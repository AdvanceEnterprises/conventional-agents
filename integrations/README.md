# Substrate Bindings

A **binding** maps the framework's workflow-substrate capabilities onto one platform.
`ADR-0024` establishes the two-layer model: a platform-neutral core naming what a
substrate must provide, and bindings naming the mechanisms that provide it.

**This document is the current statement of the six capabilities.** ADRs record why
they are what they are; this records what they are (`ADR-0030`). If this section and an
individual ADR appear to disagree, check for a later ADR revising that capability before
concluding either is wrong.

## Available bindings

| Binding | Platform | Status |
| --- | --- | --- |
| [`github-issues-projects.md`](./github-issues-projects.md) | GitHub Issues + Projects v2 | Reference binding; the substrate this repository runs on |
| [`github/README.md`](./github/README.md) | GitHub binding executables | Executable provisioning and audit layer; mechanisms only |
| [`hermes-kanban.md`](./hermes-kanban.md) | Hermes kanban | **Draft candidate, not yet conforming**; Type attribution and activity retention unproven |

## The six capabilities

A substrate conforms when it provides all six. A binding maps each onto a named
mechanism and states, per capability, whether that mechanism **enforces** the property
or merely makes violations **attributable**.

### 1. Work item

An item that can exist before any FS, PLAN, or ADR, carrying a free-text brief. It is
the entry point for all governed work.

### 2. Type

A single-valued attribute from a closed set, keying the applicable safety gate, **whose
modification is attributable** — so that a change by an agent is detectable after the
fact.

### 3. Phase

A single-valued attribute from a closed set, tracking workflow position.

### 4. Parked state

A state that suppresses agent action while set, and whose presence an agent can read
before acting.

### 5. Activity record

Ordered, attributable entries. Entries recording **state transitions** must be
non-retractable; entries recording **agent commentary** need not be.

### 6. Enumerability

Work items and their attributes readable **on demand**, so a reconciler can evaluate
current state.

A substrate **may** additionally offer event notification. Events reduce latency and are
never the sole trigger: per `ADR-0028`, the reconciler is the correctness guarantee and
the event is an optimization. A binding whose only trigger mechanism is event
notification does not conform.

## Detection over prevention

Capabilities 2, 4, and 5 are stated as *attributability* rather than *enforcement*, and
this is deliberate.

The first binding written under `ADR-0024` established that GitHub can enforce none of
them: Projects v2 has no per-field access control, labels carry no per-label permission,
and comments are deletable by their author. An earlier draft required a type attribute
"which agents cannot modify" — a property no known work-tracking platform supplies.

The framework therefore requires that agent deviation be **visible**, not that it be
**impossible**. A binding claiming prevention where its platform offers only detection is
non-conforming, and must say which of the two it provides.

The merge gate (`ADR-0012`) is the exception: branch protection genuinely enforces it.
That asymmetry is a reasonable explanation for why merge is the rule the framework made
non-overridable, and the others are rules of conduct backed by audit.

## Writing a binding

Per `ADR-0024`'s ordering rule, a binding is written **first and in full**, and any
generalization is extracted from it afterwards. Specifically:

- No binding may be merged as a stub.
- No core capability may be added that no existing binding implements.

The core generalizes over shipped bindings; it never forecasts them. A binding must map
all six capabilities with none marked deferred or planned, and must state its
scheduler's reliability characteristics — under `ADR-0028` the reconciler carries
correctness, so a scheduler that silently stops is an outage rather than a delay.

## Two kinds of binding

`integrations/` holds two:

- **Substrate bindings** map the six work-item capabilities above onto a
  work-tracking platform (`ADR-0024`). `integrations/<substrate>.md` or, when the
  binding ships templates and executables, `integrations/<substrate>/` —
  `github-issues-projects.md` is the reference.
- **Runtime bindings** map the framework's setup requirements — anchor-file
  wiring (`ADR-0004`), gate-script execution, skill discovery (`ADR-0038`),
  commit identity and the `Agent-Attribution:` trailer, and optionally MCP
  configuration — onto one agent runtime's configuration surface.
  `integrations/runtimes/<runtime>/`, governed by `ADR-0039` and one FS per
  binding. The first is Claude Code (`FS-0030`).

`ADR-0037`'s envelope applies to both: a binding directory may ship parameterised
templates and executables; an executable that provisions or reports is binding
content, but any executable wired into a merge-blocking CI job is a Category 1
gate (`ADR-0015` Location invariant) and lives in `scripts/`.

## Related

- `ADR-0024` — the two-layer model and the ordering rule
- `ADR-0028` — level-triggered reconciliation; amends capability 6
- `FS-0018` — the work item lifecycle these capabilities support
- `ADR-0012` — the merge gate, the one rule a substrate can enforce
