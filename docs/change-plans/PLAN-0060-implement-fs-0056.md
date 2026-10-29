---

type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0056
related_adrs:
  - ADR-0012
  - ADR-0015
  - ADR-0018
  - ADR-0026
  - ADR-0027
  - ADR-0029
  - ADR-0041
  - ADR-0047
  - ADR-0049
consensus_required: false
touches:
  - scripts/eligibility-gate.sh
  - scripts/direct-merge-digest.sh
  - scripts/README.md
  - .github/workflows/lint-docs.yml
  - package.json
  - docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md
  - docs/specifications/FS-0056-narrow-direct-to-trunk-merge-exception.md
  - docs/change-plans/PLAN-0060-implement-fs-0056.md
  - test/FS-0056/eligibility-gate.bats
  - test/FS-0056/direct-merge-digest.bats
  - CHANGELOG.md
created: 2026-10-27
updated: 2026-10-29

---

<!--
`touches:` declares every path this plan will modify, as repo-relative paths or
globs. It is compared against the governing FS's `interfaces:` to route approval:

- Entirely within the FS's `interfaces:` → the plan is derivative of an
  already-approved decision and may self-approve.
- Anything outside them → the plan proposes scope no human sanctioned, and
  requires human approval.

Certain paths always require human approval regardless of the FS's `interfaces:`.
See ADR-0027 for the reserved set and the rationale.

Under-declaring here is a process violation, not a shortcut: the document hygiene
gate checks touched files against the FS `interfaces:` at PR time, so an
under-declared plan fails later and louder.
|-->

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0056
* Related ADR ID(s): ADR-0012, ADR-0015, ADR-0018, ADR-0026, ADR-0027, ADR-0029, ADR-0041, ADR-0047, ADR-0049
* Issue / PR Reference: #151

## 2. Scope of Change

**This change WILL:**

* Create `scripts/eligibility-gate.sh` implementing the `ADR-0041` Phase 1
  path-based eligibility predicate over the built-in category table defined in
  FS-0056 §Eligible Category Matching (Phase 1). The gate reports category
  eligibility only and never reads or honours an `Approved-By:` trailer.
* Create `scripts/direct-merge-digest.sh` emitting the per-sweep JSON Lines
  digest defined in FS-0056 §Interfaces, with `category_matched` and
  `rollback_ref`, failing closed when a claimed range does not match git or an
  entry lacks an `Agent-Attribution:` trailer.
* Add an `eligibility-gate` job to `.github/workflows/lint-docs.yml` that runs
  the gate and reports its status; making the check required on trunk, and
  requiring a human review for merges outside the eligible-category branch, is
  the separate human-reviewed ruleset change named in §9.
* Add `eligibility-gate` and `digest:direct-merges` npm script entries in
  `package.json`.
* Document both scripts in `scripts/README.md` — purpose, when each runs, what a
  failure means — and declare the responsible role, per `ADR-0015`'s Category 1
  introduction requirements.
* Provide bats tests under `test/FS-0056/` covering every Success Criterion in
  FS-0056, including the trailer-is-not-approval and digest cases.
* Add a consumer-framed `CHANGELOG.md` entry because the change touches
  exported surface (`scripts/`).

**This change will NOT:**

* Implement Phase 2 content-aware eligibility (`updated:` refreshes) unless
  `ADR-0041` Phase 2 is separately accepted.
* Add or modify a `config/gates.yml` in this repository, or read one for this
  repository's own check: the category table is compiled into the gate, per
  FS-0056 and `FS-0024`'s non-goals.
* Add a rule to `scripts/check-status.sh`. That script is a local
  git+filesystem checker with no PR/check-run primitives and cannot observe an
  `eligibility-gate` pass; the verdict is enforced by the ruleset requiring the
  status check, and audited through the digest.
* Change the merge prohibition in `ADR-0012` or any role contract.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0056/eligibility-gate.bats`
  * `test/FS-0056/direct-merge-digest.bats`

* Target test(s), each mapped to its FS-0056 Success Criterion:

  * `test_sc_1__eligible_category_passes` — SC 1
  * `test_sc_1__reports_matched_category` — SC 1
  * `test_sc_2__reserved_path_fails` — SC 2
  * `test_sc_2__mixed_diff_fails` — SC 2
  * `test_sc_3__trailer_is_not_approval` — SC 3
  * `test_sc_4__digest_entry_emitted` — SC 4
  * `test_sc_4__digest_fails_closed_on_missing_attribution` — SC 4
  * `test_sc_5__fail_closed_on_unresolved_base` — SC 5
  * `test_sc_5__fail_closed_on_parse_error` — SC 5

## 4. Files to Be Modified

Only list files that will be changed.

* `scripts/eligibility-gate.sh`
* `scripts/direct-merge-digest.sh`
* `scripts/README.md`
* `.github/workflows/lint-docs.yml`
* `package.json`
* `docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md`
  (update `updated:` only, and only if the ruleset-side changes require it)
* `docs/specifications/FS-0056-narrow-direct-to-trunk-merge-exception.md`
* `docs/change-plans/PLAN-0060-implement-fs-0056.md`
* `test/FS-0056/eligibility-gate.bats`
* `test/FS-0056/direct-merge-digest.bats`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

1. Implement `scripts/eligibility-gate.sh`:
   * Resolve the PR base as `origin/${GITHUB_BASE_REF:-trunk}` and fail closed
     with `fail-closed` on exit 1 if it does not resolve; never use a bare
     `trunk` ref, which does not exist in this CI's checkout.
   * Read the full PR diff with
     `git diff "origin/${GITHUB_BASE_REF:-trunk}...HEAD"`.
   * Match the diff against the built-in Phase 1 category table from FS-0056
     §Eligible Category Matching; apply the README table-row line-shape
     condition for `cat-readme-index`.
   * Check the `ADR-0027` reserved set (`scripts/`, `.github/workflows/`,
     `package.json`, `docs/decisions/`, `guidelines/ROLE_CONTRACT.md`) and fail
     closed on any match.
   * Apply the halt variable: exit 1 with `halted by operator: <id>` when
     `ELIGIBILITY_GATE_HALT` names `all` or the matched category.
   * Exit 0 printing `eligible` and the category id, or 1 naming the first
     ineligible path. Do not read commit trailers as approval.
2. Implement `scripts/direct-merge-digest.sh`:
   * Accept a sweep id and the PR numbers the sweep merged.
   * For each PR, re-verify the landed commit range, touched paths, and
     `Agent-Attribution:` trailer against git; derive `category_matched` with
     the same matcher the gate uses; compute `rollback_ref` as
     `git revert <sha>`.
   * Emit one JSON Lines entry per PR, fail closed on any mismatch, and print
     the count of direct merges per category for the Observability metric.
3. Add the gate as an `eligibility-gate` job in
   `.github/workflows/lint-docs.yml`, passing `ELIGIBILITY_GATE_HALT` from the
   repository Actions variable into the script's environment.
4. Add the `eligibility-gate` and `digest:direct-merges` npm script entries.
5. Add the `scripts/README.md` Category 1 entries for both scripts, each naming
   the responsible role: Role 0 (Head Architect) owns the gate's coverage and
   approves changes to it; Role 3 (Implementer) makes the fixes that keep it
   green.
6. Write the bats tests listed in §3.
7. Add a consumer-framed `CHANGELOG.md` entry.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0056 Success Criteria and Out of Scope.

* ADR constraints:

  * ADR-0012: agents do not merge; the gate only reports eligibility.
  * ADR-0015: Category 1 introduction requirements — `package.json`,
    `scripts/README.md`, approved FS, declared role.
  * ADR-0026: a commit trailer is not an approval authority; the human branch is
    a ruleset-required review.
  * ADR-0027: reserved paths always require human approval.
  * ADR-0041: the exact eligible categories and fail-closed posture.

* Architecture constraints:

  * The gate must be vendorable, but this repository's own category table is
    compiled into the script — `FS-0024` rules out a populated
    `config/gates.yml` here, and `scripts/check-status.sh`'s hardcoded
    `RESERVED_PATHS` is the precedent.
  * The gate script stays network-free and reads only git and environment
    values, so it can run inside the existing `lint-docs` workflow.

## 7. Risks and Edge Cases

* Risk: the gate script itself could be widened by an agent. Mitigation:
  `scripts/` is reserved, so changes require human approval.
* Risk: an agent writes an `Approved-By:` trailer to claim human approval.
  Mitigation: the gate ignores trailers; the ruleset requires a human review.
* Risk: a gate run in a clone without the base ref fetched. Mitigation: fail
  closed with an explicit diagnostic instead of diffing against a guessed base.
* Edge case: a PR whose diff mixes an eligible category with an ineligible path
  fails closed, even when most of the diff is eligible — the human-approval
  branch of `ADR-0041` is then the only route.

## 8. Validation

* Tests expected to pass:

  * `test/FS-0056/eligibility-gate.bats`
  * `test/FS-0056/direct-merge-digest.bats`

* Manual checks (if any):

  * Run the gate against a sample of recent PRs and verify the verdicts
    match `ADR-0041` intent.
  * Run the digest against one completed sweep and confirm a human can read the
    category and commit range without opening individual PRs.

## 9. Explicit Non-Changes

State what will NOT be modified.

* `guidelines/ROLE_CONTRACT.md`
* `scripts/check-status.sh`
* `docs/decisions/` content other than `updated:` front matter on ADR-0041.
* `config/gates.yml` (does not exist in this repository and must not be created).
* Branch protection rulesets outside the workflow change: the required status
  check and the human-review requirement are a separate, human-reviewed PR.

## 10. Readiness Check

* [x] Spec is draft (implementation blocked until approved)
* [x] Tests exist or are clearly defined (§3 names nine cases mapped to the five
  FS-0056 Success Criteria; the bats files land with implementation)
* [x] Scope is minimal and explicit
* [x] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding

agent-stance: mode=architecture-planning; role=Head Architect; model=ollama-cloud/kimi-k2.7-code; session=implementation; rationale=draft implementation plan for the ADR-0041 direct-to-trunk merge exception
agent-stance: mode=autonomous; role=implementer; model=deepseek-v4.1-flash; session=conventional-agents-maintenance; rationale=revision for the Minimax M3 review (PR #257): ruleset-carried approval branch, resolvable diff base, built-in category table, digest in scope, sunset cadence, halt/rollback
