# Review brief — collective-agents PR #4 and PR #6

You are an **independent reviewer**. You did not author these changes and you were
not involved in designing them. Your job is to find problems. A review that
agrees with everything and checks nothing is worse than no review.

## Hard rules

- **Read-only.** Do not create, modify, or delete any file in either checkout.
  Do not commit, push, open or edit a pull request, or comment on GitHub. Do not
  run any mutating command.
- **If you cannot read the material you need, say so and stop.** Never guess at
  content you could not read.
- **Distinguish verified from assumed.** A claim you did not check is reported as
  unverified, not as a finding.
- Every finding needs: severity, location, what is wrong, why it matters, and the
  smallest fix you would accept.

## The product, in one paragraph

`collective-agents` is a reusable **workflow execution product**: it enumerates
governed work items, decides what is eligible, dispatches bounded agent runs,
records outcomes, and publishes proposals for human review. It is governed by the
pinned `conventional-agents` framework, vendored as a Git submodule. It is *not*
an agent framework, a GitHub replacement, or an organisation's private ops desk.
Git is core; GitHub (work items) and Hermes (agent runtime) are the *first*
integrations, not required dependencies. **Nothing is implemented yet** — the
repository has a governance bootstrap and two proposed decisions.

## What you are reviewing

Two **stacked** pull requests. PR #6 is based on PR #4's branch, so PR #6's own
changes are the *second* diff, not the first.

### PR #4 — `chore: establish governed document surface and vendored gates`

Branch `chore/governed-document-surface`, base `trunk`. Establishes the document
surface the framework expects a consumer repository to have:

- `docs/{decisions,specifications,change-plans}/`, each with an index README
- `scripts/check-status.sh` — the framework's status gate, vendored
- `config/gates.yml` — this repository's `reserved_paths`
- root Markdown lint config, `package.json`, `.github/workflows/governance.yml`
- `CHANGELOG.md`; edits to `README.md` and `AGENTS.md`

### PR #6 — `docs: propose ADR-0001, ADR-0002, and FS-0001 for the first pilot`

Branch `feat/adr-0001-0002-fs-0001`, base PR #4's branch. Proposes:

- `ADR-0001` — authorized intent identity and the human grant
- `ADR-0002` — worker and publisher credential separation
- `FS-0001` — the `feature` / `draft-spec` pilot specification
- per-directory lint configs at `docs/*/.markdownlint.yml`

Both ADRs land `proposed` and the FS lands `draft`. Neither is approved.

## Where the material is

Both branches are checked out on this host:

| | path |
| --- | --- |
| PR #4 branch | `/workspace/collective-agents-bootstrap` |
| PR #6 branch | `/workspace/collective-agents-design` |
| Pinned governing contract | `<either worktree>/vendor/conventional-agents` |
| Pre-generated diffs | `/workspace/.review/pr4-6/PR4.diff`, `PR6.diff` |

Contract pin: `94b784aa022b715bf7dad331a714f786620f961a`.

Exact diffs if you want them fresh:

```sh
git -C /workspace/collective-agents-bootstrap diff 8039de5 169794c   # PR #4
git -C /workspace/collective-agents-design    diff 169794c 34c0aab   # PR #6
```

## The contract you are judging against

Read these before forming an opinion. They are binding for this repository:

- `vendor/conventional-agents/workflows/document-lifecycle.md` — statuses, transition rules, approval shapes
- `vendor/conventional-agents/docs/decisions/README.md` — ADR process
- `vendor/conventional-agents/docs/specifications/README.md`
- `vendor/conventional-agents/docs/change-plans/README.md`
- `vendor/conventional-agents/guidelines/ROLE_CONTRACT.md` — universal gates
- `vendor/conventional-agents/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md`
- accepted ADRs: `ADR-0012`, `ADR-0014`, `ADR-0019`, `ADR-0020`, `ADR-0024`, `ADR-0026`, `ADR-0028`, `ADR-0039` under `vendor/conventional-agents/docs/decisions/`
- templates: `vendor/conventional-agents/templates/core/{adr-full-madr,feature-spec,change-plan}.md`

## Review dimensions

1. **Framework conformance.** Front matter, required sections, four-digit IDs,
   index sync, status vocabulary, approval shape (`ADR-0026`). Does anything
   contradict an accepted upstream ADR, or silently supersede one?
2. **Substance and safety.** In `ADR-0001` and `ADR-0002`: is any guarantee
   asserted that the described mechanism cannot deliver? Any missing failure
   mode? Is "one canonical publication per intent" honestly bounded, or dressed
   up as exactly-once?
3. **Testability of `FS-0001`.** Are the Success Criteria objectively testable and
   free of implementation presupposition? Is the deliberately empty `interfaces:`
   a legitimate use of the framework's containment rule, or a dodge that lets an
   unapproved plan slip through?
4. **Boundary.** Does anything leak instance data into the product repository
   (identities, board or field IDs, schedules, budgets, credentials, org names),
   or put product mechanisms into the framework's territory?
5. **Independent verification.** Run the repository's own gates if you can, and
   report the real result — do not take the PR description's word for it:

   ```sh
   cd /workspace/collective-agents-design
   npm install --no-audit --no-fund
   npm run governance
   ```

## Output

Write your review to exactly one file, replacing `<MODEL>` with the model id
given in your task line:

`/workspace/.review/pr4-6/review-<MODEL>.md`

Use this structure:

```markdown
# Review: collective-agents PR #4 and PR #6

**Model:** <your model id>
**Revisions read:** <commit SHAs you actually read>
**Files read:** <or "partial: ...">
**Gate commands run:** <exact commands and exit codes, or "not run: <reason>">

## Verdict

- PR #4: approve | approve-with-changes | reject
- PR #6: approve | approve-with-changes | reject

<one short paragraph per PR>

## Findings

### [BLOCKER|MAJOR|MINOR|NIT] <short title>

- **Where:** <file:line or section>
- **What:** <the problem>
- **Why it matters:** <consequence>
- **Smallest acceptable fix:** <change>

(repeat. An empty findings list is legitimate if you state what you checked.)

## Not verified

<what you could not check, and why>

## Where another reviewer may reasonably disagree

<the places you expect a different reading, and why>
```

Then print a **10-line summary** to stdout: verdicts, blocker/major counts, and the
single most important finding.
