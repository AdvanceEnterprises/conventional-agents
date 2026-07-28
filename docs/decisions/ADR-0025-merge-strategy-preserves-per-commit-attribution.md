---
type: adr
id: ADR-0025
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0003
  - FS-0017
superseded_by: null
---

# ADR-0025: Merge strategy preserves per-commit attribution

## Status

- Proposed

## Context and Problem Statement

`workflows/git-and-gh-conventions.md` sets squash-merge as the default merge strategy,
in its Defaults section and again in step 8 of the standard workflow. That default
predates agent attribution and was chosen for the usual reason: a clean, linear trunk
history with one commit per unit of work.

`ADR-0018`, as amended by `ADR-0029`, makes per-commit `Agent-Attribution:` trailers the
authoritative record of which actor, model, and role produced each change. `FS-0017`
implemented that convention and `test/FS-0017/commit-attribution.bats` verifies it.

Squash-merge collapses every commit on a branch into one. Whatever the squashed message
contains, the other commits' trailers are gone from trunk. A branch carrying twelve
commits — twelve documents, twelve distinct role and model attributions — arrives on
trunk as one commit with at most one trailer set.

The conflict is invisible at small scale and severe at large scale. A three-commit
feature branch authored by one agent in one role loses little. A bootstrap branch
carrying dozens of documents authored across sessions, roles, and models loses almost
everything the attribution convention exists to record. The framework would be
squash-merging away the audit trail it accepted an ADR to create, in exactly the PR
where that trail is most informative.

Both conventions are accepted. Neither yields to the other by precedence, since they
sit at the same level and address different concerns. This requires a decision rather
than an interpretation.

## Decision Drivers

- **Attribution is the point.** The framework's central claim is that agent work is
  auditable. A merge strategy that discards attribution falsifies the claim.
- **Linear history has real value.** `git bisect`, `git log --first-parent`, and casual
  reading all benefit from it, and it is why squash was chosen originally.
- **The rule must scale with commit count.** A strategy that is fine for three commits
  and destructive for thirty needs to say which case it is addressing.
- **Escape hatches must not silently lose data.** If squash remains available, using it
  must not quietly discard trailers.

## Considered Options

### Option A — Keep squash-merge as default

Cleanest trunk history, one commit per PR, trivially bisectable. Discards per-commit
attribution on every multi-commit branch. Rejected: it makes `FS-0017`'s convention
decorative on trunk, where it matters most.

### Option B — Merge commits as default

Preserves every commit and every trailer exactly. Produces a non-linear history with a
merge commit per PR, which makes `git log` noisier and `git bisect` traverse branch
commits that were never independently tested against trunk.

### Option C — Rebase-merge as default

Replays each branch commit onto trunk individually. Preserves every commit message and
therefore every trailer, and keeps history linear — the two properties in tension under
Options A and B.

Rewrites commit SHAs and committer dates. Author identity and message body, which carry
the attribution, are preserved. Cannot proceed automatically when the branch conflicts
with trunk.

### Option D — Per-PR judgment, no default

Maximum flexibility, no guarantee. The failure mode is that the convenient option gets
chosen under time pressure, which is the option that loses data.

## Decision Outcome

**Chosen option: Option C — rebase-merge as the default.**

### The rule

1. **Default: rebase-merge.** Every commit lands on trunk individually, preserving its
   author, message, and trailers, and trunk history stays linear.
2. **Merge commit when rebase is blocked.** If the branch conflicts with trunk and
   resolving through rebase is impractical, a merge commit is the correct fallback.
   Attribution is preserved either way.
3. **Squash only when nothing is lost.** Squash-merge is permitted only when the branch's
   commits are not individually meaningful — successive review-fix commits on one
   document, for example — **and** every distinct `Agent-Attribution:` trailer on the
   branch is carried into the squashed message. Squashing away a trailer set that
   appears nowhere else on trunk is a data-loss event, not a formatting preference.

### Why signing does not block this

Rebase-merge rewrites commit SHAs, which invalidates commit signatures.
`workflows/git-and-gh-conventions.md` §"Multi-identity model" states that commit signing
is nice-to-have and not required, so no accepted convention is broken. If signing later
becomes required, this ADR should be revisited — Option B becomes the correct default at
that point, since merge commits preserve signatures.

### Relationship to the merge gate

Nothing here touches `ADR-0012`. Agents still MUST NOT merge, by any strategy. This ADR
governs which strategy a human selects, not who selects it.

## Consequences

### Positive

- Per-commit attribution survives to trunk, making `FS-0017`'s convention and its bats
  verification meaningful after merge rather than only on branches.
- Trunk history stays linear, so the property that motivated squash is retained.
- The one-document-per-commit practice this repository already follows becomes readable
  on trunk instead of being collapsed at the last step.

### Negative

- `git log` on trunk becomes longer — commits per PR rather than one per PR. On a
  documentation repository with verbose commit bodies, that is a real readability cost.
- Rebase-merge cannot run automatically on conflicting branches, so some PRs need manual
  resolution that squash would have absorbed.
- Commit SHAs on trunk differ from the SHAs on the PR branch, which occasionally confuses
  references to branch commits made during review.
- The squash exception in rule 3 requires judgment and has no automated check. A
  contributor can squash away trailers and nothing will stop them.

### Neutral

- Repository merge-button settings should be configured to match, with rebase-merge
  enabled and set as default. That is configuration, not policy, and is out of this
  ADR's scope.
- Existing trunk history is unaffected. Commits squashed before this decision stay as
  they are.

## Validation

- **Signal:** after acceptance, PRs with more than one commit arrive on trunk as more
  than one commit.
- **Signal:** `git log --format='%(trailers:key=Agent-Attribution)' origin/trunk` returns
  distinct trailers for distinct documents, rather than one per PR.
- **Signal:** `workflows/git-and-gh-conventions.md` Defaults and step 8 both state
  rebase-merge.
- **Review checkpoint:** after ten merges under this rule. The question is whether trunk
  history has become hard to read; if so, the answer is better commit hygiene on
  branches, not a return to squash.
- **Failure condition:** if trailers are observed missing from trunk for work known to be
  agent-authored, rule 3's squash exception is being used carelessly and should be
  removed rather than narrowed.

## Links

- ADR-0018 / ADR-0029: the attribution convention this decision protects.
- ADR-0012: the merge gate — unchanged; agents still do not merge.
- FS-0017: implemented commit attribution; `test/FS-0017/commit-attribution.bats`
  verifies it.
- `workflows/git-and-gh-conventions.md`: the current-state document this ADR updates,
  per `ADR-0030` rule 3.
