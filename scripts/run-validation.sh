#!/usr/bin/env bash
# Canonical, bounded validation surface for conventional-agents (#132 / FS-0032).
# The five commands below are the same entry point used locally and in CI.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/validation-common.sh"

REPO_ROOT="$(validation_resolve_repo_root)" || exit 1
cd "$REPO_ROOT" || exit 1

TEST_TIMEOUT_RAW="${CA_VALIDATION_TEST_TIMEOUT:-1800}"
GATE_TIMEOUT_RAW="${CA_VALIDATION_GATE_TIMEOUT:-120}"
BATS_TIMEOUT_RAW="${BATS_SUITE_TIMEOUT:-900}"
BUDGET_RAW="${CA_VALIDATION_BUDGET:-1800}"
TEST_TIMEOUT="$(validation_normalize_positive_integer "$TEST_TIMEOUT_RAW")" || {
  echo "ERROR: CA_VALIDATION_TEST_TIMEOUT must be a positive integer (got '$TEST_TIMEOUT_RAW')." >&2
  exit 2
}
GATE_TIMEOUT="$(validation_normalize_positive_integer "$GATE_TIMEOUT_RAW")" || {
  echo "ERROR: CA_VALIDATION_GATE_TIMEOUT must be a positive integer (got '$GATE_TIMEOUT_RAW')." >&2
  exit 2
}
BATS_TIMEOUT="$(validation_normalize_positive_integer "$BATS_TIMEOUT_RAW")" || {
  echo "ERROR: BATS_SUITE_TIMEOUT must be a positive integer (got '$BATS_TIMEOUT_RAW')." >&2
  exit 2
}
BUDGET="$(validation_normalize_positive_integer "$BUDGET_RAW")" || {
  echo "ERROR: CA_VALIDATION_BUDGET must be a positive integer (got '$BUDGET_RAW')." >&2
  exit 2
}

# A validation target must be clean: otherwise a result depends on the caller's
# uncommitted files. node_modules is normally ignored and therefore harmless.
if [ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=all)" ]; then
  echo "ERROR: validation target is not clean: $REPO_ROOT" >&2
  echo "       Run validation from a clean checkout or set CA_TARGET_REPO to one." >&2
  exit 1
fi

LOG_FILE="${CA_VALIDATION_LOG:-}"
if [ -z "$LOG_FILE" ]; then
  LOG_PARENT="${CA_VALIDATION_LOG_DIR:-/tmp}"
  mkdir -p "$LOG_PARENT" || exit 1
  LOG_FILE="$(mktemp "$LOG_PARENT/conventional-agents-validation.XXXXXX.log")" || exit 1
elif [ "${LOG_FILE#/}" = "$LOG_FILE" ]; then
  LOG_FILE="$REPO_ROOT/$LOG_FILE"
fi
case "$LOG_FILE" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "ERROR: CA_VALIDATION_LOG must be outside the validation target so the run cannot dirty it." >&2
    exit 1
    ;;
esac
mkdir -p "$(dirname "$LOG_FILE")" || exit 1
: > "$LOG_FILE" || exit 1

# Keep all generated state, credentials/config lookup, and network-capable
# command names inside a disposable sandbox. The gate commands themselves use
# only local files and Git history prepared by the caller.
SANDBOX_PARENT="${CA_VALIDATION_TMPDIR:-/tmp}"
mkdir -p "$SANDBOX_PARENT" || exit 1
SANDBOX="$(mktemp -d "$SANDBOX_PARENT/conventional-agents-validation.XXXXXX")" || exit 1
cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$SANDBOX/tmp" "$SANDBOX/home" "$SANDBOX/config" "$SANDBOX/npm-cache" "$SANDBOX/bin"
: > "$SANDBOX/gitconfig"

cat > "$SANDBOX/network-denied" <<'DENIED'
#!/usr/bin/env bash
printf '%s\n' "ERROR: network-capable command is disabled during canonical validation." >&2
exit 86
DENIED
chmod +x "$SANDBOX/network-denied"
for blocked in gh curl wget ssh scp nc; do
  ln -s "$SANDBOX/network-denied" "$SANDBOX/bin/$blocked"
done

export HOME="$SANDBOX/home"
export XDG_CONFIG_HOME="$SANDBOX/config"
export GIT_CONFIG_GLOBAL="$SANDBOX/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export npm_config_cache="$SANDBOX/npm-cache"
export npm_config_offline=true
export TMPDIR="$SANDBOX/tmp"
export PATH="$SANDBOX/bin:$PATH"
unset GH_TOKEN GITHUB_TOKEN 2>/dev/null || true

# The log captures the full runner output; the path is intentionally printed so
# callers can archive it as a baseline artifact.
exec > >(tee "$LOG_FILE") 2>&1

STARTED=$SECONDS
FAILED=0
STEP=0
TOTAL_STEPS=5
COMMIT_RANGE_VALUE="${COMMIT_RANGE:-HEAD~20..HEAD}"

printf 'VALIDATION START repo=%s revision=%s\n' "$REPO_ROOT" "$(git -C "$REPO_ROOT" rev-parse HEAD)"
printf 'VALIDATION CONTRACT steps=%s test_timeout=%ss gate_timeout=%ss bats_suite_timeout=%ss budget=%ss\n' \
  "$TOTAL_STEPS" "$TEST_TIMEOUT" "$GATE_TIMEOUT" "$BATS_TIMEOUT" "$BUDGET"
printf 'VALIDATION LOG %s\n' "$LOG_FILE"
printf 'VALIDATION COMMIT_RANGE %s\n' "$COMMIT_RANGE_VALUE"

run_step() {
  local label="$1" configured_timeout="$2"
  shift 2
  local elapsed remaining timeout started status
  STEP=$((STEP + 1))
  elapsed=$((SECONDS - STARTED))
  remaining=$((BUDGET - elapsed))
  if [ "$remaining" -le 0 ]; then
    echo "STEP $STEP/$TOTAL_STEPS SKIP $label — validation budget exhausted"
    FAILED=1
    return 0
  fi
  timeout="$configured_timeout"
  if [ "$timeout" -gt "$remaining" ]; then
    timeout="$remaining"
  fi
  started=$SECONDS
  printf 'STEP %s/%s BEGIN %s timeout=%ss\n' "$STEP" "$TOTAL_STEPS" "$label" "$timeout"
  validation_run_with_timeout "$timeout" "$@"
  status=$?
  elapsed=$((SECONDS - started))
  if [ "$status" -eq 0 ]; then
    printf 'STEP %s/%s PASS %s elapsed=%ss\n' "$STEP" "$TOTAL_STEPS" "$label" "$elapsed"
  elif [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
    printf 'STEP %s/%s TIMEOUT %s elapsed=%ss status=%s\n' "$STEP" "$TOTAL_STEPS" "$label" "$elapsed" "$status"
    FAILED=1
  else
    printf 'STEP %s/%s FAIL %s elapsed=%ss status=%s\n' "$STEP" "$TOTAL_STEPS" "$label" "$elapsed" "$status"
    FAILED=1
  fi
  return 0
}

run_step "npm test" "$TEST_TIMEOUT" \
  env CA_TARGET_REPO="$REPO_ROOT" BATS_SUITE_TIMEOUT="$BATS_TIMEOUT" npm test
run_step "npm run lint:docs" "$GATE_TIMEOUT" \
  env CA_TARGET_REPO="$REPO_ROOT" npm run lint:docs
run_step "npm run check:status" "$GATE_TIMEOUT" \
  env CA_TARGET_REPO="$REPO_ROOT" npm run check:status
run_step "npm run check:freshness" "$GATE_TIMEOUT" \
  env CA_TARGET_REPO="$REPO_ROOT" npm run check:freshness
run_step "npm run lint:cross-repo" "$GATE_TIMEOUT" \
  env CA_TARGET_REPO="$REPO_ROOT" CA_NO_NETWORK=1 STRICT_TOOLS=1 COMMIT_RANGE="$COMMIT_RANGE_VALUE" npm run lint:cross-repo

ELAPSED=$((SECONDS - STARTED))
printf 'VALIDATION END elapsed=%ss verdict=%s\n' "$ELAPSED" "$([ "$FAILED" -eq 0 ] && echo PASS || echo FAIL)"
if [ "$ELAPSED" -gt "$BUDGET" ]; then
  echo "VALIDATION FAIL: documented budget ${BUDGET}s exceeded (${ELAPSED}s)."
  FAILED=1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "VALIDATION FAIL: one or more commands failed or timed out."
  exit 1
fi
echo "VALIDATION PASS: all five commands completed within the documented budget."
