---
title: "arc42 Architecture Documentation"
system: "conventional-agents"
version: "1.0.0"
status: "Draft"
last_updated: "2026-01-28"
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
├── packs/ (planned)
├── integrations/ (planned)
├── skills/
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
| packs/ (planned)  | Copy-ready anchor files for common tools                              |
| integrations/ (planned) | Tool-specific integration guidance and precedence summaries   |
| skills/           | Example skills and guidance for skill structure                      |
| docs/             | Architecture, ADRs, and process documentation                        |
| vendor/           | Upstream references (arc42 template, MADR template/docs)             |
| INTEGRATION.md    | Cross-tool precedence rules and integration guidance                 |
| README.md         | Entry point and usage overview                                        |

Important Interfaces:
- Stable file paths referenced by host repos and tools.
- vendor/arc42-template for architecture template reference.
- vendor/madr for ADR templates and ADR documentation.

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

### White Box packs/ (planned)

Purpose:
- Provide copy-ready anchor files for common tools.

Planned elements:
- packs/agents-md/
- packs/claude/
- packs/aider/
- packs/agent-config/

### White Box integrations/ (planned)

Purpose:
- Provide tool-specific guidance and precedence summaries.

Planned elements:
- integrations/spec-kit.md
- integrations/spec-kit-plus.md
- integrations/aicodeguide.md
- integrations/tool-evaluation.md

### White Box vendor/

Purpose:
- Track upstream reference material as submodules.

Key elements:
- vendor/arc42-template/
- vendor/madr/

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

1) Coordination rules are read from guidelines/multi-agent-coordination.md.
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

See guidelines/context-engineering.md for patterns on:
- Scope definition
- Constraints
- Success criteria

## 8.4 Multi-Agent Coordination

See guidelines/multi-agent-coordination.md for handoff protocol and
decision logging.

## 8.5 Evidence-Based Practices

Minimum bar for each guideline:
1) What is the practice?
2) Why it matters (grounded rationale)
3) How to implement it (concrete example)
4) How to check it (checkable gate)

# 9. Architecture Decisions

ADRs live in docs/decisions/.

Accepted ADRs:
- ADR-0003: Mirror arc42-template as an upstream-tracking git submodule
  - Status: accepted
  - Source: docs/decisions/ADR-0003.md

Accepted ADRs:
- ADR-0003: Mirror arc42-template as an upstream-tracking git submodule
  - Status: accepted
  - Source: docs/decisions/ADR-0003.md

- ADR-0004: AGENTS.md as Canonical Integration Surface
  - Status: accepted
  - Source: docs/decisions/ADR-0004.md
  - Summary: AGENTS.md is the primary cross-tool integration surface with defined precedence hierarchy.

- ADR-0005: Submodule-First Referencing Strategy
  - Status: accepted
  - Source: docs/decisions/ADR-0005.md
  - Summary: Recommend submodule deployment as primary pattern; support copy-in and hybrid as valid alternatives.

- ADR-0006: Role-as-Skill-Card Format
  - Status: accepted
  - Source: docs/decisions/ADR-0006.md
  - Summary: Use skill-card format (Purpose, Inputs, Outputs, Guardrails, Gates, Checks) for role contracts.

- ADR-0007: Adjacent-to-Spec-Kit Positioning
  - Status: accepted
  - Source: docs/decisions/ADR-0007.md
  - Summary: Stay adjacent to Spec Kit (quality standards only, never workflow orchestration); never modify .specify/.

- ADR-0008: Adopt markdownlint for ADR Formatting Consistency
  - Status: accepted
  - Source: docs/decisions/ADR-0008.md
  - Summary: Use markdownlint with MADR-derived config to enforce consistent markdown formatting in ADRs via CI and optional local tooling.

- ADR-0009: Feature Specification Template Selection
  - Status: accepted
  - Source: docs/decisions/ADR-0009.md
  - Summary: Keep current feature-spec.md template as v1.0 with versioned evolution strategy; position GitHub Spec Kit as complementary (orchestration) not competing (standards).

Notes:
- ADR-0000, ADR-0001, and ADR-0002 are not empty (they define skills and role/skill referencing conventions).
- ADR lifecycle rules and status conventions are documented in docs/decisions/README.md.

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
