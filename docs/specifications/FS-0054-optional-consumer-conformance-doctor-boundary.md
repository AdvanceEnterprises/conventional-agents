---
type: feature-spec
id: FS-0054
status: draft
title: Optional consumer conformance doctor — standalone package boundary and clean-adopter checks
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
related_adrs: [ADR-0015, ADR-0033]
supersedes: []
requires: [FS-0034]
tags: [conformance, consumer, diagnostics, adoption, doctor, clean-adopter, read-only]
created: 2026-10-27
updated: 2026-10-28
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

# Feature Spec: Optional consumer conformance doctor — standalone package boundary and clean-adopter checks

## Status

- Draft

## Plan Status

- No PLAN exists yet.
- This is a proposal-class spec for issue [#142](https://github.com/AdvanceEnterprises/conventional-agents/issues/142); implementation is blocked until the spec reaches `approved` and a governing PLAN is approved.

## Summary

Adopting repositories drift from the framework contract (vendored pin stale, gates misconfigured, conventions diverged) with no cheap, repeatable check. `FS-0034` shipped the first in-framework slice (`scripts/check-conformance.sh`) as read-only diagnostics. The remaining open questions are architectural:

1. Does a richer `ca doctor` / `ca init` utility belong in the framework repository or in a separate conformance project/package?
2. What checks turn the clean-adopter fixture and real consumer audits into a reproducible gap report?

This spec answers those questions. It keeps the core framework vendorable and adoptable without installing the optional tool. The doctor remains read-only: it reports gaps; it never rewrites architecture, approves work, or replaces Git as the source of truth.

## Goals

- Decide and document whether the richer conformance doctor belongs in `scripts/` or in a separate conformance repository/package.
- Define the check list for a clean-adopter fixture and at least one real consumer: vendored pin freshness, required anchors, `config/gates.yml` presence and reserved-path plausibility, status-gate runnability, and convention-document presence.
- Define stable, human-readable and machine-readable output plus exit-code semantics.
- Keep all writes opt-in, explicit, and reviewable; Git remains the source of truth.
- Ensure the core framework remains adoptable without installing the optional doctor.

## Non-Goals

- A hosted service or runtime dependency.
- Automatic remediation or fix-it mode.
- Replacing Git, governance gates, or recorded approvals as authority.
- Checking consumer-specific conventions or planning policy (those belong to the consumer).
- Duplicating the first-slice implementation already covered by `FS-0034`.

## Users / Stakeholders

- New consumers bootstrapping from the clean-adopter fixture.
- Existing consumers running periodic drift checks.
- Framework maintainers validating that real consumers can upgrade safely.

## Interfaces

- `docs/specifications/README.md` and `docs/change-plans/README.md` — index rows for this spec and its future PLAN.
- `FS-0034` — the first-slice script this spec builds on; no direct path change is implied by this draft.

## Success Criteria

### SC-1: Ownership boundary is decided

Given this spec reaches `approved`, it records one of the following ownership choices with rationale:

- The richer doctor remains in the framework repository (evolving `scripts/check-conformance.sh` or a sibling script).
- The richer doctor moves to a separate conformance repository/package, with a documented vendoring/coupling model to the framework.

### SC-2: Check list is documented and fixture-backed

Given the chosen boundary, the spec enumerates checks for:

- Vendored framework reference freshness (commit or semver pin not stale).
- Presence and plausibility of required anchors (`AGENTS.md`, `INTEGRATION.md`).
- Presence of `config/gates.yml` and reserved-path configuration.
- Runnability of the governance status gate in the consumer repository.
- Presence of convention documents the consumer is expected to vendor.

### SC-3: Output contract and exit codes

Given a doctor invocation, it produces:

- A human-readable gap report by default.
- A machine-readable report (`--json`) with stable fields: `tool`, `target`, `conformant`, `finding_count`, `findings`.
- Exit codes: `0` = conformant, `1` = findings, `2` = usage or run failure.

### SC-4: Optional adoption

Given a consumer repository without the doctor installed, the core framework gates and documents remain sufficient for adoption. The doctor is optional tooling, not a required governance gate.

### SC-5: No silent writes

Given any doctor implementation, its source contains no mutating operation against the work-item substrate or the local repository: no issue/PR/label/field writes, no merges, no file rewrites, unless the user explicitly invokes a separate, documented opt-in command outside the doctor's read-only mode.

### SC-6: Validated against a clean-adopter fixture and one real consumer

Given the design is approved, a prototype is validated against the clean-adopter fixture and at least one existing real consumer, and the validation results are referenced from the implementing work item.

## Edge Cases

- A consumer with no vendored framework reference receives a `critical` `framework-presence` finding.
- A dangling `vendor/conventional-agents/<path>` reference in `AGENTS.md` or `INTEGRATION.md` is reported as a `dangling-reference` finding.
- Unknown arguments exit `2` with a usage message; `--help` exits `0`.

## Out of Scope

- The first-slice `scripts/check-conformance.sh` implementation already delivered by `FS-0034`.
- Cross-repo scaffolding or migration automation.
- Planning-field checks (Priority, Iteration, Milestone) — those belong to `FS-0036`.
- Any write path that is not explicit, opt-in, and reviewable.

## Dependencies

- `FS-0034` — the first in-framework conformance-doctor slice.
- `ADR-0015` — Tool taxonomy and introduction process (governs tool location and category boundaries).
- `ADR-0033` — caller-relative portable gates and configuration.
- The clean-adopter fixture referenced in issue #142 and the framework's exported `integrations/` surface.
- Issue [#142](https://github.com/AdvanceEnterprises/conventional-agents/issues/142).

## Rollout / Migration

- This spec introduces no new code. The first implementation PR will evolve or split the doctor after this FS and its PLAN are approved.
- Consumers who already run `FS-0034` continue to work; richer checks arrive as an optional addition.

## Open Questions

- Does the richer doctor stay in-framework or move to a separate package? This spec intentionally leaves the decision open pending human review.
