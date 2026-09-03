---
type: adr
id: ADR-0037
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0029
  - FS-0018
  - FS-0024
superseded_by: null
created: 2026-09-03
updated: 2026-09-03
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
- Use this document only to constrain or explain behavior, not to generate code.
-->

# ADR-0037: Executable layer for the GitHub binding

## Status

- Proposed

## Context and Problem Statement

`ADR-0024` established the two-layer substrate model — a platform-neutral core
naming capabilities, and bindings naming the mechanisms that provide them — and
shipped `integrations/github-issues-projects.md` as the reference binding. That
document does its job well. It maps all six capabilities onto named GitHub
mechanisms, and its §7 refuses to claim enforcement where GitHub offers only
detection.

It is also entirely declarative. It ends in a nine-item **Setup Checklist** whose
items are prose instructions a human follows by hand:

- [ ] `Issue Type` single-select field created with `feature`, `bug`, `task`
- [ ] Label vocabulary created: `enhancement`, `bug`, `documentation`, `spec`, `plan`, `question`
- [ ] Per-Issue concurrency serialization configured

Nothing creates those labels. Nothing verifies they exist. Nothing reports when
they drift. The binding tells a consumer what the substrate must look like and
then leaves them to make it look that way, once, from memory.

ARC42 §8.2 requires quality gates to be checkable rather than aspirational, and
`ADR-0024`'s own decision drivers name the failure mode: guidance written ahead
of a working implementation becomes `packs/`. A checklist is guidance written
ahead of an implementation. It is the same shape, one layer down.

### The evidence that this is not hypothetical

The framework operates alongside two consumer repositories that implement this
binding. The mechanisms the binding describes have been implemented repeatedly,
by hand, and have drifted:

- **The submodule-initialisation step is duplicated in at least four CI workflow
  files across two repositories.** Each copy performs the same `git config
  --global url."https://x-access-token:${TOKEN}@github.com/".insteadOf` rewrite
  followed by `git submodule update --init`. The `--global` is load-bearing —
  `git submodule update` clones in a child process that reads only global and
  system configuration — and that fact appears in no framework document. A new
  consumer reverse-engineers it from someone else's workflow YAML.
- **The label vocabulary has drifted.** The `FS-0018` six exist in all three
  repositories, but organisation additions do not: `propagation` is present in
  two and absent in the third. No one noticed, because nothing looks.
- **Board metadata is hand-maintained.** `config/project.example.yml` documents
  the *shape* of board metadata; the consumer files carrying real project,
  field, and option IDs are maintained by hand against it, with nothing checking
  that a hand-maintained file still matches the shape it was copied from.
- **Operational knowledge lives in session transcripts.** Projects v2 is
  GraphQL-only, and its *secondary* burst limit is invisible through the
  `rate_limit` endpoint — that endpoint reports the primary quota as full while
  real calls fail, and `gh project` surfaces the failure as `unknown owner type`.
  The working discipline (pace calls, probe before mutating, wait past the reset
  timestamp) was learned twice in one session and written down nowhere a reader
  would find it.

Every one of these is the same defect: the binding names a mechanism, and the
mechanism's operation is left to be rediscovered. The declarative layer cannot
fix it, because prose cannot be idempotent and cannot be tested.

### What is not the problem

This is not a gap in `integrations/github-issues-projects.md`. That document is
scoped to substrate mechanics — how work items are represented, classified,
moved, and observed — and it covers them. Restating operational detail there
would make a 321-line reference document into an operations manual and blur the
line `ADR-0024` drew.

Nor is it a gap in `FS-0018`, which governs the *lifecycle* of work items rather
than the provisioning of the substrate they live on.

The question this ADR answers: **does a binding under `ADR-0024` consist only of
a document, or may it also ship executable mechanisms — and if so, where do they
live, how are they governed, and what may they not do?**

## Decision Drivers

- **`ADR-0024`'s own driver applies recursively.** "Abstraction must be
  extracted, not imagined" was the argument against a core without a binding. A
  binding whose mechanisms are described but never executed is the same wager
  one level down, and this repository has now lost it twice.
- **A checklist is not a conformance test.** `ADR-0024` says conformance is
  checkable — "a binding either maps all six onto concrete platform mechanisms
  or it does not." Mapping is checkable by reading. Whether a given repository
  *is* in the mapped state is not, today, checkable at all.
- **`ADR-0007` is accepted and binding at precedence level 1.** "Standards only,
  never orchestration." Anything shipped here must survive that constraint
  read strictly, not read charitably.
- **`ADR-0015` classifies tools by how they are governed, and miscategorisation
  has a concrete cost.** `ADR-0034` states it plainly: a tool filed as
  Category 2 escapes the approved-FS requirement, and one filed as Category 3
  escapes governance entirely. A new kind of executable must be placed
  deliberately.
- **`ADR-0032` forbids instance data in a template repository.** Board IDs,
  project numbers, and field option IDs belong to the consumer. Whatever ships
  must be parameterised, not populated.
- **The substrate's authentication regime is about to change.** This repository
  is private and its consumers fetch it with a fine-grained token. On the day it
  becomes public, that token becomes unnecessary — and every copy of the token
  dance becomes a thing four workflow files still do for no reason. A change
  that is coming is cheaper to design for than to retrofit.
- **Enforcement honesty must survive the move to code.** The reference binding's
  §7 is its most valuable section. An executable layer that quietly implies its
  checks are controls, when they are audits, would undo that.

## Considered Options

### Option A — Leave the binding declarative; document harder

Expand `integrations/github-issues-projects.md` with the operational detail: the
`--global` requirement, the secondary rate limit, the `gh` CLI quirks. Ship no
code.

Cheapest, and it does capture the tribal knowledge. But it addresses none of the
drift: four workflow files still each carry their own copy of the token dance,
and the label vocabulary still diverges silently because prose does not compare
itself against a repository. It also grows the reference document past the scope
`ADR-0024` gave it. This is the option the framework has been taking by default
for three consumer repositories, and the evidence above is its result.

### Option B — Ship the mechanisms as Category 1 governance gates in `scripts/`

Place the executables in `scripts/`, register each as an npm script, document
each in `scripts/README.md`, and wire them into `.github/workflows/lint-docs.yml`
— the full `ADR-0015` Category 1 treatment.

Uniform with every other executable the framework ships, and the strongest
governance available. But it is a category error. A Category 1 gate answers *may
this change proceed?* and its answer is binding on a pull request. Provisioning
labels, initialising a submodule with a credential, and enumerating a project
board answer a different question — *is the substrate in the state the binding
describes?* — and two of the three cannot run in CI at all without an
administrative token the gate jobs deliberately do not hold. Forcing gate shape
onto a non-gate produces a job that is either permanently skipped or permanently
red, which is the failure mode `scripts/README.md` already catalogues four prior
instances of.

### Option C — Ship an executable layer as part of the binding, under `integrations/github/`

The binding becomes a directory rather than a file: the existing reference
document stays as the capability mapping, and an executable layer ships beside it
providing the mechanisms the mapping names. The executables are *binding
content*, governed by `ADR-0024` and by an approved FS, and they are not
classified under `ADR-0015`'s tool taxonomy at all.

Keeps the binding self-contained and keeps the reference document's scope intact.
Requires this ADR to draw two lines that do not exist yet — one against
`ADR-0007`, one against `ADR-0015` — and to defend both.

### Option D — A separate repository for GitHub tooling

Extract the executables into their own repository, versioned and consumed
independently.

Attractive for release cadence, and wrong on ownership. GitHub is this
framework's *own* substrate; `ADR-0024`'s driver was that "the framework's own
substrate should be documented, not hidden … as a binding, not as an
embarrassment." Splitting the binding across two repositories recreates the
framework/consumer boundary inside content that is unambiguously framework, and
guarantees the document and the code version apart.

## Decision Outcome

**Chosen option: Option C — an executable layer shipped as part of the GitHub
binding, under `integrations/github/`.**

`FS-0029` specifies the contents. This ADR records the four boundaries that
constrain it.

### 1. A binding may ship executables, and they are binding content

`ADR-0024` says a binding "maps each core capability onto a named mechanism." It
does not say the mapping must be prose. Where a mechanism can be *provided*
rather than merely *named*, the binding provides it.

The existing `integrations/github-issues-projects.md` remains the binding's
normative capability mapping and is not restructured. The executable layer lives
beneath it and is subordinate to it: an executable that disagrees with the
mapping is a defect in the executable.

### 2. The framework ships mechanisms; it never ships a trigger that mutates a work item

This is the `ADR-0007` line, drawn precisely.

`ADR-0007` chose "standards only, never orchestration," and the reference binding
already prints `gh project item-edit` invocations for a reader to run. Shipping a
tested script that runs the same command is a difference in packaging, not in
kind — a command a human or a consumer's automation invokes is a tool, not an
orchestrator.

What makes something an orchestrator is the loop. Therefore:

- The binding **may** ship one-shot, idempotent commands that a caller invokes.
- The binding **must not** ship any scheduler, daemon, watcher, or workflow
  `schedule:` trigger that mutates a governed work item. Consumers own their
  triggers. `ADR-0028` makes the reconciler the correctness guarantee; it does
  not make the reconciler the framework's to run.
- CI templates the binding ships **may** carry triggers, because gate workflows
  evaluate changes rather than mutate work items. A shipped template that
  mutates a work item on a schedule violates this rule regardless of how it is
  labelled.

A consequence worth stating rather than discovering: **the binding ships a
read-only board audit, not a board reconciler.** Reporting that a project item
carries no `Status`, or that an Issue is absent from the board, is enumeration —
capability 6, which GitHub provides natively. Setting the field is the
consumer's act, performed by the consumer's tick under the consumer's policy. The
audit is where the framework puts the GraphQL pacing discipline it learned, so
the knowledge is shipped and tested without the loop being shipped with it.

### 3. Binding executables are governed by `ADR-0024`, not classified under `ADR-0015`

`ADR-0015` classifies *tools* by how they are introduced and governed.
`ADR-0034` widened it with a fourth category and, in doing so, established the
right test: place a thing where its governance actually is, not where it
superficially resembles something else.

A binding executable's governance is already fully determined: it is exported
surface, it requires an approved FS to introduce (this one), it is versioned with
the framework, and it is subordinate to the binding document. Adding a fifth
taxonomy category would restate what `ADR-0024` already provides.

The boundary is a bright line, and it is testable:

| The executable… | Lives in | Governed as |
| --- | --- | --- |
| …can fail a pull request | `scripts/` | Category 1 gate (`ADR-0015`) |
| …provisions, inspects, or reports on a platform substrate | `integrations/<binding>/` | Binding content (`ADR-0024`) |

An executable that starts failing pull requests has become a gate and must move
to `scripts/` and acquire a Category 1 entry. This is the rule, not a
recommendation: the reason gates live in one directory is so that a reader
auditing what can block a merge has one place to look.

Binding executables are nonetheless registered as npm scripts and cross-
referenced from `scripts/README.md`, because a reader looking for *every*
executable the framework ships should find them from the place that catalogues
executables. Discoverability and classification are different problems.

### 4. Authentication is a dual regime, designed in from the start

The submodule-initialisation mechanism resolves the framework repository's
visibility and behaves accordingly:

- **Public** — no credential is used, and none is required. A missing token is
  not a warning.
- **Private** — the credential is required. A missing or unusable credential is
  a hard failure.

The second half is the important one, and it restates a rule this repository
already holds: **a step that disables itself when its dependency is missing is
the fail-open shape `FS-0024` was written to remove.** A submodule init that
silently proceeds without the framework checked out yields a gate run against a
repository whose governance documents are not present — green, and meaningless.
Red is the honest state.

This is not future-proofing for a hypothetical. This repository's transition to
public is planned, and on that day the correct behaviour of every consumer's CI
changes. Designing the mechanism to read visibility rather than to assume it
means the transition is a fact the code observes, not four files someone
remembers to edit.

### 5. No neutral-core generalisation, by rule

`ADR-0024`'s ordering rule binds here: "The core generalizes over shipped
bindings; it never forecasts them," and "no core capability may be added that no
existing binding implements."

One binding now has an executable layer. That is one data point. `FS-0029`
therefore adds **nothing** to the six capabilities in `integrations/README.md`,
and states no requirement that a conforming binding ship executables. A binding
that is a document alone remains fully conforming. If a second platform binding
later ships its own executable layer, the generalisation may be extracted then —
from two working implementations, which is what the ordering rule is for.

### 6. Enforcement honesty carries into the tooling layer

`integrations/github-issues-projects.md` §7 states, per capability, what GitHub
does not guarantee. The executable layer inherits that obligation and extends
it: its own documentation states, per command, whether the command **enforces** a
property, **provisions** it once, or merely **reports** a divergence.

The distinction is not decorative. A label-provisioning command makes the
vocabulary correct at the moment it runs and guarantees nothing about the moment
after. Presenting it as enforcement would be the same overclaim §7 exists to
prevent, and would be worse for being executable — a passing command reads as
proof in a way a checked checklist does not.

### 7. Instance data stays out

`ADR-0032` holds without exception. The binding ships parameterised templates and
`*.example.yml` shapes. Project numbers, node IDs, field option IDs, organisation
names, token secret names, and organisation-specific label additions are supplied
by the caller — as arguments, environment, or a configuration file resolved from
the *caller's* repository root, never from inside a vendored tree. This is the
same resolution rule `FS-0024`/`ADR-0033` established for governance gates, and
it applies here for the same reason.

## Consequences

### Positive

- The `Setup Checklist` becomes runnable and re-runnable. Provisioning stops
  being a one-time act performed from memory and becomes a state that can be
  re-asserted and audited.
- Four duplicated copies of the submodule-initialisation step collapse to one
  tested implementation, and the `--global` requirement stops being folklore.
- The GraphQL secondary-rate-limit discipline acquires a home in the exported
  surface, tested, instead of living in session transcripts.
- Label drift becomes detectable. The divergence that went unnoticed across three
  repositories is exactly what an audit command reports.
- The public transition becomes a behaviour the code observes rather than a
  migration someone must remember to perform across consumer repositories.
- The framework's dogfooding claim strengthens: it will run the binding it ships,
  on itself, in CI.

### Negative

- The exported surface grows, and with it the maintenance obligation. Shipped
  shell that calls `gh` is coupled to a CLI the framework does not control, and
  `gh` has already demonstrated it breaks compatibility — `gh pr edit --body`
  currently fails on a GraphQL deprecation, and `gh project item-edit` takes node
  IDs rather than the field-name flags a reader would reach for first. Every such
  breakage now lands on the framework rather than on whoever hit it.
- Two new boundaries must be maintained by reviewers, not by tooling: the
  gate-versus-mechanism placement rule (§3) and the no-trigger rule (§2). Both
  are conventions backed by review. `scripts/README.md` already carries a table
  of five such rules and the reason each is unenforced; these join it.
- Testing shell that calls a network API is genuinely hard. The bats suites will
  exercise argument handling, visibility resolution, idempotency logic, and
  failure modes against fixtures — not GitHub. The commands' behaviour against
  the live API is verified by using them, which is a weaker guarantee than the
  rest of the corpus enjoys, and `FS-0029` says so rather than implying
  otherwise.
- A consumer may reasonably read the executable layer as an endorsement to
  automate more than `ADR-0007` permits. §2's line is the mitigation, and it will
  need restating.

### Neutral

- `integrations/` becomes a directory of directories rather than a directory of
  files. `npm run lint:integrations` currently globs `integrations/*.md` and must
  widen; `check-status.sh` rule 8 already treats `integrations/` as
  current-state, so referenced paths beneath it are checked once they exist.
- The reference binding document is unchanged in scope and substance. It gains
  cross-references to the executable layer and nothing else.
- The consumer maintenance tick keeps its policy — which repositories, which
  caps, which cadence — and may adopt the binding's shared helpers for pacing and
  authentication. That adoption is the consumer's decision, not a requirement
  this ADR imposes.

## Validation

This decision is correct if, twelve months on:

- **The duplication stayed collapsed.** No consumer repository has reintroduced
  an inline copy of the submodule-initialisation step. A reintroduction means the
  shipped mechanism was harder to use than copying, and the packaging is wrong.
- **Label drift was caught by the audit rather than by a person.** The concrete
  test: the next divergence is reported by a command, not noticed during an
  unrelated investigation, which is how the current one surfaced.
- **The public transition required no consumer edits to authentication.** If
  consumers had to change their workflows on flip day, §4 failed and the regime
  was assumed rather than resolved.
- **No shipped executable acquired a scheduler.** A `schedule:` trigger mutating
  a work item anywhere under `integrations/` means §2's line did not hold, and
  `ADR-0007` needs revisiting explicitly rather than by drift.
- **No binding executable started failing pull requests from `integrations/`.**
  If one did and stayed there, §3's bright line is decorative.
- **The core stayed at six capabilities.** A seventh capability about executable
  mechanisms, extracted from a single binding, would be exactly the forecasting
  `ADR-0024`'s ordering rule forbids.

The falsifying outcome is a directory of scripts nobody runs — the `packs/`
failure mode, relocated. The early signal is the framework's own CI: if the
framework does not use its own binding within the implementing change, no
consumer will either.

## Links

- `integrations/README.md` — the six capabilities and the binding registry; this
  ADR adds a binding *layer*, not a capability.
- `integrations/github-issues-projects.md` — the reference binding this layer
  makes executable; remains normative for the capability mapping.
- `scripts/README.md` — the Category 1 gate contract; gains the cross-reference
  establishing where binding executables live and why they are not gates.
- `workflows/git-and-gh-conventions.md` — the current-state document carrying
  git and `gh` conventions; the `gh` behaviours this layer works around belong
  in its record.
- ADR-0024 — platform-neutral core with shipped bindings; the constitutional
  basis and the ordering rule constraining §5.
- ADR-0007 — standards only, never orchestration; the constraint §2 draws
  against.
- ADR-0015 / ADR-0034 — the tool taxonomy and the precedent for placing a tool
  by its governance rather than its resemblance; §3 declines to extend it.
- ADR-0028 — level-triggered reconciliation; why the reconciler is the
  correctness guarantee and why it is nonetheless not the framework's to run.
- ADR-0032 — template and instance repository forms; the instance-data rule §7
  applies.
- ADR-0033 / FS-0024 — governance gate target resolution; the caller-relative
  resolution rule §7 reuses.
- ADR-0012 — the merge gate and the `gh auth status` verification requirement
  every shipped command inherits.
- FS-0018 — the work-item lifecycle and the label vocabulary the provisioning
  command asserts.
- FS-0029 — the governing spec for this decision.
