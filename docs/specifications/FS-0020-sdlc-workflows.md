---
type: feature-spec
id: FS-0020
status: approved
title: SDLC workflows — single-model and multi-model
owner: ajoeofalltrades
test_required: true
interfaces:
  - "workflows/sdlc-single-model.md"
  - "workflows/sdlc-multi-model.md"
  - "workflows/session-modes.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "README.md"
  - "AGENTS.md"
  - "INTEGRATION.md"
  - "docs/specifications/README.md"
  - "test/FS-0020/sdlc-workflows.bats"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0012
  - ADR-0013
  - ADR-0024
  - ADR-0026
  - ADR-0027
  - ADR-0031
supersedes: []
requires:
  - FS-0018
tags: [workflow, sdlc, roles, multi-model]
created: 2026-07-28
updated: 2026-07-28
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: SDLC Workflows

## Status

- Approved

## Plan Status

- **PLAN-0020 is `approved`**, approved in the same session as this FS. `workflows/document-lifecycle.md`
  places PLAN creation at "initial creation" and constrains only its
  *approval*: a PLAN may not reach `approved` while its FS is `draft`.
  Drafting alongside is permitted.
- The two workflow documents this spec governs are authored during
  PLAN-0020's execution, not here.

## Summary

Define two named workflows for carrying governed work from brief to merge:

1. **Single-model, multi-role** — one model occupies every role in turn.
2. **Multi-model, multi-role** — different models occupy different roles,
   handing off through documents and git state.

Both traverse the **same spine**. Roles are always plural; what varies is
how many models fill them. Neither workflow introduces a role, a phase, or
a gate that the other lacks.

The spine is **sequential per artifact**. Concurrency exists only across
disjoint artifact scopes (`ADR-0013` Mode 1) and inside a single step, where
a gate may fan out to several models and back (`ADR-0031`). Two sessions
never work the same artifact at the same time in either workflow.

## Goals

- Name the phases, the role that leads each, and the artifact each
  produces.
- State which gates are human-held and which are mechanical, identically
  in both workflows.
- Define how a role hands off to the next role, and what a receiving
  session may assume.
- Define where collaboration rounds attach, and why they are available in
  only one of the two workflows.
- Establish that model count is the only axis on which the workflows
  differ.

## Non-Goals

- Introducing roles or session modes. Roles come from
  `guidelines/ROLE_CONTRACT.md`; modes and meta-modes from `FS-0015` and
  `ADR-0022`.
- Defining concurrent role-holders on one artifact. `ADR-0013` forbids it;
  this spec does not reopen the question.
- Assigning models to roles. That is consumer configuration, exactly as
  participant selection is in `FS-0019` and seat composition in `FS-0021`.
- Naming a platform. The work item layer is `FS-0018`; substrate mechanics
  live in `integrations/` bindings.
- Prescribing a review process. Whether review is a human, a single agent,
  or a review board is the consumer's choice.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — operates both workflows across
  Tais-Den projects and needs the handoffs to be legible between sessions.
- **Agent actors** — need to know which role they hold, what the previous
  role guaranteed, and what they must leave for the next.
- **Consumer-repo maintainers** — choose a workflow per project and
  configure model assignment.

## The Shared Spine

Seven phases. Both workflows traverse all seven in order.

| # | Phase | Leading role | Produces | Exit gate |
| --- | --- | --- | --- | --- |
| 1 | Origination | Head Architect (0) | Work item with a brief | Type set by a human (`FS-0018`) |
| 2 | Specification | Document Author (1) | FS, `status: draft` | **Human approval** (`ADR-0026`) |
| 3 | Planning | Document Author (1) | PLAN, `status: draft` | Human approval, **or** self-approval (`ADR-0027`) |
| 4 | Test authoring | Spec Reader / Test Planner (2) | Failing tests | Tests exist and fail, or `test_required: false` |
| 5 | Implementation | Implementer (3) | Production changes | Tests pass; `check:status` and lint pass |
| 6 | Review | Reviewer (4) | Observations | Findings dispositioned |
| 7 | Merge | — | Merged trunk | **Human merge** (`ADR-0012`) |

Phase 8, Communications (Role 5), is optional and follows merge.

**Phases do not overlap on one work item.** Phase 5 does not begin while
phase 4 is producing tests for the same FS. This is `ROLE_CONTRACT`'s
Docs → Tests → Code ordering, and it is a design choice rather than a
limitation: the ordering is what makes tests a correctness boundary rather
than a description of whatever was built.

### Gates that never move

Three gates are identical in both workflows and are not configurable:

- **FS approval is human.** `ADR-0026` gives three shapes — merge, recorded, deferred —
  and all three are human acts.
- **Merge is human.** `ADR-0012`, non-overridable.
- **A `draft` spec is not implementable.** Phases 4 and 5 may not begin
  against one.

PLAN approval is the one gate with a mechanical path, and only under
`ADR-0027`'s containment and reserved-path conditions.

## Workflow 1 — Single-Model, Multi-Role

One model traverses the spine, adopting each phase's role in turn.

**Role transitions are stance changes, not handoffs.** The model declares
its new role per `ROLE_CONTRACT` §"Role and session transparency", and
each role's prohibited actions bind it while held. A model in Reviewer
stance produces observations and does not fix what it finds, even though
the same model held Implementer stance an hour earlier.

**Sessions may span phases or not.** One session may carry phases 2
through 6; six sessions may carry one phase each. What must survive a
session boundary is the artifacts — governed documents, tests, commits —
not conversational context.

**Collaboration rounds are unavailable.** Consensus (`FS-0019`) and review
boards (`FS-0021`) both require at least two distinct models
(`ADR-0023` Constraint 1). Neither can run here. This is a real capability
difference and not a configuration one: single-model review is one
perspective however many stances it adopts, because a model's blind spots
are correlated across every stance it holds.

## Workflow 2 — Multi-Model, Multi-Role

Different models occupy different roles. The spine is unchanged.

**Handoff is through artifacts.** A receiving session reads the governed
documents, the tests, the commits, and the work item's activity record. It
does not receive the previous session's context, and must not be designed
as though it does. Where a decision was made and not written down, it is
lost — which is the framework's central premise, applied to itself.

**Each session declares its scope** per `ADR-0013` Mode 1: work item or
PLAN ID, branch, and artifact scope. Artifact scope is the PLAN's
`touches:` field, not a second list.

**Concurrency is across work items, never within one.** Two sessions may
run simultaneously on different work items whose `touches:` sets are
disjoint. On overlap both stop and escalate. A single work item advances
one phase at a time.

**Collaboration rounds attach at gates.** A round fans out to several
models and back inside one phase; the spine remains sequential. Placements:

| Round | Phase | Specification |
| --- | --- | --- |
| Consensus, pre-submission | 2 or 3, before approval | `FS-0019` Gate A |
| Review board, artifact review | 2 or 3, before approval | `FS-0021` Placement A |
| Consensus, review-time | 6 | `FS-0019` Gate B |
| Review board, change review | 6 | `FS-0021` Placement B |

Rounds are **advisory to the phase's leading role**, which retains
authority. A review board reporting `blocking` findings does not block; it
informs the Reviewer, who dispositions them. Rounds are opt-in and ship
disabled (`ADR-0023` Constraint 2).

## What Differs, and What Does Not

| | Single-model | Multi-model |
| --- | --- | --- |
| Phases | Seven | Seven |
| Roles per phase | Same | Same |
| Human gates | Same | Same |
| Spine ordering | Sequential | Sequential |
| Role change is | A stance change | A handoff |
| Context carried | May persist in-session | Artifacts only |
| Concurrency across work items | Possible | Possible |
| Collaboration rounds | **Unavailable** | Available, opt-in |

The single row that produces every other difference is model count.

## Handoff Contract

What a receiving session may assume, in both workflows, at each boundary:

| Receiving phase | May assume | Must verify |
| --- | --- | --- |
| 3 Planning | FS is `approved` | The FS's `interfaces:` cover the work |
| 4 Test authoring | FS is `approved`; PLAN is `approved` | Success criteria are testable |
| 5 Implementation | Tests exist and fail | Tests map to success criteria |
| 6 Review | Tests pass; gates pass | The diff matches the FS's `interfaces:` |

A receiving session that finds an assumption false **stops and escalates**
rather than repairing the previous phase's output. Repairing it silently
destroys the boundary the phases exist to create.

## Success Criteria

**Spine**:

- Given either workflow, when its documentation is read, then it names
  seven phases with the same leading role per phase.
- Given a work item in phase 5, when its history is read, then phase 4
  completed for the governing FS before phase 5 began.

**Gates**:

- Given an FS at `draft`, when an agent attempts to begin phase 4 or 5,
  then it stops and no test or implementation commit is produced.
- Given an FS transitioning `draft → approved` without a merge, when the
  commit is read, then it carries an `Approved-By:` trailer naming a human
  who is not the commit's author (`ADR-0026`).
- Given a completed work item, when its history is read, then the merge
  was performed by a human.

**Single-model workflow**:

- Given a single-model configuration, when a collaboration round is
  requested, then it fails with a configuration error naming the
  different-models requirement, and no round artifact is written.
- Given one model holding Reviewer stance, when it produces output, then
  that output contains observations and no modifications to the artifact
  under review.

**Multi-model workflow**:

- Given two sessions with overlapping `touches:` sets, when the overlap is
  detected, then both stop and escalate, and neither commits.
- Given two sessions with disjoint `touches:` sets, when both run, then
  both proceed.
- Given a session beginning a phase, when its activity-record entry is
  read, then it declares work item or PLAN ID, branch, and artifact scope.
- Given a collaboration round at any placement, when the phase completes,
  then the leading role dispositioned the round's output and the round
  performed no status transition.

**Handoff**:

- Given a receiving session that finds a stated assumption false, when it
  responds, then it escalates and does not modify the previous phase's
  output.

## Edge Cases

- **`test_required: false`.** Phase 4 is skipped; phase 5 may begin once
  the PLAN is approved. The FS must say so explicitly — an absent field is
  not a false one.
- **A single PR completing several phases.** Permitted. Phases are
  ordering constraints on the work, not a requirement for one PR each.
- **Review finds a spec defect rather than an implementation defect.**
  Escalates to phase 2 with the work item returning to an earlier phase.
  The Reviewer does not amend the FS.
- **The same model available under two identifiers.** Fails
  `ADR-0023` Constraint 1; a collaboration round configured that way does
  not run.
- **A work item abandoned mid-spine.** Phase moves to Done with the
  governing documents marked `deprecated`. Partial work is not left at
  `in-progress` indefinitely.
- **Multi-model configuration where only one model is reachable.**
  Degrades to workflow 1 for that work item, and records the degradation.
  It does not proceed while claiming to be multi-model.

## Out of Scope

- Concurrent role-holders on one artifact (`ADR-0013`).
- Model-to-role assignment.
- Estimation, scheduling, and velocity.
- Release process. `workflows/versioning-and-releases.md` covers it.
- Rollback and incident response.
- Any workflow with a non-sequential spine.

## Dependencies

- `FS-0018`: the work item layer phase 1 originates into, and the activity
  record handoffs are declared on.
- `ADR-0013`: Mode 1 scope declaration and the no-concurrent-artifact rule
  the spine rests on; Mode 2 authority for rounds.
- `ADR-0031`: the three-artifact round collaboration placements use.
- `ADR-0026`: the approval shapes phase 2 and 3 gates accept.
- `ADR-0027`: the self-approval path at phase 3.
- `ADR-0012`: the merge gate at phase 7.
- `guidelines/ROLE_CONTRACT.md`: the roles, their prohibitions, and the
  Docs → Tests → Code ordering.
- `FS-0019`, `FS-0021`: the collaboration modes workflow 2 may invoke.

## Open Questions

None blocking approval.

- **Whether phase 8 (Communications) should be in the spine table.**
  Working answer: no — it follows merge and is optional, so including it
  would imply a gate it does not have. Confirm.
- **Whether a work item may re-enter an earlier phase without returning to
  Backlog.** Working answer: yes, phase moves backward with an
  activity-record entry recording why. Forward-only applies to document
  status, not to work item phase. Confirm.

## Rollout / Migration

1. Author `workflows/sdlc-single-model.md` and
   `workflows/sdlc-multi-model.md` as the current-state documents for the
   two workflows, per `ADR-0030`.
2. Cross-reference both from `workflows/session-modes.md`, which describes
   role stance within a phase rather than the phase sequence.
3. Add `test/FS-0020/sdlc-workflows.bats` covering the spine, gate
   invariants, and the single-model collaboration exclusion.
4. Reference both workflows from `README.md` and `AGENTS.md`.
5. Update `INTEGRATION.md` with workflow selection guidance for consumers.
