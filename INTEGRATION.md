# Integration Guide

Version: 2.0.0
Last Updated: 2026-06-08

This document is the canonical source for how conventional-agents integrates with host repositories and resolves conflicts between instruction sources.

⸻

## Table of Contents

1. Quick Start
2. Consumer Issue Configuration (Work Item Lifecycle, FS-0018)
3. Precedence Rules
4. Integration Patterns
5. Tool-Specific Integration
6. Multi-Agent Coordination
7. Troubleshooting
8. Best Practices
9. Migration Guides

⸻

## Quick Start

### Recommended: submodule + stub pattern

```bash
# 1) Add submodule
# Note: replace with the actual repository URL when known
git submodule add <REPO_URL> vendor/conventional-agents

git submodule update --init

# 2) Create minimal AGENTS.md stub
cat > AGENTS.md << 'EOF'
# Agent Instructions

## Read First
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/workflows/session-modes.md

## Universal Gates
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

## Minimum Quality Gates
- vendor/conventional-agents/guidelines/tests.md
- vendor/conventional-agents/guidelines/commit-and-pr.md

## Precedence Rules
See vendor/conventional-agents/INTEGRATION.md

## Project-Specific Rules
(Add your project-specific context here)
EOF

# 3) Commit
git add .gitmodules vendor/conventional-agents AGENTS.md
git commit -m "Add conventional-agents foundation layer"
```

### Alternative: copy-in pattern

Use this when a tool only reads root files.

```bash
cp vendor/conventional-agents/packs/agents-md/AGENTS.full.example.md ./AGENTS.md
cp vendor/conventional-agents/packs/claude/CLAUDE.full.example.md ./CLAUDE.md

# Customize
vim AGENTS.md
```

⸻

## Consumer Issue Configuration (Work Item Lifecycle, FS-0018)

Consumer repos adopting `conventional-agents` configure their work-tracking substrate to match
the three-axis schema (`FS-0018`). The framework ships two reference paths:

### Path A — GitHub Issues + Projects v2 (reference binding)

This is the substrate the framework itself runs on. Configuration:

1. **Issue Type field** — a Projects v2 single-select field with the closed set
   `{feature, bug, task}`. Title-prefix fallback (`[feature]`, `[bug]`, `[task]`) is acceptable
   for repos without Projects.
2. **Status field** — built-in Projects v2 Status, mapped to phases
   `{Backlog, Approved, In Progress, In Review, Done}`.
3. **Labels** — six labels classified by content (`enhancement`, `bug`, `documentation`) and
   position (`spec`, `plan`, `question`).
4. **Unattended actor** — a dedicated GitHub identity (machine user or PAT) with a distinct
   email alias (e.g., `hermes-cron@tais-den.dev`), per `ADR-0021`.
5. **Trigger handlers** — webhook handlers that:
   - Verify the agent's `user.email` against the unattended alias before applying the
     `mode=autonomous` stance to a work item.
   - Reject Type-field edits by anyone other than a human.
   - Suppress all work-item transitions while the `question` label is set.
6. **Branch protection** — `Require status checks to pass before merging` plus
   `Require review from Code Owners`, per `ADR-0012`. Agents MUST NOT merge.

Reference: [`integrations/github-issues-projects.md`](./integrations/github-issues-projects.md).

### Path B — other substrates

A consumer on a different platform authors a binding in `integrations/` mapping the six
`ADR-0024` capabilities — work item, Type, Phase, parked state, activity record, trigger
source — onto the platform's mechanisms, per `ADR-0024`'s two-layer model. The binding states
per capability whether the mechanism **enforces** or merely makes violations **attributable**.
The framework cannot technically enforce the Type-immutability and `question`-suppression
rules; the binding's enforcement decisions are what the consumer relies on.

### Origination paths

Consumer repos wire trigger handlers for `FS-0018`'s three origination paths:

- **Path 1** — Issues opened by humans with the `enhancement` label. Handler applies
  Head Architect stance, proposes `Type=feature`, transitions phase to Approved.
- **Path 2** — Hybrid-session Head Architect conversations conclude. The agent itself creates
  the work item.
- **Path 3** — Scheduled jobs (drift detection, `npm run check:status` failures, dependency
  scans) create work items of `Type=bug` or `task` under the unattended actor identity.

### Cron actor provisioning (Path 3)

Operating Path 3 at runtime requires:

- A GitHub PAT or App installation with `repo` and `project` scopes, scoped to the unattended
  actor's email alias.
- The PAT is held by the consumer's cron infrastructure, NOT in the framework repository.
- The cron entry itself is a `bash` snippet or equivalent that sets the `user.email` and
  `user.name` env vars before any `git commit` it issues, then posts an `agent-stance:` entry
  on the created work item.

⸻

## Precedence Rules

### Canonical hierarchy

When multiple instruction sources exist, apply this binding order:

0. Non-overridable safety gates: ROLE_CONTRACT § Non-Overridable Safety Gates (cannot be weakened by any source; see ADR-0012)
1. Host repo project-specific rules in root AGENTS.md (highest project-level authority)
2. Universal gates and guardrails: vendor/conventional-agents/roles/ROLE_CONTRACT.md (cannot be weakened)
3. Role-specific contracts: `vendor/conventional-agents/roles/<role>.md`
4. Guidelines: vendor/conventional-agents/guidelines/
5. Tool-specific configs: CLAUDE.md, .cursorrules, editor settings, etc.

If instructions conflict, lower number wins.

### Detailed precedence

| Priority | Source | Scope | Can override? |
| --- | --- | --- | --- |
| 0 | ROLE_CONTRACT § Non-Overridable Safety Gates | Safety-critical rules (ADR-0012) | Cannot be overridden by any source |
| 1 | Root AGENTS.md project-specific sections | Project decisions and constraints | Can override 3 to 5 and can strengthen 2 |
| 2 | vendor/conventional-agents/roles/ROLE_CONTRACT.md | Universal gates and guardrails | Cannot be weakened |
| 3 | `vendor/conventional-agents/roles/<role>.md` | Role-specific behavior and gates | Can strengthen 4 to 5 |
| 4 | vendor/conventional-agents/guidelines/ | General practices and checklists | Can be tailored by 1 and 3 |
| 5 | Tool configs (CLAUDE.md, .cursorrules, etc.) | Tool-specific hints | Must defer to 0 to 4 |

### Strengthening vs weakening

Strengthening (allowed):

- Universal gate: “Must write tests”
- Project adds: “Must achieve 95% coverage”

Result: allowed. More strict is fine.

Weakening (not allowed):

- Universal gate: “Must write tests”
- Project says: “Skip tests for prototypes”

Result: not allowed. Projects cannot weaken universal gates.

### Resolution examples

#### Example 1: project strengthens a guideline

```text
# AGENTS.md
Coverage requirement: 90%
```

Result: project requirement wins over any default guideline.

#### Example 2: attempt to weaken a universal gate

```text
# AGENTS.md
Skip tests for this feature
```

Result: invalid by default. If you truly must, document a narrowly-scoped exception in AGENTS.md with rationale and compensating controls.

⸻

## Integration Patterns

### Choosing a Pattern

| Scenario | Use This Pattern | Submodules |
| --- | --- | --- |
| Single repo, baseline framework guidance | Pattern 1 or 3 | `vendor/conventional-agents` |
| Organization with shared conventions | Pattern 4 | `vendor/conventional-agents` + `vendor/<consumer-conventions>` |
| Tool only reads root files | Pattern 2 | None (copy-in) |
| Heavy customization of the framework | Fork conventional-agents | `vendor/conventional-agents` (fork URL) |

### Pattern 1: submodule with minimal stubs

When to use:

- Teams or orgs that want consistent standards across multiple repos
- Repos that will update conventional-agents over time

Structure:

```text
your-repo/
├── AGENTS.md
├── CLAUDE.md (optional)
└── vendor/
    └── conventional-agents/
```

Pros:

- Single source of truth
- Easy updates

Cons:

- Requires submodule discipline

AGENTS.md stub:

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

### Pattern 2: copy-in with local customization

When to use:

- Tools that only read root files
- One-off snapshots or prototypes where drift is acceptable

Pros:

- No submodule setup

Cons:

- Drift risk

If you copy, record the snapshot in root AGENTS.md:

- "Copied from conventional-agents version <commit/tag>"

### Pattern 3: hybrid (recommended default)

Submodule for canonical content plus small root stubs with project additions.

Add a minimal `CLAUDE.md` or `.cursorrules`:

```text
Defer to AGENTS.md.
Foundation:
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

Precedence: vendor/conventional-agents/INTEGRATION.md
```

Keep tool-specific files short. Put project specifics in `AGENTS.md`.

### Pattern 4: submodule + consumer conventions repo

When to use:

- Organizations or individuals whose setup spans multiple repos
- Cases where the framework is not enough — there are org-specific or
  consumer-specific conventions (tool boundaries, identity mappings,
  planning surface rules) that must be documented separately

Structure:

```text
your-repo/
├── AGENTS.md
├── CLAUDE.md (optional)
└── vendor/
    ├── conventional-agents/        # Framework
    └── tais-den-conventions/     # Consumer/org conventions
```

AGENTS.md:

```text
# Agent Instructions

## Foundation Standards
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/workflows/session-modes.md

## Consumer Conventions
- vendor/tais-den-conventions/README.md
- vendor/tais-den-conventions/ADR-0001-notion-github-boundary.md

## Project-Specific Rules
(Add your project-specific context here)

## Precedence
See vendor/conventional-agents/INTEGRATION.md
```

Rules:

- Consumer conventions use the same ADR format as the framework but are
  governed by the consumer, not by conventional-agents.
- The consumer conventions repo may itself vendor conventional-agents for
  its own dogfooding, but consuming projects must not rely on that nested
  path. Always vendor both submodules as siblings.
- Updates to consumer conventions are independent of framework updates.
- The framework's `vendor/` directory is framework-internal. No consumer
  documentation, AGENTS.md, CLAUDE.md, or tool config should reference
  `vendor/conventional-agents/vendor/...` paths.

For more details, see ADR-0016: Consumer conventions and ADR-0017: Framework
vendor directory is internal.

⸻

## Tool-Specific Integration

### AGENTS.md (cross-tool)

Purpose: primary briefing surface.

Minimal stub:

```text
# Agent Instructions

## Foundation Standards
- vendor/conventional-agents/guidelines/index.md
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

## Project Context
(Add project-specific information)

## Precedence
See vendor/conventional-agents/INTEGRATION.md
```

### CLAUDE.md (Claude tooling)

Purpose: Claude-specific additions. Must defer to AGENTS.md.

```text
# Claude Instructions

Defer to AGENTS.md.

Foundation:
- vendor/conventional-agents/guidelines/index.md
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

Precedence: vendor/conventional-agents/INTEGRATION.md
```

### Aider

Reference via config:

```yaml
read:
  - vendor/conventional-agents/packs/aider/CONVENTIONS.md
  - vendor/conventional-agents/roles/ROLE_CONTRACT.md
  - vendor/conventional-agents/guidelines/tests.md
  - vendor/conventional-agents/guidelines/commit-and-pr.md
```

Or copy:

```bash
cp vendor/conventional-agents/packs/aider/CONVENTIONS.md ./CONVENTIONS.md
```

### Cursor and other editors

Treat editor rule files as lower precedence (Priority 5). Keep them short and point back to AGENTS.md.

Example .cursorrules stub:

```text
Defer to AGENTS.md.
Universal gates: vendor/conventional-agents/roles/ROLE_CONTRACT.md
Precedence: vendor/conventional-agents/INTEGRATION.md
```

### Codex

Use root AGENTS.md as the consistent entry point. If you maintain an extra context file, keep it referential.

Example CODEX_CONTEXT.md:

```text
# Codex Context

Foundation:
- vendor/conventional-agents/guidelines/index.md
- vendor/conventional-agents/roles/ROLE_CONTRACT.md

Role:
- vendor/conventional-agents/roles/test-writer.md

Precedence:
- vendor/conventional-agents/INTEGRATION.md
```

### Spec Kit

Spec Kit owns workflow. conventional-agents supplies quality gates.

Recommended hook: .specify/memory/constitution.md

```text
## Article IX: Code Quality Standards

Reference: vendor/conventional-agents/integrations/spec-kit.md

Mandatory:
- Universal gates: vendor/conventional-agents/roles/ROLE_CONTRACT.md
- Testing: vendor/conventional-agents/guidelines/tests.md
- PR hygiene: vendor/conventional-agents/guidelines/commit-and-pr.md
```

⸻

## Multi-Agent Coordination

### Baseline

1. All agents read root AGENTS.md
2. Universal gates apply to all roles: vendor/conventional-agents/roles/ROLE_CONTRACT.md
3. Tool-specific files are additive, not authoritative

### Handoff protocol

Agent A (completing work):

- Record what changed (commit message; ADR if architectural)
- Verify gates passed
- Provide handoff summary in PR description

Agent B (receiving work):

- Read the handoff summary
- Load the appropriate role contract
- Re-check key gates before proceeding

⸻

## Troubleshooting

### Agent ignores standards

Symptoms:

- Code does not follow gates
- Tests are missing or not run

Diagnosis:

```bash
cat AGENTS.md

git submodule status

ls -la vendor/conventional-agents/guidelines/
```

Solutions:

1. Ensure AGENTS.md references the correct paths
2. Initialize the submodule: git submodule update --init
3. Reduce competing tool-specific instruction files

### Conflicting instructions between files

Symptoms:

- Agent claims two files disagree
- Different tools behave differently

Diagnosis:

- Identify which files are in play (AGENTS.md, CLAUDE.md, editor rules)
- Apply precedence: lower number wins

Solutions:

1. Make root AGENTS.md explicit and minimal
2. Treat tool configs as additive, not authoritative
3. If needed, add a single “Conflict Resolution” snippet to AGENTS.md that points back here

### Updates break existing setup

Symptoms:

- After updating the submodule, paths or expectations changed
- A consumer-facing file now references `vendor/conventional-agents/vendor/...`
- The framework's `README.md` or `INTEGRATION.md` now describes a structure
  that differs from your local integration

Diagnosis:

```bash
cd vendor/conventional-agents

git log --oneline HEAD@{1}..HEAD

cd ../..
```

Solutions:

1. Review CHANGELOG.md (if present)
2. Pin to a known good tag or commit
3. Update stubs only if stable paths were deprecated
4. Remove any references to nested vendor paths; use framework files or upstream URLs
5. If using consumer conventions, confirm the sibling submodule relationship

### Tool only reads root files

Symptoms:

- Tool does not follow vendor/ references

Diagnosis:

- Tool limitation

Solutions:

1. Copy the needed docs to root
2. Update AGENTS.md to reference the copied files
3. Record the snapshot version and schedule periodic sync
4. Consider using Pattern 2 (copy-in) instead of submodules for that tool

### Consumer conventions not found

Symptoms:

- `vendor/tais-den-conventions/` is empty or missing
- Agent cannot find org-specific ADRs

Diagnosis:

```bash
git submodule status
```

Solutions:

1. Run `git submodule update --init`
2. Confirm `.gitmodules` includes the consumer conventions repo
3. Confirm the submodule is a sibling of `vendor/conventional-agents/`, not nested inside it

### Nested vendor path leak

Symptoms:

- AGENTS.md, CLAUDE.md, or a tool config references `vendor/conventional-agents/vendor/...`

Diagnosis:

- Violation of ADR-0017

Solutions:

1. Replace the nested path with the framework file path or upstream URL
2. If the needed content is not in the framework's exported surface, copy it into the host repo
3. If the framework is missing the wrapper you need, open an issue or PR against conventional-agents

⸻

## Best Practices

### Do

- Keep root stubs short and referential
- Put project specifics in root AGENTS.md
- Strengthen standards explicitly when needed
- Document exceptions clearly and rarely

### Do not

- Duplicate large guidance blocks across multiple files
- Modify submodule content directly
- Assume tools auto-load anything

⸻

## Migration Guides

### No standards to conventional-agents

1. Add submodule
2. Add root AGENTS.md stub
3. Test with your tools
4. Commit

### Copy-in to submodule

1. Add submodule
2. Convert root files to stubs
3. Re-add project-specific customizations
4. Record what changed

### Submodule to fork (heavy customization)

1. Fork conventional-agents
2. Point submodule URL to your fork
3. Sync upstream intentionally
