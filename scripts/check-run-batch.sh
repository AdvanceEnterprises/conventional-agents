#!/usr/bin/env bash
# check-run-batch.sh — validate a batch-acceptance commit's tier integrity.
#
# Implements FS-0050 / ADR-0045. A *batch-acceptance commit* — a commit carrying
# an Approved-Artifacts: trailer (the batch list of a recorded approval, per
# ADR-0026) — must accept only proposal-class documents and change no
# implementation surface.
#
# Proposal-class locations: docs/specifications/, docs/change-plans/,
# docs/decisions/, their index READMEs, and CHANGELOG.md. Every other path
# (scripts/, test/, .github/, package.json, integrations/, templates/,
# workflows/, guidelines/, ...) is forbidden in a batch-acceptance diff.
#
# Artifact IDs and their front-matter status are resolved against the tree at
# the commit being validated, not the working tree (PLAN-0056 §7).
#
# This is a DETECTION check, not prevention: it reports an overreaching batch
# and exits non-zero, but does not block a merge and does not enforce the
# reserved-path approval gate (ADR-0027 / ADR-0012 concerns). It does NOT
# re-validate the ADR-0026 approval shape.
#
# Read-only; never fetches or edits. Bash 3.2 compatible — no associative arrays.
set -euo pipefail

if [ -n "${CA_TARGET_REPO:-}" ]; then
  if ! REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 2
  fi
else
  if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: cannot resolve a Git worktree; run from a repository or set CA_TARGET_REPO." >&2
    exit 2
  fi
fi
cd "$REPO_ROOT"

usage() {
  cat <<'EOF'
Usage: check-run-batch.sh [<commit-ish>] [--help]

Validate the tier integrity of a batch-acceptance commit (one carrying an
Approved-Artifacts: trailer). Defaults to HEAD.

Exit codes:
  0  no batch-acceptance commit, or a clean proposal-only batch
  1  the batch overreaches (forbidden path, or a missing/unaccepted artifact)
  2  unavailable history, invalid input, or a non-Git working tree

Read-only; never fetches or edits.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") COMMIT="HEAD" ;;
  *) COMMIT="$1" ;;
esac

if ! git cat-file -e "$COMMIT^{commit}" 2>/dev/null; then
  echo "ERROR: '$COMMIT' is not a commit in this repository." >&2
  exit 2
fi

# The batch list. valueonly joins multiple trailers with newlines; normalize.
APPROVED="$(git log -1 --format='%(trailers:key=Approved-Artifacts,valueonly)' "$COMMIT" 2>/dev/null | tr '\n' ',' || true)"

# No Approved-Artifacts trailer => not a batch-acceptance commit; not in scope.
if [ -z "$(printf '%s' "$APPROVED" | tr -d ' ,')" ]; then
  exit 0
fi

status=0

# Changed paths in this commit only (not its parents).
CHANGED="$(git diff-tree --no-commit-id --name-only -r "$COMMIT" 2>/dev/null || true)"
for path in $CHANGED; do
  [ -n "$path" ] || continue
  case "$path" in
    docs/specifications/*|docs/change-plans/*|docs/decisions/*|CHANGELOG.md) ;;
    *) echo "ERROR: batch-acceptance commit $COMMIT touches forbidden path: $path" >&2; status=1 ;;
  esac
done

# Tracked files at the commit being validated (not the working tree), so the
# artifact resolution and status read are correct for any commit-ish.
TREE_FILES="$(git ls-tree -r --name-only "$COMMIT" 2>/dev/null || true)"

# Every listed artifact must resolve to an existing proposal-class document in
# an accepted/approved/implemented state.
IFS=',' read -ra IDS <<< "$APPROVED"
for id in "${IDS[@]}"; do
  id="$(printf '%s' "$id" | tr -d '[:space:]')"
  [ -z "$id" ] && continue
  case "$id" in
    FS-[0-9][0-9][0-9][0-9])   pat="^docs/specifications/$id-[^/]*\.md$" ;;
    PLAN-[0-9][0-9][0-9][0-9]) pat="^docs/change-plans/$id-[^/]*\.md$" ;;
    ADR-[0-9][0-9][0-9][0-9])  pat="^docs/decisions/$id-[^/]*\.md$" ;;
    *)
      echo "ERROR: unrecognized artifact ID '$id' in $COMMIT (expected FS-/PLAN-/ADR-)." >&2
      status=1
      continue ;;
  esac
  file="$(printf '%s\n' "$TREE_FILES" | grep -E "$pat" | head -n 1 || true)"
  if [ -z "$file" ]; then
    echo "ERROR: $id has no matching proposal-class document at $COMMIT." >&2
    status=1
    continue
  fi
  st="$(git show "$COMMIT:$file" 2>/dev/null | sed -n 's/^status:[[:space:]]*//p' | head -n 1 | tr -d '[:space:]"')"
  case "$st" in
    accepted|approved|implemented) ;;
    *) echo "ERROR: $id is '$st' — a batch acceptance may only name accepted/approved/implemented artifacts." >&2; status=1 ;;
  esac
done

exit "$status"
