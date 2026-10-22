---
type: change-plan
role: implementer
language: markdown and bash
status: approved
related_specs:
  - FS-0047
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
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
touches:
  - docs/specifications/FS-0047-exported-consumer-boundary-audit.md
  - docs/change-plans/PLAN-0053-implement-fs-0047-exported-consumer-boundary-audit.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
  - scripts/cross-repo-lint.sh
  - scripts/README.md
  - workflows/git-and-gh-conventions.md
  - skills/git-commit-identity/SKILL.md
  - skills/git-branch-and-commit/SKILL.md
  - skills/framework-consumer-integration/SKILL.md
  - integrations/runtimes/claude-code/skills/git-commit-identity/SKILL.md
  - integrations/runtimes/claude-code/skills/git-branch-and-commit/SKILL.md
  - integrations/runtimes/claude-code/skills/framework-consumer-integration/SKILL.md
  - integrations/runtimes/claude-code/README.md
  - integrations/runtimes/claude-code/settings.fragment.json
  - INTEGRATION.md
  - README.md
  - .github/workflows/lint-docs.yml
  - test/FS-0047/instance-exemptions.tsv
  - test/FS-0047/exported-boundary.bats
  - test/FS-0017/attribution-diagnostic.bats
  - test/FS-0043/cron-attribution.bats
  - test/FS-0017/commit-attribution.bats
  - .claude/settings.json
  - CHANGELOG.md
created: 2026-10-04
updated: 2026-10-22
---

# PLAN-0053: Implement FS-0047 — Exported consumer-boundary audit

> **Template note (historical):** the first revision published the governance
> package only: FS-0047, this plan, the two index rows, and a CHANGELOG entry.
> It did not edit exported guidance or add tests. The implementation revision
> (the `touches:` set below) proceeds only under the recorded human approval
> carried by this revision's approval commit, the exact implementation
> `touches:` set below, and separate recorded approval for the reserved
> `scripts/README.md`, `scripts/cross-repo-lint.sh`, and
> `.github/workflows/lint-docs.yml` paths.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0047
* Related ADR ID(s): ADR-0009, ADR-0015, ADR-0016, ADR-0017, ADR-0026,
  ADR-0027, ADR-0030, ADR-0033, ADR-0037
* Issue / PR Reference: #211

## 2. Scope of Change

**This package WILL (documentation + implementation revisions):**

* Publish FS-0047 and this plan as approved documents.
* Add the new approved rows to the specification and plan indexes.
* Add a CHANGELOG entry that describes the proposal without claiming the
  exported guidance has been corrected.

**This package will NOT:**

* Change `INTEGRATION.md`, a skill, a workflow, a script, a test, or a generated
  runtime copy.
* Remove legitimate internal repository identity or history.
* Create or select a replacement organization-specific repository or board.

**The implementation revision WILL (carried by this package; the recorded
approval above authorizes it, the implementation `touches:` set is exact — it
names `scripts/cross-repo-lint.sh` — and recorded human approval covers the
reserved `scripts/README.md`, `scripts/cross-repo-lint.sh`, and
`.github/workflows/lint-docs.yml` paths):**

* Parameterize the framework source URL in the README, `INTEGRATION.md`, and
  consumer-integration skill using `FRAMEWORK_REPO_URL`; replace fixed temporary
  clone paths with `TMPDIR`/`mktemp` guidance.
* Remove the instance-owned project-board link/context from the README and use
  a generic `<your-org>-conventions` placeholder wherever that option is shown.
* Rewrite the cross-repository lint section in `scripts/README.md` to match the
  actual `CA_REPO_DIRS` and `CA_TARGET_REPO` behavior and remove the named fleet
  inventory; tell consumers to configure an explicit target rather than rely on
  this repository's local sibling defaults — and remove the instance fleet
  names from `scripts/cross-repo-lint.sh`'s `CA_SIBLING_NAMES` default and the
  instance actor aliases from its `AGENT_EMAILS`/`CRON_AGENT_EMAILS` defaults,
  leaving the discovery mechanism unchanged; an attribution run with both
  allowlists unset fails closed naming the variables and the
  `CA_SKIP_ATTRIBUTION=1` opt-out (FS-0047 SC-9). The instance's CI job exports
  the allowlists explicitly.
* Replace framework-instance actor names/emails in reusable identity guidance
  with consumer-selected placeholders; sync generated skill copies from their
  source files.
* Replace the framework-instance `userName` in
  `integrations/runtimes/claude-code/settings.fragment.json` with a visible
  placeholder; re-word the `.github/workflows/lint-docs.yml` comment that
  names the instance fleet.
* Add `test/FS-0047/instance-exemptions.tsv` and
  `test/FS-0047/exported-boundary.bats` with unmarked-leak, exact-exemption,
  malformed-exemption, generic-command, and excluded-history fixtures; report
  every finding by path and line.
* Update `test/FS-0017/attribution-diagnostic.bats`,
  `test/FS-0043/cron-attribution.bats`, and
  `test/FS-0017/commit-attribution.bats` so the attribution harnesses use the
  instance's current actor domain (`advance.enterprises`) and configure the
  actor allowlists explicitly — the script now ships empty defaults
  (FS-0047 SC-9), so the harnesses configure the same set the instance
  tooling uses; the historical `tais-den.dev` aliases stay in the commit
  allowlist and the CI exports for anchored-history audits.
* Move the instance's agent-email domain from `tais-den.dev` to
  `advance.enterprises` across the exported configuration and harnesses —
  the labeled non-normative appendices, the allowlist, the CI env exports,
  the attribution harnesses, and the framework's committed
  `.claude/settings.json`; the old-domain aliases remain only as historical
  records (accepted ADRs, CHANGELOG, `.mailmap`) and as audit identifiers.
* Run documentation, status, freshness, conformance, and Bats validation.

The implementation must keep the issue's boundary: generic adoption guidance
is corrected, while accurate internal identity and historical records remain
untouched.

Before implementation, re-read the current default branch and open draft PRs.
PR #208 (GitHub Pages website governance package) also touches `INTEGRATION.md`
and `scripts/README.md`; reconcile that revision before editing shared
guidance, or coordinate shared-file ownership. Base implementation on the
then-current `trunk`. Do not stack uncoordinated edits onto an open draft or
reuse an audit SHA; if a predecessor remains open or changes scope, revise
the plan and coordinate shared-file ownership first.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0047/exported-boundary.bats` — fixture-backed tests for SC-1
    through SC-9, including a hard-coded instance URL and a fixed checkout path
    that must fail without a valid exact exemption, and a source assertion
    against `scripts/cross-repo-lint.sh` verifying the sibling-discovery
    default is empty (SC-9).

* Documentation-package validation now:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation validation:

  * `bats test/FS-0047/exported-boundary.bats`
  * `npm test`
  * `npm run check:conformance`

## 4. Files to Be Modified

**Approval + implementation revision (this package):**

* `docs/specifications/FS-0047-exported-consumer-boundary-audit.md` (status
  flip, interface additions)
* `docs/change-plans/PLAN-0053-implement-fs-0047-exported-consumer-boundary-audit.md`
  (status flip, exact implementation `touches:`)
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`
* `scripts/cross-repo-lint.sh`
* `scripts/README.md`
* `.github/workflows/lint-docs.yml`
* `workflows/git-and-gh-conventions.md`
* `skills/git-commit-identity/SKILL.md`
* `integrations/runtimes/claude-code/skills/git-commit-identity/SKILL.md`
* `skills/git-branch-and-commit/SKILL.md`
* `integrations/runtimes/claude-code/skills/git-branch-and-commit/SKILL.md`
* `skills/framework-consumer-integration/SKILL.md`
* `integrations/runtimes/claude-code/skills/framework-consumer-integration/SKILL.md`
* `integrations/runtimes/claude-code/README.md`
* `integrations/runtimes/claude-code/settings.fragment.json`
* `INTEGRATION.md`
* `README.md`
* `test/FS-0047/instance-exemptions.tsv`
* `test/FS-0047/exported-boundary.bats`
* `test/FS-0017/attribution-diagnostic.bats` (harness configures the instance
  actor allowlists explicitly; FS-0047 SC-9)
* `test/FS-0043/cron-attribution.bats` (same harness configuration)
* `test/FS-0017/commit-attribution.bats` (current-domain alias assertions +
  historical allowlist)
* `.claude/settings.json` (instance actor alias moves to the current domain)
* Any additional audited exported Markdown file that contains a confirmed
  consumer-specific leak; keep all edits inside FS-0047 `interfaces:`.

## 5. Implementation Steps (High-Level)

1. Write the fixture-backed audit tests first and confirm they fail for
   unmarked instance URLs, fixed checkout paths, and fleet identifiers.
2. Replace hard-coded URLs and temporary paths in README, `INTEGRATION.md`, and
   the consumer skill with `FRAMEWORK_REPO_URL`, placeholders, and temporary-path
   guidance; remove the instance-owned README board reference.
3. Keep consumer-conventions examples visibly generic; do not invent or link a
   real or archived consumer repository.
4. Rewrite `scripts/README.md` from the executable's actual configuration
   behavior; preserve the difference between a directory list and a single
   target override, and do not present local defaults as a consumer contract.
5. Replace non-portable identity values in reusable guidance with consumer
   placeholders, then synchronize generated skill copies.
6. Add the exact exemption manifest and fixture-backed audit; allow no broad
   directory or pattern exemptions.
7. Run the boundary audit, focused suite, documentation lint, all status and
   conformance checks, and full Bats tests; inspect the exported-surface diff.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0047's consumer-provided values and exact exemption behavior are the
    acceptance contract.
  * An exact exemption documents a narrowly retained identifier; it cannot make
    an instance-specific command a portable instruction.
  * Excluded history is preserved rather than silently rewritten.

* ADR constraints:

  * ADR-0015: tests and gates follow their existing repository governance.
  * ADR-0016: consumer-specific conventions live outside reusable framework
    guidance.
  * ADR-0017: do not reference nested framework vendor paths.
  * ADR-0026: approval is a separate recorded act scoped to the exact plan
    `touches:` set; this revision's approval commit carries the exact
    implementation `touches:` set and the reserved-path record.
  * ADR-0027: `scripts/README.md`, `scripts/cross-repo-lint.sh`, and
    `.github/workflows/lint-docs.yml` are reserved paths and require recorded
    human approval before they are changed.
  * ADR-0030: update current-state docs in place while keeping decision history
    separate.
  * ADR-0033 / FS-0024: configuration names and target-repository behavior must
    match executable semantics.
  * ADR-0037: parameterized binding examples do not embed consumer settings.

* Architecture constraints:

  * Do not add a dependency on another consumer repository.
  * Do not expose credentials or invent a board configuration.
  * Do not rewrite ADRs, changelog history, or issue history to remove valid
    instance facts.

## 7. Risks and Edge Cases

* A quick-start placeholder must be visibly non-literal; otherwise a consumer
  may paste it as a working repository URL.
* The real upstream framework URL may change during the public-release work; do
  not resolve that separate decision here.
* Existing actor aliases may remain in audited guidance only with a visible
  non-normative label and one exact, reason-bearing exemption; do not copy those
  values into generic commands.
* A test that audits only the three reported files would miss generated copies;
  scan the complete exported Markdown set defined in FS-0047.
* `CA_TARGET_REPO` takes precedence over `CA_REPO_DIRS`; documentation must
  preserve that order.
* Removing the instance fleet names from the sibling-discovery default breaks
  the maintainer's zero-config local multi-repo sweep; instance tooling (the
  maintenance tick and any local dev checkout) must export `CA_SIBLING_NAMES`
  or `CA_REPO_DIRS` explicitly after the change.
* Emptying the actor-email defaults makes an unconfigured attribution run
  fail closed (`CA_SKIP_ATTRIBUTION=1` opts out explicitly); every in-repo
  caller of `npm run lint:cross-repo` — the CI job, the maintenance tick, and
  local sweeps — must export `AGENT_EMAILS`/`CRON_AGENT_EMAILS` so the
  instance gate stays enforced rather than skipped.

## 8. Validation

* Documentation package:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation revision:

  * `bats test/FS-0047/exported-boundary.bats`
  * `npm test`
  * `npm run check:conformance`

* Manual checks:

  * Read every matching instance identifier in the audited export surface and
    verify its marker or removal.
  * Verify generated skills exactly match their source after synchronization.
  * Confirm the consumer-facing examples remain generic and runnable after
    substituting a consumer's values.

## 9. Explicit Non-Changes

* No change to internal ADR/FS/PLAN/CHANGELOG history.
* No migration of instance policy into the framework core.
* No real organization-specific repository URL or replacement project board.
* No change to repository discovery semantics or the attribution rule
  (trailer format, cron boundary); the attribution check's unconfigured
  behavior is the SC-9 fail-closed contract recorded in §2.

## 10. Readiness Check

* [x] Spec is approved
* [x] Tests are clearly defined for the implementation revision
* [x] Scope is minimal and explicit
* [ ] No implementation code or test change is included

## Declaration

I affirm that:

* This plan reflects the full intended scope of the approval and
  implementation revisions.
* Implementation proceeds under this revision: FS-0047 and PLAN-0053 are
  human-approved, the implementation `touches:` set is exact, and the
  reserved-path approval for `scripts/README.md`, `scripts/cross-repo-lint.sh`,
  and `.github/workflows/lint-docs.yml` is recorded on the implementation
  commit.
* Any deviation will require revising this plan before implementation.
