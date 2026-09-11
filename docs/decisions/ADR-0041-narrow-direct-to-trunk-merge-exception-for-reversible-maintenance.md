---
type: adr
id: ADR-0041
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0022
superseded_by: null
created: 2026-09-11
updated: 2026-09-11
---

# ADR-0041: Narrow direct-to-trunk merge exception for reversible maintenance categories, audited by a maintenance digest

## Status

- Proposed

## Context and Problem Statement

Issue #151 names the real constraint precisely: once agent-driven maintenance
runs across 5-10+ consumer repositories, per-PR human approval-and-merge
ceremony scales linearly with repo count. Nothing about today's human
oversight act — a click per PR, per repo — scales sub-linearly. Solving that
is the actual goal; a general loosening of the merge prohibition is not.

`docs/decisions/ADR-0012-non-overridable-gates.md` makes "Agents MUST NOT
merge pull requests" a non-overridable super-gate, framework-wide, with an
explicit escape hatch: "A consuming project that genuinely needs an exception
must document it in a project-level ADR with explicit human sign-off." This
ADR exercises that mechanism for `conventional-agents`' own operation — this
repository acting as an instance of itself, distinct from the template form
described in ADR-0032. It does not amend ADR-0012 and does not weaken the
framework-wide default for any other consumer.

Issue #151 explored two shapes:

1. **Staging-branch buffer** — agents merge to `staging`; a human periodically
   promotes `staging → trunk`.
2. **Narrow direct-to-trunk merge authority** for a defined, reversible
   category, audited by a cross-repo digest instead of a second branch.

Discussion on the issue converged on (2): staging multiplies ceremony
per-repo rather than reducing it, and degrades the per-commit attribution
granularity that ADR-0025 was written to preserve.

Two constraints surfaced during design that shape the chosen option below:

- **ADR-0018 collapsed the three-identity GitHub model (ADR-0011) into a
  single shared identity**, with attribution carried by
  `Agent-Attribution:` commit trailers rather than by which account acted.
  There is no separate "agent" GitHub account to scope a technical bypass
  to — any technical gate has to operate on the diff and the PR's review
  state, not on actor identity.
- **`trunk` currently carries no GitHub branch protection or required-review
  ruleset.** Verified live: classic branch protection returns 404; the one
  active ruleset ("Base Ruleset") only blocks branch deletion and
  non-fast-forward pushes. The merge prohibition today is enforced entirely
  by agent compliance with instructions — there is no technical backstop at
  all, for anyone.

## Decision Drivers

- Human approval-and-merge ceremony must not scale linearly with consumer-repo
  count, or the framework's own governance becomes the bottleneck it exists
  to prevent.
- Per-commit attribution (ADR-0025) and audit granularity must not degrade as
  a side effect of solving the ceremony problem.
- Any merge authority granted to agents must fail closed and be revocable
  without a deploy or a code change.
- The exception must be narrow, named, and self-limiting per ADR-0012's
  qualification criteria — not a general loosening.
- Given that no technical control exists on `trunk` today, the result should
  not be weaker than the status quo; ideally it is the first real technical
  backstop `trunk` has had.
- The single-identity model (ADR-0018) means any technical gate must be
  diff/category-based, not actor-based.

## Considered Options

### Option A — Staging-branch buffer (issue #151 original proposal)

Agents merge their own reviewed PRs into a `staging` branch. A human
periodically reviews the aggregated diff and merges `staging → trunk`.

### Option B — Direct-to-trunk exception, documentation-only gate

Agents may merge PRs in defined categories once required checks pass.
Enforcement is purely instructional (ROLE_CONTRACT/ADR text) — the same
mechanism as the rest of ADR-0012, with no GitHub-side technical control.

### Option C — Direct-to-trunk exception, phased category set, enforced by a required-status-check ruleset, audited by a maintenance digest

Same eligible-category merge authority as Option B, but `trunk` gains a
GitHub ruleset requiring a new required status check, `eligibility-gate`,
before any merge — agent-authored or human-authored alike. The check passes
iff `(diff is fully within an allowlisted category AND full CI is green)` OR
`(the PR carries a human review approval AND full CI is green)`. This makes
the category boundary a technical property of the branch, not a promise the
agent keeps. A minimal maintenance digest — built now, not blocked on the
unresolved flow-report work in issue #146 — gives the human a batched,
cross-repo audit surface.

## Decision Outcome

**Chosen option: Option C.**

### Rationale

- **Option A (staging) is rejected.** It multiplies ceremony per repo instead
  of reducing it — N repos become N staging branches, N promotion reviews.
  It shifts audit granularity from per-commit to per-bundle exactly where
  ADR-0025 fought to keep it per-commit. It hides drift in a buffer invisible
  to status gates until promotion. And it reproduces the shared-mutable-state
  conflict hazard that worktree discipline was adopted to avoid. It remains a
  documented, deferred fallback (see Consequences), not the chosen design.
- **Option B (documentation-only) is rejected in favor of C.** Once it was
  clear `trunk` has no technical backstop today, shipping a category
  exception as pure instruction-following would be strictly weaker than
  necessary. Option C costs one CI job and gives the exception a real
  boundary instead of trusting an agent to read the category list correctly
  under load.
- **Option C does not require reintroducing a separate agent GitHub
  identity.** The `eligibility-gate` check evaluates the diff and the PR's
  review state, not which account clicked merge, so it composes with the
  single-identity model (ADR-0018) as-is.

### Scope — eligible categories (phased)

**Phase 1 (path-based; ships with the initial implementation):**

- Category 2 productivity-skill work under ADR-0015 (`skills/**`): skill
  helper scripts and `SKILL.md` content, provided the skill remains
  non-CI-enforced.
- README index-table updates in `docs/specifications/`,
  `docs/change-plans/`, `docs/decisions/` that are purely mechanical sync
  output of `npm run check:status` — no prose or decision-content changes.

**Phase 2 (content-aware; requires the eligibility check to parse diff
content, not just changed paths — deferred until that tooling exists):**

- `updated:` front-matter date refreshes on FS/PLAN/ADR documents, where no
  other line in the document changes.
- `CHANGELOG.md`-only entries for changes already on `trunk`.

**Explicitly excluded, in every phase:**

- `scripts/` and `.github/workflows/`, including the `eligibility-gate`
  check itself — the gate that decides what is auto-mergeable must not be
  auto-mergeable.
- `package.json`, dependency manifests, and lockfiles. Dependency bumps carry
  a different risk profile (supply-chain surface) that a green test suite
  does not fully cover; they stay human-reviewed regardless of category.
- `guidelines/ROLE_CONTRACT.md`, `docs/decisions/` content changes (status
  transitions, ADR body content, and decision-content edits remain
  human-approved — mechanical README index syncs of new rows remain Phase-1
  eligible), and any change to an enforcement path or safety/control
  document.
- Any PR whose Issue Type is `feature`, or that touches a reserved path under
  ADR-0027.
- Work-item Type remains human-classified. An agent cannot lower a Type to
  escape this boundary merely because the touched files sit under `skills/`.

### Required controls

1. Full required CI, the document-hygiene checks in ROLE_CONTRACT §
   Non-Overridable Safety Gates, and attribution checks
   (`Agent-Attribution:` trailers present) must all pass before
   `eligibility-gate` can pass.
2. `trunk` gains a GitHub ruleset requiring: the existing
   deletion/non-fast-forward protections (already active), plus the new
   required status check `eligibility-gate`, gating every merge.
3. `eligibility-gate` passes iff `(diff fully within an eligible Phase-1/2
   category AND CI green)` OR `(the PR carries an explicit human review
   approval AND CI green)`. The human-approval branch means a review
   submitted by a human account — never CI green alone — and the ruleset in
   control 2 must require it for every merge that does not satisfy the
   eligible-category branch. Anything outside the category list still
   requires the human-approval branch of that OR — unchanged from today.
4. Merge strategy is rebase-merge per ADR-0025 (merge-commit fallback only if
   rebase is blocked). Squash is not permitted for eligible-category
   auto-merges, so per-commit `Agent-Attribution:` trailers land on `trunk`
   intact.
5. Each maintenance sweep produces a minimal digest: repository, PR, commit
   range, touched paths, category matched, actor/model/session attribution,
   check results, and a rollback reference (`git revert <sha>`). This ships
   as a small script reading `git log`/trailers — it does not wait on issue
   #146's flow-report read-model, and is explicitly superseded by that work
   once it lands.
6. The human retains standing authority, exercised via the digest, to halt
   the category (fall back to Option B or full human-per-PR review) or roll
   back any merged change, at any time, without needing to amend this ADR
   first.
7. Any failed check, category-ambiguous diff, missing attribution, or
   digest-generation failure fails closed: the PR falls to the
   human-approval branch of the `eligibility-gate` OR — merge is blocked
   pending human review, never silently permitted.
8. Sunset/re-ratification checkpoint after a fixed number of
   maintenance-sweep cycles (set by the companion FS/PLAN), and an immediate
   pause-and-review after the first incident or human rollback.

### Consequences

**Good:**

- Removes the linear-scaling human click for the categories that actually
  generate volume across consumer repos, without removing it for anything
  else.
- First real technical enforcement of any merge boundary on `trunk` —
  strictly safer than the current unprotected state, independent of whether
  the category list ever grows.
- Per-commit attribution (ADR-0025) and audit granularity are fully
  preserved; the digest is an additional audit surface, not a replacement
  for the commit-level trailer record.
- Compatible with the single-identity model (ADR-0018) without
  reintroducing a separate agent account.
- Fails closed: any gap in the eligibility check, digest, or CI defaults
  back to today's human-approval requirement, not to an open door.

**Bad:**

- Adds one more required CI job (`eligibility-gate`) to build and keep
  honest — it must be verified by mutation (deliberately construct an
  out-of-category diff and confirm the check blocks it), not just observed
  passing on in-category fixtures.
- The minimal digest is a stopgap. It needs real migration work once issue
  #146 lands, and until then the audit surface is less rich than the
  flow-report read-model this design assumes will eventually exist.
- Phase 2 categories are deferred, so the initial cut captures less volume
  than the full target scope — ceremony reduction is partial until the
  eligibility check supports diff-content predicates.

**Neutral:**

- Accepting this ADR creates a binding project-level exception per
  ADR-0012's override mechanism; revoking it requires a later ADR or explicit
  human sign-off. `reversible: yes` in the frontmatter describes that the
  gate can be disabled without rewriting history, not that acceptance is
  costless to unwind.
- Staging (Option A) remains documented as a deferred fallback, to be
  revisited only if Option C cannot sustain its fail-closed controls in
  practice, or the digest proves inadequate.
- This ADR does not modify `docs/decisions/ADR-0012-non-overridable-gates.md`
  or `guidelines/ROLE_CONTRACT.md`'s super-gate text. The framework-wide
  default — agents MUST NOT merge — is unchanged for every consumer that has
  not adopted an equivalent project-level ADR of its own.

## Implementation Notes

- This ADR is a decision record only. Implementation — the
  `eligibility-gate` workflow, the ruleset configuration, the digest script,
  and any `workflows/git-and-gh-conventions.md` updates — requires a
  companion FS/PLAN per the ADR-0012 override mechanism, and is out of scope
  for this PR.
- **Current-state obligation (ADR-0030 rule 3):** acceptance of this ADR
  changes the operative rule stated in
  `guidelines/ROLE_CONTRACT.md` § Non-Overridable Safety Gates, so that
  section's super-gate text must be updated to record the project-level
  exception. Per ADR-0030 the edit is held until this ADR is `accepted` and
  ships with the companion FS/PLAN, not with this decision record.
- The companion FS must define: the exact category-matching logic (path
  globs for Phase 1; diff-content predicates for Phase 2), the digest schema
  and its storage location, the sunset cadence, and the halt/rollback
  procedure referenced in Required Controls item 6.
- `docs/decisions/README.md` is updated in this PR to list ADR-0041 as
  `proposed`.

## Validation

- **Signal:** `eligibility-gate` blocks merge for a PR with an out-of-category
  diff and no human approval — confirmed post-implementation by deliberately
  constructing such a PR, not merely by observing the check pass on
  in-category fixtures.
- **Signal:** every commit landing on `trunk` via this exception carries its
  `Agent-Attribution:` trailer intact (rebase-merge, not squash).
- **Signal:** the digest for each maintenance sweep is produced and is
  legible enough that a human can identify, without reading individual PRs,
  which repository, category, and commit range warrant closer inspection.
- **Review checkpoint:** at the sunset/re-ratification cycle set by the
  companion FS/PLAN, review actual click-volume reduction, failure rate, and
  rollback rate against the 5-10+ repo bottleneck this ADR was written to
  address.

## Confirmation

Confirmed implemented once: the companion FS/PLAN is accepted and its
interfaces are merged, the `eligibility-gate` ruleset is active on `trunk`,
the digest script has run on at least one real maintenance sweep, and this
ADR's `status` is updated to `accepted` with explicit human sign-off recorded
(per ADR-0012's override mechanism).

## Links

- ADR-0012: Non-overridable gates (super-gates) — the override mechanism this
  ADR exercises.
- ADR-0015: Tool taxonomy — defines Category 2 (productivity skills), the
  Phase 1 eligible scope.
- ADR-0018: Single-identity workflow — why the technical gate is diff-based,
  not actor-based.
- ADR-0025: Merge strategy preserves per-commit attribution — the required
  merge strategy for eligible-category merges.
- ADR-0027: PLAN self-approval within declared interfaces — the
  reserved-path definition this ADR excludes.
- `guidelines/ROLE_CONTRACT.md` § Non-Overridable Safety Gates — the
  super-gate text this ADR does not modify.
- Issue #151 — origin of this proposal and its discussion.
- Issue #146 — the flow-report read-model; the digest in this ADR is an
  interim stand-in, superseded once #146 lands.
