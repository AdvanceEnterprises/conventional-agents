---
type: change-plan
role: implementer
language: shell
status: draft
related_specs: []
related_adrs: [ADR-0047, ADR-0032, ADR-0026, ADR-0012]
touches:
  - "docs/decisions/ADR-0047-merge-governance-and-operations-templates.md"
  - "docs/change-plans/PLAN-0058-migrate-merge-reconcile-template-mesh.md"
  - "docs/decisions/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
  - "docs/specifications/README.md"
  - "docs/operations/ARC42.md"
  - "config/gates.yml"
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
* Related ADR ID(s): ADR-0032 (template/instance forms), ADR-0026 (recorded approval),
  ADR-0012 (non-overridable merge gate)
* Issue / PR Reference: supersedes and closes PR #227 (ADR-0046/FS-0051/PLAN-0057, the
  two-loop tick)

## 2. Scope of Change

**This plan WILL:**

* Transfer conventional-agents from Tais-Den to Advance.Enterprises (private → private).
* Re-pin the `vendor/conventional-agents` submodule URLs in pack-protocol and
  feral-fleet to the new org.
* Fold collective-agents into conventional-agents — renumber its ADRs/FS/PLAN via the
  identity map in §4a, migrate their internal cross-references, reconcile the stale
  `PARSING_HINTS`, and archive collective-agents.
* Amend ADR-0045 (status-inferred go → grant model) via a *successor* ADR, and withdraw
  ADR-0046 (unmerged), folding its mechanics into the operations layer.
* Compose feral-fleet ADR-0023 / FS-0028 with the re-homed publisher ADR (ADR-0049).
* Author the Hermes-Agent runtime binding (own FS/PLAN, per ADR-0039 §5).
* Scrub instance data, flip the merged repository public, then configure and read back
  branch protection.

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
* Imported and renumbered: `docs/decisions/ADR-0048-*.md`, `ADR-0049-*.md`,
  `docs/specifications/FS-00NN-*.md`, `docs/change-plans/PLAN-00NN-*.md`,
  `docs/operations/ARC42.md`, `docs/research/**`, `config/gates.yml` (merged).
* `docs/decisions/ADR-0050-*.md` — the successor ADR that amends ADR-0045 (step 4).
* `docs/decisions/ADR-0045-*.md` — append-only Status note (never a body rewrite).
* `docs/decisions/README.md`, `docs/change-plans/README.md`, `docs/specifications/README.md`,
  `CHANGELOG.md` — index and changelog rows throughout.

In other repositories (named in prose, not touched by this repo's diff):

* `pack-protocol/.gitmodules`, `feral-fleet/.gitmodules` — submodule re-pin (step 2).
* `feral-fleet/docs/decisions/ADR-0023-*.md`, `docs/specifications/FS-0028-*.md` — the
  publisher composition (step 5).
* `collective-agents` — archived (step 3).

### 4a. Identity map and import manifest (lightweight)

| Source (collective-agents) | Destination (conventional-agents) | Notes |
| --- | --- | --- |
| `docs/decisions/ADR-0001` | `docs/decisions/ADR-0048-*.md` | renumber; reconcile `PARSING_HINTS`; migrate cross-refs |
| `docs/decisions/ADR-0002` | `docs/decisions/ADR-0049-*.md` | same |
| `docs/specifications/FS-0001` | `docs/specifications/FS-00NN-*.md` | next free FS ID |
| `docs/change-plans/PLAN-0001` | `docs/change-plans/PLAN-00NN-*.md` | next free PLAN ID |
| `docs/ARC42.md` | `docs/operations/ARC42.md` (new dir) | operations-layer architecture, distinct from `docs/ARC42.md` |
| `docs/research/**` | `docs/research/**` | merge |
| `config/gates.yml` | `config/gates.yml` | reconcile and merge, never replace |
| `scripts/**`, `.github/**`, `package.json` | (dropped) | duplicated scaffolding collapses; the survivor's copy wins |

Every imported document has its internal references to the old IDs remapped to the new
IDs (or a qualified `collective-agents/ADR-0001` pointer where history must be preserved),
and the stale `PARSING_HINTS` line ("This ADR is PROPOSED") is corrected to match the
`accepted` front matter. Import completeness is verified against the source tree before
collective-agents is archived.

## 5. Implementation Steps (High-Level)

1. **Transfer** conventional-agents Tais-Den → Advance.Enterprises (private → private;
   not a visibility change).
2. **Re-pin** `vendor/conventional-agents` submodule URLs in pack-protocol and
   feral-fleet to `Advance.Enterprises/conventional-agents`. Step 2 must follow step 1
   and complete before any consumer clones or builds against the new URL (the old
   `Tais-Den/...` URL is stale in the interim).
3. **Fold** collective-agents into conventional-agents per the §4a manifest: renumber
   (0001→0048, 0002→0049; FS/PLAN take next-free IDs), migrate cross-references,
   reconcile `PARSING_HINTS`, move the remaining content, then archive collective-agents.
4. **Amend ADR-0045 and withdraw ADR-0046.** ADR-0045 is amended by a *successor* ADR
   (ADR-0050) that records the grant-model replacement and wires `superseded_by` back from
   ADR-0045 via an append-only Status note — the accepted body is never rewritten in
   place, and the successor's acceptance is a recorded human act (ADR-0026). ADR-0046,
   unmerged and carried only by PR #227, is withdrawn: its two-loop mechanics are
   refolded into the operations-layer engine (FS-0001), and its instance knobs belong to
   pack-protocol configuration — so no successor ADR is needed for it. FS-0051 and
   PLAN-0057, the two-loop tick's spec and plan, are likewise not carried forward as
   separate documents; their content refolds into the engine FS/PLAN.
5. **Compose** feral-fleet ADR-0023 / FS-0028 with the re-homed publisher ADR
   (**ADR-0049**, after step 3's renumbering). This step depends on step 3.
6. **Author** the Hermes-Agent runtime binding (own FS/PLAN, per ADR-0039 §5).
7. **Finalize visibility and protection** — three ordered sub-steps:
   7a. **Scrub** instance data (config/project.yml board/project IDs, any token
   references).
   7b. **Flip public** — a prerequisite that *enables* protection, not proof of it.
   7c. **Configure and read back** branch protection on `trunk` (and any required
   writer/bypass permissions), satisfying ADR-0012's merge gate — re-verifying at this
   step that the free-plan-public-repo protection policy still holds (it is a
   policy-as-of-draft assumption).

Steps 4 and 6 are order-independent; step 5 depends on step 3. Steps 1–3 and 7a–7c are
strict-order.

## 6. Constraints and Guardrails

* ADR-0032 — no instance data in a published repository; scrub precedes the public flip.
* ADR-0026 — the merge and the ADR-0045 amendment are recorded human-approved acts; the
  renumbered ADRs are re-homed, not re-decided.
* ADR-0012 — merge authority remains human-gated; protection is *configured and read
  back*, not assumed from visibility.
* ADR-0039 §5 — each runtime binding gets its own FS/PLAN; the Hermes-Agent binding is
  authored, not improvised.
* Layer boundary — the governance/operations boundary is *review-enforced* (a documented
  placement rule: operations content under `docs/operations/`, governance content in the
  existing registries). Any future blocking gate for that boundary is a separate change
  with its own FS/PLAN, not an implicit property of the existing lint/status checks.

## 7. Risks and Edge Cases

* **A no-protection window.** Steps 1–6 run in Advance.Enterprises *private*, with no
  branch protection; this is not a regression (conventional-agents' trunk is unprotected
  today) and step 7c closes it by explicit configuration, not by the flip alone.
* **Submodule resolution during the transfer.** Between step 1 and step 2 the old
  `Tais-Den/conventional-agents` URL is stale; re-pin promptly to avoid consumer clone
  breakage.
* **Renumber collisions.** The imported ADR/FS/PLAN IDs must be renumbered into the
  surviving sequence without colliding with open PRs (§1 closes #227 first) or with the
  surviving repo's existing FS-0001/PLAN-0001, which the §4a identity map handles by
  taking next-free IDs rather than reusing 0001.
* **Reference-integrity drift.** An imported document that keeps a stale old-ID reference
  points at a now-nonexistent decision; the §4a reference-migration sweep must run before
  archiving the source, and a `check:status` re-run confirms the registries stay gap-free.

## 8. Validation

* After step 2: `gh api repos/<owner>/<repo>/contents/.gitmodules` on each consumer
  resolves to `Advance.Enterprises/conventional-agents`.
* After step 3: `collective-agents` is archived; `npm run check:status` in
  conventional-agents is green with a sequential, gap-free registry; no imported document
  still references a pre-renumber ID.
* After step 4: ADR-0045 carries an append-only Status note and ADR-0050 records the
  grant-model amendment with `Approved-By:`; the grant model is the stated authority, and
  no status-inferred go remains.
* After step 5: feral-fleet ADR-0023 names the publisher layer and defers the credential
  model to ADR-0049.
* After step 6: the Hermes-Agent binding has its own FS/PLAN and ships no
  status-mutating hooks or schedulers (ADR-0039).
* After step 7c: the repository is public, and `gh api repos/<owner>/<repo>/branches/trunk/protection`
  reads back the configured protection (not merely that visibility changed).

## 9. Explicit Non-Changes

* ADR-0001 / ADR-0002 authority and wording — re-homed and renumbered only, with
  references migrated and status reconciled.
* ADR-0024 / ADR-0039 binding models.
* feral-fleet's leaf status (it vendors conventional-agents, not the merged operations
  layer).

## 10. Readiness Check

* [x] Governing decision is drafted (ADR-0047)
* [x] Steps are explicit and ordered, with an identity map and import manifest
* [x] Cross-repository scope is named rather than implied
* [x] No code implementation implied (engine re-extraction is deferred)

## Declaration

I affirm that:

* This plan reflects the full intended scope of the migration
* No governance decision is re-opened by re-homing it
* Any deviation will require revising this plan before execution
