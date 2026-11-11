---
type: adr
id: ADR-0049
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0051
superseded_by: null
updated: 2026-10-18
---

# ADR-0049: Grant-based go signal for autonomous runs

## Status

- Accepted

## Context and Problem Statement

`ADR-0045` (accepted) defines the autonomous run's go signal as a *status
move*: "A human records go by moving Status to In Progress." `ADR-0047`
(accepted, re-homed from the folded operations template) establishes the
opposite: authority comes from an explicit **human grant** — a durable record
naming the work item, the governed action, and the permitted scope/generation —
never from a work item's current Type or Phase. As `ADR-0047` puts it, an agent
that reads `feature` + `Approved` and concludes it may draft is inferring
authority it was never granted.

The two accepted decisions conflict. `ADR-0045`'s Gate step *is* the
status-inferred go signal that `ADR-0047` rejects. Because `ADR-0047` post-dates
`ADR-0045` (it arrived with the operations-template fold), the conflict is
resolved here by a **successor** decision rather than by rewriting `ADR-0045`
in place — accepted ADR bodies are append-only.

The conflict is not academic: a run whose start is keyed to a mutable status
field can be started, or believed started, without a specific human authorizing
*this action over this scope*. That is precisely the inference `ADR-0047` was
written to forbid.

## Decision Drivers

- **Authority integrity:** a run must start on an attributable human grant, not
  an inference from mutable fields.
- **Continuity:** the rest of `ADR-0045`'s run machinery (bound, manifest,
  batch acceptance, risk-tier split) is sound and should carry forward, not be
  re-litigated.
- **Coherence:** the merged repository must not carry two accepted decisions
  that contradict each other on the same point.

## Considered Options

### Option A — Leave `ADR-0045` as-is (status-inferred gate)

Keeps the status move as the go signal. Leaves the framework carrying two
accepted ADRs that contradict on authority. *Rejected* — the contradiction is
the defect this decision exists to remove.

### Option B — Grant-based go signal (reconcile `ADR-0045` with `ADR-0047`)

Replace `ADR-0045`'s Gate step with the grant model from `ADR-0047`; carry the
rest of the run contract forward unchanged. *Chosen.*

### Option C — Repeal `ADR-0045` and re-specify the run wholesale

Discards the batch-acceptance and risk-tier machinery along with the gate.
More churn than the conflict warrants, and re-opens decisions that were already
settled and reviewed. *Rejected.*

## Decision Outcome

**Chosen option: Option B.** The autonomous run's go signal becomes an
**explicit grant** (per `ADR-0047`), replacing `ADR-0045`'s status-inferred
Gate.

The amendment to `ADR-0045`'s run contract:

- **Gate → Grant.** A human records an explicit grant — the work item, the
  governed action (for the pilot, `draft-spec`), and the permitted
  scope/generation — per `ADR-0047`. The run starts only on a resolvable grant,
  never on a status move alone. A status move may accompany the grant as a
  human-visible record, but it is an *effect*, not the *source*, of authority.
- **Declare.** The run's declared scope, non-goals, and acceptance criteria
  become the grant's named scope/generation.
- **Mid-run reversal.** A revoked grant stops the run at the point of
  revocation, mirroring `ADR-0045`'s mid-run reversal; already-authored drafts
  are surfaced for human disposition. The *mechanism* of revocation — how a
  grant is revoked and detected — is not decided here; it is deferred to
  `FS-0051`, as in `ADR-0047`.

Everything else in `ADR-0045` carries forward unchanged: the Run step, the
≤48-hour Bound, the Present step (one manifest-first PR with the
proposal/implementation split), the Approve step (batch proposal-acceptance
recorded once per run), and the invariant that batch acceptance reaches
proposal-acceptance only — reserved-path, ruleset, and workflow changes and
merge remain individually human-gated and never enter the batch.

### Cadence, parallelism, and queue depth (instance operating intent, not policy)

This decision does **not** fix the tick's cadence, worker count, or queue depth,
and the following is **not** framework policy. It records the instance
operator's stated direction for the operations instance's cron schedule and
worker lanes — a lower-frequency pass every few hours, one main thread plus
four worker lanes, and a conservative queue depth — and may change in
configuration without amending this ADR. Do not cite these figures as a
framework constraint; they are instance configuration.

### Deferred

**Generation ambition** — how many scope generations a single run may produce,
and when a new generation (rather than a re-use of the current intent) is
warranted — is left open. The scope-revision rules that trigger a new
generation are a separate future decision; they are already named as open
questions in `FS-0051`, and this ADR does not settle them.

## Consequences

### Positive

- The run's go signal is a durable, attributable grant rather than a mutable
  status field, resolving the contradiction between `ADR-0045` and `ADR-0047`.
- The run model gains `ADR-0047`'s deduplication and generation semantics: a
  retry converges on one intent, and a new generation requires an explicit
  human act.

### Negative

- A grant must be resolvable before a run starts; an unresolvable grant blocks
  the run until a human acts. This is intended friction, not a regression.
- Operators mint grants rather than flipping a status field.

### Neutral

- Cadence, parallelism, and queue depth remain instance-configurable; they are
  not framework decisions.

## Validation

- **Signal:** every started run carries a citation to the grant record (work
  item, action, scope/generation) that authorized it; a work item bearing
  `feature` + `Approved` with no resolvable grant dispatches nothing.
- **Signal:** a revoked grant stops a run mid-flight, and no further edits are
  made after the point of revocation.
- **Signal:** the batch-acceptance invariant (proposal tier only) holds
  unchanged across the amendment.

## Links

- `ADR-0045` — the decision this amends (superseded by this ADR on acceptance).
- `ADR-0047` — authorized intent identity and the human grant; the grant model
  this decision adopts as the go signal.
- `ADR-0026` — recorded approval; the run's batch acceptance form is unchanged.
- `FS-0051` — the engine spec; its open questions include the scope-revision
  rules this decision defers.
