---
name: spec-authoring
description: "Writes feature specs whose Success Criteria become real tests and whose scope holds under implementation. Use when drafting or revising an FS, deciding whether work needs a spec at all, writing acceptance criteria, declaring interfaces, or reviewing a spec before it is approved."
license: MIT
---

# Spec Authoring Skill

Teaches the *craft* of writing a Feature Spec in this framework: deciding whether work needs one, writing Success Criteria that survive contact with a test author, and declaring scope that holds.

The governing constraint is unusual and worth stating first: **`## Success Criteria` is the only section tests are generated from.** Every spec carries a parsing hint saying so. A behaviour you want built and verified either appears there as a checkable criterion, or it does not get tested.

## Source Documents

- `templates/core/feature-spec.md` — the section skeleton and front matter
- `docs/specifications/README.md` — index rules and the consumer-impact rule
- `guidelines/ROLE_CONTRACT.md` — the spec-first rule; the document hygiene gate
- `ADR-0026` / `ADR-0027` — approval as a recorded act; reserved paths a PLAN may never self-approve
- `../testing-guide/SKILL.md` — how a test author consumes what you write
- `scripts/check-status.sh` — rules 1, 2, 4, 6, 7

## Purpose

This skill helps an agent:

1. **Decide whether the work needs an FS** — much of it does not
2. **Write Success Criteria that a test author can mechanically map**
3. **Declare scope that holds** — Non-Goals and Out of Scope are hard constraints
4. **Declare `interfaces:` correctly** — it is a machine-read surface contract
5. **Route approval honestly** when the plan touches reserved paths

---

## Scope: Craft, Not Mechanics

This skill does **not** cover ID assignment, status transition rules, front matter field lists, README index maintenance, or resolving `npm run check:status` violations. That is `../document-lifecycle/SKILL.md`. Load that for mechanics; load this for judgement.

---

## Step 1 — Does This Work Need a Spec?

The spec-first rule (`guidelines/ROLE_CONTRACT.md`) blocks implementation without an approved FS **and** an approved PLAN. But it does not make every change a spec.

| The work is | Needs an FS? |
| --- | --- |
| A governance gate — a script in `scripts/`, a CI check | **Yes** (`ADR-0015` Category 1) |
| A productivity skill under `skills/` | **No** (`ADR-0015` Category 2) |
| A convention people and agents follow | **No** — an ADR plus the current-state document discharges it |
| A typo, broken link, or formatting fix | **No** — trivial-fix exception |
| Anything you are unsure about | **Yes.** "If you are unsure whether work qualifies as trivial, it does not." |

An ADR that decides a check should exist has not authorized anyone to write it — that decision *implies* a spec (`docs/decisions/README.md` §1a). Write the FS before the code, not after.

---

## Step 2 — Success Criteria Are the Deliverable

This is the section the spec exists for. Everything else is context.

### Number every criterion

Write them `SC-1`, `SC-2`, … and group them by component with sub-headings. `../testing-guide/SKILL.md` requires that test names include the SC identifier and that the criterion text be referenced verbatim in the test. Unnumbered criteria make that impossible and the mapping silently degrades.

### Use Given / When / Then

```markdown
- **SC-7.** Given the framework repository is private and no credential is present,
  when the command runs, then it exits non-zero without initialising the submodule,
  and the message names the expected environment variable.
```

Three parts, each doing work: the precondition, the trigger, the observable outcome. A criterion missing the "then" is a wish.

### The test: could someone write the assertion today?

Read each criterion and ask whether a test author could write a `bats`, `pytest`, or `vitest` assertion from it **without asking you a question**. If not, it is not a criterion yet.

Strong criteria in this repository name the thing they inspect — a flag, an exit code, a file's content, an absent API call:

- "then it configures the `insteadOf` rewrite at **`--global`** scope. A test asserts the `--global` flag specifically, as a regression guard"
- "Given the command's source is inspected, then it contains no mutating project or issue operation — no `item-add`, no `item-edit`"

### An ambiguous criterion becomes an untested one

This is the failure mode worth internalising. `testing-guide` tells the test author what to do with an ambiguous criterion: mark it `xfail`, `it.todo`, or `skip` with a "spec unclear" reason. It does not tell them to come back and ask.

So a vague criterion does not fail loudly — it converts into a skipped test and a green suite.

> Observed: `FS-0022` §1c sat at `approved` carrying a success criterion nobody had written. Nothing caught it; it was found by reading.

### State the limits you cannot test

A spec that admits what its tests do not cover is stronger than one that implies total coverage. `FS-0029` says so directly about shell that calls a network API: behaviour against the live API "is not covered by these suites … This is a weaker guarantee than the rest of the corpus enjoys, and `FS-0029` says so rather than implying otherwise."

### Example — audit your own criteria before submitting

```bash
# Every criterion numbered and greppable?
grep -c '^- \*\*SC-' docs/specifications/FS-00XX-*.md

# Any criterion missing a "then"?
grep -n '^- \*\*SC-' -A3 docs/specifications/FS-00XX-*.md | grep -v 'then'

# After implementation: does every SC appear in a test?
for n in $(grep -o 'SC-[0-9]\+' docs/specifications/FS-00XX-*.md | sort -u); do
  grep -rq "$n" test/ || echo "UNMAPPED: $n"
done
```

---

## Step 3 — Non-Goals and Out of Scope Are Hard Constraints

Every spec's parsing hints say: *Treat "Non-Goals" and "Out of Scope" as hard constraints.* An implementer reads them as prohibitions, not preferences.

Use both, and use them differently:

- **Non-Goals** — things a reader would reasonably expect this change to do, which it deliberately will not. Each one states *why*, usually citing the ADR or rule that forbids it.
- **Out of Scope** — adjacent work that belongs to someone else or to a later change. Shorter, no justification needed.

The discipline: when scope grows during implementation, the Non-Goals are what you revise **first**, in the spec, before writing the code. Scope that grows without the spec changing is the most common way an implementation stops matching its spec.

---

## Step 4 — `interfaces:` Is a Surface Contract

The front matter carries a parsing hint: *Interfaces listed here define allowed surface area for code changes.* It is read by tooling and by the hygiene gate item "Interfaces match reality".

**Write it as a YAML block list, never as an inline list.**

```yaml
interfaces:
  - "integrations/github/lib/gh-common.sh"
  - "test/FS-0029/**"
```

The inline form `interfaces: ["guidelines/", "skills/"]` is parsed by `get_list_field`, whose inline branch does **not** strip surrounding quotes — the values come out as `"guidelines/"` with the quotes attached and match nothing by prefix. Every `interfaces:`, `related_specs:`, and `touches:` field in this repository is block-list form, which is why the bug is latent rather than live. Keep it that way.

Declare every path the change will touch, including tests, index READMEs, and `CHANGELOG.md`. A path touched but undeclared, or declared but untouched, is a hygiene-gate finding.

---

## Step 5 — Open Questions Carry Their Own Defaults

An Open Question without a default blocks the spec. An Open Question **with** a stated default does not:

> **Should the CI templates be copyable fragments or reusable workflows?** *Default: copyable fragments.* A reusable workflow in a private repository imposes access requirements on every caller. Reconsider after the public transition.

Write each as: the question, the default in italics, the reason, and the condition that would change it. Then say plainly at the top of the section that none are blocking.

---

## Step 6 — Route Approval Honestly

If the governing PLAN's `touches:` includes a reserved path — `docs/decisions/`, `guidelines/ROLE_CONTRACT.md`, `scripts/`, `.github/workflows/`, or `package.json` — the plan **cannot self-approve** (`ADR-0027`, enforced by `check:status` rule 6). Approval is a recorded act carried by an `Approved-By:` trailer on the merge commit (`ADR-0026`).

Say this in the spec, in a **Plan Status** section, rather than leaving a reader to work it out. State which reserved paths are involved and that implementation does not begin before the transition. Flipping a PLAN's status inside the implementing PR fails the gate rather than recording an approval that had already happened.

---

## Status Discipline

Two failures this repository has actually had, neither caught by a gate:

- **Front matter drifting from the body.** When `FS-0018`–`FS-0023` moved to `implemented`, the front matter said `implemented` while each body's `## Status` section still said "Approved" and each still claimed its PLAN was `approved`. Six documents; the gate was green throughout. **Update the `## Status` bullet and any bolded *PLAN-NNNN is `status`* claim in the same edit as the front matter.**
- **Merged but never marked.** `FS-0018`–`FS-0023` merged and sat at `approved` for three days. Rule 1 only fires on documents already marked `implemented`, so an unmarked one is invisible to it.

And the slow one: `FS-0002` sat `approved` for five months while a different set of skills shipped past it. An `approved` spec nobody is building should be `deprecated` with a note, not left indefinitely.

---

## What the Gates Catch — and What They Do Not

| Mechanically enforced | Gate |
| --- | --- |
| FS↔PLAN status pairing — but only once one is marked `implemented` | `check:status` rule 1 |
| README index table matches front-matter status | rule 2 |
| FS/PLAN index title sync | rule 4 |
| PLAN `touches:` containment against reserved paths | rule 6 (`ADR-0027`) |
| CHANGELOG entry when an exported prefix changes | rule 7 |
| Front-matter fields present; no placeholder dates | `test/FS-0025/governance-patterns.bats` |

Nothing checks whether a Success Criterion is testable, whether a Non-Goal is honoured by the implementation, whether the body's `## Status` agrees with front matter, or whether a merged spec was ever marked `implemented`.

**Paths named in a spec are not resolved.** `check:status` rule 8 covers current-state documents only — decision records, specs, and plans describe what was true when written. Broken paths in your FS are yours to catch.

---

## Pre-Submit Checklist

- [ ] The work actually needs a spec (`ADR-0015` category; not a trivial fix)
- [ ] Every criterion is numbered `SC-N` and grouped by component
- [ ] Every criterion has a Given, a When, and an observable Then
- [ ] A test author could write each assertion without asking a question
- [ ] Criteria that cannot be tested are named as such, not implied covered
- [ ] Non-Goals state *why*, citing the rule or ADR that forbids each
- [ ] `interfaces:` is a block list, covers tests, indexes, and `CHANGELOG.md`
- [ ] Open Questions each carry a stated default and are declared non-blocking
- [ ] Plan Status names any reserved paths and the approval route (`ADR-0026`/`ADR-0027`)
- [ ] Body `## Status` agrees with front-matter `status:`
- [ ] `test_required:` is set deliberately
- [ ] `npm run lint:specs` and `npm run check:status` pass

## Scaffold and Check

There is no `new:spec` generator — `npm run new:adr` and `npm run new:plan` exist, specs are copied from the template.

```bash
cp templates/core/feature-spec.md docs/specifications/FS-00XX-<slug>.md
# fill front matter, then:
npm run lint:specs
npm run check:status
```

---

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Unnumbered success criteria | Test names cannot carry an SC identifier; mapping degrades silently |
| Vague criterion ("handles errors gracefully") | Becomes an `xfail`/`todo`/`skip` and a green suite |
| Behaviour described only in Summary or Goals | Never tested — only `## Success Criteria` generates tests |
| Inline `interfaces: ["a", "b"]` | Quotes are not stripped; prefix matching fails |
| Scope grown in code, Non-Goals unchanged | Implementation no longer matches its spec |
| Open Question with no default | Blocks approval unnecessarily |
| PLAN touching a reserved path with no stated approval route | `check:status` rule 6 fails at the worst moment |
| Front-matter status updated, body `## Status` left behind | Gate stays green; readers follow the wrong state |
| `approved` spec left unbuilt indefinitely | Ships a false claim about what the framework is doing |

---

## Related Skills

- `../document-lifecycle/SKILL.md` — IDs, status transitions, templates, front matter, README index, `check:status` resolution
- `../testing-guide/SKILL.md` — how a test author maps your Success Criteria into tests; read it before writing them
- `../adr-authoring/SKILL.md` — writing the decision record that may require this spec
- `../framework-health-audit/SKILL.md` — the document hygiene gate before a PR is marked ready

---

## Prohibitions

- **Do NOT** transition a spec from `draft` to `approved` — that is a recorded human act.
- **Do NOT** write implementation or test code from a spec that is not `approved`.
- **Do NOT** put a behaviour you expect to be tested anywhere but `## Success Criteria`.
- **Do NOT** widen scope in code without revising Non-Goals in the spec first.
- **Do NOT** declare an interface path the change will not touch, or touch one it does not declare.
- **Do NOT** flip a PLAN's status inside the PR that implements it.
