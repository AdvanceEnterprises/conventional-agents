---
type: feature-spec
id: FS-0032
status: draft
title: ArcOps architecture-intent checker boundary — read-only pilot contract
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/decisions/ADR-0040-arcops-architecture-intent-checker-boundary.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0007, ADR-0024, ADR-0026, ADR-0040]
supersedes: []
requires: []
tags: [arcops, architecture-intent, read-only, boundary, contract, benchmark]
created: 2026-09-10
updated: 2026-09-10
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly required.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: ArcOps Architecture-Intent Checker Boundary

## Status

- Draft

## Summary

This spec defines the boundary contract for ArcOps, a read-only
architecture-intent checker that works alongside `conventional-agents` without
turning the framework into an application platform or a second source of
truth. The framework ships the contract; the pilot implementation lives in a
separate ArcOps repository and is measured by `#124` as an independent
experimental arm.

## Goals

- A consumer can run a read-only `check-plan` / `check-diff` against their
  repository and get a structured report citing the exact source artifacts
  (file, section, commit) behind each finding.
- The checker reports conflicts, severity, affected path, source citation,
  and uncertainty — it never rewrites, never transitions work items, and
  never approves or rejects merges.
- Git remains authoritative: the checker indexes the accepted corpus with
  revision identity and cites it; it does not maintain a second copy of the
  intent.
- The framework remains adoptable without ArcOps: no consumer must install
  the checker, and no framework gate or CI job depends on it.
- The pilot against `conventional-agents` and `pack-protocol` produces
  measurable false-positive, missed-conflict, and reviewer-usefulness data
  for `#124`.

## Non-Goals

- **A hosted service or runtime dependency.** The first slice is a local,
  read-only tool.
- **Automatic remediation.** The checker reports; it never rewrites files.
- **A new governance gate.** ArcOps is not wired into CI as a blocking check
  and does not gate pull requests.
- **Replacing Git as the source of truth.** Findings are diagnostics, not
  authority.
- **Generic chat or an approval mechanism.** ArcOps cannot produce an
  `ADR-0026` approval record.
- **Framework-core implementation.** The checker is not a framework script,
  a binding under `integrations/`, or a CI job in this repository.

## Users / Stakeholders

- Framework consumers who want architecture drift caught before review.
- Reviewers who want cited, structured conflict reports instead of
  re-deriving context.
- The `#124` benchmark, which measures the checker as an experimental arm.

## Interfaces

- Type: Documentation contract
- Details: `ADR-0040` records the decision; this spec defines the contract
  surface. The pilot implementation is consumer-side, in a separate ArcOps
  repository, and is not part of this repository's exported surface.

## Success Criteria

1. Given a repository with `docs/ARC42.md`, accepted ADRs, and approved
   FS/PLAN documents, when the checker runs `check-plan` against a proposed
   plan, then every finding cites the exact source artifact (file, section,
   and commit) it was derived from.
2. Given a proposed change that conflicts with an accepted ADR, when the
   checker runs, then the conflict is reported with a severity, an affected
   path, and an uncertainty value — and the checker exits without writing to
   the repository.
3. Given a repository with no `vendor/conventional-agents/` reference, when
   the checker runs, then the framework-presence question is not part of the
   report (the checker analyzes intent, not adoption).
4. Given a checker run, when the run completes, then no work item is created,
   transitioned, or commented on, and no merge is approved or rejected.
5. Given a consumer repository, when the consumer runs the framework's
   governance gates, then no gate depends on ArcOps existing or passing.
6. Given the pilot against `conventional-agents` and `pack-protocol`, when
   the pilot concludes, then false positives, missed conflicts, and reviewer
   usefulness are recorded in a form `#124` can consume.
7. Given a proposed diff, when `check-diff` runs, then the output shape is
   stable and machine-readable: conflict, severity, affected path, source
   citation, and uncertainty.

## Edge Cases

- A finding whose source artifact was edited after the finding was derived:
  the citation carries the commit, so the finding is reproducible or
  explicitly stale.
- A corpus with no accepted ADRs: the checker reports an empty intent index
  rather than failing or inventing intent.
- A proposed change that conflicts with a superseded ADR: the supersession
  chain (`FS-0028`) resolves the effective intent; the superseded record is
  not treated as binding.

## Out of Scope

- Cross-repo scaffolding or a standalone `ca doctor`-style package in this
  repository.
- Interactive remediation or fix-it mode.
- Checking consumer-specific conventions (those belong to the consumer).
- Milestone/iteration/priority planning checks (see `#145`/`#146` — the
  flow-report read-model is a separate capability).
- Any write path, including work-item creation or status transitions.

## Dependencies

- `ADR-0040` — the boundary decision this spec operationalises.
- `#124` — the benchmark that measures the pilot.
- `FS-0028` — the ADR supersession chain the checker relies on for effective
  intent.

## Rollout / Migration (if applicable)

- The contract ships with this repository's documentation surface.
- The pilot implementation is created in a separate ArcOps repository and
  runs against `conventional-agents` and `pack-protocol` as targets.

## Observability (if applicable)

- Logs: the pilot records per-run corpus revision, finding counts, and
  runtime.
- Metrics: false-positive rate, missed-conflict rate, reviewer-usefulness
  rating — consumed by `#124`.

## Security / Privacy (if applicable)

- Data handled: repository documents only; no credentials, no work-item
  content beyond what the repository already exposes.
- Threats considered: a checker that writes or approves would violate
  `ADR-0007`/`ADR-0026`; the read-only rule is structural.
- Mitigations: the first slice has no write path by construction.

## Open Questions

- Whether the ArcOps implementation repository should be governed by this
  framework's conventions (its own choice, not a framework requirement).
