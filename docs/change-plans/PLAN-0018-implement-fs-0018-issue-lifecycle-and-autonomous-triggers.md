---
type: change-plan
role: implementer
language: markdown
status: approved
related_specs: [FS-0018]
related_adrs: [ADR-0019, ADR-0020, ADR-0021, ADR-0022, ADR-0012, ADR-0018]
created: 2026-07-27
updated: 2026-07-27
---

# Change Plan: Implement FS-0018 Issue Lifecycle and Autonomous Triggers

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0018
- Related ADR ID(s): ADR-0019 (Type immutability + autonomous gate), ADR-0020
  (`question` suppression), ADR-0021 (cron actor identity), ADR-0022 (meta-modes);
  composes with ADR-0012 (merge gate) and ADR-0018 (attribution layers)
- Issue / PR Reference: PR #71 (bootstrap package)

## 2. Scope of Change

**This change WILL:**

- Insert the Issue layer into `workflows/document-lifecycle.md` as the canonical
  entry point for governed work, positioned above the existing FS/PLAN/ADR state
  machine (which is unchanged).
- Add the three-axis Issue schema (Type, Label, Status) and the three origination
  paths to `workflows/document-lifecycle.md`.
- Add the `agent-stance:` comment format and the autonomous-gate rules to
  `skills/git-gh-workflow/SKILL.md`.
- Add an Issue-stance comment section to `workflows/git-and-gh-conventions.md`,
  including the cron actor identity rows from ADR-0021.
- Reference `agent-stance:` in `guidelines/ROLE_CONTRACT.md` as the autonomous
  equivalent of the interactive role-transition phrase.
- Add a "Multi-agent and autonomous operation" pointer to `AGENTS.md` and `README.md`
  referencing FS-0018 and the Issue lifecycle.
- Add a consumer-onboarding section to `INTEGRATION.md` describing how a consumer repo
  configures its Issue Type field, labels, and project board Status column to match
  the schema.
- Update `docs/decisions/README.md` with index rows for ADR-0019 through ADR-0022.
- Update `docs/change-plans/README.md` with an index row for this PLAN.

**This change will NOT:**

- Implement webhook handlers. Consumer repos implement these; the framework describes
  required behavior only (FS-0018 Non-Goals).
- Implement cron scheduling or detection logic. Project-level configuration.
- Add a sixth session mode. Per ADR-0022, `autonomous` is a meta-mode composed with a
  declared role, not a new session mode. `workflows/session-modes.md` already carries
  the meta-mode section (landed earlier on this branch).
- Implement multi-model consensus. See FS-0019 and PLAN-0019.
- Migrate existing Issues to the new schema. New Issues follow the schema; legacy
  Issues are not retroactively reclassified (FS-0018 Out of Scope).
- Add CI enforcement of the Issue schema. The framework has no access to a consumer's
  Issue tracker.

## 3. Tests Driving This Change

`test_required: true` per FS-0018. Validation is via:

- `test/FS-0018/issue-lifecycle.bats` (already present on this branch) — asserts the
  three-axis schema, six labels, three Types, five Status values, the agent-stance
  regex against positive and negative cases, enumerated mode values, Type
  human-mutability, the autonomous gate, the three origination paths, ADR
  dependencies, the Plan Status section, the cron-identity blocker, and the FS-0019
  cross-reference.
- `npm run check:status` — FS/PLAN status pairing and README index sync.
- `npm run lint:docs` — markdownlint across ADRs, specs, plans, workflows.

The bats suite was written against FS-0018's success criteria and covers the spec's
structural assertions. Behavioral criteria that describe consumer-repo runtime
behavior (webhook rejection, Status transition enforcement) are not framework-testable
and are validated by the consumer's own harness.

## 4. Files to Be Modified

- `workflows/document-lifecycle.md` (modify — insert the Issue layer above the
  FS/PLAN/ADR state machine)
- `workflows/git-and-gh-conventions.md` (modify — add Issue-stance comment section and
  ADR-0021 cron actor rows)
- `skills/git-gh-workflow/SKILL.md` (modify — add agent-stance format and
  autonomous-gate rules)
- `guidelines/ROLE_CONTRACT.md` (modify — reference `agent-stance:` in the Role and
  session transparency section)
- `AGENTS.md` (modify — add pointer to the Issue lifecycle)
- `README.md` (modify — index the Issue lifecycle and autonomous triggers)
- `INTEGRATION.md` (modify — add consumer Issue-configuration section)
- `docs/decisions/ADR-0019-issue-type-immutability-and-autonomous-gate.md` (new)
- `docs/decisions/ADR-0020-question-label-suppression.md` (new)
- `docs/decisions/ADR-0021-cron-actor-identity.md` (new)
- `docs/decisions/ADR-0022-autonomous-and-consensus-meta-modes.md` (new)
- `docs/decisions/README.md` (modify — add ADR-0019 through ADR-0022 rows)
- `docs/change-plans/PLAN-0018-implement-fs-0018-issue-lifecycle-and-autonomous-triggers.md`
  (new — this file)
- `docs/change-plans/README.md` (modify — add PLAN-0018 row)
- `docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md` (modify —
  update the Plan Status section to reference this PLAN)

Already landed on this branch, not re-touched by this plan:

- `workflows/session-modes.md` (meta-modes section)
- `test/FS-0018/issue-lifecycle.bats`
- `docs/specifications/README.md` (FS-0018 row)

## 5. Implementation Steps (High-Level)

1. **Author ADR-0019 through ADR-0022** — ratify the four binding decisions FS-0018
   states as proposed defaults: Type immutability plus the autonomous gate,
   `question` suppression, cron actor identity, and the meta-mode distinction.
2. **Update `workflows/document-lifecycle.md`** — insert the Issue layer as the entry
   point, with the three-axis schema and three origination paths. Leave the existing
   FS/PLAN/ADR state machine unchanged; the Issue layer sits above it.
3. **Update `skills/git-gh-workflow/SKILL.md`** — teach agents the `agent-stance:`
   comment format, the label-set precondition check from ADR-0020, and the
   Type-keyed checkpoints from ADR-0019.
4. **Update `workflows/git-and-gh-conventions.md`** — add the Issue-stance comment
   section and extend the actor table with ADR-0021's unattended-actor rows.
5. **Update `guidelines/ROLE_CONTRACT.md`** — reference `agent-stance:` as the
   autonomous equivalent of the role-transition phrase in the Role and session
   transparency section.
6. **Update `AGENTS.md`, `README.md`, and `INTEGRATION.md`** — surface the Issue
   lifecycle to agents, to readers, and to consumer repos respectively.
7. **Update FS-0018's Plan Status section** — replace "Not yet drafted" with a
   reference to this PLAN.
8. **Update indexes** — `docs/decisions/README.md`, `docs/change-plans/README.md`.
9. **Run `npm run check:status` and `npm run lint:docs`** — verify no regressions.
10. **Run `test/FS-0018/issue-lifecycle.bats`** — verify the spec's structural
    assertions hold after the doc updates.
11. **Commit with attribution** — per ADR-0018, each commit carries the actor
    `user.email` and an `Agent-Attribution:` trailer.

## 6. Constraints and Guardrails

- FS-0018 Non-Goals are hard constraints: no webhook implementation, no cron
  scheduling, no new session mode, no consensus, no board-structure mandate.
- `workflows/document-lifecycle.md`'s existing FS/PLAN/ADR state machine must not be
  modified. The Issue layer is additive and sits above it.
- ADR-0012's merge gate is untouched and unweakened. ADR-0019's autonomous gate
  composes with it; neither replaces the other.
- Per ADR-0022, `autonomous` must not be introduced as a sixth session mode anywhere
  in the docs. It is a meta-mode composed with a declared role.
- ADR-0019 and ADR-0020 must be described as convention-level at the framework layer.
  The framework cannot technically enforce Issue-metadata rules; consumer repos may.
- `npm run check:status` and `npm run lint:docs` must pass before the PR is marked
  ready.

## 7. Risks and Edge Cases

- **Convention-only enforcement.** ADR-0019's Type immutability and ADR-0020's
  `question` suppression are agent-side rules the framework cannot enforce. The audit
  trail is the enforcement mechanism. Documentation must state this plainly so
  consumers do not assume technical guarantees they are not getting.
- **Path 3 remains partially blocked.** ADR-0021 resolves the cron actor identity
  question, unblocking Path 3 at the framework layer. Actual Path 3 operation still
  requires a consumer repo to provision the unattended actor's email alias and token,
  which is outside this plan's scope.
- **Issue Type field mechanism varies by consumer.** FS-0018 recommends a GitHub
  Project single-select field with a title-prefix fallback for repos without Projects.
  `INTEGRATION.md` must document both paths without mandating either.
- **Doc-count growth.** This plan touches seven existing documents. Cross-references
  between them can drift. Step 9's lint run catches formatting drift but not semantic
  drift; a review pass over the cross-references is warranted.
- **FS-0018 Open Questions remain open.** The Type `task` versus `documentation`
  boundary, multi-Issue consolidation, and auto-add behavior are unresolved in the
  spec. This plan implements what is specified and does not invent answers to those
  questions.

## 8. Validation

- `npm run check:status` passes.
- `npm run lint:docs` passes (ADRs, specs, plans, workflows).
- `test/FS-0018/issue-lifecycle.bats` passes.
- `workflows/document-lifecycle.md` contains the Issue layer and the three-axis
  schema, and its FS/PLAN/ADR state machine is byte-unchanged.
- `skills/git-gh-workflow/SKILL.md` contains the `agent-stance:` format and the
  Type-keyed checkpoint table.
- ADR-0019 through ADR-0022 exist with `status: proposed` and appear in
  `docs/decisions/README.md`.
- No document introduces `autonomous` as a sixth session mode.

## 9. Explicit Non-Changes

- `workflows/session-modes.md` is not modified by this plan; its meta-mode section
  landed earlier on this branch.
- The FS/PLAN/ADR status state machine in `workflows/document-lifecycle.md` is
  unchanged.
- ADR-0012 is unchanged. ADR-0018 is unchanged; ADR-0021 extends it by adding actor
  rows in the workflow doc, not by editing the ADR.
- No CI workflow, `package.json` script, or `scripts/` gate is added or modified.
- No consensus machinery. See PLAN-0019.

## 10. Readiness Check

- [ ] FS-0018 is approved (currently `draft` — this PLAN cannot be approved until
      FS-0018 is)
- [x] Tests exist and are clearly defined (`test/FS-0018/issue-lifecycle.bats`)
- [x] Scope is minimal and explicit (seven documents modified, five new)
- [x] Binding decisions are ratified as ADRs (ADR-0019 through ADR-0022)
- [ ] Cron actor provisioning confirmed with the consumer repo (required for Path 3
      operation, not for this PLAN's completion)

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
