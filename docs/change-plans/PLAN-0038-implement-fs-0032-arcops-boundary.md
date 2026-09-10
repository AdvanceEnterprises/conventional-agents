---
type: change-plan
role: implementer
language: n/a
status: draft
related_specs: [FS-0032]
approved_by: ""
related_adrs: [ADR-0007, ADR-0024, ADR-0026, ADR-0040]
touches:
  - docs/decisions/ADR-0040-arcops-architecture-intent-checker-boundary.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-10
updated: 2026-09-10
---

# PLAN-0038: Implement FS-0032 — ArcOps Architecture-Intent Checker Boundary

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0032
* Related ADR ID(s): ADR-0007 (standards only, never orchestration),
  ADR-0024 (platform-neutral core with shipped bindings), ADR-0026 (approval
  is a recorded act), ADR-0040 (the boundary decision this plan implements)
* Issue / PR Reference: #143 (spec: define the ArcOps architecture-intent
  checker boundary)

## 2. Scope of Change

**This change WILL:**

* Add `ADR-0040` — the boundary decision: ArcOps is a separate capability;
  the framework ships the contract, not the checker; ArcOps may explain and
  flag, Git and human gates decide; the corpus is the accepted intent indexed
  with revision identity; the first slice is read-only and local; the pilot
  implementation lives in a separate ArcOps repository.
* Add `FS-0032` — the read-only pilot contract: structured `check-plan` /
  `check-diff` output (conflict, severity, affected path, source citation,
  uncertainty), no write path, no governance gate, no framework-core
  implementation, pilot targets `conventional-agents` and `pack-protocol`
  with `#124`-consumable measurements.
* Register both documents in `docs/specifications/README.md` and
  `docs/change-plans/README.md` index tables.
* Add a CHANGELOG entry under Unreleased → Added.

**This change will NOT:**

* Ship any ArcOps implementation, script, or CI job in this repository.
* Wire ArcOps into any governance gate.
* Create the ArcOps repository (that is the pilot's own step, outside this
  plan's surface).

## 3. Tests Driving This Change

* Test file(s):

  * None — documentation-only change. The repository's existing gates
    (`npm run check:status`, `npm run lint:docs`) are the verification.

* Target test(s):

  * `check:status` — FS/PLAN/ADR index sync, status pairing, ADR structural
    completeness, PLAN touches containment.
  * `lint:docs` — markdownlint over the governed corpus.

## 4. Files to Be Modified

* docs/decisions/ADR-0040-arcops-architecture-intent-checker-boundary.md
* docs/specifications/FS-0032-arcops-architecture-intent-checker-boundary.md
* docs/specifications/README.md
* docs/change-plans/README.md
* CHANGELOG.md

## 5. Implementation Steps (High-Level)

1. Author `ADR-0040` (proposed) recording the boundary decision and its
   rationale, with the required MADR sections.
2. Author `FS-0032` (draft) defining the read-only pilot contract and
   success criteria.
3. Add index rows for `FS-0032` and `PLAN-0038` to their README tables.
4. Add the CHANGELOG entry.
5. Run `npm run check:status` and `npm run lint:docs`; fix any drift.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0032 Non-Goals / Out of Scope: no hosted service, no automatic
    remediation, no governance gate, no framework-core implementation.

* ADR constraints:

  * ADR-0007: standards only, never orchestration — the contract must not
    edge toward a gate.
  * ADR-0024: tool neutrality — no consumer must install ArcOps.
  * ADR-0026: approval is a recorded act — ArcOps cannot produce it.
  * ADR-0040: the boundary decision itself.

* Architecture constraints:

  * Documentation-only change; no exported-surface executable added.

## 7. Risks and Edge Cases

* Index drift: README rows must match front-matter status and title exactly
  (`check:status` rule 2/4) — verified by the gate.
* ADR structural completeness: `ADR-0040` at `proposed` needs the MADR
  sections; `Validation` is required before acceptance — present.
* Scope creep toward a gate: the contract language must stay read-only;
  reviewed by the two-round reviewer pipeline.

## 8. Validation

* Tests expected to pass:

  * `npm run check:status` (all rules)
  * `npm run lint:docs` (markdownlint)

* Manual checks (if any):

  * None — the gates are the verification.

## 9. Explicit Non-Changes

* No framework script, npm script, or CI workflow is added or modified.
* No existing ADR, FS, or PLAN is modified.
* No ArcOps implementation is started.

## 10. Readiness Check

* [ ] Spec is approved — no; this plan is the draft that seeks approval
* [x] Tests exist or are clearly defined — the repository gates
* [x] Scope is minimal and explicit
* [x] No architectural changes implied — the boundary is documentation

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
