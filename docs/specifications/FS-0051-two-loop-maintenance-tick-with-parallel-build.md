---
type: feature-spec
id: FS-0051
status: draft
title: Two-loop maintenance tick with parallel build
owner: ajoeofalltrades
test_required: false
interfaces:
  - "docs/specifications/FS-0051-two-loop-maintenance-tick-with-parallel-build.md"
  - "docs/change-plans/PLAN-0057-implement-fs-0051-two-loop-maintenance-tick.md"
  - "docs/decisions/ADR-0046-two-loop-maintenance-tick-with-parallel-build.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "docs/decisions/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0046, ADR-0021, ADR-0019, ADR-0020, ADR-0026, ADR-0027, ADR-0045, ADR-0012]
supersedes: []
requires: []
tags: [maintenance-tick, parallel-build, autonomy, generation, governance]
created: 2026-10-14
updated: 2026-10-14
---

# Feature Spec: Two-loop maintenance tick with parallel build

## Status

- Draft

## Summary

The maintenance tick's build phase is currently serialized: at most one feature
is implemented per tick, round-robin across repos. This spec defines a **build
loop** that runs on its own, slower cadence and implements several approved
features **in parallel** — a main thread plus up to four worker sub-agents —
while leaving the fast detection/review/promotion loop unchanged. It also makes
feature **generation demand-driven**, maintaining a conservative ready queue
instead of originating at a fixed rate.

## Goals

- Decouple the build cadence from the detection cadence (two loops).
- Implement up to four approved features concurrently per build-loop fire, each
  as a draft PR.
- Generate new feature proposals only to refill the ready queue (target ≈ 4-6),
  not at a fixed per-repo rate.
- Preserve the fast loop's detection, review, promotion, and sync behavior verbatim.
- Keep the human the sole approval/merge authority.

## Non-Goals

- Changing the fast loop's phases or cadence.
- Automating approval or merge (still ADR-0012 / ADR-0026).
- Reducing the reserved-path approval burden (ADR-0027 still applies per-item).
- Changing the review identities or the two-reviewer (Kimi → Minimax M3) pipeline.
- Defining the exact Hermes cron topology (one job vs. two); that is a PLAN
  implementation detail, constrained here only by the two-loop requirement.

## Users / Stakeholders

- The human owner (approves features, merges draft PRs).
- The maintenance tick's main thread (scans, reviews, promotes, coordinates builds).
- Worker sub-agents (implement one approved feature each).
- The three in-scope repos' boards (consume the generated proposals and draft PRs).

## Interfaces

The behavior this spec constrains lives in the `conventional-agents-maintenance`
skill — whose canonical repository copy is **`skills/conventional-agents-maintenance/SKILL.md`
in `Tais-Den/pack-protocol`** (not in this repo), with the live Hermes copy under
`~/.hermes/skills/` and a mirror in `Tais-Den/feral-fleet`. The build phase
(Phase 3 / 3.5) and suggest phase (Phase 2.5) are the surface this spec changes.
The in-repo files above are the governance documents that record the decision,
spec, and plan.

## Success Criteria

1. **SC1 — Parallel fan-out.** A build-loop fire dispatches up to four worker
   sub-agents (zero when the ready queue is empty), each targeting a distinct
   approved feature, as distinct draft PRs.
2. **SC2 — Idle gate preserved.** When the fast loop has found a reactive bug,
   the build loop does not dispatch new feature builds that cycle.
3. **SC3 — Demand-driven generation.** A new `feature:` proposal is originated
   only when the ready queue (approved, no draft PR) is below the target depth
   and no `feature:` proposal was originated for that repo in the prior 24 hours;
   otherwise the suggest phase originates nothing.
4. **SC4 — Draft PRs only.** Every build-loop output is a draft PR; no worker
   merges, approves, or advances a work item past its Type checkpoint.
5. **SC5 — Fast loop unchanged.** The fast loop's scan/detect/suggest/review/
   promote/sync phases continue on the 20-minute cadence with no behavior change.
6. **SC6 — Ready queue bounded.** The build loop consumes oldest-approved-first
   and does not exceed four concurrent implementations in a single fire.

## Edge Cases

- **Queue larger than four.** The build loop dispatches the four oldest approved
  features and leaves the remainder for the next fire (FIFO, oldest-first).
- **Empty queue.** The build loop fires and dispatches nothing; it does not
  generate proposals on its own — generation is the fast loop's demand-driven
  suggest phase.
- **Worker failure / branch behind trunk.** A worker whose draft PR fails CI or
  falls behind is handled by the fast loop's existing merge-state check and
  feedback-application path; the build loop does not re-dispatch a failed target
  in the same fire.
- **Reactive bug mid-cycle.** The idle gate (SC2) defers feature builds when a
  bug is actionable; the build loop's next fire re-evaluates.

## Out of Scope

- Reserved-path implementation approval mechanics (ADR-0027 unchanged).
- Any change to the two-reviewer pipeline, promotion caps, or Notion mirror.
- A generic multi-repo parallel build for repos outside the tick's scope.

## Dependencies

- The upgraded Ollama cloud (5-7 concurrent sub-agent dispatch).
- The `conventional-agents-maintenance` skill (canonical repo copy) as the
  implementation surface.
- ADR-0046 (the decision this spec implements).

## Rollout / Migration

- Ship the skill edit and any cron-topology change in a single PLAN (PLAN-0057),
  following the existing reserved-path approval path for the skill file.
- No data migration; the ready queue already exists implicitly as "approved
  issues without a draft PR" (the tick's current priority-3 detection).

## Security / Privacy

- No new secrets or credentials. Worker identity and attribution follow the
  existing cron-fired conventions (ADR-0021, the attribution trailer).

## Open Questions

- Whether the two loops are one Hermes cron job with internal time-gating or two
  jobs (fast tick + build). Resolved in PLAN-0057; both satisfy the two-loop
  requirement.
