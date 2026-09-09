---
type: feature-spec
id: FS-0030
status: approved
title: Claude Code runtime binding — the first agent-runtime binding under ADR-0039
owner: ajoeofalltrades
test_required: true
interfaces:
  - "integrations/runtimes/README.md"
  - "integrations/runtimes/claude-code/README.md"
  - "integrations/runtimes/claude-code/.claude-plugin/plugin.json"
  - "integrations/runtimes/claude-code/skills/**"
  - "integrations/runtimes/claude-code/hooks/hooks.json"
  - "integrations/runtimes/claude-code/.mcp.json.example"
  - "integrations/runtimes/claude-code/settings.fragment.json"
  - "integrations/runtimes/claude-code/CLAUDE.md.example"
  - "integrations/runtimes/claude-code/bin/ca-runtime-audit.sh"
  - "integrations/runtimes/claude-code/lib/**"
  - "integrations/README.md"
  - "INTEGRATION.md"
  - "docs/ARC42.md"
  - ".claude/settings.json"
  - "CLAUDE.md"
  - "package.json"
  - "scripts/README.md"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0030/**"
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
tags: [runtime-binding, claude-code, integrations, skills, mcp, exported-surface]
created: 2026-09-05
updated: 2026-09-09
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

# Feature Spec: Claude Code runtime binding

## Status

- Approved

Approved 2026-09-08 by Joey Clark, recorded on the commit that flips this status
with an `Approved-By:` trailer (`ADR-0026`). #112's merge message asserted this
transition but carried no trailer and left both documents `draft`; issue #122
detected the gap and this change reconciles it. `ADR-0039` is `accepted`, so the
spec-first gate (`guidelines/ROLE_CONTRACT.md`) is now satisfied and
implementation of the Claude Code runtime binding may begin.

## Plan Status

- **PLAN-0036 is `approved`**, recorded on the same commit and carried by the same
  `Approved-By:` trailer (`ADR-0026`). Its `touches:` set includes `package.json`,
  `.github/workflows/lint-docs.yml`, and `scripts/README.md` — three reserved
  paths under `ADR-0027` — so it could not self-approve; this is a recorded human
  act. The implementing PR opens separately, after this one merges.

## Summary

`ADR-0039` established the runtime binding: a directory under
`integrations/runtimes/<runtime>/` that maps the framework's setup requirements
onto one agent runtime's configuration surface. This spec delivers the **first**
one — Claude Code — in full, per `ADR-0039` §5 stage 1, plus the
`integrations/runtimes/` surface the later bindings share.

Claude Code is first because binding against it forces `ADR-0038`'s base-spec
skill conformance (its plugin validator surfaces non-conformant frontmatter), and
because its plugin layout is the most reusable starting point for the Hermes,
OpenClaw, and Codex bindings that follow — the *skill and MCP* portions carry
over even though hooks and anchor-file wiring do not.

The binding is packaged as a Claude Code **plugin** (installable, and checkable
with `claude plugin validate` locally), with a non-plugin `.claude/` fragment
path for consumers who do not want a plugin. It ships:

- a `CLAUDE.md` that imports the canonical `AGENTS.md` (`ADR-0004`);
- the framework's skills made discoverable to Claude Code, sourced from
  `skills/*/SKILL.md` unchanged (`ADR-0038` — no dialect committed to source);
- a **local, advisory** hook that runs the framework's existing gate scripts at a
  Claude Code lifecycle event — not a new gate (`ADR-0039` §3);
- a settings fragment for commit identity and the `Agent-Attribution:` trailer
  (`ADR-0018` / `ADR-0029`);
- a parameterised MCP configuration example (`ADR-0039` §4);
- a **report-only** audit command that tells a consumer whether their `.claude/`
  matches the binding — non-blocking, never a CI gate (`ADR-0037` §3,
  `ADR-0015` Location invariant).

The framework adopts its own binding within this change (`ADR-0039` Validation),
and a documented, tested demonstration shows a runtime with **no** binding still
runs the governed workflow off `AGENTS.md` + `scripts/` + `skills/`.

## Goals

- Ship the `integrations/runtimes/` surface and the Claude Code binding in full.
- Package it as a plugin that `claude plugin validate` accepts, and provide a
  non-plugin fragment path.
- Wire Claude Code to the canonical `AGENTS.md` without changing `ADR-0004`'s
  precedence hierarchy.
- Make the framework's skills discoverable to Claude Code from unchanged
  base-spec source files.
- Ship a local advisory gate-runner hook and a report-only config audit — no new
  enforcement, no orchestration.
- Have the framework run its own binding, and demonstrate the no-binding path
  still works.
- State, per shipped artefact, whether it **provisions** or **documents** — no
  artefact **enforces** (`ADR-0037` §6).

## Non-Goals

- **The Hermes Agent, OpenClaw, and Codex bindings.** Each is its own FS/PLAN
  after this one (`ADR-0039` §5). This spec ships only Claude Code.
- **A neutral runtime contract.** Not defined here or anywhere until ≥2 bindings
  have shipped and their overlap is demonstrated (`ADR-0039` §5, `ADR-0024`).
- **`claude plugin validate` as a merge-blocking CI check.** That is a Category 1
  governance gate under `ADR-0015`'s Location invariant and needs its own FS,
  PLAN, and a home in `scripts/`. The framework may run it **advisory**
  (non-blocking) in its own CI; nothing here fails a merge on its exit code.
- **Restructuring `skills/*/SKILL.md`.** The `ADR-0038` Category 2 conformance
  cleanup (metadata flattening, dangling cross-references, `example-skill`)
  landed in #116/#117/#118; this binding consumes whatever the source files are
  and does not edit them.
- **Orchestration of any kind.** No scheduler, watcher, daemon, background
  monitor, `schedule:` trigger, or hook that transitions the status of any FS,
  PLAN, ADR, or work item (`ADR-0007`, `ADR-0039` §3).
- **Any change to `integrations/github-issues-projects.md`** or the GitHub
  executable layer (`FS-0029`).
- **Publishing the plugin to a marketplace.**

## Users / Stakeholders

- **Consumer repositories** that use Claude Code against a framework-governed
  project and today hand-assemble `.claude/`.
- **This framework**, its own first consumer — its `.claude/` adopts the binding.
- **The Hermes / OpenClaw / Codex binding authors**, who reuse this binding's
  skill and MCP portions.
- **Adopters evaluating the framework**, for whom `INTEGRATION.md`'s per-runtime
  guidance currently points at a `packs/` directory that never existed.

## Interfaces

- **Type:** Config, Infra, CLI, Library
- **Details:**

| Path | Kind | Purpose |
| --- | --- | --- |
| `integrations/runtimes/README.md` | Doc | Index of runtime bindings; the substrate-vs-runtime distinction |
| `integrations/runtimes/claude-code/README.md` | Doc | The binding contract and the provisions/documents table |
| `integrations/runtimes/claude-code/.claude-plugin/plugin.json` | Config | Plugin manifest (`claude plugin validate` target) |
| `integrations/runtimes/claude-code/skills/**` | Config | Skill discovery mechanism (sync/symlink from `skills/`) |
| `integrations/runtimes/claude-code/hooks/hooks.json` | Config | Local advisory hook running `check-status.sh` / `lint:docs` |
| `integrations/runtimes/claude-code/.mcp.json.example` | Config | Parameterised MCP example |
| `integrations/runtimes/claude-code/settings.fragment.json` | Config | `.claude/settings.json` keys for identity/attribution + the hook |
| `integrations/runtimes/claude-code/CLAUDE.md.example` | Template | `CLAUDE.md` that imports `AGENTS.md` |
| `integrations/runtimes/claude-code/bin/ca-runtime-audit.sh` | CLI | Report-only `.claude/` conformance audit |
| `integrations/runtimes/claude-code/lib/**` | Library | Shared helpers for the audit |
| `.claude/settings.json`, `CLAUDE.md` | Instance | The framework's own adoption |
| `package.json` | Config | npm registration of `ca-runtime-audit` (report-only) |
| `scripts/README.md` | Doc | Cross-reference: binding executables live here, not `scripts/`, and why |
| `.github/workflows/lint-docs.yml` | Infra | `lint:integrations` widened to `integrations/**/*.md`; optional advisory `claude plugin validate` |
| `test/FS-0030/**` | Test | bats suites |

## Success Criteria

### The `integrations/runtimes/` surface

- **SC-1.** Given `integrations/README.md`, when inspected, then it distinguishes
   substrate bindings from runtime bindings and names `integrations/runtimes/` as
   the home of the latter, governed by `ADR-0039`.
- **SC-2.** Given `integrations/runtimes/README.md`, when inspected, then it lists
   Claude Code as `available` and Hermes Agent, OpenClaw, and Codex as
   `planned — own FS`, with no configuration content for the planned three.
- **SC-3.** Given `npm run lint:integrations`, when it runs, then it covers
   markdown beneath `integrations/` recursively, not only `integrations/*.md`.
- **SC-4.** Given `npm run check:status`, when it runs against this repository
   after the change, then rule 8 passes: every backticked path in
   `integrations/runtimes/**/*.md` resolves.

### Shared behaviour

- **SC-5.** Given any file under `integrations/runtimes/claude-code/`, when
   inspected, then it contains no organisation name, repository name, project
   number, node ID, field or option ID, model name, or secret value
   (`ADR-0032`); parameterised placeholders are used instead.
- **SC-6.** Given any file under `integrations/runtimes/`, when inspected, then it
   contains no `schedule:` trigger, no background monitor, and no hook or command
   that writes a `status:` field (`ADR-0007`, `ADR-0039` §3).
- **SC-7.** Given any shipped script, when its source is inspected, then it reads
   no path containing a `vendor/` segment, and resolves its target repository
   from the caller's working directory with `CA_TARGET_REPO` overriding
   (`FS-0024` / `ADR-0033`).
- **SC-8.** Given `integrations/runtimes/claude-code/README.md`, when inspected,
   then it contains a table with one row per shipped artefact classifying it as
   **provisions** or **documents**, and no row is **enforces** (`ADR-0037` §6).

### Anchor-file wiring

- **SC-9.** Given `CLAUDE.md.example`, when inspected, then it imports `AGENTS.md`
   (via `@AGENTS.md` or an equivalent the binding documents) and adds no
   authority tier — it defers to the `ADR-0004` hierarchy.
- **SC-10.** Given the framework's own `CLAUDE.md` after the change, when
   inspected, then it imports the repository's `AGENTS.md` and Claude Code loads
   both (verifiable with `/context`).

### Skill discovery

- **SC-11.** Given the binding's skill-discovery mechanism, when applied to a
   consumer repository, then every skill in the framework's `skills/index.md`
   becomes invocable in Claude Code, sourced from the unchanged
   `skills/*/SKILL.md` files.
- **SC-12.** Given the skill-discovery mechanism, when its source and outputs are
   inspected, then it writes no `metadata.hermes.*`, `metadata.openclaw.*`, or
   other runtime dialect into any `skills/*/SKILL.md` (`ADR-0038` §5).
- **SC-13.** Given `claude plugin validate` is run against
  `integrations/runtimes/claude-code/`, when it completes, then it reports no
  errors (warnings on the source skills are permitted and recorded in the
  binding README; the pre-cleanup allowance ended when the `ADR-0038` Category 2
  work landed in #116 — source skills now carry only spec fields).

### The advisory hook

- **SC-14.** Given `hooks/hooks.json`, when inspected, then its hook invokes an
   existing framework gate script (`check-status.sh` or `lint:docs`) at a
   documented Claude Code lifecycle event, and the binding README states the hook
   is a local convenience that adds no enforcement the framework's CI does not
   already have.
- **SC-15.** Given the hook runs and the gate script exits non-zero, when the
   hook returns, then it surfaces the failure to the session without blocking it
   unconditionally — it is advisory, not a `deny`.

### Identity and attribution

- **SC-16.** Given `settings.fragment.json`, when inspected, then it sets the keys
   that make Claude Code emit the `Agent-Attribution:` trailer and a commit
   identity consistent with `ADR-0018` / `ADR-0029`, and the binding README shows
   how a consumer substitutes their own actor address.

### MCP

- **SC-17.** Given `.mcp.json.example`, when inspected, then it is a parameterised
   example carrying no real server credentials or endpoints, and the binding
   README states that an MCP server which would expand the framework's governance
   surface requires its own approved FS (`ADR-0039` §4).

### The report-only audit

- **SC-18.** Given `ca-runtime-audit.sh --help`, when it runs, then it prints
   usage naming every flag and environment variable it reads, and exits 0.
- **SC-19.** Given `ca-runtime-audit.sh` runs against a repository whose
   `.claude/` does not match the binding, when it completes, then it reports each
   divergence and **exits 0** in default mode; `--strict` exits non-zero when
   divergences exist.
- **SC-20.** Given `ca-runtime-audit.sh`'s source, when inspected, then it
   performs no mutation — it does not write `.claude/`, does not call a mutating
   `gh`/`git` operation, and is registered in `package.json` as a report-only
   script that the framework's CI does not run as a blocking check.

### The no-binding demonstration

- **SC-21.** Given a repository with `AGENTS.md`, `scripts/`, and `skills/` but no
   runtime binding installed, when the governed workflow is exercised end to end
   (per a documented procedure in `integrations/runtimes/README.md`), then it
   completes — spec-first, gate scripts, and skill guidance all function. The
   binding is a convenience, not a requirement.

### Documentation and registration

- **SC-22.** Given `scripts/README.md`, when inspected, then it cross-references
   `integrations/runtimes/` and states that binding executables are **not**
   Category 1 gates while non-blocking, citing `ADR-0015`'s Location invariant.
- **SC-23.** Given `INTEGRATION.md`, when inspected, then it contains no reference
   to a `packs/` path, and its Claude Code guidance points at
   `integrations/runtimes/claude-code/`.
- **SC-24.** Given `npm test`, when it runs, then the `test/FS-0030/` suites
   execute and pass, and `bash -n` succeeds on every shipped `.sh` file.

## Edge Cases

- **A consumer runs Claude Code without the plugin, using the `.claude/`
  fragment.** Both paths are supported; the binding README documents both and the
  audit checks whichever is present.
- **Source skills carry a runtime's dialect.** `claude plugin validate` can still
  warn if a consumer's runtime requires dialect fields; SC-13 permits warnings
  recorded in the binding README, and the framework's own source skills carry
  only spec fields since the `ADR-0038` Category 2 cleanup (#116).
- **A consumer has their own `.claude/settings.json` hooks.** The binding's hook
  fragment is additive; the README says how to merge rather than overwrite.
- **`claude` CLI is absent.** The audit and any validate step fail with an
  install hint, not a vacuous pass (`FS-0022` §6).
- **Bash 3.2** (macOS system bash): the shipped library uses no associative
  arrays, consistent with `scripts/README.md`.
- **A shallow clone.** Any gate script the hook invokes already handles this; the
  binding does not reintroduce the hazard.

## Out of Scope

- Any configuration for Hermes Agent, OpenClaw, Codex, Cursor, or Aider.
- Mutating a consumer's `.claude/`, git config, or any repository state from a
  shipped command.
- A marketplace listing or `marketplace.json`.
- `shellcheck` adoption as a gate (applies repo-wide; a separate decision).
- Changing `ADR-0004`'s precedence hierarchy or any accepted ADR's body.

## Dependencies

- `ADR-0039` accepted (done); `ADR-0038` accepted (done); this spec approved.
- `claude` CLI for `claude plugin validate` (advisory) and manual verification.
- `bats` and `rg` for the test suites.
- `AGENTS.md` present at the consumer repository root (`ADR-0004`).

## Rollout / Migration

1. `FS-0030` approved; `PLAN-0036` approved on merge with an `Approved-By:`
   trailer.
2. The binding lands with the framework as its first consumer: `.claude/` and
   `CLAUDE.md` adopt it, `lint:integrations` widens, and the binding README
   records the `claude plugin validate` output.
3. `INTEGRATION.md` Claude Code guidance repoints at the binding.
4. Hermes, OpenClaw, and Codex bindings follow in their own FS/PLAN cycles,
   reusing this binding's skill and MCP portions.

## Observability

- `ca-runtime-audit.sh` prints a summary distinguishing "matches the binding"
  from "diverges" without parsing.
- The advisory hook announces which gate it ran and its result.

## Security / Privacy

- **Data handled:** repository configuration read from the caller's working
  directory; no credentials.
- **Threats considered:** a shipped hook presented as an enforcement control when
  the runtime treats it as advisory; instance data (actor addresses, MCP
  endpoints) baked into a vendored template.
- **Mitigations:** SC-8 forbids an **enforces** classification; SC-14/SC-15 keep
  the hook advisory; SC-5/SC-17 keep instance data out; SC-20 keeps the audit
  non-mutating and out of blocking CI.

## Open Questions

None blocking. Each has a stated default that implementation follows unless the
approving human directs otherwise:

- **Plugin `skills/` — copy, symlink, or a sync script?** *Default: a documented
  symlink for local use plus a sync script for CI/packaging*, so the source of
  truth stays `skills/*/SKILL.md`.
- **Does the framework's CI run `claude plugin validate` at all?** *Default: yes,
  advisory (non-blocking).* Promoting it to a merge gate is explicitly a separate
  Category 1 FS.
- **One combined binding doc, or split contract/hazards files?** *Default:
  one `README.md`* until it exceeds the size signal, then `references/`.
