#!/usr/bin/env bash
#
# check-current-state.sh — ADR-0030 rule 3 (FS-0022 §3)
#
# An ADR that changes a rule must modify the current-state document carrying that rule
# in the same change. A decision recorded nowhere but the decision log leaves the
# document a reader actually follows saying the old thing.
#
# CI-only, and separate from check-status.sh on purpose: this needs the change set, and
# FS-0022 §3 requires check-status.sh to stay runnable against a working tree with no
# diff context.
#
# Usage:  check-current-state.sh [base-ref]        (default: origin/trunk)
#
# Scope narrowing, deliberate and narrower than FS-0022 §3's literal wording:
#
#   The spec says "every ADR added or modified in a pull request". Taken literally, a
#   typo fix in an accepted ADR whose Links name `workflows/session-modes.md` would
#   demand an unrelated edit to that workflow. ADR-0030 rule 3 binds on *changing a
#   rule*, not on touching a file, and the mechanically detectable moment a rule
#   becomes binding is acceptance. So an ADR is in scope when the diff adds a
#   `status: accepted` line — which covers both an ADR added at accepted and one
#   transitioning to it — and out of scope for edits that do not change its status.
#
#   An ADR added as `proposed` is also out of scope: nothing is binding yet, and the
#   current-state update is due when it is accepted.
#
# Not caught: an ADR that changes a rule and names no current-state document at all.
# That is a documentation defect the hygiene gate covers, not this check.

set -uo pipefail

# Already caller-relative, not script-relative — this script never had the
# defect FS-0024/ADR-0033 fixes in the other two. CA_TARGET_REPO is added here
# only for symmetry: a caller should not need to know that this one script
# already happened to resolve correctly and so doesn't honor the override the
# other two do.
REPO_ROOT="${CA_TARGET_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BASE_REF=${1:-origin/trunk}

# Current-state directories per ADR-0030. `runbooks/` was added by FS-0023, after
# FS-0022 §3 enumerated the list.
CURRENT_STATE_RE='^(workflows|guidelines|skills|templates|integrations|runbooks)/'

# Print the current-state paths an ADR names in its ## Links section.
adr_current_state_links() {
  awk '/^## Links/{f=1;next} f&&/^## /{exit} f' "$1" 2>/dev/null |
    grep -oE '`[A-Za-z0-9_./-]+`' 2>/dev/null | tr -d '`' |
    grep -E "$CURRENT_STATE_RE" 2>/dev/null | sort -u
}

# True when the diff for this ADR adds a `status: accepted` line.
adr_becomes_accepted() {
  git -C "$REPO_ROOT" diff "$1...HEAD" -- "$2" 2>/dev/null |
    grep -qE '^\+status:[[:space:]]*accepted[[:space:]]*$'
}

# Core logic, separated from git so tests can drive it directly.
#   $1 — newline-separated changed files
#   $2 — newline-separated ADR paths in scope
# Prints one ERROR per unsatisfied ADR; returns the count.
check_links_against_changes() {
  local changed="$1" in_scope="$2" adr links found link errs=0
  while IFS= read -r adr; do
    [ -z "$adr" ] && continue
    [ -f "$REPO_ROOT/$adr" ] || continue
    links=$(adr_current_state_links "$REPO_ROOT/$adr")
    [ -z "$links" ] && continue
    found=0
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      # A link naming a directory (`skills/`) is satisfied by any change beneath it;
      # a link naming a file must match exactly.
      case "$link" in
        */) printf '%s\n' "$changed" | grep -q "^${link}" && { found=1; break; } ;;
        *)  printf '%s\n' "$changed" | grep -qxF "$link" && { found=1; break; } ;;
      esac
    done <<< "$links"
    if [ "$found" -eq 0 ]; then
      echo "ERROR: $(basename "$adr") becomes accepted in this change but modifies none of the"
      echo "       current-state documents its ## Links name (ADR-0030 rule 3, FS-0022 §3):"
      printf '         %s\n' $links
      errs=$((errs+1))
    fi
  done <<< "$in_scope"
  return $errs
}

main() {
  if ! git -C "$REPO_ROOT" rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    echo "check-current-state.sh: base ref '$BASE_REF' not found — skipping."
    echo "  (Pass a base ref explicitly, or fetch it, if this ran outside CI.)"
    return 0
  fi

  local changed adr in_scope=""
  changed=$(git -C "$REPO_ROOT" diff --name-only "$BASE_REF...HEAD")
  [ -z "$changed" ] && { echo "No changes against $BASE_REF."; return 0; }

  while IFS= read -r adr; do
    case "$adr" in
      docs/decisions/ADR-*.md) ;;
      *) continue ;;
    esac
    [ -f "$REPO_ROOT/$adr" ] || continue      # deleted
    adr_becomes_accepted "$BASE_REF" "$adr" && in_scope+="$adr"$'\n'
  done <<< "$changed"

  if [ -z "${in_scope//[$'\n' ]/}" ]; then
    echo "No ADR becomes accepted in this change — ADR-0030 rule 3 does not apply."
    return 0
  fi

  check_links_against_changes "$changed" "$in_scope"
  local errs=$?
  if [ "$errs" -ne 0 ]; then
    echo
    echo "Found $errs ADR(s) violating ADR-0030 rule 3."
    echo "Fix by updating the current-state document the ADR changes, in this change."
    return 1
  fi
  echo "ADR-0030 rule 3: all newly accepted ADRs update a current-state document they name."
  return 0
}

# Sourceable for tests; runs only when executed directly.
#
# Both conditions matter. BASH_SOURCE is unset outside bash, and a `:-$0` fallback
# would make the guard trivially true — sourcing from zsh would run the whole check.
# Require it to be set *and* equal to $0.
if [ -n "${BASH_SOURCE[0]-}" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
