---

type: change-plan
role: implementer
language: n/a
status: draft
related_specs:
  - FS-0057
related_adrs:
  - ADR-0018
  - ADR-0022
  - ADR-0029
  - ADR-0036
  - ADR-0050
consensus_required: false
touches:
  - guidelines/ROLE_CONTRACT.md
  - workflows/session-modes.md
  - skills/in-cycle-re-review/SKILL.md
  - skills/index.md
  - docs/specifications/FS-0057-in-cycle-re-review-trace-convention.md
  - docs/change-plans/PLAN-0061-implement-fs-0057-in-cycle-re-review-trace.md
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

* Feature Spec ID(s): FS-0057
* Related ADR ID(s): ADR-0018, ADR-0022, ADR-0029, ADR-0036, ADR-0050
* Issue / PR Reference: #220

## 2. Scope of Change

**This change WILL:**

* Add a new subsection to `guidelines/ROLE_CONTRACT.md` recording the reviewer
  obligation to post a delta-review trace when a PR head changes after a model's
  review.
* Add a new subsection to `workflows/session-modes.md` under autonomous and
  consensus modes describing the trace-posting step.
* Create `skills/in-cycle-re-review/SKILL.md` containing the exact comment
  template and once-per-head dedupe rule.
* Register the new skill in `skills/index.md`.
* Update `CHANGELOG.md` with a consumer-framed entry because the change touches
  exported surface (`guidelines/`, `workflows/`, `skills/`).

**Delivery is staged.** FS-0057 is `status: draft`, and the spec's parsing hints
say to not implement it unless `status: approved`. The draft PR carries only the
draft artifacts — FS-0057, this plan, `skills/in-cycle-re-review/SKILL.md`, and
the `skills/index.md` registration.

The remaining items above are gated and land in a follow-up change:

* `guidelines/ROLE_CONTRACT.md` and `workflows/session-modes.md` implement the
  spec's declared `interfaces:`, so they are blocked by the draft status.
* `CHANGELOG.md` sits outside FS-0057's `interfaces:`, so it needs an
  `interfaces:` amendment plus the human approval recorded under ADR-0026.
* `test/FS-0057/in-cycle-re-review-trace.bats` sits outside FS-0057's
  `interfaces:` and is absent from `touches:`, so adding it now would
  under-declare this change against the governing spec.

**This change will NOT:**

* Modify GitHub branch protection or required checks.
* Backfill trace comments on existing PRs.
* Change how the promotion gate evaluates head age.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0057/in-cycle-re-review-trace.bats`

* Target test(s):

  * `test_sc_1__trace_posted_after_head_change`
  * `test_sc_2__no_trace_when_head_unchanged`
  * `test_sc_3__dedupe_once_per_head_per_model`
  * `test_sc_4__parseable_format`

The test file is defined here but deliberately not created in the draft PR: its
path is outside FS-0057's `interfaces:` and absent from this plan's `touches:`,
so adding it now would under-declare the change against the governing spec. It
lands with the post-approval implementation change.

## 4. Files to Be Modified

Only list files that will be changed.

In this draft PR:

* `skills/in-cycle-re-review/SKILL.md`
* `skills/index.md`
* `docs/specifications/FS-0057-in-cycle-re-review-trace-convention.md`
* `docs/change-plans/PLAN-0061-implement-fs-0057-in-cycle-re-review-trace.md`

Index rows in `docs/specifications/README.md` and `docs/change-plans/README.md`
track the front-matter status of the two documents above and are kept in sync by
`check:status`.

Deferred to the post-approval implementation change (see "Delivery is staged"
in §2):

* `guidelines/ROLE_CONTRACT.md`
* `workflows/session-modes.md`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

In this draft PR:

1. Draft the exact trace-comment template and once-per-head dedupe rule in the
   new skill file.
2. Register the skill in `skills/index.md`.

After FS-0057 is approved:

1. Add the reviewer-role subsection to `guidelines/ROLE_CONTRACT.md` referencing
   the skill.
2. Add the autonomous/consensus mode subsection to `workflows/session-modes.md`
   referencing the skill.
3. Write the bats tests against the comment template parser.
4. Add a consumer-framed `CHANGELOG.md` entry.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0057 Non-Goals / Out of Scope.

* ADR constraints:

  * ADR-0018: trace comments must preserve single-identity attribution.
  * ADR-0022: the posting act is part of autonomous/consensus meta-mode
    workflow.
  * ADR-0029: the comment or an associated commit must carry the reviewing
    model's attribution.
  * ADR-0036: attribution vocabulary must match the canon.

* Architecture constraints:

  * The convention must not require a new substrate; it reuses PR comments.

## 7. Risks and Edge Cases

* Risk: a model could omit a negative delta trace. Mitigation: the promotion
  gate still requires the latest commit to be newer than each reviewer's most
  recent comment; missing traces are flagged by the tick.
* Edge case: a rebase-only head change triggers a trace. Accepted per FS-0057
  because SHA audit matters.

## 8. Validation

* Tests expected to pass:

  * `test/FS-0057/in-cycle-re-review-trace.bats`

* Manual checks (if any):

  * None.

## 9. Explicit Non-Changes

State what will NOT be modified.

* `scripts/check-status.sh`
* `.github/workflows/`
* Branch protection rulesets.

## 10. Readiness Check

* [x] Spec is draft (implementation blocked until approved)
* [x] Tests exist or are clearly defined — defined in §3; the file lands with the
  post-approval implementation change
* [x] Scope is minimal and explicit
* [x] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding

agent-stance: mode=architecture-planning; role=Head Architect; model=ollama-cloud/kimi-k2.7-code; session=implementation; rationale=draft implementation plan for the in-cycle re-review trace convention
