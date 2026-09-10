---
type: adr
id: ADR-0040
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0032
superseded_by: null
created: 2026-09-10
updated: 2026-09-10
---

# ADR-0040: ArcOps architecture-intent checker boundary

## Status

- Proposed

## Context and Problem Statement

`conventional-agents` governs how work is proposed, authorized, executed, and
evidenced. It does not currently retrieve architecture context or check a
proposed change against accepted intent: nothing reads `docs/ARC42.md`, the
accepted ADRs, or the approved FS/PLAN corpus and asks "does this plan or diff
conflict with what we already decided?"

The cost of that gap is paid in review effort. Reviewers re-derive the
architecture context for every change, and drift between a change and the
accepted intent is caught by eye, late, and inconsistently. A separate
architecture-intent capability — provisionally called ArcOps — could reduce
that drift and reviewer effort, but only if two boundaries hold:

1. **Git remains authoritative.** ArcOps reports; it never silently rewrites,
   never transitions work items, and never approves or rejects merges.
2. **The framework stays a standards kit, not an application platform.**
   `ADR-0007` draws the "standards only, never orchestration" line, and
   `ADR-0024` keeps the core platform-neutral. A checker that ships inside the
   framework core would make every consumer adopt an analysis tool they did
   not ask for.

`#124` (benchmark governed agent performance) also needs this capability as a
separate experimental arm: measuring whether an architecture-intent checker
reduces reviewer effort requires the checker to be an independent variable,
not a framework component.

## Decision Drivers

- **Git-authoritative reporting.** The checker explains and flags; Git and
  human gates decide (`ADR-0007`, `ADR-0026`).
- **No second source of truth.** The accepted corpus — `docs/ARC42.md`,
  accepted ADRs, approved FS/PLAN documents — is the only intent source; the
  checker indexes it with revision identity, it does not copy it.
- **Consumer neutrality.** No consumer must install ArcOps to use
  `conventional-agents` (`ADR-0024` tool neutrality).
- **No application platform.** The framework ships standards and gates, not
  analysis services (`ADR-0007`).
- **Benchmark arm.** `#124` measures the checker as an independent variable.
- **Read-only first slice.** Automatic rewriting, merge approval, generic
  chat, and hosted-service requirements are explicitly out of the first
  slice.

## Considered Options

### Option A — In-framework script (like `check-conformance.sh`)

Ship the checker as a framework script, registered in `package.json`, in the
same shape as the consumer conformance doctor (`FS-0031`, draft — #147).

Uniform and strongly governed. It is a category error: the conformance doctor
checks *adoption of the framework* and is therefore framework tooling; ArcOps
checks *architecture intent* and is an analysis capability with its own
corpus, its own output contract, and its own pilot surface. Embedding it makes
every consumer install an analysis tool they did not ask for, and blurs the
`ADR-0007` line — a checker that can flag "this plan conflicts with an
accepted ADR" is one step from a gate that blocks on it, which is exactly the
orchestration the framework must not ship.

### Option B — Separate ArcOps repository with a small integration contract here (chosen)

The framework defines the boundary contract — what ArcOps may read, what it
may claim, and what it may never do — in this ADR and `FS-0032`. The pilot
implementation lives in a separate ArcOps repository, and consumers opt in.

Keeps the framework neutral, keeps the checker independently versioned and
measured, and gives `#124` its experimental arm. The cost is a second
repository and a contract that must be maintained — but the contract is small
and stable: the corpus locations, the read-only rule, and the output shape.

### Option C — Framework extension module under `integrations/`

Package ArcOps as binding content under `integrations/`, reusing the
`ADR-0037`/`ADR-0039` directory envelope.

`integrations/` is the home for *platform mappings* — substrate bindings
(`ADR-0024`) and runtime bindings (`ADR-0039`). ArcOps is neither: it does not
map a framework concept onto a platform, it analyzes a repository against its
own accepted intent. Forcing it into the binding envelope misstates what it
is and drags the binding-content rules (provisions/reports classification,
target resolution) onto a capability they were not written for.

## Decision Outcome

**Chosen option: Option B — ArcOps is a separate capability; the framework
ships the boundary contract, not the checker.**

### 1. The boundary contract lives in the framework

This ADR and `FS-0032` define what ArcOps is and is not. The framework's
exported surface gains the contract as documentation; no framework script,
gate, or CI job depends on ArcOps existing.

### 2. ArcOps may explain and flag; Git and human gates decide

ArcOps output is a structured report — conflict, severity, affected path,
source citation, and uncertainty — against a proposed plan or diff. It never
writes to the repository, never transitions work items, and never approves or
rejects merges. `ADR-0026` approval remains a recorded human act; ArcOps
cannot produce it.

### 3. The corpus is the accepted intent, indexed with revision identity

The checker reads `docs/ARC42.md`, accepted ADRs, and approved FS/PLAN
documents, and cites each claim to the exact source artifact and commit. It
does not maintain a second copy of the intent.

### 4. The first slice is read-only and local

No automatic rewriting, no merge approval, no generic chat, no hosted-service
requirement. The pilot runs against `conventional-agents` and `pack-protocol`
and reports false positives, missed conflicts, and reviewer usefulness —
feeding `#124`.

### 5. The implementation lives in a separate ArcOps repository

The pilot implementation is consumer-side, outside the framework's CI and
governance surface. The framework's obligation is the contract; the ArcOps
repository's obligation is the implementation.

## Consequences

### Positive

- The framework remains a standards kit; no consumer is forced to install an
  analysis tool.
- The checker is independently versioned, measured, and benchmarked (`#124`).
- The read-only rule is structural: a checker that cannot write cannot
  silently rewrite.

### Negative

- The pilot requires a second repository and a maintained integration
  contract.
- The framework cannot verify ArcOps conformance from inside its own CI; the
  contract is enforced by review, not by gate.
- ArcOps consumes the corpus as it stands: a citation to a document whose
  `updated:` is stale under the FS-0027 freshness gate may still be indexed
  as effective intent. The framework gate flags the staleness on its own;
  ArcOps does not duplicate that finding.

### Neutral

- The ArcOps repository is consumer-side and not governed by the framework's
  CI; its own governance is its own choice.

## Validation

- `FS-0032` success criteria are the acceptance test for the contract.
- The pilot against `conventional-agents` and `pack-protocol` validates the
  corpus model and the output shape.
- `#124` measures reviewer usefulness as the experimental arm.

## Links

- `FS-0032` — the read-only pilot specification.
- `#143` — the originating work item.
- `#124` — the benchmark that measures ArcOps as an experimental arm.
- `ADR-0007` — standards only, never orchestration.
- `ADR-0024` — platform-neutral core with shipped bindings.
- `ADR-0026` — approval is a recorded act.
