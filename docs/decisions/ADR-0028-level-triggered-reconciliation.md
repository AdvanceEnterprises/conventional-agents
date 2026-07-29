---
type: adr
id: ADR-0028
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
---

# ADR-0028: Level-triggered reconciliation

## Status

- Proposed

## Context and Problem Statement

`FS-0018` Path 3 has an agent create work items from detected drift, fired by "a
scheduled tick, detection run, or other autonomous signal." `ADR-0024` capability 6
requires a substrate to provide "a trigger source capable of invoking an agent on
work-item events **or** on a schedule." The GitHub binding lists both: webhook events
and Actions `schedule:`.

That "or" treats the two as interchangeable. They are not, and the difference is not
about latency — it is about what happens when a trigger is missed.

An **edge-triggered** handler reacts to a transition: *this changed, respond to it.* A
missed event is missed permanently. The work item sits in the wrong phase, the stale
document is never flagged, and nothing anywhere notices, because the only thing that
would have noticed was the event that did not arrive.

A **level-triggered** handler reconciles state: *what is true now, and what should be?*
A missed run costs latency and nothing else. The next run sees the same unreconciled
state and acts on it.

| | Edge-triggered | Level-triggered |
| --- | --- | --- |
| Handler asks | "This changed — react" | "What state is the world in?" |
| Missed firing | Lost permanently | Corrected by the next pass |
| Latency | Seconds | Bounded by interval |
| Failure mode | Silent divergence | Slower convergence |

Treating them as equivalent lets a consumer build an events-only system, believe it
conforms, and accumulate silent divergence that only a manual audit will find. This
repository has already demonstrated that failure class from a different cause: the ADR
index drifted to eleven wrong titles and nine wrong statuses precisely because nothing
periodically compared state to what it should be.

The question this ADR answers: **which trigger mechanism is authoritative, and what
must a substrate actually provide?**

## Decision Drivers

- **A missed trigger must not cause permanent divergence.** This is the whole point.
- **The substrate requirement should be the weakest one that works.** Requiring event
  emission excludes platforms that are perfectly capable of supporting the governance.
- **Latency has real value** and should be available to consumers who can get it.
- **Agent reconcilers are not classical controllers.** The pattern is borrowed from
  deterministic control loops and the borrowing is imperfect.

## Considered Options

### Option A — Events only

Handlers fire on work-item events. Lowest latency, simplest mental model, and no
scheduled infrastructure.

Every dropped delivery is permanent divergence. Webhook delivery is at-most-once in
practice — endpoints go down, retries expire, deliveries are dropped under load — and
nothing in an events-only system ever revisits state to notice.

### Option B — Schedule only

A reconciler runs on an interval and nothing else. Self-healing and simple to reason
about, at the cost of interval-bounded latency on every action.

### Option C — Both, treated as equivalent

The status quo, and what `ADR-0024` capability 6 currently says. A consumer may
implement either.

The problem is that it permits Option A while appearing to require more, and the
consumer who picks events-only gets no signal that they have chosen the unsound half.

### Option D — Reconciliation authoritative, events as accelerator

Reconciliation is mandatory and authoritative. Events are an optional optimization that
may trigger a reconciliation pass earlier than the schedule would.

## Decision Outcome

**Chosen option: Option D — level-triggered reconciliation is the correctness
guarantee; events are a latency optimization.**

### The rule

> **The reconciler is the correctness guarantee. The event is an optimization.** If the
> event never fires, the system is slower but still correct. If the reconciler never
> runs, the system is broken.

Three consequences follow directly:

1. **Handlers are written as reconcilers.** A handler asks what state the work items
   are in and what should be true of them — not "what just changed." An event-shaped
   handler that cannot answer the first question is not conformant, however it is
   triggered.
2. **An event may start a reconciliation pass early.** It must never be the only path
   to one. A consumer with excellent webhooks still runs the schedule.
3. **Reconciliation must be idempotent.** `ADR-0014` covers the mechanism: the agent
   reads the activity record, finds its own prior entry for that transition, and skips.

### Substrate requirement, restated

`ADR-0024` capability 6 is amended. A conforming substrate must be **enumerable**: its
work items and their attributes readable on demand, so a reconciler can evaluate
current state. It **may** additionally offer event notification, which reduces latency
and is never the sole trigger.

This is a weaker requirement than the original "events or schedule," and deliberately
so. Enumerability is close to universal among work-tracking platforms; reliable event
delivery is not. Requiring the weaker property admits more substrates while
guaranteeing more, because the property that actually carries correctness is the one
being required.

### Scheduled execution becomes load-bearing

If the reconciler is the correctness guarantee, its reliability is the system's
reliability. This reframes something the GitHub binding already documents as a
footnote: Actions `schedule:` is best-effort, delayed under load, runs only on the
default branch, and is **disabled automatically after 60 days without repository
activity**.

Under Option A or C that is a nuisance. Under this decision it means a quiet repository
silently loses its convergence loop while appearing to be governed. Bindings must state
their scheduler's reliability characteristics, and consumers must treat scheduler
failure as an outage rather than a delay.

### The borrowing is imperfect: agent reconcilers are non-deterministic

Control-loop reconciliation assumes a deterministic controller: same state in, same
action out. An LLM reconciler does not have that property. Two passes over identical
state can reach different conclusions, which admits a failure mode classical
controllers cannot exhibit — **oscillation**: act, re-evaluate, judge the previous
action wrong, undo, re-evaluate, redo.

This decision does not solve that. Two existing mechanisms bound it:

- `FS-0018`'s autonomous gate limits what an unattended agent may change at all, so
  oscillation is confined to transitions below the gate.
- The activity record makes oscillation **visible** — a work item whose timeline shows
  the same transition applied and reversed repeatedly is legible as malfunctioning.

Bounded and visible is not prevented. A consumer running unattended reconciliation
should watch for it, and this ADR should be revisited if it is observed, rather than
the pattern being trusted because it works for Kubernetes.

## Consequences

### Positive

- A missed event costs latency instead of correctness, which is the property the
  governance actually needs.
- The substrate bar drops to enumerability, admitting platforms whose event surfaces are
  weak or absent — the Notion binding's known risk area stops being a risk.
- Consumers with good event infrastructure keep their latency; nothing is taken away.
- Drift of the kind this repository suffered in its ADR index becomes a thing a
  reconciler finds, rather than a thing a manual audit finds.

### Negative

- Every consumer must run scheduled infrastructure, including those whose event
  delivery is entirely reliable. There is no events-only conformant configuration.
- Handlers must be written in reconciler shape, which is harder than reacting to an
  event payload: a reconciler needs to determine desired state from the governance
  documents rather than being told what changed.
- Reconciliation cost scales with corpus size rather than with change rate. A large
  quiet repository pays on every pass.
- Non-determinism is bounded, not eliminated.

### Neutral

- No change to what an unattended agent may *do*. `FS-0018`'s autonomous gate and
  `ADR-0012`'s merge gate are untouched; this decides how the agent is invoked, not what
  it may then perform.
- Existing bindings are unaffected in substance. The GitHub binding already provides
  both mechanisms; what changes is which one it must not omit.

## Validation

- **Signal:** every binding documents an enumeration mechanism, and states its
  scheduler's delivery characteristics and failure modes.
- **Signal:** no consumer configuration passes conformance with event triggers and no
  reconciliation pass.
- **Signal:** a work item deliberately left in an inconsistent state is corrected by
  the next reconciliation pass without any event being emitted.
- **Signal:** repeated reconciliation over unchanged state produces no repeated actions
  — idempotency holding in practice.
- **Review checkpoint:** the first time oscillation is observed on a real work item.
  That is the moment the control-loop borrowing is tested against a non-deterministic
  controller.
- **Failure condition:** if reconciliation passes are routinely disabled for cost or
  noise, the interval is wrong or the corpus has outgrown full-scan reconciliation.
  Neither is fixed by removing the guarantee.

## Links

- ADR-0024: Platform-neutral core with shipped bindings — capability 6 is amended by
  this ADR.
- ADR-0014: Background task governance — unattended sessions as primaries, and the
  activity record as idempotency key.
- ADR-0021: Cron actor identity — the identity a scheduled reconciler runs under.
- ADR-0022: Meta-modes — a reconciler declares `mode=autonomous`.
- FS-0018: Work item lifecycle — Path 3 and the autonomous gate bounding what a
  reconciler may do.
- `integrations/README.md` — the current-state statement of the substrate capabilities,
  updated by this ADR.
- `integrations/github-issues-projects.md` §6 — the scheduler caveats this decision
  promotes from footnote to load-bearing.
