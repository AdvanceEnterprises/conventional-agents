#!/usr/bin/env bats
# FS-0039 — validation reproducibility contract (#132).
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
  git -C "$repo" config user.name "FS-0039 Fixture"
  git -C "$repo" config user.email "fs-0039@example.invalid"
  printf '%s\n' "fixture" > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "fixture"
}

make_fake_npm() {
  local fakebin="$1"
  mkdir -p "$fakebin"
  cat > "$fakebin/npm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$PWD|$*" >> "$CA_REPRO_TRACE_DIR/$(basename "$PWD").trace"
exit 0
EOF
  chmod +x "$fakebin/npm"
}

run_fixture_validation() {
  local repo="$1" log="$2" fakebin="$3" trace_dir="$4"
  env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    CA_VALIDATION_LOG="$log" \
    CA_VALIDATION_TEST_TIMEOUT=5 \
    CA_VALIDATION_GATE_TIMEOUT=5 \
    CA_VALIDATION_BUDGET=30 \
    BATS_SUITE_TIMEOUT=1 \
    CA_REPRO_TRACE_DIR="$trace_dir" \
    COMMIT_RANGE=HEAD..HEAD \
    PATH="$fakebin:$PATH" \
    bash "$RUNNER"
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

@test "reproducibility: serial runs keep the verdict and target clean" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local trace_dir="$BATS_TEST_TMPDIR/traces"
  local log_a="$BATS_TEST_TMPDIR/serial-a.log"
  local log_b="$BATS_TEST_TMPDIR/serial-b.log"
  mkdir -p "$trace_dir"
  make_clean_repo "$repo"
  make_fake_npm "$fakebin"

  run run_fixture_validation "$repo" "$log_a" "$fakebin" "$trace_dir"
  [ "$status" -eq 0 ]
  run run_fixture_validation "$repo" "$log_b" "$fakebin" "$trace_dir"
  [ "$status" -eq 0 ]

  assert_file_contains "$log_a" "VALIDATION PASS"
  assert_file_contains "$log_b" "VALIDATION PASS"
  [ "$(wc -l < "$trace_dir/$(basename "$repo").trace" | tr -d ' ')" -eq 10 ]
  [ -z "$(git -C "$repo" status --porcelain --untracked-files=all)" ]
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

@test "validate: never invokes a network-capable git subcommand" {
  local repo="$BATS_TEST_TMPDIR/repo"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local trace="$BATS_TEST_TMPDIR/git.trace"
  local log="$BATS_TEST_TMPDIR/validation.log"
  local real_git
  real_git="$(command -v git)"
  mkdir -p "$fakebin"
  make_clean_repo "$repo"
  cat > "$fakebin/npm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$fakebin/npm"
  # Record every git invocation the runner makes and fail closed on the
  # network-capable verbs. The git stubs in the sandbox cover `gh`/`curl`/…,
  # but git itself can fetch remotes, so the hermeticity claim needs its own
  # assertion at the acceptance surface.
  # NOTE: the heredoc delimiter is unquoted on purpose — $trace and $real_git
  # are evaluated at stub-write time and baked into the stub. Both are assigned
  # above; if you reorder this block, keep the assignments before the heredoc.
  cat > "$fakebin/git" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$trace"
case "\$1" in
  fetch|pull|push|ls-remote|clone|remote) exit 86 ;;
esac
exec "$real_git" "\$@"
EOF
  chmod +x "$fakebin/git"

  run env -u RUN_BATS_ACTIVE \
    CA_TARGET_REPO="$repo" \
    CA_VALIDATION_LOG="$log" \
    CA_VALIDATION_TEST_TIMEOUT=5 \
    CA_VALIDATION_GATE_TIMEOUT=5 \
    CA_VALIDATION_BUDGET=30 \
    COMMIT_RANGE=HEAD..HEAD \
    PATH="$fakebin:$PATH" \
    bash "$RUNNER"

  [ "$status" -eq 0 ]
  assert_file_contains "$log" "VALIDATION PASS"
  assert_file_exists "$trace"
  if grep -E -q '^(fetch|pull|push|ls-remote|clone|remote)( |$)' "$trace"; then
    echo "runner invoked a network-capable git subcommand:"
    cat "$trace"
    return 1
  fi
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

@test "reproducibility: concurrent fresh checkouts do not share state" {
  local source="$BATS_TEST_TMPDIR/source"
  local repo_a="$BATS_TEST_TMPDIR/repo-a"
  local repo_b="$BATS_TEST_TMPDIR/repo-b"
  local fakebin="$BATS_TEST_TMPDIR/bin"
  local trace_dir="$BATS_TEST_TMPDIR/traces"
  local log_a="$BATS_TEST_TMPDIR/concurrent-a.log"
  local log_b="$BATS_TEST_TMPDIR/concurrent-b.log"
  local output_a="$BATS_TEST_TMPDIR/concurrent-a.out"
  local output_b="$BATS_TEST_TMPDIR/concurrent-b.out"
  local pid_a pid_b rc_a rc_b
  mkdir -p "$trace_dir"
  make_clean_repo "$source"
  git clone -q --no-hardlinks "$source" "$repo_a"
  git clone -q --no-hardlinks "$source" "$repo_b"
  make_fake_npm "$fakebin"

  run_fixture_validation "$repo_a" "$log_a" "$fakebin" "$trace_dir" >"$output_a" 2>&1 &
  pid_a=$!
  run_fixture_validation "$repo_b" "$log_b" "$fakebin" "$trace_dir" >"$output_b" 2>&1 &
  pid_b=$!
  if wait "$pid_a"; then rc_a=0; else rc_a=$?; fi
  if wait "$pid_b"; then rc_b=0; else rc_b=$?; fi

  [ "$rc_a" -eq 0 ]
  [ "$rc_b" -eq 0 ]
  assert_file_contains "$log_a" "VALIDATION PASS"
  assert_file_contains "$log_b" "VALIDATION PASS"
  assert_file_contains "$output_a" "STEP 5/5 PASS npm run lint:cross-repo"
  assert_file_contains "$output_b" "STEP 5/5 PASS npm run lint:cross-repo"
  [ "$(wc -l < "$trace_dir/$(basename "$repo_a").trace" | tr -d ' ')" -eq 5 ]
  [ "$(wc -l < "$trace_dir/$(basename "$repo_b").trace" | tr -d ' ')" -eq 5 ]
  [ -z "$(git -C "$repo_a" status --porcelain --untracked-files=all)" ]
  [ -z "$(git -C "$repo_b" status --porcelain --untracked-files=all)" ]
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
