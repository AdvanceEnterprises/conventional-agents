---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs: [FS-0019, FS-0018]
related_adrs: [ADR-0023, ADR-0022, ADR-0018, ADR-0012]
created: 2026-07-27
updated: 2026-07-27
---

# Change Plan: Implement FS-0019 Multi-Model Consensus at Workflow Gates

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0019 (primary), FS-0018 (dependency — consensus gates
  integrate with the Issue lifecycle)
- Related ADR ID(s): ADR-0023 (consensus integrity constraints), ADR-0022 (meta-modes);
  composes with ADR-0018 (attribution) and ADR-0012 (merge gate)
- Issue / PR Reference: PR #71 (bootstrap package)

## 2. Scope of Change

**This change WILL:**

- Add a "Multi-model consensus (optional)" section to `INTEGRATION.md` describing how
  a consumer repo opts in, copies `config/consensus.yml`, and wires its own
  orchestration.
- Add a consensus-round section to `skills/git-gh-workflow/SKILL.md` covering round
  initiation, the `mode=consensus` stance declaration, and the audit artifact path.
- Document the consensus gates in `workflows/document-lifecycle.md` as optional,
  consumer-implemented checkpoints at Gate A (pre-submission) and Gate B
  (review-time), explicitly marked disabled by default.
- Add the consensus-round PR/Issue comment conventions to
  `workflows/git-and-gh-conventions.md`, including the `consensus-override:` comment
  form.
- Add `consensus_required` to the front-matter field list in
  `templates/core/feature-spec.md` and `templates/core/change-plan.md` as an optional
  per-document override.
- Add a `README.md` pointer to the consensus feature, stated as optional and
  off by default.
- Update `docs/decisions/README.md` with an index row for ADR-0023.
- Update `docs/change-plans/README.md` with an index row for this PLAN.

**This change will NOT:**

- Implement consensus orchestration. The framework ships vocabulary, artifact shape,
  gate placement, and configuration schema. Consumer repos implement the machinery
  that invokes models and compares outputs (FS-0019 Non-Goals).
- Enable consensus anywhere in the framework. Per ADR-0023, `config/consensus.yml`
  ships disabled and the framework's own evolution does not use consensus.
- Create a `docs/consensus/` directory in this repository. Its absence is an
  ADR-0023 validation signal.
- Define a consensus algorithm. The framework describes behavior shape, not
  majority-vote, weighted-vote, or judge-model mechanics.
- Add CI enforcement of consensus. There is nothing framework-side to enforce.
- Resolve FS-0019's Open Questions (override authority, drafter-vs-reviewer default,
  transcript logging depth, cross-gate rounds). Those remain open in the spec.

## 3. Tests Driving This Change

`test_required: true` per FS-0019. Validation is via:

- `test/FS-0019/consensus-schema.bats` (already present on this branch) — asserts the
  spec declares consensus disabled by default, the different-models requirement, three
  failure modes, two gates, the artifact schema, escalation behavior, the
  `config/consensus.yml` all-defaults state, per-gate configuration, an empty models
  list, the FS-0018/ADR-0018 dependencies, the Plan Status section, the test-harness
  note, and the same-model prohibition.
- `npm run check:status` — FS/PLAN status pairing and README index sync.
- `npm run lint:docs` — markdownlint across ADRs, specs, plans, workflows.

Per FS-0019's own test-harness note, the framework's tests verify schema and
structural rules only. End-to-end consensus behavior is validated by fixture-based
tests in a consumer repo, not here.

## 4. Files to Be Modified

- `INTEGRATION.md` (modify — add "Multi-model consensus (optional)" section)
- `skills/git-gh-workflow/SKILL.md` (modify — add consensus-round initiation and audit
  trail section)
- `workflows/document-lifecycle.md` (modify — document Gate A and Gate B as optional,
  default-disabled checkpoints)
- `workflows/git-and-gh-conventions.md` (modify — add consensus comment conventions
  including `consensus-override:`)
- `templates/core/feature-spec.md` (modify — add optional `consensus_required` field)
- `templates/core/change-plan.md` (modify — add optional `consensus_required` field)
- `README.md` (modify — add optional-feature pointer)
- `docs/decisions/ADR-0023-consensus-integrity-constraints.md` (new)
- `docs/decisions/README.md` (modify — add ADR-0023 row)
- `docs/change-plans/PLAN-0019-implement-fs-0019-multi-model-consensus.md` (new —
  this file)
- `docs/change-plans/README.md` (modify — add PLAN-0019 row)
- `docs/specifications/FS-0019-multi-model-consensus.md` (modify — update the Plan
  Status section to reference this PLAN)

Already landed on this branch, not re-touched by this plan:

- `config/consensus.yml` (consumer-copy template, ships disabled)
- `test/FS-0019/consensus-schema.bats`
- `workflows/session-modes.md` (meta-modes section, includes `consensus`)
- `docs/specifications/README.md` (FS-0019 row)

## 5. Implementation Steps (High-Level)

1. **Author ADR-0023** — ratify the two binding constraints FS-0019 flags: the
   different-models requirement is non-overridable, and consensus ships disabled.
2. **Update `workflows/document-lifecycle.md`** — document Gate A and Gate B as
   optional consumer checkpoints, clearly marked default-disabled, positioned relative
   to the existing status transitions without altering them.
3. **Update `skills/git-gh-workflow/SKILL.md`** — teach agents how a consensus round
   is initiated, how to declare `mode=consensus` composed with a role per ADR-0022,
   and where the round artifact is written.
4. **Update `workflows/git-and-gh-conventions.md`** — add the consensus comment
   conventions, including `consensus-override: <reason>` and the disagreement-recording
   form.
5. **Add `consensus_required` to the FS and PLAN templates** — as an optional
   front-matter field, documented as a per-document override that can enable consensus
   but cannot relax the different-models constraint.
6. **Update `INTEGRATION.md`** — add the consumer opt-in section: copy
   `config/consensus.yml`, populate `models` with at least two distinct identifiers,
   enable the desired gates, implement orchestration.
7. **Update `README.md`** — one pointer, stated as optional and off by default.
8. **Update FS-0019's Plan Status section** — replace "Not yet drafted" with a
   reference to this PLAN.
9. **Update indexes** — `docs/decisions/README.md`, `docs/change-plans/README.md`.
10. **Run `npm run check:status` and `npm run lint:docs`** — verify no regressions.
11. **Run `test/FS-0019/consensus-schema.bats`** — verify the schema assertions hold.
12. **Commit with attribution** — per ADR-0018, each commit carries the actor
    `user.email` and an `Agent-Attribution:` trailer.

## 6. Constraints and Guardrails

- FS-0019 Non-Goals are hard constraints: no orchestration implementation, no
  framework-level consensus adoption, no algorithm definition, no cross-repo consensus,
  no cost/latency optimization.
- Per ADR-0023, no document may describe the different-models requirement as
  configurable, and no document may show `config/consensus.yml` shipping enabled.
- Per ADR-0022, `consensus` must not be introduced as a session mode. It is a
  meta-mode composed with a declared role.
- `config/consensus.yml` must not be modified for framework development. It is a
  consumer-copy template; its all-defaults state is asserted by the bats suite.
- No `docs/consensus/` directory may be created in this repository.
- ADR-0012's merge gate is unweakened. A passing consensus round does not authorize a
  merge; merging remains human-only.
- `npm run check:status` and `npm run lint:docs` must pass before the PR is marked
  ready.

## 7. Risks and Edge Cases

- **The framework ships a feature it cannot enforce.** Consensus correctness lives
  entirely in consumer implementations. A consumer whose orchestration violates
  ADR-0023 produces a non-compliant artifact that the framework cannot detect. The
  documentation must be explicit that the framework supplies the contract and the
  consumer supplies the compliance.
- **Untested by dogfooding.** Because the framework does not enable consensus, gaps in
  the artifact schema or gate placement will surface only when a consumer adopts the
  feature. This is an accepted consequence of ADR-0023's default-disabled decision.
- **`consensus_required` interacts with the ADR-0023 constraint.** The per-document
  override can turn consensus on for a specific artifact; it cannot relax
  different-models. Template documentation must state this or a consumer may assume
  the override is a general escape hatch.
- **Gate placement versus the Issue lifecycle.** Gate A and Gate B are described
  relative to both the FS/PLAN status machine and FS-0018's Issue Status. Consumers
  need both framings; the documentation must not conflate them.
- **Escalation loops.** FS-0019 defines a default depth of 3 before an escalation
  chain converts to `hard_block`. This is consumer-configured; documentation should
  flag that an unbounded value risks an infinite loop.
- **Vocabulary drift with PR #71's description.** The PR body refers to
  "consensus cohort" and "review_panel cohort"; the spec text on this branch uses
  "consensus round" and "participant". This plan follows the spec text. If the cohort
  vocabulary is intended, FS-0019 needs a revision pass first and this plan must be
  updated to match.

## 8. Validation

- `npm run check:status` passes.
- `npm run lint:docs` passes (ADRs, specs, plans, workflows).
- `test/FS-0019/consensus-schema.bats` passes.
- `config/consensus.yml` is unmodified and still ships `enabled: false` with
  `models: []`.
- No `docs/consensus/` directory exists in this repository.
- `INTEGRATION.md` contains the opt-in section and states the default is off.
- ADR-0023 exists with `status: proposed` and appears in `docs/decisions/README.md`.
- No document describes the different-models requirement as configurable.
- No document introduces `consensus` as a session mode.

## 9. Explicit Non-Changes

- `config/consensus.yml` is not modified. It landed earlier on this branch as a
  consumer-copy template.
- `workflows/session-modes.md` is not modified by this plan.
- The FS/PLAN/ADR status state machine in `workflows/document-lifecycle.md` is
  unchanged; consensus gates are documented alongside it, not inserted into it.
- ADR-0012 and ADR-0018 are unchanged.
- No CI workflow, `package.json` script, or `scripts/` gate is added or modified.
- FS-0019's Open Questions are not answered by this plan.

## 10. Readiness Check

- [ ] FS-0019 is approved (currently `draft` — this PLAN cannot be approved until
      FS-0019 is)
- [ ] FS-0018 is approved (FS-0019 `requires: [FS-0018]`; the dependency must land
      first)
- [x] Tests exist and are clearly defined (`test/FS-0019/consensus-schema.bats`)
- [x] Scope is minimal and explicit (seven documents modified, three new)
- [x] Binding decisions are ratified as an ADR (ADR-0023)
- [ ] Cohort-versus-round vocabulary confirmed (see §7 — spec text and PR #71
      description diverge)

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
