#!/usr/bin/env bats

load "helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "config exists and matches MADR baseline" {
  local config="$REPO_ROOT/docs/decisions/.markdownlint.yml"
  local madr="$REPO_ROOT/vendor/madr/.markdownlint.yml"
  assert_file_exists "$config"
  assert_file_exists "$madr"
  assert_files_equal "$config" "$madr"
}

@test "config disables MD013 and MD024" {
  local config="$REPO_ROOT/docs/decisions/.markdownlint.yml"
  assert_file_exists "$config"
  assert_file_contains "$config" "MD013: false"
  assert_file_contains "$config" "MD024: false"
}

@test "workflow exists and pins markdownlint-cli2 action" {
  local workflow="$REPO_ROOT/.github/workflows/lint-adrs.yml"
  assert_file_exists "$workflow"
  assert_file_contains "$workflow" "markdownlint-cli2-action@v17"
}

@test "workflow targets trunk and ADR globs only" {
  local workflow="$REPO_ROOT/.github/workflows/lint-adrs.yml"
  assert_file_exists "$workflow"
  assert_file_contains "$workflow" "trunk"
  assert_file_contains "$workflow" "docs/decisions/ADR-*.md"
  assert_file_contains "$workflow" "docs/decisions/.markdownlint.yml"
}

@test "package.json defines markdownlint-cli2 and lint:adrs script" {
  local pkg="$REPO_ROOT/package.json"
  assert_file_exists "$pkg"
  assert_file_contains "$pkg" "\"markdownlint-cli2\""
  assert_file_contains "$pkg" "\"lint:adrs\""
  assert_file_contains "$pkg" "markdownlint-cli2 \\\"docs/decisions/ADR-\\*.md\\\""
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
