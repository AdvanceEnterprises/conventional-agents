---
type: adr
id: ADR-0047
status: accepted
decision_scope: system
reversible: unknown
related_specs:
  - FS-0051
superseded_by: null
created: 2026-09-29
updated: 2026-09-29
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
-->
# ADR-0047: Authorized intent identity and the human grant

## Status

- Accepted

## Context and Problem Statement

The engine dispatches bounded agent runs against governed work items and
publishes the results as proposals. Publication is an external, non-transactional
write against the work-item substrate and Git host. Retries, crashes, and
overlapping passes are normal, so the engine needs a stable identity for "the
work being done" that survives a retry and refuses to be minted by accident.

Two obvious candidates fail:

- **A run/attempt identifier.** Too narrow. Every retry produces a new one, so a
  retry after an unacknowledged write looks like new work and can publish a
  second proposal for the same intended change.
- **A work-item identifier.** Too broad. One issue may legitimately produce a
  spec proposal, then an implementation proposal, then a follow-up correction.
  Collapsing these into one identity means the second and third are either
  blocked or silently treated as duplicates of the first.

There is also an authority question. `FS-0018` and `ADR-0019` make
Type human-mutable and key the autonomous gate to Type; `ADR-0026` requires
approval to be a human act with a locatable record. But a work item's *current*
Type and Phase tell you nothing about **who authorized this particular action,
over this particular scope**. An agent that reads `feature` + `Approved` and
concludes it may draft a spec is inferring authority it was never granted.

`ADR-0014` already names the work-item activity record as an idempotency
mechanism. This decision does not replace that; it adds an internal correlation
identity the activity record cannot provide, because a comment is editable and
deletable.

## Decision Drivers

- Safety: a retry must not produce a second independent proposal.
- Auditability: an operator must be able to say who authorized what, and when.
- Multiplicity: one work item may host several distinct authorized actions.
- Honesty: the framework cannot enforce this on GitHub; it is conduct plus
  detection, and must not be described as enforcement.

## Considered Options

### Option A — Key on the run/attempt identifier

Simple, and correct for logging. Wrong for deduplication: a retry mints a new
identifier and therefore new work.

### Option B — Key on the work-item identifier

Prevents duplicate proposals within one item, at the cost of forbidding the
second, legitimately distinct action on the same item.

### Option C — Key on the authorized action and scope generation

Identify an **intent** by the work item, the governed action, and an explicit
authorization/scope generation. Retries and in-scope review revisions share the
intent; a genuinely new action, or a change of scope, requires an explicit human
act that creates a new generation. Attempts are recorded under the intent without
minting authority.

## Decision Outcome

**Option C.** Adopt a stable *authorized intent* as the unit of deduplication and
publication.

- An intent is identified by the work item, the governed action (for the first
  pilot, `draft-spec`), and an explicit authorization/scope generation.
- A **grant** is a human-origin record that names the work item, the action, and
  the permitted scope/generation. Authority comes from the grant, not from the
  work item's current Type, Phase, or text.
- An attempt is not a grant. A retry, a re-read, or a worker's own recommendation
  cannot create a generation.
- Editing the work item's description or an agent comment **cannot** mint a new
  generation.
- The engine targets **one canonical publication per intent** — for the pilot,
  one draft FS PR. Multiple attempts and multiple audit records are expected
  beneath that single publication target.
- Where evidence of a valid grant is absent or unverifiable, the engine stops.
  It does not infer approval from the substrate's current field values.

### What this ADR does not decide

The durable representation and verification of a grant; how the acting human is
authenticated; revocation handling; Git snapshot binding; where the ledger lives;
and the exact scope-revision rules. These are specified in `FS-0051` and the
implementation `PLAN`. Their absence here is deliberate: the semantic floor is
decidable now, the mechanism is not.

### What this ADR does not change

It does not alter any other accepted ADR. (Before the merge that folded this
content into conventional-agents, the two repositories kept separate identifier
sequences; after the merge they share one sequence.)

## Consequences

### Positive

- A retry converges on existing work instead of creating a second proposal.
- Authority is attributable to a specific human act rather than inferred from
  mutable fields.
- Distinct actions on one work item remain possible.

### Negative

- The engine must maintain correlation state of its own; a stateless design
  cannot express this.
- A grant whose record cannot be resolved blocks legitimate work until a human
  acts. This is intended, and it is friction.
- Because GitHub and the engine's own store cannot commit atomically, "one
  canonical publication" remains a **goal with a specified recovery path**, not
  an exactly-once guarantee.

### Neutral

- Some work items will need more than one grant over their life. That is a
  documented, expected sequence rather than an error.

## Validation

- Two independent passes over the same authorized intent select the same intent
  and reserve exactly one.
- A retry after an unacknowledged publication does not create a second
  proposal; unresolved ambiguity holds for inspection.
- Editing the work item's description creates no new generation.
- A work item with no resolvable grant dispatches nothing.
- Crash-point tests are run at each reservation/dispatch/publication boundary,
  and the observed outcome matches the documented recovery path. Until those
  tests exist and pass, this ADR's guarantee language is treated as a target.

## Links

- Spec: `FS-0051`
- Related: `ADR-0048` (worker/publisher separation)
- Related (same repository): `ADR-0014`
  (background-task governance), `ADR-0019` (Type-keyed autonomous gate),
  `ADR-0020` (the `question` label suppresses agent work-item actions),
  `ADR-0026` (approval is a recorded act); and `FS-0018` (work-item lifecycle).
