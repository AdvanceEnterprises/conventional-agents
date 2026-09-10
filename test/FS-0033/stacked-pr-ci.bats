#!/usr/bin/env bats
# FS-0033 — governance CI on stacked and non-trunk pull requests.
#
# FS-0033 declares test_required: true. The implementation is largely
# self-evidencing (the workflow change is the test), but this suite pins the
# two conventions that a future editor could silently regress:
#   1. the pull_request trigger carries NO base-branch filter (stacked PRs
#      must receive the same governance signal as trunk-based PRs), and
#   2. lint-cross-repo resolves the PR's actual base ref (github.base_ref)
#      rather than hardcoding trunk — the fetch step and the COMMIT_RANGE
#      export must agree on which ref is the base.
#
# These are static assertions against .github/workflows/lint-docs.yml, the
# same pattern FS-0022's gate-coverage suite uses for its CI-job checks.

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CI="$REPO_ROOT/.github/workflows/lint-docs.yml"
  assert_file_exists "$CI"
}

@test "fs0033: pull_request trigger carries no base-branch filter" {
  # The only branches: filter in the file must belong to the push trigger —
  # every branches: line must appear before the pull_request: trigger.
  local pr_line branches_lines
  pr_line=$(grep -n "^  pull_request:" "$CI" | head -1 | cut -d: -f1)
  [ -n "$pr_line" ] || skip "pull_request trigger not found"
  branches_lines=$(grep -n "branches:" "$CI" || true)
  [ -n "$branches_lines" ] || skip "no branches: filter found at all"
  while IFS= read -r line; do
    local lineno
    lineno=$(echo "$line" | cut -d: -f1)
    [ "$lineno" -lt "$pr_line" ]
  done <<< "$branches_lines"
}

@test "fs0033: lint-cross-repo fetches the base ref, not only trunk" {
  # The fetch step must reference github.base_ref for pull_request events.
  assert_file_contains "$CI" 'git fetch --no-tags origin "${{ github.base_ref }}"'
}

@test "fs0033: lint-cross-repo COMMIT_RANGE resolves against the fetched base" {
  # The COMMIT_RANGE export must use the same base ref the fetch step pulls.
  assert_file_contains "$CI" 'COMMIT_RANGE="origin/${{ github.base_ref }}..HEAD"'
}

@test "fs0033: no pull_request_target and no secrets in the workflow" {
  # Fork-PR safety (FS-0033 requirement 2): the workflow must not use
  # pull_request_target or reference secrets, so removing the base-branch
  # filter cannot broaden secret exposure.
  ! grep -q "pull_request_target" "$CI"
  ! grep -qE "secrets\." "$CI"
}

@test "fs0033: skill documents the stacked-PR governance expectation" {
  local skill="$REPO_ROOT/skills/gh-pr-workflow/SKILL.md"
  assert_file_exists "$skill"
  assert_file_contains "$skill" "Stacked PRs (base is a non-\`trunk\` branch) run the same governance chain"
  assert_file_contains "$skill" "github.base_ref"
}
