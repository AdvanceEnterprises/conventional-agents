---
type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0048
approved_by: ""
related_adrs:
  - ADR-0015
  - ADR-0026
  - ADR-0027
  - ADR-0030
touches:
  - docs/specifications/FS-0048-governance-metadata-and-version-source-of-truth-reconciliation.md
  - docs/change-plans/PLAN-0054-implement-fs-0048-governance-metadata-and-version-reconciliation.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-05
updated: 2026-10-27
---

# PLAN-0054: Implement FS-0048 — Governance metadata and version reconciliation

> **Template note:** this first revision publishes the governance package only:
> FS-0048, this plan, the two index rows, and a draft CHANGELOG entry. It does
> not edit the ADR template, the ADR corpus, any script, `package.json`, the
> displayed version markers, or any pre-existing index row. The implementation
> touches ADR-0027 reserved paths (`docs/decisions/`, `scripts/`,
> `package.json`), so it requires recorded human approval for the exact
> implementation scope.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0048
* Related ADR ID(s): ADR-0015, ADR-0026, ADR-0027, ADR-0030
* Issue / PR Reference: #212

## 2. Scope of Change

**This documentation revision WILL:**

* Publish FS-0048 and this plan as draft documents.
* Add draft rows to the feature-specification and change-plan indexes.
* Add a CHANGELOG entry that describes the package without claiming any
  reconciliation is implemented.

**This documentation revision will NOT:**

* Edit `templates/core/adr-full-madr.md`, `workflows/document-lifecycle.md`,
  any ADR, any script, `package.json`, `README.md`, `AGENTS.md`,
  `INTEGRATION.md`, or any pre-existing index row.
* Mark the FS or PLAN approved, or treat this review as recorded approval for
  the reserved-path implementation.

**The later implementation revision WILL, only after FS-0048 and PLAN-0054 are
approved and the reserved-path approval is recorded:**

* Add `updated:` to `templates/core/adr-full-madr.md` and align the lifecycle
  document's wording so the requirement and the scaffold agree.
* Extend the freshness coverage to `docs/decisions/` with named-rule
  diagnostics and backfill `updated:` across the ADR corpus as a bounded,
  metadata-only edit.
* Correct `INTEGRATION.md`'s displayed version marker and add marker-agreement
  validation to the canonical validation surface, with `package.json`
  `version` as the single authority.
* Align the ADR status vocabulary across `docs/decisions/README.md`,
  `workflows/document-lifecycle.md`, and the ADR template; document the
  index-ordering rule in both index READMEs and normalize both index tables.
* Extend index validation to flag out-of-order rows; register any new or
  extended entry point in `package.json` and document it in
  `scripts/README.md`.
* Add fixture-driven Bats coverage under `test/FS-0048/` and re-run the full
  validation surface, resolving all findings before proposing completion.

The implementation `touches:` set must be updated to the exact approved
FS-0048 `interfaces:` surface before any implementation file is changed. Any
scope change first requires a revision to the FS and PLAN.

Before implementation, re-read the current default branch and open draft PRs
`#206`, `#208`, and `#213`. PR #213 adds FS-0045–FS-0047 and PLAN-0051–PLAN-0053
rows to the same two index READMEs and a CHANGELOG entry; PR #206 and PR #208
also edit `CHANGELOG.md` and shared guidance files. Reconcile index-row
ordering (ascending by number) and CHANGELOG entry placement before editing
shared files, and base the implementation on the then-current `trunk`. If a
predecessor remains open or changes scope, revise this plan before touching
shared paths.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0048/metadata-version-reconciliation.bats` — temporary-repository
    fixtures for: a fresh ADR scaffolded from the template passing the
    metadata policy; a missing-`updated:` ADR producing a named-rule
    diagnostic; a disagreeing version marker failing validation; vocabulary
    set equality across the three surfaces; an out-of-order index fixture
    being flagged; and no-mutation stability across re-runs.

* Documentation-package validation now:

  * `npm run check:status` — draft document/index consistency.
  * `npm run check:freshness` — governed-document dates.
  * `npm run lint:docs` — Markdown lint across the package.

* Implementation validation:

  * `bats test/FS-0048/metadata-version-reconciliation.bats`
  * `npm run validate`

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0048-governance-metadata-and-version-source-of-truth-reconciliation.md`
* `docs/change-plans/PLAN-0054-implement-fs-0048-governance-metadata-and-version-reconciliation.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

**Implementation revision, not this package:**

* `templates/core/adr-full-madr.md`
* `workflows/document-lifecycle.md`
* `docs/decisions/README.md`
* `docs/decisions/ADR-*.md` (front-matter `updated:` backfill only)
* `scripts/check-freshness.sh`
* `scripts/check-status.sh`
* `scripts/README.md`
* `package.json` (only if a new or extended entry point is required)
* `README.md`, `AGENTS.md`, `INTEGRATION.md`
* `docs/specifications/README.md`, `docs/change-plans/README.md`
* `test/FS-0048/**`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

1. Write the fixture suite first and verify it fails against the current
   surfaces.
2. Template and lifecycle: add `updated:` to the ADR template; align the ADR
   status vocabulary to the five-value closed set; document the
   index-ordering rule.
3. Extend freshness coverage to `docs/decisions/` with named-rule
   diagnostics; backfill `updated:` across the ADR corpus as a bounded
   metadata-only edit.
4. Reconcile the displayed version markers to the `package.json` authority and
   add marker-agreement validation to the canonical surface.
5. Normalize both index tables to ascending numeric order; extend index
   validation for ordering; register and document entry points.
6. Re-run the full validation surface; reconcile shared files against any
   predecessor PRs that landed first.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0048 Non-Goals: no history rewrite, no body edits, no merge-blocking
    age warnings, no lifecycle-state changes, no scope into the history-aware
    detection line.

* ADR constraints:

  * ADR-0015: any new or extended check respects the tool/location boundary.
  * ADR-0026: recorded human approval is a separate act.
  * ADR-0027: `docs/decisions/`, `scripts/`, and `package.json` are reserved.
  * ADR-0030: decisions and current-state documents stay distinct.

* Architecture constraints:

  * Offline and deterministic; no network or GitHub dependency in any check.
  * Bash 3.2 compatibility for every script change.
  * The backfill must be reproducible: the same corpus state must yield the
    same diff.

## 7. Risks and Edge Cases

* The ADR-corpus backfill touches many files and increases merge-conflict
  surface with open PRs that change ADRs (for example PR #208's ADR-0044);
  reconcile against the then-current trunk and re-measure counts at
  implementation time.
* Once `docs/decisions/` is covered by the freshness gate, the soft >90-day
  staleness rule will list older ADRs; that listing is informational and the
  implementation must not convert it into a blocker.
* A release version bump in flight changes the expected marker value; the
  implementation re-reads `package.json` at the checked-out head.
* An ADR with unparseable front matter must fail closed, not be silently
  skipped.

## 8. Validation

* Tests expected to pass:

  * `bats test/FS-0048/metadata-version-reconciliation.bats`
  * `npm run validate`

* Manual checks (if any):

  * Diff review confirming the ADR backfill changes front matter only.
  * Read-back that the three displayed markers equal the `package.json`
    authority at the pushed head.

## 9. Explicit Non-Changes

* No ADR acceptance, rejection, deprecation, or supersession changes.
* No FS/PLAN lifecycle-status changes.
* No workflow-file edits, no branch-protection or repository-setting changes.
* No removal or renaming of any exported surface.
* No change to the history-aware freshness tooling.

## 10. Readiness Check

* [ ] Spec is approved
* [x] Tests are clearly defined for the implementation revision
* [x] Scope is minimal and explicit
* [x] No implementation or corpus edit is included

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
