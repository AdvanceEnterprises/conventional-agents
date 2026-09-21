#!/usr/bin/env bash
# Run all Bats suites under test/. Each suite has a bounded wall-clock budget
# and emits progress/timing output so a stalled suite is visible.
set -uo pipefail

SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
[ "$SCRIPT_DIR" = "${BASH_SOURCE[0]}" ] && SCRIPT_DIR="."
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd -P)"

# Re-entrancy guard. This script runs every suite under test/, and a suite that
# invokes it again forks without bound — each level re-runs every suite,
# including itself. That happened: a test exercising the missing-bats path
# sanitised PATH to /usr/bin:/bin, which excludes Homebrew's bats on macOS but
# includes apt's /usr/bin/bats on Linux, so CI recursed until it exhausted the
# runner. A test that deliberately exercises this script's own behaviour must
# unset the variable (`env -u RUN_BATS_ACTIVE`), which is explicit rather than
# accidental.
if [ -n "${RUN_BATS_ACTIVE:-}" ]; then
  echo "ERROR: run-bats.sh invoked recursively — a bats suite is running it." >&2
  echo "       This would fork without bound. If a test means to exercise this" >&2
  echo "       script, run it with 'env -u RUN_BATS_ACTIVE'." >&2
  exit 1
fi
export RUN_BATS_ACTIVE=1

if ! command -v bats >/dev/null 2>&1; then
  echo "ERROR: 'bats' is not installed or not on PATH." >&2
  echo "       Install bats (https://github.com/bats-core/bats-core) to run this repo's test suite." >&2
  echo "       On macOS: brew install bats-core" >&2
  echo "       On Debian/Ubuntu: apt-get install bats" >&2
  echo "       The framework does not vendor a test runner — install it locally or via CI." >&2
  exit 1
fi

# Several suites call rg (ripgrep) directly, including with -U and -A. Check
# explicitly so missing rg cannot masquerade as assertion failures.
if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: 'rg' (ripgrep) is not installed or not on PATH." >&2
  echo "       Several suites call it directly. Without it, assertions fail with" >&2
  echo "       misleading 'pattern not found' messages against files that match." >&2
  echo "       On macOS: brew install ripgrep" >&2
  echo "       On Debian/Ubuntu: apt-get install ripgrep" >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$SCRIPT_DIR/validation-common.sh"

# Per FS-0024/ADR-0033: target the repository containing the caller's working
# directory, unless CA_TARGET_REPO explicitly selects another repository.
REPO_ROOT="$(validation_resolve_repo_root)" || exit 1

BATS_TIMEOUT_RAW="${BATS_SUITE_TIMEOUT:-900}"
BATS_TIMEOUT="$(validation_normalize_positive_integer "$BATS_TIMEOUT_RAW")" || {
  echo "ERROR: BATS_SUITE_TIMEOUT must be a positive integer (got '$BATS_TIMEOUT_RAW')." >&2
  exit 2
}

suites=()
while IFS= read -r suite; do
  [ -n "$suite" ] && suites[${#suites[@]}]="$suite"
done < <(find "$REPO_ROOT/test" -type f -name '*.bats' -print | sort)

total=${#suites[@]}
if [ "$total" -eq 0 ]; then
  echo "ERROR: no Bats suites found under '$REPO_ROOT/test'." >&2
  exit 1
fi

printf 'BATS START suites=%s suite_timeout=%ss repo=%s\n' "$total" "$BATS_TIMEOUT" "$REPO_ROOT"
failures=0
index=0
for suite in "${suites[@]}"; do
  index=$((index + 1))
  relative="${suite#"$REPO_ROOT/"}"
  started=$SECONDS
  printf 'BATS %s/%s BEGIN %s timeout=%ss\n' "$index" "$total" "$relative" "$BATS_TIMEOUT"
  validation_run_with_timeout "$BATS_TIMEOUT" bats "$suite"
  status=$?
  elapsed=$((SECONDS - started))
  if [ "$status" -eq 0 ]; then
    printf 'BATS %s/%s PASS %s elapsed=%ss\n' "$index" "$total" "$relative" "$elapsed"
  elif [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
    printf 'BATS %s/%s TIMEOUT %s elapsed=%ss status=%s\n' "$index" "$total" "$relative" "$elapsed" "$status" >&2
    failures=$((failures + 1))
  else
    printf 'BATS %s/%s FAIL %s elapsed=%ss status=%s\n' "$index" "$total" "$relative" "$elapsed" "$status" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "FAILED: $failures of $total Bats suites reported failures." >&2
  exit 1
fi
printf 'BATS PASS: all %s suites passed.\n' "$total"
