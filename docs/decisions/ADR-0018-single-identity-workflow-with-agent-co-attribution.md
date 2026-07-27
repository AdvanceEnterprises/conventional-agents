---
type: adr
id: ADR-0018
status: proposed
decision_scope: workflow
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0018: Single-identity workflow with agent co-attribution

## Status

- Proposed

## Context and Problem Statement

ADR-0011 established a three-identity GitHub model: human, agent-committer,
and agent-reviewer. The intent was clear — separate authorship from review,
preserve an audit trail, avoid agents reviewing their own work under the same
identity. The model assumes three GitHub accounts.

The current operational reality of this repository is different. Only one
GitHub account is in use (`ajoeofalltrades` / Tai Solstag), and two agents
currently operate in or against the repo: **Hermes Agent** (running on
`hades-01` via Quadlet, also operating in interactive sessions like this one)
and **GitHub Copilot** (operating via IDE integration). More agents may be
added later, but the identity model must work today with these two.

This creates three concrete problems:

1. **Audit trail ambiguity.** PRs opened by Hermes or Copilot are authored by
   `ajoeofalltrades`. Reviews posted by an agent are posted by
   `ajoeofalltrades`. A reader of the repository cannot tell, from GitHub
   alone, which actions were human-driven, agent-driven, or hybrid.

2. **The GitHub identity gate (ADR-0012) is a no-op.** With one identity,
   "verify the active account is the expected one" trivially passes — there
   is no wrong identity to be. The gate's intent (preventing privilege
   escalation by habit) is not exercised.

3. **Multi-account setup is premature.** Adding `taisden-agent-committer` and
   `taisden-agent-reviewer` accounts would create real operational cost
   (multiple tokens, `gh auth switch` per session, separate SSH keys, branch
   protection wiring) without commensurate benefit until agents operate
   *autonomously* (scheduled tasks, multi-agent pipelines). Today,
   agent-driven actions are supervised interactively — separation by account
   adds ceremony without enforcement.

This ADR does not contradict ADR-0011. ADR-0011 remains the framework's
recommendation for projects that have separate human/agent identities. This
ADR documents the operational reality and convention for projects (including
this repo today) that operate with one GitHub identity and one or more
agents.

## Decision Drivers

- **Auditability** — Even with one GitHub login, readers of the repo should
  be able to tell which commits were authored by which actor (human vs
  specific agent).
- **Operational simplicity** — Avoid forcing multi-account setup before
  autonomous-agent workflows exist. Don't add ceremony that isn't enforced.
- **Forward compatibility** — When autonomous-agent workflows arrive, the
  attribution layer added by this ADR should map cleanly onto
  separate-account identity. The convention chosen should not block a later
  transition to ADR-0011's three-identity model.
- **Tool compatibility** — Must work with git, GitHub's commit rendering,
  `gh` CLI, and conventional-agents' existing CI / lint gates.
- **Identity gate stays meaningful** — The gate's *intent* (preventing
  wrong-actor actions) should be exercisable in the single-account regime.

## Considered Options

### Option A — Single identity, no attribution layer

Continue using one GitHub account with no distinguishing metadata. Commit
author and GitHub login both show `ajoeofalltrades` for every commit, PR, and
review. Agents are invisible in the audit trail.

### Option B — Git author/email distinction only

Use git's `user.email` field to distinguish human commits from agent
commits. Human commits use `taisden@tais-den.dev`; agent commits use
`hermes-agent@tais-den.dev` (or per-agent addresses). GitHub renders both as
the same profile but the email addresses differ. No co-author trailers.

### Option C — Git author/email distinction + co-author trailer (chosen)

Use both layers. Agent commits set a distinguishing `user.email`. Hybrid
sessions (human + agent working together on one commit) additionally include
a `Co-authored-by:` trailer naming the agent. This produces:

- A distinguishable email per actor in `git log`.
- A second actor in the `Co-authored-by:` field for hybrid sessions.
- Two layers of attribution that can be enforced, displayed, and later
  mapped onto separate GitHub identities if/when that transition happens.

### Option D — Add multi-account setup per ADR-0011 immediately

Create `taisden-agent-committer` and `taisden-agent-reviewer` accounts now,
even though all current agent activity is supervised. Use `gh auth switch`
per session.

## Decision Outcome

**Chosen option: Option C — git author/email distinction + co-author
trailer.**

### The convention

**Single GitHub identity** (`ajoeofalltrades` / Tai Solstag) is used for all
commits, PRs, and reviews in this repository. The identity layer does not
distinguish actors.

**Git `user.email` distinguishes actors** at the commit-metadata level:

| Actor | `user.name` | `user.email` |
| --- | --- | --- |
| Human (Tai) | `Tai Solstag` | `taisden@tais-den.dev` |
| Hermes Agent | `Hermes Agent` | `hermes-agent@tais-den.dev` |
| GitHub Copilot | `GitHub Copilot` | `copilot@tais-den.dev` |

These addresses are aliases under the same GitHub login. GitHub will render
each commit's author email as a link to the `ajoeofalltrades` profile, but
`git log`, `git shortlog`, and downstream tooling can distinguish actors by
email.

**`Co-authored-by:` trailer** names the non-primary actor for hybrid
sessions:

- A commit where Tai wrote the code and Hermes wrote the commit message
  includes `Co-authored-by: Hermes Agent <hermes-agent@tais-den.dev>` in
  the message body.
- A commit where Copilot suggested a function and Tai integrated it
  includes `Co-authored-by: GitHub Copilot <copilot@tais-den.dev>`.
- A pure-agent commit (e.g., autonomous batch update) does not need a
  trailer — the email alone identifies the actor.

GitHub renders `Co-authored-by:` trailers natively as a second author chip
on the commit page.

### How this maps onto the existing rules

**ROLE_CONTRACT §"GitHub identity gate" (ADR-0012).** The gate's literal
text says *"verify the active account is the expected agent-committer
identity."* With one account, the gate becomes: *"verify the active account
is `ajoeofalltrades`."* That trivially passes. To exercise the gate's
*intent* (preventing wrong-actor actions), we add a parallel check before
any commit: **verify the staging-area `user.name`/`user.email` matches the
actor making the commit.** A bats test enforces this convention on recent
commits; pre-commit hooks can enforce it before the commit lands.

**ROLE_CONTRACT §"Role and session transparency".** Roles remain
in-session declarations, not identities. Head Architect, Implementer,
Reviewer, etc., are stance choices within a session — they don't need
separate GitHub accounts. The current per-session role declaration
behavior is unchanged.

**`workflows/git-and-gh-conventions.md`.** A new section
"Single-identity workflow with agent co-attribution" documents the
convention, including:

- The actor table above.
- The exact `git -c user.name=... -c user.email=... commit` form for
  per-commit actor override.
- When to add `Co-authored-by:` trailers.
- How to set identity once per agent session via `git config user.useConfigOnly true` + an includeIf directive in `.gitconfig`.

**`skills/git-gh-workflow/SKILL.md`.** A new section teaches agents to
recognize the convention, set their own `user.email` when authoring
commits, and add `Co-authored-by:` trailers in hybrid sessions.

### Why not the other options?

**Option A** loses the audit trail entirely. Once Copilot and Hermes are
both authoring commits invisibly, the repo's history tells no story about
who did what. This is a step backwards from ADR-0011's intent.

**Option B** preserves the email distinction but loses the hybrid-session
case. When Tai and Hermes work together on one commit, only the committer's
email is recorded; the contributor's involvement is invisible. Two-layer
attribution is the minimum needed to represent hybrid sessions accurately.

**Option D** is correct long-term but premature now. The operational cost
of three accounts is real and the enforcement benefit is nil while all
agent activity is supervised interactively. When autonomous agents
arrive, this ADR is the stepping stone: the email + trailer convention
maps cleanly onto separate GitHub accounts (the email becomes the login,
the trailer becomes the "co-committer from another account" relationship).

### Mapping to ADR-0011 (forward compatibility)

ADR-0011 describes the target identity model for projects with separate
human and agent identities. ADR-0018 describes the operational model for
projects (including this repo today) operating with one identity. The two
are complementary, not in conflict.

When this repo (or any project following ADR-0018) is ready to transition
to separate accounts, the migration path is:

1. Create the `taisden-agent-committer` and `taisden-agent-reviewer`
   GitHub accounts.
2. Add both accounts' emails to the existing authors' GitHub profiles
   so commits authored before the transition still link correctly.
3. Update agent commit scripts to use the new account tokens via
   `gh auth switch` rather than per-commit `user.email` overrides.
4. The `Co-authored-by:` trailer convention continues unchanged; it now
   represents a cross-account relationship rather than a same-account
   co-authorship.

This ADR does not require ADR-0011 to be modified. The two cross-reference
each other (ADR-0011's Links section gets a new line; this ADR's Links
section lists ADR-0011 as the framework-level target).

## Consequences

### Positive

- The audit trail distinguishes human commits from agent commits at the
  email level, and hybrid sessions at the trailer level — without requiring
  separate GitHub accounts.
- The Identity Gate's *intent* becomes exercisable: a commit that ships
  with the wrong actor email is detectable and rejectable.
- Two layers of attribution map cleanly onto separate-account identity
  later; no historical information is lost in the transition.
- Agents and humans can continue to share one GitHub login without
  ceremony, while the metadata tells the real story.

### Bad

- Commit metadata becomes slightly noisier — hybrid sessions have two
  email addresses per commit instead of one.
- A `git config` discipline is required: per-agent sessions must set
  `user.email` correctly or the audit trail degrades to Option A.
- Two email aliases must be kept deliverable (or at least valid) so GitHub
  doesn't reject commit attribution. The `tais-den.dev` domain must
  remain under Tai's control.
- Readers of the repo who don't know the convention will see "Hermes
  Agent <hermes-agent@tais-den.dev>" and not realize that's the same
  login as `ajoeofalltrades`. README and AGENTS.md should briefly explain.

### Neutral

- The convention is opt-in for hybrid sessions. Pure-agent commits don't
  need trailers; pure-human commits don't need them either. The convention
  only fires when more than one actor contributed.
- The chosen email addresses are recommendations, not hard rules. A
  project can use different addresses as long as the *pattern* (one
  address per actor, all under the same login) holds.
- Branch protection rules don't change with this ADR. ADR-0011's
  CODEOWNERS-style enforcement is still the target when separate
  accounts exist.

## Validation

We will consider this decision successful if:

1. **Recent commits show distinguishable emails.** `git log --format='%an
   <%ae>' -n 50 | sort -u` lists at least two of the three actor emails
   in this repo's history, with the agent email appearing on commits that
   were agent-driven.
2. **Hybrid sessions show `Co-authored-by:` trailers.** A representative
   hybrid commit (one authored by Tai with Hermes drafting, or vice
   versa) carries the appropriate trailer.
3. **The bats test passes.** `test/FS-0016/attribution.bats` (or
   equivalent new test) verifies that every commit on `trunk` and on
   the most recent release branch has either a known-actor email or a
   `Co-authored-by:` trailer naming a known actor.
4. **README and AGENTS.md mention the convention.** A reader landing on
   the repo can discover the convention without reading ADR-0018
   directly.
5. **No regression in CI or lint.** `npm run check:status` and
   `npm run lint:docs` continue to pass; the bats test integrates with
   the existing test suite.

## Links

- ADR-0011: Multi-identity GitHub model (framework-level target for
  projects with separate human/agent identities)
- ADR-0012: Non-overridable safety gates (defines the Identity Gate
  whose intent this ADR re-anchors on commit metadata)
- ROLE_CONTRACT.md §"GitHub identity gate" (operational contract)
- ROLE_CONTRACT.md §"Role and session transparency" (roles remain
  stance, not identity)
- `workflows/git-and-gh-conventions.md` (workflow doc updated by this ADR)
- `skills/git-gh-workflow/SKILL.md` (skill updated by this ADR)
