# Feature Specifications

Feature Specs (FS-XXXX) document the requirements and acceptance criteria for implementing features, tools, and processes in agentic-dev-kit.

## Purpose

Feature Specs serve as the bridge between:
- **Architecture Decisions (ADRs):** Document the "why" of decisions (what we've decided and why)
- **Implementation:** Document the "what" of features (requirements, success criteria, rollout plan)

Unlike ADRs which record decisions made, feature specs document the concrete requirements and behaviors needed to implement those decisions.

## Naming Convention

Feature Specs follow the pattern: `FS-XXXX-descriptive-name.md`

- **Prefix:** `FS` (Feature Spec)
- **ID:** Sequential 4-digit number (FS-0001, FS-0002, etc.)
- **Description:** Kebab-case, descriptive title
- **Location:** This directory (`docs/specifications/`)

## Lifecycle

Feature Specs progress through the following statuses:

1. **Draft:** Initial creation, under development and review
2. **Approved:** Reviewed and ready for implementation
3. **Implemented:** Implementation work is complete
4. **Deprecated:** Spec is no longer active or has been superseded

Only specs with `status: approved` should be actively implemented.

## Template

All feature specs must use the template defined in `templates/core/feature-spec.md`. The template includes required sections:

- **Status:** Current lifecycle stage
- **Summary:** One-paragraph overview
- **Goals:** What the feature enables
- **Non-Goals:** What it explicitly does not do
- **Users / Stakeholders:** Who is affected
- **Interfaces:** Public surface area (CLI, API, Config, CI, etc.)
- **Success Criteria:** Objective, testable acceptance criteria using Given-When-Then format
- **Edge Cases:** Non-typical scenarios
- **Out of Scope:** Explicit exclusions to prevent scope creep
- **Dependencies:** What this depends on
- **Rollout / Migration:** How to deploy (if applicable)
- **Observability:** Logs, metrics, tracing (if applicable)
- **Security / Privacy:** Data handling and threat mitigations (if applicable)
- **Open Questions:** Only blocking questions

## Relationship to ADRs

| Aspect | ADR | Feature Spec |
|--------|-----|------|
| **Purpose** | Record a decision and its rationale | Document requirements to implement a decision |
| **Type** | Architecturally significant | Feature/tool/process implementation |
| **Audience** | Stakeholders, reviewers | Developers, QA, implementation team |
| **Status** | Proposed, Accepted, Deprecated | Draft, Approved, Implemented, Deprecated |
| **Contains** | Context, options, decision, consequences | Goals, non-goals, success criteria, rollout |
| **Example** | "We decided to use markdownlint" (ADR-0008) | "How to set up markdownlint and enforce it" (FS-0001) |

## Current Specifications

- **FS-0001:** [Markdownlint Integration for ADR Quality Gates](FS-0001-markdownlint-implementation.md) – Implement ADR-0008's markdownlint adoption
