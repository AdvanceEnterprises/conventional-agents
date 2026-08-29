#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

# FS-0027 freshness gate — behavioral suite for scripts/check-freshness.sh.
#
# The gate resolves its target from its own location (ROOT_DIR = script/..),
# so the corpus-level assertions run against the real repo, and the
# negative cases (missing field, invalid date, prose-only occurrence) are
# exercised with throwaway probe files created inside the working tree and
# removed in teardown.

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-freshness.sh"
}

teardown() {
  rm -f "$REPO_ROOT/workflows/_freshness_probe.md"
  rm -f "$REPO_ROOT/guidelines/_freshness_probe.md"
}

# --- Success criteria 5/6: the corpus is green and the npm script exists -----

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
  run env DOC_STALE_DAYS=0 bash "$CHECK"
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
  run bash -c "bash '$CHECK' 2>&1 | grep -c '^STALE: guidelines/' || true"
  # With the default 90d threshold only the two Feb-2026 JS guides are stale.
  [ "$output" = "2" ]
}
