---
type: adr
id: ADR-0029
status: proposed
decision_scope: workflow
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0029: Commit-author naming for multi-model agent frameworks

## Status

- Proposed

## Context and Problem Statement

`ADR-0018` established a three-layer attribution convention: git `user.email`
distinguishes actors, `Co-authored-by:` names non-primary actors on hybrid commits, and
an `Agent-Attribution:` trailer records model, role, and session. Its actor table reads:

| Actor | `user.name` | `user.email` |
| --- | --- | --- |
| Human (Joey) | `Joey Clark` | `taisden@tais-den.dev` |
| Hermes Agent | `Hermes Agent` | `hermes-agent@tais-den.dev` |

`user.name` carries the **actor**; the model lives in the trailer's `model=` field.

That table was written when one agent framework operated on this repository. Two facts
have changed since. More than one agent framework now commits here — Hermes Agent and
Claude Code — and each runs on different models across sessions. The actor is no longer
the interesting variable.

The practical consequence is visible in the tooling. `git log`, `git shortlog`, `git
blame`, and every GitHub commit list render `user.name` by default and show trailers
only on request. Under ADR-0018's table, a year of commits from one framework displays
one repeated name while the fact that actually varies — which model produced the change
— is recoverable only by reading each message body. For a repository whose stated
purpose is making agent work auditable, the audit-relevant field is the one hidden by
default.

The inverse arrangement puts the varying field where tools already look and the stable
field in the address, which `git log --format='%ae'`, `git shortlog -e`, and mailmap all
read natively.

The question this ADR answers: **which of actor and model belongs in `user.name`?**

## Decision Drivers

- **The default view should carry the discriminating information.** Attribution that
  requires a non-default flag to see is attribution that will not be seen.
- **Both fields must remain recoverable.** Whichever goes in the name, the other must
  stay mechanically retrievable — not inferred.
- **The trailer stays canonical.** Display names are for humans; `Agent-Attribution:`
  remains the machine-readable record.
- **Aliases must stay valid GitHub identities.** All addresses remain aliases under the
  single `ajoeofalltrades` login per ADR-0018; this decision does not touch the identity
  layer.

## Considered Options

### Option A — Keep ADR-0018's table: name is the actor

`Hermes Agent <hermes-agent@tais-den.dev>`, model in the trailer only.

Stable across sessions, so `git shortlog` groups cleanly by actor. But the model — the
field that varies and that a reviewer most often wants — is invisible in every default
view, and becomes more invisible as the number of models per framework grows.

### Option B — Name is the model, email is the actor

`Opus 5 <claude-code@tais-den.dev>`. The model displays by default; the actor is carried
by the address and recoverable with `%ae`, `shortlog -e`, or a mailmap.

Puts the varying field in the visible position. Costs `shortlog` grouping: commits
fragment across model names and across versions of one model.

### Option C — Composite name

`Claude Code (Opus 5) <claude-code@tais-den.dev>`. Both fields visible without reading a
trailer.

Loses nothing informationally, but produces long author columns, and the parenthetical
is not a structured field — anything parsing it is parsing prose.

## Decision Outcome

**Chosen option: Option B — `user.name` carries the model, `user.email` carries the
actor.**

### The convention

```text
<Model Display Name> <actor@tais-den.dev>
```

| Field | Carries | Example |
| --- | --- | --- |
| `user.name` | Model display name, human-readable | `Opus 5` |
| `user.email` | Agent framework (the actor), as an alias | `claude-code@tais-den.dev` |

Worked examples:

| Commit source | Author line |
| --- | --- |
| Claude Code running Opus 5 | `Opus 5 <claude-code@tais-den.dev>` |
| Hermes running DeepSeek V4 | `DeepSeek V4 <hermes-agent@tais-den.dev>` |
| Joey, unassisted | `Joey Clark <taisden@tais-den.dev>` |

The human row is unchanged. A human is not a model, and `user.name` continues to carry
the person's name.

### Relationship to the trailer

`user.name` carries a display form; `Agent-Attribution:` continues to carry the
canonical provider-qualified identifier. The redundancy is deliberate and the two are
not interchangeable:

```text
Agent-Attribution: actor=Claude Code; model=anthropic/claude-opus-5; role=Head Architect; session=architecture-planning
```

`Opus 5` is what a reviewer reads in a commit list. `anthropic/claude-opus-5` is what
tooling matches on. `actor=` restates the framework named in the email so the trailer
stands alone when quoted out of context.

### Scope of supersession

This ADR supersedes **only** the `user.name` / `user.email` semantics in ADR-0018's
actor table. Everything else in ADR-0018 stands unchanged: the single GitHub identity,
email-as-actor-discriminator, `Co-authored-by:` for hybrid commits, and the
`Agent-Attribution:` trailer format and its role in the audit trail.

The framework has no status value for an ADR that is superseded in part. ADR-0018 is not
marked `superseded`, because it is not — one table within it is. Both ADRs cross-
reference each other in their Links sections, following the pattern ADR-0018 itself
established with ADR-0011. That pattern works, but it relies on a reader following links
to discover that a table they are reading has been overridden. A future ADR should
decide whether the framework needs partial-supersession vocabulary, or whether
scope-limited supersession stated in the superseding ADR is sufficient.

## Consequences

### Positive

- The model is visible in every default git and GitHub view, without flags or trailer
  reading.
- The actor stays mechanically recoverable via `%ae`, `git shortlog -e`, or mailmap —
  not inferred from prose.
- Adding a model to a framework requires no configuration change beyond `user.name`.
- Scales as the number of frameworks and models grows, which Option A does not.

### Negative

- `git shortlog` without `-e` now groups by model, and fragments across model versions —
  `Opus 5` and `Opus 4.8` count separately. A `.mailmap` mapping model names to actor
  addresses restores actor-level grouping for anyone who wants it.
- Model identity appears in two places with two granularities. They can drift if set
  carelessly; the trailer is authoritative when they disagree.
- One more thing to configure correctly per session, in a repository where the previous
  session had no git identity configured at all.

### Neutral

- No change to the GitHub identity layer. All addresses remain aliases under
  `ajoeofalltrades`, and GitHub continues to render every commit against that profile.
- Historical commits are not rewritten. Commits authored under ADR-0018's table remain
  valid records of the convention in force when they were made.

## Validation

- **Signal:** `git log --format='%an <%ae>'` over commits after acceptance shows a model
  name in the author position and an actor alias in the address, for every agent commit.
- **Signal:** for any agent commit, the `Agent-Attribution:` trailer's `actor=` matches
  the local part of the author email.
- **Review checkpoint:** when a third agent framework is added, or when one framework
  runs more than three models concurrently. If `git shortlog` fragmentation has become
  the dominant complaint by then, a `.mailmap` is the first remedy and Option C the
  second.
- **Failure condition:** if commits appear with a model in `user.name` and a mismatched
  or absent `actor=` in the trailer, the two-place redundancy is drifting and should be
  collapsed to one field by a superseding ADR.

## Links

- ADR-0018: Single-identity workflow with agent co-attribution — establishes the
  three-layer convention; its `user.name` / `user.email` table is superseded in part by
  this ADR.
- ADR-0021: Cron actor identity — unattended actors carry their own address under the
  same scheme.
- ADR-0011: Multi-identity GitHub model — framework-level target for projects with
  separate human and agent GitHub accounts; unaffected by this decision.
