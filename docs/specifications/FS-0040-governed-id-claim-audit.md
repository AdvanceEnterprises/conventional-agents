---
type: feature-spec
id: FS-0040
status: approved
title: Governed-ID claim and citation audit — local duplicates, cross-PR collisions, and stale renumber citations
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "integrations/github/bin/gh-pr-claim-audit.sh"
  - "integrations/github/README.md"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0040/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0015, ADR-0024, ADR-0027, ADR-0033, ADR-0037]
supersedes: []
requires: []
tags: [quality-gates, id-registry, collisions, github-binding, read-only, detection]
created: 2026-09-30
updated: 2026-10-03
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

# Feature Spec: Governed-ID claim and citation audit — local duplicates, cross-PR collisions, and stale renumber citations

## Status

- Approved

## Plan Status

- **PLAN-0046 is `approved`.** This package defines both the local duplicate and
  cross-PR claim layers from #179 and the stale-citation complement from #186.
  Under `ADR-0026`, approval covers only the exact `touches:` set recorded at
  the approval boundary.
- The **implementation revision** declares the complete executable surface
  (`scripts/check-status.sh`, `scripts/README.md`,
  `integrations/github/bin/gh-pr-claim-audit.sh`,
  `integrations/github/README.md`, `package.json`,
  `.github/workflows/lint-docs.yml`, `test/FS-0040/**`). That set includes
  `ADR-0027` reserved paths (`scripts/`, `.github/workflows/`,
  `package.json`), so the plan cannot self-approve; the implementation
  revision needs its own recorded approval covering its own `touches:` set,
  and **no implementation commit is written until that record exists**.

## Summary

Two documents claiming the same governed ID — `FS-NNNN`, `PLAN-NNNN`, or
`ADR-NNNN` — can coexist without any gate reporting it, in two distinct
shapes:

- **In-tree.** A duplicate inside one repository's own corpus passes the
  portable core gate today (all three registries; reproduced 2026-09-30, see
  Problem / Evidence). The cross-repo sweep catches the FS/PLAN subset, but
  not ADRs, and only when its repo-discovery inputs are supplied — it is
  not the gate every commit runs.
- **Cross-PR.** A branch claiming an ID another open pull request already
  claims (or that already exists on the default branch under a different
  path) is invisible to every local check by construction — a branch-local
  gate sees only its own tree. The last collision (issue #174, pairs
  `#148`/`#159` and `#149`/`#173`) was caught and resolved by hand.

This spec defines one coverage layer per shape and one event-driven companion:

1. **Local (offline).** `scripts/check-status.sh` gains duplicate-ID
   detection within the checked repository's own tree, across all three
   registries: two documents in one registry directory resolving to the
   same ID fail the gate, naming every offending file. No GitHub
   dependency — the portable core stays offline.
2. **Cross-PR claims and citations (binding).** A read-only **claim audit** in the GitHub
   binding (`integrations/github/bin/gh-pr-claim-audit.sh`, registered as
   `npm run github:pr-claim-audit`) reports same-ID / different-path claims
   among the repository's open pull requests (drafts included) and claims
   colliding with IDs already present on the default branch under a
   different path. It also observes open-PR governed-document renames and
   reports added-line citations of the retired ID on sibling open PRs. Report-
   only per `ADR-0024`'s detection-over-prevention posture; an opt-in
   `--strict` makes findings exit non-zero for consumers who want their own job
   to fail.

The citation layer is deliberately event-driven: a rename visible in the open
PR set supplies the old-to-new mapping, and sibling added lines are the scan
surface. It does not pretend that a closed historical rename can be reconstructed
from a current token alone.

The audit never rewrites IDs. Detection, not prevention; the human
arbitrates, exactly as #174's resolution did.

## Problem / Evidence

The silent-collision class, from issue #174:

| Pair | First claim | Later claim | Claimed IDs | Resolved by |
| --- | --- | --- | --- | --- |
| A | #148 (ArcOps boundary, 2026-09-10) | #159 (validation reproducibility, 2026-09-21) | FS-0032 / PLAN-0038 | hand renumber in #174's amendment (swap) |
| B | #149 (stacked-PR CI, 2026-09-10) | #173 (Hermes kanban binding, 2026-09-24) | FS-0033 / PLAN-0039 | hand amendment; #173 kept FS-0038 / PLAN-0044 |

Each branch was internally consistent — `check:status` passed on both — and
the colliding filenames differed per PR (`FS-0032-arcops-…md` vs
`FS-0032-validation-…md`), so the second merge would have been textually
clean and the duplicate would have landed silently.

Measured coverage on trunk `d5d0a35` (2026-09-30 maintenance tick; every
scenario an injected copy of an existing document):

| Scenario | `check:status` | `cross-repo-lint.sh` |
| --- | --- | --- |
| Duplicate FS id (two files, same id) | **passes** (rc=0 — gap) | fails (rc=1) |
| Duplicate PLAN token (two files, same token) | **passes** (rc=0 — gap) | fails (rc=1) |
| Duplicate ADR id (two files, same id) | **passes** (rc=0 — gap) | **passes** (rc=0 — gap) |

So today: **ADR duplicates are caught by no layer at all.** FS/PLAN
duplicates are caught by `cross-repo-lint.sh` check 3 alone — a check that
runs in this repository's CI (the `lint-cross-repo` job supplies
`CA_REPO_DIRS`) and that requires repo-discovery inputs or the sibling-repo
layout for a local run (a bare run from a clean clone failed repo discovery:
`ERROR: Could not locate any repos`). It is not the portable gate:
`check:status` is, and it runs on every commit (per `ROLE_CONTRACT`'s
pre-commit testing gate) and in every consumer that vendors it — a consumer
wiring only the portable gate has no duplicate protection at all. The
repository's own corpus has no duplicates today in any registry (all 37 FS,
38 PLAN, and 43 ADR IDs resolve uniquely), so both layers ship green.

Why the local layer is not optional: the cross-PR audit runs only where a
consumer wires it. A duplicate introduced by a PR merged without the audit,
or by direct-to-trunk maintenance pushes (`ADR-0041`), would otherwise reach
trunk unnoticed until someone ran a registry sweep by hand.

## Relationship to existing checks

- **`cross-repo-lint.sh` check 3** (FS/PLAN filename tokens, per repo) is
  the existing sweep. This spec does **not** change it; it remains the
  per-repo component of the multi-repo sweep. The local detection lands in
  `check-status.sh` because that is the portable gate every consumer and
  every commit runs (`FS-0024`), and because ADRs are outside check 3's
  scope entirely. Once implemented, FS/PLAN duplicates will be reported by
  both tools in this repository's CI — the same property on two surfaces,
  each owning its own scope; no gate is weakened or removed.
- **Filename/id agreement** (front-matter `id:` matching the filename
  token) stays `cross-repo-lint.sh` check 3's territory. This spec adds
  per-registry uniqueness to the core gate; it does not duplicate the
  agreement check.
- **The `conventional-agents-id-registry` skill** documents the human
  query patterns. This spec is the mechanical enforcement of the property
  the skill's queries defend: an ID resolves to exactly one document per
  registry.

## Goals

- Detect duplicate governed IDs within the checked repository's own tree,
  across all three registries, as a `check-status.sh` failure naming every
  offending file and the duplicated ID.
- Provide a read-only cross-PR claim audit consuming GitHub pull-request
  metadata that reports (a) same-ID / different-path claims among open pull
  requests — drafts included — (b) claims colliding with IDs already on the
  default branch under a different path, and (c) sibling citations of a retired
  ID when an open PR exposes the corresponding rename event.
- Keep the portable, offline core gate free of any GitHub dependency: the
  layers stay independent; the audit lives in the binding's executable
  layer per `ADR-0037`.
- Keep the audit's default posture informational (`ADR-0024`), with
  `--strict` as the consumer opt-in, and make audit-runnable failures
  (unauthenticated CLI, API failure, unresolvable target) exit non-zero
  with an explicit error — never a silent clean report.
- Stay within the existing architecture: same `check-status.sh` rule
  machinery, same binding conventions (the `gh-common` library's
  authentication check, caller-relative target resolution per
  `FS-0024`/`ADR-0033`, rate-limit pacing), Bash 3.2 compatible.
- Make citation findings explicit about the observed rename event and the
  citing PR; do not silently reinterpret a still-valid forward reference.

## Non-Goals

- Rewriting, renumbering, or otherwise mutating IDs or documents. Both
  layers report; neither writes (`ADR-0024`).
- Making the claim audit a blocking gate by default. Findings are
  informational; `--strict` is consumer policy.
- Giving the offline core gate any network dependency, or moving ID
  uniqueness checking into a hosted service.
- Cross-repository claim checking. Each repository owns an independent
  registry sequence, so uniqueness is a per-repository property.
- Reconstructing renumber events from closed PRs or arbitrary historical
  commits. The citation companion only reports mappings visible in the open-PR
  file set for this audit run.

## Users / Stakeholders

- Concurrent-PR authors and reviewers — the parties who currently discover
  collisions by hand, if at all.
- Framework maintainers and the maintenance tick, whose registry sweeps are
  the manual stopgap this pair of layers replaces.
- Consumers vendoring the framework — they inherit the local duplicate
  detection with their `check-status.sh` copy, and may adopt the audit per
  their own CI policy.

## Interfaces

- Type: CLI (governance gate) + CLI (read-only binding command)
- Details:
  - `scripts/check-status.sh` — new duplicate-ID detection across the
    `FS` / `PLAN` / `ADR` registries (behavior per Success Criteria 1–4);
    documented in `scripts/README.md`.
  - `integrations/github/bin/gh-pr-claim-audit.sh` — new read-only command
    (claim and citation report posture, `--strict`, `--json`, `--help`, stable exit codes);
    registered in `package.json` as `github:pr-claim-audit`; documented in
    `integrations/github/README.md`, including its `reports`
    classification in the enforcement-posture table.
  - `.github/workflows/lint-docs.yml` — the framework's own pull-request
    workflow runs the audit as an informational step (Success
    Criterion 12).
  - `test/FS-0040/**` — bats coverage, fixture-driven (no live GitHub
    calls).
  - Index rows: `docs/specifications/README.md`,
    `docs/change-plans/README.md`; `CHANGELOG.md` entry naming `FS-0040`
    (exported-surface gate per rule 7).

## Success Criteria

- **SC-1** Given a repository where two files in `docs/specifications/`
  carry the same front-matter `id:` (`FS-NNNN`), when `check-status.sh`
  runs, then it fails (non-zero) and the error names both files and the
  duplicated ID.
- **SC-2** Given a repository where two files in `docs/change-plans/`
  claim the same `PLAN-NNNN` token in their filenames, when the check runs,
  then it fails and names both files and the duplicated ID.
- **SC-3** Given a repository where two files in `docs/decisions/` carry
  the same front-matter `id:` (`ADR-NNNN`), when the check runs, then it
  fails and names both files and the duplicated ID.
- **SC-4** Given the repository's current corpus (every ID resolving to a
  single document), when the check runs, then it passes — the extended gate
  introduces no false positives; a document whose resolved ID is claimed
  once is never reported.
- **SC-5** Given governed documents added or modified by open pull requests
  (drafts included) that claim the same ID under different paths — across
  different pull requests or within one — when `gh-pr-claim-audit` runs
  against the repository, then one finding per duplicated ID names every
  claiming pull request with its path.
- **SC-6** Given an open pull request whose governed document claims an ID
  that already exists on the default branch under a different path, when
  the audit runs, then a finding names the ID, the pull request, the
  pull-request path, and the default-branch path.
- **SC-7** Given an open pull request that edits a governed document
  claiming an ID whose default-branch owner is the same path (a status
  flip or in-place update), when the audit runs, then no finding is
  emitted — same-ID / same-path is not a collision.
- **SC-8** Given findings exist, when the audit runs without `--strict`,
  then the full report is emitted and the exit status is 0; with `--strict`
  the exit status is 1. `--json` emits the same findings as a
  machine-readable report. Given the audit cannot run (unauthenticated
  `gh`, API failure, unresolvable target repository), then the exit status
  is 2 with an explicit error — never a silent clean report.
- **SC-9** The audit is read-only: its source contains no mutating
  operation (no issue, pull-request, label, item, or field writes; no
  merges; no local file mutation), asserted by a source-level test in the
  style of the binding's existing read-only audits.
- **SC-10** Given a caller checking a host repository that vendors the
  framework, when the audit runs from that repository, then the target
  repository resolves caller-relative with explicit overrides
  (`--repository`, `--target`, or the environment variables of the
  binding's common library) per `FS-0024` / `ADR-0033`.
- **SC-11** `npm run github:pr-claim-audit` invokes the audit, and
  `--help` documents the options and exit codes.
- **SC-12** Given the framework's own CI after this change, when a pull
  request is opened or updated, then the claim audit runs against it as an
  informational step: a clean report or findings-only report (non-strict)
  does not fail the job, while a run failure (exit 2) surfaces as a
  failure. No existing gate or job is weakened or removed.
- **SC-13** Given one open PR that renames a governed document from an old ID
  to a new ID and a sibling open PR whose added lines cite the old ID, when the
  audit runs, then one `citation-drift` finding names the old/new IDs, both PRs,
  and the citing path; `--strict` treats it like any other finding.
- **SC-14** Given a rename PR whose removed side contains the retired ID and
  whose added side contains the replacement ID, when the audit runs, then the
  rename PR's own claim and removal do not become a stale citation finding.
- **SC-15** Given an added-line citation for an ID with no observed rename event
  in the open-PR set, when the audit runs, then the citation layer emits no
  finding merely because the token is old or forward-looking.
- **SC-16** Given multiple sibling citations of the same retired ID, when the
  audit runs, then one finding lists all citing PR/path pairs rather than
  emitting a pairwise duplicate for each line.
- **SC-17** JSON output identifies citation findings with `class:
  citation-drift` and includes the rename mapping and citing claims; the text
  report identifies the same evidence.

## Edge Cases

- **Removals are not claims.** A pull request that removes a governed
  document (a renumber's old side) does not claim the removed ID; only the
  added side — including a rename target — is a claim. A renumber
  therefore produces no false collision against the ID it is retiring.
- **One finding per ID.** Multiple claimants for one ID are reported as a
  single finding listing all distinct claimants, not one finding per pair.
- **A PR touching no governed files claims nothing** and contributes no
  findings.
- **Two PRs editing the same document** claim the same ID at the same
  path; that is not a cross-PR collision and produces no finding.
- **Trunk-internal duplicates are the local layer's finding class.** The
  audit's default-branch comparison treats an ID as existing there; it
  does not double-report in-tree duplicates, which SC-1..3 fail locally.
- **Token shape.** Only four-digit `FS-NNNN` / `PLAN-NNNN` / `ADR-NNNN`
  forms are extracted (the registry's format rule); other forms are not
  claims.
- **Pagination and rate limits.** Repositories with more open pull
  requests than one API page are fully enumerated, and successive calls
  honor the binding's pacing and bounded rate-limit backoff.
- **Self-claim.** The pull request under audit is itself an open pull
  request; its own claims participate in the comparison like any other
  claimant's.
- **Citation scan.** Only added lines from sibling open PR files participate;
  removed lines, unchanged context, and the rename PR itself are not citations.

## Out of Scope

- Auto-repair or renumbering of any kind; both layers report, neither
  rewrites.
- Branch-protection or required-status-check changes.
- Extending the citation event source beyond open pull requests (for example,
  reconstructing recently closed renames from the default-branch commit graph).
  The open-PR + default-branch claim scope remains the binding boundary.
- Changing `cross-repo-lint.sh` check 3 or the filename/id agreement check.
- `docs/orchestration/` and other preserved-evidence exclusions carried by
  the existing rule set.

## Dependencies

- `FS-0022` — the rule machinery the local duplicate detection extends,
  and its bats suite conventions.
- `ADR-0024` — detection-over-prevention posture; read-only reporting.
- `ADR-0026` — recorded-approval shape; `ADR-0027` — reserved paths
  (`scripts/`, `.github/workflows/`, `package.json`): the implementation
  revision cannot self-approve.
- `ADR-0033` / `FS-0024` — caller-relative target resolution and
  configuration for the binding command.
- `ADR-0037` / `FS-0029` — the executable GitHub binding layer (`bin/`
  venue, `gh-common` library, report-only classification) this command
  joins.
- `ADR-0015` — tool taxonomy: a report-only command is integration-layer
  tooling, not a Category 1 governance gate.
- Issues #174 (the worked collision and closing recommendation) and #179
  (this work item).
- **No new ADR.** The posture is `ADR-0024`'s, the venue is `ADR-0037`'s,
  and the offline-core / binding split follows `FS-0024`/`ADR-0033`; this
  spec composes existing decisions rather than making a new one.

## Rollout / Migration

- **Local layer:** ships green — the repository's corpus has no duplicate
  IDs today, and the new failure mode only triggers on genuinely
  duplicated registries. Consumers receive it by updating their vendored
  copy; no configuration or document edits are required.
- **Cross-PR audit:** informational on adoption. The framework's own CI
  runs it on pull requests from the first implementation; consumers wire
  it (or not) per their own policy, with `--strict` as the explicit
  fail-on-findings opt-in. Citation findings are tied to observed open-PR
  renames and never rewrite the citing branch.
- No document edits ship with the implementation beyond the index rows,
  the `scripts/README.md` / `integrations/github/README.md` documentation,
  and the `CHANGELOG.md` entry.

## Open Questions

- None blocking.
