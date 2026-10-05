---
type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0045
approved_by: ""
related_adrs:
  - ADR-0009
  - ADR-0015
  - ADR-0024
  - ADR-0027
  - ADR-0030
  - ADR-0033
touches:
  - docs/specifications/FS-0045-accepted-adr-authority-check.md
  - docs/change-plans/PLAN-0051-implement-fs-0045-accepted-adr-authority-check.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-04
updated: 2026-10-04
---

# PLAN-0051: Implement FS-0045 — Accepted-ADR authority check

> **Template note:** this first revision publishes the governance package only:
> FS-0045, this plan, the two index rows, and a draft CHANGELOG entry. It does
> not add the checker, tests, or npm entry. The later implementation
> touches ADR-0027 reserved paths (`scripts/` and `package.json`) and requires a
> separate recorded human approval under ADR-0026/ADR-0027. The existing CI
> workflow is verified read-only; no workflow edit is planned.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0045
* Related ADR ID(s): ADR-0009, ADR-0015, ADR-0024, ADR-0027, ADR-0030,
  ADR-0033
* Issue / PR Reference: #209

## 2. Scope of Change

**This documentation revision WILL:**

* Publish FS-0045 as a draft specification for an offline accepted-ADR
  authority check.
* Publish this draft plan with documentation-only `touches:`.
* Add draft rows for FS-0045 and PLAN-0051 to their README indexes.
* Add a CHANGELOG entry that describes the proposal without claiming the check
  or any ADR has been accepted or implemented.

**This documentation revision will NOT:**

* Modify any current-state document, ADR status, script, package entry, test, or
  workflow.
* Treat ADR-0032, ADR-0035, ADR-0036, or ADR-0041 through ADR-0043 as binding
  authority.
* Convert a human review of this draft into recorded approval for the later
  reserved-path implementation.

**The later implementation revision WILL, only after FS-0045 and PLAN-0051 are
approved and the reserved-path approval is recorded:**

* Add `scripts/check-adr-authority.sh` with the status-resolution,
  scan-surface, annotation, error-reporting, and no-mutation behavior in
  FS-0045.
* Correct or annotate every current-state reference whose only claimed
  authority is a non-accepted ADR, preserving the ADR's proposal status and
  accurate historical records.
* Register `npm run check:adr-authority` and include it in
  `scripts/run-validation.sh`; verify the existing CI workflow continues to
  invoke `npm run validate` without changing that workflow.
* Add fixture-driven Bats coverage in `test/FS-0045/` and document operation and
  remediation in `scripts/README.md`.
* Re-run the checker on the complete scan surface and resolve all findings
  before proposing completion.

The implementation `touches:` set must be updated to the exact approved
FS-0045 `interfaces:` surface before any implementation file is changed. Any
scope change first requires a revision to the FS and PLAN.

Before implementation, re-read the current default branch and open draft PRs
`#206` and `#208`. PR #206 changes `package.json`, `scripts/README.md`, and
`workflows/git-and-gh-conventions.md`; PR #208 also changes `INTEGRATION.md`,
`scripts/README.md`, the document indexes, and CHANGELOG. Do not implement from
the audit SHA or stack uncoordinated edits onto either draft. Base the
implementation on the then-current `trunk` after reconciling those changes; if
a predecessor remains open or its scope changes, revise the plan and coordinate
shared-file ownership before editing.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0045/adr-authority.bats` — temporary-repository fixtures for SC-1
    through SC-8, including all non-accepted statuses, annotations, unresolved
    and duplicate IDs, `docs/ARC42.md` scan coverage, excluded records, and
    no-mutation behavior.

* Documentation-package validation now:

  * `npm run check:status` — draft document/index consistency.
  * `npm run check:freshness` — governed-document dates.
  * `npm run lint:docs` — Markdown lint across the package.

* Implementation validation:

  * `npm run check:adr-authority`
  * `bats test/FS-0045/adr-authority.bats`
  * `npm run validate`

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0045-accepted-adr-authority-check.md`
* `docs/change-plans/PLAN-0051-implement-fs-0045-accepted-adr-authority-check.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

**Implementation revision, not this package:**

* `scripts/check-adr-authority.sh`
* `scripts/README.md`
* `scripts/run-validation.sh`
* `package.json`
* `test/FS-0045/adr-authority.bats`
* The specific current-state documents and generated runtime skill copies found
  by the checker; each correction must stay within FS-0045 `interfaces:`.
* Read-only validation input: `.github/workflows/lint-docs.yml`.

## 5. Implementation Steps (High-Level)

1. Build a deterministic ADR-ID resolver from local ADR front matter; reject
   missing, malformed, or duplicate records rather than guessing.
2. Scan exactly the Markdown current-state/exported surfaces named in FS-0045,
   including `docs/ARC42.md`; exclude decision, proposal, changelog, backlog,
   validation-baseline, orchestration, and test records.
3. Fail on every unresolved or unqualified non-accepted reference. Accept only
   the explicit per-ID non-normative context markers in FS-0045.
4. Write fixture tests first and confirm the expected failures before adding
   the checker; verify report-only behavior with before/after tree comparisons.
5. Remove normative claims that depend only on non-accepted ADRs, annotate
   genuine historical/proposal/example references, and sync any generated skill
   copies from their source files.
6. Register and document the check in the package and canonical validation
   runner; verify the existing CI workflow invokes that runner, then run all
   focused and full validation commands.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0045 defines the complete scan surface and annotation vocabulary.
  * The check does not determine whether prose is normative; unannotated
    references are treated as authoritative by default.
  * No proposed ADR is accepted or promoted by this work.

* ADR constraints:

  * ADR-0015: a pull-request-blocking checker is a Category 1 governance gate
    and needs an approved FS and PLAN.
  * ADR-0024: core checks remain local and offline.
  * ADR-0026: approval is a recorded human act scoped to the exact plan change.
  * ADR-0027: `scripts/` and `package.json` are reserved and require recorded
    human approval. The existing workflow is not modified.
  * ADR-0030: accepted ADRs are decision records; current-state documents carry
    present guidance.
  * ADR-0033: target resolution must follow the framework's repository-local
    execution contract.

* Architecture constraints:

  * Do not add GitHub, network, or project-board dependencies.
  * Never alter ADR status automatically.
  * Historical and proposal references remain allowed only with explicit,
    accurate annotations.

## 7. Risks and Edge Cases

* Treating every mention as normative may expose existing intentional
  historical references; annotate the exact reference rather than weakening
  the default.
* A malformed or duplicate ADR record must not be mistaken for acceptance.
* Generated runtime copies can reintroduce stale references unless synchronized
  and included in the scan.
* Markdown examples may contain ADR IDs; use the same explicit annotation rule
  rather than silently excluding code fences.

## 8. Validation

* Documentation package:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation revision:

  * `npm run check:adr-authority`
  * `bats test/FS-0045/adr-authority.bats`
  * `npm run validate`

* Manual checks:

  * Review every reported non-accepted reference and its proposed remediation.
  * Verify the exact default-branch source and generated skill copies after
    synchronization.
  * Confirm the tree is unchanged by a checker run that reports findings.

## 9. Explicit Non-Changes

* No ADR status transitions or changes to proposed ADR contents.
* No automatic edits to current-state guidance.
* No GitHub API, Notion, project-board, or network access from the checker.
* No blanket exclusion for code examples, historical-looking prose, or
  generated copies.

## 10. Readiness Check

* [ ] Spec is approved
* [ ] Tests exist or are clearly defined
* [x] Scope is minimal and explicit
* [x] No implementation or reserved-path change is included

## Declaration

I affirm that:

* This plan reflects the full intended scope of the documentation revision.
* The checker and reserved-path work are explicitly deferred until separate
  human approval is recorded for the implementation `touches:` set.
* Any deviation will require revising this plan before coding.
