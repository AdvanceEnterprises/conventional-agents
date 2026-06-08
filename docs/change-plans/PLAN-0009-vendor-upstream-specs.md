---
type: change-plan
role: implementer
language: markdown
status: approved
related_specs: [FS-0009]
related_adrs: [ADR-0010]
created: 2026-02-08
updated: 2026-02-08
---

# Change Plan: Vendor Upstream Specs (Conventional Commits, Keep a Changelog)

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0009
- Related ADR ID(s): ADR-0010
- Issue / PR Reference: TBD

## 2. Scope of Change

**This change WILL:**

- Add `vendor/conventional-commits/` as a git submodule
- Add `vendor/keep-a-changelog/` as a git submodule
- Update README.md with an "Upstream References" section
- Update `workflows/versioning-and-releases.md` with vendor path references
- Update CHANGELOG.md format header with vendor path reference
- Update INTEGRATION.md to mention vendored upstream specs

**This change will NOT:**

- Modify the substance of any guideline or template
- Add build tooling or dependencies
- Vendor MADR, arc42, or semver.org

## 3. Tests Driving This Change

Validation is via:

- `markdownlint-cli2` CI passing on all modified .md files
- Manual verification of submodule init + spec file accessibility
- Manual review against FS-0009 Success Criteria

## 4. Files to Be Modified

- `.gitmodules` (modify — add 2 submodule entries)
- `vendor/conventional-commits/` (new submodule)
- `vendor/keep-a-changelog/` (new submodule)
- `README.md` (modify)
- `workflows/versioning-and-releases.md` (modify)
- `CHANGELOG.md` (modify)
- `INTEGRATION.md` (modify)

## 5. Implementation Steps (High-Level)

1. **Add conventional-commits submodule** — `git submodule add https://github.com/conventional-commits/conventionalcommits.org.git vendor/conventional-commits`

2. **Add keep-a-changelog submodule** — `git submodule add https://github.com/olivierlacan/keep-a-changelog.git vendor/keep-a-changelog`

3. **Update README.md** — add "Upstream References" section before the footer listing:
   - Conventional Commits (vendored + URL)
   - Keep a Changelog (vendored + URL)
   - joelparkerhenderson/architecture-decision-record (URL only, recommended reading)

4. **Update workflows/versioning-and-releases.md** — in the changelog conventions section and commit message section, add notes pointing to the vendored spec files

5. **Update CHANGELOG.md** — in the format header, add a parenthetical referencing the vendored spec

6. **Update INTEGRATION.md** — in the repo structure or best practices section, mention the vendored upstream specs under `vendor/`

7. **Run lint** — verify all modified markdown passes

## 6. Constraints and Guardrails

- FS-0009 Non-Goals: no forking upstream, no build tooling, no substance changes
- Submodules should be pinned to the latest tagged release where available

## 7. Risks and Edge Cases

- Upstream repos contain website build files (Hugo, Ruby) — consumers should not try to build them
- If upstream repos archive or move, submodule URLs will need updating

## 8. Validation

- Submodules init cleanly: `git submodule update --init --recursive`
- Spec files accessible at expected paths
- All markdown lint passes
- Each FS-0009 Success Criterion verified

## 9. Explicit Non-Changes

- Guideline substance (only adding references, not changing rules)
- Existing external URLs (kept alongside new vendor paths)
- Other vendored content
- CI workflow configuration

## 10. Readiness Check

- [x] Spec is approved
- [x] Tests exist or are clearly defined
- [x] Scope is minimal and explicit
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation
- No additional behavior will be introduced
- Any deviation will require revising this plan before coding
