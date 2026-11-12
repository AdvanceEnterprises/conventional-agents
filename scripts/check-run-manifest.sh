#!/usr/bin/env bash
# check-run-manifest.sh — run-manifest / tier-integrity detection for ADR-0049
# (supersedes ADR-0045).
#
# Iterates a commit range (or a single commit) and detects two ADR-0049
# violations in detection-only posture:
#
#   (a) A proposal-class document (docs/specifications/, docs/change-plans/,
#       docs/decisions/) ENTERS AN ACCEPTED STATUS outside a batch-acceptance
#       commit that covers it — i.e. an Approved-Artifacts: trailer naming that
#       artifact AND an Approved-By: trailer recording the approver (ADR-0026).
#       The rule is a status-transition rule, not a touch rule: ADR-0045 steps
#       5-6 require the drafting, review-fix, and index-alignment commits that
#       precede acceptance, and those legitimately change a proposal-class
#       document while it is still draft/proposed.
#   (b) A batch-acceptance commit (one carrying an Approved-Artifacts: trailer)
#       overreaches into forbidden paths outside the proposal-class set.
#
# An Approved-Artifacts: trailer with no Approved-By: is reported on its own: a
# trailer alone must never be able to silence rule (a) (ADR-0026 — approval is a
# recorded act by an author other than the committer).
#
# Rule (b) delegates to the existing check-run-batch.sh so the two scripts stay
# aligned on path classification and artifact-state rules.
#
# Merge commits are enumerated with `git diff-tree -m --root`, so conflict-
# resolution content introduced by a merge (present in neither parent) and the
# root commit are both scanned. For a merge, a document counts as promoted only
# when its status is accepted at the merge and not accepted at ANY parent.
#
# Out of scope by design: edits to an already-accepted document that do not
# change its status, index-README edits that are not accompanied by a document
# status change (the document front matter is the authoritative state), and
# deletions of proposal-class documents.
#
# Exit codes:
#   0  no findings in the inspected range
#   1  one or more tier-integrity findings
#   2  invalid input, missing history, or not a Git worktree
#
# Read-only; never fetches or edits. Bash 3.2 compatible — no associative arrays.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

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
Usage: check-run-manifest.sh [<rev-range>|<commit-ish>] [--help]

Inspect a commit range (or a single commit) for ADR-0049 tier-integrity
violations:

  - a proposal-class document entering an accepted status outside a covering
    batch-acceptance commit (Approved-Artifacts: naming it plus Approved-By:);
  - an Approved-Artifacts: trailer with no Approved-By:;
  - batch-acceptance commits that touch forbidden paths.

A <rev-range> uses Git's two-dot syntax, e.g. origin/trunk..HEAD.
Defaults to HEAD.

Exit codes:
  0  clean
  1  tier-integrity findings
  2  invalid input or unavailable history

Read-only; never fetches or edits.
EOF
}

ARG="${1:-HEAD}"
case "$ARG" in
  -h|--help) usage; exit 0 ;;
esac

# Resolve the range into a list of commits. A single commit-ish yields one commit;
# a two-dot range yields the commits reachable from the second excluding the first.
if [[ "$ARG" == *..* ]]; then
  if ! COMMITS="$(git rev-list --reverse "$ARG" 2>/dev/null)"; then
    echo "ERROR: '$ARG' is not a valid rev-range in this repository." >&2
    exit 2
  fi
else
  if ! COMMIT="$(git rev-parse --verify "${ARG}^{commit}" 2>/dev/null)"; then
    echo "ERROR: '$ARG' is not a valid commit in this repository." >&2
    exit 2
  fi
  COMMITS="$COMMIT"
fi
if [ -z "$COMMITS" ]; then
  echo "ERROR: no commits resolved from '$ARG'." >&2
  exit 2
fi

# Proposal-class artifact locations (the batchable set under ADR-0049,
# which carries forward the ADR-0045 contract).
# Note: CHANGELOG.md is deliberately excluded here. It is allowed inside a batch
# acceptance (see check-run-batch.sh) but it is not itself a proposal-class
# artifact, and requiring every non-batch CHANGELOG update to carry an
# Approved-Artifacts: trailer would be false-positive noise.
is_proposal_class() {
  case "$1" in
    docs/specifications/*|docs/change-plans/*|docs/decisions/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Front-matter status of <commit>:<path>. Empty when the path is absent at that
# commit, has no front matter, or states no status.
status_at() {
  local commit="$1" path="$2" raw
  raw="$(git show "$commit:$path" 2>/dev/null | awk '
    NR == 1 { if ($0 !~ /^---[ \t]*$/) exit; next }
    /^---[ \t]*$/ { exit }
    /^status:/ { sub(/^status:[ \t]*/, ""); print; exit }
  ' || true)"
  printf '%s' "$raw" | tr -d '[:space:]"'
}

is_accepted_status() {
  case "${1:-}" in
    accepted|approved|implemented) return 0 ;;
    *) return 1 ;;
  esac
}

# Changed paths in <commit>. Merge commits need -m: plain `git diff-tree` prints
# nothing for them, so conflict-resolution content would be invisible. The root
# commit needs --root for the same reason. sort -u dedupes the per-parent union.
changed_paths() {
  git diff-tree -m --root --no-commit-id --name-only -r "$1" 2>/dev/null | sort -u || true
}

parents_of() {
  # Strip the leading commit ID; a root commit leaves an empty string. (cut -f2-
  # prints the whole line when the delimiter is absent, which would make a root
  # commit look like its own parent.)
  git rev-list --parents -n 1 "$1" 2>/dev/null | sed 's/^[0-9a-f]*//' || true
}

# Trailer value for <key> on <commit>, newlines normalized to commas and an
# absent trailer normalized to the empty string.
trailer_value() {
  local raw
  raw="$(git log -1 --format="%(trailers:key=$2,valueonly)" "$1" 2>/dev/null || true)"
  printf '%s' "$raw" | tr '\n' ',' | sed 's/,,*/,/g; s/^,//; s/,$//'
}

has_value() {
  [ -n "$(printf '%s' "$1" | tr -d ' ,')" ]
}

# The FS-/PLAN-/ADR- ID named by a proposal-class path, e.g.
# docs/specifications/FS-0050-run-batch-tier-integrity-check.md -> FS-0050.
# Fails for index READMEs and non-document paths.
artifact_id_of_path() {
  local path="$1" base kind rest num
  case "$path" in
    docs/specifications/*|docs/change-plans/*|docs/decisions/*) ;;
    *) return 1 ;;
  esac
  base="${path##*/}"
  case "$base" in
    FS-[0-9][0-9][0-9][0-9]-*.md|PLAN-[0-9][0-9][0-9][0-9]-*.md|ADR-[0-9][0-9][0-9][0-9]-*.md) ;;
    *) return 1 ;;
  esac
  kind="${base%%-*}"
  rest="${base#*-}"
  num="${rest%%-*}"
  printf '%s-%s' "$kind" "$num"
}

# True when <commit> may promote <path>: it carries a non-empty Approved-Artifacts:
# trailer, a non-empty Approved-By: trailer (ADR-0026), and the artifact ID of
# <path> is named in the batch list. Naming an unrelated, already-accepted
# artifact — or omitting the approver — does not authorize this document's
# promotion, so it cannot silence rule (a).
batch_covers() {
  local commit="$1" approved="$2" approved_by="$3" path="$4" id
  has_value "$approved" || return 1
  has_value "$approved_by" || return 1
  id="$(artifact_id_of_path "$path")" || return 1
  [ -n "$id" ] || return 1
  printf '%s' "$approved" | tr ',' '\n' | sed 's/[[:space:]]//g' | grep -qx "$id"
}

status=0

while IFS= read -r commit; do
  [ -n "$commit" ] || continue

  CHANGED="$(changed_paths "$commit")"
  APPROVED="$(trailer_value "$commit" Approved-Artifacts)"
  APPROVED_BY="$(trailer_value "$commit" Approved-By)"

  # A claim of acceptance with no recorded approver is not an approval
  # (ADR-0026). Reported even when the commit promotes nothing, so a bare
  # trailer cannot be used as a detector silencer.
  if has_value "$APPROVED" && ! has_value "$APPROVED_BY"; then
    echo "ERROR: commit $commit claims Approved-Artifacts without an Approved-By: trailer (ADR-0026: approval is a recorded act)." >&2
    status=1
  fi

  if has_value "$APPROVED"; then
    # (b) delegate the batch-acceptance tier check to the existing detector.
    if ! env CA_TARGET_REPO="$REPO_ROOT" bash "$SCRIPT_DIR/check-run-batch.sh" "$commit"; then
      status=1
    fi
  fi

  # (a) a proposal-class document must not enter an accepted status outside a
  # batch acceptance that names it. Drafting / review-fix / index commits change
  # the document while it is still draft: not a transition, not a finding.
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    is_proposal_class "$path" || continue

    new_status="$(status_at "$commit" "$path")"
    is_accepted_status "$new_status" || continue

    promoted=1
    for parent in $(parents_of "$commit"); do
      if is_accepted_status "$(status_at "$parent" "$path")"; then
        promoted=0
        break
      fi
    done
    [ "$promoted" -eq 1 ] || continue

    if batch_covers "$commit" "$APPROVED" "$APPROVED_BY" "$path"; then
      continue
    fi

    echo "ERROR: commit $commit promotes proposal-class artifact $path to '$new_status' outside a covering batch acceptance (named: ${APPROVED:-none})." >&2
    status=1
  done <<< "$CHANGED"
done <<< "$COMMITS"

exit "$status"
