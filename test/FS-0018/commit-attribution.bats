#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

# Known actor emails for this repository. Update this list when adding
# new actors or rotating aliases. See ADR-0018.
ACTOR_EMAILS=(
  "taisden@tais-den.dev"
  "hermes-agent@tais-den.dev"
  "copilot@tais-den.dev"
  "ajoeofalltrades@users.noreply.github.com"
)

# Regex that matches the `Co-authored-by:` trailer naming any known actor.
# GitHub's trailer format is "Co-authored-by: Name <email>".
co_authored_by_pattern() {
  local emails_re
  emails_re="$(printf '%s\n' "${ACTOR_EMAILS[@]}" | paste -sd '|' -)"
  printf 'Co-authored-by:.*(%s)' "$emails_re"
}

# How far back the convention applies. ADR-0018 enforces attribution
# from its own merge commit forward. Use the commit hash of the merge
# that introduces ADR-0018 as the cutoff. Set to the merge commit SHA
# when ADR-0018 lands; leave empty to apply to all reachable commits.
#
# Initial value: empty (test runs against trunk HEAD until the merge
# commit is known). Update this in a follow-up commit once ADR-0018 is
# merged, with a comment noting the merge SHA.
CUTOFF_SHA=""

@test "every commit at and after the cutoff has a known actor email" {
  local range="HEAD"
  if [[ -n "$CUTOFF_SHA" ]]; then
    range="${CUTOFF_SHA}^..HEAD"
  fi
  local commit_emails
  commit_emails="$(git -C "$REPO_ROOT" log "$range" --format='%ae' | sort -u)"
  local unknown
  unknown="$(printf '%s\n' "$commit_emails" | grep -vFx -f <(printf '%s\n' "${ACTOR_EMAILS[@]}"))"
  if [[ -n "$unknown" ]]; then
    echo "commits with unknown author emails in range $range:"
    printf '  %s\n' $unknown
    return 1
  fi
}

@test "every default-email commit at and after the cutoff has a Co-authored-by trailer" {
  # A commit with the default `ajoeofalltrades@users.noreply.github.com`
  # email must include a `Co-authored-by:` trailer naming another actor.
  # Commits with `taisden@tais-den.dev`, `hermes-agent@tais-den.dev`, or
  # `copilot@tais-den.dev` are self-identifying and need no trailer.
  local range="HEAD"
  if [[ -n "$CUTOFF_SHA" ]]; then
    range="${CUTOFF_SHA}^..HEAD"
  fi
  local pattern
  pattern="$(co_authored_by_pattern)"
  local default_email="ajoeofalltrades@users.noreply.github.com"
  local sha email message
  while read -r sha; do
    [[ -z "$sha" ]] && continue
    email="$(git -C "$REPO_ROOT" log -1 --format='%ae' "$sha")"
    if [[ "$email" == "$default_email" ]]; then
      message="$(git -C "$REPO_ROOT" log -1 --format='%B' "$sha")"
      if ! printf '%s\n' "$message" | rg -F -q -- "$pattern"; then
        echo "commit $sha uses default email but has no Co-authored-by trailer:"
        git -C "$REPO_ROOT" log -1 --format='  %s' "$sha"
        return 1
      fi
    fi
  done < <(git -C "$REPO_ROOT" log "$range" --format='%H')
}

@test "workflow doc teaches the single-identity convention" {
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Single-identity workflow with agent co-attribution"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "hermes-agent@tais-den.dev"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Co-authored-by:"
}

@test "skill teaches the single-identity convention" {
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "Single-Identity Workflow"
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "hermes-agent@tais-den.dev"
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "Co-authored-by:"
}

@test "ADR-0018 exists with proposed status" {
  assert_file_exists "$REPO_ROOT/docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md"
  assert_file_contains "$REPO_ROOT/docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md" "status: proposed"
}

@test "ADR-0011 cross-references ADR-0018" {
  assert_file_contains "$REPO_ROOT/docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md" "ADR-0018"
}