---
type: feature-spec
id: FS-0016
status: draft
title: Domain document type — expertise bundles for agentic work
owner: Tai
test_required: false
interfaces:
  - docs/domains/DOMAIN-XXXX-*.md (new document type)
  - docs/domains/README.md (new index)
  - docs/specifications/README.md (add FS-0016 entry)
related_adrs:
  - ADR-0017
supersedes: []
requires: []
tags:
  - domains
  - governance
  - process
created: 2026-06-29
updated: 2026-06-29
---

<!--
PARSING_HINTS:

- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly specified.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Domain Document Type — Expertise Bundles for Agentic Work

## Status

- Draft

## Summary

The framework introduces a new first-class governed document type: the Domain
(DOMAIN-XXXX). A Domain is a named bundle of skills plus metadata (default
role, default personality, description, related domains) that captures an
area of expertise or specialization of attention. Domains live in the
consuming project's `docs/domains/` directory and are governed by the same
lifecycle as FS, PLAN, and ADR documents.

Domains answer the question "what does the agent need to know about and be
good at for this kind of work?" — orthogonal to Role (authority boundaries),
Session Mode (operational stance), and Personality (tone/style).

## Goals

- Define a DOMAIN-XXXX document template with required and optional fields.
- Define the Domain lifecycle (draft → approved → implemented → deprecated).
- Establish `docs/domains/` as the canonical directory for Domain documents.
- Provide guidance for writing good Domain documents, including how to
  identify the right skill bundle and default role/personality.
- Ensure Domains compose cleanly with existing concepts (Role, Session Mode,
  Personality) without creating confusion or overlap.

## Non-Goals

- Creating a runtime Domain switcher in Hermes Agent (that is a follow-up
  feature, not part of this spec).
- Defining specific Domains for Tai's projects (those are project-level
  artifacts, not framework-level).
- Changing any existing document type, role definition, or session mode.
- Adding a new role or session mode — Domains reference existing ones.
- Making Domain activation automatic or mechanical — Domains are declarative
  governance documents; activation is a human or tool decision.

## Users / Stakeholders

- **Tai** — primary user who will define and switch between Domains for
  different work contexts (Amnesty, Feral Fleet, Legal, Programming, etc.).
- **Future conventional-agents consumers** — teams who adopt the framework
  and want to define their own expertise bundles.
- **Hermes Agent developers** — may later build a `/domain` command that
  reads DOMAIN documents to load skills and set defaults.

## Interfaces

- Type: Document template + directory convention
- Details:
  - New directory: `docs/domains/`
  - New document type: `DOMAIN-XXXX-name.md`
  - New index: `docs/domains/README.md`
  - Template: `templates/core/domain.md` (new)

## Domain Template

Every Domain document MUST use the following template:

```markdown
---
type: domain
id: DOMAIN-XXXX
status: draft
title: <short name>
owner: <owner>
skills:
  - <skill-name>  # required — at least one skill
default_role: <role-name>  # from FS-0014 six-role taxonomy
default_personality: <personality-name>  # from Hermes Agent personalities list
related_domains: []
context_pointers: []  # optional — files, KB pages, or references
tags: []
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

# Domain: <title>

## Status

- Draft | Approved | Implemented | Deprecated

## Description

One to three paragraphs describing what this domain covers, what kind of work
it's used for, and when someone would activate it.

## Skills

| Skill | Purpose | Source |
|-------|---------|--------|
| <skill-name> | <what this skill provides> | <Hermes hub / local / project> |

Each skill listed MUST exist and be loadable. If a skill is renamed or
removed, this document MUST be updated.

## Default Role

**<role-name>** — <one-sentence rationale for why this role is the default
for this domain.>

The human or session mode can override this at any time.

## Default Personality

**<personality-name>** — <one-sentence rationale for why this tone/style is
the default for this domain.>

The human can override this at any time via `/personality` or equivalent.

## Related Domains

| Domain | Relationship |
|--------|-------------|
| DOMAIN-XXXX | <overlaps, complements, depends-on, etc.> |

## Context Pointers (Optional)

- <file path or KB reference — what it provides>

## Activation Notes

Optional guidance for what to expect when activating this domain: which
session mode is most common, which toolsets are typically needed, any
pre-flight checks, etc.
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `type` | yes | Must be `domain` |
| `id` | yes | Sequential 4-digit number: `DOMAIN-XXXX` |
| `status` | yes | One of: draft, approved, implemented, deprecated |
| `title` | yes | Short human-readable name |
| `owner` | yes | Who owns this domain definition |
| `skills` | yes | Array of skill names (at least one) |
| `default_role` | yes | One of the six roles from FS-0014 |
| `default_personality` | yes | One of the Hermes Agent personalities |
| `related_domains` | no | Array of DOMAIN-XXXX IDs |
| `context_pointers` | no | Array of file paths or KB references |
| `tags` | no | Array of searchable tags |
| `created` | yes | ISO date |
| `updated` | yes | ISO date |

## Lifecycle

Domain documents follow the same lifecycle as FS and PLAN documents:

1. **Draft:** Initial creation, under development and review.
2. **Approved:** Reviewed and ready for use. A Domain at `approved` status
   is considered stable — its skill bundle, defaults, and description are
   reliable.
3. **Implemented:** The Domain is actively being used. This status signals
   that the Domain has been validated through real use.
4. **Deprecated:** The Domain is no longer active or has been superseded.

Only Domains with `status: approved` or `status: implemented` should be
considered authoritative for context-switching purposes.

### Transition Rules

- Draft → Approved: requires human review (same as FS/PLAN).
- Approved → Implemented: automatic when the Domain is first used in a real
  session.
- Implemented → Deprecated: requires a reason (superseded by another Domain,
  domain no longer relevant, etc.).
- Deprecated → (removed): Domains are never deleted; deprecated entries
  remain in the index for auditability.

## Success Criteria

- Given a new Domain document, when reviewed, then it follows the template
  exactly with all required fields populated.
- Given a Domain with `status: approved`, when activated, then the listed
  skills are loadable and the defaults are sensible for the domain's work.
- Given a Domain with `status: implemented`, when audited, then the skills
  listed still exist and the defaults are still appropriate.
- Given a Domain document, when the skills it references are renamed or
  removed, then the Domain document is flagged for update (manual process
  in initial version).

## Edge Cases

- **Domain with no skills.** Not allowed — `skills` is required with at
  least one entry. A Domain that exists only as a label is not a Domain.
- **Domain referencing a non-existent skill.** The Domain document is still
  valid as a governance artifact, but activation will fail. The document
  should be updated to reflect the current skill state.
- **Domain with no clear default role.** If a domain genuinely spans multiple
  roles equally, pick the most common one and note the ambiguity in the
  Activation Notes section.
- **Domain overlapping with another Domain.** This is expected — Amnesty and
  Legal may share skills. Use the `related_domains` field to document the
  relationship.

## Out of Scope

- Hermes Agent `/domain` command implementation.
- Automatic skill loading on Domain activation.
- Domain-specific memory filters or context file injection.
- Domain-specific toolset restrictions (too granular per earlier decision).

## Dependencies

- FS-0014: Role definitions (Domains reference roles as defaults)
- FS-0015: Session modes (Domains reference session modes in Activation Notes)
- ADR-0017: Domain concept (this spec implements the ADR's decision)

## Open Questions

- Should Domains be allowed to reference session modes as defaults, or is
  the role default sufficient? (Deferred — Activation Notes can mention
  common session modes without making them a required field.)
- Should the template include an `example_use` field showing a typical
  activation command or workflow? (Deferred — Activation Notes covers this
  informally.)
