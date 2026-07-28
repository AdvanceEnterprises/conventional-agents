# conventional-agents

A prescriptive governance framework for agentic development — for any project
where LLMs or other generative models do structured work. Provides role
contracts, process gates, document templates, and workflow patterns that make
agent behavior auditable, correctable, and coherent across sessions.

## Philosophy

Agent sessions are ephemeral; the artifacts they produce are not. This framework
treats documents as the primary interface between humans and agents:

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

This repository is designed to be **vendored into other projects** (typically as
a git submodule at `vendor/conventional-agents/`) to provide baseline guidance
and templates.

At the same time, **this repo uses its own exported guidance to govern itself** —
the framework is recursive.

**Exported surface** (consumed by host repos and agents):

| Directory | Contents |
| --- | --- |
| `guidelines/` | Normative standards and role contracts |
| `roles/` | Role contracts — start here and customize per project |
| `skills/` | Portable SKILL.md modules |
| `templates/` | FS / ADR / PLAN / review scaffolds |
| `workflows/` | Process docs usable in any repo |
| `integrations/` | Substrate bindings — platform mappings per ADR-0024 |
| `INTEGRATION.md` | How to integrate and precedence rules |
| `AGENTS.md` | Agent briefing surface for this repo |

**Internal governance** (how this framework evolves):

| Directory | Contents |
| --- | --- |
| `docs/specifications/` | Feature Specs (FS) |
| `docs/change-plans/` | Change Plans (PLAN) |
| `docs/decisions/` | Architecture Decision Records (ADRs) |
| `docs/ARC42.md` | Architecture overview |
| `BACKLOG.md` | Deferred work and known gaps |
| `package.json` | Doc lint scripts |
| `test/` | Framework self-tests |

Rule of thumb: if a document is a reusable instruction or process for
downstream work, it belongs in the exported surface. If it records how *this
framework* decided to evolve, it belongs in `docs/`.

### Framework-Internal Vendor Directory

The `vendor/` directory is framework-internal. `vendor/madr/` remains as
operational infrastructure for ADR linting. Consuming projects must not
reference nested vendor paths such as `vendor/conventional-agents/vendor/...`.
See `ADR-0017`.

### Role Contract

The framework defines six roles in `guidelines/ROLE_CONTRACT.md` and
`roles/ROLE_CONTRACT.md`:

| Role | Purpose |
| --- | --- |
| **0 — Head Architect** | Strategic oversight, framework health, governance proposals |
| **1 — Document Author** | Drafts and maintains FS, PLAN, ADR documents |
| **2 — Spec Reader and Test Planner** | Translates approved specs into executable tests |
| **3 — Implementer** | Makes failing tests pass with minimum viable changes |
| **4 — Reviewer** | Identifies mismatches between docs, tests, and implementation |
| **5 — Communications Lead** | Human-facing communication — release notes, status summaries, INTEGRATION.md |

Each role has defined inputs, outputs, prohibited actions, stop conditions,
and `best_used_when` / `avoid_when` guidance. See
`guidelines/ROLE_CONTRACT.md` for the full contract.

### Session Modes

`workflows/session-modes.md` defines five named session modes that tell agents
which role to lead with and how to handle transitions:

- **Architecture Planning** — Head Architect primary
- **Document Authoring** — Document Author primary
- **Implementation** — Implementer primary
- **Review** — Reviewer primary
- **Communications** — Communications Lead primary

### Process Gates

The framework enforces correctness through layered gates:

- **Spec-first rule**: no implementation without an approved FS + PLAN
- **Status consistency check**: `npm run check:status` — validates FS↔PLAN
  pairing and README index sync; runs in CI
- **Document hygiene gate**: 7-item checklist before any PR is marked ready
- **Non-overridable safety gates (ADR-0012)**: agents must not merge PRs; must
  verify GitHub identity before every push

### Guidelines

Language-specific best practices vendored into host repos:

- **Bash**: style, testing patterns, implementation guidance
- **Python**: style, testing patterns, implementation guidance
- **JavaScript/TypeScript**: style, testing patterns, implementation guidance

See `guidelines/` directory.

### Skills

Portable skill modules that encode the framework's knowledge into actionable
guidance for agents. Each skill is a self-contained `SKILL.md` in its own
directory under `skills/`:

| Skill | Purpose |
| --- | --- |
| **Role-Aware Session** | Infers session mode, primary/supporting roles, and enforces role boundaries |
| **Document Lifecycle** | Scaffolds, transitions, and maintains FS/PLAN/ADR documents with correct front matter |
| **Git/GH Workflow** | Branching, commits, PRs, multi-identity model, versioning, and release process |
| **Framework Health / Audit** | Runs `check:status`, performs full framework health audits, enforces hygiene gate |
| **Testing Guide** | Writes tests from approved specs across Python, JS/TS, and Bash |
| **Framework Consumer Integration** | Helps host projects integrate conventional-agents correctly |

See `skills/index.md` for the full catalog.

### Templates

Reusable scaffolds for common activities:

- **Core**: feature specs, ADRs, architecture docs, change plans
- **Reviewer**: PR review, spec review, test review templates
- **Python Tests**: unit test, integration test, test configuration templates

See `templates/` directory.

## For Projects Consuming This Framework

### Quick Start

```bash
cd /path/to/your-project
git submodule add https://github.com/Tais-Den/conventional-agents.git vendor/conventional-agents
git submodule update --init
git add .gitmodules vendor/conventional-agents
git commit -m "chore: add conventional-agents foundation layer"
```

Create `AGENTS.md` in your project root:

```text
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md
- vendor/conventional-agents/workflows/session-modes.md

## Universal Gates
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

## Project-Specific Rules
(Add your project-specific context here)

## Precedence
See vendor/conventional-agents/INTEGRATION.md
```

### With Organization-Specific Conventions

If your organization has its own conventions repo (see `ADR-0016`), vendor it
as a sibling submodule:

```bash
git submodule add https://github.com/Tais-Den/tais-den-conventions.git vendor/tais-den-conventions
git add .gitmodules vendor/tais-den-conventions
git commit -m "chore: add tais-den-conventions"
```

Then add a `Consumer Conventions` section to your `AGENTS.md`:

```text
## Consumer Conventions
- vendor/tais-den-conventions/README.md
- vendor/tais-den-conventions/ADR-0001-notion-github-boundary.md
```

### Update to Latest

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

See `INTEGRATION.md` for full integration patterns.

## For Agents Working on This Repo

Read `AGENTS.md` at the root of this repo first.

## Usage

### Customizing Roles for Your Project

`roles/ROLE_CONTRACT.md` is the project-customizable copy. Start from the
template in `guidelines/ROLE_CONTRACT.md` and adapt it:

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

The framework uses curated subsets of the following upstream standards. The
authoritative full specifications are available at the URLs below.

- **Conventional Commits** — [conventionalcommits.org](https://www.conventionalcommits.org/) (framework subset in `workflows/git-and-gh-conventions.md`)
- **Keep a Changelog** — [keepachangelog.com](https://keepachangelog.com/) (framework subset in `workflows/versioning-and-releases.md`)
- **MADR** — [adr.github.io/madr](https://adr.github.io/madr/) (template adapted in `templates/core/adr-full-madr.md`)
- **arc42** — [arc42.org](https://arc42.org/) (structure adapted in `docs/ARC42.md`)

Recommended reading:

- **Architecture Decision Records** — [joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record)

## License

MIT License. See [LICENSE](./LICENSE) for details.

---

**Framework Version:** 2.1.0 | **Last Updated:** 2026-07-27
