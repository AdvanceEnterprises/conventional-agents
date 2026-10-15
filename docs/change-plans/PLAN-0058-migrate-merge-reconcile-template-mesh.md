---
type: change-plan
role: implementer
language: shell
status: draft
related_specs: []
related_adrs: [ADR-0047, ADR-0032, ADR-0026]
touches:
  - "docs/decisions/ADR-0047-merge-governance-and-operations-templates.md"
  - "docs/change-plans/PLAN-0058-migrate-merge-reconcile-template-mesh.md"
  - "docs/decisions/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
created: 2026-10-14
updated: 2026-10-14
---

# Change Plan: Migrate, merge, and reconcile the template mesh

> **Note:** this plan is `draft`. It is a migration plan whose steps are mostly
> *cross-repository* operations (org transfer, submodule re-pins, an archive), so most
> of its `touches:` live outside this repository and are named in prose rather than
> listed as in-repo paths. The governing decision is ADR-0047; there is no feature spec
> because a migration implements no testable behavior — it is validated by repository
> state (see §8).

## 1. Feature / Issue Reference

* Governing decision: ADR-0047 (merge the governance and operations templates)
* Related ADR ID(s): ADR-0032 (template/instance forms), ADR-0026 (recorded approval)
* Issue / PR Reference: supersedes and closes PR #227 (ADR-0046/FS-0051/PLAN-0057,
  the two-loop tick, which ADR-0047 re-homes)

## 2. Scope of Change

**This plan WILL:**

* Transfer conventional-agents from Tais-Den to Advance.Enterprises (private → private).
* Re-pin the `vendor/conventional-agents` submodule URLs in pack-protocol and
  feral-fleet to the new org.
* Fold collective-agents into conventional-agents (renumber its ADRs, move its FS,
  PLAN, ARC42, research, and gate config), and archive collective-agents.
* Revise ADR-0045 (replace the status-inferred go with the grant model) and re-frame
  ADR-0046 (worker produces evidence; publisher writes) as same-repo ADR revisions.
* Compose feral-fleet ADR-0023 / FS-0028 with the publisher layer (ADR-0002).
* Author the Hermes-Agent runtime binding (own FS/PLAN, per ADR-0039 §5).
* Scrub instance data, then flip the merged repository public — which enables branch
  protection and satisfies ADR-0012's merge gate.

**This plan will NOT:**

* Change the authority of ADR-0001 / ADR-0002 (re-homed and renumbered, not reopened).
* Alter the substrate- and runtime-binding models (ADR-0024 / ADR-0039).
* Implement FS-0001's engine — that remains a later re-extraction (ADR-0047).

## 3. Tests Driving This Change

None. This is a migration; it is validated by repository state, not a bats suite. The
acceptance checks are in §8.

## 4. Files to Be Modified

In this repository (conventional-agents):

* `docs/decisions/ADR-0047-*.md`, `docs/change-plans/PLAN-0058-*.md` — this package.
* `docs/decisions/ADR-0048-*.md`, `docs/decisions/ADR-0049-*.md` — renumbered
  collective-agents ADR-0001 / ADR-0002 (step 3).
* `docs/specifications/`, `docs/change-plans/`, `docs/research/`, `config/gates.yml` —
  folded collective-agents content (step 3).
* `docs/decisions/ADR-0045-*.md` — the grant-model revision (step 4).
* `docs/decisions/README.md`, `docs/change-plans/README.md`, `docs/specifications/README.md`,
  `CHANGELOG.md` — index and changelog rows throughout.

In other repositories (named in prose, not touched by this repo's diff):

* `pack-protocol/.gitmodules`, `feral-fleet/.gitmodules` — submodule re-pin (step 2).
* `feral-fleet/docs/decisions/ADR-0023-*.md`, `docs/specifications/FS-0028-*.md` — the
  publisher composition (step 5).
* `collective-agents` — archived (step 3).

## 5. Implementation Steps (High-Level)

1. **Transfer** conventional-agents Tais-Den → Advance.Enterprises (private → private;
   not a visibility change).
2. **Re-pin** `vendor/conventional-agents` submodule URLs in pack-protocol and
   feral-fleet to `Advance.Enterprises/conventional-agents`.
3. **Fold** collective-agents into conventional-agents: renumber ADR-0001 → ADR-0048,
   ADR-0002 → ADR-0049; move FS-0001, PLAN-0001, ARC42, `docs/research/`,
   `config/gates.yml` into the surviving tree; archive collective-agents.
4. **Revise** ADR-0045 (replace status-inferred go with the grant model) and ADR-0046
   (worker produces evidence; publisher writes) as same-repo ADR revisions.
5. **Compose** feral-fleet ADR-0023 / FS-0028 with the publisher layer (ADR-0002).
6. **Author** the Hermes-Agent runtime binding (own FS/PLAN, per ADR-0039 §5).
7. **Scrub** instance data (config/project.yml board/project IDs, any token references),
   then **flip public** — enabling branch protection on the free plan and satisfying
   ADR-0012's merge gate.

Steps 4–6 are order-independent and may run in parallel; steps 1–3 and 7 are
strict-order.

## 6. Constraints and Guardrails

* ADR-0032 — no instance data in a published repository; scrub precedes the public flip.
* ADR-0026 — the merge is a recorded human-approved act; the renumbered ADRs are
  re-homed, not re-decided.
* ADR-0012 — merge authority remains human-gated; branch protection is restored by the
  public flip, not by an org plan change.
* ADR-0039 §5 — each runtime binding gets its own FS/PLAN; the Hermes-Agent binding is
  authored, not improvised.

## 7. Risks and Edge Cases

* **A no-protection window.** Steps 1–6 run in Advance.Enterprises *private*, with no
  branch protection; this is not a regression (conventional-agents' trunk is unprotected
  today) and step 7 closes it.
* **Submodule resolution during the transfer.** Between step 1 and step 2 the old
  `Tais-Den/conventional-agents` URL is stale; re-pin promptly to avoid consumer clone
  breakage.
* **Renumber collisions.** collective-agents' ADR-0001/0002 must be renumbered into the
  surviving sequence without colliding with open PRs (§1 closes #227 first).

## 8. Validation

* After step 2: `gh api repos/<owner>/<repo>/contents/.gitmodules` on each consumer
  resolves to `Advance.Enterprises/conventional-agents`.
* After step 3: `collective-agents` is archived; `npm run check:status` in
  conventional-agents is green with a sequential, gap-free registry.
* After step 7: the repository is public and `trunk` has branch protection enabled.

## 9. Explicit Non-Changes

* ADR-0001 / ADR-0002 authority and wording — re-homed and renumbered only.
* ADR-0024 / ADR-0039 binding models.
* feral-fleet's leaf status (it vendors conventional-agents, not the merged operations
  layer).

## 10. Readiness Check

* [x] Governing decision is drafted (ADR-0047)
* [x] Steps are explicit and ordered
* [x] Cross-repository scope is named rather than implied
* [x] No code implementation implied (engine re-extraction is deferred)

## Declaration

I affirm that:

* This plan reflects the full intended scope of the migration
* No governance decision is re-opened by re-homing it
* Any deviation will require revising this plan before execution
