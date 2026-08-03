---
type: feature-spec
id: FS-0024
status: draft
title: Portable governance gates — vendored checks target the host repository, not the framework
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/check-current-state.sh"
  - "scripts/run-bats.sh"
  - "scripts/README.md"
  - "config/gates.example.yml"
  - "README.md"
  - "AGENTS.md"
  - "docs/specifications/README.md"
  - "CHANGELOG.md"
  - "test/FS-0024/portable-gates.bats"
related_adrs:
  - ADR-0012
  - ADR-0015
  - ADR-0019
  - ADR-0027
  - ADR-0030
  - ADR-0032
  - ADR-0033
supersedes: []
requires: []
tags: [gates, portability, ci, scripts, consumer]
created: 2026-08-02
updated: 2026-08-02
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

# Feature Spec: Portable Governance Gates

## Status

- Draft

## Plan Status

- **Drafted as PLAN-0024** (`status: draft`), alongside this spec. This is not a
  departure: `workflows/document-lifecycle.md` places PLAN *creation* at "initial
  creation" and constrains only PLAN *approval* to come after the governing FS has
  been reviewed. `FS-0018`'s own Plan Status section states the same rule the same
  way. The spec and its implementation strategy were reasoned about together, which
  the lifecycle document permits without qualification.
- PLAN-0024 cannot be approved until this FS is approved, and — because every path it
  touches is reserved under `ADR-0027` (`scripts/`, `package.json`) — cannot
  self-approve regardless. It requires human approval by construction.
- `ADR-0033` must also be accepted before implementation begins. Per
  `docs/decisions/README.md` §1a, this FS is the governing spec an ADR implying code
  requires, and per `ADR-0015`, no governance gate may be written or modified without
  an approved FS and PLAN. Both gates must clear before PLAN-0024 executes.
- No open questions block approval.

## Summary

`scripts/check-status.sh` and `scripts/run-bats.sh` resolve the repository they check
from the location of the running script, not from the repository that invoked them. A
host repository vendoring this framework as a git submodule and running either script
gets the framework's own — clean — documents checked, not its own. A scratch
reproduction confirms it: a host repository with a deliberately broken spec (`status:
implemented`, no governing PLAN, no README row) reports `All status checks passed.`
when the vendored `check-status.sh` is run from the host's own root.

`scripts/check-current-state.sh` does not share the defect — it already resolves its
target via `git rev-parse --show-toplevel`, which is caller-relative rather than
script-relative. That is the mechanism this spec extends to the other two scripts.

Fixing resolution alone is not enough. Two of the values these scripts check against —
`RESERVED_PATHS` and `EXPORTED_PREFIXES` — are this repository's own structural facts,
not portable defaults. A consumer's governing role contract, manifest format, and
exported-surface directories are theirs, not this repository's to assume. This spec
adds a per-repository configuration file, sourced from outside the vendored tree per
`ADR-0032`, and defines what each configuration-dependent check does when that file is
absent — refusing to certify self-approval where the stakes are a safety hazard,
skipping visibly where they are a documentation reminder.

`ADR-0033` is this spec's governing decision record.

## Goals

- Every governance gate in `scripts/` resolves the repository it checks from the
  working directory that invoked it, not from the script's own location on disk.
- Every existing invocation of these scripts — `npm run check:status`, `npm test`, the
  three CI jobs in `.github/workflows/lint-docs.yml`, and every bats suite that invokes
  a script directly — continues to behave exactly as it does today, with no change to
  how any of them are called.
- A consumer repository can run `bash vendor/conventional-agents/scripts/check-status.sh`
  (and the other two scripts) from its own root and have the check evaluate its own
  documents.
- `RESERVED_PATHS` and `EXPORTED_PREFIXES` are sourced from a per-repository
  configuration file that does not ship inside the vendored tree, consistent with
  `ADR-0032`.
- Absence of that configuration is not silently treated as "nothing is reserved" —
  the self-approval check refuses to certify any PLAN until `reserved_paths` is set.
- Absence of exported-surface configuration is not silently treated as a pass — the
  consumer-impact CHANGELOG check reports explicitly that it is skipped, distinct in
  its output from having run and found nothing to flag.
- `scripts/` is corrected from "internal governance only" to "exported surface" in
  every document that currently states the opposite, because the defect this spec
  fixes only matters if consumers are meant to run these scripts, and the existing
  classification says they should not reference them at all.

## Non-Goals

- **Reconciling the directory sets `check-status.sh` rule 8 (referenced-path
  resolution) and `check-current-state.sh`'s `CURRENT_STATE_RE` each use for
  "current-state document."** They currently disagree — rule 8 covers `roles/` and
  `scripts/`; `CURRENT_STATE_RE` covers neither. This is a real inconsistency,
  already recorded as a finding on the open PR relocating `config/project.yml`, and it
  concerns which directories count as current-state for ADR-Links checking — a
  different question from which repository a script checks. See `ADR-0033`'s
  Non-Goals for the full reasoning. Left for separate work.
- **Making `FS_DIR`, `PLAN_DIR`, `ADR_DIR`, `REQUIRED_ADR_SECTIONS`, or
  `CURRENT_STATE_RE` per-repository configurable.** `ADR-0033` classifies these
  universal — true of any adopter using this framework's own templates and
  conventions unchanged. Nothing here revisits that classification.
- **Fixing `feral-fleet`'s undetected status-pairing violation.** It is the evidence
  this defect is real, not a repository this spec commits to correcting. Its
  maintainers fix it once the corrected gates reach them.
- **Building a `config/gates.yml` for this repository's own use.** This repository
  continues to use its hardcoded `RESERVED_PATHS` and `EXPORTED_PREFIXES` when
  checking itself, detected by comparing the resolved target against the script's own
  location. Creating a real, populated `config/gates.yml` at this repository's root
  would itself be instance data inside a template repository, which `ADR-0032`
  forbids — the self-check path exists precisely so this repository need not do that.
- **Implementing a YAML parser, or taking on a YAML library dependency.**
  `config/gates.example.yml` uses a flat, list-of-strings schema parseable by the same
  bash/awk approach `check-status.sh` already uses for markdown front matter. No new
  tooling dependency.
- **Changing what any check enforces.** This spec is about which repository a check
  runs against and how it behaves when per-repository configuration is absent — not
  about the rules any of the eight checks in `scripts/check-status.sh` and
  `scripts/check-current-state.sh` evaluate. Every existing rule's logic is unchanged.
- **CI workflow changes.** `.github/workflows/lint-docs.yml`'s three relevant jobs
  invoke the scripts with the same syntax before and after this change; none of its
  YAML requires editing. (`scripts/**/*` is already a CI trigger path, so no
  path-trigger change is needed either.)

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — maintains both this framework and several
  consumer repositories, including `feral-fleet`, whose undetected drift motivated
  this spec. Needs the gates to actually check what he vendors them for.
- **Consumer-repository maintainers** — anyone who vendors this framework and expects
  the eight checks it ships to mean something in their own repository.
- **Future gate authors, in this repository and in consumers.** `ADR-0033` establishes
  the resolution convention every future governance gate should follow; this spec is
  where that convention is first applied.

## Interfaces

- **`scripts/check-status.sh`** — `REPO_ROOT` resolution changes from script-relative
  to working-tree-relative, with an optional `CA_TARGET_REPO` override. Gains a
  `FRAMEWORK_HOME` self-check comparison. Rules 6 (PLAN `touches:` containment /
  self-approval) and 7 (consumer-impact CHANGELOG) read `RESERVED_PATHS` and
  `EXPORTED_PREFIXES` from `$REPO_ROOT/config/gates.yml` when the target is not this
  repository checking itself, falling back to the existing hardcoded arrays only in
  the self-check case. `EXPORTED_PREFIXES`'s hardcoded (self-check) value gains
  `scripts/`.
- **`scripts/check-current-state.sh`** — gains the same `CA_TARGET_REPO` override,
  ahead of its existing (already-correct) `git rev-parse --show-toplevel` call. Default
  behavior unchanged.
- **`scripts/run-bats.sh`** — same `REPO_ROOT` resolution change as `check-status.sh`.
- **`scripts/README.md`** — documents the resolution mechanism, the self-check
  detection, the `config/gates.yml` schema and where it is sourced from, and the
  fail-closed/skip distinction between rules 6 and 7 when configuration is absent.
  Current-state document per `ADR-0030` rule 3; updated in the change that accepts
  `ADR-0033`.
- **`config/gates.example.yml`** (new) — ships with the "THIS IS A CONSUMER-COPY
  TEMPLATE, NOT FRAMEWORK CONFIGURATION" header `config/consensus.yml` and
  `config/review-board.yml` already use. Documents `reserved_paths`,
  `exported_prefixes`, and `ref_exempt` as flat, empty-by-default list fields, each
  with a comment explaining what leaving it empty means for the corresponding check.
- **`README.md`, `AGENTS.md`** — exported-surface tables move `scripts/` from
  "internal governance" to "exported surface."
- **`docs/specifications/README.md`** — the "Does this spec change the exported
  surface?" section's bullet list of exported-surface prefixes gains `scripts/`,
  going forward. Its existing `FS-0022` worked example, which correctly described
  `scripts/` as internal-only *at the time FS-0022 was written*, is left unedited — it
  is a historical record of a spec's classification when this spec's own change had
  not yet landed, not a currently-asserted rule.
- **`CHANGELOG.md`** — a consumer-framed entry, added when PLAN-0024 executes (not
  before `ADR-0033` is accepted and this FS is approved — see Rollout / Migration).
- **`test/FS-0024/portable-gates.bats`** (new) — the mutation-style suite described in
  Success Criteria.

## Success Criteria

Each bullet MUST be objectively testable, per `CONTRIBUTING.md` §"Changing a
Governance Gate": each mutates the thing the check protects and asserts the check
notices, not merely that it runs and exits zero.

**Target resolution:**

- Given a scratch host repository with `vendor/conventional-agents` linked at its own
  `vendor/conventional-agents/`, and a deliberately broken spec in the host's own
  `docs/specifications/` (`status: implemented`, no governing PLAN, no README row),
  when `bash vendor/conventional-agents/scripts/check-status.sh` is run from the host
  repository's own root, then it reports the break and exits non-zero — not `All
  status checks passed.`
- Given the same scratch host repository, when `bash
  vendor/conventional-agents/scripts/check-status.sh` is run from a subdirectory of
  the host repository (not its root), then it still resolves the host as its target
  and reports the same break.
- Given `npm run check:status`, `npm test`, the `check-status` CI job, the
  `current-state-update` CI job, and the `test-bats` CI job, when each is run against
  this repository's own trunk with no invocation changed, then each passes exactly as
  it does before this change.
- Given `CA_TARGET_REPO` set to a path different from both the caller's working
  directory and the script's own location, when any of the three scripts is run, then
  it resolves its target to the value of `CA_TARGET_REPO`, not to the working
  directory or the script location.

**Self-check detection:**

- Given `check-status.sh` run with its resolved target equal to its own
  `FRAMEWORK_HOME`, when rule 6 or rule 7 evaluates, then it uses this repository's
  existing hardcoded `RESERVED_PATHS` / `EXPORTED_PREFIXES` values, unchanged from
  today.
- Given `check-status.sh` run with its resolved target different from its own
  `FRAMEWORK_HOME`, when rule 6 or rule 7 evaluates, then it reads
  `$REPO_ROOT/config/gates.yml` and does not use this repository's hardcoded arrays.

**Fail-closed configuration (rule 6):**

- Given a vendored `check-status.sh` (resolved target ≠ `FRAMEWORK_HOME`) with no
  `config/gates.yml` present at the target, when a PLAN at `status: approved` with no
  human-approval evidence is evaluated for self-approval, then the check exits
  non-zero and its output names `reserved_paths` as unconfigured — it does not
  certify the PLAN as self-approved.
- Given the same setup but with `config/gates.yml` present and `reserved_paths: []`
  explicitly set (not merely absent), when the same PLAN is evaluated, then the check
  treats the reserved set as genuinely empty and evaluates self-approval against
  `interfaces:` containment alone — an explicit empty list is not the same as an
  absent file.
- Given `config/gates.yml` present with `reserved_paths` naming a path, when a PLAN's
  `touches:` includes that path, then the check requires human approval for it,
  exactly as `RESERVED_PATHS` does today for this repository's own hardcoded set.

**Skip-explicit configuration (rule 7):**

- Given a vendored `check-status.sh` with no `config/gates.yml` present, or one
  present with `exported_prefixes: []`, when rule 7 evaluates, then the check reports
  that rule 7 does not apply and is skipped, exits zero (assuming no other failure),
  and its output is distinguishable from a report that rule 7 ran and found no
  violation.
- Given `config/gates.yml` present with `exported_prefixes` naming a path, when an
  FS at `approved` or beyond names that path in `interfaces:` with no matching
  `CHANGELOG.md` entry, then the check fails exactly as `EXPORTED_PREFIXES` does today
  for this repository's own hardcoded set.

**`scripts/` reclassification:**

- Given `README.md` and `AGENTS.md`, when their exported-surface tables are read, then
  `scripts/` appears under "exported surface," not "internal governance."
- Given `check-status.sh`'s self-check `EXPORTED_PREFIXES` value, when read, then it
  includes `scripts/`.

**Documentation:**

- Given `scripts/README.md`, when read, then it documents `CA_TARGET_REPO`, the
  `FRAMEWORK_HOME` self-check comparison, the `config/gates.yml` schema and where it
  is sourced from, and states explicitly which of rules 6 and 7 fails closed and which
  skips when configuration is absent, and why they differ.

## Edge Cases

- **A consumer runs a script from inside `vendor/conventional-agents/` itself** (e.g.,
  `cd vendor/conventional-agents && bash scripts/check-status.sh`). `git rev-parse
  --show-toplevel` resolves to the submodule's own root — this framework's vendored
  copy — because the caller's working directory is now inside it. `REPO_ROOT` equals
  `FRAMEWORK_HOME`, the self-check path is taken, and the framework's own documents are
  checked. This is correct: a caller who has `cd`ed into the submodule has asked to
  check that repository, the same way checking out this repository directly and
  running the script from its root does.
- **`git rev-parse --show-toplevel` fails** — the caller's working directory is not
  inside any git repository at all. `REPO_ROOT` falls back to `pwd`, matching
  `check-current-state.sh`'s existing fallback. The scripts do not require git to be
  present at the target beyond what rule 6's approval-provenance check already
  requires (documented in `scripts/README.md` as needing full history).
  `config/gates.yml`, if present, is read the same way regardless.
- **A consumer sets `reserved_paths` but not `exported_prefixes`, or vice versa.** The
  two fields are read independently. One being configured does not imply anything
  about the other; rule 6 and rule 7 each check only the field they use.
  Fail-closed vs. skip applies per field, not per file.
- **A template-form consumer (`ADR-0032`) configures `exported_prefixes` for their own
  downstream consumers.** Rule 7 then behaves for that consumer's specs exactly as it
  does for this framework's own — evaluated, not skipped.

## Out of Scope

- Any change to what the eight existing checks in `check-status.sh` and
  `check-current-state.sh` enforce.
- The `RESERVED_PATHS`/`CURRENT_STATE_RE` reconciliation named in Non-Goals.
- Extending `config/gates.yml` to cover `FS_DIR`/`PLAN_DIR`/`ADR_DIR` overrides —
  these are classified universal by `ADR-0033` and not exposed as configuration.
- Any change to `.github/workflows/lint-docs.yml`.
- Retrofitting `feral-fleet` or any other consumer.

## Dependencies

- `ADR-0033`: Governance gate target resolution and configuration — the governing
  decision record for this spec's resolution mechanism, universal/per-repository
  classification, and fail-closed/skip distinction.
- `ADR-0012`: Non-overridable gates — unaffected; the merge gate is not this spec's
  concern.
- `ADR-0015`: Tool taxonomy — these are Category 1 governance gates; no governance
  gate may be written or modified without an approved FS and PLAN, which is why
  neither exists yet.
- `ADR-0019`: Issue Type immutability and the autonomous gate — the "an agent must not
  lower its own gate" principle this spec's fail-closed behavior for rule 6 applies to
  unconfigured self-approval certification.
- `ADR-0027`: PLAN self-approval within declared interfaces — defines `RESERVED_PATHS`
  and reserves `scripts/`, meaning PLAN-0024 cannot self-approve.
- `ADR-0030`: Decision records versus current-state documents — `scripts/README.md`
  must update in the same change that accepts `ADR-0033`, per rule 3.
- `ADR-0032`: Template and instance repository forms — governs where
  `config/gates.yml` lives and why `config/gates.example.yml`, not a populated file,
  ships inside this repository.
- `CONTRIBUTING.md` §"Changing a Governance Gate" — the test-writing standard every
  Success Criterion above is written to satisfy.
- `FS-0022`: Gate coverage — introduced `RESERVED_PATHS`, `EXPORTED_PREFIXES`,
  `REF_EXEMPT`, and `scripts/README.md`, all revised for portability here without
  their enforcement logic changing.

## Rollout / Migration

1. `ADR-0033` and this FS require human approval (deferred approval is not appropriate
   here — see `ADR-0026`: this is ordinary single-package review, not a package too
   large to evaluate as one decision).
2. PLAN-0024 requires human approval regardless of `interfaces:` containment, because
   every path it touches is reserved under `ADR-0027`.
3. Implementation proceeds per PLAN-0024: the resolution and self-check changes to the
   three scripts, `config/gates.example.yml`, the `scripts/README.md` update (landing
   in the same change that accepts `ADR-0033`, per rule 3), the exported-surface table
   corrections in `README.md` and `AGENTS.md`, the `docs/specifications/README.md`
   bullet-list addition, and the bats suite.
4. The `CHANGELOG.md` entry is added at this point — not before — because it would
   otherwise describe unapproved, unimplemented work as though it were current, which
   is the same premature-assertion failure `ADR-0030` rule 3 exists to prevent on the
   current-state-document side.
5. This FS and PLAN-0024 transition to `implemented` in the completing PR.

## Open Questions

None.
