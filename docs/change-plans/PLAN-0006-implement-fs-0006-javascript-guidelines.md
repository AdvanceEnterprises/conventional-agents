---
type: change-plan
role: implementer
language: markdown
status: approved
related_specs:
  - FS-0006
related_adrs: []
created: 2026-02-08
updated: 2026-02-08
---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This plan covers creating three new guideline documents and updating
  existing project files (excluding docs/) to reference JavaScript.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

# Change Plan: Implement FS-0006 — JavaScript/TypeScript Guidelines

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0006
- Related ADR ID(s): None
- Issue / PR Reference: PR #12 (<https://github.com/Tais-Den/agentic-dev-kit/pull/12>)

## 2. Scope of Change

**This change WILL:**

- Create `guidelines/javascript/JS_STYLE_GUIDE.md` covering formatting, naming, module system (ESM/CJS), TypeScript typing discipline, documentation/comments, formatting tool expectations, and import organization.
- Create `guidelines/javascript/JS_TESTING_GUIDE.md` covering test framework expectations (framework-agnostic with Vitest as recommended default), spec-to-test mapping, agent parsing guidance (authoritative signals, test file metadata), approved test patterns (at least 2 runnable examples), and common pitfalls.
- Create `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md` covering role definition, authoritative inputs (priority order), parsing hints, tooling/environment assumptions, code shape guidelines (pure functions, determinism, error handling, module boundaries), and at least one JS-specific pitfall not present in Python/Bash guides.
- Include clearly labeled `### TypeScript-specific` subsections within each guide (integrated approach per resolved FS-0006 question).
- Update `README.md` to list JavaScript alongside Bash and Python in the "Guidelines" section and add example references.
- Update `CONTRIBUTING.md` to include `guidelines/javascript/` in the directory tree and list the three JS guide files.
- Update `AGENTS.md` if it references guidelines (to include the new JS directory).
- Ensure all three new guides pass markdownlint with zero errors.
- Ensure each guide is between 150 and 600 lines (per FS-0006 success criteria).

**This change will NOT:**

- Modify any files under `docs/` (ADRs, specs, change plans, ARC42).
- Prescribe a specific frontend or backend framework.
- Prescribe a specific linter, formatter, test runner, or package manager (guides say "follow existing repo conventions" with recommended defaults for new projects).
- Add JavaScript-specific test templates under `templates/` (out of scope for FS-0006; can be a follow-up).
- Change `INTEGRATION.md` or `roles/ROLE_CONTRACT.md` (no structural changes needed; the guidelines are discoverable via the existing `guidelines/` contract).

## 3. Tests Driving This Change

This is a documentation-only change; there are no code tests.

Quality gates:

- `npm run lint:docs` must pass (markdownlint).
- Manual review: each guide must follow the three-document pattern established by Bash and Python.
- Manual review: each guide must satisfy the FS-0006 success criteria.

## 4. Files to Be Modified

**New files:**

- `guidelines/javascript/JS_STYLE_GUIDE.md`
- `guidelines/javascript/JS_TESTING_GUIDE.md`
- `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`

**Existing files to update:**

- `README.md` — add JavaScript to "Guidelines" list, add example reference
- `CONTRIBUTING.md` — add `javascript/` to directory tree, list JS guide files

## 5. Implementation Steps (High-Level)

1. Create `guidelines/javascript/` directory.

2. Write `JS_STYLE_GUIDE.md`:
   - Follow the structure of `PYTHON_STYLE_GUIDE.md` (decision precedence → voice/tone → formatting → naming → documentation → modules → imports).
   - Add JS-specific sections: ESM vs CJS, TypeScript typing discipline, named vs default exports.
   - Include `### TypeScript-specific` subsections for: strict mode, type narrowing, `as` cast avoidance, generics hygiene.

3. Write `JS_TESTING_GUIDE.md`:
   - Follow the structure of `PYTHON_TESTING_GUIDE.md` (scope → parsing guidance → test file metadata → framework expectations → success criteria mapping → approved patterns → common pitfalls).
   - Define test file metadata convention using JSDoc comment blocks (YAML-like, compatible with Python/Bash pattern).
   - Framework-agnostic with Vitest as recommended default for new projects.
   - Include at least 2 runnable test examples (one unit, one parametrized/table-driven).
   - Include JS-specific testing pitfalls: async test handling, module mocking in ESM, timer/date mocking.

4. Write `JS_IMPLEMENTATION_GUIDE.md`:
   - Follow the structure of `PYTHON_IMPLEMENTATION_GUIDE.md` (role definition → authoritative inputs → parsing hints → tooling assumptions → code shape guidelines → common pitfalls).
   - JS-specific code shape guidance: pure functions, determinism (inject Date.now/Math.random), explicit error returns, narrow types, named exports.
   - JS-specific pitfalls: ESM/CJS confusion, `this` binding, prototype chain surprises, `$` in filenames (TanStack Router), implicit type coercion, callback vs promise vs async/await mixing.

5. Update `README.md`:
   - In "### Guidelines" section, add: `- **JavaScript/TypeScript**: Style, testing patterns, and implementation guidance`
   - In the example CLAUDE.md reference block, add a JS style guide link.

6. Update `CONTRIBUTING.md`:
   - In the "### Guidelines" directory tree, add the `javascript/` directory with its three files.

7. Run `npm run lint:docs` and fix any markdownlint errors.

8. Verify line counts are within 150–600 lines per guide.

## 6. Constraints and Guardrails

- Spec constraints:
  - FS-0006 Non-Goals: no framework-specific prescriptions, no build system config, no frontend component testing.
  - FS-0006 Out of Scope: no ESLint/Biome/Prettier rule recommendations, no package publishing guidance.
  - FS-0006 Edge Cases: guides must be useful for pure JS (no TS), CJS codebases, and should not break on Deno/Bun where avoidable.

- Architecture constraints:
  - Three-document pattern must match Bash and Python (`*_STYLE_GUIDE.md`, `*_TESTING_GUIDE.md`, `*_IMPLEMENTATION_GUIDE.md`).
  - PARSING_HINTS blocks must be present in testing and implementation guides.
  - Guides must be framework-agnostic with "follow existing repo conventions" as the primary directive.

## 7. Risks and Edge Cases

- **Ecosystem churn**: JS tooling changes rapidly; guides must avoid version-specific advice that will become stale. Mitigated by: "follow existing repo conventions" as primary rule; recommended defaults are explicitly labeled as defaults, not mandates.
- **TypeScript integration depth**: risk of TS sections becoming too large and overwhelming the JS content. Mitigated by: keeping TS subsections focused and concise; deferring advanced TS patterns to a potential future FS.
- **Guide length**: risk of exceeding 600 lines if all topics are covered exhaustively. Mitigated by: matching the depth of existing Python guides (177–276 lines) rather than Bash guides (311–558 lines); being prescriptive, not exhaustive.

## 8. Validation

- Markdownlint passes:
  - `npx markdownlint-cli2 "guidelines/javascript/*.md"` returns 0 errors.
- Line count check:
  - Each guide is between 150 and 600 lines (`wc -l guidelines/javascript/*.md`).
- FS-0006 success criteria spot-check:
  - `guidelines/javascript/` contains exactly 3 files.
  - `JS_STYLE_GUIDE.md` has sections for: decision precedence, voice/tone, module system, naming, TS typing, documentation, formatting tools, import organization.
  - `JS_TESTING_GUIDE.md` has test file metadata convention, at least 2 runnable examples.
  - `JS_IMPLEMENTATION_GUIDE.md` has at least one JS-specific pitfall not in Python/Bash guides.
  - No guide mandates a specific linter, formatter, test runner, or framework.
- README.md lists JavaScript in "Guidelines" section.
- CONTRIBUTING.md directory tree includes `javascript/` with three files.

## 9. Explicit Non-Changes

- `docs/` directory (ADRs, specs, change plans, ARC42) — not modified.
- `INTEGRATION.md` — not modified (guidelines are already discoverable via `vendor/agent-dev-kit/guidelines/`).
- `roles/ROLE_CONTRACT.md` — not modified.
- `templates/` — no new JS test templates (potential follow-up).
- `skills/` — not modified.
- `workflows/` — not modified.
- `package.json` — not modified (no new lint scripts needed; existing `lint:docs` covers `docs/` only; guideline linting is optional/manual).

## 10. Readiness Check

- [x] Spec is approved (FS-0006, status: approved)
- [x] Tests exist or are clearly defined (documentation-only; markdownlint is the quality gate)
- [x] Scope is minimal and explicit
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
