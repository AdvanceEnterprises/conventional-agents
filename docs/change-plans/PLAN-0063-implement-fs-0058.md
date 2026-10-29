---

type: change-plan
role: implementer
language: bash
status: draft
related_specs:
  - FS-0058
related_adrs:
  - ADR-0015
  - ADR-0027
  - ADR-0033
consensus_required: false
touches:
  - scripts/check-citations.sh
  - scripts/README.md
  - package.json
  - test/FS-0058/citation-resolution.bats
  - docs/specifications/FS-0058-local-governed-id-citation-resolution-gate.md
  - docs/change-plans/PLAN-0063-implement-fs-0058.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-27
updated: 2026-10-29

---

<!--
`touches:` declares every path this plan will modify, as repo-relative paths or
globs. It is compared against the governing FS's `interfaces:` to route approval:

- Entirely within the FS's `interfaces:` → the plan is derivative of an
  already-approved decision and may self-approve.
- Anything outside them → the plan proposes scope no human sanctioned, and
  requires human approval.

Certain paths always require human approval regardless of the FS's `interfaces:`.
See ADR-0027 for the reserved set and the rationale.

Under-declaring here is a process violation, not a shortcut: the document hygiene
gate checks touched files against the FS `interfaces:` at PR time, so an
under-declared plan fails later and louder.
|-->

# PLAN-0063: Implement FS-0058 — Local governed-ID citation resolution gate

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0058
* Related ADR ID(s): ADR-0015 (Category 1 gate introduction requirements),
  ADR-0027 (reserved paths and human approval), ADR-0033 (target repository
  resolution)
* Issue / PR Reference: #186 (cross-PR stale-citation drift remains covered by
  FS-0040 / PLAN-0046 / `gh-pr-claim-audit.sh`; this plan covers only the local
  offline resolution layer)

## 2. Scope of Change

**This change WILL:**

* Create `scripts/check-citations.sh`, a Bash 3.2-compatible, read-only,
  offline gate that resolves `FS-NNNN`, `PLAN-NNNN`, and `ADR-NNNN` citations
  against the local registries.
* Register the script as `npm run check:citations` in `package.json`.
* Document the gate in `scripts/README.md` as optional, detection-only tooling
  governed by FS-0058 / PLAN-0063 — explicitly **not** a Category 1 gate, since
  ADR-0015 reserves that class for scripts wired into CI — and explicitly
  distinguish it from the FS-0040 cross-PR stale-citation audit.
* Provide Bats regression coverage under `test/FS-0058/` for resolved,
  unresolved, exempted, malformed-input, and invalid-input scenarios.
* Author FS-0058 and PLAN-0063, and update the FS/PLAN index READMEs and
  `CHANGELOG.md` to reflect the new governed documents.
* Move the previously misplaced `test/FS-0040/citation-resolution.bats` into
  the FS-0058-owned test directory so the suite's scope matches the governing
  spec.
* Renumber this branch's own draft spec from the previous `FS` sequence number
  `0056` to `FS-0058`, and carry that rename through the plan, the index
  READMEs, the test directory, `scripts/README.md`, and `CHANGELOG.md`. An open
  PR (#257) holds the earlier registry claim on `0056`; merging both would put
  two documents claiming one ID in one tree and fire the framework's rule-4
  duplicate detector.

**This change will NOT:**

* Implement cross-PR stale-citation drift detection; that remains FS-0040
  (`integrations/github/bin/gh-pr-claim-audit.sh`).
* Wire `check:citations` as a required CI gate by default, and therefore does
  not claim ADR-0015's Category 1 class for it.
* Rewrite, renumber, or mutate any pre-existing `trunk` governance document or
  ID. The only renumbering is this branch's own draft spec, described above.
* Close issue #186, whose unresolved gap is the cross-PR renumber-drift event,
  not local unresolved citations.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0058/citation-resolution.bats`

* Target test(s):

  * `passes when all citations resolve`
  * `fails on unresolved FS citation`
  * `fails on unresolved PLAN citation`
  * `fails on unresolved ADR citation`
  * `exempted IDs are not reported`
  * `command-line exemptions combine with environment`
  * `comma-separated environment exemptions are honored`
  * `self-citation is allowed`
  * `invalid input exits with usage`
  * `invalid exemption token exits 2 with a diagnostic`
  * `malformed environment exemption exits 2 instead of aborting silently`
  * `non-directory CA_TARGET_REPO exits 2`

## 4. Files to Be Modified

* `scripts/check-citations.sh`
* `scripts/README.md`
* `package.json`
* `test/FS-0058/citation-resolution.bats` (moved from `test/FS-0040/`)
* `docs/specifications/FS-0058-local-governed-id-citation-resolution-gate.md`
* `docs/change-plans/PLAN-0063-implement-fs-0058.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

1. Restore the previously withdrawn `check-citations.sh` implementation on a
   branch that already contains FS-0058 and PLAN-0063 as draft governance
   documents.
2. Update the script header and `scripts/README.md` framing to remove the
   incorrect "Issue #186 / FS-0040 complement" description and instead describe
   the local unresolved-citation check.
3. Move the bats regression suite from `test/FS-0040/` to `test/FS-0058/` and
   update the file header to reference FS-0058 / PLAN-0063 and explicitly
   disclaim FS-0040 coverage.
4. Add FS-0058 and PLAN-0063 to their respective index READMEs and add a
   consumer-framed `CHANGELOG.md` entry because the change touches the exported
   `scripts/` surface.
5. Run the dedicated bats suite, the status gate, and `check-run-batch.sh` on
   every new commit before pushing.
6. Add per-finding review follow-ups on the same branch: relabel the gate from
   Category 1 to optional tooling, validate exemption tokens instead of
   filtering them, state the implemented scan scope in the script comment and
   in FS-0058's Edge Cases, and de-tokenize this plan's own corpus-debt prose
   so the plan stops reporting itself as a finding.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0058 Non-Goals: no cross-PR drift, no default CI enforcement, no network.

* ADR constraints:

  * ADR-0015 §Category 1: a governance gate must have an approved FS and PLAN
    before code is written, must live in `scripts/`, must be registered in
    `package.json`, and must be documented in `scripts/README.md`. This change
    deliberately does **not** claim Category 1 because it is not wired into CI;
    the location, registration, and documentation requirements still hold.
  * ADR-0027: because this plan touches reserved paths (`scripts/`,
    `package.json`), it requires human approval before it can leave `draft`.
    It stays `draft` in this PR.
  * ADR-0033: target repository resolution must respect `CA_TARGET_REPO` and
    the caller's working directory.

* Architecture constraints:

  * Bash 3.2 compatibility; no associative arrays.
  * Read-only; never fetches or edits.

## 7. Risks and Edge Cases

* The script reports the framework corpus's pre-existing unresolved citations:
  seven findings on `trunk`, emitted from `PLAN-0024`, `PLAN-0054`, `ADR-0033`,
  `FS-0040` (two), and `FS-0048` (two). Those five phantom identifiers are
  retired-or-example IDs written into the older documents, not citations this
  change introduces, and rewriting them is out of scope (§9). Run
  `npm run check:citations` to see the exact tokens.
* This section names the citing documents and the counts, not the phantom
  tokens, because the scanner is token-based and fence-agnostic: quoting a
  phantom ID anywhere in this plan — including inside backticks — makes the
  plan its own finding and raises the corpus count from seven to twelve. The
  head of this branch reports the same seven findings as `trunk`.
* An exemption token that is not a governed ID is a usage error (`2`), not a
  silently dropped entry: a filtering pipeline under `set -euo pipefail`
  aborted the whole scan with exit 1 and no output before this was fixed.
* Exemptions must not be silently dropped when both CLI and environment
  sources are present, and both sources accept a comma- or space-separated
  list.
* The script must fail closed when the target repository has no governed
  documents to scan.

## 8. Validation

* Tests expected to pass:

  * `bats test/FS-0058/citation-resolution.bats`
  * `npm run check:status`
  * `npm run lint:docs`
  * `bash scripts/check-run-batch.sh` for each commit in the PR range

* Manual checks (if any):

  * Verify `npm run check:citations` is wired correctly.
  * Confirm the PR body no longer claims `Closes #186` and accurately describes
    the local gate's scope.

## 9. Explicit Non-Changes

* Issue #186 remains open; its cross-PR renumber-drift gap is handled by
  FS-0040 / PLAN-0046 (`gh-pr-claim-audit.sh`).
* No changes to `.github/workflows/lint-docs.yml`, `npm run validate`, or
  `check-status.sh` to enforce the gate; the posture stays detection-only. The
  honest remedy for the Category 1 mislabel was the relabel, not CI wiring:
  wiring is a reserved path (`.github/workflows/`) behind human approval, and
  ADR-0015 expects a clean corpus for a blocking check, which the framework
  does not have.
* No cleanup of the pre-existing unresolved citations the gate reports on
  `trunk`, and no exemption list committed for them: a repo-wide exemption
  would mask genuine debt for every consumer.
* No renumbering of any pre-existing `trunk` governance ID. The `FS` number
  change described in §2 applies only to this branch's own draft spec, which
  this same PR authored.

## 10. Readiness Check

* [x] FS-0058 drafted with `interfaces:` covering every path in this plan's
      `touches:`.
* [x] PLAN-0063 `touches:` declares every reserved path and every new
      proposal-class path.
* [x] Bats suite relocated from `test/FS-0040/` to `test/FS-0058/` and
      re-labeled.
* [x] `scripts/README.md` no longer frames the gate as an #186 / FS-0040
      complement.
* [ ] Human approval recorded for reserved-path changes before `status: approved`
      or `in-progress`.
* [ ] CI green and `check-run-batch.sh` clean at the final HEAD.

### Where the approval trailer must land

Human approval is recorded in git, not in prose (ADR-0026). The `Approved-By:`
trailer belongs on **the most recent commit that touches this plan file**, and
its author email must differ from that commit's author email — a trailer whose
`Approved-By:` matches its own commit author is malformed. `scripts/check-status.sh`
reads approval evidence this way (`:963-966`, `:994-996`), and it also compares
the `touches:` set recorded at the approving commit against the working tree, so
**any later edit to this plan requires a fresh approval commit**. A trailer on a
commit that does not touch this file records nothing.
