---
title: "arc42 Architecture Documentation"
system: "conventional-agents"
version: "1.0.0"
status: "Current"
last_updated: "2026-10-27"
---

# 1. Introduction and Goals

## 1.1 Requirements Overview

The conventional-agents repository provides a standalone, submodule-friendly
foundation layer for AI-assisted software development. Its primary
responsibilities are to define evidence-based guidelines, role contracts,
and reusable templates that host repositories can reference from stable
paths.

Key requirements and driving forces:
- Provide clear, checkable engineering standards for AI-assisted work.
- Remain tool-neutral and usable across multiple agent runtimes.
- Allow safe vendoring via submodule with stable paths.
- Keep the guidance auditable, repeatable, and explicit.

Primary references:
- README.md for positioning and usage.
- INTEGRATION.md for precedence and cross-tool integration rules.
- docs/decisions/README.md for the ADR lifecycle and template usage.

## 1.2 Quality Goals

Top quality goals for the architecture:

| Priority | Quality Goal           | Concrete Scenario Example                                      |
|---------:|------------------------|----------------------------------------------------------------|
| 1        | Composability          | Integrate as a submodule without repo restructuring            |
| 2        | Tool Neutrality        | Same guidance usable by Codex, Claude, Cursor, Aider            |
| 3        | Submodule Friendliness | Stable path references do not break across updates              |
| 4        | Enforceability         | Guidance expressed as checkable quality gates                   |
| 5        | Evidence-Based         | Guidance includes rationale and how-to, not opinion             |

## 1.3 Stakeholders

| Role/Name          | Contact | Expectations                                                         |
|--------------------|---------|----------------------------------------------------------------------|
| Repo Maintainers   | TBD     | Consistent agent behavior across projects without tool lock-in       |
| Contributors       | TBD     | Clear guidance for AI-assisted coding and review                      |
| Workflow Kit Teams | TBD     | Stable, referenceable standards for implementation phases             |
| Code Reviewers     | TBD     | Repeatable expectations for tests, PR quality, and change control     |

# 2. Architecture Constraints

Technical constraints:
- Must work as a standalone repository and as a git submodule.
- Must not require adoption of a specific workflow kit or runtime.
- Must not modify or depend on .specify/ internals.
- Must support multi-agent and multi-tool contexts.
- All canonical references must be addressable via stable paths.

Organizational constraints:
- Avoid becoming a competing workflow or orchestration layer.
- Remain complementary to Spec Kit, Aider, and Claude Code ecosystems.
- Preserve standalone value even without external tooling.

Conventions and stability requirements:
- Prefer well-known integration surfaces (AGENTS.md, CLAUDE.md, Aider config).
- Keep templates easy to copy into host repos.
- Maintain stable vendor paths for upstream sources (see ADR-0003).

# 3. Context and Scope

## 3.1 Business Context

System boundary: conventional-agents is a documentation and template repository
consumed by humans and tools via filesystem paths and git submodules.

Communication partners and domain I/O:

| Communication Partner       | Inputs to conventional-agents                     | Outputs from conventional-agents                               |
|----------------------------|----------------------------------------------|----------------------------------------------------------|
| Repo Maintainers           | Updates, governance decisions, reviews       | Published guidelines, role contracts, templates          |
| Contributors               | PRs, issue context                            | Structured standards and reusable artifacts              |
| Host Repositories          | Submodule pointers, path references          | Stable documentation and template paths                  |
| Agent Runtimes (Codex, Claude, Aider) | File reads, config references       | Rules, quality gates, and templates in Markdown          |
| Workflow Kits (e.g., Spec Kit) | References to standards and ADRs           | Implementable standards for downstream execution         |

## 3.2 Technical Context

Technical interfaces and channels:
- Git (clone or submodule) is the delivery channel.
- Filesystem paths are the integration surface.
- Markdown is the primary content format.

Mapping of I/O to channels:

| I/O Type                    | Channel / Interface                           |
|----------------------------|-----------------------------------------------|
| Fetch updates               | git clone / git submodule update              |
| Read guidance               | Filesystem paths (e.g., guidelines/, roles/)  |
| Consume templates           | Filesystem paths (templates/ and vendor/)     |
| Track upstream references   | Submodules under vendor/                      |

# 4. Solution Strategy

Core strategy: provide a portable briefing packet and role library in
stable locations that can be referenced by workflow tools or copied into
host repos as needed.

Key design decisions:

Decision 1: Content Organization
- Canonical content lives in guidelines/, roles/, templates/.
- Integration stubs are expected to point to canonical content.

Decision 2: Integration Pattern
- Use well-known filenames (AGENTS.md, CLAUDE.md) as references.
- Keep stubs minimal and point to canonical content in stable paths.

Decision 3: Spec Kit Relationship
- Stay adjacent, never competitive.
- Provide references for how to integrate standards with Spec Kit.
- Never touch .specify/ directory structure.

Decision 4: Role Contract Format
- Use a role-as-skill-card format with explicit gates and checks.

# 5. Building Block View

## 5.1 Whitebox Overall System

Overview (textual diagram):

conventional-agents
├── guidelines/
├── roles/
├── templates/
├── integrations/          # substrate + runtime bindings (ADR-0024, ADR-0039)
├── skills/
├── runbooks/
├── scripts/
├── workflows/
├── docs/
├── vendor/
├── INTEGRATION.md
└── README.md

Motivation:
The repository is organized around stable, human-readable files so that
agent runtimes can load guidance via filesystem paths with minimal
assumptions.

Contained Building Blocks (black boxes):

| Name              | Responsibility                                                      |
|-------------------|----------------------------------------------------------------------|
| guidelines/       | Evidence-based engineering and testing guidance                      |
| roles/            | Role contracts and shared guardrails                                 |
| templates/        | Reusable document templates (ADR, specs, reviews)                    |
| integrations/     | Substrate bindings (ADR-0024) and runtime bindings (ADR-0039). `packs/` was named "planned" here from the start and never built; the runtime binding replaces it. |
| skills/           | Portable skill modules for session management, document lifecycle, git workflow, framework health, and testing; `AUTHORING.md` carries the Agent Skills profile (ADR-0038) |
| docs/             | Architecture, ADRs, and process documentation                        |
| vendor/madr/      | ADR template and ADR documentation (framework-internal)            |
| INTEGRATION.md    | Cross-tool precedence rules and integration guidance                 |
| README.md         | Entry point and usage overview                                        |

> **Note (v2.1.0):** `vendor/conventional-commits/`, `vendor/keep-a-changelog/`,
> and `vendor/arc42-template/` were removed as consumer-facing submodules per
> ADR-0017. Only `vendor/madr/` remains as internal infrastructure. Consumers
> should use framework files and upstream URLs, not nested vendor paths.

Important Interfaces:
- Stable file paths referenced by host repos and tools.
- `vendor/madr/` for ADR templates and ADR documentation.

> **Note (v2.1.0):** `vendor/arc42-template/` was removed as a consumer-facing
> submodule per ADR-0017. `docs/ARC42.md` remains hand-curated prose following
> the arc42 structure; consumers should consult [arc42.org](https://arc42.org/)
> for the full upstream template.

## 5.2 Level 2

### White Box guidelines/

Purpose:
- Provide language-agnostic and language-specific guidance.

Key elements:
- guidelines/ROLE_CONTRACT.md
- guidelines/python/
- guidelines/bash/

### White Box roles/

Purpose:
- Define role responsibilities, guardrails, and acceptance checks.

Key elements:
- roles/ROLE_CONTRACT.md

### White Box templates/

Purpose:
- Provide reusable templates for planning, ADRs, and reviews.

Key elements:
- templates/core/
- templates/python/
- templates/reviewer/

### White Box integrations/

Purpose:
- Map the framework's six `ADR-0024` substrate capabilities onto one or more
  platforms. Each binding is normative for projects using that substrate;
  the framework itself runs on GitHub Issues and Projects.

Key elements:
- `integrations/README.md` — capability vocabulary and binding selection.
- `integrations/github-issues-projects.md` — reference binding; six
  capability mappings plus the substrate limitations table.
- `integrations/runtimes/` — runtime bindings (`ADR-0039`), mapping the
  framework's setup onto agent runtimes' configuration surfaces. The Claude
  Code binding (`FS-0030`) ships under
  `integrations/runtimes/claude-code/`; Hermes Agent, OpenClaw, and Codex
  bindings are planned, each behind its own FS/PLAN cycle.

### White Box runbooks/

Purpose:
- Record operational procedures *as performed against a real substrate*.
  Per `FS-0023`, a runbook is current-state evidence: it tells the next
  operator what actually happened, including where the substrate diverged
  from its binding.

Key elements:
- `runbooks/README.md` — status vocabulary (`current`/`stale`/`superseded`)
  and the `RB-NNNN` convention.
- `templates/core/runbook.md` — scaffold with the mandatory
  **Deviations Observed** section.

> The `packs/` building block was planned in the v2.0.0 cycle but never
> built. Its entries here are removed; if a future `packs/` returns, it
> should land via its own FS and gain its own subsection.

### White Box skills/

Purpose:
- Provide portable skill modules that encode the framework's knowledge
  into actionable guidance for agents. Each skill is a self-contained
  `SKILL.md` in the [Agent Skills](https://agentskills.io/specification)
  format, which the framework *profiles* rather than defines (`ADR-0038`);
  `skills/AUTHORING.md` carries the profile and the runtime-dialect
  boundary, and `skills/index.md` is the catalog and source-document map.

Key elements (current set):
- `skills/role-aware-session/` — session mode inference, role boundaries, safety gates.
- `skills/document-lifecycle/` — FS/PLAN/ADR lifecycle, templates, front matter hygiene.
- `skills/git-commit-identity/` — commit identity and `Agent-Attribution:` trailers
  (`ADR-0011`/`ADR-0018`/`ADR-0029`/`ADR-0036`).
- `skills/git-branch-and-commit/` — branching, Conventional Commits, commit bodies.
- `skills/gh-pr-workflow/` — pull-request lifecycle and the merge gate (`ADR-0012`).
- `skills/versioning-and-releases/` — semver, changelogs, release process.
- `skills/work-item-stance/` — `agent-stance:` entries and the autonomous gates
  (`FS-0018`, `ADR-0019`–`ADR-0022`).
- `skills/git-gh-workflow/` — deprecated router to the five above.
- `skills/framework-consumer-integration/` — host-repo integration patterns and pitfalls.
- `skills/framework-health-audit/` — `check:status`, hygiene gate, full audit procedure.
- `skills/testing-guide/` — language-specific test patterns for Python, JS/TS, Bash.
- `skills/binding-authoring/` — selecting and authoring a substrate or runtime
  binding under `integrations/` (`ADR-0024`/`ADR-0037`/`ADR-0039`).

### White Box vendor/

Purpose:
- Track upstream reference material as submodules.

Key elements:
- `vendor/madr/`

> **Note (v2.1.0):** `vendor/arc42-template/` was removed as a consumer-facing
> submodule per ADR-0017. Only `vendor/madr/` remains as framework-internal
> infrastructure.

## 5.3 Level 3

Role-as-skill-card format (applies to every role file):

# Role: [Role Name]

## Purpose
[Single sentence describing what this role does]

## Inputs Required
- [What context/files/data the agent needs]

## Outputs Expected
- [What artifacts the role produces]

## Guardrails (Boundaries)
- [What this role MUST NOT do]

## Quality Gates
- [ ] [Checkable acceptance criterion]

## Acceptance Checks
- [ ] [How to verify completion]

## Related Guidelines
- [Links to relevant guidelines]

# 6. Runtime View

## 6.1 Scenario: Submodule Sidecar (Recommended)

1) Host repo adds submodule at vendor/conventional-agents/.
2) Host repo creates a minimal AGENTS.md stub pointing to canonical paths.
3) Tools read guidelines and role contracts directly from the submodule.

## 6.2 Scenario: Spec Kit + conventional-agents Integration

1) Spec Kit memory references conventional-agents standards via stable paths.
2) Implementation work follows the referenced guidelines and gates.
3) ADRs and plans remain in the host repo, with standards referenced.

## 6.3 Scenario: Aider Integration

1) Aider config includes read paths for key guidelines and role contracts.
2) Optional conventions are copied into the host repo.

## 6.4 Scenario: Claude Code Usage

1) CLAUDE.md references canonical guidance.
2) Precedence rules are defined in INTEGRATION.md.

## 6.5 Scenario: Multi-Agent Coordination

1) Coordination rules are read from the collaboration governance documents
   (`ADR-0013`, `ADR-0031`, `FS-0019`, `FS-0021`; see §8.4 — the earlier
   reference to `guidelines/multi-agent-coordination.md` pointed at a file
   that does not exist).
2) Handoffs reference shared gates and acceptance checks.

# 7. Deployment View

## 7.1 Infrastructure Level 1

Deployment environments are documentation-centric:
- Developer workstation
- CI workspace (optional)
- Git host (source distribution)

Overview (textual diagram):

[Git Host] -> [Developer/CI Workspace] -> [Filesystem Paths]

Motivation:
The system is consumed as files; no runtime infrastructure is required.

Quality and/or Performance Features:
- Low operational overhead (no services required).
- High portability (plain Markdown and Git).

Mapping of Building Blocks to Infrastructure:
- All building blocks map to filesystem paths under the repo root.

Deployment options:

| Option    | Setup                         | Pros                                    | Cons                            | When to Use                          |
|-----------|-------------------------------|-----------------------------------------|---------------------------------|--------------------------------------|
| Copy-in   | Copy anchor files to repo root | Simple for root-only tools              | Drift risk, manual updates      | Quick prototypes, single repo        |
| Submodule | git submodule add              | Shared updates, stable references       | Requires submodule discipline   | Multi-repo standards, teams          |
| Hybrid    | Submodule + copied stubs       | Best of both                            | Slightly more complex           | Recommended for most projects        |

## 7.2 Infrastructure Level 2

No further infrastructure decomposition is required.

# 8. Cross-cutting Concepts

## 8.1 Role Contracts

- roles/ROLE_CONTRACT.md defines universal gates and guardrails.
- Role-specific files extend with additional acceptance checks.

## 8.2 Quality Gates (Checkable, Not Vibes)

Prefer:
- "Add or update tests that fail before and pass after implementation"
- "Document migration steps for schema changes"

Avoid:
- "Write clean code"
- "Make it good"

## 8.3 Context Engineering

Context engineering — what an agent is told and how — is governed by the
role contract (`guidelines/ROLE_CONTRACT.md`, "Inputs Required" per role)
and by the work-item layer (`FS-0018`): every governed action records its
`agent-stance:` entry, so scope, constraints, and success criteria are
visible in the activity record rather than scattered through chat history.
The earlier cross-reference to `guidelines/context-engineering.md` pointed
at a file that does not exist; the substance lives in `FS-0018` and in
each role's "Inputs Required" / "Stop Conditions" sections.

## 8.4 Multi-Agent Coordination

Multi-agent coordination is governed by `ADR-0013` (session coordination
model), `ADR-0031` (structured multi-model collaboration), `FS-0019`
(consensus rounds), and `FS-0021` (review boards). The collaborative
templates live in `templates/collaboration/`. The earlier cross-reference
to `guidelines/multi-agent-coordination.md` pointed at a file that does
not exist; the substance lives in those ADRs and specs.

## 8.5 Evidence-Based Practices

Minimum bar for each guideline:
1) What is the practice?
2) Why it matters (grounded rationale)
3) How to implement it (concrete example)
4) How to check it (checkable gate)

# 9. Architecture Decisions

ADRs live in `docs/decisions/`. The canonical machine-checkable index is
[`docs/decisions/README.md`](./decisions/README.md) — it is regenerated
from file front matter and is the source of truth for status, title, and
ID. The list below is a categorized summary for human readers, maintained
by hand: nothing checks it against the README. If the two disagree the
README wins, and a row here that lags a newly merged ADR is a bug in this
summary rather than a change to the decision.

## Documentation origins and templates

| ID | Title | Status |
| --- | --- | --- |
| ADR-0000 | Use MADR and arc42 template as documentation origins | accepted |
| ADR-0001 | Incorporate cross-tool portable skills as SKILL.md | accepted |
| ADR-0003 | Mirror arc42-template as an upstream-tracking git submodule | accepted |
| ADR-0008 | Adopt markdownlint for ADR Formatting Consistency | accepted |
| ADR-0009 | Feature Specification Template Selection | accepted |
| ADR-0010 | Use Custom Change Plan Template Instead of Open Source Alternative | accepted |
| ADR-0030 | Decision records versus current-state documents | accepted |
| ADR-0032 | Template and instance repository forms | proposed |
| ADR-0038 | Agent Skills as a profiled upstream standard | accepted |
| ADR-0046 | Merge the governance and operations templates | accepted |

## Integration and consumer surface

| ID | Title | Status |
| --- | --- | --- |
| ADR-0004 | AGENTS.md as Canonical Integration Surface | accepted |
| ADR-0005 | Submodule-First Referencing Strategy | accepted |
| ADR-0007 | Adjacent-to-Spec-Kit Positioning | accepted |
| ADR-0016 | Consumer conventions — local adaptations of the framework | accepted |
| ADR-0017 | Framework vendor directory is internal; consumers must not reference nested submodules | accepted |
| ADR-0024 | Platform-neutral core with shipped bindings | accepted |
| ADR-0028 | Level-triggered reconciliation | accepted |
| ADR-0034 | MCP tool category and GitHub skills consolidation | superseded |
| ADR-0037 | Executable layer for the GitHub binding | accepted |
| ADR-0039 | Agent-runtime integration bindings | accepted |
| ADR-0042 | Portable flow-report read-model — visibility profile, not a seventh capability | proposed |

## Roles, sessions, and non-overridable gates

| ID | Title | Status |
| --- | --- | --- |
| ADR-0002 | Roles reference skills via convention and skills index | accepted |
| ADR-0006 | Role-as-Skill-Card Format | accepted |
| ADR-0012 | Introduce non-overridable gates ("super-gates") in ROLE_CONTRACT | accepted |
| ADR-0013 | Multi-model session coordination model | accepted |
| ADR-0014 | Background task governance | accepted |
| ADR-0015 | Tool taxonomy and introduction process | accepted |
| ADR-0022 | Autonomous and consensus are meta-modes, not session modes | accepted |
| ADR-0035 | Concurrent-session workspace isolation | proposed |

## Attribution, identity, and history

| ID | Title | Status |
| --- | --- | --- |
| ADR-0011 | Adopt multi-identity GitHub model (human + agent-committer + agent-reviewer) | accepted |
| ADR-0018 | Single-identity workflow with agent co-attribution | accepted |
| ADR-0025 | Merge strategy preserves per-commit attribution | accepted |
| ADR-0029 | Commit-author naming for multi-model agent frameworks | accepted |
| ADR-0036 | Attribution vocabulary canon and history-integrity policy | proposed |
| ADR-0047 | Authorized intent identity and the human grant | accepted |
| ADR-0048 | Worker and publisher credential separation | accepted |

## Work-item layer and autonomous operation

| ID | Title | Status |
| --- | --- | --- |
| ADR-0019 | Issue Type immutability and the autonomous gate | accepted |
| ADR-0020 | The `question` label suppresses agent Issue actions | accepted |
| ADR-0021 | Cron actor identity for unattended agents | accepted |
| ADR-0041 | Narrow direct-to-trunk merge exception for reversible maintenance categories, audited by a maintenance digest | proposed |
| ADR-0043 | Planning fields are binding policy, not framework state — authority matrix for Priority, Iteration, and Milestone | proposed |
| ADR-0045 | Bounded autonomous runs with batch proposal-acceptance | superseded |
| ADR-0049 | Grant-based go signal for autonomous runs | accepted |

## Collaboration modes

| ID | Title | Status |
| --- | --- | --- |
| ADR-0023 | Collaboration integrity constraints | accepted |
| ADR-0031 | Structured multi-model collaboration | accepted |

## Approval and process gates

| ID | Title | Status |
| --- | --- | --- |
| ADR-0026 | Approval is a recorded act | accepted |
| ADR-0027 | PLAN self-approval within declared interfaces | accepted |
| ADR-0033 | Governance gate target resolution and configuration | accepted |

ADR-0003 is the historical decision that the framework *would* mirror
upstream as a submodule (`vendor/arc42-template/`). `ADR-0017`
supersedes it on this point: `vendor/` is now framework-internal and
consumers reference framework files or upstream URLs. ADR-0003 remains
accepted because the upstream-tracking *intent* — keep the framework's
structure in step with its sources — is real, but the mechanism moved
to a different layer.

# 10. Quality Requirements

## 10.1 Quality Requirements Overview

| Category               | Summary Requirement                                         |
|------------------------|-------------------------------------------------------------|
| Composability          | Integrate without restructuring host repositories           |
| Tool Neutrality        | Guidance usable by multiple agent runtimes                  |
| Submodule Friendliness | Stable, vendorable path references                          |
| Enforceability         | Checkable quality gates with verification steps             |
| Evidence-Based         | Rationale and examples for each guideline                   |

## 10.2 Quality Scenarios

Short-form scenarios (context, stimulus, response, metric):

- Context: Host repo adds submodule. Stimulus: new release of conventional-agents.
  Response: update submodule pointer with minimal diffs. Metric: update time
  under 10 minutes and no path breakages.

- Context: Agent runtime reads guidance. Stimulus: tool loads AGENTS.md.
  Response: consistent set of paths resolves without missing files.
  Metric: zero missing-path errors in CI or local runs.

- Context: Contributor adds a new guideline. Stimulus: PR opened.
  Response: guideline includes rationale, example, and gate.
  Metric: review checklist complete and accepted.

# 11. Risks and Technical Debts

| Risk                                   | Impact | Probability | Mitigation                                               |
|----------------------------------------|--------|-------------|----------------------------------------------------------|
| Anchor file fragmentation              | High   | Medium      | Canonical precedence rules in INTEGRATION.md             |
| Drift between copied docs and upstream | Medium | High        | Recommend submodule usage; provide sync checklist        |
| Tool interpretation differences        | Medium | Medium      | Keep stubs minimal; point to canonical docs              |
| Scope creep into workflow orchestration| High   | Medium      | Enforce non-goals and document deviations via ADRs       |
| Breaking stable paths                  | High   | Low         | Versioning and explicit path stability policy            |

# 12. Glossary

| Term              | Definition                                                     |
|-------------------|----------------------------------------------------------------|
| ADR               | Architecture Decision Record                                   |
| Anchor file       | Root-level instruction file (e.g., AGENTS.md, CLAUDE.md)        |
| Foundation layer  | Standards and role contracts independent of orchestration       |
| Quality gate      | Checkable acceptance criterion                                  |
| Role contract     | Structured definition of responsibilities and boundaries        |
| Submodule         | Git-linked external repository mounted at a stable path         |
