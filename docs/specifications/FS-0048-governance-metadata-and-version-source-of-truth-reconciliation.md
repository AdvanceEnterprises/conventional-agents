---
type: feature-spec
id: FS-0048
status: draft
title: Governance metadata and version source-of-truth reconciliation
owner: ajoeofalltrades
test_required: true
interfaces:
  - "templates/core/adr-full-madr.md"
  - "workflows/document-lifecycle.md"
  - "docs/decisions/README.md"
  - "docs/decisions/ADR-*.md"
  - "scripts/check-freshness.sh"
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "package.json"
  - "test/FS-0048/**"
  - "README.md"
  - "AGENTS.md"
  - "INTEGRATION.md"
  - "docs/specifications/FS-0048-governance-metadata-and-version-source-of-truth-reconciliation.md"
  - "docs/change-plans/PLAN-0054-implement-fs-0048-governance-metadata-and-version-reconciliation.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0015
  - ADR-0026
  - ADR-0027
  - ADR-0030
supersedes: []
requires:
  - FS-0027
tags: [metadata, versioning, adr, freshness, index, source-of-truth]
created: 2026-10-05
updated: 2026-10-05
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
# Feature Spec: Governance metadata and version source-of-truth reconciliation

## Status

- Draft

## Plan Status

- **PLAN-0054 is `draft`.** The initial package contains this spec, its plan,
  index rows, and a draft CHANGELOG entry only. It does not authorize any
  template, lifecycle, script, corpus, index, or marker change.
- The implementation touches ADR-0027 reserved paths (`docs/decisions/`,
  `scripts/`, `package.json`). Implementation requires an approved FS and PLAN
  plus a separate recorded human approval for the exact reserved-path
  `touches:` set under ADR-0026/ADR-0027.

## Summary

The framework's governance metadata contract is split across lifecycle prose,
templates, validation scripts, and index tables, and several sources disagree
(audited at trunk `d0f8029`, issue #212): the ADR template omits the `updated:`
field while `workflows/document-lifecycle.md` requires it on every FS, PLAN,
and ADR change; the freshness gate does not scan `docs/decisions/`, and only 8
of 43 ADRs carry the field; `INTEGRATION.md` displays version `2.0.0` while
`package.json`, `README.md`, and `AGENTS.md` display `2.1.0`; and the ADR
status vocabulary and FS/PLAN index ordering differ across documents. This
spec defines the reconciliation: one `updated:` metadata policy per document
type, one framework-version authority with validated display markers, and one
ADR status vocabulary plus a documented index-ordering rule.

## Goals

- Make the ADR `updated:` policy explicit and consistent across the lifecycle
  document, the canonical ADR template, the freshness coverage, and the ADR
  corpus.
- Establish `package.json` `version` as the single framework-version authority
  and reconcile every displayed version marker to it, with a check that fails
  on disagreement.
- Align the ADR status vocabulary across `docs/decisions/README.md`, the
  lifecycle document, and the ADR template; document and normalize FS/PLAN
  index ordering.
- Keep every change metadata/structure-only: no document-history rewrites, no
  body edits, no lifecycle-state changes.

## Non-Goals

- Rewriting document history, or treating a metadata-only backfill as
  substantive content drift.
- Making age-based freshness warnings into merge blockers.
- Changing FS/PLAN/ADR lifecycle states, approval semantics, or the reserved
  path set.
- Extending the history-aware content-versus-metadata detection (the #183 /
  #206 line of work); this spec covers the static contract only.

## Users / Stakeholders

- Framework maintainers who author governed documents and reconcile the
  corpus.
- Consumers who rely on the exported surface for one unambiguous metadata and
  version story.
- Reviewers who need a single documented rule to check against instead of
  three disagreeing sources.

## Interfaces

- Type: templates, workflow current-state documentation, index tables,
  offline validation checks, npm script registration.
- Details:
  - `templates/core/adr-full-madr.md` gains the `updated:` front-matter field
    so the scaffold matches the lifecycle requirement.
  - `scripts/check-freshness.sh` extends its governed-doc coverage so
    `docs/decisions/` is evaluated under the same `updated:` policy, naming
    the governing rule in every finding.
  - `scripts/check-status.sh` index validation extends to flag out-of-order
    index rows, and the status vocabulary checks reflect the aligned closed
    set.
  - `package.json` registers a new or extended validation entry point if one
    is required; `scripts/README.md` documents it.
  - `README.md`, `AGENTS.md`, and `INTEGRATION.md` display markers reconciled
    to the single authority; the validating check fails when any marker
    disagrees.
  - `docs/decisions/README.md`, `docs/specifications/README.md`,
    `docs/change-plans/README.md`, and `workflows/document-lifecycle.md`
    carry the vocabulary and ordering rules.
  - `test/FS-0048/**` holds fixture-driven coverage for the checks.

## Success Criteria

- **SC-1 — template parity.** Given a fresh ADR created from the canonical
  template, when the metadata policy runs, then it carries the same `updated:`
  requirement as FS and PLAN documents and passes it.
- **SC-2 — ADR freshness coverage.** Given the ADR corpus, when the freshness
  check runs, then every ADR under `docs/decisions/` is evaluated for
  `updated:` and any finding names the governing rule; after reconciliation
  there are zero missing-field findings.
- **SC-3 — bounded corpus reconciliation.** Given the reconciled repository,
  when `npm run check:status`, `npm run check:freshness`, and
  `npm run lint:docs` run, then all pass; the ADR backfill is limited to front
  matter and no document body or history is rewritten.
- **SC-4 — single version authority.** Given `package.json` `version` as the
  authority, when display markers are compared, then `README.md`, `AGENTS.md`,
  and `INTEGRATION.md` each display the same version, and a fixture with a
  disagreeing marker makes the validating command exit non-zero.
- **SC-5 — vocabulary parity.** Given `docs/decisions/README.md`,
  `workflows/document-lifecycle.md`, and the ADR template, when their ADR
  status lists are compared, then they define the same closed set —
  `Proposed`, `Accepted`, `Rejected`, `Deprecated`, `Superseded` — as the
  allowed values.
- **SC-6 — index ordering.** Given the FS and PLAN index tables, when the
  ordering validation runs, then rows are ascending by numeric ID, gaps from
  skipped numbers are allowed, the ordering rule is documented in both index
  READMEs, and a fixture with a deliberately swapped pair is flagged.
- **SC-7 — no scope creep.** Given the implementation diff, when it is
  reviewed, then it contains no FS/PLAN/ADR status transition, no lifecycle
  semantics change, no workflow-file edit, and no history rewrite; the
  reserved-path approval is recorded before any reserved file is changed.
- **SC-8 — separation maintained.** Given the implemented checks, when they
  run, then the static metadata/vocabulary/ordering contract is evaluated
  independently of the history-aware freshness detection, which remains a
  distinct capability.

## Edge Cases

- An ADR added as `proposed` in the same PR as the template change still
  carries `updated:` and passes SC-1.
- A skipped spec number (for example FS-0025, FS-0032) does not count as
  ordering drift; ordering is ascending by number, not contiguous.
- A version bump shipped in the same PR as the marker reconciliation must
  agree with the authority at the pushed head; the check reads the authority
  from the checked-out tree, not from a cached value.
- An ADR whose front matter cannot be parsed fails closed under SC-2 rather
  than being skipped.

## Out of Scope

- Consumer-repository metadata policies; this spec governs the framework's own
  corpus and exported markers only.
- Automated version generation or release tooling; the chosen mechanism is
  validation, not generation.
- Any modification to `docs/decisions/ADR-*.md` beyond the front-matter
  `updated:` backfill.

## Dependencies

- FS-0027 — the existing freshness gate this coverage extension completes.
- FS-0008 — the self-versioning intent this authority statement makes
  checkable.
- ADR-0015 — tool/location boundaries for any new or extended check.
- ADR-0026 / ADR-0027 — approval and reserved-path routing for the
  implementation.
- ADR-0030 — the decision-records-versus-current-state split this
  reconciliation preserves.

## Open Questions

None. The policy choices (ADRs carry `updated:`; `package.json` is the version
authority; the five-value status set; ascending index order) are specified
above, and the implementation revision re-measures corpus counts before the
backfill.
