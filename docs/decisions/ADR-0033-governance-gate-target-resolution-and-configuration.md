---
type: adr
id: ADR-0033
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0024
superseded_by: null
---

# ADR-0033: Governance gate target resolution and configuration

## Status

- Proposed

## Context and Problem Statement

`scripts/check-status.sh` and `scripts/run-bats.sh` resolve the repository they check
with `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` — the directory containing the
running script, one level up. That is correct for exactly one caller: this repository
checking itself. It is wrong for every other caller, silently.

A host repository vendors this framework as a git submodule at
`vendor/conventional-agents/`. When it runs
`bash vendor/conventional-agents/scripts/check-status.sh` from its own root, `$0` is a
path *into the submodule*, so `dirname "$0"/..` resolves to the submodule's root —
this framework's own vendored copy — not the host's. The script then validates the
framework's own `docs/specifications/`, `docs/change-plans/`, and `docs/decisions/`,
reports them clean (they are), and exits zero, having examined nothing that belongs to
the repository that invoked it.

`scripts/check-current-state.sh` does not share this defect. It resolves
`REPO_ROOT=$(git rev-parse --show-toplevel)` — the git repository containing the
current working directory, discovered by walking up from wherever the caller stands.
Run from a host repository's root, that call returns the host's root, because the host
root is where the caller's `.git` lives; the submodule boundary is never crossed
because nothing `cd`s into it. This script gets it right, not by design against this
problem — its author needed the change set for a diff-based check and reached for `git
rev-parse` for that reason — but the effect is the fix the other two scripts need.

**Demonstrated, not merely reasoned.** A scratch repository containing a deliberately
broken `FS-9001` — `status: implemented`, no governing PLAN, no README index row — was
initialized with this repository linked at `vendor/conventional-agents`. Running
`bash vendor/conventional-agents/scripts/check-status.sh` from the scratch repository's
own root reported `All status checks passed.` The defect is not hypothetical.

**A live instance exists.** `feral-fleet` vendors this framework, completed its
v2.1.0 migration, and runs `markdownlint` in CI. It vendors all three scripts and runs
none of them meaningfully — `check-status.sh` would check the framework's own docs,
not `feral-fleet`'s, if invoked. A status-pairing violation — `PLAN-0018` at
`implemented` while its primary spec `FS-0016` remains `draft` — currently sits on
`feral-fleet`'s trunk, undetected, because nothing capable of detecting it has ever
looked at the right repository.

Fixing the resolution mechanism is necessary but not sufficient. Two of the values
these scripts check against are this repository's own structural facts, hardcoded:
`RESERVED_PATHS` names `guidelines/ROLE_CONTRACT.md`, `scripts/`, and `package.json` —
paths that are true of *this* repository because of how *this* repository happens to
be built, not because any consumer's repository shares that structure. A consumer
whose own governing role contract lives at `roles/ROLE_CONTRACT.md`, who has no
`package.json` at all, or whose CI lives outside `.github/workflows/`, is not served by
inheriting this repository's list — and silently applying it, or silently applying
nothing, both fail in the direction `CONTRIBUTING.md` §"Changing a Governance Gate"
warns is the one that matters: **permissive**. A gate that reports success while
checking the wrong thing, or while checking nothing, is indistinguishable from a
working gate and stays broken for months. Four such defects already have, in this
repository's own history, each passing its own test suite.

The question this ADR answers: **how does a vendored governance gate learn which
repository to check, and what does it do when the values it needs are not this
repository's to assume?**

## Decision Drivers

- **The framework's own invocations must not break.** `npm run check:status`, the
  `check-status`, `current-state-update`, and `test-bats` CI jobs, and every bats suite
  that invokes a script directly must behave exactly as they do today. A portability
  fix that breaks the framework checking itself has traded one outage for another.
- **A consumer must be able to run the same script against their own repository with
  no source edit.** Vendoring is read-only in practice — a consumer who has to patch a
  vendored script to make it work has not been given a portable tool.
- **Silent misconfiguration must fail loudly, not permissively.** The demonstrated
  pattern in this repository's own gates is checks that pass while enforcing nothing.
  A gate lacking the configuration it needs to evaluate a safety-relevant rule must say
  so and refuse, not default to "nothing is reserved."
- **Not every check carries the same stakes.** A gate that blocks an unsafe
  self-approval and a gate that reminds someone to write a changelog entry warrant
  different behavior when unconfigured. Treating them identically is either too harsh
  on the low-stakes case or too permissive on the high-stakes one.
- **Consumer-specific values must not live inside the vendored tree.** `ADR-0032`:
  a template repository carries no instance data. A consumer's reserved paths and
  exported-surface list are facts about their repository, not this one.

## Considered Options

### Option A — Positional argument for target repository

Every script accepts a repository-root argument: `check-status.sh /path/to/host`.
Explicit and simple to trace.

Breaks every existing invocation on day one. `npm run check:status`,
`.github/workflows/lint-docs.yml`'s three jobs, and every bats suite that calls a
script by absolute path all currently invoke with zero arguments, relying on the
default resolving correctly. Making the argument required breaks all of them; making
it optional reintroduces the question this ADR exists to answer — optional and
defaulting to what?

### Option B — Required environment variable

A caller must set `CA_TARGET_REPO` before running any of the three scripts. No
default; absence is an error.

Solves nothing for the framework's own invocations, which would all need to set the
variable to keep working — the same breakage as Option A, relocated from an argument to
an environment variable.

### Option C — Working-directory resolution via `git rev-parse --show-toplevel`, with an optional override

The default target is the git repository containing the caller's current working
directory — `check-current-state.sh`'s existing, already-correct mechanism, applied to
the other two scripts. An optional `CA_TARGET_REPO` environment variable overrides it
for a caller whose working directory is not inside the repository they mean to check.

### Option D — Auto-detect by walking up from the script's own path, preferring a `vendor/` ancestor

Inspect `$0`; if any path component is `vendor/conventional-agents`, target the
directory above it. Otherwise target the script's own directory, as today.

Handles the one shape of vendoring this repository uses, and silently mistargets any
consumer who vendors under a different path, symlinks the submodule, or vendors this
framework a second layer down (a template-form consumer, vendored in turn by their own
downstream). A convention that works only for one directory name is not a convention.

## Decision Outcome

**Chosen option: Option C — working-directory resolution via `git rev-parse
--show-toplevel`, with an optional `CA_TARGET_REPO` override.**

### Target resolution

`REPO_ROOT` in `check-status.sh` and `run-bats.sh` changes from
`$(cd "$(dirname "$0")/.." && pwd)` to:

```text
REPO_ROOT="${CA_TARGET_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
```

`check-current-state.sh` gains the same `CA_TARGET_REPO` override ahead of its
existing call, for one reason: a caller should not need to know that one of the three
scripts already happened to resolve correctly and therefore doesn't honor the override
the other two do. All three scripts answer "which repository am I checking" the same
way.

This is not a new interface. It is the mechanism `check-current-state.sh` already
uses, applied to the two scripts that lack it. Every invocation enumerated in the
Context section resolves identically before and after this change, because in every
one of them the caller's working directory already **is** the repository being
checked — `npm` runs with CWD at the directory containing `package.json`; CI's
`actions/checkout` places the workspace there; a bats suite that invokes a script by
absolute path does so without changing directory, inheriting the framework root its
own harness already resolved. Nothing about *how* those callers invoke the scripts
needs to change; only what the scripts do with an unspecified target changes, and it
changes to agree with what those callers were already relying on being true.

A consumer running `bash vendor/conventional-agents/scripts/check-status.sh` from
their own repository root now resolves `REPO_ROOT` to that root — `git rev-parse
--show-toplevel` walks up from the caller's working directory to find its nearest
`.git`, which is the host's, because the host's working directory never crosses into
the submodule. Run from a subdirectory of the host repository, the result is the
same, for the same reason — the resolution is repository-relative, not
working-directory-relative.

### Self-check detection

The scripts distinguish two callers: this repository checking itself, and a vendored
copy checking a host. The distinction is computed, not declared:

```text
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
# REPO_ROOT as above
```

When `REPO_ROOT` equals `FRAMEWORK_HOME`, the script is checking the repository it
physically lives in — this repository, running against itself, in every invocation
shape enumerated above. When they differ, the script is a vendored copy checking
something else.

This reuses the old (broken-as-a-target-resolver, correct-as-a-self-locator)
computation for exactly what it is good at: finding where the script itself lives.
That was never the wrong computation — it was the wrong one to use as the answer to
"what do I check."

### Universal versus per-repository values

Inspected directly, the hardcoded values in these scripts fall into two kinds.

**Universal — true of any repository adopting this framework's document lifecycle,
unchanged:**

- `FS_DIR`, `PLAN_DIR`, `ADR_DIR` (`docs/specifications`, `docs/change-plans`,
  `docs/decisions`). These are the paths `templates/core/feature-spec.md` and
  `templates/core/change-plan.md` instruct an adopter to use, and the paths
  `workflows/document-lifecycle.md` documents. A consumer who has renamed them has
  departed from the exported convention, not exercised a supported option.
- `REQUIRED_ADR_SECTIONS`. These come from the MADR structure `docs/decisions/README.md`
  adopts as the baseline (`ADR-0000`), which every consumer inherits by using the same
  ADR template. Not this repository's preference; the upstream standard's.
- `CURRENT_STATE_RE` in `check-current-state.sh` (`workflows|guidelines|skills|
  templates|integrations|runbooks`). These are the framework's own exported-surface
  directory names, which a consumer following the convention reproduces verbatim. Left
  as a fixed default by this ADR — see Non-Goals.

**Per-repository — true of this repository because of how this repository happens to
be built, not portable as a fixed value:**

- `RESERVED_PATHS`. `guidelines/ROLE_CONTRACT.md` is this repository's own template
  role contract; a consumer's governing contract lives at `roles/ROLE_CONTRACT.md` per
  `roles/README.md`. `package.json` presumes an npm-based consumer, which is common but
  not universal. `.github/workflows/` presumes GitHub Actions specifically.
- `EXPORTED_PREFIXES`. Whether a consumer has an exported surface at all depends on
  `ADR-0032`'s form: an instance-form repository, by that ADR's own definition, has
  none. A template-form consumer's exported directory names are theirs to name, not
  this repository's to assume are identical.
- `REF_EXEMPT`. Three entries, each naming a specific sentence in a specific document
  in this repository. No consumer has this repository's documents.

### Configuration lives outside the vendored tree

Per `ADR-0032`, a template repository carries no instance data, and a consumer's
reserved paths and exported surface are exactly that: facts that would have to change
for a second adopter's copy to be correct, which is the ADR's own test. They cannot
ship as fixed values inside `scripts/`.

The framework ships `config/gates.example.yml` — a documented, empty-by-default
structure, carrying the same "THIS IS A CONSUMER-COPY TEMPLATE, NOT FRAMEWORK
CONFIGURATION" header `config/consensus.yml` and `config/review-board.yml` already use.
A consumer copies it to `config/gates.yml` **in their own repository root**, outside
`vendor/conventional-agents/`, and fills in their own values. The vendored scripts read
`$REPO_ROOT/config/gates.yml` — never a path inside the submodule.

This repository does not create `config/gates.yml` for itself. `RESERVED_PATHS` and
`EXPORTED_PREFIXES` remain hardcoded exactly as they are today, used precisely when
`REPO_ROOT` equals `FRAMEWORK_HOME` — this repository checking itself, the case that
must keep working unchanged. Creating a real `config/gates.yml` at this repository's
own root, populated with this repository's own values, would itself be instance data
inside a template repository by `ADR-0032`'s test; the self-check path exists so that
this repository need not do that.

### Fail closed where it matters; skip explicitly where it does not

When `REPO_ROOT` differs from `FRAMEWORK_HOME` — the vendored case — and
`config/gates.yml` is absent or a needed field is unset, the two configuration-dependent
checks do not behave the same way, because they do not carry the same stakes.

**`RESERVED_PATHS` gates PLAN self-approval (`ADR-0027`).** Getting this wrong in the
permissive direction lets an agent self-approve a change to whatever the missing
configuration should have protected — the exact hazard `ADR-0019` names one layer down
and `ADR-0027` names at this one. So absence is treated as *not yet safe to certify*:
the check reports that `reserved_paths` is unset in `config/gates.yml` and refuses to
certify any PLAN as self-approved, exiting non-zero, until it is configured. This is a
deliberate departure from convenience in favor of the direction `CONTRIBUTING.md`
requires: a gate that cannot tell whether a path is reserved must not report as though
it had checked.

**`EXPORTED_PREFIXES` gates the consumer-impact CHANGELOG reminder.** Getting this
wrong costs a missed documentation courtesy, not a safety violation, and an
instance-form repository (`ADR-0032`) — `feral-fleet`, the concrete case this ADR was
asked to reason against — correctly has no exported surface at all. So absence, or an
explicit empty list, is treated as *this repository asserts it has nothing to declare*:
the check reports that rule 7 does not apply and skips it, visibly, exiting zero. A
skip and a pass must not look the same in the output — the message names which one
occurred.

`REF_EXEMPT` needs neither treatment. An absent or empty list simply grants no
exemptions, which is what it does today when no consumer-specific exemption has been
added; nothing about it is safety-relevant enough to warrant refusing to run.

## Non-Goals

- **Reconciling `CURRENT_STATE_RE`'s directory set with the referenced-path check's
  directory set.** `scripts/README.md` documents rule 8 (referenced-path resolution,
  in `check-status.sh`) as covering `guidelines/`, `roles/`, `skills/`, `templates/`,
  `workflows/`, `integrations/`, `runbooks/`, and `scripts/` — eight categories.
  `check-current-state.sh`'s `CURRENT_STATE_RE` covers six: it omits `roles/` and
  `scripts/`. This is a real inconsistency, distinct from the one this ADR resolves —
  it is about which directories count as "current-state" for ADR-Links checking,
  not about which repository a script checks — and it is already recorded as a
  finding on the open PR relocating `config/project.yml`. Folding it in here would
  make one PLAN responsible for two independently-scoped defects. Left for separate
  work.
- **Making `CURRENT_STATE_RE` per-repository configurable.** It is classified
  universal above, and left as a fixed default in `check-current-state.sh` for the
  reason given there — it names this framework's own exported-surface directories,
  which a consumer inherits by using the same convention. If a consumer's document
  lifecycle grows current-state families this framework does not have, extending it
  is future work, not required by the defect this ADR fixes.
- **Fixing `feral-fleet`.** Its undetected status-pairing violation is evidence this
  defect is real, not a repository this ADR or its governing FS commits to correcting.

## Consequences

### Positive

- A vendored gate checks the repository that invoked it, without the caller doing
  anything differently than they do today.
- The framework's own invocations — `npm run check:status`, three CI jobs, every bats
  suite that calls a script directly — are unchanged in behavior, verified by the fact
  that each one's working directory already resolves to the repository it needs to
  check.
- A safety-relevant check that lacks the configuration it needs says so and refuses,
  rather than silently certifying nothing as reserved — closing off a fifth instance
  of the fail-open pattern `CONTRIBUTING.md` already catalogues four of.
- A low-stakes check that lacks configuration says so and skips, rather than either
  refusing to run (which would make every instance-form consumer's gates permanently
  red) or silently passing (which would be indistinguishable from having checked and
  found nothing wrong).
- No consumer-specific value is committed inside the vendored tree; `ADR-0032` holds.

### Negative

- A consumer must create `config/gates.yml` before self-approval routing will certify
  anything. For a consumer with no PLANs yet approaching self-approval, this is
  invisible; for one relying on it from day one, it is a new required step with no
  default that "just works."
- Two ways of being unconfigured now exist — refuse, or skip — and a maintainer
  extending these scripts with a new per-repository value must decide which one a new
  check needs, rather than having a single existing pattern to copy without thinking
  about it.
- `FRAMEWORK_HOME` versus `REPO_ROOT` is one more piece of state to reason about when
  reading these scripts, for a distinction — "is this the framework checking itself" —
  that did not need to exist before vendoring was expected to work.

### Neutral

- `check-current-state.sh`'s default behavior does not change; only its acceptance of
  an override is new; and this ADR does not attribute the original problem to it.
- The self-check comparison is exact-path equality, not a marker file or a
  `package.json` name check. Either script relocated relative to the other — a
  consumer who moves `vendor/conventional-agents` to a non-standard path but somehow
  runs the script with a working directory equal to the framework's own root, or a
  local development checkout at a path also named `conventional-agents` for unrelated
  reasons — is a contrived case this ADR does not construct defenses against.

## Validation

- **Signal:** `bash vendor/conventional-agents/scripts/check-status.sh`, run from a
  host repository's root against a host repository whose FS/PLAN state is
  deliberately broken, reports the break. This is the scratch-repository
  reproduction in Context, re-run after implementation with the opposite expected
  result.
- **Signal:** `npm run check:status`, the three CI jobs in `lint-docs.yml`, and the
  full bats suite all pass on this repository's own trunk with no invocation syntax
  changed.
- **Signal:** a vendored `check-status.sh` run against a host repository with no
  `config/gates.yml` present exits non-zero, and its output names `reserved_paths` as
  unconfigured, for any PLAN it would otherwise evaluate for self-approval.
- **Signal:** the same run reports rule 7 (consumer-impact CHANGELOG) as skipped, not
  passed, and exits zero if that is the only outstanding condition.
- **Review checkpoint:** the first consumer repository that creates a
  `config/gates.yml` and reports back whether the schema was sufficient for their
  structure.
- **Failure condition:** if a consumer's legitimate reserved-path or exported-surface
  need cannot be expressed in the shipped schema, the schema is under-specified and
  this ADR's Decision Outcome — not merely the file — needs revisiting.

## Links

- `ADR-0012`: Non-overridable gates — the merge gate this ADR does not touch.
- `ADR-0019`: Issue Type immutability and the autonomous gate — the "an agent must not
  lower its own gate" principle this ADR applies to unconfigured self-approval routing.
- `ADR-0024`: Platform-neutral core with shipped bindings — detection over prevention,
  the same posture this ADR takes toward `Approved-By:`-adjacent self-approval
  certification: audited and refusable, not cryptographically enforced.
- `ADR-0027`: PLAN self-approval within declared interfaces — defines `RESERVED_PATHS`
  and the hazard this ADR's fail-closed behavior protects.
- `ADR-0030`: Decision records versus current-state documents — `scripts/README.md` is
  the current-state document this ADR's acceptance must update, in the same change,
  per rule 3.
- `ADR-0032`: Template and instance repository forms — the rule `config/gates.example.yml`
  and its consumer-owned counterpart apply; the source of the instance-form reasoning
  behind the `EXPORTED_PREFIXES` skip behavior.
- `CONTRIBUTING.md` §"Changing a Governance Gate" — the standard this ADR's Validation
  section and its governing FS's tests are held to: break the thing the gate protects,
  confirm the gate notices.
- `FS-0022`: Gate coverage — introduced `RESERVED_PATHS`, `EXPORTED_PREFIXES`,
  `REF_EXEMPT`, and `scripts/README.md`, all of which this ADR revises the portability
  of without changing what any of them enforce.
- FS-0024: Portable governance gates — the governing spec this ADR requires, per
  `docs/decisions/README.md` §1a: this ADR implies code, and code requires an approved
  FS and PLAN before it is written (`ADR-0015`).
- `scripts/README.md`: the current-state document this ADR's acceptance updates.
