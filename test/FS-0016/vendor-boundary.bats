#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "only vendor/madr remains as framework submodule" {
  local submodules
  submodules="$(git -C "$REPO_ROOT" submodule status | awk '{print $2}')"
  assert_file_contains <(echo "$submodules") "vendor/madr"
  ! echo "$submodules" | grep -q "vendor/conventional-commits"
  ! echo "$submodules" | grep -q "vendor/keep-a-changelog"
  ! echo "$submodules" | grep -q "vendor/arc42-template"
}

@test "no consumer-facing file references concrete nested vendor submodule paths" {
  local files=(
    "$REPO_ROOT/README.md"
    "$REPO_ROOT/AGENTS.md"
    "$REPO_ROOT/INTEGRATION.md"
    "$REPO_ROOT/skills/framework-consumer-integration/SKILL.md"
  )
  for file in "${files[@]}"; do
    assert_file_exists "$file"
    ! rg -F "vendor/conventional-agents/vendor/conventional-commits" "$file" >/dev/null 2>&1
    ! rg -F "vendor/conventional-agents/vendor/keep-a-changelog" "$file" >/dev/null 2>&1
    ! rg -F "vendor/conventional-agents/vendor/arc42-template" "$file" >/dev/null 2>&1
  done
}

@test "framework docs cite upstream URLs for removed submodules" {
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "https://www.conventionalcommits.org/"
  assert_file_contains "$REPO_ROOT/workflows/versioning-and-releases.md" "https://keepachangelog.com"
  assert_file_contains "$REPO_ROOT/README.md" "https://arc42.org/"
}
