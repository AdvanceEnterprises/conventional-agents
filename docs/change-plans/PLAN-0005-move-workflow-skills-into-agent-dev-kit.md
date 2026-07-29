---
type: change-plan
role: implementer
language: python
status: deprecated
related_specs: [FS-0002]
related_adrs: [ADR-0001, ADR-0002]
created: 2026-02-05
updated: 2026-07-29
---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- Fill in all sections succinctly.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0002
- Related ADR ID(s): ADR-0001, ADR-0002
- Issue / PR Reference: TBD

## 2. Scope of Change

**Deprecated 2026-07-29. This plan will not be executed.** Its governing spec
`FS-0002` is deprecated; see that document's Status section for the verification —
none of the ten skills has ever existed on any branch, and the source workspace this
plan reads from is no longer reachable.

Two reasons it could not be resumed as written even if the source were recovered:

- §4 below states the file list "will be finalized during implementation". `ADR-0027`
  requires a bounded `touches:` set declared before approval; this plan predates that
  rule and does not satisfy it. It would have to be rewritten, not restarted.
- The tests in §3 target Python helper scripts that were never written, in a language
  (`language: python`) this repository has otherwise not adopted for tooling.

The original scope is preserved unchanged below as the record of what was planned.

---

This change WILL:

- Add the workflow skill modules (currently in this OpenClaw workspace under `skill-src/`) into the `conventional-agents` repository under `skills/{name}/`.
- Add/maintain a canonical `skills/index.md` in `conventional-agents` listing and describing these skills.
- Refactor generator/helper scripts so template/path discovery is dual-mode:
  - Works inside the `conventional-agents` repo (templates resolved from `./templates/...`).
  - Works in a host repo that vendors conventional-agents (templates resolved from `./vendor/conventional-agents/templates/...`).
- Update documentation (likely `INTEGRATION.md` and/or `skills/index.md`) to describe the canonical paths and invocation model.

This change will NOT:

- Add network access or external service calls.
- Publish the skills to a marketplace.
- Introduce new role contracts or change universal gates.
- Add CI to run the Python helper scripts.

## 3. Tests Driving This Change

Primary checks are self-tests built into each helper script.

- Target checks (mapped to FS-0002 Success Criteria):
  - test_sc_1__skills_exist_under_skills_dir
  - test_sc_2a__self_tests_pass_inside_agent_dev_kit
  - test_sc_2b__self_tests_pass_from_host_repo_with_vendor_submodule
  - test_sc_3__skills_index_lists_all_moved_skills
  - test_sc_4__integration_docs_include_backward_compat_guidance
  - test_sc_5__python_self_tests_do_not_require_node

## 4. Files to Be Modified

(Exact list will be finalized during implementation; scope constrained to these areas.)

- `skills/index.md` (create or update)
- `skills/{skill-name}/SKILL.md` (create)
- `skills/{skill-name}/*.py` (create; for skills that include helper scripts)
- `INTEGRATION.md` (update: how to run the skills from host repos)
- Possibly: `README.md` (small pointer to skills index)

## 5. Implementation Steps (High-Level)

1. Inventory the current set of workflow skills in `skill-src/` and map them 1:1 to `conventional-agents/skills/{name}/` directories.
2. Create `skills/index.md` (or expand it) to include each skill with:
   - purpose
   - paths
   - primary invocation command
   - safety notes (local-only; overwrite rules)
3. For each skill that has a Python helper:
   - Move or copy the script into `skills/{name}/`.
   - Implement a shared repo-root discovery function that:
     - detects when running inside conventional-agents (find `.git` + `templates/`), OR
     - detects when running from host repo (find `vendor/conventional-agents/templates/`).
   - Ensure `--self-test` succeeds in both contexts.
4. Update each moved `SKILL.md` to reference the new canonical paths (no workspace-relative `skill-src/...` paths).
5. Update `INTEGRATION.md` (and any other relevant docs) with:
   - the dual-mode invocation model
   - examples for both contexts
6. Validation pass:
   - Run all `--self-test` commands from inside conventional-agents.
   - Run at least one representative `--self-test` from a simulated host repo directory structure.

## 6. Constraints and Guardrails

- FS-0002 Non-Goals / Out of Scope are hard constraints.
- ADR-0001/ADR-0002 filesystem contract must remain valid for consumers vendoring conventional-agents.
- Scripts must remain low-risk: local filesystem only, explicit overwrite behavior.

## 7. Risks and Edge Cases

- Ambiguous repo root detection when both `templates/` and `vendor/conventional-agents/templates/` exist in the same tree.
- Consumers relying on the OpenClaw workspace `skill-src/` layout (we need docs guidance; no breaking changes promised there).

## 8. Validation

- Expected to pass:
  - All generator scripts `--self-test` pass when executed from inside conventional-agents.
  - All generator scripts `--self-test` pass when executed from a host repo that vendors conventional-agents.
  - `skills/index.md` includes all moved skills.

- Manual checks:
  - Confirm path discovery works when running scripts from a nested cwd.

## 9. Explicit Non-Changes

- No changes to existing ADR markdownlint CI/scaffolding.
- No changes to role contracts/guidelines content beyond adding skill documentation pointers.
- No new CI workflows.

## 10. Readiness Check

- [x] FS-0002 is approved
- [x] Skill list and destinations are finalized
- [x] Dual-mode path discovery approach is specified
- [x] Validation steps are explicit and runnable

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation for FS-0002.
- Any deviation (e.g., adding CI, adding networked behavior, changing role contracts) will require revising this plan first.
