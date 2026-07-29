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

## Next after this PR

### Implement the GitHub guidance on this repository, and write the runbook

The first real exercise of the workflows defined in this PR. `conventional-agents`
runs on GitHub Issues and Projects, and `integrations/github-issues-projects.md`
describes the substrate binding — but the binding is documentation, not
configuration. Nothing described in it has been provisioned.

**What closing it requires:**

- Work through the binding's Setup Checklist against the live repository: the
  `Issue Type` single-select field, the label vocabulary, auto-add, the unattended
  actor identity and its token, branch protection, trigger handlers, per-work-item
  concurrency serialization, and `Issue Type` change alerting.
- Write a runbook documenting the process as performed, not as imagined. Deviations
  between the binding and what GitHub actually permits are findings, and belong back
  in the binding.
- Repository merge settings must be switched to rebase-merge per `ADR-0025`. This is
  operator work; it is not reachable from an agent session.

**Why this order:** it is the first end-to-end test of the work item lifecycle
(`FS-0018`), and it produces the runbook that consuming projects copy. It also
exercises the binding as a real conformance checklist rather than a hypothetical one.

---

## Enforcement obligations from this PR

**Distinct from everything else in this file.** These are not deferred — they are
decisions made in this PR whose enforcement was not built alongside them. They belong
in this PR's PLANs, and this section exists so a PLAN author can assemble the list
without reading twelve ADRs to find their Consequences sections.

Remove each entry as its PLAN absorbs it.

**Governed by `FS-0022`.** `ADR-0015` requires an approved FS and PLAN before any
governance gate is written or modified, and `ADR-0027` reserves `scripts/`,
`.github/workflows/`, and `package.json` as always-human-approval paths — so this work
could not be folded into PLAN-0018 or PLAN-0019 as incidental scope. `FS-0022` is that
spec, and it extends `FS-0013` and `FS-0005` rather than starting fresh: both are
`implemented`, and both describe purposes broader than what they actually cover.

The entries below are retained as the audit that produced `FS-0022`. They are
superseded by its Behavior section and should be removed once PLAN-0022 exists.

### Gate coverage — `scripts/check-status.sh`

The script currently validates FS↔PLAN status pairing and README index sync for specs
and plans. It contains zero references to `docs/decisions/`, `touches:`,
`integrations/`, or `templates/`.

| Obligation | Source | Note |
| --- | --- | --- |
| ADR index sync — titles and statuses against files | — | Root cause of the eleven fabricated titles and nine wrong statuses this PR corrected. Nothing would catch a recurrence. |
| `touches:` containment against the governing FS's `interfaces:` | `ADR-0027` | Plus the reserved-path set. Without it, PLAN self-approval is unenforced. |
| An ADR changing a rule must touch a current-state document | `ADR-0030` rule 3 | Catchable case: an ADR whose Links name a current-state document the same change did not modify. |

### Lint coverage

`npm run lint:docs` and `.github/workflows/lint-docs.yml` both enumerate four globs.
Uncovered directories containing markdown: `guidelines/` (10), `skills/` (8),
`templates/` (11), `integrations/` (1), `roles/` (1), and the repository root (16,
including `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `BACKLOG.md`).

`docs/orchestration/multi-model-pilot-001/` is deliberately exempt and carries its own
`default: false` config; expanding coverage must not override it.

### Test execution

`bats` is invoked nowhere — not in `package.json`, not in any workflow. Five suites
exist and none run: `test/FS-0001`, `FS-0016`, `FS-0017`, `FS-0018`, `FS-0019`.

Every "validation" claim in this PR's commits rests on assertions verified by hand
because the suite could not be executed. `ROLE_CONTRACT`'s pre-commit testing gate
requires running the suite before committing code changes, and there is no suite to
run.

`test/FS-0021/review-board.bats` is named in FS-0021's rollout and is not written —
correctly, since tests follow FS approval.

### Convention-only rules, by design

Recorded so a PLAN author does not mistake these for oversights. Each is enforced by
detection or discipline, and the deciding document says so:

| Rule | Source | Why not enforced |
| --- | --- | --- |
| Parallel primaries must not touch the same artifact | `ADR-0013` | Relies on discipline; no tooling proposed |
| Primary/contributor designation | `ADR-0013` | Undeclared sessions can both act as primary |
| Work item Type is human-mutable only | `ADR-0019` | No substrate offers per-field ACLs (`ADR-0024`) |
| Parked-state suppression | `ADR-0020` | No substrate offers per-label permissions |
| Bootstrap merge must be declared in advance | `ADR-0026` | Nothing prevents a PR description claiming it after the fact |

### Documentation reconciliation

Conventions currently stated in more than one place, which `ADR-0030` rule 1 forbids
going forward but does not retroactively fix.

`scripts/README.md` — required by `ADR-0015` and absent — is no longer listed here. It
is now `FS-0022` §5, since that spec adds checks whose documentation `ADR-0015`
requires.

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

### Close PRs #62, #63, #64

Cumulative branches (#62 → #63 → #64) carrying the multi-model orchestration pilot.
Their useful content is extracted in the current PR — into `FS-0019`'s amendments and
`FS-0021` — so the branches can be closed unmerged once that work lands. Closing them
is a GitHub action, not a change to this repository.

**Not extracted, still undecided:** `scripts/render_contributor_prompt.py` with its
bats suite, and the `pyproject.toml` those branches add. Real code with real tests,
but adopting it means deciding its category under `ADR-0015` and introducing a Python
toolchain to a repository that currently has none. Evaluate on its own merits rather
than inheriting it with the rest.

### Stale work-tracking issues

GitHub issues #28–#49 are backfilled FS/PLAN tracking issues, all OPEN while their
documents are `implemented` on trunk. Several still name the pre-2.0 project
`agentic-dev-kit`. They contradict the framework's own status-consistency principle
and should be closed or reconciled.

### `.mailmap` for author grouping

`ADR-0029` moves the model into `user.name`, so `git shortlog` without `-e` groups by
model and fragments across model versions (`Opus 5` and `Opus 4.8` count separately).
A `.mailmap` mapping model names to actor addresses restores actor-level grouping.
Named in ADR-0029 as the first remedy; not yet needed.
