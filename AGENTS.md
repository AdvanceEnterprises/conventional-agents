# Agent Instructions: conventional-agents

This repository is the `conventional-agents` framework. It provides governance
documents, role contracts, templates, skills, and workflow patterns for
agentic development. The framework is recursive: it governs itself and is also
vendored by other projects.

## On Entry

1. Load the `role-aware-session` skill.
2. Infer the session mode from the work the human describes.
3. State the mode, primary role, and any supporting roles.
4. Confirm with the human before acting if the mode is unclear.

## Foundation Standards

- `guidelines/ROLE_CONTRACT.md` — role definitions and universal gates
- `INTEGRATION.md` — integration patterns and precedence rules
- `workflows/session-modes.md` — session mode definitions
- `docs/decisions/README.md` — accepted ADRs (binding constraints)

## Multi-agent and autonomous operation

Conventional-agents supports unattended agent operation (cron, webhook, scheduled detection) and
multi-agent collaboration (consensus rounds, review boards). The lifecycle and rules are in
`FS-0018` (work item layer) and `FS-0019` (consensus), and the meta-mode vocabulary in
`workflows/session-modes.md` documents `autonomous`, `consensus`, and `review-board`.

Key references:

- `FS-0018-issue-lifecycle-and-autonomous-triggers.md` — work item schema, three-axis
  classification, three origination paths, agent-stance format, autonomous gate.
- `workflows/document-lifecycle.md` §"Work Items" — lifecycle summary.
- `skills/work-item-stance/SKILL.md` — operational rules for `agent-stance:` entries,
  Type-keyed checkpoints, `question` suppression.
- `ADR-0019`, `ADR-0020`, `ADR-0021`, `ADR-0022` — the binding decisions that ratify these
  rules. Convention-level enforcement on most platforms; audit-trail-based detection
  everywhere.

## Working on the Framework Itself

This repo contains no application code. Quality is documentation-centric.

- ADRs go in `docs/decisions/ADR-XXXX-<slug>.md`.
- Feature specs go in `docs/specifications/FS-XXXX-<slug>.md`.
- Change plans go in `docs/change-plans/PLAN-XXXX-<slug>.md`.
- Skills go in `skills/<topic>/SKILL.md`.
- Follow the document lifecycle in `workflows/document-lifecycle.md`.

### Exported Surface vs Internal Governance

| Exported surface (consumers may reference) | Internal governance (framework evolution only) |
| --- | --- |
| `guidelines/` | `docs/specifications/` |
| `roles/` | `docs/change-plans/` |
| `skills/` | `docs/decisions/` |
| `templates/` | `docs/ARC42.md` |
| `workflows/` | `BACKLOG.md` |
| `integrations/` | `package.json` |
| `runbooks/` | `CHANGELOG.md` |
| `scripts/` (`FS-0024`: vendored copies check the invoking repository, not this one) | `test/` |
| `INTEGRATION.md` | |
| `AGENTS.md` | |
| | `site/` (internal build source; the generated Pages artifact is a public derivative) |

The framework `vendor/` directory is framework-internal. Only `vendor/madr/`
remains as operational infrastructure for ADR linting. Do not reference
nested vendor paths in consumer-facing content. See `ADR-0017`.

### Process Gates

- `npm run check:status` — FS/PLAN status consistency and README index sync
- `npm run lint:docs` — lint all governed documents
- `npm run lint:adrs` — lint ADRs specifically
- `npm run lint:specs` — lint feature specs
- `npm run lint:workflows` — lint workflow docs

### Commit and PR Conventions

Use Conventional Commits (lite), defined in `workflows/git-and-gh-conventions.md`:

- `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

PRs must state what changed, link related ADRs/specs when applicable, avoid
editing submodule contents directly, and confirm all tests pass before
submitting.

## Non-Overridable Safety Gates (ADR-0012)

- **Do not merge PRs.** Merging is human-gated.
- **Verify GitHub identity** with `gh auth status` before every `gh` or `git push` operation.

## For Projects Consuming This Framework

Point host-repo agents at `vendor/conventional-agents/AGENTS.md` (this file) and
`vendor/conventional-agents/INTEGRATION.md`. If the host project is part of an
organization with its own conventions, also vendor the consumer conventions
repo as a sibling submodule and reference it in the host `AGENTS.md`.

See `ADR-0016` and the `framework-consumer-integration` skill.

## License

MIT License. See `LICENSE`.

---

**Framework Version:** 2.1.0 | **Last Updated:** 2026-07-27
