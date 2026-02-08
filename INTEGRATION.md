Integration Guide

Version: 1.0.0
Last Updated: 2026-01-27

This document is the canonical source for how agentic-dev-kit integrates with host repositories and resolves conflicts between instruction sources.

⸻

Table of Contents
	1.	Quick Start
	2.	Precedence Rules
	3.	Integration Patterns
	4.	Tool-Specific Integration
	5.	Multi-Agent Coordination
	6.	Troubleshooting
	7.	Best Practices
	8.	Migration Guides

⸻

Quick Start

Recommended: submodule + stub pattern

# 1) Add submodule
# Note: replace with the actual repository URL when known
git submodule add <REPO_URL> vendor/agent-dev-kit

git submodule update --init

# 2) Create minimal AGENTS.md stub
cat > AGENTS.md << 'EOF'
# Agent Instructions

## Read First
- vendor/agent-dev-kit/guidelines/index.md
- vendor/agent-dev-kit/roles/index.md

## Universal Gates
- vendor/agent-dev-kit/roles/ROLE_CONTRACT.md

## Minimum Quality Gates
- vendor/agent-dev-kit/guidelines/tests.md
- vendor/agent-dev-kit/guidelines/commit-and-pr.md

## Precedence Rules
See vendor/agent-dev-kit/INTEGRATION.md

## Project-Specific Rules
(Add your project-specific context here)
EOF

# 3) Commit
git add .gitmodules vendor/agent-dev-kit AGENTS.md
git commit -m "Add agentic-dev-kit foundation layer"

Alternative: copy-in pattern

Use this when a tool only reads root files.

cp vendor/agent-dev-kit/packs/agents-md/AGENTS.full.example.md ./AGENTS.md
cp vendor/agent-dev-kit/packs/claude/CLAUDE.full.example.md ./CLAUDE.md

# Customize
vim AGENTS.md


⸻

Precedence Rules

Canonical hierarchy

When multiple instruction sources exist, apply this binding order:
1.	Host repo project-specific rules in root AGENTS.md (highest authority)
2.	Universal gates and guardrails: vendor/agent-dev-kit/roles/ROLE_CONTRACT.md (cannot be weakened)
3.	Role-specific contracts: vendor/agent-dev-kit/roles/<role>.md
4.	Guidelines: vendor/agent-dev-kit/guidelines/
5.	Tool-specific configs: CLAUDE.md, .cursorrules, editor settings, etc.

If instructions conflict, lower number wins.

Detailed precedence

Priority	Source	Scope	Can override?
1	Root AGENTS.md project-specific sections	Project decisions and constraints	Can override 3 to 5 and can strengthen 2
2	vendor/agent-dev-kit/roles/ROLE_CONTRACT.md	Universal gates and guardrails	Cannot be weakened
3	vendor/agent-dev-kit/roles/<role>.md	Role-specific behavior and gates	Can strengthen 4 to 5
4	vendor/agent-dev-kit/guidelines/	General practices and checklists	Can be tailored by 1 and 3
5	Tool configs (CLAUDE.md, .cursorrules, etc.)	Tool-specific hints	Must defer to 1 to 4

Strengthening vs weakening

Strengthening (allowed):
-	Universal gate: “Must write tests”
-	Project adds: “Must achieve 95% coverage”

Result: allowed. More strict is fine.

Weakening (not allowed):
-	Universal gate: “Must write tests”
-	Project says: “Skip tests for prototypes”

Result: not allowed. Projects cannot weaken universal gates.

Resolution examples

Example 1: project strengthens a guideline

# AGENTS.md
Coverage requirement: 90%

Result: project requirement wins over any default guideline.

Example 2: attempt to weaken a universal gate

# AGENTS.md
Skip tests for this feature

Result: invalid by default. If you truly must, document a narrowly-scoped exception in AGENTS.md with rationale and compensating controls.

⸻

Integration Patterns

Pattern 1: submodule with minimal stubs

When to use:
-	Teams or orgs that want consistent standards across multiple repos
-	Repos that will update agentic-dev-kit over time

Structure:

your-repo/
├── AGENTS.md
├── CLAUDE.md (optional)
└── vendor/
    └── agent-dev-kit/

Pros:
-	Single source of truth
-	Easy updates

Cons:
-	Requires submodule discipline

Pattern 2: copy-in with local customization

When to use:
-	Tools that only read root files
-	One-off snapshots or prototypes where drift is acceptable

Pros:
-	No submodule setup

Cons:
-	Drift risk

If you copy, record the snapshot in root AGENTS.md:
-	“Copied from agentic-dev-kit version ”

Pattern 3: hybrid (recommended default)

Submodule for canonical content plus small root stubs with project additions.

⸻

Tool-Specific Integration

AGENTS.md (cross-tool)

Purpose: primary briefing surface.

Minimal stub:

# Agent Instructions

## Foundation Standards
- vendor/agent-dev-kit/guidelines/index.md
- vendor/agent-dev-kit/roles/ROLE_CONTRACT.md

## Project Context
(Add project-specific information)

## Precedence
See vendor/agent-dev-kit/INTEGRATION.md

CLAUDE.md (Claude tooling)

Purpose: Claude-specific additions. Must defer to AGENTS.md.

# Claude Instructions

Defer to AGENTS.md.

Foundation:
- vendor/agent-dev-kit/guidelines/index.md
- vendor/agent-dev-kit/roles/ROLE_CONTRACT.md

Precedence: vendor/agent-dev-kit/INTEGRATION.md

Aider

Reference via config:

read:
  - vendor/agent-dev-kit/packs/aider/CONVENTIONS.md
  - vendor/agent-dev-kit/roles/ROLE_CONTRACT.md
  - vendor/agent-dev-kit/guidelines/tests.md
  - vendor/agent-dev-kit/guidelines/commit-and-pr.md

Or copy:

cp vendor/agent-dev-kit/packs/aider/CONVENTIONS.md ./CONVENTIONS.md

Cursor and other editors

Treat editor rule files as lower precedence (Priority 5). Keep them short and point back to AGENTS.md.

Example .cursorrules stub:

Defer to AGENTS.md.
Universal gates: vendor/agent-dev-kit/roles/ROLE_CONTRACT.md
Precedence: vendor/agent-dev-kit/INTEGRATION.md

Codex

Use root AGENTS.md as the consistent entry point. If you maintain an extra context file, keep it referential.

Example CODEX_CONTEXT.md:

# Codex Context

Foundation:
- vendor/agent-dev-kit/guidelines/index.md
- vendor/agent-dev-kit/roles/ROLE_CONTRACT.md

Role:
- vendor/agent-dev-kit/roles/test-writer.md

Precedence:
- vendor/agent-dev-kit/INTEGRATION.md

Spec Kit

Spec Kit owns workflow. agentic-dev-kit supplies quality gates.

Recommended hook: .specify/memory/constitution.md

## Article IX: Code Quality Standards

Reference: vendor/agent-dev-kit/integrations/spec-kit.md

Mandatory:
- Universal gates: vendor/agent-dev-kit/roles/ROLE_CONTRACT.md
- Testing: vendor/agent-dev-kit/guidelines/tests.md
- PR hygiene: vendor/agent-dev-kit/guidelines/commit-and-pr.md


⸻

Multi-Agent Coordination

Baseline
1.	All agents read root AGENTS.md
2.	Universal gates apply to all roles: vendor/agent-dev-kit/roles/ROLE_CONTRACT.md
3.	Tool-specific files are additive, not authoritative

Handoff protocol

Agent A (completing work):
-	Record what changed (commit message; ADR if architectural)
-	Verify gates passed
-	Provide handoff summary in PR description

Agent B (receiving work):
-	Read the handoff summary
-	Load the appropriate role contract
-	Re-check key gates before proceeding

⸻

Troubleshooting

Agent ignores standards

Symptoms:
-	Code does not follow gates
-	Tests are missing or not run

Diagnosis:

cat AGENTS.md

git submodule status

ls -la vendor/agent-dev-kit/guidelines/

Solutions:
1.	Ensure AGENTS.md references the correct paths
2.	Initialize the submodule: git submodule update --init
3.	Reduce competing tool-specific instruction files

Conflicting instructions between files

Symptoms:
-	Agent claims two files disagree
-	Different tools behave differently

Diagnosis:
-	Identify which files are in play (AGENTS.md, CLAUDE.md, editor rules)
-	Apply precedence: lower number wins

Solutions:
1.	Make root AGENTS.md explicit and minimal
2.	Treat tool configs as additive, not authoritative
3.	If needed, add a single “Conflict Resolution” snippet to AGENTS.md that points back here

Updates break existing setup

Symptoms:
-	After updating the submodule, paths or expectations changed

Diagnosis:

cd vendor/agent-dev-kit

git log --oneline HEAD@{1}..HEAD

cd ../..

Solutions:
1.	Review CHANGELOG.md (if present)
2.	Pin to a known good tag or commit
3.	Update stubs only if stable paths were deprecated

Tool only reads root files

Symptoms:
-	Tool does not follow vendor/ references

Diagnosis:
-	Tool limitation

Solutions:
1.	Copy the needed docs to root
2.	Update AGENTS.md to reference the copied files
3.	Record the snapshot version and schedule periodic sync

⸻

Best Practices

Do
-	Keep root stubs short and referential
-	Put project specifics in root AGENTS.md
-	Strengthen standards explicitly when needed
-	Document exceptions clearly and rarely

Do not
-	Duplicate large guidance blocks across multiple files
-	Modify submodule content directly
-	Assume tools auto-load anything

⸻

Migration Guides

No standards to agentic-dev-kit
1.	Add submodule
2.	Add root AGENTS.md stub
3.	Test with your tools
4.	Commit

Copy-in to submodule
1.	Add submodule
2.	Convert root files to stubs
3.	Re-add project-specific customizations
4.	Record what changed

Submodule to fork (heavy customization)
1.	Fork agentic-dev-kit
2.	Point submodule URL to your fork
3.	Sync upstream intentionally