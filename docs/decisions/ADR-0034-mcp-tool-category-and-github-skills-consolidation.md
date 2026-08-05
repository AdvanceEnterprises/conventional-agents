---
type: adr
id: ADR-0034
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
created: 2026-08-05
updated: 2026-08-05
---

# ADR-0034: MCP tool category and GitHub skills consolidation

## Status

- Proposed

## Context and Problem Statement

The framework's tool taxonomy (`ADR-0015`) defines three categories: governance
gates (Category 1), productivity skills (Category 2), and platform tools
(Category 3). Two gaps have accumulated since it was accepted, both recorded in
`BACKLOG.md`:

**Gap 1 — MCP servers do not fit any existing category.** Model Context Protocol
servers are external processes agents invoke through a protocol rather than a
CLI. They are not CI-enforced scripts (Category 1), not markdown skill files
(Category 2), and not runtime-assumed capabilities like `git` (Category 3).
They are *introduced* by the framework or consumer, carry their own authority
model, and have a lifecycle. Miscategorisation has a concrete cost: a tool filed
as Category 2 escapes the approved-FS requirement Category 1 imposes, and a
tool filed as Category 3 escapes governance entirely.

The unresolved questions from `BACKLOG.md`:

- Is an MCP server a fourth category or a subtype of platform capability?
- What authority does an MCP server carry — bounded by the session's role,
  by `ADR-0014`'s background-task rules, or by something new?
- How is an MCP server introduced, and which role is accountable?

**Gap 2 — GitHub skills are undersized and the Agent Skills upstream is
unrecorded.** The framework ships a single `git-gh-workflow` skill at 558 lines
— over the Agent Skills spec's 500-line recommendation. Hermes Agent ships ten
GitHub skills with richer operational detail, but they are platform-specific
and cannot be ported directly. The Agent Skills format (`SKILL.md`) is an
unnamed upstream dependency with three conformance violations (non-spec
top-level fields, `metadata` typing violations, oversize skills).

Git and GitHub are unique among platform tools: they are the only tools the
framework can assume in every environment — its own and every consumer's. The
framework's governance, work-item lifecycle, and autonomous triggers all depend
on GitHub. The quality and discoverability of GitHub skills is a first-class
concern.

The question this ADR answers: **how does the framework extend its tool
taxonomy to cover MCP servers, and how does it consolidate its GitHub skills
into a coherent, framework-agnostic set while recording the Agent Skills
upstream dependency?**

## Decision Drivers

- **ADR-0015 is append-only.** The taxonomy cannot be widened by editing it.
  A new ADR is required.
- **Miscategorisation has a concrete cost.** The answer must not be "nearest
  fit" — a tool in the wrong category either escapes governance or imposes
  unnecessary FS/PLAN overhead.
- **Authority must be scoped, not inherited.** An MCP server with file system
  or command execution capabilities is an agent with delegated authority. The
  framework must say where that authority comes from and how it is bounded.
- **Git and GitHub are universal in this framework's domain.** The framework's
  GitHub skills should be the best in the framework, not an afterthought.
- **The Agent Skills format is an external standard.** Recording the dependency
  and fixing conformance is a prerequisite to public publication.
- **Skills are Category 2 per ADR-0015.** No FS is required to introduce or
  modify them, but they must have a `SKILL.md`, be listed in `skills/index.md`,
  and pass `--self-test` before merging.

## Considered Options

### Option A — MCP as a subtype of Category 3 (platform tools)

Treat MCP servers as a special case of platform tools. No new category, no new
introduction requirements.

Cheapest immediately, but wrong: MCP servers are *introduced*, not assumed
present. They have a lifecycle and carry authority that may exceed a session
role. Filing them as Category 3 means the framework has no opinion on what an
MCP server may do — the same gap that exists today.

### Option B — MCP as a fourth category, with binding pattern

Establish a fourth category following `ADR-0024`'s two-layer pattern: a
platform-neutral core plus concrete bindings in `integrations/`. The
binding-first ordering rule applies: the binding is written first, the
abstraction extracted from it.

Most complete answer, but most expensive. Requires a new FS and PLAN for the
core definition plus at least one binding to validate the abstraction.

### Option C — MCP as a fourth category, core-only, bindings deferred

Establish the fourth category in this ADR with the core definition, deferring
concrete bindings to follow-up work.

Less expensive than Option B, and sufficient to close the taxonomy gap. The
binding-first rule from `ADR-0024` is a strong precedent, but the framework has
no MCP server to bind against yet — writing a binding before one exists would
be the `packs/` failure mode (a phantom directory). The core definition is the
right deliverable now; bindings arrive when a concrete MCP server is adopted.

### Option D — Consolidate GitHub skills, record Agent Skills upstream, defer MCP

Address only the skills consolidation and upstream recording. Leave the MCP
taxonomy question for a separate ADR.

Safest scope, but defers a known gap. The MCP and skills questions are
independent in implementation — they touch different files and different
governance mechanisms — so there is no coupling reason to defer one.

## Decision Outcome

**Chosen option: Option C — MCP as a fourth category, core-only, with Option
D's skills consolidation bundled in the same change.**

The two concerns share a root cause: the framework's tool model has gaps that
`ADR-0015` cannot close by editing. A single ADR records both decisions; a
single PLAN sequences the work across both tracks.

### Part 1 — MCP as a fourth tool category

A new Category 4 is added to the taxonomy defined in `ADR-0015`:

#### Category 4: Protocol-based external capabilities (MCP servers)

##### Definition

External processes that agents invoke through the Model Context
Protocol (or an equivalent capability-declaration protocol). MCP servers are
not distributed with the framework, are not assumed present in the runtime
environment, and are introduced by the framework or consumer through explicit
installation or configuration.

##### Characteristics

- Live outside the framework's directory tree (installed by the consumer or
  runtime).
- Declared through a capability manifest naming the server, its transport, and
  the tools/resources it exposes.
- Invocable by agents during a session without human approval per invocation,
  **within the authority bounds declared in the server's manifest**.
- Any MCP server whose declared capabilities include file system write access,
  command execution, network access beyond the origin, or credential management
  MUST be treated as a background task under `ADR-0014` and MUST declare its
  authority scope in a form the session's role model can evaluate.

##### Introduction requirements

- No FS required to adopt an existing MCP server whose declared capabilities
  are within the consumer's existing authority baseline.
- If the framework ships a recommended MCP server configuration (e.g., a
  `config/mcp-servers.yml` example), that configuration is a Category 4
  artifact and follows the same lightweight introduction rules as a
  productivity skill (no FS required, documented in `integrations/`).
- If an MCP server's capabilities would expand the framework's governance
  surface (e.g., modifying Issue statuses, approving PLANs, writing to reserved
  paths), its adoption requires an approved FS and PLAN — the same as a new
  governance gate.
- The framework's own MCP server configuration (if any) MUST be documented in
  `integrations/` following the `ADR-0024` binding pattern.

##### Authority model

An MCP server's authority is bounded by the **intersection** of:

1. The session's current role and mode (per `guidelines/ROLE_CONTRACT.md`).
2. The server's declared capability scope (per its manifest).
3. `ADR-0014`'s background-task rules (if the server's capabilities include
   mutation of any governed artifact).

The weakest of the three bounds applies. An MCP server whose manifest declares
write access to the file system does not thereby gain the right to modify
governed documents during a Review session — the session role's prohibition on
modification (Role 4, Reviewer) is the tighter bound.

##### Responsible role

Head Architect (Role 0) for proposing adoption of an MCP
server whose capabilities affect governance. Implementer (Role 3) for
configuring and integrating an MCP server whose capabilities are within the
existing authority baseline.

### Part 2 — GitHub skills consolidation and Agent Skills upstream recording

**Record the Agent Skills upstream dependency.** Add Agent Skills
([agentskills.io](https://agentskills.io/specification)) to `README.md`'s
"Upstream References" section, matching the treatment of Conventional Commits,
Keep a Changelog, MADR, and arc42.

**Fix SKILL.md conformance.** Move `version`, `author`, and `platforms` fields
under `metadata` as string values (per the Agent Skills spec). Flatten the
`metadata.hermes` nesting. These are mechanical changes to existing skills.

**Split `git-gh-workflow` into focused sub-skills.** The single skill is over
the Agent Skills spec's 500-line recommendation. Split it into:

- `git-branch-and-commit` — branching, commits, commit body conventions
- `gh-pr-workflow` — PR lifecycle, CI monitoring, merging
- `gh-code-review` — reviewing PRs, inline comments, formal reviews
- `gh-issues` — creating, triaging, managing issues
- `gh-remote-verification` — verifying remote state after pushes

Each sub-skill is framework-agnostic (no Hermes-specific paths, no
platform-specific auth scripts). The existing `git-gh-workflow` skill is
deprecated and its content replaced with a redirect to the sub-skills.

**Port the two already-agnostic Hermes skills.** `github-governed-doc-tracking`
and `reviewing-stacked-prs` have no Hermes-specific content and reference
framework paths already. Port them as:

- `gh-governed-doc-tracking` — FS/PLAN/ADR tracking via Issues and Projects
- `gh-stacked-prs` — stacked PR chains, consolidation, cleanup

**Update `skills/index.md`** to list all new skills and mark `git-gh-workflow`
as deprecated.

## Consequences

### Positive

- The taxonomy gap for MCP servers is closed. Future MCP adoption has a clear
  category, introduction requirements, and authority model.
- The GitHub skills become focused, framework-agnostic, and discoverable
  through `skills/index.md`.
- The Agent Skills upstream dependency is recorded, fixing a known gap in
  `README.md`'s "Upstream References" and unblocking public publication.
- SKILL.md conformance is restored, fixing the three violations recorded in
  `BACKLOG.md`.
- The skills split brings `git-gh-workflow` under the Agent Skills spec's
  500-line recommendation.

### Negative

- The MCP core definition is abstract until a concrete binding is written.
  This is acceptable per `BACKLOG.md`'s own framing: "taxonomy questions are
  cheaper to answer once the workflows that consume tools are settled."
- Splitting `git-gh-workflow` creates a migration cost for consumers that
  reference it by name. The deprecated skill with a redirect mitigates this.
- The four-category taxonomy exists across two ADRs (`ADR-0015` and this one),
  which readers must cross-reference. `ADR-0015` is append-only and cannot be
  amended.

### Neutral

- The skills work (Part 2) is Category 2 per `ADR-0015` — no FS required.
  The MCP taxonomy change (Part 1) is an ADR-level decision and requires no FS
  because it establishes a convention, not code.
- If a future MCP binding requires changing the core definition, the
  `ADR-0024` ordering rule applies: the binding is written first, the
  generalization extracted from it.

## Validation

- **Signal (MCP):** A future reader can determine which category an MCP server
  belongs to by reading this ADR and `ADR-0015` together, without ambiguity.
- **Signal (skills):** `skills/index.md` lists the new sub-skills and marks
  `git-gh-workflow` as deprecated. Each new skill is under 500 lines.
- **Signal (conformance):** `skills-ref validate` (when adopted) passes on all
  framework skills, or the only failures are documented exceptions.
- **Signal (upstream):** `README.md`'s "Upstream References" includes Agent
  Skills with its URL.
- **Review checkpoint:** when the first MCP server is proposed for adoption by
  the framework or a consumer. If the authority model in this ADR is
  insufficient, a superseding ADR must amend it.

## Links

- `ADR-0015`: Tool taxonomy and introduction process (the three-category
  taxonomy this ADR extends to four categories).
- `ADR-0014`: Background task governance (authority model for MCP servers with
  mutation capabilities).
- `ADR-0024`: Platform-neutral core with shipped bindings (the two-layer
  pattern this ADR references for future MCP bindings).
- `BACKLOG.md` §"MCP tooling integration": the deferred entry this ADR closes.
- `BACKLOG.md` §"The Agent Skills format is an unnamed upstream dependency":
  the conformance and recording gap this ADR addresses.
- `BACKLOG.md` §"New skills are deferred with it": the deferred skills this
  ADR's Part 2 begins to address.
- `skills/git-gh-workflow/SKILL.md`: the oversize skill this ADR splits.
- `README.md` §"Upstream References": where the Agent Skills entry will be
  added.
