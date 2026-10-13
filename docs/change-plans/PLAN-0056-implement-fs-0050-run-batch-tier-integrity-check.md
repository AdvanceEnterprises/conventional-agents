---
type: change-plan
role: implementer
language: shell
status: draft
related_specs: [FS-0050]
related_adrs: [ADR-0045, ADR-0026]
touches:
  - "scripts/check-run-batch.sh"
  - "test/FS-0050/run-batch-tier-integrity.bats"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "docs/specifications/FS-0050-run-batch-tier-integrity-check.md"
  - "docs/change-plans/PLAN-0056-implement-fs-0050-run-batch-tier-integrity-check.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
created: 2026-10-13
updated: 2026-10-13
---

# Change Plan: Implement FS-0050 run-batch tier-integrity check

> **Note:** this plan is `draft` and is a *proposal*. The implementation that
> follows it is a separate, narrowly-approved change: `scripts/`,
> `.github/workflows/`, and `package.json` are reserved paths under ADR-0027 and
> require recorded human approval, never a run-level batch acceptance.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0050
* Related ADR ID(s): ADR-0045, ADR-0026
* Issue / PR Reference: #223

## 2. Scope of Change

**This change WILL:**

* Add `scripts/check-run-batch.sh`, a git-only detection check that validates a
  batch-acceptance commit (one carrying an `Approved-Artifacts:` trailer).
* Verify that such a commit's diff touches only proposal-class locations
  (`docs/specifications/`, `docs/change-plans/`, `docs/decisions/`, their index
  READMEs, and `CHANGELOG.md`).
* Verify every `Approved-Artifacts:` ID resolves to an existing proposal-class
  document in an accepted/approved state.
* Add `test/FS-0050/run-batch-tier-integrity.bats` covering the Success Criteria.
* Wire the check into CI (`.github/workflows/lint-docs.yml`) and an npm script
  (`package.json`).

**This change will NOT:**

* Implement branch protection, merge gating, or prevention.
* Validate the run manifest's PR-body structure.
* Enforce the 48-hour bound or work-item scope linkage.
* Modify ADR-0045, ADR-0026, or the ADR-0027 reserved-path set.

## 3. Tests Driving This Change

* Test file(s):
  * `test/FS-0050/run-batch-tier-integrity.bats`

* Target test(s):
  * `sc1_proposal_only_batch_passes`
  * `sc2_reserved_path_batch_fails`
  * `sc3_missing_artifact_fails`
  * `sc4_unaccepted_artifact_fails`
  * `sc5_no_batch_trailer_passes`

## 4. Files to Be Modified

* `scripts/check-run-batch.sh` — new.
* `test/FS-0050/run-batch-tier-integrity.bats` — new.
* `package.json` — add an npm script running the check.
* `.github/workflows/lint-docs.yml` — add a step running the check over the PR commit range.
* `docs/specifications/README.md`, `docs/change-plans/README.md` — index rows.
* `CHANGELOG.md` — entry.

## 5. Implementation Steps (High-Level)

1. Author `scripts/check-run-batch.sh`: parse the target commit's
   `Approved-Artifacts:` trailer; if absent, exit 0. Otherwise classify each
   changed path as proposal-class vs. forbidden; resolve each listed ID against
   `docs/{specifications,change-plans,decisions}/` and its front-matter status.
2. Author the Bats suite with fixtures for each Success Criterion.
3. Wire an npm script and a `lint-docs.yml` step; run on the PR commit range.
4. Update indexes and CHANGELOG.
5. Record the required human approval for the reserved-path surface before any
   merge (separate from this draft package).

## 6. Constraints and Guardrails

* Spec constraints: FS-0050 Non-Goals and Out of Scope.
* ADR constraints:
  * ADR-0045 — batch acceptance is proposal-acceptance only.
  * ADR-0026 — `Approved-By:` / `Approved-Artifacts:` trailer shape; author ≠ approver.
* Architecture constraints: detection over prevention; platform-neutral, git-only,
  no GitHub API dependency.

## 7. Risks and Edge Cases

* Path classification must be exact — a wrong allow-list entry could let a
  reserved path slip through. Mitigate with fixtures covering each reserved path.
* The check reads only the checked-out tree; a stale checkout could misclassify.
  Mitigate by resolving against the tree at the commit being validated.

## 8. Validation

* Tests expected to pass: `bats test/FS-0050/run-batch-tier-integrity.bats`.
* Manual checks: `bash -n scripts/check-run-batch.sh`; run the check against the
  ADR-0045 acceptance commit and against a synthetic overreaching commit.

## 9. Explicit Non-Changes

* `scripts/check-status.sh` — untouched; this check is a sibling, not a rewrite.
* The ADR-0027 reserved-path set.
* Any existing reserved-path approval gate behavior.

## 10. Readiness Check

* [x] Spec is drafted (FS-0050, this package)
* [x] Tests are clearly defined
* [x] Scope is minimal and explicit
* [x] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
