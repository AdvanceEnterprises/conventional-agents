---
type: feature-spec
id: FS-0015
status: draft
title: Role selection and session modes
owner: Tai
test_required: false
interfaces:
  - guidelines/ROLE_CONTRACT.md (add best_used_when/avoid_when to each role; add explainability rule to shared rules)
  - roles/ROLE_CONTRACT.md (sync with guidelines/)
  - workflows/session-modes.md (new)
  - docs/specifications/README.md
related_adrs:
  - ADR-0002
  - ADR-0006
  - ADR-0012
supersedes: []
requires:
  - FS-0014
tags:
  - roles
  - governance
  - process
  - sessions
created: 2026-06-08
updated: 2026-06-08
---

<!--
PARSING_HINTS:

- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.

-->

# Feature Spec: Role Selection and Session Modes

## Status

- Draft

## Summary

The framework defines six role contracts but gives no guidance on when to apply each
role, how a session should declare its primary stance, or how an agent should signal a
role transition mid-session. Without this, agents default to either over-applying all
roles simultaneously or staying in an inappropriate role after the session has shifted.
This spec addresses that gap through document-governed guidance — not a new routing
subsystem.

**Architectural decision:** Role selection is governed by documents, not delegated to a
separate routing component. The mechanism is a workflow document, expanded role
contract guidance, and a lightweight explainability convention enforced through
ROLE_CONTRACT shared rules.

This framework is designed for use in any project type where agentic models do
structured work — not only software development. Session modes and role selection
guidance are deliberately general.

---

## Goals

- Add `best_used_when` and `avoid_when` guidance to each of the six roles in
  ROLE_CONTRACT, so agents have clear selection pressure without a decision tree.

- Add a `workflows/session-modes.md` document defining five named session modes, each
  with a primary role, supporting roles, out-of-scope boundaries, escalation triggers,
  and a role-transition phrase template.

- Add an explainability rule to ROLE_CONTRACT shared rules: agents must briefly declare
  their active role and session mode when the role stance changes in a way that affects
  the work, and when entering a session where role choice is non-obvious.

- Add escalation and override rules to `workflows/session-modes.md` so session modes
  are operational, not decorative.

## Non-Goals

- Creating a separate routing component, routing rules file, or role dispatcher.
- Adding roles beyond the six defined in FS-0014.
- Making role selection mechanically enforced (it remains interpretive and
  human-overridable).
- Per-role separate files (ROLE_CONTRACT remains consolidated).
- Defining sub-role profiles for domain-specific contexts (e.g., security-sensitive
  implementation) — those belong in project-level customization of `roles/`.

---

## Role Selection Guidance (for ROLE_CONTRACT)

Each role gains two compact sub-sections. The point is practical selection pressure,
not an exhaustive decision tree.

### Role 0 — Head Architect

**Best used when:**

- The session involves strategic direction, framework evolution, or a question of "what
  should we do or build?"
- Cross-role ambiguity exists and needs resolution via an ADR proposal.
- A framework health audit is needed (stale statuses, process gaps, drift).
- A new FS or ADR needs to be proposed (even if Document Author will draft it).

**Avoid when:**

- A decision is already made and approved — shift to Document Author or Implementer.
- The work is purely editorial with no governance implications.
- The session is executing a clearly scoped, approved PLAN.

---

### Role 1 — Document Author

**Best used when:**

- Creating or updating governed documents: FS, PLAN, ADR.
- Reconciling stale statuses, updating index tables, or running `npm run check:status`.
- The Head Architect has identified what needs to be documented and the task is
  execution, not strategy.

**Avoid when:**

- Strategic direction is still undecided — wait for Head Architect guidance before
  drafting.
- The session is in review mode and no documents need updating.
- Implementation is underway and no doc changes are in scope.

---

### Role 2 — Spec Reader and Test Planner

**Best used when:**

- An FS with `status: approved` exists and needs tests written before implementation
  begins.
- The goal is translating acceptance criteria into executable tests, not writing code.

**Avoid when:**

- The governing FS does not yet have `status: approved`.
- `test_required: false` is set in the FS front matter.
- Implementation is already complete and tests are being written retroactively (flag
  this as a process exception).

---

### Role 3 — Implementer

**Best used when:**

- Failing tests exist and an approved FS + PLAN define exactly what to build.
- The work is executing a known, bounded change — not exploring what to do.
- All pre-implementation gates are satisfied (approved FS, approved PLAN, tests exist).

**Avoid when:**

- Design decisions are still open — stop and escalate to Head Architect.
- No approved spec or plan exists.
- The work is primarily creating or updating governance documents.

---

### Role 4 — Reviewer

**Best used when:**

- A concrete artifact exists to review: a PR diff, a completed document draft, a
  proposed spec or ADR.
- The goal is identifying mismatches, gaps, or conflicts — not fixing them.

**Avoid when:**

- There is nothing concrete to review yet (the session is still in planning or
  authoring mode).
- The reviewer has already flagged an issue and the fix is underway — hand off to the
  appropriate role rather than re-reviewing in progress work.

---

### Role 5 — Communications Lead

**Best used when:**

- A release or milestone is ready to communicate and needs human-facing framing.
- `INTEGRATION.md`, consumer-facing README sections, or GitHub Release descriptions
  need updating.
- A stakeholder or team status summary is requested.

**Avoid when:**

- Internal governance documents are being actively modified (let Document Author
  finish first).
- The implementation is not complete — do not communicate outcomes prematurely.
- Strategic decisions are still being made (Communications Lead does not interpret
  intent; it translates completed work).

---

## Session Modes (for `workflows/session-modes.md`)

Five named modes cover the dominant patterns of agentic collaborative sessions. Modes
are not exclusive — a session may shift from one mode to another. The mode describes
the *default stance at the start of a session or a distinct phase*, not a permanent
constraint.

A session mode is inferred from context when not declared. When the agent infers a
mode, it should state that inference in a role-transition phrase (see Explainability
Convention below) so the human can correct it.

---

### Mode 1 — Architecture Planning

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

- If the discussion produces a durable decision → shift to Document Authoring to
  capture it.
- If the proposal conflicts with an existing ADR → activate Reviewer before proceeding.
- If the decision requires modifying ADR-0012-level gates → stop; escalate to human.

**Role-transition phrase:**
> "I'm treating this as architecture-planning, with Head Architect primary [and
> Document Author supporting, since this will likely become an ADR / FS]."

---

### Mode 2 — Document Authoring

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

### Mode 3 — Implementation

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

- If the approved PLAN is ambiguous or contradicts the FS → stop; do not infer; flag
  to Head Architect.
- If tests fail for unclear reasons → stop; do not commit; report.
- If the implementation reveals an undocumented architectural constraint → stop and
  escalate to Head Architect before proceeding.

**Role-transition phrase:**
> "Switching to implementation mode, Implementer primary, executing [PLAN-XXXX]."

---

### Mode 4 — Review

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

### Mode 5 — Communications

**Use when:** The session is producing human-facing communication: release notes,
stakeholder summaries, `INTEGRATION.md` updates, or consumer-facing README sections.

**Primary role:** Communications Lead

**Supporting roles:**

- Document Author — when `INTEGRATION.md` or README consumer sections need updating
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

## Explainability Convention (for ROLE_CONTRACT shared rules)

The following rule is added to ROLE_CONTRACT under Shared Rules:

> **Role and session transparency**
>
> When beginning a session where role choice is non-obvious, or when the active role
> stance shifts in a way that affects the work, the agent must state:
>
> 1. Which session mode is active (declared or inferred).
> 2. Which role is primary.
> 3. Which roles are supporting, if any.
>
> One sentence is sufficient. The human may override the interpretation at any time.
> If overridden, the agent adopts the stated role without argument.
>
> This is not optional ceremony — it is the mechanism by which humans stay in control
> of agentic sessions without needing to read every tool call.

---

## Users / Stakeholders

- **Tai** — framework owner; needs role selection to be legible and correctable without
  interrupting flow.
- **Agents** — need clear selection pressure to avoid defaulting to an inappropriate
  role or applying all roles simultaneously.
- **Any project team** vendoring this framework — session modes should be general
  enough to apply to any domain where agentic models do structured work.

## Interfaces

- **`guidelines/ROLE_CONTRACT.md`** — add `best_used_when` / `avoid_when` to each of
  the six role definitions; add explainability rule to Shared Rules.
- **`roles/ROLE_CONTRACT.md`** — sync with `guidelines/` per FS-0014 model.
- **`workflows/session-modes.md`** — new document defining the five session modes.
- **`docs/specifications/README.md`** — add FS-0015 row.

## Success Criteria

Each bullet MUST be objectively testable.

- Given the updated ROLE_CONTRACT, when reading each of the six role definitions, then
  each contains a `Best used when` section and an `Avoid when` section.
- Given the updated ROLE_CONTRACT, when reading Shared Rules, then it contains a role
  and session transparency rule specifying when agents must declare mode, primary role,
  and supporting roles.
- Given `workflows/session-modes.md`, when listing all mode headings, then exactly five
  modes are present: Architecture Planning, Document Authoring, Implementation, Review,
  Communications.
- Given any session mode definition, when reading it, then it contains: purpose, primary
  role, supporting roles, out of scope, escalation triggers, and a role-transition
  phrase.
- Given the updated ROLE_CONTRACT and `workflows/session-modes.md`, when running
  `npm run check:status`, then it exits zero.
- Given the updated ROLE_CONTRACT, when comparing `roles/ROLE_CONTRACT.md` and
  `guidelines/ROLE_CONTRACT.md`, then `roles/` contains the same `best_used_when` /
  `avoid_when` sections and the same explainability rule.

## Edge Cases

- A session may shift modes mid-session. The explainability convention handles this —
  the agent declares the shift; it does not require starting a new session.
- A session that is explicitly declared by the human ("act as Reviewer only") overrides
  any inferred mode. The agent must honor it without argument, even if the session
  content seems to call for a different role.
- The Head Architect role spans all modes as a potential supporting role. This is
  intentional — it is the meta-role and does not belong exclusively to Architecture
  Planning mode.

## Out of Scope

- A routing component, routing rules file, or dispatcher of any kind.
- Adding roles beyond the six defined in FS-0014.
- Domain-specific sub-role profiles (e.g., security-sensitive implementer guidance) —
  those belong in project-level customization of `roles/ROLE_CONTRACT.md`.
- Mechanically enforcing mode selection (it remains interpretive and human-overridable).

## Dependencies

- FS-0014: defines the six roles that this spec extends.

## Rollout / Migration

1. Add `best_used_when` / `avoid_when` to each of the six roles in
   `guidelines/ROLE_CONTRACT.md`.
2. Add explainability rule to Shared Rules in `guidelines/ROLE_CONTRACT.md`.
3. Sync both changes to `roles/ROLE_CONTRACT.md`.
4. Create `workflows/session-modes.md` with all five modes.
5. Update `docs/specifications/README.md` to add FS-0015.
6. Run `npm run check:status` — must exit zero.
7. Run `npm run lint:docs` — must exit zero.
8. Open PR for human review and approval.

## Open Questions

1. **`workflows/session-modes.md` discoverability:** Should the document be referenced
   from `guidelines/ROLE_CONTRACT.md` shared rules, or is the explainability rule
   sufficient to make agents find it? Recommend a direct reference from the
   explainability rule: "See `workflows/session-modes.md` for mode definitions."
2. **Maintenance mode:** Five modes cover dominant patterns. If a project phase
   (e.g., a sustained maintenance period) does not fit any mode well, should the team
   add a sixth mode to `roles/session-modes.md`, or use Implementation mode with
   narrowed scope? Recommend: customize in `roles/` if a project consistently needs it;
   don't add to `guidelines/` until multiple projects encounter the same gap.
