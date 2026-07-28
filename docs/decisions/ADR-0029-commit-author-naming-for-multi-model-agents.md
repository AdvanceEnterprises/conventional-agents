---
type: adr
id: ADR-0029
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0017
supersedes:
  - ADR-0018
superseded_by: null
---

# ADR-0029: Single-identity workflow with agent co-attribution and model-named authorship

## Status

- Proposed
- Supersedes ADR-0018 in full. On acceptance, ADR-0018 becomes `superseded`.

This ADR restates the entire commit-attribution convention. ADR-0018 established it;
this ADR changes one part — which field carries the model — and reproduces the rest
verbatim in substance so that no reader must consult a superseded document to know the
convention in force.

## Context and Problem Statement

### The original problem (from ADR-0018)

`ADR-0011` established a three-identity GitHub model: human, agent-committer, and
agent-reviewer, each a separate GitHub account. The intent was to separate authorship
from review, preserve an audit trail, and prevent agents reviewing their own work under
the same identity.

The operational reality of this repository is different. One GitHub account
(`ajoeofalltrades` / Joey Clark) performs all commits, PRs, and reviews. Agent activity
is supervised and interactive. Provisioning two additional accounts carries real cost —
token management, `gh auth switch` discipline per session, profile upkeep — for
enforcement benefit that is nil while every agent action has a human watching it.

But abandoning attribution entirely is worse. Once agents commit invisibly under the
human's identity, the repository's history tells no story about who did what, and the
framework's central claim — that agent work is auditable — becomes false in its own
repository.

### The new problem

ADR-0018 resolved that by distinguishing actors through `user.email` while keeping one
GitHub login, and by recording the model in an `Agent-Attribution:` trailer. Its actor
table put the **actor** in `user.name`:

| Actor | `user.name` | `user.email` |
| --- | --- | --- |
| Human (Joey) | `Joey Clark` | `taisden@tais-den.dev` |
| Hermes Agent | `Hermes Agent` | `hermes-agent@tais-den.dev` |

That was correct when one agent framework operated here. Two facts have changed. More
than one framework now commits — Hermes Agent and Claude Code — and each runs different
models across sessions. The actor is no longer the field that varies.

The consequence is visible in tooling. `git log`, `git shortlog`, `git blame`, and every
GitHub commit list render `user.name` by default and show trailers only on request.
Under ADR-0018's table, a year of commits from one framework displays one repeated name
while the audit-relevant fact — which model produced the change — is recoverable only by
reading each message body. In a repository whose stated purpose is making agent work
auditable, the discriminating field is the one hidden by default.

The question this ADR answers: **how are actors and models distinguished in commit
metadata, under one GitHub identity, when multiple frameworks each run multiple models?**

## Decision Drivers

- **Audit trail without account overhead.** Distinguish actors without provisioning and
  maintaining separate GitHub accounts.
- **Hybrid sessions must be representable.** When a human and an agent both contribute
  to one commit, both must appear.
- **The default view should carry the discriminating information.** Attribution
  requiring a non-default flag to see is attribution that will not be seen.
- **Both actor and model must remain mechanically recoverable.** Whichever occupies the
  name field, the other must be retrievable — not inferred from prose.
- **Forward compatibility with ADR-0011.** The convention must map cleanly onto separate
  accounts when this repository is ready for them, without losing history.
- **The identity gate's intent must stay exercisable.** ADR-0012's gate is trivially
  satisfied with one account; something must still catch wrong-actor commits.

## Considered Options

### Identity model

**Option A — No distinction.** All commits under one name and email. Zero overhead,
zero audit trail. A step backwards from ADR-0011's intent.

**Option B — Email distinction only.** Different `user.email` per actor, no trailers.
Preserves the actor distinction but loses hybrid sessions: when a human and an agent
work on one commit, only the committer's email is recorded and the contributor is
invisible.

**Option C — Email distinction plus co-author and attribution trailers.** Actors
distinguished by email; `Co-authored-by:` names non-primary actors; `Agent-Attribution:`
records model, role, and session. Two layers are the minimum needed to represent hybrid
sessions accurately.

**Option D — Provision separate accounts per ADR-0011 now.** Correct long-term,
premature today. Real operational cost, no enforcement benefit while all agent activity
is supervised.

### Name-field assignment

**Option E — Name carries the actor.** ADR-0018's table. Stable across sessions, so
`git shortlog` groups cleanly by actor. But the model is invisible in every default
view, and grows more invisible as models per framework multiply.

**Option F — Name carries the model, email carries the actor.** Puts the varying field
in the visible position; the actor moves to the address, recoverable via `%ae`,
`shortlog -e`, or mailmap. Costs `shortlog` grouping — commits fragment across model
names and versions.

**Option G — Composite name.** `Claude Code (Opus 5) <claude-code@tais-den.dev>`. Both
visible without reading a trailer, but produces long author columns and the
parenthetical is prose, not a structured field.

## Decision Outcome

**Chosen: Option C for the identity model, Option F for the name field.**

### Single GitHub identity

One GitHub identity (`ajoeofalltrades` / Joey Clark) performs all commits, PRs, and
reviews in this repository. The identity layer does not distinguish actors.

### Actor and model in commit metadata

```text
<Model Display Name> <actor@tais-den.dev>
```

| Field | Carries | Example |
| --- | --- | --- |
| `user.name` | Model display name, human-readable | `Opus 5` |
| `user.email` | Agent framework — the actor — as an alias | `claude-code@tais-den.dev` |

Worked examples:

| Commit source | Author line |
| --- | --- |
| Claude Code running Opus 5 | `Opus 5 <claude-code@tais-den.dev>` |
| Hermes running DeepSeek V4 | `DeepSeek V4 <hermes-agent@tais-den.dev>` |
| Joey, unassisted | `Joey Clark <taisden@tais-den.dev>` |

The human row is unchanged from ADR-0018. A human is not a model, and `user.name`
continues to carry the person's name.

These addresses are aliases under the same GitHub login. GitHub renders each commit's
author email as a link to the `ajoeofalltrades` profile, while `git log`, `git shortlog`,
and downstream tooling distinguish actors by email.

The chosen addresses are recommendations, not hard rules. A project may use different
addresses provided the pattern holds: one address per actor, all under the same login.

### `Co-authored-by:` trailer

Names the non-primary actor for hybrid sessions:

- A commit where Joey wrote the content and an agent wrote the commit message includes
  `Co-authored-by: <Model> <actor@tais-den.dev>` in the message body.
- A commit where a cloud-side assistant suggested content that Joey integrated locally
  includes a trailer only if that assistant is registered as a local co-author when the
  commit is made. Suggestions surfaced through Joey's edits and committed under Joey's
  identity do not reach the local audit trail on their own. If a future workflow change
  makes such an assistant a local co-author, the convention applies naturally.
- A pure-agent commit needs no `Co-authored-by:` trailer — the email alone identifies
  the actor.

GitHub renders `Co-authored-by:` natively as a second author chip on the commit page.

### `Agent-Attribution:` trailer

Records the model, role, and session of any agent actor. This is the third attribution
layer, on top of `user.email` and `Co-authored-by:`:

- It persists into the audit trail the role and session declaration that
  `guidelines/ROLE_CONTRACT.md` §"Role and session transparency" already requires at
  session start.
- It distinguishes a Reviewer-role agent from an Implementer-role agent even when both
  commit under the same login.
- It carries the canonical provider-qualified model identifier, which `user.name` does
  not.

Format:

```text
Agent-Attribution: actor=<actor>; model=<provider/model-id>; role=<role>; session=<session-mode>
```

Examples:

```text
# Pure-agent commit, Claude Code running Opus 5 as Head Architect
Agent-Attribution: actor=Claude Code; model=anthropic/claude-opus-5; role=Head Architect; session=architecture-planning
```

```text
# Hybrid commit — Joey and Hermes both contributed
Co-authored-by: DeepSeek V4 <hermes-agent@tais-den.dev>
Agent-Attribution: actor=Hermes Agent; model=ollama-cloud/deepseek-v4-flash; role=Implementer; session=implementation
Agent-Attribution: actor=Joey Clark; model=human; role=Implementer; session=implementation
```

Multiple `Agent-Attribution:` trailers are permitted when more than one agent actor
contributed.

### Relationship between the name field and the trailer

`user.name` carries a display form; the trailer carries the canonical
provider-qualified identifier. The redundancy is deliberate and the two are not
interchangeable. `Opus 5` is what a reviewer reads in a commit list;
`anthropic/claude-opus-5` is what tooling matches on. The trailer's `actor=` restates the
framework named in the email so the trailer stands alone when quoted out of context.

**Where they disagree, the trailer is authoritative.**

### Recommended commit structure for agent commits

```text
<type>(<scope>?): <summary>

<body>

Co-authored-by: <actor-or-model> <<email>>
Agent-Attribution: actor=<actor>; model=<provider/model>; role=<role>; session=<session-mode>
```

GitHub does not render custom trailers natively, but `git log --format=%(trailers)`
parses them and `test/FS-0017/commit-attribution.bats` verifies them. PR bodies should
also carry an "Agent Attribution" section summarizing the agent actors and their roles —
see `workflows/git-and-gh-conventions.md` §"PR body template (agents)".

### How this maps onto existing rules

**ADR-0012 §"GitHub identity gate".** The gate's literal text requires verifying the
active account is the expected agent-committer identity. With one account this becomes
"verify the active account is `ajoeofalltrades`," which trivially passes. To exercise the
gate's intent — preventing wrong-actor actions — a parallel check applies before any
commit: **verify the staging-area `user.name`/`user.email` matches the actor and model
making the commit.** A bats test enforces this on recent commits; a pre-commit hook can
enforce it before the commit lands.

**ROLE_CONTRACT §"Role and session transparency".** Roles remain in-session
declarations, not identities. Head Architect, Implementer, Reviewer and the rest are
stance choices within a session and need no separate GitHub accounts. Per-session role
declaration behavior is unchanged.

**`workflows/git-and-gh-conventions.md`.** Documents the convention, including the actor
table above, the `git -c user.name=... -c user.email=... commit` form for per-commit
override, when to add `Co-authored-by:`, and how to set identity once per agent session
via `git config user.useConfigOnly true` plus an `includeIf` directive.

**`skills/git-gh-workflow/SKILL.md`.** Teaches agents to recognize the convention, set
`user.name` and `user.email` when authoring commits, and add trailers in hybrid sessions.

### Forward compatibility with ADR-0011

`ADR-0011` describes the target identity model for projects with separate human and
agent GitHub accounts. This ADR describes the operational model for projects running
with one identity. They are complementary, not in conflict, and ADR-0011 is unaffected
by this decision.

When this repository is ready to transition to separate accounts:

1. Create the `taisden-agent-committer` and `taisden-agent-reviewer` accounts.
2. Add both accounts' emails to the existing profiles so pre-transition commits still
   link correctly.
3. Update agent commit tooling to use the new account tokens via `gh auth switch` rather
   than per-commit `user.email` overrides.
4. The `Co-authored-by:` convention continues unchanged, now representing a
   cross-account relationship rather than same-account co-authorship.

## Consequences

### Positive

- The audit trail distinguishes human from agent commits at the email level and hybrid
  sessions at the trailer level, without separate GitHub accounts.
- The model — the field that actually varies — is visible in every default git and
  GitHub view, with no flags and no trailer reading.
- The actor stays mechanically recoverable via `%ae`, `git shortlog -e`, or mailmap.
- ADR-0012's identity gate becomes exercisable: a commit shipping with the wrong actor
  email is detectable and rejectable.
- Adding a model to a framework requires no configuration beyond `user.name`, and the
  scheme scales as frameworks and models multiply.
- Both attribution layers map cleanly onto separate-account identity later, with no
  historical information lost.

### Negative

- `git shortlog` without `-e` groups by model and fragments across model versions —
  `Opus 5` and `Opus 4.8` count separately. A `.mailmap` mapping model names to actor
  addresses restores actor-level grouping.
- Model identity appears in two places at two granularities and can drift if set
  carelessly. The trailer governs when they disagree.
- Commit metadata is noisier: hybrid sessions carry two addresses per commit.
- `git config` discipline is required per agent session. Set it wrong and the audit
  trail degrades to Option A.
- Email aliases must remain valid, which requires `tais-den.dev` staying under Joey's
  control.
- Readers unfamiliar with the convention will see `Opus 5 <claude-code@tais-den.dev>` and
  not realize it is the same login as `ajoeofalltrades`. README and AGENTS.md should
  explain briefly.

### Neutral

- Trailers are opt-in per situation. Pure-agent and pure-human commits need none; the
  `Co-authored-by:` convention fires only when more than one actor contributed.
- Branch protection is unchanged. ADR-0011's CODEOWNERS-style enforcement remains the
  target once separate accounts exist.
- Historical commits are not rewritten and remain valid records of the convention in
  force when they were made.

## Validation

1. **Distinguishable authorship.** `git log --format='%an <%ae>' -n 50 | sort -u` shows
   model names in the author position and actor aliases in the address, with at least two
   distinct actor addresses across the repository's history.
2. **Trailer consistency.** For any agent commit, the `Agent-Attribution:` trailer's
   `actor=` matches the local part of the author email.
3. **Hybrid sessions carry co-author trailers.** A representative hybrid commit carries
   the appropriate `Co-authored-by:` trailer.
4. **The bats test passes.** `test/FS-0017/commit-attribution.bats` verifies that recent
   commits carry a known-actor email or a `Co-authored-by:` trailer naming a known actor,
   and that agent-authored commits carry a well-formed `Agent-Attribution:` trailer.
5. **Discoverability.** README and AGENTS.md mention the convention, so a reader can
   find it without opening this ADR.
6. **No CI regression.** `npm run check:status` and `npm run lint:docs` continue to pass.
7. **Review checkpoint.** When a third agent framework is added, or when one framework
   runs more than three models concurrently. If `shortlog` fragmentation is the dominant
   complaint by then, a `.mailmap` is the first remedy and Option G the second.
8. **Failure condition.** If commits appear with a model in `user.name` and a mismatched
   or absent `actor=` in the trailer, the two-place redundancy is drifting and should be
   collapsed to one field by a superseding ADR.

## Links

- ADR-0018: Single-identity workflow with agent co-attribution — superseded in full by
  this ADR.
- ADR-0011: Multi-identity GitHub model — framework-level target for projects with
  separate human and agent identities; unaffected by this decision.
- ADR-0012: Non-overridable safety gates — defines the identity gate whose intent this
  ADR re-anchors on commit metadata.
- ADR-0021: Cron actor identity — unattended actors carry their own address under this
  scheme.
- FS-0017: Single-identity commit attribution — the spec that implemented ADR-0018's
  convention.
- `guidelines/ROLE_CONTRACT.md` §"GitHub identity gate", §"Role and session
  transparency".
- `workflows/git-and-gh-conventions.md`, `skills/git-gh-workflow/SKILL.md` — documents
  carrying the convention.
