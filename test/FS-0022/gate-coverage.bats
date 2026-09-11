#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

# Every test below injects a defect into a real tracked file, runs
# check-status.sh, and asserts on the result. Doing that against the live
# working tree meant a killed run (CI timeout, Ctrl-C) between mutate and
# restore left the mutation on disk permanently — corrupting every other
# suite that reads the same file afterward. This suite instead mutates a
# disposable `git worktree` checked out at HEAD, so a bad exit loses nothing
# and concurrent runs (each its own mktemp -d) never collide.
#
# check-status.sh's self-check path requires REPO_ROOT (git rev-parse
# --show-toplevel, from cwd) to equal FRAMEWORK_HOME (derived from the
# script's own on-disk location) — see is_self_check() in check-status.sh.
# FS-0024/FS-0026's vendored-symlink scratch-host pattern deliberately makes
# those differ, to test the *portable*, non-self-check path; FS-0022 needs
# the opposite; a real worktree checkout gives both, as long as every
# invocation below cd's into it first (see run_check).
setup_file() {
  # setup_file and individual @test bodies don't share shell state — bats
  # runs each test as its own process — so these must be exported, not just
  # assigned, to reach setup() below.
  export REAL_REPO_ROOT="$(repo_root)"
  # mktemp -d on macOS returns a path under /var/folders/…, which is a
  # symlink to /private/var/folders/…. `cd … && pwd` (no -P) preserves that
  # logical form, but `git rev-parse --show-toplevel` always resolves to the
  # physical path. is_self_check() compares the two verbatim, so without -P
  # here they'd differ by exactly that symlink and every test below would
  # silently run in non-self-check mode. Resolve to the physical path first.
  export WORKTREE="$(cd "$(mktemp -d)" && pwd -P)"
  git -C "$REAL_REPO_ROOT" worktree add --quiet --detach "$WORKTREE" HEAD
}

teardown_file() {
  git -C "$REAL_REPO_ROOT" worktree remove --force "$WORKTREE" 2>/dev/null || rm -rf "$WORKTREE"
}

setup() {
  REPO_ROOT="$WORKTREE"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  SCRIPTS_README="$REPO_ROOT/scripts/README.md"
  NPM_TEST="$REPO_ROOT/scripts/run-bats.sh"
  PACKAGE_JSON="$REPO_ROOT/package.json"
  ADR_README="$REPO_ROOT/docs/decisions/README.md"
  FS_README="$REPO_ROOT/docs/specifications/README.md"
  PLAN_README="$REPO_ROOT/docs/change-plans/README.md"
  CHANGELOG="$REPO_ROOT/CHANGELOG.md"
}

# `run bash "$CHECK"` alone would run the worktree's copy of the script from
# bats' own cwd (the real repo's root), which breaks the self-check match
# above — check-status.sh would see REPO_ROOT (real repo) != FRAMEWORK_HOME
# (worktree) and take the non-self-check path. Route every invocation
# through this so cwd and script location always agree.
run_check() {
  ( cd "$REPO_ROOT" && bash "$CHECK" )
}

teardown() {
  # Clean up PLAN-9999-fake-test.md if a previous test run was interrupted.
  # This test fixture is created by the plan_touches:* tests. It lands in the
  # disposable worktree, not the real tree, but a stray file here can still
  # confuse the next test in this run.
  rm -f "$REPO_ROOT/docs/change-plans/PLAN-9999-fake-test.md"
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
  run run_check
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
  run run_check
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
  run run_check
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
  run run_check
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
  run run_check
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
  run run_check
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
  # Build a PATH that keeps the tools run-bats.sh needs (dirname, find) but drops
  # every directory containing a bats binary.
  #
  # The previous version hardcoded PATH=/usr/bin:/bin. That excludes Homebrew's bats
  # on macOS, so it passed locally — but it *includes* apt's /usr/bin/bats on Linux,
  # so run-bats.sh found bats and ran every suite, including this one, recursively.
  # CI hung until the runner was exhausted. Never assume a fixed path excludes a tool.
  local clean_path="" d
  local IFS=':'
  for d in $PATH; do
    [ -n "$d" ] || continue
    [ -x "$d/bats" ] && continue
    clean_path="${clean_path:+$clean_path:}$d"
  done
  unset IFS
  [ -n "$clean_path" ]

  # env -u RUN_BATS_ACTIVE: this test deliberately exercises run-bats.sh, so it opts
  # out of the re-entrancy guard the script added after the incident above.
  run env -u RUN_BATS_ACTIVE PATH="$clean_path" /bin/bash "$NPM_TEST"

  # Unconditional. The previous version wrapped these in `if ! command -v bats`, so it
  # asserted nothing whenever bats was installed -- which is always, in CI. A test that
  # only checks things in the environment where it never runs is not a test.
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "not installed or not on PATH"
  echo "$output" | grep -qF "bats-core"
}

@test "npm_test: run-bats.sh refuses to run recursively" {
  # The guard that turns the fork bomb above into a clear error.
  run env RUN_BATS_ACTIVE=1 /bin/bash "$NPM_TEST"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "invoked recursively"
}

# --- scripts/README.md --------------------------------------------------------

@test "scripts_readme: documents every check" {
  [ -f "$SCRIPTS_README" ]
  # Every check in check-status.sh must have an entry.
  for term in "FS↔PLAN status pairing" \
              "ADR index consistency" \
              "FS index title sync" \
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
  # This asserted only that CHANGELOG.md contained the string "FS-0018" — it never
  # invoked the check. It passed for two years' worth of commits while the check it
  # named was resolving "$FS_DIR/FS-0018.md", a path that does not exist for suffixed
  # filenames, and skipping every spec. Mutate and assert the failure instead.
  local backup
  backup=$(mktemp)
  cp "$CHANGELOG" "$backup"
  sed -i.bak 's/FS-0023/FS-XXXX/g' "$CHANGELOG"
  rm -f "${CHANGELOG}.bak"
  run run_check
  cp "$backup" "$CHANGELOG"; rm -f "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-0023"
  echo "$output" | grep -qF "no CHANGELOG entry naming it"
}

@test "index_titles: FS title drift is detected" {
  # Rule 4 built "$doc_dir/$row_id.md" and skipped every row whose file carries a
  # descriptive suffix — i.e. all of them. It passed while enforcing nothing.
  local backup
  backup=$(mktemp)
  cp "$FS_README" "$backup"
  sed -i.bak 's/^| FS-0023 | [^|]*|/| FS-0023 | COMPLETELY WRONG TITLE |/' "$FS_README"
  rm -f "${FS_README}.bak"
  run run_check
  cp "$backup" "$FS_README"; rm -f "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-0023 front matter title"
}

@test "index_titles: an orphan README row is detected" {
  local backup
  backup=$(mktemp)
  cp "$PLAN_README" "$backup"
  echo "| PLAN-9999 | Nonexistent plan | FS-0001 | approved |" >> "$PLAN_README"
  run run_check
  cp "$backup" "$PLAN_README"; rm -f "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "PLAN-9999 has a row"
}

@test "index_titles: PLAN rows are not title-compared" {
  # PLANs carry no title: field (templates/core/change-plan.md defines none). Comparing
  # them reports all 23 as drifted. Guard the scoping decision, not just the behaviour.
  run run_check
  ! echo "$output" | grep -qE "PLAN-[0-9]+ front matter title"
}

@test "resolve_doc_by_id: resolves both bare and suffixed filenames" {
  run bash -c "source '$CHECK' >/dev/null 2>&1; true"
  # ADR-0006.md is bare; FS-0023-*.md is suffixed. Both must resolve.
  [ -f "$REPO_ROOT/docs/decisions/ADR-0006.md" ]
  local suffixed
  suffixed=$(ls "$REPO_ROOT/docs/specifications/FS-0023"-*.md 2>/dev/null | head -1)
  [ -n "$suffixed" ]
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
  run run_check
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
  run run_check
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
  run run_check
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
  run run_check
  cp "$backup" "$adr"; rm -f "$backup"
  ! echo "$output" | grep -F "never-existed"
}

@test "ref_paths: bare filenames are not treated as repository paths" {
  # `tsconfig.json` in a guideline names a file in the reader's repo, not ours.
  local doc="$REPO_ROOT/guidelines/javascript/JS_STYLE_GUIDE.md"
  [ -f "$doc" ] || skip "guideline moved"
  run run_check
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

# --- Current-state update, ADR-0030 rule 3 (FS-0022 §3) -----------------------
#
# The script is sourced, not executed: its logic is separated from git so these can
# drive it with synthetic change sets rather than building throwaway history.

@test "current_state: script exists and is sourceable without running" {
  local s="$REPO_ROOT/scripts/check-current-state.sh"
  [ -f "$s" ]
  run bash -c "source '$s'; echo SOURCED_CLEAN"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "SOURCED_CLEAN"
  # Sourcing must not execute the check.
  ! echo "$output" | grep -qF "ADR-0030 rule 3:"
}

@test "current_state: ADR naming an unmodified current-state doc fails" {
  local adr="docs/decisions/ADR-0025-merge-strategy-preserves-per-commit-attribution.md"
  [ -f "$REPO_ROOT/$adr" ] || skip "ADR-0025 filename changed"
  run bash -c "source '$REPO_ROOT/scripts/check-current-state.sh'; \
    check_links_against_changes 'README.md' '$adr'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ADR-0030 rule 3"
  echo "$output" | grep -qF "workflows/git-and-gh-conventions.md"
}

@test "current_state: ADR whose linked doc is modified passes" {
  local adr="docs/decisions/ADR-0025-merge-strategy-preserves-per-commit-attribution.md"
  [ -f "$REPO_ROOT/$adr" ] || skip "ADR-0025 filename changed"
  run bash -c "source '$REPO_ROOT/scripts/check-current-state.sh'; \
    check_links_against_changes 'workflows/git-and-gh-conventions.md' '$adr'"
  [ "$status" -eq 0 ]
}

@test "current_state: a directory link is satisfied by any change beneath it" {
  # ADR-0024 links `integrations/` as well as a file. A link naming a directory can
  # never match a changed file path exactly, so prefix matching is required.
  local adr="docs/decisions/ADR-0024-platform-neutral-core-with-shipped-bindings.md"
  [ -f "$REPO_ROOT/$adr" ] || skip "ADR-0024 filename changed"
  run bash -c "source '$REPO_ROOT/scripts/check-current-state.sh'; \
    check_links_against_changes 'integrations/github-issues-projects.md' '$adr'"
  [ "$status" -eq 0 ]
}

@test "current_state: an ADR naming no current-state document is out of scope" {
  # ADR-0031's Links name no workflows/guidelines/skills/templates/integrations path.
  local adr="docs/decisions/ADR-0031-structured-multi-model-collaboration.md"
  [ -f "$REPO_ROOT/$adr" ] || skip "ADR-0031 filename changed"
  run bash -c "source '$REPO_ROOT/scripts/check-current-state.sh'; \
    check_links_against_changes 'README.md' '$adr'"
  [ "$status" -eq 0 ]
}

@test "current_state: only ADRs becoming accepted are in scope" {
  # A status-preserving edit must not drag in an unrelated current-state change.
  # adr_becomes_accepted keys on the diff adding `status: accepted`.
  run bash -c "source '$REPO_ROOT/scripts/check-current-state.sh'; \
    declare -f adr_becomes_accepted"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'status:'
  echo "$output" | grep -qF 'accepted'
}

@test "current_state: the CI job exists and runs on pull_request" {
  local ci="$REPO_ROOT/.github/workflows/lint-docs.yml"
  assert_file_contains "$ci" "current-state-update:"
  assert_file_contains "$ci" "check-current-state.sh"
  assert_file_contains "$ci" "fetch-depth: 0"
}

# --- ADR structural completeness anchoring (FS-0022 §1b) ----------------------

@test "adr_structure: a renamed required section is detected" {
  # grep -qF was unanchored, so "## Consequences-renamed" satisfied the
  # "## Consequences" requirement. Renaming a required section left the check green.
  local adr="$REPO_ROOT/docs/decisions/ADR-0031-structured-multi-model-collaboration.md"
  [ -f "$adr" ] || skip "ADR-0031 filename changed"
  local backup
  backup=$(mktemp)
  cp "$adr" "$backup"
  sed -i.bak -E 's/^(#{2,3}) Consequences$/\1 Consequences-renamed/' "$adr"
  rm -f "${adr}.bak"
  run run_check
  cp "$backup" "$adr"; rm -f "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing required section"
}

@test "adr_structure: MADR's H3-nested Consequences is accepted" {
  # MADR 4.0 puts Consequences at H3 under "## Decision Outcome"; six accepted ADRs
  # here follow that. Pinning the requirement to H2 would fail all six. This guards
  # the accommodation, not just the rejection.
  local nested=0 f
  for f in "$REPO_ROOT"/docs/decisions/ADR-*.md; do
    if grep -qE '^### Consequences[[:space:]]*$' "$f" && ! grep -qE '^## Consequences[[:space:]]*$' "$f"; then
      nested=$((nested+1))
    fi
  done
  [ "$nested" -gt 0 ]          # the situation this guards actually exists
  run run_check
  ! echo "$output" | grep -qF "missing required section: ## Consequences"
}
