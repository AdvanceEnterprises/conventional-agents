# Independent arc42 candidates (comparison evidence)

The Head Architect's [reconciliation worksheet](RECONCILIATION.md) is a
separately authored comparison and decision queue. It does not edit or
endorse any candidate; the synthesis that followed it is
[`docs/ARC42.md`](../../ARC42.md), merged from PR #2.

The original four files are **raw, unadopted candidate drafts**, not
architectures to merge or independent approvals. They are comparison
evidence for the synthesis, not the canonical `docs/ARC42.md`.

All four received the same frozen [brief](BRIEF.md), bootstrap `trunk` at
`e322e5258b8a6f0e66c956eb0f677a266b907dfb`, pinned conventional-agents
at `94b784aa022b715bf7dad331a714f786620f961a`, and the
[PR #1 research memo](https://github.com/AdvanceEnterprises/collective-agents/blob/6d2a94b44545be0aec072c45e3f8bfe83067ed38/docs/research/engine-boundary-and-failure-modes.md).
They were instructed not to read either PR #1 or PR #2's arc42 draft, or one
another's output. Independence beyond this instruction was not technically
enforced: the read-only source checkout and output directory were shared.
Treat self-reported reading discipline as such.

| File | Requested and routed provider/model | Execution receipt |
| --- | --- | --- |
| [minimax-m3.md](minimax-m3.md) | `ollama-cloud` / `minimax-m3` | File verified; authoring run hit its turn limit after writing |
| [kimi-k2.7-code.md](kimi-k2.7-code.md) | `ollama-cloud` / `kimi-k2.7-code` | File verified; authoring run hit its turn limit after writing |
| [deepseek-v4.1-flash.md](deepseek-v4.1-flash.md) | `ollama-cloud` / `deepseek-v4.1-flash` | Resumed the same session after an initial turn-limit stop; file verified |
| [gpt-6-astra.md](gpt-6-astra.md) | `openai-codex` / `gpt-6-astra` | Hostops call timed out without a final receipt; subsequently verified the complete-looking, model-identified file on disk; no session completion claim |

Reasoning levels were **not overridden**; the configured level for each route
applied, per the human's revised instruction. This is not a controlled
comparison of equal compute. No model draft is endorsed or corrected here.
In particular, competing claims about approval/Phase transitions or
exactly-once publication must be checked against the pinned contract and
fault-tested rather than voted into the architecture.

The drafting instructions used an absolute `/workspace/` path as a local
source location; any such path in a raw draft is provenance, not a portable
dependency. Files are preserved byte-for-byte from their model outputs.
Source memo is linked rather than copied here; it remains background
evidence, not normative architecture.

## Later addition: Claude Opus 5.5 (outside the routed run)

[claude-opus-5-5.md](claude-opus-5-5.md) was added on 2026-09-28 at the
human's request, by `anthropic/claude-opus-5-5` in Claude Code, against
the same frozen brief and pinned sources. It differs from the four
routed drafts in ways that matter for comparison:

- **Not independent of PR #1's arc42.** The same session wrote PR #1's
  `docs/ARC42.md` and research memo earlier (under Claude Sonnet 5) and
  saw an external review of PR #1, so the brief's exclusion of PR #1's
  arc42 could not be honoured in substance. The draft was written from
  scratch without copying or reopening that file.
- **Did not read** PR #2 or any of the four drafts above.
- **Not byte-for-byte raw.** Unlike the four above, it was self-edited
  before commit: citations were re-checked against the memo and ADR
  front matter, and it was made lint-clean. It remains unendorsed and
  unreconciled.
- **Committed by the drafting session** at the human's request, rather
  than archived by an orchestrator; the brief's no-commit instruction
  addressed the routed runs.
