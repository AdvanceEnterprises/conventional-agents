# scripts/ — Governance Gate Scripts

This directory holds the framework's governance gate scripts. They are
**Category 1 governance gates** per `ADR-0015`: every script lives under
`scripts/`, is registered as an npm script in `package.json`, and has a
documented entry here.

A gate whose failure message is the only explanation of what it wanted is a
gate people work around. This file is the contract.

---

## check-status.sh

`npm run check:status` runs `bash scripts/check-status.sh`.

**Purpose.** Validates FS/PLAN/ADR status pairings, README index table sync,
ADR structural completeness, PLAN `touches:` containment, and
consumer-impact CHANGELOG entries.

**When it runs.**

- On every commit (pre-commit testing gate per `ROLE_CONTRACT`).
- In CI as part of the `lint-docs` workflow's `check-status` job.
- Manually: `npm run check:status`.

**What it checks.**

1. **FS↔PLAN status pairing.** A PLAN at `implemented` requires its primary FS
   at `implemented`. A FS at `implemented` requires at least one PLAN with it
   as primary spec to also be `implemented`.
2. **FS and PLAN README index sync.** Every FS/PLAN file has a row in its
   directory's `README.md`, and the row's status matches the file's
   front-matter `status:`. (Original check; preserved.)
3. **ADR index consistency.** Every `docs/decisions/ADR-*.md` has a row in
   `docs/decisions/README.md`, and the row's H1 title and front-matter
   status match the file. The file is authoritative for both. Rows for
   deleted ADRs are flagged.
4. **FS and PLAN index title sync.** The title column in `README.md` matches
   the file's front-matter `title:` field. Abbreviated titles drift silently
   without this check.
5. **ADR structural completeness.** An `accepted` ADR must contain
   `## Context and Problem Statement`, `## Considered Options`,
   `## Decision Outcome`, `## Consequences`, and `## Validation`. Missing
   any of these is an `accepted`-severity failure; missing `## Validation`
   on a `proposed` ADR is a warning.
6. **PLAN `touches:` containment** (ADR-0027). For an `approved` PLAN, every
   path in `touches:` must fall within the union of its governing FS's
   `interfaces:`, AND must not match the reserved-path set
   (`docs/decisions/`, `guidelines/ROLE_CONTRACT.md`, `scripts/`,
   `.github/workflows/`, `package.json`). A PLAN with no `touches:` field
   fails this check; absence is not an empty declaration.
7. **Consumer-impact CHANGELOG entry.** An FS at `approved` or beyond whose
   `interfaces:` names an exported-surface path (`guidelines/`, `roles/`,
   `skills/`, `templates/`, `workflows/`, `integrations/`, `INTEGRATION.md`,
   `AGENTS.md`, `runbooks/`) must have a `CHANGELOG.md` entry naming it.
   Presence is checked; framing is a review judgment.
8. **Referenced-path resolution** (`FS-0022` §1c). Every path a current-state
   document names in backticks must resolve, relative to the repository root
   or the naming document's own directory.

   *Scope is deliberately narrower than the spec's literal wording, because a
   literal reading fails on correct documents:*

   - **Current-state documents only** — root `README`/`AGENTS`/`INTEGRATION`/
     `CONTRIBUTING`, plus `guidelines/`, `roles/`, `skills/`, `templates/`,
     `workflows/`, `integrations/`, `runbooks/`, `scripts/`. Decision records
     (ADR, FS, PLAN) describe what was true when written and are append-only
     after acceptance; checking them would force edits to satisfy a linter.
     `BACKLOG.md` is excluded for the opposite reason — naming things that do
     not exist yet is its purpose. `CHANGELOG.md` is a historical record.
   - **Only tokens containing a directory separator.** A bare `tsconfig.json`
     or `pnpm-lock.yaml` in a guideline names a file in the *reader's*
     repository.
   - Excluded per `FS-0022` §1c: `vendor/` (uninitialised submodule),
     `docs/orchestration/` (preserved evidence), and paths an approved PLAN's
     `touches:` declares as to-be-created.
   - `REF_EXEMPT` in the script covers what none of the above can: a path the
     framework tells a consumer to create in *their* repo is syntactically
     identical to a reference to one of ours. Entries carry a reason; a bats
     assertion fails if one does not.

   A failure means a reader following the document looks for a file that is
   not there. Fix the reference, not the check.

**What it does NOT check.**

- **Rule 3 of `ADR-0030`** (an ADR that changes a rule must modify the
  governing current-state document in the same change). This requires the
  change set and runs in CI only — see `lint-docs.yml` §"current-state
  update" job.
- **Convention-only rules** (`ADR-0019`, `ADR-0020`, `ADR-0026`,
  `ADR-0013`'s artifact boundaries). Detection or discipline, not
  enforcement, per `FS-0022` §Non-Goals.
- **Lint coverage.** See `npm run lint:docs`.

**Failure.** One error per violation. Exit code 1 on any failure. Run
`npm run check:status` and resolve every reported violation before
committing.

**Performance.** ~5s on a clean tree. The script spawns `awk` per PLAN per
`interfaces:` row and `grep -F` per ADR; this is acceptable for CI. A future
optimization could cache file reads in bash arrays.

---

## run-bats.sh

`npm test` runs `bash scripts/run-bats.sh`.

**Purpose.** Executes every `.bats` suite under `test/`. Per `FS-0022` §6,
"a missing `bats` binary fails loudly with an install hint, rather than
passing vacuously."

**When it runs.**

- Manually: `npm test`.
- In CI as a separate job (see `lint-docs.yml`).
- Pre-commit testing gate (when `bats` is installed locally).

**Install hints** (when `bats` is absent):

- macOS: `brew install bats-core`
- Debian/Ubuntu: `apt-get install bats`

The framework does not vendor a test runner.

**Failure.** Exits non-zero on any failing assertion in any suite.
