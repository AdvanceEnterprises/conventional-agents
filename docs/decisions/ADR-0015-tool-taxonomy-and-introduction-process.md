---
type: adr
id: ADR-0015
status: proposed
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0015: Tool taxonomy and introduction process

## Status

- Proposed

## Context and Problem Statement

The framework references "tools" in several senses without a shared definition:
governance scripts that run in CI, skills that agents invoke from `skills/`, and platform
capabilities like `gh` or `git`. Each of these has a different mandatory/optional status,
different introduction requirements, and a different relationship to roles and governance.

Without a taxonomy, the framework cannot answer questions like: Does adding a new linting
script require an FS? Does bundling a Python helper as a skill require human approval?
Does the introduction of a new model capability (like a background task spawner) require
architectural review?

This ADR defines three categories of tools, the rules for each, and the process for
introducing a tool in each category.

## Decision Drivers

- **Governance scripts are load-bearing**: Scripts in `scripts/` run in CI and enforce
  framework compliance. Changing them is an architectural decision, not a convenience.
  They require the same spec-first rigor as any other framework component.
- **Skills are optional productivity aids**: Skills in `skills/` make agents more
  effective but are not compliance-critical. They should have a lighter introduction
  process that doesn't impose FS/PLAN overhead.
- **Platform tools are framework-neutral**: Tools like `git`, `gh`, `python3`, and the
  Claude Code CLI are provided by the runtime environment. The framework does not govern
  their presence but does govern how agents use them.
- **Role assignment is meaningful**: Each tool category should have a clear answer to
  "which role is responsible for this tool?" This connects tool governance to the role
  model.
- **Introduction process must match risk**: A heavyweight process for lightweight tools
  discourages adoption. A lightweight process for load-bearing tools is a safety risk.

## Considered Options

### Option A: All tools require an FS

Treat every tool addition as a framework feature. All tools go through FS → PLAN →
implementation, regardless of category.

### Option B: Two categories — mandatory and optional

Scripts that run in CI are mandatory and governed; everything else (skills, platform
tools) is optional and ungoverned.

### Option C: Three categories — governance gates, productivity skills, platform tools

A three-way taxonomy distinguishing CI-enforced scripts, optional SKILL.md-format skills,
and platform-provided capabilities. Each category has its own introduction requirements
and role assignment.

### Option D: Role-derived authorization (no taxonomy)

Instead of categorizing tools, allow each role's definition to specify what tools it may
use. No shared taxonomy.

## Decision Outcome

**Chosen option: Option C — three-category taxonomy.**

---

### Category 1: Governance gates

**Definition**: Scripts that run in CI and enforce framework compliance. Their output is
authoritative — a non-zero exit blocks a merge or a status transition.

**Characteristics**:

- Live in `scripts/`.
- Registered in `package.json` as named npm scripts (e.g., `check:status`, `lint:docs`).
- Run automatically in CI; may also be run locally.
- Enforced by role: a governance gate is associated with at least one role that is
  responsible for ensuring it passes before completing work.
- Produce machine-readable exit codes (0 = pass, non-zero = fail) and human-readable
  output explaining any failure.

**Introduction requirements**:

- MUST have an approved FS before implementation begins.
- MUST have an approved PLAN before any code is written.
- MUST be added to `package.json` and CI workflow in the same PR as the script.
- MUST include a description in `scripts/README.md` (or equivalent index) explaining its
  purpose, when it runs, and what a failure means.
- Role assignment MUST be declared at introduction: which role is responsible for keeping
  this gate green.

**Modification requirements**:

- Any change to a governance gate's enforcement logic (what it checks, what constitutes a
  pass) MUST be preceded by an approved FS.
- Changes to a gate's implementation that do not alter enforcement logic (refactors,
  performance improvements) require a PLAN but may reference the existing FS.
- The gate MUST remain a non-zero exit on failure after any modification.

**Responsible role**: Implementer (Role 3) for writing and modifying gate scripts.
Head Architect (Role 0) for proposing new gates via FS.

---

### Category 2: Productivity skills

**Definition**: Optional, agent-invokable capabilities in `skills/` format. Each skill
is a directory containing a `SKILL.md` that describes the skill's purpose, invocation,
and expected output. Skills may include helper scripts (`*.py`, `*.sh`) but are not
CI-enforced.

**Characteristics**:

- Live in `skills/{skill-name}/`.
- Described by a `SKILL.md` at `skills/{skill-name}/SKILL.md`.
- Optional: agents choose when to invoke them; their absence does not block work.
- Invocable by agents during a session without human approval per invocation.
- Any helper scripts included in a skill MUST support `--self-test`.

**Introduction requirements**:

- No FS required for a productivity skill.
- MUST have a `SKILL.md` that covers: purpose, primary role(s) that use this skill,
  invocation syntax, expected output, known limitations, and `--self-test` instructions.
- MUST be listed in `skills/index.md` (purpose + location + primary invocation).
- MAY be introduced in the same PR as a PLAN that uses the skill, or in a standalone PR.
- MUST pass `--self-test` before merging.

**Modification requirements**:

- Modifications to a skill that do not change its invocation interface may be made in any
  PR where the modification serves a documented need.
- Changes to a skill's invocation interface (flag names, input format, output format)
  require updating `SKILL.md` and the `skills/index.md` entry in the same PR.

**Responsible role**: Document Author (Role 1) for `SKILL.md` content. Implementer
(Role 3) for helper scripts. Any role may propose a new skill.

---

### Category 3: Platform tools

**Definition**: Capabilities provided by the runtime environment. These are not bundled
with the framework but are assumed to be present in any environment where the framework
operates.

**Examples**: `git`, `gh` (GitHub CLI), `python3`, `node`/`npm`, `bash`, the Claude
Code CLI, model-provided capabilities (background task spawning, parallel agent
invocation, web fetch).

**Characteristics**:

- Not distributed with the framework.
- Not versioned or governed by the framework directly.
- Assumed available; their absence is an environment configuration issue, not a framework
  issue.
- Framework-wide conventions about *how* agents use platform tools are governed by ADRs
  and workflow documents, even though the tools themselves are not.

**Introduction requirements**:

- No introduction process is required for using an existing platform tool.
- If the framework adds a new *convention* or *constraint* about how a platform tool is
  used (e.g., "agents MUST verify GitHub identity before `git push`"), that convention
  MUST be documented in an ADR or workflow document through the normal spec-first process.
- New model capabilities that create new governance implications (e.g., background task
  spawning, multi-session coordination) MUST be addressed by an ADR before agents rely
  on them. ADR-0013 and ADR-0014 are examples of this.

**Responsible role**: Head Architect (Role 0) for proposing new platform conventions via
ADR. Implementer (Role 3) for integrating platform tools into workflow documents.

---

### Tool category summary

| Category | Location | FS required | PLAN required | SKILL.md required | CI-enforced |
| --- | --- | --- | --- | --- | --- |
| Governance gate | `scripts/` | Yes | Yes | No | Yes |
| Productivity skill | `skills/` | No | No | Yes | No |
| Platform tool | N/A (runtime) | No (convention) | No | No | No |

### Why not the other options?

Option A (all tools require FS) is appropriate for governance gates but overloads the
process for skills. A developer adding a helpful Python generator to `skills/` should not
need a full FS/PLAN cycle — that ceremony is reserved for load-bearing governance changes.

Option B (two categories) collapses skills and platform tools into a single ungoverned
bucket. This works for platform tools, which the framework doesn't control, but it leaves
skills — which agents actively invoke — without any quality or discoverability standard.
A `SKILL.md` requirement is lightweight and delivers significant value.

Option D (role-derived authorization) conflates "what a role is authorized to do" with
"what tools exist and how they're introduced." These are orthogonal concerns: the role
model governs *who acts*; the tool taxonomy governs *what tools exist*. Merging them
makes both muddier.

### Consequences

**Good:**

- The FS/PLAN requirement for governance gates prevents ad-hoc CI changes that alter
  framework enforcement without architectural review.
- The SKILL.md requirement for productivity skills creates a consistent discoverability
  interface (`skills/index.md`) without imposing FS overhead.
- The platform tool category cleanly names why the framework has ADRs about `git` and
  `gh` conventions without needing to distribute those tools: the ADR governs usage, not
  the tool.
- Role assignments for each category connect tool governance to the existing role model.

**Bad:**

- The boundary between a governance gate and a productivity skill requires judgment:
  a script that *could* be run in CI but currently isn't — is it a governance gate or
  a skill? The distinction is based on actual CI registration, not potential, which
  should reduce ambiguity.
- The SKILL.md requirement adds a small authoring overhead for contributors adding skills.
  This is intentional (quality floor) but may slow initial skill adoption.

**Neutral:**

- A skill may graduate to a governance gate if it is registered in CI. This transition
  requires an FS and a PLAN for the CI registration step, but the skill's code may
  already exist.
- The framework does not dictate the language or runtime of tools in any category. Python
  scripts, shell scripts, and Node scripts are all valid as long as they meet the
  category's interface requirements.

## Links

- ADR-0001: Skills as portable markdown modules (established `SKILL.md` convention)
- ADR-0002: Skills index (established `skills/index.md`)
- ADR-0013: Multi-model session coordination (multi-session coordination is a platform
  capability governed by ADR, per Category 3)
- ADR-0014: Background task governance (background task spawning is a platform capability
  governed by ADR, per Category 3)
- FS-0002: Move workflow skills into conventional-agents (productivity skill migration)
- FS-0014: Six-role model (role assignments referenced in Category 1 and Category 2)
