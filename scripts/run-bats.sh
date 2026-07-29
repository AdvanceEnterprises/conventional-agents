#!/usr/bin/env bash
# Run all bats suites under test/. Fails with an install hint when bats is absent
# — silent skip is worse than failure, since `ROLE_CONTRACT`'s pre-commit testing gate
# has nothing to run otherwise.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
  echo "ERROR: 'bats' is not installed or not on PATH." >&2
  echo "       Install bats (https://github.com/bats-core/bats-core) to run this repo's test suite." >&2
  echo "       On macOS: brew install bats-core" >&2
  echo "       On Debian/Ubuntu: apt-get install bats" >&2
  echo "       The framework does not vendor a test runner — install it locally or via CI." >&2
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
