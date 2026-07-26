---
type: adr
id: ADR-0016
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0014
superseded_by: null
---

# ADR-0016: Instance conventions — local adaptations of the framework

## Status

- Proposed

## Context and Problem Statement

The framework defines reusable conventions for agentic development: role
contracts, document lifecycles, tool taxonomies, and workflow patterns. These
are designed to be consumed by any project that adopts the framework.

However, every consumer of the framework also has **instance-specific**
conventions — decisions that are not reusable because they depend on the
consumer's particular setup, tooling, team structure, or personal workflow
preferences.

Examples of instance-specific decisions include:

- Which project management tool (Notion, Linear, Trello) serves as the task
  board, and how it relates to GitHub Issues
- How the consumer's particular directory of repos maps to their personal or
  organizational taxonomy (e.g., "Orbits")
- Which specific GitHub identities are used for agent-committer vs
  agent-reviewer roles
- Custom CI/CD workflows that are specific to the consumer's infrastructure
- Personal conventions about when to use which AI model

Without a designated place for instance-specific conventions, consumers face
two bad options:

1. **Pollute the framework** — Add instance-specific ADRs to `docs/decisions/`,
   where they appear alongside framework-level decisions and confuse future
   consumers about what's reusable vs what's local.
2. **No documentation at all** — Instance-specific decisions go undocumented,
   leading to drift, confusion, and inconsistent agent behavior across sessions.

This ADR introduces a third option: a designated `docs/instances/` directory
where consumers document their local adaptations using the same ADR format,
explicitly scoped as instance-level rather than framework-level.

## Decision Drivers

- **Framework hygiene** — Instance-specific decisions must not pollute the
  framework's `docs/decisions/` directory. A consumer browsing framework ADRs
  should see only reusable decisions.
- **Discoverability** — Instance-specific decisions must be findable by agents
  and humans working in the consumer's environment. They should not be hidden
  in private Notion pages or personal notes.
- **Format consistency** — Instance-specific decisions should use the same ADR
  format as framework decisions, so agents can parse and reason about them
  with the same tooling.
- **Scope clarity** — It must be immediately obvious whether a given ADR is
  framework-level or instance-level, without reading the full document.
- **Multiple instances** — The framework may be consumed by multiple instances
  (e.g., a team's shared instance and an individual's personal instance).
  The directory structure must support this.
- **Low ceremony** — Instance conventions should be easy to create and update.
  They should not require the same FS/PLAN lifecycle as framework changes,
  because they don't affect the framework's reusable surface.

## Considered Options

### Option A: Instance ADRs live in `docs/decisions/` with a scope marker

Add a `decision_scope: instance` value to the existing front matter, and allow
instance-specific ADRs to coexist with framework ADRs in the same directory.

### Option B: Separate `docs/instances/` directory

Create a `docs/instances/` directory at the repo root. Each instance gets a
subdirectory (`docs/instances/<name>/`). Instance ADRs live there, using the
same MADR template and front matter format, with `decision_scope: instance`.

### Option C: Instance conventions live outside the repo entirely

Consumers document instance-specific decisions in their own private system
(Notion, a separate private repo, a local file). The framework does not
provide a mechanism for this.

### Option D: Instance conventions as a new document type (not ADRs)

Create a new document type (e.g., "Instance Convention" or "IC") with its own
template, lifecycle, and directory, separate from ADRs.

## Decision Outcome

**Chosen option: Option B — Separate `docs/instances/` directory.**

### Structure

```
docs/instances/
├── README.md                    # Index and explanation of the directory
└── <instance-name>/
    ├── INSTANCE.md              # Instance metadata (optional)
    ├── ADR-0001.md              # Instance-specific decisions
    ├── ADR-0002.md
    └── ...
```

### Rules

1. **Instance ADRs use the same MADR template** as framework ADRs, with one
   difference: `decision_scope` MUST be set to `instance`.

2. **Instance ADRs are not framework ADRs.** They are not listed in
   `docs/decisions/README.md`. They are listed in `docs/instances/README.md`
   and the instance's own index.

3. **Instance ADRs do not require FS/PLAN lifecycle.** They may be created,
   updated, or superseded directly via PR, without a feature spec or change
   plan. This reflects their lower scope: they affect only the instance, not
   the framework.

4. **Instance ADRs may reference framework ADRs** as constraints (e.g., "per
   ADR-0011, we use three GitHub identities"). They may also reference other
   instance ADRs.

5. **The `docs/instances/` directory is part of the framework repo.** It is
   not gitignored or treated as a separate module. This ensures instance
   conventions are versioned alongside the framework version they apply to.

6. **Multiple instances are supported.** Each instance gets its own
   subdirectory. The instance name should be short and descriptive (e.g.,
   `tais-den`, `acme-corp`).

7. **An `INSTANCE.md` file** in the instance directory MAY provide metadata:
   owner, scope, contact, list of repos the instance covers, and any other
   context that helps an agent or human understand the instance.

### Why not the other options?

**Option A** (instance ADRs in `docs/decisions/`) would mix framework and
instance decisions in the same namespace and index. A consumer browsing
framework ADRs would have to check `decision_scope` on every entry to know
whether a decision applies to them. This undermines framework hygiene.

**Option C** (outside the repo) loses versioning, discoverability, and
consistency. Instance decisions would drift from the framework version they
were made against, and agents would have no reliable way to find them.

**Option D** (new document type) adds unnecessary complexity. Instance
decisions are still architecture decisions — they just have a narrower scope.
Using the ADR format with a different `decision_scope` value reuses existing
tooling and mental models without inventing a new document type.

### Consequences

**Good:**

- Framework ADRs remain clean and reusable. Instance-specific decisions are
  clearly separated.
- Instance ADRs are versioned alongside the framework, so the relationship
  between a framework version and the instance's local adaptations is always
  clear.
- Agents can find instance conventions by looking in `docs/instances/` — a
  predictable location.
- The same ADR parsing and reasoning tooling works for both framework and
  instance ADRs.
- Multiple instances are supported without namespace conflicts.

**Bad:**

- The framework repo now contains content that is not universally applicable.
  Consumers who don't use instance conventions will have an empty or sparse
  `docs/instances/` directory.
- Instance ADRs that are sensitive (e.g., containing internal infrastructure
  details) cannot be stored here if the repo is public. Those instances should
  use a private fork or a separate private repo with the same structure.

**Neutral:**

- The boundary between "framework ADR" and "instance ADR" requires judgment.
  A decision that starts as instance-specific may later be generalized into a
  framework ADR. This is a natural evolution path, not a problem.
- Instance ADRs use the same sequential numbering as framework ADRs but in a
  separate namespace per instance. Instance `ADR-0001` is unrelated to
  framework `ADR-0001`.

## Validation

We will consider this decision successful if:

1. A new consumer of the framework can create an instance directory and write
   their first instance ADR in under 15 minutes, using only the framework docs
   as reference.
2. An agent working in an instance can find and correctly interpret instance
   ADRs by checking `docs/instances/<name>/`.
3. No instance-specific ADRs appear in `docs/decisions/` after this ADR is
   accepted.
4. Framework consumers report that the separation is intuitive and does not
   require explanation beyond what's in this ADR.

## Links

- ADR-0000: Use MADR and arc42 template as documentation origins
- ADR-0009: Separate exported surface from internal governance docs
- FS-0014: Six-role model (role assignments)
- `docs/instances/README.md` — Instance conventions index
