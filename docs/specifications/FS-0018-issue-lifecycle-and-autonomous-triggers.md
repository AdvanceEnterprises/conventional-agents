---
type: feature-spec
id: FS-0018
status: implemented
title: Work item lifecycle and autonomous triggers for governed work
owner: ajoeofalltrades
test_required: true
interfaces:
  - "workflows/session-modes.md"
  - "workflows/document-lifecycle.md"
  - "workflows/git-and-gh-conventions.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "skills/git-gh-workflow/SKILL.md"
  - "integrations/github-issues-projects.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "test/FS-0018/issue-lifecycle.bats"
related_adrs:
  - ADR-0012
  - ADR-0018
  - ADR-0019
  - ADR-0020
  - ADR-0021
  - ADR-0022
  - ADR-0024
supersedes: []
requires: []
tags: [workflow, triggers, agent-orchestration, work-items]
created: 2026-07-27
updated: 2026-08-01
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

# Feature Spec: Work Item Lifecycle and Autonomous Triggers for Governed Work

## Status

- Approved

## Plan Status

- **PLAN-0018 is `approved`**, approved in the same session as this FS.
  It was drafted alongside this spec, which
  `workflows/document-lifecycle.md` permits — that document places PLAN
  creation at "initial creation" and constrains only approval.
- **Cron identity precondition — resolved.** Path 3 (autonomous work
  item creation) was blocked on the unattended-actor identity
  question. `ADR-0021` resolves it: unattended actors carry a distinct
  `user.email`, a mandatory `mode=autonomous`, and a specific
  `session=<job-name>`. Path 3 is specified and implementable at the
  framework layer; operating it still requires a consumer repo to
  provision the actor alias and token.
- Remaining open questions are listed in the "Open Questions" section
  below. None of them block approval of this FS.

## Summary

Define how governed work originates in a project that adopts
`conventional-agents`, including the three origination paths (human
request, Head Architect summary, autonomous agent detection), the
three-axis classification of every work item (Type, Label, Phase), and
the agent behavior at each lifecycle transition.

The first governed artifact for any new piece of work is a **work
item**, not an FS or ADR. The work item is the brief; the FS is the
contract; ADRs surface only if a binding decision is needed; the PLAN
comes after the FS is approved; implementation follows the PLAN.

This spec defines framework-level behavior in terms of the substrate
capabilities named in `ADR-0024`. It does not name a platform. The
mapping onto GitHub Issues and Projects — the substrate this repository
itself uses — is `integrations/github-issues-projects.md`. Consumers on
another platform author a binding of their own; consumers on the same
substrate adopt the one that ships.

## Goals

- Establish a single, canonical entry point for all governed work in a
  consumer repo: the work item with its three axes (Type, Label,
  Phase).
- Define three origination paths with explicit trigger sources, first
  actor, first artifact, and first classification for each.
- Define the phase axis as the workflow position indicator, with five
  named phases (Backlog, Approved, In Progress, In Review, Done).
- Define a 2-axis safety-gate model: **Type** determines which safety
  gate applies; **Label** is contextual and content-bearing. Type is
  single-valued and human-mutable only.
- Define the agent-stance rule: every work item action by an autonomous
  or hybrid agent must be preceded by an activity-record entry in the
  documented stance format.
- Define the autonomous gate: agents operating without a human present
  (scheduled, triggered, or delegated) cannot transition a work item's
  phase past a Type-determined checkpoint without human approval.
- Define the Type working definition: feature, bug, task.
- Document the audit trail implications: each transition is
  attributable per `ADR-0018`'s three-layer convention as amended by
  `ADR-0029`.

## Non-Goals

- Defining how trigger handlers are implemented. Consumer repos
  implement these themselves; the framework describes the required
  behavior, not the implementation.
- Naming a work-tracking platform. Platform mechanics live in bindings
  under `integrations/`, per `ADR-0024`.
- Implementing multi-model consensus. Consensus is described in
  FS-0019 and is opt-in per consumer; this spec describes only the
  single-model flow.
- Defining what triggers a scheduled tick. The framework describes how
  an unattended agent behaves; the schedule and detection criteria are
  project-level configuration.
- Replacing `workflows/document-lifecycle.md`. That document governs
  the FS/PLAN/ADR status state machine; this spec adds the work item
  layer above it.
- Adding a new session mode. Meta-modes are defined by `ADR-0022`.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — human maintainer of the
  conventional-agents framework and operator of consumer repos. Needs
  a predictable entry point for all work and clear gates for
  autonomous vs human-driven activity.
- **Agent actors** — run interactively under human guidance and
  autonomously under schedules, triggers, and subagent delegation.
  Need unambiguous role-stance and safety-gate semantics.
- **Future consumer-repo maintainers** — will read this spec to
  understand how to wire their substrate, trigger handlers, and agent
  roles to the framework's prescribed flow.

## Substrate Assumptions

This spec requires the six substrate capabilities defined in
`ADR-0024`. A consumer's platform must supply all six through a binding
before this lifecycle can operate:

| Capability | Used by this spec for |
| --- | --- |
| Work item | The brief; the entry point for all governed work |
| Type (attributable) | Axis 1 — keys the safety gate |
| Phase | Axis 3 — workflow position |
| Parked state | The `question` label's suppression behavior |
| Activity record | Agent-stance entries, in timeline order |
| Trigger source | Origination Path 3; the autonomous gate's context |

Per `ADR-0024`, the Type, parked state, and activity record
capabilities are specified as **attributable**, not enforceable. No
known substrate can technically prevent an agent from editing a Type
field or deleting its own comment. The rules below are rules of conduct
backed by detection and audit. A binding states which of its mappings
are enforced and which are conventional; the reference binding does so
in its §7.

## Three-Axis Work Item Schema

Every work item in a repo adopting this framework carries exactly three
classification axes.

### Axis 1: Type (single-valued)

Exactly one of:

- **`feature`** — new functionality, governance change, or change to
  the exported surface. Requires FS + PLAN. Highest safety gate.
- **`bug`** — deviation from documented behavior. May require FS if
  the fix involves design; may not if the fix is a one-line
  correction. Medium safety gate.
- **`task`** — operational, administrative, or hygiene work
  (dependency bump, doc edit, refactor that does not change
  behavior, infrastructure change). Does not require FS. Low safety
  gate.

**Default rule**: when in doubt, choose the higher-severity Type.
Bumping a dependency is `task`; changing the public API is
`feature`. Fixing a typo in a doc is `task`; fixing wrong documented
behavior is `bug`.

**Mutability**: Type is human-mutable only. An agent may *flag* that
it believes the Type is wrong by posting an activity-record entry, but
the Type change itself requires a human actor. Rationale: Type
determines the safety gate, and an agent should not unilaterally lower
its own gate. Ratified by `ADR-0019`.

### Axis 2: Label (multi-valued)

Six labels classify *what kind of work* and *workflow position*:

- **`enhancement`** — new feature or request, casual description.
  Typically applied by the human when opening the work item.
- **`bug`** — defect report. May be applied by a human or by an
  autonomous agent detecting drift.
- **`documentation`** — documentation-only change. Often paired with
  Type `task`.
- **`spec`** — the work item carries the spec for the work (or
  references an FS file). Indicates it has been elevated beyond a
  casual description.
- **`plan`** — the work item carries the change plan (or references a
  PLAN file). Indicates implementation strategy is set.
- **`question`** — clarification request. The work item is parked,
  awaiting human response. While this label is present, the agent
  MUST NOT perform any transitions (label changes, phase changes, or
  comments) except to remove the `question` label itself when the
  human's response resolves the question. The suppression mechanism
  is agent-side: before any action, the agent checks the label set
  and skips the action if `question` is present. Consumer repos may
  additionally enforce this via handler rejection. Ratified by
  `ADR-0020`.

Labels are multi-valued: a work item can have several. Most commonly it
has one content label (`enhancement`, `bug`, or `documentation`) and one
position label (`spec`, `plan`, or `question`). Some have all three.

**Mutability**: any actor may apply or remove labels, with the rule
that every transition is preceded by an agent-stance declaration if the
actor is an agent.

### Axis 3: Phase (single-valued)

Exactly one of:

- **Backlog** — triaged, no work started. Passive state.
- **Approved** — authorized for work. Triggers the agent's drafting
  action.
- **In Progress** — active work is happening. Expect commits and PRs
  referencing this work item.
- **In Review** — a PR is open against this work item.
- **Done** — closed. PR merged or work abandoned.

Phase is distinct from the work item's open/closed state where the
substrate has one. The phase attribute is authoritative for workflow
position; a binding states how the two are reconciled.

**Mutability**: any actor may transition phase, subject to the
autonomous gate below, with the same agent-stance rule applying to
agent transitions.

## Origination Paths

### Path 1: Human opens a work item with the `enhancement` label

- **Trigger**: human creates a work item, applies label `enhancement`.
- **First artifact**: the brief, as the work item body.
- **First actor**: agent (autonomous), assuming Head Architect role.
- **First action**: agent reads the work item, posts a stance entry
  proposing Type `feature` and label `spec`, and transitions phase →
  Approved. The body then carries the Head Architect's summary of what
  the FS should cover. The Type change itself requires a human actor
  per the Type mutability rule; the agent's entry is the proposal
  mechanism.
- **Next step**: Document Author or Implementer agent drafts the FS in
  a new branch, referencing this work item.

### Path 2: Head Architect conversation produces a Type `feature` work item

- **Trigger**: a conversation between human and agent (Head Architect
  role) reaches a conclusion about new work.
- **First artifact**: work item of Type `feature`, label `spec`, with
  the Head Architect's summary as the body.
- **First actor**: agent (hybrid session).
- **First action**: agent creates the work item with the summary as
  body, no FS yet.
- **Next step**: Document Author or Implementer agent drafts the FS in
  a new branch, referencing this work item.

### Path 3: Autonomous agent creates a work item from drift

- **Trigger**: scheduled tick, detection run, or other autonomous
  signal (e.g., `npm run check:status` failure, dependency scan
  alert).
- **First artifact**: work item of Type `bug` or Type `task`, with the
  detection signal and diagnosis as the body.
- **First actor**: agent (autonomous, no human present), under the
  unattended actor identity `ADR-0021` requires.
- **First action**: agent creates the work item. If Type `bug`,
  applies label `bug`. If Type `task`, may or may not apply a label.
- **Next step**: agent may investigate (if Type `bug`) or execute (if
  Type `task`) up to the autonomous gate.

## Agent Stance on Activity Records

Every work item action by an agent (label change, phase change,
comment) must be preceded by an activity-record entry in the following
format:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

Where:

- `mode` is one of the five session modes from
  `workflows/session-modes.md` (architecture-planning,
  document-authoring, implementation, review, communications), or one
  of the meta-modes `autonomous`, `consensus`, and `review-board`, per
  `ADR-0022`. The value must come from that enumerated set;
  non-enumerated values are invalid. Meta-modes may combine with at most
  one session mode; `consensus` and `review-board` are mutually
  exclusive, since a round is one or the other.
- `role` is the primary role from `guidelines/ROLE_CONTRACT.md`.
- `model` is the model identifier.
- `session-name` is the scheduled job name, trigger event source, or
  interactive session identifier.
- `rationale` is a single-line explanation of why this action is
  being taken.

This is the autonomous-equivalent of the role-transition phrase
required by ROLE_CONTRACT §"Role and session transparency" for
interactive sessions. The entry is the persistent record of the
agent's role stance for that action.

For work-item-creation actions (Path 3 first artifact), the stance
entry is the body itself, with the stance metadata embedded as a
structured block.

Per `ADR-0024`, activity-record entries carrying agent commentary are
not guaranteed non-retractable. Where an action also produced a commit,
the commit's `Agent-Attribution:` trailer is the durable record and
governs.

## Autonomous Gate

An agent operating without a human present (scheduled, triggered, or
delegated) MUST NOT transition a work item's phase past the
Type-determined checkpoint without explicit human approval. Ratified by
`ADR-0019`.

Type-determined checkpoints:

- **Type `feature`**: phase may not advance past Approved without
  human approval. The agent may draft the FS and open a PR, but
  phase to In Progress requires human approval.
- **Type `bug`**: phase may not advance past Approved without human
  approval of the proposed fix. The agent may investigate and
  propose, but the fix PR requires human approval.
- **Type `task`**: phase may not advance past In Progress without
  human approval. The agent may draft and open a PR autonomously,
  but PR-merge to phase Done requires human review at the merge
  gate.

A work item whose Type is unset has not been classified, and the gate
treats it at the most restrictive setting.

This gate composes with `ADR-0012`'s merge gate: even within an
authorized phase range, the agent MUST NOT execute the merge action.
The merge is always human-gated. Per `ADR-0024`, the merge gate is the
only rule in this spec that a substrate can technically enforce; the
rest are conduct rules backed by detection.

## Audit Trail

Every transition by an agent is attributable per `ADR-0018`'s
three-layer convention, as amended by `ADR-0029`:

- **Commit-author identity**: `user.name` carries the model,
  `user.email` carries the actor, for any commits produced as part of
  the work.
- **Co-authored-by**: trailer on commits produced by hybrid sessions.
- **Agent-Attribution**: trailer recording actor, model, role, session.
- **Activity-record stance entry**: the format above is the work-item
  level equivalent. It persists on the timeline.

The timeline is therefore a record of role transitions, with each entry
and label change traceable to a specific model + role + session
combination — subject to the retractability limits noted above.

## Success Criteria

Each bullet MUST be objectively testable.

**Three-axis schema**:

- Given a work item in a project adopting this framework, when its
  metadata is read, then it has exactly one Type value from
  {feature, bug, task}.
- Given a work item, when its labels are read, then they are a subset
  of {enhancement, bug, documentation, spec, plan, question}, with
  zero or more applied.
- Given a work item, when its phase is read, then it has exactly one
  value from {Backlog, Approved, In Progress, In Review, Done}.

**Origination paths**:

- Given Path 1 (human opens `enhancement` work item), when the agent
  reads it, then within the agent's first action cycle the label
  transitions to `spec` and phase transitions to Approved.
- Given Path 2 (Head Architect conversation concludes), when the
  conversation ends, then a work item exists with Type `feature`, label
  `spec`, and phase Approved, whose body matches the conversation's
  conclusion.
- Given Path 3 (autonomous detection), when the detection signal
  fires, then a work item is created with Type `bug` or `task` and a
  body describing the detection signal.

**Agent stance**:

- Given a work item action by an agent, when the preceding activity
  entry is read, then it contains a line matching
  `^agent-stance: mode=([^;]+); role=([^;]+); model=([^;]+); session=([^;]+); rationale=(.+)$`.

**Type mutability**:

- Given a work item, when an agent modifies the Type attribute, then
  the modification is attributable to that agent in the substrate's
  audit record, and detectable by the consumer's monitoring.

**Autonomous gate**:

- Given a work item of Type `feature` and phase Approved, when an
  autonomous agent attempts to transition phase to In Progress,
  then the transition is rejected unless a human actor has approved
  the action.
- Given a work item of Type `task` and phase In Progress, when the
  PR opens, then phase transitions to In Review automatically
  (the only transition an autonomous agent may perform past the
  Type-determined checkpoint, because the PR itself is the
  human-review surface).

**Substrate conformance**:

- Given a consumer repo adopting this lifecycle, when its binding
  document is read, then the binding maps all six `ADR-0024`
  capabilities and states for each whether it is enforced or
  conventional.

**Audit trail**:

- Given a transition by an agent, when the activity record is read,
  then the agent-stance entry precedes the transition by no more than
  one event.

**Unattended actor identity**:

- Given an unattended agent creating or transitioning a work item, when
  the resulting commit or activity entry is read, then the actor
  identity is unambiguous: it identifies as an unattended actor (not
  as the human maintainer and not as an interactive agent), it carries
  `mode=autonomous`, and it cites the job name in `session=<job-name>`.

## Edge Cases

- A work item opens without any labels applied. The agent's first
  action is to propose labels via an activity entry; the human
  confirms.
- A work item's Type is wrong. The agent posts an entry proposing the
  correct Type; the human edits.
- Two agents race to transition the same work item. The substrate or
  handler must serialize transitions; the loser sees its transition
  rejected and posts an entry explaining.
- A scheduled job runs while a human is editing simultaneously. The
  human's edit wins for Type and phase; the agent's action applies to
  label only.
- A work item has been in Approved for 90+ days with no work started.
  Stale detection flags it via an activity entry; the human decides to
  keep, return to Backlog, or close.

## Out of Scope

- The implementation of trigger handlers in consumer repos.
- Platform-specific mechanics. Those belong in `integrations/`
  bindings per `ADR-0024`.
- Multi-model consensus. See FS-0019.
- Schedule and detection configuration. Project-level config.
- Sprint planning, velocity metrics, or time tracking.
- Migration of existing work items to this schema. New work items
  follow it; legacy items are not retroactively reclassified.
- Cross-repo work item propagation. Each repo's work items are local
  to that repo.

## Dependencies

- **A conforming substrate binding.** The consumer's platform must
  supply the six `ADR-0024` capabilities through a binding in
  `integrations/`. `integrations/github-issues-projects.md` ships as
  the reference binding and is the substrate this repository uses.
- **`ADR-0021`** for unattended actor identity, required by Path 3.
- **`ADR-0018` as amended by `ADR-0029`** for commit-level
  attribution. Work-item-level attribution extends it with the
  agent-stance entry format.
- **`ADR-0022`** for the meta-mode vocabulary used in the `mode=`
  field.
- **`workflows/document-lifecycle.md`** — FS/PLAN/ADR status
  transitions continue to follow their existing rules. This spec adds
  the work item layer above.

## Open Questions

None of the following block approval of this FS.

- **Type `task` boundary with the `documentation` label**: when is a
  documentation edit Type `task` vs Type `feature`? Working answer:
  Type `task` if the edit does not change the framework's exported
  surface; Type `feature` if it changes governance, workflow, or
  session-mode documents. Confirm.
- **Multi-item consolidation**: if Path 1 produces three related work
  items, one consolidated Type `feature` item or one per item? Working
  answer: one consolidated item, with the originals linked as "blocked
  by" or "related." Confirm.
- **Auto-add behavior**: where a substrate supports automatically
  adding new work items to a board, do they arrive in Backlog
  regardless of Type and Label? Working answer: yes, with Type unset
  until a human sets it, which the autonomous gate treats at its most
  restrictive. Confirm.

## Rollout / Migration

1. **Update framework docs**: this spec, the associated workflow
   updates (`workflows/document-lifecycle.md`,
   `workflows/session-modes.md`, `guidelines/ROLE_CONTRACT.md`).
2. **Update `skills/git-gh-workflow/SKILL.md`**: add the agent-stance
   entry format and the autonomous-gate rules.
3. **Consumer-repo onboarding**: update `INTEGRATION.md` to document
   how consumer repos select or author a binding, configure trigger
   handlers, and wire agent roles to match this spec.
4. **Test harness**: bats coverage for the agent-stance format, the
   enumerated mode values, the Type-mutability rule, and binding
   conformance.
5. **Documentation**: README.md and AGENTS.md reference this spec and
   FS-0019 as the canonical work item and consensus flow.
