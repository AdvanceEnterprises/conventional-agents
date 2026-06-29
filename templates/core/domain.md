---
type: domain
id: DOMAIN-XXXX
status: draft
title: <short name>
owner: <owner>
skills:
  - <skill-name>
default_role: <role-name>
default_personality: <personality-name>
related_domains: []
context_pointers: []
tags: []
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

<!--
PARSING_HINTS:

- This document defines a Domain — a named bundle of skills plus metadata.
- Domains are orthogonal to Roles (authority), Session Modes (stance), and
  Personalities (tone). They capture expertise and attention focus.
- The default_role and default_personality are suggestions, not constraints.
  The human can override at any time.
- Skills listed here MUST exist and be loadable. If a skill is renamed or
  removed, this document MUST be updated.
-->

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
