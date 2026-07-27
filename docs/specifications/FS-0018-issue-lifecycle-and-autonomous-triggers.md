---
type: feature-spec
id: FS-0018
status: draft
title: Issue lifecycle and autonomous triggers for governed work
owner: ajoeofalltrades
test_required: true
interfaces:
  - "workflows/session-modes.md"
  - "workflows/document-lifecycle.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "skills/git-gh-workflow/SKILL.md"
  - "docs/specifications/README.md"
  - "test/FS-0018/issue-lifecycle.bats"
related_adrs:
  - ADR-0018
  - ADR-0012
supersedes: []
requires: []
tags: [workflow, triggers, agent-orchestration, github-projects]
created: 2026-07-27
updated: 2026-07-27
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

# Feature Spec: Issue Lifecycle and Autonomous Triggers for Governed Work

## Status

- Draft

## Plan Status

- **Not yet drafted.** Per `workflows/document-lifecycle.md`, PLANs
  are drafted after the FS is approved and immediately before
  implementation. Drafting a PLAN for a `draft` FS would be
  premature.
- Open questions blocking PLAN drafting are listed in the
  "Open Questions" section below.

## Summary

Define how governed work originates in a project that adopts
`conventional-agents`, including the three origination paths (human
Issue, Head Architect summary, autonomous agent detection), the three-axis
classification of every Issue (Type, Label, Status), and the agent
behavior at each lifecycle transition.

The first governed artifact for any new piece of work is an **Issue**,
not an FS or ADR. The Issue is the brief; the FS is the contract;
ADRs surface only if a binding decision is needed; the PLAN comes
after the FS is approved; implementation follows the PLAN.

This spec defines the framework-level behavior. Consumer repos that
adopt this pattern implement the GitHub webhook handlers and project
board configuration that materializes the behavior.

## Goals

- Establish a single, canonical entry point for all governed work in a
  consumer repo: the GitHub Issue with its three axes (Type, Label,
  Status).
- Define three origination paths with explicit trigger sources, first
  actor, first artifact, and first classification for each.
- Define the GitHub Project Status field as the workflow phase
  indicator, with five named phases (Backlog, Approved, In Progress,
  In Review, Done) per FS-0011.
- Define a 2-axis safety-gate model: **Type** determines which safety
  gate applies; **Label** is contextual/content. Type is single-valued
  and human-mutable only.
- Define the agent-stance-on-Issue-comment rule: every Issue action by
  an autonomous or hybrid agent must be preceded by an Issue comment
  in the documented stance format.
- Define the autonomous gate: agents operating without a human
  present (cron, webhook, subagent delegation) cannot transition an
  Issue's Status past a Type-determined checkpoint without human
  approval.
- Define the Type `task` working definition: feature, bug, task.
- Document the audit trail implications: each Issue transition is
  attributable per ADR-0018's three-layer convention (commit-author
  email, Co-authored-by, Agent-Attribution).

## Non-Goals

- Defining how the GitHub webhook handlers are implemented. Consumer
  repos implement these themselves; the framework describes the
  required behavior, not the implementation.
- Implementing multi-model consensus. Multi-model consensus is
  described in FS-0019 and is opt-in per consumer; this spec only
  describes the single-model flow.
- Defining what triggers a cron tick. The framework describes how a
  cron-triggered agent behaves; the schedule and what triggers
  detection are project-level configuration.
- Replacing `workflows/document-lifecycle.md`. That document governs
  the FS/PLAN/ADR status state machine; this spec adds the Issue
  layer above it.
- Modifying `workflows/session-modes.md` to add a new session mode.
  This spec describes Issue-level agent behavior; new modes (e.g.,
  "Autonomous / unattended") are a separate change.
- Mandating a specific GitHub project board structure. FS-0011
  defines the standard columns; this spec assumes those columns exist
  but does not redefine them.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — human maintainer of the
  conventional-agents framework and operator of consumer repos. Needs
  a predictable entry point for all work and clear gates for
  autonomous vs human-driven activity.
- **Hermes Agent** — runs interactively under Joey's guidance and
  autonomously under cron, webhooks, and subagent delegation. Needs
  unambiguous role-stance and safety-gate semantics.
- **Future consumer-repo maintainers** — will read this spec to
  understand how to wire their GitHub project board, webhook
  handlers, and agent roles to the framework's prescribed flow.

## Three-Axis Issue Schema

Every Issue in a repo adopting this framework carries exactly three
classification axes:

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
it believes the Type is wrong by posting an Issue comment, but the
Type change itself requires a human actor. Rationale: Type determines
safety gate, and an agent should not unilaterally lower its own
gate by editing its own Type. This rule is stated as a proposed
default; it will be ratified as a binding ADR when this FS moves
to approved (see "Notes for Future ADRs").

### Axis 2: Label (multi-valued)

Six labels classify *what kind of work* and *workflow position*:

- **`enhancement`** — new feature or request, casual description.
  Typically applied by the human when opening the Issue.
- **`bug`** — defect report. May be applied by a human or by an
  autonomous agent detecting drift.
- **`documentation`** — documentation-only change. Often paired with
  Type `task`.
- **`spec`** — the Issue carries the spec for the work (or
  references an FS file). Indicates the Issue has been elevated
  beyond a casual description.
- **`plan`** — the Issue carries the change plan (or references a
  PLAN file). Indicates implementation strategy is set.
- **`question`** — clarification request. The Issue is parked,
  awaiting human response. While this label is present, the agent
  MUST NOT perform any Issue transitions (label changes, Status
  changes, or comments) except to remove the `question` label
  itself when the human's response resolves the question. The
  suppression mechanism is agent-side: before any Issue action, the
  agent checks the label set and skips the action if `question` is
  present. Consumer repos may additionally enforce this via
  webhook handler rejection.

Labels are multi-valued: an Issue can have multiple. Most commonly,
an Issue has one content label (`enhancement`, `bug`, or
`documentation`) and one position label (`spec`, `plan`, or
`question`). Some have all three.

**Mutability**: any actor (human or agent) may apply or remove
labels, with the rule that every transition is preceded by an
agent-stance declaration comment if the actor is an agent.

### Axis 3: Status (single-valued, lives on the GitHub Project)

Exactly one of (per FS-0011):

- **Backlog** — triaged, no work started. Passive state.
- **Approved** — authorized for work. Triggers the agent's drafting
  action.
- **In Progress** — active work is happening. Expect commits and PRs
  referencing this Issue.
- **In Review** — a PR is open against this Issue.
- **Done** — closed. PR merged or work abandoned.

**Mutability**: any actor may transition Status, with the same
agent-stance comment rule applying to agent transitions.

## Origination Paths

### Path 1: Human opens Issue with `enhancement` label

- **Trigger**: human opens Issue, selects label `enhancement`.
- **First artifact**: Issue body contains the casual description.
- **First actor**: Hermes Agent (autonomous), assuming Head
  Architect role.
- **First action**: agent reads Issue, posts an Issue comment
  suggesting Type `feature` and label `spec`, and transitions
  Status → Approved. The Issue body now carries the Head
  Architect's summary of what the FS should cover. (The Type
  change itself requires a human actor per the Type mutability
  rule below; the agent's comment is the suggestion mechanism.)
- **Next step**: Document Author or Implementer agent (human-in-loop
  or autonomous) drafts the FS in a new branch, referencing this
  Issue.

### Path 2: Head Architect conversation produces Type `feature` Issue

- **Trigger**: a Hermes GUI or web-interface conversation between
  human and agent (Head Architect role) reaches a conclusion about
  new work.
- **First artifact**: Issue of Type `feature`, label `spec`, with
  the Head Architect's summary as the Issue body.
- **First actor**: Hermes Agent (hybrid session).
- **First action**: agent creates the Issue with the summary as body,
  no FS yet.
- **Next step**: Document Author or Implementer agent drafts the FS
  in a new branch, referencing this Issue.

### Path 3: Autonomous agent creates Issue from drift

- **Trigger**: cron tick, scheduled detection, or other autonomous
  signal (e.g., `npm run check:status` failure, dependency scan
  alert).
- **First artifact**: Issue of Type `bug` or Type `task`, with the
  detection signal and diagnosis as the Issue body.
- **First actor**: Hermes Agent (autonomous, no human present).
- **First action**: agent creates the Issue. If Type `bug`, applies
  label `bug`. If Type `task`, may or may not apply a label.
- **Next step**: agent may investigate (if Type `bug`) or execute
  (if Type `task`) up to the autonomous gate (see below).

## Agent Stance on Issue Comments

Every Issue action by an agent (label change, Status change, comment)
must be preceded by an Issue comment in the following format
(proposed default; subject to ADR ratification):

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

Where:

- `mode` is one of the five session modes from
  `workflows/session-modes.md` (architecture-planning,
  document-authoring, implementation, review, communications), or
  one of the additional mode values defined by FS-0019
  (consensus) and this spec (autonomous, for cron/webhook-fired
  agents without a human present). The mode value must be one of
  this enumerated set; non-enumerated values are invalid.
- `role` is the primary role from `guidelines/ROLE_CONTRACT.md`.
- `model` is the model identifier (per ADR-0018).
- `session-name` is the cron job name, webhook event source, or
  interactive session identifier.
- `rationale` is a single-line explanation of why this action is
  being taken.

This is the autonomous-equivalent of the role-transition phrase
required by ROLE_CONTRACT §"Role and session transparency" for
interactive sessions. The comment is the persistent record of the
agent's role stance for that action.

For Issue-creation actions (Path 3 first artifact), the stance
comment is the Issue body itself, with the agent-stance metadata
embedded as a structured comment block.

## Autonomous Gate (Proposed Default)

An agent operating without a human present (cron, webhook, subagent
delegation) MUST NOT transition an Issue's Status past the
Type-determined checkpoint without explicit human approval.
This rule is stated as a proposed default; it will be ratified
as a binding ADR when this FS moves to approved (see "Notes for
Future ADRs").

Type-determined checkpoints:

- **Type `feature`**: Status may not advance past Approved without
  human approval. The agent may draft the FS and open a PR, but
  Status → In Progress requires human approval.
- **Type `bug`**: Status may not advance past Approved without
  human approval of the proposed fix. The agent may investigate and
  propose, but the fix PR requires human approval.
- **Type `task`**: Status may not advance past In Progress without
  human approval. The agent may draft and open a PR autonomously,
  but PR-merge → Status → Done requires human review at the merge
  gate (per ADR-0012).

This gate composes with ADR-0012's merge gate: even within an
authorized Status range, the agent MUST NOT execute the merge
action. The merge is always human-gated.

## Audit Trail

Every Issue transition by an agent is attributable per ADR-0018's
three-layer convention:

- **Commit-author email**: the agent's `user.email` for any commits
  produced as part of Issue work.
- **Co-authored-by**: trailer on commits produced by hybrid
  sessions.
- **Agent-Attribution**: trailer on commits produced by the agent,
  recording model, role, session.
- **Issue-comment agent-stance**: the comment format above is the
  Issue-level equivalent. It persists on the Issue timeline.

The Issue timeline is therefore a complete record of role
transitions, with each comment and label change traceable to a
specific model + role + session combination.

## Success Criteria

Each bullet MUST be objectively testable.

**Three-axis schema**:

- Given an Issue in a project adopting this framework, when its
  metadata is read, then it has exactly one Type value from
  {feature, bug, task}.
- Given an Issue, when its labels are read, then they are a subset
  of {enhancement, bug, documentation, spec, plan, question}, with
  zero or more applied.
- Given an Issue on a project board, when its Status field is read,
  then it has exactly one value from {Backlog, Approved, In
  Progress, In Review, Done}.

**Origination paths**:

- Given Path 1 (human opens `enhancement` Issue), when the agent
  reads the Issue, then within the agent's first action cycle the
  Issue's label transitions to `spec` and Status transitions to
  Approved.
- Given Path 2 (Head Architect conversation concludes), when the
  conversation ends, then an Issue exists with Type `feature`, label
  `spec`, and Status `Approved`, whose body matches the
  conversation's conclusion.
- Given Path 3 (autonomous detection), when the detection signal
  fires, then an Issue is created with Type `bug` or `task` and a
  body describing the detection signal.

**Agent stance**:

- Given an Issue action by an agent, when the action's preceding
  Issue comment is read, then it contains a line matching
  `^agent-stance: mode=([^;]+); role=([^;]+); model=([^;]+); session=([^;]+); rationale=(.+)$`.

**Type mutability**:

- Given an Issue, when an agent attempts to change the Type field,
  then the change is rejected by the system (or, if not enforced
  technically, the agent's audit log records the attempt and the
  human is informed via Issue comment).

**Autonomous gate**:

- Given an Issue of Type `feature` and Status `Approved`, when an
  autonomous agent attempts to transition Status to `In Progress`,
  then the transition is rejected unless a human actor has approved
  the action (e.g., by commenting `approve` on the Issue, or by
  configuring the cron job to allow this specific transition).
- Given an Issue of Type `task` and Status `In Progress`, when the
  PR opens, then Status transitions to `In Review` automatically
  (this is the only transition an autonomous agent may perform
  past the Type-determined checkpoint, because the PR itself is the
  human-review surface).

**Audit trail**:

- Given an Issue transition by an agent, when the Issue timeline is
  read, then the agent-stance comment precedes the transition by no
  more than one Issue event (label change, Status change, comment).

**Cron actor identity (blocker for Path 3)**:

- Given a cron-fired agent creating or transitioning an Issue, when
  the resulting commit or Issue comment is read, then the actor
  identity is unambiguous: it identifies as a cron-fired actor (not
  as Joey or as an interactive agent), it carries an
  `Agent-Attribution:` trailer or comment with `mode=autonomous`,
  and it cites the cron job name in `session=<cron-job-name>`.

## Edge Cases

- An Issue opens without any labels applied. The agent's first
  action is to suggest labels via Issue comment; the human
  confirms.
- An Issue's Type is wrong. The agent posts an Issue comment
  suggesting the correct Type; the human edits.
- Two agents are racing to transition the same Issue. The webhook
  handler must serialize transitions; the loser sees its transition
  rejected and posts an Issue comment explaining.
- A cron job runs while a human is editing the Issue simultaneously.
  The human's edit wins for Type and Status; the agent's action is
  applied to label only.
- An Issue has been in `Approved` for 90+ days with no work
  started. Stale-Issue detection (cron) flags it via Issue comment;
  the human decides to keep, transition to `Backlog`, or close.

## Out of Scope

- The implementation of webhook handlers in consumer repos.
  Consumer repos wire their own handlers; the framework describes
  required behavior.
- Multi-model consensus. See FS-0019.
- Cron schedule and detection configuration. Project-level config.
- Sprint planning, velocity metrics, or time tracking. FS-0011's
  board does not extend to those concerns.
- Migration of existing Issues to the new schema. New Issues
  follow the schema; legacy Issues are not retroactively
  reclassified (per the framework's append-only treatment of
  historical state).
- Cross-repo Issue propagation. Each repo's Issues are local to
  that repo.

## Dependencies

- GitHub Issues with a Type classification mechanism. This may be
  GitHub's native Issue Types (org-level beta feature), a custom
  single-select field on the GitHub Project board (as used by
  FS-0011's `Doc Type` field), or a consumer-implemented
  convention (e.g., a `type:` prefix in the Issue title). The
  framework describes the required behavior; consumer repos
  choose the mechanism that matches their GitHub plan and org
  settings. See Open Question \"Type field mechanism\" below.
- GitHub Labels API for label management.
- GitHub Projects v2 for the Status field. Status transitions
  require `gh project` CLI or GraphQL API access.
- Per ADR-0018: `user.email`, `Co-authored-by:`, and
  `Agent-Attribution:` conventions for commit-level attribution.
  Issue-level attribution extends this with the agent-stance
  comment format.
- Per FS-0011: GitHub Projects v2 with the five Status columns.
- Per `workflows/document-lifecycle.md`: FS/PLAN/ADR status
  transitions continue to follow their existing rules. This spec
  adds the Issue layer above.

## Open Questions

- **Type `task` boundary with `documentation` label**: when is a
  documentation edit Type `task` vs Type `feature`? My read: Type
  `task` if the edit does not change the framework's exported
  surface; Type `feature` if it changes governance, workflow, or
  session-mode documents. Confirm.
- **Cron job identity**: when a cron job runs and creates an Issue,
  what `user.email` and GitHub identity applies? The active
  service-account identity? An explicitly-configured
  `cron@tais-den.dev` style? This needs ADR-0018's commit-attribution
  layer to extend to cron-fired actors. **This is a blocker for
  Path 3 implementation; resolve before approving this FS.** See
  Success Criterion "Cron actor identity" below.
- **Type field mechanism**: GitHub does not have a universal
  single-valued "Type" field on Issues. The mechanism varies by
  GitHub plan: native Issue Types (org-level beta), custom
  Project fields, or a consumer-implemented convention. The spec
  should clarify which mechanism(s) the framework recommends and
  whether the framework provides a fallback convention for repos
  without org-level Issue Types. **This affects portability of
  the convention across consumer repos.**
- **Multi-Issue consolidation**: if Path 1 produces three related
  consolidated Type `feature` Issue or one per Issue? My read: one
  consolidated Issue, with the three original Issues linked as
  "blocked by" or "related." Confirm.
- **Auto-add workflow**: per FS-0011, auto-add to project is
  enabled. Does this mean new Issues automatically appear on the
  project board in Backlog, regardless of Type/Label? Confirm.

## Rollout / Migration

1. **Update framework docs**: add this spec, the associated
   workflow updates (`workflows/document-lifecycle.md`,
   `workflows/session-modes.md`, `guidelines/ROLE_CONTRACT.md`),
   and any new ADRs surfaced by this spec.
2. **Update `skills/git-gh-workflow/SKILL.md`**: add the
   agent-stance comment format and the autonomous-gate rules.
3. **Consumer-repo onboarding**: update `INTEGRATION.md` to
   document how consumer repos configure their GitHub project
   board, webhook handlers, and agent roles to match this spec.
4. **Test harness**: add a bats test (or equivalent) verifying
   the agent-stance comment format regex and the Type-mutability
   rule.
5. **Documentation**: README.md and AGENTS.md should briefly
   reference this spec and FS-0019 as the canonical Issue and
   consensus flow.

## Notes for Future ADRs

This spec is likely to surface the following binding decisions,
which would become ADRs in follow-up:

- **Type immutability by agents**: agent-mutable Type is forbidden.
- **Autonomous gate semantics**: Type-determined checkpoints where
  agents cannot advance Status without human approval.
- **`question` label suppression**: agent actions are suppressed
  while `question` is applied, even within an authorized Status
  range.

These should be drafted as ADRs only after this FS is approved and
implementation begins, to follow the framework's own dogfooded
discipline (FS first, ADR if a binding decision surfaces).\n
