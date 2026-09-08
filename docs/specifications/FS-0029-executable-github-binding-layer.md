---
type: feature-spec
id: FS-0029
status: implemented
title: Executable layer for the GitHub binding — provisioning, initialisation, and audit commands
owner: ajoeofalltrades
test_required: true
interfaces:
  - "integrations/github/README.md"
  - "integrations/github/lib/gh-common.sh"
  - "integrations/github/bin/gh-submodule-init.sh"
  - "integrations/github/bin/gh-label-provision.sh"
  - "integrations/github/bin/gh-board-audit.sh"
  - "integrations/github/ci-templates/submodule-checkout.yml"
  - "integrations/github/ci-templates/governance-gates.yml"
  - "integrations/github/templates/pull-request.md"
  - "integrations/README.md"
  - "integrations/github-issues-projects.md"
  - ".github/pull_request_template.md"
  - ".github/workflows/lint-docs.yml"
  - "package.json"
  - "scripts/README.md"
  - "test/FS-0029/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0037
  - ADR-0024
  - ADR-0007
  - ADR-0012
  - ADR-0015
  - ADR-0028
  - ADR-0032
  - ADR-0033
supersedes: []
requires:
  - FS-0018
  - FS-0024
tags: [github, binding, integrations, substrate, provisioning, ci, exported-surface]
created: 2026-09-03
updated: 2026-09-06
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

# Feature Spec: Executable Layer for the GitHub Binding

## Status

- Implemented

## Plan Status

- **PLAN-0035 is implemented.** Implementation (PR #113 for #111) was merged
  2026-09-06; the status transition was deferred post-merge and reconciled by
  the maintenance tick (issue #125). Implementation was gated on a recorded
  human approval because the plan's `touches:` set includes
  `scripts/README.md`, `.github/workflows/lint-docs.yml`, and `package.json` —
  all reserved paths under `ADR-0027` — carried by matching `Approved-By:` and
  `Approved-Artifacts:` trailers per `ADR-0026`.

## Summary

`ADR-0024` shipped `integrations/github-issues-projects.md` as the reference
substrate binding. It maps all six core capabilities onto GitHub mechanisms and
ends in a nine-item setup checklist that a human performs by hand, once, from
prose. Nothing creates the label vocabulary that checklist requires, nothing
verifies it exists, and nothing reports when it drifts — and it has drifted:
`propagation` is present in two of three repositories implementing this binding
and absent from the third, unnoticed until an unrelated audit.

The same gap recurs elsewhere. The binding's submodule-initialisation step is
duplicated in at least four CI workflow files across two consumer repositories,
each carrying its own copy of a credential rewrite whose `--global` scope is
load-bearing and documented nowhere. The GraphQL pacing discipline that makes
Projects v2 usable under its invisible secondary rate limit lives in session
transcripts.

This spec adds an **executable layer** to the GitHub binding — three commands, a
shared library, two CI templates, and a pull-request template — under
`integrations/github/`. `ADR-0037` is the governing decision record and fixes the
boundaries: the framework ships mechanisms and never a trigger that mutates a
work item; binding executables are governed as binding content rather than
classified under `ADR-0015`; authentication resolves the framework repository's
visibility rather than assuming it; and no capability is added to the neutral
core, because one binding is not a generalisation.

The existing binding document is not restructured. It remains normative for the
capability mapping; this layer provides mechanisms it already names.

## Goals

- Turn the binding's setup checklist from a one-time manual act into an
  idempotent, re-runnable, auditable one.
- Collapse the duplicated submodule-initialisation step to a single tested
  implementation, and record the `--global` requirement where a reader will find
  it rather than in a workflow comment.
- Make label drift detectable by a command rather than by chance.
- Ship the GraphQL pacing and rate-limit discipline as tested code in the
  exported surface.
- Make the private-to-public transition a fact the code observes at run time, so
  that no consumer must edit workflow authentication on flip day.
- State per command whether it **enforces**, **provisions**, or **reports**, so
  the executable layer inherits the enforcement honesty of the reference
  binding's §7 rather than quietly overclaiming by being executable.
- Have the framework run its own binding, in its own CI, within the implementing
  change.

## Non-Goals

- **Orchestration of any kind.** No scheduler, daemon, watcher, polling loop, or
  workflow `schedule:` trigger that mutates a governed work item. `ADR-0007` is
  accepted at precedence level 1 and `ADR-0037` §2 draws the line; this spec does
  not relitigate it.
- **A board reconciler.** The binding reports board drift and does not correct
  it. Correcting it is the consumer's act under the consumer's policy — for this
  organisation, the maintenance tick. `ADR-0028` makes the reconciler the
  correctness guarantee; it does not make it the framework's to run.
- **Adding a seventh core capability.** `ADR-0024`'s ordering rule forbids
  generalising from a single binding. `integrations/README.md`'s six capabilities
  are unchanged, and a binding that ships no executables remains fully
  conforming.
- **Restructuring `integrations/github-issues-projects.md`.** It gains
  cross-references and nothing else.
- **Migrating consumer repositories.** `feral-fleet` and `pack-protocol` adopting
  these commands is consumer work, sequenced in their own repositories after this
  lands. This spec ships the mechanism and the framework's own adoption of it.
- **Changing the maintenance tick.** The tick may adopt `lib/gh-common.sh`; that
  is a consumer decision, not a requirement here.
- **Validating consumer board-metadata files against a schema.** Named as an Open
  Question with a stated default of *not now*; see below.
- **Replacing or relocating `config/project.example.yml`.** It stays where it is
  and is referenced, not moved.

## Users / Stakeholders

- **Consumer repositories vendoring this framework**, whose CI performs the
  submodule-initialisation step and whose substrate must match the binding.
- **This framework**, which is its own first consumer and whose CI must exercise
  what it ships (`ADR-0024`: the framework's own substrate should be documented,
  not hidden).
- **Adopters outside this organisation**, post-public-release, for whom the
  binding is currently a checklist and tribal knowledge they have no access to.
- **The maintenance tick** (consumer-side), as a potential caller of the shared
  library.

## Interfaces

- **Type:** CLI, Config, Infra, Library
- **Details:**

| Path | Kind | Purpose |
| --- | --- | --- |
| `integrations/github/README.md` | Doc | The executable layer's contract and the per-command enforcement table |
| `integrations/github/lib/gh-common.sh` | Library | Auth precheck, target resolution, visibility resolution, GraphQL pacing and backoff |
| `integrations/github/bin/gh-submodule-init.sh` | CLI | Dual-regime submodule initialisation |
| `integrations/github/bin/gh-label-provision.sh` | CLI | Idempotent label provisioning and drift audit |
| `integrations/github/bin/gh-board-audit.sh` | CLI | Read-only project-board drift report |
| `integrations/github/ci-templates/submodule-checkout.yml` | Template | Canonical checkout + submodule-init job fragment |
| `integrations/github/ci-templates/governance-gates.yml` | Template | Canonical governance-gate job fragment |
| `integrations/github/templates/pull-request.md` | Template | Shipped pull-request scaffold |
| `.github/pull_request_template.md` | Instance | This framework's adoption of the above |
| `package.json` | Config | npm registration of the three commands |
| `scripts/README.md` | Doc | Cross-reference establishing where binding executables live and why they are not Category 1 gates |
| `.github/workflows/lint-docs.yml` | Infra | Lint coverage widening; the framework's own use of the binding |
| `test/FS-0029/**` | Test | bats suites |

## Success Criteria

### Shared behaviour — every command under `bin/`

- **SC-1.** Given any command is invoked with `--help`, when it runs, then it prints usage
   naming every flag and environment variable it reads, and exits 0.
- **SC-2.** Given `gh` is not authenticated, when any command that calls the GitHub API
   runs, then it exits non-zero before making any API call, and the message names
   `gh auth status` as the remediation (`ADR-0012`).
- **SC-3.** Given a caller whose working directory is inside a repository, when a command
   resolves its target repository, then it resolves from the caller's working
   directory via `git rev-parse --show-toplevel`, and `CA_TARGET_REPO` overrides
   the resolved value (`FS-0024`/`ADR-0033`).
- **SC-4.** Given any command, when its source is inspected, then it reads no path
   containing a `vendor/` segment.
- **SC-5.** Given any command exits non-zero, when its output is inspected, then the
   message names the specific condition and the remediation — not only the
   failed operation.

### `gh-submodule-init.sh` — dual-regime initialisation

- **SC-6.** Given the framework repository is public, when the command runs with no
   credential in the environment, then it configures no credential, initialises
   the submodule, and exits 0. Absence of a credential produces no warning.
- **SC-7.** Given the framework repository is private and no credential is present, when
   the command runs, then it exits non-zero without initialising the submodule,
   and the message names the expected environment variable. It does not skip, and
   it does not continue with the submodule uninitialised.
- **SC-8.** Given the framework repository is private and a credential is present, when
   the command runs, then it configures the `insteadOf` rewrite at **`--global`**
   scope. A test asserts the `--global` flag specifically, as a regression guard:
   `git submodule update --init` clones in a child process that reads only global
   and system configuration, so a repository-scoped rewrite is silently ignored.
- **SC-9.** Given the command runs with a credential present, when its combined stdout and
   stderr are inspected, then the credential value appears nowhere in them.
- **SC-10.** Given the command has already run successfully, when it runs a second time
  with identical inputs, then it exits 0 and the resulting `git config` state is
  byte-identical to the state after the first run.
- **SC-11.** Given visibility cannot be determined (no network, unauthenticated `gh`, or
  an API error), when the command runs, then it exits non-zero rather than
  guessing a regime. An assumed regime is the fail-open shape `FS-0024` exists
  to remove.

### `gh-label-provision.sh` — provisioning and drift audit

- **SC-12.** Given a repository missing one or more of the `FS-0018` six (`enhancement`,
  `bug`, `documentation`, `spec`, `plan`, `question`), when the command runs in
  its default mode, then each missing label is created, each existing label is
  left unmodified, and the summary states how many were created and how many
  already existed.
- **SC-13.** Given the command has just run successfully, when it runs again, then it
  creates nothing, exits 0, and reports zero creations.
- **SC-14.** Given the command is invoked with `--audit`, when it runs, then it makes no
  mutating API call, reports labels that are **missing** and labels that are
  **unexpected** as two distinct categories, and exits 0.
- **SC-15.** Given the command is invoked with `--dry-run`, when it runs, then it
  makes no mutating API call, prints exactly the mutations it *would* make
  in default mode, and exits 0. `--dry-run` composes with `--audit` (the
  audit's `missing` set is printed as the would-create list); both flags'
  behaviour is covered by the same stubbed-`gh` tests as SC-12–SC-14.
- **SC-16.** Given a repository carries labels beyond the framework set, when `--audit`
  runs, then those labels are reported as unexpected and are never deleted,
  under any flag this command provides.
- **SC-17.** Given the shipped framework label set is inspected, then it contains exactly
  the `FS-0018` six and no organisation-specific label — `propagation`
  specifically must not appear (`ADR-0032`). Consumer additions are supplied
  through the documented extension input and are not compiled in.

### `gh-board-audit.sh` — read-only drift report

- **SC-18.** Given the command's source is inspected, then it contains no mutating project
  or issue operation — no `item-add`, no `item-edit`, no `--single-select-option-id`
  write, no `issue edit`, no `issue create`.
- **SC-19.** Given a project board, when the command runs, then it reports, as separate
  categories: project items whose `Issue Type` is unset, project items whose
  `Status` is unset, and open Issues in the target repository that have no
  project item.
- **SC-20.** Given the command makes successive GraphQL calls, when it runs, then it
  leaves at least a configurable minimum interval between them (default 7
  seconds, override via a documented environment variable).
- **SC-21.** Given a GraphQL call returns a `RATE_LIMIT` error, when the command handles
  it, then it waits until the reported reset timestamp plus a buffer before
  retrying, and does not consult the `rate_limit` endpoint to decide whether to
  proceed — that endpoint reports the primary quota and is silent about the
  secondary burst limit that actually failed the call. Verified against a
  stubbed `gh`.
- **SC-22.** Given the command completes enumeration, when it exits, then it exits 0
  whether or not it found drift. `--strict` exits non-zero when findings exist,
  and the framework does not wire `--strict` into its own CI: a command that
  fails a pull request is a Category 1 gate and belongs in `scripts/`
  (`ADR-0037` §3).
- **SC-23.** Given an operational failure — unreachable API, exhausted retries, malformed
  response — when the command exits, then it exits non-zero and is
  distinguishable in its output from a clean run that found drift.

### CI templates and the pull-request template

- **SC-24.** Given any file under `integrations/github/ci-templates/` or
  `integrations/github/templates/`, when it is inspected, then it contains no
  organisation name, repository name, project number, node ID, field or option
  ID, or secret value (`ADR-0032`).
- **SC-25.** Given any file under `integrations/github/`, when it is inspected, then it
  contains no `schedule:` trigger (`ADR-0037` §2).
- **SC-26.** Given `ci-templates/submodule-checkout.yml`, when it is inspected, then its
  checkout step sets `fetch-depth: 0` and its submodule step invokes
  `gh-submodule-init.sh` rather than inlining the credential rewrite. The
  shallow-clone hazard is documented in `scripts/README.md`; the canonical
  template must not reintroduce it.
- **SC-27.** Given `.github/pull_request_template.md`, when it is inspected, then it
  exists and carries every section defined by
  `integrations/github/templates/pull-request.md`. The framework uses what it
  ships.

### Documentation and registration

- **SC-28.** Given `integrations/github/README.md`, when it is inspected, then it contains
  a table with one row per shipped command classifying it as **enforces**,
  **provisions**, or **reports**, and every command under `bin/` appears in it
  (`ADR-0037` §6).
- **SC-29.** Given `integrations/github/README.md`, when it is inspected, then it records
  the operational hazards this layer works around: the `--global` requirement,
  the invisible GraphQL secondary limit, and the distinct `unknown owner type`
  owner-resolution error that must not be retried as a rate limit,
  `gh pr edit --body` failing on the GraphQL deprecation with `gh api -X PATCH`
  as the working path, `reviewDecision` being null on draft pull requests, and
  the 60-day scheduled-workflow auto-disable already named in the reference
  binding §6.
- **SC-30.** Given `package.json`, when it is inspected, then each `bin/` command is
  registered as an npm script, and `scripts/README.md` cross-references the
  executable layer and states why these are not Category 1 gates.
- **SC-31.** Given `npm run lint:integrations`, when it runs, then it covers markdown
  beneath `integrations/` recursively, not only `integrations/*.md`.
- **SC-32.** Given `npm run check:status`, when it runs against this repository after the
  change, then rule 8 passes: every path named in backticks in
  `integrations/github/README.md` resolves.
- **SC-33.** Given `npm test`, when it runs, then the `test/FS-0029/` suites execute and
  pass, and `bash -n` succeeds on every shipped `.sh` file.

## Edge Cases

- **Visibility flips mid-transition.** A consumer's cached knowledge is stale for
  the duration of one CI run. Resolution is per-invocation and not cached, so the
  worst case is one run using the previous regime — and SC-7 makes the
  private-with-no-credential case loud rather than silent, so the failure
  direction is safe.
- **A credential exists but is expired or scoped wrong.** Distinct from absent.
  The command must not report "no credential"; the API error must reach the
  operator, because the two conditions have different fixes.
- **`gh` is absent entirely.** Fails with an install hint, matching
  `run-bats.sh`'s treatment of a missing `bats` — a missing dependency fails
  loudly rather than passing vacuously (`FS-0022` §6).
- **The repository has no project board.** `gh-board-audit.sh` reports that the
  board is absent and exits 0 in default mode. A repository legitimately without
  a board is not in an error state; the reference binding §2 already provides
  label-namespace and title-prefix fallbacks for exactly this.
- **A label exists with the right name and a different colour or description.**
  Reported as present. The framework asserts the vocabulary, not its
  presentation; overwriting a consumer's colour choice would be instance data
  imposed from a template repository.
- **Concurrent invocations.** Label creation races produce an
  already-exists error from the API, which is treated as success — that is what
  idempotent means here. The commands impose no locking.
- **A shallow clone.** `check-status.sh` already fails loudly and misleadingly
  under `fetch-depth: 1`; SC-26 puts `fetch-depth: 0` in the canonical
  template so a consumer copying it does not rediscover this.
- **Bash 3.2.** macOS system bash has no associative arrays and treats an empty
  array expansion as unset under `set -u`. The shipped commands avoid both
  hazards; the FS-0029 suites can be run with an explicit interpreter via
  `CA_BASH_FOR_TESTS`, as recorded in `scripts/README.md`.

## Out of Scope

- Mutating any project field, issue status, or board membership.
- Any Notion, Slack, or non-GitHub integration surface.
- The maintenance tick's review pipeline, promotion logic, or suggestion
  generation.
- Repository settings automation: branch protection, private vulnerability
  reporting, Copilot review enablement. The reference binding's setup checklist
  names these; automating settings is a different authority surface and a
  different decision.
- `shellcheck` adoption as a CI gate. Worth doing and outside this change: it
  would apply to `scripts/` as much as to `integrations/`, which makes it a gate
  question rather than a binding question.
- A second platform binding, or any generalisation of this layer toward one.
- Deleting or renaming any existing label, workflow, or configuration file in any
  repository.

## Dependencies

- `gh` CLI, authenticated, with `project` scope for board enumeration and
  repository admin for label creation. The two commands requiring different
  scopes must say so rather than failing opaquely.
- `git` ≥ 2.13 for `insteadOf` behaviour as relied upon.
- `bats` and `rg` for the test suites (`scripts/run-bats.sh` already requires
  both).
- `ADR-0037` accepted.
- `FS-0018` for the label vocabulary; `FS-0024`/`ADR-0033` for target resolution.

## Rollout / Migration

1. `ADR-0037` accepted; this spec approved.
2. The layer lands with the framework as its only consumer: `.github/workflows/lint-docs.yml`
   adopts the canonical fragments, `.github/pull_request_template.md` is added,
   and `gh-label-provision.sh --audit` is run against this repository and its
   output recorded in the pull request.
3. Consumer adoption happens in the consumer repositories, on their own schedule.
   Nothing in this change edits them, and the inline steps they carry keep
   working until they choose to replace them.
4. On the public transition, no consumer authentication edit is required.
   SC-6 is the test of that claim, and the transition is the occasion to
   check it.

## Observability

- Each command prints a summary line stating what it examined and what it
  changed, with created-versus-existing and found-versus-clean distinguishable
  without parsing.
- `--audit` and `--dry-run` output are stable enough to diff between runs, so
  drift over time is visible by comparing two reports.
- Rate-limit waits are announced with the reset timestamp being waited for. A
  command that appears hung is indistinguishable from one that is, unless it says
  so.

## Security / Privacy

- **Data handled:** a GitHub token supplied through the environment; repository,
  label, and project metadata read from the API.
- **Threats considered:** credential disclosure in CI logs; credential
  persistence in global git configuration on a shared runner; a fail-open
  initialisation producing a governance gate that runs against an absent
  framework and reports green.
- **Mitigations:** SC-9 asserts the token never reaches stdout or stderr;
  the `insteadOf` rewrite is scoped to the framework's own host prefix rather
  than to all of `github.com`; SC-7 and SC-11 make every indeterminate or
  under-credentialed state a hard failure. No command writes a credential to a
  file in the repository.

## Open Questions

None blocking. Each of these has a stated default that implementation follows
unless the approving human directs otherwise:

- **Should the binding validate a consumer's board-metadata file against
  `config/project.example.yml`?** *Default: no.* It requires YAML parsing in
  bash for a file that changes rarely, and `gh-board-audit.sh` detects the
  failure that a wrong ID actually causes. Revisit if a consumer hits it.
- **Should `gh-label-provision.sh` accept its extension set as a file or as
  repeated flags?** *Default: a file path, defaulting to a documented location in
  the caller's repository*, consistent with `ADR-0033`'s resolution rule for
  `config/gates.yml`.
- **Should the CI templates be copyable fragments or reusable workflows
  (`workflow_call`)?** *Default: copyable fragments.* A reusable workflow in a
  private repository imposes access requirements on every caller, and the
  visibility regime is precisely what this layer refuses to assume. Reconsider
  after the public transition.
