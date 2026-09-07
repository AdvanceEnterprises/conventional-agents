---
updated: 2026-09-05
---

# Skill Authoring — the framework's profile of Agent Skills

`SKILL.md` is not a `conventional-agents` invention. It is **Agent Skills**, an
open standard at [agentskills.io/specification](https://agentskills.io/specification),
implemented by ~45 agent products — including Claude Code, Codex CLI, and the two
dominant self-hosted runtimes, Hermes Agent and OpenClaw.

**The framework profiles that standard; it does not define a format.** `ADR-0038`
records the decision. This document is the profile: the authoring rules that are
the framework's own, distinct from the spec's structural requirements.

## The spec is authoritative for structure

The agentskills.io specification governs `SKILL.md` frontmatter, its typing, and
directory layout. Where a framework skill and the spec disagree on structure, the
spec wins and the skill is the defect. In particular:

- Frontmatter fields are only those the spec defines: `name` and `description`
  (both **required**), plus the optional `license`, `compatibility`, `metadata`,
  and `allowed-tools`. Nothing else is valid at the top level.
- `version` and `author` go **under `metadata:`** as string values, or are
  dropped where they carry no information.
- A genuine environment requirement goes in **`compatibility`** (max 500
  characters), not in `metadata`. A client reading `compatibility` to decide
  whether a skill can run will not consult a `metadata.platforms` key. Most
  skills need neither — omit both rather than asserting a constraint that is not
  real.
- `metadata` is a flat map of string keys to string values — no nested maps, no
  arrays.
- Runtime-specific frontmatter (Hermes's `metadata.hermes.*`, OpenClaw's
  `metadata.openclaw.*`, any future Codex convention) is **never** committed to
  `skills/*/SKILL.md`. A runtime binding under `integrations/runtimes/` applies
  the dialect at sync time (`ADR-0038` rule 5, `ADR-0039`). Source stays portable
  to every runtime and to the claude.ai Skills API.
- Every `related_skills` entry and every prose cross-reference names a skill that
  exists in this repository and appears in `skills/index.md`.

## The framework's authoring rules

Carried forward from `ADR-0001` and owned here:

1. **Standalone-useful.** A skill must be actionable when loaded alone — it
   includes operational procedures and at least two runnable examples.
   **Exemption:** a deprecated router that exists only to point consumers at
   successor skills (e.g. `skills/git-gh-workflow/SKILL.md` after the
   `git-gh-workflow` split) is exempt — it teaches nothing and is not meant to;
   a router that carried examples would compete with the skills it points at.
2. **Compliance-aware, non-exhaustive.** A short, clearly labelled summary of key
   gates, plus links to canonical sources (`guidelines/ROLE_CONTRACT.md`, the
   relevant `guidelines/`). Never the full universal gate list.
3. **Minimum content checklist.** When-to-use; compliance references; at least
   two runnable examples; a copy-paste-friendly checklist; a common-pitfalls
   section.
4. **Size signal.** The main `SKILL.md` stays under ~400 lines (the framework's
   number; the spec recommends under 500). What to do when it does not depends on
   *why* it is long:
   - **One topic that ran long.** The overflow is depth on a single subject. Move
     it into the spec's optional `references/` directory and keep one skill.
     Do **not** split: fracturing a coherent topic to hit a line count leaves
     every fragment less useful than the whole was, and rule 1 then fails on all
     of them.
   - **Several topics sharing a file.** The length is a symptom, not the defect —
     the skill is really N skills bundled, and each would satisfy rules 1–3
     standing alone. Split on the topic boundaries and give each successor a
     `description` that says when to reach for it rather than for its siblings.

   The test is whether a reader who needs one part reliably needs the others. If
   yes, it is one topic — use `references/`. If no, it was a bundle — split it.
   **Size alone never justifies a split**, and cohesion always justifies one
   regardless of size.
5. **No duplicate gates.** A skill summarises and links; it does not restate
   `guidelines/ROLE_CONTRACT.md`. Where another skill already owns a gate's full
   statement, link to that skill rather than repeating it: two skills expanding
   the same rule is the drift `ADR-0030` exists to prevent.

> Rule 4's two cases were separated after an earlier single-sentence form ("not
> into a second skill") was read as forbidding the `git-gh-workflow` split that
> `ADR-0038` rule 7 sanctions. Both readings were defensible against the old
> wording, which is the defect. The rule now turns on cohesion rather than on
> line count, so the two documents agree.

## Conformance

Adopting a conformance validator (`skills-ref validate` or equivalent) as a
merge-blocking CI check is a Category 1 governance gate under `ADR-0015` and
needs its own approved FS and PLAN and a home in `scripts/`. `claude plugin
validate` is a Claude-plugin check, not the cross-runtime Agent Skills
conformance gate.

## Adding a skill

1. Create `skills/<topic>/SKILL.md`. `name` and `description` are both required.
   `name` must equal the directory name — lowercase `a-z`, `0-9`, and hyphens
   only, with no leading, trailing, or consecutive hyphen.
2. Write `description` to say both **what** the skill does and **when** to use
   it, carrying the keywords an agent would search for. It is the only field the
   spec loads at startup for every skill, so it is the entire discovery surface:
   a skill nobody retrieves is a skill nobody runs.
3. Follow the rules above and the spec.
4. Add a row to `skills/index.md`.
5. Do not add a runtime dialect to the source file — that is a binding's job.
