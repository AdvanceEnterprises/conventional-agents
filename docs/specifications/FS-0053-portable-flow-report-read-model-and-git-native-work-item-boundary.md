---
type: feature-spec
id: FS-0053
status: draft
title: Portable flow-report read-model and Git-native work-item boundary
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "docs/decisions/ADR-0042-portable-flow-report-read-model.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0030, ADR-0037, ADR-0042]
supersedes: []
requires: [FS-0018, FS-0035]
tags: [flow-report, read-model, work-item-binding, substrate-neutrality, git, governance, visibility]
created: 2026-10-27
updated: 2026-10-27
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

# Feature Spec: Portable flow-report read-model and Git-native work-item boundary

## Status

- Draft

## Plan Status

- No PLAN exists yet.
- This is a proposal-class spec for issue [#146](https://github.com/AdvanceEnterprises/conventional-agents/issues/146); implementation is blocked until the spec reaches `approved` and a governing PLAN is approved.

## Summary

Work items currently live in more than one substrate (GitHub Issues, Projects boards, tick digests, and possibly native Git artifacts). There is no portable, read-only read-model for "what is the current state of work item X", and no explicit framework decision on whether a Git-native binding can ever satisfy the six substrate capabilities defined by `FS-0018`.

This spec defines:

1. A **portable `flow-report` read-model** that the maintenance tick emits per work item, containing only the fields that can be derived from every conforming substrate or stated explicitly when a field is unset/invalid.
2. The **Git-native work-item boundary decision**: whether pure Git can be a conforming work-item binding, and if not, what minimal substrate capability it can and cannot provide.

The read-model is derived data. Git remains authoritative only for Git artifacts (commits, branches, tags, pull requests). Issues, boards, and digests stay where they are. The report makes governance state visible without making GitHub a core framework dependency.

## Goals

- A conforming `flow-report` can be generated from any conforming work-item binding plus Git evidence, without requiring GitHub, `gh`, or Projects v2.
- The report's governance profile is distinct from its optional planning profile; a reader can tell which sections are mandatory and which are advisory.
- The read-model is lossless: unset and invalid states are represented explicitly, never folded into a guessed value.
- The Git-native work-item boundary is recorded as an explicit framework decision, separate from the report contract.
- The read-model is deterministic for a fixed binding snapshot: the same inputs produce byte-identical output except for `generated_at`.

## Non-Goals

- A universal project-management UI, scheduler, or hosted service.
- Making GitHub, `gh`, Projects v2, or a GitHub account a core framework dependency.
- Defining any consumer's cadence, WIP limits, priority meanings, replenishment, rollover, or outcome policy.
- Implementing the GitHub binding field extension covered by the parent issue (#145); that belongs to `FS-0036`.
- Back-filling work items from branch names or commit messages unless the Git-native binding decision explicitly authorizes it.

## Users / Stakeholders

- Maintenance tick authors who reconcile the board and emit digests.
- Watch jobs and rollups that consume governance state.
- Consumers who cannot or will not use GitHub as their work-item binding.
- Reviewers deciding whether pure-Git consumers can claim `FS-0018` lifecycle conformance.

## Interfaces

- `docs/specifications/README.md` and `docs/change-plans/README.md` — index rows for this spec and its future PLAN.
- `docs/decisions/ADR-0042-portable-flow-report-read-model.md` — the boundary rationale this spec extends with the Git-native work-item question.

## Success Criteria

### SC-1: Report envelope

Given a conforming generator run, the emitted report starts with an envelope containing mandatorily:

- `schema_version` — the exact contract version (semver string).
- `generated_at` — ISO-8601 timestamp of generation.
- `scope` — repository, tree-ish (commit SHA) or tag, and path/object glob covered.
- `source_binding` — machine-readable name and reference for the work-item binding used, or literal `none` when the report covers Git evidence only.
- `policy_version` — the framework version whose gates and phase definitions the report interprets.

### SC-2: Work-item read-model

Given the tick runs against a conforming work-item binding, the emitted JSON contains, for every in-scope work item:

- `id` — the work-item identifier.
- `substrate` — the binding-native substrate name.
- `status` — the binding-native phase state, represented verbatim; unset/invalid states are `unset`/`invalid`.
- `owner` — the accountable party as recorded by the binding.
- `last_touched` — ISO-8601 timestamp of the most recent binding-native or Git evidence.
- `hra` — boolean or list of human-required actions awaiting a human.
- `links` — URLs or binding-native handles for the item and its Git evidence.

### SC-3: Determinism and lossless state

Given a fixed binding snapshot and revision, when the report is generated twice, the two outputs are byte-identical except for `generated_at`. Unset and invalid substrate fields are rendered as `unset` and `invalid` respectively, never coerced into a guessed lifecycle value.

### SC-4: Git-native boundary decision

Given this spec reaches `approved`, the repository contains a separate governed record (this spec or a companion ADR) that explicitly answers:

- Which of the six `FS-0018` substrate capabilities pure Git can provide.
- Which capabilities it cannot provide.
- Whether a Git-only consumer may claim partial, full, or no `FS-0018` lifecycle conformance.

### SC-5: Human decisions queue is read-only

Given a report that includes items awaiting human action, the `human_decisions_required` queue is present and read-only. The report never transitions work-item state, assigns owners, or writes to a substrate.

### SC-6: Examples without consumer-specific identifiers

Given the contract is documented, it is accompanied by one human-readable example and one machine-readable example, both free of consumer-specific identifiers, cadence, field names, repository rotation, or policy values imported from any consumer digest.

## Edge Cases

- A work item referenced in Git evidence but absent from the binding is reported as a `governed-document exception` with traceability, not as a binding work item.
- A work item present in two substrates is represented once per substrate with a documented canonical-status precedence rule.
- A `source_binding: none` report carries a partial-conformance claim at most and does not imply full `FS-0018` conformance.

## Out of Scope

- Work-item creation, transition, approval, or closure by the report.
- Inference of lifecycle state from branch names or commit messages unless a Git-native binding decision explicitly authorizes and documents the inference rule.
- A Git-native work-item binding implementation (this spec records the decision and contract; a follow-on PLAN would implement it).
- Any new gate or CI dependency on the report contract.

## Dependencies

- `FS-0018` — the six substrate capabilities that define a conforming work-item binding.
- `FS-0035` — the existing portable flow-report read-model contract this spec extends with the Git-native boundary.
- `ADR-0024` — platform-neutral core with shipped bindings.
- `ADR-0026` — approval is a recorded act; evidence requirement.
- `ADR-0037` — executable binding boundary.
- `ADR-0042` — the report as a visibility profile, not a seventh capability.
- Issue [#146](https://github.com/AdvanceEnterprises/conventional-agents/issues/146).

## Rollout / Migration

- This spec introduces no code; the first implementation PR will add the generator and examples after both this FS and its PLAN are approved.
- Consumers vendoring the framework receive no breaking change until they opt into the new report contract.

## Open Questions

- Should the Git-native boundary be recorded in this FS's own front matter (`related_adrs:`) or in a new ADR? This spec deliberately references `ADR-0042` and leaves the choice to the first review cycle.
