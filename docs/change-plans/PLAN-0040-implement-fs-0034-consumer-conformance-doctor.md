---
type: change-plan
role: implementer
language: bash
status: implemented
related_specs: [FS-0034]
approved_by: ""
related_adrs: [ADR-0015, ADR-0033]
touches:
  - scripts/check-conformance.sh
  - scripts/README.md
  - package.json
  - test/FS-0034/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
created: 2026-09-10
updated: 2026-09-30
---

# PLAN-0040: Implement FS-0034 — Consumer Conformance Doctor

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0034
* Related ADR ID(s): ADR-0015 (tool taxonomy and location boundaries),
  ADR-0033 (governance-gate target resolution and configuration)
* Issue / PR Reference: #142 (feature: define an optional consumer
  conformance doctor, implemented in **PR #147, merged 2026-09-30**)

## 2. Scope of Change

**This change WILL:**

* Add `scripts/check-conformance.sh` — a read-only consumer-conformance
  doctor. Checks: framework presence (`vendor/conventional-agents/`),
  AGENTS.md anchors, dangling vendor references, status-gate runnability,
  CI wiring, and framework version reference. Supports `--json`,
  `--help`, and stable exit codes (0/1/2). Resolves the target repository
  from the caller's cwd or `CA_TARGET_REPO` per FS-0024/ADR-0033.
* Register `check:conformance` in `package.json`.
* Document the command in `scripts/README.md`.
* Add `test/FS-0034/conformance-doctor.bats` covering the FS-0034 success
  criteria (scratch-repo isolation, same pattern as FS-0026).
* Add FS-0034 and PLAN-0040 index rows to `docs/specifications/README.md`
  and `docs/change-plans/README.md`.

**This change WILL NOT:**

* Wire the doctor into CI as a failing gate (it is optional tooling, not a
  governance gate — FS-0034 Non-Goals).
* Add any write path, remediation, or work-item mutation.
* Decide the `ca doctor` / separate-conformance-project boundary (issue
  #142 proposed action 3; out of scope for this slice).

## 3. Implementation Plan

1. Author `scripts/check-conformance.sh` (bash, `set -uo pipefail`,
   caller-relative `REPO_ROOT`).
2. Register `check:conformance` in `package.json` scripts.
3. Document the command in `scripts/README.md` under the governance-gate
   scripts contract (noting it is NOT a Category 1 gate).
4. Author the bats suite under `test/FS-0034/`.
5. Update both README index tables.
6. Verify: `npm run check:status`, `npm run lint:docs`, `npm test`,
   `shellcheck scripts/check-conformance.sh`.

## 4. Risks and Mitigations

* **Reserved paths:** `scripts/` and `package.json` are reserved
  (ADR-0027) — this plan's `touches:` stays within FS-0034's declared
  `interfaces:` so the containment rule passes; human approval is still
  required before the plan may advance past draft. **Reserved-path contact
  blocks self-approval under ADR-0027:** the plan cannot be self-approved
  even with `interfaces:` containment satisfied, because `scripts/` and
  `package.json` are reserved regardless of `interfaces:`. Human approval
  (ADR-0026) is the only path past draft.
* **False positives on real consumers:** the doctor reports, never
  rewrites; findings are diagnostics for the human.
* **Self-check noise:** self-check mode skips the presence check so the
  framework's own CI runs stay meaningful.

## 5. Verification

* `npm run check:status` — FS/PLAN pairing and index sync pass.
* `npm run lint:docs` — all governed documents lint clean.
* `npm test` — all bats suites pass, including `test/FS-0034/`.
* `shellcheck scripts/check-conformance.sh` — no findings.
* Manual: run the doctor against a scratch consumer fixture and against
  this repository (self-check).

## 6. Rollout

* Draft PR opened against trunk; CI runs the full gate chain.
* Kimi K2.7 Code and Minimax M3 review sequentially; findings applied by
  the maintenance tick.
* Shipped in **PR #147 (merged 2026-09-30)**; the governing FS/PLAN pair
  statuses were reconciled post-merge by the maintenance tick (issue #178).
