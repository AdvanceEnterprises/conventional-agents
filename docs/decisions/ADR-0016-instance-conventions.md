---
type: adr
id: ADR-0016
status: accepted
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0014
superseded_by: null
---

# ADR-0016: Consumer conventions — local adaptations of the framework

## Status

- Accepted

## Context and Problem Statement

The framework defines reusable conventions for agentic development: role
contracts, document lifecycles, tool taxonomies, and workflow patterns. These
are designed to be consumed by any project that adopts the framework.

However, every consumer of the framework also has **consumer-specific**
conventions — decisions that are not reusable because they depend on the
consumer's particular setup, tooling, team structure, organization, or personal
workflow preferences.

Examples of consumer-specific decisions include:

- Which project management tool (Notion, Linear, Trello) serves as the task
  board, and how it relates to GitHub Issues
- How the consumer's particular directory of repos maps to their personal or
  organizational taxonomy
- Which specific GitHub identities are used for agent-committer vs
  agent-reviewer roles
- Custom CI/CD workflows that are specific to the consumer's infrastructure
- Personal conventions about when to use which AI model

Without a designated place for consumer-specific conventions, consumers face
two bad options:

1. **Pollute the framework** — Add consumer-specific ADRs to `docs/decisions/`,
   where they appear alongside framework-level decisions and confuse future
   consumers about what's reusable vs what's local.
2. **No documentation at all** — Consumer-specific decisions go undocumented,
   leading to drift, confusion, and inconsistent agent behavior across sessions.

This ADR introduces a third option: a **separate consumer conventions
repository** where consumers document their local adaptations using the same ADR
format, explicitly scoped as consumer-level rather than framework-level.

## Decision Drivers

- **Framework hygiene** — Consumer-specific decisions must not pollute the
  framework's `docs/decisions/` directory or ship inside the framework's vendor
  tree. A consumer browsing framework ADRs should see only reusable decisions.
- **Discoverability** — Consumer-specific decisions must be findable by agents
  and humans working in the consumer's environment. They should not be hidden
  in private Notion pages or personal notes.
- **Format consistency** — Consumer-specific decisions should use the same ADR
  format as framework decisions, so agents can parse and reason about them
  with the same tooling.
- **Scope clarity** — It must be immediately obvious whether a given ADR is
  framework-level or consumer-level, without reading the full document.
- **Multiple consumers** — The framework may be consumed by multiple consumers
  (e.g., a team's shared conventions and an individual's personal conventions).
  The structure must support this without namespace conflicts.
- **Low ceremony** — Consumer conventions should be easy to create and update.
  They should not require the same FS/PLAN lifecycle as framework changes,
  because they don't affect the framework's reusable surface.
- **Independent versioning** — Consumer conventions should be versioned
  independently from the framework, so consumers can update their local
  conventions without waiting for a framework release, and vice versa.

## Considered Options

### Option A: Consumer ADRs live in `docs/decisions/` with a scope marker

Add a `decision_scope: consumer` value to the existing front matter, and allow
consumer-specific ADRs to coexist with framework ADRs in the same directory.

### Option B: Separate `docs/consumers/` directory inside the framework repo

Create a `docs/consumers/` directory at the repo root. Each consumer gets a
subdirectory (`docs/consumers/<name>/`). Consumer ADRs live there, using the
same MADR template and front matter format, with `decision_scope: consumer`.

### Option C: Consumer conventions live in a separate repository

Consumers document consumer-specific decisions in a dedicated repository
(e.g., an organization conventions repo or a personal conventions repo). The
framework provides only a template and integration guidance.

### Option D: Consumer conventions as a new document type (not ADRs)

Create a new document type (e.g., "Consumer Convention" or "CC") with its own
template, lifecycle, and directory, separate from ADRs.

## Decision Outcome

**Chosen option: Option C — Consumer conventions live in a separate repository.**

The repository may be dedicated to a single consumer, or it may serve a team or
organization. For organizations, we use the term **organization conventions**
(abbreviated "org conventions"). For individuals or non-organizational groups,
we use the term **consumer conventions**.

### Structure

A consumer conventions repository is a small documentation repository with
its own governance, optionally vendoring the framework for its own use.

```text
tais-den-conventions/
├── README.md                    # Consumer/org overview, how to consume
├── ADR-0001.md                  # Consumer-specific decisions
├── ADR-0002.md
├── ...
└── vendor/conventional-agents/  # Framework submodule (optional, for dogfooding)
```

### Consuming pattern

Projects that follow the consumer conventions vendor both the framework and the
consumer conventions repository as sibling submodules. They must not rely on
a nested framework path inside the consumer conventions repository.

```text
feral-fleet/
├── vendor/conventional-agents/     # Framework
├── vendor/tais-den-conventions/  # Consumer conventions
└── AGENTS.md
```

AGENTS.md references both:

```markdown
## Foundation Standards
- vendor/conventional-agents/guidelines/ROLE_CONTRACT.md
- vendor/conventional-agents/INTEGRATION.md

## Consumer Conventions
- vendor/tais-den-conventions/README.md
- vendor/tais-den-conventions/ADR-0001-notion-github-boundary.md
```

### Rules

1. **Consumer ADRs use the same MADR template** as framework ADRs, with one
   difference: `decision_scope` MUST be set to `consumer` (or `organization` for
   org conventions).

2. **Consumer ADRs are not framework ADRs.** They are not listed in the
   framework's `docs/decisions/README.md`. They are listed in the consumer
   repository's own index.

3. **Consumer ADRs do not require FS/PLAN lifecycle.** They may be created,
   updated, or superseded directly via PR, without a feature spec or change
   plan. This reflects their lower scope: they affect only the consumer, not
   the framework's reusable surface.

4. **Consumer ADRs may reference framework ADRs** as constraints (e.g., "per
   ADR-0011, we use three GitHub identities"). They may also reference other
   consumer ADRs.

5. **Consumer conventions live outside the framework repo.** They are not part
   of the framework's vendor tree. This prevents personal or
   organization-specific content from being included in every framework
   consumer's checkout.

6. **Multiple consumers are supported.** Each consumer has its own repository
   or clearly separated directory within a shared conventions repository.

7. **A `README.md` file** in the consumer conventions repository SHOULD
   provide metadata: owner, scope, list of repos the conventions cover, and
   any other context that helps an agent or human understand the consumer.

### Why not the other options?

**Option A** (consumer ADRs in `docs/decisions/`) would mix framework and
consumer decisions in the same namespace and index. A consumer browsing
framework ADRs would have to check `decision_scope` on every entry to know
whether a decision applies to them. This undermines framework hygiene and fails
to solve the pollution problem.

**Option B** (consumer content inside the framework repo) would ship
consumer-specific content to every framework consumer. Personal Notion URLs,
organization-specific identity mappings, and private infrastructure details
would appear inside `vendor/conventional-agents/` for any project that uses the
framework. This is exactly the pollution this ADR is intended to prevent.

**Option D** (new document type) adds unnecessary complexity. Consumer
decisions are still architecture decisions — they just have a narrower scope.
Using the ADR format with a different `decision_scope` value reuses existing
tooling and mental models without inventing a new document type.

### Consequences

**Good:**

- Framework ADRs remain clean and reusable. Consumer-specific decisions are
  physically separated from the framework.
- Consumer conventions are versioned independently from the framework.
- Agents can find consumer conventions by looking in a predictable location
  (the consumer conventions repo) rather than hunting across Notion pages or
  private files.
- The same ADR parsing and reasoning tooling works for both framework and
  consumer ADRs.
- Multiple consumers can share the framework without sharing each other's local
  conventions.
- Sensitive consumer details (private infrastructure, personal tool URLs) can
  live in a private consumer conventions repo without affecting the public
  framework.

**Bad:**

- Consumers must set up and maintain a second repository for their conventions.
  This is slightly more overhead than a directory inside the framework repo.
- Consuming projects must vendor both the framework and the consumer
  conventions repo as sibling submodules.
- The relationship between framework version and consumer conventions version
  must be managed by the consumer.

**Neutral:**

- The boundary between "framework ADR" and "consumer ADR" requires judgment.
  A decision that starts as consumer-specific may later be generalized into a
  framework ADR. This is a natural evolution path, not a problem.
- Consumer ADRs use the same sequential numbering as framework ADRs but in a
  separate namespace per consumer. Consumer `ADR-0001` is unrelated to
  framework `ADR-0001`.
- The consumer conventions repository may vendor the framework for its own
  dogfooding, but consuming projects must not rely on that nested path.

## Validation

We will consider this decision successful if:

1. A new consumer of the framework can create a consumer conventions repository
   and write their first consumer ADR in under 30 minutes, using the framework
   docs as reference.
2. An agent working in a consuming project can find and correctly interpret
   consumer ADRs by checking the consumer conventions repository.
3. No consumer-specific ADRs appear in `docs/decisions/` or `docs/consumers/`
   after this ADR is accepted.
4. Framework consumers report that the separation is intuitive and does not
   require explanation beyond what's in this ADR.
5. At least one consuming project vendors both the framework and a consumer
   conventions repository as sibling submodules without relying on nested paths.

## Links

- ADR-0000: Use MADR and arc42 template as documentation origins
- ADR-0009: Separate exported surface from internal governance docs
- FS-0014: Six-role model (role assignments)
- INTEGRATION.md: Consuming consumer conventions alongside the framework
- Example consumer conventions repository: Tais-Den/tais-den-conventions
  (to be created)
