---
type: adr
id: ADR-0048
status: accepted
decision_scope: system
reversible: unknown
related_specs:
  - FS-0051
superseded_by: null
created: 2026-09-29
updated: 2026-09-29
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
-->
# ADR-0048: Worker and publisher credential separation

## Status

- Accepted

## Context and Problem Statement

A worker runs model-driven code. Its inputs — work-item text, repository content,
retrieved documents — are untrusted, and a model can be induced to act on
instructions embedded in them. If the worker's environment carries a GitHub write
credential, then a confused or manipulated run can write to the substrate
directly: comment, label, open a PR, or push a branch. The engine's own
authority checks would be bypassed by the very process they are meant to
constrain.

The reflex is to constrain the worker with instructions, a tool allowlist, or a
named runtime profile. None of those establish a credential boundary. A tool
allowlist is a property of the agent's own configuration, which the agent's
inputs can influence; a profile name is a label, not an isolation proof.

Separately, publication needs a single accountable identity. If several
processes can write, "one canonical publication per intent" from `ADR-0047`
becomes unachievable in practice, and the audit trail fragments across
identities.

## Decision Drivers

- Containment: untrusted input must not be able to reach a write credential.
- Verifiability: the boundary must be checkable from inside the worker, not
  asserted in prose.
- Accountability: publication must be attributable to one narrow identity.
- Non-escalation: the publishing identity must not be able to cross a human gate.

## Considered Options

### Option A — Give the worker a scoped write token

Fewer moving parts and one hop instead of two. Rejected: the credential sits in
the same process that consumes untrusted input, so containment depends entirely on
the model's behavior.

### Option B — Worker returns evidence; a separate publisher writes

The worker produces a patch, changed paths, a base revision, check results, and
provenance, with no GitHub write credential available to it. A separate publisher
revalidates current authority and the artifact's conformance to the authorized
scope, then performs the write.

### Option C — Worker writes through a broker holding no credentials

Tempting because it appears to remove the credential from everywhere. Rejected for
the pilot: it moves the same authority problem into an undesigned component and
does not reduce the number of trust boundaries to verify.

## Decision Outcome

**Option B.** Separate credential-free evidence production from publication.

**The worker:**

- MUST NOT hold a usable GitHub write credential: no token in its environment, no
  mounted `gh` login, no SSH push key, no Git credential helper, and no publisher
  secret.
- Returns evidence: the patch, the changed paths, the base revision, model and
  provider actually used, and check results attributed to the exact proposed tree.
- Cannot declare its own tests independently verified; reported results are
  claims until checked against the artifact.

**The publisher:**

- Holds one narrowly scoped credential and is the only automated writer.
- Revalidates the grant under `ADR-0047` and the work item's current state before
  writing, and verifies its own GitHub identity before any `gh` operation or push.
- Validates the artifact against the authorized scope, the base revision, and the
  changed-path expectations.
- Creates at most one canonical draft proposal per intent, then reads it back.
- MUST NOT merge, mark a PR ready for review, approve, or otherwise cross a human
  gate.

The boundary is a **process, filesystem, environment, and network** boundary. It
is verified by probing the effective environment from inside the worker, not by
asserting that a profile or allowlist exists.

### What this ADR does not decide

**Network egress is not constrained here.** Whether the worker may reach the
general internet, and if so which destinations, is a separate boundary that no
in-worker credential probe can verify: the absence of a credential is not the
absence of a network path to one. That boundary is deliberately left as a named
non-goal rather than asserted, and must be specified in `FS-0051` or its `PLAN`
before any claim about it is made.

Ledger technology; publisher concurrency and fencing; the discovery algorithm for
pre-existing remote publications; and the exact CI trust rules for branches a
publisher creates. The last of these matters: a worker without credentials can
still propose code that later executes in a privileged workflow, so the CI trust
boundary is configured separately and is not covered by worker isolation.

## Consequences

### Positive

- A compromised or confused run cannot write to the substrate.
- Publication is attributable to one identity that provably cannot merge.
- The two trust boundaries (worker, publisher) can be tested independently.

### Negative

- Two hops and a handoff format to specify and test.
- The evidence handoff must be validated; a worker can return a patch that does
  not match its claimed scope.
- An ambiguous external write (a create whose acknowledgement was lost) is a real
  state. It is resolved by discovery, or held for human inspection — never by
  retrying the create.

### Neutral

- Isolation makes local development slightly awkward, which is the intended
  trade.

## Validation

- A credential probe run from inside the worker finds no usable GitHub write
  credential, including environment, mounted files, and helper configuration.
- A publisher instructed to merge, approve, or mark ready fails: the identity
  lacks the capability, and host protection rules reject it.
- A worker attempting a direct `gh` write fails, and the failure is visible as an
  isolation violation rather than a silent retry.
- With a grant revoked between dispatch and publication, the publisher holds the
  evidence and records why.
- Ambiguous-write fault injection at the create boundary produces a hold, not a
  second PR.

## Links

- Spec: `FS-0051`
- Related: `ADR-0047` (authorized intent identity and the human grant)
- Related (same repository): `ADR-0012` (no agent merges), `ADR-0018` as amended by
  `ADR-0029` and `ADR-0036` (attribution)
