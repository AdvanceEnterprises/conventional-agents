---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs: [FS-0016]
related_adrs: [ADR-0017]
created: 2026-07-27
updated: 2026-07-27
---

# Change Plan: Implement Framework Internal Vendor Boundary

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0016
- Related ADR ID(s): ADR-0017
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Remove `vendor/conventional-commits/`, `vendor/keep-a-changelog/`, and
  `vendor/arc42-template/` git submodules.
- Keep `vendor/madr/` as the only internal operational submodule.
- Update `docs/decisions/README.md` to list ADR-0017.
- Update consumer-facing references in:
  - `workflows/git-and-gh-conventions.md`
  - `workflows/versioning-and-releases.md`
  - `CHANGELOG.md`
  - `skills/git-gh-workflow/SKILL.md`
  - `README.md`
  - `AGENTS.md`
  - `INTEGRATION.md`
- Add historical-context notes to:
  - `docs/ARC42.md`
  - `docs/decisions/ADR-0003.md`
  - `docs/specifications/FS-0009-vendor-upstream-specs.md`
  - `docs/change-plans/PLAN-0009-vendor-upstream-specs.md`
- Add `CHANGELOG.md` `[Unreleased]` entry describing the breaking change and
  annotate the v2.0.0 entry.
- Bump `package.json` version from `2.0.0` to `2.1.0`.
- Create `skills/framework-consumer-integration/SKILL.md` to guide agents
  integrating the framework into host projects.
- Delete the legacy `docs/implementation-plans/` directory.

**This change will NOT:**

- Modify the framework's commit-message or changelog contract substance.
- Add build tooling or dependencies.
- Rename or move `vendor/madr/`.
- Modify accepted ADR bodies beyond append-only status notes.
- Change MADR template or lint config copies in `templates/` and
  `docs/decisions/`.

## 3. Tests Driving This Change

Validation is via:

- `git submodule status` confirms only `vendor/madr/` remains.
- `test/FS-0001/adr-linting.bats` continues to pass (byte-equality check for
  `vendor/madr/.markdownlint.yml`).
- `npm run check:status` passes.
- `npm run lint:docs` passes on all modified CI-linted files.
- Manual review confirms no consumer-facing file references
  `vendor/conventional-agents/vendor/...` paths.

## 4. Files to Be Modified

- `.gitmodules`
- `vendor/conventional-commits/` (delete)
- `vendor/keep-a-changelog/` (delete)
- `vendor/arc42-template/` (delete)
- `docs/decisions/ADR-0017-framework-internal-submodules.md` (already created)
- `docs/decisions/README.md`
- `workflows/git-and-gh-conventions.md`
- `workflows/versioning-and-releases.md`
- `CHANGELOG.md`
- `skills/git-gh-workflow/SKILL.md`
- `README.md`
- `AGENTS.md`
- `INTEGRATION.md`
- `docs/ARC42.md`
- `docs/decisions/ADR-0003.md`
- `docs/specifications/FS-0009-vendor-upstream-specs.md`
- `docs/change-plans/PLAN-0009-vendor-upstream-specs.md`
- `package.json`
- `skills/framework-consumer-integration/SKILL.md` (new)
- `skills/index.md`
- `docs/implementation-plans/` (delete)

## 5. Implementation Steps (High-Level)

1. **Write ADR-0017** documenting the vendor-internal decision and its
   rules.
2. **Remove submodules** with `git rm` for the three dropped submodules and
   update `.gitmodules`.
3. **Update consumer-facing docs** to cite framework files or upstream URLs.
4. **Update historical docs** with append-only status notes pointing at
   ADR-0017.
5. **Update CHANGELOG** with `[Unreleased]` entry and v2.0.0 annotation.
6. **Bump package.json** to `2.1.0`.
7. **Rewrite `AGENTS.md`** and update `README.md`/`INTEGRATION.md` for clear
   consumer onboarding.
8. **Create `framework-consumer-integration` skill** and register it in
   `skills/index.md`.
9. **Delete `docs/implementation-plans/`**.
10. **Run `npm run check:status` and `npm run lint:docs`**.

## 6. Constraints and Guardrails

- FS-0016 Non-Goals: no substance changes to commit/changelog contracts, no
  new build tooling, no additional consumer submodules.
- ADR-0017 constraints: `vendor/` is framework-internal; consumers must not
  reference nested vendor paths.
- ADR-0000 immutability rule: accepted ADR bodies remain append-only; updates
  use status notes.

## 7. Risks and Edge Cases

- Consumers may have referenced dropped submodule paths. Mitigation: clear
  migration guidance in `INTEGRATION.md` and the new skill.
- Historical docs may be misread as current. Mitigation: explicit status
  notes and CHANGELOG annotation.

## 8. Validation

- `git submodule status` shows only `vendor/madr/`.
- `npm run check:status` exits zero.
- `npm run lint:docs` exits zero.
- `test/FS-0001/adr-linting.bats` passes.
- No `vendor/conventional-agents/vendor/...` strings in `README.md`,
  `AGENTS.md`, `INTEGRATION.md`, or `skills/framework-consumer-integration/SKILL.md`.

## 9. Explicit Non-Changes

- `templates/core/adr-full-madr.md`
- `docs/decisions/.markdownlint.yml`
- `vendor/madr/` content or mount path
- CI workflow definitions
- Existing ADR bodies beyond status notes

## 10. Readiness Check

- [x] Spec is approved (FS-0016 implemented as part of this PR; spec-first
  discipline applied retroactively)
- [x] Tests exist or are clearly defined
- [x] Scope is minimal and explicit
- [x] No architectural changes implied beyond the vendor boundary

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
