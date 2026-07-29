---

type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0020]
related_adrs: [ADR-0012, ADR-0013, ADR-0024, ADR-0026, ADR-0027, ADR-0030, ADR-0031]
touches:
  - workflows/sdlc-single-model.md
  - workflows/sdlc-multi-model.md
  - workflows/session-modes.md
  - test/FS-0020/sdlc-workflows.bats
  - README.md
  - AGENTS.md
  - INTEGRATION.md
created: 2026-07-28
updated: 2026-07-28

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0020
* Related ADR ID(s): ADR-0012, ADR-0013, ADR-0024, ADR-0026, ADR-0027,
  ADR-0030, ADR-0031
* Issue / PR Reference: PR #71

## 2. Scope of Change

**This change WILL:**

* Author `workflows/sdlc-single-model.md` and
  `workflows/sdlc-multi-model.md` as the current-state documents for the
  two workflows.
* Cross-reference both from `workflows/session-modes.md`.
* Add `test/FS-0020/sdlc-workflows.bats`.
* Reference both workflows from `README.md` and `AGENTS.md`.
* Add workflow-selection guidance to `INTEGRATION.md`.

**This change will NOT:**

* Introduce roles, session modes, or meta-modes.
* Define concurrent role-holders on one artifact.
* Assign models to roles.
* Modify `guidelines/ROLE_CONTRACT.md`. The workflows compose the roles;
  they do not redefine them.
* Modify `workflows/document-lifecycle.md`. Phase gates reference its
  statuses without changing them.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0020/sdlc-workflows.bats`

* Target test(s):

  * `test_spine__both_workflows_name_seven_phases`
  * `test_spine__leading_role_matches_across_workflows`
  * `test_gates__fs_approval_stated_human_in_both`
  * `test_gates__merge_stated_human_in_both`
  * `test_gates__draft_spec_not_implementable_in_both`
  * `test_single_model__collaboration_rounds_excluded`
  * `test_single_model__exclusion_cites_adr_0023`
  * `test_multi_model__declares_touches_as_artifact_scope`
  * `test_multi_model__collaboration_placements_named`
  * `test_handoff__contract_table_present`
  * `test_neutrality__no_platform_nouns`

These assert the *documents*, not runtime behaviour — the workflows are
prose, and what is checkable is that both state the same spine, the same
gates, and the same role-per-phase mapping. Divergence between the two
documents is the defect this suite exists to catch.

## 4. Files to Be Modified

* `workflows/sdlc-single-model.md` (new)
* `workflows/sdlc-multi-model.md` (new)
* `workflows/session-modes.md`
* `test/FS-0020/sdlc-workflows.bats` (new)
* `README.md`
* `AGENTS.md`
* `INTEGRATION.md`

## 5. Implementation Steps (High-Level)

1. Write the bats suite first. The cross-document consistency assertions
   are the point: extract the phase table from each workflow document and
   compare them, rather than asserting each independently.
2. Author `workflows/sdlc-single-model.md`: the seven phases, role per
   phase, exit gate per phase, and the stance-change model for role
   transitions. State the collaboration exclusion and why it is a
   capability limit rather than a configuration one.
3. Author `workflows/sdlc-multi-model.md`: the same spine, plus handoff
   through artifacts, the ADR-0013 Mode 1 scope declaration, the
   disjoint-`touches:` concurrency rule, and the four collaboration
   placements.
4. Add a short section to `workflows/session-modes.md` positioning it
   relative to the two workflows — modes describe role stance *within* a
   phase; the workflows describe the phase sequence.
5. Add a workflows section to `README.md` and a pointer in `AGENTS.md`.
6. Add workflow-selection guidance to `INTEGRATION.md`: single-model when
   one model is available or collaboration is not wanted; multi-model
   otherwise.
7. Set FS-0020 and this PLAN to `implemented` in the completing PR.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0020 Non-Goals and Out of Scope. No new roles, no concurrent
    role-holders, no model assignment, no platform nouns.

* ADR constraints:

  * ADR-0013 — the spine is sequential per artifact because parallel
    primaries must not touch the same artifact. Do not describe a
    workflow that permits it.
  * ADR-0031 — collaboration rounds are fan-out *within* a phase. Do not
    describe them as phases.
  * ADR-0023 — the single-model exclusion follows from the
    different-models requirement. State it as derived, not as a rule of
    its own.
  * ADR-0012 and ADR-0026 — the human gates are stated identically in
    both documents.
  * ADR-0024 — no platform nouns in either workflow document.
  * ADR-0030 — these two documents are current-state. They state what to
    do; FS-0020 and the ADRs state why.

* Architecture constraints:

  * The two documents must not drift. Where they say the same thing, they
    must say it the same way, and the bats suite enforces it.

## 7. Risks and Edge Cases

* **Divergence between the two documents is the main risk.** They share
  five of seven table columns. Consider generating the shared spine
  section from one source rather than maintaining two copies — a
  judgment call for the implementer, but duplication here will rot.
* A reader may treat the seven phases as requiring seven PRs. Both
  documents must state that phases are ordering constraints on the work,
  not a PR granularity rule.
* `test_required: false` skips phase 4. The documents must say an absent
  field is not a false one.
* The multi-model document risks reading as though it requires several
  models simultaneously. It does not — models occupy roles in sequence;
  only collaboration rounds are concurrent.

## 8. Validation

* Tests expected to pass:

  * All of `test/FS-0020/sdlc-workflows.bats`.
  * `npm run lint:docs`, which covers `workflows/*.md`.
  * `npm run check:status`.

* Manual checks:

  * Read both documents end to end and confirm the phase tables are
    identical in phases, roles, and gates.
  * Confirm neither contains a platform noun (`grep -i github`).

## 9. Explicit Non-Changes

* `guidelines/ROLE_CONTRACT.md` — role definitions, prohibitions, and the
  Docs → Tests → Code ordering.
* `workflows/document-lifecycle.md` — document statuses and transitions.
* `workflows/git-and-gh-conventions.md`.
* FS-0018's work item phases. The SDLC phases sit above them and are a
  different axis; the documents must not conflate the two.

## 10. Readiness Check

* [x] FS-0020 is approved
* [x] Tests are clearly defined — §3
* [x] Scope is minimal and explicit
* [x] No architectural changes implied
* [x] **Human approval given.** `touches:` includes `README.md`,
      `AGENTS.md`, and `INTEGRATION.md`, which fall outside FS-0020's
      declared `interfaces:`. Under ADR-0027 this PLAN cannot
      self-approve. Either a human approves it, or FS-0020's
      `interfaces:` is widened to cover them before approval — the first
      is correct, since those three are consumer-facing surface.
