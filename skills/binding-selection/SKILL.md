---
name: binding-selection
description: "Guides agents through choosing the right binding for a task — substrate vs runtime, reference vs executable, and when to write a new one."
license: MIT
---

# Binding Selection Skill

The framework ships two kinds of binding — **substrate** (work-tracking
platforms) and **runtime** (agent runtimes) — and each kind has a reference
implementation plus, for GitHub, an executable layer. This skill encodes how to
pick the right one for the task at hand, and when the right answer is to write
a new binding instead of stretching an existing one.

## Source Documents

- `integrations/README.md` — the current statement of the six capabilities and the two binding kinds
- `integrations/github-issues-projects.md` — the reference substrate binding
- `integrations/github/README.md` — the executable layer for the GitHub binding
- `docs/decisions/ADR-0024-*.md` — the two-layer model and the ordering rule
- `docs/decisions/ADR-0039-agent-runtime-integration-bindings.md` — runtime bindings
- `docs/specifications/FS-0030-claude-code-runtime-binding.md` — the first runtime binding

## When to Use

- Starting any task that touches work items, project boards, or agent-runtime configuration
- Deciding whether a capability belongs in the core, a binding, or a script
- Onboarding a new platform or runtime
- Reviewing whether a proposed change should extend a binding or live elsewhere

## Decision tree

| Task | Binding to use |
| --- | --- |
| Work items, types, phases, boards on GitHub | `integrations/github-issues-projects.md` (reference substrate binding) |
| Provisioning labels, initialising submodules, auditing board drift | `integrations/github/` executable layer (`integrations/github/bin/gh-*.sh`) |
| Wiring the framework into Claude Code | `integrations/runtimes/claude-code/` once shipped (per `FS-0030` — **draft**, so the directory does not exist on trunk yet; until it lands, treat runtime guidance as the procedure to follow, not a shipped artifact) |
| Wiring the framework into Hermes, OpenClaw, or Codex | No binding yet — write one (`ADR-0039` §5, one FS/PLAN per binding) |
| A new work-tracking platform (Linear, Jira, …) | Write a substrate binding (`ADR-0024`) |
| A merge-blocking CI check | Not a binding — a Category 1 gate in `scripts/` (`ADR-0015`) |

## Substrate vs runtime

- **Substrate bindings** answer: *where do work items live, and how are they
  typed, phased, parked, recorded, and enumerated?* They map the six
  capabilities onto a work-tracking platform.
- **Runtime bindings** answer: *how does an agent runtime discover the
  framework's setup — anchor file, gates, skills, commit identity, MCP?* They
  map setup requirements onto one runtime's configuration surface.

The two are orthogonal. A consumer on GitHub + Claude Code uses the GitHub
substrate binding **and** the Claude Code runtime binding. A consumer on GitHub
with Hermes uses the GitHub substrate binding and (once written) the Hermes
runtime binding.

## Reference vs executable

The reference substrate binding (`integrations/github-issues-projects.md`) is
declarative: it maps capabilities onto mechanisms and ends in a setup
checklist. The executable layer (`integrations/github/`) turns the checklist
into repeatable commands:

| Command | Posture | What it does not claim |
| --- | --- | --- |
| `integrations/github/bin/gh-submodule-init.sh` | **enforces** fail-closed initialisation | It does not make a missing credential usable or mutate repository policy |
| `integrations/github/bin/gh-label-provision.sh` | **provisions** the framework vocabulary | It does not delete, recolour, or otherwise own consumer labels |
| `integrations/github/bin/gh-board-audit.sh` | **reports** project drift | It does not reconcile fields, items, Issues, or board membership |

The distinction is deliberate: a binding can provide a mechanism without
pretending that GitHub's permission model enforces a convention. The board
audit is safe to run from an informational CI job; use `--strict` only when a
consumer deliberately wants its own job to fail.

## When to write a new binding

Write a new binding when the platform or runtime is genuinely new — never to
work around a limitation of an existing one:

- **New substrate** (Linear, Jira, GitLab): write a new binding under `integrations/`
  mapping all six capabilities, per `ADR-0024`'s ordering rule — first and in
  full, never as a stub.
- **New runtime** (Hermes, OpenClaw, Codex): write
  `integrations/runtimes/<runtime>/` with its own FS/PLAN (`ADR-0039` §5).
- **New executable mechanism** for an existing binding: extend the binding's
  directory — provisioning/reporting commands are binding content.

Do **not** write a new binding when the task is a merge-blocking gate (that is
a `scripts/` Category 1 gate, `ADR-0015`), a one-off script (that is a
consumer-policy invocation of an existing command), or a capability no shipped
binding implements (the core never forecasts — `ADR-0024`).

## Procedure

1. **Name the substrate and the runtime** of the task. If both are already bound, use the existing bindings — do not reinvent.
2. **Check the executable layer** for a command that already does the job (`gh-submodule-init`, `gh-label-provision`, `gh-board-audit`).
3. **If the mechanism is missing**, decide: new binding (new platform/runtime), binding extension (new mechanism for a bound platform), or `scripts/` gate (merge-blocking).
4. **Verify** the chosen binding's claims against the platform's actual permission model — enforces vs attributable.
5. **Open a draft PR** for any new or extended binding; never commit directly to trunk.

## Runnable examples

**Example 1 — a consumer asks "how do I wire conventional-agents into my
Claude Code project?"** The planned answer is the Claude Code runtime binding
(`integrations/runtimes/claude-code/`, per `FS-0030`): it is specified to ship
the plugin layout, the `CLAUDE.md` anchor, the advisory hook, the settings
fragment, and the parameterised MCP example. The binding has **not shipped
yet** — `FS-0030` / `PLAN-0036` are draft — so do not point the consumer at
`integrations/runtimes/claude-code/` as if it existed; point them at the spec
and the work item instead, and do not hand-write a `CLAUDE.md` from memory as a
substitute procedure.

**Example 2 — a consumer asks "can the framework track work in Linear?"** No
substrate binding exists for Linear. The correct move is a new substrate
binding under `integrations/` mapping all six capabilities — written first and
in full (`ADR-0024`), with enforcement posture stated per capability, opened as
a draft PR. It is not a `scripts/` script and not a core change.

## Checklist

- [ ] Substrate and runtime of the task identified
- [ ] Existing binding checked before writing anything new
- [ ] Executable layer checked for an existing command
- [ ] New binding only for a genuinely new platform/runtime
- [ ] Merge-blocking gates routed to `scripts/`, not `integrations/`
- [ ] Enforcement posture matches the platform's real permission model
- [ ] Draft PR for new or extended bindings

## Pitfalls

- **Reaching for a new binding when an existing one covers the task** — the reference substrate binding and executable layer cover GitHub; the Claude Code runtime binding (once `FS-0030` ships) covers that runtime. Extend, don't duplicate.
- **Treating a binding as a script library** — a binding maps capabilities onto mechanisms; a one-off invocation is consumer policy, not binding content.
- **Putting a merge-blocking gate in a binding directory** — Category 1 gates live in `scripts/` (`ADR-0015`).
- **Assuming a runtime is bound because a sibling is** — Hermes and OpenClaw are close in shape but are two runtimes and will be two bindings (`ADR-0039`).
- **Forecasting the core** — a capability no shipped binding implements does not belong in the core (`ADR-0024` ordering rule).

## Related Skills

- `skills/binding-authoring/SKILL.md` — how to write a binding once you have decided to
- `skills/framework-consumer-integration/SKILL.md` — how host projects consume the framework
- `skills/git-gh-workflow/SKILL.md` — branch, commit, and PR conventions for landing binding changes
