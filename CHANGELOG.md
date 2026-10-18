# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

For this project (a documentation/standards kit), semver follows the
"Documentation and Standards Kits" semantics defined in
`workflows/versioning-and-releases.md`.

## [Unreleased]

### Added

- **ADR-0049 (proposed): Grant-based go signal for autonomous runs.** Amends ADR-0045 by replacing its status-inferred gate with the explicit human grant from ADR-0047; the run's declare/bound/present/approve machinery carries forward unchanged. Records cadence, parallelism, and queue depth as instance configuration (not framework policy) and defers generation ambition to FS-0051's open questions.
- **Fold collective-agents into conventional-agents (PLAN-0057 step 3).** Imports the operations layer's decisions — `ADR-0047` (authorized intent identity and the human grant) and `ADR-0048` (worker/publisher credential separation), both `accepted` — plus the deferred engine's spec and plan (`FS-0051`/`PLAN-0058`, carried as `draft` because the engine is re-extracted when built, not now), the operations arc42 (`docs/operations/ARC42.md`), and the research evidence. Renumbers references, reconciles stale `PARSING_HINTS`, and rewrites the obsolete "framework vs separate-sequence" qualifier language.
- **ADR-0046 (accepted) / PLAN-0057 (draft): Merge the governance and operations templates.** Decides to collapse conventional-agents and collective-agents into one repository (conventional-agents survives, collective-agents archives), eliminating the template-as-consumer recursion, the duplicated scaffolding, and the public-flip ordering coupling. The migration plan carries the org transfer, the submodule re-pins, the fold (via an identity map + import manifest), the ADR-0045 amendment via successor ADR-0049 and the two-loop-tick withdrawal, the feral-fleet ADR-0023 composition, the Hermes-Agent runtime binding, and the instance-data scrub + public flip + branch-protection configuration and read-back.
- **ADR-0045: Bounded autonomous runs with batch proposal-acceptance (accepted).** Introduces the run as the unit of bounded autonomous work — declare-then-run, a 48-hour bound, one manifest-first PR, and a single batch acceptance of proposal-class artifacts at run end — while keeping reserved-path and merge authorization individually human-gated.
- **FS-0050 / PLAN-0056 (approved): Run-batch tier-integrity check.** Specifies and plans a detection check that enforces ADR-0045's proposal/implementation line: a batch-acceptance commit must touch only proposal-class locations and list only accepted proposal-class artifacts. Approved — the implementation is a separate reserved-path change with recorded approval.
- **FS-0042: History-aware freshness audit (`FS-0042`,
  `PLAN-0048`).** The companion to the implemented freshness gate ships in
  the implementation revision (PR #206): `scripts/check-freshness-history.sh`
  compares `updated:` with the latest substantive Git history, treats
  date-only metadata commits (including pure renames) as diagnostics, and
  fails closed on missing history. Document statuses remain `approved`
  until a human reconciliation PR advances them (tracked by #183).
- **FS-0043: Cron attribution enforcement (`FS-0043`,
  `PLAN-0049`).** Ships in the implementation revision (PR #206): the
  boundary-aware check in `scripts/cross-repo-lint.sh` requires the terminal
  `mode=autonomous` marker for configured cron identities after the adoption
  boundary, grandfathers earlier history, fails closed on unreadable commit
  timestamps, and never rewrites old commits. Document statuses remain
  `approved` until a human reconciliation PR advances them (tracked by #187).
- **FS-0040 now includes the #186 citation-drift complement.** The governed-ID
  audit package covers local duplicate detection, cross-PR claim collisions,
  and stale citations of retired IDs when an open PR exposes the corresponding
  renumber event. The implementation ships in PR #206; document statuses
  remain `approved` until a human reconciliation PR advances them (tracked by
  #179 and #186).
- **Bash 3.2 status-gate compatibility contract (`FS-0049` / `PLAN-0055`, approved).** Defines opt-in real Bash 3.2 parse-and-run regression coverage for consumer repositories that run the exported status gate. A missing interpreter is an explicit skip, not compatibility evidence. PR #215 must record successful GNU Bash 3.2.39 and 3.2.57 parse-and-run results against its final head before implementation is complete.
- **Draft governance packages for issues #209–#211 (FS-0045–FS-0047,
  PLAN-0051–PLAN-0053).** Specify an accepted-ADR authority check,
  whole-corpus governance triggers and trunk review enforcement, and a
  regression-audited consumer-boundary cleanup. These documents remain drafts;
  they authorize no implementation or live ruleset changes.
- **Claude Code runtime binding (`FS-0030`).** The framework's first agent-runtime
  binding ships under `integrations/runtimes/claude-code/`: a plugin manifest
  (`claude plugin validate` clean), synced skill copies sourced from
  `skills/*/SKILL.md`, an advisory gate-runner hook, a parameterised MCP
  example, an identity/attribution settings fragment, and a report-only
  `ca-runtime-audit.sh` that never mutates `.claude/` and never blocks. The
  framework adopts its own binding's `.claude/settings.json` and its root
  `CLAUDE.md` (importing `AGENTS.md`, adding no authority tier),
  `npm run ca-runtime-audit`/`sync:claude-skills` are registered, and an
  advisory (non-blocking) `claude-plugin-validate` CI job was added.
  Hermes Agent, OpenClaw, and Codex bindings remain planned behind their own
  FS/PLAN cycles (`ADR-0039` §5).
- **Bounded, hermetic validation runner (`FS-0039`, issue #132).** Framework
  maintainers and consumers can run `npm run validate` to execute the five
  documented acceptance gates through one ordered, timed, fail-closed entry
  point. Bats suites report progress and enforce per-suite bounds; the default
  path isolates temporary state and does not fetch Git or call GitHub. CI uses
  the same runner after preparing full history and dependencies.
- **ADR-0041: Narrow direct-to-trunk merge exception for reversible
  maintenance categories** (proposed) — exercises `ADR-0012`'s
  project-level-exception mechanism for issue #151's scaling problem
  (per-PR human approval ceremony scaling linearly with consumer-repo
  count). Rejects the staging-branch shape (multiplies ceremony per repo,
  degrades `ADR-0025` per-commit attribution granularity) in favor of a
  phased, path-based eligible-category set (Category 2 skill work under
  `ADR-0015`, mechanical README index syncs) gated by a new required
  `eligibility-gate` status check — diff-based, not actor-based, since
  `ADR-0018` collapsed the agent/human GitHub identity split `ADR-0011`
  introduced. Notes that `trunk` currently has no GitHub branch protection
  at all (verified live) and requires a minimal maintenance digest, shipped
  now rather than blocked on issue #146's flow-report read-model, as the
  human audit surface. Decision record only; implementation needs a
  companion FS/PLAN.
- **FS-0037: Vendor-prefixed reference resolution (implemented — `FS-0037`,
  `PLAN-0043`).** Closes a blind spot in the `FS-0022` §1c referenced-path
  check: references of the form `vendor/conventional-agents/<path>` — how
  consumers are instructed to cite framework files — are blanket-skipped by
  the `vendor/*` exclusion before any resolution is attempted, so the
  strip-prefix fallback the script already carries is unreachable for them.
  Measured on trunk: a phantom **bare** reference fails the gate (rc=1) while
  a phantom **prefixed** reference passes (rc=0). The spec also extends the
  extractor for the three exported-surface documents (`INTEGRATION.md`,
  `README.md`, `AGENTS.md`) to non-backticked occurrences of the same prefix,
  because the `INTEGRATION.md` phantoms repaired by PR #164 carried no
  backticks. Third-party submodule paths (`vendor/madr/`) keep today's skip
  behaviour. Tracks issue #165; consumer impact is a framework-citation that
  currently cannot fail — a public adopter following the documented
  integration path is the party who hits a dead reference. (Consumer-framed
  per `FS-0022` §1d — the spec names `scripts/` — and staged with the draft
  package rather than held back, so reviewers see the consumer impact while
  the spec is under review.) Implemented under PLAN-0043's recorded approval
  (PR #191): rule 8 in `scripts/check-status.sh`
  resolves the prefixed form — strip-prefix in self-check, the host's
  initialised submodule in a consumer run, skipping only when it is
  uninitialised — and `test/FS-0037/vendor-ref-resolution.bats` covers
  SC-1..SC-7.
- **FS-0040: Governed-ID claim audit (`FS-0040`, `PLAN-0046`).**
  Closes the governed-ID collision class in two layers. Locally,
  `check-status.sh` learns to fail when two documents in one registry
  resolve to the same `FS-NNNN` / `PLAN-NNNN` / `ADR-NNNN` ID — a
  duplicate that passes the portable gate today (measured on trunk: an
  injected FS, PLAN, or ADR duplicate leaves `check:status` at rc=0; the
  cross-repo sweep catches the FS/PLAN subset only, and ADR duplicates
  nowhere).
  Cross-PR, a new read-only audit in the GitHub binding
  (`npm run github:pr-claim-audit`) reports same-ID / different-path
  claims among open pull requests — drafts included — and claims
  colliding with the default branch under a different path, mirroring
  the detection posture of the board audit. Tracks issue #179 (from
  #174's closing recommendation; the last collision, `#148`/`#159` +
  `#149`/`#173`, was resolved by hand). Consumer impact is the collision
  class itself: a vendoring repository inherits the local duplicate
  detection with its gate copy, and a silently-landed duplicate — two
  `FS-00NN-*` files, an index row lost to merge order — is precisely the
  drift that reaches downstream adopters. (Consumer-framed per `FS-0022`
  §1d — the spec names `scripts/` — and staged with the draft package.)
- **FS-0041: Status-vs-delivery consistency audit (`FS-0041`,
  `PLAN-0047`).** A conservative, offline, report-only audit for the
  opposite side of the lifecycle pairing gate: a pair that remains
  non-terminal — `draft`, `approved`, or `in-progress` — after its declared
  implementation surface has shipped. Findings rest on post-plan Git history,
  the required test suite, and a CHANGELOG marker — never file existence
  alone — and never change a document's status. The executable audit, npm
  entry, CI wiring (advisory in CI until the delivered pairs are reconciled),
  and Bats suite ship in the implementation revision (PR #206); document
  statuses remain `approved` until a human reconciliation PR advances them
  (tracked by #188).
- **`INTEGRATION.md` documents the version-to-version upgrade path.** The
  Migration Guides carried "no standards → framework", "copy-in → submodule",
  and "submodule → fork" transitions, but nothing for a consumer already
  vendoring the framework that wants to move its pin — the gap flagged in
  [#140](https://github.com/Tais-Den/conventional-agents/issues/140) (sequence
  item 3 of [#138](https://github.com/Tais-Den/conventional-agents/issues/138);
  Tier-1 of [#136](https://github.com/Tais-Den/conventional-agents/issues/136)).
  The new § "Version-to-version upgrades" states the support policy — one tag-to-tag line, breaking changes
  only in majors per `workflows/versioning-and-releases.md` § "Documentation and
  Standards Kits", additive minors/patches, framework-internal paths excluded
  from any stability promise, and cumulative review when skipping majors — plus
  a four-step procedure (diff the exported surface between tags, bump the pin as
  its own commit, re-run the vendored gates per `FS-0024`, re-verify stub
  references), grounded in the `v2.0.0` rename/renumbering and the additive
  `v2.1.0` release as worked examples. Consumers previously had to infer the
  policy from `CHANGELOG.md` alone.

- **Planning-field conventions for the GitHub binding (draft — `ADR-0043`,
  `FS-0036`, `PLAN-0042`).** Defines `Priority`, `Iteration`, and `Milestone`
  as binding policy, not framework state: the authority matrix (humans
  create/assign Milestones and arbitrate Priority; agents read/recommend and
  may only backfill UNSET Priority from a documented mapping, assign
  iterations under the scheduling contract, and idempotently clear
  closed-item iterations), the cross-repository Milestone limitation (a
  project spanning repositories cannot uniformly milestone items), and the
  read-only `--flow` drift report for the board audit. Architecture
  mechanism is separated from consumer planning policy per `ADR-0043`; the
  flow-report boundary from `ADR-0042`/`FS-0035` is inherited. Tracks issue
  #145.
- **`binding-authoring` skill.** Operationalises `integrations/README.md`
  § "Writing a binding" plus `ADR-0024` / `ADR-0037` / `ADR-0039` for a
  contributor writing or reviewing a binding — substrate or runtime. Covers the
  step of deciding whether a platform needs a binding at all, mapping the six
  substrate capabilities or the five runtime setup requirements with none
  deferred, stating enforcement honestly per capability, the binding-first
  ordering rule (no generalisation from a single binding), the
  `enforces`/`provisions`/`reports` classification and the "anything that can
  fail a PR lives in `scripts/`" bright line for shipped executables, and a
  grep-shape conformance-test pattern modelled on
  `test/FS-0016/vendor-boundary.bats`. The GitHub reference binding — the
  declarative `integrations/github-issues-projects.md` and the executable
  `integrations/github/` layer — is the worked example throughout. Category 2
  under `ADR-0015`; no FS. `binding-selection` is folded in as the skill's first
  step rather than shipped as a separate skill: a reader concluding they *do*
  need a binding immediately needs the authoring content, and the "no" branch is
  a short decision with no natural runnable example of its own.
- **FS-0031: Governed-agent benchmark harness (implemented)** — reproducible
  functional + governance scoring for issue #124. `scripts/bench-run.sh`
  executes a versioned task card under a named condition in a disposable
  worktree and emits a JSON report separating functional success from
  governance compliance, with evidence, overhead, and failure fields.
  Includes `benchmark/task-card.schema.json` (v1), the first shipped task card
  (`benchmark/task-cards/pilot-001.md`, with escalation + adversarial
  scenarios), the `bench:run` npm script, and bats coverage
  (`test/FS-0031/bench-harness.bats`). No live model calls — the harness
  drives any command; wiring real agents is a later pilot concern.
- **Governance CI now covers stacked and non-trunk pull requests (`FS-0033`).**
  The `lint-docs` workflow's `pull_request` trigger no longer filters to
  `trunk`, so a stacked PR whose base is a non-trunk branch receives the same
  lint, status, freshness, and Bats signal as a trunk-based PR — previously it
  silently received none. The `lint-cross-repo` job fetches the PR's actual
  base ref before computing its commit range, and fork-safety is preserved (no
  secrets, no `pull_request_target`). `skills/gh-pr-workflow/SKILL.md`
  documents the behavior for reviewers.
- **Consumer conformance doctor (`FS-0034`).** `npm run check:conformance`
  ships `scripts/check-conformance.sh` — a read-only diagnostic that checks a
  vendoring repository for framework presence (`vendor/conventional-agents/`),
  AGENTS.md anchors, dangling vendor references, status-gate runnability, CI
  wiring, and framework version reference. It reports findings and never
  writes: target resolution follows `FS-0024`/`ADR-0033` (caller's working
  directory or `CA_TARGET_REPO`), `--json` output is available for tooling,
  and exit codes are stable (0/1/2). Optional tooling, not a Category 1
  governance gate (`ADR-0015`) — deliberately not wired into CI as a failing
  check.

- **FS-0035: Portable flow-report read-model (draft)** — substrate-neutral
  governance visibility for issue #146: a versioned, read-only visibility
  profile over any conforming work-item binding plus Git evidence. Contract
  only — no generator ships until human approval (ADR-0042, proposed).

- **Executable GitHub binding layer (`FS-0029`).** Consumers can use the shared
  submodule initializer, idempotent label provisioner, and read-only Project
  board audit under `integrations/github/`. Copyable CI and pull-request
  templates document the required full-history checkout and keep authentication
  and board reconciliation explicit; the framework's own CI runs the label audit.
- **Two authoring skills: `adr-authoring` and `spec-authoring`** — the two
  `BACKLOG.md` named as "the two worth revisiting first: they teach the two
  document types this repository has watched get mis-authored repeatedly,
  including by its own agents." Category 2 under `ADR-0015` (no FS/PLAN);
  authored to the `skills/AUTHORING.md` profile.
  - **`adr-authoring`** teaches craft, not mechanics: deciding whether the work
    is an ADR at all (`ADR-0030`'s two families and four rules) or a
    current-state edit; whether the decision implies a governing FS
    (`docs/decisions/README.md` §1a); verifying a cited ADR's status and title
    against the file rather than an index; building each MADR section; and the
    claim discipline — enforcement versus detection, absolute verbs, and the
    tense a change actually delivers. Every rule is derived from an ADR in this
    repository that was mis-authored and corrected, with the correcting commit
    cited (11 pitfalls, each with its SHA).
  - **`spec-authoring`** centres the one section tests are generated from:
    numbered `SC-N` criteria in Given/When/Then form that a test author can map
    without asking a question — because `skills/testing-guide/SKILL.md` converts
    an ambiguous criterion into an `xfail`/`todo`/`skip`, so vagueness produces a
    green suite rather than a loud failure. Also covers Non-Goals and Out of
    Scope as hard constraints, `interfaces:` as a machine-read surface contract
    (block-list form — the inline form's quotes are not stripped by
    `get_list_field`), Open Questions carrying their own defaults, and approval
    routing when a PLAN touches an `ADR-0027` reserved path.
  - Both state explicitly what they do **not** cover — IDs, status transitions,
    templates, README index, `check:status` resolution — and defer to
    `skills/document-lifecycle/SKILL.md` for it, per the profile's
    no-duplicate-gates rule. Both carry a "what the gates catch and what they do
    not" table, so a reader knows which quality properties are theirs to hold.
  - `skills/index.md` gains both rows.

- **Agent-runtime integration is now a governed surface** — `ADR-0038` and
  `ADR-0039` (both **accepted** 2026-09-05), plus the new `skills/AUTHORING.md`
  and `integrations/runtimes/` scaffolding, plus the first governing spec
  `FS-0030` (draft):
  - **ADR-0038** records that the framework *profiles* the Agent Skills open
    standard ([agentskills.io](https://agentskills.io/specification)) rather than
    defining a skill format. `SKILL.md` is now implemented by ~45 products, by
    Codex CLI, and by both dominant self-hosted runtimes — Hermes Agent and
    OpenClaw, which each add an incompatible `metadata.<runtime>.*` namespace,
    overtaking ADR-0001's "most other tools have no formal skills system"
    premise. The framework's authoring rules (standalone-useful, non-exhaustive
    compliance summary, minimum content checklist, ~400-line size signal, no
    duplicate gates) now live in **`skills/AUTHORING.md`**, and `README.md`'s
    Agent Skills upstream line points there instead of at `BACKLOG.md`. Source
    `skills/*/SKILL.md` must target the base spec (flat string `metadata`, no
    `metadata.hermes.*` / `metadata.openclaw.*`, no dangling cross-references);
    the six skills are non-conformant today and that mechanical cleanup is
    Category 2 follow-up, not in this change. A conformance validator as
    merge-blocking CI is Category 1 and deferred to its own FS. ADR-0001 gets a
    Status note; its decision stands.
  - **ADR-0039** extends ADR-0024's two-layer substrate model to agent runtimes:
    a *runtime binding* under `integrations/runtimes/<runtime>/` maps the
    framework's setup requirements (anchor-file wiring per ADR-0004, gate-script
    execution, skill discovery, commit identity/attribution, MCP config) onto one
    runtime's config surface, in ADR-0037's directory envelope — **bounded by
    ADR-0015's Location invariant**: a binding executable is outside the tool
    taxonomy only while non-blocking; anything wired into a merge-blocking CI job
    is a Category 1 gate in `scripts/`. Suggests a binding order (Claude Code
    first, then Hermes and OpenClaw as two independently accepted bindings, then
    Codex) without pre-unifying any two; no neutral runtime contract is defined
    until ≥2 bindings ship. Draws the ADR-0007 line: config that *applies*
    framework rules (a local advisory hook running `check-status.sh`), never
    config that *defines* new workflow. MCP-server configuration is
    runtime-binding content, not a new ADR-0015 category. Retires the never-built
    `packs/` concept — `INTEGRATION.md`'s broken `packs/` copy-paste path is
    fixed, `docs/ARC42.md` §5.1 updated, ADR-0001 gets a Status note (not a body
    edit).
  - **`integrations/README.md`** gains a "Two kinds of binding" section
    distinguishing substrate bindings from runtime bindings.
  - **`FS-0030`** (draft) specifies the first binding — Claude Code — in full:
    a plugin (`claude plugin validate`-able), a `CLAUDE.md` importing `AGENTS.md`,
    skills made discoverable from unchanged base-spec source, a local advisory
    gate-runner hook, an identity/attribution settings fragment, a parameterised
    MCP example, and a report-only `ca-runtime-audit.sh`. `PLAN-0036` (draft)
    sequences it library-first; it touches reserved paths and cannot self-approve.

- **FS-0038 / PLAN-0044: Hermes kanban binding candidate (draft).** Documents
  a proposed peer work-item substrate under `ADR-0024` and tests isolated CLI
  creation/enumeration in `test/FS-0038/`. It is not yet conforming: Type
  mutation attribution, human authorization before dispatch, and non-retractable
  transition history still need verified mechanisms before adoption. The
  candidate resides in internal `docs/proposals/`, not the shipped
  `integrations/` surface; GitHub remains the only published substrate binding.

- **ADR-0034 superseded; PLAN-0034 deprecated.** `ADR-0034` (proposed, never
  accepted) bundled the MCP tool-category question with skills consolidation;
  that bundling stalled it for a month (issue #107 shows a reader losing track).
  It is now `superseded_by: [ADR-0038, ADR-0039]`, `PLAN-0034` is `deprecated`,
  and issue #107 (which misreported the skills split as done — the split-target
  skills never existed) is corrected and closed. `check-status.sh` rule 5b
  (FS-0028) machine-checks the resulting chain.
- **FS-0028: ADR supersession chain gate** (implemented) — rule 5b in
  `scripts/check-status.sh` machine-checks the `superseded_by:` front-matter
  field on every ADR: a `superseded` ADR must name a replacement, every
  non-null value must resolve to an existing ADR (by `id:`), and only a
  `superseded` ADR may declare a replacement. Lands with zero backlog —
  the corpus is 37/37 `superseded_by: null` with no supersessions.
  Documented in `scripts/README.md` and `docs/decisions/README.md` §5;
  covered by `test/FS-0028/adr-supersession-chain.bats`.
- **ADR-0036: Attribution vocabulary canon and history-integrity
  policy** (proposed) — canonical `Agent-Attribution:` trailer vocabulary
  (`actor=` lowercase persona slug; `model=` provider-qualified;
  `role=` ROLE_CONTRACT title case; `session=` kebab-case; fixed field
  order), `Co-authored-by:` restricted to human–human collaboration
  (amends ADR-0018's hybrid example; aligns with the ecosystem consensus
  that models cannot hold co-authorship), a committed `.mailmap` as the
  canonical alias table (drives `git log --use-mailmap` and the
  pre-public history rewrite via `git filter-repo --use-mailmap`),
  history-rewrite policy (identities only; trailers never edited
  retroactively; tree-identical verification before force-push), and
  SSH commit-signing guidance so public-era commits carry `Verified`.
  Includes `.mailmap` (human aliases + Marten persona), FS-0017 bats
  updates (human-identity allowlist, `.mailmap` regression test,
  removal of the default-email Co-authored-by rule, Marten agent case),
  and the cross-repo-lint agent-email sync.

- **ADR-0035: Concurrent-session workspace isolation** (proposed) — every
  agent session performs repository mutations in a per-session worktree;
  the shared checkout is read-only for agents; `git stash` in a shared
  checkout is forbidden. Where a container runtime is available, sessions
  should run in per-session sandbox instances mounting their own
  worktrees (mechanical enforcement, not a replacement). Includes the
  per-agent sandbox instance design: one session, one sandbox, one
  worktree — never a shared workspace inside a container. Extends
  ADR-0013's authority model with workspace mechanics. The sandbox
  instance design lands in feral-fleet PLAN-0024 (Hermes-Agent ↔ Podman
  integration).

#### Public-release preflight (license, security, conduct, issue template)

- **`LICENSE` corrected to the actual copyright holder.** The file carried
  `Copyright (c) 2026 Anthropic` (inherited from an early contributor's
  scaffold); the copyright now reads `Copyright (c) 2026 Joey Clark`
  (matches the GitHub account that owns the repository — `ajoeofalltrades`).
  MIT terms unchanged. Required before the repository goes public.
- **`SECURITY.md` added** — private vulnerability reporting, the
  security-relevant surfaces of a standards kit (gates that fail open,
  approval/provenance bypasses, template secret-leaks, attribution
  spoofing), supported-versions policy, coordinated-disclosure window.
- **`CODE_OF_CONDUCT.md` added** — Contributor Covenant 2.1, with
  enforcement contact via the `ajoeofalltrades` GitHub account.
- **`.github/ISSUE_TEMPLATE/work-item.md` added** — GitHub issue-template
  front matter, scaffold matching the framework's own work-item schema
  (FS-0018 three axes: Type / Label / Phase; ADR-0019 type-keyed
  checkpoints noted).
- **ADR-0018 operational-context scrub** — removed the `hades-01` / Quadlet
  internal-infrastructure references from ADR-0018's operational-context
  paragraph (internal infrastructure naming should not appear in a public
  repository).
- **Clone URLs verified against the org home** — README (Quick Start
  submodule + Manual Copy) and `skills/framework-consumer-integration/SKILL.md`
  (all four integration patterns) reference
  `github.com/Tais-Den/conventional-agents` (the repository's home; the
  org stays the owner). The README Project Board link to `pack-protocol`
  is unchanged and now discloses that the board is a maintainer-side
  surface.
- **Exported-surface generalization (final review round)** — the issue
  template no longer names internal consumer repos; `scripts/cross-repo-lint.sh`
  drops the hardcoded repo-name/absolute-path heuristics (sibling discovery
  is now overridable via `CA_SIBLING_NAMES`, agent-email allowlist via
  `AGENT_EMAILS`); the single-identity convention docs now state that the
  `tais-den.dev` actor addresses are this repository's own aliases and
  adopters substitute their own domain; the CI comment no longer claims
  the repos are private.
- **MM3 final-round polish** — the pure-human-commit guidance notes the
  `taisden@tais-den.dev` default is this repo's own alias, and
  `config/project.example.yml` no longer names `pack-protocol` as the
  board-metadata home (generalized to "maintained outside this
  repository").

#### ADR and PLAN scaffolding CLI (`FS-0026`, implemented)

- **`npm run new:adr` and `npm run new:plan` scaffold governed documents with
  framework-conformant frontmatter and sequential IDs.** `new:adr` creates
  `docs/decisions/ADR-<next>-<slug>.md` (with a built-in template string — no
  vendored MADR dependency), supports `--title` / `--dry-run`, and is base-10
  safe for leading-zero IDs. `new:plan` scaffolds a draft PLAN from an existing
  ADR, carrying over its `related_specs`/`related_adrs` and Consequences
  section (inline and multi-line YAML forms). Index updates remain a documented
  follow-up step.

#### Bats coverage for the ADR/PLAN scaffolding CLI (`FS-0026`, implemented)

- **`test/FS-0026/scaffolding-cli.bats` covers all six FS-0026 success
  criteria** — ADR creation, dry-run, PLAN reference/consequence carry-over,
  trailing-`--title` error, quote preservation, and base-10 next-number
  computation — plus argument-validation edges. Tests run against scratch
  repos under `BATS_TEST_TMPDIR`; the real `docs/` is never written.
- **`scripts/new-plan.sh`: multi-line YAML list extraction now captures every
  item.** The awk list-walker stripped the leading dash with `gsub` and then
  re-tested the mutated line, tripping its own exit guard after the first
  item — a `related_specs:` block with more than one entry carried only the
  first into the generated PLAN. The walker now `next`s after printing, and
  the exit guard only fires on a non-list, non-blank line. Found by the new
  suite (criterion 3); the shipped CLI had carried single-item lists
  correctly, so no previously generated PLAN was affected.

#### Workflow and guideline freshness gate (`FS-0027`, implemented)

- **`npm run check:freshness` validates the exported workflow/guideline surface.**
  Every governed doc under `workflows/` and `guidelines/**` must carry an
  `updated:` front-matter field (hard rule, exit non-zero) and docs whose
  `updated:` date exceeds 90 days are reported as staleness candidates
  (soft rule, `DOC_STALE_DAYS` override). Runs in CI on push and pull request.
  All 16 governed docs were backfilled with their last-commit date in the same
  change, so the gate is green immediately. Target resolution follows
  FS-0024/ADR-0033 (caller's working-directory repo, `CA_TARGET_REPO` override),
  and `DOC_FRESHNESS_NOW` pins the evaluation date for deterministic tests.
- The maintenance tick's staleness detection (proactive check #2) now covers
  the workflow/guideline surface, which previously carried no `updated:` fields
  anywhere.

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

#### Cross-repo lint enforcement (`fixes #85`)

- **`npm run lint:cross-repo` runs `scripts/cross-repo-lint.sh`, now wired into
  CI.** The script shipped with the cross-repo linting change but was never
  registered or gated; the `lint-cross-repo` job in `.github/workflows/lint-docs.yml`
  audits the calling repository's commits for FS-0017 Agent-Attribution trailer
  conformance (`origin/<base>..HEAD` on pull_request, last 20 trunk commits on push).
  The full three-repo sweep remains a maintenance-tick responsibility (the runner
  cannot check out the other two private repos), and `scripts/README.md` now documents
  the gate per ADR-0015.

### Changed

#### `lint-docs` workflow gains spend guards (concurrency + job timeouts)

- **`.github/workflows/lint-docs.yml` now sets `concurrency` (workflow + ref,
  `cancel-in-progress: true`) and a bounded `timeout-minutes` on every job.**
  Rapid successive pushes to the same ref — a PR receiving reviewer-feedback
  pushes while its previous run is still in flight — previously launched a full
  11-job workflow generation each time; the superseded runs cannot change the
  newest run's outcome, but consumed included Actions minutes in full. Every
  job also ran against GitHub's 360-minute default, so a hung install step
  (the `test-bats` job installs bats/ripgrep/pyyaml; `lint-docs-widened` runs
  the widened npm lint chain) could silently consume hours. Timeouts are 10
  minutes for gate jobs and 20 for `test-bats` (observed ~5–7 minutes).
- **This is the CI-refactor mitigation for the recurring Actions billing
  condition** (feral-fleet #207), which blocks every workflow org-wide at
  job-start while the monthly included-minutes limit is hit. It is the
  complement of the public-release track (#136): moving the repos public
  removes the private-repo minutes multiplier, these guards shrink the spend
  itself.
- **No `paths:` filter is introduced.** The governance gates are whole-corpus
  (`check-status.sh` reads every FS/PLAN/ADR regardless of the diff; gate
  coverage is FS-0022's subject, gate target resolution is ADR-0033's), so a
  filter that skips the workflow on non-matching diffs would re-open the
  fail-open shape FS-0024 was written to remove. The guards bound spend without
  weakening any gate.
- **The concurrency group key separates event kinds without special-casing.**
  `${{ github.ref }}` is `refs/heads/<branch>` on push and `refs/pull/N/merge`
  on pull_request, so a push run and a PR run never cancel each other and each
  PR's own superseded generations collapse.
- **DeepSeek model migration** — canonical/example model identifiers updated from the retired `deepseek-v4-flash:0731` tag to `deepseek-v4.1-flash` (Ollama Cloud retirement notice, 2026-09-21) in FS-0019, `workflows/git-and-gh-conventions.md`, and ADR-0036 (proposed — its binding-vocabulary table is not yet append-only). Historical examples inside accepted ADRs (ADR-0018) are deliberately unchanged — accepted ADRs are append-only.

#### `testing-guide` overflow moved into `references/` (AUTHORING rule 4)

- **`skills/testing-guide/SKILL.md` goes 517 → 231 lines.** The three
  language-specific sections — Python, JavaScript/TypeScript, Bash — moved into
  the Agent Skills spec's optional `references/` directory:
  `references/python.md` (98), `references/javascript-typescript.md` (117),
  `references/bash.md` (164). `SKILL.md` keeps the language-agnostic core
  (authoritative signals, Success Criteria mapping, ambiguity handling, test file
  metadata, the reviewer checklist) plus a routing table.
- **This is the other half of the amended rule 4, and the test of it.**
  `testing-guide` is one coherent topic that ran long, so it takes `references/`
  and stays one skill; `git-gh-workflow` was five topics sharing a file, so it
  splits. Same rule, opposite remedies, decided by cohesion rather than line
  count. The split is now the whole of `skills/` **under the ~400-line signal**.
- This is also the framework's first use of the spec's `references/` convention
  at all — no skill previously had a `references/`, `scripts/`, or `assets/`
  directory, and progressive disclosure (name + description at startup, `SKILL.md`
  on activation, references on demand) was unexercised.
- `SKILL.md` gains an explicit `When to Use` section, a `Gates That Bind Here`
  summary, two runnable examples, and a consolidated cross-language pitfalls
  table, so it still satisfies profile rules 1–3 standing alone now that the
  per-language examples live in `references/`.

#### `git-gh-workflow` split into five focused skills (ADR-0038 rule 7)

- **`skills/git-gh-workflow/SKILL.md` (554 lines) is now a 46-line deprecated
  router.** It bundled five distinct topics in one file. Its content moved to:

  | Successor | Covers |
  | --- | --- |
  | `skills/git-commit-identity/` | Commit identity, the multi-identity and single-identity models, `Agent-Attribution:` trailers, the actor alias table, the `gh auth status` gate |
  | `skills/git-branch-and-commit/` | Branch prefixes, the mandatory feature-branch rule, Conventional Commits, commit bodies, pushing |
  | `skills/gh-pr-workflow/` | PR bodies, rebasing, review response, CI checks, the merge gate, compliant `--auto` merge |
  | `skills/versioning-and-releases/` | Semver by project type, changelog conventions, the release process, agent-safe vs human-gated actions |
  | `skills/work-item-stance/` | The `agent-stance:` entry, Type-keyed autonomous checkpoints, `question` suppression, unattended actor identity |

  Each successor is 146–196 lines, satisfies the profile's rules 1–3 standing
  alone, and is listed in `skills/index.md`.
- **`skills/AUTHORING.md` rule 4 amended first, as the governance predicate.**
  The old single sentence — overflow goes to `references/`, "not into a second
  skill" — read as forbidding the split that `ADR-0038` rule 7 sanctions. Both
  documents were current and authoritative, so the wording was the defect. Rule 4
  now turns on **cohesion rather than line count**: one topic that ran long takes
  `references/`; several topics sharing a file are split. Size alone never
  justifies a split. Under the amended rule the two current breaches resolve
  differently, which is the test of it — `git-gh-workflow` splits,
  `testing-guide` (517 lines, one topic) will take `references/`.
- **The duplicated gates collapsed rather than being copied five times.** The old
  skill restated the seven-item document hygiene gate in full, which
  `framework-health-audit` already expands; and the `ADR-0012` non-overridable
  gates, which `guidelines/ROLE_CONTRACT.md` owns. Each successor now carries a
  short, labelled "Gates That Bind Here" summary plus links. Rule 5 gains a
  clause making this explicit. Net effect: **fewer** places state each rule, not
  more.
- **Inbound references updated** in `README.md`, `AGENTS.md`,
  `guidelines/ROLE_CONTRACT.md`, `docs/ARC42.md`, `config/consensus.yml`,
  `skills/index.md`, and the four sibling skills' Related Skills sections.
  `test/FS-0017/commit-attribution.bats` now asserts the identity strings against
  `git-commit-identity`, where they live. Decision records (ADRs, FS, PLAN) and
  historical `CHANGELOG` entries are left alone: they describe the state when
  written.
- **Consumer impact.** `skills/git-gh-workflow/SKILL.md` still resolves, so no
  vendored reference breaks today, but it no longer carries guidance — a consumer
  loading it gets a routing table. Consumers referencing it should move to the
  successor they actually need. The router is expected to be removed in a future
  major release.

#### Skill frontmatter conformed to the Agent Skills base spec (ADR-0038)

- **The six shipped skills' `SKILL.md` frontmatter is now base-spec-clean.**
  `version`, `author`, and `platforms` — non-spec fields, identical and
  information-free across all six — are dropped; the nested
  `metadata.hermes.{tags,related_skills}` map-of-arrays, which is Hermes
  Agent's runtime dialect, is removed from source per `ADR-0038` rules 4–5.
  Each skill keeps `name`, `description`, and `license`. Cross-references move
  to a prose `## Related Skills` section, and the three dangling
  `related_skills` targets — `test-driven-development`, `github-auth`,
  `github-pr-workflow`, none of which exist in this repository — are gone. A
  runtime that needs a dialect gets it from a runtime binding at sync time,
  never from source (`ADR-0039`).
- **All six `description` fields rewritten to carry what *and* when.** Removing
  `metadata.hermes.tags` removed the only keyword surface the skills had, and the
  spec makes `description` the sole field loaded at startup for discovery — it
  "should include specific keywords that help agents identify relevant tasks."
  Each description now states when to use the skill and carries the vocabulary
  that was in `tags`, so retrieval does not regress. All are far inside the
  spec's 1024-character limit.
- **`skills/example-skill/` removed.** It held an empty, unindexed `SKILL.md`
  that failed the spec's `name`/`description` requirement; `ADR-0038` rule 4's
  stated position is to remove it. The format reference is
  [agentskills.io/specification](https://agentskills.io/specification) and
  `skills/AUTHORING.md`.
- **`skills/AUTHORING.md` corrected on two points it got wrong.** It told authors
  `name` was optional ("if present"), where the spec makes it required and
  directory-matching; and it routed platform constraints to `metadata:` where the
  spec's field for environment requirements is `compatibility`, which the profile
  never named. It now enumerates all six permitted frontmatter fields and states
  that `description` is the entire discovery surface. `ADR-0038` is accepted and
  append-only, so the correction lands in the current-state document that carries
  the rule (`ADR-0030` rule 3), not in the ADR.
- **Known gap, not closed by this change.** `skills/git-gh-workflow/SKILL.md`
  (554 lines) and `skills/testing-guide/SKILL.md` (517) still breach
  `skills/AUTHORING.md` rule 4's ~400-line signal and the spec's 500-line
  recommendation, and no skill yet uses the spec's `references/` remedy. Tracked
  as work item #115 item B; `ADR-0038` rule 7 names the disposition for the
  first. Work item #115 does not close on this change.
- **Consumer impact.** Skills load identically and no body guidance changed, but
  this deletes a file from the exported surface (`skills/example-skill/SKILL.md`),
  which `workflows/versioning-and-releases.md` classifies as **major** for a
  documentation and standards kit. The file was empty and absent from
  `skills/index.md`, so nothing could have depended on its content; the release
  classification is a human call at release-cut time, not an agent's.
  Discharges the `ADR-0038` rule 4 conformance follow-up and removes the
  precondition `FS-0030` SC-13's warning allowance was written for.

#### History rewrite — identity normalization per ADR-0036 (2026-09-01)

- **Repository history rewritten with `git filter-repo --mailmap .mailmap`
  before the public release.** All human-authored commits are now
  attributed to the canonical identity `Joey Clark
  <administrator@ajoeofalltrades.dev>`: the `Joe Clark` variant (49
  commits) and the `ajoeofalltrades <…noreply.github.com>` variant (2
  commits) are merged in; the Marten persona's legacy alternate name
  `martenoftheden` normalizes to `Marten <github.marten@fwd.mtnden.org>`.
  (The `.mailmap` also carries a dormant `taisden@tais-den.dev` alias
  for Joey Clark — unexercised in the rewritten history, listed for
  completeness.) Agent-author identities are unchanged
  (ADR-0018/ADR-0029).
- **Only author/committer identities changed.** Verified before
  force-push: tree hash identical (`6c13a16f`), 237 commits preserved,
  all 165 `Agent-Attribution:` trailers preserved byte-for-byte
  (trailers are the audit record and are never edited retroactively —
  ADR-0036).
- **All pre-rewrite commit SHAs are invalidated.** Tag `v2.1.0` was
  re-pushed to the rewritten history; `v2.0.0` still points at a
  pre-rewrite commit (`94e9640`) that is not an ancestor of trunk
  (consumers checking out `v2.0.0` land off the mainline). Pre-rewrite
  SHAs (CHANGELOG, docs, issues, local clones) are no longer reachable
  from any ref — SHA-based lookups still resolve the objects, but
  ref-based resolution fails. Consumer submodule pins bump in the
  companion PRs: feral-fleet `35503c2` → `5c5af66`, pack-protocol
  `7dbfb32` → `5c5af66`.
- **Signatures:** the rewrite (filter-repo) stripped the historical
  commit signatures — all commits on the rewritten history are now
  unsigned (GitHub reports `unsigned`, not `unverified`). Commit
  signing resumes per ADR-0036 going forward.

#### Instance data removed from the exported surface

- **`config/project.yml` deleted.** It held one organization's GitHub Project board
  metadata (IDs, URLs, field options). Replaced by `config/project.example.yml` with
  placeholder values, following the house style of `config/gates.example.yml`. If you
  vendored this file, copy the example and fill in your own board's values. The real
  board metadata for the conventional-agents project now lives in
  `pack-protocol/config/boards/conventional-agents.yml`.
- **`README.md`, `INTEGRATION.md`, and `skills/framework-consumer-integration/SKILL.md`
  no longer hardcode `Tais-Den/tais-den-conventions` or `vendor/tais-den-conventions/`**
  in copy-paste instructions. The Quick Start, Pattern 4, and the integration skill now
  use `<your-org>-conventions` / `vendor/<your-org>-conventions/` placeholders. If you
  previously followed these instructions literally, your submodule URL and vendor path
  will need updating — replace `<your-org>` with your actual organization name.
- **`README.md` Project Board section** now points to `config/project.example.yml` and
  `pack-protocol` instead of the deleted `config/project.yml`.

#### Stronger identity verification for the single-identity workflow (`ADR-0018`, `ADR-0029`)

- **`workflows/git-and-gh-conventions.md` and `skills/git-gh-workflow/SKILL.md` now
  tell an agent to verify its commit identity against its own current model, not just
  that the fields are set.** Previously "verify `user.name`/`user.email` before
  committing" only caught an unset identity — a `user.name` left over from a
  *different* model in a prior session is well-formed and passes that check trivially.
  If you run agent sessions across multiple models in the same working tree, this
  closes a real misattribution path: a later session silently inheriting an earlier
  session's identity in its commit history and `Agent-Attribution:` trailers.
- Convention-level, not enforced — no check can verify a self-report is honest. What
  changes is what "verify" means in the checklist, not a new gate.

#### Vendored governance gates now check your repository, not the framework's (`FS-0024`, `ADR-0033`)

- **If you vendor this framework and run `check-status.sh` or `run-bats.sh` from
  `vendor/conventional-agents/scripts/`, they now check *your* documents.** Previously
  both scripts resolved their target from their own on-disk location, so a vendored
  copy silently checked the framework's own (clean) `docs/` instead of yours, and
  reported success regardless of what your repository actually contained.
  `check-current-state.sh` was never affected.
- **Self-approval routing (`ADR-0027`) and the consumer-impact CHANGELOG reminder now
  require your own `config/gates.yml`, copied from the shipped
  `config/gates.example.yml`.** Without it: self-approval routing refuses to certify
  any plan and exits non-zero — a safety-relevant check does not silently default to
  "nothing is reserved." The CHANGELOG reminder instead skips explicitly and exits
  zero — the correct behavior if your repository has no exported surface at all
  (`ADR-0032` instance form).
- `scripts/` is now documented exported surface in `README.md` and `AGENTS.md`,
  correcting a prior classification that said the opposite while assuming the same
  thing this change makes true: that consumers run these scripts.
- See `scripts/README.md` for the full mechanism and `ADR-0033` for the reasoning.

### Fixed

- **Three vendored-gate fail-open paths now fail closed (issues #194, #195).**
  Each of these could report success while skipping all or part of the audit
  it exists to perform, so a consumer's CI could receive green from a gate
  that never (fully) ran:
  - `scripts/check-status.sh` **exits non-zero when run outside a git working
    tree** (#194, case 1). The `pwd` fallback manufactured a root for a
    non-repository directory, the git-backed rules failed silently, and the
    script printed the success line — a CI job or maintainer in the wrong
    working directory received green. The resolved target is now required to
    be inside a work tree.
  - `scripts/cross-repo-lint.sh` **fails closed on an unresolvable
    `COMMIT_RANGE`** (#194, case 2). The endpoint-wise `rev-parse --verify`
    check accepted the null object hash, then `git rev-list "<null>..HEAD"`
    silently iterated zero commits and the attribution check printed OK —
    exactly the range shape GitHub produces for `github.event.before` on a
    new-branch push. The whole range is now resolved before the audit; an
    empty-but-resolvable range (`A == B`) still audits nothing without error.
  - The rule-6 **grandfather clause in `check-status.sh` is now
    self-check-only** (#195). The pre-ADR-0027 allow-list (`PLAN-0001`–
    `PLAN-0017`) names this repository's historical plans, but it applied in
    consumer runs too — where `PLAN-0001` is the first plan a host repository
    ever writes. A vendored copy silently skipped containment and
    reserved-path checks on a consumer's first seventeen plan numbers, which
    is exactly where the self-approval rule is most needed. Consumers cannot
    inherit this repository's history; the safe default is to enforce.
  Regression coverage: four new cases in `test/FS-0024/portable-gates.bats`
  (the non-git-cwd and nested-target loud failures, plus the two consumer
  PLAN-0001 cases — one against the reserved set, one outside interfaces) and
  two in `test/FS-0017/attribution-diagnostic.bats` — the null-hash range
  failing closed, and the empty-but-resolvable range (`A == B`) preserving the
  caller's declared audit-nothing behavior with an explicit zero-exit
  assertion; each fail-closed case asserts the loud failure against the
  pre-fix silent pass.
- **`check-freshness.sh` no longer certifies a non-git working directory
  (#199).** The resolved target fell back to `pwd` outside any repository, so
  both governed directories "didn't exist", the empty-corpus branch printed
  its message, and the gate exited 0 for a run that checked nothing — the
  same fail-open shape `check-status.sh` carried in #194, one script over. The
  resolved root must now be inside a git working tree or the run fails loudly
  and names the directory; a bare repository gets its own message (it is a
  repository, just one with no working tree to scan). A work tree that
  genuinely has no `workflows/` or `guidelines/` (a fresh consumer repository
  mid-adoption) still gets the empty-corpus message — the guard only rejects
  directories git disclaims. A missing `git` binary is named as such instead of
  blaming the directory. `test/FS-0027/freshness-gate.bats` gains five
  regression cases: the loud failure from a non-git cwd (fails against the
  pre-fix script), the `CA_TARGET_REPO`-override failure, the bare-repository
  discrimination, the missing-git diagnostic, and the fresh-work-tree positive
  control.
- **`new-plan.sh` no longer scaffolds into a non-git directory (#202).** The
  target-resolution fallback (`git rev-parse --show-toplevel || pwd`) let the
  scaffolder proceed when the caller stood outside any repository: the
  next-number scan read an empty tree, and the write path created
  `docs/change-plans/PLAN-0001-<slug>.md` under whatever directory the caller
  happened to be in — even inside a bare repository — exit 0, a durable PLAN
  outside any repository (the `#194`/`#199` fail-open class, write side). The
  resolved root must now be a git work tree or the run fails loudly and names
  the directory; a bare repository gets its own message, and a missing `git`
  binary is named as such — the same two diagnostics the sibling gate fixes
  specify (issues `#198`/`#200`, in review at this commit; this change lands
  the write-side guard first). `--help` and
  argument errors keep working from any directory. `test/FS-0026/scaffolding-cli.bats`
  gains five cases: non-git cwd (fails loudly, writes nothing — fails against
  the pre-fix script), `CA_TARGET_REPO` at a non-repo directory, bare-repository
  diagnostic, missing-git diagnostic, and the fresh-work-tree positive control
  (still scaffolds). Closes #202.
- **The Claude Code runtime-binding tools resolve their target repository
  properly, and sync-skills can no longer certify a copy that copied nothing
  (issue #204).** Both `ca-runtime-audit.sh` and `sync-skills.sh` resolved
  their target as literal `$PWD`: from a directory git disclaims the audit
  printed a confident "[info] no .claude/ directory — nothing to audit" at
  exit 0 (and under `--strict` too), from a checkout subdirectory it missed
  the root's real `.claude/`, and sync wrote plugin scaffolding into a
  non-repository at exit 0 — the #194 resolution class in
  `integrations/runtimes/`. Both now resolve the repository containing the
  caller's working directory (`CA_TARGET_REPO` overriding, per
  `FS-0024`/`ADR-0033`), reject a non-work-tree target with a loud error on
  their distinct target-error exit (2) — with their own diagnostics for a bare
  repository and a missing `git` — and map a subdirectory target to the
  work-tree top level. `sync-skills.sh` additionally counts a source skill
  missing its `SKILL.md` as a failed copy: the previously unreachable
  `N skill(s) failed to sync` check now fires instead of a run that copied
  nothing exiting 0. Ten regression cases in `test/FS-0030/runtime-binding.bats`
  (each of the fail-closed cases fails against the pre-fix scripts —
  regression-proved).
- **`gh-board-audit.sh` reported every pull-request item as field drift
  (#171).** Rows were serialised tab-delimited and parsed with `IFS=$'\t'`.
  Tab is IFS *whitespace*, so the empty `number`/`repository` cells on
  non-Issue rows collapsed into one delimiter and shifted every later field:
  each PullRequest was counted as both `unset-issue-type` and `unset-status`
  regardless of its real values — **135 phantom PR-rows** (38 board #2 /
  39 board #4 / 58 board #1), every one with a set `Status` on direct read.
  Rows now serialise with a non-whitespace delimiter (ASCII Unit
  Separator, `\u001f`) and the parser splits on it, so empty middle fields
  survive. `test/FS-0029/board-audit.bats` fixtures emit the new delimiter and
  carry a regression case: a PullRequest with set fields must produce a
  zero-drift summary (fails against the pre-fix script).
- **Attribution gate now distinguishes `MISSING` from `MALFORMED` trailers (#154).**
  `scripts/cross-repo-lint.sh` check 1 reported every unreachable
  `Agent-Attribution:` line as "missing", so a commit whose trailer is
  syntactically present but unreachable by git's trailer parser (displaced by a
  following paragraph, or wrapped across continuation lines) was
  indistinguishable from one that carries no trailer at all — the two need
  opposite responses (write it vs move it). When the trailer parser returns
  empty, the gate now body-scans and reports the two modes distinctly. The
  failing set is unchanged. New hermetic suite
  `test/FS-0017/attribution-diagnostic.bats` covers both modes, the positive
  controls, and the scope case (a human-authored commit with no trailer is not
  an offender). Closes #154.
- **`INTEGRATION.md` no longer routes adopters at paths that never existed.** The Quick Start stub, the AGENTS.md/CLAUDE.md/Codex examples, and the Spec Kit hook referenced `guidelines/tests.md`, `guidelines/commit-and-pr.md`, `guidelines/index.md`, `roles/test-writer.md`, and `integrations/spec-kit.md` — six references to files that have never existed in this repository (the `packs/` references were already repointed by `8cf14ac`; these were the remainder named in `ADR-0039` §"The framework's expression against these surfaces is undocumented and has drifted"). Repointed at the current-state files: `guidelines/ROLE_CONTRACT.md` and `roles/ROLE_CONTRACT.md` for foundation/gates, `skills/testing-guide/SKILL.md` for testing guidance, `workflows/git-and-gh-conventions.md` for PR hygiene, and `integrations/github-issues-projects.md` for the Spec Kit hook's binding reference. The Quick Start's `<REPO_URL>` placeholder is replaced with the real repository URL (public-release Tier 1; `#136`). Every remaining `vendor/conventional-agents/...` path in the file now resolves on trunk. Closes #163.
- FS-0004 / PLAN-0002 marked `deprecated` — superseded in practice by FS-0018/FS-0019 (agent-stance and role-aware commentary conventions now live in `workflows/git-and-gh-conventions.md`). Frontmatter and body Status sections updated, PLAN-0002 §2 records the deprecation rationale, README indexes synced, lifecycle lists include `deprecated`. Closes #82.
- **`test/FS-0025/` renamed to `test/FS-0022/` — the directory named a spec that never existed.** `governance-patterns.bats` (the repository's largest governance suite, introduced by PR #89 for #86) sat in a `test/FS-NNNN/` directory whose ID had no `docs/specifications/FS-0025-*.md` — the numbering runs `FS-0024` → `FS-0026`. Two skills cited the phantom path as the reference for real gates (`adr-authoring`, `spec-authoring`), so a reader following the citation found nothing. The suite's scope (governance consistency patterns enforced by `check-status.sh`) belongs to `FS-0022`, which already owns `test/FS-0022/gate-coverage.bats`; the directory was renumbered there, both skill citations updated, and the general correspondence (`test/FS-NNNN/` ⇄ a spec that exists, in both directions) is now pinned by `suite_traceability` cases in `test/FS-0022/gate-coverage.bats`. Closes #168.

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
