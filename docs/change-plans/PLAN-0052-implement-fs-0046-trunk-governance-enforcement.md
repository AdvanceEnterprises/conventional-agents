---
type: change-plan
role: implementer
language: n/a
status: draft
related_specs:
  - FS-0046
approved_by: ""
related_adrs:
  - ADR-0012
  - ADR-0015
  - ADR-0024
  - ADR-0025
  - ADR-0026
  - ADR-0027
  - ADR-0030
touches:
  - docs/specifications/FS-0046-trunk-governance-enforcement.md
  - docs/change-plans/PLAN-0052-implement-fs-0046-trunk-governance-enforcement.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-04
updated: 2026-10-04
---

# PLAN-0052: Implement FS-0046 — Trunk governance enforcement

> **Template note:** this first revision publishes the governance package only:
> FS-0046, this plan, the two index rows, and a draft CHANGELOG entry. It does
> not edit `.github/workflows/`, repository settings, or a live ruleset. The
> implementation revision touches an ADR-0027 reserved path and changes an
> external repository control, so it requires recorded human approval for the
> exact implementation scope.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0046
* Related ADR ID(s): ADR-0012, ADR-0015, ADR-0024, ADR-0025, ADR-0026,
  ADR-0027, ADR-0030
* Issue / PR Reference: #210

## 2. Scope of Change

**This documentation revision WILL:**

* Publish FS-0046 and this plan as draft documents.
* Add draft rows to the feature-specification and change-plan indexes.
* Add a CHANGELOG entry that does not claim a workflow or live setting has
  changed.

**This documentation revision will NOT:**

* Change workflow triggers or repository rulesets.
* Mark the FS or PLAN approved, or treat this request as recorded approval for
  the live ruleset mutation.
* Change the existing all-branch `Base Ruleset` or any agent identity access.

**The later implementation and live-configuration revision WILL, only after
FS-0046 and PLAN-0052 are approved and the reserved-path and external-control
approval is recorded:**

* Remove `paths:` and `paths-ignore:` event filters from the `push` and
  `pull_request` triggers in `.github/workflows/lint-docs.yml`, retaining the
  `trunk` push branch filter, all pull-request bases, concurrency, timeouts,
  permissions, and fork-safe event type.
* Add fixture-driven trigger regression tests under `test/FS-0046/`.
* Correct `INTEGRATION.md`, `integrations/README.md`, and
  `integrations/github/README.md` so generic GitHub guidance, existing binding
  paths, and repository-specific live configuration are distinguished; remove
  the unsupported Code Owner-review claim.
* Update source and generated PR-workflow guidance to describe the human review
  gate without claiming unverified repository settings.
* Re-read the latest active workflows and create a separate ruleset scoped only
  to `refs/heads/trunk`; require a PR, one approving review, dismissal of stale
  approvals, and every active blocking PR status context; configure no bypass
  actors. Preserve the existing `Base Ruleset` unchanged.
* Open a dedicated verification PR as draft, complete the repository's required
  comment-only review rounds, address all findings, and mark it ready without an
  approving formal review. Verify all required checks are green and GitHub
  reports review required / blocked; capture evidence in the implementation PR
  and close the verification PR without merging it.

The complete PR check-run inventory (including external/platform contexts),
workflow triggers, and current API-visible repository rules must be re-read
immediately before the external mutation. If any context or rule differs from
FS-0046, revise this plan before proceeding.

Before any implementation, revise `touches:` from this documentation-only set
to enumerate the exact tracked-file changes and obtain recorded human approval
for that complete scope under ADR-0026/ADR-0027. The live ruleset mutation is a
separate external action requiring its own explicit recorded human approval;
approval of this draft documentation set authorizes neither change.

Before implementation, re-read the current default branch and open draft PRs
`#206` and `#208`. PR #206 changes `.github/workflows/lint-docs.yml` and
`integrations/github/README.md`; its current diff adds audit steps but does not
remove the existing event-level `paths:` filters. PR #208 adds the Pages
workflow and changes `INTEGRATION.md`. Reconcile those revisions before
changing workflow or binding guidance, and base implementation on the
then-current `trunk`. Do not stack uncoordinated edits onto either draft or
reuse the audit SHA; if a predecessor remains open or changes scope, revise
the plan before touching shared paths or the live ruleset.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0046/workflow-trigger.bats` — validates the `push` and
    `pull_request` trigger contract and guards against path filters.

* Documentation-package validation now:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation validation:

  * `bats test/FS-0046/workflow-trigger.bats`
  * `npm run validate`

* Live manual verification after recorded approval:

  * Read back the new ruleset and effective rules for `trunk`.
  * Verify exact required context names against workflows on `trunk`.
  * Verify the ready, green PR with no approving formal review is blocked for
    review and remains unmerged; capture URL, head SHA, review decision, and
    check conclusions.

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0046-trunk-governance-enforcement.md`
* `docs/change-plans/PLAN-0052-implement-fs-0046-trunk-governance-enforcement.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

**Implementation revision, not this package:**

* `.github/workflows/lint-docs.yml`
* `.github/workflows/pages.yml` (read-only input when present on `trunk`)
* `INTEGRATION.md`
* `integrations/README.md`
* `integrations/github/README.md`
* `skills/gh-pr-workflow/SKILL.md`
* `integrations/runtimes/claude-code/skills/gh-pr-workflow/SKILL.md`
* `test/FS-0046/workflow-trigger.bats`
* The live repository ruleset, separate from tracked files.

## 5. Implementation Steps (High-Level)

1. Write the workflow trigger tests first and verify they fail against the
   existing path-filtered workflow.
2. Remove only the event-level path filters; retain the documented spend,
   permission, and fork-safety controls.
3. Update the reusable GitHub binding and PR guidance to distinguish generic
   policy from instance-specific enforcement evidence; remove the unsupported
   Code Owner-review assertion and repair links to existing guidance.
4. Run the focused trigger suite, full repository validation, and review the
   workflow diff for unrelated changes.
5. Re-read the current trunk SHA, all active workflow triggers, the complete
   PR check-run inventory (including external/platform contexts), the existing
   Base Ruleset, and effective rules; classify each context as required or
   advisory and revise the plan if the approved assumptions no longer match.
6. After the separate human approval, create the trunk-only ruleset with the
   exact reviewed checks and no bypass actors; read it back from the ruleset
   endpoint and effective branch-rules endpoint.
7. Open a separate draft verification PR, complete comment-only review rounds
   and address all findings, then mark it ready without an approving formal
   review. Verify its green required checks and review-blocked state, record
   the evidence, and close it without merging.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0046 requires all pull requests and `trunk` pushes to run governance
    checks, independent of changed paths.
  * Ruleset scope is `refs/heads/trunk`; no existing global protection is
    weakened or replaced.
  * Only blocking PR contexts are required; skipped, push-only, and explicitly
    advisory checks are not.

* ADR constraints:

  * ADR-0012: agents never merge pull requests; preserve a human approval gate.
  * ADR-0024: local governance checks stay usable without GitHub.
  * ADR-0025: preserve the rebase-and-merge strategy.
  * ADR-0026: record human approval as a separate act.
  * ADR-0027: `.github/workflows/` is reserved and requires recorded approval.
  * ADR-0030: current-state policy and live instance settings are distinct.

* Architecture constraints:

  * Do not add a GitHub API dependency to offline tests or the validation
    runner.
  * Do not create an agent bypass actor or claim a rule is enforced before
    read-back.
  * Do not include an unmerged workflow's check context as required until it
    exists on `trunk` and is emitted for pull requests.

## 7. Risks and Edge Cases

* A skipped required context can leave a PR unable to merge; verify every
  selected job is emitted and blocking on pull requests.
* The current open PR check inventory contains `Analyze (python)`; verify its
  source and non-advisory/required status before deciding whether to require it.
* The current Pages workflow in an open draft PR has an unfiltered
  `pull_request` trigger. If that revision lands unchanged, require its build
  check; otherwise verify the landed trigger before deciding.
* A live ruleset may stack with the existing all-branch Base Ruleset; read both
  back and verify the effective rule set rather than assuming the new rule
  replaces the old one.
* GitHub may report cached mergeability; verify the PR head SHA and re-read
  merge state before drawing a conclusion.
* A successful API response is not evidence of effective branch enforcement.

## 8. Validation

* Documentation package:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation revision:

  * `bats test/FS-0046/workflow-trigger.bats`
  * `npm run validate`

* Manual checks after approval:

  * Read the new ruleset by its discovered repository-local ID.
  * Read effective rules for `trunk` and compare scope, approval count, exact
    contexts, and bypass actors.
  * Verify the green but unreviewed ready PR remains unmergeable and unmerged.

## 9. Explicit Non-Changes

* No broadening of the existing `Base Ruleset` beyond its current deletion and
  non-fast-forward rules.
* No `pull_request_target`, write token permission, agent merge, or bypass
  authority.
* No change to workflow concurrency or timeout budgets.
* No requirement for advisory or push-only jobs.
* No automated repository-settings mutation from CI.

## 10. Readiness Check

* [ ] Spec is approved
* [x] Tests are clearly defined for the implementation revision
* [ ] Scope is minimal and explicit
* [x] No implementation or live-ruleset mutation is included

## Declaration

I affirm that:

* This plan reflects the full intended scope of the documentation revision.
* The workflow and ruleset changes are not authorized by this draft package.
* Any deviation will require revising this plan before implementation.
