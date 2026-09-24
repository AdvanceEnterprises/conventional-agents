---

type: change-plan
role: implementer
language: n/a
status: draft
related_specs:
  - FS-0038
related_adrs:
  - ADR-0024
  - ADR-0039
# consensus_required: false
touches:
  - integrations/hermes-kanban.md
  - integrations/README.md
  - docs/specifications/FS-0038-hermes-kanban-substrate-binding.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - test/FS-0038/hermes-kanban-binding.bats
  - CHANGELOG.md
created: 2026-09-23
updated: 2026-09-23

---

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0038
- Related ADR ID(s): ADR-0024, ADR-0039
- Issue / PR Reference: new binding under ADR-0024; no prior issue

## 2. Scope of Change

**This change WILL:**

- Add `integrations/hermes-kanban.md`, the second substrate binding alongside the GitHub binding.
- Map the six `ADR-0024` capabilities onto Hermes Agent `kanban` CLI and worker toolset commands.
- Update `integrations/README.md` to list the Hermes kanban binding.
- Add `test/FS-0038/hermes-kanban-binding.bats` to verify the binding against the live CLI.
- Update `docs/specifications/README.md` and `docs/change-plans/README.md` with FS-0038 / PLAN-0044 rows.
- Add a consumer-framed `CHANGELOG.md` entry because the change touches the exported surface (`integrations/`).

**This change will NOT:**

- Implement a sync between Hermes kanban and GitHub Issues/Projects.
- Modify the framework's default substrate or CI workflow.
- Add new Hermes CLI verbs or change the kanban SQLite schema.
- Implement the Hermes runtime binding (that remains a separate FS/PLAN under ADR-0039).

## 3. Tests Driving This Change

- Test file(s):
  - `test/FS-0038/hermes-kanban-binding.bats`
- Target test(s):
  - `hermes kanban boards create` creates an isolated board.
  - `hermes kanban create` creates a prefixed task and returns a task ID.
  - `hermes kanban claim` atomically moves a ready task to running.
  - `hermes kanban block` parks a task and records a reason.
  - `hermes kanban list --json` enumerates task status and title; Type is derived from the prefix.
  - Binding document passes `npm run lint:docs`.

## 4. Files to Be Modified

- `integrations/hermes-kanban.md` (new)
- `integrations/README.md`
- `docs/specifications/FS-0038-hermes-kanban-substrate-binding.md` (new)
- `docs/specifications/README.md`
- `docs/change-plans/README.md`
- `test/FS-0038/hermes-kanban-binding.bats` (new)
- `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

1. Draft `integrations/hermes-kanban.md` mirroring the GitHub binding's structure and conformance table.
2. Add the FS and PLAN documents with `status: draft`.
3. Create bats tests that probe the `hermes kanban` CLI surface without mutating the real repo.
4. Update the three README indexes.
5. Run `npm run check:status` and `npm run lint:docs` locally.
6. Open a PR for human review and approval of the spec/plan.
7. After merge, open a second PR to implement the binding document and tests, flipping statuses to `implemented`.

## 6. Constraints and Guardrails

- Spec constraints:
  - `FS-0038` Non-Goals: no GitHub sync, no new Hermes CLI verbs, no runtime config.
  - Out of Scope: cross-tenant hosting, GitHub bridge.
- ADR constraints:
  - `ADR-0024`: bindings written first and in full; core capabilities must all map.
  - `ADR-0028`: enumerability is the correctness guarantee; do not rely solely on events.
  - `ADR-0039`: runtime setup is a separate binding category from work tracking.
- Architecture constraints:
  - Exported-surface docs must be consumer-framed.
  - No enforcement claims where only detection is available, and vice versa.

## 7. Approval Routing

This PLAN touches `integrations/` (exported surface) but not the reserved paths
under `ADR-0027` (`.github/workflows/`, `package.json`, `scripts/`, etc.). However,
it also adds a new FS and PLAN, which are governance documents. Approval of the
FS/PLAN PR is a human act recorded by an `Approved-By:` trailer on the merge
commit per `ADR-0026`.

The binding draft and tests in this PR are proposed examples, not evidence of
complete conformance. Implementation follows after FS-0038 / PLAN-0044 are
approved and the Type attribution and event-retention questions are resolved.

## 8. Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| `hermes kanban` CLI flags differ by version | Tests probe flags documented in the installed Hermes; skip tests if `hermes kanban` is absent. |
| Tests create local SQLite state | Isolate `HERMES_HOME` to a temporary directory; never invoke the real board. |
| Binding overlaps with future Hermes runtime binding | Keep this binding focused on work-tracking substrate; runtime setup stays under `ADR-0039`. |

## 9. Open Questions

- Should the binding document also define a kanban board layout recommendation
  (column order, field names) or leave that to consumer convention?
- Do we want a sample `config/project.yml` or skill file that teaches an agent
  how to operate the Hermes kanban binding?
