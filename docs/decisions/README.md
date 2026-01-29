# ADR Process and Lifecycle

This README defines how we write, review, and maintain Architecture Decision Records (ADRs) in this repo.

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
# Install markdownlint
npm install

# Run linting on all ADRs
npx markdownlint docs/decisions/ADR-*.md

# Fix common issues automatically (where possible)
npx markdownlint --fix docs/decisions/ADR-*.md
```

**Automatic: CI enforcement**

- CI pipeline runs markdownlint on all ADRs automatically.
- PR will fail if any ADR violates linting rules.
- See `.markdownlint.yml` for the active ruleset (derived from MADR's configuration).

### Common Issues and Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| MD001 | Incorrect heading hierarchy | Ensure headings use correct level (# → ## → ###) |
| MD009 | Trailing whitespace | Remove spaces at end of lines |
| MD010 | Hard tabs | Use spaces instead (2 or 4 spaces per indent level) |
| MD025 | Duplicate H1 | Use only one H1 (# title) at top of file; rest should be H2 (##) |

### Configuration

- Config file: `vendor/madr/.markdownlint.yml` (referenced from CI)
- Disabled rules:
  - `MD013`: Line length (MADR uses one-sentence-per-line, which may exceed 80 chars)
  - `MD024`: Duplicate headings (ADRs intentionally reuse headings like "Options", "Consequences")

For more info: https://github.com/DavidAnson/markdownlint/doc/Rules.md

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