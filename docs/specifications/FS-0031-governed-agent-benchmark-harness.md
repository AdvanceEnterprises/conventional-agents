---
type: feature-spec
id: FS-0031
status: draft
title: Governed-agent benchmark harness — reproducible functional + governance scoring
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/bench-run.sh"
  - "benchmark/task-card.schema.json"
  - "benchmark/task-cards/**"
  - "test/FS-0031/**"
  - "package.json"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "scripts/README.md"
  - "CHANGELOG.md"
related_adrs: []
supersedes: []
requires: []
tags: [benchmark, harness, governance, evaluation, reproducibility]
created: 2026-09-07
updated: 2026-09-07
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

# Feature Spec: Governed-Agent Benchmark Harness

## Summary

Issue #124 proposes measuring whether an agent operating under
`conventional-agents` achieves a higher **governed-completion rate** than an
otherwise identical agent without the framework. This spec defines the
reproducible harness that makes that measurement possible: a versioned
task-card schema, a runner that executes the same task under matched agent
conditions in disposable worktrees, and a scoring rubric that separates
**functional** success from **governance** success.

The harness is benchmark *infrastructure*, not a benchmark itself. It does not
define tasks, claim leaderboard scores, or replace official benchmark
evaluation. It makes the framework's own validation run reproducible first
(issue work package 1), then lets a pilot (work package 3) run matched
baseline/context/gated comparisons.

## Success Criteria

### SC-1: Reproducible runner

`scripts/bench-run.sh` accepts a task card path and a condition name, sets up a
disposable worktree from a pinned base commit, runs the condition's driver
command with a captured action log, and exits non-zero on harness failure
(not on task failure).

### SC-2: Versioned task-card schema

`benchmark/task-card.schema.json` validates task cards. A card declares: a
version, a pinned base repository and commit, a task prompt, permitted and
forbidden paths/actions, required plan and evidence fields, at least one
escalation/refusal scenario or adversarial instruction, and deterministic
governance checks. Schema version is a required field; unknown versions are
rejected.

### SC-3: Separate functional and governance scores

The runner produces a JSON report with at least: `functional` (task success /
test pass rate), `governance` (scope, compliance, traceability, truthful
reporting verdicts), and `evidence` (paths to the captured action log, patch,
and test output). The two scores are never conflated.

### SC-4: Matched conditions

The runner can execute the same task card under at least two named conditions
(e.g. `baseline`, `context`, `gated`) with identical task, tools, and budget
parameters, differing only in the driver command and any framework material
the condition injects.

### SC-5: Escalation and adversarial coverage

At least one shipped task card contains a correct escalation/refusal outcome
and at least one contains an adversarial or misleading instruction, per issue
124's acceptance criteria (issue #124).

### SC-6: Cost and failure analysis fields

The report includes `overhead` (wall time, token/step counts when the driver
reports them) and `failures` (a list of failed checks with the evidence each
failed against), not only an aggregate score.

## Non-Goals

- Replacing official benchmark evaluation or claiming an official leaderboard
  score.
- Counting document production as success without a corresponding engineering
  outcome.
- Treating refusal as inherently good; escalation is correct only when the
  task is actually unauthorized or underspecified.
- Designing a benchmark limited to cooperative, ambiguity-free tasks.
- Running live LLM agents from CI in this spec's scope — the harness drives
  any command; wiring real models is a later pilot concern.

## Out of Scope

- The pilot study itself (work package 3 of #124) and its results.
- Model-specific drivers or agent-runtime adapters.
- Cross-repository execution beyond the single pinned base repo a task card
  declares.

## Interfaces

- `scripts/bench-run.sh` — the runner (Category 1 gate script per ADR-0015;
  registered as `bench:run` in `package.json`).
- `benchmark/task-card.schema.json` — the versioned schema (v1).
- `benchmark/task-cards/` — shipped task cards; the pilot card is
  `benchmark/task-cards/pilot-001.md` (YAML frontmatter + prompt body).
- `test/FS-0031/bench-harness.bats` — bats coverage for SC-1..SC-6 using mock
  drivers (no live model calls).

## Success Criteria → Test Mapping

| Criterion | Test |
| --- | --- |
| SC-1 | `test/FS-0031/bench-harness.bats` — runner sets up worktree, runs driver, captures log |
| SC-2 | schema validation tests — valid card passes, unknown version rejected, missing fields rejected |
| SC-3 | report JSON contains functional/governance/evidence keys with expected shapes |
| SC-4 | same card runs under two condition names with distinct driver commands |
| SC-5 | pilot card declares escalation + adversarial elements (schema-level check) |
| SC-6 | report contains overhead and failures fields |
