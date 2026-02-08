# Repository Guidelines

This repository is a documentation and template kit for AI-assisted development. It is consumed via filesystem paths and git submodules.

## Project Structure & Module Organization

- `guidelines/`: Evidence-based engineering and testing guides.
- `roles/`: Role contracts and universal guardrails.
- `templates/`: Reusable templates (ADRs, feature specs, change plans, reviews).
- `docs/`: Architecture (`docs/ARC42.md`), decisions (`docs/decisions/`), and specs (`docs/specifications/`).
- `skills/`: Portable skill modules (`skills/<topic>/SKILL.md`).
- `vendor/`: Upstream submodules (arc42 template, MADR).

There is no application source code or runtime assets in this repo.

## Build, Test, and Development Commands

No build or test commands are required for day-to-day work.
- Optional doc linting: `npm install` then `npm run lint:docs` (or `npm run lint:adrs` etc.)
- Git submodules: `git submodule update --init` to populate `vendor/`

## Coding Style & Naming Conventions

Content is Markdown. Follow MADR formatting for ADRs and keep one-sentence-per-line style.
Naming patterns:
- ADRs: `docs/decisions/ADR-0001.md`
- Feature specs: `docs/specifications/FS-0001-<name>.md`
- Skills: `skills/<topic>/SKILL.md`

## Testing Guidelines

There are no code tests in this repository. Quality gates are documentation-centric.
If you add ADRs, ensure they remain lint-clean once markdownlint is enabled (see `docs/decisions/README.md`).

**For projects consuming this kit:** the framework follows a BDD/TDD workflow (Docs → Tests → Code).
Agents MUST run the project's test suite and verify tests pass before committing changes.
See `guidelines/ROLE_CONTRACT.md` for role definitions and the testing-first workflow.

Language-specific testing guidance:

- Bash: `guidelines/bash/BASH_TESTING_GUIDE.md`
- Python: `guidelines/python/PYTHON_TESTING_GUIDE.md`
- JavaScript/TypeScript: `guidelines/javascript/JS_TESTING_GUIDE.md`

## Commit & Pull Request Guidelines

No formal commit message convention is established. Use clear, descriptive messages (e.g., "Add ADR-000X for <decision>").
Pull requests should:
- State the document(s) changed and intent.
- Link related ADRs or specs when applicable.
- Avoid editing submodule contents directly.
- Confirm all tests pass before submitting (agents MUST NOT commit code with failing tests).

## Architecture Overview

Architecture is documented in `docs/ARC42.md`. Decisions live in `docs/decisions/` and are treated as constraints once accepted.
