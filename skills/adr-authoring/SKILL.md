---
name: adr-authoring
description: "Writes architecture decision records that survive review in the conventional-agents framework — deciding whether a decision needs an ADR at all, constructing the argument, and stating only claims the repository can back. Use when drafting or revising an ADR, choosing between an ADR and a current-state document, or reviewing a proposed ADR before it is accepted."
license: MIT
---

# ADR Authoring Skill

Teaches the *craft* of writing an Architecture Decision Record in this framework: what belongs in one, how to build an argument that holds, and which claims the repository will not let you make.

Every rule below is derived from an ADR in this repository that was actually mis-authored and corrected. The commit that caught each one is cited, so you can read the correction yourself.

## Source Documents

- `docs/decisions/README.md` — ADR lifecycle, §1a (does this ADR need a governing FS?), Validation requirements, supersession process
- `templates/core/adr-full-madr.md` — the section skeleton
- `ADR-0030` — decision records versus current-state documents; the four rules
- `ADR-0015` — tool taxonomy; append-only ADRs; why miscategorisation costs
- `ADR-0026` / `ADR-0027` — approval as a recorded act; reserved paths
- `scripts/check-status.sh` — rule 5b, the supersession chain gate

## Purpose

This skill helps an agent:

1. **Decide whether the work is an ADR at all** — or a current-state document edit, or an FS
2. **Verify the ground** before building an argument on it
3. **Construct each section** so it does the job that section exists for
4. **State only claims the repository can back** — the overclaim failures are the most common
5. **Respect precedence and lifecycle moments** when citing other decisions

---

## Scope: Craft, Not Mechanics

This skill does **not** cover ID assignment, status transition rules, front matter field lists, README index maintenance, or resolving `npm run check:status` violations. All of that is `skills/document-lifecycle/SKILL.md`. Load that skill for mechanics; load this one for judgement.

---

## Step 1 — Is This an ADR At All?

Most bad ADRs in this repository are bad because they should not have been ADRs.

### The two families (`ADR-0030`)

| | Decision record | Current-state document |
| --- | --- | --- |
| Answers | Why is it this way? What was rejected? | What do I do? |
| Time frame | Fixed at the decision date | Always now |
| Mutability | Append-only after acceptance | Edited in place |
| Lives in | `docs/decisions/` | `workflows/`, `guidelines/`, `skills/`, `templates/`, `integrations/` |

`ADR-0030` rule 1: every rule has **exactly one** current-state document that states it. Rule 2: an ADR may quote a rule for legibility, but it is not where a reader looks the rule up.

**The test.** If you are writing out the complete rule as it will be followed, stop. That text belongs in the current-state document; the ADR cites it and records *why* it changed.

> Observed: `ADR-0029` was drafted replicating `ADR-0018` in full, producing a third copy of a convention `workflows/git-and-gh-conventions.md` already carried. Commit `edb528b` reshaped it as a decision record and moved 52 lines into the workflow doc.

### Does the decision also need a governing FS?

`docs/decisions/README.md` §1a decides this, and it is not style:

| The ADR implies | Needs a governing FS? |
| --- | --- |
| A convention, followed by people and agents | **No.** Update the current-state document and the ADR is discharged. |
| Code — a script, a CI job, a check, a generator | **Yes.** Write the FS before the code. |

An ADR that decides a check should exist has **not** authorized anyone to write it. A code-implying ADR with an empty `related_specs:` is the error signature.

### If the ADR you would edit is `accepted`, you need a new one

Accepted ADRs are append-only. A taxonomy cannot be widened, nor a premise corrected, by editing. Post-acceptance you may add a **Status note** pointing forward to the successor — nothing else.

---

## Step 2 — Verify the Ground Before You Argue

The single most damaging failure class here is building an argument on an unverified claim about another document.

**Resolve every citation against the file's own front matter and H1 — never against an index, a summary table, or a prior audit.**

> Observed: `docs/decisions/README.md` once carried eleven index rows naming decisions that exist in no file, and nine ADRs whose files said `proposed` while the index said `accepted` (commit `36a4046`). The fabricated title for `ADR-0009` was cited in `ADR-0024`'s Links and was load-bearing in `ADR-0030`'s premise (commit `e35d7f3`). `ADR-0009`'s real H1 is "Feature Specification Template Selection".
>
> Observed: a claim that `ADR-0015` was `accepted` — never checked against the file — propagated into an FS, a PLAN, the ADR's own Validation note, and several commit messages. It then caused commit `cfedfdc` to **delete correct content** by invoking the append-only rule, which did not apply. Commit `e9b2b26` restored it.

### Example — verify before you cite

```bash
# The only authoritative status and title: the file itself.
grep -m1 '^status:' docs/decisions/ADR-0015-*.md
grep -m1 '^# ADR-' docs/decisions/ADR-0015-*.md

# Every ADR's real status, to check an index claim in bulk.
for f in docs/decisions/ADR-*.md; do
  printf '%s\t%s\n' "$(basename "$f")" "$(grep -m1 '^status:' "$f")"
done
```

### Check the premise against the repository

Before writing Options, grep for the problem the Context asserts. If the gap is already filled, or the workflow already runs differently, the premise is the first thing to fix.

> Observed: `ADR-0026` was drafted to solve a problem this repository does not have. Commit `8ee78e2` records the finding; the file was renamed from `ADR-0026-bootstrap-merges.md` to `ADR-0026-approval-is-a-recorded-act.md` once the real problem was identified.

---

## Step 3 — Build the Argument

### Context and Problem Statement

State the problem, then **prove it is not hypothetical**. The strongest ADRs here carry an explicit evidence subsection naming files, counts, and incidents. Also name **what is not the problem** — it stops reviewers relitigating scope.

End with the question the ADR answers, in one bolded sentence.

### Decision Drivers

Cite binding constraints **by ID and with their status inline**. Drivers should be in genuine tension; if they all point one way, the decision is not hard and probably is not an ADR.

### Considered Options

At least two, and **steel-man the ones you reject**. Take the cheapest option seriously — usually "document harder, ship no code" — and say concretely why it loses. An option written to lose is a reviewer's first target.

### Decision Outcome

State the chosen option, then draw the boundaries as **numbered sections**. Numbered lines are what later ADRs and specs cite (`ADR-0037` §2, `ADR-0039` §5). Include a "what this does not change" statement.

### Consequences

Positive, negative, neutral. **Negative must be real costs you accept**, not hedges. A Consequences section with no genuine cost reads as unexamined.

### Validation

Name a signal someone could evaluate **today**, against a named file, command, or observable event. `docs/decisions/README.md` requires at least one of: metrics, signals, or review checkpoints. Add a **failure condition** — the observation that would mean the decision was wrong.

> Observed: Validation sections have been added to clear the acceptance gate rather than to be checkable (commits `4521178`, `68bc36c`). If the only way to satisfy the gate is prose, the ADR is not ready.

---

## Step 4 — Claims You Must Be Able to Back

### Enforcement versus detection

**Before writing that a rule is enforced, open the gate script or test and name the exact assertion.** If it checks shape only, say the values are review-audited and that mechanical enforcement is deferred.

> Observed: `ADR-0036` claimed "future drift fails CI instead of accumulating". Review forced commit `0a2f189` to restate it: the gate "keeps its structural checks (field presence and order via the `agent_attribution_pattern` regex)", while values "are review-audited". Commit `5c5af66` removed the same overclaim from the current-state document.

The framework already names the correct stance — `ADR-0024` §"Detection over prevention". A binding claiming prevention where its platform offers only detection is non-conforming.

### Example — check what a gate actually asserts

```bash
# Name the assertion before claiming it enforces anything.
grep -n "agent_attribution_pattern" -A4 test/FS-0017/commit-attribution.bats

# What rule 5b actually obliges (supersession chain, FS-0028):
sed -n '556,566p' scripts/check-status.sh
```

### Absolute verbs

Claim only what the decision mechanically prevents. Write **"removes &lt;named hazard&gt;"**, not "eliminates &lt;failure class&gt;", unless every path to that class is closed.

> Observed: `ADR-0035` said "Eliminates the stale-checkout and stash-pop failure classes." Commit `39cf301` qualified it — stale tracking refs can still cause drift.

### Tense

State rules in the tense the change delivers. If the PR does not perform the work, write the rule as prospective and say so in Consequences and Validation.

> Observed: `ADR-0038` rule 4 was corrected to say the source skills "**do not** conform when this ADR is accepted; this rule is the target state" (commit `3fe03d8`).

---

## Precedence and Lifecycle Moments

- **A `proposed` ADR is not precedent.** Cite it for its reasoning only, never as an authority your decision depends on, and mark its status inline where you cite it (commit `c5b8820`).
- **Every MUST names the lifecycle moment it binds at** — proposal, acceptance, merge, or implementation. A rule with no moment attached gets applied at the wrong one. `ADR-0030` rule 3 is the model: the current-state document updates **in the change that accepts** the ADR, not the one that proposes it.
- **Status must match reality.** Rule 5b proves the supersession chain is well-formed, not that any ADR reflects the world. When a decision's subject is removed in practice, update `status:` and `superseded_by:` in the same change.
- **Supersession is for reversal, not revision** (`ADR-0030` rule 4). An ADR revising one rule inside an earlier decision does not supersede it.

---

## Three Situations With Their Own Rule

**You are the author and the subject.** An ADR that expands the authoring agent's own authority must declare the conflict in its own text and route its safeguards into the document a human reads at approval time. `ADR-0027` acquired five findings in adversarial review for exactly this (commits `466af62`, `922c7f0`, `9c92b25`).

**You are correcting your own error.** Leave a one-line record of what was wrong and where the wrong belief came from. `ADR-0024` does this in its own Context; the correction without the record teaches nothing.

**You are citing another repository's document.** Qualify the ID with the repository name at **every** mention — an unqualified `FS-0024` or `PLAN-0024` reads as local and will collide (commit `39cf301`).

---

## What the Gates Catch — and What They Do Not

| Mechanically enforced | Gate |
| --- | --- |
| `superseded` ADR names a replacement; `superseded_by` resolves; only a `superseded` ADR declares one | `check:status` rule 5b |
| Filename number matches the `id:` field | `test/FS-0025/governance-patterns.bats` |
| `decision_scope` is one of: `architecture`, `workflow`, `convention`, `infrastructure`, `process`, `system`, `cross-cutting` | `test/FS-0025` |
| Markdown formatting | `npm run lint:adrs` |

Nothing checks: whether your Considered Options are steel-manned, whether Validation is falsifiable, whether a cited ADR's status is stated correctly, whether an enforcement claim is true, or whether the rule belongs in a current-state document instead.

**Referenced paths in ADRs are deliberately not checked.** `check:status` rule 8 covers current-state documents only — an ADR naming a file later renamed is history, not drift. That means broken paths in your ADR are *your* responsibility.

---

## Pre-Submit Checklist

- [ ] This is a decision, not a rule statement — the rule lives in a current-state document (`ADR-0030` rules 1–2)
- [ ] If the decision implies code, `related_specs:` names a governing FS (`README` §1a)
- [ ] Every cited ADR's status and title were read from its file, not an index
- [ ] The Context proves the problem is real, and names what is not the problem
- [ ] At least two options, rejected ones steel-manned, cheapest taken seriously
- [ ] Decision Outcome draws numbered boundaries and says what it does not change
- [ ] Negative Consequences are real costs
- [ ] Validation names a signal evaluable today plus a failure condition
- [ ] No enforcement claim without the gate's exact assertion named
- [ ] No absolute verb the decision cannot mechanically deliver
- [ ] Every MUST names its lifecycle moment
- [ ] Cross-repository IDs are qualified at every mention
- [ ] `npm run lint:adrs` and `npm run check:status` pass

## Scaffold and Check

```bash
npm run new:adr -- --title "Platform-neutral core with shipped bindings"
npm run new:adr --dry-run      # preview without writing
npm run lint:adrs
npm run check:status
```

---

## Common Pitfalls

| Pitfall | Evidencing commit |
| --- | --- |
| Citing an ADR's status or title from the index | `36a4046`, `e35d7f3` |
| Invoking append-only against a document that is not accepted | `e9b2b26`, `cfedfdc` |
| Claiming enforcement where only detection exists | `0a2f189`, `5c5af66` |
| Absolute verb in Consequences | `39cf301` |
| ADR restating a rule that belongs in a workflow doc | `edb528b` |
| Premise never checked against the repository | `8ee78e2` |
| Claiming as done what the PR does not do | `3fe03d8` |
| Treating a `proposed` ADR as binding precedent | `c5b8820` |
| Code-implying ADR with no governing FS | `466af62` |
| Validation written to clear the gate | `4521178`, `68bc36c` |
| Unqualified cross-repository ID | `39cf301` |

---

## Related Skills

- `skills/document-lifecycle/SKILL.md` — IDs, status transitions, templates, front matter, README index, `check:status` resolution
- `skills/spec-authoring/SKILL.md` — writing the governing FS an ADR's decision may require
- `skills/role-aware-session/SKILL.md` — Head Architect proposes ADRs; Document Author drafts them; neither approves them
- `skills/framework-health-audit/SKILL.md` — the document hygiene gate before a PR is marked ready

---

## Prohibitions

- **Do NOT** transition an ADR from `proposed` to `accepted` — acceptance is a recorded human act (`ADR-0026`).
- **Do NOT** modify an `accepted` ADR beyond its Status section.
- **Do NOT** cite a document's status from an index, a summary table, or a prior audit.
- **Do NOT** write that a rule is enforced without naming the assertion that enforces it.
- **Do NOT** restate a complete rule in an ADR when a current-state document carries it.
- **Do NOT** implement code an ADR implies without an approved FS and PLAN.
