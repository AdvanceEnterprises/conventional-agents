---
type: feature-spec
id: FS-0049
status: approved
title: Bash 3.2 regression coverage for the status consistency gate
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "test/FS-0022/bash32-compat.bats"
  - "test/FS-0049/**"
  - "docs/specifications/FS-0049-bash32-status-check-compatibility.md"
  - "docs/change-plans/PLAN-0055-implement-fs-0049-bash32-status-check-compatibility.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0012, ADR-0026, ADR-0027]
supersedes: []
requires: [FS-0013, FS-0022]
tags: [bash, compatibility, check-status, regression-testing]
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

# Feature Spec: Bash 3.2 regression coverage for the status consistency gate

## Status

- Approved (recorded approval per ADR-0026).

The recorded approval covers FS-0049 and PLAN-0055. This governance PR is
unmerged, so the approval is provisional for trunk and authorizes implementation
only on a branch descended from the approval commit. PR #215 must include this
approved contract in its ancestry and pass its acceptance criteria before it
can enter the merge train.

## Summary

FS-0013 states that `scripts/check-status.sh` supports Bash 3.2+, but the
reported rule-8 parser regression was not exercised by the repository's normal
Bash 5 CI environment. Issue #214 and PR #215 identify the need for executable
Bash 3.2 coverage, not only a compatibility claim or a source-shape assertion.
This spec defines opt-in real-shell regression coverage and the evidence needed
to verify the documented compatibility floor.

## Goals

- Preserve the Bash 3.2+ compatibility requirement already stated by FS-0013.
- Exercise both shell parsing and a real run of `scripts/check-status.sh` under
  Bash 3.2 when a compatible binary is supplied.
- Make absence of a Bash 3.2 binary visible as an explicit test skip, never as
  evidence that Bash 3.2 compatibility passed.
- Document how maintainers and consumers can run the version-specific check.
- Require real Bash 3.2.39 and Bash 3.2.57 parse-and-run evidence before the
  implementation is considered complete.

## Non-Goals

- Installing or building Bash 3.2 in GitHub Actions.
- Changing the status check's accepted references, diagnostics, exit semantics,
  or supported behavior.
- Auditing or changing Bash compatibility of other scripts.
- Treating a grep-only structural assertion as a substitute for running Bash
  3.2.

## Users / Stakeholders

- Framework maintainers running the gate on macOS or older distributions.
- Consumer repositories that vendor and execute `scripts/check-status.sh`.
- Reviewers evaluating the Bash 3.2 compatibility claim.

## Interfaces

- Type: CLI + Test + Documentation.
- Details:
  - `scripts/check-status.sh` remains the Bash 3.2+ gate under test.
  - `test/FS-0049/**` contains the dedicated Bats regression suite. The
    existing issue-specific test under `test/FS-0022/` is migrated here.
  - `scripts/README.md` documents the opt-in `CA_BASH32` invocation and makes
    clear that a skipped local/CI test is not a successful Bash 3.2 run.
  - The FS/PLAN indexes and `CHANGELOG.md` track the governed scope. Because
    `scripts/` is exported surface, the changelog entry must describe the effect
    for consumer repositories rather than only naming internal governance IDs.

## Success Criteria

Each criterion is objectively testable.

- Given GNU Bash 3.2.39 and GNU Bash 3.2.57, when each runs
  `bash -n scripts/check-status.sh`, then each exits zero.
- Given a clean, supported repository state, when the full status-check script
  runs under GNU Bash 3.2.39 and GNU Bash 3.2.57 from the repository root, then
  each exits zero and prints `All status checks passed.`.
- Given `CA_BASH32` names an executable Bash 3.2 binary, when the dedicated Bats
  test runs, then it invokes that binary for both parse and execution checks; a
  parser, runtime, exit-status, or success-summary failure makes the test fail.
- Given `CA_BASH32` is unset and no `bash-3.2` is available on `PATH`, when the
  suite runs, then the real-Bash test reports an explicit skip naming the
  `CA_BASH32` opt-in; that skip is not reported as Bash 3.2 verification.
- Given `CA_BASH32` is set to a missing or non-executable path, when the suite
  runs, then the test fails with a diagnostic instead of skipping.
- Given the dedicated test is present, when `npm test` runs, then the repository
  test runner discovers and executes it.
- Given the documented Bash 3.2 opt-in command is followed, when a maintainer
  runs it with Bash 3.2.39 and Bash 3.2.57, then the resulting test output makes
  both successful runs distinguishable from a skipped run.

## Edge Cases

- An explicitly configured but invalid `CA_BASH32` path is an error, not an
  absent optional binary.
- The test runs the gate from the repository root so its self-check resolves
  the same target the CI invocation checks.
- The real-shell check must fail closed if Bash 3.2 cannot parse the script; a
  passing Bash 5 syntax check alone is insufficient.

## Out of Scope

- Adding a Bash 3.2 CI image or changing the repository workflow matrix.
- Changing the check-status implementation beyond the parse-safe correction
  required by the documented Bash 3.2 behavior.
- Claiming the default CI job has executed under Bash 3.2 when it has not.

## Dependencies

- FS-0013 owns the status gate and its Bash 3.2+ compatibility requirement.
- FS-0022 owns the repository's Bats test execution path.
- GNU Bash 3.2.39 and GNU Bash 3.2.57 binaries are required for the final
  version-specific acceptance evidence.

## Rollout / Migration

- Move the regression suite from `test/FS-0022/` to `test/FS-0049/` so its
  acceptance criteria have a dedicated owning spec.
- Keep the `CA_BASH32` test opt-in for environments without a Bash 3.2 binary;
  require recorded successful runs on both specified versions before merge.

## Open Questions

None.
