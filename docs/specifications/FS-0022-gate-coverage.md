---
type: feature-spec
id: FS-0022
status: draft
title: Gate coverage — extend consistency, lint, and test enforcement to the whole corpus
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CONTRIBUTING.md"
  - "INTEGRATION.md"
  - "test/FS-0022/gate-coverage.bats"
related_adrs:
  - ADR-0008
  - ADR-0015
  - ADR-0027
  - ADR-0030
supersedes: []
requires: []
tags: [quality-gates, ci, enforcement]
created: 2026-07-28
updated: 2026-07-28
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

# Feature Spec: Gate Coverage

## Status

- Draft

## Plan Status

- **PLAN-0022 drafted** (`status: draft`). `workflows/document-lifecycle.md`
  places PLAN creation at "initial creation" and constrains only its
  *approval*: a PLAN may not reach `approved` while its FS is `draft`.

## Summary

Two implemented specs already own this machinery, and both cover less
than the purpose they state.

`FS-0013` introduced `scripts/check-status.sh` because *"status fields
drifted silently... so the drift cannot recur undetected."* It validates
FS↔PLAN pairing and the FS and PLAN README indexes. It does not look at
`docs/decisions/` at all — and the drift recurred there, undetected, until
a manual audit found eleven fabricated titles and nine statuses
contradicting their files.

`FS-0005` extended linting so *"CI validates the documentation classes we
own."* It enumerates four globs. Six directories containing markdown are
outside them, including the repository root.

Separately, five `bats` suites exist and none are executed. `bats` is
invoked in no npm script and no workflow, so `ROLE_CONTRACT`'s pre-commit
testing gate has nothing to run and every test in the repository is
decorative.

This spec closes all three gaps. It also supplies the governing spec for
the code obligations in `ADR-0027` and `ADR-0030`, neither of which had
one.

## Goals

- Extend `check-status.sh` to validate the ADR index against ADR files, and
  to compare titles and statuses in the FS and PLAN indexes.
- Check ADR structural completeness, including the Validation section
  `docs/decisions/README.md` requires before acceptance.
- Check that every path a governed document names actually resolves.
- Implement `ADR-0027`'s PLAN self-approval check: `touches:` containment
  against the governing FS's `interfaces:`, plus the reserved-path set.
- Implement `ADR-0030` rule 3 as a CI check: an ADR that changes a rule
  must modify the governing current-state document in the same change.
- Extend lint coverage to every directory containing governed markdown,
  preserving deliberate exemptions.
- Execute the existing `bats` suites in CI and expose them locally.
- Make coverage failures loud rather than absent — an unchecked surface
  should be a visible gap, not a silent one.

## Non-Goals

- Rewriting `check-status.sh`. This extends it.
- Changing any rule the checks enforce. `ADR-0027` and `ADR-0030` decide
  what is checked; this spec decides that it is checked and how failure is
  reported.
- Linting preserved evidence. `docs/orchestration/multi-model-pilot-001/`
  carries `default: false` deliberately and must remain exempt.
- Enforcing convention-only rules. `ADR-0013`'s artifact boundaries,
  `ADR-0019`'s Type immutability, `ADR-0020`'s parked-state suppression,
  and `ADR-0026`'s declaration rule are enforced by detection or
  discipline by decision, not by omission.
- Adding a test framework. `bats` is already the repository's choice; this
  spec runs it.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — needs drift caught by CI rather
  than by manual audit.
- **Agent actors** — run `npm run check:status` before committing and are
  entitled to have it mean something.
- **Consumer-repo maintainers** — inherit these gates when vendoring, and
  inherit their coverage gaps too.

## Behavior

### 1. ADR index consistency

`check-status.sh` gains ADR validation, matching what it already does for
FS and PLAN:

- Every `docs/decisions/ADR-*.md` has a row in `docs/decisions/README.md`.
- Every index row's title matches the ADR file's H1, after stripping its
  `ADR-NNNN:` numbering prefix.
- Every index row's status matches the file's front-matter `status:`.
- Every index row corresponds to a file that exists.

**Direction of authority:** the file wins on title, the file wins on
status. The audit that motivated this spec resolved one column each way
because the index had recorded a merge the files missed — that was a
one-time reconciliation of historical drift, not a rule. Going forward the
file is authoritative for both, and the index is generated from it.

### 1a. FS and PLAN index consistency

The same four assertions as §1, applied to `docs/specifications/README.md`
and `docs/change-plans/README.md`. The existing check validates that rows
exist; it does not compare titles or statuses.

An audit during this spec's drafting found **15 of 22** FS index rows
carrying titles that differ from their front matter. Unlike the ADR index,
these are consistent abbreviations of real titles rather than fabrications
— a lower-severity class, and one that only stays lower-severity while
something checks it.

### 1b. ADR structural completeness

`docs/decisions/README.md` §2 requires an ADR to carry Context and Problem
Statement, Considered Options, Decision Outcome, Consequences, and
Validation before it may move to `accepted`. Nothing checks this.

`ADR-0013`, `ADR-0014`, and `ADR-0015` have no Validation section.
`ADR-0015` is `accepted` without one.

The check verifies all five sections are present, and reports an ADR at
`accepted` missing any of them as a distinct, higher-severity failure.

### 1c. Referenced-path resolution

Every path a governed document names in backticks — `.md`, `.sh`, `.yml`,
`.json`, `.py`, `.bats` — must resolve, relative to the repository root or
to the naming document's own directory.

This catches the class of defect that motivated adding it. `PLAN-0017`
deleted `roles/ROLE_CONTRACT.md` as a byte-identical duplicate of
`guidelines/ROLE_CONTRACT.md` and did not remove the references. Seven
documents still point at it, including `README.md`, `INTEGRATION.md`, and
three skills — and `INTEGRATION.md` lists it eleven times, once as
precedence level 2, "cannot be weakened." A consumer following the
documented integration path looks for a file that is not there.

Exclusions, which the check must honour rather than the corpus being
edited to satisfy it:

- `docs/orchestration/multi-model-pilot-001/` — preserved evidence whose
  references are to the branch context it came from.
- Paths a `touches:` field declares as *to be created* by an approved PLAN.
- Uninitialised submodule contents. `vendor/madr/` is a submodule; its
  files are absent until `git submodule update --init` and that is not
  drift.

### 2. PLAN self-approval check (`ADR-0027`)

For any PLAN with `status: approved`:

- Every entry in `touches:` falls within the governing FS's `interfaces:`,
  or the PLAN carries evidence of human approval.
- No entry in `touches:` matches the reserved set: `docs/decisions/`,
  `guidelines/ROLE_CONTRACT.md`, `scripts/`, `.github/workflows/`,
  `package.json`.

A violation names the offending path and which rule it broke.

A PLAN with no `touches:` field fails this check rather than skipping it.
An absent declaration is not an empty one.

### 3. Current-state update check (`ADR-0030` rule 3)

**CI-only**, because it requires the change set and `check-status.sh` must
remain runnable against a working tree with no diff context.

For every ADR added or modified in a pull request: if its `## Links`
section references a path under `workflows/`, `guidelines/`, `skills/`,
`templates/`, or `integrations/`, at least one such referenced path must
also be modified in the same pull request.

This catches the common case — an ADR that changes a rule and names the
document carrying it, without touching that document. It does not catch an
ADR that changes a rule and names nothing, which is a documentation defect
the hygiene gate covers.

### 4. Lint coverage

`npm run lint:docs` and the CI workflow cover every directory containing
governed markdown: `docs/decisions/`, `docs/specifications/`,
`docs/change-plans/`, `workflows/`, `guidelines/`, `skills/`,
`templates/`, `integrations/`, `roles/`, and root-level `*.md`.

Per-directory `.markdownlint.yml` files continue to govern their
directories. `docs/orchestration/multi-model-pilot-001/` remains exempt via
its `default: false` config, and expanding coverage MUST NOT override it.

Coverage is **derived, not enumerated** where the tooling allows. The
enumerated-glob pattern is what produced these gaps: every new directory
was unguarded by default, and nobody noticed because nothing reported it.

### 5. Gate documentation

`ADR-0015` requires every governance gate to carry a description in
`scripts/README.md` explaining its purpose, when it runs, and what a
failure means. That file does not exist, and `scripts/` contains
`check-status.sh`.

This spec creates it and documents every check it adds, alongside the
checks already present. A gate whose failure message is the only
explanation of what it wanted is a gate people work around.

### 6. Test execution

- `npm test` runs the `bats` suites under `test/`.
- CI runs the same, as a job that blocks merge.
- A missing `bats` binary fails loudly with an install hint, rather than
  passing vacuously.

## Success Criteria

**ADR index**:

- Given an ADR file whose H1 differs from its index row, when
  `npm run check:status` runs, then it exits non-zero naming the ADR.
- Given an ADR whose front-matter status differs from its index row, when
  the check runs, then it exits non-zero naming the ADR.
- Given an ADR file with no index row, when the check runs, then it exits
  non-zero.
- Given an index row naming a file that does not exist, when the check
  runs, then it exits non-zero.

**FS and PLAN indexes**:

- Given an FS whose front-matter title differs from its index row, when
  the check runs, then it exits non-zero naming the FS.
- Given a PLAN with no index row, when the check runs, then it exits
  non-zero.

**ADR structure**:

- Given an ADR missing any of the five required sections, when the check
  runs, then it exits non-zero naming the ADR and the missing section.
- Given an ADR at `accepted` missing a required section, when the check
  runs, then the failure is reported at higher severity than the same
  omission on a `proposed` ADR.

**Referenced paths**:

- Given a governed document naming a path that resolves neither from the
  repository root nor from its own directory, when the check runs, then it
  exits non-zero naming the document and the path.
- Given a path under `docs/orchestration/multi-model-pilot-001/`, when the
  check runs, then it is not reported.
- Given a path declared in an approved PLAN's `touches:` and not yet
  created, when the check runs, then it is not reported.

**PLAN self-approval**:

- Given an approved PLAN whose `touches:` includes a path outside its FS's
  `interfaces:` and no human approval evidence, when the check runs, then
  it exits non-zero naming the path.
- Given an approved PLAN whose `touches:` includes `scripts/` and no human
  approval evidence, when the check runs, then it exits non-zero.
- Given an approved PLAN with no `touches:` field, when the check runs,
  then it exits non-zero.

**Current-state update**:

- Given a PR modifying an ADR whose Links reference a `workflows/` path,
  and modifying no such path, when CI runs, then the job fails naming the
  unmodified document.
- Given the same PR that also modifies the referenced document, when CI
  runs, then the job passes.

**Lint coverage**:

- Given a markdown file with a lint violation in any covered directory,
  when `npm run lint:docs` runs, then it exits non-zero.
- Given a file under `docs/orchestration/multi-model-pilot-001/` with a
  style violation, when lint runs, then it does not fail.

**Gate documentation**:

- Given `scripts/README.md`, when it is read, then every check
  `check-status.sh` performs has an entry naming its purpose, when it
  runs, and what a failure means.

**Test execution**:

- Given the repository, when `npm test` runs, then every `bats` suite
  under `test/` executes.
- Given a failing assertion in any suite, when CI runs, then the job fails.
- Given a machine with no `bats` installed, when `npm test` runs, then it
  fails with a message naming the missing dependency.

## Edge Cases

- **A per-directory config disables everything.** Distinguishing a
  deliberate exemption from an accidental one is not mechanically
  possible; the check reports which directories are exempt so the set is
  visible in CI output.
- **An ADR's Links reference several current-state documents.** Modifying
  any one satisfies the check. Requiring all would fail legitimate changes
  that touch one rule among several the ADR mentions.
- **A PLAN governs several FSs.** `touches:` must be contained in the
  union of their `interfaces:`.
- **An index row exists for a deleted ADR.** Caught by the
  file-exists check.
- **`bats` unavailable in a consumer's environment.** The npm script fails
  with an install hint; the framework does not vendor a test runner.

## Out of Scope

- Enforcing convention-only rules (see Non-Goals).
- Linting non-markdown files.
- Validating ADR *content* beyond title, status, and index presence.
- Replacing markdownlint or bats.
- Retroactively fixing drift found when coverage first lands. That is
  PLAN work, and the corpus is expected to fail on first run.

## Dependencies

- `FS-0013`: established `check-status.sh` and the drift-cannot-recur
  goal this spec extends to ADRs.
- `FS-0005`: established the lint globs this spec widens.
- `ADR-0008`: markdownlint as the baseline quality gate.
- `ADR-0015`: governance gates require an approved FS and PLAN before
  implementation — the reason this spec exists rather than the checks
  being written directly.
- `ADR-0027`: defines the PLAN self-approval rule this implements.
- `ADR-0030`: defines rule 3, which §3 implements.

## Open Questions

None blocking approval.

- **Whether the ADR index should be generated rather than checked.** A
  generator removes the drift class entirely; a checker preserves the
  index as a reviewable artifact. Working answer: check first, since a
  generator is a larger change and the checker is the prerequisite for
  trusting either. Confirm.
- **Whether rule 3 should also run locally** against staged changes.
  Working answer: no — the local check must work without diff context, and
  a pre-commit hook is a consumer choice. Confirm.

## Rollout / Migration

1. Extend `check-status.sh` with §1 and §2. Expect the corpus to fail on
   first run; fixing what it finds is PLAN work.
2. Add the §3 CI job.
3. Widen lint coverage per §4, verifying the orchestration exemption
   survives.
4. Create `scripts/README.md` per §5, covering both existing and new checks.
5. Add `npm test` and the CI job per §6. Expect existing suites to reveal
   failures never previously executed.
6. Update `ADR-0027` and `ADR-0030` `related_specs` to name this spec.
7. Remove the corresponding entries from `BACKLOG.md`.
