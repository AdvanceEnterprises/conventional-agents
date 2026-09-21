---
type: change-plan
role: implementer
language: bash
status: implemented
related_specs: [FS-0032]
approved_by: "Joey Clark <taisden@tais-den.dev>"
related_adrs: [ADR-0015, ADR-0027, ADR-0030, ADR-0033]
touches:
  - scripts/run-validation.sh
  - scripts/validation-common.sh
  - scripts/run-bats.sh
  - scripts/cross-repo-lint.sh
  - scripts/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0032/validation-reproducibility.bats
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
  - docs/validation-baseline.md
  - docs/validation-baseline.log
created: 2026-09-21
updated: 2026-09-21
---

# PLAN-0038: Implement FS-0032 — Validation reproducibility contract

## 1. Feature / Issue Reference

* Feature Spec ID: FS-0032
* Related ADRs: ADR-0015, ADR-0027, ADR-0030, ADR-0033
* Issue Reference: [conventional-agents#132](https://github.com/Tais-Den/conventional-agents/issues/132)

## 2. Scope of Change

**This change WILL:**

* Add a canonical `npm run validate` runner for the five-command validation
  surface, with ordered progress, per-command timing, a global budget, and
  fail-closed timeout handling.
* Add shared Bash timeout and repository-target helpers and extend
  `run-bats.sh` with deterministic discovery, per-suite bounds, progress, and
  timing output.
* Remove implicit remote fetches from `cross-repo-lint.sh` and make unavailable
  commit ranges fail closed.
* Isolate the canonical run's temporary directory, HOME, Git configuration,
  npm cache, and network-capable command names; use explicit target and commit
  range environment variables.
* Register the runner in `package.json`, switch markdownlint scripts to the
  installed local binary, and wire CI to invoke the same runner after preparing
  full history and dependencies.
* Add Bats coverage for runner ordering, timeout validation, network guardrails,
  cross-repo fail-closed behavior, and documentation/registration.
* Document the contract and commit a clean baseline log and timing summary.
* Update the FS and PLAN indexes and the Unreleased changelog entry.

**This change will NOT:**

* Modify the rules enforced by the existing governance checks.
* Include network-backed GitHub binding audits in the five-command runner.
* Replace the existing granular CI jobs or make their setup network-free.
* Implement or alter the benchmark harness in FS-0031.
* Claim identical elapsed times across machines.

## 3. Tests Driving This Change

* Test file:

  * `test/FS-0032/validation-reproducibility.bats`

* Target tests:

  * `test_validate__runs_the_five_commands_in_order`
  * `test_validate__rejects_invalid_timeout_before_running`
  * `test_validate__uses_an_isolated_network_guard`
  * `test_run_bats__reports_suite_progress_and_timeout`
  * `test_cross_repo_lint__does_not_fetch_and_fails_on_missing_range`
  * `test_ci__invokes_the_canonical_runner_with_full_history`
  * `test_scripts_readme__documents_contract_and_defaults`
  * `test_baseline__records_revision_log_and_timings`

## 4. Files to Be Modified

* `scripts/run-validation.sh`
* `scripts/validation-common.sh`
* `scripts/run-bats.sh`
* `scripts/cross-repo-lint.sh`
* `scripts/README.md`
* `package.json`
* `.github/workflows/lint-docs.yml`
* `test/FS-0032/validation-reproducibility.bats`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`
* `docs/validation-baseline.md`
* `docs/validation-baseline.log`

## 5. Implementation Steps (High-Level)

1. Add the approved FS-0032 and this approved PLAN, update their index rows,
   and commit the recorded human approval before implementation begins.
2. Implement shared timeout, duration, target-resolution, and isolated-command
   helpers with Bash 3.2-compatible syntax.
3. Extend `run-bats.sh` to use the shared timeout, deterministic suite list,
   per-suite progress, and fail-closed timeout/no-suite behavior.
4. Implement `run-validation.sh` with the fixed five-command order, command
   budgets, isolated environment, log capture, summary, and cleanup.
5. Make cross-repo linting explicitly network-free and fail closed on unavailable
   commit ranges; register the runner and use local markdownlint binaries.
6. Update CI to install dependencies, prepare full history/base refs, and call
   `npm run validate` with the same gate entry point and pull-request range.
7. Write mutation-style Bats coverage for the contract and update the gate
   documentation and changelog.
8. Run the full validation twice serially from fresh disposable checkouts and
   once concurrently from separate worktrees; capture a clean baseline log and
   timing summary.
9. Transition FS-0032 and PLAN-0038 to `implemented` in the completing change
   after every acceptance criterion is verified.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0032 Success Criteria, Non-Goals, and Interfaces are authoritative.
  * FS-0022 remains the governing implemented spec for the existing gate corpus;
    this plan adds the reproducibility contract without changing its rules.

* ADR constraints:

  * ADR-0015: the runner is a Category 1 gate, so it must be registered,
    documented, and traceable to an approved spec.
  * ADR-0027: `scripts/`, `package.json`, and `.github/workflows/` are reserved
    paths; the recorded human approval covers this plan's reserved touches.
  * ADR-0030: `scripts/README.md` is the current-state document for the gate
    behavior and must be updated with the implementation.
  * ADR-0033: target resolution and consumer/own-repository behavior must remain
    explicit; no framework-internal path assumptions may leak into the runner.

* Architecture constraints:

  * Keep the framework Bash 3.2-compatible; do not require associative arrays,
    `wait -n`, or a nonstandard timeout binary.
  * The runner must not mutate the target checkout or perform remote operations.
  * Fixture state belongs under temporary directories; no acceptance test may
    mutate tracked files in the live checkout.
  * CI setup may provision dependencies and refs, but the validation command
    itself must be the same local entry point.

## 7. Risks and Edge Cases

* A hung suite may leave descendants behind if process-group termination is not
  used; use `setsid` when available and a documented fallback.
* A shallow or missing commit range must fail rather than silently skipping the
  attribution check.
* Local markdownlint must be required after dependency installation so `npx`
  cannot download an unpinned package during validation.
* Bats suites intentionally exercise missing-tool and fake-GitHub paths; the
  runner's guard commands must be overridable by test-local fixtures without
  exposing the real environment.
* Baseline timings are evidence for the documented budget, not a promise of
  hardware-independent wall-clock equality.

## 8. Validation

* Tests expected to pass:

  * `npm test`
  * `npm run lint:docs`
  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:cross-repo`
  * `npm run validate`

* Manual checks:

  * Two serial `npm run validate` executions from fresh disposable checkouts.
  * One concurrent execution from two separate fresh worktrees.
  * Confirm target checkout status and Git worktree registry are unchanged.
  * Confirm the validation log contains no real `gh` invocation or remote fetch.
  * Confirm CI workflow invokes `npm run validate` with `fetch-depth: 0`.

## 9. Explicit Non-Changes

* Existing governance-rule semantics and document schemas.
* GitHub binding audit behavior and its permissions.
* Benchmark task-card schema, runner, and scoring behavior.
* Public framework version and release metadata.
* Merge behavior; the completing work remains in a draft PR for human merge.

## 10. Readiness Check

* [x] Spec is approved by recorded human direction.
* [x] Tests are defined before implementation.
* [x] Scope is minimal and explicit.
* [x] No architectural rule changes are implied.

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation.
* No additional behavior will be introduced.
* Any deviation will require revising this plan before coding.
