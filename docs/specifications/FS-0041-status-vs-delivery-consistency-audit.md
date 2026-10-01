---
type: feature-spec
id: FS-0041
status: draft
title: Status-vs-delivery consistency audit — detect governed documents that lag shipped implementation
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-delivery-status.sh"
  - "scripts/README.md"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0041/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0015, ADR-0024, ADR-0026, ADR-0027, ADR-0033]
supersedes: []
requires: [FS-0022, FS-0024]
tags: [quality-gates, status-drift, delivery-evidence, report-only, detection]
created: 2026-10-01
updated: 2026-10-01
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

# Feature Spec: Status-vs-delivery consistency audit — detect governed documents that lag shipped implementation

## Status

- Draft

## Plan Status

- **PLAN-0047 is `draft`.** This first revision is the documentation package
  only (spec + plan + index rows + CHANGELOG entry). Approval of that package
  must not be read as approval to add the executable gate.
- The implementation revision will declare the executable surface in its own
  `touches:` set. It includes `scripts/` and `.github/workflows/`, which are
  reserved by `ADR-0027`; that revision needs a recorded approval under
  `ADR-0026` before any implementation commit is written.

## Summary

The framework currently checks that an `implemented` PLAN is paired with an
`implemented` FS, but it does not detect the opposite claim: a governing FS and
PLAN remain `draft` or `approved` after the implementation surface they describe
has landed on the default branch. This is the delivered-but-draft family recorded
in issue #188. The failure is operationally misleading rather than cosmetic: a
consumer or maintenance agent reads the document status as "not yet shipped"
even though the repository already carries the implementation.

This spec defines a conservative, offline, report-only audit. It compares the
status of each FS/primary-PLAN pair with repository-local delivery evidence from
the PLAN's declared `touches:` surface, Git history, the required test suite,
and the CHANGELOG marker. It reports a candidate; it never changes document
status, edits files, or decides that a partial implementation is complete.

## Problem / Evidence

The class has recurred in at least five documented forms:

| Instance | Drift | Resolution |
| --- | --- | --- |
| #82 | FS-0004 / PLAN-0002 remained draft after delivery | small reconciliation PR |
| #107 | PLAN-0034 remained stale after ADR-0034 consolidation | small reconciliation PR |
| #99 | FS-0026/0027 and PLAN-0026/0027 remained draft after PRs #88/#92/#95 | reconciliation in the #100-era work |
| #125 | FS-0028/0029 and PLAN-0028/0035 remained draft after implementation PRs | reconciliation in the #126-era work |
| #178 | FS-0031/0033/0034 and PLAN-0037/0039/0040 remained draft after delivery | reconciled by PR #180 and its companion merges |

The existing status gate intentionally catches the forward pairing (`implemented`
PLAN without `implemented` FS) but cannot infer delivery from a draft document.
A file's existence alone is not evidence: a draft may describe an existing file
that will be modified, and a documentation-only package may list planned paths
without changing them. The audit therefore requires corroborating, post-plan
signals and errs toward a false negative rather than a false positive.

## Definitions

### Governing pair

A **governing pair** is an FS plus its primary PLAN as resolved by the existing
FS/PLAN relationship rules. The pair is eligible for this audit when neither
document is `implemented`, `deprecated`, or `superseded`.

### Implementation surface

The PLAN's `touches:` entries are expanded against the checked repository. The
implementation surface is the subset that is not documentation-only metadata:

- include executable, configuration, integration, workflow, and test paths;
- exclude `docs/**`, `CHANGELOG.md`, root `README.md`, and `**/README.md`;
- preserve `.github/workflows/**` and `scripts/**` as implementation paths even
  when their sibling README is excluded.

A PLAN with no implementation-surface path is not a delivery candidate. It may
be a documentation-only plan and is outside this audit's inference boundary.

### Delivery candidate

The audit reports a **delivery candidate** only when all applicable evidence
holds:

1. the governing pair is not `implemented`;
2. every declared implementation-surface path resolves in the current tree and
   has at least one non-merge commit on or after the PLAN's `created:` date;
3. `CHANGELOG.md` contains an explicit `FS-0041`-style marker for the governed
   FS or PLAN identifier, or the implementation commit range contains a
   consumer-framed entry naming that identifier; and
4. when the FS has `test_required: true`, `test/FS-NNNN/` exists, contains a
   tracked test file, and that suite has history on or after the PLAN's
   `created:` date. A `test_required: false` FS does not require this signal.

The result is evidence that the declared delivery surface has likely shipped,
not a status transition. Human review still decides whether the implementation
is complete and whether the FS/PLAN status should advance.

## Goals

- Detect the delivered-but-draft and delivered-but-approved class with
  repository-local evidence only.
- Name the governing FS, primary PLAN, status values, evidence paths, and the
  relevant commit dates in every finding.
- Require the whole declared implementation surface, rather than treating one
  existing file as proof of delivery.
- Support multi-PR implementations by examining history since the PLAN's
  `created:` date instead of assuming one commit or one PR.
- Stay offline and portable: no GitHub API, issue lookup, branch-name heuristic,
  or provider-specific metadata is required.
- Remain report-only: findings may fail the check, but the check never mutates
  statuses, files, indexes, or the worktree.
- Fail closed when the history needed for the evidence calculation is missing,
  so a shallow checkout cannot report a misleading clean result.

## Non-Goals

- Automatically changing an FS or PLAN from `draft`, `approved`, or
  `in-progress` to another status.
- Reconstructing intent from issue numbers, PR titles, branch names, commit
  messages, or file existence alone.
- Proving semantic completeness of an implementation or reviewing its code.
- Detecting the inverse class where an `implemented` document names an artifact
  that never shipped; that is tracked by #185 and requires acceptance-criterion
  validation rather than delivery-history inference.
- Replacing the existing FS/PLAN pairing, index, freshness, conformance, or
  CHANGELOG-presence checks.
- Requiring consumers to use GitHub, a specific CI provider, or a monorepo
  layout.

## Users / Stakeholders

- Framework maintainers who need the document lifecycle to describe the shipped
  repository truth.
- Consumers reading an exported FS/PLAN to decide whether a capability is live.
- The maintenance tick, which currently finds this class by manual history
  sweeps.
- Reviewers of implementation PRs who need a machine-reported reconciliation
  candidate without granting an agent authority to flip status.

## Interfaces

- Type: CLI governance audit + npm script + CI invocation.
- Details:
  - `scripts/check-delivery-status.sh` — offline report-only audit with stable
    exit codes and caller-relative target resolution per FS-0024/ADR-0033.
  - `scripts/README.md` — rule, evidence model, limitations, and remediation.
  - `package.json` — `check:delivery` entry point.
  - `.github/workflows/lint-docs.yml` — runs the audit after full-history
    preparation; it must not turn a shallow checkout into a vacuous pass.
  - `test/FS-0041/**` — fixture-driven Bats coverage with real Git history in
    disposable worktrees.
  - The two document indexes and `CHANGELOG.md` — package and consumer-facing
    tracking surfaces.

## Success Criteria

- **SC-1 — delivered draft is reported.** Given a disposable repository with a
  non-implemented FS/PLAN pair, a non-document implementation path in the
  PLAN's `touches:`, a post-`created:` commit for every such path, the required
  `test/FS-NNNN/` suite, and a matching CHANGELOG marker, when the audit runs,
  then it exits non-zero and names the FS, PLAN, statuses, evidence paths, and
  a remediation to reconcile the pair.
- **SC-2 — approved drift is reported.** Given the same evidence with the pair
  at `approved` rather than `draft`, when the audit runs, then it reports the
  candidate without changing either document.
- **SC-3 — existing files alone do not report.** Given a draft pair whose
  `touches:` paths predate the PLAN and whose test/CHANGELOG evidence is absent,
  when the audit runs, then it exits zero and emits no delivery finding.
- **SC-4 — documentation-only work is excluded.** Given a draft pair whose
  `touches:` contains only excluded documentation paths, when the audit runs,
  then it exits zero and explains that no implementation surface was evaluated.
- **SC-5 — partial delivery is not over-claimed.** Given a draft pair where
  one of several implementation-surface paths lacks a post-`created:` change,
  when the audit runs, then it does not report the pair as delivered; it may
  print a diagnostic that evidence is incomplete.
- **SC-6 — implemented and terminal documents are quiet.** Given an
  `implemented`, `deprecated`, or `superseded` pair with the same evidence,
  when the audit runs, then it emits no delivery finding.
- **SC-7 — test-required semantics are honored.** Given a `test_required: true`
  pair without a tracked post-`created:` FS test suite, the audit does not
  report delivery; given `test_required: false` with all other evidence, it
  may report the candidate without inventing a test requirement.
- **SC-8 — history failures are explicit.** Given a shallow or otherwise
  unavailable history for an evidence path, when the audit runs, then it exits
  with the documented unavailable-history code and says which evidence cannot
  be evaluated; it never reports a clean result solely because history is
  missing.
- **SC-9 — report-only is verifiable.** Given any finding, before and after the
  run the repository tree, FS/PLAN content, indexes, and CHANGELOG are
  byte-identical; the only side effect is stdout/stderr and the exit code.
- **SC-10 — the entry points are wired.** Given a clean framework checkout,
  `npm run check:delivery` invokes the same script as CI, the script is
  caller-relative in an ordinary clone and a Git worktree, and the focused
  suite covers SC-1 through SC-9 without live GitHub calls.

## Edge Cases

- A multi-PR implementation is valid evidence only when every declared
  implementation-surface path has qualifying history; one partial PR must not
  trigger a delivered claim.
- A path created before the PLAN but modified after it counts only when the
  post-`created:` history is present; creation date is not required.
- A glob that expands to no files is incomplete evidence, not a successful
  delivery.
- A `test_required: false` document is allowed to have no suite, but the audit
  still requires the implementation surface and CHANGELOG evidence.
- A shallow clone or missing commit object is an evaluation error, not a pass.
- A renamed implementation path must be resolved from the current PLAN surface;
  the audit does not follow speculative historical names outside Git's normal
  path history.

## Out of Scope

- Bare filenames and prose references; those belong to FS-0022 §1c and the
  vendor-reference work in FS-0037.
- Cross-repository delivery inference; each repository owns its own history.
- GitHub issue/PR state, board fields, milestones, or Notion mirrors.
- Semantically reviewing whether a test actually proves a criterion.

## Dependencies

- FS-0022 / PLAN-0022 for the existing status and governance-gate conventions.
- FS-0024 / ADR-0033 for portable caller-relative execution and worktree support.
- ADR-0024 for detection over prevention and report-only behavior.
- ADR-0026 and ADR-0027 for the reserved-path approval route.

## Rollout / Migration

- Ship the spec and documentation-only plan as a draft package.
- After human review and recorded approval, implement the audit in a separate
  revision of PLAN-0047.
- Run it against the current corpus and classify every finding before making any
  status edits; historical reconciliation belongs in separate, reviewable PRs.
- Keep the audit report-only until a later decision explicitly changes its
  enforcement posture.

## Observability

- Logs: stable `ERROR`/`INFO`/`SKIP` lines naming the governing pair and evidence.
- Metrics: none required; a future consumer may count findings externally.
- Traces: none; the commit hashes and paths in each finding are the evidence.

## Security / Privacy

- Data handled: local repository paths, front matter, and Git metadata only.
- Threats considered: a shallow checkout or a crafted existing-file layout
  causing a false clean result; explicit history failure and conservative
  evidence rules mitigate this.
- No network calls, credentials, issue bodies, or secret values are read.

## Open Questions

- None blocking for the documentation package. The implementation revision
  should settle the exact stable exit-code numbers and whether consumers want an
  optional JSON report before its recorded approval.
