---
type: change-plan
role: implementer
language: yaml
status: draft
related_specs: [FS-0033]
approved_by: ""
related_adrs: [ADR-0012, ADR-0027]
touches:
  - ".github/workflows/lint-docs.yml"
  - "skills/gh-pr-workflow/SKILL.md"
  - "test/FS-0033/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
created: 2026-09-10
updated: 2026-09-10
---

# PLAN-0039: Implement FS-0033 — Governance CI on Stacked and Non-Trunk PRs

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0033
* Related ADR ID(s): ADR-0012 (human merge gate), ADR-0027 (reserved-path
  self-approval rule)
* Issue / PR Reference: #139 (enhancement: run governance CI on stacked and
  non-trunk pull requests)

## 2. Scope of Change

**This change WILL:**

* Remove the `branches: [trunk]` filter from the `pull_request` trigger in
  `.github/workflows/lint-docs.yml`, with a comment documenting the fork-safety
  rationale (no secrets, no `pull_request_target`).
* Fix the `lint-cross-repo` job to fetch the PR's actual base ref
  (`origin/${{ github.base_ref }}`) before computing
  `COMMIT_RANGE="origin/${{ github.base_ref }}..HEAD"`, so stacked PRs get a
  valid range instead of an invalid one.
* Add a stacked-PR paragraph to `skills/gh-pr-workflow/SKILL.md` stating that
  stacked PRs run the same governance chain and that jobs must diff against
  `github.base_ref`, not hardcoded `trunk`.
* Add FS-0033 and PLAN-0039 index rows to `docs/specifications/README.md` and
  `docs/change-plans/README.md`.

**This change WILL NOT:**

* Alter the `push` trigger's `branches: [trunk]` filter.
* Add, remove, or reorder any governance job in `lint-docs.yml`.
* Introduce `pull_request_target`, secrets, or any fork-PR privilege change.

## 3. Implementation Steps

1. Edit `.github/workflows/lint-docs.yml`:
   * Remove `branches: [trunk]` from the `pull_request` trigger.
   * In `lint-cross-repo`, replace the unconditional
     `git fetch --no-tags origin trunk` with a fetch of the base ref:
     `git fetch --no-tags origin "${{ github.base_ref }}"` (with a fallback
     to `trunk` for push events, where `github.base_ref` is empty).
2. Edit `skills/gh-pr-workflow/SKILL.md` — add the stacked-PR paragraph.
3. Add `test/FS-0033/stacked-pr-ci.bats` — static assertions pinning the
   no-filter trigger, the base-ref fetch/range agreement, fork-PR safety
   (no `pull_request_target`, no secrets), and the skill documentation.
4. Add index rows to both READMEs.
5. Run `npm run check:status`, `npm run lint:docs`, and the FS-0033 bats
   suite locally; confirm green.
6. Push the branch; CI re-runs the full `lint-docs` chain on the PR itself
   (this PR is its own stacked-PR test case once a non-trunk base exists).

## 4. Verification

* `npm run check:status` passes (FS-0033/PLAN-0039 both `draft` — no pairing
  constraint fires for draft status).
* `npm run lint:docs` passes.
* CI on the PR shows all `lint-docs` jobs running and green.
* A stacked-PR exercise (base = non-trunk branch) shows the full job set
  running, with `lint-cross-repo` reporting a valid range.

## 5. Rollback

* Revert the trigger filter change and the fetch change; the workflow returns
  to trunk-only `pull_request` behavior. The skill paragraph and README rows
  are documentation-only and can be reverted independently.

## 6. Notes

* ADR-0027 reserves `.github/workflows/` for human approval; this PLAN exists
  to satisfy issue #139's acceptance criterion ("If the implementation changes
  reserved CI paths under ADR-0027, create the required FS/PLAN before
  implementation") and remains `draft` until human approval.
