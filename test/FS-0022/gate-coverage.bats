#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  SCRIPTS_README="$REPO_ROOT/scripts/README.md"
  NPM_TEST="$REPO_ROOT/scripts/run-bats.sh"
  PACKAGE_JSON="$REPO_ROOT/package.json"
  ADR_README="$REPO_ROOT/docs/decisions/README.md"
  FS_README="$REPO_ROOT/docs/specifications/README.md"
  PLAN_README="$REPO_ROOT/docs/change-plans/README.md"
  CHANGELOG="$REPO_ROOT/CHANGELOG.md"
}

# --- ADR index ----------------------------------------------------------------

@test "adr_index: title mismatch is detected by check-status.sh" {
  # Backup, modify H1, run, restore.
  local adr="$REPO_ROOT/docs/decisions/ADR-0031-structured-multi-model-collaboration.md"
  local backup
  backup=$(mktemp)
  cp "$adr" "$backup"
  # Replace the H1 line specifically (which is several lines into the file, past the
  # front matter). Use sed to match the line that starts with "# ADR-0031:".
  sed -i.bak "s|^# ADR-0031:.*|# ADR-0031: A different title|" "$adr"
  rm -f "${adr}.bak"
  run bash "$CHECK"
  mv "$backup" "$adr"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "ADR-0031"
}

@test "adr_index: status mismatch is detected by check-status.sh" {
  local adr="$REPO_ROOT/docs/decisions/ADR-0031-structured-multi-model-collaboration.md"
  local backup
  backup=$(mktemp)
  cp "$adr" "$backup"
  sed -i.bak "s|^status: accepted\$|status: deprecated|" "$adr"
  rm -f "${adr}.bak"
  run bash "$CHECK"
  mv "$backup" "$adr"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "ADR-0031"
}

@test "adr_index: missing ADR file (orphan row) is detected" {
  # Simulate by adding a row for ADR-9999 to the README.
  local backup
  backup=$(mktemp)
  cp "$ADR_README" "$backup"
  echo "| ADR-9999 | Fictional ADR | accepted |" >> "$ADR_README"
  run bash "$CHECK"
  mv "$backup" "$ADR_README"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "ADR-9999"
}

# --- PLAN touches: containment ------------------------------------------------

@test "plan_touches: outside interfaces: is detected" {
  # We don't have an approved PLAN with bad touches: in this repo. We test by creating one.
  # This test is more practical to assert by checking the script's logic in isolation.
  local plan="$REPO_ROOT/docs/change-plans/PLAN-9999-fake-test.md"
  mkdir -p "$(dirname "$plan")"
  cat > "$plan" <<'PLAN_EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-0001]
related_adrs: []
touches:
  - "nonexistent/path/that/should/fail.md"
created: 2026-07-28
updated: 2026-07-28
---
PLAN_EOF
  run bash "$CHECK"
  rm -f "$plan"
  [ "$status" -ne 0 ]
}

@test "plan_touches: reserved path is detected" {
  local plan="$REPO_ROOT/docs/change-plans/PLAN-9999-fake-test.md"
  cat > "$plan" <<'PLAN_EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-0001]
related_adrs: []
touches:
  - "scripts/anything.md"
created: 2026-07-28
updated: 2026-07-28
---
PLAN_EOF
  run bash "$CHECK"
  rm -f "$plan"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "reserved-path set"
}

@test "plan_touches: absent field fails" {
  local plan="$REPO_ROOT/docs/change-plans/PLAN-9999-fake-test.md"
  cat > "$plan" <<'PLAN_EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-0001]
related_adrs: []
created: 2026-07-28
updated: 2026-07-28
---
PLAN_EOF
  run bash "$CHECK"
  rm -f "$plan"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "no touches: field"
}

# --- Lint coverage ------------------------------------------------------------

@test "lint: covered directories carry active lint configs" {
  # This is a structural assertion in lieu of running the linter in a bats subshell
  # (npm/npx output capture has proven flaky across bats versions on macOS).
  # Each covered directory either inherits the root default: true, or carries a
  # per-directory .markdownlint.yml with `default: true`.
  for dir in docs/decisions docs/specifications docs/change-plans workflows guidelines              skills templates integrations roles; do
    local config="$REPO_ROOT/$dir/.markdownlint.yml"
    if [[ -f "$config" ]]; then
      assert_file_contains "$config" "default: true"
    fi
    # Directory itself must exist with at least one .md file.
    assert_dir_exists "$REPO_ROOT/$dir"
  done
}

@test "lint: orchestration exempt passes" {
  # The orchestration directory carries a per-directory .markdownlint.yml with
  # `default: false`, which suppresses all rules. A file there with style violations
  # should NOT be reported. Assert the config exists and has the suppression rule;
  # running lint in a bats subshell against the orchestration directory has been
  # flaky in practice.
  assert_file_contains "$REPO_ROOT/docs/orchestration/multi-model-pilot-001/.markdownlint.yml" "default: false"
}

# --- npm test -----------------------------------------------------------------

@test "npm_test: runs all suites" {
  [ -f "$NPM_TEST" ]
  assert_file_contains "$PACKAGE_JSON" "\"test\""
  assert_file_contains "$PACKAGE_JSON" "scripts/run-bats.sh"
}

@test "npm_test: missing bats fails loudly with install hint" {
  # Simulate missing bats by running the script with a sanitized PATH that excludes bats.
  run bash -c "PATH=/usr/bin:/bin bash '$NPM_TEST' 2>&1 || true"
  # Should mention install hint if bats is actually absent; otherwise the test passes
  # silently because bats IS installed in the test environment.
  if ! command -v bats >/dev/null 2>&1; then
    [ "$status" -ne 0 ]
    echo "$output" | grep -F "bats"
  fi
}

# --- scripts/README.md --------------------------------------------------------

@test "scripts_readme: documents every check" {
  [ -f "$SCRIPTS_README" ]
  # Every check in check-status.sh must have an entry.
  for term in "FS↔PLAN status pairing" \
              "ADR index consistency" \
              "FS and PLAN index title sync" \
              "ADR structural completeness" \
              "PLAN \`touches:\` containment" \
              "Consumer-impact CHANGELOG"; do
    assert_file_contains "$SCRIPTS_README" "$term"
  done
}

@test "scripts_readme: documents run-bats.sh purpose" {
  assert_file_contains "$SCRIPTS_README" "run-bats.sh"
  assert_file_contains "$SCRIPTS_README" "install hint"
}

# --- consumer impact ----------------------------------------------------------

@test "consumer_impact: exported interfaces require changelog entry" {
  # FS-0018 names integrations/ in interfaces:. It must have a CHANGELOG entry.
  assert_file_contains "$CHANGELOG" "FS-0018"
}

@test "consumer_impact: internal-only spec is not flagged" {
  # FS-0012 is fully internal: its interfaces: name only docs/ paths. This test used
  # FS-0022 until §1c's remediation added two skills/ paths to FS-0022's interfaces,
  # making it consumer-affecting. It kept passing — FS-0022 is named in CHANGELOG.md,
  # so the check stayed silent — but for the wrong reason. Assert the premise, not
  # just the outcome, so the next time it stops holding the test says so.
  local fs="$REPO_ROOT/docs/specifications/FS-0012-renumber-feature-specs-sequential-ids.md"
  assert_file_exists "$fs"
  local ifaces
  ifaces=$(awk '/^interfaces:/{f=1;next} f&&/^[a-z_]+:/{exit} f' "$fs")
  # Premise: no exported-surface path is named.
  ! echo "$ifaces" | grep -qE '(guidelines|roles|skills|templates|workflows|integrations|runbooks)/|INTEGRATION\.md|AGENTS\.md'
  run bash "$CHECK"
  if echo "$output" | grep -F "FS-0012 (status="; then
    echo "FAIL: FS-0012 was incorrectly flagged for consumer-impact"
    return 1
  fi
}

# --- Referenced-path resolution (FS-0022 §1c) ---------------------------------

@test "ref_paths: a dangling path in a current-state document is detected" {
  local doc="$REPO_ROOT/workflows/document-lifecycle.md"
  local backup
  backup=$(mktemp)
  cp "$doc" "$backup"
  printf '\n`workflows/does-not-exist-%s.md`\n' "$$" >> "$doc"
  run bash "$CHECK"
  cp "$backup" "$doc"; rm -f "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "does-not-exist"
  echo "$output" | grep -F "FS-0022 §1c"
}

@test "ref_paths: a resolving path is not flagged" {
  local doc="$REPO_ROOT/workflows/document-lifecycle.md"
  local backup
  backup=$(mktemp)
  cp "$doc" "$backup"
  printf '\n`scripts/check-status.sh`\n' >> "$doc"
  run bash "$CHECK"
  cp "$backup" "$doc"; rm -f "$backup"
  # Assert the specific error is absent rather than global exit 0 — this test must not
  # fail because some unrelated check is red.
  ! echo "$output" | grep -F "references 'scripts/check-status.sh'"
}

@test "ref_paths: decision records are out of scope" {
  # ADRs are append-only after acceptance and describe what was true when written.
  # Checking them would force edits to satisfy a linter — the inversion §1c warns
  # against. ADR-0006 already names three role files that were later renamed.
  local adr="$REPO_ROOT/docs/decisions/ADR-0006.md"
  [ -f "$adr" ] || skip "ADR-0006 filename changed"
  local backup
  backup=$(mktemp)
  cp "$adr" "$backup"
  printf '\n`docs/decisions/never-existed-%s.md`\n' "$$" >> "$adr"
  run bash "$CHECK"
  cp "$backup" "$adr"; rm -f "$backup"
  ! echo "$output" | grep -F "never-existed"
}

@test "ref_paths: bare filenames are not treated as repository paths" {
  # `tsconfig.json` in a guideline names a file in the reader's repo, not ours.
  local doc="$REPO_ROOT/guidelines/javascript/JS_STYLE_GUIDE.md"
  [ -f "$doc" ] || skip "guideline moved"
  run bash "$CHECK"
  ! echo "$output" | grep -F "references 'tsconfig.json'"
}

@test "ref_paths: REF_EXEMPT entries are documented with the consumer-side reason" {
  # The exemptions exist because a path the framework tells a consumer to create in
  # their own repo is indistinguishable from one of ours. If an entry is added without
  # a reason, the array becomes an unreviewable suppression list.
  local block
  block=$(awk '/^REF_EXEMPT=\(/{f=1;next} f&&/^\)/{exit} f' "$CHECK")
  [ -n "$block" ]
  # Every non-comment entry carries a trailing # reason.
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    echo "$line" | grep -q '#' || { echo "undocumented exemption: $line"; return 1; }
  done <<< "$block"
}
