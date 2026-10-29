---
type: feature-spec
id: FS-0055
status: draft
title: Re-approval detection and diagnostics for amended PLANs
owner: Head Architect
test_required: true
interfaces:
  - scripts/check-status.sh
  - docs/decisions/ADR-0050-re-approval-flow-for-amended-plans.md
  - docs/specifications/FS-0055-re-approval-diagnostics-for-amended-plans.md
  - docs/change-plans/PLAN-0062-implement-fs-0055.md
  - test/FS-0055/reapproval-diagnostic.bats
  - CHANGELOG.md
related_adrs:
  - ADR-0026
  - ADR-0027
  - ADR-0050
supersedes: []
requires:
  - FS-0022
tags:
  - governance
  - diagnostics
  - approval
  - plan
  - check-status
created: 2026-10-27
updated: 2026-10-29
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- `interfaces:` bounds which change plans may self-approve (ADR-0027) — draw
  it narrowly; a loose `interfaces:` widens agent authority.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->
# Feature Spec: Re-approval detection and diagnostics for amended PLANs

## Status

- Draft

## Summary

Add a `check-status` rule that fails a PLAN whose `Approved-By:` record no
longer covers the plan's current content, and tells the implementer exactly
which commit voided the approval and how to recover. Today that state is
silent: a voided approval passes `check-status` whenever the amendment leaves
`touches:` inside the governing FS's `interfaces:`, so the rule closes a
governance gap between `ADR-0026`'s approval semantics and what the gate
enforces. It changes no approval definition — it makes an already-invalid state
fail instead of pass.

## Goals

- Detect post-approval PLAN edits that invalidate the current `Approved-By:`
  record.
- Fail the branch for a human-approved plan whose approval record no longer
  covers its current content, instead of passing silently.
- Emit one diagnostic per invalidated PLAN naming the voiding commit SHA and
  the two recovery paths (re-carry trailer or bump to draft).
- Distinguish human-approved plans from self-approved plans in the diagnostic.
- Leave the existing rule 6 containment checks unchanged.

## Non-Goals

- Relaxing `ADR-0026` or `ADR-0027`.
- Auto-recovering or auto-re-approving plans.
- Adding a new status value.
- Changing the merge gate.

## Users / Stakeholders

- Implementer whose branch fails the re-approval check after applying reviewer
  feedback.
- Human reviewer deciding whether to re-approve a plan they already approved once.
- Autonomous tick compiling the digest of blocked work items.

## Interfaces

- Type: Script | CI check
- Details:
  - `scripts/check-status.sh` gains a new rule (numbered after the existing
    rule 6, conceptually rule 6a) that checks every PLAN at `approved` or
    `in-progress` — the same plan set rule 6 governs — for post-approval edits
    that void its approval.
  - Diagnostic format:

    ```text
    ERROR: PLAN-XXXX was amended after its Approved-By record. Voiding commit:
           <sha>. Recover by (1) re-carrying Approved-By on a new commit, or (2)
           setting status: draft and re-approving. See ADR-0026, ADR-0050.
    ```

  - A non-failing notice is emitted when a self-approved plan under ADR-0027 was
    amended but remains within containment, where self-approval is simply
    recomputed from the current `touches:`. A self-approved plan that left
    containment is an ERROR, not a notice (see Success Criteria).

## Success Criteria

- Given a human-approved PLAN whose most recent touching commit lacks an
  `Approved-By:` trailer and whose prior touching commit carries one, when
  `check-status` runs, then it exits non-zero, names the voiding commit SHA, and
  prints the two recovery paths.
- Given a PLAN whose most recent touching commit has a matching `Approved-By:`
  trailer, when `check-status` runs, then no diagnostic is emitted for that
  plan.
- Given a self-approved PLAN that was amended so its new `touches:` exceeds the
  governing FS's `interfaces:`, when `check-status` runs, then the diagnostic
  states that human approval is now required.
- Given an `approved → in-progress` transition commit with no re-carry trailer,
  when `check-status` runs, then the diagnostic names the transition commit as
  the voiding commit.

## Edge Cases

- A rebase that touches the plan file without changing content still voids the
  approval because the commit SHA changed; the diagnostic is accurate.
- A plan amended only to update its `updated:` front matter is still amended;
  the rule is commit-based, not content-based.
- If multiple plans are voided by the same commit, the diagnostic is emitted
  once per plan.

## Out of Scope

- Suggesting specific edits to the plan text.
- Integrating with GitHub Checks annotations.
- Backfilling diagnostics for historical PRs.

## Dependencies

- ADR-0026: Approval is a recorded act — the definition of approval whose
  currency this spec enforces at the gate.
- ADR-0027: PLAN self-approval within declared interfaces — the mechanical
  approval path that also needs invalidation detection.
- ADR-0050: Re-approval flow for reviewer-feedback commits on approved PLANs
  — the decision this spec implements.
- FS-0022: Gate coverage — the spec governing `check-status.sh`.

Front-matter `requires:` is documentation only — no repository gate reads it. The
dependency above is recorded for readers and reviewers; the enforced relationship
is ADR-0027's containment routing, which reads a plan's `related_specs:` and not
this field.

## Rollout / Migration

- Add the rule to `scripts/check-status.sh`.
- Add bats tests under `test/FS-0055/`.
- Update `CHANGELOG.md` with a consumer-framed entry because `scripts/` is
  exported surface.

## Observability

- Logs: check-status logs one line per voided plan.
- Metrics: tick digest counts "plans awaiting re-approval".
- Traces: n/a.

## Security / Privacy

- Data handled: PLAN paths, commit SHAs, `Approved-By:` trailers. All already in
  the repository.
- Threats considered: an agent could suppress the diagnostic by editing
  check-status. Mitigation: `scripts/` is reserved, so any such edit requires
  human approval.
- Mitigations: the rule is read-only and additive.

## Open Questions

- Should a self-approved plan that remains within containment still receive the
  non-failing notice, or is silence correct there because self-approval is
  recomputed from `touches:` rather than recorded? ADR-0050 settles the routing —
  no branch failure — but not whether the notice earns its noise.
- Should the rule also flag FS documents amended after `Approved-By:`?
  `ADR-0026` applies to FS approvals too, but the worked cases are all PLANs.
