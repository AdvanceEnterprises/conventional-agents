---
type: feature-spec
id: FS-0014
status: draft
title: Role definitions overhaul — expand from 3 to 6 roles
owner: Tai
test_required: false
interfaces:
  - guidelines/ROLE_CONTRACT.md (full rewrite)
  - roles/ROLE_CONTRACT.md (sync with guidelines/)
  - docs/specifications/README.md
related_adrs:
  - ADR-0002
  - ADR-0006
  - ADR-0007
  - ADR-0012
supersedes: []
requires:
  - FS-0010
  - FS-0013
tags:
  - roles
  - governance
  - process
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

# Feature Spec: Role Definitions Overhaul — Expand from 3 to 6 Roles

## Status

- Draft

## Summary

The current ROLE_CONTRACT defines three roles (Spec Reader/Test Planner, Implementer,
Reviewer) that cover the code-phase of the BDD workflow well, but leave significant gaps:
there is no role for the people and agents doing document authoring, no role for
framework-level strategic oversight, and no role for external communications. Additionally,
the existing role definitions contain a stale file path, a precedence model that
contradicts ADR-0012's level-0 gates, and no assignment of the `check:status` gate. The
`roles/ROLE_CONTRACT.md` file — which is supposed to be the authoritative exported copy
— is empty.

This spec defines a full overhaul: six roles, a corrected precedence model, structural
fixes, and a consolidated authoritative location.

---

## Goals

- Define three new roles: Chief Process Architect, Document Author, and

  Communications Lead.

- Retain the three existing roles with corrections: fix the stale `docs/specs/` path in

  Role 1, assign `check:status` responsibility, and align the conflict-resolution
  precedence model with ADR-0012's level-0 gates.

- Establish `guidelines/ROLE_CONTRACT.md` as the single authoritative source; make

  `roles/ROLE_CONTRACT.md` a verbatim copy (or symlink) so the exported surface matches.

- Ensure every role has a clear mandate, explicit prohibited actions, and defined stop

  conditions.

## Non-Goals

- Creating per-role separate files (ROLE_CONTRACT.md remains a single consolidated

  document).

- Defining tooling or automation for role assignment.
- Changing any non-role content in ROLE_CONTRACT (safety gates, shared rules, hygiene

  gate checklist).

- Defining a human organizational chart — roles describe agent behaviors and authority

  boundaries, not human org structure.

- Prescribing which agent model fills which role — that is a project-level decision.

---

## Role Inventory

### Role 0 — Chief Process Architect

**Purpose:** Strategic oversight of the framework's evolution and health. Operates at the
meta-level: designs processes, identifies systemic drift, proposes governance decisions,
and ensures all other roles remain coherent and well-bounded. The Chief Process Architect
is the only role permitted to propose changes to ROLE_CONTRACT itself.

**Mandate:**

- Conduct periodic framework health audits: review spec/plan ledger for stale statuses,

  precedence conflicts, and process gaps.

- Identify when existing roles, gates, or workflows are creating friction or drift and

  propose corrective ADRs or FS specs.

- Review all governance documents (FS, PLAN, ADR) for coherence with the overall

  framework before they are approved.

- Design and document new roles, gates, and workflows as the framework evolves.
- Serve as the first responder to cross-role ambiguity: if two roles have conflicting

  authority over a decision, the Chief Process Architect resolves it by proposing a
  clarifying ADR — not by making an ad hoc ruling.

**Inputs (Authoritative):**

- All FS, PLAN, and ADR documents across the repository
- Framework health signals: `npm run check:status` output, CI results, open PR review

  comments, stale document reports

- Human direction and strategic priorities

**Outputs:**

- New draft FS specs and draft ADRs (proposed; human must approve)
- Framework health assessments (written summaries or audit reports)
- Role boundary clarifications (as ADR proposals, not unilateral edits)
- Change plan recommendations for other roles to execute

**Prohibited Actions:**

- Unilaterally changing any governance document without a draft FS or ADR
- Bypassing or weakening non-overridable safety gates (ADR-0012)
- Approving its own proposed specs or ADRs (human approval required)
- Merging pull requests (non-overridable gate, ADR-0012)
- Making implementation decisions that belong to the Implementer role

**Stop Conditions:**

- Strategic direction is unclear or contradictory — stop and escalate to human
- A proposed framework change would require modifying ADR-0012-level gates — stop; this

  requires explicit human decision and a new ADR

---

### Role 1 — Document Author

**Purpose:** Draft, maintain, and transition all governed documents: Feature Specs (FS),
Change Plans (PLAN), and Architecture Decision Records (ADR). Owns document hygiene as a
first-class responsibility.

**Inputs (Authoritative):**

- Human direction or Chief Process Architect output identifying what needs to be

  documented

- Existing FS, PLAN, and ADR documents for cross-reference
- Templates: `templates/core/feature-spec.md`, `templates/core/change-plan.md`,

  `templates/core/adr-full-madr.md`

- `workflows/document-lifecycle.md` — status transition rules

**Outputs:**

- Draft FS documents (`docs/specifications/FS-XXXX-*.md`)
- Draft PLAN documents (`docs/change-plans/PLAN-XXXX-*.md`)
- Draft ADR documents (`docs/decisions/ADR-XXXX-*.md`)
- Updated README index tables in `docs/specifications/`, `docs/change-plans/`, and

  `docs/decisions/`

- Updated `updated:` front matter dates on any document touched
- Status transitions on governed documents (draft→in-progress→implemented) per lifecycle

  rules

**Responsibilities:**

- Follow all document templates exactly; do not invent new sections or omit required ones.
- Run `npm run check:status` before every commit and resolve all violations.
- Update README index tables whenever a document is added or its status changes.
- Populate `related_adrs:` and `related_specs:` cross-references fully.
- Set `updated:` to today's date on every document modified.
- Never transition a document from `draft` to `approved` — that transition is human-only.

**Prohibited Actions:**

- Approving any FS, PLAN, or ADR (human-only gate)
- Writing implementation code or tests
- Modifying existing accepted ADRs beyond the Status section
- Creating documents without following the prescribed template
- Committing without running `npm run check:status`

**Stop Conditions:**

- A document's required content is ambiguous — stop and ask; do not infer
- A cross-reference points to a non-existent document — stop and flag before committing
- The document lifecycle transition rules are unclear for the current situation

---

### Role 2 — Spec Reader and Test Planner

**Purpose:** Translate approved feature specifications into executable tests that define
the correctness boundary for implementation.

**Inputs (Authoritative):**

- `docs/specifications/FS-*.md` where `type: feature-spec` and `status: approved`
- Authoritative sections within each spec: `## Success Criteria`, `## Interfaces`,

  `## Non-Goals`, `## Out of Scope`

**Outputs:**

- Test files only
- No production code

**Responsibilities:**

- Map each success criterion to one or more tests.
- Ensure tests are deterministic and independently meaningful.
- Name tests after the behavior they validate, not the implementation.

**Prohibited Actions:**

- Writing or modifying production code
- Modifying specs or their metadata
- Introducing behavior not explicitly stated in the spec
- Generating tests from sections other than Success Criteria

**Stop Conditions:**

- Spec `status` is not `approved`
- Success criteria are not objectively testable as written
- Interfaces are undefined or ambiguous

---

### Role 3 — Implementer

**Purpose:** Implement the minimum code necessary to make failing tests pass, without
introducing behavior beyond what tests require.

**Inputs (Authoritative):**

- Failing tests (produced by Role 2)
- Approved feature specs (`docs/specifications/FS-*.md`, `status: approved`)
- Accepted ADRs (`docs/decisions/ADR-*.md`, `status: accepted`)
- Architecture context (`docs/ARC42.md`)

**Outputs:**

- Production code changes only

**Responsibilities:**

- Make tests pass with the smallest viable change.
- Respect all documented constraints from specs and ADRs.
- Preserve existing behavior unless tests require otherwise.
- Run the full test suite after every change; never commit with failures.
- Run `npm run lint:docs` and `npm run check:status` before committing.

**Prohibited Actions:**

- Modifying specs, ADRs, or architecture docs
- Introducing features or behaviors not required by failing tests
- Refactoring code unrelated to the failing test
- Changing version numbers in manifests during feature work
- Committing with failing tests

**Stop Conditions:**

- A test requires behavior not specified in any approved spec
- An ADR explicitly constrains the implementation path in a way that cannot satisfy the test
- Architecture boundaries would be violated
- Tests fail for unclear reasons

---

### Role 4 — Reviewer

**Purpose:** Verify alignment between documentation, tests, and implementation. Produces
observations only — fixes are the responsibility of other roles.

**Inputs (Authoritative):**

- Feature specs, ADRs, architecture docs
- Test code and implementation diffs
- `npm run check:status` output

**Outputs:**

- Review comments only (inline or summary)
- No code or documentation changes

**Responsibilities:**

- Identify mismatches between specs and implementation.
- Flag missing or insufficient test coverage.
- Identify conflicts with ADRs or architecture boundaries.
- Call out undocumented behavior introduced in the diff.
- Report any `check:status` violations observed.

**Prohibited Actions:**

- Modifying code or documentation directly
- Fixing issues on behalf of another role
- Reinterpreting spec intent beyond what is written

**Stop Conditions:**

- Conflicting documentation prevents a coherent review
- Undocumented behavior is widespread enough that a framework-level issue exists

  (escalate to Chief Process Architect, not Reviewer)

---

### Role 5 — Communications Lead

**Purpose:** Translate internal governance artifacts into external-facing communication
for downstream consumers of the framework. Owns the consumer-facing surface: release
announcements, the exported README sections, and the INTEGRATION.md guide.

**Mandate:** Where other roles speak to contributors and agents working inside the
framework, the Communications Lead speaks to teams that _vendor_ or _consume_ the
framework. The audience is an engineering team evaluating or integrating
`agentic-dev-kit`, not a contributor writing specs.

**Inputs (Authoritative):**

- `CHANGELOG.md` — source of truth for what changed in each release
- Merged FS and PLAN documents — source of truth for what was built and why
- `README.md`, `INTEGRATION.md` — documents to keep current for downstream consumers
- Human direction on release timing, messaging priorities, and audience

**Outputs:**

- Polished GitHub Release descriptions (drafted for human to publish)
- Consumer-framed release notes: plain-English summary of what changed and why it

  matters to a downstream user, distinct from the internal CHANGELOG entries

- Updates to consumer-facing sections of `README.md` (installation, usage, what's

  included) when a release changes the exported surface

- Updates to `INTEGRATION.md` when the integration contract changes
- Periodic "framework status" summaries for stakeholders (what's implemented, what's

  planned, what's blocked)

**Responsibilities:**

- Frame changes in terms of impact on consuming projects, not internal governance IDs.

  ("You no longer need to manually check spec statuses — CI now blocks merges when they
  drift" is better than "FS-0013 added a check-status gate.")

- Keep `INTEGRATION.md` current with the actual exported surface after each release.
- Flag to the Chief Process Architect when the external-facing docs contradict internal

  governance docs — do not resolve the contradiction unilaterally.

- Draft GitHub Release descriptions for human review and publication; never publish

  directly.

**Prohibited Actions:**

- Publishing GitHub Releases or any external announcements autonomously
- Modifying internal governance documents (FS, PLAN, ADR, ROLE_CONTRACT)
- Reinterpreting what was built — content must be traceable to merged CHANGELOG entries

  and approved specs

- Changing CHANGELOG.md entries (read-only for this role)

**Stop Conditions:**

- A release note would require interpreting intent beyond what the CHANGELOG and specs

  document — stop and ask

- The exported surface has changed in ways not reflected in any FS — flag to Chief

  Process Architect before drafting

---

## Structural Fix: `roles/` vs `guidelines/`

Currently, `roles/ROLE_CONTRACT.md` is empty and `guidelines/ROLE_CONTRACT.md` is the
live document. Per README.md, `roles/` is part of the exported surface (consumed by host
repos). This creates a silent gap: downstream consumers who follow the integration guide
and load `vendor/agent-dev-kit/roles/ROLE_CONTRACT.md` get nothing.

**Resolution:** After the ROLE_CONTRACT rewrite, `roles/ROLE_CONTRACT.md` should contain
the same content as `guidelines/ROLE_CONTRACT.md`. The implementation plan must include
syncing both files. Going forward, `guidelines/ROLE_CONTRACT.md` is the edit target;
`roles/ROLE_CONTRACT.md` is the exported copy that must be kept identical.

---

## Conflict Resolution Precedence (Corrected)

The current precedence list omits ADR-0012's level-0 gates. The corrected model:

1. **Level 0 — Non-overridable safety gates (ADR-0012).** Above all other sources. Cannot
   be weakened by any other document, role, or human instruction.
2. **Level 1 — Accepted ADRs.** Binding decisions; supersede specs when they conflict.
3. **Level 2 — Approved feature specs.** Define required behavior for implementation.
4. **Level 3 — Architecture documentation.** Define structural constraints.
5. **Level 4 — Tests.** Define correctness boundary.
6. **Level 5 — Implementation code.** Lowest authority; must conform to all above.

If two sources at the same level conflict, escalate to the Chief Process Architect (not
the Implementer or Reviewer).

---

## Users / Stakeholders

- **Tai** — framework owner; needs the Chief Process Architect and Communications Lead

  roles to match how the project actually operates.

- **Marten** — primary agent executor; benefits from clearer Document Author and Implementer

  boundaries.

- **Downstream consumers** — benefit from a Communications Lead that keeps INTEGRATION.md

  and release notes current.

- **Future contributors** — benefit from an unambiguous role inventory.

## Interfaces

- **`guidelines/ROLE_CONTRACT.md`** — full rewrite; all six roles defined, precedence

  corrected, stale path fixed (`docs/specs/` → `docs/specifications/FS-*.md`),
  `check:status` responsibility assigned to Role 1 (Document Author) and Role 3
  (Implementer).

- **`roles/ROLE_CONTRACT.md`** — synced to match `guidelines/ROLE_CONTRACT.md` exactly.
- **`docs/specifications/README.md`** — add FS-0014 row.

## Success Criteria

Each bullet MUST be objectively testable.

- Given the rewritten ROLE_CONTRACT, when searching for `docs/specs/`, then zero matches

  are found — the stale path has been replaced with `docs/specifications/FS-*.md`.

- Given the rewritten ROLE_CONTRACT, when reading the conflict resolution section, then

  it lists six levels (0–5) and Level 0 explicitly references ADR-0012 non-overridable
  gates.

- Given the rewritten ROLE_CONTRACT, when listing all role headings, then exactly six

  roles are present: Chief Process Architect, Document Author, Spec Reader and Test
  Planner, Implementer, Reviewer, Communications Lead.

- Given the rewritten ROLE_CONTRACT, when reading each role's Responsibilities section,

  then `npm run check:status` is mentioned in Document Author and Implementer.

- Given the rewrite is complete, when comparing `roles/ROLE_CONTRACT.md` and

  `guidelines/ROLE_CONTRACT.md` byte-for-byte (e.g., `diff`), then they are identical.

- Given the rewrite is complete, when running `npm run check:status`, then it exits zero.

## Edge Cases

- The Chief Process Architect role is unusual in that it can operate across all other

  roles. The implementation must make clear it does NOT bypass safety gates.

- The Communications Lead's "consumer-framing" output overlaps with CHANGELOG entries.

  The role definition must draw a clear line: CHANGELOG is the internal record (not
  touched by Communications Lead); release notes are the external derivative (owned by
  Communications Lead).

- `roles/ROLE_CONTRACT.md` being empty means any sync mechanism must handle an

  overwrite, not a merge.

## Out of Scope

- Per-role separate files (single ROLE_CONTRACT.md document is retained).
- Tooling to enforce role assignment at runtime.
- Changes to non-role content in ROLE_CONTRACT (shared rules, safety gates, hygiene

  gate checklist) beyond the precedence correction and path fix.

- Any changes to FS, PLAN, or ADR templates.

## Dependencies

- FS-0010: process compliance gates define the document hygiene gate referenced in Role 1.
- FS-0013: status consistency check is referenced as a responsibility in Roles 1 and 3.

## Rollout / Migration

1. Rewrite `guidelines/ROLE_CONTRACT.md` with all six roles and corrected content.
2. Copy the result verbatim to `roles/ROLE_CONTRACT.md` (overwrite the empty file).
3. Update `docs/specifications/README.md` to add FS-0014.
4. Run `npm run check:status` to confirm zero violations.
5. Run `npm run lint:specs` to confirm the spec itself passes markdownlint.
6. Open PR for human review and approval.

## Open Questions

1. **Role 0 naming:** "Chief Process Architect" is descriptive for this project's context.
   Is it too title-like for a generic exported framework? An alternative is
   "Framework Architect" or "Process Steward." Recommend keeping "Chief Process
   Architect" unless downstream consumers find it confusing.
2. **Communications Lead scope:** Should this role also cover internal status updates
   (e.g., weekly framework health summaries for the team), or is it strictly
   external-facing? Current spec assumes external-only; internal reporting stays with
   Chief Process Architect.
3. **`roles/` sync mechanism:** Simple overwrite (copy the file) is proposed. If the two
   files diverge intentionally in the future (e.g., a slimmer exported version), the
   mechanism would need to change. Flag for future ADR if this arises.
