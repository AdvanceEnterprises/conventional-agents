# Research and evidence

Preserved research material supporting this repository's architecture. Nothing
here is a governed document: the framework's document lifecycle gate covers FS,
PLAN, and ADR status under `docs/specifications/`, `docs/change-plans/`, and
`docs/decisions/`. These files are evidence, and are kept unedited where they
are other parties' outputs.

## Contents

| Path | What it is |
| --- | --- |
| `architecture-evidence.md` | The architecture's research synthesis: verified constraints, agreed directions, and open questions, separated. Written alongside `docs/ARC42.md`. |
| `model-drafts/` | Five arc42 candidate drafts (four independently drafted; the fifth discloses prior exposure to PR #1), a frozen brief, a provenance README, and the Head Architect's claim-by-claim reconciliation worksheet. |
| `reviews/` | Archived independent model reviews of the governed-surface PR (#4) and the first ADR/FS PR (#6), with their brief and provenance notes. |

## Reading order

For the architecture itself, start at [`docs/operations/ARC42.md`](../operations/ARC42.md) — that is
the synthesis. Come here afterwards for the material behind it:

1. `architecture-evidence.md` — what is verified versus assumed.
2. `model-drafts/RECONCILIATION.md` — how the five candidates were compared, and
   which claims were kept, refined, rejected, or deferred.
3. `model-drafts/` and `reviews/` — the raw inputs, preserved as written.

## Preservation policy

Raw model outputs are kept **byte-for-byte**. They are not reformatted, and
they carry known Markdown lint findings by design; each evidence directory has
its own `.markdownlint.yml` disabling exactly the rules those files violate, so
the relaxation cannot hide a defect in a governed document.

## Caveats worth knowing before citing these files

- **Independence is bounded.** In `model-drafts/`, the Claude Opus candidate had
  prior exposure to an earlier architecture draft, and in `reviews/`, the
  Minimax reviewer read the Kimi reviewer's output after writing its own. Each
  README states its own limits; where they say "reached independently," read it
  as scoped to the specific claim and disclosure given there.
- **Some provenance claims are reviewer self-report.** Where an archived review
  says it ran a gate and got a particular exit code, that is what the review
  file reports, not something this archive re-verified.
- **Reviewer findings are not accepted decisions.** A finding is input to a
  human decision. Dispositions live with the PR or issue that acted on them, and
  the accepted outcomes live in `docs/decisions/` and `docs/specifications/`.
