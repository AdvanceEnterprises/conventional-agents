---
updated: 2026-07-29
---

# Bash Testing Guide

This document provides **authoritative guidance for coding agents** when writing or reviewing tests for bash scripts in this repository.

It applies to **Role 1: Spec Reader and Test Planner** and **Role 3: Reviewer**.

If there is a conflict between this guide and a prompt, **this guide wins**.

---

## Scope

This guide covers:

* How to parse and interpret Bash test files
* How Feature Specs map to shell tests
* Approved patterns for testing shell scripts
* The preferred pattern for handling ambiguity in specs
* Shell-specific testing considerations

It does NOT define general Bash programming or testing frameworks in detail.

---

## Parsing Guidance for Codex Skills

### Authoritative signals

Agents MUST rely on the following, in order:

1. Test file docstring metadata (YAML-like block)
2. `PARSING_HINTS` blocks inside test file docstrings
3. Feature Spec front matter and parsing hints
4. The body of the Feature Spec

If these conflict, stop and escalate to a human.

---

### Test file metadata expectations

Each bash test file (bats or shell-based) SHOULD include a header with:

```bash
#!/usr/bin/env bats
#
# Test suite for pod-up script
#
# ---
# type: test-module
# language: bash
# framework: bats (or: shell-integration, shunit2)
# spec_id: FS-XXXX
# scope: unit | integration
# ---
```text

Agents MUST:

* Use `spec_id` to locate the authoritative Feature Spec
* Refuse to write tests if the spec status is not `approved`
* Treat missing or malformed metadata as a stop condition
* Ensure test framework matches the project conventions

---

## Test Framework Expectations

The repository uses bash-centric testing. Default expectations:

* **Unit tests**: `bats` (Bash Automated Testing System)
  * File extension: `test.bats`
  * Simple syntax, bash-native assertions
  * Useful for isolated function testing

* **Integration tests**: Shell scripts with explicit test functions
  * File extension: `*_test.sh` or `*_integration.sh`
  * Can test full scripts with real dependencies
  * Useful for end-to-end workflows

* **Assertion patterns**: Use simple bash conditionals and bats assertions

If the project uses a different framework (shunit2, bash-unit), follow its conventions.

---

## Success Criteria Mapping

### Mapping rules

* Each bullet in `## Success Criteria` MUST map to at least one test
* Success Criteria text MUST be referenced in the test as a comment
* Test names MUST be descriptive and include the SC identifier when clear
* Tests MUST NOT validate behavior not explicitly stated in the spec

Example mapping:

```bash
# Spec: "The script exits with code 1 if the pod already exists"
# (Success Criterion: SC-2)
@test "pod-up exits with code 1 if pod already exists" {
    # Setup: create a pod first
    podman pod create test-pod || true

    # Test: pod-up should fail
    run ops/scripts/pod-up
    [ "$status" -eq 1 ]

    # Cleanup
    podman pod rm test-pod || true
}
```text

### Ambiguity handling

If a Success Criterion is ambiguous, incomplete, or untestable:

```bash
# Test: Ambiguous criterion from FS-XXXX (SC-5)
@test "XFAIL: Spec unclear on retry behavior - FS-XXXX SC-5" {
    skip "Spec does not define retry count or backoff strategy"
}
```text

Rules:

* Always reference the spec ID and SC number
* Use `skip` (bats) or `@Ignore` (shunit2) for ambiguous tests
* Do NOT attempt to infer intended behavior
* This forces clarification in the spec

---

## Approved Test Patterns

### Unit test pattern (bats)

```bash
#!/usr/bin/env bats
#
# Tests for helper functions in pod-up
#
# ---
# type: test-module
# language: bash
# framework: bats
# spec_id: FS-POD-UP
# scope: unit
# ---

# Source the script being tested
source "ops/scripts/pod-up"

@test "error function exits with code 1" {
    run error "test message"
    [ "$status" -eq 1 ]
}

@test "error function prints to stderr" {
    run error "test message" 2>&1
    [[ "$output" == *"ERROR: test message"* ]]
}
```text

### Parametrized test pattern (bats)

Use bats parametrization for multiple test cases:

```bash
@test "port availability check - valid port 8080" {
    # Assumes port 8080 is free
    run check_port_available 8080
    [ "$status" -eq 0 ]
}

@test "port availability check - invalid port 0" {
    run check_port_available 0
    [ "$status" -ne 0 ]
}

@test "port availability check - invalid port 65536" {
    run check_port_available 65536
    [ "$status" -ne 0 ]
}
```text

Or use a loop with test data:

```bash
@test "validate pod name - valid names" {
    local valid_names=("app-dev" "myapp-test" "xyz-prod")

    for name in "${valid_names[@]}"; do
        run validate_pod_name "$name"
        [ "$status" -eq 0 ] || fail "Failed for: $name"
    done
}
```text

### Integration test pattern (shell script)

For testing the full script with real dependencies:

```bash
#!/usr/bin/env bash
#
# Integration tests for pod-up script
#
# ---
# type: test-module
# language: bash
# framework: shell-integration
# spec_id: FS-POD-UP
# scope: integration
# ---

set -euo pipefail

# Cleanup function (runs before and after)
cleanup() {
    podman pod rm test-app-dev >/dev/null 2>&1 || true
}

trap cleanup EXIT
cleanup  # Clean before starting

# Test: Pod creation
test_pod_creation() {
    export ENV=dev
    export APP_NAME=test-app
    # ... other required env vars ...

    # Run the script
    if ops/scripts/pod-up; then
        echo "✓ Test passed: pod-up created pod"
        podman pod exists test-app-dev || { echo "✗ Pod not found"; exit 1; }
    else
        echo "✗ Test failed: pod-up exited with non-zero"
        exit 1
    fi
}

# Run all tests
test_pod_creation
# ... other tests ...

echo "All integration tests passed"
```text

---

## Test Structure Best Practices

### Setup and teardown

Use bats setup/teardown for per-test preparation:

```bash
setup() {
    # Run before each test
    export TEST_TMP_DIR=$(mktemp -d)
    export SCRIPT_UNDER_TEST="ops/scripts/pod-up"
}

teardown() {
    # Run after each test
    rm -rf "$TEST_TMP_DIR"
    # Kill any pods created during test
    podman pod rm test-* >/dev/null 2>&1 || true
}

@test "test that needs setup" {
    [ -d "$TEST_TMP_DIR" ]
}
```text

### Fixtures and test data

Create test data files:

```bash
@test "script processes config file correctly" {
    # Create a test config
    cat > "$TEST_TMP_DIR/test.env" <<EOF
APP_NAME=testapp
PORT=3000
EOF

    run ops/scripts/parse-config "$TEST_TMP_DIR/test.env"
    [ "$status" -eq 0 ]
    [[ "$output" == *"APP_NAME=testapp"* ]]
}
```text

### Mocking and isolation

For tests that need to avoid real operations:

```bash
@test "migration runs when required in test env" {
    export ENV=test
    export MIGRATE_CMD="echo 'Running migrations'"

    # Mock podman to avoid creating real pods
    mock_podman() {
        if [[ "$1" == "pod" ]] && [[ "$2" == "create" ]]; then
            echo "pod-created"
        else
            /usr/bin/podman "$@"
        fi
    }

    # Source script with mocked podman
    # (or test the migration logic separately from pod logic)
    ...
}
```text

---

## Assertions and Test Clarity

### Bats assertion patterns

```bash
# Exit code checks
[ "$status" -eq 0 ]         # Success
[ "$status" -eq 1 ]         # Failure
[ "$status" -ne 0 ]         # Any error

# Output checks
[ -z "$output" ]            # Empty output
[ -n "$output" ]            # Non-empty output
[[ "$output" == *"text"* ]] # Contains text
[[ "$output" =~ regex ]]    # Matches regex
[ "${#lines[@]}" -eq 3 ]    # Number of lines

# File checks (from within test)
[ -f "$file" ]              # File exists
[ -d "$dir" ]               # Directory exists
[ -s "$file" ]              # File has content

# Assertions with messages
[ "$actual" = "$expected" ] || fail "Expected $expected, got $actual"
```text

### Clear test names

```bash
# ✅ Good: Describes what is being tested
@test "pod-up creates pod with correct name" { ... }
@test "pod-down preserves volumes by default" { ... }
@test "migrate exits with error if MIGRATE_CMD not set" { ... }

# ❌ Avoid: Unclear or too specific
@test "test pod" { ... }
@test "function works" { ... }
@test "input handling" { ... }
```text

---

## Integration Test Guidance

Integration tests SHOULD:

* Be few in number (focus on critical paths)
* Be deterministic (not flaky, no random delays)
* Use isolated test data (tmp directories, test pod names)
* Use `trap` for cleanup (even if tests fail)
* Document dependencies (e.g., "requires Podman 4.0+")

Integration tests MUST:

* Be marked or grouped separately from unit tests
* Be traceable to a Feature Spec via comments
* Not require network access unless explicitly needed
* Clean up after themselves (no leftover pods, files, etc.)
* Be runnable on CI systems

Example:

```bash
#!/usr/bin/env bash
# Integration tests for pod-up
# Requires: Podman 4.0+, psql client
# Time: ~30 seconds

set -euo pipefail

export TEST_APP_NAME="test-app-$$"  # Use PID for isolation
export ENV=dev

cleanup() {
    podman pod rm "$TEST_APP_NAME-$ENV" >/dev/null 2>&1 || true
}

trap cleanup EXIT

# Test
ops/scripts/pod-up || { echo "pod-up failed"; exit 1; }
podman pod exists "$TEST_APP_NAME-$ENV" || { echo "Pod not created"; exit 1; }

echo "✓ Integration test passed"
```text

---

## Reviewer Checklist (Bash Tests)

When acting as Reviewer, agents SHOULD check:

* Every Success Criterion has at least one test
* No test exists without a corresponding spec reference
* No behavior is validated that is not documented
* Ambiguities are surfaced via `skip` or xfail, not hidden
* Tests are isolated (no side effects between tests)
* Tests clean up after themselves
* Test names are clear and describe what is tested
* Scripts use `set -euo pipefail` (strict mode)
* Variables are quoted and properly scoped
* Error messages in tests are helpful for debugging

---

## Common Bash Testing Pitfalls

### ❌ Pitfall: Tests that depend on state

```bash
# Bad: State carries over between tests
pod_name=""

@test "create pod" {
    run ops/scripts/pod-up
    pod_name="created-pod"  # Global state!
}

@test "pod exists" {
    # Depends on previous test running first
    run podman pod exists "$pod_name"
    [ "$status" -eq 0 ]
}
```text

**Fix**: Use setup/teardown, not shared state

### ❌ Pitfall: Non-deterministic tests

```bash
# Bad: Uses current time, random delays
@test "backup is recent" {
    sleep 5  # Non-deterministic
    ls -lt /backups | head -1
}
```text

**Fix**: Mock time or use fixed test data

### ❌ Pitfall: Flaky cleanup

```bash
# Bad: Cleanup might not run
@test "create and remove pod" {
    podman pod create test-pod
    [ ... test ... ]
    podman pod rm test-pod
}
```text

**Fix**: Use `trap` to guarantee cleanup

### ✅ Correct approach

```bash
@test "create pod" {
    # Each test is isolated
    local test_pod="test-pod-$$"

    trap "podman pod rm '$test_pod' >/dev/null 2>&1" EXIT

    run podman pod create "$test_pod"
    [ "$status" -eq 0 ]
}
```text

---

## Test Naming and Organization

### File organization

```text
tests/
├── unit/
│   ├── test_pod_up.bats          # Unit tests for pod-up functions
│   └── test_pod_down.bats        # Unit tests for pod-down
└── integration/
    ├── test_pod_lifecycle.sh     # Full pod start/stop cycle
    └── test_backup_restore.sh    # Backup and restore workflow
```text

### Test naming

**Bats format:**

```text
@test "pod-up exits with code 0 on success" { ... }
@test "pod-up exits with code 1 if pod exists" { ... }
```text

**Shell format:**

```bash
test_pod_up_creates_pod() { ... }
test_pod_up_fails_if_exists() { ... }
```text

---

## Final Notes

If writing a test feels creative, pause.

If writing a test requires guessing behavior, stop.

The test suite is executable documentation of what the script should do. Treat it with the same care as specifications.

Tests should:

* Be readable
* Be maintainable
* Be trustworthy
* Exercise the real code path (not mocked away)
* Fail clearly when the script is broken
