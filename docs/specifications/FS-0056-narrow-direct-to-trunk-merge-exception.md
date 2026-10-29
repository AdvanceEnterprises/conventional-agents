---
type: feature-spec
id: FS-0056
status: draft
title: Narrow direct-to-trunk merge exception — eligibility gate and audit digest
owner: Head Architect
test_required: true
interfaces:
  - scripts/eligibility-gate.sh
  - scripts/direct-merge-digest.sh
  - scripts/README.md
  - .github/workflows/lint-docs.yml
  - package.json
  - test/FS-0056/eligibility-gate.bats
  - test/FS-0056/direct-merge-digest.bats
  - docs/decisions/ADR-0041-narrow-direct-to-trunk-merge-exception-for-reversible-maintenance.md
  - docs/specifications/FS-0056-narrow-direct-to-trunk-merge-exception.md
  - docs/change-plans/PLAN-0060-implement-fs-0056.md
  - CHANGELOG.md
related_adrs:
  - ADR-0012
  - ADR-0015
  - ADR-0018
  - ADR-0026
  - ADR-0029
  - ADR-0041
  - ADR-0047
  - ADR-0049
supersedes: []
requires:
  - ADR-0041
  - FS-0022
tags:
  - governance
  - ci
  - merge-gate
  - autonomy
created: 2026-10-27
updated: 2026-10-29
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- `interfaces:` bounds which change plans may self-approve (ADR-0027) — draw
  it narrowly; a loose `interfaces:` widens agent authority.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->
# Feature Spec: Narrow direct-to-trunk merge exception — eligibility gate and audit digest

## Status

- Draft

## Summary

Implement the mechanical controls that let agents merge narrow, reversible
maintenance changes directly to trunk under the exception ratified by
`ADR-0041`. The implementation has two parts: an `eligibility-gate` script that
reports whether a PR's full diff lies inside one of the Phase 1 eligible
categories defined in §Eligible Category Matching (Phase 1); and an audit digest
that records every direct merge so a human can review the batch.

The gate reports **category eligibility only**. It never treats a commit
message, a trailer, or a label as human approval — the human-approval branch of
`ADR-0041` Required Control 3 is a GitHub review object enforced by the trunk
ruleset, outside this script (see §Approval Semantics).

## Goals

- Provide a technical backstop on trunk that enforces the `ADR-0041` scope.
- Preserve the full per-commit attribution record.
- Produce a machine-readable, human-reviewable digest per maintenance sweep.
- Fail closed when eligibility cannot be determined.

## Non-Goals

- Granting agents general merge authority.
- Removing the human promotion/audit act.
- Batching PRs through a staging branch.
- Expanding eligible categories beyond what `ADR-0041` ratifies.

## Users / Stakeholders

- Human maintainer reviewing the cross-repo maintenance digest.
- Autonomous maintenance tick performing eligible merges.
- CI/ruleset enforcement on trunk.

## Interfaces

- Type: CLI | CI status check
- Details:
  - `scripts/eligibility-gate.sh` — exit 0 and print `eligible` iff the full PR
    diff is inside one Phase 1 eligible category and the base ref resolves;
    exit 1 with a diagnostic otherwise. It reads git and environment only: no
    network, no GitHub API, no PR metadata.
  - `scripts/direct-merge-digest.sh` — given a sweep id and the PR numbers the
    sweep merged under this exception, re-verifies each landed range against
    git and emits the digest entries defined below; exits non-zero if any
    claim does not match git.
  - `.github/workflows/lint-docs.yml` — extended with an `eligibility-gate` job
    that runs the gate and reports the required `eligibility-gate` status
    check on trunk.
  - `package.json` — adds `eligibility-gate` and `digest:direct-merges` script
    entry points.
  - `scripts/README.md` — a Category 1 gate entry for each new script, per
    `ADR-0015` (purpose, when it runs, what a failure means, responsible
    role).
  - `test/FS-0056/eligibility-gate.bats` and
    `test/FS-0056/direct-merge-digest.bats` — bats coverage for the Success
    Criteria cases.
  - Digest output format: JSON Lines, one object per merged PR, with fields
    `sweep_id`, `generated_at`, `repo`, `pr`, `commit_range`, `touched_paths`,
    `category_matched`, `work_item`, `issue_type`, `actor`, `model`,
    `session`, `checks`, `rollback_ref`.
  - Digest storage: a GitHub Actions artifact named
    `direct-merge-digest-<run_id>` with 90-day retention, and the same JSONL
    echoed into the maintenance sweep's tracking-issue comment for human
    review. The digest is **not** committed to the repository: a populated
    digest is instance data, and `ADR-0032` forbids instance data inside this
    template repository (`FS-0024` non-goals).

## Eligible Category Matching (Phase 1)

`ADR-0041` assigns the exact category-matching logic to this spec. Phase 1 is
path-based, with one line-shape condition for the README category, and is
compiled into `scripts/eligibility-gate.sh` as a built-in table. This
repository does not read a populated `config/gates.yml` for its own check —
`FS-0024` rules that out, and this spec does not create one. A vendored copy
running against a host repository may override the table from that host's own
`config/gates.yml`; the override is out of scope here.

| Category id | Path pattern | Additional condition |
| --- | --- | --- |
| `cat2-skills` | `skills/**` | None. The skill must not be CI-enforced, which the reserved-path rule enforces structurally: any `package.json` or `.github/workflows/**` in the same diff fails the gate. |
| `cat-readme-index` | `docs/specifications/README.md`, `docs/change-plans/README.md`, `docs/decisions/README.md` | Every added or removed line must be a markdown table row (`^\| ... \|$`), and every added row's id/status cells must equal the corresponding document's front matter. Any other changed line in these files fails the gate. |

Rules that apply to every category:

- A diff that mixes an eligible category with any other path fails closed; the
  gate reports the first ineligible path and exits 1.
- A diff matching more than one eligible category reports the category of the
  first ineligible-free match in the order above, and records that id in
  `category_matched`.
- `scripts/`, `.github/workflows/`, `package.json`,
  `docs/decisions/**` content changes, and `guidelines/ROLE_CONTRACT.md` are
  never eligible, matching `ADR-0041`'s explicit exclusions. `docs/decisions/README.md`
  index-row sync is the only `docs/decisions/` path the second category admits.
- Category assignment never consults PR title, labels, or `type:` front matter.
  Work-item Issue Type `feature` is excluded by the ruleset per `ADR-0041`,
  not by this script.

## Approval Semantics

- The gate does not read or honour `Approved-By:` commit trailers. A trailer is
  agent-writable text; `ADR-0026` (§Enforcement is by audit, not control)
  documents that nothing prevents an agent from writing one naming a human who
  said nothing.
- The human-approval branch of `ADR-0041` Required Control 3 is a review
  submitted by a human account, required by the trunk ruleset for every merge
  that does not satisfy the eligible-category branch. That ruleset change ships
  in a separate, human-reviewed PR (§Rollout / Migration); this spec defines
  the gate's half only.
- If a trailer-based corroboration check is ever reintroduced anywhere in this
  path, it MUST follow the corroboration rule `scripts/check-status.sh`
  already implements for PLAN approval: the `Approved-By:` email must match a
  named human, differ from the commit's own author, and cover an unchanged
  `touches:` set (`ADR-0026`; `scripts/check-status.sh:866-891`). No such check
  is part of this spec's gate.

## Success Criteria

- Given a PR whose diff is entirely within one Phase 1 eligible category, when
  `scripts/eligibility-gate.sh` runs with a resolvable base ref, then it exits 0,
  prints `eligible`, and prints the matched category id.
- Given a PR whose diff touches a reserved path, a non-eligible file, or mixes
  an eligible category with any other path, when the gate runs, then it exits 1
  and names the first ineligible path.
- Given a PR whose diff is outside every eligible category but whose most recent
  commit carries an `Approved-By:` trailer naming a human, when the gate runs,
  then it exits 1 — the trailer does not change the verdict, because the
  human-approval branch is a ruleset-enforced review, not a commit message.
- Given a sweep that merged PRs under this exception, when
  `scripts/direct-merge-digest.sh <sweep-id> <pr>...` runs, then it emits one
  JSONL entry per PR containing every field in §Interfaces including
  `category_matched` and `rollback_ref`, every `commit_range` matches git, and
  the script exits non-zero if any entry is missing an `Agent-Attribution:`
  trailer or a matching category.
- Given a gate run where the base ref does not resolve or the eligibility
  predicate cannot be parsed, when the gate runs, then it exits 1 and the error
  message says "fail-closed".

## Edge Cases

- An eligible PR that later receives a new commit outside the category must be
  re-evaluated; the gate checks the full PR diff, not the original approval.
- A PR with mixed eligible and ineligible commits fails closed even if most of
  the diff is eligible.
- The gate does not itself perform the merge; it only reports eligibility. The
  merge act remains subject to `ADR-0012` and the ruleset.
- A gate run in a clone without the base ref fetched exits 1 with the
  fail-closed diagnostic rather than diffing against a guessed base.

## Out of Scope

- Implementing a staging branch or promotion UI.
- Multi-repo orchestration beyond digest aggregation.
- Auto-merge wiring; the ruleset is the only actor that may block merge.
- Phase 2 content-aware eligibility (`updated:` date-only refreshes) unless
  `ADR-0041` Phase 2 has been separately accepted.
- Host-repository override of the built-in category table from
  `config/gates.yml` (follow-up for vendored copies).

## Dependencies

- ADR-0012: Non-overridable gates — the merge prohibition remains intact.
- ADR-0015: Tool taxonomy — the Category 1 introduction requirements for both
  new scripts (`package.json`, `scripts/README.md`, approved FS, role
  assignment).
- ADR-0026: Human approval recording — why a commit trailer cannot be the
  approval authority.
- ADR-0041: The exception this spec implements.
- ADR-0047: Authorized intent identity and the human grant — ties the digest
  actor to the grant.
- ADR-0049: Grant-based go signal for autonomous runs — the batch gating
  model this digest feeds.
- FS-0022: Gate coverage — the check script conventions this spec extends.

## Rollout / Migration

- Add `scripts/eligibility-gate.sh`, `scripts/direct-merge-digest.sh`, their
  bats files, and the `scripts/README.md` entries first.
- Add the required check to the trunk ruleset in a separate, human-reviewed PR
  because it touches `.github/workflows/` and the ruleset itself; that PR also
  carries the human-review requirement of `ADR-0041` Required Control 3.
- Begin the pilot only after `ADR-0041` is accepted and the ruleset change is
  live.

## Sunset and Re-ratification

`ADR-0041` defers the cadence to this spec. The checkpoint is counted in
completed maintenance-sweep cycles, not calendar time:

- First re-ratification checkpoint after **60** completed maintenance sweeps
  following the ruleset going live.
- Every **120** completed sweeps thereafter.
- Immediate pause-and-review after the first incident, failed gate on a merged
  PR, or human rollback, without waiting for the cycle boundary.

At each checkpoint the reviewing human re-reads the digests, compares actual
click-volume reduction, failure rate, and rollback rate against `ADR-0041`'s
Validation signals, and records either continuation (with a new cycle count) or
withdrawal of the exception.

## Halt and Rollback

`ADR-0041` Required Control 6 reserves a human's standing authority to halt a
category or roll back a merged change, exercised via the digest. The exercise
path is:

- **Halt.** The host repository sets the Actions variable
  `ELIGIBILITY_GATE_HALT` to `all`, or to a comma-separated list of category ids
  (`cat2-skills,cat-readme-index`). The workflow passes the variable to the gate
  as an environment value; the script reads only its environment, so it stays
  network-free. A halted category exits 1 with `halted by operator: <id>`, which
  fails closed and blocks merges until a human clears the variable. The variable
  is server-side configuration: an agent cannot edit it from a pull request.
- **Rollback.** Each digest entry carries `rollback_ref` as `git revert <sha>`
  for the merge's first landed commit. A human maintainer directs the revert —
  directly, or by instructing a maintenance run — and records the digest entry
  and the reason in the sweep's tracking issue. Reverting a rollback requires a
  normal reviewed PR; the exception never covers the revert of its own revert.
- Neither action requires amending `ADR-0041` first, per Required Control 6.

## Observability

- Logs: gate emits one eligibility verdict per run, including the matched
  category id or the first ineligible path.
- Metrics: the digest carries the count of direct merges per sweep, grouped by
  `category_matched`.
- Traces: every eligible merge leaves an `Agent-Attribution:` trailer intact
  (rebase-merge per `ADR-0025`).

## Security / Privacy

- Data handled: PR diffs, check results, attribution trailers. All already in
  the repository.
- Threats considered: an agent could try to widen eligibility by editing the gate
  script. Mitigation: `scripts/` is in `ADR-0027`'s reserved set, so any change
  to the gate requires human approval.
- Threats considered: an agent writes an `Approved-By:` trailer to claim human
  approval. Mitigation: the gate ignores trailers entirely; the human branch is
  a ruleset-required review object the agent cannot create.
- Mitigations: gate script is read-only at runtime; ruleset requires the gate
  status check; halt is controlled by a server-side variable.

## Open Questions

- Phase 2 (content-aware predicates for `updated:` date refreshes and
  pre-landed `CHANGELOG.md` entries) is defined by `ADR-0041` but deliberately
  left unimplemented here; the follow-up spec is not yet written.
- Whether the host-repository `config/gates.yml` category override is worth
  building for vendored copies, or whether the built-in table should be the only
  source, is deferred to the first consumer that needs a different category set.
