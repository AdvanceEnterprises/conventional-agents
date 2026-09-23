---
type: feature-spec
id: FS-0037
status: draft
title: Vendor-prefixed reference resolution — close the submodule-citation blind spot in referenced-path checking
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "test/FS-0037/vendor-ref-resolution.bats"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0027, ADR-0030, ADR-0033]
supersedes: []
requires: []
tags: [quality-gates, references, vendor, submodule, enforcement]
created: 2026-09-22
updated: 2026-09-22
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

# Feature Spec: Vendor-prefixed reference resolution

## Summary

`FS-0022` §1c's referenced-path check catches a document naming a file that
does not exist — but it carries a blanket exclusion for every reference
beginning `vendor/`, justified as "uninitialised submodule contents are
absent until `git submodule update --init` and that is not drift." The
canonical consumer-side citation of a **framework** file —
`vendor/conventional-agents/<path>` — matches that exclusion too, so the
most common way a consumer-facing document names a framework file is the
one shape the check never resolves. The strip-prefix fallback the script
already carries (`bare=${ref#vendor/conventional-agents/}`) is unreachable
for those references because the exclusion clause `continue`s first.

This spec closes that blind spot: references of the form
`vendor/conventional-agents/<path>` are resolved against the framework tree
(by stripping the prefix) instead of being skipped, while genuinely
uninitialised third-party submodules — `vendor/madr/` and any other
non-conventional-agents vendor path — keep today's skip behaviour. A
companion clause extends coverage to non-backticked occurrences of the same
prefix in the three exported-surface documents, because the worked incident
below involved references that carried no backticks at all.

## Problem / Evidence

Three separate incidents in this repository are the same failure class: a
current-state document cites a path that has never existed.

| Incident | References | Survived every gate? |
| --- | --- | --- |
| `packs/` removal (repaired by `8cf14ac`) | 4 paths under `packs/` | Yes — repaired by hand, nothing detected the remainder |
| `INTEGRATION.md` phantom paths (#163, repaired by PR #164) | `guidelines/tests.md`, `guidelines/commit-and-pr.md`, `guidelines/index.md`, `roles/test-writer.md`, `integrations/spec-kit.md`, plus a `<REPO_URL>` placeholder | Yes — for the file's entire life |
| `docs/ARC42.md` §8.3/§8.4 (recorded in `BACKLOG.md`) | `guidelines/context-engineering.md`, `guidelines/multi-agent-coordination.md` | Yes — `docs/ARC42.md` is outside the check's document scope |

The referenced-path check (rule 8) exists precisely to catch this class, and
it does catch the bare form. Measured against trunk `ffa2dad` during the
2026-09-22 maintenance tick:

- Injecting a phantom **bare** reference (`guidelines/NEVER-EXISTED.md`) into
  `INTEGRATION.md` → `check-status.sh` fails, rc=1, naming the path.
- Injecting a phantom **vendor-prefixed** reference
  (`vendor/conventional-agents/guidelines/NEVER-EXISTED.md`) → the gate
  **passes**, rc=0. The prefix is skipped before any resolution is attempted.

The prefix form is not an edge case. It is how this framework's own
documentation instructs consumers to cite framework files (`INTEGRATION.md`'s
precedence table, `AGENTS.md`'s "point host-repo agents at
`vendor/conventional-agents/AGENTS.md`"), and a raw-text scan of the three
repositories' governed documents finds **127** concrete prefixed references
(conventional-agents 64, feral-fleet 39, pack-protocol 24), all currently
resolving, none currently checked.

The count is reproducible. The extractor is a raw-text scan — not the
backtick-only form rule 8 uses today — over rule 8's current-state document
set:

```sh
for doc in $(git ls-files '*.md'); do
  case "$doc" in
    README.md|AGENTS.md|INTEGRATION.md|CONTRIBUTING.md) ;;
    guidelines/*|roles/*|skills/*|templates/*|workflows/*|integrations/*|runbooks/*|scripts/*) ;;
    *) continue ;;
  esac
  grep -oE 'vendor/conventional-agents/[A-Za-z0-9_./@-]+' "$doc"
done | grep -vE '<|\*|\.\.\.|/$' | grep -E '\.[a-z]+$' | wc -l
```

Two scope sensitivities are worth recording, because they move the figure and
each is a symptom of the same narrowness:

- **The `docs/` tree.** Extending the same scan to `docs/` raises
  conventional-agents to 92 (feral-fleet 66, pack-protocol 47). The
  conventional-agents tree carries a large governed `docs/` corpus; this
  spec's scope is rule 8's document set, so 64 is the figure that matches the
  change being proposed.
- **The backtick requirement.** Under the *backtick-only* extractor rule 8
  runs today, the prefixed population in scope collapses to
  conventional-agents **3** (feral-fleet 38, pack-protocol 24). The blind spot
  is near-total in this repository precisely because its prefixed references
  are predominantly unbackticked — which is the second clause's whole point.

One further measurement shapes the scope: the `INTEGRATION.md` phantoms were
not backticked. The current extractor only sees backticked tokens
(`` `path.ext` ``), so a purely prefix-resolution fix would not have caught
the incident that motivated this spec. Both clauses are therefore in scope —
they are two halves of the same blind spot.

## Goals

- Resolve `vendor/conventional-agents/<path>` references instead of skipping
  them, in both the self-check (framework checking itself) and consumer
  (vendored copy checking a host) modes of `scripts/check-status.sh`.
- Extend the extractor for the three exported-surface documents
  (`INTEGRATION.md`, `README.md`, `AGENTS.md`) to see the same prefixed form
  without requiring backticks, with the conservative token shape below.
- Keep the legitimate exclusion intact: third-party vendor paths that are
  genuinely uninitialised submodules (`vendor/madr/`) must continue to skip,
  not fail, and prose anti-examples must continue to pass.
- Stay within the existing rule-8 architecture: same script, same
  `REF_EXEMPT` / `config/gates.yml` escape hatches, same Bash 3.2
  compatibility, no new npm script or CI job.

## Non-Goals

- Re-checking decision records (`ADR`, `FS`, `PLAN`). They describe what was
  true when written; §1c's existing scope decision stands. The historical
  `vendor/conventional-agents/...` references inside `ADR-0006`, `ADR-0007`,
  and `ADR-0039` are out of scope and must not be "fixed" to satisfy a
  linter.
- Extending rule 8's document scope to `docs/ARC42.md` or any other file
  outside the current in-scope set. The ARC42 phantoms are recorded in
  `BACKLOG.md` and belong to that document's own refresh, not this gate.
- Resolving *unprefixed* references that name a consumer-side path (the
  existing `REF_EXEMPT` mechanism already handles those).
- Changing `FS-0022` §1c's backtick-token rule for documents other than the
  three exported-surface files.

## Users / Stakeholders

- Consumers following the documented integration path — the party who hits a
  dead reference.
- Maintainers of the three repositories, who currently have no mechanical
  defence against reintroducing the class.
- The maintenance tick, whose reference sweep is the manual stopgap this
  spec replaces (issue #165).

## Interfaces

- Type: CLI (governance gate)
- Details: a new branch of rule 8 inside `scripts/check-status.sh`;
  documentation of the extended rule in `scripts/README.md`; bats coverage in
  `test/FS-0037/vendor-ref-resolution.bats`; registry rows in the FS and PLAN
  READMEs; a CHANGELOG entry naming `FS-0037` (exported-surface gate per rule
  7).

## Success Criteria

- **SC-1** Given a current-state document carrying a backticked
  `vendor/conventional-agents/<path>` reference whose `<path>` does not exist
  in the framework tree, when `check-status.sh` runs in self-check mode, then
  it fails (non-zero) and the error names both the document and the
  reference.
- **SC-2** Given the same shape whose `<path>` does exist, when the check
  runs in self-check mode, then it passes; specifically the three
  repositories' currently-resolving prefixed references (92 / 39 / 24 as
  measured on 2026-09-22) produce no failures.
- **SC-3** Given a reference to any other `vendor/*` path (e.g.
  `vendor/madr/template.md`) that does not exist, when the check runs, then
  it skips the reference without failing — the uninitialised-submodule
  exclusion is preserved — and this is asserted both for self-check and
  non-self-check modes.
- **SC-4** Given placeholder forms (`vendor/conventional-agents/roles/<role>.md`)
  or prose anti-examples (`vendor/conventional-agents/vendor/...`), when the
  check runs, then neither fails; placeholders are exempt as today, and the
  anti-example contains no file extension so it is not extracted as a path.
- **SC-5** Given `INTEGRATION.md`, `README.md`, or `AGENTS.md` carrying a
  NON-backticked occurrence of `vendor/conventional-agents/<path>` where
  `<path>` is concrete (has a file extension, no angle brackets, no
  ellipsis, no glob) and does not exist, when the check runs, then it fails
  and names the reference; the worked check is that reintroducing any one of
  the six #163 phantoms into `INTEGRATION.md` fails the gate.
- **SC-6** Given a host repository whose `vendor/conventional-agents`
  submodule is not initialised, when a vendored `check-status.sh` runs in
  non-self-check mode against it, then prefixed references in that host's
  in-scope documents do not fail (the uninitialised exemption applies at the
  submodule, not at the prefix).
- **SC-7** Given a reference the operator has confirmed is a legitimate
  consumer-side path, when it is listed in `REF_EXEMPT` (self-check) or
  `ref_exempt` in `config/gates.yml` (host), then the extended check honours
  the exemption exactly as the existing check does.

## Edge Cases

- A prefixed reference naming a directory (`vendor/conventional-agents/scripts/`)
  is not extracted: the token requires a file extension.
- A prefixed reference resolving to a file that exists but is a directory,
  or vice versa, is a failure in both cases (existence test, not type test —
  consistent with the existing rule).
- Multiple references to the same phantom path in one document are reported
  once per document (the extractor sorts and de-duplicates, as today).
- In non-self-check mode with an initialised submodule, the as-is resolution
  (`$REPO_ROOT/vendor/conventional-agents/<path>`) and the strip-prefix
  resolution (`$REPO_ROOT/vendor/conventional-agents/<path>` again, from the
  host's perspective) are the same file; the failure message must not
  double-report.
- A document in a subdirectory referencing the prefix (e.g.
  `skills/x/SKILL.md` citing `vendor/conventional-agents/...`) keeps the
  existing three-way resolution order: repo root, bare-after-strip, then the
  naming document's own directory.

## Out of Scope

- Any change to rule 3 scope, template-placeholder handling for other
  document classes, or the `docs/orchestration/` exclusion.
- Auto-repair of references. The check reports; it never rewrites.
- Link-checking HTTP(S) URLs.

## Dependencies

- `FS-0022` §1c (the rule being extended) and its existing exclusions.
- `ADR-0033` (target resolution) — the extended resolution must respect both
  the self-check and non-self-check modes and the `config/gates.yml`
  `ref_exempt` list.
- `ADR-0027` — `scripts/` is a reserved path; the implementing PLAN cannot
  self-approve and requires human approval.
- `ADR-0030` — current-state documents are the check's subject.

## Rollout / Migration

- The gate goes green on adoption: post-#164, no in-scope prefixed reference
  in any of the three repositories fails resolution (verified during the
  2026-09-22 tick by raw-text scan). No document edits ship with the
  implementation except the CHANGELOG entry and registry rows.

## Open Questions

- None blocking. Whether to eventually widen the non-backticked clause beyond
  the three exported-surface documents is deliberately deferred: measure
  false-positive pressure from those three first.
