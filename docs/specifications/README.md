# Feature Specifications

Feature Specs (FS-XXXX) document the requirements and acceptance criteria for implementing features, tools, and processes in conventional-agents.

**Agents MUST update this file when adding new specs or changing spec statuses.**

## Purpose

Feature Specs serve as the bridge between:

- **Architecture Decisions (ADRs):** Document the "why" of decisions (what we've decided and why)
- **Implementation:** Document the "what" of features (requirements, success criteria, rollout plan)

Unlike ADRs which record decisions made, feature specs document the concrete requirements and behaviors needed to implement those decisions.

## Naming Convention

Feature Specs follow the pattern: `FS-XXXX-descriptive-name.md`

- **Prefix:** `FS` (Feature Spec)
- **ID:** Sequential 4-digit number (FS-0001, FS-0002, etc.)
- **Description:** Kebab-case, descriptive title
- **Location:** This directory (`docs/specifications/`)

## Lifecycle

Feature Specs progress through the following statuses:

1. **Draft:** Initial creation, under development and review
2. **Approved:** Reviewed and ready for implementation
3. **In-progress:** Implementation actively underway
4. **Implemented:** Implementation work is complete
5. **Deprecated:** Spec is no longer active or has been superseded

Only specs with `status: approved` should be actively implemented. See `workflows/document-lifecycle.md` for transition rules.

## Does this spec change the exported surface?

Every spec must answer this before it is approved. It is the counterpart to
`docs/decisions/README.md` §1a: that section asks whether an ADR obliges someone to
write code, this one asks whether a spec obliges someone downstream to change.

**The answer is derivable, not declared.** A spec is consumer-affecting when its
`interfaces:` names any path in the exported surface — `guidelines/`, `roles/`,
`skills/`, `templates/`, `workflows/`, `integrations/`, `runbooks/`, `scripts/`,
`INTEGRATION.md`, or `AGENTS.md`. Those are the paths host repositories vendor. No new
front-matter field: `interfaces:` already declares the surface area a spec may touch,
and this reads it.

`scripts/` joined this list with `FS-0024`: before it, a vendored copy of these gates
checked the framework's own repository regardless of which repository invoked it, so
nothing about them was consumer-affecting in the sense this section means. After it,
a change to `scripts/` can change what a host repository's own gates do.

| The spec's `interfaces:` name | Requires |
| --- | --- |
| Internal governance only — `docs/`, `package.json`, `test/`, CI | Nothing beyond the ordinary CHANGELOG entry |
| Any exported-surface path | A **consumer-framed** CHANGELOG entry in the PR that implements it |

**Consumer-framed** is the operative word, and it is `guidelines/ROLE_CONTRACT.md`
Role 5's standard: describe the change by its effect on the reader, not by the
governance ID that produced it. *"Agent commits now carry the model in the author
name, so `git log` shows which model wrote what"* is a consumer-framed entry.
*"ADR-0029 landed"* is not, and tells a downstream maintainer nothing about whether
their tooling breaks.

Worked examples from this repository:

- **`FS-0021`** (review board) names `templates/collaboration/`,
  `workflows/session-modes.md`, and `guidelines/ROLE_CONTRACT.md`. Consumer-affecting:
  a host repo vendoring the framework gets a new collaboration mode and a new mode
  value in its stance vocabulary. Requires an entry.
- **`FS-0022`** (gate coverage) names `scripts/`, `package.json`,
  `.github/workflows/`, and the docs indexes. Internal only: consumers vendor the
  documents, not this repository's CI. No consumer-framed entry required.

## Why this is symmetric with §1a

Both rules exist because a document can imply obligations it does not name. An ADR
deciding a check should exist has not authorized anyone to write it — §1a. A spec
changing something host repositories vendor has not told them it changed — this
section.

The failure modes mirror each other, and both are silent. An ADR implying code
without a governing FS produces a gate that entered CI without architectural review.
A spec changing exported surface without a consumer note produces a downstream break
whose cause is discoverable only by reading this repository's internal governance —
which is precisely what `ADR-0009`'s separation exists to spare consumers.

## Template

All feature specs must use the template defined in `templates/core/feature-spec.md`.

## Current Specifications

| ID | Title | Status |
| --- | --- | --- |
| FS-0001 | Markdownlint Integration for ADR Quality Gates | implemented |
| FS-0002 | Move workflow skills into conventional-agents (dual-mode) | deprecated |
| FS-0003 | Git + gh CLI conventions for the kit | implemented |
| FS-0004 | Agent-authored commit + PR commentary policy (role-aware) | deprecated |
| FS-0005 | Expand docs linting coverage to FS/PLAN/workflows | implemented |
| FS-0006 | JavaScript/TypeScript guidelines for agentic development | implemented |
| FS-0007 | Versioning, releases, and packaging guidance for agentic development | implemented |
| FS-0008 | Apply versioning and changelog to conventional-agents itself | implemented |
| FS-0009 | Vendor Upstream Specs (Conventional Commits, Keep a Changelog) | implemented |
| FS-0010 | Process Compliance Gates — Spec-First Enforcement and Document Lifecycle | implemented |
| FS-0011 | Adopt GitHub Projects for work tracking | implemented |
| FS-0012 | Renumber feature specs to sequential IDs | implemented |
| FS-0013 | Status consistency check for FS/PLAN documents | implemented |
| FS-0014 | Role definitions overhaul — expand from 3 to 6 roles (Head Architect, Comms Lead) | implemented |
| FS-0015 | Role selection and session modes | implemented |
| FS-0016 | Framework Internal Vendor Boundary | implemented |
| FS-0017 | Single-identity commit attribution with model, role, and session metadata | implemented |
| FS-0018 | Work item lifecycle and autonomous triggers for governed work | implemented |
| FS-0019 | Multi-model consensus at workflow gates (optional consumer feature) | implemented |
| FS-0020 | SDLC workflows — single-model and multi-model | implemented |
| FS-0021 | Review board collaboration mode | implemented |
| FS-0022 | Gate coverage — extend consistency, lint, and test enforcement to the whole corpus | implemented |
| FS-0023 | Runbook document type — operational procedures recorded as performed | implemented |
| FS-0024 | Portable governance gates — vendored checks target the host repository, not the framework | implemented |
| FS-0026 | ADR and PLAN scaffolding CLI — npm run new:adr and npm run new:plan | implemented |
| FS-0027 | Workflow and guideline doc freshness gate — enforce updated: frontmatter | implemented |
| FS-0029 | Executable layer for the GitHub binding — provisioning, initialisation, and audit commands | implemented |
| FS-0028 | ADR supersession chain gate — machine-check superseded_by completeness | implemented |
| FS-0030 | Claude Code runtime binding — the first agent-runtime binding under ADR-0039 | implemented |
| FS-0031 | Governed-agent benchmark harness — reproducible functional + governance scoring | implemented |
| FS-0033 | Governance CI on stacked and non-trunk pull requests | implemented |
| FS-0034 | Consumer conformance doctor — read-only diagnostics for framework adoption | implemented |
| FS-0035 | Portable flow-report read-model — substrate-neutral governance visibility without a work-item binding | draft |
| FS-0036 | Planning-field conventions for the GitHub binding — Priority, Iteration, Milestone semantics and read-only flow checks | draft |
| FS-0037 | Vendor-prefixed reference resolution — close the submodule-citation blind spot in referenced-path checking | implemented |
| FS-0038 | Hermes kanban substrate binding for work item lifecycle | draft |
| FS-0039 | Validation reproducibility contract — bounded, hermetic, and CI-parity framework checks | implemented |
| FS-0040 | Governed-ID claim and citation audit — local duplicates, cross-PR collisions, and stale renumber citations | approved |
| FS-0041 | Status-vs-delivery consistency audit — detect governed documents that lag shipped implementation | approved |
| FS-0042 | History-aware freshness audit — distinguish substantive document drift from metadata-only updates | approved |
| FS-0043 | Cron attribution enforcement — require terminal mode=autonomous after the adoption boundary | approved |
| FS-0045 | Accepted-ADR authority check for current-state guidance | draft |
| FS-0046 | Whole-corpus governance triggers and trunk merge enforcement | draft |
| FS-0047 | Reusable consumer guidance without instance-specific leakage | draft |
| FS-0049 | Bash 3.2 regression coverage for the status consistency gate | approved |
| FS-0050 | Run-batch tier-integrity check — validate batch acceptance is proposal-only | approved |
