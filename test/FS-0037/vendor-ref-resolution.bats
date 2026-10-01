#!/usr/bin/env bats
# FS-0037 — vendor-prefixed reference resolution (rule 8 extension).
#
# Self-check cases mutate a disposable git worktree checked out at HEAD (the
# FS-0022 pattern) so a killed run loses nothing. Non-self-check cases build
# scratch host repositories under BATS_TEST_TMPDIR (the FS-0024 pattern) with
# the framework at vendor/conventional-agents — symlinked for the initialised
# case, an empty directory for the uninitialised case. check-status.sh resolves
# rule 8's document set from the *tracked* file list of the repository it
# checks, so each host fixture stages its documents with git add before running
# the vendored copy.
#
# check-status.sh's self-check path requires REPO_ROOT == FRAMEWORK_HOME (see
# is_self_check() in check-status.sh), so self-check invocations cd into the
# worktree and use its own script; host invocations cd into the host, keeping
# REPO_ROOT (the host) and FRAMEWORK_HOME (this checkout) distinct.

load "../FS-0001/helpers.bash"

set -euo pipefail

setup_file() {
  export REAL_REPO_ROOT="$(repo_root)"
  export WORKTREE="$(cd "$(mktemp -d)" && pwd -P)"
  if ! git -C "$REAL_REPO_ROOT" worktree add --quiet --detach "$WORKTREE" HEAD; then
    echo "FS-0037: git worktree add failed for '$WORKTREE'" >&2
    return 1
  fi
  # Safety net: a mid-suite abort must not orphan the worktree or leave a
  # stale .git/worktrees registry entry.
  trap 'git -C "$REAL_REPO_ROOT" worktree remove --force "$WORKTREE" 2>/dev/null || true; git -C "$REAL_REPO_ROOT" worktree prune || true' EXIT
}

teardown_file() {
  git -C "$REAL_REPO_ROOT" worktree remove --force "$WORKTREE" 2>/dev/null || {
    rm -rf "$WORKTREE"
    git -C "$REAL_REPO_ROOT" worktree prune
  }
}

setup() {
  REPO_ROOT="$WORKTREE"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
}

# Route every self-check invocation through this so cwd and script location
# always agree (a direct `bash "$CHECK"` would run from bats' own cwd).
run_check() {
  ( cd "$REPO_ROOT" && bash "$CHECK" )
}

# --- fixtures -----------------------------------------------------------------

# Copy a tracked document aside before mutating it; restore_doc puts it back.
# The backup lives outside the worktree so it cannot be confused with the
# mutation itself.
backup_doc() {
  local doc="$1"
  local backup
  backup="$(mktemp)"
  cp "$REPO_ROOT/$doc" "$backup"
  echo "$backup"
}

restore_doc() {
  local doc="$1" backup="$2"
  cp "$backup" "$REPO_ROOT/$doc"
  rm -f "$backup"
}

# A scratch host repository with minimal governed indexes, this framework at
# vendor/conventional-agents, and a config/gates.yml stating the empty
# reserved set explicitly (per ADR-0033 an explicit empty set is a declaration;
# these fixtures exercise rule 8, not rules 6-7).
build_scratch_host() {
  local host="$1" mode="${2:-initialised}"
  mkdir -p "$host/docs/specifications" "$host/docs/change-plans" \
    "$host/docs/decisions" "$host/vendor" "$host/config"
  ( cd "$host" && git init -q )
  printf '# Specs\n\n| ID | Title | Status |\n| --- | --- | --- |\n' \
    > "$host/docs/specifications/README.md"
  printf '# Plans\n\n| ID | Title | Related Spec | Status |\n| --- | --- | --- | --- |\n' \
    > "$host/docs/change-plans/README.md"
  printf '# Decisions\n\n| ID | Title | Status |\n| --- | --- | --- |\n' \
    > "$host/docs/decisions/README.md"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"
  if [ "$mode" = "initialised" ]; then
    ln -sfn "$REPO_ROOT" "$host/vendor/conventional-agents"
  else
    # Mirror git's post-clone state for an uninitialised submodule: the
    # directory exists and is empty.
    mkdir -p "$host/vendor/conventional-agents"
  fi
}

# Rule 8 resolves its document set from the tracked list, so host fixtures
# must stage what they write.
stage_host() {
  ( cd "$1" && git add -A )
}

# --- SC-1: phantom backticked prefixed reference fails (self-check) ----------

@test "sc1: backticked phantom vendor/conventional-agents reference fails and names the document" {
  local doc="workflows/document-lifecycle.md" backup
  backup="$(backup_doc "$doc")"
  printf '\n`vendor/conventional-agents/guidelines/NEVER-EXISTED-SC1.md`\n' >> "$REPO_ROOT/$doc"
  run run_check
  restore_doc "$doc" "$backup"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "vendor/conventional-agents/guidelines/NEVER-EXISTED-SC1.md"
  echo "$output" | grep -F "$doc"
}

# --- SC-2: resolving prefixed references pass --------------------------------

@test "sc2: a resolving backticked prefixed reference is not flagged" {
  local doc="workflows/document-lifecycle.md" backup
  backup="$(backup_doc "$doc")"
  printf '\n`vendor/conventional-agents/guidelines/ROLE_CONTRACT.md`\n' >> "$REPO_ROOT/$doc"
  run run_check
  restore_doc "$doc" "$backup"
  ! echo "$output" | grep -F "references 'vendor/conventional-agents/guidelines/ROLE_CONTRACT.md'"
}

@test "sc2: the spec's count bar is the rule-8-set figure (64 / 39 / 24)" {
  # The SC-2 parenthetical and this suite assert against one number; the spec
  # owns the bar (FS-0037 §Success Criteria).
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0037-vendor-ref-resolution.md" "64 / 39 / 24"
}

# --- SC-3: third-party vendor paths keep the skip ----------------------------

@test "sc3: a phantom third-party vendor path skips in self-check" {
  local doc="workflows/document-lifecycle.md" backup
  backup="$(backup_doc "$doc")"
  printf '\n`vendor/madr/template.md`\n' >> "$REPO_ROOT/$doc"
  run run_check
  restore_doc "$doc" "$backup"
  ! echo "$output" | grep -F "vendor/madr/template.md"
}

@test "sc3: a phantom third-party vendor path skips in a host run" {
  local host="$BATS_TEST_TMPDIR/host-sc3"
  build_scratch_host "$host" initialised
  printf '# Host\n\nSee vendor/madr/template.md for the template.\n' > "$host/README.md"
  stage_host "$host"
  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "vendor/madr/template.md"
}

# --- SC-4: placeholders and prose anti-examples are not extracted ------------

@test "sc4: placeholder forms and prose anti-examples are not flagged" {
  local doc="workflows/document-lifecycle.md" backup
  backup="$(backup_doc "$doc")"
  printf '\n- `vendor/conventional-agents/roles/<role>.md`\n' >> "$REPO_ROOT/$doc"
  printf -- '- `vendor/conventional-agents/vendor/...`\n' >> "$REPO_ROOT/$doc"
  printf -- '- a directory citation: vendor/conventional-agents/scripts/\n' >> "$REPO_ROOT/$doc"
  run run_check
  restore_doc "$doc" "$backup"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "<role>"
  ! echo "$output" | grep -F "vendor/..."
}

# --- SC-5: the #163 phantoms fail as non-backticked citations ----------------

@test "sc5: the five concrete #163 phantoms fail as non-backticked citations; the placeholder is not extracted" {
  local doc="INTEGRATION.md" backup
  backup="$(backup_doc "$doc")"
  cat >> "$REPO_ROOT/$doc" <<'EOF'

- vendor/conventional-agents/guidelines/tests.md
- vendor/conventional-agents/guidelines/commit-and-pr.md
- vendor/conventional-agents/guidelines/index.md
- vendor/conventional-agents/roles/test-writer.md
- vendor/conventional-agents/integrations/spec-kit.md
- vendor/conventional-agents/<REPO_URL>
- vendor/conventional-agents/guidelines/tests.md (repeated — reported once per document)
EOF
  run run_check
  restore_doc "$doc" "$backup"
  [ "$status" -ne 0 ]
  local ref
  for ref in \
    "vendor/conventional-agents/guidelines/tests.md" \
    "vendor/conventional-agents/guidelines/commit-and-pr.md" \
    "vendor/conventional-agents/guidelines/index.md" \
    "vendor/conventional-agents/roles/test-writer.md" \
    "vendor/conventional-agents/integrations/spec-kit.md"; do
    echo "$output" | grep -F "$ref"
  done
  # The sixth item is a placeholder — not extracted (SC-4's exemption).
  ! echo "$output" | grep -F "REPO_URL"
  # Multiple occurrences of one phantom path are reported once per document.
  [ "$(printf '%s' "$output" | grep -cF "references 'vendor/conventional-agents/guidelines/tests.md'")" -eq 1 ]
}

@test "sc5: the non-backticked extension also covers README.md and AGENTS.md" {
  local doc backup
  for doc in README.md AGENTS.md; do
    backup="$(backup_doc "$doc")"
    printf '\nPhantom: vendor/conventional-agents/guidelines/NEVER-EXISTED-SC5.md\n' >> "$REPO_ROOT/$doc"
    run run_check
    restore_doc "$doc" "$backup"
    [ "$status" -ne 0 ]
    echo "$output" | grep -F "$doc references 'vendor/conventional-agents/guidelines/NEVER-EXISTED-SC5.md'"
  done
}

# --- SC-6: the uninitialised exemption applies at the submodule --------------

@test "sc6: an uninitialised host submodule leaves prefixed references skipped" {
  local host="$BATS_TEST_TMPDIR/host-sc6-uninit"
  build_scratch_host "$host" uninitialised
  printf '# Host\n\nSee vendor/conventional-agents/guidelines/NEVER-EXISTED-HOST.md for details.\n' > "$host/README.md"
  stage_host "$host"
  run bash -c "cd '$host' && bash '$CHECK'"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "NEVER-EXISTED-HOST"
}

@test "sc6: an initialised host submodule is checked — the same phantom fails" {
  local host="$BATS_TEST_TMPDIR/host-sc6-init"
  build_scratch_host "$host" initialised
  printf '# Host\n\nSee vendor/conventional-agents/guidelines/NEVER-EXISTED-HOST.md for details.\n' > "$host/README.md"
  stage_host "$host"
  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "NEVER-EXISTED-HOST"
}

# --- SC-7: REF_EXEMPT / ref_exempt honoured exactly --------------------------

@test "sc7: a self-check REF_EXEMPT entry is honoured for a prefixed reference" {
  local check="$REPO_ROOT/scripts/check-status.sh"
  local doc="workflows/document-lifecycle.md"
  local check_backup doc_backup
  check_backup="$(mktemp)"
  doc_backup="$(backup_doc "$doc")"
  cp "$check" "$check_backup"
  # Insert one exemption in the array's documented "<doc>:<ref>  # reason"
  # format. Write in place (`cat >`) so the script's mode is preserved; restore
  # the same way.
  awk '{ print; if ($0 == "REF_EXEMPT=(") print "  \"workflows/document-lifecycle.md:vendor/conventional-agents/guidelines/EXEMPT-SC7.md\"  # consumer creates this" }' \
    "$check" > "$check.mod"
  cat "$check.mod" > "$check"
  rm -f "$check.mod"
  printf '\n`vendor/conventional-agents/guidelines/EXEMPT-SC7.md`\n' >> "$REPO_ROOT/$doc"
  run run_check
  cat "$check_backup" > "$check"
  restore_doc "$doc" "$doc_backup"
  rm -f "$check_backup"
  ! echo "$output" | grep -F "EXEMPT-SC7"
}

@test "sc7: a host ref_exempt entry is honoured for a prefixed reference" {
  local host="$BATS_TEST_TMPDIR/host-sc7"
  build_scratch_host "$host" initialised
  printf 'ref_exempt:\n  - "README.md:vendor/conventional-agents/guidelines/EXEMPT-SC7-HOST.md"\n' >> "$host/config/gates.yml"
  printf '# Host\n\nSee vendor/conventional-agents/guidelines/EXEMPT-SC7-HOST.md for details.\n' > "$host/README.md"
  stage_host "$host"
  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "EXEMPT-SC7-HOST"
}
