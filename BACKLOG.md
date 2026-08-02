# Backlog

Work deliberately deferred out of the current bootstrap PR, plus known gaps found
along the way.

**What this file is:** a durable record of things we decided *not* to do now, with
enough context to act on them later without reconstructing the conversation that
deferred them. When a reference to future work is removed from a spec, ADR, or
workflow document to keep that document's scope clean, the reference lands here.

**What this file is not:** normative. Nothing here is a decision, a commitment, or a
constraint. Per `ADR-0030`, decisions live in `docs/decisions/` and current rules live
in the exported surface. This file holds neither — it is internal governance, and an
agent must not treat an entry here as authorization to act.

Entries are removed when the work lands or is explicitly abandoned.

---

## Next

### Implement the GitHub guidance on this repository, and write the runbook

The first real exercise of the workflows defined in this PR. `conventional-agents`
runs on GitHub Issues and Projects, and `integrations/github-issues-projects.md`
describes the substrate binding — but the binding is documentation, not
configuration. Nothing described in it has been provisioned.

**This is two phases, not one.** The Setup Checklist's ninth item — "Webhook endpoint
or Actions workflows subscribed to the §6 events" — writes new files under
`.github/workflows/`, which is in `ADR-0027`'s reserved path set, and `ADR-0015`
requires an approved FS and PLAN before any governance gate is written. A session that
starts at checklist item 1 and works down will hit that gate partway through with
provisioning already done and no authorization to continue. Sequence it deliberately.

**Phase 1 — operator provisioning. No FS required.**

- Work the binding's Setup Checklist against the live repository: the `Issue Type`
  single-select field, the label vocabulary, auto-add, the unattended actor identity
  and its token, branch protection, per-work-item concurrency serialization, and
  `Issue Type` change alerting.
- Switch repository merge settings to rebase-merge per `ADR-0025`. Operator work; not
  reachable from an agent session.
- Write `RB-0001` as you go, per `FS-0023` and `templates/core/runbook.md`. Record the
  procedure **as performed, not as imagined** — the Deviations Observed section is the
  deliverable that matters, because it is what corrects the binding.

**Phase 2 — trigger handlers. Needs its own FS and PLAN.**

- Write the FS from Phase 1's findings, not ahead of them. The binding's §6 already
  documents that scheduled workflows are disabled after 60 days of repository
  inactivity and that delivery is best-effort; what the webhook payloads and Projects
  v2 field APIs actually provide is not knowable until Phase 1 is done.
- Its `interfaces:` will name `.github/workflows/`, so the PLAN cannot self-approve and
  needs an `Approved-By:` trailer per `ADR-0026`.

**Why this order:** Phase 1 is the first end-to-end test of the work item lifecycle
(`FS-0018`) and produces the runbook that consuming projects copy. Phase 2 is
implementation informed by it. Writing Phase 2's spec first would be specifying against
an imagined substrate, which is the failure the runbook type exists to prevent.

### Consumers are pinned to a pre-rename version and a vendor path that no longer matches

Verified against the Tais-Den org on 2026-08-01, by inspection only — nothing in those
repositories was modified.

| Repo | Submodule URL | Vendor path | Pinned |
| --- | --- | --- | --- |
| `agentic-bootstrap-constitution` | `agentic-dev-kit` | `vendor/agent-dev-kit` | 2026-02-08 |
| `deploy-ducky` | `agentic-dev-kit` | `vendor/agentic-dev-kit` | 2026-02-16 (v1.2.0) |
| `feral-fleet` | `agentic-dev-kit` | `vendor/agent-dev-kit` | 2026-02-16 (v1.2.0) |
| `pack-protocol` | `agentic-dev-kit` | `vendor/agentic-dev-kit` | 2026-02-16 (v1.2.0) |
| `tais-den-conventions` | `conventional-agents` | `vendor/conventional-agents` | current |

Four consumers point at the pre-`v2.0.0` repository name and at two vendor paths,
neither of which is the `vendor/conventional-agents` every document here specifies.
GitHub's rename redirect is the only reason their submodules still resolve. They are
running against a three-role contract with no session modes, work items, or
multi-model workflow.

**The exported surface held, which is the useful finding.** All eight framework paths
`deploy-ducky` references still exist on trunk. Migration is mechanical — rename the
path, bump the pointer, update references — plus absorbing content growth. This is
evidence the exported/internal split works, not evidence against it.

**Two things this exposes:**

- **No consumer registry here.** The rename broke four consumers and no gate could
  catch it: the consumer-impact check reads only this repository's `CHANGELOG.md`. A
  registry exists as `pack-protocol/config/repos.yml` — outside the framework, and
  itself still naming `agentic-dev-kit`.
- **No upgrade path.** `INTEGRATION.md`'s Migration Guides cover "no standards →
  framework" and "copy-in → submodule". Nothing covers version-to-version, and there
  is no stated support or breaking-change policy.

`agentic-bootstrap-constitution` compounds it: a GitHub *template* repository pinned to
February, so every repo generated from it inherits the stale integration. Fixing it is
the only one of the five that prevents future drift rather than repairing past drift.

---

## Public release

The repository is private and consumed by a handful of private repositories. Making it
public is a distinct project from anything above, and it is sequenced **after** the
GitHub provisioning work — the automations are what turn this list into tracked work
items.

Everything below was verified against the repository on 2026-07-29, not inferred.
Tiers are ordered by whether they block publication, not by effort.

### Tier 0 — Legal and identity

**`LICENSE` names the wrong copyright holder.** It reads `Copyright (c) 2026 Anthropic`.
This is not Anthropic's project. The MIT text itself is fine; the holder line is a
scaffolding artifact that nobody has read since it was generated. Publishing with
another party's copyright notice is the single highest-consequence item in this file.

**`config/project.yml` ships one organization's private infrastructure.** It hardcodes
the Tais-Den GitHub Project number, project ID, board URL, and every field and option
ID:

```text
project.id: "PVT_kwDOD3aO3M4BQcYf"
project.url: "https://github.com/orgs/Tais-Den/projects/2"
```

These are not credentials, but they are deployment config for one org sitting in a
framework that consumers vendor — and they contradict `ADR-0024`'s platform-neutral
core directly. A consumer vendoring the framework gets a pointer to a board they cannot
read. Decide whether `config/` is exported at all; if it is, it needs to ship as an
example with the real values held outside the repository.

**Decide the disposition of personal and organizational identifiers.** Present in
tracked files: `Tais-Den` (28 files), `Hermes` (23), `ajoeofalltrades` (14),
`taisden@tais-den.dev` (12). **Not all of these should be removed** — `owner:` fields
and `approved_by:` records are legitimate attribution, and they are already in the git
history that publication exposes regardless. What is needed is a deliberate decision,
made once and written down, covering: the maintainer's email in commit trailers, the
`Hermes` agent's name if that is proprietary, and whether `tais-den-conventions` stays
as `INTEGRATION.md` Pattern 4's worked example or is replaced with a neutral one.

A secrets scan for GitHub tokens, private keys, and AWS keys found nothing.

### Tier 1 — The documented integration path does not work

**`packs/` has never existed.** `INTEGRATION.md` instructs consumers to run:

```text
cp vendor/conventional-agents/packs/agents-md/AGENTS.full.example.md ./AGENTS.md
cp vendor/conventional-agents/packs/claude/CLAUDE.full.example.md ./CLAUDE.md
cp vendor/conventional-agents/packs/aider/CONVENTIONS.md ./CONVENTIONS.md
```

Four references across the Quick Start, Pattern 2, and the Aider section.
`docs/ARC42.md` §5.1 lists `packs/` as "(planned)" and has since the beginning. This is
the copy-in path — the one recommended for tools that only read root files — and it is
the first thing a new public user runs. Either build `packs/` or rewrite those
instructions to point at what exists.

**`<REPO_URL>` is still a placeholder.** `INTEGRATION.md` Quick Start step 1 says
"replace with the actual repository URL when known". On a public repo it is known, and
the submodule command is the first thing anyone executes.

### Tier 2 — The threat model changes when the repository is public

**Recorded approval is forgeable by anyone who can open a pull request.** This is the
most consequential finding, and it is not a bug — it is a design that assumed trusted
committers.

`scripts/check-status.sh` gates reserved paths (`scripts/`, `.github/workflows/`,
`package.json`, `docs/decisions/`, `guidelines/ROLE_CONTRACT.md`) behind `ADR-0026`
recorded approval. It requires the most recent commit touching a PLAN to carry an
`Approved-By:` trailer matching the PLAN's `approved_by:` front matter, authored by
someone other than the commit author. **In a fork pull request, every one of those
inputs is contributor-controlled**: the front matter is in the diff, the trailer is in
their commit, and the author-differs constraint is satisfied by naming any maintainer
they like. An outside contributor can open a PR whose PLAN self-certifies as
human-approved for `.github/workflows/`.

This is consistent with the framework's stated "detection over prevention" stance, and
the honest fix is not to make the check unforgeable — it cannot be. What is required
before publication:

- `CODEOWNERS` plus branch protection as the actual control, with the check demoted to
  advisory on fork PRs.
- A statement in `integrations/github-issues-projects.md` §7 ("What This Binding Does
  Not Guarantee") saying so plainly, in the same voice as the existing three
  not-technically-enforceable capabilities.
- Review of whether `ADR-0026` needs a public-repository amendment or a successor.

**`ADR-0011` and `ADR-0021` assume a private organization.** The multi-identity model
and the cron actor identity both rest on the set of people who can push being known.
`FS-0018`'s autonomous gate keys on the agent's `user.email` matching an unattended
alias — trivially set by anyone in a fork. Same class as the above; needs the same
review pass.

### Tier 3 — Records that contradict the repository

**`FS-0022` §1c — resolved.** Referenced-path resolution is implemented as
`check-status.sh` rule 8 and found four broken references, all in `skills/`, all
corrected. Two scoping decisions the spec left open are recorded in `scripts/README.md`
and `PLAN-0022` §5a: the check covers current-state documents only, and only tokens
containing a directory separator. The residue is `REF_EXEMPT`, three entries for paths
the framework tells a consumer to create in *their* repo — syntactically identical to
references to ours, so they cannot be distinguished automatically.

**`docs/ARC42.md` is stale** — already recorded below, but publication raises its
priority. `status: Draft`, §9's ADR list stops at `ADR-0009`, and it references two
guidelines that do not exist.

**`ADR-0003`** mirrors arc42 as a submodule; that submodule was removed in v2.1.0.
`docs/ARC42.md` records the removal, but the ADR's status does not.

**Approved-but-never-implemented work is publicly visible.** `FS-0002`/`PLAN-0005` are
**resolved** — deprecated on 2026-07-29 with the verification recorded in `FS-0002`'s
Status section. `FS-0004`/`PLAN-0002` remain `draft` with an open PR (#60) and still
need a disposition.

**Both known instances are now closed, and that is the reason to build the check, not
a reason to skip it.** `FS-0002` sat `approved` for five months while a different set
of skills was built and shipped past it; `FS-0022` §1c sat `approved` with a success
criterion nobody had written. Neither was found by a gate — both were found by reading,
which does not scale and did not happen for months.

A status-versus-reality check — does an `approved` or `implemented` document's declared
output actually exist? — would have caught both at the commit that created the gap.
`FS-0022` §1c is the shape to copy: it reads `interfaces:` and asserts the paths
resolve. The harder half is asserting that a *behaviour* a spec describes exists, which
is not mechanically checkable; scoping it to declared paths would have caught `FS-0002`
(ten named skill directories, none present) and is worth building on its own.

### Tier 4 — Community health and contribution

- **No `CODE_OF_CONDUCT.md`.**
- **No `SECURITY.md`.** For a framework whose subject is constraining what autonomous
  agents may do, an absent security policy is conspicuous. It should name the Tier 2
  boundary explicitly: the gates are detection, not prevention.
- **No issue or pull request templates.** `.github/` contains only `workflows/`.
  `FS-0018` defines a three-axis work-item schema, and issue templates are how `Type`
  gets set correctly at creation rather than corrected afterward. This is the natural
  output of the GitHub provisioning work.

  **Settle `FS-0004` here rather than separately.** It is `draft` on trunk and defines
  per-role PR body templates for Roles 0, 1, 2, 3 and 5, commit-body guidance with a
  trivial-change exception, and a PR update comment section. Its problem statement
  still holds: `workflows/git-and-gh-conventions.md` has exactly one
  `#### PR body template (agents)` and one `### Commit bodies (agents)` — the
  one-size template the spec exists to replace. Nothing was implemented.

  Doing it *with* the PR-template work rather than before it avoids writing two
  answers to one question: GitHub-native `PULL_REQUEST_TEMPLATE` is a delivery
  mechanism `FS-0004` predates and does not consider.

  Three things to fix in the spec when it is picked up, none fatal:

  - `related_adrs` cites `ADR-0011` (multi-identity) as operative. `ADR-0018` and
    `ADR-0029` superseded it as the working convention; `ADR-0011` is now the
    forward-compatibility path.
  - `ADR-0029`'s `Agent-Attribution:` trailer already carries `role=` on every commit,
    so role is machine-readable without a template. The templates should complement
    that rather than restate it.
  - The five templates predate the meta-modes. `FS-0019` and `FS-0021` shipped
    `templates/collaboration/consensus-synthesis.md` and `review-board-findings.md`,
    which are PR-adjacent artifacts for `consensus` and `review-board`. A PR opened
    from either has a shape none of the five covers.
- **`CONTRIBUTING.md` is written for the internal loop.** It needs an outside-
  contributor path: what a first-time contributor may change without an FS, how the
  role model applies to someone who is not running an agent session, and what happens
  to their PR.
- Repository description, topics, and social preview are unset.

### Tier 5 — Release mechanics

- **Version and tags disagree.** `package.json` is `2.1.0`; the only tag in the
  repository is `v2.0.0`; `CHANGELOG.md` `[Unreleased]` holds the whole of this PR.
  Cut a release per `workflows/versioning-and-releases.md` before or with publication.
- **Open PRs and issues** — PRs #62–#64 and issues #28–#49 are now closed. PR #60
  (`FS-0004`/`PLAN-0002`, role-aware commentary policy) is still open and still needs a
  disposition before publication.
- **The exported surface is enumerated five times** — recorded below; a public API
  surface maintained by hand in five places will diverge, and now with witnesses.
- **The Agent Skills format is an unnamed upstream dependency** — recorded below.
  Publishing a framework that implements someone else's open standard without citing it
  is both a correctness problem and a courtesy one.

---

## Deferred concepts

### Domain concept

A first-class `DOMAIN-XXXX` document declaring a domain's required skills, default
role, default personality, description, related domains, and context pointers — so
that switching between areas of work (advocacy, infrastructure, legal, personal
history, software) stops being a manual reload of skills, role, and tone.

**Material:** `docs/decisions/ADR-0017-domain-concept.md`,
`docs/specifications/FS-0016-domain-document-type.md`, `docs/domains/README.md`, and
`templates/core/domain.md`, all on branch `docs/domain-concept-adr-fs` (PR #64).

**Why deferred:** genuinely orthogonal to the SDLC workflows this PR defines. It
concerns agent profile and skill bundling, not how governed work moves. Including it
would widen an already large PR without improving it.

**What closing it requires:** renumber — its ADR-0017 and FS-0016 both collide with
documents already on trunk. Re-enter as `proposed`/`draft`; the branch versions carry
statuses they never earned through merge. Reconcile against the layer table it
proposes, which references `ADR-0016` for render mode — an ID that means something
else on trunk.

### MCP tooling integration

Model Context Protocol servers as a governed tool category: how an MCP server is
introduced, what authority it carries, how its capabilities are declared, and which
role is accountable for it.

**Why deferred:** `ADR-0015` establishes a three-category tool taxonomy (governance
gates, productivity skills, platform capabilities) and MCP servers do not cleanly
occupy any of them. Slotting them in is a taxonomy question, and taxonomy questions
are cheaper to answer once the workflows that consume tools are settled.

**What closing it requires:** decide whether MCP servers are a fourth category or a
subtype of platform capability; define introduction and modification requirements
matching `ADR-0015`'s existing structure; determine whether an MCP server's authority
is bounded by the session's role, by `ADR-0014`'s background-task rules, or by
something new.

Miscategorisation has a concrete cost, so the answer should not be "nearest fit": a
tool filed as Category 2 escapes the approved-FS requirement Category 1 imposes.
Whatever the answer, it needs a new ADR — `ADR-0015` is accepted and append-only, so
the taxonomy cannot be widened by editing it.

### `render_contributor_prompt.py` and a Python toolchain

Carried by the now-closed PRs #62–#64. Real code with a real bats suite, never
extracted. Adopting it means deciding its category under `ADR-0015` and introducing a
Python toolchain to a repository that has none — `templates/python/` ships Python
guidance, but nothing here executes Python. Evaluate on its own merits rather than
inheriting it because it happened to ride along with the orchestration pilot.

### Model provider guidance

A spec covering how models are selected for collaboration rounds, how
transports differ, and how cost and latency are managed across providers.

**Why deferred — and why it may never be needed.** Most of what this was
scoped to cover has either landed elsewhere or was deliberately ruled out
of scope:

- The Mixture-of-Agents mapping is in `FS-0019` §"Relationship to Mixture
  of Agents", including the correction that an MoA aggregator is the
  synthesizing primary and never the gate.
- Transport enumeration was rejected on purpose. `render_mode` is a
  consumer-named value, because attribution and output contract are
  identical across transports and that is what makes outputs comparable.
- Model-to-role assignment is consumer configuration, the same as
  participant selection in `FS-0019` and seat composition in `FS-0021`.

What remains is provider-selection heuristics — which models suit which
role stances — and there is no evidence base for that. The one run on
record used a fixed set chosen by the operator. Writing guidance from a
single unmeasured run would be the imagined abstraction `ADR-0024` exists
to prevent.

**What closing it requires:** enough runs across varied model sets to say
something falsifiable about selection. If that evidence never accumulates,
the correct outcome is to close this entry without writing the spec, not
to write it anyway.

### Notion substrate binding

`integrations/notion.md` — the second binding under `ADR-0024`.

**Why deferred:** the GitHub binding must be exercised against a live repository first
(see "Next after this PR"). Writing a second binding before the first is proven would
repeat the mistake `ADR-0024` exists to prevent.

**Why it matters:** most Tais-Den projects consuming this framework use Notion for
knowledge base and project tracking, not GitHub Projects. This binding is required,
not hypothetical, and its arrival triggers `ADR-0024`'s review checkpoint: if
extracting it forces a change to the six core capabilities, the core was
under-generalized.

**Risk area, now resolved at the framework layer:** capability 6 was "a trigger source
capable of invoking an agent on work-item events or on a schedule", and Notion's event
surface is shaped differently from GitHub's webhooks. `ADR-0028` amended the capability
to **enumerability** — a substrate must be readable on demand; event notification is
optional and never the sole trigger. Notion is plainly enumerable, so the risk is now
that its *scheduler* is reliable enough to carry correctness, not that its events are
rich enough. That remains untested.

---

## Known gaps

### No ADR governs the exported-surface / internal-governance split

`README.md` and `AGENTS.md` both publish the split as a two-column table, and
`ADR-0009`'s index entry claimed to establish it — but `ADR-0009` is "Feature
Specification Template Selection" and the split has no decision record at all.
Verified by grepping `docs/decisions/` for "exported surface": only `ADR-0016`,
`ADR-0017`, and ADRs written in the current session mention it.

`ADR-0030` depends on this split to assign document families their jobs, and
currently cites `README.md`/`AGENTS.md` as the only sources.

### Nothing detects that an open PR has become an empty diff

`PR #60` (revise `FS-0004`/`PLAN-0002`) sat open from 2026-06-08 until 2026-08-01
containing **no delta**. Both its files were byte-identical to trunk: the revision had
landed through other commits during the `v2.1.0` era — `3bec778`, `24da040`, and
`a5facd2` (#61) — while the PR carrying the same change stayed open.

Nobody noticed because nothing looks. GitHub reported `mergeable: UNKNOWN`, having no
reason to compute a merge for an empty diff, and that is the only signal there was.

Cheap to detect: for each open PR, compare its head tree against the merge base for the
files it claims to touch. An empty diff means the work landed elsewhere and the PR is
bookkeeping. Related to the entry below — both are cases where the repository is in a
state no gate has an opinion about.

### Nothing detects "merged but never marked implemented"

`FS-0018`–`FS-0023` and `PLAN-0018`–`PLAN-0023` merged on 2026-07-29 and sat at
`approved` until the `v2.1.0` release was cut three days later.
`workflows/document-lifecycle.md` places the transition in the completing PR;
`PLAN-0022` §5 step 9 said so explicitly. It did not happen, and `check:status`
stayed green throughout — rule 1 only fires on documents already marked
`implemented`, so an unmarked one is invisible to it.

The detectable signal is a document whose governing PR has merged while its status is
still `approved`. That needs the merge state, so it belongs with
`check-current-state.sh` in CI rather than in `check-status.sh`.

Fifth fail-open in the same family: the gate reports success because the condition it
tests never becomes true, not because the repository is correct.

### `ADR-0027`'s reserved-path list is static and nothing detects staleness

Raised in review of PR #71. `RESERVED_PATHS` in `scripts/check-status.sh` names
`docs/decisions/`, `guidelines/ROLE_CONTRACT.md`, `scripts/`, `.github/workflows/`,
and `package.json` — the paths a PLAN may never self-approve. `ADR-0027` acknowledges
the list will need extending as enforcement machinery grows, but nothing detects when
it has fallen behind.

The failure is quiet and in the permissive direction: new CI or gate machinery added
outside those paths becomes agent-self-approvable, and the only signal is that nobody
noticed. Same shape as the exported-surface duplication below, and as the two checks
that shipped dead in this PR — a hand-maintained list with no drift detection.

Worth pairing with that entry: both are "a list the gates depend on, maintained by
hand, with no gate on the list itself."

### The exported surface is enumerated in five places with no source of truth

Distinct from the entry above, which is about the split lacking a *decision record*.
This is about the *list* being restated five times:

| Location | Form |
| --- | --- |
| `README.md` | "Exported surface" table |
| `AGENTS.md` | Two-column surface table |
| `docs/specifications/README.md` | Prose list in the consumer-impact rule |
| `scripts/check-status.sh` | `EXPORTED_PREFIXES` array |
| `package.json` + `.github/workflows/lint-docs.yml` | Lint globs and CI path triggers |

Adding `runbooks/` in `FS-0023` required editing all five. Four of five would have
produced a directory that is exported for anyone reading `README.md` and invisible to
the consumer-impact gate — a spec could then change it without ever triggering the
CHANGELOG requirement. `test/FS-0023/runbook-convention.bats` asserts the five agree,
which detects the drift but does not remove the ability to create it.

**What closing it requires:** one source of truth the other four derive from or are
checked against. Because that changes `scripts/check-status.sh` and `package.json` —
both reserved paths — it needs its own FS and PLAN. It is the same class of defect as
the ADR index that carried eleven fabricated titles: a list maintained by hand in more
than one place will diverge, and this repository has already paid for that lesson once.

### The Agent Skills format is an unnamed upstream dependency

`SKILL.md` is not a `conventional-agents` invention. It is **Agent Skills**, an open
standard at [agentskills.io](https://agentskills.io/specification) — originally
developed by Anthropic, released as an open standard, and implemented by roughly
forty-five agent products including Cursor, GitHub Copilot, VS Code, Gemini CLI,
OpenAI Codex, Goose, OpenHands and JetBrains Junie. It has a published specification,
a GitHub organisation (`agentskills/agentskills`), and a conformance validator
(`skills-ref validate ./my-skill`).

The framework adopted the format and never recorded the dependency. `README.md`'s
"Upstream References" documents four adopted standards — Conventional Commits, Keep a
Changelog, MADR, arc42 — each with a URL and a pointer to where the framework's subset
lives. Agent Skills is the fifth and is absent. Grepping the repository for any
reference to the format's origin returns nothing.

**`ADR-0001`'s premise has been overtaken by events.** Its Context reads: *"Claude Code
provides native support for 'skills,' but most other tools do not have a formal skills
system."* That was true when written. It is now false, and the change vindicates the
decision while invalidating its reasoning — the framework chose `SKILL.md` to avoid
Claude-only lock-in, and the format became the cross-vendor standard.

**Conformance is broken in three ways**, measured against the published spec:

| Issue | Detail |
| --- | --- |
| Non-spec top-level fields | All six skills carry `version`, `author` and `platforms`. None are spec fields; the spec's own example places `author` and `version` **under `metadata:`** |
| `metadata` typing violated | The spec defines `metadata` as *"a map from string keys to string values"*. Ours is `metadata.hermes.tags: [array]` — nested maps containing arrays |
| Oversize skill | `skills/git-gh-workflow/SKILL.md` is 558 lines, over the spec's *"keep your main SKILL.md under 500 lines"* and over `ADR-0001`'s ~400-line signal |

Clean: every skill's `name` matches its parent directory, which the spec requires.

Unused: the spec's optional `scripts/`, `references/` and `assets/` directories. That
matters for the oversize skill — the spec's own remedy is moving detail into
`references/`, not splitting the skill.

**What closing it requires**, in four parts, none belonging to the current PR:

1. Add Agent Skills to `README.md`'s Upstream References with its URL, matching the
   treatment of the other four.
2. A **new ADR** — `ADR-0001` is `accepted` and append-only — recording that the
   framework *profiles* an external standard rather than defining one, that ADR-0001's
   premise was overtaken, and which rules are the framework's own profile (the minimum
   content checklist, the no-duplicate-gates rule, standalone-usefulness, the line
   signal) as distinct from the spec's requirements.
3. Fix conformance: move `version`/`author`/`platforms` under `metadata` as string
   values, flatten the `hermes` nesting, and relocate `git-gh-workflow`'s overflow into
   `references/`.
4. Adopt `skills-ref validate` as a gate. It is Category 1 under `ADR-0015`, so it
   needs an approved FS and PLAN before it is written — and it is the mechanical check
   that would have caught every item above.

**`skills/example-skill/SKILL.md` is empty, and should stay that way or be removed.**
Filling it as a format reference was considered and rejected: the specification is the
reference, `skills-ref validate` is the conformance check, and a hand-written local
example would fork a standard the framework does not own and freeze whatever it
understood the format to be on the day it was written.

**New skills are deferred with it.** Several were proposed — `adr-authoring`,
`spec-authoring`, `work-item-lifecycle`, `bootstrap-merge-authoring`,
`platform-neutral-authoring`, `mcp-tool-governance`. Most would teach procedures from
ADRs accepted in this PR and never yet performed, which is the imagined-abstraction
failure `ADR-0024` exists to prevent. `adr-authoring` and `spec-authoring` are the two
worth revisiting first: they teach the two document types this repository has watched
get mis-authored repeatedly, including by its own agents.

**The pattern worth naming.** The framework has now vendored or adopted five upstream
standards and lost track of one. Its second-highest quality goal is Tool Neutrality
(`docs/ARC42.md` §1.2), and that goal is better served by tracking upstreams than by
inventing — but only if the tracking is recorded. An adopted standard with no reference
entry is the same class of gap as a rule with no ADR.

### `docs/ARC42.md` is stale

- `status: Draft`, `last_updated: 2026-07-12`.
- §9 duplicates its "Accepted ADRs" block verbatim and stops at ADR-0009 — every ADR
  from 0010 onward is missing, including `ADR-0012`'s non-overridable gates.
- References `guidelines/context-engineering.md` and
  `guidelines/multi-agent-coordination.md` (§8.3, §8.4). Neither file exists.
- §5.1 lists `packs/` as a planned building block. It has never been built.
  `integrations/` was also phantom until this PR created it.

### Lint coverage is enumerated, not discovered

`npm run lint:docs` and `.github/workflows/lint-docs.yml` both list directories
explicitly. Anything outside `docs/decisions`, `docs/specifications`,
`docs/change-plans`, and `workflows/` is unlinted — currently `integrations/`,
`templates/`, `guidelines/`, `skills/`, and root-level documents including this file.

Related: `scripts/check-status.sh` has no ADR coverage at all, which is why the ADR
index drifted to eleven wrong titles and nine wrong statuses undetected. Both are
tracked for the PLAN work rather than here, but they share a root cause worth naming
once: coverage is opt-in by enumeration, so new surfaces are unguarded by default.

---

## Cleanup

### `.mailmap` for author grouping

`ADR-0029` moves the model into `user.name`, so `git shortlog` without `-e` groups by
model and fragments across model versions (`Opus 5` and `Opus 4.8` count separately).
A `.mailmap` mapping model names to actor addresses restores actor-level grouping.
Named in ADR-0029 as the first remedy; not yet needed.
