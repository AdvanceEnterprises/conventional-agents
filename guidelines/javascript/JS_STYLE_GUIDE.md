# JavaScript/TypeScript Style Guide

This document provides **authoritative style guidance for coding agents** writing or reviewing JavaScript and TypeScript code.

It applies to all agent roles as defined in the Agent Role Contract.

If there is a conflict between this guide and a prompt, **this guide wins**.

---

## Decision Precedence

1. Project style (root `AGENTS.md`, `.eslintrc.*`, `biome.json`, `prettier` config, `tsconfig.json`)
2. Guidelines in this document
3. Community conventions (MDN, TypeScript handbook, framework docs)

**Rule:** Follow existing repository conventions first.
This guide provides defaults for new projects and fills gaps where the repo has no convention.

---

## Voice and Tone

- Be clear and direct.
- Use imperative when describing what a function does: "Parse the input", "Return the result".
- Avoid jargon; explain technical terms.
- Be consistent with terminology used in the project.

---

## Module System

### Determine the project's module system first

Before writing any code, check:

- `package.json` → `"type": "module"` (ESM) or `"type": "commonjs"` (CJS) or absent (CJS default).
- `tsconfig.json` → `"module"` and `"moduleResolution"` settings.
- Existing source files → `import`/`export` vs `require`/`module.exports`.

**Do not mix module systems.** If the project uses ESM, write ESM. If it uses CJS, write CJS.

### ESM (preferred for new projects)

```javascript
import { readFile } from "node:fs/promises";
import { parse } from "./parser.js";

export function process(input) {
  // ...
}
```

### CJS (legacy; follow if the project uses it)

```javascript
const { readFile } = require("node:fs/promises");
const { parse } = require("./parser");

function process(input) {
  // ...
}

module.exports = { process };
```

### Key rules

- In ESM, always include file extensions in relative imports (`.js`, `.ts`, or as configured).
- Prefer `node:` prefix for built-in modules (`node:fs`, `node:path`, `node:crypto`).
- Never use `require()` in an ESM project or `import` in a CJS project without explicit interop configuration.

---

## Naming Conventions

- **Variables and functions:** `camelCase`
- **Classes and type aliases:** `PascalCase`
- **Constants (true compile-time values):** `UPPER_SNAKE_CASE`
- **Enum members:** `PascalCase`
- **File names:** `kebab-case.ts` or `camelCase.ts` — follow existing repo convention.
- **Test files:** `*.test.ts`, `*.spec.ts`, or `*.test.js` — follow existing repo convention.
- **Directories:** `kebab-case` (lowercase, hyphens).

Avoid abbreviations unless they are universally understood (`id`, `url`, `html`, `css`).

---

## Exports

- **Prefer named exports** over default exports.
  - Named exports are easier for agents to refactor (rename/move).
  - Named exports produce better error messages on typos.
  - Named exports enable tree-shaking without extra tooling.

```javascript
// Good
export function parseInput(raw) { /* ... */ }
export class InputParser { /* ... */ }

// Avoid
export default function parseInput(raw) { /* ... */ }
```

- Default exports are acceptable for framework conventions that require them (e.g., page components in some routers).

---

## Import Organization

Order imports in this sequence:

1. Node built-ins (`node:fs`, `node:path`)
2. External packages (`express`, `zod`, `vitest`)
3. Internal aliases (`@/lib/...`, `~/utils/...`)
4. Relative imports (`./parser`, `../config`)

Separate each group with a blank line.

```javascript
import { readFile } from "node:fs/promises";
import path from "node:path";

import { z } from "zod";

import { config } from "@/lib/config";

import { parse } from "./parser.js";
```

If the project uses an auto-import-sorting tool (ESLint plugin, Biome, Prettier plugin), defer to it.

---

## Formatting and Linting Tools

**Do not introduce new formatting or linting tools into an existing project.**

Follow whatever the project already uses:

- **ESLint** (flat config, v9+) — dominant linter.
- **Prettier** — dominant formatter.
- **Biome** — fast, combined linter+formatter (growing adoption).
- **`dprint`** — alternative formatter.

**For new projects with no existing convention:**

- Recommended default: ESLint (flat config) + Prettier.
- Alternative: Biome (single tool, faster, simpler config).

Run the project's lint/format commands before committing.
Do not disable lint rules inline without a documented reason.

---

## Comments and Documentation

### When to comment

Comment **why**, not **what**.

```javascript
// Retry up to 3 times because the upstream API is flaky under load
const MAX_RETRIES = 3;
```

**Avoid:**

```javascript
// Set max retries to 3
const MAX_RETRIES = 3;
```

### JSDoc

Use JSDoc for public functions and module-level exports.
Include `@param`, `@returns`, and `@throws` where they add clarity.

```javascript
/**
 * Parse raw input into a structured record.
 *
 * @param {string} raw - The raw input string.
 * @returns {Record} The parsed record.
 * @throws {ValidationError} If the input is malformed.
 */
export function parseInput(raw) {
  // ...
}
```

If the project uses TypeScript, type annotations often replace `@param`/`@returns` types.
In that case, keep the description but omit the type from JSDoc:

```typescript
/**
 * Parse raw input into a structured record.
 *
 * @throws {ValidationError} If the input is malformed.
 */
export function parseInput(raw: string): Record {
  // ...
}
```

### File header comments

For non-trivial modules, add a brief header explaining purpose:

```javascript
/**
 * parser.ts
 *
 * Converts raw API responses into internal record format.
 * Used by the ingestion pipeline (see docs/architecture.md).
 */
```

---

## Error Handling

- Prefer explicit error returns or Result-type patterns over relying on uncaught exceptions.
- When throwing, throw `Error` instances (or subclasses), never strings or plain objects.
- Catch errors at appropriate boundaries; do not swallow them silently.

```javascript
// Good
throw new ValidationError(`Invalid field: ${field}`);

// Bad
throw "invalid field";
throw { error: "invalid" };
```

- Avoid bare `catch (e) {}` blocks. At minimum, log or re-throw.

---

### TypeScript-specific

#### Strict mode

New projects SHOULD use `"strict": true` in `tsconfig.json`.
This enables `strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`, and others.

Follow existing project settings; do not change `tsconfig.json` strictness as part of feature work.

#### Type discipline

- Avoid `any`. Prefer `unknown` when the type is truly unknown, then narrow.
- Avoid `as` type assertions unless there is no safer alternative. Document why.
- Prefer discriminated unions over loose union types.
- Prefer interfaces for object shapes that may be extended; use `type` for unions, intersections, and mapped types.

```typescript
// Good: discriminated union
type Result =
  | { ok: true; value: Data }
  | { ok: false; error: AppError };

// Avoid: loose union
type Result = Data | AppError; // How do you tell them apart?
```

#### Generics

- Use generics when they add real type safety.
- Avoid unnecessary generic parameters that add complexity without benefit.
- Name type parameters descriptively when they are not obvious: `TInput`, `TOutput` over `T`, `U`.

```typescript
// Good: adds real safety
function first<T>(items: T[]): T | undefined {
  return items[0];
}

// Avoid: unnecessary generic
function log<T>(message: T): void {
  console.log(message); // T adds nothing here
}
```

---

## Miscellaneous

- Use `===` and `!==` (strict equality). Never use `==` or `!=` except when intentionally checking for `null`/`undefined` (`value == null`).
- Prefer `const` over `let`. Never use `var`.
- Prefer template literals over string concatenation for readability.
- Prefer optional chaining (`?.`) and nullish coalescing (`??`) over manual null checks.
- Avoid modifying function arguments (especially objects/arrays passed in).
