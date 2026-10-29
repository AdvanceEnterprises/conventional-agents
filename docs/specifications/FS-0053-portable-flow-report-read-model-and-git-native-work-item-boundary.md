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
updated: 2026-10-29
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
- **Prerequisite before this spec advances past `draft`:** the Git-native boundary decision must be recorded in an `accepted` companion ADR in `docs/decisions/` (see `SC-4`). `ADR-0042` defers that decision and cannot stand in for it.
- **Transitive prerequisite:** `requires: [FS-0018, FS-0035]` means this spec inherits their readiness. `FS-0018` is `implemented`; `FS-0035` is `status: draft`, so `FS-0053` cannot advance to `approved` ahead of `FS-0035`, and the `SC-2` projection above is re-checked against `FS-0035`'s finalized `SC-2` at that point.

## Summary

Work items currently live in more than one substrate (GitHub Issues, Projects boards, tick digests, and possibly native Git artifacts). There is no portable, read-only read-model for "what is the current state of work item X", and no explicit framework decision on whether a Git-native binding can ever satisfy the six substrate capabilities defined by `FS-0018`.

This spec adds two things to the contract owned by `FS-0035`:

1. A **per-work-item read-model projection** that the maintenance tick emits for every in-scope work item, containing only the fields that can be derived from every conforming substrate or stated explicitly when a field is unset/invalid. The report envelope, determinism rule, planning-profile separation, and conformance-claim rule remain `FS-0035`'s contract and are not redefined here.
2. The **Git-native work-item boundary decision**: whether pure Git can be a conforming work-item binding, and if not, what minimal substrate capability it can and cannot provide.

The read-model is derived data. Git remains authoritative only for Git artifacts (commits, branches, tags, pull requests). Issues, boards, and digests stay where they are. The report makes governance state visible without making GitHub a core framework dependency.

### Spec ownership relative to `FS-0035`

`FS-0035` ("Portable flow-report read-model — substrate-neutral governance visibility without a work-item binding") owns the **base read-model contract**: the mandatory envelope (`FS-0035` `SC-1`), lossless and deterministic rendering (`FS-0035` `SC-4`), planning-profile separation (`FS-0035` `SC-3`), and the conformance-claim rule (`FS-0035` `SC-5`).

This spec owns only:

- the **per-work-item projection** in `SC-2` — the field set a report needs in order to describe the items of a named work-item binding — and
- the **Git-native boundary decision** in `SC-4`, which `FS-0035` explicitly excludes from its own scope.

Where the two specs appear to disagree, `FS-0035` governs the base contract and this spec must be corrected to match it. This spec never supersedes, narrows, or reinterprets an `FS-0035` success criterion, and both drafts must stay consistent when either one changes.

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
- `docs/decisions/ADR-0042-portable-flow-report-read-model.md` — the report-as-visibility-profile decision this spec builds on. Its Decision 6 defers the Git-native work-item question, so it is context for `SC-4`, not the record that satisfies it.

## Success Criteria

### SC-1: Report envelope (owned by `FS-0035`)

The mandatory envelope is `FS-0035`'s `SC-1` and is **not** redefined here; a report conforming to this spec carries that envelope unchanged. The fields are restated below only as the context the `SC-2` projection attaches to. This restatement is non-normative context: if `FS-0035`'s `SC-1` envelope changes, `FS-0035` governs and this criterion is corrected to match.

Given a conforming generator run, the emitted report starts with an envelope containing mandatorily:

- `schema_version` — the exact contract version (semver string).
- `generated_at` — ISO-8601 timestamp of generation.
- `scope` — repository, tree-ish (commit SHA) or tag, and path/object glob covered.
- `source_binding` — machine-readable name and reference for the work-item binding used, or literal `none` when the report covers Git evidence only.
- `policy_version` — the framework version whose gates and phase definitions the report interprets.

### SC-2: Work-item read-model

Given the tick runs against a conforming work-item binding, the emitted JSON contains one projection record for every in-scope artifact (work items, or `governed-document exceptions` when `source_binding` is `none`, per `FS-0035` `SC-2`; the enclosing report envelope remains `FS-0035`'s `SC-1`). Each record is the `FS-0035` `SC-2` governance record for that artifact **carried unchanged**, plus the projection-only fields this spec adds. `FS-0035`'s field names and semantics govern; this spec renames and drops nothing.

Carried unchanged from `FS-0035` `SC-2` (all mandatory on every projection record):

- `id` and `links` — together realize `FS-0035`'s "identifier and external reference" bullet: `id` is the work-item identifier, and `links` carries the URL or binding-native handles for the item and its Git evidence.
- `lifecycle_state` — the binding-native phase state reported verbatim; unset/invalid states are represented losslessly as `unset`/`invalid`, never folded into a guessed value. `FS-0035` names this field `lifecycle_state`, and so does this spec; `status` is not an alias for it anywhere in the report.
- `type_classification` — the item's Type axis (feature/bug/task/other) plus Phase axis, as stored by the binding.
- `evidence` — for each reported state, the exact artifact and location (file, section, commit, binding record) that backs the claim. Required on every projection record, not optional: approval state is evidenced per `ADR-0026`, where approval is a recorded act.
- `human_decisions_required` — a READ-ONLY boolean-or-list marker of human-required actions awaiting a human decision. This is the same canonical field name used by `FS-0035` `SC-2` and by `SC-5` below; no shorter alias exists.

Projection-only fields (added here, absent from `FS-0035` `SC-2`):

- `substrate` — the binding-native substrate name.
- `owner` — the accountable party as recorded by the binding.
- `last_touched` — ISO-8601 timestamp of the most recent binding-native or Git evidence.

### SC-3: Determinism and lossless state (inherited from `FS-0035`)

Determinism and lossless rendering are `FS-0035`'s `SC-4`; this spec restates them only to bind the per-work-item fields introduced in `SC-2`.

Given a fixed binding snapshot and revision, when the report is generated twice, the two outputs are byte-identical except for `generated_at`. Unset and invalid substrate fields are rendered as `unset` and `invalid` respectively, never coerced into a guessed lifecycle value. If `FS-0035`'s determinism rule changes, `FS-0035` governs and this criterion is corrected to match.

### SC-4: Git-native boundary decision (companion ADR prerequisite)

Given this spec advances past `draft`, a companion ADR in `docs/decisions/` is `accepted` and explicitly answers:

- Which of the six `FS-0018` substrate capabilities pure Git can provide.
- Which capabilities it cannot provide.
- Whether a Git-only consumer may claim partial, full, or no `FS-0018` lifecycle conformance.

`ADR-0042` does **not** satisfy this criterion. Its Decision 6 records that the Git-native question "is recorded separately from this contract and is NOT decided here", and its Consequences leave that question "open as a separate bounded decision". The companion ADR must therefore be authored and accepted on its own merits; this draft does not assert that the decision exists, and `SC-4` fails until such an ADR is `accepted`.

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

- `FS-0018` — the six substrate capabilities that define a conforming work-item binding (`implemented`).
- `FS-0035` — the existing portable flow-report read-model contract this spec extends; `FS-0035` owns the base contract (envelope, determinism, planning profile, conformance claim) and this spec adds only the per-work-item projection and the Git-native boundary decision. `FS-0035` is `draft` at this revision, so the transitive prerequisite recorded in `Plan Status` applies.
- `ADR-0024` — Platform-neutral core with shipped bindings.
- `ADR-0026` — Approval is a recorded act (source of the mandatory `evidence` field in `SC-2`).
- `ADR-0037` — Executable layer for the GitHub binding (the executable-binding boundary).
- `ADR-0042` — Portable flow-report read-model — visibility profile, not a seventh capability (the report reports state; it is not a seventh substrate capability and not a work-item binding).
- Issue [#146](https://github.com/AdvanceEnterprises/conventional-agents/issues/146).

ADR titles above are verbatim from `docs/decisions/`; text in parentheses after a title is a non-normative gloss on why the decision matters to this spec.

## Rollout / Migration

- This spec introduces no code; the first implementation PR will add the generator and examples after both this FS and its PLAN are approved.
- Consumers vendoring the framework receive no breaking change until they opt into the new report contract.

## Open Questions

- The **content** of the Git-native boundary decision — which of the six `FS-0018` capabilities pure Git can provide — remains open. `SC-4` fixes only its venue: an `accepted` companion ADR in `docs/decisions/` that this spec then references from `related_adrs:`.
