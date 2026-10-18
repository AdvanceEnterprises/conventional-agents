---

type: change-plan
role: implementer
language: python
status: draft
related_specs: [FS-0051]
related_adrs: [ADR-0047, ADR-0048]
touches:
  - "src/collective_agents/"
  - "tests/"
  - "pyproject.toml"
  - "config/instance.example.yml"
  - "grants/"
  - ".github/workflows/engine-tests.yml"
  - "package.json"
  - "README.md"
  - "docs/ARC42.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
created: 2026-10-01
updated: 2026-10-02

---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 3)
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
- `touches:` is authoritative for approval routing. See ADR-0027.
-->

> **Note — imported and deferred.** This plan was `approved` in collective-agents
> as PLAN-0001. The engine it describes is deferred per ADR-0046 and will be
> re-extracted as its own package when built, not inside conventional-agents.
> The `touches:` paths below describe that future engine.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0051 (amended 2026-10-01 to declare this surface)
* Related ADR ID(s): ADR-0047 (intent identity and the human grant), ADR-0048
  (worker/publisher credential separation)
* Issue / PR Reference: GH #5 (the pilot work item); PR #15 (the FS-0051
  interface amendment this plan depends on)

## 2. Scope of Change

**This change WILL:**

* Create the `collective_agents` Python package implementing the FS-0051
  pilot's engine loop for the single authorized intent: pass enumeration,
  grant resolution and verification, intent reservation and ledger, dispatch
  through a runtime adapter, evidence validation, publication through a
  separately credentialed publisher, and every hold path the spec names.
* Create the pytest suite mapping one test (or parametrized set) to each
  FS-0051 Success Criterion, with the module metadata the framework's Python
  testing guide requires, plus fault-injection tests at the reservation,
  dispatch, publication, and acknowledgement boundaries named in the FS's
  Edge Cases.
* Create `config/instance.example.yml` documenting the instance configuration
  shape (repository, substrates, runtime, schedules, budgets, secret
  references by name only).
* Create `grants/` with a README stating the record format and the
  human-only write rule; a grant is a human commit, never an engine write.
* Create `.github/workflows/engine-tests.yml` running the pytest suite.
* Add the npm `test` entry invoking pytest (`package.json`).
* Update `README.md` status text and `docs/ARC42.md` to mark the pilot blocks
  implemented, and both governed-doc indexes for status sync.
* Execute the pilot as one implementation PR after the plan receives its
  separate human approval. Use the lifecycle's single-PR exception: leave
  `FS-0051` and this plan at `approved` while the implementation PR is built,
  then transition both directly to `implemented` in that completing PR; no
  intermediate `in-progress` status commit is used.

**This change will NOT:**

* Implement any `task` path, any Phase transition, or any merge/approve/ready
  action by any automated actor (FS-0051 Non-Goals; ADR-0012).
* Give the worker process any GitHub write credential, mounted `gh` login,
  SSH push key, or credential helper — the probe test asserts absence from
  inside the worker's effective environment (ADR-0048).
* Add a second work-item substrate or a second agent runtime. GitHub binding
  and the Hermes worker are the first implementations; other adapters are
  later work.
* Claim exactly-once external publication anywhere. The goal is one canonical
  draft PR per intent with the discovery/hold recovery path (ADR-0047).
* Touch `config/gates.yml`, `AGENTS.md`, `vendor/conventional-agents`, or any
  other reserved path not listed in `touches:`.

## 3. Tests Driving This Change

* Test file(s), under `tests/`:

  * `tests/test_authority.py` — FS SC-1, SC-2, SC-6 (grant resolution, unset
    Type, description-edit generation rules)
  * `tests/test_ledger.py` — SC-3, SC-4, SC-5 (reservation-before-dispatch,
    two-pass convergence, repeated-attempt single publication)
  * `tests/test_evidence.py` — SC-7, SC-8 (evidence completeness, worker
    credential probe)
  * `tests/test_publication.py` — SC-9, SC-11, SC-12, SC-13 (revoked-grant
    hold, ambiguous-create discovery, draft-PR readback, Phase unchanged)
  * `tests/test_holds.py` — SC-10, SC-14, SC-15, SC-16 (lost-dispatch hold,
    stale-generation and unknown-write question ordering, operational hold
    vs question, no merge/approve/ready by any automated actor)
  * `tests/conftest.py` + `tests/fakes/` — substrate, runtime, and Git-host
    fakes used to fault-inject at each boundary without real external writes

* Target tests (names carry their SC identifier per the framework testing
  guide; each SC maps to at least one test, verbatim text in the `Spec
  mapping` block):

  * `test_sc_1__no_grant_no_dispatch`, `test_sc_1__records_why`
  * `test_sc_2__unset_type_most_restrictive`
  * `test_sc_3__reservation_precedes_dispatch_effects`
  * `test_sc_4__two_passes_one_reservation`
  * `test_sc_5__retry_no_second_publication`
  * `test_sc_6__description_edit_mints_no_generation`
  * `test_sc_7__evidence_completeness`
  * `test_sc_8__worker_credential_probe`
  * `test_sc_9__revoked_grant_holds_publication`
  * `test_sc_10__lost_dispatch_ack_holds`
  * `test_sc_11__unknown_create_discovers_first`
  * `test_sc_12__published_pr_readback_draft`
  * `test_sc_13__phase_remains_approved`
  * `test_sc_14__question_ordering_stance_first`
  * `test_sc_15__operational_hold_not_question`
  * `test_sc_16__no_merge_approve_ready`

## 4. Files to Be Modified

* `src/collective_agents/__init__.py`, `cli.py`, `config.py`, `workitems.py`,
  `grants.py`, `ledger.py`, `reconciler.py`, `dispatcher.py`, `evidence.py`,
  `publisher.py`, `holds.py`, `errors.py` (all new)
* `tests/` suite files above (all new); `tests/fakes/` (new)
* `pyproject.toml` (new)
* `config/instance.example.yml` (new)
* `grants/README.md` (new)
* `.github/workflows/engine-tests.yml` (new)
* `package.json`, `README.md`, `docs/ARC42.md`,
  `docs/specifications/README.md`, `docs/change-plans/README.md`,
  `docs/specifications/FS-0051-feature-draft-spec-pilot.md` (status),
  `docs/change-plans/PLAN-0058-*.md` (this file, status), `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

1. Land this plan and the FS-0051 amendment (PR #15) by human merge; record
   the plan's separate `draft` → `approved` human approval before implementation
   begins, then confirm the gates read the amended `interfaces:`.
2. Scaffold `pyproject.toml` and write the full pytest suite first (RED):
   every Success Criterion test plus the boundary fault-injection tests, all
   against the fakes. The suite defines the engine's observable contract
   before any engine module exists.
3. Implement the durable pieces bottom-up: ledger store and atomic
   reservation; grant parsing/verification against the grant record format;
   work-item adapter (GitHub binding's documented capabilities, with the
   enforcement-versus-detection table); runtime adapter against the probed
   Hermes invocation behavior.
4. Implement the reconciler pass: enumerate, evaluate eligibility (Type,
   Phase, `question`, grant, prior intent), and the stop/hold decisions with
   reason recording.
5. Implement the dispatcher and evidence validator: bounded FS-drafting
   scope, evidence completeness checks, actual-model recording, path-scope
   validation.
6. Implement the publisher: authority recheck, identity verification,
   discovery before create, draft-PR create with readback, link without a
   closing keyword, and the operational/question hold paths with their
   stance ordering.
7. Implement the worker credential probe as a test that runs against the
   configured runtime boundary and fails closed.
8. Wire CI (`engine-tests.yml`), the npm test entry, and the instance example
   config; run the full suite to GREEN.
9. Fault-injection pass: lost dispatch acknowledgement, ambiguous create,
   revoked grant mid-run, interleaved passes — asserting the hold, not a
   second effect.
10. In the same implementation PR, update README/ARC42/indexes and add the
    CHANGELOG entry; transition PLAN-0058 and FS-0051 directly from `approved`
    to `implemented` after the full suite and validation pass.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0051 Non-Goals / Out of Scope apply in full — no task path, no Phase
    writes, no exactly-once claims, no second substrate/runtime.

* ADR constraints:

  * ADR-0047: authority comes from a human grant, never from Type or Phase;
    the intent (work item + action + scope generation) is the dedupe unit;
    an attempt never mints authority.
  * ADR-0048: evidence-only worker; separate publisher; the boundary is
    verified by probing from inside, not asserted; the publisher can never
    merge.

* Architecture constraints:

  * Git remains the durable artifact source; the ledger is correlation state,
    not a second source of truth.
  * No cross-system atomic transaction may be assumed anywhere; every
    boundary names its recovery path.

## 7. Risks and Edge Cases

* The credential-probe test can pass vacuously if the probe target is
  misconfigured — it must enumerate environment, mounts, helpers, `gh` state,
  and SSH keys, and fail closed on any enumeration error.
* The two-pass test must assert one reservation, not one process; the fake
  substrate must be able to interleave.
* The discovery-before-create path must search closed and merged PRs; a fake
  that only lists open PRs would make the test falsely green.
* Ambiguous-create fault injection must be possible in the fake with the
  exact timing (success remote, lost acknowledgement local) the spec names.
* Model fallback: the runtime fake must be able to substitute a fallback
  model so the actual-model recording and independence-claim failure are
  exercised.
* `package.json` and `.github/workflows/` are reserved: this plan cannot
  self-approve and requires the separate human `approved_by:` / `Approved-By:`
  record before execution. Because execution is constrained to one
  implementation PR, it uses the direct `approved` → `implemented` path and
  does not change the PLAN to `in-progress`.
* **Rule-6 containment will not machine-check this plan.** The framework gate's
  grandfather clause lists `PLAN-0001-*`–`PLAN-0017-*` and skips those plan IDs
  by name at every status — not merely at `draft` — so no containment error on
  this plan will be caught mechanically until `conventional-agents`
  issue #195 (scoping the clause to the framework's self-check) is fixed. The
  plan therefore rests on human review and the trailered approval record
  (`ADR-0026`) for containment discipline; it does not claim the
  machine check as evidence.

## 8. Validation

* Tests expected to pass:

  * The full `tests/` suite, run by `npm test` (pytest) and by
    `engine-tests.yml` in CI.
  * The repository gates: `npm run check:status` and `npm run lint:all`.

* Manual checks:

  * One dry-run pass against a scratch clone with a fake substrate and the
    fake runtime: no real GitHub writes; the pass stops at each gate for the
    expected reason.
  * The worker credential probe run against the real configured worker
    boundary before any unattended dispatch is enabled.

## 9. Explicit Non-Changes

* `config/gates.yml`, `AGENTS.md`, `vendor/conventional-agents/` (no
  submodule bump), `.github/workflows/governance.yml` and
  `.github/workflows/attribution.yml`.
* No change to ADR-0047/ADR-0048 text.
* No new dependencies beyond `pytest` (dev) and the Python standard library;
  the HTTP/substrate access uses the installed `gh` CLI as the framework's
  own tooling does, not a new SDK.

## 10. Readiness Check

* [ ] FS-0051 is approved with the amended interface surface (PR #15 merged)
* [ ] Tests exist or are clearly defined — §3, one per Success Criterion
* [ ] Scope is minimal and explicit — the pilot slice only
* [ ] Execution is constrained to one implementation PR using the documented
      direct `approved` → `implemented` transition; no intermediate
      `in-progress` status commit is planned
* [ ] No architectural changes implied — implementation follows ADR-0047/
      ADR-0048; new decisions go to a new ADR first
* [ ] **Human approval required.** `touches:` includes reserved paths
      (`.github/workflows/`, `package.json`), so self-approval is impossible
      by construction. `approved_by:` and its `Approved-By:` trailer are to
      be recorded at approval time, not before.

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
