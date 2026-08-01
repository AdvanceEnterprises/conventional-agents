---

type: change-plan
role: implementer
language: markdown
status: implemented
related_specs: [FS-0023]
approved_by: "Joey Clark <taisden@tais-den.dev>"
related_adrs: [ADR-0024, ADR-0027, ADR-0030]
touches:
  - runbooks/README.md
  - templates/core/runbook.md
  - workflows/document-lifecycle.md
  - README.md
  - AGENTS.md
  - docs/specifications/README.md
  - scripts/check-status.sh
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0023/runbook-convention.bats
created: 2026-07-29
updated: 2026-08-01

---

## 1. Feature / Issue Reference

`FS-0023` — Runbook document type. Establishes `runbooks/` as an exported surface with
a template, a lifecycle, and registration in every place the framework enumerates its
exported surface.

## 2. Scope of Change

This plan **cannot self-approve**. Three of its `touches:` are in `ADR-0027`'s reserved
path set — `scripts/check-status.sh`, `package.json`, and `.github/workflows/` — and
`ADR-0015` independently requires an approved FS and PLAN before any governance gate is
modified. The `approved_by:` trailer records the human approval given in the session
that authored this plan.

The change is additive throughout. No existing document type, status vocabulary, or
check changes behaviour; `EXPORTED_PREFIXES` gains an entry and the lint chain gains a
glob.

## 3. Tests Driving This Change

`test/FS-0023/runbook-convention.bats`, generated from `FS-0023` §Success Criteria
(12 assertions). The suite is structural: it asserts the convention's artifacts exist
and that all five exported-surface enumerations agree. It does not run the linter in a
bats subshell — `test/FS-0022/gate-coverage.bats` records why that has proven flaky on
macOS, and the same reasoning applies here.

The most valuable assertion is criterion 6 paired with 7, 8, and 9: they fail
independently, so registering `runbooks/` in the human-readable tables but not in
`EXPORTED_PREFIXES` is caught rather than shipped.

## 4. Files to Be Modified

* `runbooks/README.md` (new) — index and convention statement
* `templates/core/runbook.md` (new) — scaffold with the five required sections
* `workflows/document-lifecycle.md` — new `## Runbooks (RB)` section
* `README.md` — exported-surface table row
* `AGENTS.md` — surface table row
* `docs/specifications/README.md` — exported-surface prose list
* `scripts/check-status.sh` — `EXPORTED_PREFIXES` gains `runbooks/`
* `package.json` — `lint:runbooks` script, added to the `lint:docs` chain
* `.github/workflows/lint-docs.yml` — `runbooks/**/*.md` in both path lists
* `test/FS-0023/runbook-convention.bats` (new)

Also updated, outside `touches:` because they are index and record maintenance rather
than interface changes: `docs/specifications/README.md` and
`docs/change-plans/README.md` index rows, and `CHANGELOG.md`.

## 5. Implementation Steps (High-Level)

1. Create `runbooks/` with `README.md` stating the `RB-NNNN` convention and an empty
   index table.
2. Write `templates/core/runbook.md` with the front matter from `FS-0023` §2 and the
   five section headings from §4.
3. Add `## Runbooks (RB)` to `workflows/document-lifecycle.md`, placed after
   `## Architecture Decision Records (ADR)` so the document's four type sections stay
   contiguous.
4. Register `runbooks/` in all five exported-surface enumerations. Do these as one
   change, not four — a partial registration is the failure mode.
5. Add the lint script and CI path triggers.
6. Write the bats suite.
7. Run `npm run lint:docs`, `npm run check:status`, `npm test`.

## 6. Constraints and Guardrails

* `runbooks/` inherits the root `.markdownlint.yml`. Do **not** add a per-directory
  config; `test/FS-0022/gate-coverage.bats` asserts covered directories either inherit
  the root `default: true` or carry a config that sets it, and a new config is one more
  thing to drift.
* No runbook is authored by this plan. `runbooks/README.md`'s index table ships empty.
  Writing the GitHub provisioning runbook requires a live repository and is the next
  unit of work.
* `EXPORTED_PREFIXES` is prefix-matched with a `case` glob. `runbooks/` with the
  trailing slash matches `runbooks/RB-0001-*.md`; do not write it without the slash.

## 7. Risks and Edge Cases

* **The consumer-impact check begins firing on this FS.** `FS-0023`'s own `interfaces:`
  names `runbooks/`, `README.md`, and `AGENTS.md` — all exported. Once `runbooks/`
  enters `EXPORTED_PREFIXES`, `check-status.sh` requires a CHANGELOG entry naming
  `FS-0023`. That entry is part of this change, not a follow-up.

  **This was untrue when written.** The consumer-impact check resolved
  `"$FS_DIR/$fs_id.md"`, which does not exist for suffixed filenames, so it skipped
  every spec and fired on none. Adding `runbooks/` to `EXPORTED_PREFIXES` changed
  nothing. The CHANGELOG entry was written because the plan said to, not because a
  gate demanded it — which is exactly the difference this PR claims to remove.
  The check was repaired after review; the statement above is now accurate.
* **`.github/workflows/lint-docs.yml` path triggers are `pull_request`-scoped to
  `trunk`.** Adding `runbooks/**/*.md` does not retroactively trigger CI on branches
  already open. Not a defect; worth knowing when the first runbook lands.
* **Ordering within `document-lifecycle.md`.** The `## Transition Rules` section that
  follows the type sections speaks in FS/PLAN vocabulary (`draft`, `approved`,
  `implemented`). Runbooks use a different vocabulary and are deliberately not folded
  into those rules. The new section states its own transitions inline.

## 8. Validation

* `npm run lint:docs` — passes with `runbooks/` in the chain
* `npm run check:status` — passes, including the consumer-impact check now applying to
  `FS-0023`
* `npm test` — all bats suites pass, including the new `test/FS-0023/` suite
* Manual: confirm all five exported-surface enumerations name `runbooks/`

## 9. Explicit Non-Changes

* No staleness or index-consistency check for runbooks. `FS-0023` §Non-Goals states the
  reasoning: there are zero runbooks, so any drift pattern would be invented rather
  than observed.
* The five-way duplication of the exported-surface definition is **recorded, not
  fixed**. Collapsing it to one source of truth changes `scripts/check-status.sh` and
  every document that restates it, which is its own spec. Filed in `BACKLOG.md`.
* No existing operational prose in `workflows/` is retrofitted into runbooks.

## 10. Readiness Check

* [x] Governing FS is `approved` (`FS-0023`)
* [x] `approved_by:` records human approval; reserved paths prevent self-approval
* [x] Success Criteria are testable and mapped to bats assertions
* [x] Non-Goals stated as hard constraints
