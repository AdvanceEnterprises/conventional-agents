#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "FS-0019 exists with draft status" {
  assert_file_exists "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "status: draft"
}

@test "FS-0019 declares consensus disabled by default" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "**Default**: consensus is **disabled**"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "framework's own evolution does not use consensus"
}

@test "FS-0019 declares different-models requirement" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$f" "Different-Models Requirement"
  assert_file_contains "$f" "forbidden"
  assert_file_contains "$f" "theater"
}

@test "FS-0019 defines three failure modes" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  for mode in "hard_block" "soft_flag" "escalation"; do
    assert_file_contains "$f" "$mode"
  done
}

@test "FS-0019 defines two gates" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$f" "Gate A: Pre-Submission"
  assert_file_contains "$f" "Gate B: Review-Time"
}

@test "FS-0019 defines consensus round artifact schema" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$f" "docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml"
  assert_file_contains "$f" "agreement_check"
  assert_file_contains "$f" "verdict"
}

@test "FS-0019 consensus round escalation creates Type task Issue" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$f" "Consensus escalation"
  assert_file_contains "$f" "Type \`task\` Issue"
}

@test "config/consensus.yml template exists with all-defaults state" {
  assert_file_exists "$REPO_ROOT/config/consensus.yml"
  local cfg="$REPO_ROOT/config/consensus.yml"
  assert_file_contains "$cfg" "enabled: false"
  assert_file_contains "$cfg" "default_threshold: 2/2"
  assert_file_contains "$cfg" "default_failure_mode: hard_block"
  assert_file_contains "$cfg" "min_models: 2"
}

@test "config/consensus.yml has per-gate configuration" {
  local cfg="$REPO_ROOT/config/consensus.yml"
  assert_file_contains "$cfg" "pre_submission:"
  assert_file_contains "$cfg" "review_time:"
}

@test "config/consensus.yml models list starts empty" {
  local cfg="$REPO_ROOT/config/consensus.yml"
  assert_file_contains "$cfg" "models: []"
}

@test "FS-0019 lists dependencies on FS-0018 and ADR-0018" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  grep -qE "^related_adrs:" "$f" || return 1
  grep -qE "^  - ADR-0018" "$f"
  grep -qE "^requires:" "$f"
  grep -qE "^  - FS-0018" "$f"
}

@test "FS-0019 has Plan Status section naming its PLAN" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "## Plan Status"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "PLAN-0019"
}

@test "PLAN-0019 exists and is not approved ahead of its FS" {
  local p="$REPO_ROOT/docs/change-plans/PLAN-0019-implement-fs-0019-multi-model-consensus.md"
  [ -f "$p" ]
  # A PLAN must not be approved while its primary FS is still draft.
  local fs_status plan_status
  fs_status=$(grep -m1 '^status:' "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" | awk '{print $2}')
  plan_status=$(grep -m1 '^status:' "$p" | awk '{print $2}')
  if [ "$fs_status" = "draft" ]; then
    [ "$plan_status" = "draft" ]
  fi
}

@test "FS-0019 has test-harness note about consumer-repo fixtures" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md" "fixture-based bats tests"
}

@test "FS-0019 same-model consensus is forbidden" {
  local f="$REPO_ROOT/docs/specifications/FS-0019-multi-model-consensus.md"
  assert_file_contains "$f" "Same-model-with-same-prompt is forbidden"
  assert_file_contains "$f" "noise dressed as consensus"
}
