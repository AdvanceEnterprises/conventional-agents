---
type: adr
id: ADR-0032
status: accepted
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0032: Template and instance repository forms

## Status

- Accepted

## Context and Problem Statement

A repository that adopts this framework holds two kinds of content, and confusing them
is expensive in ways that only become visible later.

**Template content** is reusable. Roles, playbooks, scripts, contracts, guidelines,
scaffolds — anything a second adopter could take unchanged.

**Instance content** describes one deployment. Hostnames, IP addresses, secrets,
project and board identifiers, absolute filesystem paths, real service definitions, the
inventory of what is actually running.

Nothing in this framework currently says these are different, and the omission has a
consistent failure direction: **instance data accumulates inside template repositories**,
never the reverse. It arrives one file at a time, each addition locally reasonable, and
the repository quietly stops being reusable without anyone deciding that it should.

The cost surfaces in three places, none of them at the moment the data is added:

1. **A second instance becomes impossible without a fork.** The template is entangled
   with one deployment's facts.
2. **The repository cannot be shared or published.** A framework carrying a private
   board identifier cannot go public; a repository carrying encrypted secrets and real
   management IPs cannot be shared at all.
3. **Agents cannot be gated differently on the two.** Editing a role changes every
   future run. Editing a live inventory changes a running system *now*. `ADR-0027`'s
   reserved-path set distinguishes neither — it has no concept of "this file describes
   something currently in production."

The third is the framework-relevant one. The first two are consequences an operator
notices; the third is a gap in what this framework claims to govern.

This is not hypothetical. It is the shape of a defect already recorded in `BACKLOG.md`:
this repository's own `config/project.yml` hardcodes one organization's project number,
board URL, and every field identifier — inside the artifact consumers vendor.

## Decision Drivers

- Reusability should be a property a repository either has or does not, not one that
  erodes silently.
- The distinction must be decidable by inspection, not by knowing the author's intent.
- It must not require restructuring repositories that have only one instance and may
  never have two. Speculative generality is its own failure.
- It must be stated where a consumer will encounter it before they have accumulated the
  problem.

## Considered Options

### Option A — Say nothing; treat it as ordinary hygiene

Status quo. Each repository decides for itself, and the framework has no opinion.

Cheap, and wrong for a framework whose subject is making agent work auditable. The
failure is silent and one-directional, which is exactly the class this framework exists
to make visible. It also leaves the `ADR-0027` gap unaddressed.

### Option B — Require every repository to separate template from instance

A repository must physically separate the two — different directories, or different
repositories.

Correct in the limit and wrong in practice. It imposes the cost of a split on
repositories that have exactly one instance and may never have a second. Extracting a
reusable form before a second consumer exists means guessing at what generalizes, which
is how a specification comes to describe an imagined system rather than a real one.

### Option C — Declare a form per repository; forbid mixing; defer extraction

Each repository is **one form or the other**, declared. A template repository carries no
instance data. An instance repository owes no one a template, and may hardcode freely.

Extraction of a template *from* an instance is a later decision, made when a second
instance actually exists — not a standing obligation.

### Option D — Option C, plus a naming convention that makes instance data visible

Option C, plus: template repositories name placeholder-bearing files with the
placeholder in the filename, so instance data cannot be added without visibly changing
the file's name.

## Decision Outcome

**Chosen: Option D.**

### The rule

> **A template repository carries no instance data. An instance repository owes no one a
> template.**

Both halves are load-bearing. The first is the constraint; the second is the permission
that makes the first affordable. Without it, every repository inherits an obligation to
generalize, and Option B's cost returns by the back door.

### Declaring a form

A repository declares its form in its `README.md`. A repository that cannot state which
form it is has not yet made the decision, and that is the finding.

### The test

For any file, ask: **would a second adopter's copy have to change it?**

| Answer | Form | Examples |
| --- | --- | --- |
| Yes | instance | hostnames, IPs, secrets, board and project identifiers, absolute paths, real service and host definitions, records of what is actually deployed |
| No | template | roles, playbooks, scripts, contracts, guidelines, scaffolds, examples, tests |

The test is about the *file*, not the repository. A template repository failing the test
on any file has instance data to relocate.

### The naming convention

In a template repository, a file that will be copied and filled in names its
placeholders **in the filename**, in caps:

```text
ops/quadlet/APP_NAME-ENV-app.container
ops/env/prod.env.example
services/examples/single-container.yml
```

The convention is doing real work: `APP_NAME-ENV-app.container` cannot be mistaken for a
real service definition, and a reviewer does not need to open it to know. Instance data
cannot be added to such a file without renaming it, which is a visible act.

### Where relocated instance data goes

When a template repository is found to hold instance data, it moves to the adopting
organization's own repository — the consumer-conventions repository `ADR-0016`
describes. The template repository keeps a `*.example` form documenting the structure
with placeholder values.

### What this does not decide

This ADR does not classify any particular repository. Those classifications are instance
data about one organization's repositories, and recording them here would violate the
rule this ADR states. They belong in the adopting organization's own conventions
repository.

## Consequences

### Positive

- Reusability becomes a declared property rather than an eroding one.
- The decidability test is mechanical, so it can become a check later without
  renegotiating the rule.
- Instance repositories are explicitly licensed to hardcode. That is a real
  simplification, not a concession — it removes the standing pressure to generalize
  prematurely.
- It gives `ADR-0027` a concept it lacks. A future revision can reserve instance-bearing
  paths on the grounds that they describe running systems, and this ADR supplies the
  definition that would rest on.

### Negative

- Extraction cost is deferred, not removed. An instance repository that later needs a
  template pays then, at whatever size it has grown to.
- The cost is bounded by how modular the underlying format already is — Ansible roles
  and shell scripts extract cheaply; a monolithic configuration does not. The framework
  does not mitigate this and should not pretend to.
- "One form per repository" is a simplification. A repository genuinely holding both
  must split or accept being classified as an instance, and the second is usually the
  honest answer.

### Neutral

- No existing repository is required to change. The rule binds when a form is declared
  and when instance data is found in a declared template.
- This is a convention, enforced by review rather than tooling. Per
  `docs/decisions/README.md` §1a it therefore requires no governing feature spec: it
  obliges nobody to write code, and is discharged by updating the current-state document
  that carries it. Extending `ADR-0027`'s reserved paths to instance-bearing files would
  be code, and needs its own spec.

## Validation

- **Signal:** every repository adopting this framework states its form in `README.md`.
  Checkable by inspection.
- **Signal:** no repository declared as a template contains a hostname, IP address,
  secret, board identifier, or absolute filesystem path outside a file whose name marks
  it as an example or placeholder.
- **Signal:** when a template repository is found holding instance data, the fix
  relocates the data rather than declaring the repository an instance. The reverse
  indicates the rule is being used to justify what it was written to prevent.
- **Review checkpoint:** the first time a second instance of an existing instance
  repository is needed. The extraction cost incurred then is the measurable price of
  this decision, and should be recorded against Option B's avoided cost.
- **Failure condition:** if instance data continues accumulating in template
  repositories after this is accepted, the convention is insufficient and needs the
  enforcement that `ADR-0027`'s reserved-path mechanism could provide.

## Links

- `ADR-0016` — consumer conventions; the destination for relocated instance data.
- `ADR-0017` — framework-internal vendor boundary; a related containment rule.
- `ADR-0024` — platform-neutral core with shipped bindings; the same separation applied
  to substrates rather than repositories.
- `ADR-0027` — PLAN self-approval within declared interfaces; the reserved-path set this
  ADR gives a missing concept to.
- `ADR-0030` — decision records versus current-state documents; why the rule is carried
  by `INTEGRATION.md` and not by this ADR alone.
- `INTEGRATION.md` §"Template and instance repositories" — the current-state document
  carrying this rule.
