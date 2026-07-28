# Orchestration Evidence

Preserved artifacts from multi-model orchestration runs performed against this
framework. These are **evidence, not guidance** — they record what happened during a
run, at the time it ran, under the conventions in force then.

For current rules, see the collaboration-mode specifications and their templates.
Nothing in this directory is normative, and none of it should be copied as a pattern
without checking it against the specs that superseded it.

## Provenance

These files originate from PR #62 and its successors #63 and #64
(`feature/multi-model-orchestration-foundation`, `docs/adr/0016/round2-acceptance`,
`docs/domain-concept-adr-fs`). Those branches are being closed unmerged; their useful
content was extracted into the framework proper, and this directory preserves the
empirical record that extraction was based on.

They are preserved verbatim. Where they reference documents by an ID that means
something else on trunk — their `ADR-0016` is multi-model orchestration, ours is
consumer conventions — the reference is to the branch document, not ours. Where they
show `Assisted-By:` / `Contributor-Session:` trailers, that was the convention on
those branches; `ADR-0018` as amended by `ADR-0029` governs attribution now.

## Contents

### `multi-model-pilot-001/`

The pilot run itself. Every file is reproduced byte-for-byte from the source branch
and is exempt from style linting via a local `.markdownlint.yml` — see that file for
why.

| File | What it is |
| --- | --- |
| `multi-model-pilot-001.yaml` | Run parameters — contributor set, roles, render modes, gate config |
| `contrib-claude.md` | Contributor output (external-cli transport) |
| `contrib-codex.md` | Contributor output (external-cli transport) |
| `contrib-qwen3.md` | Contributor output (hermes-chat transport) |
| `contrib-devstral2.md` | Contributor output (hermes-chat transport) |
| `multi-model-pilot-001-synthesis.md` | Round-2 synthesis: coverage table, disposition record over all received claims, consensus, divergent points, unique insights, recommended action |
| `multi-model-pilot-001-gate.md` | Gate verdict, round 1 |
| `multi-model-pilot-001-gate-r2.md` | Gate verdict, round 2 |
| `multi-model-pilot-001-gate-r3.md` | Gate verdict, round 3 — final verdict `PROCEED` |

The four contributor outputs are retained specifically because the synthesis's
disposition record cites each of them per claim. Removing them would leave 59 dangling
references and make the synthesis untraceable — the property it exists to demonstrate.

There are three gate verdicts because the first two returned `CONDITIONAL` with
specific issues to resolve. That progression is itself part of the evidence: it shows
the bounded revision cycle working, rather than a gate rubber-stamping on first pass.

## What this run demonstrated

Four contributors across two invocation transports, producing structured output
against a shared contract; a synthesis that preserved disagreement rather than
averaging it; and an independent gate evaluator — a model that participated in no
contributor slot — returning a verdict over three rounds.

The specific findings that survived extraction are recorded in the specifications and
ADRs that cite this directory. The value of keeping the raw run is that those
documents can be checked against something that actually happened.
