---
type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0026]
approved_by: ""
related_adrs: []
touches:
  - scripts/new-adr.sh
  - scripts/new-plan.sh
  - package.json
  - scripts/README.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
created: 2026-08-28
updated: 2026-08-28
---

# PLAN-0026: Implement FS-0026 — ADR and PLAN scaffolding CLI

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0026
* Related ADR ID(s): none (new capability, no governing ADR yet)
* Issue / PR Reference: #84 (ADR template automation), #91 (spec/plan generation from ADRs)

## 2. Scope of Change

**This change WILL:**

* Add `scripts/new-adr.sh` — scaffolds a new ADR with sequential ID, slugified
  filename, and framework-conformant frontmatter. Supports `--title` (non-interactive),
  `--dry-run`, and interactive prompts.
* Add `scripts/new-plan.sh` — scaffolds a draft PLAN from an existing ADR,
  carrying over context/decision/consequences and frontmatter list fields
  (inline and multi-line YAML forms).
* Register both as npm scripts (`new:adr`, `new:plan`) in `package.json`.
* Document both commands in `scripts/README.md`.

**This change WILL NOT:**

* Edit `docs/decisions/README.md` or `docs/change-plans/README.md` automatically
  (index updates remain a documented follow-up step).
* Modify the vendored MADR template.
* Change any existing governance gate behavior.

## 3. Tests Driving This Change

* `bash -n` syntax check on both scripts.
* Manual dry-run invocations covering: multi-word titles, `--title` as last
  argument, apostrophes/quotes in input, leading-zero ADR IDs, multi-line
  `related_specs` frontmatter, top-level vs subsection Consequences.
* `npm run check:status` and `npm run lint:adrs` / `npm run lint:plans` pass
  with the new docs present.

## 4. Implementation Steps

1. `scripts/new-adr.sh`:
   * Parse args with `set -euo pipefail`; `--title` consumes the rest of the
     args (multi-word titles) and must not crash when it is the last argument.
   * `next_adr_num()` uses base-10 arithmetic (`10#...`) to strip leading zeros.
   * `sanitize()` is a no-op passthrough (variables interpolate inside double
     quotes; no backslash escaping).
   * Pre-flight template check tests both `vendor/madr/template/` and
     `vendor/madr/templates/` paths.
   * Header comment states generation uses a built-in template string.
2. `scripts/new-plan.sh`:
   * `extract_list()` handles inline `[a, b]` and multi-line `- a` YAML list
     forms without `grep -P` (portable), and does not exit when the field is
     absent.
   * Consequences extraction matches both `## Consequences` (top-level) and
     `### Consequences` (under Decision Outcome).
3. `package.json`: add `"new:adr"` and `"new:plan"` script entries.
4. `scripts/README.md`: document usage, flags, and the index-update follow-up.

## 5. Verification

* All success criteria in FS-0026 pass.
* `npm run check:status` reports all status checks passed.
* `npm run lint:adrs` and `npm run lint:plans` report 0 issues.

## 6. Rollout

* No rollout risk: both commands are additive; no existing behavior changes.
* The governing FS/PLAN pair (FS-0026/PLAN-0026) is authored in the same
  change as the implementation (PR #88) and must be approved before merge.
