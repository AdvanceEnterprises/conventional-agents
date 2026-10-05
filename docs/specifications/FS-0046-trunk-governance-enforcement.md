---
type: feature-spec
id: FS-0046
status: draft
title: Whole-corpus governance triggers and trunk merge enforcement
owner: ajoeofalltrades
test_required: true
interfaces:
  - ".github/workflows/lint-docs.yml"
  - ".github/workflows/pages.yml"
  - "INTEGRATION.md"
  - "integrations/README.md"
  - "integrations/github/README.md"
  - "skills/gh-pr-workflow/SKILL.md"
  - "integrations/runtimes/claude-code/skills/gh-pr-workflow/SKILL.md"
  - "test/FS-0046/**"
  - "docs/specifications/FS-0046-trunk-governance-enforcement.md"
  - "docs/change-plans/PLAN-0052-implement-fs-0046-trunk-governance-enforcement.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0012
  - ADR-0015
  - ADR-0024
  - ADR-0025
  - ADR-0026
  - ADR-0027
  - ADR-0030
supersedes: []
requires: []
tags: [ci, branch-protection, governance, human-review]
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
# Feature Spec: Whole-corpus governance triggers and trunk merge enforcement

## Status

- Draft

## Plan Status

- **PLAN-0052 is `draft`.** The initial package contains this spec, its plan,
  index rows, and a draft CHANGELOG entry only. It does not edit a workflow,
  repository setting, or live ruleset.
- Implementation changes `.github/workflows/`, a reserved path under
  ADR-0027. Live ruleset configuration is also a human-controlled external
  change. Both require separate recorded human approval before execution.

## Summary

The governance workflow inspects whole-repository state, so event-level path
filters must not allow a change to its inputs to bypass the checks. The live
`trunk` branch must also require human review and the blocking governance checks
to pass. This spec defines unfiltered governance triggers, a trunk-only active
ruleset that preserves the existing broader deletion/non-fast-forward rules,
and read-back evidence that the hosted controls actually enforce the intended
policy.

## Goals

- Run governance checks for every pull request and every push to `trunk`,
  regardless of changed paths.
- Preserve the workflow's concurrency and timeout spend guards and its
  read-only/fork-safe permissions.
- Require a pull request, at least one approval from someone other than its
  author, and the blocking checks emitted by workflows active on `trunk`.
- Verify the effective live rules and an otherwise-green PR without an
  approving review before
  claiming that the controls are enforced.

## Non-Goals

- Making GitHub a dependency of the offline framework gates.
- Granting agents merge, bypass, or direct-push authority.
- Changing repository visibility, merge strategy, or the existing all-branch
  deletion/non-fast-forward rules.
- Requiring advisory or explicitly non-blocking checks.
- Treating a successful ruleset API mutation as verification.

## Users / Stakeholders

- Contributors whose changes alter governance inputs or implementation.
- Maintainers who rely on required CI and human review before `trunk` changes.
- Consumers reading the GitHub binding's setup guidance.

## Interfaces

- Type: GitHub Actions workflow, repository ruleset, and GitHub-binding
  documentation.
- Details:
  - `.github/workflows/lint-docs.yml` keeps `push` limited to `trunk` and
    `pull_request` open to all bases, but removes event-level `paths:` filters.
    Existing concurrency groups, timeouts, permissions, and fork-safety
    behavior remain unchanged.
  - The live repository gains a separate active ruleset scoped only to
    `refs/heads/trunk`; the existing `Base Ruleset` remains unchanged.
  - The new ruleset requires a pull request and one approving review, dismisses
    stale approvals when new commits arrive, requires the blocking status checks
    active on `trunk`, and has no bypass actors.
  - At the audit basis, the blocking `lint-docs.yml` contexts are
    `lint-adrs`, `lint-specs`, `lint-change-plans`, `lint-workflows`,
    `lint-docs-widened`, `check-status`, `github-binding-audit`,
    `check-freshness`, `lint-cross-repo`, `current-state-update`,
    `test-bats`, and `validation`. Open PR check rollups also contain
    `Analyze (python)`; classify this external/platform context from the live
    rules and check-run inventory, and require it if it is an active,
    non-advisory PR check. PR #208's current Pages workflow has an unfiltered
    `pull_request` trigger; if that revision lands unchanged on `trunk`, require
    `Build and validate site`. Advisory `claude-plugin-validate` and push-only
    `Deploy Pages` are not required PR contexts. Re-read active workflow names
    and complete PR check-run inventory before applying the live configuration
    and revise this list first if it has changed.
  - `test/FS-0046/**` proves the trigger has no path-based skip condition.
  - `INTEGRATION.md`, `integrations/README.md`, and
    `integrations/github/README.md` describe the generic GitHub binding and
    link only to existing guidance; they do not claim unsupported Code Owner
    review requirements or unverified live settings.
  - PR workflow guidance distinguishes human review policy from repository-
    specific configuration and verified live enforcement.

## Success Criteria

- **SC-1 — whole-corpus events cannot be skipped by paths.** Given the workflow
  configuration, when the trigger contract is evaluated, then `pull_request`
  has no path filter, `push` has no path filter and remains scoped to `trunk`,
  and every PR base receives the governance workflow.
- **SC-2 — trigger regression is tested.** Given a fixture or the repository's
  workflow, when the focused test runs, then it fails if either event gains a
  `paths:` or `paths-ignore:` filter and passes for the SC-1 trigger contract.
- **SC-3 — cost and fork guards remain.** Given the revised workflow, when its
  diff is inspected and the workflow test runs, then concurrency cancellation,
  bounded job timeouts, read-only permissions, and `pull_request` (not
  `pull_request_target`) remain present.
- **SC-4 — live ruleset is trunk-only and human-gated.** Given the authorized
  ruleset change, when the live ruleset and effective branch rules are read
  back, then the active ruleset targets only `refs/heads/trunk`, requires PRs
  and at least one non-author approval, dismisses stale approvals on new
  commits, and has no bypass actors.
- **SC-5 — all blocking governance contexts are required.** Given the active
  workflows and complete PR check-run inventory on the default branch at
  installation time, when the ruleset is read back, then every active,
  non-advisory PR context identified in FS-0046's interface details is required
  and no explicitly advisory or push-only context is required.
- **SC-6 — live enforcement is demonstrated.** Given the active ruleset and a
  dedicated verification PR opened as draft, when all required checks are
  green, required comment-only reviewer rounds are complete, and their findings
  are addressed without an approving formal review, then marking that PR ready
  causes GitHub to report review required and blocked; record its URL, head SHA,
  review state, check conclusions, and merge state, then close it without
  merging. If CI or the review gate cannot be observed, acceptance remains
  incomplete.
- **SC-7 — external state is separate from offline validation.** Given a clean
  local checkout without GitHub credentials or network access, when the focused
  workflow test and offline validation run, then they complete without reading
  or mutating repository rulesets.
- **SC-8 — policy claims are scoped accurately.** Given the updated binding and
  PR guidance, when a reader distinguishes policy, workflow behavior, and live
  configuration, then the documents do not assert that a consumer's or this
  repository's live controls exist without corresponding read-back evidence.

## Edge Cases

- A new blocking job added to a workflow on `trunk` must be added to the
  required-check set before the repository claims that all governance checks are
  enforced.
- A required check that is skipped or never emitted for PRs must not be
  configured as a required context.
- A workflow's site-build check is required only if it is emitted for every PR;
  path-filtered or push-only jobs cannot be assumed to satisfy the trunk PR gate.
- A check that is deliberately advisory or uses `continue-on-error` remains
  outside the required set.
- A ruleset broadening beyond `trunk` is a scope change and requires revising
  this spec and plan.
- The existing `Base Ruleset` applies to all branches; adding review/check
  requirements to it would broaden their scope and is excluded.

## Out of Scope

- Repository ruleset automation in CI or portable offline scripts.
- Changing branch permissions for identities other than the `trunk` rules
  described here.
- Deploying GitHub Pages or changing its publication allowlist.

## Dependencies

- ADR-0012 keeps merge execution human-gated and prohibits agent merge or
  bypass.
- ADR-0025 preserves the repository's rebase-and-merge attribution behavior.
- PR #208's Pages build check is included if the current unfiltered `pull_request`
  trigger lands unchanged on `trunk`; re-read the landed workflow before
  ruleset configuration.

## Open Questions

None. One approving review and a separate trunk-only ruleset are the explicit
specification defaults; the complete status-check list must be re-read from the
merged workflows immediately before configuration.
