---
type: change-plan
role: implementer
language: markdown
status: deprecated
related_specs:
  - FS-0004
related_adrs:
  - ADR-0011
  - ADR-0012
created: 2026-02-07
updated: 2026-08-24
---

# PLAN-0002: Implement FS-0004 — Agent commentary policy (role-aware)

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0004
- Related ADR ID(s): ADR-0011, ADR-0012
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Replace the current single PR body template in `workflows/git-and-gh-conventions.md`
  (step 5 of the standard workflow) with five per-role templates: Head Architect,
  Document Author, Spec Reader and Test Planner, Implementer, and Communications Lead.
- Strengthen the commit body guidance with four explicit required fields (Why, What,
  Risk, Validation) and a trivial-change exception.
- Preserve and lightly clean up the existing PR update comment section.

**This change will NOT:**

- Add CI enforcement that blocks merges based on PR body structure.
- Change commit message subject line conventions (Conventional Commits, already live).
- Change branching or merge strategy (FS-0003, already implemented).
- Add any new files — this is a single workflow document update.

## 3. Tests Driving This Change

`test_required: false` per FS-0004. Success verified against the five success criteria
in FS-0004:

1. Per-role PR templates present for Role 0, 1, 2, 3, and 5.
2. Commit body section defines four required fields plus trivial exception.
3. PR update comment section specifies the three required elements.
4. Old single-template format (`Summary: / Context / Why: / Changes: / Validation: /
   Risk / Rollback:` as a flat list) is not present.
5. `npm run check:status` exits zero.

## 4. Files to Be Modified

- **Modify:** `workflows/git-and-gh-conventions.md` — replace PR body template,
  strengthen commit body section, clean up PR update comment section.

## 5. Implementation Steps

1. In `workflows/git-and-gh-conventions.md`, locate the "PR body template (agents)"
   subsection inside step 5 (Open a PR).
2. Replace the flat five-field template with a heading and five role-specific
   subsections, one per role that opens PRs (Roles 0, 1, 2, 3, 5). Each subsection
   must include the required sections defined in FS-0004 Policy.
3. Locate the "Commit bodies (agents)" section under Commits.
4. Expand it: add the four required fields (Why, What, Risk, Validation) as an explicit
   list; add the trivial-change exception ("may omit the body if the change is trivially
   self-evident from the subject line"); preserve the secrets prohibition.
5. Locate the "PR update comment (agents)" subsection in step 6.
6. Verify it covers the three required elements (addressed items, changes, validation).
   Tighten the language if needed without removing existing content.
7. Run `npm run check:status` — must exit zero.
8. Run `npm run lint:workflows` — must exit zero.

## 6. Constraints and Guardrails

- Single file change only — `workflows/git-and-gh-conventions.md`.
- Role 4 (Reviewer) intentionally has no PR template; do not add one.
- The existing PR update comment section must be preserved, not replaced.
- No new sections may be added to the workflow document beyond what FS-0004 specifies.

## 7. Risks and Edge Cases

- The workflow document is in the exported surface (`workflows/`) and is linted by CI.
  The updated content must pass `markdownlint-cli2`.
- Multi-role PRs: the implementation should note in the workflow doc that multi-role
  PRs use the dominant role's template (per FS-0004 edge cases).
- The squash-merge note (PR description becomes the permanent trunk commit body) should
  be added near the templates as a reminder of why they matter.

## 8. Validation

- All five FS-0004 success criteria pass (see section 3).
- `npm run check:status` exits zero.
- `npm run lint:workflows` exits zero.

## 9. Explicit Non-Changes

- No changes to commit subject conventions, branching, or merge strategy.
- No changes to any FS, PLAN, or ADR documents other than status transitions.
- No changes to CI workflows, scripts, or package.json.
- No changes to ROLE_CONTRACT or session modes.

## 10. Readiness Check

- [ ] FS-0004 is approved (currently draft — this plan cannot be approved until FS-0004 is)
- [x] Scope is minimal and explicit — single file change
- [x] CP migration removed — that work shipped in an earlier release
- [x] No architectural or code changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
