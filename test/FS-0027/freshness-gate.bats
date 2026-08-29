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
# evaluation date) so they do not depend on the wall clock. The pinned epoch is
# 2026-08-30 00:00 UTC — shortly after the PR was authored — under which the
# two Feb-2026 JS guides are stale (203d) and the Jun-2026 JS testing guide
# (83d) is not, keeping the expected counts stable.

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
  # Pinned evaluation date (2026-08-30): only the two Feb-2026 JS guides are
  # stale under the default 90d threshold.
  run env DOC_FRESHNESS_NOW=1788048000 bash -c "bash '$CHECK' 2>&1 | grep -c '^STALE: guidelines/' || true"
  [ "$output" = "2" ]
}
