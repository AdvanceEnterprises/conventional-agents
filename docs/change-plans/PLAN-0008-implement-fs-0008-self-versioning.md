---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs:
  - FS-0008
related_adrs: []
created: 2026-02-08
updated: 2026-06-08
---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This is a release-prep change: version bumps and changelog creation.
- Treat the completed plan as a binding contract for implementation.
-->

# Change Plan: Implement FS-0008 — Self-versioning and Changelog

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0008
- Related ADR ID(s): None
- Issue / PR Reference: N/A (follows from PR #18 / FS-0007)

## 2. Scope of Change

**This change WILL:**

- Create `CHANGELOG.md` at repo root with retroactive entries and an `[Unreleased]` section.
- Update `README.md` framework version from `1.0.0` to `1.1.0`.
- Update `package.json` version from its current value to `1.1.0`.

**Implementation will NOT:**

- Create git tags or GitHub Releases (human-gated per FS-0007).
- Modify any other files.
- Set up CI/CD release automation.
- Bump the submodule pointer in `agentic-bootstrap-constitution`.

## 3. Tests Driving This Change

Documentation-only + manifest change. Quality gates:

- `npx markdownlint-cli2 "CHANGELOG.md"` must pass (zero errors).
- `npm run lint:docs` must pass (existing lint scripts in `package.json`).

## 4. Files to Be Modified

**New files:**

- `CHANGELOG.md`

**Existing files to update:**

- `README.md` (version reference line)
- `package.json` (version field)

## 5. Implementation Steps (High-Level)

1. Write `CHANGELOG.md`:
   - Keep a Changelog format.
   - `[Unreleased]` section at top (empty).
   - `[1.1.0] - 2026-02-08` section with retroactive entries covering:
     - Project rename to conventional-agents.
     - Exported surface / internal governance split (workflows/ move).
     - JavaScript/TypeScript guidelines (3 files).
     - BDD/TDD pre-commit testing gates in ROLE_CONTRACT.
     - Versioning, releases, and packaging workflow.
     - Version-number constraints in all implementation guides.
     - Doc linting improvements (workflow rename, new lint scripts).
     - README updates (submodule URLs, recursive property docs).
   - `[1.0.0] - 2026-01-27` section noting the initial framework baseline.

2. Update `README.md`: change `Framework Version: 1.0.0` to `Framework Version: 1.1.0`.

3. Update `package.json`: change version to `"1.1.0"`.

4. Run markdownlint and lint:docs to validate.

## 6. Constraints and Guardrails

- Per FS-0007 / workflows/versioning-and-releases.md: this is a release-prep change, so version bumps are appropriate here.
- CHANGELOG must be human-curated, not auto-generated.
- Do not create tags or publish (human-gated).

## 7. Risks and Edge Cases

- Retroactive changelog may miss some changes. Mitigated by: reviewing git log from initial commit through current trunk.
- package-lock.json may change if npm processes the version bump. Acceptable: commit the updated lockfile.

## 8. Validation

- `CHANGELOG.md` exists and follows Keep a Changelog format.
- `CHANGELOG.md` has `[Unreleased]` and `[1.1.0]` sections.
- `README.md` shows `1.1.0`.
- `package.json` shows `"1.1.0"`.
- All markdownlint passes.

## 9. Explicit Non-Changes

- `docs/` governance files (ADRs, specs, change plans) — not modified (except this plan and the FS, which are added).
- `guidelines/`, `workflows/`, `templates/`, `skills/`, `roles/` — not modified.
- `AGENTS.md`, `CONTRIBUTING.md`, `INTEGRATION.md` — not modified.

## 10. Readiness Check

- [x] Spec is approved (FS-0008)
- [x] Tests defined (markdownlint quality gate)
- [x] Scope is minimal and explicit
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
