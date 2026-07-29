---

type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0022]
related_adrs: [ADR-0008, ADR-0015, ADR-0027, ADR-0030]
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0022/gate-coverage.bats
created: 2026-07-28
updated: 2026-07-28

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0022
* Related ADR ID(s): ADR-0008, ADR-0015, ADR-0027, ADR-0030
* Issue / PR Reference: PR #71

## 2. Scope of Change

**This change WILL:**

* Extend `check-status.sh` to validate the ADR index against ADR files —
  presence, title, and status, in both directions.
* Add the PLAN self-approval check: `touches:` containment against the
  governing FS's `interfaces:`, plus the reserved-path set.
* Add a CI-only job implementing ADR-0030 rule 3.
* Widen lint coverage to every directory containing governed markdown.
* Create `scripts/README.md` documenting every check.
* Add `npm test` and a CI job that executes the `bats` suites.

**This change will NOT:**

* Rewrite `check-status.sh`. Existing FS/PLAN checks are untouched.
* Change any rule being enforced. FS-0022 §Non-Goals.
* Lint `docs/orchestration/multi-model-pilot-001/`.
* Add enforcement for convention-only rules (ADR-0013, ADR-0019,
  ADR-0020, ADR-0026).
* Fix the drift the new checks find. See §7.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0022/gate-coverage.bats`

* Target test(s), one per FS-0022 success criterion:

  * `test_adr_index__title_mismatch_fails`
  * `test_adr_index__status_mismatch_fails`
  * `test_adr_index__missing_row_fails`
  * `test_adr_index__orphan_row_fails`
  * `test_plan_touches__outside_interfaces_fails`
  * `test_plan_touches__reserved_path_fails`
  * `test_plan_touches__absent_field_fails`
  * `test_lint__covered_directory_violation_fails`
  * `test_lint__orchestration_exempt_passes`
  * `test_npm_test__runs_all_suites`
  * `test_npm_test__missing_bats_fails_loudly`
  * `test_scripts_readme__documents_every_check`

Rule 3 (§3 of the spec) is CI-only and has no bats coverage; it is
verified by the two-PR manual check in §8.

## 4. Files to Be Modified

* `scripts/check-status.sh`
* `scripts/README.md` (new)
* `package.json`
* `.github/workflows/lint-docs.yml`
* `test/FS-0022/gate-coverage.bats` (new)

## 5. Implementation Steps (High-Level)

1. Write the bats suite first, against the current script. Every test
   fails; that is the starting condition.
2. Add ADR index validation to `check-status.sh`, reusing the existing
   `check_readme_sync` shape rather than a parallel implementation.
3. Add the PLAN `touches:` check: resolve each PLAN's governing FS via
   `related_specs`, compare `touches:` against that FS's `interfaces:`,
   then test the reserved-path set. Report the offending path and the
   rule it broke.
4. Add `npm test` invoking `bats` across `test/`, failing with an install
   hint when the binary is absent.
5. Widen the lint globs in `package.json` and `lint-docs.yml`. Confirm the
   orchestration exemption survives by running lint against a
   deliberately malformed file there.
6. Add the CI job for rule 3: for each ADR in the PR diff, parse its
   `## Links` for paths under the current-state directories, and require
   at least one to appear in the same diff.
7. Add a CI job running `npm test`.
8. Write `scripts/README.md` covering every check — existing and new —
   with purpose, when it runs, and what a failure means.
9. Update FS-0022 and this PLAN to `implemented` in the completing PR.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0022 Non-Goals and Out of Scope. In particular: no rule changes,
    no convention-only enforcement, no retroactive drift fixing.

* ADR constraints:

  * ADR-0015 — these are Category 1 governance gates. They live in
    `scripts/`, are registered in `package.json`, and are documented in
    `scripts/README.md`. That is not optional.
  * ADR-0027 — every path in `touches:` above is a reserved path. **This
    PLAN can never self-approve.** It requires human approval by
    construction, which is the correct outcome for a plan that modifies
    the check evaluating self-approval.
  * ADR-0030 — rule 3 applies to this change: `scripts/README.md` is the
    current-state document for what the gates do.
  * ADR-0008 — markdownlint stays the linter; this widens its scope.

* Architecture constraints:

  * `check-status.sh` must remain runnable against a working tree with no
    diff context. Rule 3 needs the change set, so it is CI-only. Do not
    add git-diff dependence to the local script.

## 7. Risks and Edge Cases

* **The corpus is expected to fail on first run.** FS-0022 states this.
  Fixing what the checks find is separate work — do not weaken a check to
  make the corpus pass.
* A per-directory `.markdownlint.yml` with `default: false` is
  indistinguishable from an accidental one. The lint job reports which
  directories are exempt so the set is visible in CI output.
* A PLAN governing several FSs: `touches:` must be contained in the union
  of their `interfaces:`.
* An ADR whose Links name several current-state documents: modifying any
  one satisfies rule 3. Requiring all would fail legitimate changes.
* `bats` absent locally is the common developer case. It must fail with an
  install hint, never skip silently — a suite that passes by not running
  is the state this PLAN exists to end.
* Widening lint may surface violations in `guidelines/`, `skills/`, and
  `templates/` that have never been linted. Expect a large first-run
  failure set.

## 8. Validation

* Tests expected to pass:

  * All of `test/FS-0022/gate-coverage.bats`.
  * All pre-existing suites, now actually executing:
    `test/FS-0001`, `FS-0016`, `FS-0017`, `FS-0018`, `FS-0019`.

* Manual checks:

  * Rule 3, positive: open a PR modifying an ADR whose Links name a
    `workflows/` path without touching it. The job must fail.
  * Rule 3, negative: add the referenced document to the same PR. The job
    must pass.
  * Introduce a deliberate style violation under
    `docs/orchestration/multi-model-pilot-001/`. Lint must not fail.
  * Run `npm run check:status` against trunk before fixing anything and
    record the failure set — that is the drift baseline.

## 9. Explicit Non-Changes

* The FS↔PLAN pairing and README-sync checks already in
  `check-status.sh`.
* The `.markdownlint.yml` configs in `docs/decisions/`,
  `docs/specifications/`, `docs/change-plans/`, `workflows/`,
  `guidelines/javascript/`, and `docs/orchestration/multi-model-pilot-001/`.
* The bats suites themselves. This plan runs them; it does not fix what
  they report.
* Any rule text in any ADR or FS.

## 10. Readiness Check

* [ ] FS-0022 is approved
* [x] Tests are clearly defined — §3, one per success criterion
* [x] Scope is minimal and explicit
* [x] No architectural changes implied
* [ ] **Human approval required.** Every path in `touches:` is reserved
      under ADR-0027; this PLAN cannot self-approve.
