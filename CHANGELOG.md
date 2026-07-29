# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

For this project (a documentation/standards kit), semver follows the
"Documentation and Standards Kits" semantics defined in
`workflows/versioning-and-releases.md`.

## [Unreleased]

### Added

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

### Removed

- `vendor/conventional-commits/` git submodule.
- `vendor/keep-a-changelog/` git submodule.
- `vendor/arc42-template/` git submodule.
- `docs/instances/` directory and `IDEA.md` (relocated to
  `Tais-Den/tais-den-conventions` per ADR-0016).
- `docs/implementation-plans/` legacy directory.

### Notes for release

- **A version decision is required and is not made here.** Several changes are
  contract-affecting for consumers: the attribution convention (`ADR-0029`), the
  substrate capability model (`ADR-0024`, `ADR-0028`), the approval mechanism
  (`ADR-0026`), and PLAN self-approval (`ADR-0027`) — a consumer adopting that
  inherits the reserved-path set along with it. Whether that is a minor or major bump is a human call
  per `guidelines/ROLE_CONTRACT.md`.
- Every document added in this cycle is `draft` or `proposed`. Nothing here is
  binding until approved.

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
