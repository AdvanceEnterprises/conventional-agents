---
type: adr
id: ADR-0014
status: accepted
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0014
  - FS-0015
  - FS-0018
superseded_by: null
updated: 2026-07-28
---

# ADR-0014: Background task governance

## Status

- Accepted

## Context and Problem Statement

Long-running sessions increasingly spawn background tasks — sub-processes or parallel
agent invocations that execute work while the foreground session continues. Examples:
a CI lint run triggered during an Implementation session, a test-generation sub-task
initiated by a Spec Reader session, or a parallel document review spawned by a Review
session.

The framework governs what any agent session is authorized to do through roles, session
modes, and ADR-0012's non-overridable gates. But it has no explicit model for background
tasks. Without one, a background task's authority is undefined — it may inherit
everything the spawning session can do, or it may operate entirely without governance.
Either extreme is wrong.

The question: what authority does a background task inherit, and what governance
constraints apply to it?

## Decision Drivers

- **ADR-0012 gates must apply unconditionally**: No mechanism — including background task
  spawning — should allow agents to bypass the merge gate or other non-overridable safety
  constraints.
- **Background tasks must be auditable**: The record of what a background task did and
  why must be recoverable from the artifact layer (commits, PR comments, log output).
- **Authority must be scoped, not inherited wholesale**: A background task performing a
  narrow operation (running lint, drafting a single document) should not inherit the full
  authority of the spawning session.
- **Minimal blocking**: Governance must not prevent legitimate background tasks from
  doing useful work. The goal is appropriate constraint, not restriction for its own sake.
- **Human escalation remains possible**: If a background task encounters something that
  requires a human decision, it must be able to surface that to the foreground session and
  the human rather than proceeding unilaterally.

## Considered Options

### Option A: Full authority inheritance

Background tasks inherit all of the spawning session's role and authority. No additional
governance applies. The task is treated as an extension of the spawning session.

### Option B: Read-only by default

Background tasks have read access to all artifacts but cannot write, commit, or publish.
All outputs must be delivered back to the foreground session for incorporation.

### Option C: Scoped role with declared authority

The spawning session explicitly declares a role and authority scope for the background
task at spawn time. The background task operates within that role's constraints. ADR-0012
gates apply unconditionally regardless of the declared scope.

### Option D: Independent session with its own PLAN

Each background task is treated as an independent session, requires its own PLAN approval,
and is fully self-governing — same as any other session.

## Decision Outcome

**Chosen option: Option C — scoped role with declared authority.**

### What this means

When a session spawns a background task, it MUST declare:

1. **The role the background task operates under** (one of the six roles from FS-0014).
2. **The artifact scope** — which files or directories the task may modify.
3. **The communication channel** — how the task delivers output back (see below).
4. **Commit permission** — explicitly state `Commit: allowed` if the task may commit;
   omit or write `Commit: no` to require non-committing output.

Where the work has a work item, the declaration is recorded as an agent-stance entry on
its activity record in the format `FS-0018` defines. A background task spawned without a
human present carries `mode=autonomous` per `ADR-0022`, as does any task spawned by a
session that itself carries it.

The background task operates exactly as a full session would if assigned that role —
meaning all role-specific prohibited actions and stop conditions apply — with the
additional constraint that its artifact scope is bounded by the spawn declaration.

ADR-0012 gates apply regardless of declared role or scope. No background task may merge
a pull request. No background task may push to a protected branch without explicit human
authorization.

### What this ADR does not govern: unattended sessions

This ADR governs tasks **spawned by a session** — a subordinate execution whose
authority derives from a parent that declared it. Everything above assumes that parent
exists.

A **scheduled or trigger-fired session has no parent.** A reconciler running on a
schedule, or an agent invoked by a work-item event, was not delegated by a foreground
session; it was configured by a human and fired by infrastructure. It is a **primary
session in its own right that happens to have no human watching**, and it is governed
by `ADR-0013` as a primary plus `FS-0018`'s autonomous gate — not by the background-task
restrictions in this ADR.

The distinction is not academic, because the two shapes have opposite authority
profiles:

| | Background task | Unattended session |
| --- | --- | --- |
| Authority source | Spawn declaration by parent | Job configuration, authored by a human |
| May open a PR | No | Yes, within `FS-0018`'s autonomous gate |
| Reports to | The spawning session | The work item's activity record |
| Failure surfaces via | Parent session | Its own escalation path |

Reading this ADR as covering unattended sessions would forbid something `FS-0018`
Path 3 explicitly permits — an autonomous agent opening a PR for Type `task` work —
and would leave scheduled reconcilers with no authority source at all, since there is
no parent to declare one.

**Composition.** An unattended session may itself spawn background tasks. Those tasks
are governed by this ADR with the unattended session as their parent, and inherit its
`mode=autonomous` declaration. Authority does not widen by being delegated: a task
spawned by an unattended session has at most what that session has.

**Where the declaration lives.** For a background task, the spawn declaration is made
by the parent at spawn time. For an unattended session, the equivalent declaration is
its **job configuration** — role, artifact scope, and permitted actions — authored by a
human when the job is created. That is arguably the stronger of the two, since a human
wrote it rather than an agent scoping its own child.

### Repeating executions must be idempotent

Any task or session that runs more than once over the same state — a scheduled
reconciler above all — MUST NOT repeat an action it has already performed. A reconciler
firing every ten minutes must not post the same stance entry six times an hour.

The check does not need new machinery. `FS-0018`'s activity record is the idempotency
key: the agent reads the timeline, finds its own prior entry for that transition, and
skips. This is a second load-bearing use for a capability otherwise justified as audit.

### Default channel: non-committing output

The default communication channel for a background task is **non-committing**: the task
writes to a designated draft file or delivers output via stdout captured by the
spawning session. Committing to a branch requires `Commit: allowed` in the spawn
declaration and the spawning session reviews those commits before pushing.

This default prevents background task commits from accumulating unreviewed in the
parent branch.

### Background task authority by role

The role declaration at spawn time determines what a background task may do. The "May
commit" column applies only when the spawn declaration includes `Commit: allowed`.

| Declared role | May write files | May commit | May push | May open PR | May post PR comment |
| --- | --- | --- | --- | --- | --- |
| Role 0 — Head Architect | Yes | If declared | No | No | Yes |
| Role 1 — Document Author | Yes | If declared | No | No | Yes |
| Role 2 — Spec Reader / Test Planner | Yes | If declared | No | No | Yes |
| Role 3 — Implementer | Yes | If declared | No | No | Yes |
| Role 4 — Reviewer | No | No | No | No | Yes |
| Role 5 — Communications Lead | Yes | If declared | No | No | Yes |

"May commit" means: may create commits on the branch the spawning session owns and
designated at spawn time, but **only for artifacts that are** (a) inside the declared
artifact scope, (b) permitted outputs for the declared role under FS-0014, and (c)
covered by the foreground session's approved PLAN or explicit human instruction. It does
not mean unrestricted commit access within the branch.

"May push" is blocked for background tasks by default; the spawning session pushes after
reviewing what the background task produced.

### PLAN requirement

Background tasks executing within the scope of an existing approved PLAN do not require
their own PLAN. The spawning session's PLAN covers the task.

`ADR-0027` allows a PLAN to reach `approved` without human action when its `touches:`
is contained in the governing FS's `interfaces:` and touches no reserved path. A
background task inherits such a PLAN's coverage exactly as it inherits a
human-approved one — the route to `approved` does not change what the PLAN authorizes.
It also does not widen it: a self-approved PLAN cannot cover reserved paths, so a
background task under one cannot reach them either.

Background tasks that would expand scope beyond any existing approved PLAN MUST stop and
surface this to the foreground session rather than proceeding. The foreground session then
determines whether a new PLAN is needed.

### Communication back to foreground session and human

A background task MUST communicate its completion state through the declared channel:

- If the task committed changes: through the commit message and any associated PR comment.
- If the task produced output but did not commit: through a named draft file in a
  designated location, or through stdout captured by the spawning session.
- If the task encountered a stop condition: through an explicit escalation message
  delivered to the foreground session, which surfaces it to the human.

A background task MUST NOT silently fail. If it cannot complete its scope, it writes a
summary of what it did, what it encountered, and why it stopped. If no other channel is
available, the foreground session MUST capture the failure summary in its PR update
comment or session summary.

### CI jobs vs. agent background tasks

Automated CI jobs — lint runs, test runners, status checks — are background executions
but are **not** agent background tasks under this ADR unless they have write authority
and can modify artifacts or publish comments. Read-only, pass/fail CI executions are
governed by ADR-0015 Category 1 (governance gates), not by the role authority table
above. The role authority table applies only to agent background tasks that can produce
or modify artifacts.

### Why not the other options?

Option A (full inheritance) allows a background task to take any action the spawning
session can take, with no additional scoping. This creates an escalation path: spawn
a background task to bypass the authority limits the foreground session was being careful
about. It also makes auditing harder — the foreground session's authority and the
background task's authority are indistinguishable in the record.

Option B (read-only) is too restrictive for legitimate use cases. A background task
running tests and producing a test report, or drafting a document section, needs to write
output somewhere. Forcing all writes through the foreground session creates unnecessary
serialization.

Option D (independent session with PLAN) adds too much ceremony for narrow background
tasks. A lint run or a document section draft does not need its own full FS/PLAN
lifecycle.

### Consequences

**Good:**

- ADR-0012 gates remain non-overridable — background task spawning cannot be used to
  circumvent the merge gate or branch protection.
- The scoped role model keeps governance consistent: agents in a background task context
  are governed by the same role rules as agents in any other context.
- Auditable: the spawn declaration, the declared role, the artifact scope, and the
  communication channel are all explicit and appear in the session record.
- PLAN coverage is clear: a background task within an existing PLAN's scope does not
  add governance overhead.

**Bad:**

- The spawning session must make an explicit scope declaration at spawn time. Imprecise
  scope declarations create ambiguity about what the background task was authorized to do.
- Enforcing "no push" for background tasks requires discipline; there is no tooling gate
  that automatically blocks a background task from pushing (outside of branch protection
  rules configured on GitHub).

**Neutral:**

- Background tasks may be implemented as Claude Code sub-agents, as parallel terminal
  sessions, or as CI jobs. The governance model is the same regardless of the
  implementation mechanism. The declared role and scope apply at the authorization layer,
  not at the process layer.

## Coordination Conventions

1. **Spawn declaration format**: A spawning session documents the background task in its
   session state (conversation context or a note in the foreground PR comment).

   ```text
   Background task spawned:
   - Role: [role name]
   - Scope: [file or directory paths]
   - Channel: [draft file path | stdout | PR comment on PR#N]
   - Commit: [allowed | no]
   - Task: [one sentence description]
   ```

2. **Commit attribution**: If the background task produces commits, each commit message
   MUST include trailers identifying it as a background task product:

   ```text
   Background-Task: true
   Spawned-By: [foreground session identifier]
   Task-Scope: [short scope description]
   ```

3. **Naming spawned branches**: If the background task commits to a branch, the branch
   name SHOULD include a token indicating it is a background task product:
   `bg/{parent-branch-name}/{short-description}`

4. **Stop on scope ambiguity**: If the background task encounters a case not covered by
   its scope declaration, it stops and writes an escalation note rather than expanding
   its own scope.

## Validation

We will consider this decision successful if:

1. **Every spawned task carries a declaration.** Role, artifact scope,
   communication channel, and commit permission are stated at spawn time. A
   background task whose authority has to be inferred from what it did was
   spawned without this ADR being applied.
2. **The default holds.** Tasks without an explicit `Commit: allowed` produce
   no commits. Checkable from the commit history against the spawn records.
3. **No background task pushes or opens a PR.** The role-authority table
   forbids both for every role. Violations are visible in the reflog and the
   PR author list.
4. **Unattended sessions are not treated as background tasks.** A scheduled or
   trigger-fired session that reports to a parent, or that declines to open a
   PR on the grounds that this ADR forbids it, has been misclassified — it is a
   primary under `ADR-0013` with `FS-0018`'s autonomous gate applying instead.
   This is the distinction most likely to be got wrong, because the earlier
   draft of this ADR did get it wrong.
5. **Repeating executions are idempotent.** A reconciler running on a schedule
   produces one stance entry per transition, not one per pass. Directly
   observable on any work item a reconciler has visited more than once, and the
   activity record is both the mechanism and the evidence.
6. **Nothing fails silently.** A task that cannot complete its scope leaves a
   summary of what it did, what it encountered, and why it stopped. Absence of
   output from a task known to have run is a failure of this rule regardless of
   whether the task's work was needed.

**Review checkpoint:** when a background task is first spawned by an unattended
session rather than an interactive one. The composition rule — authority does
not widen by being delegated — is stated but has never been exercised.

**Failure condition:** if background tasks are observed committing outside
their declared artifact scope, the scope declaration is decorative. The remedy
is the same as `ADR-0013`'s: a check comparing what was touched against what
was declared, not a firmer restatement of the rule.

## Links

- ADR-0012: Non-overridable gates — apply to background tasks regardless of declared
  scope.
- ADR-0013: Multi-model session coordination — governs unattended sessions as primaries,
  which this ADR does not cover.
- ADR-0021: Cron actor identity — the identity an unattended session commits under.
- ADR-0022: Meta-modes — `mode=autonomous` for tasks and sessions with no human present.
- ADR-0027: PLAN self-approval — a self-approved PLAN covers a background task on the
  same terms as a human-approved one.
- FS-0014: Six-role model — the roles a spawn declaration selects from.
- FS-0015: Session modes.
- FS-0018: Work item lifecycle — the autonomous gate bounding unattended sessions, and
  the activity record serving as idempotency key for repeating executions.
