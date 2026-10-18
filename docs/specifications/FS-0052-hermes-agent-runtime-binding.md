---
type: feature-spec
id: FS-0052
status: draft
title: Hermes Agent runtime binding — the second agent-runtime binding under ADR-0039
owner: ajoeofalltrades
test_required: true
interfaces:
  - "integrations/runtimes/README.md"
  - "integrations/runtimes/hermes-agent/README.md"
  - "integrations/runtimes/hermes-agent/bundle/**"
  - "integrations/runtimes/hermes-agent/skills/**"
  - "integrations/runtimes/hermes-agent/hooks/**"
  - "integrations/runtimes/hermes-agent/config.fragment.yaml"
  - "integrations/runtimes/hermes-agent/SOUL.md.example"
  - "integrations/runtimes/hermes-agent/mcp_servers.fragment.yaml"
  - "integrations/runtimes/hermes-agent/bin/ca-hermes-audit.sh"
  - "integrations/runtimes/hermes-agent/lib/**"
  - "integrations/README.md"
  - "INTEGRATION.md"
  - "docs/ARC42.md"
  - "package.json"
  - "scripts/README.md"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0052/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs:
  - ADR-0039
  - ADR-0038
  - ADR-0004
  - ADR-0007
  - ADR-0015
  - ADR-0018
  - ADR-0029
  - ADR-0032
  - ADR-0037
supersedes: []
requires:
  - ADR-0039
  - ADR-0038
tags: [runtime-binding, hermes-agent, integrations, skills, mcp, exported-surface]
created: 2026-10-18
updated: 2026-10-18
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Hermes Agent runtime binding

## Status

- Draft

## Summary

`ADR-0039` established the runtime binding: a directory under
`integrations/runtimes/<runtime>/` that maps the framework's setup requirements
onto one agent runtime's configuration surface. `FS-0030` delivered the first
binding (Claude Code) and the shared `integrations/runtimes/` surface. This spec
delivers the **second** — Hermes Agent — per `ADR-0039` §5 stage 2, as a
**separate** binding from OpenClaw (they are two runtimes, not one; `ADR-0039`
does not pre-unify them).

Hermes Agent is the runtime the framework itself runs on: the bulk of trunk's
commits are authored on it, and the framework's skills were originally authored
in its dialect. That makes this binding both the most-*used* and the one whose
tribal knowledge is most expensive to leave unwritten. It differs from the
Claude Code binding in the ways `ADR-0039`'s table records:

- **Anchor file.** Hermes reads `AGENTS.md` plus workspace-bootstrap files
  (`SOUL.md`, `USER.md`, `MEMORY.md`), first-matching `.hermes.md` →
  `AGENTS.md` → `CLAUDE.md` (`ADR-0004`'s hierarchy, unchanged).
- **Config.** `~/.hermes/config.yaml` (YAML) plus profiles — a **user-home**
  surface, not a repo-local `.claude/settings.json`. The binding ships a
  parameterised fragment a consumer merges into their profile; it commits no
  instance config.
- **Skills.** Hermes honours the base agentskills.io spec plus a
  `metadata.hermes.*` namespace over a multi-source hierarchy. The framework's
  source skills are base-spec since the `ADR-0038` Category 2 cleanup; the
  binding documents discovery and applies the Hermes dialect only where Hermes
  requires it, never back into `skills/*/SKILL.md` (`ADR-0038` §5).
- **Packaging.** Hermes bundles/plugins, not a Claude Code plugin.
- **Hooks.** Shell `hooks` (`ADR-0039` §3: local and advisory, never a new
  gate).
- **MCP.** `mcp_servers:` in `config.yaml` plus a curated catalog.

Hermes's **`cron` / `webhook` / `moa` / `kanban` primitives are documented, not
wired** (`ADR-0039` §3 and §5). The binding's README describes what they are and
why the framework does not configure them — a shipped trigger that mutates a
governed work item is orchestration, and the line is the same one `ADR-0039`
§3 draws for every runtime.

The binding ships: a `SOUL.md.example` anchor that imports `AGENTS.md`; a
`config.fragment.yaml` for identity/attribution and MCP; a skills-discovery
mechanism sourced from unchanged `skills/*/SKILL.md`; an advisory shell hook that
runs the framework's existing gate scripts; a report-only `ca-hermes-audit.sh`;
and a README with a per-artefact **provisions**/**documents** classification
(`ADR-0037` §6) — no artefact **enforces**, and nothing is a merge-blocking
gate.

## Goals

- Ship the Hermes Agent binding under `integrations/runtimes/hermes-agent/` in
  full, reusing the `integrations/runtimes/` surface `FS-0030` established.
- Wire Hermes to the canonical `AGENTS.md` via a bootstrap fragment without
  changing `ADR-0004`'s precedence hierarchy.
- Make the framework's base-spec skills discoverable to Hermes from unchanged
  source files, applying the `metadata.hermes.*` dialect only at the binding
  edge.
- Ship a local advisory gate-runner hook and a report-only config audit — no
  new enforcement, no orchestration.
- Document (not configure) Hermes's `cron`/`webhook`/`moa`/`kanban` primitives
  and the `ADR-0007` line they sit behind.
- State, per shipped artefact, whether it **provisions** or **documents** — no
  artefact **enforces** (`ADR-0037` §6).

## Non-Goals

- **The OpenClaw and Codex bindings.** Each is its own FS/PLAN after this one
  (`ADR-0039` §5). This spec ships only Hermes Agent.
- **A neutral runtime contract.** Not defined here or anywhere until ≥2 bindings
  have shipped and their overlap is demonstrated (`ADR-0039` §5, `ADR-0024`).
  `FS-0030` shipped one; this is the second, and whether a contract is warranted
  is the Head Architect's deliberate call after this one lands — not an
  automatic effect of this spec.
- **Configuring Hermes `cron`/`webhook`/`moa`/`kanban`.** Documented only.
- **Any merge-blocking CI check on a binding command.** That is a Category 1
  gate under `ADR-0015`'s Location invariant, needing its own FS, PLAN, and a
  home in `scripts/`.
- **Restructuring `skills/*/SKILL.md`.** This binding consumes the base-spec
  source files and does not edit them.
- **Orchestration of any kind.** No scheduler, watcher, daemon, background
  monitor, `schedule:` trigger, or hook that transitions the status of any FS,
  PLAN, ADR, or work item (`ADR-0007`, `ADR-0039` §3).
- **Any change to the GitHub substrate binding (`FS-0029`) or the Claude Code
  binding (`FS-0030`).**

## Users / Stakeholders

- **Consumer repositories** that run Hermes Agent against a framework-governed
  project and today hand-assemble `~/.hermes/`.
- **This framework**, its own first consumer — the maintainer's `~/.hermes/`
  profile adopts the binding.
- **The OpenClaw / Codex binding authors**, who reuse this binding's skill and
  MCP portions (`ADR-0039` §5: the two gateway-shaped runtimes share much).

## Interfaces

- **Type:** Config, Infra, CLI, Library
- **Details:**

| Path | Kind | Purpose |
| --- | --- | --- |
| `integrations/runtimes/README.md` | Doc | Index of runtime bindings; Hermes Agent moves to `available` |
| `integrations/runtimes/hermes-agent/README.md` | Doc | The binding contract, the provisions/documents table, and the primitives note |
| `integrations/runtimes/hermes-agent/bundle/**` | Config | Hermes bundle/plugin manifest and contents |
| `integrations/runtimes/hermes-agent/skills/**` | Config | Skill-discovery mechanism (sync from `skills/`) |
| `integrations/runtimes/hermes-agent/hooks/**` | Config | Local advisory shell hook running `check-status.sh` / `lint:docs` |
| `integrations/runtimes/hermes-agent/config.fragment.yaml` | Config | `~/.hermes/config.yaml` keys for identity/attribution + the hook |
| `integrations/runtimes/hermes-agent/SOUL.md.example` | Template | `SOUL.md` bootstrap that imports `AGENTS.md` |
| `integrations/runtimes/hermes-agent/mcp_servers.fragment.yaml` | Config | Parameterised `mcp_servers:` example |
| `integrations/runtimes/hermes-agent/bin/ca-hermes-audit.sh` | CLI | Report-only `~/.hermes/` conformance audit |
| `integrations/runtimes/hermes-agent/lib/**` | Library | Shared helpers for the audit |
| `package.json` | Config | npm registration of `ca-hermes-audit` (report-only) |
| `scripts/README.md` | Doc | Cross-reference: binding executables are not Category 1 gates |
| `.github/workflows/lint-docs.yml` | Infra | `lint:integrations` already widened; verify Hermes markdown is covered |
| `test/FS-0052/**` | Test | bats suites |

## Success Criteria

### The `integrations/runtimes/` surface

- **SC-1.** Given `integrations/runtimes/README.md`, when inspected, then it
  lists Claude Code and Hermes Agent as `available`, and OpenClaw and Codex as
  `planned — own FS`, with no configuration content for the planned two.
- **SC-2.** Given `npm run lint:integrations`, when it runs, then it covers the
  markdown beneath `integrations/runtimes/hermes-agent/` recursively.
- **SC-3.** Given `npm run check:status`, when it runs against this repository
  after the change, then rule 8 passes: every backticked path in
  `integrations/runtimes/**/*.md` resolves.

### Shared behaviour

- **SC-4.** Given any file under `integrations/runtimes/hermes-agent/`, when
  inspected, then it contains no organisation name, repository name, project
  number, node ID, field or option ID, model name, or secret value
  (`ADR-0032`); parameterised placeholders are used instead.
- **SC-5.** Given any file under `integrations/runtimes/`, when inspected, then
  it contains no `schedule:` trigger, no background monitor, and no hook or
  command that writes a `status:` field (`ADR-0007`, `ADR-0039` §3).
- **SC-6.** Given any shipped script, when its source is inspected, then it
  reads no path containing a `vendor/` segment, and resolves its target
  repository from the caller's working directory with `CA_TARGET_REPO`
  overriding (`FS-0024` / `ADR-0033`).
- **SC-7.** Given `integrations/runtimes/hermes-agent/README.md`, when
  inspected, then it contains a table with one row per shipped artefact
  classifying it as **provisions** or **documents**, and no row is
  **enforces** (`ADR-0037` §6).

### Anchor-file wiring

- **SC-8.** Given `SOUL.md.example`, when inspected, then it imports `AGENTS.md`
  (via the mechanism Hermes documents) and adds no authority tier — it defers
  to the `ADR-0004` hierarchy.
- **SC-9.** Given the binding README, when inspected, then it documents Hermes's
  first-match order (`.hermes.md` → `AGENTS.md` → `CLAUDE.md`) and how a
  consumer points a profile at the canonical `AGENTS.md`.

### Skill discovery

- **SC-10.** Given the binding's skill-discovery mechanism, when applied to a
  consumer repository, then every skill in the framework's `skills/index.md`
  becomes invocable in Hermes, sourced from the unchanged `skills/*/SKILL.md`
  files.
- **SC-11.** Given the skill-discovery mechanism, when its source and outputs
  are inspected, then it writes no runtime dialect back into any
  `skills/*/SKILL.md` (`ADR-0038` §5); any `metadata.hermes.*` is applied at the
  binding edge only.

### The advisory hook

- **SC-12.** Given `hooks/**`, when inspected, then its hook invokes an existing
  framework gate script (`check-status.sh` or `lint:docs`) at a documented
  Hermes lifecycle event, and the binding README states the hook is a local
  convenience that adds no enforcement the framework's CI does not already have.
- **SC-13.** Given the hook runs and the gate script exits non-zero, when the
  hook returns, then it surfaces the failure to the session without blocking it
  unconditionally — it is advisory, not a `deny`.

### Identity and attribution

- **SC-14.** Given `config.fragment.yaml`, when inspected, then it sets the keys
  that make Hermes emit the `Agent-Attribution:` trailer and a commit identity
  consistent with `ADR-0018` / `ADR-0029`, and the binding README shows how a
  consumer substitutes their own actor address.

### MCP

- **SC-15.** Given `mcp_servers.fragment.yaml`, when inspected, then it is a
  parameterised example carrying no real server credentials or endpoints, and
  the binding README states that an MCP server which would expand the
  framework's governance surface requires its own approved FS (`ADR-0039` §4).

### The report-only audit

- **SC-16.** Given `ca-hermes-audit.sh --help`, when it runs, then it prints
  usage naming every flag and environment variable it reads, and exits 0.
- **SC-17.** Given `ca-hermes-audit.sh` runs against a `~/.hermes/` profile that
  does not match the binding, when it completes, then it reports each divergence
  and **exits 0** in default mode; `--strict` exits non-zero when divergences
  exist.
- **SC-18.** Given `ca-hermes-audit.sh`'s source, when inspected, then it
  performs no mutation — it does not write `~/.hermes/`, does not call a
  mutating `gh`/`git` operation, and is registered in `package.json` as a
  report-only script that the framework's CI does not run as a blocking check.

### Primitives documentation

- **SC-19.** Given the binding README, when inspected, then it names Hermes's
  `cron`, `webhook`, `moa`, and `kanban` primitives and states that the framework
  documents but does not configure them, citing `ADR-0039` §3 and `ADR-0007`
  (a shipped trigger that mutates a governed work item is orchestration).

### Documentation and registration

- **SC-20.** Given `scripts/README.md`, when inspected, then it cross-references
  `integrations/runtimes/` and states that binding executables are **not**
  Category 1 gates while non-blocking, citing `ADR-0015`'s Location invariant.
- **SC-21.** Given `INTEGRATION.md`, when inspected, then its Hermes guidance
  points at `integrations/runtimes/hermes-agent/` (and contains no reference to
  a `packs/` path).
- **SC-22.** Given `npm test`, when it runs, then the `test/FS-0052/` suites
  execute and pass, and `bash -n` succeeds on every shipped `.sh` file.

## Edge Cases

- **A consumer runs Hermes with an existing `~/.hermes/config.yaml`.** The
  fragment is additive; the README shows how to merge rather than overwrite.
- **`SOUL.md` already exists in a consumer's workspace.** The binding documents
  the import merge, not a wholesale replace.
- **The `hermes` CLI is absent.** The audit fails with an install hint, not a
  vacuous pass (`FS-0022` §6).
- **Bash 3.2** (macOS system bash): the shipped library uses no associative
  arrays, consistent with `scripts/README.md`.
- **A consumer's profile carries its own `metadata.hermes.*`.** The binding does
  not overwrite consumer values (`ADR-0039` §6); the audit flags a divergence,
  not a correction.

## Out of Scope

- Any configuration for OpenClaw, Codex, Cursor, or Aider.
- Mutating a consumer's `~/.hermes/`, git config, or any repository state from a
  shipped command.
- A marketplace listing for the bundle.
- `shellcheck` adoption as a gate (applies repo-wide; a separate decision).
- Changing `ADR-0004`'s precedence hierarchy or any accepted ADR's body.
- Wiring any Hermes `cron`/`webhook`/`moa`/`kanban` trigger.

## Dependencies

- `ADR-0039` accepted (done); `ADR-0038` accepted (done); this spec approved.
- `hermes` CLI for manual verification of the audit and hook.
- `bats` and `rg` for the test suites.
- `AGENTS.md` present at the consumer repository root (`ADR-0004`).

## Rollout / Migration

1. `FS-0052` approved; `PLAN-0059` approved on merge with an `Approved-By:`
   trailer (reserved paths under `ADR-0027`).
2. The binding lands with the framework as its first consumer: the maintainer's
   `~/.hermes/` profile adopts the fragment, and the binding README records the
   audit output.
3. `INTEGRATION.md` Hermes guidance repoints at the binding; the
   `integrations/runtimes/README.md` index marks Hermes Agent `available`.
4. OpenClaw and Codex bindings follow in their own FS/PLAN cycles, reusing this
   binding's skill and MCP portions.

## Observability

- `ca-hermes-audit.sh` prints a summary distinguishing "matches the binding"
  from "diverges" without parsing.
- The advisory hook announces which gate it ran and its result.

## Security / Privacy

- **Data handled:** `~/.hermes/` configuration read from the caller's profile;
  no credentials.
- **Threats considered:** a shipped hook presented as an enforcement control when
  the runtime treats it as advisory; instance data (actor addresses, MCP
  endpoints) baked into a vendored template; a shipped trigger mutating governed
  work.
- **Mitigations:** SC-7 forbids an **enforces** classification; SC-12/SC-13
  keep the hook advisory; SC-4/SC-15 keep instance data out; SC-5/SC-19 keep
  primitives documented-not-wired; SC-18 keeps the audit non-mutating and out of
  blocking CI.

## Open Questions

None blocking. Each has a stated default that implementation follows unless the
approving human directs otherwise:

- **Skills discovery — copy, symlink, or a sync script?** *Default: a documented
  symlink for local use plus a sync script for CI/packaging*, so the source of
  truth stays `skills/*/SKILL.md`.
- **Does the `metadata.hermes.*` dialect live in the bundle or get applied at
  sync time?** *Default: applied at sync time to the binding's copy*, never back
  into source (`SC-11`).
- **One combined binding doc, or split contract/hazards files?** *Default: one
  `README.md`* until it exceeds the size signal, then `references/`.
- **Is a neutral runtime contract warranted now that two bindings ship?** This is
  the `ADR-0039` §5 review checkpoint, resolved by the Head Architect after this
  binding lands — not by this spec.
