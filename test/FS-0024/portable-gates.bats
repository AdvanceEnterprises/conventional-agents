#!/usr/bin/env bats
# FS-0024 / ADR-0033 — portable governance gates.
#
# Every fixture-based test below builds a scratch host repository under
# BATS_TEST_TMPDIR (bats-provided, auto-cleaned per test) and vendors this
# repository's own scripts/ at vendor/conventional-agents via a symlink to
# REPO_ROOT. This is not a real git submodule, but it produces the same
# resolution shape a submodule would: the host's working directory has its own
# .git and never crosses into the symlinked target, so `git rev-parse
# --show-toplevel` resolves to the host, exactly as it would for a real
# submodule. Verified empirically before writing these tests (see PLAN-0024).

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  RUN_BATS="$REPO_ROOT/scripts/run-bats.sh"
  CURRENT_STATE="$REPO_ROOT/scripts/check-current-state.sh"
  SCRIPTS_README="$REPO_ROOT/scripts/README.md"
}

# --- fixture helpers ----------------------------------------------------------

# A scratch host repository with the minimal governed-document structure and
# this repository vendored at vendor/conventional-agents.
build_scratch_host() {
  local host="$1"
  mkdir -p "$host/docs/specifications" "$host/docs/change-plans" \
    "$host/docs/decisions" "$host/vendor"
  ( cd "$host" && git init -q )
  printf '# Specs\n\n| ID | Title | Status |\n| --- | --- | --- |\n' \
    > "$host/docs/specifications/README.md"
  printf '# Plans\n\n| ID | Title | Related Spec | Status |\n| --- | --- | --- | --- |\n' \
    > "$host/docs/change-plans/README.md"
  printf '# Decisions\n\n| ID | Title | Status |\n| --- | --- | --- |\n' \
    > "$host/docs/decisions/README.md"
  ln -sfn "$REPO_ROOT" "$host/vendor/conventional-agents"
}

# A deliberately broken spec: status implemented, no governing PLAN, no
# README index row. This is the exact reproduction from ADR-0033's Context
# section.
write_broken_spec() {
  local host="$1"
  cat > "$host/docs/specifications/FS-9001-scratch-defect.md" <<'EOF'
---
type: feature-spec
id: FS-9001
status: implemented
title: Scratch defect
owner: test
---
EOF
}

# --- target resolution ---------------------------------------------------------

@test "target_resolution: the pre-FS-0024 formula does not resolve to the host root" {
  # Positive control, per CONTRIBUTING.md's standard: prove the failure mode is
  # real before proving the fix addresses it. This reproduces the exact
  # pre-change formula (dirname "$0"-based) inline against the fixture's own
  # invocation shape, without depending on git history or a checked-out old
  # revision of the script.
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"

  local pre_fix_target
  pre_fix_target=$(cd "$host" && cd "$(dirname "vendor/conventional-agents/scripts/check-status.sh")/.." && pwd)

  [ "$pre_fix_target" != "$host" ]
}

@test "target_resolution: vendored check-status.sh detects host drift the pre-fix formula would have missed" {
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"
  write_broken_spec "$host"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-9001"
  ! echo "$output" | grep -qF "All status checks passed."
}

@test "target_resolution: resolution holds from a subdirectory of the host, not only its root" {
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"
  write_broken_spec "$host"
  mkdir -p "$host/some/nested/dir"

  run bash -c "cd '$host/some/nested/dir' && bash ../../../vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-9001"
}

@test "target_resolution: CA_TARGET_REPO overrides both the caller's cwd and the script's location" {
  local target="$BATS_TEST_TMPDIR/target"
  local elsewhere="$BATS_TEST_TMPDIR/elsewhere"
  build_scratch_host "$target"
  write_broken_spec "$target"
  mkdir -p "$elsewhere"

  run bash -c "cd '$elsewhere' && CA_TARGET_REPO='$target' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-9001"
}

@test "target_resolution: a relative CA_TARGET_REPO is canonicalized, not used as-is" {
  # Found in Copilot's review of #77: an uncanonicalized relative CA_TARGET_REPO
  # would make every $REPO_ROOT/... path below relative to the caller's cwd, not
  # the target. This host is at $BATS_TEST_TMPDIR/host; the override is passed as
  # a relative path from a sibling directory.
  local host="$BATS_TEST_TMPDIR/host"
  local elsewhere="$BATS_TEST_TMPDIR/elsewhere"
  build_scratch_host "$host"
  write_broken_spec "$host"
  mkdir -p "$elsewhere"

  run bash -c "cd '$elsewhere' && CA_TARGET_REPO='../host' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-9001"
}

@test "target_resolution: a CA_TARGET_REPO that is not a real directory fails loudly" {
  run bash -c "CA_TARGET_REPO='$BATS_TEST_TMPDIR/does-not-exist' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "CA_TARGET_REPO"
  echo "$output" | grep -qF "is not a directory"
}

@test "target_resolution: running outside a git work tree fails loudly instead of certifying nothing (issue #194)" {
  # Pre-fix, REPO_ROOT fell back to `pwd` outside any repository, the git-backed
  # rules failed in silence, and the script printed the success line — exit 0
  # from a directory that is not a repository at all. A CI job or maintainer in
  # the wrong working directory must see a loud error instead.
  local nongit="$BATS_TEST_TMPDIR/not-a-repo"
  mkdir -p "$nongit"

  run bash -c "cd '$nongit' && bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "not inside a git working tree"
  ! echo "$output" | grep -qF "All status checks passed."
}

@test "target_resolution: a CA_TARGET_REPO naming a subdirectory maps to the work-tree top level (issue #194 class, Copilot #198)" {
  # Copilot review, PR #198: a subdirectory path satisfies the
  # is-inside-work-tree membership check, but every document path roots at
  # the subdirectory — the loops then audit nothing and the script prints the
  # success line. Pre-fix this shape exited 0 with "All status checks
  # passed." against a target whose real documents (here: a broken spec at
  # the host root) were never examined. Post-fix the subdirectory maps to
  # the work-tree top level before any path is built.
  local host="$BATS_TEST_TMPDIR/host-subdir"
  build_scratch_host "$host"
  write_broken_spec "$host"
  mkdir -p "$host/some/nested/dir"

  run bash -c "cd '$REPO_ROOT' && CA_TARGET_REPO='$host/some/nested/dir' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-9001"
  ! echo "$output" | grep -qF "All status checks passed."
}

@test "target_resolution: this repository's own invocation is unaffected" {
  # npm run check:status shape: cwd already at the repository being checked,
  # no override. Must still exit zero on this repository's own (clean) trunk.
  run bash -c "cd '$REPO_ROOT' && bash scripts/check-status.sh"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "All status checks passed."
}

# --- self-check detection -------------------------------------------------------

@test "self_check: framework checking itself uses its own hardcoded reserved paths" {
  # No config/gates.yml exists anywhere in this repository (by design — see
  # ADR-0033). If self-check detection were broken, rule 6 would demand one
  # and fail closed on this repository's own approved-with-reserved-touches
  # plans. It does not.
  run bash -c "cd '$REPO_ROOT' && bash scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "cannot be certified for self-approval"
}

@test "self_check: a vendored copy does not fall back to this repository's hardcoded values" {
  # A host repository with no config/gates.yml, and a plan touching a path
  # that IS reserved in this repository's own hardcoded set (scripts/) but
  # is not this host's declared interfaces. If the vendored copy silently
  # used this repository's own hardcoded RESERVED_PATHS, the touch would be
  # flagged as reserved rather than as unconfigured — the wrong error.
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"
  cat > "$host/docs/specifications/FS-1-test.md" <<'EOF'
---
type: feature-spec
id: FS-1
status: approved
title: Test
owner: test
interfaces:
  - "src/"
---
EOF
  printf '| FS-1 | Test | approved |\n' >> "$host/docs/specifications/README.md"
  cat > "$host/docs/change-plans/PLAN-1-test.md" <<'EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-1]
touches:
  - scripts/deploy.sh
---
EOF
  printf '| PLAN-1 | Test | FS-1 | approved |\n' >> "$host/docs/change-plans/README.md"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot be certified for self-approval"
  echo "$output" | grep -qF "reserved_paths"
  ! echo "$output" | grep -qF "is in ADR-0027's reserved-path set"
}

# --- fail-closed configuration (rule 6) ------------------------------------------

# Shared fixture for the rule-6 tests: a host with one FS (interfaces: ci/)
# and one PLAN (touches: ci/deploy.sh) at approved with no human-approval
# evidence.
build_rule6_fixture() {
  local host="$1"
  build_scratch_host "$host"
  cat > "$host/docs/specifications/FS-1-test.md" <<'EOF'
---
type: feature-spec
id: FS-1
status: approved
title: Test
owner: test
interfaces:
  - "ci/"
---
EOF
  printf '| FS-1 | Test | approved |\n' >> "$host/docs/specifications/README.md"
  cat > "$host/docs/change-plans/PLAN-1-test.md" <<'EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-1]
touches:
  - ci/deploy.sh
---
EOF
  printf '| PLAN-1 | Test | FS-1 | approved |\n' >> "$host/docs/change-plans/README.md"
}

@test "rule6: no config/gates.yml at all refuses to certify self-approval" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot be certified for self-approval"
  echo "$output" | grep -qF "reserved_paths"
  echo "$output" | grep -qF "PLAN-1-test.md"
}

@test "rule6: config/gates.yml present but missing the reserved_paths key also refuses" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"
  mkdir -p "$host/config"
  printf 'exported_prefixes: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot be certified for self-approval"
}

@test "rule6: explicit reserved_paths: [] is honored — plan self-approves via interfaces containment" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "cannot be certified for self-approval"
  ! echo "$output" | grep -qF "requires human approval"
}

@test "rule6: a configured reserved path is enforced exactly as the hardcoded set is for self-check" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"
  mkdir -p "$host/config"
  printf 'reserved_paths:\n  - "ci/"\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ci/deploy.sh"
  echo "$output" | grep -qF "reserved-path set"
  ! echo "$output" | grep -qF "cannot be certified for self-approval"
}

@test "rule6: an inline-list reserved_paths (with quotes) is enforced, not silently ignored" {
  # Found in Copilot's review of #77: get_flat_list_field's inline-list branch did
  # not strip quotes, so `reserved_paths: ["ci/"]` emitted the literal string
  # '"ci/"' (quotes included), which never matched a bare touched path by prefix —
  # the reserved path silently stopped being reserved.
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"
  mkdir -p "$host/config"
  printf 'reserved_paths: ["ci/"]\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ci/deploy.sh"
  echo "$output" | grep -qF "reserved-path set"
}

# --- governing-spec requirement (FS-0022 §2: no draft-governed self-approval) -----

@test "rule6: a self-approved plan with no governing spec fails instead of skipping" {
  local host="$BATS_TEST_TMPDIR/host-nospec"
  build_rule6_fixture "$host"
  sed -i '/^related_specs:/d' "$host/docs/change-plans/PLAN-1-test.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "no related_specs"
  echo "$output" | grep -qF "PLAN-1-test.md"
}

@test "rule6: a self-approved plan whose governing FS is draft fails" {
  local host="$BATS_TEST_TMPDIR/host-draftfs"
  build_rule6_fixture "$host"
  sed -i 's/^status: approved$/status: draft/' "$host/docs/specifications/FS-1-test.md"
  sed -i 's/| FS-1 | Test | approved |/| FS-1 | Test | draft |/' "$host/docs/specifications/README.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "status: draft"
  echo "$output" | grep -qF "FS-1"
}

@test "rule6: a self-approved plan referencing a nonexistent spec fails" {
  local host="$BATS_TEST_TMPDIR/host-nofs"
  build_rule6_fixture "$host"
  sed -i 's/FS-1/FS-9001/' "$host/docs/change-plans/PLAN-1-test.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "no spec with that id exists"
}

@test "rule6: a self-approved plan against a non-draft (in-progress) FS still certifies" {
  # Non-draft acceptance: rule 6's governing-spec condition rejects only `draft`
  # (and missing). An `implemented` FS would trip rule 1 unless the plan is also
  # implemented — but implemented plans skip rule 6, so the positive fixture uses
  # `in-progress`, the other forward status.
  local host="$BATS_TEST_TMPDIR/host-implfs"
  build_rule6_fixture "$host"
  sed -i 's/^status: approved$/status: in-progress/' "$host/docs/specifications/FS-1-test.md"
  sed -i 's/^status: approved$/status: in-progress/' "$host/docs/change-plans/PLAN-1-test.md"
  sed -i 's/| FS-1 | Test | approved |/| FS-1 | Test | in-progress |/' "$host/docs/specifications/README.md"
  sed -i 's/| PLAN-1 | Test | FS-1 | approved |/| PLAN-1 | Test | FS-1 | in-progress |/' "$host/docs/change-plans/README.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "requires human approval"
}

@test "rule6: a draft SECONDARY spec supplying part of the union fails self-approval" {
  # Every referenced spec contributes interfaces to the containment union, so a
  # draft secondary spec's interfaces would otherwise supply part of the boundary
  # without a human having drawn it (the residual C-23 shape: an approved spec
  # first, a draft boundary second).
  local host="$BATS_TEST_TMPDIR/host-mixed"
  build_rule6_fixture "$host"
  cat > "$host/docs/specifications/FS-2-test.md" <<'EOF'
---
type: feature-spec
id: FS-2
status: draft
title: Test2
owner: test
interfaces:
  - "src/"
---
EOF
  printf '| FS-2 | Test2 | draft |\n' >> "$host/docs/specifications/README.md"
  sed -i 's/related_specs: \[FS-1\]/related_specs: [FS-1, FS-2]/' "$host/docs/change-plans/PLAN-1-test.md"
  sed -i 's|  - ci/deploy.sh|  - src/unapproved.sh|' "$host/docs/change-plans/PLAN-1-test.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-2"
  echo "$output" | grep -qF "status: draft"
}

@test "rule6: a multi-spec plan whose specs are all non-draft certifies" {
  local host="$BATS_TEST_TMPDIR/host-multiok"
  build_rule6_fixture "$host"
  cat > "$host/docs/specifications/FS-2-test.md" <<'EOF'
---
type: feature-spec
id: FS-2
status: approved
title: Test2
owner: test
interfaces:
  - "src/"
---
EOF
  printf '| FS-2 | Test2 | approved |\n' >> "$host/docs/specifications/README.md"
  sed -i 's/related_specs: \[FS-1\]/related_specs: [FS-1, FS-2]/' "$host/docs/change-plans/PLAN-1-test.md"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "cannot be certified for self-approval"
}

# --- grandfather clause scoping (issue #195) -------------------------------------

@test "grandfather: a consumer PLAN-0001 gets no exemption from the framework's historical allow-list (issue #195)" {
  # The allow-list names THIS repository's pre-ADR-0027 plans, but it applied in
  # consumer runs too — silently skipping containment and reserved-path checks on
  # a host's first seventeen plan numbers, which is where the check is most
  # needed. Post-fix the clause is self-check-only: the same plan content fails
  # loudly in a consumer, evaluated against the host's own reserved set.
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"
  mkdir -p "$host/config"
  printf 'reserved_paths:\n  - "config/"\n' > "$host/config/gates.yml"
  cat > "$host/docs/specifications/FS-1-test.md" <<'EOF'
---
type: feature-spec
id: FS-1
status: approved
title: Test
owner: test
interfaces: []
---
EOF
  printf '| FS-1 | Test | approved |\n' >> "$host/docs/specifications/README.md"
  cat > "$host/docs/change-plans/PLAN-0001-first-consumer-plan.md" <<'EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-1]
touches:
  - config/gates.yml
---
EOF
  printf '| PLAN-0001 | First consumer plan | FS-1 | approved |\n' >> "$host/docs/change-plans/README.md"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "PLAN-0001-first-consumer-plan.md"
  echo "$output" | grep -qF "reserved-path set"
  ! echo "$output" | grep -qF "All status checks passed."
}

@test "grandfather: a consumer PLAN-0001 outside its FS interfaces is flagged, not skipped (issue #195)" {
  # The containment half of the same skip: with an explicit empty reserved set,
  # the touch must still be evaluated against the governing FS's interfaces.
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"
  mkdir -p "$host/config"
  printf 'reserved_paths: []\n' > "$host/config/gates.yml"
  cat > "$host/docs/specifications/FS-1-test.md" <<'EOF'
---
type: feature-spec
id: FS-1
status: approved
title: Test
owner: test
interfaces:
  - "ci/"
---
EOF
  printf '| FS-1 | Test | approved |\n' >> "$host/docs/specifications/README.md"
  cat > "$host/docs/change-plans/PLAN-0001-outside-interfaces.md" <<'EOF'
---
type: change-plan
role: implementer
status: approved
related_specs: [FS-1]
touches:
  - src/other.sh
---
EOF
  printf '| PLAN-0001 | Outside | FS-1 | approved |\n' >> "$host/docs/change-plans/README.md"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "outside its governing FS's interfaces"
}

# --- skip-explicit configuration (rule 7) ----------------------------------------

build_rule7_fixture() {
  local host="$1"
  build_scratch_host "$host"
  printf '# Changelog\n\n## Unreleased\n' > "$host/CHANGELOG.md"
  cat > "$host/docs/specifications/FS-1-test.md" <<'EOF'
---
type: feature-spec
id: FS-1
status: approved
title: Test
owner: test
interfaces:
  - "public/"
---
EOF
  printf '| FS-1 | Test | approved |\n' >> "$host/docs/specifications/README.md"
}

@test "rule7: no config/gates.yml skips visibly, distinct from a clean pass" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule7_fixture "$host"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "SKIP: rule 7"
  echo "$output" | grep -qF "no exported_prefixes configured"
}

@test "rule7: explicit exported_prefixes: [] also skips, same as absent" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule7_fixture "$host"
  mkdir -p "$host/config"
  printf 'exported_prefixes: []\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "SKIP: rule 7"
}

@test "rule7: a configured exported prefix is enforced — missing CHANGELOG entry fails" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule7_fixture "$host"
  mkdir -p "$host/config"
  printf 'exported_prefixes:\n  - "public/"\n' > "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "FS-1"
  echo "$output" | grep -qF "no CHANGELOG entry naming it"
  ! echo "$output" | grep -qF "SKIP: rule 7"
}

@test "rule7: a configured exported prefix with a matching CHANGELOG entry passes" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule7_fixture "$host"
  mkdir -p "$host/config"
  printf 'exported_prefixes:\n  - "public/"\n' > "$host/config/gates.yml"
  printf '\n- FS-1 ships a thing.\n' >> "$host/CHANGELOG.md"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "no CHANGELOG entry"
}

# --- absent config produces no stderr noise --------------------------------------

@test "no_config: an entirely absent config/gates.yml produces no awk 'can't open file' noise" {
  local host="$BATS_TEST_TMPDIR/host"
  build_scratch_host "$host"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  ! echo "$output" | grep -qF "can't open file"
  ! echo "$output" | grep -qi "no such file or directory"
}

# --- scripts/ reclassification --------------------------------------------------

@test "reclassification: README.md exported-surface table lists scripts/" {
  assert_file_contains "$REPO_ROOT/README.md" "\`scripts/\`"
}

@test "reclassification: AGENTS.md exported-surface column lists scripts/" {
  local table
  table=$(awk '/Exported Surface vs Internal Governance/{f=1} f{print} f&&/^###/&&!/Exported Surface/{if(c++>0) exit}' "$REPO_ROOT/AGENTS.md")
  echo "$table" | grep -qF '`scripts/`'
}

@test "reclassification: check-status.sh self-check EXPORTED_PREFIXES includes scripts/" {
  local block
  block=$(awk '/^EXPORTED_PREFIXES=\(/{f=1;next} f&&/^\)/{exit} f' "$CHECK")
  echo "$block" | grep -qF '"scripts/"'
}

@test "reclassification: docs/specifications/README.md exported-surface list names scripts/" {
  assert_file_contains "$REPO_ROOT/docs/specifications/README.md" "\`scripts/\`"
}

# --- documentation ---------------------------------------------------------------

@test "docs: scripts/README.md documents CA_TARGET_REPO" {
  assert_file_contains "$SCRIPTS_README" "CA_TARGET_REPO"
}

@test "docs: scripts/README.md documents the FRAMEWORK_HOME self-check comparison" {
  assert_file_contains "$SCRIPTS_README" "FRAMEWORK_HOME"
}

@test "docs: scripts/README.md documents config/gates.yml and where it is sourced from" {
  assert_file_contains "$SCRIPTS_README" "config/gates.yml"
  assert_file_contains "$SCRIPTS_README" "config/gates.example.yml"
  assert_file_contains "$SCRIPTS_README" "never a path inside"
}

@test "docs: scripts/README.md states which of rules 6/7 fails closed and which skips, and why" {
  assert_file_contains "$SCRIPTS_README" "cannot self-approve anything"
  assert_file_contains "$SCRIPTS_README" "does not fail closed"
}

@test "docs: config/gates.example.yml does not set reserved_paths live — a straight copy stays fail-closed" {
  # Found in Copilot's review of #77: the template set reserved_paths: [] live,
  # which a straight `cp` would turn into an explicit (honored) empty reserved
  # set — the least safe configuration — contradicting its own comment telling
  # readers to leave it unset. The key must be commented out by default.
  ! grep -qE '^reserved_paths:' "$REPO_ROOT/config/gates.example.yml"
  assert_file_contains "$REPO_ROOT/config/gates.example.yml" "# reserved_paths: []"
}

@test "rule6: a straight copy of config/gates.example.yml preserves fail-closed behavior" {
  local host="$BATS_TEST_TMPDIR/host"
  build_rule6_fixture "$host"
  mkdir -p "$host/config"
  cp "$REPO_ROOT/config/gates.example.yml" "$host/config/gates.yml"

  run bash -c "cd '$host' && bash vendor/conventional-agents/scripts/check-status.sh"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot be certified for self-approval"
}

@test "docs: config/gates.example.yml exists and carries the consumer-copy template header" {
  assert_file_exists "$REPO_ROOT/config/gates.example.yml"
  assert_file_contains "$REPO_ROOT/config/gates.example.yml" "THIS IS A CONSUMER-COPY TEMPLATE"
}

@test "docs: config/gates.example.yml is never referenced as if it were read directly by the scripts" {
  # The scripts read config/gates.yml (the consumer's own copy), never the
  # .example file. A stray reference to reading the example directly would be
  # a real bug in the documentation.
  ! grep -q 'GATES_CONFIG=.*\.example\.yml' "$CHECK"
}

# --- check-current-state.sh and run-bats.sh accept the same override -------------

@test "check_current_state: accepts CA_TARGET_REPO and it is documented as symmetry, not a fix" {
  assert_file_contains "$CURRENT_STATE" "CA_TARGET_REPO"
}

@test "check_current_state: default (no override) behavior is unchanged — still resolves via git rev-parse" {
  assert_file_contains "$CURRENT_STATE" "git rev-parse --show-toplevel"
}

@test "run_bats: REPO_ROOT resolution no longer uses dirname \"\$0\"" {
  ! grep -q 'REPO_ROOT="\$(cd "\$(dirname "\$0")/\.\." && pwd)"' "$RUN_BATS"
  assert_file_contains "$RUN_BATS" "CA_TARGET_REPO"
}

@test "check_status: REPO_ROOT resolution no longer uses dirname \"\$0\" as the target" {
  # FRAMEWORK_HOME is allowed to keep the old formula — it is now a
  # self-locator, not a target-resolver. REPO_ROOT itself must not.
  ! grep -qE '^REPO_ROOT="\$\(cd "\$\(dirname "\$0"\)/\.\." && pwd\)"' "$CHECK"
  assert_file_contains "$CHECK" "git rev-parse --show-toplevel"
}
