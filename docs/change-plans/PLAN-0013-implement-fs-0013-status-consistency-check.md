---
type: change-plan
role: implementer
language: bash
status: implemented
related_specs:
  - FS-0013
related_adrs: []
created: 2026-06-08
updated: 2026-06-08
---

# PLAN-0013: Implement FS-0013 — Status Consistency Check

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0013
- Related ADR ID(s): none
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Create `scripts/check-status.sh` — a bash script that validates FS↔PLAN status
  pairing and README index table sync.
- Add `check:status` npm script to `package.json`.
- Add a `check-status` CI job to `.github/workflows/lint-docs.yml`.
- Add one checklist item to the document hygiene gate in `guidelines/ROLE_CONTRACT.md`.

**This change will NOT:**

- Auto-fix any inconsistencies.
- Change any existing FS, PLAN, or ADR content.
- Add schema validation for front matter fields beyond `status:`.
- Modify the markdownlint configuration or existing lint jobs.

## 3. Tests Driving This Change

Validation is via manual run of `npm run check:status` against the current repo state.
The script must exit zero after reconciliation changes are applied (FS-0013 requires
this as a success criterion).

`test_required: false` per FS-0013 — the script itself is the quality gate.

## 4. Files to Be Modified

- **Add:** `scripts/check-status.sh`
- **Modify:** `package.json` — add `check:status` script entry
- **Modify:** `.github/workflows/lint-docs.yml` — add `check-status` job
- **Modify:** `guidelines/ROLE_CONTRACT.md` — add checklist item to document hygiene gate

## 5. Implementation Steps

1. Create `scripts/` directory if it does not exist.
2. Write `scripts/check-status.sh`:
   - Parse `status:` from front matter of every `docs/specifications/FS-*.md`.
   - Parse `status:` and `related_specs:` from front matter of every
     `docs/change-plans/PLAN-*.md`.
   - Enforce pairing rules: if FS=`implemented`, all related PLANs must be
     `implemented`; if any PLAN=`implemented`, its FS must be `implemented`.
   - Parse README tables from `docs/specifications/README.md` and
     `docs/change-plans/README.md`; compare status column to front matter status.
   - Print one error line per violation; exit non-zero if any violations found.
   - Print "All status checks passed." and exit zero if clean.
3. Add `"check:status": "bash scripts/check-status.sh"` to `package.json` scripts.
4. Add `check-status` job to `.github/workflows/lint-docs.yml`:
   - `runs-on: ubuntu-latest`
   - Steps: `actions/checkout@v4`, then `bash scripts/check-status.sh`
   - Path filters: same as existing jobs (triggers on FS, PLAN, workflow, and lint config changes).
5. Add to document hygiene gate checklist in `guidelines/ROLE_CONTRACT.md`:
   `Run \`npm run check:status\` and resolve all violations before committing.`
6. Run `npm run check:status` locally to verify it exits zero.

## 6. Constraints and Guardrails

- Script must work with Bash 3.2+ (macOS default) — no `bash 4` associative arrays.
- Script must be self-contained — no `npm install` or Python required to run it.
- Front matter parsing must be robust to multi-line YAML lists for `related_specs:`.

## 7. Risks and Edge Cases

- A PLAN with no `related_specs:` is silently skipped for pairing checks — this is
  intentional per FS-0013.
- Documents not listed in the README table are reported as missing index entries, which
  may surface other hygiene issues unrelated to this plan.

## 8. Validation

- `npm run check:status` exits zero on the current repo state (after reconciliation).
- CI job appears in the Actions tab and passes on trunk.

## 9. Explicit Non-Changes

- No changes to existing FS, PLAN, or ADR documents beyond what's described above.
- No changes to markdownlint config or existing lint jobs.
- No new submodules.

## 10. Readiness Check

- [x] FS-0013 is approved
- [x] Scope is minimal and explicit
- [x] No architectural/code changes implied beyond the script and CI config

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
