---
updated: 2026-07-28
---

# SDLC Workflows — Multi-Model

This document is the **current-state description** of the multi-model SDLC workflow.
The single-model sibling lives at `workflows/sdlc-single-model.md`. The two share a
seven-phase spine that is identical in phases, roles, and gates — what varies is how
many models fill the roles.

Per `ADR-0030`, this document states *what to do*. `FS-0020` and its related ADRs state
*why*. Where this document and an ADR appear to disagree, the ADR is the rationale; this
document is the materialized view.

## The shared spine

Seven phases. Every workflow — single-model and multi-model — traverses all seven in order.

| # | Phase | Leading role | Produces | Exit gate |
| --- | --- | --- | --- | --- |
| 1 | Origination | Head Architect (0) | Work item with a brief | Type set by a human (`FS-0018`) |
| 2 | Specification | Document Author (1) | FS, `status: draft` | **Human approval** (`ADR-0026`) |
| 3 | Planning | Document Author (1) | PLAN, `status: draft` | Human approval, **or** self-approval (`ADR-0027`) |
| 4 | Test authoring | Spec Reader / Test Planner (2) | Failing tests | Tests exist and fail, or `test_required: false` |
| 5 | Implementation | Implementer (3) | Production changes | Tests pass; `check:status` and lint pass |
| 6 | Review | Reviewer (4) | Observations | Findings dispositioned |
| 7 | Merge | — | Merged trunk | **Human merge** (`ADR-0012`) |

Phase 8, Communications (Role 5), is optional and follows merge. It is not in the spine
because it has no gate; the framework recommends a Communications session after merge but
does not require one.

**Phases do not overlap on one work item.** Phase 5 does not begin while phase 4 is
producing tests for the same FS. This is `ROLE_CONTRACT`'s Docs → Tests → Code ordering,
and it is a design choice rather than a limitation: the ordering is what makes tests a
correctness boundary rather than a description of whatever was built.

### Gates that never move

Three gates are identical in both workflows and are not configurable:

- **FS approval is human.** `ADR-0026` gives three shapes — merge, recorded, deferred —
  and all three are human acts.
- **Merge is human.** `ADR-0012`, non-overridable.
- **A `draft` spec is not implementable.** Phases 4 and 5 may not begin against one.

PLAN approval is the one gate with a mechanical path, and only under `ADR-0027`'s
containment and reserved-path conditions.

## Workflow 2 — Multi-Model, Multi-Role

Different models occupy different roles. The spine is unchanged.

**Handoff is through artifacts.** A receiving session reads the governed documents, the
tests, the commits, and the work item's activity record. It does not receive the
previous session's context, and must not be designed as though it does. Where a decision
was made and not written down, it is lost — which is the framework's central premise,
applied to itself.

**Each session declares its scope** per `ADR-0013` Mode 1: work item or PLAN ID, branch,
and artifact scope. Artifact scope is the PLAN's `touches:` field, not a second list.
Concurrency across work items is permitted only when their `touches:` sets are disjoint.

**Concurrency is across work items, never within one.** Two sessions may run
simultaneously on different work items whose `touches:` sets are disjoint. On overlap
both stop and escalate. A single work item advances one phase at a time.

**Collaboration rounds attach at gates.** A round fans out to several models and back
inside one phase; the spine remains sequential. Placements:

| Round | Phase | Specification |
| --- | --- | --- |
| Consensus, pre-submission | 2 or 3, before approval | `FS-0019` Gate A |
| Review board, artifact review | 2 or 3, before approval | `FS-0021` Placement A |
| Consensus, review-time | 6 | `FS-0019` Gate B |
| Review board, change review | 6 | `FS-0021` Placement B |

Rounds are **advisory to the phase's leading role**, which retains authority. A review
board reporting `blocking` findings does not block; it informs the Reviewer, who
dispositions them. Rounds are opt-in and ship disabled (`ADR-0023` Constraint 2).

## Handoff Contract

What a receiving session may assume, in both workflows, at each boundary:

| Receiving phase | May assume | Must verify |
| --- | --- | --- |
| 3 Planning | FS is `approved` | The FS's `interfaces:` cover the work |
| 4 Test authoring | FS is `approved`; PLAN is `approved` | Success criteria are testable |
| 5 Implementation | Tests exist and fail | Tests map to success criteria |
| 6 Review | Tests pass; gates pass | The diff matches the FS's `interfaces:` |

A receiving session that finds an assumption false **stops and escalates** rather than
repairing the previous phase's output. Repairing it silently destroys the boundary the
phases exist to create.

### Mode 1 scope declaration

Each session declares its scope as:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

with `<role>` carrying the work item or PLAN ID and the `touches:` artifact scope. Two
sessions whose `touches:` sets overlap MUST both stop and escalate per `ADR-0013`.

## What this workflow adds over single-model

- **Handoff through artifacts.** Conversational context does not survive the session
  boundary; artifacts do.
- **`touches:` artifact scope.** The PLAN's `touches:` field is the concurrency contract.
- **Collaboration rounds.** Fan-out inside a phase; the spine stays sequential.

## What this workflow does NOT require

- **Concurrent models on one artifact.** `ADR-0013` forbids it; the spine is sequential
  per artifact regardless.
- **Several models simultaneously.** Models occupy roles in sequence; only collaboration
  rounds are concurrent. The workflow does not require any specific number of models
  to be active at once.
- **A specific role-to-model mapping.** That is consumer configuration per `FS-0019`
  (participant selection) and `FS-0021` (seat composition).

### When to choose this workflow

- More than one model is available.
- Collaboration rounds are wanted at one or more gates.
- The work spans role stances that benefit from model diversity — for example,
  Reviewer and Head Architect perspectives catching different things.

If any of those does not hold, the single-model workflow may serve better — see
`workflows/sdlc-single-model.md`.

## Notes for reading the spine

- Phases are **ordering constraints on the work**, not a requirement for one PR per
  phase. A single PR may traverse phases 2 through 6; a multi-PR sequence may split
  them. The order is what matters.
- `test_required: false` skips phase 4. The FS must say so explicitly — an absent field
  is not a false one. Phase 5 may begin once the PLAN is approved.
- A work item abandoned mid-spine moves to Done with the governing documents marked
  `deprecated`. Partial work is not left at `in-progress` indefinitely.
- Where only one model is reachable mid-workflow, the work item degrades to the
  single-model workflow for that item, with the degradation recorded on the work
  item timeline. It does not proceed while claiming to be multi-model.
