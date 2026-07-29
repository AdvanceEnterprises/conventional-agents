#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  RUNBOOKS_README="$REPO_ROOT/runbooks/README.md"
  TEMPLATE="$REPO_ROOT/templates/core/runbook.md"
  LIFECYCLE="$REPO_ROOT/workflows/document-lifecycle.md"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  README="$REPO_ROOT/README.md"
  AGENTS="$REPO_ROOT/AGENTS.md"
  FS_README="$REPO_ROOT/docs/specifications/README.md"
  PACKAGE_JSON="$REPO_ROOT/package.json"
  CI="$REPO_ROOT/.github/workflows/lint-docs.yml"
}

# --- Location and index (FS-0023 criteria 1-2) --------------------------------

@test "runbooks: directory exists with a README index" {
  assert_dir_exists "$REPO_ROOT/runbooks"
  assert_file_exists "$RUNBOOKS_README"
}

@test "runbooks: README states the RB-NNNN convention and carries an index table" {
  assert_file_contains "$RUNBOOKS_README" "RB-NNNN-short-description.md"
  assert_file_contains "$RUNBOOKS_README" "| ID | Title | Substrate | Status |"
}

# --- Template (FS-0023 criteria 3-4) ------------------------------------------

@test "runbook template: front matter carries the verification fields" {
  assert_file_exists "$TEMPLATE"
  assert_file_contains "$TEMPLATE" "type: runbook"
  assert_file_contains "$TEMPLATE" "status:"
  assert_file_contains "$TEMPLATE" "substrate:"
  assert_file_contains "$TEMPLATE" "last_verified:"
  assert_file_contains "$TEMPLATE" "verified_by:"
}

@test "runbook template: carries all five required sections" {
  assert_file_contains "$TEMPLATE" "## Preconditions"
  assert_file_contains "$TEMPLATE" "## Procedure"
  assert_file_contains "$TEMPLATE" "## Deviations Observed"
  assert_file_contains "$TEMPLATE" "## Rollback"
  assert_file_contains "$TEMPLATE" "## Verification"
}

# --- Lifecycle (FS-0023 criterion 5) ------------------------------------------

@test "lifecycle: document-lifecycle.md defines the runbook status vocabulary" {
  assert_file_contains "$LIFECYCLE" "## Runbooks (RB)"
  # The three statuses must appear as table cells, not merely as prose.
  grep -q '^| `current` |' "$LIFECYCLE"
  grep -q '^| `stale` |' "$LIFECYCLE"
  grep -q '^| `superseded` |' "$LIFECYCLE"
}

@test "lifecycle: no runbook status row uses the FS/PLAN vocabulary" {
  # The section may mention draft/approved/implemented in prose — it explains that
  # they do NOT apply to runbooks. What must not happen is one of them appearing as
  # an actual status value, so assert against the table's first column only.
  local section statuses
  section=$(awk '/^## Runbooks \(RB\)/{f=1} f&&/^## Transition Rules/{exit} f' "$LIFECYCLE")
  [ -n "$section" ]
  statuses=$(echo "$section" | grep -oE '^\| `[a-z]+` \|' | tr -d '|` ')
  [ -n "$statuses" ]
  ! echo "$statuses" | grep -qE '^(draft|approved|implemented)$'
  # And the three that must be there, are.
  echo "$statuses" | grep -qx "current"
  echo "$statuses" | grep -qx "stale"
  echo "$statuses" | grep -qx "superseded"
}

# --- Exported-surface registration (FS-0023 criteria 6-9) ---------------------
#
# These four assertions fail independently on purpose. Registering runbooks/ in the
# human-readable tables but not in EXPORTED_PREFIXES would leave the directory
# exported for readers and invisible to the consumer-impact gate — the partial
# registration this spec exists to prevent.

@test "exported surface: check-status.sh EXPORTED_PREFIXES contains runbooks/" {
  # Must be inside the array, not merely somewhere in the file.
  local block
  block=$(awk '/^EXPORTED_PREFIXES=\(/{f=1;next} f&&/^\)/{exit} f' "$CHECK")
  echo "$block" | grep -q '"runbooks/"'
}

@test "exported surface: README.md surface table lists runbooks/" {
  grep -q '^| `runbooks/` |' "$README"
}

@test "exported surface: AGENTS.md surface table lists runbooks/" {
  grep -q '^| `runbooks/` |' "$AGENTS"
}

@test "exported surface: docs/specifications/README.md consumer-impact rule names runbooks/" {
  assert_file_contains "$FS_README" '`runbooks/`'
}

# --- Lint coverage (FS-0023 criteria 10-11) -----------------------------------

@test "lint: package.json defines lint:runbooks and lint:docs invokes it" {
  assert_file_contains "$PACKAGE_JSON" '"lint:runbooks"'
  # The chain must actually call it, not merely define it.
  grep -q 'lint:docs.*lint:runbooks' "$PACKAGE_JSON"
}

@test "lint: CI triggers on runbooks in both push and pull_request path lists" {
  local n
  n=$(grep -c 'runbooks/\*\*/\*\.md' "$CI")
  [ "$n" -eq 2 ]
}

@test "lint: runbooks/ inherits the root markdownlint config" {
  # PLAN-0023 §6 forbids a per-directory config here: one more file to drift.
  [ ! -f "$REPO_ROOT/runbooks/.markdownlint.yml" ]
  assert_file_contains "$REPO_ROOT/.markdownlint.yml" "default: true"
}

# --- Gate still passes ---------------------------------------------------------

@test "check_status: passes with runbooks/ registered as exported surface" {
  run bash "$CHECK"
  [ "$status" -eq 0 ]
}
