---
type: change-plan
role: implementer
language: markdown
status: in-progress
related_specs: [FS-0018]
related_adrs: [ADR-0012]
created: 2026-02-16
updated: 2026-02-16
---

# Change Plan: Implement FS-0018 — Process Compliance Gates and Document Lifecycle

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0018
- Related ADR ID(s): ADR-0012
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Add spec-first gate, merge prohibition, identity verification gate, and document hygiene checklist to ROLE_CONTRACT
- Create `workflows/document-lifecycle.md` with status values, transition rules, and responsible parties
- Update `workflows/README.md` to list all workflow documents (including catching up missing entries)
- Update `workflows/git-and-gh-conventions.md` to reinforce identity verification and merge prohibition
- Update INTEGRATION.md precedence rules to add level 0 (non-overridable safety gates per ADR-0012)
- Update `docs/specifications/README.md`, `docs/change-plans/README.md`, and `docs/decisions/README.md` with agent-update requirements and current document tables

**This change will NOT:**

- Build CI tooling for mechanical enforcement
- Retroactively fix statuses on existing FS/PLAN documents (separate task)
- Change FS/PLAN/ADR template structure
- Modify any guideline substance

## 3. Tests Driving This Change

Validation is via:

- `npm run lint:docs` passing on all modified markdown
- Manual verification against each FS-0018 Success Criterion (11 items)

## 4. Files to Be Modified

- `guidelines/ROLE_CONTRACT.md` (modify)
- `workflows/document-lifecycle.md` (new)
- `workflows/README.md` (modify)
- `workflows/git-and-gh-conventions.md` (modify)
- `INTEGRATION.md` (modify)
- `docs/specifications/README.md` (modify)
- `docs/change-plans/README.md` (modify)
- `docs/decisions/README.md` (modify)

## 5. Implementation Steps (High-Level)

1. **Create `workflows/document-lifecycle.md`**
   - Status value tables for FS, PLAN, and ADR
   - Transition rules with responsible party and timing
   - Explicit rule: agents MUST NOT implement `draft` specs
   - Multi-PR implementation guidance (`in-progress` until final PR)
   - Stale document guidance (unused `approved` specs → `deprecated`)

2. **Update `guidelines/ROLE_CONTRACT.md`** — add four new subsections to "Shared Rules":
   - **Spec-first rule**: approved FS + PLAN required before implementation; exceptions for trivial fixes and hotfixes
   - **PR merge rule** (non-overridable safety gate per ADR-0012): agents must not merge PRs
   - **GitHub identity gate** (non-overridable safety gate per ADR-0012): `gh auth status` before every operation
   - **Document hygiene gate**: 6-item pre-commit/PR checklist (statuses, dates, READMEs, CHANGELOG, cross-refs, interfaces)
   - Reference `workflows/document-lifecycle.md` for lifecycle details

3. **Update `INTEGRATION.md`** — modify the precedence table/list:
   - Add level 0: "Non-overridable safety gates (ROLE_CONTRACT § Non-Overridable Safety Gates)" above current level 1
   - Reference ADR-0012
   - Renumber existing levels (1→2, 2→3, etc.) or use 0-indexed numbering

4. **Update `workflows/git-and-gh-conventions.md`**:
   - In the "Standard workflow" section step 8 (Merge), add: "Agents must not merge. This is a non-overridable safety gate (ADR-0012)."
   - Add identity verification step at the top of the standard workflow: "Before starting, verify your `gh` identity"

5. **Update `workflows/README.md`**:
   - Add missing entry for `versioning-and-releases.md`
   - Add new entry for `document-lifecycle.md`

6. **Update `docs/specifications/README.md`**:
   - Add note: "Agents MUST update this file when adding new specs or changing spec statuses."
   - Add/update table of current specs with statuses

7. **Update `docs/change-plans/README.md`**:
   - Add note: "Agents MUST update this file when adding new plans or changing plan statuses."
   - Add/update table of current plans with statuses

8. **Update `docs/decisions/README.md`**:
   - Add note: "Agents MUST update this file when adding new ADRs or changing ADR statuses."
   - Verify existing ADR table/list is current

9. **Run `npm run lint:docs`** — verify all markdown passes

## 6. Constraints and Guardrails

- FS-0018 Non-Goals: no CI tooling, no retroactive fixes, no template structure changes
- ADR-0012: super-gates must be clearly marked and narrowly scoped (only merge prohibition and identity verification)
- Precedence renumbering must not break existing references in other docs

## 7. Risks and Edge Cases

- Renumbering precedence levels may confuse agents trained on the old numbering — mitigate by updating all references in the same PR
- The ROLE_CONTRACT is already long — adding 4 subsections needs clear structure to remain scannable
- Existing docs README files vary in structure — normalize them enough to be consistent without rewriting everything

## 8. Validation

- Each of the 11 FS-0018 Success Criteria verified manually
- All markdown lint passes
- Precedence references consistent across INTEGRATION.md, ROLE_CONTRACT, and any other files that mention the precedence chain

## 9. Explicit Non-Changes

- FS/PLAN/ADR template files (no structural changes)
- Existing document statuses (retroactive cleanup is a separate task)
- CI workflow configuration
- Guideline substance (Python, Bash, JS guides untouched)

## 10. Readiness Check

- [x] Spec is approved (FS-0018)
- [x] ADR is accepted (ADR-0012)
- [x] Tests exist or are clearly defined (lint + manual SC verification)
- [x] Scope is minimal and explicit
- [x] No architectural changes implied (ADR-0012 covers the precedence model change)

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
