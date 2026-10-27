---

type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0053
related_adrs:
  - ADR-0012
  - ADR-0018
  - ADR-0027
  - ADR-0029
  - ADR-0041
  - ADR-0047
  - ADR-0049
consensus_required: false
touches:
  - scripts/eligibility-gate.sh
  - scripts/check-status.sh
  - .github/workflows/lint-docs.yml
  - package.json
  - docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md
  - docs/specifications/FS-0053-narrow-direct-to-trunk-merge-exception.md
  - docs/change-plans/PLAN-0060-implement-fs-0053.md
  - test/FS-0053/eligibility-gate.bats
  - CHANGELOG.md
created: 2026-10-27
updated: 2026-10-27

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

* Feature Spec ID(s): FS-0053
* Related ADR ID(s): ADR-0012, ADR-0018, ADR-0027, ADR-0029, ADR-0041, ADR-0047, ADR-0049
* Issue / PR Reference: #151

## 2. Scope of Change

**This change WILL:**

* Create `scripts/eligibility-gate.sh` implementing the `ADR-0041` eligibility
  predicate for Phase 1 (path-based categories).
* Extend `scripts/check-status.sh` to validate that any PR claiming the direct
  merge exception has an `eligibility-gate` pass recorded.
* Add the gate as a required status check in `.github/workflows/lint-docs.yml`
  (or a new workflow) on trunk.
* Add an `eligibility-gate` npm script entry in `package.json`.
* Provide bats tests under `test/FS-0053/` covering eligible, ineligible, and
  human-approved cases.
* Add a consumer-framed `CHANGELOG.md` entry because the change touches
  exported surface (`scripts/`).

**This change will NOT:**

* Implement Phase 2 content-aware eligibility (`updated:` refreshes) unless
  `ADR-0041` Phase 2 is separately accepted.
* Implement the digest generator (that is a separate, future FS/PLAN; this
  plan emits the per-PR verdict the digest will aggregate).
* Change the merge prohibition in `ADR-0012` or any role contract.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0053/eligibility-gate.bats`

* Target test(s):

  * `test_sc_1__eligible_category_passes`
  * `test_sc_2__reserved_path_fails`
  * `test_sc_3__human_approved_passes`
  * `test_sc_4__fail_closed_on_parse_error`
  * `test_sc_5__mixed_diff_fails`

## 4. Files to Be Modified

Only list files that will be changed.

* `scripts/eligibility-gate.sh`
* `scripts/check-status.sh`
* `.github/workflows/lint-docs.yml`
* `package.json`
* `docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md`
  (update `updated:` only)
* `docs/specifications/FS-0053-narrow-direct-to-trunk-merge-exception.md`
* `docs/change-plans/PLAN-0060-implement-fs-0053.md`
* `test/FS-0053/eligibility-gate.bats`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

1. Implement `scripts/eligibility-gate.sh`:
   * Read the PR diff with `git diff trunk...HEAD`.
   * Parse `config/gates.yml` or a built-in eligible list for Phase 1
     categories.
   * Check for reserved paths (`scripts/`, `.github/workflows/`,
     `package.json`, `docs/decisions/`, `guidelines/ROLE_CONTRACT.md`).
   * Check for an `Approved-By:` trailer on the most recent commit from a
     non-agent author.
   * Exit 0 with `eligible` or 1 with a diagnostic.
2. Add a rule to `scripts/check-status.sh` verifying that any PR with
   `type=autonomous` and a direct-merge claim has an `eligibility-gate` pass.
3. Add the gate to CI in `.github/workflows/lint-docs.yml`.
4. Add the npm script entry.
5. Write bats tests.
6. Add a consumer-framed `CHANGELOG.md` entry.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0053 Success Criteria and Out of Scope.

* ADR constraints:

  * ADR-0012: agents do not merge; the gate only reports eligibility.
  * ADR-0027: reserved paths always require human approval.
  * ADR-0041: the exact eligible categories and fail-closed posture.

* Architecture constraints:

  * The gate must be vendorable; it reads repo-specific config from
    `config/gates.yml` per `FS-0024`.

## 7. Risks and Edge Cases

* Risk: the gate script itself could be widened by an agent. Mitigation:
  `scripts/` is reserved, so changes require human approval.
* Edge case: a human-approved PR whose diff also contains eligible-only
  changes must pass because human approval is the authority.

## 8. Validation

* Tests expected to pass:

  * `test/FS-0053/eligibility-gate.bats`

* Manual checks (if any):

  * Run the gate against a sample of recent PRs and verify the verdicts
    match `ADR-0041` intent.

## 9. Explicit Non-Changes

State what will NOT be modified.

* `guidelines/ROLE_CONTRACT.md`
* `docs/decisions/` content other than `updated:` front matter on ADR-0041.
* Branch protection rulesets outside the workflow change.

## 10. Readiness Check

* [x] Spec is draft (implementation blocked until approved)
* [ ] Tests exist or are clearly defined
* [x] Scope is minimal and explicit
* [x] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding

agent-stance: mode=architecture-planning; role=Head Architect; model=ollama-cloud/kimi-k2.7-code; session=implementation; rationale=draft implementation plan for the ADR-0041 direct-to-trunk merge exception
