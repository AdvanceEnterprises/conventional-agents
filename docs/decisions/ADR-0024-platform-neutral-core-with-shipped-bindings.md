---
type: adr
id: ADR-0024
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
  - FS-0020
superseded_by: null
---

# ADR-0024: Platform-neutral core with shipped bindings

## Status

- Proposed

## Context and Problem Statement

FS-0018 defines how governed work originates: a work item is created, classified
along three axes, and moves through workflow phases under gates that constrain what
an unattended agent may do. That governance content is the point of the spec.

The spec expresses all of it in GitHub's vocabulary. The work item is an Issue. The
classification axis that keys the safety gate is a GitHub Project custom single-select
field. The phase axis "lives on the GitHub Project." The parked state is the
`question` label. The spec's `interfaces:` block names a GitHub Project field
directly, and its Dependencies section requires the GitHub Labels API, GitHub Projects
v2, and `gh project` CLI or GraphQL access.

This creates a conflict with constraints the framework has already stated.
`docs/ARC42.md` §2 states that the framework "must not require adoption of a specific
workflow kit or runtime," and §1.2 ranks Tool Neutrality as the second-highest quality
goal, above both Submodule Friendliness and Enforceability. ARC42 §11 lists scope creep
into workflow orchestration as a high-impact risk whose stated mitigation is to "enforce
non-goals and document deviations via ADRs." ADR-0007 chose "stay strictly adjacent —
standards only, never orchestration" for the same reason.

None of those sources settles the question by precedence. ARC42 is itself `status:
Draft`, and ADR-0007 is `status: proposed` — the README index listing it as accepted is
one of eleven inaccurate entries in that table. So this is not an accepted constraint
overruling a draft spec; it is two draft-level sources pointing one way, a third
drafting itself the other way, and nothing adjudicating. That is precisely the situation
an ADR exists to resolve.

There is a second force, pulling the other way, and it is not weaker. ARC42 §8.2
requires quality gates to be checkable rather than aspirational, and no test can be
written against an abstraction. This repository has a demonstrated failure mode here:
`packs/` and `integrations/` have been listed as planned building blocks in ARC42
since the architecture document was first written, and neither directory exists. A
purely abstract work-item vocabulary, with concrete bindings deferred to consumers,
would very likely join them — producing guidance that is neutral, unfalsifiable, and
unused.

The framework also has a specific, non-hypothetical consumer: itself. This repository
runs on GitHub Issues and Projects, and will continue to. Whatever the framework
prescribes, its own operation is a GitHub operation, and pretending otherwise in the
documentation would make the framework's dogfooding claim false.

The question this ADR answers: **how does the framework describe workflow substrate
so that the governance is portable, the guidance stays checkable, and the framework's
own GitHub usage remains honestly documented?**

## Decision Drivers

- **Stated constraints deserve an explicit override, not a silent one.** Tool Neutrality
  and ADR-0007 point one way; a new spec may overrule them, but only by saying so.
- **Abstraction must be extracted, not imagined.** Guidance derived from a working
  implementation is testable; guidance written ahead of one becomes `packs/`.
- **The framework's own substrate should be documented, not hidden.** This repo uses
  GitHub. That belongs in the exported surface as a binding, not as an embarrassment.
- **A consumer on another platform must have something to conform to.** "Use whatever
  you like" is not a specification.
- **Cost of reversal is asymmetric.** Vocabulary propagates. Every downstream document
  that learns GitHub nouns has to be rewritten if the substrate is genericized later.

## Considered Options

### Option A — GitHub as substrate

Approve FS-0018 substantially as written. GitHub Issues and Projects are the framework's
work-item model. Consumers on other platforms adapt as best they can, guided by
`INTEGRATION.md`.

Cheapest immediately, and it matches what the framework actually runs on. But it
contradicts ARC42 §2 and sits badly against ADR-0007 without ever saying so, which is
precisely the undocumented deviation ARC42 §11 names as the risk. Because PR #71 is
the bootstrap for the SDLC workflows and both collaboration-mode specs, GitHub
vocabulary would propagate into all of them before any correction could land.

### Option B — Fully generic, no bindings

Rewrite FS-0018 with a platform-neutral work-item vocabulary and ship no concrete
binding at all. GitHub specifics move to consumer-implementation territory, mentioned
in `INTEGRATION.md` at most.

Maximally neutral and the leanest exported surface. But it produces exactly the
unfalsifiable guidance ARC42 §8.2 warns against, gives adopters nothing to copy, and
leaves the framework's own GitHub usage undocumented in the surface it exports. On
this repository's track record, the concrete layer would not subsequently appear.

### Option C — Generic core with bindings shipped alongside, binding written first

Two layers, both normative, both in the exported surface:

- A platform-neutral core that names the *capabilities* a workflow substrate must
  provide, expressed as a conformance checklist.
- One or more *bindings* that map those capabilities onto a specific platform. The
  GitHub Issues and Projects binding ships in the same change, written in full.

The ordering is load-bearing: the binding is written first and completely, and the
neutral core is extracted from it. The abstraction is therefore a generalization of
something that demonstrably works rather than a prediction about what might.

### Option D — Generic core, bindings deferred to a later spec

As Option C, but the GitHub binding is promised rather than delivered — a follow-up FS
after the core lands.

Preserves sequencing discipline on paper. In practice this is Option B with an
intention attached, and `packs/` and `integrations/` are two prior instances of that
intention not surviving contact with subsequent priorities.

## Decision Outcome

**Chosen option: Option C — generic core with bindings shipped alongside, binding
written first.**

### The two layers

**Core (platform-neutral, normative).** The core names the capabilities a substrate
must provide for the framework's governance to hold. It does not name a platform, a
product, or an API. A substrate conforms when it provides:

1. A **work item** that can exist before any FS, PLAN, or ADR, carrying a free-text
   brief.
2. A **type** attribute on the work item, single-valued from a closed set, which keys
   the applicable safety gate, and whose modification is *attributable* — so that a
   change by an agent is detectable after the fact.
3. A **phase** attribute, single-valued from a closed set, tracking workflow position.
4. A **parked state** that suppresses agent action while set, and whose presence an
   agent can read before acting.
5. An **activity record** whose entries are ordered and attributable. Entries recording
   state transitions must be non-retractable; entries recording agent commentary need
   not be.
6. A **trigger source** capable of invoking an agent on work-item events or on a
   schedule.

Conformance is checkable: a binding either maps all six onto concrete platform
mechanisms or it does not.

### Detection over prevention

Capabilities 2, 4, and 5 are stated in terms of *attributability* rather than
*enforcement*, and this is deliberate rather than a concession.

The first binding written under this ADR established that GitHub cannot enforce any of
the three: Projects v2 has no per-field access control, labels carry no per-label
permission, and Issue comments are deletable by their author. An earlier draft of this
ADR required a type attribute "which agents cannot modify," and no known work-tracking
platform can supply that — the requirement was unsatisfiable, and would have been
extracted into every downstream document had the core been written before a binding.

The framework therefore requires that agent deviation be **visible**, not that it be
**impossible**. A binding claiming prevention where its platform offers only detection
is non-conforming, and must say which of the two it provides.

This has a corollary worth stating: the merge gate (`ADR-0012`) is the framework's only
rule that a substrate can genuinely enforce, via branch protection. That asymmetry is a
reasonable explanation for why merge is the rule made non-overridable, and why the
others are rules of conduct backed by audit.

**Bindings (platform-specific, normative for users of that platform).** A binding maps
each core capability onto a named mechanism. Bindings live in `integrations/`,
materializing the directory ARC42 §5.1 has reserved for tool-specific guidance since
the architecture document was written. The GitHub binding is
`integrations/github-issues-projects.md`.

### The ordering rule

The GitHub binding is authored first and in full. The core is then extracted from it
by removing platform nouns and generalizing mechanisms into capabilities. No future
binding may be merged as a stub, and no future core capability may be added that no
existing binding implements. The core is a generalization over shipped bindings, never
a forecast.

### What this does not change

FS-0018's governance content is unaffected. The three-axis model, the origination
paths, the agent-stance comment requirement, and the autonomous gate all survive
intact; they are restated in capability terms in the core and in GitHub terms in the
binding. ADR-0019 through ADR-0023 are untouched. This ADR relocates vocabulary; it
does not reopen any decision those ADRs make.

The framework continues to run on GitHub Issues and Projects. That fact becomes
documented rather than assumed.

## Consequences

### Positive

- The framework's stated Tool Neutrality goal and ADR-0007's positioning are honored
  without giving up concrete, copyable guidance.
- Downstream documents — the two SDLC workflows, the review-board and consensus specs,
  their templates — learn capability vocabulary rather than GitHub vocabulary, so a
  future second binding costs one file instead of a corpus-wide rewrite.
- `integrations/` stops being a phantom directory in ARC42 §5.1 and becomes real.
- The framework's own GitHub usage is documented in the exported surface, where
  adopters can copy it, rather than being implicit in the specs.

### Negative

- One additional document to write and keep current, and a vocabulary pass across
  FS-0018 before it can be approved.
- Two documents must stay in sync. A change to a core capability requires revisiting
  every binding.
- Readers who only ever use GitHub must follow one indirection to find their concrete
  answer.

### Neutral

- The exported surface gains a top-level directory. `README.md`'s exported-surface
  table and ARC42 §5.1 both need a row; the ARC42 entry already exists as "planned"
  and changes state rather than being added.
- No position is taken on which platforms deserve future bindings. The ordering rule
  governs how one would be added; nothing obliges anyone to add one.

## Validation

- **Signal:** FS-0018, after revision, contains no GitHub product nouns outside
  explicit references to the binding document. Checkable by grep, in the same shape as
  `test/FS-0016/vendor-boundary.bats`.
- **Signal:** `integrations/github-issues-projects.md` maps all six core capabilities,
  with no capability marked deferred or planned.
- **Signal:** specifications built on this core reference capabilities rather than
  platform mechanisms. FS-0021 satisfies this; FS-0020 is pending.
- **Review checkpoint:** when a second binding is first proposed. If extracting it
  requires changing core capabilities, the core was under-generalized and this ADR's
  ordering rule needs revisiting.
- **Recorded instance:** the first binding already forced a core revision — capabilities
  2, 4, and 5 were restated from enforcement to attributability once GitHub was shown
  unable to enforce any of them. This is the ordering rule working as intended, and is
  the evidence for it, not against it.
- **Failure condition:** if `integrations/` still contains exactly one binding and no
  consumer has requested a second within a year of acceptance, the neutrality layer is
  costing more than it returns, and a superseding ADR should collapse the core back
  into the binding.

## Links

- ADR-0007: Adjacent-to-Spec-Kit positioning — quality standards, never orchestration.
- ADR-0007: Adjacent-to-Spec-Kit positioning — standards only, never orchestration
  (`proposed`; cited for its reasoning, not as a binding constraint).
- ADR-0016: Consumer conventions as local adaptations of the framework.
- `docs/ARC42.md` §1.2 (Tool Neutrality), §2 (architecture constraints), §5.1
  (`integrations/` as a planned building block), §8.2 (checkable gates), §11 (scope
  creep risk).
- FS-0018: Issue lifecycle and autonomous triggers — the spec this ADR requires be
  restated in capability terms.
- FS-0020: SDLC workflow definitions — first downstream consumer of the core
  vocabulary.
