---
type: adr
id: ADR-0042
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0035
superseded_by: null
---

# ADR-0042: Portable flow-report read-model — visibility profile, not a seventh capability

## Status

- Proposed

## Context and Problem Statement

Issue #145 grew beyond a GitHub field extension. Consumers of the framework
need to make governance state visible in digests, dashboards, and reports
without GitHub becoming a core dependency (`ADR-0024`, `ADR-0037`). A report
can make state visible; it cannot create work items, hold lifecycle state, or
provide a human write path. Treating the report as a full work-item binding
would overclaim pure-Git conformance; treating it as the next substrate
capability would put a read-only artifact on par with capabilities that
actually hold state.

`FS-0018` requires the six substrate capabilities a work-item binding must
provide (current statement: `integrations/README.md`): Work item, Type,
Phase, Parked state, Activity record, and Enumerability. A read-model
provides none of them — it consumes them.

## Decision

1. Define the `flow-report` as a versioned, **read-only visibility profile**
   — NOT a seventh `ADR-0024` substrate capability and NOT a work-item
   binding.
2. The contract's source boundary is explicit: Git alone is not a work-item
   binding. A Git-only report is a partial view, not a conformance claim.
3. The report's **governance profile** (SC-2 in FS-0035) is mandatory;
   the **planning profile** (SC-3) is optional, structurally separate, and
   advisory.
4. Reproducible scope metadata, lossless rendering of unset/invalid state,
   evidence-backed findings, and traceability distinguish *linked work items*
   from *governed-document exceptions* (SC-4); SC-5 states the conformance
   claim rule.
5. `human_decisions_required` is a read-only queue; human interaction remains
   the binding's responsibility.
6. The **Git-native work-item decision** is recorded separately from this
   contract and is NOT decided here (the Git-native work-item decision
   acceptance bullet in issue #146, tracked as FS-0035's out-of-scope item).
   No branch-name or commit-message inference of lifecycle state.
7. A neutral report fixture is extracted from a consumer digest shape without
   importing the consumer's cadence, field names, repository rotation, or
   other policy.

## Consequences

- Consumers without GitHub Projects (or any binding) can still produce
  conforming reports and remain conforming at the partial-conformance
  level; full FS-0018 lifecycle conformance requires naming a binding that
  provides all six capabilities.
- The report contracts with a stable, versioned shape that dashboards and
  digests can consume without coupling to a specific platform's API.
- Planning policy (priorities, horizons, cadence) stays out of the core
  contract — it is consumer policy, not framework fact.
- The Git-native work-item question remains open as a separate bounded
  decision; nothing in this ADR blocks or endorses it.

## Validation

- `npm run check:status` is green with the ADR-0042 index row and FS-0035 /
  PLAN-0041 rows present (index sync + consistency rules).
- The ADR's `## Validation` section is present (this section), per the
  requirement for acceptance.
- FS-0035's SC-1..SC-6 success criteria are the acceptance measure for the
  contract once implemented; this ADR introduces no code, so validation is
  document-level (lint + status) until the approved implementation ships.
- Review checkpoint: at the first implementation PR; if the capability list
  or the report's boundary changes, this ADR is revisited before that PR
  lands (house style per ADR-0024/ADR-0027).
