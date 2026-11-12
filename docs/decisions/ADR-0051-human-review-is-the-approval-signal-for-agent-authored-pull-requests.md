---
type: adr
id: ADR-0051
status: proposed
decision_scope: system
reversible: unknown
related_specs: []
superseded_by: null
created: 2026-11-12
updated: 2026-11-12
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
- Use this document only to constrain or explain behavior, not to generate code.
-->
# ADR-0051: Human review is the approval signal for agent-authored pull requests

## Status

- Proposed

## Context and Problem Statement

This repository is public and has exactly one human participant. That person is the
sole organisation member, the sole collaborator, the sole entry in `CODEOWNERS`
(`* @ajoeofalltrades`), and the author of every open pull request.

GitHub does not count self-approval. With `required_approving_review_count: 1` and
`require_code_owner_reviews: true`, a pull request authored by the only code owner
can never satisfy its own review requirement. Every merge is therefore a bypass.

The record shows this is not theoretical. The two most recent merges carry a review
record, but the review state is `COMMENTED`, not `APPROVED`:

```text
#252  merged 2026-11-12T00:03:53Z  author=ajoeofalltrades  reviews=1  states=[COMMENTED]
#256  merged 2026-11-12T00:03:30Z  author=ajoeofalltrades  reviews=1  states=[COMMENTED]
```

`ADR-0026` already defines what approval *is* — a recorded act, not a conversational
tone — and it is not in question here. What is missing is which signal carries that
act for a pull request, and where it is evaluated.

**Adding a second collaborator does not fix this.** The review requirement keys on
the *pull request author*, and the only code owner *is* that author. A second
account can submit a review, but it cannot satisfy a code-owner requirement it does
not own. The requirement stays unsatisfiable upstream however many collaborators
are added.

What changes the outcome is who opens the pull request. If an agent-authored pull
request is reviewed by the human, the human's review is both non-author and a
code-owner review — the same repository configuration is unsatisfiable in one shape
and satisfiable in the other.

## Decision Drivers

- The review gate must be satisfiable for the pull requests that actually need it.
- A control that a governed party can satisfy on its own is not a control.
- The mechanism must be expressible in platform-attested records, not reconstructed
  from git history.
- A bypass and a vacuous satisfaction are different states and must be named
  differently.

## Considered Options

### Option A — Keep the current configuration; record the bypass as a residual

Honest, and it costs nothing. But it leaves a required review context that is red or
bypassed on every merge, so the signal carries no information either way.

### Option B — Add the agent account to `CODEOWNERS`

Makes the requirement satisfiable, and makes the governed party a required reviewer
of the governance. Once two agent accounts exist, agent-approves-agent satisfies the
code-owner requirement on an agent pull request. This is the hole the requirement
exists to close.

### Option C — Human-only `CODEOWNERS`; a non-author human approval is the gate

The invariant is stated in its own terms rather than as a platform approximation,
and it is checked against records the platform writes.

### Option D — Require merge commits and disable squash

Addresses attribution preservation (`ADR-0025`), not authorship of the pull request.
It leaves the review requirement exactly as unsatisfiable as it is today.

## Decision Outcome

**Chosen option: Option C.**

### The invariant

**Every pull request whose author identity is not human MUST carry an `APPROVED`
review from a non-author human at merge time.**

A human-authored pull request satisfies this **vacuously**. The author is the human,
and `ADR-0026`'s recorded act delegates judgment; it does not ask a human to
countersign their own judgment. That state is *self-approved by definition*, and it
must not be described as a residual bypass — the phrasing invites someone to close it
by adding a code owner, which is the move that breaks the asymmetry.

### `CODEOWNERS` stays human-only

The governed party must not be a required reviewer of the governance. This follows
from the same rule that produced the invariant.

### The agent account authors the pull request

The human reviews and merges; the agent opens. This is the only shape in which the
requirement is both satisfiable and non-trivial.

Capability separation is a **precondition, not a consequence**, and it is already
decided: `ADR-0048` requires that a worker hold no usable GitHub write credential
and that the publisher hold one narrowly scoped credential that cannot merge. This
ADR does not restate that decision; it depends on it. Until the human's credential
is removed from agent environments, every signal below records *who held the token*,
not who was present, and this ADR's checks inherit that weakness.

### The rule lives in the current-state document

`workflows/git-and-gh-conventions.md` states the convention in the present tense.
Per `ADR-0030`, an ADR that changes a rule updates the current-state document that
carries it, in the same change. The placement is load-bearing rather than cosmetic:
`current-state-update` is a required context, so stating the invariant there means
changing it requires touching that document, which the existing gate already
enforces.

### The mechanism is a post-merge detector, not a merge gate

A required status check runs on the pull request head, **before** the merge. At that
moment there is no `merged_at`, no merge commit, and no review to inspect:

```text
#250 (open): merged=False  merged_at=None  reviews=[]
```

A check of the form "a human `APPROVED` review exists at `merged_at`" therefore
cannot be a pre-merge required context. It must run post-merge, on `push` to the
default branch, resolving the just-merged pull request from the trunk tip.

**This is a materially weaker control than the others in this repository, and the
record should say so:** it detects a bad merge after it has happened. It does not
prevent one.

### Evidence comes from platform-attested records only

- **Agent authorship** — `GET /repos/{owner}/{repo}/pulls/{n}/commits`. The branch's
  commits retain their original authors and remain queryable after the merge.
- **The human's review** — `GET /repos/{owner}/{repo}/pulls/{n}/reviews`, requiring
  state `APPROVED` from an author identity outside the human set.
- **The human's merge act** — the merged commit's committer, which the platform
  writes at merge time.

Three consequences follow, and each is a constraint on the implementation:

1. **Do not compute a git range.** After a rebase merge there is no merge commit to
   anchor a range to, and `merge-base` against present-day trunk gives the wrong
   answer once other pull requests have landed. Read the API's commit list.
2. **Branch commits and merged commits are different objects.** A rebase merge
   produces a merged commit with the same author but a different committer:

   ```text
   PR head        a0d1ecbe  author=hermes-agent@…  committer=hermes-agent@…
   merged commit  9cffae5b  author=hermes-agent@…  committer=administrator@ajoeofalltrades.dev
   ```

   No single object carries both authorship and the human's merge act. The check
   reads both.
3. **Every commit in the pull request counts, not the head.** Stacked pull requests
   here already carry commits from more than one author; head-only verification
   blesses the tip and ignores the rest.

## Consequences

### Positive

- The review gate becomes satisfiable for exactly the pull requests that need it,
  and vacuous for the ones that do not.
- The invariant is stated in the language of the rule rather than in the platform's
  approximation of it, so it survives a change of platform configuration.
- Code-owner review stops being a proxy that the governed party can satisfy.

### Negative

- The detector fires after the merge. A bad merge is recorded, not blocked.
- Until `ADR-0048` conformance lands, the evidence proves credential possession
  rather than human presence. That limitation belongs in the detector's own docs,
  not in a footnote.
- Human-authored pull requests are self-approved by definition, which will look like
  an exemption to a reader who has not read this document.

### Neutral

- The agent account must exist before any of this is meaningful, which is ordinary
  setup work rather than a design question.

## Validation

- A merged pull request whose commits are agent-authored and whose review record
  contains no non-author `APPROVED` review is reported.
- A merged pull request authored by the human is reported as vacuous satisfaction,
  not as a finding.
- A stacked pull request with commits from more than one author is evaluated on
  every commit, not the head.
- With the human's credential removed from agent environments, an attempted
  publisher-context merge fails and is visible as an isolation violation rather than
  a silent retry (`ADR-0048`).

## What this ADR does not decide

- **Whether a fork is created, and where it lives.** The fork is a hosting decision;
  this ADR's shape works in the upstream repository as soon as agents open the pull
  requests.
- **Branch protection values themselves** — required contexts, dismissal settings,
  admin enforcement. Those are configuration, and they are recorded where the
  configuration lives.
- **The feature specification and plan for the detector.** This ADR fixes the
  invariant and the evidence sources; the detector's behaviour, failure modes, and
  tests belong in an `FS` and `PLAN`.
- **The CI trust boundary** — a worker without credentials can still propose code
  that later executes in a privileged workflow. `ADR-0048` names that as a separate
  boundary and this ADR does not close it.

## References

- `ADR-0026` — approval is a recorded act (the definition of approval; unchanged).
- `ADR-0030` — decision records versus current-state documents (rule placement).
- `ADR-0047` — authorized intent identity and the human grant.
- `ADR-0048` — worker and publisher credential separation (the capability
  precondition this ADR depends on).
- `ADR-0025` — merge strategy preserves per-commit attribution.
- `workflows/git-and-gh-conventions.md` — the current-state document that will carry
  the invariant.
