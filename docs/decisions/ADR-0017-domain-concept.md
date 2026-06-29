---
type: adr
id: ADR-0017
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0016
supersedes: []
superseded_by: null
---

<!--
PARSING_HINTS:

- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
- Use this document only to constrain or explain behavior, not to generate code.
- This ADR introduces a new first-class concept (Domain) that sits alongside
  Role, Session Mode, Render Mode, and Personality. It does not change any
  existing concept.
-->

# ADR-0017: Domain as a first-class concept — expertise bundles for agentic work

## Status

- Proposed

## Context and Problem Statement

The framework defines five layers that govern how an agent operates:

| Layer | What it controls | Where defined |
|-------|-----------------|---------------|
| **Profile** | Which config/skills/memory/infra | Hermes Agent |
| **Role** | Authority & responsibility boundaries | FS-0014, ROLE_CONTRACT |
| **Session Mode** | Which role is primary, operational stance | FS-0015, session-modes.md |
| **Render Mode** | Invocation transport & attribution | ADR-0016 |
| **Personality** | Tone & style | Hermes Agent config.yaml |

These layers answer *how* an agent works (authority, stance, transport, voice).
They do not answer *what* the agent knows about or is good at — the domain
expertise, knowledge areas, and specializations of attention that determine
which skills are relevant, which context files matter, and which default role
and personality make sense for a given kind of work.

In practice, Tai works across several distinct domains — Amnesty International
advocacy, feral-fleet infrastructure, legal case management, personal history
documentation, software development — each with its own:

- Set of skills (the amnesty skills, the homelab-IaC skill, etc.)
- Default role (Document Author for Amnesty, Head Architect for infrastructure)
- Default personality (professional/technical for legal, creative for personal history)
- Relevant context files and knowledge base pointers

Without a first-class Domain concept, switching between these contexts is
manual: load the right skills, set the right role, pick the right personality.
This is friction that accumulates across every context switch in a session.

The framework needs a way to declare, bundle, and switch these expertise
contexts as a named, documented unit.

## Decision Drivers

- **Domain expertise is orthogonal to role authority.** A Head Architect who
  specializes in legal thinks differently than one who specializes in DevOps,
  even though both have the same authority boundaries. The framework must
  separate *what you know* from *how you work*.
- **Skills already exist but lack grouping metadata.** Skills are the atomic
  unit of procedural knowledge. A Domain bundles them with metadata (default
  role, default personality, description) so the bundle is more than the sum
  of its parts.
- **Context switching is a real cost.** Every time Tai shifts between Amnesty
  work and infrastructure work, the agent needs different context. A named
  Domain makes this a single declaration rather than a multi-step setup.
- **Domains are project-level, not framework-level.** The conventional-agents
  framework defines what a Domain IS and how to declare one. The actual
  Domains (Amnesty, Feral Fleet, Legal, etc.) are project-level artifacts
  that consuming projects define for themselves.
- **Domains must compose with existing concepts.** A Domain does not replace
  Roles, Session Modes, or Personalities. It provides sensible defaults for
  them within a knowledge area, but the human can override at any time.

## Considered Options

### Option A — Domain = Skill Bundle with Metadata (CHOSEN)

A Domain is a named group of skills plus metadata: default role, default
personality, description, related domains, and optional context file pointers.
The skills already exist; the Domain just bundles them with enough metadata
to set sensible defaults. Lightweight, additive, no new runtime infrastructure
required in the framework.

**Pros:**
- Skills already exist as atomic units; Domain is a grouping layer on top
- No new runtime in conventional-agents — Domains are governance documents
- Defaults are overridable; the human always wins
- Maps naturally to Hermes Agent's existing `/skill` loading and personality system
- Backward compatible — existing skills and documents don't change

**Cons:**
- Requires a new document type (DOMAIN-XXXX) and template
- Domain metadata must be kept in sync with the skills it references
- No automatic enforcement — Domains are declarative, not mechanical

### Option B — Domain = Skill Category / Namespace

Skills are already organized under category directories (e.g.,
`autonomous-ai-agents/`, `productivity/`). The Domain IS the category.

**Pros:**
- No new document type — uses existing directory structure
- Zero additional metadata to maintain

**Cons:**
- Categories are too coarse — Amnesty and Legal would share a category
- No way to declare default role, personality, or related domains
- A skill can only belong to one category, but a skill could serve multiple domains
- Loses the metadata that makes the bundle useful

### Option C — Domain = Context Profile (heavier)

A Domain includes skills + context files + memory filters + knowledge base
pointers. Closer to a "sub-profile" — lighter than a full Hermes profile,
but heavier than a skill bundle.

**Pros:**
- Richer context switching — loads files, filters memory, points to KB pages
- More useful for complex domains like Legal with many context files

**Cons:**
- Scope creep — this is approaching Hermes Agent profile territory
- Context files and memory filters are runtime concerns, not governance
- Would require Hermes Agent changes to implement, not just conventional-agents docs
- Premature — we don't yet know which metadata beyond skills is needed

### Option D — Domain = Just a Tag/Label

Lightest possible. Tags on skills and documents. No runtime behavior change.
Organizational only.

**Pros:**
- Minimal overhead to adopt
- No new document type or template

**Cons:**
- Does not solve the context-switching problem
- No default role, personality, or skill grouping
- Tags are metadata, not a switchable unit

## Decision Outcome

**Chosen option: Option A — Domain = Skill Bundle with Metadata.**

A Domain is a first-class governed document (DOMAIN-XXXX) that declares:

- **Required skills** — the set of skills that define this domain's expertise
- **Default role** — the role most commonly used when working in this domain
- **Default personality** — the tone/style most appropriate for this domain
- **Description** — what this domain covers, when to use it
- **Related domains** — other domains that overlap or complement this one
- **Optional context pointers** — files, knowledge base pages, or other references
  that provide background for this domain (deferred from Option C — captured
  as metadata but not yet runtime-enforced)

The Domain document lives in `docs/domains/DOMAIN-XXXX-name.md` in the
consuming project (not in the conventional-agents framework itself). The
framework provides the template and lifecycle; projects define their own
Domains.

Domains compose with existing concepts:

- A Domain's default role is a suggestion, not a constraint. The human or
  session mode can override it.
- A Domain's default personality is a suggestion. The human can change it
  via `/personality` or equivalent.
- A Domain's skills are loaded when the Domain is activated. Individual skills
  can still be loaded or unloaded independently.
- A Domain does not change the active Profile, Session Mode, Render Mode, or
  Role. It provides defaults for Role and Personality within a knowledge area.

## Consequences

### Positive

- Context switching becomes a single declaration: "switch to Amnesty domain"
  loads the right skills, sets sensible defaults for role and personality.
- Domains are documented and auditable — no tribal knowledge about "which
  skills to load for Amnesty work."
- Backward compatible — existing skills, roles, session modes, and
  personalities are unchanged.
- The framework defines the *shape* of a Domain; projects define the *content*.
  This keeps the framework general and the domains specific.
- Domains can be reviewed, accepted, deprecated, and superseded like any
  other governed document.

### Negative

- New document type to maintain (DOMAIN-XXXX template, lifecycle, README index).
- Domain metadata must be kept in sync with the skills it references — if a
  skill is renamed or removed, the Domain document needs updating.
- No runtime enforcement in the initial version — Domains are governance
  documents, not executable configuration. Hermes Agent integration is a
  follow-up.

### Neutral

- The first Domains will be defined by Tai for his own projects (Amnesty,
  Feral Fleet, Legal, Programming, Personal History). This serves as the
  validation corpus for the template.
- Hermes Agent could later add a `/domain` slash command that loads the
  bundled skills and sets defaults. This is a natural extension but not
  required for the governance concept to be useful.

## Validation

We will consider this decision successful if:

1. **Template usability.** At least three DOMAIN documents exist in
   conventional-agents or a consuming project, each referencing real skills
   and setting sensible defaults.
2. **Context-switch reduction.** After adopting Domains, Tai reports that
   switching between work contexts (e.g., Amnesty → Feral Fleet) requires
   fewer manual steps than before.
3. **No concept confusion.** New contributors can distinguish Domain from
   Role, Session Mode, and Personality without additional explanation.
4. **Hermes Agent integration (follow-up).** If a `/domain` command or
   equivalent is added to Hermes Agent, it uses the DOMAIN document as its
   source of truth — not a parallel config.

Review checkpoints:

- After three DOMAIN documents are drafted: review the template for missing
  fields or unnecessary complexity.
- After six months: evaluate whether Domains are being used as intended or
  whether they've drifted into Role or Profile territory.

## Links

- FS-0016: Domain document spec (DOMAIN-XXXX template, lifecycle, metadata schema)
- FS-0014: Role definitions overhaul (Domains reference roles as defaults)
- FS-0015: Role selection and session modes (Domains reference session modes as defaults)
- ADR-0016: Multi-model session orchestration (Domains are orthogonal to render modes)
- ROLE_CONTRACT: Role definitions (Domains do not change role authority boundaries)
