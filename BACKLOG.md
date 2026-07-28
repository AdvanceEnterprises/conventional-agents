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

**These require their own FS before implementation.** `ADR-0015` — accepted — requires
an approved FS and PLAN before any governance gate is written or modified, and
`ADR-0027` reserves `scripts/`, `.github/workflows/`, and `package.json` as
always-human-approval paths. The gate work below cannot be folded into PLAN-0018 or
PLAN-0019 as incidental scope.

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
going forward but does not retroactively fix. Also `scripts/README.md`, required by
`ADR-0015` — now accepted — and absent.

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

**Known risk area:** capability 6 (trigger source). Notion's event surface is shaped
differently from GitHub's webhooks. Under level-triggered semantics this should cost
latency rather than correctness — the substrate needs to be *enumerable*, not
*event-emitting* — but that expectation is untested.

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

### `docs/ARC42.md` is stale

- `status: Draft`, `last_updated: 2026-07-12`.
- §9 duplicates its "Accepted ADRs" block verbatim and stops at ADR-0009 — every ADR
  from 0010 onward is missing, including `ADR-0012`'s non-overridable gates.
- References `guidelines/context-engineering.md` and
  `guidelines/multi-agent-coordination.md` (§8.3, §8.4). Neither file exists.
- §5.1 lists `packs/` as a planned building block. It has never been built.
  `integrations/` was also phantom until this PR created it.

### `scripts/README.md` does not exist

`ADR-0015` requires every governance gate to carry a description in
`scripts/README.md` explaining its purpose, when it runs, and what a failure means.
`scripts/` contains `check-status.sh` and no README. Now binding, since ADR-0015 moved
to `accepted`.

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
