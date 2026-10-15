---
type: adr
id: ADR-0047
status: proposed
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0047: Merge the governance and operations templates

## Status

- Proposed

## Context and Problem Statement

The framework is split across two template repositories:

- `conventional-agents` — the governance template: ADRs, the FS/PLAN lifecycle,
  roles, skills, and the gate scripts. It governs itself and is vendored by every
  consumer.
- `collective-agents` — the operations template ("generalized protocol layer"): the
  engine spec (FS-0001), the grant model (ADR-0001), and the worker/publisher split
  (ADR-0002). It vendors `conventional-agents` as a git submodule.

That second template consuming the first through the *same* submodule mechanism the
instances use is a recursion, and it has cost more than it has returned:

- **It produced mis-homing.** Operations content — ADR-0045 (bounded runs) and
  ADR-0046 (two-loop tick) — landed in the governance repo, because the operations
  repo did not exist when they were written and the boundary was never operationally
  enforced. The boundary the split was meant to maintain did not maintain itself.
- **It duplicates the governance template's machinery.** `collective-agents` carries
  its own `docs/decisions/README.md`, `scripts/gates/check-status.sh`, markdownlint
  configs, `package.json`, and two CI workflows — a structural clone of the repo it
  vendors.
- **It adds a second pin every consumer tracks.** collective-agents sits ~60 commits
  behind its own vendor, independently of the 60–147-commit drift the other consumers
  already show.
- **It forces a public-flip ordering.** The governance repo must go public before the
  operations repo, purely because the latter's submodule would otherwise fail to
  resolve for anonymous users.

And the split pays for nothing yet. Nothing consumes `collective-agents` (pack-protocol
and feral-fleet vendor only conventional-agents; advance-operations does not exist), and
it contains no engine code — two ADRs, one FS, one PLAN, and research drafts. Its
justifications are all still hypothetical:

| Claimed benefit | Reality on this mesh |
| --- | --- |
| Consumers take governance without operations (feral-fleet) | Vendoring is not running; a leaf simply ignores the operations directory |
| Separate maturity/cadence (stable governance vs experimental engine) | collective-agents has moved little since creation; there is no engine |
| Separate visibility (public governance, private operations) | Both are planned public |
| Keeps app code out of the governance repo's charter | The engine does not exist yet |

ADR-0032 (template/instance forms) rejected mandatory splitting on the grounds that a
split "imposes the cost ... on repositories that have exactly one instance" and that
"extracting a reusable form before a second consumer exists means guessing at what
generalizes." The same logic applies one layer up: a second template repository was
created before a second consumer of it existed.

## Decision Drivers

- **The boundary must pay for itself.** A repository wall that does not prevent the
  mis-homing it exists to prevent is pure overhead.
- **A decision needs one authoritative home.** The reconciliation this ADR accompanies
  exists because authority (ADR-0001) and publication (ADR-0002) were specified in a
  separate repo from the run/tick content that disagreed with them.
- **Concrete action over documentation.** Collapsing two repos into one removes the
  inconsistency; a reconciliation document that explains the inconsistency does not.
- **ADR-0032's discipline.** Do not extract a reusable form before a second consumer
  exists; re-extract when the engine actually ships.
- **Cost of reversal is asymmetric.** The merge is ~20 files today; it is an order of
  magnitude more once instances vendor both templates and the engine is built.

## Considered Options

### Option A — Keep two repositories (status quo)

Preserves the intended layer separation and the "no app code in the governance repo"
charter. But it keeps the recursion, the duplicated scaffolding, the doubled drift, the
public-flip coupling, and the mis-homing vector — all realized costs against benefits
that remain hypothetical. *Rejected.*

### Option B — Merge now; re-extract when the engine exists

Collapse the two templates into one repository, with `conventional-agents` as the
survivor (it is the base, the vendored unit, and the public name). The
governance/operations boundary becomes a directory-and-lint-gate boundary inside one
repo, not a repository wall. The engine is re-extracted as its own package/repo only
when FS-0001 is actually implemented, per ADR-0032. *Chosen.*

### Option C — Merge later, once the engine ships

Defers the merge until the "app code" distinction is real. This waits for a divergence
that has not occurred, and pays the running costs of the split (drift, duplication,
mis-homing risk) for the entire interval, after which the merge is far more expensive.
*Rejected.*

## Decision Outcome

**Chosen option: Option B — merge now, re-extract when the engine exists.**

`conventional-agents` survives and absorbs `collective-agents`; `collective-agents` is
archived. Its two ADRs are renumbered into the surviving repository's sequence
(ADR-0001 → ADR-0048, ADR-0002 → ADR-0049, taking the IDs after this one), and its FS,
PLAN, ARC42, research drafts, and gate config move into the surviving tree. The
governance/operations boundary is expressed as a directory and enforced by the same
lint/status gates the framework already runs, not by repository walls.

The org/visibility migration (transfer conventional-agents to Advance.Enterprises,
re-pin the consumer submodules, scrub instance data, flip public) is the operational
spine that surrounds this merge and is planned separately (PLAN-0058). Branch
protection — the mechanism behind ADR-0012's merge gate — is restored by the public
flip, which a free-plan org supports only for public repositories.

## Consequences

### Positive

- One vendored unit, one pin, one version. The recursion, the duplicated scaffolding,
  and the public-flip ordering coupling all disappear.
- The authority correction (grant over status-inferred go) and the worker-framing fix
  (workers produce evidence, the publisher writes) become same-repo ADR revisions
  rather than cross-repo moves.
- The mis-homing vector dies: there is no second repo into which operations content can
  "belong elsewhere" and drift.

### Negative

- conventional-agents' charter ("no application code; documentation-centric") must be
  revisited when the engine is re-extracted — the merge defers, but does not remove,
  that decision.
- Two accepted ADRs (ADR-0001, ADR-0002) change their IDs and repository. Their
  authority is unchanged; their location and numbering are not.

### Neutral

- feral-fleet (a leaf repo) and the runtime bindings (ADR-0039) are unaffected by the
  merge: the former vendors only conventional-agents, the latter is content work in the
  surviving repo.

## Validation

- **Signal:** after the merge, `collective-agents` is archived and no consumer's
  `.gitmodules` references it. Checkable by `gh api` on each consumer.
- **Signal:** the surviving repo's ADR/FS/PLAN registries remain sequential and
  gap-free (`npm run check:status`).
- **Failure condition:** if the engine (FS-0001) is implemented without a re-extraction
  decision, the "no app code" charter has been silently violated — the re-extraction
  ADR is the scheduled follow-on when PLAN-0001 is picked up.

## Links

- ADR-0032: Template and instance repository forms — the "defer extraction" principle.
- ADR-0024 / ADR-0039: the substrate- and runtime-binding layers, unaffected by the merge.
- collective-agents ADR-0001 / ADR-0002: the grant model and worker/publisher split,
  re-homed and renumbered by this decision.
- PLAN-0058: the migration that carries out this merge and the surrounding org/visibility
  moves.
