---
type: adr
id: ADR-0038
status: proposed
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
created: 2026-09-05
updated: 2026-09-05
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
- Use this document only to constrain or explain behavior, not to generate code.
-->

# ADR-0038: Agent Skills as a profiled upstream standard

## Status

- Proposed

## Context and Problem Statement

`ADR-0001` chose `SKILL.md` as the framework's skill format, for cross-tool
portability, on this premise: *"Claude Code provides native support for 'skills,'
but most other tools do not have a formal skills system."*

That premise is now false. `SKILL.md` is **Agent Skills**, an open standard
published at [agentskills.io](https://agentskills.io/specification) — originally
developed by Anthropic, released as an open standard, and implemented by roughly
forty-five agent products including Cursor, GitHub Copilot, VS Code, Gemini CLI,
OpenAI Codex, Goose, and JetBrains Junie. It is also implemented by the two
dominant self-hosted agent runtimes of 2026 — **Hermes Agent**
(`NousResearch/hermes-agent`, Python), which authors the majority of this
repository's commits, and **OpenClaw** (`openclaw.ai`, formerly Moltbot,
TypeScript, governed by the non-profit OpenClaw Foundation) — each of which adds
its own extension namespace on top of the base spec. The format the framework
chose to avoid single-vendor lock-in became the cross-vendor standard. The
decision was vindicated; its reasoning was overtaken.

### The evidence that this is not hypothetical

Three consequences have accumulated, each already recorded in `BACKLOG.md`:

- **The upstream is unrecorded.** `README.md`'s "Upstream References" section
  lists four adopted standards — Conventional Commits, Keep a Changelog, MADR,
  arc42 — each with a URL and a pointer to where the framework's subset lives.
  Agent Skills is the fifth adopted standard and is absent. Grepping the
  repository for any reference to the format's origin returns nothing.

- **The framework's own skills do not conform to the base spec.** All six shipped
  skills carry `version`, `author`, and `platforms` as top-level frontmatter
  keys; the spec's own example places `author` and `version` **under
  `metadata:`**. All six carry `metadata.hermes.tags: [array]` and
  `metadata.hermes.related_skills: [array]` — nested maps containing arrays,
  where the spec defines `metadata` as *"a map from string keys to string
  values."* `skills/git-gh-workflow/SKILL.md` also lists `related_skills:`
  entries `github-auth` and `github-pr-workflow`, which exist only in Hermes
  Agent's shipped skill set, not this repository.

- **The framework's skills are written in one runtime's dialect, and it is not
  the only dialect.** The `metadata.hermes.*` keys the six skills carry are
  Hermes Agent's documented extension namespace. OpenClaw defines a parallel and
  incompatible one — `metadata.openclaw.skillKey`, `metadata.openclaw.primaryEnv`
  — and a single `SKILL.md` can serve at most one. `claude plugin validate`
  warns on all six framework skills; the claude.ai Skills API accepts only
  `name`, `description`, `license`, `compatibility`, `metadata`, and
  `allowed-tools`. A skill authored against the Hermes profile is portable to
  neither OpenClaw, nor Claude Code, nor the Skills API — the exact property
  `ADR-0001` chose the format to guarantee. Two independent runtimes
  independently reaching for `metadata.<runtime>.*` is the signal that this is a
  category of divergence, not a Hermes quirk.

### What is not the problem

`ADR-0001`'s **decision** is correct and stays: `SKILL.md` remains the format,
skills remain standalone-useful, skills do not duplicate the universal gate list.
This ADR does not reopen any of that.

What is missing is a record of **provenance and profile**. The framework has been
authoring an unrecorded profile of an external standard and calling it "the
format." `ADR-0001` is `accepted` and append-only, so its premise cannot be
corrected in place. `ADR-0030` requires that the rule a document carries live in
a current-state document; there is no current-state document naming the skill
format's origin or the framework's own authoring rules — those rules are prose
buried in an accepted ADR.

The question this ADR answers: **does the framework define a skill format, or
profile an external one — and if it profiles, which rules are the framework's own
and how do runtime-specific dialects stay out of portable source?**

## Decision Drivers

- **`ADR-0001` is append-only.** Its premise cannot be edited. A successor record
  is the only mechanism.
- **`ADR-0030` separates decision records from current-state documents.** The
  framework's authoring rules are a current-state concern and currently have no
  current-state home.
- **Public release.** Publishing a framework that implements someone else's open
  standard without citing it is both a correctness problem and a discourtesy.
  `README.md` already treats four other upstreams with a URL and a subset
  pointer; Agent Skills is conspicuously the exception.
- **The framework runs on at least four runtimes** — Hermes Agent, OpenClaw,
  Claude Code, an OpenAI Codex-family agent — and each has its own
  skill-discovery expectations and its own (or no) extension namespace. A source
  skill baked to one runtime's dialect defeats the portability `ADR-0001` chose
  the format for.
- **Miscategorising the fix has a cost (`ADR-0015`).** Editing skills is
  Category 2 — no FS. Adopting a conformance validator as a CI gate is
  Category 1 — an approved FS and PLAN are required first. The two must not be
  bundled.

## Considered Options

### Option A — Record the upstream in `README.md`, change nothing else

Add the Agent Skills row to "Upstream References" and stop.

Cheapest, and it clears the public-release blocker. It fixes neither the
conformance drift nor the dialect problem: the six skills still fail
`claude plugin validate`, and a skill authored tomorrow still defaults to the
Hermes profile because nothing says otherwise. This is the status quo `BACKLOG.md`
has flagged since 2026-07-29.

### Option B — Formally fork: the framework defines its own skill format

Declare `conventional-agents SKILL.md` a distinct format with its own schema.

Honest about what has happened in practice. But it discards the portability
`ADR-0001` bought, cuts the framework off from a forty-five-product ecosystem and
its conformance tooling, and freezes whatever the framework understood the format
to be on the day the fork is declared — the precise failure `BACKLOG.md` names in
rejecting a hand-written local format example.

### Option C — Record that the framework *profiles* Agent Skills

The agentskills.io specification is authoritative for `SKILL.md` structure. The
framework adds a **named profile** of additional *authoring* rules — not
structural changes — carried forward from `ADR-0001` and owned explicitly. Source
skills target the base spec; runtime-specific frontmatter is applied by a runtime
binding at sync time, never committed to source.

Keeps portability and the ecosystem. Requires this ADR to enumerate the profile
and to draw one seam — portable source versus runtime dialect — that does not
exist yet.

## Decision Outcome

**Chosen option: Option C — the framework profiles Agent Skills.**

### 1. Agent Skills is a recorded upstream

`README.md`'s "Upstream References" gains an Agent Skills entry with its URL
(`agentskills.io/specification`) and a pointer to where the framework's profile
is documented, matching the treatment of the other four upstreams. `ADR-0001`
gains a Status note pointing to this ADR (an allowed post-acceptance edit).

### 2. The framework profiles the standard; it does not define a format

The agentskills.io specification is authoritative for `SKILL.md` structure,
frontmatter typing, and directory layout. **Where this framework and the spec
disagree on structure, the spec wins and the framework's skill is the defect.**

### 3. The framework's profile is a named set of authoring rules

These are the framework's own, distinct from the spec's requirements. They are
carried forward from `ADR-0001` and stated here so they can be checked:

- **Standalone-useful.** A skill must be actionable when loaded alone — it
  includes operational procedures and at least two runnable examples.
- **Compliance-aware, non-exhaustive.** A short, clearly labelled summary of key
  gates plus links to canonical sources (`roles/ROLE_CONTRACT.md`, relevant
  `guidelines/`). Never the full universal gate list.
- **Minimum content checklist.** When-to-use; compliance references; at least two
  runnable examples; a copy-paste-friendly checklist; a common-pitfalls section.
- **Size signal.** The main `SKILL.md` stays under ~400 lines (the framework's
  number; the spec recommends under 500). Overflow moves into the spec's
  optional `references/` directory, not into a second skill.
- **No duplicate gates.** A skill summarises and links; it does not restate
  `ROLE_CONTRACT.md`.

Per `ADR-0030`, these rules live in a current-state document
(`skills/index.md` or a new `skills/AUTHORING.md`), and this ADR is discharged
once that document carries them.

### 4. Source skills target the base spec

The committed `skills/*/SKILL.md` files are base-spec-clean:

- `version`, `author`, `platforms` move under `metadata:` as string values, or
  are dropped where they carry no information.
- `metadata` is a flat map of string keys to string values. The
  `metadata.hermes.*` nesting is removed from source.
- Cross-references (`related_skills` and prose) name only skills that exist in
  this repository and appear in `skills/index.md`.

### 5. Runtime dialects are a binding's responsibility, not the source's

If a runtime needs frontmatter the base spec does not define — Hermes Agent's
`metadata.hermes.*`, OpenClaw's `metadata.openclaw.*`, a future Codex convention
— a **runtime binding** (`ADR-0039`) applies it at sync or build time. The source
file stays portable to every runtime and to the claude.ai Skills API. A runtime
dialect is never backported into `skills/*/SKILL.md`.

### 6. Conformance becomes a gate — under its own FS

Adopting `skills-ref validate` (or an equivalent conformance validator) as a CI
gate is Category 1 under `ADR-0015` and requires an approved FS and PLAN. This
ADR authorises the direction; it does not authorise writing the gate.

### 7. The `ADR-0034` Part 2 skill reorganisations proceed as Category 2 work

Splitting `git-gh-workflow` into focused sub-skills and porting the two
already-agnostic Hermes skills are Category 2 under `ADR-0015` — no further ADR —
and follow rules 3–5 above when done.

## Consequences

### Positive

- The upstream dependency is recorded, clearing a public-release blocker and
  matching the framework's own second-highest quality goal (Tool Neutrality is
  better served by tracking upstreams than by inventing).
- The six shipped skills become spec-conformant and portable; `git-gh-workflow`'s
  dangling cross-references are resolved.
- The framework's authoring rules stop being folklore in an accepted ADR's prose
  and become a checkable current-state document.
- A clean seam — portable source skill versus runtime dialect — that `ADR-0039`
  builds on directly.

### Negative

- The six skills need mechanical edits and re-review.
- A consumer running the framework's skills through Hermes today and relying on
  `metadata.hermes.*` in the **source** files loses that until the Hermes runtime
  binding restores it at sync time — a migration with a timing gap.
- Adopting `skills-ref validate` later makes the framework depend on an external
  tool, the same maintenance class as `markdownlint`.

### Neutral

- `ADR-0001` stays `accepted`. This ADR is its successor on the provenance and
  profile question, not its replacement on the format decision.
- `ADR-0034`'s Part 2 intent (record the upstream, fix conformance, reorganise
  skills) is carried here. The combined disposition of `ADR-0034` — proposed and
  never accepted, its two parts split across this ADR and `ADR-0039` — is
  recorded in `ADR-0039`'s Consequences.

## Validation

This decision is correct if:

- **Conformance holds.** Once adopted, `skills-ref validate ./skills/<name>`
  passes on every framework skill, or each failure is a documented exception in
  the profile document.
- **The upstream is cited.** `README.md`'s "Upstream References" has an Agent
  Skills row with its URL.
- **Source stays base-spec-clean.** No `skills/*/SKILL.md` has a nested map or
  array under `metadata:`, and no cross-reference names a skill absent from
  `skills/index.md`. Both are grep-checkable and belong in the future conformance
  gate.
- **Review checkpoint — first runtime binding.** When `ADR-0039`'s first binding
  ships, confirm the runtime dialect it needs was applied *in the binding*, not
  backported into a source skill.

The falsifying outcome: a year on, `skills/*/SKILL.md` again carries
`metadata.hermes.*` or `metadata.openclaw.*` because that was easier than
teaching the binding to apply it. That means the seam in rule 5 is not real and
the framework has a fork it will not admit — and it has picked a side in the
Hermes/OpenClaw split by accident.

## Links

- `ADR-0001` — the skill-format decision this ADR succeeds on provenance; gains a
  forward-pointing Status note.
- `ADR-0015` — the tool taxonomy; skill edits are Category 2, the conformance
  gate is Category 1.
- `ADR-0030` — decision records versus current-state documents; the profile rules
  move to a current-state document.
- `ADR-0034` — the proposed ADR whose Part 2 this carries forward.
- `ADR-0039` — agent-runtime bindings; consumes rule 5 (dialects are a binding's
  job).
- `README.md` §"Upstream References" — where the Agent Skills entry lands.
- `skills/index.md` — the current-state document that will carry the profile.
- `BACKLOG.md` §"The Agent Skills format is an unnamed upstream dependency" — the
  gap this ADR closes.
- [agentskills.io/specification](https://agentskills.io/specification) — the
  authoritative format specification.
- [docs.openclaw.ai/tools/skills-config](https://docs.openclaw.ai/tools/skills-config)
  — OpenClaw's six-source skill hierarchy and `metadata.openclaw.*` namespace;
  the second `metadata.<runtime>.*` extension this ADR's rule 5 accounts for.
