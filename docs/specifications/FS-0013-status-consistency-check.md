---
type: feature-spec
id: FS-0013
status: implemented
title: Status consistency check for FS/PLAN documents
owner: Tai
test_required: false
interfaces:
  - scripts/check-status.sh (new)
  - package.json (new npm script)
  - .github/workflows/lint-docs.yml (new CI job)
  - guidelines/ROLE_CONTRACT.md (reference update)
related_adrs: [ADR-0007, ADR-0008]
supersedes: []
requires: [FS-0010]
tags: [process, compliance, gates, ci, tooling]
created: 2026-06-08
updated: 2026-06-08
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Status consistency check for FS/PLAN documents

## Status

- Implemented

## Summary

Status fields in FS and PLAN front matter drifted silently from the ground truth because
there was no machine-enforced check. This spec introduces a lightweight script that
validates two consistency rules — FS↔PLAN status pairing and README index table sync —
and runs it in CI so the drift cannot recur undetected.

## Goals

- Detect mismatches between an FS's `status:` and the `status:` of every PLAN whose
  `related_specs:` references it.
- Detect mismatches between front matter `status:` values and the corresponding rows in
  the README index tables (`docs/specifications/README.md` and
  `docs/change-plans/README.md`).
- Provide a local command (`npm run check:status`) that agents and humans can run before
  committing.
- Add a CI job so the check blocks merges when consistency is violated.

## Non-Goals

- Enforcing YAML schema or front matter completeness (separate concern from FS-0001/FS-0005).
- Linting markdown formatting (covered by existing markdownlint jobs).
- Validating that stated deliverables actually exist on the filesystem (out of scope for
  this iteration).
- Auto-fixing inconsistencies (the script reports; humans fix).

## Users / Stakeholders

- Tai — framework owner; wants status fields to be trustworthy at a glance.
- Agents — need accurate status signals to decide whether a spec is ready to implement.
- Contributors — benefit from CI blocking PRs that leave status out of sync.

## Interfaces

- **`scripts/check-status.sh`** — new executable bash script; exits non-zero on any
  violation; prints a human-readable error per violation.
- **`package.json`** — new `check:status` script: `bash scripts/check-status.sh`.
- **`.github/workflows/lint-docs.yml`** — new `check-status` job that runs
  `npm run check:status` and triggers on the same path filters as existing lint jobs.
- **`guidelines/ROLE_CONTRACT.md`** — document hygiene gate checklist gains one item:
  run `npm run check:status` and resolve all violations before committing.

## Success Criteria

Each bullet MUST be objectively testable.

- Given an FS with `status: implemented` and a PLAN whose `related_specs:` includes that
  FS but has `status: approved`, when `npm run check:status` is run, then the script
  exits non-zero and prints an error naming the mismatched FS/PLAN pair.
- Given a PLAN with `status: implemented` and its governing FS has `status: approved`,
  when `npm run check:status` is run, then the script exits non-zero and prints an error.
- Given a README index table row whose status column differs from the corresponding
  document's front matter `status:`, when `npm run check:status` is run, then the script
  exits non-zero and prints an error naming the document and the discrepancy.
- Given all FS/PLAN pairs are consistent and all README tables match front matter, when
  `npm run check:status` is run, then the script exits zero and prints "All status checks
  passed."
- Given a PR that introduces a status inconsistency, when CI runs, then the `check-status`
  job fails and the PR cannot be merged until resolved.

## Status Pairing Rules

The *first* entry in a PLAN's `related_specs:` list is its **primary governing spec**.
Secondary entries are informational dependencies and are not checked for pairing.

The script enforces:

1. If a PLAN is `implemented`, its primary FS must also be `implemented`.
2. If an FS is `implemented`, at least one PLAN listing it as its primary spec must also
   be `implemented`.

`draft` and `approved` statuses are not cross-checked against each other — a PLAN may be
`approved` while its FS is also `approved`, which is normal pre-execution state.

## README Sync Rules

For each FS and PLAN document, the script checks that the status value in the relevant
README index table row matches the `status:` field in the document's YAML front matter.
The README table format is:

```markdown
| FS-XXXX | Title | status-value |
```

The script extracts `status-value` from the table and compares it to the front matter.

## Edge Cases

- A PLAN with no `related_specs:` is skipped for pairing checks (no spec to pair with).
- A document not listed in the README table is reported as a missing index entry.
- Front matter parsing reads only the first YAML block (between the first two `---` lines).

## Out of Scope

- Checking ADR status consistency (ADRs have a different lifecycle; out of scope for v1).
- Checking `draft`→`approved` transitions (human-only; not machine-checkable without PR
  event context).
- Renumbering or renaming documents.

## Dependencies

- FS-0010: document lifecycle rules define what status values are valid and what the
  pairing invariants mean.
- Bash 3.2+ (macOS default) for the script; no external dependencies.

## Rollout / Migration

1. Write `scripts/check-status.sh`.
2. Add `check:status` to `package.json`.
3. Add `check-status` job to `.github/workflows/lint-docs.yml`.
4. Add one-line checklist item to `guidelines/ROLE_CONTRACT.md` document hygiene gate.
5. Run `npm run check:status` locally — must exit zero after the accompanying
   reconciliation changes (PLAN-0013 depends on the reconciliation PR landing first, or
   being in the same PR).

## Open Questions

None.
