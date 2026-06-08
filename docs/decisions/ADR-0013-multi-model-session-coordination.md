---
type: adr
id: ADR-0013
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0014
  - FS-0015
superseded_by: null
---

# ADR-0013: Multi-model session coordination model

## Status

- Proposed

## Context and Problem Statement

The framework was designed around a single agent session: one model, one conversation,
working sequentially through a PLAN. In practice, sessions involving different models
running simultaneously are increasingly common — a Sonnet session drafting documents
while an Opus session handles architecture planning, for example. These concurrent
sessions may not be working on the same task, but they have visibility into shared
artifacts and the ability to contribute outputs or compute to each other's work.

The framework currently has no model for this. Without one, multi-model sessions
operate on implicit conventions that can't be audited, can produce conflicts in shared
artifacts, and create ambiguity about which session holds authority over a decision.

The question: how do concurrent sessions of different models coordinate within the
framework's governance model?

## Decision Drivers

- **Human oversight must remain intact**: Adding more sessions must not dilute human
  control. The merge gate, approval gate, and other human-held controls must not be
  weakened by distributing work across multiple sessions.
- **Authority must be unambiguous**: When two sessions touch the same artifact, there
  must be a clear answer to "who has final say?"
- **Auditability**: The coordination model must produce a legible record. Humans
  reviewing the git history or PR comments should be able to understand what each
  session contributed and why.
- **Role coherence**: The six-role model (FS-0014) must remain the primary authority
  assignment mechanism. Multi-session coordination should not create a parallel
  authority system.
- **Minimal new infrastructure**: The framework is document-driven. The coordination
  model should extend existing artifact-based conventions rather than introduce
  real-time channels or message-passing infrastructure.

## Considered Options

### Option A: Fully independent parallel primaries

Each session is a fully independent primary. They coordinate exclusively through
committed artifacts — git commits, PR comments, markdown documents. No real-time
awareness between sessions. Each session operates within its declared role scope.
Conflicts are resolved through the normal artifact-merging process (git).

### Option B: Designated primary with observer-contributors

For any given task (PLAN), one session is designated the **primary**. Other sessions
may have visibility and can contribute outputs — analysis, draft content, review
observations — but the primary incorporates those contributions and holds final
authority over all artifact publication (commits, PR creation, status updates). A
contributing session declares itself as such at the start of its work.

### Option C: Orchestrator-worker

A dedicated orchestrator session manages task distribution across worker sessions.
Workers have narrowly scoped authority. The orchestrator synthesizes results and
makes final decisions. Workers cannot publish artifacts independently.

### Option D: Peer mesh with conflict resolution

All sessions are equal peers. They coordinate through a shared task queue and a
locking mechanism. Conflicts are resolved by timestamp or explicit yield signals.

## Definitions

**Governed artifact**: Any file whose changes are constrained by an FS, PLAN, ADR, role
contract, lifecycle workflow, CI gate, or README index requirement. This includes
governance documents, workflow documents, source files, tests, scripts, package metadata,
CI configuration, and generated indexes when those files are inside the declared task
scope.

## Decision Outcome

**Chosen option: Option B for same-task coordination; Option A for different-task
coordination. These are the two modes of multi-session operation.**

### Mode 1 — Parallel independent primaries (different tasks)

When sessions are working on distinct tasks (different PLANs, different scopes), each
session is a fully independent primary. They coordinate only through the shared
artifact layer (git, PR comments, governance documents). Each session operates within
its declared role and session mode.

Every parallel primary MUST declare at session start:

- **PLAN ID** (or governing task identifier, e.g., a GitHub issue number)
- **Branch name** being used for this task
- **Artifact scope** — which files or directories this session may modify
- **Known excluded artifacts** — any files in the branch that are explicitly out of
  scope for this session

Rule: Parallel primaries MUST NOT modify the same governed artifacts concurrently. If
two primaries need to touch the same file, they must be sequenced, not parallelized.
On discovering an overlap, both sessions stop and escalate to the human.

### Mode 2 — Primary + contributor (same task)

When sessions are working on the same task, one session is designated the **primary**
and holds final authority. Other sessions are **contributors**. A contributor:

- May read all artifacts authorized for the primary task scope.
- May produce outputs (draft content, analysis, review observations, suggested edits).
- Delivers outputs to the primary through a defined channel: PR comments, a designated
  draft document, or inline suggestions on a branch the primary owns.
- Does NOT commit directly to the primary's working branch.
- Does NOT open PRs on behalf of the task.
- Does NOT make status transitions on governed documents.

The primary incorporates contributor outputs at its discretion, with attribution in the
commit message or PR description.

### Why not Option C or D?

Option C (orchestrator-worker) introduces a new privileged role — the orchestrator —
that sits outside the six-role model. This undermines role coherence and adds
infrastructure complexity without a clear need.

Option D (peer mesh) has no clear authority hierarchy, which makes auditing difficult
and creates race conditions on shared artifacts. It also conflicts with ADR-0012's
requirement that a single identity be responsible for any given git action.

### Consequences

**Good:**

- Human oversight is preserved: one primary session holds all commit/PR authority for
  a given task.
- Role model is unchanged: primary and contributor sessions both declare a role from
  the six-role taxonomy; the contributor role simply has restricted output channels.
- Auditable: contributor outputs flow through PR comments or named draft documents,
  leaving a visible record of what each session contributed.
- Minimal infrastructure: no message-passing or shared state required beyond existing
  git and GitHub primitives.

**Bad:**

- The primary/contributor designation must be made explicitly at session start; if it
  isn't, two sessions may both operate as primaries on the same task.
- Contributor outputs that aren't incorporated are lost unless the contributor posts
  them as PR comments (which become part of the permanent record).
- Parallel primaries on different tasks must be careful about artifact boundaries;
  the framework relies on human discipline to enforce this, not tooling.

**Neutral:**

- A session's model (Sonnet, Opus, GPT-4, local model) is irrelevant to its mode
  designation. A contributor can be more capable than the primary. The designation
  is about task authority, not capability.

## Coordination Conventions

1. **Declare at session start**: A contributor session begins with a transparency
   statement naming the primary session and its contributor scope.
   Example: "Operating as contributor to [primary session/task]. My outputs will be
   delivered as PR comments on [PR URL] and will not be committed directly."

2. **Artifact boundaries for parallel primaries**: Each primary session declares its
   PLAN scope in its opening transparency statement. A session MUST NOT modify
   artifacts outside its declared scope without explicit human instruction.

3. **Pre-commit conflict check**: Before committing, a primary session MUST verify that
   no files in its declared artifact scope have changed upstream since session start. If
   overlap is detected, the session stops and escalates rather than resolving the
   conflict unilaterally.

4. **Attribution**: When the primary incorporates contributor output, the commit message
   or PR description notes the contribution using trailers that do not conflict with
   GitHub's `Co-Authored-By` convention (which requires a real name + email identity):

   ```text
   Assisted-By: [model name or session identifier]
   Contributor-Session: [session identifier or PR comment URL]
   ```

5. **Conflict escalation**: If two sessions discover they need to modify the same
   artifact, they stop and escalate to human. Neither session proceeds unilaterally.

## Links

- ADR-0011: Multi-identity GitHub model (agent-committer vs. agent-reviewer)
- ADR-0012: Non-overridable gates (apply to all sessions, primary and contributor)
- FS-0014: Six-role model (role taxonomy applies to all sessions)
- FS-0015: Session modes (each session declares a mode independently)
