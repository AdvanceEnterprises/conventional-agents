---
type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0052]
related_adrs: [ADR-0039, ADR-0038]
touches:
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
created: 2026-10-18
updated: 2026-10-18
---

# PLAN-0059: Implement FS-0052 — Hermes Agent runtime binding

## Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes `package.json`,
`.github/workflows/lint-docs.yml`, and `scripts/README.md` — reserved paths under
`ADR-0027` — so `check-status.sh` rule 6 requires a recorded human approval
regardless of how `FS-0052`'s `interfaces:` are framed. Approval is recorded as
an `Approved-By:` trailer on the commit that flips this plan (and `FS-0052`) to
`approved`, whose email differs from the commit author's (`ADR-0026`). Until that
record exists this plan is `draft` and must not be executed.

**Once the approval commit lands, this file must not be edited again before
merge.** Under `ADR-0026` any commit touching it *after* the approval record
invalidates that approval and requires a fresh recorded act; draft review
revisions before the approval commit are permitted. The implementing PR opens
separately, after this one merges — never inside it.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0052
* Related ADR ID(s): ADR-0039 (governing), ADR-0038 (skill source contract),
  ADR-0004, ADR-0007, ADR-0015, ADR-0018, ADR-0029, ADR-0032, ADR-0037
  (constraining)
* Issue / PR Reference: implementation PR linked on merge

## 2. Scope of Change

**This change WILL:**

* Create the Hermes Agent binding under `integrations/runtimes/hermes-agent/`: a
  bundle/plugin manifest, a `SOUL.md.example` importing `AGENTS.md`, a
  parameterised `config.fragment.yaml` (identity/attribution + MCP), a
  skill-discovery mechanism sourced from unchanged `skills/*/SKILL.md`, an
  advisory shell hook, a parameterised `mcp_servers.fragment.yaml`, and a
  report-only `ca-hermes-audit.sh` with its `lib/`.
* Classify every shipped artefact as **provisions** or **documents** in the
  binding README, with the operational hazards each works around.
* Document (not configure) Hermes's `cron` / `webhook` / `moa` / `kanban`
  primitives and the `ADR-0007` line they sit behind.
* Update `integrations/runtimes/README.md` to mark Hermes Agent `available`.
* Register `ca-hermes-audit` in `package.json` as a report-only script; add the
  `scripts/README.md` cross-reference; verify `lint:integrations` covers the
  Hermes markdown.
* Repoint `INTEGRATION.md`'s Hermes guidance and `docs/ARC42.md` at the binding.
* Add `test/FS-0052/` bats coverage for SC-1..SC-22, exercisable against
  fixtures without a live `hermes` CLI where possible.

**This change will NOT:**

* Ship any OpenClaw, Codex, Cursor, or Aider configuration.
* Define a neutral runtime contract (that is the `ADR-0039` §5 review checkpoint,
  resolved by the Head Architect after this lands — not by this plan).
* Wire `ca-hermes-audit` (or any binding command) into a merge-blocking CI job.
* Edit any `skills/*/SKILL.md` (base-spec since the `ADR-0038` Category 2
  cleanup).
* Add a scheduler, monitor, `schedule:` trigger, or status-writing hook, or wire
  any Hermes `cron`/`webhook`/`moa`/`kanban` trigger.
* Touch `integrations/github-issues-projects.md`, the `FS-0029` executable layer,
  or the Claude Code binding (`FS-0030`).

## 3. Tests Driving This Change

* Test file(s), under `test/FS-0052/`:

  * `runtime-surface.bats` — SC-1..SC-3
  * `binding-shared.bats` — SC-4..SC-7
  * `anchor-and-skills.bats` — SC-8..SC-11
  * `hook-and-identity.bats` — SC-12..SC-15
  * `audit.bats` — SC-16..SC-18
  * `primitives-and-registration.bats` — SC-19..SC-22
  * `sync-and-acceptance.bats` — SC-23..SC-27

* Target tests (names carry their SC identifier per the framework testing guide;
  each SC maps to at least one test):

  * `test_sc_1__hermes_marked_available`
  * `test_sc_4__no_instance_data`
  * `test_sc_5__no_orchestration`
  * `test_sc_7__classification_table_no_enforces`
  * `test_sc_8__soul_imports_agents`
  * `test_sc_10__skills_discoverable`
  * `test_sc_11__no_dialect_written_back`
  * `test_sc_12__hook_advisory`
  * `test_sc_16__audit_help_exits_0`
  * `test_sc_17__audit_divergence_exit_codes`
  * `test_sc_18__audit_non_mutating`
  * `test_sc_19__primitives_documented_not_wired`

  The named tests are representative; the file-group SC ranges above are the
  full coverage contract — each SC in a range maps to at least one test in its
  `*.bats` file.

## 4. Files to Be Modified

As declared in `touches:` above. New trees: `integrations/runtimes/hermes-agent/`,
`test/FS-0052/`. Modified: `integrations/runtimes/README.md`,
`integrations/README.md`, `INTEGRATION.md`, `docs/ARC42.md`, `package.json`,
`scripts/README.md`, `.github/workflows/lint-docs.yml`, the two docs READMEs,
`CHANGELOG.md`.

## 5. Implementation Steps (High-Level)

1. Scaffold `integrations/runtimes/hermes-agent/README.md` and update the
   `integrations/runtimes/README.md` index (Hermes Agent → `available`).
2. Build the report-only `ca-hermes-audit.sh` and `lib/` first, test-driven
   against fixtures (SC-16..SC-18, SC-6).
3. Build the anchor-file, config-fragment, MCP-example, and `SOUL.md.example`
   artefacts; write the binding README with the classification table and the
   primitives note (SC-7, SC-19).
4. Build the skill-discovery mechanism; confirm `SC-11` (no dialect written
   back to source).
5. Build the advisory shell hook; confirm it is advisory, not `deny` (SC-12,
   SC-13).
6. Document the framework's own adoption (the maintainer's `~/.hermes/` profile
   applies the fragment); record the audit output in the binding README.
7. Register the npm script; add the `scripts/README.md` cross-reference; verify
   `lint:integrations` coverage.
8. Repoint `INTEGRATION.md` and `docs/ARC42.md`.
9. Write and run all bats suites; run `npm test`, `check:status`, and
   `lint:docs`.
10. CHANGELOG consumer-framed entry; docs README index rows to `implemented` on
    completion per `workflows/document-lifecycle.md`.

## 6. Constraints and Guardrails

* Spec constraints: `FS-0052` Non-Goals and Out of Scope.
* ADR constraints:
  * `ADR-0039` §1 — binding executables are binding content only while
    non-blocking; §3 — setup, not workflow the runtime executes; §5 — Hermes is
    its own binding, not a shared one with OpenClaw.
  * `ADR-0038` §5 — no runtime dialect in `skills/*/SKILL.md`.
  * `ADR-0007` — no orchestration.
  * `ADR-0032` — no instance data; `ADR-0033`/`FS-0024` — caller-relative
    resolution.
  * `ADR-0037` §6 — provisions/documents classification; no overclaim.
* Architecture constraints: `integrations/` is the only home for bindings;
  gates live in `scripts/`.

## 7. Risks and Edge Cases

* **A binding command drifts into a blocking CI check.** Mitigation: SC-18 and
  the `scripts/README.md` cross-reference; reviewers hold the line (`ADR-0039`
  §1).
* **The advisory hook is read as enforcement** by a consumer. Mitigation:
  SC-12/SC-13 require the README to say plainly it is not.
* **Skill-discovery writes the `metadata.hermes.*` dialect back to source.**
  Mitigation: SC-11; the mechanism reads `skills/` and writes only under the
  binding's `skills/` copy.
* **The `hermes` CLI surface changes** — the framework does not control it.
  Mitigation: the audit is report-only; the binding README records the version
  it was verified against.
* **Hermes's `cron`/`webhook` primitives tempt a consumer to wire a trigger.**
  Mitigation: SC-5 and SC-19 document-not-configure; the README states the
  `ADR-0007` line explicitly.

## 8. Validation

* Tests expected to pass: all `test/FS-0052/` suites; `npm test`; `npm run
  check:status`; `npm run lint:docs`; `npm run lint:integrations`; `bash -n` on
  shipped scripts.
* Manual checks: `ca-hermes-audit.sh` against the maintainer's `~/.hermes/`
  profile (report-only); a Hermes session shows `SOUL.md` importing `AGENTS.md`;
  confirm no `schedule:` trigger or status-writing hook exists under
  `integrations/runtimes/` (grep-checkable).

## 9. Explicit Non-Changes

* `ADR-0004` precedence hierarchy.
* `skills/*/SKILL.md` content.
* The GitHub substrate binding and `FS-0029` executable layer.
* The Claude Code binding (`FS-0030`).
* Any accepted ADR body.
* Any Hermes `cron`/`webhook`/`moa`/`kanban` trigger.

## 10. Readiness Check

* [ ] FS-0052 is approved with the interface surface above
* [ ] Tests exist or are clearly defined — §3, one per Success Criterion
* [ ] Scope is the Hermes Agent binding only — no other runtime
* [ ] **Human approval required.** `touches:` includes reserved paths
      (`package.json`, `.github/workflows/`, `scripts/README.md`), so
      self-approval is impossible by construction. `approved_by:` and its
      `Approved-By:` trailer are recorded at approval time, not before.

## Declaration

I affirm that this plan reflects the full intended scope of implementation for
`FS-0052`; no additional behaviour will be introduced; any deviation requires
revising this plan before coding.
