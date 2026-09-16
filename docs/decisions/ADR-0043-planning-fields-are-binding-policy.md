---
type: adr
id: ADR-0043
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0036
superseded_by: null
---

# ADR-0043: Planning fields are binding policy, not framework state — authority matrix for Priority, Iteration, and Milestone

## Status

- Proposed

## Context and Problem Statement

Issue #145 grew from a GitHub field extension into a governance-boundary
question. The framework governs work-item identity, lifecycle phase, and
safety gates (`FS-0018`, ratified by `ADR-0019`/`ADR-0020`/`ADR-0021`/
`ADR-0022`), but it does not yet define how items are *ranked*, selected into
near-term flow, or tied to enduring outcomes. Tais-Den's own boards now carry
`Priority`, `Iteration`, and `Human Required Action` fields plus repository
`Milestone`s, and the tick assigns iterations nightly.

GitHub Projects v2 has **no per-field ACL** (research recorded in issue #145):
a token able to edit a Project can edit `Priority` and `Iteration` as well as
`Status` and `Issue Type`. A binding must therefore rely on **explicit agent
conduct, stance/proposal records, webhook alerts, and reconciliation** — not
permission-level prevention. `Milestone` is repository-native issue metadata,
not a Project custom-field value; its updates use the Issue mechanism, and a
cross-repository project board cannot uniformly milestone all its items —
the binding must state that limitation.

At the same time, the framework's own rules already constrain agents around
these fields: `ADR-0026` (approval is a recorded act) and `ADR-0030`
(decision records versus current-state documents) imply that planning values
an agent writes must be evidenced and traceable. The missing piece is an
explicit, substrate-neutral statement of *who may set which planning field,
and what evidence an agent write must carry*.

## Decision

1. **Planning fields are policy, not framework state.** `Priority`,
   `Iteration`, and `Milestone` are ranked-select/planning metadata that
   expresses near-term focus, capacity intent, and enduring outcome. They
   are **not** part of the `FS-0018` lifecycle axes (Type/Phase/Parked
   state); a consumer may omit them and still be fully lifecycle-
   conforming. This is the mechanism-vs-policy separation: the framework
   ships the *mechanism* (how the fields map onto a substrate, how they are
   read/written, how attribution is recorded); the *policy* (cadence, WIP
   limits, priority meanings, replenishment, rollover) belongs to the
   consumer or a higher-level convention, never to the core.

2. **Authority matrix.** The framework defines exactly three write
   authorities for planning fields:

   | Field | Human (primary) | Agent |
   | --- | --- | --- |
   | Milestone (native issue metadata) | create/assign/close | read; **recommend** via stance/proposal only — never create/assign/close |
   | Priority | set/re-rank | read; **recommend** with evidence in a stance/proposal; may apply the suggested mapping only when the field is UNSET and the write is idempotent, logged, and attributable |
   | Iteration | set/move | read; may assign/clear only under the explicit, documented scheduling contract (see FS-0036), with the same idempotent, logged, attributable requirement |

   The sole unattended **mandatory** agent mutation is idempotently clearing
   `Iteration` (and related planning context) from an already-`Done` item
   when a built-in workflow did not do so.

3. **Recommendations are never silent writes.** An agent that believes a
   priority or milestone is wrong MUST record the recommendation in a
   work-item comment or proposal document with evidence and a stance
   trailer, and MUST NOT alter the field itself. The human is the arbiter.

4. **The flow-report boundary is inherited.** The advisory, structurally
   separate planning profile of the portable flow-report (`ADR-0042`,
   `FS-0035`) is the framework's own statement of what planning visibility
   looks like without a work-item binding; this ADR extends that boundary to
   the GitHub binding's planning fields. Nothing in this ADR makes any
   planning field a seventh substrate capability (`ADR-0024`).

## Consequences

- Positive: agents can operate a continuous-flow board (unset-priority
  backfill, iteration roll-forward and roll-back) without becoming
  autonomous portfolio managers; the authority matrix is machine-checkable
  by the binding's audit layer.
- Negative: a misconfigured agent holding a project token can still rewrite
  planning fields. Mitigation is conduct-level (this ADR, stance records,
  `gh-board-audit` read-only drift reports), not permission-level.
- Framework change: this ADR is the architectural ratification for the
  `FS-0036` spec (field semantics, the scheduling contract, the read-only
  flow report checks) and may be superseded by a future ADR that moves a
  planning field into lifecycle scope — that would require revisiting
  `FS-0018`'s axis definition and is deliberately NOT done here.

## Validation

- `npm run check:status` is green with the ADR-0043 index row and FS-0036 /
  PLAN-0042 rows present (index sync + consistency rules).
- The ADR's `## Validation` section is present (this section), per the
  requirement for acceptance.
- FS-0036's SC-1..SC-6 success criteria are the acceptance measure for the
  contract once implemented; this ADR introduces no code, so validation is
  document-level (lint + status) until the approved implementation ships.
- Review checkpoint: at the first implementation PR; if the authority
  matrix or the planning-policy boundary changes, this ADR is revisited
  before that PR lands (house style per ADR-0024/ADR-0027).

## References

- `FS-0036` (draft) — field semantics, authority-matrix mechanics, the
  iteration scheduling contract, and read-only flow checks.
- `FS-0035` / `ADR-0042` — the portable flow-report read-model; planning
  profile boundary.
- `FS-0018`, `ADR-0019`, `ADR-0020`, `ADR-0021`, `ADR-0022` — lifecycle
  axes, autonomous gates.
- `ADR-0026` — approval is a recorded act (evidence requirement for writes).
- `ADR-0030` — decision records versus current-state documents.
- Issue #145 — research on GitHub Projects v2 field-ACL absence and
  mechanism-vs-policy.
