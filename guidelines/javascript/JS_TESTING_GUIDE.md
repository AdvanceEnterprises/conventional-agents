# JavaScript/TypeScript Testing Guide

This document provides **authoritative guidance for coding agents** when writing or reviewing tests for JavaScript and TypeScript projects.

It applies to **Role 1: Spec Reader and Test Planner** and **Role 3: Reviewer** as defined in the Agent Role Contract.

If there is a conflict between this guide and a prompt, **this guide wins**.

---

## Scope

This guide covers:

- How agents should parse and interpret JS/TS test files.
- How Feature Specs map to tests.
- Approved patterns for table-driven and parametrized tests.
- The preferred pattern for handling ambiguity in specs.
- JavaScript/TypeScript-specific testing considerations.

It does NOT define testing framework basics or general JavaScript testing practices.

---

## Parsing Guidance for Agents

### Authoritative signals

Agents MUST rely on the following, in order:

1. Test file metadata (JSDoc block with YAML-like content)
2. `PARSING_HINTS` blocks inside test file JSDoc
3. Feature Spec front matter and parsing hints
4. The body of the Feature Spec

If these conflict, stop and escalate to a human.

---

### Test file metadata expectations

Each test file SHOULD include a top-level JSDoc comment containing metadata:

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

Agents MUST:

- Use `spec_id` to locate the authoritative Feature Spec.
- Refuse to write tests if the spec status is not `approved`.
- Treat missing or malformed metadata as a stop condition.
- Match the `framework` field to the project's actual test runner.

---

### Success Criteria mapping rules

- Each bullet in `## Success Criteria` MUST map to at least one test.
- Success Criteria text MUST be referenced in a comment near the test.
- Test names MUST be descriptive and include the SC identifier when clear.
- Tests MUST NOT validate behavior not explicitly stated in the spec.

If a criterion cannot be tested as written, do NOT guess.

---

## Test Framework Expectations

**Follow existing repo conventions.** Do not switch test runners.

Default expectations (for new projects with no existing convention):

- **Recommended default:** Vitest
  - Native ESM and TypeScript support (no extra transform step).
  - Jest-compatible API (`describe`, `it`, `expect`).
  - Fast watch mode with HMR-driven re-execution.
  - File extension: `*.test.ts`, `*.test.js`, or `*.spec.ts`.

- **If the project uses Jest:** follow Jest conventions.
  - May require `ts-jest` or `@swc/jest` for TypeScript.
  - File extension: `*.test.ts`, `*.test.js`, or `*.spec.ts`.

- **If the project uses `node:test`:** follow its conventions.
  - Built-in to Node.js 18+, zero dependencies.
  - Requires manual TypeScript compilation step.
  - File extension: `*.test.ts`, `*.test.js`.

Regardless of framework, all tests must be:

- Deterministic (same result every run).
- Isolated (no shared mutable state between tests).
- Fast (prefer unit tests; use integration tests sparingly).

---

## Approved Test Patterns

### Example 1: Unit test with spec mapping

```typescript
import { describe, it, expect } from "vitest";

import { parseInput } from "./parser.js";

/**
 * @module test
 *
 * ---
 * type: test-module
 * language: typescript
 * framework: vitest
 * spec_id: FS-0012
 * scope: unit
 * ---
 */

describe("parseInput", () => {
  // SC-1: Given valid JSON input, when parsing, then return structured record
  it("should return a structured record for valid JSON", () => {
    const raw = '{"name": "test", "value": 42}';
    const result = parseInput(raw);

    expect(result).toEqual({ name: "test", value: 42 });
  });

  // SC-2: Given malformed input, when parsing, then throw ValidationError
  it("should throw ValidationError for malformed input", () => {
    expect(() => parseInput("not json")).toThrow("ValidationError");
  });
});
```

### Example 2: Table-driven (parametrized) test

```typescript
import { describe, it, expect } from "vitest";

import { slugify } from "./string-utils.js";

describe("slugify", () => {
  // SC-3: Given various string inputs, when slugifying, then produce valid URL slugs
  it.each([
    { input: "Hello World", expected: "hello-world", id: "spaces" },
    { input: "UPPER CASE", expected: "upper-case", id: "uppercase" },
    { input: "special!@#chars", expected: "specialchars", id: "special-chars" },
    { input: "  leading-trailing  ", expected: "leading-trailing", id: "trim" },
  ])("should slugify: $id", ({ input, expected }) => {
    expect(slugify(input)).toBe(expected);
  });
});
```

Rules for table-driven tests:

- Parametrization MUST NOT introduce new requirements.
- Each row must still satisfy the same Success Criterion.
- Use descriptive IDs for each case.

---

### Preferred pattern for handling ambiguity

If a Success Criterion is ambiguous, incomplete, or untestable:

```typescript
import { describe, it, expect } from "vitest";

describe("featureX", () => {
  // SC-4: Spec unclear — escalate before implementing
  it.todo("SC-4: spec is ambiguous, needs clarification (see FS-XXXX SC-4)");
});
```

Rules:

- Always reference the spec ID and SC number.
- Do NOT attempt to infer intended behavior.
- Use `it.todo()` (Vitest/Jest) or `it.skip()` with a clear reason.
- This pattern forces clarification in the spec.

---

## Integration Test Guidance

Integration tests SHOULD:

- Be few in number.
- Be deterministic.
- Use temporary directories (`node:os` `tmpdir` or framework-provided helpers).
- Clean up after themselves.

Integration tests MUST:

- Be clearly separated from unit tests (separate directory or naming convention).
- Be traceable to a Feature Spec via metadata or comments.

---

## Common Pitfalls (JavaScript/TypeScript-specific)

### Async test handling

Always `await` async operations or return the promise.
Forgetting this causes tests to pass when they should fail.

```typescript
// Good
it("should fetch data", async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});

// Bad: test passes even if fetchData rejects
it("should fetch data", () => {
  fetchData().then((data) => {
    expect(data).toBeDefined();
  });
});
```

### Module mocking in ESM

ESM modules cannot be monkey-patched like CJS `require()` calls.
Use the test framework's mocking utilities:

- **Vitest:** `vi.mock("./module.js")` at the top of the file.
- **Jest:** `jest.mock("./module.js")` at the top of the file (with `--experimental-vm-modules` for ESM).

Do not use `jest.mock()` in ESM projects without confirming ESM support is configured.

### Timer and date mocking

Use framework-provided fake timers:

- **Vitest:** `vi.useFakeTimers()` / `vi.useRealTimers()`
- **Jest:** `jest.useFakeTimers()` / `jest.useRealTimers()`

Always restore real timers in `afterEach` to prevent test pollution.

### Snapshot overuse

Snapshots are useful for large, stable outputs (serialized config, rendered HTML).
Do NOT use snapshots as a substitute for specific assertions.
Snapshots that change on every run indicate the test is not deterministic.

---

## Reviewer Checklist (Tests)

When acting as Reviewer, agents SHOULD check:

- Every Success Criterion has at least one test.
- No test exists without a corresponding spec reference.
- No behavior is validated that is not documented.
- Ambiguities are surfaced via `it.todo()`, not hidden via assumptions.
- All async tests properly `await` or return promises.
- Mocking is done via framework utilities, not manual monkey-patching.

---

## Non-Goals

This guide does NOT:

- Optimize test performance.
- Enforce coverage thresholds.
- Dictate fixture structure beyond minimal guidance.
- Replace human judgment.

It exists solely to keep tests honest, traceable, and spec-driven.

---

## Final Note

If writing a test feels creative, pause.

If writing a test requires guessing, stop.

The test suite is executable documentation.
Treat it with the same restraint as specs and ADRs.
