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
  - docs/proposals/hermes-kanban-substrate-binding.md
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

- Keep the incomplete candidate in `docs/proposals/hermes-kanban-substrate-binding.md`
  while proving the six `ADR-0024` capabilities against Hermes kanban.
- Only after conformance is demonstrated, publish `integrations/hermes-kanban.md`
  and list it in `integrations/README.md` as the second substrate binding.
- Extend `test/FS-0038/hermes-kanban-binding.bats` to verify the binding
  against the live CLI and guard against publishing an incomplete candidate.
- Keep the FS-0038 / PLAN-0044 index rows aligned with their draft statuses.
- Add a consumer-framed `CHANGELOG.md` entry when the binding is published.

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

- `docs/proposals/hermes-kanban-substrate-binding.md` (internal candidate)
- `integrations/hermes-kanban.md` (future publication, contingent on conformance)
- `integrations/README.md`
- `docs/specifications/FS-0038-hermes-kanban-substrate-binding.md`
- `docs/specifications/README.md`
- `docs/change-plans/README.md`
- `test/FS-0038/hermes-kanban-binding.bats`
- `CHANGELOG.md`

## 5. Implementation Steps (High-Level)

1. Retain the incomplete mapping in `docs/proposals/`, not `integrations/`.
2. Prove Type-change attribution, human authorization before dispatch, parked-state
   suppression, and non-retractable transition records with tests and a stated threat model.
3. Publish a complete mapping in `integrations/hermes-kanban.md` only when every
   `ADR-0024` capability is supported. Then update `integrations/README.md`.
4. Run status, lint, and the relevant isolated Bats tests before proposing adoption.

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

Future implementation touches `integrations/` (exported surface), but this
relocation only withdraws a premature candidate from that surface. The plan
does not touch the reserved paths under `ADR-0027` (`.github/workflows/`,
`package.json`, `scripts/`, etc.). FS-0038 and PLAN-0044 remain draft; only
a human can approve them under `ADR-0026`.

The internal proposal and tests are examples, not evidence of complete
conformance. Implementation follows after FS-0038 / PLAN-0044 are approved
and the Type attribution and event-retention questions are resolved.

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
