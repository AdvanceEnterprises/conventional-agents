---
type: change-plan
role: implementer
language: bash
status: approved
related_specs: [FS-0049]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0012, ADR-0026, ADR-0027]
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - test/FS-0022/bash32-compat.bats
  - test/FS-0049/**
  - docs/specifications/FS-0049-bash32-status-check-compatibility.md
  - docs/change-plans/PLAN-0055-implement-fs-0049-bash32-status-check-compatibility.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-05
updated: 2026-10-05
---

# PLAN-0055: Implement FS-0049 — Bash 3.2 status-check compatibility

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0049
* Related ADR ID(s): ADR-0012 (human merge gate), ADR-0026 (recorded approval),
  ADR-0027 (reserved paths)
* Issue / PR Reference: [#214](https://github.com/Tais-Den/conventional-agents/issues/214),
  [#215](https://github.com/Tais-Den/conventional-agents/pull/215)

Human approval of FS-0049 and PLAN-0055 is recorded by Joey Clark in a separate
commit with `Approved-By:` and `Approved-Artifacts:` trailers, per ADR-0026. The
approved status is provisional while this governance PR is unmerged; it
authorizes implementation only on a branch descended from that approval commit.
The current PR #215 contains candidate implementation work that predates this
contract. After the governance PR merges, #215 must be rebased onto the approved
contract and rechecked against every criterion here before it can enter the
merge train.

## 2. Scope of Change

**The implementation WILL:**

* Preserve rule-8 reference extraction semantics while replacing the reported
  Bash 3.2-incompatible parser shape with a parse-safe equivalent.
* Move the issue-specific regression suite from `test/FS-0022/` to
  `test/FS-0049/bash32-compat.bats` and exercise a real Bash 3.2 binary for
  parsing and execution when `CA_BASH32` is configured.
* Fail the test when an explicitly configured `CA_BASH32` path is invalid; use
  an explicit skip only when no optional Bash 3.2 binary was supplied or found.
* Document the opt-in command and accurately distinguish a skip from successful
  Bash 3.2 evidence in `scripts/README.md`.
* Record successful parse-and-run evidence for GNU Bash 3.2.39 and GNU Bash
  3.2.57 before the implementation is considered complete.

**The implementation will NOT:**

* Install Bash 3.2 in CI or change GitHub Actions workflow configuration.
* Change the check's reference-matching rules, messages, or exit behavior.
* Change other scripts or generalize the compatibility claim beyond the
  existing FS-0013 contract.

The approval PR for this plan changes only the FS/PLAN documents, indexes, and
approval changelog entry. It does not alter the implementation files listed in
`touches:` or ship runtime behavior.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0049/bash32-compat.bats` — parse and execute the gate with the
    configured Bash 3.2 binary; report a visible skip only when none is
    configured or available.

* Target checks:

  * `bash -n scripts/check-status.sh` with GNU Bash 3.2.39.
  * `bash -n scripts/check-status.sh` with GNU Bash 3.2.57.
  * Full `scripts/check-status.sh` run under each Bash 3.2 version.
  * `npm test` discovers and runs the new suite; on hosts without Bash 3.2, the
    opt-in test is visibly skipped.

* Manual evidence:

  * Capture the interpreter version, parse result, full-run exit status, and
    final success line for both GNU Bash 3.2.39 and 3.2.57 in the implementation
    PR. Do not substitute the optional skip or a Bash 5 run for this evidence.

## 4. Files to Be Modified

* `scripts/check-status.sh` — preserve behavior while correcting the
  Bash 3.2-incompatible parser shape.
* `scripts/README.md` — document `CA_BASH32`, the opt-in test command, and the
  distinction between skipped coverage and verified compatibility.
* `test/FS-0022/bash32-compat.bats` — remove the test from its previous owner.
* `test/FS-0049/bash32-compat.bats` — add the FS-0049-owned regression suite.
* `docs/specifications/FS-0049-bash32-status-check-compatibility.md` — update
  lifecycle status only after the plan is completed.
* `docs/change-plans/PLAN-0055-implement-fs-0049-bash32-status-check-compatibility.md`
  — update lifecycle status only after the plan is completed.
* `docs/specifications/README.md` and `docs/change-plans/README.md` — maintain
  the index rows and statuses.
* `CHANGELOG.md` — add a consumer-framed entry describing verified Bash 3.2
  regression coverage.

## 5. Implementation Steps (High-Level)

1. Confirm the current rule-8 extractor's accepted reference set and diagnostics
   so the parser fix does not change gate behavior.
2. Refactor only the Bash construct that prevents the script from parsing under
   Bash 3.2; retain the existing extraction results and sort/deduplication.
3. Move and adapt the Bats regression suite under `test/FS-0049/`. Exercise
   `bash -n` and a full gate run with `CA_BASH32`; distinguish unset optional
   input from an invalid explicit path.
4. Update `scripts/README.md` with the opt-in invocation and its evidence limits.
5. Run the dedicated suite with GNU Bash 3.2.39 and 3.2.57, then run the normal
   test and documentation gates on the resulting worktree.
6. Keep FS/PLAN at `approved` until all success criteria and implementation
   steps are complete; then set both to `implemented` in the completing PR.
   This approval is already recorded separately. Any later edit to PLAN-0055
   requires a renewed approval record on the latest commit touching it.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0049 Success Criteria and Non-Goals are binding.
  * FS-0013's Bash 3.2+ support remains the compatibility contract.
  * FS-0022 remains the owner of Bats discovery and execution.

* ADR constraints:

  * ADR-0012: an agent must not merge the implementation PR.
  * ADR-0026: only a human can approve; any recorded approval must name the
    exact artifacts.
  * ADR-0027: `scripts/` is reserved and requires recorded human approval;
    PLAN-0055 cannot self-approve.

* Architecture constraints:

  * Keep the correction local to rule 8 and its regression coverage.
  * Do not represent the opt-in test as a default CI Bash 3.2 run.

## 7. Risks and Edge Cases

* A missing binary can hide a compatibility regression if the test's skip is
  mistaken for a pass; the plan therefore requires real-version evidence.
* A typo in `CA_BASH32` must fail rather than silently skip.
* A parser-only success is insufficient if the gate fails during execution.
* Moving the test must not remove it from the repository's normal Bats discovery.

## 8. Validation

* Tests expected to pass:

  * `CA_BASH32=/path/to/bash-3.2.39 bats test/FS-0049/bash32-compat.bats`
  * `CA_BASH32=/path/to/bash-3.2.57 bats test/FS-0049/bash32-compat.bats`
  * `npm test`
  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`
  * `npm run check:conformance`

* Manual checks:

  * Read back both Bash 3.2 version strings and successful parser/full-run
    results in the implementation PR before recommending merge.
  * Confirm a host without Bash 3.2 reports a visible skip, not a compatibility
    pass.

## 9. Explicit Non-Changes

* No changes to `.github/workflows/`, `package.json`, or the Bats runner.
* No Bash 3.2 build or installation step in CI.
* No change to status-check rules other than the syntax-safe extraction needed
  for the already documented Bash 3.2 support.
* No changes to any script other than `scripts/check-status.sh`.

## 10. Readiness Check

* [x] Spec is approved.
* [x] Tests and real-version acceptance evidence are defined.
* [x] Scope is minimal and explicit.
* [x] No architectural change is implied.

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation.
* No additional behavior will be introduced.
* Any deviation will require revising this plan before coding.
