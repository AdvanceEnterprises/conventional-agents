---

type: change-plan
role: implementer
language: bash
status: approved
related_specs: [FS-0024]
approved_by: "Joey Clark <taisden@tais-den.dev>"
related_adrs: [ADR-0012, ADR-0015, ADR-0019, ADR-0027, ADR-0030, ADR-0032, ADR-0033]
touches:
  - scripts/check-status.sh
  - scripts/check-current-state.sh
  - scripts/run-bats.sh
  - scripts/README.md
  - config/gates.example.yml
  - README.md
  - AGENTS.md
  - docs/specifications/README.md
  - CHANGELOG.md
  - test/FS-0024/portable-gates.bats
created: 2026-08-02
updated: 2026-08-02

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0024
* Related ADR ID(s): ADR-0033 (governing), ADR-0012, ADR-0015, ADR-0019, ADR-0027,
  ADR-0030, ADR-0032
* Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

* Change `REPO_ROOT` resolution in `check-status.sh` and `run-bats.sh` from
  `$(cd "$(dirname "$0")/.." && pwd)` to
  `${CA_TARGET_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}`.
* Add the same `CA_TARGET_REPO` override to `check-current-state.sh`, ahead of its
  existing (already-correct) resolution call.
* Add a `FRAMEWORK_HOME` computation (the old `dirname "$0"`-based value, renamed and
  retained) to `check-status.sh` and `run-bats.sh`, used to detect whether the
  resolved target is this repository checking itself.
* Add `config/gates.yml` reading to `check-status.sh`'s rule 6 (PLAN `touches:`
  containment / self-approval) and rule 7 (consumer-impact CHANGELOG), sourced from
  `$REPO_ROOT/config/gates.yml`, used only when `REPO_ROOT` differs from
  `FRAMEWORK_HOME`.
* Implement fail-closed behavior for rule 6 when `reserved_paths` is unset in
  `config/gates.yml` or the file is absent: refuse to certify any PLAN as
  self-approved, exit non-zero, name `reserved_paths` as unconfigured.
* Implement skip-and-report behavior for rule 7 when `exported_prefixes` is unset or
  the file is absent: report the rule as inapplicable, exit zero (absent other
  failures), with output distinguishable from "ran, found nothing."
* Add `scripts/` to `check-status.sh`'s self-check (hardcoded) `EXPORTED_PREFIXES`
  value.
* Create `config/gates.example.yml`, matching the header convention of
  `config/consensus.yml` and `config/review-board.yml`, with `reserved_paths`,
  `exported_prefixes`, and `ref_exempt` as flat, empty, documented list fields.
* Rewrite `scripts/README.md`'s relevant sections to document all of the above —
  target resolution, self-check detection, the configuration schema and its source,
  and the fail-closed/skip distinction and why it exists.
* Move `scripts/` from "Internal governance" to "Exported surface" in `README.md`'s
  and `AGENTS.md`'s exported-surface tables.
* Add `scripts/` to the exported-surface bullet list in
  `docs/specifications/README.md`'s "Does this spec change the exported surface?"
  section, leaving the existing `FS-0022` worked example unedited as a historical
  record.
* Add a consumer-framed `CHANGELOG.md` entry under `[Unreleased]`.
* Write `test/FS-0024/portable-gates.bats`, one test per Success Criterion, each
  shaped per `CONTRIBUTING.md` §"Changing a Governance Gate": mutate the condition
  the check protects, assert the check notices, assert the message names the
  specific thing.
* Transition FS-0024 and this PLAN to `implemented` in the completing PR.

**This change will NOT:**

* Change any rule any existing check evaluates. All eight checks' enforcement logic
  is untouched; only target resolution and per-repository-value sourcing change.
* Create a populated `config/gates.yml` for this repository's own use.
  `RESERVED_PATHS` and `EXPORTED_PREFIXES` remain hardcoded in `check-status.sh` for
  the self-check case, per `ADR-0033`.
* Reconcile `CURRENT_STATE_RE` (`check-current-state.sh`) with rule 8's directory set
  (`check-status.sh`). Named in `FS-0024` Non-Goals and `ADR-0033` Non-Goals; a
  distinct, already-recorded finding.
* Make `FS_DIR`, `PLAN_DIR`, `ADR_DIR`, `REQUIRED_ADR_SECTIONS`, or `CURRENT_STATE_RE`
  configurable. Classified universal by `ADR-0033`.
* Modify `.github/workflows/lint-docs.yml`. Its three relevant jobs invoke the scripts
  with unchanged syntax; `scripts/**/*` is already a trigger path.
* Add a YAML parsing library or `yq` dependency. `config/gates.example.yml`'s schema
  is flat enough for the same bash/awk approach already used against markdown front
  matter.
* Retrofit `feral-fleet` or any other consumer repository.

## 3. Tests Driving This Change

* Test file: `test/FS-0024/portable-gates.bats`

* Target tests, one per FS-0024 Success Criterion. Each follows
  `CONTRIBUTING.md`'s shape: back up, mutate the exact thing the check protects, run,
  restore before asserting, assert both the exit code and that the output names the
  specific offending condition — not merely that the check exits non-zero for some
  reason.

  **Target resolution** (the core defect; the test that would have caught it):

  * `test_target_resolution__vendored_check_detects_host_drift` — build a scratch
    host fixture under `$BATS_TMPDIR` with its own `.git`, its own
    `docs/specifications/README.md` and `docs/change-plans/README.md`, and a
    deliberately broken `FS-9001` (`status: implemented`, no governing PLAN, no
    README row). Symlink or copy this repository's `scripts/` into the fixture at
    `vendor/conventional-agents/scripts/`. Run
    `bash vendor/conventional-agents/scripts/check-status.sh` **from the fixture's
    own root**. Assert non-zero exit and output naming `FS-9001`. This is the
    positive control: run the same fixture through the **unmodified** script first (or
    against a captured pre-fix copy) and assert it currently reports `All status
    checks passed.` — the test proves the defect existed before proving the fix
    works, exactly as the CONTRIBUTING.md standard requires ("assert the accommodation
    too").
  * `test_target_resolution__subdirectory_still_resolves_host_root` — same fixture,
    invoked from a subdirectory of the fixture, not its root. Assert the same
    detection.
  * `test_target_resolution__ca_target_repo_override_wins` — set `CA_TARGET_REPO` to
    a third path, distinct from both the caller's CWD and the script's own location;
    assert the script reads from that path, not from CWD or script location.
  * `test_target_resolution__framework_self_check_unchanged` — run
    `check-status.sh` with no override, CWD at this repository's own root (the
    existing `npm run check:status` shape); assert `All status checks passed.`,
    proving the framework's own invocation is unaffected.

  **Self-check detection:**

  * `test_self_check__equal_roots_use_hardcoded_values` — resolved target equals
    `FRAMEWORK_HOME`; assert rule 6/7 use the existing hardcoded arrays (e.g., a PLAN
    touching `scripts/` in this repository's own fixture still requires human
    approval without any `config/gates.yml` present).
  * `test_self_check__differing_roots_require_config` — resolved target differs from
    `FRAMEWORK_HOME`, no `config/gates.yml` present; assert the hardcoded arrays are
    **not** consulted (a PLAN touching a path that would be reserved under this
    repository's own hardcoded set, but is not configured in the fixture, is not
    flagged as reserved — proving no silent fallback to this repository's own values
    for someone else's repository).

  **Fail-closed (rule 6):**

  * `test_rule6__missing_config_refuses_certification` — vendored context, no
    `config/gates.yml`, a PLAN at `approved` with no `Approved-By:` evidence; assert
    non-zero exit and output naming `reserved_paths` as unconfigured.
  * `test_rule6__explicit_empty_list_is_honored` — `config/gates.yml` present with
    `reserved_paths: []`; assert the same PLAN is evaluated against `interfaces:`
    containment alone, not refused — proving explicit-empty differs from absent.
  * `test_rule6__configured_path_is_enforced` — `config/gates.yml` with
    `reserved_paths` naming a path; a PLAN's `touches:` includes it; assert human
    approval is required, matching today's hardcoded-set behavior.

  **Skip-explicit (rule 7):**

  * `test_rule7__missing_config_skips_and_says_so` — vendored context, no
    `config/gates.yml`; assert exit zero (no other failure) and output stating rule 7
    is skipped — captured and asserted distinctly from the "all checks passed, rule 7
    included" message, so a consumer cannot mistake silence for verification.
  * `test_rule7__explicit_empty_list_also_skips` — `exported_prefixes: []`; same
    assertion as above.
  * `test_rule7__configured_prefix_is_enforced` — `config/gates.yml` with
    `exported_prefixes` naming a path; an `approved`-status FS in the fixture names
    that path in `interfaces:` with no matching `CHANGELOG.md` entry; assert the
    check fails, matching today's hardcoded-set behavior.

  **Reclassification:**

  * `test_reclassification__readme_and_agents_list_scripts_as_exported` — grep
    `README.md` and `AGENTS.md` exported-surface tables for a `scripts/` row on the
    exported side.
  * `test_reclassification__exported_prefixes_hardcoded_value_includes_scripts` —
    grep `check-status.sh`'s hardcoded `EXPORTED_PREFIXES` array for `scripts/`.

  **Documentation:**

  * `test_docs__scripts_readme_documents_ca_target_repo` — grep
    `scripts/README.md` for `CA_TARGET_REPO`.
  * `test_docs__scripts_readme_documents_fail_closed_vs_skip` — grep for language
    distinguishing rule 6's refusal from rule 7's skip and stating why they differ.

## 4. Files to Be Modified

* `scripts/check-status.sh`
* `scripts/check-current-state.sh`
* `scripts/run-bats.sh`
* `scripts/README.md`
* `config/gates.example.yml` (new)
* `README.md`
* `AGENTS.md`
* `docs/specifications/README.md`
* `CHANGELOG.md`
* `test/FS-0024/portable-gates.bats` (new)

Deliberately **not** listed: `.github/workflows/lint-docs.yml` (invocation syntax
unchanged; `scripts/**/*` is already a trigger path) and `package.json` (no new npm
script; the existing `check:status` and `test` entries invoke the same scripts the
same way).

## 5. Implementation Steps (High-Level)

1. Write `test/FS-0024/portable-gates.bats` first, against the current (unfixed)
   scripts. The target-resolution tests fail; that is the starting condition — it is
   the demonstration of the defect, made repeatable.
2. Change `REPO_ROOT` resolution in `check-status.sh`: introduce `FRAMEWORK_HOME` as
   the old computation, and `REPO_ROOT` as the new
   `${CA_TARGET_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}`. Every
   existing use of `$REPO_ROOT` in the script is unchanged — only its assignment
   changes.
3. Apply the same `REPO_ROOT`/`FRAMEWORK_HOME` change to `run-bats.sh`.
4. Add the `CA_TARGET_REPO` override to `check-current-state.sh`, ahead of its
   existing `git rev-parse --show-toplevel` call. Its fallback behavior when no
   override is set does not change.
5. In `check-status.sh`, add the `FRAMEWORK_HOME`-vs-`REPO_ROOT` comparison. When
   equal, rules 6 and 7 use the existing hardcoded `RESERVED_PATHS` /
   `EXPORTED_PREFIXES` arrays, unchanged. When different, both rules instead read
   `$REPO_ROOT/config/gates.yml`.
6. Write the `config/gates.yml` reader: a small variant of the existing
   `get_list_field` helper, operating on a plain YAML file with no `---`
   front-matter delimiters, extracting `reserved_paths:`, `exported_prefixes:`, and
   `ref_exempt:` as flat list fields. Distinguish "file absent" from "file present,
   field present but empty" — the fail-closed and skip behaviors below depend on
   telling these apart from "field absent."
7. Implement rule 6's fail-closed behavior: if `config/gates.yml` is absent, or
   present without a `reserved_paths:` key at all, the check reports
   `reserved_paths` as unconfigured and does not certify any PLAN as self-approved
   in this run, exiting non-zero if any PLAN would otherwise have been evaluated. An
   explicit `reserved_paths: []` is treated as a real (empty) value, not as absence.
8. Implement rule 7's skip behavior: if `config/gates.yml` is absent, or present
   without an `exported_prefixes:` key, or with `exported_prefixes: []`, the check
   prints a line stating rule 7 does not apply and takes no further action for it in
   this run. This does not affect the exit code of other rules.
9. Add `scripts/` to `check-status.sh`'s hardcoded `EXPORTED_PREFIXES` (the self-check
   value).
10. Create `config/gates.example.yml` with the `config/consensus.yml` header
    convention, flat empty-list fields for `reserved_paths`, `exported_prefixes`, and
    `ref_exempt`, and a comment on each explaining what leaving it empty means for
    the corresponding check.
11. Rewrite the relevant sections of `scripts/README.md`: document `CA_TARGET_REPO`,
    the `FRAMEWORK_HOME` comparison, the `config/gates.yml` schema and its source
    (the consumer's own repository root, never inside `vendor/`), and the fail-closed
    (rule 6) vs. skip (rule 7) distinction with the reasoning from `ADR-0033`.
12. Update `README.md`'s and `AGENTS.md`'s exported-surface tables: move `scripts/`
    from the internal-governance column to the exported-surface column.
13. Add `scripts/` to the exported-surface prefix list in
    `docs/specifications/README.md`'s "Does this spec change the exported surface?"
    section. Leave the `FS-0022` worked example's text unedited.
14. Re-run the full bats suite against the corrected scripts; the target-resolution
    tests from step 1 now pass.
15. Run `npm run check:status` and `npm run lint:docs` against this repository's own
    trunk state (the self-check path) and confirm unchanged (green) results.
16. Add the `CHANGELOG.md` entry, consumer-framed, describing the effect: vendored
    gates now check the host repository, and self-approval routing requires
    `config/gates.yml` to certify anything.
17. Transition FS-0024 and this PLAN to `implemented`.

## 6. Constraints and Guardrails

* Spec constraints:

  * `FS-0024` Non-Goals: no change to what any of the eight checks enforce; no
    `CURRENT_STATE_RE`/rule-8 reconciliation; no configurability for the
    universal-classified values; no CI workflow edits; no new parsing dependency; no
    `feral-fleet` retrofit.

* ADR constraints:

  * `ADR-0015` — these are Category 1 governance gates; this PLAN cannot proceed
    without both FS-0024 and this PLAN approved.
  * `ADR-0027` — every path in `touches:` above is reserved (`scripts/`,
    `package.json` is not touched but `scripts/` alone is sufficient). **This PLAN
    can never self-approve.** It requires human approval by construction, which is
    correct: this is the plan modifying the check that evaluates self-approval.
  * `ADR-0030` — rule 3 applies to `ADR-0033`'s acceptance: `scripts/README.md` is
    the named current-state document and must update in the same change that
    accepts the ADR, not before and not separately after.
  * `ADR-0032` — `config/gates.example.yml` ships empty; no populated
    `config/gates.yml` is created for this repository. Extending the
    `config/consensus.yml`/`config/review-board.yml`/`config/project.example.yml`
    pattern, not inventing a new one.
  * `ADR-0019` — the "an agent must not lower its own gate" principle is why rule
    6's absent-configuration behavior is refusal, not permissive default.

* Architecture constraints:

  * `check-status.sh` must remain runnable against a working tree with no diff
    context — unchanged from `FS-0022`'s constraint, and nothing here introduces a
    git-diff dependency to it.
  * The `config/gates.yml` reader must not require any tool beyond what this
    repository's CI and local development already assume (`bash`, `awk`, `git`).

## 7. Risks and Edge Cases

* **The positive-control test is load-bearing.** A test suite that only proves the
  fixed script works, without first proving the unfixed script was wrong, would
  repeat exactly the failure mode `CONTRIBUTING.md` documents four prior instances
  of — a green suite that never exercised the defect. `test_target_resolution__
  vendored_check_detects_host_drift` must run against an unmodified copy of the
  pre-change script (or the change reverted) and assert it currently passes
  incorrectly, before asserting the corrected script fails correctly.
* **Distinguishing "absent" from "present but empty" in the YAML reader is easy to
  get wrong in bash.** An `awk`-based list-field reader that returns an empty string
  for both cases would collapse the fail-closed/skip distinction this PLAN's entire
  configuration design depends on. The reader must expose three states — key absent,
  key present with an empty list, key present with values — not two.
* **A fixture-based bats test that clones or copies this repository's `scripts/`
  directory into a scratch host must not leave scratch state behind on failure.**
  Follow the existing `mktemp`/restore-before-assert pattern used throughout
  `test/FS-0022/gate-coverage.bats`.
* **`git rev-parse --show-toplevel`'s behavior when run from inside the
  `vendor/conventional-agents` submodule itself** is not a bug to guard against — see
  `FS-0024`'s Edge Cases. The test suite should include a case confirming this
  (running from inside the submodule resolves to the submodule's own root, i.e., the
  self-check path is correctly taken), so a future reader does not mistake the
  documented behavior for an oversight.
* **`CA_TARGET_REPO` must be tested for precedence order** — it must win over both
  CWD-based resolution and the self-check comparison's inputs, since a caller setting
  it explicitly is stating their intent unambiguously.
* **Rule 6's refusal must not be mistaken for a crash.** The exit code is non-zero
  either way, but the message must make clear that the check ran and declined to
  certify, versus having failed to execute — the same "assert the message, not just
  the exit code" standard `CONTRIBUTING.md` states.

## 8. Validation

* Tests expected to pass:

  * All of `test/FS-0024/portable-gates.bats`.
  * All pre-existing suites, unaffected: `test/FS-0001`, `FS-0016` through `FS-0023`.
  * `npm run check:status` and `npm run lint:docs` against this repository's own
    trunk (the self-check path), unchanged results.

* Manual checks:

  * Reproduce the scratch-host defect from `ADR-0033`'s Context section against the
    **pre-change** scripts, confirming `All status checks passed.` incorrectly.
  * Re-run the identical scratch host against the **post-change** scripts, confirming
    the deliberately broken spec is now reported.
  * Run `bash vendor/conventional-agents/scripts/check-status.sh` from a genuine
    second local checkout of a different repository (not a bats fixture) to confirm
    the mechanism holds outside the test harness.

## 9. Explicit Non-Changes

* Every rule's enforcement logic in `check-status.sh` and `check-current-state.sh`.
* `check-current-state.sh`'s default (no-override) resolution behavior.
* `FS_DIR`, `PLAN_DIR`, `ADR_DIR`, `REQUIRED_ADR_SECTIONS`, `CURRENT_STATE_RE` — no
  configurability added, per `ADR-0033`.
* `.github/workflows/lint-docs.yml`.
* `config/consensus.yml`, `config/review-board.yml`, `config/project.example.yml` —
  untouched; this PLAN follows their established pattern, does not modify them.
* Any historical reference to `scripts/` as internal-only outside the two tables and
  one bullet list named in §4 — including `FS-0022`'s own worked example in
  `docs/specifications/README.md`, which remains accurate as a record of what was
  true when it was written.

## 10. Readiness Check

* [x] FS-0024 is approved
* [x] ADR-0033 is accepted
* [x] Tests are clearly defined — §3, one per Success Criterion, each shaped to
      mutate-and-assert per `CONTRIBUTING.md`
* [x] Scope is minimal and explicit — ten files, two new
* [x] **Human approval given.** Every path in `touches:` includes `scripts/`,
      reserved under `ADR-0027`; this PLAN could not self-approve. Recorded per
      `ADR-0026` — see `approved_by:` above and the commit carrying the matching
      `Approved-By:` trailer.

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
