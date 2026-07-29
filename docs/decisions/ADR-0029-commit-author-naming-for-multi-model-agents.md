---
type: adr
id: ADR-0029
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0017
superseded_by: null
---

# ADR-0029: Commit-author naming for multi-model agent frameworks

## Status

- Accepted

## Context and Problem Statement

`ADR-0018` established the single-identity attribution convention: one GitHub login,
actors distinguished by git `user.email`, `Co-authored-by:` for hybrid sessions, and an
`Agent-Attribution:` trailer recording model, role, and session. That decision stands.
This ADR changes one rule within it — which field carries the model — and nothing else.

ADR-0018's actor table assigned `user.name` to the **actor**:

| Actor | `user.name` | `user.email` |
| --- | --- | --- |
| Human (Joey) | `Joey Clark` | `taisden@tais-den.dev` |
| Hermes Agent | `Hermes Agent` | `hermes-agent@tais-den.dev` |

The model lived only in the trailer. That was correct when one agent framework operated
on this repository. Two facts have changed since: more than one framework now commits
here — Hermes Agent and Claude Code — and each runs different models across sessions.
The actor is no longer the field that varies.

The consequence shows up in tooling. `git log`, `git shortlog`, `git blame`, and every
GitHub commit list render `user.name` by default and surface trailers only on request.
Under ADR-0018's table, a year of commits from one framework displays one repeated name,
while the audit-relevant fact — which model produced the change — is recoverable only by
reading each message body. In a repository whose purpose is making agent work auditable,
the discriminating field is the one hidden by default.

The question this ADR answers: **which of actor and model belongs in `user.name`?**

## Decision Drivers

- **The default view should carry the discriminating information.** Attribution that
  requires a non-default flag to see is attribution that will not be seen.
- **Both fields must stay mechanically recoverable.** Whichever occupies the name, the
  other must be retrievable — not inferred from prose.
- **The trailer stays canonical.** Display names serve humans; `Agent-Attribution:`
  remains the machine-readable record.
- **Nothing else about ADR-0018 should move.** The identity layer, the email-as-actor
  discriminator, and both trailer conventions are working and are out of scope here.

## Considered Options

### Option A — Keep ADR-0018's assignment: name is the actor

`Hermes Agent <hermes-agent@tais-den.dev>`, model in the trailer only. Stable across
sessions, so `git shortlog` groups cleanly by actor. But the model is invisible in every
default view, and grows more invisible as models per framework multiply.

### Option B — Name is the model, email is the actor

`Opus 5 <claude-code@tais-den.dev>`. The model displays by default; the actor moves to
the address, recoverable via `%ae`, `git shortlog -e`, or a mailmap. Costs `shortlog`
grouping — commits fragment across model names and across versions of one model.

### Option C — Composite name

`Claude Code (Opus 5) <claude-code@tais-den.dev>`. Both visible without reading a
trailer, but produces long author columns, and the parenthetical is prose rather than a
structured field — anything parsing it is parsing prose.

## Decision Outcome

**Chosen option: Option B — `user.name` carries the model, `user.email` carries the
actor.**

```text
<Model Display Name> <actor@tais-den.dev>
```

| Commit source | Author line |
| --- | --- |
| Claude Code running Opus 5 | `Opus 5 <claude-code@tais-den.dev>` |
| Hermes running DeepSeek V4 | `DeepSeek V4 <hermes-agent@tais-den.dev>` |
| Joey, unassisted | `Joey Clark <taisden@tais-den.dev>` |

The human row is unchanged. A human is not a model, and `user.name` continues to carry
the person's name.

`user.name` carries a display form; the `Agent-Attribution:` trailer continues to carry
the canonical provider-qualified identifier. The redundancy is deliberate: `Opus 5` is
what a reviewer reads in a commit list, `anthropic/claude-opus-5` is what tooling matches
on. **Where they disagree, the trailer is authoritative.**

### Scope

This ADR changes the name-field assignment and nothing else. ADR-0018 remains `accepted`
as the record of the decision made on 2026-07-27; its reasoning about single identity,
email-as-discriminator, and the two trailer layers is unaffected and is not restated
here.

The convention **in force** — actor table, per-commit override, per-session
configuration, when each trailer applies, and the ADR-0011 migration path — lives in
`workflows/git-and-gh-conventions.md` §"Single-identity workflow with agent
co-attribution", which this ADR updates. That document is exported surface and is where
agents and contributors read the current rules. ADRs record why the rules changed; they
are not the place to look up what the rules are.

## Consequences

### Positive

- The model is visible in every default git and GitHub view, with no flags and no
  trailer reading.
- The actor stays mechanically recoverable via `%ae`, `git shortlog -e`, or mailmap.
- Adding a model to a framework requires no configuration beyond `user.name`.
- The scheme scales as frameworks and models multiply, which Option A does not.

### Negative

- `git shortlog` without `-e` now groups by model and fragments across model versions —
  `Opus 5` and `Opus 4.8` count separately. A `.mailmap` mapping model names to actor
  addresses restores actor-level grouping.
- Model identity appears in two places at two granularities and can drift if set
  carelessly.
- Readers unfamiliar with the convention will see `Opus 5 <claude-code@tais-den.dev>` and
  not realize it is the same login as `ajoeofalltrades`.

### Neutral

- **The branch proposing this ADR already used the scheme.** Its commits are authored
  `Opus 5 <claude-code@tais-den.dev>` from the first one, at the maintainer's explicit
  direction when asked what identity to commit under — but `ADR-0018`'s accepted actor
  table has two rows, Joey and Hermes Agent, and no Claude Code row. The convention was
  human-sanctioned and not ADR-sanctioned at the time it was used. Recorded because the
  alternative was to commit under an identity the framework did not recognise either,
  and because a reader auditing that branch's authorship against trunk's ADR-0018 will
  otherwise find an unexplained third actor.
- No change to the GitHub identity layer. All addresses remain aliases under
  `ajoeofalltrades`.
- Historical commits are not rewritten and remain valid records of the convention in
  force when they were made.

## Validation

- **Signal:** `git log --format='%an <%ae>'` over commits after acceptance shows a model
  name in the author position and an actor alias in the address, for every agent commit.
- **Signal:** for any agent commit, the `Agent-Attribution:` trailer's `actor=` matches
  the local part of the author email.
- **Signal:** `workflows/git-and-gh-conventions.md` §"The convention" shows the model-named
  form, and no document outside `docs/decisions/` still shows the actor-named form.
- **Review checkpoint:** when a third agent framework is added, or when one framework
  runs more than three models concurrently. If `shortlog` fragmentation is the dominant
  complaint by then, a `.mailmap` is the first remedy and Option C the second.
- **Failure condition:** if commits appear with a model in `user.name` and a mismatched
  or absent `actor=` in the trailer, the two-place redundancy is drifting and should be
  collapsed to one field by a superseding ADR.

## Links

- ADR-0018: Single-identity workflow with agent co-attribution — establishes the
  convention this ADR amends; remains accepted as the record of that decision.
- ADR-0021: Cron actor identity — unattended actors carry their own address under this
  scheme.
- `workflows/git-and-gh-conventions.md` — the convention in force; updated by this ADR.
- FS-0017: Single-identity commit attribution — implemented ADR-0018's convention.
