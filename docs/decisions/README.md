# ADR Process and Lifecycle

This README defines how we write, review, and maintain Architecture Decision Records (ADRs) in this repo.

**Agents MUST update this file when adding new ADRs or changing ADR statuses.**

- ADRs capture a single significant decision, plus the context and consequences.
- ADRs are intended to be durable, searchable, and safe to treat as constraints once accepted.

## Directory and Naming

- Location
  - Store ADRs under `docs/decisions/`
  - Rationale: keep decision logs discoverable and co-located with architecture docs (not a requirement of arc42, just a common repo convention).
- Filenames
  - Use `ADR-0000.md`, `ADR-0001.md`, etc.
  - Include a short title inside the file.
- Template
  - Use the MADR template (4.0.0 pinned as a submodule) as the baseline structure.

## Formatting and Linting

All ADRs must comply with markdown formatting standards enforced by markdownlint. See ADR-0008 for the decision to adopt markdownlint.

### Setup

**Optional: Local linting (recommended)**

```bash
# Install markdownlint-cli2
npm install

# Run linting on all ADRs
npm run lint:adrs
```

**Automatic: CI enforcement**

- CI runs markdownlint on ADRs only (`docs/decisions/ADR-*.md`).
- PR will fail if any ADR violates linting rules.
- Config lives at `docs/decisions/.markdownlint.yml` (copied from MADR).

### Troubleshooting

If linting fails in CI, copy the rule name (e.g., `MD010`) and search for it in the ADR.

#### Common Issues and Fixes

| Issue | Cause | Fix |
| --- | --- | --- |
| MD001 | Incorrect heading hierarchy | Ensure headings use correct level (# → ## → ###) |
| MD009 | Trailing whitespace | Remove spaces at end of lines |
| MD010 | Hard tabs | Use spaces instead (2 or 4 spaces per indent level) |
| MD025 | Duplicate H1 | Use only one H1 (# title) at top of file; rest should be H2 (##) |

### Configuration

- Config file: `docs/decisions/.markdownlint.yml` (exact copy of MADR baseline)
- Disabled rules:
  - `MD013`: Line length (MADR uses one-sentence-per-line, which may exceed 80 chars)
  - `MD024`: Duplicate headings (ADRs intentionally reuse headings like "Options", "Consequences")

For more info: [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).

## Status Values

We use these status values (aligned with common ADR practice):

- Proposed
- Accepted
- Rejected (optional but allowed)
- Deprecated
- Superseded

The idea of tracking decisions via status (proposed, accepted, deprecated, superseded) is a widely used ADR convention.

## Lifecycle Process

### 1. Create an ADR as Proposed

- When to write an ADR
  - A decision will constrain future work, has meaningful tradeoffs, or is expensive to reverse.
- How to propose
  - Create `docs/decisions/ADR-XXXX.md` using the template.
  - Set `status: proposed`.
  - Open a PR that contains only the ADR (preferred), or the ADR plus minimal supporting context.

### 1a. Decide whether the ADR needs a governing Feature Spec

An ADR records a decision. Whether that decision also needs an FS depends on what it
obliges someone to build.

| The ADR implies | Needs a governing FS? |
| --- | --- |
| A convention, followed by people and agents | **No.** Update the current-state document that carries the rule (ADR-0030 rule 3) and the ADR is discharged. |
| Code — a script, a CI job, a check, a generator | **Yes.** Write the FS before the code. |

The second row is not optional style. `ADR-0015` requires an approved FS and PLAN
before any governance gate is written or modified, and `ADR-0027` reserves `scripts/`,
`.github/workflows/`, and `package.json` as always-human-approval paths. An ADR that
decides a check should exist has not authorized anyone to write it.

Worked examples from this repository:

- `ADR-0025` chose rebase-merge. A convention. Updating
  `workflows/git-and-gh-conventions.md` discharged it completely; no FS.
- `ADR-0027` decided a plan self-approves when its `touches:` is contained. That
  implies a check in `scripts/check-status.sh`. It needs a governing FS, and got one
  in `FS-0022` — after the fact, which is the mistake this section exists to prevent.

Populate `related_specs:` with the governing FS when there is one. An ADR implying
code with an empty `related_specs:` is the shape of this error.

### 2. Move Proposed to Accepted

An ADR can move to `accepted` when:

- The ADR has at least:
  - Context and problem statement
  - Considered options
  - Decision outcome and rationale
  - Consequences
  - Validation signals (how we will know it worked)
- The PR has been reviewed by the appropriate decision owners and merged.

This matches common ADR processes where proposed records are reviewed and then accepted (or rejected).

### 3. Optional: Reject a Proposed ADR

Use `rejected` when:

- The team explicitly decided not to do the thing.
- The rationale is still worth preserving to prevent re-litigating the same option later.

### 4. Deprecate an Accepted ADR

Use `deprecated` when:

- The decision is no longer relevant or recommended.
- There is not necessarily a direct replacement decision.

Deprecation as a status is a standard pattern in ADR practice.

### 5. Supersede an Accepted ADR

Use `superseded` when:

- A new ADR replaces the old decision.
- The old ADR should link to the new ADR in its Status section.
- The new ADR should link back to the old ADR in its Links section.

Superseding with a reference to the replacement is a standard ADR convention.

The front-matter chain is machine-checked by `scripts/check-status.sh` rule 5b
(FS-0028): a `superseded` ADR must name a replacement in `superseded_by:`,
every non-null value must resolve to an existing ADR, and only a `superseded`
ADR may declare a replacement.

## Editing Rules and Immutability

### After Acceptance, ADRs Are Append-Only

Once an ADR is `accepted`, treat it as immutable:

- Allowed edits after acceptance
  - Update the `Status` section (for accepted to deprecated or superseded).
  - Fix typos, broken links, or formatting errors that do not change meaning.
- Not allowed after acceptance
  - Changing the decision, rationale, drivers, options, or consequences.
  - Rewriting history to match current preferences.

This “only the Status evolves” rule is a known best practice for ADR logs.

### How to Change a Decision

- Do not rewrite an accepted ADR.
- Create a new ADR and either:
  - Mark the old one as `superseded` (preferred when replaced), or
  - Mark it as `deprecated` (when simply no longer relevant).

## Validation and Review Checkpoints

Each ADR must include a Validation section with at least one of:

- Metrics
- Signals (what we expect to observe)
- Review checkpoints (dates or events when we revisit)

If validation fails:

- Create a new ADR that supersedes or deprecates the prior decision.
- Link both directions (old to new, new to old).

## Relationship to arc42 and Other Docs

- arc42 encourages documenting decisions (often in section 9), but it does not require ADRs or a status workflow.
- We use ADRs as our decision log and reference them from arc42 documents when helpful.

## Quick Checklist

- New ADR
  - [ ] Uses MADR template
  - [ ] `status: proposed`
  - [ ] Has real options, not strawmen
  - [ ] Has consequences and validation
  - [ ] Passes `npx markdownlint docs/decisions/ADR-XXXX.md` locally
  - [ ] PR opened for review
- Accept ADR
  - [ ] PR merged
  - [ ] Status updated to `accepted`
- Change ADR
  - [ ] New ADR created
  - [ ] Old ADR status updated to `deprecated` or `superseded`
  - [ ] Cross-links added

## Current ADRs

| ID | Title | Status |
| --- | --- | --- |
| ADR-0000 | Use MADR and arc42 template as documentation origins | accepted |
| ADR-0001 | Incorporate cross-tool portable skills as SKILL.md | accepted |
| ADR-0002 | Roles reference skills via convention and skills index | accepted |
| ADR-0003 | Mirror arc42-template as an upstream-tracking git submodule | accepted |
| ADR-0004 | AGENTS.md as Canonical Integration Surface | accepted |
| ADR-0005 | Submodule-First Referencing Strategy | accepted |
| ADR-0006 | Role-as-Skill-Card Format | accepted |
| ADR-0007 | Adjacent-to-Spec-Kit Positioning | accepted |
| ADR-0008 | Adopt markdownlint for ADR Formatting Consistency | accepted |
| ADR-0009 | Feature Specification Template Selection | accepted |
| ADR-0010 | Use Custom Change Plan Template Instead of Open Source Alternative | accepted |
| ADR-0011 | Adopt multi-identity GitHub model (human + agent-committer + agent-reviewer) | accepted |
| ADR-0012 | Introduce non-overridable gates ("super-gates") in ROLE_CONTRACT | accepted |
| ADR-0013 | Multi-model session coordination model | accepted |
| ADR-0014 | Background task governance | accepted |
| ADR-0015 | Tool taxonomy and introduction process | accepted |
| ADR-0016 | Consumer conventions — local adaptations of the framework | accepted |
| ADR-0017 | Framework vendor directory is internal; consumers must not reference nested submodules | accepted |
| ADR-0018 | Single-identity workflow with agent co-attribution | accepted |
| ADR-0019 | Issue Type immutability and the autonomous gate | accepted |
| ADR-0020 | The `question` label suppresses agent Issue actions | accepted |
| ADR-0021 | Cron actor identity for unattended agents | accepted |
| ADR-0022 | Autonomous and consensus are meta-modes, not session modes | accepted |
| ADR-0023 | Collaboration integrity constraints | accepted |
| ADR-0024 | Platform-neutral core with shipped bindings | accepted |
| ADR-0025 | Merge strategy preserves per-commit attribution | accepted |
| ADR-0026 | Approval is a recorded act | accepted |
| ADR-0027 | PLAN self-approval within declared interfaces | accepted |
| ADR-0028 | Level-triggered reconciliation | accepted |
| ADR-0029 | Commit-author naming for multi-model agent frameworks | accepted |
| ADR-0030 | Decision records versus current-state documents | accepted |
| ADR-0031 | Structured multi-model collaboration | accepted |
| ADR-0032 | Template and instance repository forms | proposed |
| ADR-0033 | Governance gate target resolution and configuration | accepted |
| ADR-0034 | MCP tool category and GitHub skills consolidation | superseded |
| ADR-0035 | Concurrent-session workspace isolation | proposed |
| ADR-0036 | Attribution vocabulary canon and history-integrity policy | proposed |
| ADR-0037 | Executable layer for the GitHub binding | accepted |
| ADR-0038 | Agent Skills as a profiled upstream standard | accepted |
| ADR-0039 | Agent-runtime integration bindings | accepted |
| ADR-0041 | Narrow direct-to-trunk merge exception for reversible maintenance categories, audited by a maintenance digest | proposed |
| ADR-0042 | Portable flow-report read-model — visibility profile, not a seventh capability | proposed |
| ADR-0043 | Planning fields are binding policy, not framework state — authority matrix for Priority, Iteration, and Milestone | proposed |
| ADR-0045 | Bounded autonomous runs with batch proposal-acceptance | superseded |
| ADR-0046 | Merge the governance and operations templates | accepted |
| ADR-0047 | Authorized intent identity and the human grant | accepted |
| ADR-0048 | Worker and publisher credential separation | accepted |
| ADR-0049 | Grant-based go signal for autonomous runs | accepted |
| ADR-0050 | Re-approval flow for reviewer-feedback commits on approved PLANs | proposed |
