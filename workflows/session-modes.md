---
updated: 2026-07-28
---

# Session Modes

This document defines five named session modes for agentic collaborative sessions.
A session mode describes the default role stance at the start of a session or a distinct
phase. Modes are not exclusive — a session may shift between them as the work evolves.

**When to use this document:** When beginning a session or transitioning between phases,
consult this document to identify the appropriate primary role and supporting roles. State
your interpretation in a role-transition phrase (see each mode below). The human may
override at any time.

This guidance applies to any project type where agentic models do structured work — not
only software development.

---

## Mode 1 — Architecture Planning

**Use when:** The session is deciding structure, boundaries, tradeoffs, durable
conventions, or answering "what should we do / how should this work?"

**Primary role:** Head Architect

**Supporting roles:**

- Document Author — when the outcome is likely to become an FS, ADR, or architecture
  document.
- Reviewer — when validating consistency with existing decisions before proposing new
  ones.
- Communications Lead — when the decision needs to be communicated to stakeholders
  after it is made.

**Out of scope:**

- Direct implementation unless explicitly requested and an approved PLAN exists.
- Large document rewrites unless the session shifts to Document Authoring mode.

**Escalation triggers:**

- If the discussion produces a durable decision → shift to Document Authoring mode to
  capture it.
- If the proposal conflicts with an existing ADR → activate Reviewer before proceeding.
- If the decision requires modifying ADR-0012-level gates → stop; escalate to human.

**Role-transition phrase:**
> "I'm treating this as architecture-planning, with Head Architect primary [and Document
> Author supporting, since this will likely become an ADR / FS]."

---

## Mode 2 — Document Authoring

**Use when:** The session is creating or updating governed documents: Feature Specs,
Change Plans, ADRs, README index tables, or workflow documents.

**Primary role:** Document Author

**Supporting roles:**

- Head Architect — when the document involves a new governance decision or framework
  change that needs strategic review before drafting.
- Reviewer — when the document is a revision of an existing one and consistency with
  prior decisions must be checked.

**Out of scope:**

- Implementation code or tests.
- Approving documents (human-only gate).
- Publishing or communicating the document externally before it is approved.

**Escalation triggers:**

- If the document's required content is unclear or contradictory → stop; ask the human
  rather than inferring.
- If a cross-reference points to a non-existent document → flag before committing.
- If the document touches ROLE_CONTRACT or ADR-level governance → activate Head
  Architect as supporting role.

**Role-transition phrase:**
> "Switching to document-authoring mode, Document Author primary, to draft [FS/PLAN/ADR
> name]."

---

## Mode 3 — Implementation

**Use when:** The session is executing an approved PLAN: writing deliverables, applying
a known design, making concrete changes to the project's outputs.

**Primary role:** Implementer

**Supporting roles:**

- Spec Reader and Test Planner — if tests need to be written or updated as part of the
  implementation.
- Document Author — if the implementation requires corresponding document updates (e.g.,
  status transitions, README updates).

**Out of scope:**

- Reopening design decisions that belong to Architecture Planning mode.
- Modifying specs or ADRs (Implementer reads them; does not edit them).
- Communicating the outcome externally before the implementation is reviewed.

**Escalation triggers:**

- If the approved PLAN is ambiguous or contradicts the FS → stop; do not infer; flag to
  Head Architect.
- If tests fail for unclear reasons → stop; do not commit; report.
- If the implementation reveals an undocumented architectural constraint → stop and
  escalate to Head Architect before proceeding.

**Role-transition phrase:**
> "Switching to implementation mode, Implementer primary, executing [PLAN-XXXX]."

---

## Mode 4 — Review

**Use when:** The session is checking the correctness, alignment, or completeness of a
concrete artifact: a PR diff, a completed document draft, or a proposed spec.

**Primary role:** Reviewer

**Supporting roles:**

- Head Architect — when the review reveals an architectural inconsistency that requires
  a governance-level response.
- Document Author — when the review identifies documentation gaps that should be
  addressed before the artifact is approved.

**Out of scope:**

- Fixing issues directly (Reviewer produces observations; other roles fix).
- Approving the artifact (human-only gate).
- Making implementation changes.

**Escalation triggers:**

- If contradictions are widespread enough to constitute a framework-level issue →
  escalate to Head Architect; do not attempt to resolve in-review.
- If undocumented behavior is introduced in the diff → flag; do not approve until
  documented.

**Role-transition phrase:**
> "Switching to review mode, Reviewer primary, reviewing [artifact name]."

---

## Mode 5 — Communications

**Use when:** The session is producing human-facing communication: release notes,
stakeholder summaries, INTEGRATION.md updates, or consumer-facing README sections.

**Primary role:** Communications Lead

**Supporting roles:**

- Document Author — when INTEGRATION.md or README consumer sections need updating
  alongside the communication.
- Head Architect — when the communication surfaces a gap or contradiction between
  internal governance and external-facing docs that needs resolution.

**Out of scope:**

- Internal governance document changes.
- Publishing or sending communications without human review.
- Interpreting intent beyond what the CHANGELOG and approved specs document.

**Escalation triggers:**

- If the communication would require inferring intent not documented in CHANGELOG or
  specs → stop and ask.
- If the exported surface has changed in ways not reflected in any FS → flag to Head
  Architect before drafting.

**Role-transition phrase:**
> "Switching to communications mode, Communications Lead primary, drafting [release
> notes / status summary / INTEGRATION.md update]."

---

## Overrides and Human Control

The human may declare or override the session mode at any time:

- "Act as Reviewer only." — The agent adopts Reviewer primary with no supporting roles
  unless the human specifies otherwise.
- "Stay in architecture mode." — The agent does not shift to implementation even if an
  approved PLAN exists.
- "No implementation yet." — The agent treats any implementation-ready work as out of
  scope for this session.

The agent must honor overrides without argument. If an override creates an ambiguity
(e.g., "act as Reviewer" but the artifact doesn't exist yet), the agent asks rather
than inferring.

---

## Workflows vs. session modes

Session modes describe the role stance an agent adopts *within* a phase. The SDLC
workflows at `workflows/sdlc-single-model.md` and `workflows/sdlc-multi-model.md` describe
the phase sequence the agent traverses. The two are different axes:

- **Session mode** answers *what role stance is this agent holding now?*
- **SDLC workflow** answers *what phase of the spine is this session executing?*

A session in `mode=implementation` may be at any phase from 2 through 6 of either
workflow; the phase comes from the work item and its governing FS/PLAN, not from the mode.
A meta-mode (`autonomous`, `consensus`, `review-board`) is orthogonal to the phase
sequence — it describes execution context, not phase position. `ADR-0022` makes the
distinction explicit.

When a session declares its mode, it is also implicitly declaring its leading role per
the Mode 1 mapping in `ADR-0013`. The receiving phase's leading role is the work item's
current phase's role, which the workflow documents fix.

## Adding Modes (Project-Level Customization)

These five modes cover the dominant patterns across most agentic project types. If your
project consistently encounters a pattern that does not fit any mode (e.g., a sustained
maintenance phase with a distinct role stance), add a sixth mode to your project's
`roles/session-modes.md`. Do not modify this file in `guidelines/` unless the new mode
is general enough to apply across all project types that vendor this framework.

---

## Meta-Modes: Autonomous and Consensus

Three additional mode values extend the vocabulary for specialized contexts:

- **`autonomous`** — Agent operates without a human present (cron-fired, webhook-triggered,
  or delegated subagent). Defined in FS-0018. The agent-stance comment format is the
  autonomous-equivalent of the role-transition phrase.
- **`consensus`** — Multi-model consensus round at a workflow gate. Defined in FS-0019.
  Participants perform the same task and their outputs are compared for agreement.
- **`review-board`** — Multi-model review of one artifact from different role stances.
  Defined in FS-0021. Findings are merged rather than compared; disagreement between
  seats is the product, not a failure.

`consensus` and `review-board` are mutually exclusive — a round is one or the other.
Both are collaboration rounds under ADR-0031 and both are bound by ADR-0023's
integrity constraints: different models, shipped disabled, and a gate evaluator that
did not participate.

These are **meta-modes**: they describe *how* a session is executed (unattended or
multi-model) rather than *what* role stance the agent adopts. When using a meta-mode,
the agent still declares its primary role (e.g., `role=Head Architect` with
`mode=autonomous`).

See FS-0018, FS-0019, and FS-0021 for full definitions.
