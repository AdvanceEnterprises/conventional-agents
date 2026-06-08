---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs:
  - FS-0015
related_adrs:
  - ADR-0002
  - ADR-0006
  - ADR-0012
created: 2026-06-08
updated: 2026-06-08
---

# PLAN-0015: Implement FS-0015 — Role Selection and Session Modes

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0015
- Related ADR ID(s): ADR-0002, ADR-0006, ADR-0012
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Add `Best used when` and `Avoid when` sub-sections to each of the six roles in
  `guidelines/ROLE_CONTRACT.md`.
- Add a Role and Session Transparency rule to the Shared Rules section of
  `guidelines/ROLE_CONTRACT.md`, with a direct reference to `workflows/session-modes.md`.
- Sync both changes to `roles/ROLE_CONTRACT.md`.
- Create `workflows/session-modes.md` defining the five named session modes.
- Update `docs/change-plans/README.md` to add PLAN-0015.
- Update `docs/specifications/README.md` to reflect FS-0015 as implemented.
- Update `CHANGELOG.md` with an [Unreleased] entry.

**This change will NOT:**

- Add new roles or modify any existing role's purpose, mandate, inputs, outputs,
  prohibited actions, or stop conditions.
- Add a routing component, routing rules file, or dispatcher.
- Modify any non-role content in ROLE_CONTRACT beyond Shared Rules and the role
  definition sections.
- Modify any FS, PLAN, or ADR templates.

## 3. Tests Driving This Change

`test_required: false` per FS-0015. Success verified against the six success criteria
in FS-0015:

1. Each of the six role definitions in ROLE_CONTRACT contains `Best used when` and
   `Avoid when` sections.
2. Shared Rules contains a role and session transparency rule referencing
   `workflows/session-modes.md`.
3. `workflows/session-modes.md` contains exactly five mode headings.
4. Each mode contains: purpose, primary role, supporting roles, out of scope,
   escalation triggers, and a role-transition phrase.
5. `npm run check:status` exits zero.
6. `roles/ROLE_CONTRACT.md` contains the same `best_used_when` / `avoid_when` sections
   and the same explainability rule as `guidelines/ROLE_CONTRACT.md`.

## 4. Files to Be Modified

- **Modify:** `guidelines/ROLE_CONTRACT.md` — add best_used_when/avoid_when per role;
  add transparency rule to Shared Rules
- **Overwrite:** `roles/ROLE_CONTRACT.md` — sync from guidelines/
- **Add:** `workflows/session-modes.md` — five session modes
- **Modify:** `docs/change-plans/README.md` — add PLAN-0015 row
- **Modify:** `docs/specifications/README.md` — FS-0015 status: approved → implemented
- **Modify:** `CHANGELOG.md` — add [Unreleased] entry

## 5. Implementation Steps

1. For each of the six roles in `guidelines/ROLE_CONTRACT.md`, add two sub-sections
   immediately after the Stop Conditions section, using the content defined in FS-0015.
2. Add Role and Session Transparency to Shared Rules in `guidelines/ROLE_CONTRACT.md`,
   between Spec-first rule and the separator before Non-Overridable Safety Gates.
   Include the direct reference to `workflows/session-modes.md`.
3. Copy `guidelines/ROLE_CONTRACT.md` to `roles/ROLE_CONTRACT.md`.
4. Create `workflows/session-modes.md` with the five modes defined in FS-0015.
5. Update `docs/change-plans/README.md` and `docs/specifications/README.md`.
6. Update `CHANGELOG.md`.
7. Run `npm run check:status` — must exit zero.
8. Run `npm run lint:docs` — must exit zero.

## 6. Constraints and Guardrails

- Role purpose, mandate, inputs, outputs, prohibited actions, and stop conditions are
  preserved verbatim — only the two new sub-sections are added per role.
- The transparency rule is added to Shared Rules, not to any individual role, because
  it applies across all roles.
- `workflows/session-modes.md` content is sourced directly from FS-0015 — do not
  expand or reinterpret.

## 7. Risks and Edge Cases

- `roles/ROLE_CONTRACT.md` is overwritten with a full copy of `guidelines/` per the
  FS-0014 model. Any customizations a project had made to `roles/` would be lost. In
  this project, the two files are identical at the time of this plan, so no data loss.
- The transparency rule must reference `workflows/session-modes.md` by the exact path
  as it will exist after this plan is executed.

## 8. Validation

- All six FS-0015 success criteria pass (see section 3).
- `npm run check:status` exits zero.
- `npm run lint:docs` exits zero.
- `grep "Best used when" guidelines/ROLE_CONTRACT.md | wc -l` returns 6.
- `grep "Avoid when" guidelines/ROLE_CONTRACT.md | wc -l` returns 6.

## 9. Explicit Non-Changes

- No changes to any existing role's core definition.
- No changes to Non-Overridable Safety Gates section.
- No changes to Document hygiene gate section.
- No changes to scripts, CI workflows, or package.json.

## 10. Readiness Check

- [x] FS-0015 is approved
- [x] Scope is minimal and explicit
- [x] Documentation-only changes
- [x] Success criteria are objectively verifiable

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
