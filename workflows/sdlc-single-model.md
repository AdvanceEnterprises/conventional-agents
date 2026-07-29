# SDLC Workflows — Single-Model

This document is the **current-state description** of the single-model SDLC workflow.
The multi-model sibling lives at `workflows/sdlc-multi-model.md`. The two share a
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

## Workflow 1 — Single-Model, Multi-Role

One model traverses the spine, adopting each phase's role in turn.

**Role transitions are stance changes, not handoffs.** The model declares its new role
per `ROLE_CONTRACT` §"Role and session transparency", and each role's prohibited actions
bind it while held. A model in Reviewer stance produces observations and does not fix
what it finds, even though the same model held Implementer stance an hour earlier.

**Sessions may span phases or not.** One session may carry phases 2 through 6; six
sessions may carry one phase each. What must survive a session boundary is the artifacts
— governed documents, tests, commits — not conversational context.

**Collaboration rounds are unavailable.** Consensus (`FS-0019`) and review boards
(`FS-0021`) both require at least two distinct models (`ADR-0023` Constraint 1). Neither
can run here. This is a real capability difference and not a configuration one:
single-model review is one perspective however many stances it adopts, because a model's
blind spots are correlated across every stance it holds.

### Stance-change model

For each phase transition, the session declares:

- The phase it is leaving and the phase it is entering.
- The new role it is taking under `ROLE_CONTRACT` §"Role and session transparency".
- The work item or PLAN ID it is operating against.
- The artifact scope, which for implementation phases is the PLAN's `touches:` field.

A single model transitioning Reviewer → Implementer mid-spine inherits the prior phase's
artifacts but not its conversational context. Anything the prior session knew that is
not in the artifacts is lost.

### What this workflow cannot do

- **No consensus.** Same-model agreement is theater (`ADR-0023` Constraint 1).
- **No review boards.** Two seats filled by one model in different role stances do not
  satisfy `ADR-0023` — role stance changes what a model looks *for*, not what it is
  capable of *seeing*.
- **No cross-work-item concurrency on one artifact.** `ADR-0013` forbids it; the spine
  is sequential per artifact regardless of how many models are available.

### When to choose this workflow

- One model is available or affordable.
- The work is bounded and the consumer does not want collaboration rounds.
- The cost of a second model outweighs the marginal coverage gain.

If any of those does not hold, the multi-model workflow may serve better — see
`workflows/sdlc-multi-model.md`.

## Notes for reading the spine

- Phases are **ordering constraints on the work**, not a requirement for one PR per
  phase. A single PR may traverse phases 2 through 6; a multi-PR sequence may split
  them. The order is what matters.
- `test_required: false` skips phase 4. The FS must say so explicitly — an absent field
  is not a false one. Phase 5 may begin once the PLAN is approved.
- A work item abandoned mid-spine moves to Done with the governing documents marked
  `deprecated`. Partial work is not left at `in-progress` indefinitely.
