---
type: feature-spec
id: FS-0047
status: draft
title: Reusable consumer guidance without instance-specific leakage
owner: ajoeofalltrades
test_required: true
interfaces:
  - "INTEGRATION.md"
  - "README.md"
  - "AGENTS.md"
  - "CONTRIBUTING.md"
  - "scripts/README.md"
  - "skills/**/*.md"
  - "workflows/*.md"
  - "integrations/**/*.md"
  - "test/FS-0047/**"
  - "test/FS-0047/instance-exemptions.tsv"
  - "docs/specifications/FS-0047-exported-consumer-boundary-audit.md"
  - "docs/change-plans/PLAN-0053-implement-fs-0047-exported-consumer-boundary-audit.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0009
  - ADR-0015
  - ADR-0016
  - ADR-0017
  - ADR-0026
  - ADR-0027
  - ADR-0030
  - ADR-0033
  - ADR-0037
supersedes: []
requires: []
tags: [consumer-boundary, exported-surface, portability]
created: 2026-10-04
updated: 2026-10-04
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
# Feature Spec: Reusable consumer guidance without instance-specific leakage

## Status

- Draft

## Plan Status

- **PLAN-0053 is `draft`.** The initial package contains this spec, its plan,
  index rows, and a draft CHANGELOG entry only. It does not edit the exported
  guidance or add a regression test.
- The implementation includes a test under `test/FS-0047/`, but it remains
  blocked by the spec-first lifecycle until both governed documents are
  approved.

## Summary

Reusable integration guidance must work for consumers with different
organizations, repositories, directory layouts, and planning substrates. This
spec removes the framework instance's repository URLs, fixed temporary paths,
and fleet assumptions from generic adoption instructions, uses explicit
placeholders or caller-provided configuration, and adds a textual regression
audit. Framework identity and history outside reusable adoption guidance are
preserved; any consumer-specific example retained inside the exported guidance
must be visibly non-normative and narrowly allowlisted.

## Goals

- Let an adopter follow integration guidance without cloning an instance-owned
  URL or relying on an instance-specific filesystem path.
- Explain cross-repository lint in terms of the generic `CA_REPO_DIRS` and
  `CA_TARGET_REPO` inputs, not a named repository fleet.
- Replace concrete actor identities in reusable guidance with consumer-selected
  placeholders; any retained consumer-specific example must be visibly
  non-normative and have an exact, reasoned audit exemption.
- Preserve legitimate repository identity, attribution, and historical records
  outside the reusable contract.
- Prevent recurrence of the identified URL, path, and fleet-name leaks with
  fixture-backed tests.

## Non-Goals

- Moving or rewriting legitimate internal identity and history records.
- Adding consumer-specific policies, a replacement project board, or a new
  organization-specific repository.
- Changing the semantics of cross-repository lint or its configuration.
- Changing the script's framework-instance defaults; generic guidance instead
  tells consumers to configure an explicit target.
- Making framework guidance depend on a consumer repository or provider.

## Users / Stakeholders

- New adopters following `INTEGRATION.md` and the consumer-integration skill.
- Framework maintainers documenting cross-repository lint.
- Existing consumers distinguishing portable requirements from examples that
  belong to one framework instance.

## Interfaces

- Type: Exported Markdown guidance and Bats regression audit.
- Details:
  - `README.md`, `INTEGRATION.md`, and
    `skills/framework-consumer-integration/SKILL.md` use a caller-provided
    `FRAMEWORK_REPO_URL` or visible placeholder in copyable examples; temporary
    checkout examples use a caller-selected `TMPDIR` or `mktemp`, not a fixed
    instance path. The README no longer links to an instance-owned work board.
  - Consumer-conventions examples use a generic `<your-org>-conventions`
    placeholder and do not direct readers to the archived
    `Tais-Den/tais-den-conventions` repository.
  - `scripts/README.md` documents `CA_REPO_DIRS` as a colon-separated list of
    repository roots and `CA_TARGET_REPO` as the single-target override, matching
    the executable behavior; it contains no named fleet inventory and tells
    consumers to set an explicit target rather than rely on this repository's
    local discovery defaults.
  - `workflows/git-and-gh-conventions.md`, `skills/git-commit-identity/SKILL.md`,
    `skills/git-branch-and-commit/SKILL.md`, and
    `integrations/runtimes/claude-code/README.md` use generic actor/email
    placeholders instead of this repository's aliases; generated skill copies
    remain byte-identical to their sources.
  - `test/FS-0047/instance-exemptions.tsv` is an exact-path, exact-literal,
    reason-bearing allowlist. Any retained consumer-specific example must also
    have a visible non-normative label; no broad directory or pattern exemption
    is permitted.
  - `test/FS-0047/**` scans tracked exported Markdown and exercises unmarked
    leak, valid exact-exemption, and malformed-exemption fixtures. It reports
    every unapproved match with source path and line.
  - Generated Claude Code skill copies remain synchronized with their source
    skills when a source skill changes.

The audit covers root `README.md`, `AGENTS.md`, `CONTRIBUTING.md`,
`INTEGRATION.md`, and Markdown under `guidelines/`, `roles/`, `skills/`,
`templates/`, `workflows/`, `integrations/`, `runbooks/`, and `scripts/`.
ADR, FS, PLAN, CHANGELOG, backlog, issue, and test history are not reusable
adoption instructions and are not rewritten by this feature.

An allowlist row has exactly three tab-separated fields: repository-relative
path, exact identifier literal, and non-empty rationale. Blank lines and lines
beginning with `#` are ignored. The path and literal may not contain a glob or
regular-expression pattern. Each path/literal pair must match exactly one
occurrence; zero or multiple matches are invalid rather than a blanket
exemption. A matching consumer-specific example is allowed only when the
document visibly labels it non-normative and the row names that exact location
and literal. Framework identity/history outside this scan remains unchanged.

## Success Criteria

- **SC-1 — generic quick start.** Given a consumer following the README,
  `INTEGRATION.md`, or consumer-integration skill, when they set
  `FRAMEWORK_REPO_URL` to the framework source they selected and run the shown
  commands, then no command requires a Tais-Den-owned URL or the fixed path
  `/tmp/conventional-agents`.
- **SC-2 — cross-repository documentation is generic.** Given the
  `scripts/README.md` explanation, when it describes target selection, then it
  names the actual `CA_REPO_DIRS` and `CA_TARGET_REPO` semantics, recommends an
  explicit target for consumers, and does not enumerate an organization-
  specific fleet or concrete consumer repository set.
- **SC-3 — archived example is portable.** Given a consumer-conventions example
  in any audited exported document, when an adopter follows it, then it uses a
  visible placeholder and does not direct the adopter to an archived or
  instance-owned repository.
- **SC-4 — consumer-specific examples are separated.** Given an audited exported
  document retains a consumer-specific identity, URL, path, or fleet example,
  when a reader encounters it, then the example is visibly labeled
  non-normative and an exact-path/exact-literal allowlist row states its reason;
  generic commands remain parameterized.
- **SC-5 — regression audit catches new leaks.** Given a fixture with a known
  instance-specific URL, fixed checkout path, or fleet identifier without an
  exact allowlist row, when the focused test runs, then it fails and reports the
  file and line; a fixture with one exact, reasoned exemption is reported as
  exempt and does not fail.
- **SC-6 — malformed exemptions fail closed.** Given an exemption row with a
  wildcard path, pattern literal, missing field, empty reason, duplicate entry,
  unmatched source literal, or multiple matching occurrences, when the audit
  runs, then it fails and identifies the row instead of suppressing findings.
- **SC-7 — internal history is preserved.** Given a matching instance identifier
  in an excluded ADR, FS, PLAN, CHANGELOG, backlog, or test record, when the
  exported-surface audit runs, then it does not require rewriting that record.
- **SC-8 — repository validation remains portable.** Given the generic
  guidance and regression test, when `npm run lint:docs`, `npm run check:status`,
  the conformance doctor, and `npm test` run, then they complete without a
  GitHub or Notion dependency.

## Edge Cases

- Framework source URLs in copyable consumer instructions are supplied through
  `FRAMEWORK_REPO_URL`; a canonical URL in repository metadata is not scanned.
- A retained consumer-specific example needs both a visible label and one exact
  allowlist row; an exemption cannot cover adjacent normative instructions.
- Generated copies are part of the exported surface and must not retain stale
  copies of changed source text.
- `CA_TARGET_REPO` overrides `CA_REPO_DIRS`; the prose must not imply that a
  caller needs to set both.

## Out of Scope

- Rewriting historical records or removing legitimate repository ownership
  information from internal governance.
- Migrating organization-specific examples to a different repository in this
  work.
- Changing `scripts/cross-repo-lint.sh` discovery, sorting, or lint semantics.

## Dependencies

- Accepted ADR-0016 places consumer-specific conventions outside the framework.
- Accepted ADR-0017 keeps the framework's nested vendor paths internal.
- ADR-0026 requires recorded human approval scoped to the exact `touches:` set;
  approval of this draft documentation package does not authorize its later
  implementation.
- ADR-0027 reserves `scripts/`; changing `scripts/README.md` requires a
  recorded human approval for that path before implementation.
- Accepted ADR-0037 governs the parameterized GitHub binding; no proposed ADR is
  required as authority for this spec.

## Open Questions

None are blocking.

- **How should public-release material present an optional consumer-conventions
  repository?** *Default: use `<your-org>-conventions` as a placeholder and do
  not name the archived historical repository.* The public-release PR may refine
  presentation, but it must not direct consumers to an instance-owned or
  archived repository; revisit only if a human-reviewed publication decision
  establishes a different generic presentation.
