---
type: adr
id: ADR-0045
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
---

# ADR-0045: Bounded autonomous runs with batch proposal-acceptance

## Status

- Proposed

## Context and Problem Statement

The framework's approval model is per-artifact. `ADR-0026` records approval on a
commit, and `ADR-0027` gates reserved paths behind a recorded human act; every
ADR/FS/PLAN is its own approval event. That granularity is correct for
*authorizing changes* — reserved paths and live enforcement must stay narrowly
gated — but it does not fit *accepting proposals*. A draft document authorizes
nothing, yet a long autonomous work period that authors many drafts presents the
human with many separate approval events, one per document, even though the set
is one coherent body of work.

Two objectives are in tension. **Governance integrity** demands that approval
remain a recorded, human-held act with a hard line between accepting a proposal
and authorizing its implementation. **Review throughput** demands that a human
be able to review and approve a coherent body of agent work once, at the end of
a run, rather than N times as documents trickle out.

Most of the machinery already exists. `ADR-0019` keys the autonomous gate on a
work item; `FS-0018` defines the work-item layer and the agent-stance record;
`ADR-0026` records approval in a commit whose `Approved-Artifacts:` trailer
already lists multiple artifacts; `ADR-0028` resumes work when approval is
recorded. What is missing is a first-class *run* that binds a declared scope, a
bounded time window, and a single batch acceptance at its boundary.

## Decision Drivers

- **Governance integrity:** approval stays recorded and human-held;
  proposal-acceptance must never become implementation-authorization.
- **Review throughput:** one coherent review at run end, not N isolated
  approvals.
- **Scope discipline:** a run must have a declared, reviewable boundary so the
  end approval is a review of in-scope work, not a surprise.
- **Fork-PR threat model (public release):** the high-risk half must remain
  detection-over-prevention, with no weakening of the merge gate or of
  reserved-path approval.
- **Bounded staleness:** a run's artifact set must not drift between end-of-run
  and approval.

## Considered Options

### Option A — Per-artifact approval only (status quo)

Every ADR/FS/PLAN is its own approval event. Correct for authorization; a
throughput failure for proposal acceptance, and it produces the
"approving one at a time" burden this decision exists to relieve. *Rejected.*

### Option B — Batch approval with no declared scope

Approve a set of artifacts at once, keyed to nothing but the delivery PR.
Removes the up-front scope contract, so the human's first sight of what was
worked is the approval itself — weaker safety for no throughput gain.
*Rejected.*

### Option C — Bounded autonomous runs

A run is a bounded autonomous work period declared up front through a work
item, with batch proposal-acceptance recorded once at its boundary. *Chosen.*

## Decision Outcome

**Chosen option: Option C — bounded autonomous runs.**

A **run** is a single work item carrying scope, non-goals, and acceptance
criteria; a human go/no-go recorded by moving the item to In Progress; a hard
duration bound of at most 48 hours; and one batch acceptance at the end.

The contract, in order:

1. **Declare.** The agent opens the work item with scope, non-goals, and
   acceptance criteria. A human records go/no-go by moving Status to
   In Progress.
2. **Run.** The agent authors proposal-class documents (draft FS/PLAN/ADR)
   within the declared scope. During the run it does not touch reserved paths,
   does not change live enforcement, and does not merge.
3. **Bound.** The run lasts at most 48 hours. At the boundary the agent freezes
   its artifact set and stops editing.
4. **Present.** The agent opens one manifest-first PR: the body is a flow-report
   (objective, artifact manifest with status and risk tier, and two labeled
   sections — proposals vs. implementation), and the documents are the diff.
5. **Approve.** One recorded approval accepts the proposal tier: an
   `Approved-By:` trailer with `Approved-Artifacts: <list>` on the final commit.
   A rebase onto trunk happens *before* that approval commit, never after.

**The invariant that keeps this safe:** batch acceptance reaches
proposal-acceptance only. Reserved-path changes, ruleset changes, workflow
changes, and merge remain individually and narrowly human-gated, unchanged.
Accepting a proposal never authorizes its implementation.

## Consequences

### Positive

- One approval per run replaces N per-artifact approvals for proposal-class work.
- The manifest gives the human one coherent review surface; the risk-tier split
  keeps high-risk items visibly separate.
- The up-front scope contract restores "safely": the end approval is a review
  of declared, in-scope work.

### Negative

- Batch granularity means one approval covers many artifacts, so a scope
  mistake is correspondingly larger than a single-document mistake. Mitigated
  by the up-front scope contract and the risk-tier split.
- The run's declared scope must be written carefully, or the end review becomes
  harder, not easier.

### Neutral

- The 48-hour bound is a policy choice, not a technical limit; it bounds how
  stale the reviewed head can be. Trunk drift is handled by rebasing before
  approval.

## Validation

- **Signal:** proposal-class work arrives as one batch approval per run, not one
  per document.
- **Signal:** no `Approved-Artifacts:` batch ever lists a reserved path or a
  merged change; the risk-tier split is present in every run manifest.
- **Signal:** the run's acceptance criteria are satisfied or explicitly
  re-scoped before the batch is approved.
- **Review checkpoint:** after several runs, confirm the manifest-first surface
  reduces review burden without weakening the proposal/implementation line.

## Links

- ADR-0019 — the autonomous gate this widens.
- ADR-0026 — recorded approval; the batch form extends its `Approved-Artifacts:` list.
- ADR-0028 — level-triggered reconciliation.
- ADR-0042 (proposed) — the flow-report read-model; the run manifest is its
  concrete surface.
- ADR-0041 (proposed) — a distinct moderation mechanism (maintenance-class
  direct-to-trunk), kept separate from this decision.
- FS-0018 — the work-item layer and the autonomous-gate stance record.
