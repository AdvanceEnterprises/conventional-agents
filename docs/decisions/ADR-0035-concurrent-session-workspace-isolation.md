---
type: adr
id: ADR-0035
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
  - FS-0019
superseded_by: null
created: 2026-08-31
updated: 2026-08-31
---

# ADR-0035: Concurrent-session workspace isolation

## Status

- Proposed

## Context and Problem Statement

The framework was designed around a single agent session (ADR-0013). In
practice, multiple sessions — interactive, review, and unattended (cron) —
now operate concurrently on the same repositories. ADR-0013 governs
*authority* (who has final say over an artifact) but not *workspace
mechanics*: nothing constrains how concurrent sessions share the working
tree on disk.

Two failure modes have been observed in production:

1. **Stale-checkout corruption.** A session rebased a branch from a local
   checkout that had silently drifted from the remote; the rebase dropped a
   commit that existed only in the stale local state. The push succeeded
   (`--force-with-lease` matched the tracking ref) and the commit was lost
   from the branch until recovered from the object store.
2. **Stash-pop contamination.** A review session ran `git stash` /
   `git stash pop` in a shared checkout and pulled a sibling session's
   uncommitted work into the tree, leaving merge-conflict markers in files
   the review session had never touched.

Both failures share one root cause: **multiple sessions mutating the same
working tree**. The framework's governance model assumes sessions can
operate in parallel (FS-0018, FS-0019); the workspace model must not
contradict that assumption. FS-0018/FS-0019 authorize concurrent sessions
but do not prescribe workspace mechanics — that gap is what this ADR fills.

## Decision Drivers

- **Correctness** — a session's git operations must never corrupt another
  session's state.
- **Auditability** — the coordination model must produce a legible record
  (ADR-0013).
- **Tool-agnosticism** — the rule must hold for any consumer, regardless
  of execution backend (bare host, container, VM).
- **Low operational cost** — the rule must be cheap to follow; expensive
  isolation is skipped in practice.
- **Human sovereignty** — the human must retain a mutable, single-source
  surface that agents do not silently overwrite; rule 4 follows from this
  driver, not as an after-the-fact carve-out.

## Considered Options

### Option A — Worktree-only mutations (chosen)

Every agent session performs all mutations in a per-session git worktree
(`git worktree add /tmp/<topic>-<n> <branch>` — the path is an example;
production orchestrators should use a persistent or convention-based
directory such as `/workspace`); the shared checkout is read-only for
agents. `git stash` in a shared checkout is forbidden.

- **Pros:** Pure git, no infrastructure; works on any host; worktrees are
  cheap (no full clone); the shared checkout stays clean for the human.
- **Cons:** Requires discipline — a session that forgets the rule can still
  corrupt state; no mechanical enforcement.

### Option B — Per-session sandbox instances

Each session gets its own container/VM sandbox with its own workspace
copy. Strongest isolation (filesystem, privileges, resources).

- **Pros:** Mechanical isolation; also contains privilege and resource
  blast radius.
- **Cons:** Requires a container runtime on the host; workspace copies
  drift from each other; higher operational cost; not available to every
  consumer.

### Option C — Serialize all sessions

One session at a time per repository (lock file or queue).

- **Pros:** Simple to reason about.
- **Cons:** Kills the parallelism the framework explicitly supports
  (FS-0018/0019 cohorts); a long-running session blocks all others.

## Decision Outcome

**Chosen: Option A — worktree-only mutations — as the framework-level
rule, with Option B as the recommended mechanical enforcement where a
container runtime is available.**

1. **Every agent session MUST perform all repository mutations in a
   per-session worktree.** The shared checkout is read-only for agents.
   This includes branch creation, rebases, commits, and pushes.
2. **`git stash` in a shared checkout is forbidden.** If a tree is dirty,
   use a worktree instead.
3. **Where a container runtime is available, sessions SHOULD run in
   per-session sandbox instances** (Option B) that mount their own
   worktrees — this makes the isolation mechanical and adds privilege and
   resource containment. The sandbox is an enforcement mechanism for this
   ADR, not a replacement for it: a sandbox that mounts the shared
   checkout still violates rule 1. Option B is **recommended but not
   required** — the base rule (worktree-only mutations) stands alone on
   any host without a container runtime.
4. **The human's checkout is the shared checkout.** Agents treat it as
   read-only; the human may mutate it freely.

### Per-agent sandbox instance design (rule 3 elaboration)

The intent of rule 3 is **one sandbox instance per agent session**, not
one shared sandbox:

- **Session-scoped instances.** The interactive session, each unattended
  (cron) job, and each review session gets its own sandbox container
  instance. A single shared sandbox would reproduce the shared-checkout
  hazard inside a container — two sessions mutating the same mounted
  workspace corrupt each other exactly as before.
- **Per-session worktree mounts.** Each sandbox mounts its own worktree(s)
  at its workspace path (e.g. `/workspace`). The shared checkout is never
  mounted into any sandbox.
- **Resource caps per instance.** CPU/memory limits are applied per
  sandbox, so one runaway session cannot starve the host or its siblings
  (this is the resource-containment half of the design).
- **Privilege containment per instance.** Each sandbox runs as a
  restricted user; the host filesystem outside the mounted worktrees is
  not writable from inside the sandbox.
- **Mechanism is an implementation detail.** Whether the execution
  backend supports container-per-session natively, or the orchestrator
  spawns one container per session, is a consumer/implementation choice
  (see feral-fleet PLAN-0024, *Hermes-Agent ↔ Podman integration*). The
  binding part is the invariant:
  *one session, one sandbox, one worktree* — never a shared workspace
  inside a container.

## Consequences

### Positive

- Removes the shared-working-tree hazard that caused the observed
  stale-checkout and stash-pop incidents.
- Zero infrastructure cost for the base rule (git worktrees are built-in).
- Composes with the sandboxed-execution direction (feral-fleet FS-0022,
  Hermes-Agent ↔ Podman integration): the sandbox design must mount
  per-session worktrees, which this ADR constrains.

### Negative

- Requires agent discipline; a session that violates rule 1 reintroduces
  the hazard.
- Worktrees add a small operational step to every session's setup.

### Neutral

- The human's checkout remains the single mutable shared surface; the
  human is the arbiter of conflicts there.

## Validation

- No observed stale-checkout or stash-pop incidents for 30 days after
  adoption (target: 30 incident-free days across consumer repos).
- Review sessions and cron sessions operate exclusively in worktrees
  (auditable via `git worktree list`).
- Sandboxed-execution implementations (e.g., feral-fleet FS-0022) mount
  per-session worktrees, not the shared checkout.

## Links

- Related ADRs: ADR-0013 (multi-model session coordination), ADR-0016
  (consumer conventions — this ADR is consumed as a convention by
  consumer repos, which is why the relationship is listed)
- Related specs: FS-0018 (work item layer), FS-0019 (consensus)
- External references: git-worktree(1)
