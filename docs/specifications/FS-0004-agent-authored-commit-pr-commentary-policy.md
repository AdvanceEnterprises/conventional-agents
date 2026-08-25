---
type: feature-spec
id: FS-0004
status: deprecated
title: Agent-authored commit + PR commentary policy (role-aware)
owner: Tai
test_required: false
interfaces:
  - workflows/git-and-gh-conventions.md (update PR body template and commit body guidance)
related_adrs:
  - ADR-0011
  - ADR-0012
supersedes: []
requires:
  - FS-0003
  - FS-0014
tags:
  - git
  - github
  - agents
  - roles
created: 2026-02-07
updated: 2026-08-24
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Agent-authored commit + PR commentary policy (role-aware)

## Status

- Deprecated (superseded by FS-0018/FS-0019 — agent-stance and role-aware commentary conventions now live in `workflows/git-and-gh-conventions.md`)

## Summary

The existing `workflows/git-and-gh-conventions.md` has a single PR body template and
minimal commit body guidance, both written before the six-role model existed. Agents
operating in different roles produce PRs with fundamentally different purposes: an
Implementer PR carries code changes with testable outcomes; a Document Author PR carries
spec drafts with no validation to run; a Communications Lead PR carries consumer-facing
doc updates that require human publication. A single template fits none of these well.

This spec defines role-aware commentary expectations for commits and PRs, replacing the
current one-size template with per-role guidance. The implementation is a documentation
update to `workflows/git-and-gh-conventions.md` — no enforcement or CI gates.

## Goals

- Define per-role PR body templates covering the five roles that open PRs (all except
  Reviewer, which only comments).
- Retain and strengthen the commit body guidance for agent commits, adding a trivial
  change exception.
- Retain the PR update comment expectation after addressing review feedback.
- Ensure all templates explicitly prohibit secrets in PR descriptions.
- Add a `requires: [FS-0014]` dependency, since the role taxonomy this spec references
  is defined there.

## Non-Goals

- CI enforcement that blocks merges based on PR body structure.
- Requiring commit signing.
- Changing merge strategy or branching conventions (see FS-0003).
- Defining commentary policy for non-GitHub forges.
- Changing the commit message subject line convention (Conventional Commits, already
  covered by FS-0003).

## Users / Stakeholders

- **Tai** — reviewer of all agent PRs; benefits from consistent, role-appropriate context.
- **Agents** — need clear, copy/pasteable templates per role rather than a generic
  five-field form.
- **Future contributors** — benefit from documented expectations rather than inferred
  conventions.

## Interfaces

- **`workflows/git-and-gh-conventions.md`** — replace the current single PR body
  template (step 5 of the standard workflow) with per-role templates; strengthen the
  commit body guidance; preserve the PR update comment section.

## Policy (normative)

### Commit bodies (all agent roles)

Agent commits SHOULD include a useful body unless the change is trivially self-evident
from the subject line (e.g., a single-word typo fix or a one-line formatting correction).

Required fields for non-trivial commits:

- **Why** — intent or context; what problem this addresses.
- **What** — high-level summary of what changed.
- **Risk** — what could break or regress (write "none" if genuinely none).
- **Validation** — what was run to verify correctness (write "not run" if not
  applicable, e.g., doc-only changes with no test suite).

Do not include secrets, tokens, private keys, or credentials in commit messages.

### PR body templates (per role)

#### Role 0 — Head Architect

Used when: proposing a new FS draft, ADR draft, or framework audit result.

Required sections:

- **Summary** — what governance artifact is being proposed and why now.
- **Context** — what problem or gap this addresses; relevant background.
- **Open questions** — decisions the human reviewer must make before this can be
  approved; leave blank if none.
- **Human action required** — what the reviewer needs to do: approve the spec,
  answer a question, or simply merge.

#### Role 1 — Document Author

Used when: adding or updating FS, PLAN, ADR, or README index documents.

Required sections:

- **Summary** — which documents changed and what their new status is.
- **Changes** — bullet list of each document touched and what changed (status
  transition, content update, new file, etc.).
- **check:status result** — confirm `npm run check:status` exits zero, or list any
  known violations and why they are acceptable.
- **Human action required** — if the PR contains a spec or ADR pending approval,
  call it out explicitly.

#### Role 2 — Spec Reader and Test Planner

Used when: adding test files derived from an approved spec.

Required sections:

- **Summary** — which spec was translated and which success criteria were covered.
- **Test approach** — brief description of testing strategy (unit, integration, etc.).
- **Coverage** — map of success criteria to test names or test file locations.
- **Not covered** — any success criteria intentionally deferred, with rationale.

#### Role 3 — Implementer

Used when: implementing an approved PLAN — code, scripts, or configuration changes.

Required sections:

- **Summary** — which PLAN is being executed and what was built.
- **Changes** — high-level list of files modified and why.
- **Validation** — what was run: test commands, lint commands, `check:status` result.
  If nothing was run, write "not run" with a reason.
- **Risk / Rollback** — what could break; how to revert if needed. Write "low risk,
  revert the merge commit" if genuinely low risk.

#### Role 5 — Communications Lead

Used when: updating consumer-facing docs — INTEGRATION.md, README consumer sections,
or drafting a GitHub Release description.

Required sections:

- **Summary** — what communication artifact changed and for which release or
  milestone.
- **Source** — which CHANGELOG entries or approved specs this is derived from
  (ensures content is traceable, not interpreted).
- **Human action required** — any publication step the human must take (e.g.,
  publish the GitHub Release, post the announcement). Be explicit.
- **Not included** — anything intentionally out of scope for this PR (e.g., social
  media, blog posts).

### PR update comment (all roles)

After pushing follow-up commits that address review feedback, the agent MUST post a PR
comment summarizing:

- which review items were addressed (reference the reviewer's comment or quote briefly)
- what changed in response (one line per item)
- what validation was performed, or explicitly "not run"

---

## Success Criteria

Each bullet MUST be objectively testable.

- Given `workflows/git-and-gh-conventions.md`, when searching for per-role PR templates,
  then templates exist for Role 0, Role 1, Role 2, Role 3, and Role 5.
- Given `workflows/git-and-gh-conventions.md`, when reading the commit body section,
  then it defines four required fields (Why, What, Risk, Validation) and includes a
  trivial change exception.
- Given `workflows/git-and-gh-conventions.md`, when reading the PR update comment
  section, then it specifies the three required elements (addressed items, changes,
  validation).
- Given `workflows/git-and-gh-conventions.md`, when searching for the old single PR
  body template (`Summary: / Context / Why: / Changes: / Validation: / Risk / Rollback:`
  as a flat list), then it is not present — the per-role templates have replaced it.
- Given `npm run check:status`, when run after implementation, then it exits zero.

## Edge Cases

- **Role 4 (Reviewer)** produces no PRs — only inline review comments and review
  summaries. No PR template is defined for this role.
- **Trivial commits** (single-line typo fix, whitespace correction) may omit the commit
  body entirely. The word "trivial" is intentionally narrow; when in doubt, include the
  body.
- **Multi-role PRs** (e.g., a session that does Document Author work and then Implementer
  work in the same PR): use the template for the dominant role and note the secondary
  role's outputs in the Changes section.
- **Squash merges**: the PR description becomes the squash commit body on trunk. This
  makes the PR template doubly important — it is also the permanent commit record.

## Out of Scope

- Automated checks that fail PRs missing template fields.
- Policies for non-GitHub forges.
- Changing commit message subject line conventions.
- Defining review comment conventions for Role 4 (separate concern).

## Dependencies

- FS-0003: Git + gh conventions (commit subjects, branching, merge strategy).
- FS-0014: Six-role model — this spec's per-role templates depend on the roles defined
  there.
- ADR-0011: Multi-identity model — agent-committer vs. agent-reviewer identities.
- ADR-0012: Non-overridable gates — PR merge prohibition is not relaxed by this policy.

## Rollout / Migration

1. Update `workflows/git-and-gh-conventions.md`:
   - Replace the current single PR body template with the five per-role templates.
   - Strengthen the commit body section with the four required fields and trivial
     exception.
   - Preserve and lightly clean up the PR update comment section.
2. Run `npm run check:status` — must exit zero.
3. Run `npm run lint:docs` — must exit zero.
4. Open PR for human review and approval.

## Open Questions

None.
