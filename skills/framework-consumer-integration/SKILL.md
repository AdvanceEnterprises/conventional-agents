---
name: framework-consumer-integration
description: "Guides agents through integrating conventional-agents into a host repository, selecting the right pattern, writing AGENTS.md, and avoiding common mistakes."
version: 1.0.0
author: conventional-agents
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [integration, onboarding, submodules, agents-md, consumer-conventions]
    related_skills: [role-aware-session, git-gh-workflow]
---

# Framework Consumer Integration Skill

Helps agents add conventional-agents to a host project correctly, and helps
projects that already consume the framework keep their integration healthy.

## Source Documents

- `INTEGRATION.md` — integration patterns and precedence rules
- `README.md` — overview and upstream references
- `ADR-0016` — consumer conventions live outside the framework repo
- `ADR-0017` — framework vendor directory is internal
- `skills/index.md` — skill catalog

## When to Use

- Adding conventional-agents to a new host repo
- Auditing or fixing an existing integration
- Adding a consumer conventions repo (e.g., `<your-org>-conventions`)
- Reviewing a host project's AGENTS.md
- Troubleshooting submodule or precedence problems

## Integration Decision Tree

| Scenario | Pattern | Submodules needed |
| --- | --- | --- |
| Single repo, no org-specific rules | Pattern 1 or 3: submodule + minimal stub | `vendor/conventional-agents` |
| Multiple repos sharing org-specific rules | Pattern 4: submodule + consumer conventions repo | `vendor/conventional-agents`, `vendor/<consumer-conventions>` |
| Tool only reads root files | Pattern 2: copy-in | None (copy files and record version) |
| Heavy framework customization | Fork conventional-agents, vendor the fork | `vendor/conventional-agents` (fork URL) |

## Pattern 1: Minimal Submodule Integration

Use when the host repo wants baseline framework guidance and can read files in
`vendor/`.

```bash
cd /path/to/host-repo
git submodule add https://github.com/ajoeofalltrades/conventional-agents.git vendor/conventional-agents
git submodule update --init
git add .gitmodules vendor/conventional-agents
git commit -m "chore: add conventional-agents foundation layer"
```

Create `AGENTS.md`:

```text
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md
- vendor/conventional-agents/workflows/session-modes.md

## Universal Gates
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

## Project-Specific Rules
(Add host-repo context here: tech stack, domain, repo boundaries, etc.)

## Precedence
See vendor/conventional-agents/INTEGRATION.md
```

## Pattern 2: Copy-In

Use when tools only read root files, or for one-off snapshots where submodule
maintenance is not worth the overhead.

```bash
git clone https://github.com/ajoeofalltrades/conventional-agents.git /tmp/conventional-agents
cp -r /tmp/conventional-agents/guidelines /path/to/host-repo/
cp -r /tmp/conventional-agents/roles /path/to/host-repo/
cp -r /tmp/conventional-agents/workflows /path/to/host-repo/
```

Then create `AGENTS.md` pointing at the copied files and record the snapshot
version:

```text
# Agent Instructions

## Read First
- guidelines/ROLE_CONTRACT.md
- INTEGRATION.md
- workflows/session-modes.md

## Universal Gates
- roles/ROLE_CONTRACT.md

## Snapshot
Copied from conventional-agents <commit-or-tag>.

## Project-Specific Rules
(Add host-repo context here)

## Precedence
See INTEGRATION.md
```

Pros:

- No submodule setup.
- Works with tools that ignore `vendor/`.

Cons:

- Drift risk.
- Updates require manual re-copy.

## Pattern 3: Hybrid (Recommended Default)

Same as Pattern 1, but add small root stubs that capture project-specific
guidance without duplicating large blocks from the framework.

For example, add a `CLAUDE.md` or `.cursorrules` that says:

```text
Defer to AGENTS.md.
Foundation: vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
Precedence: vendor/conventional-agents/INTEGRATION.md
```

Keep tool-specific files short. Put project specifics in `AGENTS.md`.

## Pattern 4: Submodule + Consumer Conventions Repo

Use when the host project is part of an organization or group that has its own
conventions (tool boundaries, identity mappings, planning surface rules).

```bash
cd /path/to/host-repo
git submodule add https://github.com/ajoeofalltrades/conventional-agents.git vendor/conventional-agents
git submodule add "https://github.com/<your-org>/<your-org>-conventions.git" "vendor/<your-org>-conventions"
git submodule update --init
git add .gitmodules vendor/conventional-agents "vendor/<your-org>-conventions"
git commit -m "chore: add conventional-agents and <your-org>-conventions foundation layers"
```

Create `AGENTS.md`:

```text
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md
- vendor/conventional-agents/workflows/session-modes.md
- vendor/<your-org>-conventions/README.md

## Universal Gates
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

## Consumer Conventions
- vendor/<your-org>-conventions/ADR-0001-notion-github-boundary.md

## Project-Specific Rules
(Add host-repo context here)

## Precedence
See vendor/conventional-agents/INTEGRATION.md
```

## Critical Rules

### 1. Do not reference nested vendor paths

The framework's `vendor/` directory is framework-internal. Never write a real
path such as:

```text
vendor/conventional-agents/vendor/<upstream-repo>/README.md
```

Instead, reference framework files or upstream URLs:

```text
vendor/conventional-agents/workflows/git-and-gh-conventions.md
https://www.conventionalcommits.org/
```

See `ADR-0017`.

### 2. Consumer conventions must be sibling submodules

If you use a consumer conventions repo, it must be vendored at the same level as
`conventional-agents`, not inside it. Never rely on:

```text
vendor/conventional-agents/docs/instances/tais-den/...
```

See `ADR-0016`.

### 3. Keep AGENTS.md referential

AGENTS.md should point to framework files, not copy large sections. Project
specific rules go in the `Project-Specific Rules` section.

### 4. Update the submodule intentionally

```bash
cd vendor/conventional-agents
git pull origin trunk
cd ../..
git add vendor/conventional-agents
git commit -m "chore: update conventional-agents to latest"
```

Review changes before committing. Do not update blindly.

## Common Mistakes and Fixes

| Mistake | Fix |
| --- | --- |
| `vendor/conventional-agents` is empty | Run `git submodule update --init` |
| AGENTS.md copies whole sections from the framework | Replace with short references |
| AGENTS.md references `vendor/conventional-agents/vendor/...` | Update to framework file or upstream URL |
| Consumer conventions nested inside framework | Move to sibling submodule |
| Tool won't read `vendor/` files | Use Pattern 2 (copy-in) or symlink essential files to root |
| Unclear which role/session mode to use | Load `role-aware-session` skill |

## Audit Checklist

When reviewing a host integration, verify:

- [ ] `vendor/conventional-agents/` exists and is populated
- [ ] `AGENTS.md` exists at repo root
- [ ] AGENTS.md references `guidelines/ROLE_CONTRACT.md` and `INTEGRATION.md`
- [ ] No references to `vendor/conventional-agents/vendor/...`
- [ ] If consumer conventions are used, they are a sibling submodule
- [ ] Tool-specific files (CLAUDE.md, .cursorrules) are short and referential
- [ ] Project-specific rules are documented in AGENTS.md, not in the framework

## Links

- `README.md` § Installation and Upstream References
- `INTEGRATION.md` § Precedence Rules and Integration Patterns
- `ADR-0016`: Consumer conventions
- `ADR-0017`: Framework vendor directory is internal
- `skills/role-aware-session/SKILL.md`
- `skills/git-gh-workflow/SKILL.md`
