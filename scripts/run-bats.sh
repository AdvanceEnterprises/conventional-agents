#!/usr/bin/env bash
# Run all bats suites under test/. Fails with an install hint when bats is absent
# — silent skip is worse than failure, since `ROLE_CONTRACT`'s pre-commit testing gate
# has nothing to run otherwise.
set -e

# Per FS-0024/ADR-0033: the git repository containing the caller's working
# directory, not the script's own location — so a vendored copy runs the host's
# own test/ suites, not this repository's. `npm test` and every CI job invoke this
# with their working directory already at the repository they mean to run, so
# resolution is unchanged for every invocation this repository makes of itself.
# CA_TARGET_REPO overrides both, for a caller whose working directory is not
# inside the repository it means to run.
REPO_ROOT="${CA_TARGET_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Re-entrancy guard. This script runs every suite under test/, and a suite that
# invokes it again forks without bound — each level re-runs every suite, including
# itself. That happened: a test exercising the missing-bats path sanitised PATH to
# /usr/bin:/bin, which excludes Homebrew's bats on macOS but includes apt's
# /usr/bin/bats on Linux, so CI recursed until it exhausted the runner.
#
# A test that deliberately exercises this script's own behaviour must unset the
# variable (`env -u RUN_BATS_ACTIVE`), which is explicit rather than accidental.
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

# Several suites call `rg` (ripgrep) directly, including with -U (multiline) and
# -A (context), which have no clean POSIX equivalent. Check for it explicitly: a
# missing rg previously surfaced as every assertion failing with "expected <file>
# to contain pattern", naming files that plainly contained it, because the helper
# swallowed the command-not-found error. Fail loudly instead.
if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: 'rg' (ripgrep) is not installed or not on PATH." >&2
  echo "       Several suites call it directly. Without it, assertions fail with" >&2
  echo "       misleading 'pattern not found' messages against files that match." >&2
  echo "       On macOS: brew install ripgrep" >&2
  echo "       On Debian/Ubuntu: apt-get install ripgrep" >&2
  exit 1
fi

# Run every .bats file under test/. Subdirectories are intentional (FS-NNNN/*).
failures=0
total=0
for suite in $(find "$REPO_ROOT/test" -name '*.bats' -type f | sort); do
  echo "# $suite"
  if ! bats "$suite"; then
    failures=$((failures+1))
  fi
  total=$((total+1))
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAILED: $failures of $total bats suites reported failures."
  exit 1
fi

echo ""
echo "All $total bats suites passed."
