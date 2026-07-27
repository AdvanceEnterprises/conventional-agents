---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs: [FS-0017]
related_adrs: [ADR-0018]
created: 2026-07-27
updated: 2026-07-27
---

# Change Plan: Implement FS-0017 Single-identity Commit Attribution

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0017
- Related ADR ID(s): ADR-0018
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Add `docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md`
  documenting the convention and the rationale.
- Update `workflows/git-and-gh-conventions.md`:
  - Add a "Single-identity workflow with agent co-attribution (ADR-0018)"
    section with actor email table, per-commit override form,
    per-session configuration form, and the three attribution
    layers (`user.email`, `Co-authored-by:`, `Agent-Attribution:`).
  - Update the "When to use each layer" guidance to mention
    `Agent-Attribution:`.
  - Add an "Agent Attribution" subsection to the PR body template.
- Update `skills/git-gh-workflow/SKILL.md`:
  - Add a "Single-Identity Mode" subsection under the GitHub Identity
    Gate.
  - Add a "Single-Identity Workflow" section with per-commit override,
    per-session configuration, hybrid-session `Co-authored-by:`
    trailer, and known actor emails.
- Add `roles/README.md` explaining that `roles/` ships empty by design
  and documenting the customization workflow for host repos.
- Remove `roles/ROLE_CONTRACT.md` (byte-identical duplicate of
  `guidelines/ROLE_CONTRACT.md`) per the reviewer finding.
- Add `docs/specifications/FS-0017-single-identity-commit-attribution.md`.
- Add `docs/change-plans/PLAN-0017-implement-fs-0017-single-identity-commit-attribution.md`.
- Add `test/FS-0017/commit-attribution.bats` enforcing the convention
  on recent commits with a "last N" cutoff strategy that does not
  require a future merge SHA.
- Add `docs/decisions/ADR-0011` cross-reference to ADR-0018 (Status-section
  addition; permitted per ADR-0000's append-only rule).
- Add `docs/decisions/README.md` index row for ADR-0018 (already
  present from the prior commit on this branch).
- Add `docs/specifications/README.md` index row for FS-0017.
- Add `docs/change-plans/README.md` index row for PLAN-0017.

**This change will NOT:**

- Add separate GitHub accounts for agents.
- Modify or supersede ADR-0011.
- Backfill attribution on legacy commits.
- Pre-populate `roles/ROLE_CONTRACT.md`.

## 3. Tests Driving This Change

Validation is via:

- `npm run check:status` passing (FS/PLAN status consistency, README
  index sync).
- `npm run lint:docs` passing (markdownlint across ADRs, specs, plans,
  workflows).
- `test/FS-0017/commit-attribution.bats` passing against recent
  commits on the current branch (the "last N" cutoff strategy means
  the test does not require a future merge SHA to function).
- Manual review of the layered commit-message pattern in the workflow
  doc and skill.

## 4. Files to Be Modified

- `.gitmodules` (no change)
- `docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md`
  (new — this commit's main ADR)
- `docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md`
  (modify — append cross-reference in Links section)
- `docs/decisions/README.md` (modify — add ADR-0018 row)
- `docs/specifications/FS-0017-single-identity-commit-attribution.md`
  (new)
- `docs/specifications/README.md` (modify — add FS-0017 row)
- `docs/change-plans/PLAN-0017-implement-fs-0017-single-identity-commit-attribution.md`
  (new — this file)
- `docs/change-plans/README.md` (modify — add PLAN-0017 row)
- `workflows/git-and-gh-conventions.md` (modify — add ADR-0018
  section, update PR body template, update "When to use each layer")
- `skills/git-gh-workflow/SKILL.md` (modify — add Single-Identity Mode
  and Single-Identity Workflow sections)
- `roles/ROLE_CONTRACT.md` (delete — duplicate of
  `guidelines/ROLE_CONTRACT.md`)
- `roles/README.md` (new — explains why `roles/` ships empty)
- `test/FS-0017/commit-attribution.bats` (new — enforces the
  convention on recent commits)

## 5. Implementation Steps (High-Level)

1. **Author ADR-0018** — document the convention, the rationale, and
   the relationship to ADR-0011.
2. **Author FS-0017** — define the success criteria for the
   convention, including the three attribution layers and the
   `roles/` empty-by-design decision.
3. **Update `workflows/git-and-gh-conventions.md`** — add the
   Single-identity section, update the PR body template, and update
   the When-to-use table.
4. **Update `skills/git-gh-workflow/SKILL.md`** — teach agents the
   convention.
5. **Remove `roles/ROLE_CONTRACT.md`** — it's a byte-for-byte duplicate
   of `guidelines/ROLE_CONTRACT.md`.
6. **Add `roles/README.md`** — explain the customization workflow.
7. **Add `test/FS-0017/commit-attribution.bats`** — enforce the
   convention on recent commits with the "last N" cutoff strategy.
8. **Add cross-reference in ADR-0011's Links section** — note that
   ADR-0018 is the operational model for single-identity projects.
9. **Update indexes** — `docs/decisions/README.md`,
   `docs/specifications/README.md`, `docs/change-plans/README.md`.
10. **Run `npm run check:status` and `npm run lint:docs`** — verify
    no regressions.
11. **Commit with attribution** — apply ADR-0018's own convention to
    the commits on this branch: per-commit `user.email` override
    (`hermes-agent@tais-den.dev`) and `Agent-Attribution:` trailer.

## 6. Constraints and Guardrails

- FS-0017 Non-Goals: no separate GitHub accounts; no backfilling
  legacy commits; no pre-populated `roles/ROLE_CONTRACT.md`.
- ADR-0011 is `accepted` and append-only per ADR-0000's immutability
  rule. The only permitted edit is a Status-section or Links-section
  addition. No body edits.
- The bats test must not require a future merge SHA. Use a "last N
  commits" cutoff or similar forward-only enforcement.
- `npm run check:status` and `npm run lint:docs` must pass before
  the PR is marked ready.

## 7. Risks and Edge Cases

- **Agent actor names are freeform** — `Actor-Attribution:` permits
  any actor name. The bats test asserts that `Co-authored-by:` emails
  match a small allowlist but does not constrain actor names. This is
  intentional: agent ecosystems evolve, and a hardcoded allowlist of
  agent names would block new ones.
- **`Agent-Attribution:` is not rendered by GitHub** — the trailer is
  parseable by `git log --format=%(trailers)` and verified by the
  bats test, but GitHub's commit UI does not display it. The
  convention relies on tooling to surface the metadata, not the
  GitHub web UI.
- **PR body "Agent Attribution" section is informal** — the section
  is not enforced by the bats test. It exists as a documentation
  convention for reviewers. Enforcing it would require a PR-body
  test, which is out of scope for FS-0017.
- **`roles/` empty by default** — host repos that vendored the
  framework before this PR may have copy-pasted the
  pre-populated `ROLE_CONTRACT.md` into their own tree. Removing the
  duplicate from the framework does not affect their copy. The
  `roles/README.md` directs them to keep their customized version
  and re-sync from `guidelines/` periodically.

## 8. Validation

- `npm run check:status` passes.
- `npm run lint:docs` passes (ADRs, specs, plans, workflows).
- `test/FS-0017/commit-attribution.bats` passes against recent
  commits on the current branch.
- The `roles/` directory contains only `README.md`.
- ADR-0018 exists with `status: proposed` (the human-only approval
  transition remains; agent sets it to `approved` on merge per the
  document lifecycle).

## 9. Explicit Non-Changes

- ADR-0011 body is unchanged. Only the Links section gains a
  cross-reference.
- `guidelines/ROLE_CONTRACT.md` is unchanged.
- No new GitHub accounts are created.
- No commit-author or committer overrides apply to commits outside
  this PR (the convention takes effect for new commits going forward).

## 10. Readiness Check

- [x] Spec is approved (FS-0017 status: implemented; lands with this PR)
- [x] Tests exist or are clearly defined (commit-attribution.bats)
- [x] Scope is minimal and explicit (six files modified, four new)
- [x] No architectural changes implied beyond the new ADR-0018

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
