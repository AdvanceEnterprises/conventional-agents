---
name: Work item
about: File a governed work item (Type / Label / Phase) per FS-0018
title: "[type]: brief description"
labels: []
assignees: []
---

<!-- Pick your labels after opening: one content label and one position
label from the FS-0018 six (see below). The default is intentionally
empty to avoid defaulting to `enhancement` for every issue type. -->

## Work Item

- **Type:** `feature` | `bug` | `task` (single value — FS-0018 Axis 1)
- **Label:** `enhancement` | `bug` | `documentation` | `spec` | `plan` | `question` (the FS-0018 six — pick one content label and one position label)
- **Phase:** `Backlog` | `Approved` | `In Progress` | `In Review` | `Done` (FS-0018 five named phases)

## What

One paragraph: the specific guideline, template, gate, or gap.

## Why

The evidence or rationale — this framework is evidence-based
(CONTRIBUTING). E.g., "Current guidance causes X problem",
"We tested Y approach and found Z", "Gate G fails open when...".

## Context

Links to any governing FS/PLAN/ADR this touches, or consumer projects
affected (external contributors may leave this blank).

## Proposed action (if known)

What change would resolve this — targeted and scoped.

<!--
Per FS-0018: the work item is the first governed artifact — it exists
before any FS/PLAN/ADR. Type keyed checkpoints (ADR-0019): `feature`
and `bug` items may not advance past **Approved**, `task` items may
not advance past **In Progress** without human approval.
-->
