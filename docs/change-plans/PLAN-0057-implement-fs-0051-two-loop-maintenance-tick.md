---
type: change-plan
role: implementer
language: shell
status: draft
related_specs: [FS-0051]
approved_by: ""
related_adrs: [ADR-0046, ADR-0021, ADR-0027, ADR-0012, ADR-0019, ADR-0020, ADR-0026, ADR-0045]
touches:
  - "docs/specifications/FS-0051-two-loop-maintenance-tick-with-parallel-build.md"
  - "docs/change-plans/PLAN-0057-implement-fs-0051-two-loop-maintenance-tick.md"
  - "docs/decisions/ADR-0046-two-loop-maintenance-tick-with-parallel-build.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "docs/decisions/README.md"
  - "CHANGELOG.md"
created: 2026-10-14
updated: 2026-10-14
---

# Change Plan: Implement FS-0051 two-loop maintenance tick

> **Note:** this plan is `draft`. The implementation that follows it — editing
> `skills/conventional-agents-maintenance/SKILL.md`, a reserved path — requires
> recorded human approval (ADR-0027), recorded before any implementation commit.
> This plan's own `approved` transition is that approval event.

## 1. Feature / Issue Reference

- FS-0051 (Two-loop maintenance tick with parallel build), per ADR-0046.

## 2. Scope of Change

Evolve the maintenance tick from a single 20-minute loop with one-build-per-tick
to a two-loop design: a fast loop (unchanged) plus a build loop that fans out
approved features to parallel workers. The implementation is **cross-repo**:
the skill's canonical repository copy lives in `Tais-Den/pack-protocol`
(`skills/conventional-agents-maintenance/SKILL.md`), the live copy is the
user-owned Hermes skill, and the cron topology is Hermes-side. The
conventional-agents changes in this PR are the governance documents only
(ADR / FS / PLAN / indexes / CHANGELOG).

## 3. Tests Driving This Change

- `test_required: false` on FS-0051 — there is no in-repo executable to unit-test.
  Validation is `scripts/check-skill-sync.sh` parity after the skill edit, the
  tick's digest reporting a build batch per fire, and a manual one-shot build-loop
  fire observing SC1-SC6.

## 4. Files to Be Modified

- `skills/conventional-agents-maintenance/SKILL.md` — canonical copy in
  `Tais-Den/pack-protocol` (cross-repo); mirrored to `Tais-Den/feral-fleet` and
  to the live Hermes skill (`~/.hermes/skills/`, user-owned) per the
  skill-parity contract. Not present in this repo.
- The Hermes cron topology (fast job + build job) — out-of-repo, recorded as a
  step below.

## 5. Implementation Steps (High-Level)

1. Edit the skill's Phase 2.5 (Suggest) — in the `Tais-Den/pack-protocol` copy —
   to make generation demand-driven: originate a `feature:` proposal only when
   the ready queue (approved, no draft PR) is below the target depth (~4-6),
   preserving dedup and the one-per-repo-per-24h cap (a ceiling, not a floor).
2. Replace the "one build per tick" + round-robin (Phase 3) and the single-target
   build (Phase 3.5) with a **build loop**: enumerate approved-and-unimplemented
   features, dispatch up to four worker sub-agents (each in its own worktree, one
   approved feature each, draft PR), coordinated by the main thread.
3. Split the cron topology Hermes-side: a fast job (20m, existing
   `conventional-agents-maintenance`) and a build job (every few hours), or one
   job with internal time-gating. Recommend two jobs for identity clarity.
4. Update the digest's build section to report the batch (`## Build batch`) with
   per-worker PRs and rationale.
5. Run `scripts/check-skill-sync.sh` and confirm byte-parity between the repo copy
   and the live Hermes skill after the change.

## 6. Constraints and Guardrails

- ADR-0012: the tick and workers never merge.
- ADR-0019: `feature` work items never advance past `Approved` without the human.
- ADR-0020: never touch `question`-labeled items.
- ADR-0026 / ADR-0027: the skill file is a reserved path; the implementation lands
  only after this plan is `approved` with recorded human approval.
- ADR-0021: cron-fired identity (`mode=autonomous`, `session=...`) unchanged.
- The live Hermes skill is user-owned (`curator adopt` pending); the live-copy edit
  goes through `skill_manage`, not a repo push.

## 7. Risks and Edge Cases

- **Concurrent builds collide on trunk.** Mitigate with per-session worktrees and
  the fast loop's merge-state check.
- **CI congestion** from four parallel draft PRs. Mitigate by the slow build
  cadence and the existing billing-block classifier.
- **Generation starves or floods.** Demand-driven refill with the ready-queue
  target keeps it bounded (SC3).
- **Skill-parity drift** across the three mirrored repos if the sync PRs lag.
  Mitigate with `check-skill-sync` and the existing parity contract.

## 8. Validation

- `scripts/check-skill-sync.sh` passes (repo copy == live copy) after the edit.
- A manual build-loop fire observes SC1-SC6 (parallel fan-out, idle gate,
  demand-driven generation, draft-only, fast loop unchanged, queue bounded).
- `npm run check:status` green on the docs PR carrying this FS/PLAN/ADR.

## 9. Explicit Non-Changes

- Fast-loop phases, cadence, review identities, promotion caps, Notion mirror.
- The reserved-path approval gate (ADR-0027) is unchanged.
- No change to how reserved-path implementations are individually approved.

## 10. Readiness Check

- [ ] FS-0051 and this plan both `approved` (recorded human approval on the skill path).
- [ ] Next-free IDs verified (ADR-0046 / FS-0051 / PLAN-0057) against trunk and open PRs.
- [ ] `curator adopt` resolved for the live skill copy, or explicit user authorization to edit it.

## Declaration

This plan declares intent to implement FS-0051. It authorizes nothing until it
is `approved` with recorded human approval (ADR-0026 / ADR-0027); the skill-file
implementation is a reserved-path change that follows this approval as a
separate, narrowly-gated act.
