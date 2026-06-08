---
type: feature-spec
id: FS-0006
status: implemented
title: JavaScript/TypeScript guidelines for agentic development
owner: Tai
test_required: false
interfaces:
  - guidelines/javascript/ (new directory)
related_adrs: []
supersedes: []
requires: []
tags:
  - javascript
  - typescript
  - guidelines
  - style
  - testing
  - implementation
created: 2026-02-08
updated: 2026-06-08
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: JavaScript/TypeScript guidelines for agentic development

## Status

- Implemented

## Summary

Add a complete set of JavaScript/TypeScript guidelines to the conventional-agents framework, following the same three-document pattern used by Bash and Python:
a style guide, a testing guide, and an implementation guide.
These guidelines provide evidence-based, prescriptive standards specifically tuned for LLM-backed agentic developers writing JavaScript and TypeScript code.

## Goals

- Provide a **JS_STYLE_GUIDE.md** covering formatting, naming, module conventions, and documentation standards optimized for agent-readable, agent-writable code.
- Provide a **JS_TESTING_GUIDE.md** covering test framework expectations, spec-to-test mapping, approved patterns, and agentic-specific parsing guidance.
- Provide a **JS_IMPLEMENTATION_GUIDE.md** covering role definition, authoritative inputs, code shape guidelines, and common pitfalls specific to JavaScript/TypeScript.
- Ensure all three guides are **framework-agnostic** where possible (not tied to React, Next.js, Express, etc.) while acknowledging dominant ecosystem conventions.
- Ensure guides address **agentic-specific concerns**: fast feedback loops, deterministic tooling, clear error surfaces, ESM/CJS clarity, and ecosystem churn mitigation.

## Non-Goals

- Prescribing a specific frontend framework (React, Vue, Svelte, etc.).
- Prescribing a specific backend framework (Express, Fastify, Hono, etc.).
- Covering browser-specific APIs, CSS, or HTML guidance.
- Replacing or competing with tool-specific configs (ESLint configs, Prettier configs, etc.).
- Providing a full JavaScript/TypeScript language tutorial.

## Users / Stakeholders

- LLM-backed coding agents (Claude Code, Codex, Aider, Cursor, local models) acting as implementers, test writers, or reviewers on JavaScript/TypeScript projects.
- Human developers who review agent-produced JavaScript/TypeScript code.
- Maintainers of conventional-agents who need to keep guidelines consistent and evidence-based.

## Interfaces

- Type: Documentation (guidelines)
- Details: Three new markdown files under `guidelines/javascript/`:
  - `JS_STYLE_GUIDE.md`
  - `JS_TESTING_GUIDE.md`
  - `JS_IMPLEMENTATION_GUIDE.md`

## Background Research

The following research informs the decisions and recommendations in this spec.

### Agentic coding with JavaScript: known challenges

Evidence from practitioner reports (Armin Ronacher, Addy Osmani, community discussion) highlights several JavaScript-specific challenges for agentic development:

1. **Ecosystem churn**: JavaScript's ecosystem evolves rapidly. Agents trained on older data frequently generate outdated patterns (e.g., CommonJS `require()` in ESM-only projects, legacy Jest config when Vitest is used, `.eslintrc` when flat config is standard). Guidelines must emphasize "follow existing repo conventions" over prescribing specific tools.

2. **Module system confusion (ESM vs CJS)**: Agents frequently mix `import`/`export` and `require`/`module.exports`, causing runtime failures. The style guide must make the project's module system explicit and enforceable.

3. **TypeScript complexity**: Agents sometimes over-type (unnecessary generics, `as` casts everywhere) or under-type (`any` proliferation). The style guide should establish clear typing discipline.

4. **Test framework fragmentation**: Jest, Vitest, node:test, Mocha, and others coexist. The testing guide must be framework-neutral but establish metadata and mapping conventions that work across frameworks.

5. **Fast feedback loops**: JavaScript tooling startup is generally fast (unlike Python), but misconfigured TypeScript compilation or bundler steps can slow agent loops. The implementation guide should emphasize fast, incremental test execution.

6. **Special characters in filenames**: Some frameworks use `$param` patterns in filenames (e.g., TanStack Router), which confuse agents due to shell interpolation. The implementation guide should document this pitfall.

### Tooling landscape (as of early 2026)

**Linting and formatting:**

- **ESLint** (flat config, v9+): dominant linter; deprecated all formatting rules; recommends dedicated formatters.
- **Biome**: fast, Rust-based linter+formatter (340+ rules, 97% Prettier-compatible); growing adoption but smaller plugin ecosystem.
- **Prettier**: dominant formatter; stable, well-understood by agents.
- **Recommendation**: framework-agnostic; follow existing repo conventions. If no convention exists, prefer ESLint (flat config) + Prettier for broad compatibility, or Biome for simplicity and speed.

**Testing:**

- **Vitest**: modern, Vite-native, built-in ESM/TypeScript support, Jest-compatible API, fast HMR-driven execution. Strong momentum as the default for new projects.
- **Jest**: mature, vast ecosystem, requires `ts-jest` or SWC transform for TypeScript. Still dominant in existing projects.
- **node:test**: built-in Node.js test runner (v18+); zero-dependency but requires manual TypeScript compilation setup.
- **Recommendation**: framework-agnostic; follow existing repo conventions. Vitest is the recommended default for new projects due to native ESM/TS support and fast feedback loops.

**Package management:**

- npm, pnpm, yarn, bun — all viable. Guidelines should not prescribe a package manager but should emphasize using the repo's lockfile consistently.

**Type checking:**

- `tsc --noEmit` for type checking (regardless of build tool).
- Strict mode (`"strict": true`) recommended as default for new projects.

### Patterns that improve agent code quality (evidence-based)

From practitioner experience and community reports:

1. **Explicit module boundaries**: Named exports over default exports (agents handle named exports more reliably; refactoring is less error-prone).
2. **Pure functions at the core**: Keep I/O at edges, pass data in/return data out (same principle as Python/Bash guides).
3. **Deterministic by default**: Avoid direct use of `Date.now()`, `Math.random()`, `crypto.randomUUID()` in business logic; inject or wrap for testability.
4. **Narrow types over broad types**: Prefer union types and discriminated unions over `any`/`unknown` escape hatches.
5. **Error handling discipline**: Prefer explicit error returns or Result types over uncaught exceptions; agents struggle with implicit exception flows.
6. **One-sentence-per-line documentation**: Same as other conventional-agents guides; easier for agents to parse and modify.
7. **Fast, cacheable test execution**: Vitest and Jest both support watch mode and selective re-runs; agents benefit from tools that re-run only affected tests.

## Success Criteria

Each bullet MUST be objectively testable.

- Given a checkout of the conventional-agents repo, when listing `guidelines/javascript/`, then the directory contains exactly three files: `JS_STYLE_GUIDE.md`, `JS_TESTING_GUIDE.md`, `JS_IMPLEMENTATION_GUIDE.md`.
- Given `JS_STYLE_GUIDE.md`, when reading it, then it contains sections covering: decision precedence, voice/tone, module system (ESM vs CJS), naming conventions, TypeScript typing discipline, documentation/comments, formatting tool expectations, and import organization.
- Given `JS_STYLE_GUIDE.md`, when reading it, then it does NOT prescribe a specific frontend or backend framework.
- Given `JS_TESTING_GUIDE.md`, when reading it, then it contains sections covering: scope, parsing guidance for agents (authoritative signals, test file metadata), test framework expectations (framework-agnostic with recommended defaults), success criteria mapping rules, approved test patterns (with at least 2 runnable examples), and common pitfalls.
- Given `JS_TESTING_GUIDE.md`, when reading it, then it includes a test file metadata block convention compatible with the existing Python/Bash patterns (YAML-like front matter in a comment block).
- Given `JS_IMPLEMENTATION_GUIDE.md`, when reading it, then it contains sections covering: role definition, authoritative inputs (priority order), parsing hints, tooling/environment assumptions, code shape guidelines (pure functions, determinism, error handling, module boundaries), and common pitfalls.
- Given `JS_IMPLEMENTATION_GUIDE.md`, when reading it, then it includes at least one JavaScript-specific pitfall not present in the Python or Bash guides (e.g., ESM/CJS confusion, `this` binding, prototype chain issues, or shell interpolation of `$` in filenames).
- Given all three guides, when checking for framework-specific prescriptions, then none of them mandate a specific linter, formatter, test runner, or framework — instead they say "follow existing repo conventions" with recommended defaults for new projects.
- Given all three guides, when checking line counts, then each guide is between 150 and 600 lines (consistent with existing Bash and Python guide sizes).
- Given all three guides, when running markdownlint against them, then zero lint errors are reported.

## Edge Cases

- Projects using pure JavaScript (no TypeScript): guides must be useful without assuming TypeScript is present, while recommending TypeScript for new projects.
- Projects using CommonJS (legacy): guides must acknowledge CJS and provide clear guidance for agents working in CJS codebases, not just ESM.
- Monorepo setups: guides should not assume a single-package structure but should not prescribe monorepo tooling either.
- Deno and Bun runtimes: guides should primarily target Node.js but should not include Node-only assumptions that break on alternative runtimes where avoidable.

## Out of Scope

- Frontend component testing guidance (React Testing Library, Cypress, Playwright for UI).
- Build system configuration (Webpack, Vite, esbuild, Rollup).
- Deployment or CI/CD pipeline configuration.
- Package publishing guidance (npm publish workflows).
- Specific ESLint/Biome/Prettier rule recommendations (guides reference tools but don't prescribe configs).

## Dependencies

- Existing guideline structure in `guidelines/bash/` and `guidelines/python/` (pattern to follow).
- Existing template and PARSING_HINTS conventions from the conventional-agents framework.

## Resolved Questions

- **Filename prefix**: `JS_` (brevity; community convention; TypeScript is covered within the same guides).
- **TypeScript integration**: Integrated into the JS guides with clearly labeled `### TypeScript-specific` subsections. No separate TS guide set. Rationale: ~90% of guidance overlaps; splitting into 6 files would duplicate heavily and create drift.

## Open Questions

None. All blocking questions resolved.
