# Implement FS-0012 agent commentary policy

Generated: 2026-02-07T14:48:36

---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs:
  - FS-0012
  - FS-0011
related_adrs:
  - ADR-0011
created: 2026-02-07
updated: 2026-02-07
---

## 1. Feature / Issue Reference
- Feature Spec ID(s): FS-0012
- Related ADR ID(s): ADR-0011
- Issue / PR Reference: (to be created)

## 2. Scope of Change

This change WILL:
- Implement the FS-0012 policy by updating existing workflow documentation with:
  - a minimum PR description template for agent-authored PRs
  - minimum expectations for agent-authored commit messages/bodies
  - a required “PR update comment” pattern after addressing review feedback
- Include a **name migration** to remove ambiguity in change plan naming:
  - migrate `docs/change-plans/CP-*.md` to the `docs/change-plans/PLAN-*.md` convention
  - update internal links/references (if any) to the new filenames
  - ensure we have one canonical change plan naming scheme going forward

This change will NOT:
- Add CI enforcement that blocks merges based on PR body/commit message content.
- Require commit signing.
- Change merge strategy (still squash-merge as per FS-0011).

## 3. Tests Driving This Change
- None (policy + docs + filename migration)

## 4. Files to Be Modified
- docs/workflows/git-and-gh-conventions.md
- docs/workflows/README.md (if adding links)
- docs/change-plans/CP-0001.md (rename)
- docs/change-plans/CP-0002.md (rename)
- Any docs that link to CP-*.md (update references)

## 5. Implementation Steps (High-Level)
1. Update `docs/workflows/git-and-gh-conventions.md`:
   - Add a “Commit message/body (agents)” section with required fields (Why/What/Risk/Validation) and a note to avoid secrets.
   - Add a “PR body template (agents)” section with the required headings.
   - Add a “After pushing updates” section requiring a short PR comment summarizing addressed feedback + validation.
2. (Optional) Add an at-a-glance template block that agents can copy/paste into PR bodies.
3. Perform the change plan name migration:
   - Rename `docs/change-plans/CP-0001.md` → `docs/change-plans/PLAN-0004-<slug>.md` (choose appropriate numbering/slug)
   - Rename `docs/change-plans/CP-0002.md` → `docs/change-plans/PLAN-0005-<slug>.md` (choose appropriate numbering/slug)
   - Ensure numbering does not collide with existing PLAN files.
4. Search for references to `CP-0001`/`CP-0002` and update links.
5. Run markdownlint locally (or rely on CI once FS-0013 is implemented).

## 6. Constraints and Guardrails
- Spec constraints:
  - FS-0012 is policy-only; do not introduce enforcement hooks/CI gates for commentary.
- ADR constraints:
  - ADR-0011: agent PRs should be authored by agent identity; keep reviewer identity separate.
- Guardrails:
  - Do not include secrets/tokens in templates/examples.

## 7. Risks and Edge Cases
- Renames can break deep links; mitigate by updating internal references and keeping commit message clear.
- Repo already contains both CP-* and PLAN-*; migration must avoid filename collisions.

## 8. Validation
- Manual checks:
  - Confirm workflow doc includes explicit sections for: commit commentary, PR template, PR update comment.
  - Confirm `docs/change-plans/` no longer contains CP-*.md files.
  - Confirm any internal links to CP files are updated.

## 9. Explicit Non-Changes
- No changes to code behavior.
- No new CI enforcement for commentary.

## 10. Readiness Check
- [ ] FS-0012 is approved
- [ ] Scope is minimal and explicit
- [ ] No architectural changes implied

## Declaration
I affirm that:
- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
