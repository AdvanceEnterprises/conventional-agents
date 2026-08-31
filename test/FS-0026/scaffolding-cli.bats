#!/usr/bin/env bats
# FS-0026 — ADR and PLAN scaffolding CLI (scripts/new-adr.sh, scripts/new-plan.sh).
#
# FS-0026 declares test_required: true and the CLI shipped in PRs #88/#92, but
# no suite existed — the six success criteria were verified only by manual
# invocation. This suite covers all six, plus argument-validation edges.
#
# Isolation: every test builds a scratch repo under BATS_TEST_TMPDIR
# (bats-provided, auto-cleaned per test) and COPIES the scripts into it.
# Copying, not symlinking, matters: new-adr.sh resolves its docs directory
# from FRAMEWORK_HOME (the script's own location), so a symlinked copy would
# write into the real repository's docs/decisions. new-plan.sh resolves from
# the caller's cwd (FS-0024/ADR-0033), so tests run it from the scratch root.

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  NEW_ADR="$REPO_ROOT/scripts/new-adr.sh"
  NEW_PLAN="$REPO_ROOT/scripts/new-plan.sh"
}

# --- fixture helpers ----------------------------------------------------------

# Scratch repo with the two scaffolder scripts copied in and a docs/ skeleton.
build_scratch() {
  local scratch="$1"
  mkdir -p "$scratch/scripts" "$scratch/docs/decisions" "$scratch/docs/change-plans"
  cp "$NEW_ADR" "$scratch/scripts/new-adr.sh"
  cp "$NEW_PLAN" "$scratch/scripts/new-plan.sh"
  ( cd "$scratch" && git init -q )
}

# A minimal ADR fixture with multi-line related_specs/related_adrs lists and a
# "### Consequences" subsection under "## Decision Outcome" (the two forms
# FS-0026 criterion 3 requires new-plan to handle).
write_adr_fixture() {
  local scratch="$1"
  cat > "$scratch/docs/decisions/ADR-0034-scratch-fixture.md" <<'EOF'
---
type: adr
id: ADR-0034
status: proposed
title: Scratch fixture decision
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
  - FS-0024
related_adrs:
  - ADR-0033
superseded_by: null
created: 2026-08-31
updated: 2026-08-31
---

# ADR-0034: Scratch fixture decision

## Status

- Proposed

## Context and Problem Statement

Fixture context for the scaffolding CLI tests.

## Decision Outcome

Chosen option: "use the fixture"

### Consequences

Fixture consequence line one.
Fixture consequence line two.

## Validation

Fixture validation.
EOF
}

# --- criterion 1: new:adr creates a conformant ADR ----------------------------

@test "scaffolding: new:adr creates ADR with proposed status, today's dates, and standard headings" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"
  local today
  today=$(date +%Y-%m-%d)

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --title 'Test Decision'"
  [ "$status" -eq 0 ]

  local created
  created=$(ls "$scratch/docs/decisions"/ADR-0001-*.md 2>/dev/null | head -1)
  [ -n "$created" ]
  assert_file_contains "$created" "type: adr"
  assert_file_contains "$created" "id: ADR-0001"
  assert_file_contains "$created" "status: proposed"
  assert_file_contains "$created" "created: $today"
  assert_file_contains "$created" "updated: $today"
  assert_file_contains "$created" "## Context and Problem Statement"
  assert_file_contains "$created" "## Decision Outcome"
  assert_file_contains "$created" "## Validation"
}

# --- criterion 2: dry-run writes nothing --------------------------------------

@test "scaffolding: new:adr --dry-run prints content and writes no file" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --dry-run --title 'Preview Only'"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "=== DRY RUN — ADR content preview ==="
  echo "$output" | grep -qF "File: ADR-0001-preview-only.md"
  echo "$output" | grep -qF "status: proposed"

  local count
  count=$(find "$scratch/docs/decisions" -name 'ADR-*.md' -type f | wc -l | tr -d ' ')
  [ "$count" -eq 0 ]
}

# --- criterion 3: new:plan carries references and consequences ----------------

@test "scaffolding: new:plan carries related_specs, related_adrs, and Consequences from the ADR" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"
  write_adr_fixture "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-plan.sh --adr docs/decisions/ADR-0034-scratch-fixture.md"
  [ "$status" -eq 0 ]

  local plan
  plan=$(ls "$scratch/docs/change-plans"/PLAN-0001-*.md 2>/dev/null | head -1)
  [ -n "$plan" ]
  assert_file_contains "$plan" "type: change-plan"
  assert_file_contains "$plan" "status: draft"
  # Multi-line YAML list form carried over from the ADR frontmatter
  assert_file_contains "$plan" "  - FS-0018"
  assert_file_contains "$plan" "  - FS-0024"
  assert_file_contains "$plan" "  - ADR-0033"
  # Consequences subsection (### under ## Decision Outcome) carried into Rationale
  assert_file_contains "$plan" "Fixture consequence line one."
  assert_file_contains "$plan" "Fixture consequence line two."
}

# --- criterion 4: trailing --title errors clearly ------------------------------

@test "scaffolding: new:adr --title as last argument reports a clear error" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --title"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "ERROR: --title requires a value"
}

# --- criterion 5: quotes and apostrophes preserved verbatim --------------------

@test "scaffolding: new:adr preserves quotes and apostrophes in the title verbatim" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --title \"Don't Stop 'Til You Get Enough\""
  [ "$status" -eq 0 ]

  local created
  created=$(ls "$scratch/docs/decisions"/ADR-0001-*.md 2>/dev/null | head -1)
  [ -n "$created" ]
  assert_file_contains "$created" "Don't Stop 'Til You Get Enough"
  # No backslash-escape artifacts
  if grep -qF "Don\\'t" "$created"; then
    echo "FAIL: title was backslash-escaped"
    return 1
  fi
}

# --- criterion 6: next-ADR number is base-10 with leading zeros ----------------

@test "scaffolding: next ADR number is base-10 (ADR-0008 -> ADR-0009, not ADR-00081)" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"
  # Seed the highest existing ADR at 0008 to exercise leading-zero parsing.
  printf -- '---\ntype: adr\nid: ADR-0008\nstatus: proposed\ntitle: Seed\n---\n' \
    > "$scratch/docs/decisions/ADR-0008-seed.md"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --title 'Next Number'"
  [ "$status" -eq 0 ]

  [ -f "$scratch/docs/decisions/ADR-0009-next-number.md" ]
  [ ! -f "$scratch/docs/decisions/ADR-00081-next-number.md" ]
}

# --- argument validation edges ------------------------------------------------

@test "scaffolding: new:adr rejects unknown arguments with exit 2" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --bogus"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "Unknown arg: --bogus"
}

@test "scaffolding: new:adr requires a title" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-adr.sh --dry-run"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "ERROR: Title is required."
}

@test "scaffolding: new:plan rejects a missing ADR file" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-plan.sh --adr docs/decisions/does-not-exist.md"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "ERROR: ADR file not found"
}

@test "scaffolding: new:plan validates --number format" {
  local scratch="$BATS_TEST_TMPDIR/scratch"
  build_scratch "$scratch"
  write_adr_fixture "$scratch"

  run bash -c "cd '$scratch' && bash scripts/new-plan.sh --adr docs/decisions/ADR-0034-scratch-fixture.md --number PLAN-12"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "ERROR: --number must be PLAN-NNNN"
}
