#!/usr/bin/env bats
# FS-0032 — validation reproducibility contract (#132).
# These tests use scratch Git repositories and fake commands. They never invoke
# GitHub, fetch a remote, or mutate the framework checkout.

load "../FS-0001/helpers.bash"
set -euo pipefail

setup() {
  REAL_REPO_ROOT="$(repo_root)"
  RUNNER="$REAL_REPO_ROOT/scripts/run-validation.sh"
  RUN_BATS="$REAL_REPO_ROOT/scripts/run-bats.sh"
  CROSS_REPO="$REAL_REPO_ROOT/scripts/cross-repo-lint.sh"
  WORKFLOW="$REAL_REPO_ROOT/.github/workflows/lint-docs.yml"
  SCRIPTS_README="$REAL_REPO_ROOT/scripts/README.md"
}

make_clean_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "FS-0032 Fixture"
  git -C "$repo" config user.email "fs-0032@example.invalid"
  printf '%s\n' "fixture" > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "fixture"
}

@test "validate: runs the five commands in order through one entry point" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local trace="$BATS_TEST_TMPDIR/npm.trace"
  local log="$BATS_TEST_TMPDIR/validation.log"
  mkdir -p "$fakebin"
  make_clean_repo "$repo"
  cat > "$fakebin/npm" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$*" >> "$trace"
exit 0
EOF
  chmod +x "$fakebin/npm"

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    CA_VALIDATION_LOG="$log" \
    CA_VALIDATION_TEST_TIMEOUT=5 \
    CA_VALIDATION_GATE_TIMEOUT=5 \
    CA_VALIDATION_BUDGET=30 \
    BATS_SUITE_TIMEOUT=1 \
    COMMIT_RANGE=HEAD..HEAD \
    PATH="$fakebin:$PATH" \
    bash "$RUNNER"

  [ "$status" -eq 0 ]
  [ "$(wc -l < "$trace" | tr -d ' ')" -eq 5 ]
  [ "$(sed -n '1p' "$trace")" = "test" ]
  [ "$(sed -n '2p' "$trace")" = "run lint:docs" ]
  [ "$(sed -n '3p' "$trace")" = "run check:status" ]
  [ "$(sed -n '4p' "$trace")" = "run check:freshness" ]
  [ "$(sed -n '5p' "$trace")" = "run lint:cross-repo" ]
  assert_file_contains "$log" "VALIDATION PASS"
  assert_file_contains "$log" "STEP 1/5 PASS npm test"
}

@test "validate: rejects an invalid timeout before executing a command" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local trace="$BATS_TEST_TMPDIR/npm.trace"
  mkdir -p "$fakebin"
  make_clean_repo "$repo"
  cat > "$fakebin/npm" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "called" >> "$trace"
exit 0
EOF
  chmod +x "$fakebin/npm"

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    CA_VALIDATION_TEST_TIMEOUT=not-a-number \
    PATH="$fakebin:$PATH" \
    bash "$RUNNER"

  [ "$status" -eq 2 ]
  [[ "$output" == *"CA_VALIDATION_TEST_TIMEOUT must be a positive integer"* ]]
  [ ! -s "$trace" ]
}

@test "validate: blocks network-capable commands in the canonical environment" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fakebin"
  make_clean_repo "$repo"
  cat > "$fakebin/npm" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "run" ] && [ "$2" = "lint:cross-repo" ]; then
  gh --version
  exit $?
fi
exit 0
EOF
  chmod +x "$fakebin/npm"

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    CA_VALIDATION_LOG="$BATS_TEST_TMPDIR/validation.log" \
    CA_VALIDATION_TEST_TIMEOUT=5 \
    CA_VALIDATION_GATE_TIMEOUT=5 \
    CA_VALIDATION_BUDGET=30 \
    COMMIT_RANGE=HEAD..HEAD \
    PATH="$fakebin:$PATH" \
    bash "$RUNNER"

  [ "$status" -ne 0 ]
  [[ "$output" == *"network-capable command is disabled"* ]]
}

@test "run-bats: reports per-suite progress and fails closed on timeout" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fakebin" "$repo/test"
  printf '%s\n' '#!/usr/bin/env bats' > "$repo/test/hangs.bats"
  cat > "$fakebin/bats" <<'EOF'
#!/usr/bin/env bash
sleep 5
EOF
  chmod +x "$fakebin/bats"
  make_clean_repo "$repo"
  # make_clean_repo commits README only; the suite is intentionally untracked
  # because run-bats does not require a clean target.

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    BATS_SUITE_TIMEOUT=1 \
    PATH="$fakebin:$PATH" \
    bash "$RUN_BATS"

  [ "$status" -ne 0 ]
  [[ "$output" == *"BATS 1/1 BEGIN test/hangs.bats"* ]]
  [[ "$output" == *"BATS 1/1 TIMEOUT test/hangs.bats"* ]]
}

@test "cross-repo-lint: does not fetch and fails on an unavailable range" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local git_trace="$BATS_TEST_TMPDIR/git.trace"
  local real_git
  real_git="$(command -v git)"
  mkdir -p "$fakebin"
  make_clean_repo "$repo"
  cat > "$fakebin/git" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$*" >> "$git_trace"
exec "$real_git" "\$@"
EOF
  chmod +x "$fakebin/git"

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    COMMIT_RANGE=missing..also-missing \
    PATH="$fakebin:$PATH" \
    bash "$CROSS_REPO"

  [ "$status" -ne 0 ]
  [[ "$output" == *"commit range missing..also-missing is unavailable locally"* ]]
  ! grep -F -q " fetch " "$git_trace"
}

@test "CI: invokes the canonical runner with full history and pinned dependencies" {
  assert_file_contains "$WORKFLOW" "validation:"
  assert_file_contains "$WORKFLOW" "fetch-depth: 0"
  assert_file_contains "$WORKFLOW" "npm ci --ignore-scripts"
  assert_file_contains "$WORKFLOW" "run: npm run validate"
  assert_file_contains "$WORKFLOW" "COMMIT_RANGE:"
}

@test "documentation: records the reproducibility contract and fail-closed defaults" {
  assert_file_contains "$SCRIPTS_README" "run-validation.sh"
  assert_file_contains "$SCRIPTS_README" "CA_VALIDATION_BUDGET"
  assert_file_contains "$SCRIPTS_README" "BATS_SUITE_TIMEOUT"
  assert_file_contains "$SCRIPTS_README" "never fetches a remote"
  assert_file_contains "$SCRIPTS_README" "npm run validate"
}

@test "baseline: records a revision, timings, log, and final verdict" {
  local baseline="$REAL_REPO_ROOT/docs/validation-baseline.md"
  local log="$REAL_REPO_ROOT/docs/validation-baseline.log"
  assert_file_exists "$baseline"
  assert_file_exists "$log"
  assert_file_contains "$baseline" "Revision"
  assert_file_contains "$baseline" "Timing"
  assert_file_contains "$baseline" "validation-baseline.log"
  assert_file_contains "$log" "VALIDATION PASS"
  assert_file_contains "$log" "BATS PASS"
}
