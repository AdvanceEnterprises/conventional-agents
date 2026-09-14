---
type: feature-spec
id: FS-0035
status: draft
title: Portable flow-report read-model — substrate-neutral governance visibility without a work-item binding
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/decisions/ADR-0042-portable-flow-report-read-model.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0037, ADR-0042]
supersedes: []
requires: []
tags: [flow-report, read-model, portability, substrate-neutrality, git, governance, visibility]
created: 2026-09-14
updated: 2026-09-14
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Portable flow-report read-model

## Summary

A `flow-report` is a **portable, read-only, versioned visibility profile** over
governed work: it renders the lifecycle state of a work-item binding and its
Git evidence into a stable document shape that consumers, dashboards, digests,
and humans can read without adopting GitHub (or any specific binding). It
**reports** state; it never transitions it. Per `ADR-0024`, a conforming
consumer may choose any single work-item binding; the report contract must make
that choice *visible* in every report, not accidental.

This spec defines the report contract only. The Git-native work-item decision
(native Git *creation* and *transition* of work items — branch-name and
commit-message inference) is **not** part of this contract and is decided
separately (see Acceptance criterion 7 and the boundary rationale in
`ADR-0042`).

## Goals

- A conforming report can be generated from **any conforming work-item binding
  plus Git evidence**, without a GitHub account, `gh`, or Projects v2.
- The report's governance profile is distinct from its (optional) planning
  profile; a reader can tell which sections are mandatory and which are
  advisory.
- The source boundary is explicit in every report: Git alone is **not** a
  work-item binding, and any consumer claiming full `FS-0018` lifecycle
  conformance must name a binding that provides the six substrate capabilities.
- State, findings, and traceability are reproducible, lossless, and
  evidence-backed.

## Non-Goals

- A universal project-management UI, scheduler, or service.
- Making GitHub, `gh`, Projects v2, or a GitHub account a core framework
  dependency (`ADR-0024`, `ADR-0037`).
- Implementing the GitHub binding field extension covered by the parent issue
  (`#145`).
- Defining Tais-Den's cadence, WIP limits, priority meanings, replenishment,
  rollover, or outcome policy in the framework.
- A Git-native work-item binding (creation/transition via branches, tags, or
  commit messages): explicitly out of scope, decided separately.
- Back-filling "work items" from branch names or commit messages

## Success Criteria

### SC-1: Report envelope

A conforming flow-report starts with an envelope containing, **mandatorily**:

- `schema_version` — the exact contract version this report conforms to
  (string, semver).
- `generated_at` — ISO-8601 timestamp of generation.
- `scope` — the repository, tree-ish (commit SHA) or tag, and path/object
  glob the report covers.
- `source_binding` — a machine-readable name and reference for the work-item
  binding used (or literal `none` when the report covers Git evidence only,
  with the conformance claim adjusted accordingly).
- `policy_version` — which framework version's gates and phase definitions
  the report interprets.

### SC-2: Governance profile (mandatory)

The report MUST include a governance section containing, for each work item
in scope:

- Identifier and external reference (URL or binding-native handle) when the
  item exists in a binding.
- `lifecycle_state` — the binding-native phase state reported **verbatim**
  (unset/invalid states represented losslessly as `unset` / `invalid`,
  never folded into a guessed value).
- `type_classification` — the item's Type axis (feature/bug/task/other) plus
  Phase axis, reported as stored.
- `evidence` — for each reported state, the exact artifact and location
  (file, section, commit, binding record) that backs the claim.
- `human_decisions_required` — a READ-ONLY queue of items awaiting a human
  decision (e.g. Approval checkpoint, `question` states). The report never
  acts on this queue; human interaction remains the binding's responsibility.

### SC-3: Planning profile (optional)

A report MAY carry a planning profile, but if present it MUST be structurally
separate from the governance profile (distinct section namespace) and MUST
be labelled advisory: priorities, estimates, and horizon labels are
binding/consumer policy, not framework facts. Nothing in a planning profile
may be required for FS-0018 conformance claims.

### SC-4: Traceability and findings semantics

- Every finding is evidence-backed: it cites one or more concrete source
  artifacts (file+section, commit, or binding record).
- `traceability` states distinguish **linked work items** (items that exist
  in a binding and are referenced) from **governed-document exceptions**
  (docs whose lifecycle evidence is self-contained).
- Unset and invalid states are rendered losslessly; the report does not
  coerce them into a value that could be mistaken for a real state.
- The report is deterministic for a fixed input: the same scope, binding
  snapshot, and revision produce byte-identical output.

### SC-5: Consumer conformance claim

A conforming report contains, or directly accompanies, an explicit statement
of which substrate capabilities the named source binding provides (per
`FS-0018`'s six capabilities: origin, classification, phase state, parked
state, approval record, transition record). A consumer may claim full
FS-0018 lifecycle conformance ONLY when all six are provided by the named
binding; a Git-only report MUST claim partial conformance at most.

### SC-6: Human-readable and machine-readable examples

The contract ships with two example outputs (in the plan implementing this
spec):

- one human-readable example (e.g. Markdown digest shape), and
- one machine-readable example (e.g. JSON shape),

both free of consumer-specific identifiers (no Tais-Den repo names, no
Tais-Den field names, no Tais-Den policy values).

## Out of Scope (explicit)

- Work-item creation, transition, approval, or closure BY the report.
- Inference of lifecycle state from branch names or commit messages.
- A Git-native work-item binding — decided separately (SC/Acceptance 7).
- Any new gate or CI dependency on the report contract.

## Plan Status

- Drafting the PLAN alongside this spec is not a departure:
  `workflows/document-lifecycle.md` places PLAN *creation* at "initial
  creation" and constrains only PLAN *approval* to come after the governing
  FS has been reviewed. The PLAN (PLAN-0041) is `draft`.
