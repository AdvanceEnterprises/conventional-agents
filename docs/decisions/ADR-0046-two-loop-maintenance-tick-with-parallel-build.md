---
type: adr
id: ADR-0046
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0051
superseded_by: null
---

# ADR-0046: Two-loop maintenance tick with parallel build

## Status

- Proposed

## Context and Problem Statement

The maintenance tick (the `conventional-agents-maintenance` skill, cron-fired
every 20 minutes under ADR-0021) is a single eight-phase loop that builds **at
most one** feature per tick, round-robin across the three in-scope repos, and
only when idle. That one-build-per-tick constraint was calibrated for a
sequential, single-model execution environment: one implementation per fire, so
throughput was bound by the tick's cadence and by the round-robin.

Two changes make that constraint wrong. First, the underlying Ollama cloud was
upgraded to dispatch 5-7 sub-agents concurrently, so implementation throughput
is no longer bound by sequential execution. Second, ADR-0045 established the run
as the unit of bounded autonomous work and the human's board-status move as the
go signal; the tick's build phase predates that framing and names its trigger
only as "approval continuation" rather than a governed run.

The tick also conflates two cadences that want to differ. Detection, review, and
promotion are cheap and drift-sensitive — they want to run often. Implementation
is expensive and was serialized — it wants to run rarely but in parallel. Running
everything at 20 minutes forces implementation to be one-at-a-time, so the build
loop inherits the detection cadence and cannot exploit the new concurrency.

## Decision Drivers

1. **Preserve the fast detection/promotion cadence.** Governance honesty — drift
   detection, board reconciliation, and the double-review/promote hand-off —
   depends on running often.
2. **Use the upgraded concurrency** to raise implementation throughput.
3. **Keep the human the sole approval and merge authority** (ADR-0012, ADR-0019,
   ADR-0026): parallel build produces draft PRs, never approvals, never merges.
4. **Do not recreate the approval-burden problem ADR-0045 solved.** Generating
   more proposals than the human can curate just piles up unapproved drafts.

## Considered Options

- **Option A — Slow the whole tick down and build in parallel (rejected).**
  Simplest surface change, but sacrifices drift-detection freshness and slows the
  review/promote loop — both core governance value.
- **Option B — Two-loop split (chosen).** Decouple the build loop from the fast
  loop; each runs at its natural cadence.
- **Option C — A separate dedicated cron job for building (rejected).** A second
  job would duplicate the board reconciliation, Notion mirror, dedup, and review
  logic the tick already owns, and would split the tick's identity across two
  actors.

## Decision Outcome

The maintenance tick becomes a two-loop design:

1. **Fast loop (every 20 minutes, unchanged in scope):** scan → detect → suggest →
   review → apply feedback → promote → sync. Same phases, same cadence, same identity.
2. **Build loop (every few hours):** enumerate approved-and-unimplemented features
   (the ready queue) and fan out up to four concurrent worker sub-agents, each
   implementing one approved feature as a **draft PR**, coordinated by the tick's
   main thread.

Generation becomes **demand-driven**: the suggest phase maintains a conservative
ready queue of approved-but-unimplemented features (target ≈ 4-6), originating
new `feature:` proposals only to refill it, rather than at a fixed per-repo rate.

The human's "move to `Approved`" is codified as the build loop's **go signal**
(approval continuation). No per-item ping: approval is the trigger, and the tick
resumes work on the approved item at its next build-loop fire.

The "one build per tick" and round-robin build-selection rules in the
maintenance skill (Phase 3 / 3.5) are superseded by the build loop.

## Consequences

- **Positive:** implementation throughput scales to four concurrent workers per
  build-cycle; detection and promotion cadence is untouched; the board stays
  clean because generation is demand-driven rather than rate-driven.
- **Negative:** the throughput ceiling shifts to the **human's approval rate**,
  not machine speed — parallel build produces draft PRs that still queue for
  human merge (ADR-0012). Reserved-path implementations still require individual
  recorded approval (ADR-0026/ADR-0027), so the build loop does not reduce the
  reserved-path approval burden.
- **Risks:** concurrent implementations against a shared trunk raise
  merge-conflict and CI-congestion risk. Mitigated by the tick's existing
  per-session worktree discipline, the fact that each worker targets a distinct
  feature, and the fast loop's existing merge-state check (Phase 1).
- **Boundaries (unchanged):** the tick never merges (ADR-0012), never advances a
  work item past its Type checkpoint (ADR-0019), never touches a
  `question`-labeled item (ADR-0020), and never batch-accepts implementation-tier
  work (ADR-0045).

## Validation

- The maintenance skill's build-phase behavior matches FS-0051, verified by
  `scripts/check-skill-sync.sh` parity and the tick's own digest reporting a
  build batch per fire.
- The go-signal mapping ("move to `Approved`" → build) is already exercised by
  the existing approval-continuation path; this ADR names it, it does not
  introduce it.

## Links

- Supersedes: the "one build per tick" and round-robin build-selection rules in
  the `conventional-agents-maintenance` skill (Phase 3 / 3.5; canonical copy in
  `Tais-Den/pack-protocol`).
- Specifies: FS-0051 (parallel build loop and demand-driven generation).
- Extends: ADR-0019 (Type checkpoints), ADR-0020 (question suppression),
  ADR-0021 (cron-fired identity), ADR-0026 (recorded approval), ADR-0027
  (reserved paths), ADR-0045 (bounded runs and batch proposal-acceptance).
