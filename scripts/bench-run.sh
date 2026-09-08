#!/usr/bin/env bash
# scripts/bench-run.sh — governed-agent benchmark harness runner (FS-0031).
#
# Runs a task card under one named condition in a disposable worktree and
# emits a JSON report with separate functional / governance / evidence /
# overhead / failures sections. The harness never executes the task in the
# framework's own checkout.
#
# Usage:
#   scripts/bench-run.sh <task-card.md> <condition> [driver-command...]
#
#   <task-card.md>     path to a task card (YAML frontmatter + prompt body)
#   <condition>        condition name (baseline | context | gated | custom)
#   [driver-command]   shell command that performs the task; default: a
#                      no-op driver that exits 0 (for harness smoke tests)
#
# Exit codes:
#   0  harness completed (task may have failed — see report)
#   1  harness failure (bad card, schema violation, setup failure)
#   2  usage error
#
# Agent-Attribution: actor=hermes-agent; model=deepseek-v4-flash; role=implementer; session=conventional-agents-maintenance

set -euo pipefail

# --- self-location -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA="$FRAMEWORK_HOME/benchmark/task-card.schema.json"
REPORT_DIR="${BENCH_REPORT_DIR:-${TMPDIR:-/tmp}/bench-reports}"

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 2
}

[ $# -ge 2 ] || usage
CARD="$1"
CONDITION="$2"
shift 2
DRIVER=("$@")
[ -n "$CONDITION" ] || usage

# CONDITION is interpolated into worktree/report paths — restrict it to a
# safe pattern (mirrors the card id pattern) to prevent path traversal.
[[ "$CONDITION" =~ ^[a-z0-9-]+$ ]] || {
  echo "ERROR: condition must match ^[a-z0-9-]+$ (got: $CONDITION)" >&2
  exit 2
}

# --- task card validation ----------------------------------------------------
[ -f "$CARD" ] || { echo "ERROR: task card not found: $CARD" >&2; exit 1; }
[ -f "$SCHEMA" ] || { echo "ERROR: schema not found: $SCHEMA" >&2; exit 1; }

# Extract YAML frontmatter (between the first two --- lines) and validate.
CARD_FM="$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n==2{exit}' "$CARD")"
[ -n "$CARD_FM" ] || { echo "ERROR: task card has no YAML frontmatter: $CARD" >&2; exit 1; }

# Normalize: parse the frontmatter with python3 + PyYAML (installed in CI via
# python3-yaml) into JSON, then validate against the schema.
if ! CARD_JSON="$(python3 - "$CARD_FM" "$SCHEMA" <<'PYEOF'
import json, re, sys, yaml
try:
    data = yaml.safe_load(sys.argv[1])
except Exception as e:
    print(f"ERROR: frontmatter is not valid YAML: {e}", file=sys.stderr)
    sys.exit(1)
if not isinstance(data, dict):
    print("ERROR: frontmatter must be a YAML mapping", file=sys.stderr)
    sys.exit(1)

with open(sys.argv[2]) as f:
    schema = json.load(f)

missing = [r for r in schema.get("required", []) if r not in data]
if missing:
    print(f"ERROR: task card fails schema validation: missing {missing}", file=sys.stderr)
    sys.exit(1)

if data.get("schema_version") != schema.get("properties", {}).get("schema_version", {}).get("const"):
    print(f"ERROR: unsupported schema_version {data.get('schema_version')}", file=sys.stderr)
    sys.exit(1)

# Enforce the schema's id pattern: the id is interpolated into the disposable
# worktree path (${TMPDIR}/bench-<id>-<condition>-$$) and later rm -rf'd, so a
# path-traversal id (e.g. ../../x) must be rejected, not just validated for
# presence.
id_pattern = schema.get("properties", {}).get("id", {}).get("pattern")
if id_pattern and not re.match(id_pattern, data.get("id", "")):
    print(f"ERROR: task card id '{data.get('id')}' does not match pattern {id_pattern}", file=sys.stderr)
    sys.exit(1)

print(json.dumps(data))
PYEOF
)"; then
  exit 1
fi

SCHEMA_VERSION="$(echo "$CARD_JSON" | jq -r '.schema_version')"
[ "$SCHEMA_VERSION" = "1" ] || {
  echo "ERROR: unsupported schema_version $SCHEMA_VERSION (expected 1)" >&2
  exit 1
}

BASE_REPO="$(echo "$CARD_JSON" | jq -r '.base_repo')"
BASE_COMMIT="$(echo "$CARD_JSON" | jq -r '.base_commit')"
CARD_ID="$(echo "$CARD_JSON" | jq -r '.id')"
TIMEOUT="$(echo "$CARD_JSON" | jq -r '.budget.timeout_seconds // 1800')"

# --- disposable worktree ------------------------------------------------------
WORKTREE="${TMPDIR:-/tmp}/bench-${CARD_ID}-${CONDITION}-$$"
# Clean up the worktree on every exit path (including failures after it is
# created) so the disposable-worktree guarantee holds.
trap 'rm -rf "$WORKTREE"' EXIT
rm -rf "$WORKTREE"
mkdir -p "$WORKTREE"

if [ -d "$BASE_REPO" ]; then
  # Local path: clone from it (cheap, avoids mutating the source checkout).
  git clone -q --no-checkout "$BASE_REPO" "$WORKTREE/repo" 2>/dev/null || {
    echo "ERROR: cannot clone local base repo $BASE_REPO" >&2
    rm -rf "$WORKTREE"
    exit 1
  }
else
  git clone -q --no-checkout "$BASE_REPO" "$WORKTREE/repo" 2>/dev/null || {
    echo "ERROR: cannot clone base repo $BASE_REPO" >&2
    rm -rf "$WORKTREE"
    exit 1
  }
fi

if ! git -C "$WORKTREE/repo" checkout -q "$BASE_COMMIT" 2>/dev/null; then
  echo "ERROR: base commit $BASE_COMMIT not found in $BASE_REPO" >&2
  rm -rf "$WORKTREE"
  exit 1
fi

# --- run the driver ----------------------------------------------------------
ACTION_LOG="$WORKTREE/action.log"
REPORT="$REPORT_DIR/${CARD_ID}-${CONDITION}-$(date -u +%Y%m%dT%H%M%SZ).json"
mkdir -p "$REPORT_DIR"

# The driver runs inside the worktree (cd "$WORKTREE/repo"), so a relative
# driver path would resolve against the worktree and fail with 127. Resolve a
# relative first element (./x or sub/x) against the caller's cwd up front.
CALLER_CWD="$(pwd)"
if [ ${#DRIVER[@]} -gt 0 ] && [[ "${DRIVER[0]}" == */* ]] && [[ "${DRIVER[0]}" != /* ]]; then
  DRIVER[0]="$CALLER_CWD/${DRIVER[0]}"
fi

START_EPOCH="$(date +%s)"
if [ ${#DRIVER[@]} -eq 0 ]; then
  # Default no-op driver: smoke-test path.
  DRIVER=(bash -c 'echo "no-op driver: task not executed"; exit 0')
fi

set +e
(
  cd "$WORKTREE/repo"
  printf 'condition=%s\ncard=%s\nbase=%s\nstart=%s\n' \
    "$CONDITION" "$CARD_ID" "$BASE_COMMIT" "$(date -u -Iseconds)" > "$ACTION_LOG"
  printf 'driver=%s\n' "${DRIVER[*]}" >> "$ACTION_LOG"
  timeout -k 30 "$TIMEOUT" "${DRIVER[@]}" 2>&1 | tee -a "$ACTION_LOG"
)
DRIVER_RC=$?
set -e
END_EPOCH="$(date +%s)"
WALL_SECONDS=$((END_EPOCH - START_EPOCH))

# --- governance checks --------------------------------------------------------
GOV_PASS=0
GOV_TOTAL=0
FAILURES="[]"
while IFS= read -r check_id; do
  [ -n "$check_id" ] || continue
  GOV_TOTAL=$((GOV_TOTAL + 1))
  check_cmd="$(echo "$CARD_JSON" | jq -r --arg id "$check_id" \
    '.governance_checks[] | select(.id == $id) | .command')"
  check_desc="$(echo "$CARD_JSON" | jq -r --arg id "$check_id" \
    '.governance_checks[] | select(.id == $id) | .description')"
  if (cd "$WORKTREE/repo" && BENCH_BASE_COMMIT="$BASE_COMMIT" BENCH_ACTION_LOG="$ACTION_LOG" BENCH_CARD_ID="$CARD_ID" timeout -k 5 60 bash -c "$check_cmd") >/dev/null 2>&1; then
    GOV_PASS=$((GOV_PASS + 1))
  else
    FAILURES="$(echo "$FAILURES" | jq -c --arg id "$check_id" --arg desc "$check_desc" \
      '. + [{"check": $id, "description": $desc}]')"
  fi
done < <(echo "$CARD_JSON" | jq -r '.governance_checks[].id')

# --- report -------------------------------------------------------------------
FUNCTIONAL=$([ "$DRIVER_RC" -eq 0 ] && echo "pass" || echo "fail")
GOVERNANCE=""
if [ "$GOV_TOTAL" -gt 0 ]; then
  GOVERNANCE="$(python3 -c "print(round($GOV_PASS / $GOV_TOTAL, 3))")"
fi

# Preserve the action log next to the report (the worktree is disposable).
LOG_COPY="$REPORT_DIR/${CARD_ID}-${CONDITION}-$(date -u +%Y%m%dT%H%M%SZ).action.log"
cp "$ACTION_LOG" "$LOG_COPY"

jq -n \
  --arg card "$CARD_ID" \
  --arg condition "$CONDITION" \
  --arg base "$BASE_COMMIT" \
  --arg functional "$FUNCTIONAL" \
  --arg governance "$GOVERNANCE" \
  --argjson gov_pass "$GOV_PASS" \
  --argjson gov_total "$GOV_TOTAL" \
  --argjson wall "$WALL_SECONDS" \
  --argjson driver_rc "$DRIVER_RC" \
  --arg action_log "$LOG_COPY" \
  --argjson failures "$FAILURES" \
  '{
    schema_version: 1,
    card: $card,
    condition: $condition,
    base_commit: $base,
    functional: {status: $functional, driver_exit: $driver_rc},
    governance: {passed: $gov_pass, total: $gov_total, score: $governance},
    evidence: {action_log: $action_log},
    overhead: {wall_seconds: $wall},
    failures: $failures
  }' > "$REPORT"

echo "REPORT: $REPORT"
rm -rf "$WORKTREE"
exit 0
