#!/usr/bin/env bats
# FS-0034 — consumer-conformance doctor (scripts/check-conformance.sh).
#
# FS-0034 declares test_required: true. This suite covers the prototype's
# success criteria: presence detection, anchor checks, dangling-reference
# detection, status-gate wiring, CI wiring, JSON output, and exit codes.
#
# Isolation: every test builds a scratch repo under BATS_TEST_TMPDIR
# (bats-provided, auto-cleaned per test) and COPIES the script into it.
# The script resolves its target from the caller's cwd (FS-0024/ADR-0033),
# so tests run it from the scratch root. Copying, not symlinking, matters:
# a symlink would resolve the script's own location into the real
# repository, defeating the caller-relative target resolution.

load "../FS-0001/helpers.bash"

setup() {
  # Self-locating source (same pattern as FS-0026 suite): BATS_TEST_DIRNAME
  # points at this suite's file wherever bats is invoked from.
  CHECK_CONFORMANCE="$BATS_TEST_DIRNAME/../../scripts/check-conformance.sh"
  [ -f "$CHECK_CONFORMANCE" ] || {
    echo "check-conformance.sh not found near $BATS_TEST_DIRNAME"
    return 1
  }
}

# --- fixture helpers ----------------------------------------------------------

refute_output_contains() {
  if grep -F -q -- "$1" <<<"$output"; then
    echo "expected output NOT to contain: $1"
    return 1
  fi
}

# Scratch repo with the doctor script copied in and a minimal consumer layout.
build_scratch() {
  local scratch="$1"
  mkdir -p "$scratch/scripts" "$scratch/vendor/conventional-agents" \
           "$scratch/.github/workflows"
  cp "$CHECK_CONFORMANCE" "$scratch/scripts/check-conformance.sh"
  ( cd "$scratch" && git init -q )
}

# A conformant consumer fixture: AGENTS.md with anchors, vendored AGENTS.md
# with a version line, the referenced vendored files, a vendored status-gate
# stub, and a CI workflow running the gate.
write_conformant_fixture() {
  local scratch="$1"
  cat > "$scratch/AGENTS.md" <<'EOF'
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md
EOF
  cat > "$scratch/vendor/conventional-agents/AGENTS.md" <<'EOF'
# conventional-agents

**Framework Version:** 2.1.0
EOF
  cat > "$scratch/vendor/conventional-agents/INTEGRATION.md" <<'EOF'
# Integration Guide
EOF
  mkdir -p "$scratch/vendor/conventional-agents/guidelines" \
           "$scratch/vendor/conventional-agents/scripts"
  cat > "$scratch/vendor/conventional-agents/guidelines/ROLE_CONTRACT.md" <<'EOF'
# Role Contract
EOF
  cat > "$scratch/vendor/conventional-agents/scripts/check-status.sh" <<'EOF'
#!/usr/bin/env bash
# Stub vendored gate for the conformant fixture.
exit 0
EOF
  chmod +x "$scratch/vendor/conventional-agents/scripts/check-status.sh"
  cat > "$scratch/.github/workflows/governance.yml" <<'EOF'
name: governance
on: [push, pull_request]
jobs:
  check-status:
    runs-on: ubuntu-latest
    steps:
      - run: bash vendor/conventional-agents/scripts/check-status.sh
EOF
}

# --- criterion 1: conformant consumer reports OK ------------------------------

@test "conformance: conformant consumer reports OK with exit 0" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/ok.XXXXXX")"
  build_scratch "$scratch"
  write_conformant_fixture "$scratch"

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 0 ]
  assert_file_contains <(printf '%s' "$output") "conformance: OK"
}

# --- criterion 2: missing framework is a critical finding ---------------------

@test "conformance: missing vendored framework is a critical finding, exit 1" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/nofw.XXXXXX")"
  build_scratch "$scratch"
  # No vendor/conventional-agents content at all.

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 1 ]
  assert_file_contains <(printf '%s' "$output") "framework-presence"
  assert_file_contains <(printf '%s' "$output") "critical"
}

# --- criterion 3: dangling reference detection ---------------------------------

@test "conformance: dangling vendor reference in AGENTS.md is reported" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/dangling.XXXXXX")"
  build_scratch "$scratch"
  write_conformant_fixture "$scratch"
  # Break the anchor: reference a file that does not exist.
  cat > "$scratch/AGENTS.md" <<'EOF'
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/guidelines/DOES_NOT_EXIST.md
EOF

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 1 ]
  assert_file_contains <(printf '%s' "$output") "dangling-reference"
  assert_file_contains <(printf '%s' "$output") "DOES_NOT_EXIST.md"
}

# --- criterion 3b: prose-only mentions are NOT dangling references -------------

@test "conformance: prose-only vendor mention is not a dangling reference" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/prose.XXXXXX")"
  build_scratch "$scratch"
  write_conformant_fixture "$scratch"
  # The framework is mentioned only in prose — an intent note, not a declared
  # local reference. Only markdown links and list items are checked.
  cat > "$scratch/AGENTS.md" <<'EOF'
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md

For precedence rules see vendor/conventional-agents/INTEGRATION.md (the
consumer may reference vendor/conventional-agents/roles/ROLE_CONTRACT.md
as documentation intent without vendoring that path).
EOF

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 0 ]
  refute_output_contains "dangling-reference"
}

# --- criterion 4: missing AGENTS.md anchor is reported -------------------------

@test "conformance: AGENTS.md without framework reference is reported" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/noanchor.XXXXXX")"
  build_scratch "$scratch"
  write_conformant_fixture "$scratch"
  cat > "$scratch/AGENTS.md" <<'EOF'
# Agent Instructions

No framework references here.
EOF

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 1 ]
  assert_file_contains <(printf '%s' "$output") "anchors"
}

# --- criterion 5: CI wiring detection ------------------------------------------

@test "conformance: missing governance CI workflow is reported" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/noci.XXXXXX")"
  build_scratch "$scratch"
  write_conformant_fixture "$scratch"
  rm -rf "$scratch/.github/workflows"

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh"
  [ "$status" -eq 1 ]
  assert_file_contains <(printf '%s' "$output") "ci-wiring"
}

# --- criterion 6: JSON output is machine-readable ------------------------------

@test "conformance: --json emits parseable JSON with finding count" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/json.XXXXXX")"
  build_scratch "$scratch"
  # No framework, no AGENTS.md — several findings expected.

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh --json"
  [ "$status" -eq 1 ]
  python3 -c "
import json, sys
d = json.loads('''$output''')
assert d['tool'] == 'check-conformance', d
assert d['conformant'] is False, d
assert d['finding_count'] == len(d['findings']), d
assert d['finding_count'] >= 2, d
"
}

# --- criterion 7: self-check mode skips presence checks ------------------------

@test "conformance: self-check (target == framework) runs without vendor presence finding" {
  # Run from the framework's own root: presence checks are skipped, so the
  # only possible findings are anchor/status/CI ones — never framework-presence.
  run bash "$CHECK_CONFORMANCE"
  [ "$status" -eq 0 ] || {
    # If the framework itself has findings, they must not include presence.
    refute_output_contains "framework-presence"
  }
}

refute_output_contains() {
  if grep -F -q -- "$1" <<<"$output"; then
    echo "expected output NOT to contain: $1"
    return 1
  fi
}

# --- argument validation -------------------------------------------------------

@test "conformance: unknown argument exits 2" {
  local scratch
  scratch="$(mktemp -d "${BATS_TEST_TMPDIR}/badarg.XXXXXX")"
  build_scratch "$scratch"

  run bash -c "cd '$scratch' && bash scripts/check-conformance.sh --bogus"
  [ "$status" -eq 2 ]
}

@test "conformance: --help exits 0 and prints usage" {
  run bash "$CHECK_CONFORMANCE" --help
  [ "$status" -eq 0 ]
  assert_file_contains <(printf '%s' "$output") "Usage"
}
