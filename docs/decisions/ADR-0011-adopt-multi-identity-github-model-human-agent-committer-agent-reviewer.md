---
type: adr
id: ADR-0011
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0011
superseded_by: null
---

# ADR-0011: Adopt multi-identity GitHub model (human + agent-committer + agent-reviewer)

## Status

- Accepted

## Context and Problem Statement

Tai anticipates using agentic workflows for code changes and reviews while also retaining a human GitHub identity for interactive ownership. Without explicit identity separation, it is easy to:

- lose audit clarity (who authored a change vs who reviewed it)
- accidentally perform privileged actions as the wrong identity
- blur accountability for automated/agentic actions

The kit is intended to document conventions that are safe and repeatable across repositories, and may later be released to others.

## Decision Drivers

- Security: minimize risk of accidentally acting as the wrong identity
- Auditability: preserve a clear trail of authorship vs review
- Operational simplicity: a model that is easy to explain and follow
- Tool compatibility: must work with GitHub + `gh` CLI + git
- Future-proofing: should remain valid if the implementation details (one agent vs many) change

## Considered Options

### Option A — Single GitHub identity for everything (human)

Use the human account for commits, PRs, and reviews, even when work is performed by agents.

### Option B — Two identities (human + one agent)

Use a single agent account for both PR creation/commits and reviews.

### Option C — Three identities (human + agent-committer + agent-reviewer)

Use:

- Human account for interactive ownership/administration
- Agent-committer account for commits and PR creation
- Agent-reviewer account for reviews/comments

## Decision Outcome

Chosen option: **Option C — Three identities (human + agent-committer + agent-reviewer)**.

Rationale:

- Separates “change author” from “review voice”, mirroring common separation-of-duties patterns.
- Produces a more legible GitHub audit trail: PR authorship and review authorship remain distinct.
- Avoids the ambiguous situation where an agent reviews its own work under the same identity.

Clarifications / constraints:

- Agent-created PRs MUST be authored by an agent identity (not the human).
- Whether one agent or multiple agents operate these identities is explicitly out of scope.
- Commit signing (GPG/SSH “Verified”) is nice-to-have, not required.

## Consequences

### Positive

- Clear audit trail: “who proposed change” vs “who reviewed/approved”.
- Reduced risk of accidental privilege escalation by habit (e.g., always using human creds).
- Easier future policy enforcement (branch protection, CODEOWNERS, required reviews) because roles are distinct.

### Negative

- More operational complexity (multiple `gh` auth contexts; multiple SSH keys).
- Higher setup burden for contributors who want to replicate the model.
- Additional documentation required to avoid identity mix-ups.

### Neutral

- Git commit authorship and GitHub action identity are separate concepts; both must be addressed in the kit.

## Validation

We consider this decision successful if:

- PRs opened by agents consistently show the agent-committer as PR author.
- Reviews/comments intended to represent “review” consistently come from agent-reviewer.
- The number of “wrong identity” mistakes trends to near-zero after adopting documented setup steps.

## Links

- Related Spec: FS-0011 Git + gh CLI conventions for agentic-dev-kit
