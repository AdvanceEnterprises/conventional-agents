---
type: feature-spec
id: FS-0045
status: draft
title: Accepted-ADR authority check for current-state guidance
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-adr-authority.sh"
  - "scripts/README.md"
  - "scripts/run-validation.sh"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0045/**"
  - "INTEGRATION.md"
  - "README.md"
  - "AGENTS.md"
  - "CONTRIBUTING.md"
  - "guidelines/**/*.md"
  - "roles/*.md"
  - "skills/**/*.md"
  - "templates/**/*.md"
  - "workflows/*.md"
  - "integrations/**/*.md"
  - "runbooks/**/*.md"
  - "docs/ARC42.md"
  - "docs/specifications/FS-0045-accepted-adr-authority-check.md"
  - "docs/change-plans/PLAN-0051-implement-fs-0045-accepted-adr-authority-check.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0009
  - ADR-0015
  - ADR-0024
  - ADR-0026
  - ADR-0027
  - ADR-0030
  - ADR-0033
supersedes: []
requires: []
tags: [adr-authority, current-state, validation]
created: 2026-10-04
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
# Feature Spec: Accepted-ADR authority check for current-state guidance

## Status

- Draft

## Plan Status

- **PLAN-0051 is `draft`.** The initial package contains this spec, its plan,
  index rows, and a draft CHANGELOG entry only. It does not authorize the
  checker, tests, npm registration, or CI changes.
- The implementation touches `scripts/` and `package.json`, which are reserved
  by ADR-0027. Implementation requires an approved FS and PLAN plus a separate
  recorded human approval for the exact reserved-path `touches:` set under
  ADR-0026/ADR-0027.

## Summary

Current-state and exported guidance must not present a proposed, rejected,
deprecated, or superseded Architecture Decision Record as binding policy. This
spec defines a read-only, offline check that resolves ADR references in the
framework's reusable current-state surface against ADR front matter, requires an
explicit machine-readable annotation for non-normative references, and reports
any unresolved or unqualified non-accepted reference. It does not accept ADRs or
infer normative meaning from natural language.

## Goals

- Treat `status: accepted` as the only binding ADR status for current-state
  guidance.
- Detect non-accepted and unresolved ADR references before they are presented
  as current policy.
- Preserve legitimate proposal discussion, examples, and historical records
  through explicit, reviewable annotations.
- Keep the check deterministic, read-only, and independent of GitHub or other
  hosted services.

## Non-Goals

- Automatically accepting, rejecting, deprecating, or superseding an ADR.
- Inferring intent from prose or deciding whether a sentence is normative.
- Rewriting ADR, FS, PLAN, or CHANGELOG history to remove accurate historical
  references.
- Changing the repository's ADR approval process or precedence order.
- Editing the CI workflow; the existing workflow's call to canonical validation
  is verified as a read-only input.

## Users / Stakeholders

- Framework maintainers authoring current-state guidance.
- Consumers who rely on the exported framework surface as the instructions in
  force.
- Reviewers checking that a proposed decision has not been promoted to policy
  without human acceptance.

## Interfaces

- Type: Offline CLI governance check, npm script, and canonical validation-runner
  integration.
- Details:
  - `scripts/check-adr-authority.sh` resolves ADR IDs and front-matter status,
    scans the documented current-state/exported Markdown surface, and reports
    findings without modifying files.
  - `package.json` registers `check:adr-authority`; `scripts/run-validation.sh`
    invokes it as part of canonical local validation. The existing
    `.github/workflows/lint-docs.yml` `validation` job invokes `npm run validate`
    and is read-only verification evidence; this feature does not edit the
    workflow or add a separate CI job.
  - `scripts/README.md` documents scope, exception annotations, and remediation.
  - `test/FS-0045/**` covers accepted, non-accepted, unresolved, annotated, and
    excluded-reference cases using temporary repository fixtures.
  - Current-state documents and generated runtime skill copies that contain a
    non-accepted normative reference are corrected or explicitly annotated.

The scan surface is Markdown under `guidelines/`, `roles/`, `skills/`,
`templates/`, `workflows/`, `integrations/`, `runbooks/`, and `scripts/`, plus
root `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, and `INTEGRATION.md`, and the
current architecture document `docs/ARC42.md`. Exclude `docs/decisions/**`
(including its status index), `docs/specifications/**`, `docs/change-plans/**`,
`docs/proposals/**`, `docs/orchestration/**`, `docs/validation-baseline.md`,
CHANGELOG, backlog, and test records: they are decision, proposal, or historical
records rather than current reusable instructions.

Every ADR reference in the scan surface is authoritative by default. A
non-accepted reference is permitted only when that exact ID is immediately
followed by a machine-readable HTML annotation in this form:
`<!-- ca-adr-reference: ADR-NNNN; context=proposal-only -->`, with `context`
set to exactly one of `proposal-only`, `historical`, `example`, or `rejected`.
The annotation records context; it does not make the referenced ADR binding.

## Success Criteria

- **SC-1 — accepted references pass.** Given a fixture repository with a
  current-state document referencing an ADR whose front matter says
  `status: accepted`, when the checker runs, then it exits zero and reports no
  authority finding.
- **SC-2 — unqualified non-accepted references fail.** Given a current-state
  document referencing an ADR whose status is `proposed`, `rejected`,
  `deprecated`, or `superseded` without the required annotation, when the checker
  runs, then it exits non-zero and reports the ADR ID, source path, resolved
  status, and action to remove the normative claim or add a truthful
  non-normative annotation.
- **SC-3 — unresolved references fail.** Given a current-state document
  referencing an ADR ID that cannot be resolved to exactly one ADR record, when
  the checker runs, then it exits non-zero and identifies the ID and source
  path.
- **SC-4 — explicit non-normative contexts remain possible.** Given a
  non-accepted ADR reference immediately followed by one of the defined context
  annotations, when the checker runs, then it does not report that reference as
  normative; malformed, mismatched, or unsupported annotations fail with a
  diagnostic.
- **SC-5 — scope is bounded.** Given identical unannotated references in a
  current-state file, `docs/ARC42.md`, and in an excluded ADR, decision index,
  FS, PLAN, CHANGELOG, proposal, backlog, or test record, when the checker runs,
  then the current-state references are evaluated and the excluded records are
  not.
- **SC-6 — no mutation or hosted dependency.** Given a fixture containing any
  finding, when the checker runs, then the repository tree is byte-identical
  before and after and the checker makes no network or GitHub call.
- **SC-7 — validation wiring is complete.** Given a clean checkout, when
  `npm run check:adr-authority`, `npm run validate`, and the existing
  pull-request validation workflow are inspected, then the standalone command
  and canonical runner invoke the same checker, the workflow invokes that
  runner, and the checker fails when SC-2 or SC-3 is present.
- **SC-8 — current guidance is consistent.** Given the implementation is
  complete, when the checker runs against the repository's full current-state
  surface, then it reports no unqualified non-accepted or unresolved ADR
  references, and every exception has the explicit annotation required by
  SC-4.

## Edge Cases

- A reference to an accepted ADR is allowed even if it shares a line with a
  separately annotated proposal reference.
- A malformed ADR front matter status is not accepted and must fail closed.
- A duplicate ADR ID is unresolved for this check and must be reported rather
  than selecting a file by sort order.
- A reference in a generated runtime skill copy is checked just like its source
  skill; source and generated copy must agree.

## Out of Scope

- Live branch-protection or repository-ruleset inspection.
- Classification of consumer repositories or consumer-owned ADR namespaces.
- Automatically updating a current-state document when an ADR changes status.

## Dependencies

- Accepted ADR-0030 defines the distinction between immutable decision records
  and current-state documents.
- ADR-0027 reserves the script, package manifest, and workflow paths; its
  approval boundary applies to implementation.

## Open Questions

None. The annotation vocabulary and scan surface are explicit in this spec.
