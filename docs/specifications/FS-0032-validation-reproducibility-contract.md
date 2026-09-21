---
type: feature-spec
id: FS-0032
status: approved
title: Validation reproducibility contract — bounded, hermetic, and CI-parity framework checks
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/run-validation.sh"
  - "scripts/validation-common.sh"
  - "scripts/run-bats.sh"
  - "scripts/cross-repo-lint.sh"
  - "scripts/README.md"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0032/validation-reproducibility.bats"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
  - "docs/validation-baseline.md"
  - "docs/validation-baseline.log"
related_adrs:
  - ADR-0015
  - ADR-0027
  - ADR-0030
  - ADR-0033
supersedes: []
requires: []
tags: [validation, reproducibility, ci, quality-gates]
created: 2026-09-21
updated: 2026-09-21
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

# Feature Spec: Validation Reproducibility Contract

## Status

- Approved

## Summary

The framework's own acceptance machinery must be trustworthy before it is used
as infrastructure for the governed-agent benchmark harness in issue #124.
This spec makes the five-command validation surface explicit and gives local and
CI execution one bounded, hermetic entry point:

- `npm test`
- `npm run lint:docs`
- `npm run check:status`
- `npm run check:freshness`
- `npm run lint:cross-repo`

A clean validation run is reproducible when it has the same command order and
verdict on a clean checkout, reports progress and elapsed time, fails closed on
a timeout or missing prerequisite, does not call GitHub or fetch from a remote,
and records a machine-readable-enough summary plus the complete log.

## Goals

- Provide one `npm run validate` entry point for the complete validation surface.
- Apply a bounded timeout to each validation command and a bounded timeout to
each individual Bats suite, with explicit progress and timing output.
- Resolve the target repository explicitly and run fixture-backed tests in
  temp-dir-scoped state rather than in the caller's checkout or configuration.
- Make cross-repository linting network-free by requiring already-available Git
refs and failing closed when the requested commit range is unavailable.
- Have CI invoke the same `npm run validate` path used locally, with full history
and the explicit pull-request commit range prepared before the runner starts.
- Record a clean baseline containing the exact revision, command contract,
per-command timings, Bats suite timings, and the complete runner log.

## Non-Goals

- Replacing the individual CI jobs that provide granular diagnostics.
- Running the GitHub binding audit as part of the hermetic five-command surface.
- Making network-backed GitHub, package, or deployment operations hermetic.
- Changing the governance rules enforced by `check-status.sh`.
- Implementing the benchmark harness in issue #124 / FS-0031.
- Claiming that wall-clock timings are identical across machines; the contract
requires a documented budget and stable verdict, not identical hardware speed.

## Behavior

### 1. Canonical validation runner

`scripts/run-validation.sh` runs the five commands in the order listed above.
It prints a start and completion record for every command, records elapsed whole
seconds, writes all output to a log, and returns non-zero if any command fails
or exceeds its configured timeout. The command timeout and Bats suite timeout
are configurable by environment variables with documented defaults; malformed
or non-positive values fail before any gate runs.

The runner uses the repository selected by `CA_TARGET_REPO` (or the caller's
Git worktree when no override is supplied), changes into that root for every
step, and does not modify the checkout. Its default environment disables npm
network fallback, isolates temporary files and user configuration, and places
fail-closed stubs for network-capable commands used by the acceptance surface.

### 2. Bats progress and per-suite bounds

`scripts/run-bats.sh` discovers suites deterministically, reports the suite
number and path before execution, applies a timeout to each suite, reports its
elapsed time and verdict, and fails if no suites are found. A timeout is a
failure even if an earlier suite passed. Missing `bats` or `rg` remains a clear
prerequisite failure with an install hint.

### 3. Network-free cross-repo lint

`scripts/cross-repo-lint.sh` never fetches implicitly. It uses an explicit
`CA_TARGET_REPO` or `CA_REPO_DIRS` selection and an available `COMMIT_RANGE`.
If a required commit range cannot be resolved, it reports the missing range and
fails instead of skipping the attribution check.

### 4. CI parity

The `lint-docs` workflow installs the pinned local Node dependencies, prepares
full Git history and the pull-request base ref, and invokes `npm run validate`
for the five-command surface. The workflow's setup may access package and Git
infrastructure; the validation runner itself performs no remote operation.

### 5. Recorded baseline

`scripts/README.md` documents the contract, defaults, isolation model, failure
semantics, and CI invocation. `docs/validation-baseline.md` records the clean
checkout revision and verification commands, and `docs/validation-baseline.log`
contains the corresponding complete runner output with timings.

## Success Criteria

- Given a clean checkout with dependencies installed, when `npm run validate`
runs, then all five commands execute in the declared order, each emits progress
and elapsed time, and the runner exits zero only when all five pass.
- Given a command or Bats suite that exceeds its configured timeout, when the
runner executes it, then the process is terminated, the timeout is named in the
log, and the overall verdict is non-zero.
- Given an invalid or non-positive timeout value, when the runner starts, then it
fails before executing a validation command with an actionable error.
- Given a clean checkout, when two serial runs use the same target revision, then
both produce the same five-command verdict and leave the checkout unchanged.
- Given two separate clean worktrees, when the canonical runner executes in
parallel against them, then both runs complete independently without sharing
fixtures, logs, temporary state, or mutations.
- Given the default validation environment, when the five-command runner runs,
then it does not invoke a real `gh` command or fetch a Git remote; a missing
local commit range is a visible failure rather than a skipped check.
- Given a pull-request CI run, when the workflow invokes validation, then it uses
the same `npm run validate` entry point and the same gate order as local
execution, with full history and the PR base range prepared before invocation.
- Given a completed clean validation run, when the baseline artifacts are read,
then they identify the target revision, command set, timings, per-suite progress,
and final verdict, and the documented budget is sufficient for the recorded run.

## Interfaces

The front-matter `interfaces:` list is the complete implementation surface for
this contract. The runner is a Category 1 gate under ADR-0015 and therefore
requires registration in `package.json`, documentation in `scripts/README.md`,
and CI wiring through the existing workflow.
