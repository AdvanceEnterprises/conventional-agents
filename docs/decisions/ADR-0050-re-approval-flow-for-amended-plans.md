---
type: adr
id: ADR-0050
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0055
superseded_by: null
created: 2026-10-27
updated: 2026-10-27
---

# ADR-0050: Re-approval flow for reviewer-feedback commits on approved PLANs

## Status

- Proposed

## Context and Problem Statement

`ADR-0026` defines approval as a recorded act: a PLAN reaches `approved`
through a commit carrying an `Approved-By:` trailer from a non-author. The
same rule requires the approval to cover the *current* content of the plan:
"the most recent commit touching this plan file" must carry the matching
trailer, because approval that no longer covers the current content is not
approval at all.

This rule works cleanly for the single-PR case where the plan is approved and
implemented without intermediate edits. It breaks down when reviewer feedback
requires the implementer to change the plan itself — for example, to add a step,
shrink `touches:`, or correct a scope statement. The feedback commit becomes the
most recent commit touching the plan, the `Approved-By:` trailer is no longer on
the most recent commit, and `check-status` rejects the branch with:

```text
approved_by: ... is set, but the most recent commit touching this plan carries
no matching Approved-By: trailer from a different author (ADR-0026)
```

The failure is correct: the plan was amended after approval. What is missing
is a documented convention for how to recover, and a diagnostic that names the
recovery act instead of leaving the branch red with no visible next step.

A second variant of the same trap is the lifecycle's own prescribed behavior.
`workflows/document-lifecycle.md` allows a PLAN to move from `approved` to
`in-progress` when implementation starts, and that status-transition commit
also touches the plan. If the transition commit carries no `Approved-By:`
trailer, the same rule flags it — even though the approval record itself is
intact. The single-PR path (`approved → implemented` in one PR) avoids this,
but multi-PR plans have no clean path today.

The question this ADR answers: **when a post-approval commit changes an
approved PLAN, what act re-establishes approval, and how does the framework
surface that act?**

## Decision Drivers

- **Approval must remain a deliberate human act.** No agent may silently renew
  its own approval.
- **The recovery path must be locatable.** A red branch with no next step is an
  audit dead end.
- **Do not forbid legitimate plan edits.** Review feedback often improves the
  plan; the rule should make those edits safe, not impossible.
- **Do not multiply ceremony.** The default `Approved-By:` flow already has the
  right shape; the gap is detection and UX.
- **Compose with ADR-0027.** Self-approved plans are agent-approvable under
  containment; re-approval after amendment applies to both human-approved and
  self-approved plans, but the originating authority differs.

## Considered Options

### Option A — Immutable approved PLANs

Forbid any edit to a PLAN after it reaches `approved`. All feedback must land in
implementation commits or in a `Revision:` appendix that is added only in a new
trailer-carrying commit.

Simple and unambiguous, but it forbids legitimate plan refinement and the
`Revision:` appendix itself is a plan edit. It also conflicts with the
lifecycle's `approved → in-progress` transition for multi-PR plans.

### Option B — Explicit re-approval on every editing commit

Require a new `Approved-By:` trailer on any commit that edits an approved PLAN.
This is today's de-facto rule, but it is undocumented and the failure is
invisible until CI runs.

Keeps the existing mechanism and only adds ceremony where it is needed. The
problem is UX: nothing tells the implementer that the trailer is required, and
nothing tells the human that re-approval is pending.

### Option C — Detection-first with a diagnostic and a re-approval transition

Keep Option B's semantics, add a `check-status` rule that detects the
invalidated approval and prints a diagnostic naming the invalidating commit and
the expected remedy ("re-carry the trailer or revert the plan edit"). Treat the
remedy as either:

- a new `Approved-By:` trailer on a commit that re-approves the amended plan, or
- a status bump to `draft` followed by a fresh approval transition.

Zero new state, zero new mechanics, and the failure mode becomes actionable.

## Decision Outcome

**Chosen option: Option C — Detection-first with a diagnostic and a
re-approval transition.**

### The re-approval rule

When a commit after the original approval touches an approved PLAN, the
approval is void for that PLAN until one of the following happens:

1. **Re-carry the trailer.** A subsequent commit edits the PLAN's status
   (or leaves it at `approved`) and carries a new `Approved-By:` trailer from
   a non-author naming the same plan. The new trailer covers the current plan
   content. This is the normal path for single-PR implementations and for
   feedback rounds where the human confirms the amended plan.
2. **Bump to draft and re-approve.** The plan is set to `status: draft` in a
   commit, then later returned to `approved` with a fresh `Approved-By:` trailer
   (or via ADR-0027 self-approval if containment still holds). This is the
   path for larger amendments or when the original approver wants a clean
   review surface.

Until one of those acts happens, the PLAN is not approved for its current
content, and `check-status` must say so explicitly.

### Re-approval of self-approved plans

A PLAN that originally self-approved under `ADR-0027` may also be amended. The
amendment voids the self-approval. Recovery paths:

- If the amended `touches:` still falls within the governing FS's `interfaces:`
  and outside the reserved set, the plan may self-approve again through a
  status transition commit with no separate trailer. The transition itself is
  the record.
- If the amendment pushes the plan outside containment or into a reserved
  path, human approval is required via Option C.1 or C.2 above.

### Multi-PLAN PRs

If a single PR amends more than one approved PLAN, each PLAN is evaluated
separately. The re-approval act may cover multiple plans in one commit by
listing every plan in `Approved-Artifacts:`.

### Lifecycle transition commits

A commit that moves a PLAN from `approved` to `in-progress` touches the plan
and therefore requires the same re-approval coverage as a feedback commit. The
cleanest path for multi-PR plans is to combine the `in-progress` transition
with a re-carry of the `Approved-By:` trailer in the same commit, or to use the
single-PR `approved → implemented` shortcut if the plan completes in one PR.

## Consequences

### Positive

- The framework's approval rule now matches how reviewer feedback actually
  works.
- Branches stop failing with a generic "no matching Approved-By" message and
  start failing with a message that names the invalidating commit and the
  remedy.
- Self-approved plans keep their mechanical path after amendment, as long as
  containment is preserved.
- No new substrate, no new status values, no new gate types.

### Negative

- More `Approved-By:` trailers in plan histories, which is more ceremony.
- The rule makes multi-PR plans slightly more verbose; the single-PR shortcut
  is now explicitly recommended for small changes.
- Implementers must learn the two recovery paths; the diagnostic is the
  primary teacher.

### Neutral

- `ADR-0026` remains the governing record of approval as a recorded act.
  `ADR-0050` does not supersede it; it clarifies a specific case `ADR-0026`
  left implicit.
- `ADR-0012`'s merge gate is untouched.
- `FS-0022` and `scripts/check-status.sh` gain one more rule; the script is in
  the reserved set, so that rule itself requires human approval.

## Validation

- **Signal:** every PLAN amended after approval is either re-approved with a
  new `Approved-By:` trailer, bumped to `draft` and re-approved, or the
  branch fails `check-status` with a diagnostic naming the invalidating commit.
- **Signal:** the diagnostic text includes the exact commit SHA, the expected
  remedy, and the governing ADR ids (`ADR-0026`, `ADR-0050`).
- **Signal:** over a sample of merged PRs, no approved PLAN has a
  post-approval content edit that lacks a re-approval record.
- **Review checkpoint:** after the first ten amended-plan PRs following
  acceptance. The question is whether the diagnostic is clear enough that
  implementers recover without human prompting.
- **Failure condition:** if implementers routinely bypass the rule by
  splitting plan edits across fake "implementation" commits, the diagnostic is
  too narrow and should be widened or the rule should be tightened.

## Links

- `ADR-0026`: Approval is a recorded act — the rule this ADR clarifies.
- `ADR-0027`: PLAN self-approval within declared interfaces — the mechanical
  approval path that also needs a re-approval rule.
- `workflows/document-lifecycle.md` — the current-state document whose
  `approved → in-progress` transition interacts with this rule.
- `FS-0022`: Gate coverage — the governing spec for the `check-status.sh`
  diagnostic this ADR requires.
- `FS-0055`: Re-approval detection and diagnostics for amended PLANs — the
  implementation spec that makes this ADR's detection signal machine-checkable.
- `guidelines/ROLE_CONTRACT.md` § reviewer role — the role that may record a
  re-approval.
