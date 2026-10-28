---

type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0055
  - FS-0022
related_adrs:
  - ADR-0026
  - ADR-0027
  - ADR-0050
consensus_required: false
touches:
  - scripts/check-status.sh
  - test/FS-0055/reapproval-diagnostic.bats
  - docs/specifications/FS-0055-re-approval-diagnostics-for-amended-plans.md
  - docs/change-plans/PLAN-0062-implement-fs-0055.md
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
-->
## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0055, FS-0022
* Related ADR ID(s): ADR-0026, ADR-0027, ADR-0050
* Issue / PR Reference: #155

## 2. Scope of Change

**This change WILL:**

* Add a new rule to `scripts/check-status.sh` that detects when an approved
  PLAN was amended after its `Approved-By:` record.
* Emit a diagnostic naming the voiding commit SHA and the two recovery paths
  from `ADR-0050`.
* Emit a separate diagnostic for self-approved plans under `ADR-0027` that
  are amended outside containment, stating that human approval is required.
* Add bats tests under `test/FS-0055/` covering human-approved and
  self-approved scenarios.
* Add a consumer-framed `CHANGELOG.md` entry because the change touches the
  exported `scripts/` path.

**This change will NOT:**

* Modify `ADR-0026`, `ADR-0027`, or the lifecycle document directly.
* Change the containment/reserved-path checks in rule 6.
* Add auto-recovery logic.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0055/reapproval-diagnostic.bats`

* Target test(s):

  * `test_sc_1__voided_human_approved_plan`
  * `test_sc_2__valid_approved_plan`
  * `test_sc_3__voided_self_approved_plan_outside_interfaces`
  * `test_sc_4__voided_in_progress_transition`
  * `test_sc_5__multiple_voided_plans_same_commit`

## 4. Files to Be Modified

Only list files that will be changed.

* `scripts/check-status.sh`
* `test/FS-0055/reapproval-diagnostic.bats`
* `docs/specifications/FS-0055-re-approval-diagnostics-for-amended-plans.md`
* `docs/change-plans/PLAN-0062-implement-fs-0055.md`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

1. Add a helper that, for each approved PLAN, finds the most recent commit
   touching the plan and the most recent commit before it carrying an
   `Approved-By:` trailer.
2. If the approving commit is not the most recent touching commit, emit the
   diagnostic naming the voiding commit and the recovery paths.
3. For self-approved plans, additionally check whether the current `touches:`
   still satisfies containment; if not, state that human approval is required.
4. Write bats tests that construct git histories with the voiding cases.
5. Add a consumer-framed `CHANGELOG.md` entry.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0055 Success Criteria and Out of Scope.

* ADR constraints:

  * ADR-0026: approval is a recorded act; the diagnostic only detects, it does
    not approve.
  * ADR-0027: containment and reserved-path checks remain unchanged.
  * ADR-0050: the diagnostic text must match the recovery paths this ADR
    defines.

* Architecture constraints:

  * The check remains Bash 3.2 compatible and uses the existing front-matter
    cache.

## 7. Risks and Edge Cases

* Risk: false positives on single-PR plans that legitimately transition
  `approved → in-progress → implemented`. Mitigation: the diagnostic only
  fires when the most recent touching commit lacks an `Approved-By:` or
  equivalent self-approval record; the single-PR shortcut is unaffected.

## 8. Validation

* Tests expected to pass:

  * `test/FS-0055/reapproval-diagnostic.bats`

* Manual checks (if any):

  * Run the updated `check-status` against the two worked cases in issue #155
    and confirm the diagnostic is emitted with the correct voiding commit.

## 9. Explicit Non-Changes

State what will NOT be modified.

* `docs/decisions/ADR-0026-approval-is-a-recorded-act.md`
* `docs/decisions/ADR-0027-plan-self-approval-within-declared-interfaces.md`
* `workflows/document-lifecycle.md`
* `guidelines/ROLE_CONTRACT.md`

## 10. Readiness Check

* [x] Spec is draft (implementation blocked until approved)
* [x] Tests exist or are clearly defined
* [x] Scope is minimal and explicit
* [x] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding

agent-stance: mode=architecture-planning; role=Head Architect; model=ollama-cloud/kimi-k2.7-code; session=implementation; rationale=draft implementation plan for ADR-0050 re-approval diagnostics
