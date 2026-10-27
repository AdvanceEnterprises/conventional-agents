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
sub-header so the dedupe rule still treats the PR as reviewed exactly once by M.

## Trace comment format

Post a single PR comment line per model per changed head:

```text
### Kimi K2.7 delta re-review on c44fcdc: pass — no new findings
```

The line MUST contain:

- A level-three sub-header beginning with the model name and the literal words
  `delta re-review`.
- The full 40-character commit SHA of the head that was re-reviewed.
- A colon.
- A verdict of `pass`, `warn`, or `fail`.
- An optional dash and one-line rationale.

The exact regex used by the tick digest parser is:

```text
^### ([^\n]+?) delta re-review on ([0-9a-f]{40}): (pass|warn|fail)(\s*-\s*(.*))?$
```

## Procedure

1. Detect the previous review comment from M on the PR and extract its SHA.
2. Compare with the current PR head.
3. If they differ, run the delta review.
4. Post the trace comment using the format above.
5. If a trace for the same model and the same SHA already exists, skip posting.

## Failure modes

- If the review packet cannot be reconstructed, post:
  `### M delta re-review on <sha>: skipped — review packet unavailable`.
- If the head changed but the re-review did not complete, do not transition the
  PR to ready; flag it for human decision.

## Attribution

The trace comment is attributed to the reviewing model. If the comment is posted
by an implementer session on behalf of the reviewer, the implementing commit
must carry an `Agent-Attribution:` trailer naming the reviewer model and the
review round.

## Related conventions

- `guidelines/ROLE_CONTRACT.md` § reviewer role — in-cycle re-review obligation.
- `workflows/session-modes.md` § autonomous and consensus modes — when to post
  a trace comment.
- `FS-0057` — governing feature spec.
