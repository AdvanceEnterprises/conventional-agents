# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

For this project (a documentation/standards kit), semver follows the
"Documentation and Standards Kits" semantics defined in
`workflows/versioning-and-releases.md`.

## [Unreleased]

### Added

#### Template and instance repository forms (`ADR-0032`, proposed)

- **`INTEGRATION.md` gains a "Template and instance repositories" section.** If you run
  more than one repository against this framework, it gives you a test for which content
  belongs where: *would a second adopter's copy have to change it?* Yes → instance
  (hostnames, IPs, secrets, board IDs, absolute paths); no → template (roles, scripts,
  contracts, scaffolds).
- The rule is **a template repository carries no instance data; an instance repository
  owes no one a template.** The second half is the point — declaring a repo an instance
  explicitly frees it from any obligation to generalize, so you do not pay the cost of
  extracting a reusable form before a second instance exists to justify it.
- Recommends putting placeholders **in filenames** (`APP_NAME-ENV-app.container`,
  `*.env.example`) so instance data cannot be added without visibly renaming the file.
- `ADR-0032` is `proposed`, and the guidance is a convention — nothing enforces it and
  no existing repository is required to change. The table of contents renumbers: the new
  section is 5, and everything after it shifts by one.

## [2.1.0] - 2026-08-01

> Released 2026-08-01. `FS-0018`–`FS-0023` and `PLAN-0018`–`PLAN-0023` moved to
> `implemented` when this release was cut; they were left at `approved` when the
> work merged, which `workflows/document-lifecycle.md` places in the completing PR.
> Nothing detects "merged but never marked" — recorded in `BACKLOG.md`.

This release carries the work-item layer (FS-0018), the multi-model collaboration
framework (FS-0019, FS-0021, ADR-0031), the platform-neutral substrate model
(ADR-0024, ADR-0028), the single-identity attribution convention (ADR-0018,
ADR-0029), the approval model (ADR-0026, ADR-0027), and the runbook document type
(FS-0023). No consumer is forced to migrate by this release — every addition is
opt-in — but several contracts are now better-defined and a consumer adopting a
new surface should expect to read its governing ADR before integrating.

### Added

#### Runbooks — a new exported surface (`FS-0023`)

- **`runbooks/` is a new top-level directory you receive when you vendor the
  framework**, alongside `workflows/` and `integrations/`. A runbook records an
  operational procedure *as performed against a real substrate* — what was actually
  done, in order, and what the substrate did back. `workflows/` tells you how work
  should proceed and `integrations/` tells you how a capability maps onto a platform;
  a runbook tells you what happened when someone tried it.
- Runbooks use their own status vocabulary — `current`, `stale`, `superseded` — not
  the `draft → approved → implemented` model used by specs and plans. If you have
  tooling that reads `status:` from framework documents, it will encounter these three
  new values under `runbooks/`. `stale` is deliberately cheap to set and needs no
  review: a procedure that has quietly stopped matching its substrate is more
  dangerous than one flagged unverified.
- Every runbook carries `last_verified:` and `verified_by:`, recording when someone
  last ran the procedure end to end and watched it work — not when the file was last
  edited.
- A runbook's **Deviations Observed** section is mandatory even when empty (recorded
  as "None observed on `<date>`"). It is where the gap between a binding and the
  substrate's real behaviour gets written down, so it can flow back into
  `integrations/` instead of staying folklore.
- Scaffold at `templates/core/runbook.md`; convention and index at
  `runbooks/README.md`; lifecycle in `workflows/document-lifecycle.md`.
- No runbooks ship yet. The first documents provisioning this repository's own GitHub
  Issues and Projects configuration.

#### `deprecated` is now a change-plan status

- `workflows/document-lifecycle.md` adds `deprecated` to the PLAN status table. Feature
  specs and ADRs have always had it; a plan whose governing spec was deprecated had
  nowhere to go. If you have tooling that reads `status:` from change plans, it can now
  encounter this value.

#### `CONTRIBUTING.md`: how to test a governance gate

- New "Changing a Governance Gate" section. The rule is that a gate's test must break
  the thing the gate protects and confirm the gate notices — not that the check runs,
  and not that some file contains some string. Four gates in this repository shipped
  enforcing nothing and every one passed its own test suite; the section names them and
  gives the shape of a test that would have caught them.
- Includes the CI-portability traps that cost the most here: a shallow clone with no git
  history, a `PATH` that excluded a tool on one platform and included it on another, and
  a missing dependency whose "command not found" was swallowed by a redirect and read as
  a failed assertion.

#### Three gate checks were silently enforcing nothing — fixed

- **ADR structural completeness** matched required sections with an unanchored
  fixed-string search, so `## Consequences-renamed` satisfied the `## Consequences`
  requirement — as would a `### Consequences` subheading elsewhere in the file, or the
  words appearing in prose. Renaming or demoting a required section left the check
  green. It now matches a whole heading line at H2 or H3. The H3 allowance is
  deliberate: MADR 4.0 nests `### Consequences` under `## Decision Outcome`, and
  requiring H2 would fail correctly-structured ADRs.

#### Two more gate checks were silently enforcing nothing — fixed

- `npm run check:status`'s **FS/PLAN index title sync** and **consumer-impact CHANGELOG**
  checks both resolved a document as `<dir>/<ID>.md`. Every spec and plan in this
  repository carries a descriptive suffix (`FS-0018-issue-lifecycle-….md`), so neither
  path ever resolved and both checks skipped every document while reporting success.
  If you vendor this framework and rely on either check, **they were not protecting
  you.** Both now resolve by ID and tolerate bare or suffixed filenames.
- The consumer-impact rule — an FS naming exported-surface paths must have a CHANGELOG
  entry — is therefore enforced for the first time. If you have specs at `approved` or
  beyond whose `interfaces:` name `guidelines/`, `roles/`, `skills/`, `templates/`,
  `workflows/`, `integrations/`, `runbooks/`, `INTEGRATION.md`, or `AGENTS.md`, expect
  new failures until each has an entry naming it.
- PLAN rows are resolved but no longer title-compared: change plans carry no `title:`
  field, so the comparison reported every plan as drifted.
- An index row naming a file that does not exist is now reported as an orphan rather
  than skipped.

#### ADR-0030 rule 3 is now enforced in CI (`FS-0022` §3)

- New `scripts/check-current-state.sh`, run by a `current-state-update` job on pull
  requests. When an ADR becomes `accepted`, at least one of the current-state documents
  its `## Links` name — under `workflows/`, `guidelines/`, `skills/`, `templates/`,
  `integrations/`, or `runbooks/` — must be modified in the same change. If you vendor
  this framework and run its CI, an ADR that changes a rule without updating the
  document carrying that rule will now fail the build.
- Scope is **acceptance**, not every edit: the check keys on the diff adding a
  `status: accepted` line, so typo fixes and status-preserving edits do not trigger it.
- The rule itself is unchanged. `ADR-0030` has required this since it was accepted;
  only the enforcement is new.

#### Broken references in two skills fixed (`FS-0022` §1c)

- `skills/framework-health-audit/SKILL.md` and `skills/git-gh-workflow/SKILL.md` pointed
  at `docs/decisions/ADR-0011.md`, `ADR-0012.md`, and `docs/specifications/FS-0013.md`.
  Those files acquired descriptive suffixes; the references were never updated. If you
  followed either skill's reading list, three of the documents it told you to read were
  not at the paths given. Now corrected.
- `npm run check:status` gained a **referenced-path resolution** check that would have
  caught this. Every path a current-state document names in backticks must resolve.
  Decision records (ADR, FS, PLAN), `BACKLOG.md`, and `CHANGELOG.md` are out of scope,
  as are bare filenames like `tsconfig.json` — those name files in *your* repo, not the
  framework's. If you vendor this framework and run its checks, expect the same
  scoping.

#### Review feedback fixes

Per reviewer feedback on the bootstrap package:

- `approved_by:` strengthened to require a real human-approval record: the most
  recent commit touching the PLAN file must carry an `Approved-By:` trailer whose
  name+email match the front matter, and the trailer's author must differ from
  the commit author (per `ADR-0026`). This closes the self-writable bypass
  identified in the review.
- `ADR-0027` acceptance commit message amended to state the actual reason: the
  user instructed "commit those first actually" for the unstaged commit-pair
  carried over from the prior session, and at `ab2a4f2` both file and index
  read `proposed`. The previous message's "index row was already accepted"
  justification was incorrect and has been corrected.
- Per-directory lint exemptions removed. The `markdownlint --fix` chain
  auto-fixed 452 of 455 violations in the widened corpus; the remaining 3 are
  content issues fixed by hand (added H1 to `roles/ROLE_CONTRACT.md` for
  `MD041`; replaced HTML placeholders with backtick text in templates).
  Lint coverage now actually catches drift instead of hiding it.
- `INTEGRATION.md` fenced and re-linted, closing the last lint exclusion. The
  document had never used code fences, so its shell commands and its embedded
  example `AGENTS.md` files were parsing as markdown headings — 165 violations
  that `markdownlint --fix` could not fix and in fact made worse by splitting
  contiguous shell scripts. Code regions are now fenced (`bash`, `text`,
  `yaml`), the bare-prose section titles are real headings, and the
  tab-delimited pseudo-table under "Detailed precedence" is a markdown table.
  Prose is unchanged: 388 content lines before and after, verified by diffing
  token streams with markup stripped. `lint:roots` no longer excludes it, and
  all six root files lint clean with no rule exemptions.
- `INTEGRATION.md` table of contents now lists "Consumer Issue Configuration
  (Work Item Lifecycle, FS-0018)", renumbering the entries after it to 3–9.
  `FS-0018` added that section without a ToC row; the omission was invisible
  while the ToC was tab-indented prose and became obvious once it rendered as
  a list. The ToC and the document's nine `##` sections now correspond
  one-to-one, and nothing in the document cross-references section numbers.
- FS-0018/19/20/21 `interfaces:` reverted to their pre-`dddb25c` state. The
  four files added to FS-0020's interfaces (README.md, AGENTS.md,
  INTEGRATION.md, CHANGELOG.md) are removed; `PLAN-0020` and `PLAN-0021`
  now carry `approved_by:` for their human-approved consumer-surface touches.
- CI workflow extended: `lint-docs-widened` job runs the full `npm run
  lint:docs` chain; `test-bats` job runs `npm test`. Both gate merge per
  `FS-0022` §5.
- Grandfather clause for pre-`ADR-0027` plans replaced with an explicit
  allow-list (`PLAN-0005-move-workflow-skills-into-agent-dev-kit.md`). Agent-
  writable `created:` dates can no longer be backdated to skip the check.

#### Gate coverage

- `FS-0022` and `PLAN-0022`: gate coverage — extend consistency, lint, and test
  enforcement to the whole corpus.
- `scripts/check-status.sh`: extended with ADR index consistency (titles +
  statuses, both directions), FS/PLAN index title sync, ADR structural
  completeness, PLAN `touches:` containment against governing FS's
  `interfaces:` and the reserved-path set, and consumer-impact CHANGELOG
  declaration. Reads file IDs from front matter rather than filename, so the
  `FS-NNNN-description.md` naming convention works.
- `scripts/README.md`: documents every check (purpose, when it runs, what a
  failure means).
- `scripts/run-bats.sh`: executes every `.bats` suite under `test/`. Fails
  loudly with an install hint when `bats` is absent.
- `npm test`: runs the bats suite. CI job to run `npm test` separately.
- `npm run lint:docs`: widened globs to cover `guidelines/`, `skills/`,
  `templates/`, `integrations/`, `roles/`, and root-level docs.
- Per-directory `.markdownlint.yml` files for `guidelines/`, `skills/`,
  `templates/`, and `roles/` to silence mechanical whitespace noise in legacy
  content.
- `test/FS-0022/gate-coverage.bats`: 14 schema and text assertions across
  the four new checks, npm test execution, scripts/README.md coverage, and
  consumer-impact reporting.
- `test/FS-0001/adr-linting.bats` and `test/FS-0017/commit-attribution.bats`:
  updated for the world-state changes the new checks reveal (consolidated
  CI workflow, restored `roles/ROLE_CONTRACT.md` as delegating document,
  Codex actor in the email list, ADR-0018 accepted).
- `docs/specifications/FS-0018/19/20/21` `interfaces:` widened to cover the
  files their PLANs actually modify.
- `docs/change-plans/PLAN-0018/19` gained `touches:` fields (pre-existing
  PLANs lacked them; ADR-0027 grandfather-clause exempts plans authored
  before ADR-0027's `created:` date).
- `docs/decisions/ADR-0027-plan-self-approval-within-declared-interfaces.md`
  gained `created:` and `updated:` front-matter fields.
- `docs/decisions/README.md` and `docs/specifications/README.md`: titles
  regenerated from file front matter (per §5a).

#### Review board (optional)

- `FS-0021`: review board collaboration mode — several models examine one artifact from
  different role stances and findings are merged rather than compared. Disabled by
  default; ships advisory-only.
- `config/review-board.yml`: consumer-copy template, `enabled: false`, empty seats,
  `min_models: 2`, `min_roles: 2`. No `--allow-gate-overlap` override (ADR-0023
  Constraint 3).
- `test/FS-0021/review-board.bats`: 20 schema and text assertions covering composition,
  findings, coverage, gate independence, and advisory boundary.
- `INTEGRATION.md` §"Review boards (optional)": what a board is, how it differs from
  consensus, opt-in steps, and the no-override-flag rule.

#### SDLC workflows

- `FS-0020`: two SDLC workflows — single-model and multi-model — over one shared
  seven-phase spine. Collaboration rounds are available only in the multi-model workflow.
- `workflows/sdlc-single-model.md` and `workflows/sdlc-multi-model.md` — current-state
  documents for the two workflows. Identical spine, identical gates, identical role
  prohibitions; differing only on whether collaboration rounds attach.
- `workflows/session-modes.md` §"Workflows vs. session modes" — distinguishes mode
  (stance within a phase) from workflow (phase sequence).
- `test/FS-0020/sdlc-workflows.bats` — cross-document consistency suite that catches
  drift between the two workflow documents.
- `INTEGRATION.md` §"SDLC workflow selection" — guidance for choosing between workflows.
- `README.md` and `AGENTS.md` pointer entries.

#### Multi-model consensus (optional)

- `FS-0019`: optional, consumer-implemented multi-model consensus at workflow gates
  (Gate A pre-submission, Gate B review-time). The framework supplies vocabulary,
  artifact shape, gate placement, and failure modes; consumer repos implement the
  orchestration. Ships **disabled** at the framework level; the framework's own
  evolution does not use consensus.
- `ADR-0023`: collaboration integrity constraints. The different-models requirement is
  non-overridable; consensus ships disabled and `models: []` is the framework's empty
  default. Override can turn consensus *on* for a document; it cannot relax
  different-models.
- `config/consensus.yml`: consumer-copy template, unchanged and asserted by bats.
- `workflows/document-lifecycle.md` §"Multi-model Consensus Gates" — Gate A and Gate B
  documented as optional, default-disabled checkpoints.
- `skills/git-gh-workflow/SKILL.md` §"Consensus Rounds" — round initiation, audit trail,
  and failure modes.
- `workflows/git-and-gh-conventions.md` §"Consensus-round comments" — the
  `agent-stance: mode=consensus; …` and `consensus-override: <reason>` comment forms.
- `templates/core/feature-spec.md` and `templates/core/change-plan.md` gain optional
  `consensus_required` front-matter field.

#### Work item lifecycle and autonomous triggers

- `FS-0018`: work item as the canonical entry point for governed work, with a three-axis
  schema (Type, Label, Phase), three origination paths, the `agent-stance:` activity-record
  format, and the autonomous gate keyed by Type. Convention-level enforcement on most
  substrates; audit-trail detection everywhere.
- `ADR-0019`: Type is human-mutable only; agents may flag a wrong Type via the activity
  record but never edit it. The autonomous gate is Type-keyed.
- `ADR-0020`: while the `question` label is set, agents perform no work-item transitions.
- `ADR-0021`: cron-fired (unattended) actors carry a distinct `user.email`, `mode=autonomous`,
  and `session=<job-name>` so the audit trail distinguishes attended from unattended work.
- `ADR-0022`: `autonomous`, `consensus`, and `review-board` are meta-modes composed with a
  declared role, not new session modes.
- `workflows/document-lifecycle.md` §"Work Items" — lifecycle summary added above the
  FS/PLAN/ADR state machine.
- `skills/git-gh-workflow/SKILL.md` §"Work-Item Stance and Autonomous Gates" — operational
  rules for `agent-stance:` entries and the Type-keyed checkpoint table.
- `workflows/git-and-gh-conventions.md` §"Issue / work-item stance" — the stance format and
  extended actor table with unattended-actor email aliases.

#### Platform neutrality and substrate bindings

- `ADR-0024`: platform-neutral core with shipped bindings. The framework names
  six substrate *capabilities*; a binding maps them onto one platform. Bindings
  are written first and in full, and the neutral core is extracted from them —
  never forecast ahead of one.
- `integrations/` as exported surface, with `integrations/README.md` as the
  current statement of the six capabilities and
  `integrations/github-issues-projects.md` as the reference binding.
- `ADR-0028`: level-triggered reconciliation. A scheduled reconciler is the
  correctness guarantee; events are a latency optimization. A substrate must be
  *enumerable*; event notification is optional and never the sole trigger.

#### Collaboration modes

- `ADR-0031`: structured multi-model collaboration. Three artifacts per round —
  contributor outputs to a declared contract, a synthesis preserving
  disagreement, and on gated rounds a verdict from an evaluator outside the
  participant set.
- `FS-0021`: the review board, where several models examine one artifact from
  *different role stances* and findings are merged rather than compared.
- `templates/collaboration/`: contributor prompt, gate, consensus synthesis, and
  review-board findings templates.
- `review-board` as a third meta-mode alongside `autonomous` and `consensus`.
- `docs/orchestration/multi-model-pilot-001/`: preserved evidence from a
  multi-model run this work was extracted from — four contributors, two
  transports, 54 claims, three gate rounds.

#### Workflows and approval

- `FS-0020`: two SDLC workflows — single-model and multi-model — over one shared
  seven-phase spine. Collaboration rounds are available only in the multi-model
  workflow.
- `ADR-0026`: approval is a recorded act. Merge approval remains the default,
  joined by recorded approval (in-session, carrying an `Approved-By:` trailer)
  and deferred approval.
- `ADR-0027`: a change plan may self-approve when its `touches:` falls inside
  the governing spec's `interfaces:` and touches no reserved path.
- `touches:` field on the change-plan template, declaring the paths a plan will
  modify.

#### Governance and attribution

- `ADR-0030`: decision records versus current-state documents. ADRs record why a
  rule is what it is; exported documents state what it is, and an ADR changing a
  rule must update the governing document in the same change.
- `ADR-0025`: rebase-merge as the default, so per-commit attribution survives to
  trunk.
- `ADR-0029`: `user.name` carries the model, `user.email` carries the actor.
- `FS-0022` and `PLAN-0022`: gate coverage — ADR index validation, `touches:`
  containment, referenced-path resolution, widened lint coverage, and CI
  execution of the `bats` suites, which currently run nowhere.
- `BACKLOG.md`: deferred work, known gaps, and the enforcement obligations this
  release leaves for its PLANs.

#### Framework-internal vendor boundary (prior cycle)

- `ADR-0017`: Framework vendor directory is internal; consumers must not
  reference nested submodules.
- `FS-0016`: Framework Internal Vendor Boundary feature spec.
- `PLAN-0016`: Implementation plan for FS-0016.
- `skills/framework-consumer-integration/SKILL.md`: a skill that guides agents
  through integrating conventional-agents into a host repository, selecting the
  right pattern, writing `AGENTS.md`, and avoiding common mistakes such as
  nested vendor paths.
- `test/FS-0016/vendor-boundary.bats`: asserts that no consumer-facing file
  references `vendor/conventional-agents/vendor/...` paths.

### Changed

- **ADR-0001 through ADR-0010 are now `accepted`.** Their files carried
  `proposed` while the index recorded `accepted`; the index was correct and the
  files were never updated after merge.
- **The ADR index was substantially inaccurate.** Eleven of thirteen early rows
  named decisions that exist in no ADR file. All 30 rows are now generated from
  their files.
- `ADR-0013` revised: attribution reconciled to `ADR-0018`/`ADR-0029`, artifact
  scope unified with `touches:`, session declarations made durable, and Mode 2
  identified as the same shape as an `ADR-0031` collaboration round.
- `ADR-0014` scoped to tasks spawned by a session. A scheduled or trigger-fired
  session is a primary in its own right with no human watching, not a parentless
  background task.
- `ADR-0015` gained the Validation section its own process requires.
- `ADR-0022` gained `review-board`; the mode vocabulary is now eight values.
- `ADR-0023` extended from consensus to both collaboration modes, and gained the
  constraint that a gate evaluator may not have participated in the round it
  evaluates.
- `FS-0018` restated in capability vocabulary — work item, Type, Phase — with
  platform mechanics moved to the binding.
- `FS-0019` corrected: a Mixture-of-Agents aggregator is the synthesizing
  primary and never the gate; a coverage record now prevents partial coverage
  being read as agreement; gate execution status is separate from verdict.
- `workflows/git-and-gh-conventions.md`, `workflows/document-lifecycle.md`,
  `workflows/session-modes.md`, and `skills/git-gh-workflow/SKILL.md` updated to
  match the decisions above.
- `README.md` and `AGENTS.md`: surface tables now list `integrations/` and
  `BACKLOG.md`.

#### Framework-internal vendor boundary (prior cycle)

- **Framework vendor directory is now internal** (ADR-0017). Consumers must not
  reference nested vendor paths such as `vendor/conventional-agents/vendor/...`.
  This is a conceptual-contract tightening, not a working-tree breakage for
  consumers that already referenced framework files or upstream URLs.
- `README.md`: reorganized "Exported Surface vs Internal Governance" table,
  added "For Projects Consuming This Framework" and "For Agents Working on This
  Repo" sections, and updated "Upstream References" to list URLs as canonical
  with framework-subset pointers.
- `AGENTS.md`: rewritten as an agent instructions document with On Entry,
  Foundation Standards, Working on the Framework Itself, Process Gates,
  Non-Overridable Safety Gates, and consumer guidance sections.
- `INTEGRATION.md`: added a "Choosing a Pattern" decision table and
  troubleshooting entries for consumer conventions and nested vendor path
  leaks.
- `workflows/git-and-gh-conventions.md`, `workflows/versioning-and-releases.md`,
  `CHANGELOG.md`, `skills/git-gh-workflow/SKILL.md`: removed stale
  parenthetical references to dropped `vendor/conventional-commits/` and
  `vendor/keep-a-changelog/` submodules.
- Historical documents updated with status notes linking to ADR-0017:
  `docs/ARC42.md`, `docs/decisions/ADR-0003.md`,
  `docs/specifications/FS-0009-vendor-upstream-specs.md`,
  `docs/change-plans/PLAN-0009-vendor-upstream-specs.md`.

### Deprecated

- **`FS-0002` / `PLAN-0005` (move workflow skills into the framework) — never
  implemented, now deprecated.** They specified ten generator and review skills
  (`adrgen`, `specgen`, `changeplangen`, `stubgen`, `instructionlint`, `skillindex`,
  `prreview`, `specreview`, `testreview`, `newskill`) with Python helpers and dual-mode
  template path resolution. None of the ten has ever existed on any branch. If you were
  waiting on those skills, they are not coming under this spec — the `skills/` directory
  ships a different, documentation-oriented set.
- The dual-mode path-resolution requirement is **not** retired with the spec: a helper
  script shipped by this framework should still resolve templates from `./templates/…`
  when run inside the framework and `./vendor/conventional-agents/templates/…` when run
  from a host repo. It is recorded in `FS-0002`'s Status section for whatever ships
  executable tooling next.

### Removed

- `vendor/conventional-commits/` git submodule.
- `vendor/keep-a-changelog/` git submodule.
- `vendor/arc42-template/` git submodule.
- `docs/instances/` directory and `IDEA.md` (relocated to
  `Tais-Den/tais-den-conventions` per ADR-0016).
- `docs/implementation-plans/` legacy directory.

## [2.0.0] - 2026-06-08

### Breaking Changes

- **Project renamed** from `agentic-dev-kit` to `conventional-agents`. Host repos vendoring this framework must update their submodule path from `vendor/agentic-dev-kit/` to `vendor/conventional-agents/` and update all references accordingly.
- **ROLE_CONTRACT restructured**: roles renumbered from 3 roles (1–3) to 6 roles (0–5). Role 1 (Spec Reader) is now Role 2; Role 2 (Implementer) is now Role 3; Role 3 (Reviewer) is now Role 4. Projects that reference roles by number must update.

### Added

- FS-0013: Status consistency check — validates FS↔PLAN status pairing and README index table sync.
- PLAN-0013: Change plan for FS-0013 implementation.
- `scripts/check-status.sh`: machine-readable consistency check; exits non-zero on violations.
- `npm run check:status`: local entrypoint for the consistency check.
- `check-status` CI job in `lint-docs.yml`: blocks merges when status is out of sync.
- FS-0014: Role definitions overhaul — six roles: Head Architect (0), Document Author (1), Spec Reader and Test Planner (2), Implementer (3), Reviewer (4), Communications Lead (5).
- PLAN-0014: Change plan for FS-0014 implementation.
- FS-0015: Role selection and session modes — `best_used_when`/`avoid_when` guidance per role, five named session modes, explainability convention.
- PLAN-0015: Change plan for FS-0015 implementation.
- `workflows/session-modes.md`: five session modes (Architecture Planning, Document Authoring, Implementation, Review, Communications), each with primary role, supporting roles, escalation triggers, and role-transition phrase templates.
- GitHub Project board "conventional-agents Development" ([#2](https://github.com/orgs/Tais-Den/projects/2)) with Status columns and Doc Type field.
- `config/project.yml` documenting board metadata and field IDs for programmatic access.
- FS-0011: Adopt GitHub Projects for work tracking.
- PLAN-0011: Change plan for FS-0011 implementation.
- FS-0012: Renumber feature specs to sequential IDs (eliminate FS-0003–FS-0010 gap).
- PLAN-0012: Change plan for FS-0012 implementation.

### Changed

- `guidelines/ROLE_CONTRACT.md` and `roles/ROLE_CONTRACT.md`: full rewrite — three new roles (Head Architect, Document Author, Communications Lead); conflict-resolution precedence corrected to six levels (Level 0 = ADR-0012 non-overridable gates); stale `docs/specs/` path fixed to `docs/specifications/FS-*.md`; `npm run check:status` assigned to Document Author and Implementer; `roles/ROLE_CONTRACT.md` populated (was empty); `best_used_when`/`avoid_when` and role and session transparency rule added.
- All feature spec IDs renumbered to sequential. Mapping: FS-0011→0003, FS-0012→0004, FS-0013→0005, FS-0014→0006, FS-0015→0007, FS-0016→0008, FS-0017→0009, FS-0018→0010, FS-0019→0011, FS-0020→0012. PLAN filenames updated to match.
- Reconciled stale `approved` statuses on 7 FS and 7 PLAN docs to `implemented`, reflecting work delivered in v1.0.0–v1.2.0.
- Document hygiene gate checklist updated: item 7 added (run `check:status` before marking PR ready).
- All references to `agentic-dev-kit` and `agent-dev-kit` updated to `conventional-agents` throughout.
- Note: FS-0005 and PLAN-0003 were marked `implemented` directly from `draft`/`approved` — a process irregularity documented for traceability.

## [1.2.0] - 2026-02-16

### Added

- Non-overridable safety gates ("super-gates") — a new precedence level (level 0) above project AGENTS.md (ADR-0012, FS-0010 (formerly FS-0018)).
- PR merge prohibition: agents must not merge pull requests (non-overridable safety gate).
- GitHub identity verification gate: agents must run `gh auth status` before every `gh`/`git push` operation (non-overridable safety gate).
- Spec-first rule in ROLE_CONTRACT: approved FS + PLAN required before implementation; exceptions for trivial fixes and hotfixes.
- Document hygiene gate in ROLE_CONTRACT: 6-item pre-commit/PR checklist (statuses, dates, READMEs, CHANGELOG, cross-refs, interface alignment).
- `workflows/document-lifecycle.md` — status values, transition rules, front matter hygiene, README index maintenance for FS/PLAN/ADR documents.
- Document index tables in `docs/specifications/README.md`, `docs/change-plans/README.md`, and `docs/decisions/README.md` with agent-update requirements.
- Vendored upstream specs: Conventional Commits (`vendor/conventional-commits/`) and Keep a Changelog (`vendor/keep-a-changelog/`) as git submodules (FS-0009 (formerly FS-0017), PLAN-0009). These submodules were later removed from the consumer-facing surface in v2.1.0 per ADR-0017; consumers now reference framework files and upstream URLs.
- "Upstream References" section in README with vendored specs and joelparkerhenderson ADR resource.
- ADR-0012: Introduce non-overridable gates (super-gates).
- FS-0009 (formerly FS-0017), FS-0010 (formerly FS-0018), PLAN-0009, PLAN-0010.

### Changed

- INTEGRATION.md precedence model: added level 0 for non-overridable safety gates; renumbered existing levels.
- `workflows/git-and-gh-conventions.md`: added identity verification step 0 and merge prohibition in step 8.
- `workflows/README.md`: added missing `versioning-and-releases.md` entry and new `document-lifecycle.md` entry.
- ROLE_CONTRACT: "Non-Overridable Safety Gates" section clearly labeled and scoped per ADR-0012.
- Vendor path references in INTEGRATION.md normalized from `conventional-agents` to `conventional-agents`.

### Fixed

- INTEGRATION.md tool configs precedence row was self-referencing ("Must defer to 1 to 5" → "Must defer to 0 to 4").
- PLAN-0005 status normalized from non-standard `ready` to `approved` per lifecycle vocabulary.

## [1.1.0] - 2026-02-08

### Added

- JavaScript/TypeScript guidelines: `JS_STYLE_GUIDE.md`, `JS_TESTING_GUIDE.md`, `JS_IMPLEMENTATION_GUIDE.md` under `guidelines/javascript/` (FS-0006 (formerly FS-0014), PLAN-0006).
- Versioning, releases, and packaging workflow: `workflows/versioning-and-releases.md` — covers semver by project type, changelog conventions, agent-safe vs human-gated actions, dependency and submodule versioning (FS-0007 (formerly FS-0015), PLAN-0007).
- BDD/TDD pre-commit testing gate in `guidelines/ROLE_CONTRACT.md` — agents must run tests before committing, must not commit with failing tests.
- Versioning constraints in `guidelines/ROLE_CONTRACT.md` — agents must not bump major versions or publish without human approval; version bumps are release-prep only.
- Version-number discipline in all three implementation guides (Bash, Python, JS/TS) — do not change version numbers during feature work.
- Exported surface vs internal governance split documented in `README.md`.
- `CHANGELOG.md` (this file) with retroactive entries.
- `agentic-bootstrap-constitution` template repo created as the recommended project starter.

### Changed

- Project renamed from `conventional-agents` to `conventional-agents` (repo: `Tais-Den/conventional-agents`). Vendored mount path remains `vendor/conventional-agents/` for backward compatibility.
- `docs/workflows/` moved to `workflows/` (exported surface, not internal docs).
- CI workflow file renamed from `lint-adrs.yml` to `lint-docs.yml`; now lints ADRs, specs, change plans, and workflows.
- `package.json` lint scripts updated: added `lint:specs`, `lint:plans`, `lint:workflows`, `lint:docs`; scripts use `npx` for local execution.
- README submodule/clone URLs updated to `Tais-Den/conventional-agents`; default branch reference changed to `trunk`.

### Fixed

- ADR-0004 precedence wording corrected (was "highest-numbered wins", now "lowest-numbered/highest-priority wins").
- `INTEGRATION.md` directory tree corrected (showed `conventional-agents/` instead of `conventional-agents/` for vendored path).

## [1.0.0] - 2026-01-27

### Added

- Initial framework release.
- Bash guidelines: `BASH_STYLE_GUIDE.md`, `BASH_TESTING_GUIDE.md`, `BASH_IMPLEMENTATION_GUIDE.md`.
- Python guidelines: `PYTHON_STYLE_GUIDE.md`, `PYTHON_TESTING_GUIDE.md`, `PYTHON_IMPLEMENTATION_GUIDE.md`.
- Role Contract (`guidelines/ROLE_CONTRACT.md`) with Docs → Tests → Code workflow.
- Core templates: feature spec, ADR (MADR), change plan, architecture (ARC42).
- Reviewer templates: PR review, spec review, test review.
- Architecture documentation (`docs/ARC42.md`).
- ADRs 0000–0011 establishing framework decisions.
- Feature specs FS-0001 through FS-0005 (formerly FS-0001, FS-0002, FS-0011, FS-0012, FS-0013).
- Git and GitHub CLI conventions workflow (`workflows/git-and-gh-conventions.md`).
- Integration guide (`INTEGRATION.md`) with precedence rules and tool-specific patterns.
- Markdownlint CI for ADRs, specs, change plans, and workflows.
- Vendor submodules: MADR v4.0.0, arc42 template.
