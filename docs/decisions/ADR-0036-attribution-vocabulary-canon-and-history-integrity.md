---
type: adr
id: ADR-0036
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0017
superseded_by: null
created: 2026-09-01
updated: 2026-09-01
---

# ADR-0036: Attribution vocabulary canon and history-integrity policy

## Status

- Proposed

## Context and Problem Statement

ADR-0018 established the three-layer attribution model: `user.email`
distinguishes actors, `Co-authored-by:` marks collaboration, and an
`Agent-Attribution:` trailer records model, role, and session. ADR-0029
moved the model identifier into the trailer. The model works; the
_values_ have drifted because nothing bounds the vocabulary. Measured
across the 158 `Agent-Attribution:` trailer lines in this repository's
history (2026-09-01 census):

- `actor=` appears as `Claude Code`, `hermes-agent`, `Hermes Agent`,
  `Codex` — mixed casing and mixed tool-vs-agent identity in one field.
- `model=` appears as `anthropic/claude-opus-5`, `deepseek-v4-flash`,
  `Opus 5`, `ollama-cloud/deepseek-v4-flash`, `MiniMax-M3`,
  `deepseek-v4-flash:0731` — bare names and qualified identifiers in the
  same field.
- `role=` appears as `Head Architect`, `implementer`, `Implementer`,
  `document-author` — casing drift.
- Two trailer lines use `mode=` where `session=` is the field name, and
  one value is truncated mid-token.

Separately, `Co-authored-by:` is taught for agent–human commits (the
ADR-0018 hybrid example; `workflows/git-and-gh-conventions.md`). Git's
own `SubmittingPatches` defines `Co-authored-by:` as _people_ who
exchanged drafts of a patch. The 2025–2026 ecosystem debate —
Artsy's "disclose LLM usage in commits or PRs" RFC (merged 2026-06-08),
Ferdinandy's "Don't abuse Co-authored-by for marking AI assistance",
Rehm's `Coding-Agent:`/`Model:` trailer split — converged on the same
objection: co-authorship asserts shared authorship and accountability,
which a model cannot hold. GitHub additionally mints a contributor
avatar for every `Co-authored-by:` name; a tool gets an avatar, and a
human-relations signal gets tool noise.

Finally, the repository has no committed `.mailmap` (the conventions
document itself notes `git shortlog` fragments because of this), no
stated policy for the pre-public history rewrite, and 36 commits carry
signatures GitHub marks unverified — with no guidance on re-establishing
Verified for the public era.

## Decision Drivers

- Audit integrity: attribution values must be stable, queryable, and
  parseable (`git log --format=%(trailers)`).
- Human accountability: the human is the accountable author; tools are
  recorded, not credited as authors.
- Gate enforcement: vocabulary drift must fail CI, not accumulate in
  history.
- History honesty: a rewrite may normalize identities but must not erase
  the audit record.
- Public release: the rewrite must precede the public flip so every
  clone inherits a single canon.

## Considered Options

### Option A: Keep `Co-authored-by:` for agent participation

Familiar, GitHub-rendered, zero change. Rejected: contradicts git's own
definition of the trailer (people exchanging drafts), mints contributor
avatars for tools, and the ecosystem consensus explicitly warns against
it — "a model can't hold accountability".

### Option B: Introduce an `Assisted-by:` trailer for agents (Artsy convention)

Artsy adopted `Assisted-by:` for good reason: responsibility stays
visibly with the human and no avatar is minted. Considered and rejected
for this framework: `Agent-Attribution:` already exists, already carries
more information (tool, model, role, session), and is already
gate-enforced via the FS-0017 bats tests. A second trailer for the same
semantic doubles the surface for adopters to maintain. `Assisted-by` is
the right convention for projects without a richer trailer; this
framework has one. Adopters who prefer it can map directly:
`Agent-Attribution: actor=X; model=Y` ≡ `Assisted-by: X:Y`.

### Option C: Leave trailer vocabulary free-form

Zero cost. Rejected: the measured six-way `actor=` and five-way `model=`
drift is the failure mode this ADR exists to end; free-form fields are
not queryable and cannot be gated.

### Option D: Retroactively normalize historical trailers during the rewrite

Tempting for tidiness. Rejected: trailers are an audit record of what
was recorded at commit time. Rewriting them erases the evidence of
exactly the drift this ADR documents. The CHANGELOG records the past;
gates protect the future.

## Decision Outcome

1. **`Co-authored-by:` is human–human only.** It names people who
   exchanged drafts. Agent participation is recorded exclusively through
   `Agent-Attribution:` trailers. Hybrid commits carry the human
   identity in the author and committer fields and one or more
   `Agent-Attribution:` trailers naming each contributing agent actor.
   This amends the hybrid guidance in ADR-0018 (whose hybrid example
   includes `Co-authored-by: Hermes Agent`); ADR-0018 remains in force
   for everything else.
2. **Canonical trailer vocabulary (binding for new commits):**

   | Field | Canonical form | Valid examples | Invalid examples |
   | --- | --- | --- | --- |
   | `actor=` | Lowercase slug naming the agent persona | `hermes-agent`, `claude-code`, `codex`, `marten` | `Hermes Agent`, `Claude Code` (cased display forms; per ADR-0029 the author `user.name` carries the model display form, and the trailer's `actor=` is the persona slug regardless) |
   | `model=` | Provider-qualified `provider/vendor/model[:variant]` | `ollama-cloud/deepseek-v4-flash:0731`, `anthropic/claude-opus-5`, `anthropic/claude-sonnet-5` | `Opus 5`, `MiniMax-M3`, `deepseek-v4-flash` (bare display names) |
   | `role=` | ROLE_CONTRACT role in title case | `Implementer`, `Head Architect`, `Document Author`, `Reviewer` | `implementer`, `document-author` |
   | `session=` | Lowercase kebab-case session name | `architecture-planning`, `conventional-agents-maintenance` | `Architecture Planning` |
   | `mode=` | Optional terminal field; `autonomous` per ADR-0021 for unattended actors | `mode=autonomous` | `mode=hybrid` (session modes are not mode values) |

   Field order is fixed: `actor`; `model`; `role`; `session`; optional
   `mode` last.
3. **`.mailmap` is a committed canonical artifact** at the repository
   root, mapping every historical alias to its canonical identity. It is
   the single alias table for `git log --use-mailmap`,
   `git shortlog -se`, and the rewrite (`git filter-repo --use-mailmap`).
   The FS-0017 actor allowlist (the `ACTOR_EMAILS` array in
   `test/FS-0017/commit-attribution.bats`) must stay in sync with the
   identity table in `workflows/git-and-gh-conventions.md` and the
   `.mailmap`.
4. **History-rewrite policy.** A rewrite may normalize _identities_
   (author and committer name/email via `.mailmap`) and nothing else.
   Trailers are never edited retroactively. The rewrite must be verified
   tree-identical (full-tree diff between the pre-rewrite and post-rewrite
   mirrors must be empty; trailer count and content preserved) before
   force-pushing, and must complete before the repository flips public.
5. **Commit signatures.** The pre-public rewrite invalidates the 36
   existing signatures; those commits become and remain honestly
   unverified. Going forward, maintainers SHOULD sign commits with SSH
   keys so the public-era history carries `Verified` from the flip
   onward.

## Consequences

- The FS-0017 bats gate keeps its structural checks (field presence and
  order via the `agent_attribution_pattern` regex) and gains a
  `.mailmap` regression test. Canonical-vocabulary _values_ (lowercase
  actor slug, provider-qualified model, title-case role, kebab-case
  session) are review-audited per ADR-0030's detection-based enforcement
  stance; mechanical value enforcement is deferred to a future FS/PLAN
  and deliberately not claimed here — the current regex is structural,
  and a vocabulary gate over legacy history would fail on pre-canon
  commits.
- The maintenance-loop cron prompt still writes a bare
  `model=deepseek-v4-flash`; updating it is tracked separately as a
  "found, not fixed" item. Enforcement scope in this ADR's first
  revision is interactive-agent commits; the cron gap is documented, not
  silent.
- The identity table in `workflows/git-and-gh-conventions.md` corrects
  the never-used `taisden@tais-den.dev` row to the canonical human
  identity. Consumers substitute their own identities per ADR-0032's
  template-vs-instance rule and may override the instance table in their
  conventions repository per ADR-0016.
- Rebase-merge (ADR-0025) remains the only safe merge strategy:
  squash-merge collapses distinct `Agent-Attribution:` trailer sets into
  one message, which is data loss under this ADR's record-keeping model.
- The rewrite plan gains a normative shape: determine the canonical
  table, rewrite with `--use-mailmap`, verify tree-identical and
  trailer-preserved, then flip public.

## Validation

- The FS-0017 bats suite passes with the `.mailmap` regression and
  structural trailer assertions in place
  (`bats test/FS-0017/commit-attribution.bats`). Canonical-vocabulary
  value enforcement is intentionally review-audited, not CI-asserted
  (see Consequences).
- `npm run check:status` is green for the ADR-0036 index rows; the ADR's
  `## Validation` section is present (this section) per the requirement
  for acceptance.
- The `.mailmap` regression test (`git check-mailmap`) resolves every
  historical human alias to `Joey Clark <administrator@ajoeofalltrades.dev>`.
- The pre-public rewrite dry-run applies `--use-mailmap` and verifies a
  tree-identical diff against the pre-rewrite mirror; trailer lines are
  preserved byte-for-byte.

## References

- ADR-0018 — single-identity workflow with agent co-attribution
  (amended on the hybrid `Co-authored-by:` example)
- ADR-0021 — cron actor identity; `mode=autonomous` marker
- ADR-0029 — commit-author naming; `model=` lives in the trailer
- ADR-0030 — decision records versus current-state documents
  (detection-based enforcement stance used by this ADR)
- ADR-0032 — template and instance repository forms
- FS-0017 — single-identity commit attribution; bats enforcement
- `workflows/git-and-gh-conventions.md` — current-state document (ADR-0030)
- `.mailmap` — canonical alias table (committed with this ADR)
