# JavaScript / TypeScript Testing

Language-specific detail for the `testing-guide` skill. Load this when the work
is in JavaScript or TypeScript. The shared principles — authoritative signals,
Success Criteria mapping, ambiguity handling, test file metadata — are in
`SKILL.md` and apply here unchanged.

Source: `guidelines/javascript/JS_TESTING_GUIDE.md`,
`guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`,
`guidelines/javascript/JS_STYLE_GUIDE.md`.

## Framework

- **Default**: Vitest (Jest-compatible API, native ESM/TS support)
- **Alternatives**: Jest, `node:test` — follow existing repo convention
- **File extension**: `*.test.ts`, `*.test.js`, or `*.spec.ts`

## Approved Test Patterns

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

## JS/TS Implementer Guidance

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
