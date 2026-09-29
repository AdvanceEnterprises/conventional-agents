# Bash Testing

Language-specific detail for the `testing-guide` skill. Load this when the work
is in Bash. The shared principles — authoritative signals, Success Criteria
mapping, ambiguity handling, test file metadata — are in `SKILL.md` and apply
here unchanged.

Source: `guidelines/bash/BASH_TESTING_GUIDE.md`,
`guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`,
`guidelines/bash/BASH_STYLE_GUIDE.md`.

## Framework

- **Unit tests**: `bats` (Bash Automated Testing System) — file extension: `test.bats`
- **Integration tests**: Shell scripts with explicit test functions — file extension: `*_test.sh` or `*_integration.sh`
- **Linting**: `shellcheck` (if used)

## Approved Test Patterns

**Unit test (bats):**

```bash
#!/usr/bin/env bats
#
# Tests for helper functions
#
# ---
# type: test-module
# language: bash
# framework: bats
# spec_id: FS-XXXX
# scope: unit
# ---

# Source the script being tested
source "ops/scripts/<script>"

@test "error function exits with code 1" {
    run error "test message"
    [ "$status" -eq 1 ]
}

@test "error function prints to stderr" {
    run error "test message" 2>&1
    [[ "$output" == *"ERROR: test message"* ]]
}
```

**Parametrized test (bats loop):**

```bash
@test "validate pod name - valid names" {
    local valid_names=("app-dev" "myapp-test" "xyz-prod")

    for name in "${valid_names[@]}"; do
        run validate_pod_name "$name"
        [ "$status" -eq 0 ] || fail "Failed for: $name"
    done
}
```

**Ambiguity handling:**

```bash
# Test: Ambiguous criterion from FS-XXXX (SC-5)
@test "XFAIL: Spec unclear on retry behavior - FS-XXXX SC-5" {
    skip "Spec does not define retry count or backoff strategy"
}
```

**Integration test (shell script):**

```bash
#!/usr/bin/env bash
# Integration tests for <feature>
# Requires: <dependencies>
#
# ---
# type: test-module
# language: bash
# framework: shell-integration
# spec_id: FS-XXXX
# scope: integration
# ---

set -euo pipefail

cleanup() {
    # Clean up resources
}

trap cleanup EXIT
cleanup

test_pod_creation() {
    # Test logic
    if <script>; then
        echo "✓ Test passed"
    else
        echo "✗ Test failed"
        exit 1
    fi
}

test_pod_creation
echo "All integration tests passed"
```

## Bash Implementer Guidance

**Primary objective:** Make the next failing test pass with the smallest, safest script change.

**Strict mode is mandatory:**

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Authoritative inputs (in priority order):**

1. Failing shell tests (bats, bash-unit, or integration tests)
2. Approved Feature Specs (`status: approved`)
3. Accepted ADRs (`status: accepted`)
4. Architecture context

**Code shape guidelines:**

- Prefer pure functions (no side effects) where possible.
- Pass data in via arguments, return via stdout or exit codes.
- Keep I/O (files, network, commands) at the edges.
- Use `local` for all function variables.
- Always quote variables: `"$var"` not `$var`.
- Use `${var:-default}` for optional variables with defaults.
- Use `[[ ]]` for conditionals, `(( ))` for arithmetic.
- Use `$(command)` over backticks.

**Error handling defaults:**

- Usage errors: Exit with code 1, print error message to stderr.
- Missing commands: Exit early with clear message (check with `command -v`).
- Missing files: Exit with error before attempting to read.
- Never silently ignore errors.
- Never use bare `|| true` except for specific, documented cases.

**Common pitfalls to avoid:**

- Using `grep | wc -l` to count (use `grep -c` or conditional logic).
- Using backticks (use `$(command)` instead).
- Assuming `cd` succeeds (always check: `cd dir || error "..."`).
- Storing output of failing command without checking.
- Parsing CSV/JSON with grep/sed.

**Implementation checklist:**

- [ ] Confirm the relevant Feature Spec is approved
- [ ] Identify the failing test(s) and mapped Success Criteria
- [ ] Identify ADR constraints that apply
- [ ] Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- [ ] Implement the minimum change to pass the next failing test
- [ ] Quote all variables
- [ ] Check return codes for critical operations
- [ ] Run tests (bats or integration tests)
- [ ] Run `shellcheck` if available
