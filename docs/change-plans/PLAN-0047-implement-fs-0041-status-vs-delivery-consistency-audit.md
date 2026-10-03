---
type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0041]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0015, ADR-0024, ADR-0026, ADR-0027, ADR-0033]
touches:
  - scripts/check-delivery-status.sh
  - scripts/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0041/**
  - docs/specifications/FS-0041-status-vs-delivery-consistency-audit.md
  - docs/change-plans/PLAN-0047-implement-fs-0041-status-vs-delivery-consistency-audit.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-01
updated: 2026-10-03
---

# PLAN-0047: Implement FS-0041 — Status-vs-delivery consistency audit

> **Template note:** this plan declares the complete implementation surface up
> front. The executable revision touches `ADR-0027` reserved paths
> (`scripts/`, `package.json`, `.github/workflows/`) and therefore requires a
> recorded approval under ADR-0026/ADR-0027 before implementation begins.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0041
* Related ADR ID(s): ADR-0015 (governance CLI taxonomy), ADR-0024
  (detection over prevention), ADR-0026 (recorded approval), ADR-0027
  (reserved paths), ADR-0033 / FS-0024 (caller-relative execution)
* Issue / PR Reference: #188 (status-vs-delivery detection gap)

## 2. Scope of Change

**This revision WILL:**

* Publish FS-0041 as a draft specification for a conservative, offline,
  report-only status-vs-delivery audit.
* Publish this draft plan with documentation-only `touches:`.
* Add FS-0041 and PLAN-0047 to their README indexes with `draft` status.
* Add a CHANGELOG entry that names the package and does not claim the audit is
  implemented before its implementation commit lands.

**Before the recorded approval, this branch will NOT:**

* Modify the executable or workflow surfaces listed in `touches:`.
* Change any FS, PLAN, or ADR status.
* Infer that any historical delivered-but-draft instance is fixed by publishing
  this proposal.
* Add a GitHub or Notion dependency to the portable gate.

**After FS-0041 is approved and its reserved-path approval is recorded, the
implementation revision WILL. Its `touches:` set MUST equal
FS-0041's `interfaces:` set at merge time — including the reserved
`scripts/`, `.github/workflows/`, and `package.json` entries — or, where the
implementation must deviate, FS-0041's `interfaces:` is revised first, so the
approved boundary and the containment envelope cannot drift apart:**

* Add `scripts/check-delivery-status.sh` with the evidence model and stable
  exit behavior in FS-0041 SC-1 through SC-9.
* Register `npm run check:delivery` and invoke the same entry point from the
  documentation CI workflow after full-history preparation.
* Add `test/FS-0041/` fixture-driven Bats coverage in a disposable worktree,
  including multi-PR history, pre-existing files, documentation-only plans,
  `test_required: false`, shallow-history, and no-mutation cases.
* Document the rule, evidence boundaries, remediation wording, and consumer
  configuration in `scripts/README.md`.
* Run the audit against the current corpus and reconcile any real findings in
  separate status PRs; the audit itself never flips a status.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0041/status-vs-delivery.bats` — fixture-driven tests for SC-1
    through SC-10, using a real disposable Git history rather than mocked
    timestamps.

* Validation before implementation:

  * `npm run check:status` — both new rows resolve and the draft pair is
    coherent.
  * `npm run check:freshness` — the new governed documents carry `updated:`.
  * `npm run lint:docs` — the package is markdownlint-clean.

* Manual verification in the implementation revision:

  * Run the audit from an ordinary clone and a Git worktree.
  * Capture the current corpus result before any reconciliation PR.
  * Compare the tree before and after a finding to prove report-only behavior.

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0041-status-vs-delivery-consistency-audit.md`
* `docs/change-plans/PLAN-0047-implement-fs-0041-status-vs-delivery-consistency-audit.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

**Implementation revision, not this package:**

* `scripts/check-delivery-status.sh`
* `scripts/README.md`
* `package.json`
* `.github/workflows/lint-docs.yml`
* `test/FS-0041/status-vs-delivery.bats`

## 5. Implementation Steps (High-Level)

1. Resolve FS/primary-PLAN pairs using the existing repository-local front-matter
   helpers and skip terminal statuses.
2. Expand each PLAN's `touches:` against the current tree, partitioning
   documentation-only paths from executable, configuration, workflow,
   integration, and test paths.
3. For each candidate, inspect full Git history since `created:` and require
   complete implementation-surface coverage plus the applicable test and
   CHANGELOG evidence.
4. Emit stable findings with governing IDs, statuses, paths, commit dates, and
   a status-reconciliation remediation; never write to the repository.
5. Add fixture-driven coverage and the package/CI entry points, then run the
   audit against the current corpus and classify findings before any status
   transition is proposed.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0041's conservative evidence model and false-positive boundary.
  * FS-0041's report-only, offline, and no-status-mutation non-goals.

* ADR constraints:

  * ADR-0024: detection over prevention; no automatic lifecycle transition.
  * ADR-0026: recorded approval is a human act and is scoped to the exact
    implementation `touches:` set.
  * ADR-0027: `scripts/`, `package.json`, and `.github/workflows/` are
    reserved paths; this plan's later revision touches them and requires
    human approval evidence. (`test/FS-0041/**` is not reserved — it is
    included in the revision's `touches:` as scope, not as an approval
    trigger.)
  * ADR-0033 / FS-0024: caller-relative target resolution and worktree support.

* Architecture constraints:

  * The core audit must not call GitHub, Notion, or a project board.
  * It must not reinterpret branch names, issue numbers, or commit prose as
    delivery proof.
  * It must distinguish "not enough evidence" from "delivered candidate".

## 7. Risks and Edge Cases

* Existing files can predate the PLAN; history after `created:` is mandatory.
* A multi-PR implementation can leave one declared path untouched; the audit
  must remain quiet rather than over-claim completion.
* Shallow CI history can produce a false clean result unless the script fails
  explicitly; CI must prepare full history before invocation.
* A test suite can exist without proving its criteria; this audit detects
  delivery evidence, not semantic test quality.
* Renamed or deleted paths need explicit implementation-revision tests before
  they are considered supported.

## 8. Validation

* Documentation package:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation revision:

  * `npm run check:delivery`
  * `bats test/FS-0041/status-vs-delivery.bats`
  * `npm run validate`

* Manual checks:

  * Read the full-history diagnostic on a shallow fixture.
  * Verify `git diff --exit-code` before and after a finding.
  * Run the audit from both a normal clone and a worktree.

## 9. Explicit Non-Changes

* No automatic FS/PLAN status edits.
* No GitHub API, issue, board, milestone, or Notion reads from the portable
  audit.
* No change to existing FS/PLAN pairing, index, freshness, conformance, or
  referenced-path semantics.
* No claim that #188's five historical instances are reconciled merely because
  this package exists.

## 10. Readiness Check

* [x] Spec is approved
* [ ] Tests exist or are clearly defined
* [x] Scope is minimal and explicit
* [x] Full implementation surface is declared before approval

## Declaration

I affirm that:

* This plan reflects the full intended scope of the documentation revision.
* The later implementation surface is listed explicitly rather than smuggled
  into a documentation-only approval.
* Any deviation will require revising this plan before coding.
