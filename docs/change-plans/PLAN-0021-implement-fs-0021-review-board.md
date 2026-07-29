---

type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0021]
approved_by: "Joey Clark <taisden@tais-den.dev>"
related_adrs: [ADR-0022, ADR-0023, ADR-0031]
touches:
  - "config/review-board.yml"

  - "test/FS-0021/review-board.bats"

  - "templates/collaboration/review-board-findings.md"

  - "INTEGRATION.md"

  - "CHANGELOG.md"
created: 2026-07-28
updated: 2026-07-28

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0021
* Related ADR ID(s): ADR-0022, ADR-0023, ADR-0031
* Issue / PR Reference: PR #71

## 2. Scope of Change

**This change WILL:**

* Add `test/FS-0021/review-board.bats` covering the composition rules,
  contradiction preservation, disposition completeness, and gate
  independence.
* Ship `config/review-board.yml` as a consumer-copy template, disabled by
  default per ADR-0023 Constraint 2.
* Add a "Review boards (optional)" section to `INTEGRATION.md`.

**This change will NOT:**

* Implement orchestration. Consumers invoke seats themselves; the
  framework describes required behaviour.
* Modify `templates/collaboration/review-board-findings.md` beyond what
  the config template requires for consistency. It already exists and
  matches the spec.
* Add a severity taxonomy beyond the four values in FS-0021.
* Add anything to `workflows/session-modes.md` or `ADR-0022`. The
  `review-board` meta-mode already landed with FS-0021.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0021/review-board.bats`

* Target test(s):

  * `test_default__ships_disabled`
  * `test_composition__requires_two_distinct_roles`
  * `test_composition__requires_two_distinct_models`
  * `test_composition__identical_models_rejected`
  * `test_composition__identical_roles_rejected`
  * `test_findings__contradictions_both_recorded`
  * `test_findings__contradicts_is_a_list`
  * `test_findings__duplicate_records_all_raising_seats`
  * `test_findings__rejected_requires_reason`
  * `test_findings__deferred_requires_reason`
  * `test_findings__every_finding_dispositioned`
  * `test_coverage__every_seat_per_dimension`
  * `test_gate__evaluator_not_in_seats`
  * `test_gate__absent_when_no_independent_evaluator`
  * `test_advisory__blocking_severity_performs_no_transition`

Composition, gate-independence, and disposition tests are schema
assertions against a fixture artifact and the config template. The
merging-behaviour tests assert the spec and template text, since the merge
itself is consumer-implemented — FS-0021's own test-harness note applies.

## 4. Files to Be Modified

* `test/FS-0021/review-board.bats` (new)
* `config/review-board.yml` (new)
* `INTEGRATION.md`

## 5. Implementation Steps (High-Level)

1. Write the bats suite first.
2. Author `config/review-board.yml` mirroring `config/consensus.yml`'s
   shape: `enabled: false`, per-placement opt-in, empty seat list,
   `min_models: 2`, and a `min_roles: 2` field with no equivalent in the
   consensus config — role diversity is what distinguishes a board.
3. Add the `INTEGRATION.md` section: what a board is, how it differs from
   consensus, that it ships disabled, and that enabling it requires at
   least two models and two role stances.
4. Set FS-0021 and this PLAN to `implemented` in the completing PR.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0021 Non-Goals and Out of Scope. No orchestration, no severity
    taxonomy extension, no approval or transition authority.

* ADR constraints:

  * ADR-0023 Constraint 1 — distinct models. The config template must not
    permit `min_models` below 2, and the suite must assert a same-model
    configuration is rejected.
  * ADR-0023 Constraint 2 — ships disabled. `enabled: false` in the
    template, asserted by test.
  * ADR-0023 Constraint 3 — the gate evaluator fills no seat. **Do not add
    an override flag.** The ADR rejects `--allow-gate-overlap` explicitly;
    reintroducing it in config form is the same defect.
  * ADR-0031 — three artifacts, and the gate is optional. A board with no
    independent evaluator is synthesis-only and records that.
  * ADR-0022 — `review-board` and `consensus` are mutually exclusive on
    one round.

* Architecture constraints:

  * `config/review-board.yml` is a consumer-copy template. The framework
    does not read it; nothing in this repository enables a board.

## 7. Risks and Edge Cases

* **`min_roles: 2` has no consensus analogue.** An implementer copying
  `config/consensus.yml` will omit it, and a board with one role stance
  is a consensus round wearing the wrong name. The suite must assert it.
* Contradiction chains: `contradicts` is a list. A schema treating it as a
  scalar passes the two-seat case and fails silently at three.
* A seat that reviewed a dimension and found nothing is `addressed` with
  an empty finding set. A schema conflating that with `silent` destroys
  the distinction section 5 of the template exists to preserve.
* The advisory boundary is unenforceable in the same way ADR-0019's Type
  rule is. The test asserts the documents say so; nothing stops a
  consumer wiring `blocking` to a merge block.
* `config/review-board.yml` sits outside FS-0021's declared `interfaces:`.
  See §10.

## 8. Validation

* Tests expected to pass:

  * All of `test/FS-0021/review-board.bats`.
  * `npm run check:status`, `npm run lint:docs`.

* Manual checks:

  * Diff `config/review-board.yml` against `config/consensus.yml` and
    confirm every divergence is intentional and explained.
  * Confirm no override flag for gate independence exists anywhere in the
    config schema.

## 9. Explicit Non-Changes

* `templates/collaboration/*.md` — all four already exist and match the
  spec.
* `docs/decisions/ADR-0022`, `workflows/session-modes.md` — the
  `review-board` meta-mode is already recorded in both.
* `config/consensus.yml` — FS-0019's template is untouched.
* FS-0019 and its suite.

## 10. Readiness Check

* [x] FS-0021 is approved
* [x] Tests are clearly defined — §3
* [x] Scope is minimal and explicit
* [x] No architectural changes implied
* [x] **Human approval given.** `touches:` includes
      `config/review-board.yml` and `INTEGRATION.md`, neither of which
      appears in FS-0021's `interfaces:`. Under ADR-0027 containment
      fails, so this PLAN cannot self-approve. Either a human approves,
      or FS-0021's `interfaces:` is widened before approval.
