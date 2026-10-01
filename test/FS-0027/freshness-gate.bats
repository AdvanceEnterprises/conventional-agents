#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

# FS-0027 freshness gate — behavioral suite for scripts/check-freshness.sh.
#
# The gate resolves its target from the caller's working directory per
# FS-0024/ADR-0033 (REPO_ROOT = git rev-parse --show-toplevel, CA_TARGET_REPO
# override), so the corpus-level assertions run against the real repo, and the
# negative cases (missing field, invalid date, prose-only occurrence) are
# exercised with throwaway probe files created inside the working tree and
# removed in teardown.
#
# Determinism: the stale-count assertions pin DOC_FRESHNESS_NOW (the gate's
# evaluation date) so they do not depend on the wall clock. Corpus-level stale
# counts are asserted with throwaway probe files (created in the test, removed
# in teardown) rather than pinned corpus dates, so the suite does not break
# when a governed doc's updated: date is refreshed.

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-freshness.sh"
}

teardown() {
  # Remove any probe file the suite may have created, wherever it lives.
  find "$REPO_ROOT/workflows" "$REPO_ROOT/guidelines" -name '_*_probe.md' -delete 2>/dev/null || true
}

# --- Success criteria 5 and 6: the corpus is green and the npm script exists --

@test "freshness: every governed doc under workflows/ and guidelines/ carries updated: (corpus green)" {
  run bash "$CHECK"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "check-freshness: OK"
}

@test "freshness: npm run check:freshness is registered" {
  assert_file_contains "$REPO_ROOT/package.json" '"check:freshness"'
}

# --- Success criterion 1: missing updated: is a hard failure -----------------

@test "freshness: a governed doc without updated: fails hard and names the file" {
  printf '# Probe\n\nProse body.\n' > "$REPO_ROOT/workflows/_freshness_probe.md"
  run bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "workflows/_freshness_probe.md"
  echo "$output" | grep -qF "ERROR"
}

# --- Success criterion 2: an invalid date fails hard -------------------------

@test "freshness: an unparseable updated: date fails hard and names the file" {
  printf -- '---\nupdated: 2026-13-99\n---\n\n# Probe\n' > "$REPO_ROOT/workflows/_freshness_probe.md"
  run bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "workflows/_freshness_probe.md"
}

# --- Success criterion 8: prose-only updated: is not the field ----------------

@test "freshness: updated: appearing in prose outside the front-matter block is not accepted" {
  printf -- '---\nfront_matter: true\n---\n\nupdated: 2026-01-01\n' > "$REPO_ROOT/workflows/_freshness_probe.md"
  run bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "workflows/_freshness_probe.md"
}

# --- Success criterion 3: soft stale report ----------------------------------

@test "freshness: stale docs are reported with path and age but do not fail the run" {
  run env DOC_STALE_DAYS=0 DOC_FRESHNESS_NOW=1788048000 bash "$CHECK"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "STALE: "
  echo "$output" | grep -qF "threshold 0d"
}

# --- Success criterion 4: DOC_STALE_DAYS validation --------------------------

@test "freshness: non-integer DOC_STALE_DAYS is rejected" {
  run env DOC_STALE_DAYS=abc bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "DOC_STALE_DAYS"
}

@test "freshness: negative DOC_STALE_DAYS is rejected" {
  run env DOC_STALE_DAYS=-5 bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "DOC_STALE_DAYS"
}

# --- Scope: README indexes excluded, guidelines recursed ---------------------

@test "freshness: README index files are excluded from the gate" {
  run bash "$CHECK"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "README\.md.*(missing|invalid|no .updated.)"
}

@test "freshness: guidelines subdirectories are included recursively" {
  run bash "$CHECK"
  [ "$status" -eq 0 ]
  # 10 guideline files are checked (bash/JS/Python guides + ROLE_CONTRACT).
  # Probe-file based: a stale probe in a guidelines subdirectory must be
  # reported, proving recursion without pinning corpus dates (corpus stale
  # counts change whenever a governed doc's updated: date is refreshed).
  printf -- '---\nupdated: 2020-01-01\n---\n\n# Probe\n' > "$REPO_ROOT/guidelines/javascript/_freshness_probe.md"
  run env DOC_FRESHNESS_NOW=1788048000 bash "$CHECK"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "STALE: guidelines/javascript/_freshness_probe.md"
}

# --- Target resolution: non-git cwd fails loudly (issue #199) -----------------

@test "target_resolution: running outside a git work tree fails loudly instead of certifying nothing (issue #199)" {
  # Pre-fix, REPO_ROOT fell back to `pwd` outside any repository, both governed
  # directories "didn't exist", the empty-corpus branch printed its message and
  # the gate exited 0 — a run that checked nothing received green (the #194
  # fail-open class, one script over). A CI job or maintainer in the wrong
  # working directory must see a loud error instead.
  local nongit="$BATS_TEST_TMPDIR/not-a-repo"
  mkdir -p "$nongit"

  run bash -c "cd '$nongit' && bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "not inside a git working tree"
  ! echo "$output" | grep -qF "no governed docs found"
}

@test "target_resolution: a work tree with no governed docs still reports empty corpus" {
  # The distinguishing positive control (issue #199): a fresh consumer
  # repository mid-adoption is a git work tree that genuinely has no
  # workflows/ or guidelines/ — the guard must not reject it, and the
  # empty-corpus message (exit 0) stays the documented behavior for it.
  local fresh="$BATS_TEST_TMPDIR/fresh-repo"
  mkdir -p "$fresh"
  ( cd "$fresh" && git init -q )

  run bash -c "cd '$fresh' && bash '$CHECK'"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "no governed docs found"
}

@test "target_resolution: CA_TARGET_REPO pointing at a non-repo dir fails loudly" {
  # The CA_TARGET_REPO branch of the same guard (issue #199): the override
  # canonicalizes to a directory that is not a repository, and the guard must
  # reject it even when the caller's own cwd is inside a work tree.
  local nongit="$BATS_TEST_TMPDIR/not-a-repo"
  mkdir -p "$nongit"

  run bash -c "cd '$REPO_ROOT' && CA_TARGET_REPO='$nongit' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "not inside a git working tree"
  ! echo "$output" | grep -qF "no governed docs found"
}

@test "target_resolution: a bare git repository is rejected with its own message" {
  # MM3 round-B observation (issue #199): a bare repository IS a git repository,
  # just one without a working tree — the error must say so rather than reusing
  # the generic non-git wording, or a maintainer diagnosing the failure is
  # misdirected.
  local bare="$BATS_TEST_TMPDIR/bare.git"
  ( cd "$BATS_TEST_TMPDIR" && git init -q --bare "$bare" )

  run bash -c "cd '$REPO_ROOT' && CA_TARGET_REPO='$bare' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "bare git repository"
  ! echo "$output" | grep -qF "not inside a git working tree"
}

@test "target_resolution: a missing git binary is named as such, not blamed on the directory" {
  # MM3 round-B observation (issue #199): with git absent from PATH the guard's
  # `2>/dev/null` probes return empty and the directory gets blamed for an
  # environment problem. The environment check must pre-empt that.
  # Copilot review, PR #200: the fake PATH must keep the tools the script uses
  # BEFORE the git check reachable (`dirname` at the top of the script), or the
  # run emits an unrelated `dirname: command not found` that the assertion
  # would sail past; and the assertion must reject the generic work-tree blame
  # so this case isolates the diagnostic it names.
  local fakebin="$BATS_TEST_TMPDIR/fakebin"
  mkdir -p "$fakebin"
  ln -s "$(command -v bash)" "$fakebin/bash"
  ln -s "$(command -v dirname)" "$fakebin/dirname"

  run env PATH="$fakebin" bash "$CHECK"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "git' was not found on PATH"
  ! echo "$output" | grep -qF "not inside a git working tree"
  ! echo "$output" | grep -qF "command not found"
}
