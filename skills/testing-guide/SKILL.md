---
name: testing-guide
description: "Writes tests from approved specs across Python, JavaScript/TypeScript, and Bash; applies implementer guidance and approved test patterns. Use when translating success criteria into tests, choosing a test layout, practising TDD, or working with pytest, vitest, or bats."
license: MIT
---

# Testing Guide Skill

Encodes the conventional-agents language-specific testing guides, implementation guides, and test patterns into actionable guidance for all three supported languages.

## Source Documents

- `guidelines/python/PYTHON_TESTING_GUIDE.md` — pytest patterns, Success Criteria mapping, ambiguity handling
- `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md` — Python implementer guidance
- `guidelines/python/PYTHON_STYLE_GUIDE.md` — Python style and docstring conventions
- `guidelines/javascript/JS_TESTING_GUIDE.md` — Vitest/Jest patterns, Success Criteria mapping, ambiguity handling
- `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md` — JavaScript/TypeScript implementer guidance
- `guidelines/javascript/JS_STYLE_GUIDE.md` — JavaScript/TypeScript style conventions
- `guidelines/bash/BASH_TESTING_GUIDE.md` — bats patterns, Success Criteria mapping, ambiguity handling
- `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md` — Bash implementer guidance
- `guidelines/bash/BASH_STYLE_GUIDE.md` — Bash style conventions

## Purpose

This skill helps an agent:

1. **Write tests from approved specs** — map Success Criteria to tests in the correct language and framework
2. **Follow approved test patterns** — parametrized tests, ambiguity handling, integration tests
3. **Apply implementer guidance** — minimum viable changes, test-driven development
4. **Respect language-specific conventions** — style, module systems, error handling, tooling

---

## Shared Principles (All Languages)

### Authoritative Signals (in order)

1. Test file metadata (YAML-like block in docstring/header)
2. `PARSING_HINTS` blocks inside test files
3. Feature Spec front matter and parsing hints
4. The body of the Feature Spec

If these conflict, stop and escalate to a human.

### Success Criteria Mapping Rules

- Each bullet in `## Success Criteria` MUST map to at least one test.
- Success Criteria text MUST be referenced in the test (verbatim in a comment or metadata).
- Test names MUST be descriptive and include the SC identifier when clear.
- Tests MUST NOT validate behavior not explicitly stated in the spec.

### Ambiguity Handling

If a Success Criterion is ambiguous, incomplete, or untestable:

| Language | Pattern |
| --- | --- |
| Python | `@pytest.mark.xfail(reason="Spec unclear: FS-XXXX SC-N")` with `raise NotImplementedError` |
| JavaScript/TypeScript | `it.todo("SC-N: spec is ambiguous, needs clarification (see FS-XXXX SC-N)")` |
| Bash | `skip "Spec does not define ..."` with descriptive reason |

Rules:

- Always reference the spec ID and SC number.
- Do NOT attempt to infer intended behavior.
- This pattern forces clarification in the spec.

### Test File Metadata

Each test file SHOULD include metadata at the top:

**Python (pytest):**

```python
"""
---
type: test-module
language: python
framework: pytest
spec_id: FS-XXXX
scope: unit | integration
---
"""
```

**JavaScript/TypeScript (Vitest/Jest):**

```javascript
/**
 * @module test
 *
 * ---
 * type: test-module
 * language: javascript
 * framework: vitest
 * spec_id: FS-XXXX
 * scope: unit | integration
 * ---
 */
```

**Bash (bats):**

```bash
#!/usr/bin/env bats
#
# Test suite for <feature>
#
# ---
# type: test-module
# language: bash
# framework: bats
# spec_id: FS-XXXX
# scope: unit | integration
# ---
```

---

## Python Testing

### Framework

- **Test runner**: pytest
- **Lint/format**: ruff
- **Type checking**: optional (pyright if present)
- **Packaging**: `pyproject.toml`

### Approved Test Patterns

**Parametrized test:**

```python
import pytest


@pytest.mark.spec("FS-XXXX")
@pytest.mark.parametrize(
    "input_value, expected",
    [
        pytest.param(<input1>, <expected1>, id="case-1"),
        pytest.param(<input2>, <expected2>, id="case-2"),
    ],
)
def test_sc_3__<short_behavior_name>(subject, input_value, expected):
    actual = subject.<function>(input_value)
    assert actual == expected
```

**Ambiguity handling:**

```python
import pytest


@pytest.mark.spec("FS-XXXX")
@pytest.mark.xfail(reason="Spec unclear: FS-XXXX Success Criteria SC-2")
def test_sc_2__ambiguous(subject):
    raise NotImplementedError
```

**Integration test:**

```python
import pytest


@pytest.mark.integration
@pytest.mark.spec("FS-XXXX")
def test_sc_1__<behavior>():
    # Use tmp_path for isolation
    ...
```

### Python Implementer Guidance

**Primary objective:** Make the next failing test pass with the smallest, safest code change.

**Authoritative inputs (in priority order):**

1. Failing pytest tests and their assertions
2. Approved Feature Specs (`status: approved`)
3. Accepted ADRs (`status: accepted`)
4. Architecture context

**Code shape guidelines:**

- Prefer pure functions where possible.
- Keep I/O at the edges.
- Avoid direct use of current time, randomness, env vars, filesystem, network — isolate behind injectable interfaces.
- Prefer extension over modification (add new functions/modules when possible).
- Use type hints on public functions and module boundaries.

**Error handling defaults:**

- Invalid arguments: `ValueError`, `TypeError`
- Missing/malformed data: explicit validation + `ValueError`
- Operational failures: `RuntimeError` or domain-specific exception
- Do not swallow exceptions. Do not use bare `except Exception`.

**Implementation checklist:**

- [ ] Confirm the relevant Feature Spec is approved
- [ ] Identify the failing test(s) and mapped Success Criteria
- [ ] Identify ADR constraints that apply
- [ ] Implement the minimum change to pass the next failing test
- [ ] Run targeted pytest tests
- [ ] Run `./scripts/verify` if available

---

## JavaScript/TypeScript Testing

### Framework

- **Default**: Vitest (Jest-compatible API, native ESM/TS support)
- **Alternatives**: Jest, `node:test` — follow existing repo convention
- **File extension**: `*.test.ts`, `*.test.js`, or `*.spec.ts`

### Approved Test Patterns

**Unit test with spec mapping:**

```typescript
import { describe, it, expect } from "vitest";

import { parseInput } from "./parser.js";

describe("parseInput", () => {
  // SC-1: Given valid JSON input, when parsing, then return structured record
  it("should return a structured record for valid JSON", () => {
    const raw = '{"name": "test", "value": 42}';
    const result = parseInput(raw);
    expect(result).toEqual({ name: "test", value: 42 });
  });
});
```

**Table-driven (parametrized) test:**

```typescript
import { describe, it, expect } from "vitest";

import { slugify } from "./string-utils.js";

describe("slugify", () => {
  // SC-3: Given various string inputs, when slugifying, then produce valid URL slugs
  it.each([
    { input: "Hello World", expected: "hello-world", id: "spaces" },
    { input: "UPPER CASE", expected: "upper-case", id: "uppercase" },
  ])("should slugify: $id", ({ input, expected }) => {
    expect(slugify(input)).toBe(expected);
  });
});
```

**Ambiguity handling:**

```typescript
describe("featureX", () => {
  // SC-4: Spec unclear — escalate before implementing
  it.todo("SC-4: spec is ambiguous, needs clarification (see FS-XXXX SC-4)");
});
```

### JS/TS Implementer Guidance

**Primary objective:** Make the next failing test pass with the smallest, safest code change.

**Authoritative inputs (in priority order):**

1. Failing tests and their assertions
2. Approved Feature Specs (`status: approved`)
3. Accepted ADRs (`status: accepted`)
4. Architecture context

**Module system:** Always check `package.json` `"type"` field before writing `import` or `require`. Do not mix ESM and CJS.

**Code shape guidelines:**

- Prefer pure functions where possible.
- Keep I/O at the edges (network, filesystem, database).
- Avoid non-deterministic values: `Date.now()`, `Math.random()`, `crypto.randomUUID()`, `process.env`.
- Prefer named exports over default exports.
- Prefer `async`/`await` over raw `.then()` chains.
- Use `Promise.all()` for concurrent independent operations.

**Error handling defaults:**

- Invalid arguments: throw `TypeError` or `RangeError`
- Malformed data: explicit validation + custom error or `Error`
- Throw `Error` instances (or subclasses), never strings or plain objects.
- Do not swallow errors silently.

**TypeScript-specific:**

- Use `"strict": true` in `tsconfig.json` for new projects.
- Avoid `any`. Prefer `unknown` and narrow with type guards.
- Prefer discriminated unions over loose union types.
- Prefer type guards and discriminated unions over `as` assertions.

**Common pitfalls:**

- ESM/CJS confusion — always check `package.json` `"type"` field.
- `this` binding — arrow functions for callbacks to avoid `this` confusion.
- Implicit type coercion — always use `===`/`!==`.
- `$` in filenames — single-quote filenames containing `$` in shell commands.

**Implementation checklist:**

- [ ] Confirm the relevant Feature Spec is approved
- [ ] Identify the failing test(s) and mapped Success Criteria
- [ ] Identify ADR constraints that apply
- [ ] Check the module system (`package.json` `"type"` field)
- [ ] Check the test runner and lint/format tools
- [ ] Implement the minimum change to pass the next failing test
- [ ] Run the full test suite (or targeted tests)
- [ ] Run lint/format (`npm run lint`, `npm run format`, or equivalent)
- [ ] Run type checking (`tsc --noEmit`) if TypeScript is present

---

## Bash Testing

### Framework

- **Unit tests**: `bats` (Bash Automated Testing System) — file extension: `test.bats`
- **Integration tests**: Shell scripts with explicit test functions — file extension: `*_test.sh` or `*_integration.sh`
- **Linting**: `shellcheck` (if used)

### Approved Test Patterns

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

### Bash Implementer Guidance

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

---

## Reviewer Checklist (Tests)

When reviewing tests, check:

- [ ] Every Success Criterion has at least one test
- [ ] No test exists without a corresponding spec reference
- [ ] No behavior is validated that is not documented
- [ ] Ambiguities are surfaced via xfail/skip/it.todo, not hidden via assumptions
- [ ] Tests are deterministic (same result every run)
- [ ] Tests are isolated (no shared mutable state between tests)
- [ ] Tests clean up after themselves
- [ ] Test names are clear and describe what is tested
- [ ] All async tests properly `await` or return promises (JS/TS)
- [ ] Mocking is done via framework utilities, not manual monkey-patching (JS/TS)
- [ ] Scripts use `set -euo pipefail` (Bash)
- [ ] Variables are quoted and properly scoped (Bash)

---

## Related Skills

- `skills/document-lifecycle/SKILL.md` — the FS `status: approved` gate that must hold before tests are written
- `skills/role-aware-session/SKILL.md` — Spec Reader / Test Planner vs Implementer stance

---

## Prohibitions

- **Do NOT** write tests for a spec that is not `approved`.
- **Do NOT** validate behavior not explicitly stated in the spec.
- **Do NOT** infer intent when a Success Criterion is ambiguous — use the ambiguity pattern.
- **Do NOT** write production code when acting as Spec Reader and Test Planner.
- **Do NOT** modify specs, ADRs, or architecture docs when acting as Implementer.
- **Do NOT** introduce new features or behaviors not required by failing tests.
- **Do NOT** refactor code unrelated to the failing test.
- **Do NOT** change version numbers in project manifests during feature work.
- **Do NOT** commit code with failing tests.
