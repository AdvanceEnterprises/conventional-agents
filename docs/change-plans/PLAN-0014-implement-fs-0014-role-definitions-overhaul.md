---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs:
  - FS-0014
related_adrs:
  - ADR-0002
  - ADR-0006
  - ADR-0007
  - ADR-0012
created: 2026-06-08
updated: 2026-06-08
---

# PLAN-0014: Implement FS-0014 — Role Definitions Overhaul

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0014
- Related ADR ID(s): ADR-0002, ADR-0006, ADR-0007, ADR-0012
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Rewrite `guidelines/ROLE_CONTRACT.md` to define all six roles with correct content.
- Populate `roles/ROLE_CONTRACT.md` from the rewritten `guidelines/` as the initial
  project-customizable starting point (overwrite the currently empty file).
- Update `docs/change-plans/README.md` to add the PLAN-0014 row.
- Update `docs/specifications/README.md` to reflect FS-0014 status as approved.
- Update `CHANGELOG.md` with an [Unreleased] entry.

**This change will NOT:**

- Create per-role separate files — ROLE_CONTRACT remains a single document.
- Add tooling to enforce role assignment at runtime.
- Change any non-role content in ROLE_CONTRACT beyond the precedence correction and
  stale path fix (no changes to shared rules, safety gates, or hygiene gate checklist
  — those are already current).
- Modify any FS, PLAN, or ADR templates.

## 3. Tests Driving This Change

`test_required: false` per FS-0014. Success is verified by the success criteria in
FS-0014, each of which is directly observable after implementation:

1. `grep -r "docs/specs/" guidelines/ROLE_CONTRACT.md roles/ROLE_CONTRACT.md` → zero
   matches (stale path eliminated).
2. Conflict resolution section lists six levels (0–5) and Level 0 references ADR-0012.
3. Exactly six role headings present in the rewritten ROLE_CONTRACT.
4. `npm run check:status` in the `check:status` responsibilities of Document Author
   and Implementer roles.
5. `roles/ROLE_CONTRACT.md` is non-empty and contains all six role headings.
6. `npm run check:status` exits zero after implementation.

## 4. Files to Be Modified

- **Rewrite:** `guidelines/ROLE_CONTRACT.md` — full rewrite with six roles
- **Overwrite:** `roles/ROLE_CONTRACT.md` — populate from guidelines/ (currently empty)
- **Modify:** `docs/change-plans/README.md` — add PLAN-0014 row
- **Modify:** `docs/specifications/README.md` — FS-0014 status: draft → approved
- **Modify:** `CHANGELOG.md` — add [Unreleased] entry

## 5. Implementation Steps

1. Rewrite `guidelines/ROLE_CONTRACT.md` with the following structure:
   - Preserve all existing shared rules sections verbatim (Document authority, Scope
     control, Modification rules, Versioning and release constraints, Pre-commit testing
     gate, Spec-first rule).
   - Preserve Non-Overridable Safety Gates (ADR-0012) section verbatim — no changes.
   - Preserve Document hygiene gate section verbatim — already updated by FS-0013.
   - Replace the three existing role definitions (Role 1: Spec Reader, Role 2:
     Implementer, Role 3: Reviewer) with the six roles defined in FS-0014:
     - Role 0 — Head Architect
     - Role 1 — Document Author
     - Role 2 — Spec Reader and Test Planner
     - Role 3 — Implementer
     - Role 4 — Reviewer
     - Role 5 — Communications Lead
   - Replace the Conflict Resolution Rules section with the six-level precedence model
     from FS-0014 (Level 0 = ADR-0012 non-overridable gates through Level 5 = code).
   - Fix stale path: `docs/specs/*.md` → `docs/specifications/FS-*.md` in Role 2
     (Spec Reader).
   - Assign `npm run check:status` responsibility explicitly in Role 1 (Document Author)
     and Role 3 (Implementer).
   - Preserve the Non-Goals and Final Rule sections verbatim.

2. Copy the rewritten `guidelines/ROLE_CONTRACT.md` to `roles/ROLE_CONTRACT.md`
   (overwrite the empty file). This is the initial project-customizable starting point;
   the two files are expected to diverge as host projects adapt them.

3. Add PLAN-0014 row to `docs/change-plans/README.md`.

4. Update FS-0014 status in `docs/specifications/README.md` from `draft` to `approved`.

5. Add [Unreleased] CHANGELOG entry:
   - Role definitions overhaul: six roles defined (Head Architect, Document Author,
     Spec Reader and Test Planner, Implementer, Reviewer, Communications Lead).
   - Conflict resolution precedence corrected to six levels (Level 0 = ADR-0012 gates).
   - Stale `docs/specs/` path fixed to `docs/specifications/FS-*.md`.
   - `roles/ROLE_CONTRACT.md` populated (was empty).

6. Run `npm run check:status` — must exit zero.
7. Run `npm run lint:docs` — must exit zero.

## 6. Constraints and Guardrails

- All shared rules, safety gates, and the hygiene gate checklist are preserved verbatim
  — this plan touches role definitions and conflict resolution only.
- ADR-0012 non-overridable gates are reproduced unchanged.
- The precedence correction adds Level 0 above the existing five levels; it does not
  reorder or remove any existing levels.
- No markdown or YAML schema changes.

## 7. Risks and Edge Cases

- `roles/ROLE_CONTRACT.md` is currently empty — overwriting it is safe and intentional.
- The two files (`guidelines/` and `roles/`) will start identical but diverge by design;
  there is no enforcement mechanism to keep them in sync. This is the intended model per
  FS-0014.
- Role numbering shifts: existing Roles 1–3 are renumbered to Roles 2–4 in the new
  model. Any documentation that references role numbers by ordinal (not by name) will be
  stale after this change. A grep for "Role 1", "Role 2", "Role 3" across the repo
  should be done before committing to catch any such references.

## 8. Validation

- All six FS-0014 success criteria pass (see section 3 above).
- `npm run check:status` exits zero.
- `npm run lint:docs` exits zero.
- `roles/ROLE_CONTRACT.md` is non-empty.
- `grep -r "docs/specs/" guidelines/ roles/` returns zero matches.

## 9. Explicit Non-Changes

- No changes to any FS, PLAN, or ADR documents other than FS-0014 status update.
- No changes to `scripts/check-status.sh`, `package.json`, or CI workflows.
- No changes to templates or workflow docs.
- No changes to the document hygiene gate checklist (already updated by FS-0013/PLAN-0013).

## 10. Readiness Check

- [x] FS-0014 is approved
- [x] Scope is minimal and explicit
- [x] No code changes — documentation only
- [x] Success criteria are objectively verifiable

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
