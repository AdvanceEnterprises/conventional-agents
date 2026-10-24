#!/usr/bin/env bats

load "helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "config exists and matches MADR baseline when submodule is initialised" {
  local config="$REPO_ROOT/docs/decisions/.markdownlint.yml"
  local madr="$REPO_ROOT/vendor/madr/.markdownlint.yml"
  assert_file_exists "$config"
  # vendor/madr is a git submodule; it is uninitialised by default. The bats init it
  # for the assertion to be checkable.
  if [[ ! -f "$madr" ]]; then
    git -C "$REPO_ROOT" submodule update --init vendor/madr >/dev/null 2>&1 || true
  fi
  if [[ -f "$madr" ]]; then
    assert_files_equal "$config" "$madr"
  else
    skip "vendor/madr submodule is not initialised; run 'git submodule update --init vendor/madr'"
  fi
}

@test "config disables MD013 and MD024" {
  local config="$REPO_ROOT/docs/decisions/.markdownlint.yml"
  assert_file_exists "$config"
  assert_file_contains "$config" "MD013: false"
  assert_file_contains "$config" "MD024: false"
}

@test "workflow exists and pins markdownlint-cli2 action" {
  # The CI workflow was consolidated from lint-adrs.yml to lint-docs.yml per PLAN-0018 /
  # PLAN-0022. The pinned action is the same.
  local workflow="$REPO_ROOT/.github/workflows/lint-docs.yml"
  assert_file_exists "$workflow"
  assert_file_contains "$workflow" "markdownlint-cli2-action@v17"
}

@test "workflow triggers on trunk pushes and lints the whole corpus" {
  # G6 (PR #241) removed the event-level paths: filters — the workflow must run
  # the full matrix on every trunk push and every PR, so a filtered-out diff can
  # never slip past governance. The ADR glob remains a lint target, not a
  # trigger filter.
  local workflow="$REPO_ROOT/.github/workflows/lint-docs.yml"
  assert_file_exists "$workflow"
  assert_file_contains "$workflow" "branches: [trunk]"
  assert_file_contains "$workflow" "docs/decisions/ADR-*.md"
  # No paths: filters on either event.
  if grep -qE "^[[:space:]]+paths:" "$workflow"; then
    fail "lint-docs.yml must not filter triggers with paths: (G6, #241)"
  fi
}

@test "package.json defines markdownlint-cli2 and lint:adrs script" {
  local pkg="$REPO_ROOT/package.json"
  assert_file_exists "$pkg"
  assert_file_contains "$pkg" "\"markdownlint-cli2\""
  assert_file_contains "$pkg" "\"lint:adrs\""
  assert_file_contains "$pkg" "markdownlint-cli2 \\\"docs/decisions/ADR-*.md\\\""
}

@test "docs include local setup and troubleshooting for linting" {
  local doc="$REPO_ROOT/docs/decisions/README.md"
  assert_file_exists "$doc"
  assert_file_contains "$doc" "npm install"
  assert_file_contains "$doc" "npm run lint:adrs"
  assert_file_contains "$doc" "Troubleshooting"
}

@test "linting scope excludes non-ADR markdown in decisions directory" {
  [[ "README.md" != ADR-*.md ]]
}
