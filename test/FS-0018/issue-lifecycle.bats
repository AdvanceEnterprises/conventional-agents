#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

# Regex that matches a well-formed agent-stance comment line.
# Format: agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<reason>
agent_stance_pattern() {
  printf '^agent-stance:[[:space:]]*mode=[^;]+;[[:space:]]*role=[^;]+;[[:space:]]*model=[^;]+;[[:space:]]*session=[^;]+;[[:space:]]*rationale=.+$'
}

# Allowed mode values per FS-0018 and FS-0019.
# Architecture-planning, document-authoring, implementation, review,
# communications (from workflows/session-modes.md), plus
# autonomous (FS-0018) and consensus (FS-0019).
ALLOWED_MODES=(
  "architecture-planning"
  "document-authoring"
  "implementation"
  "review"
  "communications"
  "autonomous"
  "consensus"
)

@test "FS-0018 exists with draft status" {
  assert_file_exists "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "status: draft"
}

@test "FS-0018 declares three-axis Issue schema" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "Type (single-valued)"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "Label (multi-valued)"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "Status (single-valued, lives on the GitHub Project)"
}

@test "FS-0018 lists six labels" {
  local labels=("enhancement" "bug" "documentation" "spec" "plan" "question")
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  for label in "${labels[@]}"; do
    assert_file_contains "$f" "\`${label}\`"
  done
}

@test "FS-0018 lists three Types" {
  local types=("feature" "bug" "task")
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  for t in "${types[@]}"; do
    assert_file_contains "$f" "\`${t}\`"
  done
}

@test "FS-0018 lists five Status values" {
  local statuses=("Backlog" "Approved" "In Progress" "In Review" "Done")
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  for s in "${statuses[@]}"; do
    assert_file_contains "$f" "$s"
  done
}

@test "FS-0018 agent-stance regex matches positive cases" {
  local pattern
  pattern="$(agent_stance_pattern)"
  local samples=(
    "agent-stance: mode=architecture-planning; role=Head Architect; model=ollama-cloud/deepseek-v4-flash; session=interactive-001; rationale=elevate enhancement to spec"
    "agent-stance: mode=autonomous; role=Head Architect; model=ollama-cloud/deepseek-v4-flash; session=check-status-cron; rationale=file bug for drift detected"
    "agent-stance: mode=document-authoring; role=Document Author; model=ollama-cloud/deepseek-v4-flash; session=impl-002; rationale=draft FS from Issue brief"
  )
  for s in "${samples[@]}"; do
    if ! echo "$s" | grep -Eq "$pattern"; then
      echo "FAIL: positive case did not match: $s"
      return 1
    fi
  done
}

@test "FS-0018 agent-stance regex rejects negative cases" {
  local pattern
  pattern="$(agent_stance_pattern)"
  local negatives=(
    "agent-stance: role=Head Architect; model=foo; session=bar; rationale=baz"
    "agent-stance: mode=foo"
    "agent-stance: mode=foo; role=bar; model=baz; session=qux"
  )
  for s in "${negatives[@]}"; do
    if echo "$s" | grep -Eq "$pattern"; then
      echo "FAIL: negative case matched (should reject): $s"
      return 1
    fi
  done
}

@test "FS-0018 agent-stance regex is format-only, not value validation" {
  # The regex validates field presence and ordering, not value semantics.
  # A string with all five fields in the correct order matches even if
  # the values are invalid (e.g., mode=foo). Value validation is a
  # separate concern enforced by the enumerated-mode test below.
  local pattern
  pattern="$(agent_stance_pattern)"
  local format_valid=(
    "agent-stance: mode=foo; role=bar; model=baz; session=qux; rationale=quux"
  )
  for s in "${format_valid[@]}"; do
    if ! echo "$s" | grep -Eq "$pattern"; then
      echo "FAIL: format-valid case did not match: $s"
      return 1
    fi
  done
}

@test "FS-0018 enumerated mode values are all valid" {
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  for mode in "${ALLOWED_MODES[@]}"; do
    assert_file_contains "$f" "$mode"
  done
}

@test "FS-0018 declares Type human-mutable only" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "Type is human-mutable only"
}

@test "FS-0018 declares autonomous gate by Type" {
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  assert_file_contains "$f" "feature.*Approved"
  assert_file_contains "$f" "bug.*Approved"
  assert_file_contains "$f" "task.*In Progress"
}

@test "FS-0018 declares three origination paths" {
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  assert_file_contains "$f" "Path 1: Human opens Issue with \`enhancement\` label"
  assert_file_contains "$f" "Path 2: Head Architect conversation produces Type \`feature\` Issue"
  assert_file_contains "$f" "Path 3: Autonomous agent creates Issue from drift"
}

@test "FS-0018 lists ADR dependencies" {
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  grep -qE "^related_adrs:" "$f" || return 1
  grep -qE "^  - ADR-0018" "$f"
  grep -qE "^  - ADR-0012" "$f"
}

@test "FS-0018 has Plan Status section naming its PLAN" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "## Plan Status"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "PLAN-0018"
}

@test "PLAN-0018 exists and is not approved ahead of its FS" {
  local p="$REPO_ROOT/docs/change-plans/PLAN-0018-implement-fs-0018-issue-lifecycle-and-autonomous-triggers.md"
  [ -f "$p" ]
  # A PLAN must not be approved while its primary FS is still draft.
  local fs_status plan_status
  fs_status=$(grep -m1 '^status:' "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" | awk '{print $2}')
  plan_status=$(grep -m1 '^status:' "$p" | awk '{print $2}')
  if [ "$fs_status" = "draft" ]; then
    [ "$plan_status" = "draft" ]
  fi
}

@test "FS-0018 cron-identity is a documented blocker" {
  local f="$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  assert_file_contains "$f" "Cron actor identity (blocker for Path 3)"
}

@test "FS-0018 references FS-0019 as a follow-on" {
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md" "FS-0019"
}
