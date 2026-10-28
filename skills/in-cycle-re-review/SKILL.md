# Skill: In-cycle re-review trace

## When to use

Use this skill when an autonomous or consensus session has performed a new
reviewer round on a PR whose head changed after that reviewer's most recent
comment. The skill ensures the re-verification leaves a discoverable trace on
the PR without breaking the once-per-PR reviewer dedupe contract.

## Once-per-head rule

The reviewer contract considers a PR reviewed by model M when M has posted a
review comment whose header begins with the model's designated review section
(e.g. `## Kimi K2.7 Code Review`). After that, M must not post another full review
under the same header for the same PR.

When the PR head changes, M may perform a delta re-review. The result is posted
as a **trace comment**, not as a new full review. A trace comment uses a
level-three heading so the dedupe rule still treats the PR as reviewed exactly
once by M.

## Trace comment format

Post a single PR comment line per model per changed head:

```text
### Kimi K2.7 delta re-review on 3f9c1a2b4d5e6f708192a3b4c5d6e7f8091a2b3c round 2: pass — no new findings
```

The line MUST contain, in this order:

- A level-three heading (`###`) beginning with the model name and the literal
  words `delta re-review`.
- The literal word `on` followed by the full 40-character commit SHA of the head
  that was re-reviewed. Abbreviated SHAs are rejected by the parser.
- The literal word `round` followed by the decimal round number for this model on
  this PR.
- A colon.
- A verdict of `pass`, `warn`, `fail`, or `skipped`.
- An optional dash and one-line rationale. The dash may be either an ASCII
  hyphen-minus (`-`) or an em dash (`—`); both are accepted.

The exact regex used by the tick digest parser is:

```text
^### ([^\n]+?) delta re-review on ([0-9a-f]{40}) round ([0-9]+): (pass|warn|fail|skipped)(\s*[—-]\s*(.*))?$
```

Capture groups, in order: 1 = model, 2 = commit SHA, 3 = round number,
4 = verdict, 5 = the optional `- rationale` segment, 6 = its text.

### Round numbering

The round number is per model and per PR:

- Round 1 is the model's initial full review. It is posted under the full review
  header, not as a trace comment.
- The first trace comment on a head change is round 2; each further delta trace on
  the same PR increments the counter.
- A force-push that rewrites history resets the counter, because the previously
  reviewed SHA is no longer reachable. The first trace comment after such a reset
  is round 2 again.

## Procedure

1. Detect the previous review comment from M on the PR and extract its SHA.
2. Compare with the current PR head.
3. If they differ, run the delta review.
4. Derive the round number per "Round numbering" above.
5. Post the trace comment using the format above.
6. If a trace for the same model, the same SHA, and the same round already exists,
   skip posting.

## Failure modes

- If the review packet cannot be reconstructed, post:
  `### M delta re-review on <40-character-sha> round <n>: skipped — review packet unavailable`,
  substituting the full 40-character head SHA and the derived round number. A
  shortened SHA or a missing round number makes the line unparseable, and an
  unparseable trace is flagged as an exception by the tick.
- If the head changed but the re-review did not complete, do not transition the
  PR to ready; flag it for human decision.

## Attribution

The trace comment is attributed to the reviewing model. If the comment is posted
by an implementer session on behalf of the reviewer, the implementing commit
must carry an `Agent-Attribution:` trailer naming the reviewer model and the
review round.

## Related conventions

- `guidelines/ROLE_CONTRACT.md` — reviewer role. The in-cycle re-review obligation
  is declared in FS-0057's `interfaces:` and lands as a new subsection in a
  follow-up change; at this head the file has no reviewer-role section to cite.
- `workflows/session-modes.md` § Meta-Modes: Autonomous and Consensus — the
  trace-posting step lands as a new subsection in the same follow-up change.
- `FS-0057` — governing feature spec. Both follow-up edits above are blocked
  until FS-0057 leaves `draft`.
