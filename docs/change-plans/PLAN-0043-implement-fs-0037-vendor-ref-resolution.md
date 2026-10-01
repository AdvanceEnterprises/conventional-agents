---
type: change-plan
role: implementer
language: bash
status: approved
related_specs: [FS-0037]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0026, ADR-0027, ADR-0030, ADR-0033]
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - test/FS-0037/vendor-ref-resolution.bats
  - docs/specifications/FS-0037-vendor-ref-resolution.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-22
updated: 2026-10-01
---

# PLAN-0043: Implement FS-0037 — Vendor-prefixed reference resolution

> **Revision note:** this is the **implementation revision** of PLAN-0043. The
> original revision (PR #166) shipped the governance package — `FS-0037`, this
> plan, the index rows, the CHANGELOG entry — with a docs-only `touches:` set,
> and stated that the implementation revision "arrives as a separate revision
> of this plan that declares the full `scripts/` + `test/` surface in
> `touches:`". This is that revision. Because the declared surface includes
> `ADR-0027` reserved paths, the routing in §3 is human-only, and **no
> implementation commit is written until the record described in §3 exists**.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0037 (approved 2026-09-24, recorded via PR #175)
* Related ADR ID(s): ADR-0026 and ADR-0027 (recorded approval, reserved
  paths), ADR-0030 (current-state documents), ADR-0033 (target resolution
  and configuration)
* Issue / PR Reference: #165

## 2. Scope of Change

**This revision's implementation commits WILL** (they are written only after
the record described in §3 exists):

* Extend rule 8 in `scripts/check-status.sh`:
  * resolve backticked `vendor/conventional-agents/<path>` references against
    the framework tree (strip the prefix, then apply the existing resolution
    order) instead of blanket-skipping them — making the strip-prefix
    fallback the script already carries reachable for the prefix form;
  * extend the extractor, for the three exported-surface documents
    (`INTEGRATION.md`, `README.md`, `AGENTS.md`) only, to non-backticked
    occurrences of the same prefix, with the conservative token shape (a
    file extension; no angle brackets, ellipsis, or glob);
  * preserve the genuine uninitialised-submodule exclusion for every other
    `vendor/*` path (`vendor/madr/`), the `REF_EXEMPT` / `config/gates.yml`
    `ref_exempt` escape hatches, the existing three-way resolution order
    (repo root, bare-after-strip, naming document's directory), and Bash 3.2
    compatibility (no new npm script or CI job).
* Document the extended rule in `scripts/README.md` (rule 8 entry).
* Reconcile `FS-0037`'s **SC-2 parenthetical** with its own
  `§Problem/Evidence` measurement: SC-2 quotes `92 / 39 / 24`, but 92 is the
  `docs/`-extended sensitivity figure for conventional-agents while 39 / 24
  are the rule-8-set figures for feral-fleet / pack-protocol — the criterion
  mixes two measurement sets. The revision aligns the parenthetical to the
  rule-8 set (`64 / 39 / 24`, as measured 2026-09-22) so the bats case and
  the spec assert against one number; the spec file is declared in
  `touches:` for this purpose, and the edit is part of the implementation
  commits, under the §3 record.
* Add `test/FS-0037/vendor-ref-resolution.bats` covering SC-1..SC-7 on the
  disposable-worktree fixture pattern of `test/FS-0022/gate-coverage.bats`.
* On the status flips that follow: the revision's recorded approval flips
  this plan to `approved` (index row synced); once the implementation is in
  and verified, `FS-0037` and this plan flip to `implemented`, both index
  rows sync, and the CHANGELOG marker updates per rule 7 house practice.
  This is a **single-PR implementation**, so the plan transitions
  `approved → implemented` **directly** —
  `workflows/document-lifecycle.md` §"Single-PR implementations" permits
  this, and **no `in-progress` flip commit is written**: any commit touching
  this plan file after the record would leave the most recent touching
  commit without the approval trailer and void the record under rule 6,
  because rule 6 inspects only the most recent commit touching this file
  while the plan is at `approved`/`in-progress`.
  Issue #165 resolves with an evidence comment naming the implementing PR
  and its merge commit once the gate is on trunk — its originating suggest
  is fully delivered only then.

**This revision will NOT:**

* Re-check decision records (ADR, FS, PLAN). §1c's existing scope decision
  stands; the historical vendor references inside `ADR-0006` / `ADR-0007` /
  `ADR-0039` are out of scope and must not be "fixed" to satisfy a linter.
* Extend rule 8's document scope to `docs/ARC42.md` or any other file outside
  the current in-scope set.
* Resolve unprefixed references that name a consumer-side path (`REF_EXEMPT`
  already handles those), or change §1c's backtick-token rule for any
  document other than the three exported-surface files.
* Auto-repair references. The check reports; it never rewrites.

## 3. Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes
`scripts/check-status.sh` and `scripts/README.md` — both in `ADR-0027`'s
reserved set, because the check that would evaluate the change lives in
`scripts/`. `check-status.sh` rule 6 therefore requires a human approval
record for this revision's own `touches:` set.

Per `ADR-0026`, an approval covers only the content and `touches:` set that
existed when it was given — which is why the docs-only package revision could
not carry an approval forward to this one, and why this revision must be
approved before the implementation commits are written. The maintainer's
next act is to approve this revision; the record is an `Approved-By:`
trailer on the commit that flips `status:` to `approved`, whose email
differs from that commit's author **and appears in this plan's front-matter
`approved_by:` field** — rule 6 mechanically requires all three (field,
trailer, author-mismatch), so the record commit and the front matter are
edited together. This is the same recorded-approval shape `FS-0037`'s own
approval used in PR #175.

The implementation commits then follow under that record — `FS-0037`'s
§"Plan Status" names the shape: "the implementing PR opens separately and
records that approval there." Those commits must not touch this plan file
once the record exists, or they void it under `ADR-0026` (issue #155 tracks
that general trap). The plan and `FS-0037` move to `implemented` after the
implementation lands.

## 4. Tests Driving This Change

* Test file (implementation commits):
  `test/FS-0037/vendor-ref-resolution.bats` — SC-1..SC-7:

  * SC-1: phantom backticked prefixed reference → fail; the error names both
    the document and the reference.
  * SC-2: resolving prefixed reference → pass on the clean tree (the three
    repositories' currently-resolving prefixed references produce no
    failures; the count bar is owned by FS-0037 §Problem/Evidence — the
    rule-8-set figures, `64 / 39 / 24` as measured 2026-09-22 — and the
    same change reconciles SC-2's parenthetical to that figure, so the
    bats case and the spec assert against one number).
  * SC-3: any other `vendor/*` phantom (e.g. `vendor/madr/template.md`) →
    skip, not fail — asserted for self-check and non-self-check modes.
  * SC-4: placeholder forms and prose anti-examples → not flagged.
  * SC-5: non-backticked phantom in `INTEGRATION.md` / `README.md` /
    `AGENTS.md` → fail; the case iterates the full six-item #163
    enumeration — the five concrete path tokens each fail the gate, and the
    sixth (`<REPO_URL>`) asserts non-extraction per SC-4's placeholder
    exemption, so no item in the list is un-testable.
  * SC-6: host repository whose `vendor/conventional-agents` submodule is
    uninitialised (non-self-check mode) → prefixed references in that host's
    in-scope documents do not fail.
  * SC-7: `REF_EXEMPT` (self-check) / `ref_exempt` in `config/gates.yml`
    (host) honoured exactly as the existing check honours them.

  Fixture pattern: the disposable-worktree shape of
  `test/FS-0022/gate-coverage.bats` (mutate → run gate → assert → restore);
  the non-self-check cases use the scratch-host shape of
  `test/FS-0024/portable-gates.bats`, asserting self-check and
  non-self-check modes as **distinct** cases (the FS-0024 precedent is a
  one-shot shape, not a paired assertion).

* Manual verification (implementation commits):
  * Inject `vendor/conventional-agents/guidelines/NEVER-EXISTED.md` into
    `INTEGRATION.md` → gate rc≠0 (currently rc=0 — the regression proof).
  * `npm run check:status` rc=0 on the clean tree.

## 5. Rollback

Revert the implementation commits; the script, `scripts/README.md`, and the
bats file return to their pre-change state. The plan reverts with this branch
if unmerged; if merged, rollback is itself a governed change — a new
reconcile PR reverts the status rows and CHANGELOG marker (a merged plan
document cannot be un-edited in place). No instance data, no npm scripts,
and no CI jobs are added, so rollback is content-only.

## 6. Readiness Check

* [x] FS-0037 is approved (2026-09-24, recorded via PR #175) — the gate that
  held this revision back
* [ ] This revision's own recorded approval (reserved paths) — the
  maintainer's next act
* [x] Tests are defined per SC (section 4)
* [x] Scope is explicit; every reserved-path and out-of-union entry in
  `touches:` (the `scripts/` pair and the FS-0037 spec file) routes
  approval to the maintainer's recorded act (§3)
