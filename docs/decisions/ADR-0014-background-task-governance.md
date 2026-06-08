---
type: adr
id: ADR-0014
status: proposed
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0014: Background task governance

## Status

- Proposed

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
3. **The communication channel** — how the task delivers output back (commit on a named
   branch, PR comment, stdout log, a draft file).

The background task operates exactly as a full session would if assigned that role —
meaning all role-specific prohibited actions and stop conditions apply — with the
additional constraint that its artifact scope is bounded by the spawn declaration.

ADR-0012 gates apply regardless of declared role or scope. No background task may merge
a pull request. No background task may push to a protected branch without explicit human
authorization.

### Background task authority by role

The role declaration at spawn time determines what a background task may do:

| Declared role | May commit | May push | May open PR | May post PR comment |
| --- | --- | --- | --- | --- |
| Role 0 — Head Architect | Yes (branch) | No | No | Yes |
| Role 1 — Document Author | Yes (branch) | No | No | Yes |
| Role 2 — Spec Reader / Test Planner | Yes (branch) | No | No | Yes |
| Role 3 — Implementer | Yes (branch) | No | No | Yes |
| Role 4 — Reviewer | No | No | No | Yes |
| Role 5 — Communications Lead | Yes (branch) | No | No | Yes |

"May commit (branch)" means: may commit to the branch the spawning session owns and
designated at spawn time — not to any other branch, and never to trunk directly.
"May push" is blocked for background tasks by default; the spawning session pushes after
reviewing what the background task produced.

### PLAN requirement

Background tasks executing within the scope of an existing approved PLAN do not require
their own PLAN. The spawning session's PLAN covers the task.

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
summary of what it did, what it encountered, and why it stopped.

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
   - Channel: [how output is returned]
   - Task: [one sentence description]
   ```

2. **Naming spawned branches**: If the background task commits to a branch, the branch
   name SHOULD include a token indicating it is a background task product:
   `bg/{parent-branch-name}/{short-description}`

3. **Stop on scope ambiguity**: If the background task encounters a case not covered by
   its scope declaration, it stops and writes an escalation note rather than expanding
   its own scope.

## Links

- ADR-0012: Non-overridable gates (apply to all sessions including background tasks)
- ADR-0013: Multi-model session coordination (parallel primaries and contributor model)
- FS-0014: Six-role model (role taxonomy governs background task authority)
- FS-0015: Session modes (background tasks may operate in a session mode; declare at
  spawn time)
