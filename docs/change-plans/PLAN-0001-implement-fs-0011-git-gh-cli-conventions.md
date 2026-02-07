# Implement FS-0011 Git + gh CLI conventions

Generated: 2026-02-07T13:50:16

---
type: change-plan
role: implementer
language: markdown
status: approved
related_specs:
  - FS-0011
related_adrs:
  - ADR-0011
created: 2026-02-07
updated: 2026-02-07
---

## 1. Feature / Issue Reference
- Feature Spec ID(s): FS-0011
- Related ADR ID(s): ADR-0011
- Issue / PR Reference: (to be created)

## 2. Scope of Change

This change WILL:
- Add clear, copy/pasteable documentation for Git + GitHub (`gh`) conventions defined in FS-0011.
- Document the three-identity GitHub model (human, agent-committer, agent-reviewer) and the separation between:
  - git commit authorship (`user.name`/`user.email`)
  - GitHub action identity (`gh` auth context)
  - push/auth mechanism (SSH keys / HTTPS)
- Provide a standard daily workflow section (sync trunk, branch, commit, push, PR, rebase, merge).

This change will NOT:
- Add CI enforcement, hooks, or repository settings changes.
- Add non-GitHub forge support.
- Require commit signing.

## 3. Tests Driving This Change
- None (docs-only change; FS-0011 sets test_required=false)

## 4. Files to Be Modified
- docs/specifications/FS-0011-git-gh-cli-conventions-for-agent-dev-kit.md (link ADR + reflect final decisions if needed)
- docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md (status updates as accepted later)
- Add: docs/workflows/git-and-gh-conventions.md (new canonical guide)

## 5. Implementation Steps (High-Level)
1. Create `docs/workflows/` directory if it does not exist.
2. Write `docs/workflows/git-and-gh-conventions.md` containing:
   - Branch defaults (`trunk`) and branch naming prefixes.
   - Remote conventions: keep `origin` as canonical; optional `upstream`.
   - Commit message conventions (Conventional Commits-lite).
   - Standard workflow snippets:
     - sync `trunk`
     - create branch
     - commit
     - push
     - `gh pr create --fill` (+ draft guidance)
     - keep branch updated (rebase + `--force-with-lease` guidance)
     - merge policy (squash-merge) and branch deletion.
   - Multi-identity guidance:
     - when to use each identity
     - the difference between git author, GitHub PR author, and reviewer
     - recommended patterns for managing multiple identities (e.g., per-directory gitconfig includeIf; multiple `gh` auth contexts; SSH host aliases)
3. Update FS-0011:
   - add ADR-0011 to `related_adrs`
   - ensure “Remotes” section and success criteria match `origin` convention
4. (Optional, if desired) Add a short pointer in `docs/README.md` if one exists, or create a minimal index file in `docs/workflows/README.md`.
5. Run a quick docs sanity check:
   - links resolve
   - commands are consistent with `trunk`/`origin`
6. Commit changes on branch `feat/git-gh-conventions-kit` and open a PR.

## 6. Constraints and Guardrails
- Spec constraints:
  - FS-0011 Non-Goals / Out of Scope must be respected (docs-only; GitHub required; no enforcement).
- ADR constraints:
  - ADR-0011: agent PRs are authored by agent identity; keep review identity separate.
- Workspace constraints:
  - Do not introduce secrets (tokens, private emails, keys) into docs.

## 7. Risks and Edge Cases
- Risk: readers confuse `git` author identity with `gh` identity; mitigate via explicit explanation + examples.
- Risk: multi-account SSH setup is error-prone; mitigate by recommending unambiguous host aliases.
- Edge: repos whose default branch is not `trunk`; document how to adapt without attempting automatic changes.

## 8. Validation
- Manual checks:
  - Ensure the workflow doc uses `trunk` and `origin` consistently.
  - Verify FS-0011 references ADR-0011.
  - Confirm no credential-like strings are included.

## 9. Explicit Non-Changes
- No code behavior changes.
- No changes to gateway/OpenClaw config.
- No automation (hooks/CI) added.

## 10. Readiness Check
- [ ] FS-0011 is approved (required before treating as binding)
- [x] Scope is minimal and explicit
- [x] No architectural/code changes implied

## Declaration
I affirm that:
- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
