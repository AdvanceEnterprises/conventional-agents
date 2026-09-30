---
type: feature-spec
id: FS-0034
status: implemented
title: Consumer conformance doctor — read-only diagnostics for framework adoption
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-conformance.sh"
  - "scripts/README.md"
  - "package.json"
  - "test/FS-0034/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  # NOTE: `interfaces:` lists the affected surface — it is NOT approval
  # routing. This spec touches reserved paths (scripts/, package.json per
  # ADR-0027 / FS-0024), so its PLAN requires human approval and cannot
  # self-approve, regardless of interfaces: containment.
related_adrs: [ADR-0015, ADR-0033]
supersedes: []
requires: []
tags: [conformance, consumer, diagnostics, adoption, read-only]
created: 2026-09-10
updated: 2026-09-30
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

# Feature Spec: Consumer Conformance Doctor

## Status

- Implemented

Implemented 2026-09-30 via **PR #147** (read-only conformance doctor for
issue [#142](https://github.com/Tais-Den/conventional-agents/issues/142)).
The implementation merged while this spec was `draft`; the status
transition was deferred post-merge and reconciled by the maintenance tick
(issue #178 — fourth instance of the #99/#125 fail-open family).

## Plan Status

- **PLAN-0040 is `implemented`** — reconciled in the same change (PR #147,
  merged 2026-09-30).

## Summary

Consumer adoption of this framework currently depends on reading documentation
and manually spotting drift. This spec defines a read-only "doctor" capability
that checks whether a repository has adopted the framework correctly and can
upgrade safely: framework presence, required anchors, dangling references,
status-gate wiring, and CI coverage. It diagnoses installation and integration
state; it does not replace Git, approve work, or silently rewrite architecture
(see #142).

The first slice is a single portable script, `scripts/check-conformance.sh`,
with a bats suite. The architectural question of whether a richer `ca doctor`
utility belongs in a separate conformance project is deliberately left open
(see "Out of Scope").

## Goals

- A consumer can run one command and learn whether their vendored framework
  reference is present, their anchors are intact, and their governance gates
  are wired.
- The doctor is read-only: it never writes to the repository, never mutates
  work items, and never changes governance state.
- The doctor is portable: it resolves the target repository from the caller's
  working directory or `CA_TARGET_REPO` (FS-0024/ADR-0033), so a vendored
  copy checks the host repository, not the framework itself.
- Output is human-readable by default and machine-readable (`--json`) for
  tooling, with stable exit codes (0 = conformant, 1 = findings, 2 = usage).
- The framework remains adoptable without installing the doctor: the script
  is optional tooling, not a governance gate.

## Non-Goals

- **A hosted service or runtime dependency.** The doctor is a local script.
- **Automatic remediation.** The doctor reports; it never rewrites files.
- **A new governance gate.** The doctor is not wired into CI as a failing
  check and does not gate pull requests.
- **Replacing Git as the source of truth.** Findings are diagnostics, not
  authority.
- **Deciding the `ca doctor` / `ca init` project boundary.** That decision
  belongs to a separate analysis (issue #142 proposed action 3); this spec
  only ships the in-framework prototype.

## Success Criteria

1. `bash scripts/check-conformance.sh` against a conformant consumer fixture
   (vendored `AGENTS.md` + `INTEGRATION.md` + anchors + governance CI
   workflow) prints `conformance: OK` and exits 0.
2. A consumer with no `vendor/conventional-agents/` reference reports a
   `critical` `framework-presence` finding and exits 1.
3. A dangling `vendor/conventional-agents/<path>` reference in `AGENTS.md`
   or `INTEGRATION.md` is reported as a `dangling-reference` finding.
4. `AGENTS.md` missing or lacking a `vendor/conventional-agents` reference
   is reported as an `anchors` finding.
5. A repository with no workflow under `.github/workflows/` running the
   governance status gate is reported as a `ci-wiring` finding.
6. `--json` emits parseable JSON with `tool`, `target`, `conformant`,
   `finding_count`, and `findings` fields; `finding_count` equals the
   number of findings.
7. Self-check mode (target resolves to the framework itself) skips the
   `framework-presence` check and never reports it.
8. Unknown arguments exit 2 with a usage message; `--help` exits 0.
9. The script passes `shellcheck` and the suite passes under `npm test`.

## Out of Scope

- Cross-repo scaffolding or a standalone `ca doctor` package.
- Interactive remediation or fix-it mode.
- Checking consumer-specific conventions (those belong to the consumer).
- Milestone/iteration/priority planning checks (see #145/#146 — the
  flow-report read-model is a separate capability).
- Any write path, including work-item creation or status transitions.

## Implementation Notes

- The prototype lives at `scripts/check-conformance.sh` and is registered as
  `check:conformance` in `package.json` (documented in `scripts/README.md`).
- Checks in the first slice: framework presence, AGENTS.md anchors,
  dangling vendor references, status-gate runnability, CI wiring, and
  framework version reference.
- The bats suite lives at `test/FS-0034/conformance-doctor.bats` and follows
  the FS-0026 isolation pattern (scratch repos under `BATS_TEST_TMPDIR`,
  script copied in, target resolved from the caller's cwd).
