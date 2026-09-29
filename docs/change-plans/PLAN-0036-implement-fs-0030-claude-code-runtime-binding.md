---
type: change-plan
role: implementer
language: bash
status: approved
related_specs: [FS-0030]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0039, ADR-0038]
touches:
  - integrations/runtimes/README.md
  - integrations/runtimes/claude-code/README.md
  - integrations/runtimes/claude-code/.claude-plugin/plugin.json
  - integrations/runtimes/claude-code/skills/**
  - integrations/runtimes/claude-code/hooks/hooks.json
  - integrations/runtimes/claude-code/.mcp.json.example
  - integrations/runtimes/claude-code/settings.fragment.json
  - integrations/runtimes/claude-code/CLAUDE.md.example
  - integrations/runtimes/claude-code/bin/ca-runtime-audit.sh
  - integrations/runtimes/claude-code/lib/**
  - integrations/README.md
  - INTEGRATION.md
  - docs/ARC42.md
  - .claude/settings.json
  - CLAUDE.md
  - package.json
  - scripts/README.md
  - .github/workflows/lint-docs.yml
  - test/FS-0030/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-05
updated: 2026-09-29
---

# PLAN-0036: Implement FS-0030 — Claude Code runtime binding

## Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes `package.json`,
`.github/workflows/lint-docs.yml`, and `scripts/README.md` — reserved paths under
`ADR-0027` — so `check-status.sh` rule 6 requires human approval regardless of
how `FS-0030`'s `interfaces:` are framed.

It is `status: approved`. Approval was given by Joey Clark and originally recorded
on the commit that flipped this status, carried by an `Approved-By:` trailer whose
email differs from the commit author's (`ADR-0026`). `#112`'s merge asserted this
transition but left the trailer and the status behind; issue `#122` detected the
drift and that change reconciled it. `FS-0030` is `approved` on the same commit,
so the spec-first gate (`guidelines/ROLE_CONTRACT.md`) is satisfied.

**Re-approved 2026-09-29.** The review-feedback commits that followed the original
record (`37a37ac`, `8006226`) edited this plan, and `ADR-0026` scopes an approval
to the content and `touches:` set that existed when it was given — so the original
record no longer covered the plan, and `check-status.sh` rule 6 correctly rejected
the branch. Joey Clark re-approved the plan as it now stands; the record is the
`Approved-By:` trailer on the most recent commit touching this file, whose email
differs from that commit's author. The `touches:` set is unchanged from trunk's, so
this re-approval covers the same reserved surface. Issue `#155` tracks the general
problem that agent feedback cycles invalidate an approval record this way.

**This file must not be edited again before merge.** Under `ADR-0026` any further
commit touching it invalidates this approval and requires a fresh recorded act.
**The implementing PR opens separately, after this one merges — never inside it.**

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0030
* Related ADR ID(s): ADR-0039 (governing), ADR-0038 (skill source contract),
  ADR-0004, ADR-0007, ADR-0015, ADR-0018, ADR-0029, ADR-0032, ADR-0037
  (constraining)
* Issue / PR Reference: #114 (work item); implementation PR linked on merge

## 2. Scope of Change

**This change WILL:**

* Create `integrations/runtimes/` with an index README and the substrate-vs-runtime
  distinction pointer.
* Create the Claude Code binding under `integrations/runtimes/claude-code/`: a
  plugin manifest, a skill-discovery mechanism sourced from unchanged
  `skills/*/SKILL.md`, an advisory `hooks.json`, a parameterised
  `.mcp.json.example`, a `settings.fragment.json` for identity/attribution, a
  `CLAUDE.md.example` importing `AGENTS.md`, and a report-only
  `ca-runtime-audit.sh` with its `lib/`.
* Classify every shipped artefact as **provisions** or **documents** in the
  binding README, with the operational hazards it works around.
* Have the framework adopt the binding: `.claude/settings.json` and `CLAUDE.md`.
* Widen `npm run lint:integrations` to `integrations/**/*.md`; register
  `ca-runtime-audit` in `package.json` as a report-only script; add the
  `scripts/README.md` cross-reference.
* Optionally run `claude plugin validate` **advisory** (non-blocking) in CI.
* Repoint `INTEGRATION.md`'s Claude Code guidance and `docs/ARC42.md` at the
  binding.
* Add `test/FS-0030/` bats coverage for SC-1..SC-24 that can be exercised against
  fixtures without a live `claude` CLI where possible.
* Document and test the no-binding demonstration (SC-21).

**This change will NOT:**

* Ship any Hermes Agent, OpenClaw, Codex, Cursor, or Aider configuration.
* Define a neutral runtime contract.
* Wire `claude plugin validate` (or any binding command) into a merge-blocking
  CI job.
* Edit any `skills/*/SKILL.md` (the ADR-0038 Category 2 cleanup is separate).
* Add a scheduler, monitor, `schedule:` trigger, or status-writing hook.
* Touch `integrations/github-issues-projects.md` or the FS-0029 executable layer.

## 3. Tests Driving This Change

* Test file(s):
  * `test/FS-0030/runtime-surface.bats` — SC-1..SC-4 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/binding-shared.bats` — SC-5..SC-8 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/anchor-and-skills.bats` — SC-9..SC-13 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/hook-and-identity.bats` — SC-14..SC-17 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/audit.bats` — SC-18..SC-20 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/no-binding.bats` — SC-21 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/docs-and-registration.bats` — SC-22..SC-24 `[planned; covered by §8 manual checks]`
  * `test/FS-0030/runtime-binding.bats` — consolidated shipped suite covering SC-18..SC-20 and parts of SC-24 `[shipped]`

## 4. Files to Be Modified

As declared in `touches:` above. New trees: `integrations/runtimes/`,
`test/FS-0030/`. Modified: `integrations/README.md`, `INTEGRATION.md`,
`docs/ARC42.md`, `.claude/settings.json`, `CLAUDE.md`, `package.json`,
`scripts/README.md`, `.github/workflows/lint-docs.yml`, the two docs READMEs,
`CHANGELOG.md`.

## 5. Implementation Steps (High-Level)

1. Scaffold `integrations/runtimes/README.md` and the `integrations/README.md`
   cross-links (the distinction section already landed with the ADR acceptance;
   verify and extend).
2. Build the report-only `ca-runtime-audit.sh` and `lib/` first, test-driven
   against fixtures (SC-18..SC-20, SC-7).
3. Build the anchor-file, settings, MCP-example, and `CLAUDE.md.example`
   artefacts; write the binding README with the classification table.
4. Build the skill-discovery mechanism; run `claude plugin validate`; record its
   output in the binding README.
5. Build the advisory `hooks.json`; confirm it is advisory, not `deny`.
6. Adopt the binding in the framework's own `.claude/` and `CLAUDE.md`.
7. Widen `lint:integrations`; register the npm script; add the `scripts/README.md`
   cross-reference; add the advisory validate job if adopted.
8. Repoint `INTEGRATION.md` and `docs/ARC42.md`.
9. Write and run the no-binding demonstration (SC-21) and all bats suites.
10. CHANGELOG consumer-framed entry; docs README index rows to `implemented` on
    completion per `workflows/document-lifecycle.md`.

## 6. Constraints and Guardrails

* Spec constraints: `FS-0030` Non-Goals and Out of Scope.
* ADR constraints:
  * `ADR-0039` §1 — binding executables are binding content only while
    non-blocking; §3 — setup, not workflow the runtime executes.
  * `ADR-0038` §5 — no runtime dialect in `skills/*/SKILL.md`.
  * `ADR-0007` — no orchestration.
  * `ADR-0032` — no instance data; `ADR-0033`/`FS-0024` — caller-relative
    resolution.
  * `ADR-0037` §6 — provisions/documents classification; no overclaim.
* Architecture constraints: `integrations/` is the only home for bindings;
  gates live in `scripts/`.

## 7. Risks and Edge Cases

* **A binding command drifts into a blocking CI check.** Mitigation: SC-20 and
  the `scripts/README.md` cross-reference; reviewers hold the line (`ADR-0039`
  §1).
* **`claude plugin validate` behaviour changes** — the framework does not control
  the CLI. Mitigation: it is advisory; the binding README records the version it
  was verified against (a runbook candidate).
* **The advisory hook is read as enforcement** by a consumer. Mitigation: SC-14
  requires the README to say plainly it is not.
* **Skill-discovery mechanism accidentally writes a dialect back to source.**
  Mitigation: SC-12, and the mechanism reads `skills/` and writes only under
  `integrations/runtimes/claude-code/` or the consumer's `.claude/`.

## 8. Validation

* Tests expected to pass: all `test/FS-0030/` suites; `npm test`; `npm run
  check:status`; `npm run lint:docs`; `npm run lint:integrations` (widened);
  `bash -n` on shipped scripts.
* Manual checks: `claude plugin validate integrations/runtimes/claude-code/`
  (advisory); `/context` in a framework session shows `CLAUDE.md` importing
  `AGENTS.md`; run the no-binding demonstration.

## 9. Explicit Non-Changes

* `ADR-0004` precedence hierarchy.
* `skills/*/SKILL.md` content.
* The GitHub substrate binding and `FS-0029` executable layer.
* Any accepted ADR body.
* The six core substrate capabilities in `integrations/README.md`.

## 10. Readiness Check

* [x] FS-0030 is approved (2026-09-08)
* [x] This plan carries an `Approved-By:` trailer (reserved paths) — on the
  status-flip commit, per `ADR-0026`
* [x] Tests are defined per SC (section 3)
* [x] Scope is the Claude Code binding only — no other runtime

## Declaration

I affirm that this plan reflects the full intended scope of implementation for
`FS-0030`; no additional behaviour will be introduced; any deviation requires
revising this plan before coding.
