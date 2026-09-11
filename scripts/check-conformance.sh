#!/usr/bin/env bash
# check-conformance.sh — consumer-conformance doctor (prototype, FS-0031)
#
# Read-only diagnostic for a repository that vendors conventional-agents:
# checks that the framework reference is present, the required anchors exist,
# references are not dangling, the vendored status gate is wired, and CI runs
# the governance gates. Reports findings without writing anything.
#
# Usage:
#   bash scripts/check-conformance.sh            # human-readable report
#   bash scripts/check-conformance.sh --json     # machine-readable (JSON)
#   bash scripts/check-conformance.sh --help
#
# Exit codes:
#   0  conformant (no findings)
#   1  findings reported (non-conformant or unverifiable)
#   2  usage error
#
# Per FS-0024/ADR-0033 the target repository is resolved from the caller's
# working directory (git rev-parse --show-toplevel) or CA_TARGET_REPO, so a
# vendored copy checks the host repository, not this framework. When the
# resolved target IS this framework (self-check), the framework-presence
# checks are skipped and the remaining checks run against the framework's own
# exported surface.

set -uo pipefail

if [ -n "${CA_TARGET_REPO:-}" ]; then
  REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"
  if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 2
  fi
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# ----- Defaults -----
JSON_OUT=false

# ----- Help -----
show_usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

# ----- Parse arguments -----
while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      JSON_OUT=true
      shift
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      show_usage >&2
      exit 2
      ;;
  esac
done

# ----- Report accumulator -----
# Each finding: severity|check|message
FINDINGS=()
add_finding() {
  FINDINGS+=("$1|$2|$3")
}

# ----- Self-check detection -----
# The framework's own layout is docs/decisions/ + scripts/check-status.sh at
# the repo root. A consumer fixture or vendored copy does not have that shape
# at its root (its framework lives under vendor/), so this is a robust
# discriminator even when the script has been copied into a scratch repo.
SELF_CHECK=false
if [ -d "$REPO_ROOT/docs/decisions" ] && [ -f "$REPO_ROOT/scripts/check-status.sh" ]; then
  SELF_CHECK=true
fi

# ----- Check 1: framework presence (skipped in self-check) -----
VENDOR_AGENTS=""
if [ "$SELF_CHECK" = "false" ]; then
  if [ -f "$REPO_ROOT/vendor/conventional-agents/AGENTS.md" ]; then
    VENDOR_AGENTS="$REPO_ROOT/vendor/conventional-agents/AGENTS.md"
  elif [ -f "$REPO_ROOT/vendor/conventional-agents/INTEGRATION.md" ]; then
    VENDOR_AGENTS="$REPO_ROOT/vendor/conventional-agents/INTEGRATION.md"
  else
    add_finding "critical" "framework-presence" \
      "no vendored framework found: expected vendor/conventional-agents/AGENTS.md (submodule or copy)"
  fi
fi

# ----- Check 2: required anchors in AGENTS.md -----
AGENTS_MD="$REPO_ROOT/AGENTS.md"
if [ -f "$AGENTS_MD" ]; then
  if ! grep -q "vendor/conventional-agents" "$AGENTS_MD"; then
    add_finding "major" "anchors" \
      "AGENTS.md does not reference vendor/conventional-agents (see INTEGRATION.md Quick Start)"
  fi
  if ! grep -q "INTEGRATION.md" "$AGENTS_MD"; then
    add_finding "minor" "anchors" \
      "AGENTS.md does not reference INTEGRATION.md — precedence rules may be invisible to agents"
  fi
else
  add_finding "major" "anchors" "AGENTS.md is missing — the framework entry point for agents"
fi

# ----- Check 3: dangling references to vendored paths -----
# Scan AGENTS.md and INTEGRATION.md for declared vendor/conventional-agents/<path>
# references and verify each referenced file exists. Only DECLARED references
# are checked: markdown link targets ([text](vendor/...)) and explicit list
# items (- vendor/... or * vendor/...). Prose mentions (e.g. "see
# vendor/conventional-agents/INTEGRATION.md") document intent, not a local
# file reference, and are not flagged. Skipped in self-check: the framework's
# own AGENTS.md references vendor/conventional-agents/* as consumer-facing
# instructions, not as local paths.
if [ "$SELF_CHECK" = "false" ] && [ -n "$VENDOR_AGENTS" ]; then
  REF_FILES=("$AGENTS_MD")
  [ -f "$REPO_ROOT/INTEGRATION.md" ] && REF_FILES+=("$REPO_ROOT/INTEGRATION.md")
  for ref_file in "${REF_FILES[@]}"; do
    [ -f "$ref_file" ] || continue
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      # ref is like vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
      if [ ! -e "$REPO_ROOT/$ref" ]; then
        add_finding "major" "dangling-reference" \
          "$(basename "$ref_file") references $ref but the file does not exist"
      fi
    done < <({
        grep -oE '\]\(vendor/conventional-agents/[A-Za-z0-9_./-]+' "$ref_file" \
          | sed 's/^](//'
        grep -E '^[[:space:]]*[-*+][[:space:]]+vendor/conventional-agents/' "$ref_file" \
          | grep -oE 'vendor/conventional-agents/[A-Za-z0-9_./-]+'
      } | sort -u)
  done
fi

# ----- Check 4: vendored status gate runnable -----
if [ "$SELF_CHECK" = "false" ]; then
  if [ -f "$REPO_ROOT/vendor/conventional-agents/scripts/check-status.sh" ]; then
    if (cd "$REPO_ROOT" && bash vendor/conventional-agents/scripts/check-status.sh >/dev/null 2>&1); then
      :
    else
      add_finding "major" "status-gate" \
        "vendored check-status.sh fails against this repository — run it to see the findings"
    fi
  else
    add_finding "minor" "status-gate" \
      "vendored scripts/check-status.sh not found — governance status gate not wired"
  fi
else
  if (cd "$REPO_ROOT" && bash scripts/check-status.sh >/dev/null 2>&1); then
    :
  else
    add_finding "major" "status-gate" \
      "framework self-check: scripts/check-status.sh fails against this repository"
  fi
fi

# ----- Check 5: CI wiring -----
CI_FOUND=false
for wf in "$REPO_ROOT"/.github/workflows/*.yml "$REPO_ROOT"/.github/workflows/*.yaml; do
  [ -f "$wf" ] || continue
  if grep -qE "check-status|check:status|governance" "$wf"; then
    CI_FOUND=true
    break
  fi
done
if [ "$CI_FOUND" = "false" ]; then
  add_finding "minor" "ci-wiring" \
    "no workflow under .github/workflows/ runs the governance status gate (check-status)"
fi

# ----- Check 6: framework version reference -----
if [ -n "$VENDOR_AGENTS" ]; then
  version_line=$(grep -m1 "Framework Version:" "$VENDOR_AGENTS" 2>/dev/null || true)
  if [ -z "$version_line" ]; then
    add_finding "minor" "version-reference" \
      "vendored AGENTS.md carries no 'Framework Version:' line — version drift undetectable"
  fi
fi

# ----- Output -----
if [ "$JSON_OUT" = "true" ]; then
  python3 - "$REPO_ROOT" "${FINDINGS[@]}" <<'PYEOF'
import json, sys
root = sys.argv[1]
findings = []
for entry in sys.argv[2:]:
    sev, check, msg = entry.split("|", 2)
    findings.append({"severity": sev, "check": check, "message": msg})
print(json.dumps({
    "tool": "check-conformance",
    "target": root,
    "conformant": len(findings) == 0,
    "finding_count": len(findings),
    "findings": findings,
}, indent=2))
PYEOF
else
  if [ "${#FINDINGS[@]}" -eq 0 ]; then
    echo "conformance: OK — no findings for $REPO_ROOT"
  else
    echo "conformance: ${#FINDINGS[@]} finding(s) for $REPO_ROOT"
    for f in "${FINDINGS[@]}"; do
      IFS='|' read -r sev check msg <<< "$f"
      printf '  [%s] %s: %s\n' "$sev" "$check" "$msg"
    done
  fi
fi

if [ "${#FINDINGS[@]}" -gt 0 ]; then
  exit 1
fi
exit 0
