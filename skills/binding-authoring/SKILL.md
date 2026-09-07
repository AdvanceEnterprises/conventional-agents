---
name: binding-authoring
description: "Guides agents through writing substrate and runtime bindings for conventional-agents — the six capabilities, the ordering rule, and the envelope."
license: MIT
---

# Binding Authoring Skill

A **binding** maps the conventional-agents framework's workflow-substrate
capabilities onto one platform, or its setup requirements onto one agent
runtime's configuration surface. This skill encodes how to write one correctly:
what a binding must contain, in what order, and how to stay inside the
governance envelope.

## Source Documents

- `integrations/README.md` — the current statement of the six capabilities and the two binding kinds
- `docs/decisions/ADR-0024-*.md` — the two-layer model and the ordering rule
- `docs/decisions/ADR-0037-executable-github-binding.md` — the executable-layer envelope
- `docs/decisions/ADR-0039-agent-runtime-integration-bindings.md` — runtime bindings
- `docs/decisions/ADR-0038-agent-skills-as-a-profiled-upstream-standard.md` — skill dialect rules
- `docs/decisions/ADR-0028-*.md` — level-triggered reconciliation (capability 6)
- `docs/decisions/ADR-0015-*.md` — the Location invariant (Category 1 vs binding content)
- `docs/specifications/FS-0030-claude-code-runtime-binding.md` — the first runtime binding, as worked example

## When to Use

- Writing a new substrate binding (`integrations/<substrate>.md` or `integrations/<substrate>/`)
- Writing a new runtime binding (`integrations/runtimes/<runtime>/`)
- Reviewing a binding PR for conformance
- Extending an existing binding with an executable layer
- Deciding whether a proposed capability belongs in the core or in a binding

## The two binding kinds

| Kind | Maps | Home | Governed by |
| --- | --- | --- | --- |
| Substrate binding | the six work-item capabilities onto a work-tracking platform | `integrations/<substrate>.md` or `integrations/<substrate>/` | `ADR-0024`, `ADR-0028`, `ADR-0037` |
| Runtime binding | setup requirements (anchor file, gates, skills, commit identity, MCP) onto one agent runtime | `integrations/runtimes/<runtime>/` | `ADR-0039`, one FS per binding |

## The six capabilities (substrate bindings)

A substrate conforms when it provides all six. A binding maps each onto a named
mechanism and states, per capability, whether that mechanism **enforces** the
property or merely makes violations **attributable**:

1. **Work item** — an item that can exist before any FS, PLAN, or ADR, carrying a free-text brief.
2. **Type** — a single-valued attribute from a closed set, keying the applicable safety gate, whose modification is attributable.
3. **Phase** — a single-valued attribute from a closed set, tracking workflow position.
4. **Parked state** — a state that suppresses agent action while set, readable before acting.
5. **Activity record** — ordered, attributable entries; state-transition entries non-retractable, commentary entries need not be.
6. **Enumerability** — work items and attributes readable on demand, so a reconciler can evaluate current state.

A substrate **may** additionally offer event notification. Events reduce latency
and are never the sole trigger: per `ADR-0028`, the reconciler is the
correctness guarantee and the event is an optimization. A binding whose only
trigger mechanism is event notification does not conform.

## Detection over prevention

Capabilities 2, 4, and 5 are stated as *attributability* rather than
*enforcement*, deliberately. Most platforms cannot enforce them (GitHub
Projects v2 has no per-field access control, labels carry no per-label
permission, comments are deletable by their author). The framework requires
that agent deviation be **visible**, not **impossible**. A binding claiming
prevention where its platform offers only detection is non-conforming and must
say which of the two it provides.

The merge gate (`ADR-0012`) is the exception: branch protection genuinely
enforces it. That asymmetry explains why merge is the one non-overridable rule.

## The ordering rule (ADR-0024)

A binding is written **first and in full**; any generalization is extracted from
it afterwards:

- No binding may be merged as a stub.
- No core capability may be added that no existing binding implements.

The core generalizes over shipped bindings; it never forecasts them. A binding
must map all six capabilities with none marked deferred or planned, and must
state its scheduler's reliability characteristics — under `ADR-0028` the
reconciler carries correctness, so a scheduler that silently stops is an outage
rather than a delay.

## The envelope (ADR-0037, ADR-0015)

A binding directory may ship parameterised templates and executables. An
executable that **provisions or reports** is binding content. But any executable
wired into a **merge-blocking CI job** is a Category 1 gate under `ADR-0015`'s
Location invariant and lives in `scripts/`, not `integrations/`.

The executable layer is intentionally not a scheduler or a reconciler. It does
not create or move work items, change project fields, or start itself. Consumer
policy may invoke a command explicitly from CI or an operator shell.

## Runtime bindings (ADR-0039)

A runtime binding maps the framework's setup requirements onto one agent
runtime's configuration surface:

- **Anchor-file wiring** (`ADR-0004`) — how the runtime reads the canonical `AGENTS.md`
- **Gate-script execution** — how the framework's existing gate scripts run at a runtime lifecycle event (local, advisory — never a new gate)
- **Skill discovery** (`ADR-0038`) — how `skills/*/SKILL.md` become discoverable, sourced unchanged; runtime dialects (`metadata.<runtime>.*`) are applied by the binding at sync time, never committed to source
- **Commit identity and the `Agent-Attribution:` trailer** (`ADR-0018` / `ADR-0029`)
- **MCP configuration** — parameterised, as an example, never a hardcoded credential

Each runtime binding gets its own FS/PLAN (`ADR-0039` §5). The first is Claude
Code (`FS-0030`); its plugin layout is the most reusable starting point for the
Hermes, OpenClaw, and Codex bindings that follow — the *skill and MCP* portions
carry over even though hooks and anchor-file wiring do not.

## Procedure

1. **Read the governing ADR(s) first.** Substrate: `ADR-0024` + `ADR-0028` + `ADR-0037`. Runtime: `ADR-0039` + `ADR-0038` + `ADR-0004` + `ADR-0018`/`ADR-0029`.
2. **Check for an existing binding of the same kind.** The reference substrate binding is `integrations/github-issues-projects.md`; the executable layer is `integrations/github/`; the first runtime binding is `integrations/runtimes/claude-code/` (per `FS-0030`). Extend rather than duplicate.
3. **Map all six capabilities** (substrate) or all five setup requirements (runtime) — none deferred, none planned.
4. **State enforcement posture per capability**: enforces or attributable — never claim prevention the platform cannot supply.
5. **State the scheduler's reliability characteristics** (substrate) — the reconciler carries correctness.
6. **Keep executables in the envelope**: provisioning/reporting commands are binding content; merge-blocking gates live in `scripts/`.
7. **Verify** with the repo's check command (`npm run check:status`), then open a draft PR.

## Runnable examples

**Example 1 — audit an existing binding for conformance.** Read
`integrations/github-issues-projects.md` and check: does it map all six
capabilities? Does each capability state enforces-vs-attributable? Does it name
a scheduler and its reliability characteristics? Does it claim prevention
anywhere GitHub offers only detection? The reference binding passes all four;
any new binding must too.

**Example 2 — review a runtime-binding PR.** For a proposed
`integrations/runtimes/<runtime>/`: (a) confirm the skills are sourced from
`skills/*/SKILL.md` unchanged with no `metadata.<runtime>.*` dialect committed
to source (`ADR-0038` rule 5); (b) confirm the hook is local and advisory, not a
new gate (`ADR-0039` §3); (c) confirm MCP config is a parameterised example
(`ADR-0039` §4); (d) confirm the binding has its own FS/PLAN (`ADR-0039` §5).

## Checklist

- [ ] All six capabilities (substrate) or all five requirements (runtime) mapped — none deferred
- [ ] Enforcement posture stated per capability: enforces vs attributable
- [ ] Scheduler reliability characteristics stated (substrate)
- [ ] No stub bindings; no core capability without a shipped implementation
- [ ] Executables: provisioning/reporting in `integrations/`, merge-blocking gates in `scripts/`
- [ ] Runtime bindings: skills sourced unchanged, dialect applied at sync time, MCP parameterised
- [ ] `npm run check:status` passes
- [ ] Draft PR, never a direct trunk commit

## Pitfalls

- **Writing the core before the binding** — the ordering rule forbids it. Generalize from shipped bindings, never forecast.
- **Claiming enforcement where the platform offers detection** — non-conforming. Say which of the two you provide.
- **Event-only triggers** — a binding whose only trigger is event notification does not conform (`ADR-0028`).
- **Scheduler silence** — a scheduler that silently stops is an outage, not a delay; state its reliability characteristics.
- **Dialect in source skills** — `metadata.hermes.*` (or any runtime dialect) never belongs in `skills/*/SKILL.md`; the binding applies it at sync time.
- **Gates in the binding directory** — a merge-blocking CI job is Category 1 (`ADR-0015`) and lives in `scripts/`.
- **Stub bindings** — a binding merged as a stub violates the ordering rule; write it first and in full.

## Related Skills

- `skills/framework-consumer-integration/SKILL.md` — how host projects consume bindings
- `skills/document-lifecycle/SKILL.md` — FS/PLAN/ADR lifecycle for the binding's governing documents
- `skills/git-gh-workflow/SKILL.md` — branch, commit, and PR conventions for landing binding changes
