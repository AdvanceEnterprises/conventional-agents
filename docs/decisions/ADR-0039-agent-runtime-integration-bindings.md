---
type: adr
id: ADR-0039
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0029
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

# ADR-0039: Agent-runtime integration bindings

## Status

- Proposed

## Context and Problem Statement

`ADR-0004` made `AGENTS.md` the canonical integration surface and placed
tool-specific files (`CLAUDE.md`, `.cursorrules`, a Codex context file) at the
bottom of the precedence hierarchy as defer-only. `ADR-0024` established the
two-layer substrate model — a platform-neutral core plus concrete bindings under
`integrations/` — and `ADR-0037` made the first binding a *directory* with an
executable layer, governed as binding content. All three ADRs concern the
**work-tracking** substrate.

There is a second substrate the framework runs on and has never bound: the
**agent runtime** itself. This repository is worked on by at least four:

- **Hermes Agent** (`NousResearch/hermes-agent`, Python) — the bulk of trunk's
  commits.
- **OpenClaw** (`openclaw.ai`, formerly Moltbot, TypeScript, non-profit OpenClaw
  Foundation, OpenAI-sponsored) — Hermes's sibling in the market and its near
  twin in shape.
- **Claude Code** — interactive sessions.
- An **OpenAI Codex-family agent** — the `codex/` branch, `contrib-codex.md` in
  the multi-model pilot.

Each has a configuration surface the framework's setup must be expressed in, and
the surfaces differ materially:

| Concern | Claude Code | Codex CLI | Hermes Agent / OpenClaw (gateway-class) |
| --- | --- | --- | --- |
| Anchor file | reads `CLAUDE.md` only; `@AGENTS.md` import or symlink bridges it | `AGENTS.md` + `~/.codex/instructions.md`, merged root→leaf | both read `AGENTS.md` + workspace bootstrap files (`SOUL.md`, `USER.md`, `MEMORY.md`); Hermes first-matches `.hermes.md` → `AGENTS.md` → `CLAUDE.md` |
| Project config | `.claude/settings.json` / `.claude/settings.local.json` / managed | `~/.codex/config.toml` + `.codex/config.toml` (trusted only) + profiles | Hermes `~/.hermes/config.yaml` (YAML) + profiles; OpenClaw `openclaw.json` (JSON5) + `config get/set/patch/validate` |
| Skills | `.claude/skills/<n>/SKILL.md`, base agentskills.io spec | no first-class skills directory | agentskills.io + a `metadata.<runtime>.*` namespace each (`metadata.hermes.*`; `metadata.openclaw.skillKey` / `.primaryEnv`); multi-source dir hierarchy; OpenClaw also probes a tool-neutral `.agents/skills` |
| Packaging unit | plugin (`.claude-plugin/plugin.json` + skills/commands/agents/hooks/`.mcp.json`), `claude plugin validate` | profile file; `.codex-plugin/plugin.json` | Hermes `plugins` / `bundles`; **OpenClaw `bundles` ingests all four external plugin formats** (Agent Plugin, `.codex-plugin`, `.claude-plugin`, `.cursor-plugin`) into native skills/hooks/MCP/LSP |
| Pre-commit hooks | 31 events, `PreToolUse` can deny | 11 events, `PreToolUse` can deny, trust required | Hermes `hooks` (shell); OpenClaw `hooks list/enable/install` + native `HOOK.md`+`handler.ts` (Claude `hooks.json` is detect-only) |
| MCP config | `.mcp.json`, plugin `.mcp.json` | `[mcp_servers.<id>]` in `config.toml` | Hermes `mcp_servers:` in `config.yaml` + curated catalog; OpenClaw `mcp set/unset` |

**Hermes Agent and OpenClaw are one binding *family*, not two unrelated
bindings.** They are independent codebases (Python vs. TypeScript; a
self-improving loop vs. a control-plane-first gateway) with near-identical
integration shape: workspace bootstrap files anchored by `SOUL.md`, a
multi-source `SKILL.md` hierarchy, a `config get/set/patch/validate` CLI, a
`doctor` command, first-class hooks, and a `metadata.<runtime>.*` skill
extension. OpenClaw's bundle system already maps Claude, Codex, Cursor, and
generic Agent-Plugin layouts into that shape — evidence the runtime
configurations are mechanically inter-translatable, and a concrete reason the
gateway-class binding can reuse most of the Claude Code binding's content.

Today the framework's expression against these surfaces is undocumented and has
drifted:

- **`INTEGRATION.md`'s first copy-paste is broken.** Its Quick Start and
  "Tool-Specific Integration" section instruct a consumer to run
  `cp vendor/conventional-agents/packs/claude/CLAUDE.full.example.md ./CLAUDE.md`
  and `cp vendor/conventional-agents/packs/aider/CONVENTIONS.md ./CONVENTIONS.md`,
  and to read `guidelines/index.md` and `roles/test-writer.md`. `packs/` has
  never existed — `ADR-0001` and `docs/ARC42.md` §5.1 both call it "planned" —
  and the two guideline paths were removed. Four `packs/` references, all broken,
  and this is the first thing a new public adopter runs.
- **The framework's skills are in one runtime's dialect.** All six carry
  `metadata.hermes.*`, because Hermes Agent is the runtime they were authored on
  — not OpenClaw's `metadata.openclaw.*`, and not the base spec. `claude plugin
  validate` warns on all six (`ADR-0038`).
- **The operational knowledge is tribal.** How each runtime is pointed at the
  canonical `AGENTS.md`; how it runs the framework's gate scripts before a
  commit; how it sets `user.name` / `user.email` and the `Agent-Attribution:`
  trailer (`ADR-0018` / `ADR-0029` / `ADR-0036`) — none of it is written down.

This is the defect `ADR-0037` named for the GitHub binding, one substrate over:
the framework describes how a runtime should be set up and leaves the setup to be
rediscovered.

### What is not the problem

`ADR-0004`'s precedence hierarchy is not changing. A runtime binding adds no new
anchor file and no new authority tier; it ships the mechanism that wires one
runtime to the hierarchy `ADR-0004` already defines. Nor is `ADR-0007`'s
"standards only, never orchestration" line moving — see Decision Outcome §3,
which draws it precisely.

The question this ADR answers: **is an agent runtime a substrate the framework
binds, the way it binds GitHub — and if so, where do runtime bindings live, what
may they ship, and what may they not?**

## Decision Drivers

- **`ADR-0024`'s driver applies recursively**, as it did for `ADR-0037` §1:
  "abstraction must be extracted, not imagined." The framework has four runtime
  setups and a binding for none of them.
- **The runtime landscape has a real shape, not a long tail.** Two of the four
  (Hermes Agent, OpenClaw) are near-identical; a third (Codex) reads `AGENTS.md`
  natively like they do; only Claude Code is structurally distinct. Bindings
  extracted from this set will not be fitting one obscure tool — they will be
  mapping the two dominant self-hosted agent frameworks of 2026 plus the two
  largest vendor CLIs.
- **A tool-neutral skills directory is emerging.** OpenClaw already probes
  `workspace/.agents/skills` and `~/.agents/skills` alongside its own paths. Where
  a runtime honours a neutral location, a binding should target that rather than
  the runtime-specific path.
- **`ADR-0004` already anticipated this.** Its Neutral section reads: "optional
  helpers may live under `packs/agent-config/`." A runtime binding is that
  helper, finally built and correctly located.
- **`ADR-0007` is accepted at precedence level 1.** "Standards only, never
  orchestration" and "no state machines or decision logic for workflow
  execution." A binding that ships enforcing hooks, background monitors, or a
  scheduled trigger edges toward orchestration; the line must be drawn as
  precisely as `ADR-0037` §2 drew it for executables.
- **`ADR-0032` forbids instance data in a template repository.** A binding ships
  parameterised templates, never an organisation's board IDs, token names, or
  `AGENTS.md` content.
- **`ADR-0024`'s ordering rule.** "The core generalizes over shipped bindings; it
  never forecasts them." One runtime binding is not a generalisation.
- **Tool Neutrality is quality goal #2 and an architecture constraint** (`ARC42`
  §1.2, §2: "must not require adoption of a specific ... runtime"). The binding
  layer must be optional — a runtime with no binding still works off `AGENTS.md`,
  `scripts/`, and `skills/`.
- **MCP-server configuration has no governed home.** `ADR-0034` (proposed) tried
  to make MCP a fourth `ADR-0015` category; it also stated that framework MCP
  config belongs "in `integrations/` following the `ADR-0024` binding pattern."
  The second half is right.

## Considered Options

### Option A — Documentation only: build `packs/` as copyable docs

Build the long-promised `packs/` directory as per-runtime setup docs and
`AGENTS.md` fragments. Ship no configuration.

Cheapest, and it clears the broken `INTEGRATION.md` path and captures the tribal
knowledge. It fixes none of the drift: the skills stay non-conformant for Claude
Code, nothing verifies a runtime is wired correctly, and every consumer still
hand-assembles `.claude/`, `.codex/`, `~/.hermes/`, or `openclaw.json`. It is
Option A of `ADR-0037` relocated, with the same outcome — guidance ahead of an
implementation.

### Option B — One binding per runtime as `scripts/`-style Category 1 gates

Place each runtime binding in `scripts/`, register npm scripts, wire into CI.

Uniform and strongly governed. It is a category error, identical to `ADR-0037`
Option B: a Category 1 gate answers *may this pull request merge?* A runtime
binding provisions and audits a local configuration surface; it has no opinion on
a pull request, and cannot run in CI at all for the parts that touch a
developer's machine.

### Option C — Runtime bindings as binding content under `integrations/runtimes/<name>/`

Extend the two-layer model from substrate to runtime. Each runtime binding is
binding content governed by `ADR-0024`, packaged in `ADR-0037`'s directory
envelope, subordinate to `ADR-0004`.

Keeps `integrations/` as the single home for "map a framework concept onto a
platform," reuses the executable-layer rules `ADR-0037` already litigated, and
keeps the neutral surface authoritative. Requires this ADR to draw the
`ADR-0007` line and defend the neutrality claim.

### Option D — A separate repository per runtime (plugin repos)

Extract each binding into its own versioned repository.

Attractive for release cadence, wrong on ownership — same as `ADR-0037` Option D.
The runtimes are how the framework is *operated*; splitting that into another
repository recreates the framework/consumer boundary inside content that is
unambiguously framework, and guarantees the binding and the framework version
apart.

## Decision Outcome

**Chosen option: Option C — runtime bindings as binding content under
`integrations/runtimes/<runtime>/`.** A governing FS specifies contents. This
ADR records the boundaries.

### 1. A runtime binding is binding content, and `integrations/` holds two binding kinds

`integrations/` becomes home to:

- **Substrate bindings** — map the six work-item capabilities onto a
  work-tracking platform (`ADR-0024`). `integrations/<substrate>.md` or
  `integrations/<substrate>/`.
- **Runtime bindings** — map the framework's setup requirements onto one agent
  runtime's configuration surface. `integrations/runtimes/<runtime>/`.

`integrations/README.md` gains a short section stating the distinction.
`ADR-0037`'s rules for a binding directory apply unchanged: executables are
binding content and are *not* classified under `ADR-0015`; each command
classifies itself as **enforces**, **provisions**, or **reports**; target
resolution is caller-relative (`FS-0024` / `ADR-0033`); no credential reaches a
log.

### 2. A runtime binding maps a fixed set of setup requirements

The requirements are not invented here — every one is already a framework rule:

| Requirement | Framework source |
| --- | --- |
| Point the runtime at the canonical `AGENTS.md` | `ADR-0004` |
| Make the framework's gate scripts runnable at the runtime's pre-commit / pre-PR lifecycle point | `scripts/`, `FS-0024` |
| Make the framework's skills discoverable in the runtime's skill system — a neutral `.agents/skills` location where the runtime honours one, otherwise the runtime-specific path, with the runtime's dialect applied per `ADR-0038` §5 | `ADR-0038` |
| Set commit identity and the `Agent-Attribution:` trailer | `ADR-0018` / `ADR-0029` / `ADR-0036` |
| Optionally, MCP-server configuration | §4 below |

A binding states, per requirement, whether the runtime **enforces** it, the
binding **provisions** it once, or the binding only **documents** it
(`ADR-0037` §6).

### 3. The framework ships setup, never workflow the runtime executes

This is the `ADR-0007` line for runtime bindings, drawn precisely.

A binding **may** ship:

- an anchor-file fragment (a `CLAUDE.md` that imports `AGENTS.md`, a
  `config.toml` `AGENTS.md` pointer);
- a skills manifest or a sync step that applies a runtime dialect per `ADR-0038`
  §5;
- a hook that runs an **existing** framework gate script (`check-status.sh`,
  `lint:docs`) at a lifecycle event the runtime provides;
- a configuration fragment that sets commit identity, permission defaults, or
  MCP servers (`.claude/settings.json`, `.codex/config.toml`,
  `~/.hermes/config.yaml`).

A binding **must not** ship:

- a scheduler, watcher, daemon, background monitor, or `schedule:` trigger that
  mutates a governed work item;
- a plugin or profile default that changes the runtime's agent or behaviour
  beyond applying a framework rule — for example a Claude Code plugin
  `settings.json` that swaps the main agent;
- any hook that transitions the status of an FS, PLAN, ADR, or work item.

The test is whether the shipped configuration **executes rules the framework
already defines** or **defines new control flow**. A hook that runs
`check-status.sh` is the former. A hook that writes a `status:` field is the
latter.

This line is consistent with what the runtimes themselves promise. OpenClaw
documents that a skill allowlist is "a visibility and loading filter ... not a
shell-time authorization boundary," and treats a foreign `hooks.json` as
detect-only rather than executable. A binding that shipped a hook presented as an
enforcement control would be overclaiming in the same way `ADR-0037` §6 and the
GitHub binding's §7 exist to prevent — and the runtime would not honour the
claim anyway. A binding states, per shipped hook, that it **runs a framework
gate** and nothing more.

### 4. MCP-server configuration is runtime-binding content

Where the framework recommends an MCP server, that recommendation is a
parameterised entry in the relevant runtime binding(s), classified per §2 —
almost always **documents** or **provisions**, never **enforces**. The framework
adds **no** `ADR-0015` category for MCP: a binding entry's governance is already
fully determined — it is exported surface, versioned with the framework, and
subordinate to the binding — exactly as `ADR-0037` §3 found for binding
executables. **This supersedes `ADR-0034` Part 1.**

An MCP server whose declared capabilities would expand the framework's
*governance* surface (mutating Issue state, writing a reserved path, approving a
PLAN) still requires an approved FS before adoption. That is `ADR-0014` and
`ADR-0015` acting on the **server**, not on the binding entry that configures it.

### 5. No neutral runtime contract is defined here; bindings ship in a fixed order

`ADR-0024`'s ordering rule binds: "no core capability may be added that no
existing binding implements," and "the core generalizes over shipped bindings; it
never forecasts them." This ADR therefore defines **no** neutral runtime
contract. The governing FS and its successors ship bindings in this order, each
in full:

1. **Claude Code — first.** `claude plugin validate` gives the binding an
   immediate external conformance gate the framework runs in its own CI; binding
   against Claude Code forces `ADR-0038`'s base-spec skill conformance rather
   than letting the Hermes dialect keep riding in source; and the Claude
   plugin layout (`plugin.json` + `skills/` + `.mcp.json`) is the one OpenClaw's
   bundle importer ingests directly and Codex's `.codex-plugin/` mirrors — so
   the first binding's artifact is close to a lingua franca, not a Claude-only
   investment.
2. **The gateway-class family (Hermes Agent + OpenClaw) — second.** Two
   independent, near-identical implementations satisfy `ADR-0024`'s "extract from
   more than one, never forecast from one" *within a single binding cycle*. The
   new surface is the workspace-bootstrap wiring (`SOUL.md` / `AGENTS.md` /
   `MEMORY.md`) and the two `metadata.<runtime>.*` dialects; the skill and MCP
   content is largely the Claude Code binding's, re-fed through OpenClaw's bundle
   importer and a thin Hermes adapter. Hermes's `cron` / `webhook` / `moa` /
   `kanban` primitives map onto `FS-0018` / `ADR-0021` / `FS-0019` / `FS-0021`
   and are documented, not wired (§3).
3. **Codex — third.** The floor: `AGENTS.md` + a `config.toml` fragment +
   `.codex-plugin/`. If the contract holds here, it holds.

A runtime with no binding remains fully supported through the neutral surface at
every stage. **The review checkpoint fires when the gateway-class binding
lands** (stage 2): its two members share a contract by construction, so the
question is whether *that* contract also covers Claude Code, or only the
gateway-class family. If it spans both, a successor ADR records the neutral
runtime contract; if it does not, the bindings stand alone and no contract is
forced.

### 6. Instance data stays out

`ADR-0032` holds. Bindings ship `*.example` fragments and parameterised
templates. `AGENTS.md` content, board IDs, token secret names, organisation
names, model choices, and a consumer's own `metadata.hermes.*` or
`metadata.openclaw.*` values are the consumer's, resolved from the caller's
repository root (`FS-0024` / `ADR-0033`), never baked into a vendored tree.

### 7. `packs/` is retired as a concept

The four broken `INTEGRATION.md` references, and the "planned" mentions in
`docs/ARC42.md` §5.1 and `ADR-0001`, are updated to point at
`integrations/runtimes/`. Nothing is built at `packs/`.

## Consequences

### Positive

- The broken copy-paste path in `INTEGRATION.md` is fixed by building the thing,
  not by deleting the instruction.
- The framework's own four-runtime setup is written down and testable; the
  Claude Code binding is a plugin the framework can `claude plugin validate` in
  its own CI.
- The gateway-class binding (Hermes + OpenClaw) is cheap: OpenClaw's bundle
  importer consumes the Claude Code binding's plugin layout directly, so stage 2
  is mostly the workspace-bootstrap wiring and one Hermes adapter, not a second
  from-scratch binding.
- MCP configuration gets a governed home without a new taxonomy tier.
- `ADR-0004`'s "`packs/agent-config`" gesture is finally discharged.

### Negative

- The exported surface grows and couples to configuration schemas the framework
  does not control (`.claude/settings.json`, Codex `config.toml`, `openclaw.json`,
  Hermes `config.yaml`). `ADR-0037` accepted this exact class of cost for `gh`;
  "these tools break compatibility and the breakage now lands here" applies
  again, now across four schemas.
- Two conventions for reviewers to hold, both backed by review rather than
  tooling: the setup-versus-orchestration line (§3) and the
  one-binding-is-not-a-generalisation rule (§5). They join the table in
  `scripts/README.md`.
- A consumer may read a shipped plugin as licence to automate more than
  `ADR-0007` permits. §3 is the mitigation and will need restating.

### Neutral

- `integrations/` becomes a directory of two binding kinds; `integrations/README.md`
  and the `lint:integrations` glob widen (already required for
  `integrations/github/` by `FS-0029`).
- The reference substrate binding (`integrations/github-issues-projects.md`) is
  untouched in scope.
- **`ADR-0034` disposition.** `ADR-0034` was `proposed` and never `accepted`. It
  bundled the MCP taxonomy (Part 1, superseded by this ADR §4) with skills
  consolidation and upstream recording (Part 2, carried by `ADR-0038`). On
  acceptance of both `ADR-0038` and this ADR, `ADR-0034` moves to `superseded`
  with `superseded_by: [ADR-0038, ADR-0039]` and a Status note. Issue #107,
  which misreports Part 2 as implemented, is corrected and closed as part of the
  same change.

## Validation

This decision is correct if, twelve months on:

- **The broken path is gone and stays gone.** `INTEGRATION.md` contains no
  reference to a `packs/` path, and every runtime-setup instruction points at a
  path under `integrations/runtimes/` that resolves (`check-status.sh` rule 8).
- **The framework runs its own binding.** CI runs `claude plugin validate`
  against the Claude Code binding and it passes within the implementing change —
  the `ADR-0037` early signal: if the framework does not use its own binding, no
  consumer will.
- **Neutrality is demonstrable.** The governing FS shows a runtime with no
  binding, given only `AGENTS.md` + `scripts/` + `skills/`, running the governed
  workflow end to end. If that cannot be shown, the layer is not optional and
  the neutrality claim failed.
- **No orchestration crept in.** No file under `integrations/runtimes/` contains
  a `schedule:` trigger, a background monitor, or a hook that writes a `status:`
  field. Grep-checkable. Hermes's `cron` / `webhook` primitives are documented in
  the gateway-class binding, not configured by it.
- **The core stayed neutral.** When the gateway-class binding lands (§5 stage 2),
  a deliberate decision is made about whether a neutral runtime contract ADR is
  warranted, and whether it spans Claude Code or only the gateway-class family.
  All three stages shipped with no contract extracted, and no deliberate
  decision that none was warranted, is the `ADR-0024` forecasting failure and
  this decision needs revisiting.

The falsifying outcome: `integrations/runtimes/` becomes a directory of plugins
nobody installs — the `packs/` failure mode relocated, which is the same failure
`ADR-0037` names for itself and this ADR inherits.

## Links

- `ADR-0004` — `AGENTS.md` as canonical integration surface; runtime bindings
  operationalise it and do not change its hierarchy.
- `ADR-0007` — standards only, never orchestration; the line §3 draws.
- `ADR-0014` / `ADR-0015` — background-task governance and the tool taxonomy;
  act on an MCP server, not on the binding entry (§4).
- `ADR-0024` — platform-neutral core with shipped bindings; the model this
  extends and the ordering rule constraining §5.
- `ADR-0028` — level-triggered reconciliation; why a shipped trigger is not the
  framework's to run.
- `ADR-0032` — template and instance repository forms; §6.
- `ADR-0033` / `FS-0024` — caller-relative gate target resolution; reused in §1.
- `ADR-0037` — the executable-layer envelope this ADR reuses for runtime
  binding directories.
- `ADR-0038` — Agent Skills as a profiled upstream standard; supplies rule 5
  (runtime dialects are a binding's job) and the base-spec conformance §5 relies
  on.
- `ADR-0034` — the proposed ADR whose Part 1 this supersedes; combined
  disposition in Consequences.
- `INTEGRATION.md`, `integrations/README.md`, `docs/ARC42.md` §5.1 — current-state
  documents updated on acceptance (`ADR-0030` rule 3).
- `FS-0029` — precedent: a binding as a directory with an executable layer and a
  widened lint glob.
- [docs.openclaw.ai](https://docs.openclaw.ai/) — OpenClaw's workspace bootstrap
  files, six-source skill hierarchy, `metadata.openclaw.*` namespace, and the
  bundle system that ingests Claude / Codex / Cursor / Agent-Plugin layouts;
  the evidence for the gateway-class family (§5 stage 2) and the
  inter-translatability claim.
- Governing FS — to be written; ships the Claude Code binding in full (§5
  stage 1) plus the neutrality demonstration.
