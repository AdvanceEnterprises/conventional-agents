#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CFG="$REPO_ROOT/config/review-board.yml"
  TEMPLATE="$REPO_ROOT/templates/collaboration/review-board-findings.md"
  FS="$REPO_ROOT/docs/specifications/FS-0021-review-board.md"
}

# --- default and opt-in ---------------------------------------------------------

@test "default: review-board.yml ships disabled" {
  [ -f "$CFG" ]
  assert_file_contains "$CFG" "enabled: false"
}

@test "default: FS-0021 declares review boards disabled by default" {
  # The FS body wraps the phrase across two lines ("disabled by" + "default"). Use rg -U for
  # multiline matching.
  rg -U "disabled by\\s+default" "$FS" >/dev/null
}

@test "default: per-placement configuration is independently disabled" {
  assert_file_contains "$CFG" "artifact_review:"
  assert_file_contains "$CFG" "change_review:"
  # Both placements carry enabled: false
  rg -F "artifact_review:" -A 2 "$CFG" | rg -F "enabled: false" >/dev/null
  rg -F "change_review:" -A 2 "$CFG" | rg -F "enabled: false" >/dev/null
}

@test "default: seats list starts empty" {
  assert_file_contains "$CFG" "seats: []"
}

# --- composition ---------------------------------------------------------------

@test "composition: min_models floor is 2" {
  assert_file_contains "$CFG" "min_models: 2"
}

@test "composition: min_roles floor is 2 (board distinguishing constraint)" {
  assert_file_contains "$CFG" "min_roles: 2"
}

@test "composition: identical-models rejection is asserted in FS" {
  assert_file_contains "$FS" "identical models"
  assert_file_contains "$FS" "configuration error"
}

@test "composition: identical-roles rejection is asserted in FS" {
  assert_file_contains "$FS" "two identical role stances"
  assert_file_contains "$FS" "composition error"
}

# --- findings -------------------------------------------------------------------

@test "findings: contradictions are both recorded (template)" {
  # The template text states both findings are kept and each names the other.
  assert_file_contains "$TEMPLATE" "contradicts"
  assert_file_contains "$TEMPLATE" "both"
}

@test "findings: contradicts is a list, not a scalar" {
  # FS-0021 says `contradicts` is a list. The template and FS both surface this.
  assert_file_contains "$FS" "contradicts\` is a list"
  assert_file_contains "$TEMPLATE" "contradicts"
}

@test "findings: duplicate observations merge with all raising seats" {
  # Deduplication keeps every raising seat in `also_raised_by` (FS artifact shape).
  assert_file_contains "$FS" "also_raised_by"
  # Template uses prose form: "every raising seat".
  assert_file_contains "$TEMPLATE" "every raising seat"
}

@test "findings: rejected requires reason" {
  assert_file_contains "$FS" "rejected"
  assert_file_contains "$FS" "disposition_reason"
}

@test "findings: deferred requires reason" {
  assert_file_contains "$FS" "deferred"
  assert_file_contains "$FS" "disposition_reason"
}

@test "findings: every finding is dispositioned" {
  assert_file_contains "$FS" "Every finding receives a disposition"
  assert_file_contains "$TEMPLATE" "Every finding"
}

# --- coverage -------------------------------------------------------------------

@test "coverage: every seat accounted for per dimension" {
  assert_file_contains "$TEMPLATE" "addressed"
  assert_file_contains "$TEMPLATE" "silent"
}

# --- gate -----------------------------------------------------------------------

@test "gate: evaluator not in seats" {
  # ADR-0023 Constraint 3: gate evaluator MUST NOT have filled a seat. The phrase wraps
  # across two lines in FS-0021 ("MUST NOT have filled a" + "seat.").
  assert_file_contains "$FS" "MUST NOT have filled a"
  assert_file_contains "$FS" "evaluator"
}

@test "gate: absent when no independent evaluator" {
  # Synthesis-only fallback when no independent evaluator exists.
  assert_file_contains "$FS" "synthesis-only"
}

@test "gate: no override flag for gate independence" {
  # ADR-0023 Constraint 3 explicitly rejects an override flag. Config must not introduce one.
  ! rg -F "allow_gate_overlap" "$CFG"
  ! rg -F "allow_gate_overlap" "$FS"
  ! rg -F "allow-gate-overlap" "$CFG"
}

# --- advisory boundary ----------------------------------------------------------

@test "advisory: blocking severity performs no transition" {
  # A board returning blocking findings performs no status transition, approval, or merge.
  assert_file_contains "$FS" "no status transition, approval, or merge"
  assert_file_contains "$FS" "advisory"
}

@test "advisory: severity taxonomy is the four FS values" {
  assert_file_contains "$CFG" "blocking"
  assert_file_contains "$CFG" "substantive"
  assert_file_contains "$CFG" "minor"
  assert_file_contains "$CFG" "question"
}

