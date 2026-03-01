# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com) (vendored at `vendor/keep-a-changelog/`),
and this project adheres to [Semantic Versioning](https://semver.org).

For this project (a documentation/standards kit), semver follows the
"Documentation and Standards Kits" semantics defined in
`workflows/versioning-and-releases.md`.

## [Unreleased]

### Added

- GitHub Project board "agentic-dev-kit Development" ([#2](https://github.com/orgs/Tais-Den/projects/2)) with Status columns (Backlog/Approved/In Progress/In Review/Done) and Doc Type field (FS/PLAN/Task/Bug).
- `config/project.yml` documenting board metadata and field IDs for programmatic access.
- Backfilled 22 GitHub Issues (11 FS + 11 PLAN) covering all existing governance documents.
- FS-0011: Adopt GitHub Projects for work tracking (propagation from pack-protocol ADR-0001/ADR-0002).
- PLAN-0011: Change plan for FS-0011 implementation.
- FS-0012: Renumber feature specs to sequential IDs (eliminate FS-0003–FS-0010 gap).
- PLAN-0012: Change plan for FS-0012 implementation.

### Changed

- All feature spec IDs renumbered to sequential (FS-0012). Mapping: FS-0011→0003, FS-0012→0004, FS-0013→0005, FS-0014→0006, FS-0015→0007, FS-0016→0008, FS-0017→0009, FS-0018→0010, FS-0019→0011, FS-0020→0012. PLAN filenames updated to match. All cross-references updated.

## [1.2.0] - 2026-02-16

### Added

- Non-overridable safety gates ("super-gates") — a new precedence level (level 0) above project AGENTS.md (ADR-0012, FS-0010 (formerly FS-0018)).
- PR merge prohibition: agents must not merge pull requests (non-overridable safety gate).
- GitHub identity verification gate: agents must run `gh auth status` before every `gh`/`git push` operation (non-overridable safety gate).
- Spec-first rule in ROLE_CONTRACT: approved FS + PLAN required before implementation; exceptions for trivial fixes and hotfixes.
- Document hygiene gate in ROLE_CONTRACT: 6-item pre-commit/PR checklist (statuses, dates, READMEs, CHANGELOG, cross-refs, interface alignment).
- `workflows/document-lifecycle.md` — status values, transition rules, front matter hygiene, README index maintenance for FS/PLAN/ADR documents.
- Document index tables in `docs/specifications/README.md`, `docs/change-plans/README.md`, and `docs/decisions/README.md` with agent-update requirements.
- Vendored upstream specs: Conventional Commits (`vendor/conventional-commits/`) and Keep a Changelog (`vendor/keep-a-changelog/`) as git submodules (FS-0009 (formerly FS-0017), PLAN-0009).
- "Upstream References" section in README with vendored specs and joelparkerhenderson ADR resource.
- ADR-0012: Introduce non-overridable gates (super-gates).
- FS-0009 (formerly FS-0017), FS-0010 (formerly FS-0018), PLAN-0009, PLAN-0010.

### Changed

- INTEGRATION.md precedence model: added level 0 for non-overridable safety gates; renumbered existing levels.
- `workflows/git-and-gh-conventions.md`: added identity verification step 0 and merge prohibition in step 8.
- `workflows/README.md`: added missing `versioning-and-releases.md` entry and new `document-lifecycle.md` entry.
- ROLE_CONTRACT: "Non-Overridable Safety Gates" section clearly labeled and scoped per ADR-0012.
- Vendor path references in INTEGRATION.md normalized from `agent-dev-kit` to `agentic-dev-kit`.

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

- Project renamed from `agent-dev-kit` to `agentic-dev-kit` (repo: `Tais-Den/agentic-dev-kit`). Vendored mount path remains `vendor/agent-dev-kit/` for backward compatibility.
- `docs/workflows/` moved to `workflows/` (exported surface, not internal docs).
- CI workflow file renamed from `lint-adrs.yml` to `lint-docs.yml`; now lints ADRs, specs, change plans, and workflows.
- `package.json` lint scripts updated: added `lint:specs`, `lint:plans`, `lint:workflows`, `lint:docs`; scripts use `npx` for local execution.
- README submodule/clone URLs updated to `Tais-Den/agentic-dev-kit`; default branch reference changed to `trunk`.

### Fixed

- ADR-0004 precedence wording corrected (was "highest-numbered wins", now "lowest-numbered/highest-priority wins").
- `INTEGRATION.md` directory tree corrected (showed `agentic-dev-kit/` instead of `agent-dev-kit/` for vendored path).

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
