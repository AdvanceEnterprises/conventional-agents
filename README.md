# conventional-agents

A prescriptive governance framework for agentic development — for any project where LLMs, GPTs, or other generative models do structured work. Provides role contracts, process gates, document templates, and workflow patterns that make agent behavior auditable, correctable, and coherent across sessions.

## Philosophy

Agent sessions are ephemeral; the artifacts they produce are not. This framework treats documents as the primary interface between humans and agents:

- Every significant decision lives in a governed document (FS, PLAN, ADR) — not in a chat history.
- Roles define what an agent is permitted to do and when to stop, not just what it can do.
- Process gates (spec-first, status consistency, hygiene checklist) make drift visible before it becomes technical debt.
- Humans approve; agents execute. The merge gate, the spec approval gate, and the major version bump gate are all human-held.

**Core principle:** Traceability over cleverness. An auditable wrong answer is more valuable than an untraceable right one.

## Project Board

Work tracking: [conventional-agents Development](https://github.com/orgs/Tais-Den/projects/2)

Board configuration: [`config/project.yml`](./config/project.yml)

## What's Included

### Exported Surface vs Internal Governance

This repository is designed to be **vendored into other projects** (typically as a git submodule at `vendor/conventional-agents/`) to provide baseline guidance and templates.

At the same time, **this repo uses its own exported guidance to govern itself** — the framework is recursive.

**Exported surface** (consumed by host repos and agents):

| Directory | Contents |
| --- | --- |
| `guidelines/` | Normative standards and role contracts |
| `roles/` | Role contracts — start here and customize per project |
| `skills/` | Portable SKILL.md modules |
| `templates/` | FS / ADR / PLAN / review scaffolds |
| `workflows/` | Process docs usable in any repo |
| `INTEGRATION.md` | How to integrate and precedence rules |

**Internal governance** (how this framework evolves):

| Directory | Contents |
| --- | --- |
| `docs/decisions/` | Architecture Decision Records (ADRs) |
| `docs/specifications/` | Feature Specs (FS) |
| `docs/change-plans/` | Change Plans (PLAN) |
| `docs/ARC42.md` | Architecture overview |

Rule of thumb: if a document is a reusable instruction or process for downstream work, it belongs in the exported surface. If it records how *this framework* decided to evolve, it belongs in `docs/`.

### Role Contract

The framework defines six roles in `guidelines/ROLE_CONTRACT.md` and `roles/ROLE_CONTRACT.md`:

| Role | Purpose |
| --- | --- |
| **0 — Head Architect** | Strategic oversight, framework health, governance proposals |
| **1 — Document Author** | Drafts and maintains FS, PLAN, ADR documents |
| **2 — Spec Reader and Test Planner** | Translates approved specs into executable tests |
| **3 — Implementer** | Makes failing tests pass with minimum viable changes |
| **4 — Reviewer** | Identifies mismatches between docs, tests, and implementation |
| **5 — Communications Lead** | Human-facing communication — release notes, status summaries, INTEGRATION.md |

Each role has defined inputs, outputs, prohibited actions, stop conditions, and `best_used_when` / `avoid_when` guidance. See `guidelines/ROLE_CONTRACT.md` for the full contract.

### Session Modes

`workflows/session-modes.md` defines five named session modes that tell agents which role to lead with and how to handle transitions:

- **Architecture Planning** — Head Architect primary
- **Document Authoring** — Document Author primary
- **Implementation** — Implementer primary
- **Review** — Reviewer primary
- **Communications** — Communications Lead primary

### Process Gates

The framework enforces correctness through layered gates:

- **Spec-first rule**: no implementation without an approved FS + PLAN
- **Status consistency check**: `npm run check:status` — validates FS↔PLAN pairing and README index sync; runs in CI
- **Document hygiene gate**: 7-item checklist before any PR is marked ready
- **Non-overridable safety gates (ADR-0012)**: agents must not merge PRs; must verify GitHub identity before every push

### Multi-Model Session Coordination

Concurrent sessions of different models coordinate via two modes defined in
[ADR-0013](docs/decisions/ADR-0013-multi-model-session-coordination.md):
parallel independent primaries (different tasks, coordinate through shared
artifacts) and primary + contributor (same task, contributor delivers outputs
via PR comments or named draft documents but does not commit). The operational
pattern for invoking contributors with structured output contracts and
gate-evaluating the synthesis is defined in
[ADR-0016](docs/decisions/ADR-0016.md): three render modes (`external-cli`,
`hermes-chat`, `research-pass`), two structured-output contracts (Research
Brief, JSON schema) with a shared claim envelope, and an independent gate
evaluator. The pilot that validated these ADRs is at
`docs/orchestration/multi-model-pilot-001/`.

### Guidelines

Language-specific best practices vendored into host repos:

- **Bash**: style, testing patterns, implementation guidance
- **Python**: style, testing patterns, implementation guidance
- **JavaScript/TypeScript**: style, testing patterns, implementation guidance

See `guidelines/` directory.

### Templates

Reusable scaffolds for common activities:

- **Core**: feature specs, ADRs, architecture docs, change plans
- **Reviewer**: PR review, spec review, test review templates
- **Python Tests**: unit test, integration test, test configuration templates

See `templates/` directory.

## Installation

### As a Git Submodule (Recommended)

```bash
cd /path/to/your-project
git submodule add https://github.com/Tais-Den/conventional-agents.git vendor/conventional-agents
git submodule update --init
```

Reference in your project's `AGENTS.md`:

```markdown
## Foundation Standards
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md

## Session Modes
- vendor/conventional-agents/workflows/session-modes.md
```

Update to latest:

```bash
cd vendor/conventional-agents
git pull origin trunk
cd ../..
git add vendor/conventional-agents
git commit -m "chore: update conventional-agents to latest"
```

### Manual Copy

For one-time use or when tools only read root files:

```bash
git clone https://github.com/Tais-Den/conventional-agents.git
cp -r conventional-agents/guidelines /path/to/your-project/
cp -r conventional-agents/roles /path/to/your-project/
cp -r conventional-agents/workflows /path/to/your-project/
```

See `INTEGRATION.md` for full integration patterns including the hybrid (recommended) approach.

## Usage

### Customizing Roles for Your Project

`roles/ROLE_CONTRACT.md` is the project-customizable copy. Start from the template in `guidelines/ROLE_CONTRACT.md` and adapt it:

- Add domain-specific constraints to existing roles
- Add `best_used_when` conditions specific to your project type
- Add session modes in a project-level `roles/session-modes.md` if your workflow needs them beyond the five defined in `workflows/`

### Referencing in AGENTS.md / CLAUDE.md

```markdown
## Agent Guidelines

This project uses conventional-agents for governance:

- [Role Contract](./vendor/conventional-agents/roles/ROLE_CONTRACT.md)
- [Session Modes](./vendor/conventional-agents/workflows/session-modes.md)
- [Integration Guide](./vendor/conventional-agents/INTEGRATION.md)

Active session mode: [state which mode applies to this project/session]
```

### Running Process Gates Locally

```bash
# Check FS↔PLAN status consistency and README index sync
npm run check:status

# Lint all governed documents
npm run lint:docs
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Upstream References

Vendored as git submodules:

- **Conventional Commits** — `vendor/conventional-commits/` · [conventionalcommits.org](https://www.conventionalcommits.org/)
- **Keep a Changelog** — `vendor/keep-a-changelog/` · [keepachangelog.com](https://keepachangelog.com/)

Recommended reading:

- **Architecture Decision Records** — [joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record)

## License

MIT License. See [LICENSE](./LICENSE) for details.

---

**Framework Version:** 2.0.0 | **Last Updated:** 2026-06-25
