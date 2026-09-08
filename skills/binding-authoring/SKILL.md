---
name: binding-authoring
description: "Selecting and authoring a binding under integrations/ — deciding whether a platform needs one, mapping the six substrate capabilities or the runtime setup-requirement set, following ADR-0024's binding-first ordering rule, classifying any shipped executables as enforces/provisions/reports, and writing grep-shape conformance tests. Use when a consumer's platform has no binding, when reviewing a proposed binding, or when extending the GitHub reference binding."
license: MIT
---

# Binding Authoring Skill

A **binding** maps the framework onto one platform. `integrations/` holds two
kinds — substrate bindings (`ADR-0024`) and runtime bindings (`ADR-0039`) — and
`integrations/github-issues-projects.md` plus `integrations/github/` is the
worked example this skill draws from throughout.

## Source Documents

- `integrations/README.md` — the six capabilities, the two binding kinds, the "Writing a binding" rule
- `integrations/github-issues-projects.md` — the reference substrate binding (capability mapping, §7 non-guarantees)
- `integrations/github/README.md` — the reference executable layer (the enforces/provisions/reports table)
- `docs/decisions/ADR-0024-platform-neutral-core-with-shipped-bindings.md` — the two-layer model and the ordering rule
- `docs/decisions/ADR-0037-executable-github-binding.md` — the four boundaries constraining a binding's executables
- `docs/decisions/ADR-0039-agent-runtime-integration-bindings.md` — runtime bindings; §2 requirement set, §5 stage order
- `docs/decisions/ADR-0007.md` (positioning), `ADR-0032` (instance data), `ADR-0015` (Location invariant)

## When to Use

- A consumer's work-tracking platform or agent runtime has no binding under
  `integrations/`, and you are deciding whether to write one.
- You are reviewing a proposed binding for conformance before it merges.
- You are extending the GitHub reference binding (declarative doc or executable
  layer).
- You need the conformance-test shape for a binding.

Not for *using* an existing binding as a consumer — that is
`skills/framework-consumer-integration/SKILL.md`.

## Gates That Bind Here

Summarised, not restated. Canonical texts are the ADRs above.

- **Standards only, never orchestration (`ADR-0007`).** A binding ships one-shot,
  idempotent commands a caller invokes. It never ships a scheduler, daemon,
  watcher, or `schedule:` trigger that mutates a work item, and never a board
  reconciler.
- **The Location invariant (`ADR-0015`).** Anything that can fail a pull request
  is a Category 1 gate: it lives in `scripts/`, needs an approved FS and PLAN,
  and is listed in `scripts/README.md`. A binding executable is binding content
  *only while it is non-blocking*.
- **No instance data (`ADR-0032`).** Parameterised templates and `*.example.yml`
  shapes only. Project numbers, node IDs, org names, secret names, and
  org-specific labels come from the caller.
- **The merge gate (`ADR-0012`)** is inherited by every shipped command: verify
  `gh auth status` (or the runtime equivalent) before each operation.

## Step 1 — Do you need a binding at all?

Read the registry in `integrations/README.md` § "Available bindings".

| Situation | Do this |
| --- | --- |
| Your platform is listed | Use that binding. No authoring needed. |
| Not listed, and you can author one | Continue to Step 2. |
| Not listed, and you cannot author one now | Use the binding's documented fallbacks (for GitHub substrate: the `type/*` label namespace or `[type]` title prefix), and open a work item requesting the binding. A missing binding is a gap to record, not a blocker to route around. |

Then decide **which kind**:

- **Substrate binding** — maps the six work-item capabilities onto a
  work-tracking platform (Notion, Jira, Linear). Lives at
  `integrations/<platform>.md`, or `integrations/<platform>/` if it ships
  templates and executables. The reference binding shipped with `ADR-0024`
  itself; a new one is normative exported content authored under that ADR's
  rules. An **executable layer** for it needs its own approved FS — `FS-0029`
  was that for GitHub (`ADR-0037` §3).
- **Runtime binding** — maps the framework's setup requirements onto one agent
  runtime's configuration surface (Codex, Hermes Agent, OpenClaw). Lives at
  `integrations/runtimes/<runtime>/`, and **needs one FS per binding**
  (`ADR-0039` §5). The first, Claude Code, is `FS-0030` (in progress).

## Step 2a — Substrate binding: map the six capabilities

`integrations/README.md` is the current statement of what each capability is. A
substrate **conforms** when the binding maps all six onto named mechanisms, with
**none marked deferred or planned**.

| # | Capability | GitHub mechanism (the worked example) | Enforcement on GitHub |
| --- | --- | --- | --- |
| 1 | Work item | Issue | Native |
| 2 | Type (attributable) | Projects v2 single-select `Issue Type` | Convention + detection |
| 3 | Phase | Projects v2 built-in `Status` | Native |
| 4 | Parked state | `question` label | Convention + detection |
| 5 | Activity record | Issue comment timeline | Partial — events are append-only, comments are not |
| 6 | Enumerability | `gh project item-list`, Issues API, GraphQL | Native |

**State enforcement honestly, per capability.** Capabilities 2, 4, and 5 are
about *attributability*, not *prevention*. A binding that claims its platform
*enforces* a convention the platform can only *detect* is **non-conforming**. The
reference binding's §7 ("What This Binding Does Not Guarantee") is the model:
name every gap in the same voice as the mapping.

**Enumerability is the load-bearing trigger.** A substrate may also offer event
notification, but per `ADR-0028` the reconciler reading current state on demand
is the correctness guarantee and the event is only an optimisation. A binding
whose *only* trigger mechanism is events does not conform. State the scheduler's
reliability characteristics — a scheduler that silently stops is an outage, not a
delay (GitHub Actions disables a schedule after 60 days of inactivity; say so).

## Step 2b — Runtime binding: map the setup-requirement set

The requirements are fixed by `ADR-0039` §2 — every one is already a framework
rule:

| Requirement | Framework source |
| --- | --- |
| Point the runtime at the canonical `AGENTS.md` | `ADR-0004` |
| Run the framework's gate scripts at the runtime's pre-commit / pre-PR point | `scripts/`, `FS-0024` |
| Make `skills/` discoverable in the runtime's skill system, applying the runtime dialect at sync time | `ADR-0038` §5 |
| Set commit identity and the `Agent-Attribution:` trailer | `ADR-0018` / `ADR-0029` / `ADR-0036` |
| Optionally, MCP-server configuration | `ADR-0039` §4 |

A runtime binding states, per requirement, whether the runtime **enforces** it,
the binding **provisions** it once, or the binding only **documents** it. A
runtime binding command **never enforces** (`ADR-0039` §1).

## Step 3 — The ordering rule (`ADR-0024`)

This is the constraint most often missed in review.

- **The binding is written first and in full.** No stubs. No capability marked
  "deferred". If you cannot map a capability, the binding is not ready.
- **The neutral core is extracted from bindings — it never forecasts them.** No
  capability may be added to `integrations/README.md` that no shipped binding
  implements.
- **No generalisation from a single binding.** With one binding, there is nothing
  to generalise. The GitHub executable layer added *nothing* to the six
  capabilities precisely because it was the only one (`ADR-0037` §5). A second
  binding is what makes a generalisation legitimate — extract it *then*, from two
  working implementations.

## Step 4 — If the binding ships executables (`ADR-0037` envelope)

Applies to both kinds. The binding becomes a directory: the normative document
stays, and executables live beneath it, subordinate to it — an executable that
disagrees with the mapping is a defect in the executable.

- **Classify every command as `enforces`, `provisions`, or `reports`** in the
  binding's README, one row per command (`ADR-0037` §6, `FS-0029` SC-28). A
  substrate command *may* enforce (a fail-closed submodule init does); a runtime
  command never does.
- **Must not ship:** a scheduler, daemon, watcher, `schedule:` trigger that
  mutates a work item, or a reconciler that sets fields. Reporting drift is
  enumeration (capability 6); *fixing* it is the consumer's act.
- **The bright line:** anything wired into a merge-blocking CI job is a Category 1
  gate — it moves to `scripts/`, gets an FS + PLAN, a `package.json` entry, and a
  `scripts/README.md` row. A read-only audit is safe to run from an
  *informational* job; ship a `--strict` flag but do not wire it into your own
  pull-request gate.
- **Caller-relative resolution:** resolve the target from
  `git rev-parse --show-toplevel`, with an explicit `CA_TARGET_REPO` override
  (`FS-0024` / `ADR-0033`). Never read a path containing a `vendor/` segment.
- **No credential in logs.** Ever. Scope credential rewrites narrowly; keep the
  token process-scoped.
- **Bash 3.2 baseline** (macOS system bash) — no associative arrays. Register
  each command as an npm script and cross-reference it from `scripts/README.md`
  so a reader auditing every shipped executable finds it.

## Step 5 — Conformance tests

Tests exercise the binding **against fixtures, not the live platform API**. The
suites under `test/FS-0029/` (`label-provision.bats`, `board-audit.bats`,
`submodule-init.bats`) stub `gh`; `test/FS-0016/vendor-boundary.bats` is the
grep-shape model for asserting a document's structure.

Grep-checkable signals to assert:

- The binding document maps all six capabilities (substrate) or all five
  requirements (runtime); none says "deferred" or "planned".
- Every shipped command appears in the enforcement-posture table.
- No platform product noun leaks into `integrations/README.md` (the neutral core
  stays neutral — `test/FS-0018/issue-lifecycle.bats` runs exactly this check
  against `FS-0018`'s body and is the model to copy).
- No file under the binding directory contains a `schedule:` trigger.
- No shipped script reads a `vendor/` path.

**State the honest limit.** Behaviour against the live API is verified by *using*
the commands, which is a weaker guarantee than the rest of the test corpus. Say
so in the binding README rather than implying the fixtures cover it.

## Example 1 — Check what is already bound, and what a platform provides

```bash
# What bindings exist, and of which kind?
sed -n '/## Available bindings/,/## The six/p' integrations/README.md

# The six capabilities you must map for a substrate binding:
grep -E '^### [0-9]\.' integrations/README.md

# The reference binding's honesty section — the model for your own §7:
sed -n '/## 7\./,/^## /p' integrations/github-issues-projects.md
```

## Example 2 — A grep-shape conformance test for a new substrate binding

Modelled on `test/FS-0016/vendor-boundary.bats`. Save as
`test/<FS-id>/binding-conformance.bats`, substituting your binding's governing
FS id — or use the `test/integrations/` home for a purely declarative substrate
binding with no governing FS (only an executable layer earns its own FS, as
`FS-0029` did for GitHub):

```bash
#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() { REPO_ROOT="$(repo_root)"; BINDING="$REPO_ROOT/integrations/notion.md"; }

@test "binding maps all six capabilities with none deferred" {
  assert_file_exists "$BINDING"
  for cap in "Work item" "Type" "Phase" "Parked state" "Activity record" "Enumerability"; do
    assert_file_contains "$BINDING" "$cap"
  done
  ! grep -Eiq 'deferred|planned|TODO' "$BINDING"
}

@test "binding states enforcement posture per capability" {
  # Every capability row says "enforces" or "attributable"/"detection"
  run grep -cE 'enforce|attributab|detection' "$BINDING"
  [ "$output" -ge 6 ]
}

@test "neutral core gains no capability this binding does not implement" {
  run grep -cE '^### [0-9]\.' "$REPO_ROOT/integrations/README.md"
  [ "$output" -eq 6 ]
}
```

## Checklist

- [ ] Checked the `integrations/README.md` registry — no binding already covers this platform
- [ ] Decided substrate vs runtime; runtime binding has its own FS
- [ ] All six capabilities (or five requirements) mapped to named mechanisms
- [ ] Nothing marked "deferred" or "planned"
- [ ] Enforcement stated honestly per capability — no claim the platform cannot back
- [ ] Scheduler reliability characteristics stated
- [ ] No capability added to the neutral core that only this binding implements
- [ ] Any executable classified `enforces` / `provisions` / `reports`
- [ ] No scheduler, watcher, or work-item-mutating trigger shipped
- [ ] Nothing that can fail a PR — those go to `scripts/` with an FS
- [ ] Caller-relative resolution; no `vendor/` path read; no credential in logs
- [ ] No instance data — parameterised templates and `*.example` only
- [ ] Grep-shape conformance test added; honest-limit statement in the README
- [ ] Row added to `integrations/README.md` and `CHANGELOG.md` (`integrations/` is exported surface)

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Claiming the platform *enforces* a convention it can only *detect* | Non-conforming binding; a consumer buys a guarantee that is not there |
| Marking a capability "deferred" to merge sooner | `ADR-0024` forbids stub bindings; the gap propagates into every consumer |
| Adding a capability to the neutral core "for the next binding" | Forecasting, not generalising — the exact `packs/` failure `ADR-0024` exists to prevent |
| Shipping a `schedule:` trigger that moves a work item | Crosses `ADR-0007`'s orchestration line |
| Wiring a binding audit into a pull-request gate | It is now a Category 1 gate in the wrong directory, with no FS |
| A command that reports drift *and* fixes it | The fix is the consumer's act under the consumer's policy |
| Hardcoding a project number or org name in a shipped file | `ADR-0032` violation; the next adopter's copy is wrong |
| Testing against the live API | Non-deterministic; fixtures are the contract, live use is the weaker check |

## Related Skills

- `skills/framework-consumer-integration/SKILL.md` — the consumer side: adopting an existing binding
- `skills/document-lifecycle/SKILL.md` — a runtime binding, and a substrate executable layer, each need an FS
- `skills/testing-guide/SKILL.md` — writing the bats fixtures a binding's conformance tests use
- `skills/framework-health-audit/SKILL.md` — `check:status` rule 8 verifies the paths a binding document names

## Prohibitions

- **Do NOT** merge a binding that leaves any capability unmapped or "deferred".
- **Do NOT** claim enforcement where the platform provides only detection.
- **Do NOT** add a capability to `integrations/README.md` that no shipped binding implements.
- **Do NOT** ship a scheduler, watcher, or work-item-mutating trigger in a binding.
- **Do NOT** place an executable that can fail a pull request under `integrations/` — it belongs in `scripts/` with an FS.
- **Do NOT** put instance data (project IDs, org names, secrets) in a shipped file.
