---
type: feature-spec
id: FS-0056
status: draft
title: Narrow direct-to-trunk merge exception — eligibility gate and audit digest
owner: Head Architect
test_required: true
interfaces:
  - scripts/
  - .github/workflows/
  - package.json
  - test/FS-0056/eligibility-gate.bats
  - docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md
  - docs/specifications/FS-0056-narrow-direct-to-trunk-merge-exception.md
  - docs/change-plans/PLAN-0060-implement-fs-0056.md
  - CHANGELOG.md
related_adrs:
  - ADR-0012
  - ADR-0018
  - ADR-0029
  - ADR-0041
  - ADR-0047
  - ADR-0049
supersedes: []
requires:
  - ADR-0041
  - FS-0022
tags:
  - governance
  - ci
  - merge-gate
  - autonomy
created: 2026-10-27
updated: 2026-10-28
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- `interfaces:` bounds which change plans may self-approve (ADR-0027) — draw
  it narrowly; a loose `interfaces:` widens agent authority.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->
# Feature Spec: Narrow direct-to-trunk merge exception — eligibility gate and audit digest

## Status

- Draft

## Summary

Implement the mechanical controls that let agents merge narrow, reversible
maintenance changes directly to trunk under the exception ratified by
`ADR-0041`. The implementation has two parts: an `eligibility-gate` script that
approves a PR iff its diff is fully inside the eligible categories defined by
`ADR-0041` and CI is green, or a human approval is present; and an audit digest
that records every direct merge so a human can review the batch.

## Goals

- Provide a technical backstop on trunk that enforces the `ADR-0041` scope.
- Preserve the full per-commit attribution record.
- Produce a machine-readable, human-reviewable digest per maintenance sweep.
- Fail closed when eligibility cannot be determined.

## Non-Goals

- Granting agents general merge authority.
- Removing the human promotion/audit act.
- Batching PRs through a staging branch.
- Expanding eligible categories beyond what `ADR-0041` ratifies.

## Users / Stakeholders

- Human maintainer reviewing the cross-repo maintenance digest.
- Autonomous maintenance tick performing eligible merges.
- CI/ruleset enforcement on trunk.

## Interfaces

- Type: CLI | CI status check
- Details:
  - `scripts/eligibility-gate.sh` — exit 0 if the current PR/branch is eligible
    for direct-to-trunk merge, exit 1 with a diagnostic otherwise.
  - `.github/workflows/lint-docs.yml` — extended with an `eligibility-gate`
    job that runs the gate and reports the required `eligibility-gate`
    status check on trunk.
  - `package.json` — adds an `eligibility-gate` script entry point.
  - `test/FS-0056/eligibility-gate.bats` — bats coverage for the Success
    Criteria cases.
  - Digest output format: JSON Lines with fields `repo`, `pr`, `commit_range`,
    `touched_paths`, `work_item`, `type`, `actor`, `model`, `session`, `checks`,
    `rollback_ref`.

## Success Criteria

- Given a PR whose diff is entirely within an `ADR-0041` eligible category and
  all required checks pass, when `scripts/eligibility-gate.sh` runs, then it
  exits 0 and prints `eligible`.
- Given a PR whose diff touches a reserved path or a non-eligible file, when
  the gate runs, then it exits 1 and names the first ineligible path.
- Given a PR that has a human `Approved-By:` trailer on the most recent commit,
  when the gate runs, then it exits 0 regardless of category because the human
  approval is the authority.
- Given a PR merged by the direct exception, when the maintenance sweep ends,
  then a digest entry is emitted containing the exact commit range and rollback
  reference.
- Given a gate run where the eligibility predicate cannot be parsed, when the
  gate runs, then it exits 1 and the error message says "fail-closed".

## Edge Cases

- An eligible PR that later receives a new commit outside the category must be
  re-evaluated; the gate checks the full PR diff, not the original approval.
- A PR with mixed eligible and ineligible commits fails closed even if most of
  the diff is eligible.
- The gate does not itself perform the merge; it only reports eligibility. The
  merge act remains subject to `ADR-0012` and the ruleset.

## Out of Scope

- Implementing a staging branch or promotion UI.
- Multi-repo orchestration beyond digest aggregation.
- Auto-merge wiring; the ruleset is the only actor that may block merge.
- Phase 2 content-aware eligibility (`updated:` date-only refreshes) unless
  `ADR-0041` Phase 2 has been separately accepted.

## Dependencies

- ADR-0012: Non-overridable gates — the merge prohibition remains intact.
- ADR-0041: The exception this spec implements.
- ADR-0047: Authorized intent identity and the human grant — ties the digest
  actor to the grant.
- ADR-0049: Grant-based go signal for autonomous runs — the batch gating
  model this digest feeds.
- FS-0022: Gate coverage — the check script conventions this spec extends.

## Rollout / Migration

- Add `scripts/eligibility-gate.sh` and tests first.
- Add the required check to the trunk ruleset in a separate, human-reviewed PR
  because it touches `.github/workflows/` and `package.json`.
- Begin the pilot only after ADR-0041 is accepted and the ruleset change is
  live.

## Observability

- Logs: gate emits one eligibility verdict per run.
- Metrics: digest carries count of direct merges per sweep.
- Traces: every eligible merge leaves an `Agent-Attribution:` trailer.

## Security / Privacy

- Data handled: PR diffs, check results, attribution trailers. All already in
  the repository.
- Threats considered: an agent could try to widen eligibility by editing the gate
  script. Mitigation: `scripts/` is in `ADR-0027`'s reserved set, so any change
  to the gate requires human approval.
- Mitigations: gate script is read-only at runtime; ruleset requires the gate
  status check.

## Open Questions

- Should the digest be written to a file in the repo, to GitHub Actions
  artifacts, or both?
