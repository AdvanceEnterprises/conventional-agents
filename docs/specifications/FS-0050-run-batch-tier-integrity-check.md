---
type: feature-spec
id: FS-0050
status: approved
title: Run-batch tier-integrity check
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-run-batch.sh"
  - "test/FS-0050/**"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "docs/specifications/FS-0050-run-batch-tier-integrity-check.md"
  - "docs/change-plans/PLAN-0056-implement-fs-0050-run-batch-tier-integrity-check.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0045, ADR-0026, ADR-0027, ADR-0012]
supersedes: []
requires: []
tags: [runs, batch-approval, tier-integrity, detection, governance]
created: 2026-10-13
updated: 2026-10-13
---

# Feature Spec: Run-batch tier-integrity check

## Status

- Approved

## Summary

ADR-0045 makes the *run* the unit of bounded autonomous work and draws a hard
line between **proposal-acceptance** (batchable) and **implementation-authorization**
(narrow). This feature specifies a detection check that enforces that line: it
validates that a *batch-acceptance commit* — a commit carrying an
`Approved-Artifacts:` trailer (the batch list of a recorded approval, per
ADR-0026) — accepts only proposal-class documents and changes no implementation
surface. The check is detection, not prevention, consistent with the framework's
stance: it reports an overreaching batch so a human can act, and does not itself
block a merge. Proposal-class locations are `docs/specifications/`,
`docs/change-plans/`, `docs/decisions/`, their index READMEs, and `CHANGELOG.md`;
every other path — including `scripts/`, `test/`, `.github/`, `package.json`,
`integrations/`, `templates/`, `workflows/`, and `guidelines/` — is forbidden in
a batch-acceptance diff.

## Goals

- Detect a batch-acceptance commit whose diff reaches beyond proposal-class
  locations into implementation or reserved paths.
- Detect an `Approved-Artifacts:` list that names an artifact that is not an
  existing proposal-class document, or that is not in an accepted/approved state.
- Provide a platform-neutral, git-only check with no dependency on a GitHub API,
  so it runs in the offline status gate and in CI alike.

## Non-Goals

- The check does **not** prevent merges, protect branches, or enforce the
  reserved-path approval gate — those are ADR-0012 / ADR-0027 concerns.
- It does **not** validate the run manifest's PR-body structure (that surface is
  GitHub-dependent and out of scope for the platform-neutral core).
- It does **not** re-validate the ADR-0026 approval shape (the `Approved-By:`
  presence and the author-≠-approver rule) — that is the existing status gate's
  concern; this check validates only the *tier integrity* of the batch list.
- It must remain an **advisory (non-required) CI job**; marking it required or
  merge-blocking would turn detection into prevention and is out of scope
  without revisiting this stance.
- It does **not** enforce the 48-hour bound or the work-item scope linkage;
  those are conduct rules, detected-and-reported only where mechanically honest
  to state, and are otherwise out of scope.

## Users / Stakeholders

- The human approver — a clear pass/fail signal that a batch acceptance is
  proposal-only.
- The maintenance tick and autonomous agents — a gate that catches a batch
  acceptance that smuggles an implementation change.

## Interfaces

- Type: CLI
- Details: `bash scripts/check-run-batch.sh <commit-ish>` — validates one commit
  carrying an `Approved-Artifacts:` trailer. In CI it is wired to run over a
  pull-request commit range and report every offending batch-acceptance commit.

## Success Criteria

- Given a commit whose `Approved-Artifacts:` lists only existing proposal-class
  documents and whose diff touches only proposal-class locations, when the check
  runs on that commit, then it exits 0 with no findings.
- Given a batch-acceptance commit whose diff touches a reserved or
  implementation path (e.g. `scripts/`, `.github/workflows/`, `package.json`),
  when the check runs, then it reports the offending path and the commit and
  exits non-zero.
- Given a commit whose `Approved-Artifacts:` names an ID with no matching
  proposal-class file, when the check runs, then it reports the missing artifact
  and exits non-zero.
- Given a commit whose `Approved-Artifacts:` names a document still in a
  `draft`/`proposed` state, when the check runs, then it reports the unaccepted
  artifact and exits non-zero.
- Given a commit that carries no `Approved-Artifacts:` trailer, when the check
  runs, then it exits 0 and does not report (only batch-acceptance commits are in
  scope).

## Edge Cases

- A single-artifact `Approved-Artifacts:` (a batch of one) is still validated.
- A `docs/decisions/` ADR acceptance is proposal-class for this check's purpose,
  even though `docs/decisions/` is in the framework's ADR-0027 reserved set —
  accepting a decision is a proposal act; changing its enforcement is not.
- The check must not depend on the live repository's GitHub state, so it
  resolves artifact IDs against the checked-out tree only.
- `test/` files are not proposal-class: a batch-acceptance commit that also
  adds or changes a test file is an overreach and is reported.

## Out of Scope

- PR-body manifest structure validation (GitHub-binding concern).
- 48-hour bound enforcement and work-item scope linkage (conduct; not
  mechanically checkable in the offline core).
- Any change to ADR-0045, ADR-0026, or the ADR-0027 reserved-path set.

## Dependencies

- ADR-0045 (accepted) — the invariant this check enforces.
- ADR-0026 (accepted) — the `Approved-By:` / `Approved-Artifacts:` trailer shape.
- The existing `check-status.sh` reserved-path logic as a reference for path
  classification (not as a runtime dependency).

## Rollout / Migration

- None — the check is additive; existing commits are not retroactively scanned
  by default.

## Security / Privacy

- Data handled: commit metadata (diff paths, `Approved-Artifacts:` trailer values)
  only. No credentials, no network, no secret surface.

## Open Questions

- None that block implementation; see Non-Goals for the intentionally excluded
  GitHub-dependent and conduct-only checks.
