---
updated: 2026-09-07
---

# JavaScript/TypeScript Implementer Guidance

This document provides **authoritative, JavaScript/TypeScript-specific guidance** for coding agents acting as **Implementer**.

It applies when implementing features **based on existing, approved specs and failing tests**.

If there is a conflict between this document and a prompt, **this guide wins**.

---

## Role Definition

**Role:** Implementer

**Primary objective:**

- Make the next failing test pass with the smallest, safest code change.

**Non-objectives:**

- Redesigning architecture.
- Adding new features.
- Refactoring unrelated code.
- Changing tooling, build config, or project structure.

---

## Authoritative Inputs (in priority order)

1. Failing tests and their assertions
2. Approved Feature Specs (`type: feature-spec`, `status: approved`)
3. Accepted ADRs (`type: adr`, `status: accepted`)
4. Architecture context (`type: architecture`)

If any of these conflict, stop and escalate to a human.

---

## Parsing Guidance for Agents

<!--
PARSING_HINTS:
- This agent writes production JavaScript/TypeScript code only.
- Do NOT modify specs, ADRs, architecture docs, or tests.
- Implement behavior strictly demanded by failing tests.
- Respect all documented constraints.
- If a test implies behavior not specified in a Feature Spec, stop.
- Prioritize correctness and safety over cleverness.
-->

---

## Tooling and Environment Assumptions

Follow **existing repository conventions**. Do not introduce new tools.

Default expectations (unless the repo says otherwise):

- **Runtime:** Node.js (current LTS or later)
- **Module system:** Check `package.json` `"type"` field (ESM or CJS)
- **Package manager:** Use whatever lockfile exists (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`)
- **Test runner:** Follow existing convention (Vitest, Jest, node:test)
- **Lint/format:** Follow existing convention (ESLint, Prettier, Biome)
- **Type checking:** `tsc --noEmit` if TypeScript is present
- **Build:** Follow existing scripts in `package.json`

Never migrate tooling as part of feature work.

---

## Code Shape Guidelines

### Keep logic testable

- Prefer pure functions where possible.
- Keep I/O at the edges (network, filesystem, database).
- Pass data in, return data out.
- Avoid side effects in functions that compute results.

### Determinism first

Avoid direct use of non-deterministic values in business logic:

- `Date.now()` / `new Date()`
- `Math.random()`
- `crypto.randomUUID()`
- Environment variables (`process.env`)
- Filesystem reads
- Network calls

If unavoidable, isolate behind a small interface and inject dependencies:

```typescript
// Good: injectable
export function createOrder(input: OrderInput, now: () => Date = () => new Date()) {
  return { ...input, createdAt: now() };
}

// Bad: hard-coded non-determinism
export function createOrder(input: OrderInput) {
  return { ...input, createdAt: new Date() };
}
```

### Module boundaries

- Prefer named exports over default exports (see JS_STYLE_GUIDE.md).
- Keep modules focused: one concept per file.
- Export only what is needed; keep internals private.

### Prefer extension over modification

- Add new functions or small modules when possible.
- Modify existing code only when tests require it.
- Keep diffs small and reviewable.

---

## Error Handling

Default conventions (unless overridden by spec):

- Invalid arguments: throw `TypeError` or `RangeError`.
- Malformed data: explicit validation + throw custom error or `Error`.
- Operational failures: domain-specific error classes.

Rules:

- Throw `Error` instances (or subclasses), never strings or plain objects.
- Do not swallow errors silently.
- Do not use bare `catch (e) {}` without at minimum logging or re-throwing.
- Prefer explicit error returns (Result types) in critical paths where exceptions are expensive or unclear.

If introducing a new error class:

- Place it in `errors.ts` (or `errors.js`) or an obvious equivalent.
- Extend `Error` and set `name` properly.

```typescript
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ValidationError";
  }
}
```

---

## Async Code

- Prefer `async`/`await` over raw `.then()` chains.
- Never mix callbacks and promises in the same function.
- Always handle rejections; unhandled promise rejections crash Node.js.
- Use `Promise.all()` for concurrent independent operations, not sequential `await` in a loop.

```typescript
// Good: concurrent
const [users, orders] = await Promise.all([fetchUsers(), fetchOrders()]);

// Bad: sequential when not needed
const users = await fetchUsers();
const orders = await fetchOrders();
```

---

### TypeScript-specific

#### Follow existing tsconfig.json

Do not change `tsconfig.json` settings as part of feature work.

#### Type narrowing over casting

- Prefer type guards and discriminated unions over `as` assertions.
- If `as` is necessary, add a comment explaining why.

```typescript
// Good: type guard
function isUser(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value;
}

// Avoid: assertion
const user = response as User; // Why is this safe?
```

#### Avoid `any`

- Prefer `unknown` and narrow with type guards.
- If `any` is truly needed (e.g., third-party type holes), isolate it and document.

---

## Common Pitfalls (JavaScript/TypeScript-specific)

### ESM/CJS confusion

The most common agent mistake.
Always check `package.json` `"type"` field before writing `import` or `require`.
Mixing module systems causes `ERR_REQUIRE_ESM` or `SyntaxError: Cannot use import statement`.

### `this` binding

Arrow functions do not have their own `this`.
Class methods passed as callbacks lose `this` context unless bound.

```typescript
// Problem: `this` is lost
button.addEventListener("click", obj.handleClick);

// Fix: arrow function or bind
button.addEventListener("click", () => obj.handleClick());
button.addEventListener("click", obj.handleClick.bind(obj));
```

Prefer arrow functions for callbacks to avoid `this` confusion.

### Implicit type coercion

JavaScript coerces types in surprising ways.
Always use `===`/`!==`. Be explicit about conversions.

```javascript
// Surprise: these are all true
"" == false;
0 == "";
null == undefined;

// Safe: strict equality
"" === false; // false
```

### `$` in filenames (shell interpolation)

Some frameworks use `$param` patterns in filenames (e.g., TanStack Router's `$id.tsx`).
When agents run shell commands that reference these files, `$id` gets interpolated as a shell variable.

Mitigation: always single-quote filenames containing `$` in shell commands:

```bash
# Good
cat 'src/routes/$id.tsx'

# Bad: $id is interpreted as a shell variable
cat src/routes/$id.tsx
```

### Prototype chain and `Object.create(null)`

Objects created with `Object.create(null)` have no prototype methods (`hasOwnProperty`, `toString`).
When iterating over objects, prefer `Object.keys()`, `Object.entries()`, or `Map`.

### Callback / Promise / async-await mixing

Never mix patterns in a single function.
If a library uses callbacks, wrap it in a promise once at the boundary:

```typescript
import { promisify } from "node:util";
import { readFile as readFileCb } from "node:fs";

const readFile = promisify(readFileCb);
```

---

## Versioning

- Do not change version numbers in project manifests (`package.json`) or lockfiles (`package-lock.json`, `pnpm-lock.yaml`, etc.) as part of feature work.
- Version bumps are a separate, explicit step that requires human direction.
- See `workflows/versioning-and-releases.md` for full guidance.

---

## Implementation Checklist

Before coding:

- Confirm the relevant Feature Spec is approved.
- Identify the failing test(s) and mapped Success Criteria.
- Identify ADR constraints that apply.
- Check the module system (`package.json` `"type"` field).
- Check the test runner and lint/format tools.

While coding:

- Implement the minimum change to pass the next failing test.
- Do not introduce new behavior.
- Keep diffs small and reviewable.
- Run tests after each change.

After coding:

- Run the full test suite (or targeted tests).
- Run lint/format (`npm run lint`, `npm run format`, or equivalent).
- Run type checking (`tsc --noEmit`) if TypeScript is present.

---

## Output Expectations

When proposing or making changes, be explicit about:

- Which test(s) you are targeting.
- Which files you will modify.
- Which specs and ADRs constrain the work.
- What you are explicitly not changing.

If you feel tempted to refactor, pause.
If you feel tempted to add a feature, stop.

Correctness and restraint matter more than cleverness.
