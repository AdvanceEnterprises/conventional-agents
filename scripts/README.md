# scripts/ — Governance Gate Scripts

This directory holds the framework's governance gate scripts. They are
**Category 1 governance gates** per `ADR-0015`: every script lives under
`scripts/`, is registered as an npm script in `package.json`, and has a
documented entry here.

A gate whose failure message is the only explanation of what it wanted is a
gate people work around. This file is the contract.

---

## GitHub binding executables

The exported GitHub binding lives under `integrations/github/`, not `scripts/`.
Its three commands are registered as `github:submodule-init`,
`github:label-provision`, and `github:board-audit` in `package.json`.

These commands are **not Category 1 governance gates**. They provision or report
substrate state, and two of them require repository or project permissions that a
pull-request gate must not hold. `gh-board-audit.sh` is deliberately read-only;
consumer policy decides whether reported drift should be reconciled. A command
that is wired to fail a pull request belongs here under `scripts/` instead, with
the corresponding governance decision and gate coverage.

---

## Runtime binding executables

The runtime binding's executables live under `integrations/runtimes/claude-code/`,
not `scripts/` (`FS-0030`, `ADR-0039`, `ADR-0015` Location invariant). They are
registered in `package.json` as `sync:claude-skills` and `ca-runtime-audit`.

These commands are **not Category 1 governance gates**. They sync skill copies
into the binding and audit `.claude/` conformance, both report-only/advisory by
design — see `integrations/runtimes/claude-code/README.md` for the audit's exit
semantics (`--strict` is an opt-in signal for scripts, not a CI blocking gate).

The canonical CI fragments use full checkout history because the framework's
status and attribution checks inspect history. In particular, a shallow checkout
can make a consumer's governance run appear healthy while omitting approval
provenance. The submodule fragment calls the shared initializer so consumers do
not duplicate its `--global` credential-rewrite requirement.

---

## Benchmark harness

`scripts/bench-run.sh` is the governed-agent benchmark harness runner
(FS-0031). It executes a task card under one named condition in a disposable
worktree and emits a JSON report with separate functional, governance,
evidence, overhead, and failure sections. It is registered as `bench:run` in
`package.json`.

```bash
npm run bench:run -- benchmark/task-cards/pilot-001.md baseline
```

The harness never executes tasks in the framework's own checkout — it clones
the card's pinned base commit into a disposable directory. Task cards live in
`benchmark/task-cards/` and validate against
`benchmark/task-card.schema.json` (v1). See FS-0031 for the full contract.

---

## run-validation.sh — canonical reproducibility runner

`npm run validate` runs the five-command validation surface in this fixed order:

1. `npm test`
2. `npm run lint:docs`
3. `npm run check:status`
4. `npm run check:freshness`
5. `npm run lint:cross-repo`

**Purpose.** FS-0039 / issue #132 makes this the single local and CI entry point
for the framework's own acceptance signal. The runner prints progress, records
whole-second timings, writes the complete output to a log, and exits non-zero on
any command failure or timeout. It continues after a fast failure so the log
contains the state of every gate; a timeout is terminated and remains fatal.

**Default budgets.** `npm test` has 1800 seconds, each other gate has 120
seconds, each individual Bats suite has 900 seconds, and the complete run has
1800 seconds. Override with `CA_VALIDATION_TEST_TIMEOUT`,
`CA_VALIDATION_GATE_TIMEOUT`, `BATS_SUITE_TIMEOUT`, and
`CA_VALIDATION_BUDGET`. Values must be positive integers. The runner clips a
step to the remaining global budget, so the documented wall-clock bound is
real rather than advisory.

**Hermeticity.** The target is the caller's Git worktree or an explicit
`CA_TARGET_REPO`. The runner requires a clean target, uses a disposable
`TMPDIR`, `HOME`, Git global config, and npm cache, sets npm offline mode, and
places fail-closed stubs for `gh`, `curl`, `wget`, `ssh`, `scp`, and `nc` at the
front of `PATH`. It never invokes a network-capable Git subcommand: `git` is
used for local reads only, `GIT_TERMINAL_PROMPT=0` plus an empty private global
config (`GIT_CONFIG_GLOBAL`, `GIT_CONFIG_NOSYSTEM=1`) strip ambient credential
helpers, and `COMMIT_RANGE` must already exist locally — an unavailable range
fails closed instead of fetching. The hermeticity assertion in the FS-0039
suite is the *negative* form (`fetch|pull|push|ls-remote|clone|remote` are
rejected and traced), so it does not rot when a future patch adds another local
read. Set `CA_VALIDATION_LOG` to an
absolute path outside the target checkout to archive a specific log; otherwise
a temporary log under `/tmp` is printed. The log is an archival artifact: the
verdict comes from the step exit statuses, not from reading the log back. CI
prepares
full history, dependencies, and the pull-request base ref, then invokes this
same command.

**Prerequisites.** Run `npm ci --ignore-scripts` before validation, and install
`bats` and `rg`. Markdownlint scripts use the pinned local binary, not `npx`;
missing dependencies therefore fail instead of downloading an unreviewed
package during a gate run.

---

## Running these scripts against a vendored (host) repository

Per `FS-0024`/`ADR-0033`: each script resolves the repository it checks from the
**caller's working directory** (`git rev-parse --show-toplevel`), not from the
script's own on-disk location. `npm run check:status`, `npm test`, every job in
`.github/workflows/lint-docs.yml`, and every bats suite that invokes a script
directly already run with their working directory at the repository they mean to
check, so this framework's own invocations are unaffected. A host repository
vendoring this framework as a git submodule and running
`bash vendor/conventional-agents/scripts/check-status.sh` from its own root — or
any subdirectory of it — gets **its own** documents checked, not this
framework's. Set `CA_TARGET_REPO` to override the resolved target explicitly, for
a caller whose working directory is not inside the repository it means to check.

`check-status.sh` additionally distinguishes **this framework checking itself**
from **a vendored copy checking a host**, by comparing the resolved target
against the script's own physical location (`FRAMEWORK_HOME`, the old
`dirname "$0"`-based computation, kept for exactly this). When they're equal —
every invocation this repository makes of its own scripts — rules 6 and 7 below
use this repository's own hardcoded `RESERVED_PATHS`/`EXPORTED_PREFIXES`,
unchanged from before `FS-0024`. When they differ, both rules instead read
`config/gates.yml` **at the host's own repository root** — never a path inside
`vendor/`. Copy `config/gates.example.yml` there and fill it in; see rules 6 and
7 below for what happens if you don't, and why the two behave differently when
you haven't.

This repository does not create a populated `config/gates.yml` for itself.
`RESERVED_PATHS` and `EXPORTED_PREFIXES` remain hardcoded in `check-status.sh`
for the self-check case. Per `ADR-0032`, a template repository carries no
instance data, and this repository's own reserved paths and exported surface
are exactly that — facts a second adopter's copy would have to change. The
self-check path exists so this repository need not create that file.

`check-current-state.sh` never had the resolution defect — see its own section
below — but accepts `CA_TARGET_REPO` too, for symmetry: a caller should not need
to know that one of the three scripts already happened to get it right.

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
4. **FS index title sync, and FS/PLAN row resolution.** Every `FS-`/`PLAN-` row
   in the directory `README.md` must resolve to a real file; a row naming no
   file is an orphan and fails. For FS, the row's title column must also match
   the file's front-matter `title:`.

   PLAN rows are resolved but **not** title-compared: plans carry no `title:`
   field, and `templates/core/change-plan.md` defines none, so comparing would
   report all of them as drifted.

   Both this check and check 7 previously built `"$dir/$id.md"` directly. Every
   FS and PLAN here carries a descriptive suffix, so that path never resolved and
   both checks skipped every document — passing while enforcing nothing. They
   resolve by ID now (`resolve_doc_by_id`), which tolerates bare and suffixed
   filenames alike.
5. **ADR structural completeness.** An `accepted` ADR must contain
   Context and Problem Statement, Considered Options, Decision Outcome,
   Consequences, and Validation. Missing any is an `accepted`-severity
   failure; a missing Validation on a `proposed` ADR is a warning.

   Matching is a **whole heading line at H2 or H3**. Both halves matter:
   the previous `grep -qF` was unanchored, so `## Consequences-renamed`
   satisfied the Consequences requirement, as would a mention in prose —
   renaming a required section left the check green. But pinning it to H2
   fails six correctly-structured ADRs here, because MADR 4.0 nests
   `### Consequences` under `## Decision Outcome` and
   `docs/decisions/README.md` adopts MADR as the baseline. Anchor to the
   line; do not pin the level.
5b. **ADR supersession chain** (`FS-0028`). The `superseded_by:` front-matter
   field is machine-checked. An ADR at `status: superseded` must name at
   least one replacement; every non-null value must resolve to an existing
   ADR file (by front-matter `id:`); and an ADR whose status is not
   `superseded` may not declare a replacement. `null` is the empty
   declaration. See `docs/decisions/README.md` §5.
6. **PLAN `touches:` containment** (ADR-0027). For an `approved` PLAN, every
   path in `touches:` must fall within the union of its governing FS's
   `interfaces:`, AND must not match the reserved-path set. Checking this
   repository against itself, that set is
   (`docs/decisions/`, `guidelines/ROLE_CONTRACT.md`, `scripts/`,
   `.github/workflows/`, `package.json`); checking a vendored copy against a
   host repository, it is `reserved_paths` from the host's own
   `config/gates.yml` — see "Running these scripts against a vendored (host)
   repository" above. A PLAN with no `touches:` field fails this check;
   absence is not an empty declaration.

   **A host repository with no `config/gates.yml`, or one missing the
   `reserved_paths` key, cannot self-approve anything.** The check refuses to
   certify any PLAN evaluated under this rule and exits non-zero, naming
   `reserved_paths` as unconfigured, rather than silently treating an
   unconfigured reserved set as an empty one — the fail-open direction is
   exactly the pattern the rest of this file catalogues four prior instances
   of. An **explicit** `reserved_paths: []` is different from an absent one:
   it is a real, honored declaration that this repository has nothing needing
   the protection, and the check evaluates self-approval against `interfaces:`
   containment alone in that case.
7. **Consumer-impact CHANGELOG entry.** An FS at `approved` or beyond whose
   `interfaces:` names an exported-surface path must have a `CHANGELOG.md`
   entry naming it. Presence is checked; framing is a review judgment.
   Checking this repository against itself, the exported-surface set is
   `guidelines/`, `roles/`, `skills/`, `templates/`, `workflows/`,
   `integrations/`, `runbooks/`, `scripts/`, `INTEGRATION.md`, `AGENTS.md`;
   checking a vendored copy against a host repository, it is
   `exported_prefixes` from the host's own `config/gates.yml`.

   **Unlike rule 6, an unconfigured or explicitly empty `exported_prefixes`
   does not fail closed.** This is a documentation reminder, not a safety
   gate — the worst outcome of getting it wrong is a missed CHANGELOG entry,
   not a self-approved unsafe change. The check prints an explicit `SKIP:`
   line and exits zero (assuming no other failure), distinguishable in its
   output from having run the rule and found nothing to flag. This is also
   the correct, permanent state for a repository with no exported surface at
   all — a pure instance-form repository per `ADR-0032` that nobody vendors,
   the concrete case this rule's design was checked against
   (`feral-fleet`).
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
  change set, so it lives in `check-current-state.sh` and runs in CI only —
  see below, and the `current-state-update` job in `lint-docs.yml`.
- **Convention-only rules.** Detection or discipline, not enforcement, per
  `FS-0022` §Non-Goals. Each is unenforced **by decision, not by omission** —
  the reason is recorded here so nobody files the absence as a bug and tries
  to close it:

  | Rule | Source | Why it is not enforced |
  | --- | --- | --- |
  | Parallel primaries must not touch the same artifact | `ADR-0013` | Relies on discipline; no tooling proposed |
  | Primary/contributor designation | `ADR-0013` | Undeclared sessions can both act as primary |
  | Work item Type is human-mutable only | `ADR-0019` | No substrate offers per-field ACLs (`ADR-0024`) |
  | Parked-state suppression | `ADR-0020` | No substrate offers per-label permissions |
  | Bootstrap merge must be declared in advance | `ADR-0026` | Nothing prevents a PR description claiming it after the fact |

  The first four are substrate limitations, not gaps in this script. Closing
  them requires a platform that offers controls no current substrate does —
  which is why `ADR-0024`'s bindings state per capability whether a mechanism
  *enforces* or merely makes violations *attributable*.

- **Lint coverage.** See `npm run lint:docs`.

**Failure.** One error per violation. Exit code 1 on any failure. Run
`npm run check:status` and resolve every reported violation before
committing.

**Requires full git history.** Check 6's `ADR-0026` approval-provenance test
reads `git log` for the `Approved-By:` trailer on the commit that last touched
each PLAN, and `git show <sha>:<plan>` to compare the approved `touches:` set
against the current one. **A shallow clone has neither.** Every approval lookup
then fails and every reserved path reports as unapproved — 18 errors on this
repository at the time of writing, against zero with full history.

If you vendor this framework and run the check in CI, set `fetch-depth: 0` on
your checkout (or the equivalent for your runner). The failure is loud rather
than silent, but its message points at the PLANs rather than at the clone
depth, which is the wrong place to start looking.

**Performance.** ~7s on a clean tree. The script spawns `awk` per PLAN per
`interfaces:` row and `grep -F` per ADR; this is acceptable for CI. A future
optimization could cache file reads in bash arrays.

Note for anyone extending it: the referenced-path check originally forked a
`grep` per referenced path, which took the script past 8s and pushed
`npm test` — which invokes it once per assertion that runs the gate — beyond
two minutes. It now matches against a newline-delimited string with `case`,
which forks nothing. Bash 3.2 is the macOS system bash and has no associative
arrays, so that is the available substitute for a set lookup.

---

## check-current-state.sh

`bash scripts/check-current-state.sh [base-ref]` (default `origin/trunk`).

**Purpose.** `ADR-0030` rule 3, specified by `FS-0022` §3: an ADR that changes
a rule must modify the current-state document carrying that rule in the same
change. A decision recorded only in the decision log leaves the document a
reader actually follows still saying the old thing.

For each ADR in scope, the check reads its `## Links` section, collects the
paths under `workflows/`, `guidelines/`, `skills/`, `templates/`,
`integrations/`, and `runbooks/`, and requires at least one of them to be
modified in the same change. A link naming a directory is satisfied by any
change beneath it; a link naming a file must match exactly.

**When it runs.** CI only, on `pull_request`. It needs the change set, and
`FS-0022` §3 requires `check-status.sh` to stay runnable against a working
tree with no diff context — so this is a separate script rather than a flag.
On a push to `trunk` the merge has already happened and there is no
meaningful base, so the job does not run.

**Scope, narrower than `FS-0022` §3's literal wording.** The spec says "every
ADR added or modified in a pull request". Read literally, a typo fix in an
accepted ADR whose Links name `workflows/session-modes.md` would demand an
unrelated edit to that workflow. `ADR-0030` rule 3 binds on *changing a rule*,
not on touching a file, and the detectable moment a rule becomes binding is
acceptance. **An ADR is in scope when the diff adds a `status: accepted`
line** — covering both an ADR added at `accepted` and one transitioning to it.
An ADR added as `proposed` is out of scope; its current-state update is due
when it is accepted.

**What a failure means.** The ADR names a document that carries the rule it
changed, and that document was not touched. Update the document — do not
delete the link.

**Not caught.** An ADR that changes a rule and names no current-state document
at all. That is a documentation defect the hygiene gate covers.

## check-freshness.sh

`npm run check:freshness` runs `bash scripts/check-freshness.sh`.

**Purpose.** Validates the freshness of the exported workflow/guideline surface
per `FS-0027`: every governed doc under `workflows/` and `guidelines/**`
(excluding `**/README.md` index files) must carry an `updated: YYYY-MM-DD`
front-matter field, and docs whose `updated:` date exceeds the staleness
threshold are reported as candidates for refresh or `status: stale` marking.

Two rules:

1. **Hard (exit non-zero):** a governed doc without `updated:` — or with an
   unparseable date — fails the gate. Freshness cannot be measured on a doc
   that does not say when it was last touched.
2. **Soft (printed, exit 0):** a doc whose `updated:` date is older than the
   threshold (default 90 days, override with `DOC_STALE_DAYS`) is reported as
   `STALE`. Deliberately non-fatal: a stale guideline is more dangerous flagged
   than deleted.

The front-matter extraction reads only the block between the first two `---`
lines, so an `updated:` appearing in prose is not accepted as the field. Dates
must be `YYYY-MM-DD` and are compared in epoch seconds; the age computation is
day-granular (`(now - epoch) / 86400`).

**Target resolution.** Per `FS-0024`/`ADR-0033`, the gate checks the git
repository containing the caller's working directory (`git rev-parse
--show-toplevel`), with an optional `CA_TARGET_REPO` override for a caller whose
working directory is not inside the repository it means to check — so a vendored
copy checks the host's `workflows/` and `guidelines/`, not the framework's own.

**Determinism.** `DOC_FRESHNESS_NOW` (epoch seconds) overrides the system clock
as the evaluation date, so tests can pin the date and keep stale-count
assertions stable.

**When it runs.** CI push and `pull_request` (the `check-freshness` job in
`.github/workflows/lint-docs.yml`), locally via `npm run check:freshness`.

## cross-repo-lint.sh

`npm run lint:cross-repo` runs `bash scripts/cross-repo-lint.sh`.

**Purpose.** Validates cross-repo consistency across the Tais-Den fleet
(conventional-agents, feral-fleet, pack-protocol):

1. **Agent-Attribution trailer format (FS-0017)** across recent commits on
   each repo's default branch
   (`Agent-Attribution: actor=…; model=…; role=…; session=…[; mode=…]`).
2. **README index consistency** — every governed doc under `docs/decisions/`,
   `docs/specifications/`, and `docs/change-plans/` appears in its
   `README.md` index.
3. **FS/PLAN numbering validity** — no duplicate IDs within a repo.

**Repo discovery.** Heuristic sibling lookup from the framework home, or
explicit via `CA_REPO_DIRS` (colon-separated repo roots) and `CA_TARGET_REPO`
(single repo, takes precedence). A vendored copy checks the host repository
when pointed at it explicitly. In a single-repo context (a CI runner, or a
checkout without siblings) the heuristic resolves to the repository present;
finding zero repositories is a hard failure, never a silent pass.

**Config.**
- `COMMIT_RANGE` — git log range for the attribution check. Explicit ranges
  must already exist locally; the script never fetches a remote and fails
  closed if either endpoint is unavailable. Without an override, the default is
  the OLDER of the newest `v*`-tagged release reachable from the default
  branch (via `git describe --first-parent`, keeping the anchor on the
  release line) and the `ATTRIBUTION_MIN_ANCHOR` floor, when either
  resolves in the linted repo — the audit is anchored so a missing
  trailer outside a fixed recent-commit window cannot pass, and a
  moved/re-tagged release cannot silently shrink the audited set
  (work item #141). Repos with neither a release tag nor a resolvable
  floor fall back to `origin/<default-branch>~20..origin/<default-branch>`.
- `ATTRIBUTION_MIN_ANCHOR` — convention-era floor for the audited range
  (default `v2.1.0`, parity with `test/FS-0017/commit-attribution.bats`).
  Only applies when the ref resolves in the repo being linted.
- `STRICT_TOOLS=1` — fail on missing tools instead of warning.

**When it runs.** Manually via `npm run lint:cross-repo`, or as step 5 of
`npm run validate`. The canonical runner sets an explicit range
(`HEAD~20..HEAD` locally, or the pull-request base range in CI). CI wiring
lives in `.github/workflows/lint-docs.yml` (the `lint-cross-repo` job): on `pull_request`
it audits the PR's own commits (`COMMIT_RANGE=origin/<base>..HEAD`), on push to
trunk the anchored post-release commits (release-tagged repos) or the last 20
trunk commits (untagged repos) for the standalone job. The workflow prepares
the refs before invoking either entry point; the script itself never fetches.
The workflow sets `CA_REPO_DIRS` to the runner
workspace only — the runner holds one repository (all three repos are private),
so the job is the fail-closed enforcement point for the calling repository. The
full three-repo sweep runs in the maintenance tick, which holds all three
checkouts on disk. Trigger paths: the job runs on any change matching the
workflow's `paths:` (any governed doc, `package.json`, `.github/**`,
`scripts/**`, `test/**`).

**Failure.** Exits non-zero when any repo has a malformed/missing attribution
trailer on an agent-authored commit, a doc missing from its README index, or
a duplicate FS/PLAN ID.

## check-conformance.sh
`npm run check:conformance` runs `bash scripts/check-conformance.sh`.
**Purpose.** Read-only consumer-conformance doctor (FS-0034, issue #142).
Diagnoses whether a repository that vendors this framework has adopted it
correctly: framework presence (`vendor/conventional-agents/`), AGENTS.md
anchors, dangling vendor references, status-gate runnability, CI wiring, and
framework version reference. Reports findings; never writes.
**Assumes the current vendoring layout.** The doctor hardcodes
`vendor/conventional-agents/` and the framework's current file layout
(`scripts/check-status.sh`, `AGENTS.md`, `INTEGRATION.md`). If the framework
later reorganizes its directory shape, the doctor's checks must follow; the
spec's out-of-scope list flags generalization to other vendor paths or future
layout changes as future work.
**Not a Category 1 governance gate.** Per ADR-0015, this script is optional
tooling, not a gate: it is not wired into CI as a failing check and does not
gate pull requests. Consumers may run it manually or in their own tooling.
**Target resolution.** Per FS-0024/ADR-0033, the target repository is
resolved from the caller's working directory (`git rev-parse
--show-toplevel`) or `CA_TARGET_REPO`. A vendored copy checks the host
repository, not the framework. When the target IS the framework itself
(self-check), the presence check is skipped.
**Output.** Human-readable by default; `--json` emits machine-readable
JSON. Exit codes: 0 = conformant, 1 = findings, 2 = usage error.
**When it runs.** Manually (`npm run check:conformance`) or in consumer
tooling. Not in CI.
**Diagnostic (#154).** Check 1 reports two distinct offender modes. `missing`
means the commit carries no `Agent-Attribution:` line at all — the trailer must
be written. `malformed` means one is present in the message body but
unreachable by git's trailer parser (displaced by a following paragraph, or a
value wrapped across continuation lines) — the line must be moved or unwrapped.
Both fail the gate — exit-code semantics are unchanged: any `BAD` line still
makes the run non-zero, so CI wiring is unaffected. Only the remedy differs.
The hermetic cases live in `test/FS-0017/attribution-diagnostic.bats`.

## run-bats.sh

`npm test` runs `bash scripts/run-bats.sh`.

The FS-0029 suites invoke shipped binding commands with `${CA_BASH_FOR_TESTS:-bash}`.
Set `CA_BASH_FOR_TESTS` to an explicit Bash 3.2 binary when validating the
documented macOS system-bash baseline, for example:

```sh
CA_BASH_FOR_TESTS=/path/to/bash-3.2 bats test/FS-0029
```

**Purpose.** Executes every `.bats` suite under `test/`. Suites are discovered
by sorted path, announced as `BEGIN`, bounded by `BATS_SUITE_TIMEOUT` (default
900 seconds), and reported with an elapsed whole-second timing and a `PASS`,
`FAIL`, or `TIMEOUT` verdict. A timeout is a failed suite; an empty `test/`
directory is also a failure. Per `FS-0022` §6, "a missing `bats` binary fails
loudly with an install hint, rather than passing vacuously."

**When it runs.**

- Manually: `npm test`.
- In CI as a separate job (see `lint-docs.yml`).
- Pre-commit testing gate (when `bats` is installed locally).

**Re-entrancy guard.** The script exports `RUN_BATS_ACTIVE` and refuses to run
if it is already set. Without it, a suite that invokes this script forks without
bound — each level re-runs every suite, including the one that invoked it. That
is not hypothetical: a test exercising the missing-`bats` path sanitised `PATH`
to `/usr/bin:/bin`, which excludes Homebrew's `bats` on macOS but *includes*
apt's `/usr/bin/bats` on Linux. It passed locally and exhausted the CI runner.

A test that deliberately exercises this script must opt out explicitly with
`env -u RUN_BATS_ACTIVE`.

**Dependencies.** `bats` and `rg` (ripgrep). Both are checked up front and both
fail with an install hint. ripgrep is required because several suites call it
directly with `-U` and `-A`, which have no clean POSIX equivalent — and because
a missing `rg` used to surface as every assertion failing with "expected <file>
to contain pattern" against files that matched perfectly well. The shared
`assert_file_contains` helper now uses `grep -F` for exactly that reason.

**Install hints** (when a dependency is absent):

- macOS: `brew install bats-core`
- Debian/Ubuntu: `apt-get install bats`

The framework does not vendor a test runner.

**Failure.** Exits non-zero on any failing assertion in any suite.

---

## new-plan.sh

`npm run new:plan` runs `bash scripts/new-plan.sh`.

**Purpose.** Scaffolds a PLAN stub from an ADR markdown file. Accepts `--adr DOC.md` (required), `--number PLAN-NNNN` (optional, auto-filled), and `--dry-run` (preview without writing).

**What it does.**

1. Parses the source ADR's frontmatter for `id`, `title`, `related_specs`, and `related_adrs`.
2. Extracts the Context, Decision Outcome, and Consequences sections from the ADR body (respecting MADR 4.0's nested heading structure).
3. Determines the next available PLAN number (or accepts one via `--number`).
4. Generates a PLAN file at `docs/change-plans/PLAN-NNNN-<slug>.md` with canonical frontmatter.

**Conventions.**

- Per `FS-0024`/`ADR-0033`: the target repository is resolved from the caller's working directory, not from the script's physical location. `CA_TARGET_REPO` overrides. A vendored copy creates the PLAN in the host repo.
- The generated frontmatter follows `templates/core/change-plan.md` (`type: change-plan`, `role: implementer`, `language`, `status: draft`, `related_specs`, `related_adrs`, `touches: []`, `created`, `updated`). No `title:` field — plans carry none per existing convention.
- Leading zeros on PLAN numbers are stripped safely via `sed` (avoiding bash's octal trap with `set -u`).
- Generator sections follow the template's numbered structure with placeholders derived from the ADR.

**When it runs.**

- Manually: `npm run new:plan -- --adr docs/decisions/ADR-XXXX.md`.
