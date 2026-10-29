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
updated: 2026-10-29
---

# ADR-0050: Re-approval flow for reviewer-feedback commits on approved PLANs

## Status

- Proposed

## Context and Problem Statement

`ADR-0026` defines approval as a recorded act: a PLAN reaches `approved`
through a commit carrying an `Approved-By:` trailer from a non-author, and the
same ADR defines the trailer's shape and the author-mismatch rule. `ADR-0026`
does not itself say that an approval must cover the plan's *current* content; it
explicitly leaves enforcement to audit ("Enforcement is by audit, not control";
"Nothing yet checks that `Approved-By:` differs from the commit author").

The currency rule lives in the gate instead. `scripts/check-status.sh` rule 6
reads `approved_by:` from the plan's front matter and corroborates it against
git: the most recent commit touching the plan file must carry a matching
`Approved-By:` trailer from an author other than the commit's own. A later
commit that edits the plan removes that corroboration, so the human approval no
longer covers the content the gate is certifying. `ADR-0027` supplies the
surrounding routing — containment against the governing FS's `interfaces:`, and
the reserved-path set.

The problem is what the gate does with that state. Rule 6 computes
`approval_ok` only to decide whether containment errors apply — whether to
suppress its two containment errors, and, in a vendored copy, whether an
unconfigured reserved set must fail closed. No rule fails a plan because its
approval was voided, so the outcome depends entirely on containment:

- **`touches:` stays inside the governing FS's `interfaces:` and outside the
  reserved set.** `check-status` exits 0 and prints `All status checks passed.`
  The voided approval is accepted silently. This is the common case: a reviewer
  asks for a step to be added, a scope statement corrected, or an ambiguity
  resolved in the plan body, and nothing about `touches:` changes.
- **`touches:` moves into a reserved path or outside `interfaces:`.** The
  containment error fires, and the voided approval appears only as a secondary
  explanatory line: `approved_by: '...' is set, but the most recent commit
  touching this plan carries no matching Approved-By: trailer from a different
  author (ADR-0026)`.

The first case is a governance hole, not a UX wart: an approval that no longer
covers the document it names is presented to CI as a valid approval. The second
case is correct but obscure — the message describes the containment failure and
mentions the approval only in passing.

The same silence covers the lifecycle's own prescribed behavior.
`workflows/document-lifecycle.md` allows a PLAN to move from `approved` to
`in-progress` when implementation starts, and that status-transition commit also
touches the plan, voiding its approval. Nothing reports it. The single-PR path
(`approved → implemented`) escapes only because rule 6 governs plans at
`approved` and `in-progress`, and an `implemented` plan is outside its scope; a
multi-PR plan sits at `in-progress` across PRs and has no clean path today.

The question this ADR answers: **when a post-approval commit changes an
approved PLAN, what act re-establishes approval, and how does the framework make
the voided state visible instead of certifying it?**

## Decision Drivers

- **Approval must remain a deliberate human act.** No agent may silently renew
  its own approval.
- **The recovery path must be locatable.** A gate that passes a plan whose
  approval no longer covers it cannot be recovered from, because nothing tells
  the implementer that recovery is owed.
- **Do not forbid legitimate plan edits.** Review feedback often improves the
  plan; the rule should make those edits safe, not impossible.
- **Do not multiply ceremony.** The default `Approved-By:` flow already has the
  right shape; the gap is detection.
- **Compose with ADR-0027.** Self-approved plans are agent-approvable under
  containment; re-approval after amendment applies to both human-approved and
  self-approved plans, but the act differs — a trailer for one, containment for
  the other.

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
This is today's de-facto rule, but it is undocumented, and under the current gate
its failure is invisible: a voided approval passes whenever containment holds,
whether or not CI runs.

Keeps the existing mechanism and only adds ceremony where it is needed. The
problem is detection: nothing fails when the trailer is missing, and nothing
tells the implementer that re-approval is pending.

### Option C — Detection-first with a diagnostic and a re-approval transition

Keep Option B's semantics, add a `check-status` rule that fails a plan whose
`Approved-By:` record no longer covers the plan's current content, naming the
invalidating commit and the expected remedy ("re-carry the trailer or revert the
plan edit"). Treat the remedy as either:

- a new `Approved-By:` trailer on a commit that re-approves the amended plan, or
- a status bump to `draft` followed by a fresh approval transition.

Zero new state and zero new mechanics; the rule makes an already-defined invalid
state fail instead of passing.

## Decision Outcome

**Chosen option: Option C — Detection-first with a diagnostic and a
re-approval transition.**

### The re-approval rule

When a commit after the original approval touches a human-approved PLAN, the
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

Until one of those acts happens, a human-approved PLAN is not approved for its
current content, and `check-status` must fail the branch and say so. Today it
says nothing. Self-approved plans are routed differently — they carry no approval
record to renew, so the next section governs them.

### The detection rule

`scripts/check-status.sh` gains one rule, conceptually rule 6a, evaluated over
the same plan set rule 6 governs — plans at `approved` or `in-progress`:

- If the plan carries a human `approved_by:` record and the most recent commit
  touching the plan file does not carry the matching `Approved-By:` trailer, the
  rule fails the plan and names the commit that voided the approval.
- If the plan is self-approved under `ADR-0027`, no trailer is owed: self-approval
  is recomputed from the plan's current `touches:` ("A plan that self-approves
  records this in its status transition; there is no separate marker"). An
  amendment that leaves `touches:` inside the governing FS's `interfaces:` and
  outside the reserved set therefore does not fail. An amendment that leaves
  containment does fail, because self-approval authority no longer covers the
  plan and a human must approve it.

This is a new failure, not a reformatted one. Every state the rule names is a
state the current gate certifies as passing, so the rule's job is to stop
certifying it — a message change alone would leave the hole open. Rule 6's
containment and reserved-path checks are unchanged; the reserved-path set already
covers `scripts/`, so the rule that implements this ADR requires human approval to
land.

### Re-approval of self-approved plans

A PLAN that self-approved under `ADR-0027` may also be amended. Self-approval is
routing rather than a record, so the question is not how to renew it but whether
the plan still qualifies:

- If the amended `touches:` still falls within the governing FS's `interfaces:`
  and outside the reserved set, the plan remains self-approved. No trailer, no
  new transition, and no human act are owed — the gate recomputes the same
  answer from the same fields.
- If the amendment pushes the plan outside containment or into a reserved path,
  self-approval authority no longer covers it and human approval is required via
  Option C.1 or C.2 above.

### Multi-PLAN PRs

If a single PR amends more than one approved PLAN, each PLAN is evaluated
separately. Rule 6 resolves approval per plan by finding the most recent commit
that touched *that plan file*, and it never reads `Approved-Artifacts:` — that
trailer is consumed only by `scripts/check-run-batch.sh`, which does not enforce
the approval gate. One re-approval commit can therefore cover several plans only
if it physically touches every plan file it re-approves. Listing a plan in
`Approved-Artifacts:` re-approves nothing; a commit that touches one plan and
lists the others leaves the others void, and the branch fails for them.

### Lifecycle transition commits

A commit that moves a PLAN from `approved` to `in-progress` touches the plan and
therefore voids the approval it carries, exactly as a feedback commit does.
Under the current gate that is silent; under the detection rule it fails. The
cleanest path for multi-PR plans is to combine the `in-progress` transition with
a re-carry of the `Approved-By:` trailer in the same commit, or to use the
single-PR `approved → implemented` shortcut if the plan completes in one PR — a
plan that reaches `implemented` in the same PR is outside the rule's scope.

## Consequences

### Positive

- The gate's certification now matches `ADR-0026`'s approval semantics: a plan
  whose approval no longer covers its content is not certified.
- A voided approval stops passing CI. The branch fails, and the diagnostic names
  the invalidating commit and the remedy.
- Self-approved plans keep their mechanical path after amendment, as long as
  containment is preserved.
- No new substrate, no new status values, no new gate types.

### Negative

- More `Approved-By:` trailers in plan histories, which is more ceremony.
- Branches that pass today start failing. A plan amended for a good reason —
  a reviewer asked for the step — blocks until it is re-approved, even when the
  same human would approve the edit on sight. That is the intent, but it turns a
  silent pass into a mid-review blocking error.
- The rule makes multi-PR plans slightly more verbose; the single-PR shortcut
  is now explicitly recommended for small changes.
- Implementers must learn the two recovery paths; the diagnostic is the primary
  teacher.

### Neutral

- `ADR-0026` remains the governing record of approval as a recorded act.
  `ADR-0050` does not supersede it and does not change what counts as approval;
  it adds gate enforcement for a state `ADR-0026` explicitly left to audit.
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
- **Failure condition:** if plan content routinely migrates out of the PLAN file
  — into an appendix document or an uncommitted working note — to avoid touching
  the file the rule watches, the commit-based detection is too narrow and must be
  replaced with content-based detection.

## Links

- `ADR-0026`: Approval is a recorded act — the definition of approval this ADR
  enforces at the gate; it does not itself state the currency rule.
- `ADR-0027`: PLAN self-approval within declared interfaces — the mechanical
  approval path, and the source of the containment and reserved-path routing this
  rule composes with.
- `workflows/document-lifecycle.md` — the current-state document whose
  `approved → in-progress` transition interacts with this rule.
- `FS-0022`: Gate coverage — the spec that governs `scripts/check-status.sh`
  generally. It does not contain the detection rule this ADR requires; `FS-0055`
  specifies that rule.
- `FS-0055`: Re-approval detection and diagnostics for amended PLANs — the
  implementation spec that makes this ADR's detection signal machine-checkable.
- `guidelines/ROLE_CONTRACT.md` — the Reviewer role (§ Role 4) produces review
  comments only and may not modify documentation, so a reviewer cannot record a
  re-approval. The implementer records the trailer on the approving human's
  behalf, per `ADR-0026`: "The agent may record the approval. The agent may not
  be the approval."
