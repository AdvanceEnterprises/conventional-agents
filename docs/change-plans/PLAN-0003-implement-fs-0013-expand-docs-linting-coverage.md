---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs:
  - FS-0013
related_adrs: []
created: 2026-02-07
updated: 2026-02-07
---

# PLAN-0003: Implement FS-0013 expand docs linting coverage

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0013
- Related ADR ID(s): (none)
- Issue / PR Reference: (to be created)

## 2. Scope of Change

This change WILL:

- Expand existing markdownlint CI to lint only the owned doc classes:
  - `docs/decisions/ADR-*.md`
  - `docs/specifications/FS-*.md`
  - `docs/change-plans/PLAN-*.md`
  - `docs/workflows/*.md`
- Keep scope limited (do not lint all markdown under `docs/`).

This change will NOT:

- Add semantic/schema validation for front matter.
- Change markdownlint rule configuration beyond what’s necessary to include new globs.

## 3. Tests Driving This Change

- CI workflow execution (GitHub Actions)

## 4. Files to Be Modified

- .github/workflows/* (the existing markdownlint workflow file(s))

## 5. Implementation Steps (High-Level)

1. Locate the existing markdownlint workflow that runs on `docs/decisions/ADR-*.md`.
2. Expand it by either:
   - adding additional jobs (lint-fs, lint-change-plans, lint-workflows), or
   - expanding the existing job globs to include the new patterns.
3. Ensure the patterns match only the owned doc classes (no `docs/**/*.md`).
4. Confirm that `PLAN-*.md` is the canonical plan naming convention.
   - Dependency: if the repo still has `CP-*.md`, migrate first (preferred) or include both patterns.
5. Update contributor-facing docs if there is a note about lint scope.

## 6. Constraints and Guardrails

- Spec constraints:
  - FS-0013 Non-Goals: do not lint all docs; do not add semantic validation.
- Guardrails:
  - Keep CI runtime small (do not lint unnecessary paths).

## 7. Risks and Edge Cases

- If change plan naming is not yet migrated, CI may miss existing plans.
- Overly broad globs could lint vendor or third-party markdown.

## 8. Validation

- CI checks:
  - Open a PR that introduces a known markdownlint violation in each doc class and confirm the relevant job fails.
  - Open a PR that changes only a non-owned markdown file under `docs/` and confirm these jobs do not expand to lint all docs.

## 9. Explicit Non-Changes

- No changes to documentation content outside of lint scope.
- No changes to merge policy.

## 10. Readiness Check

- [ ] FS-0013 is approved
- [ ] Scope is minimal and explicit
- [ ] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
