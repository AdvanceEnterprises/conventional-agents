#!/usr/bin/env bats
# FS-0017 — attribution diagnostic: MISSING vs MALFORMED (issue #154)
#
# The trailer gate counts in-scope offender commits and reports each. Before
# #154, both failure modes produced the word "missing", so a commit whose
# trailer was syntactically present but unreachable by git's trailer parser
# (blank-line-separated, or displaced by a following paragraph) was
# indistinguishable from one that had no trailer at all. The two need
# opposite responses.
#
# These cases build a scratch repository, plant exactly one offender commit,
# and assert on the script's diagnosis plus its exit code. The failing set is
# the invariant: a malformed-trailer commit must still fail the gate.

LINT_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/cross-repo-lint.sh"

# A scratch repository with the minimum cross-repo-lint needs to reach check 1:
# a resolvable default branch. The doc checks (2/3) pass trivially on the empty
# docs tree; scope each case to the attribution check's own output.
build_scratch_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans" "$repo/docs/decisions"
  ( cd "$repo" && git init -q -b trunk )
  # Repo-local identity (not -c overrides): the human-commit scope case below
  # overrides the identity inline, which takes precedence over this config.
  git -C "$repo" config user.name "Hermes Agent (cron)"
  git -C "$repo" config user.email "hermes-cron@tais-den.dev"
  printf '# Specs\n' > "$repo/docs/specifications/README.md"
  printf '# Plans\n' > "$repo/docs/change-plans/README.md"
  printf '# Decisions\n' > "$repo/docs/decisions/README.md"
}

# Baseline commit so the audited range has a parent.
seed_commit() {
  local repo="$1"
  printf 'baseline\n' > "$repo/baseline.txt"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "chore: baseline"
}

# Plant a commit authored by an agent identity, with the given message body.
# $2 is the full message (subject line first, then whatever follows); $3 names
# the file the commit touches.
plant_agent_commit() {
  local repo="$1" message="$2" file="$3"
  local msgfile="$BATS_TEST_TMPDIR/commit-msg"
  printf '%s\n' "$message" > "$msgfile"
  printf 'content for %s\n' "$file" > "$repo/$file"
  git -C "$repo" add -A
  git -C "$repo" commit -q -F "$msgfile"
}

# Run the attribution check scoped to the fixture repo.
run_lint() {
  local repo="$1"
  run env CA_TARGET_REPO="$repo" COMMIT_RANGE="$(git -C "$repo" rev-parse HEAD~1)..$(git -C "$repo" rev-parse HEAD)" \
    bash "$LINT_SCRIPT"
}

# --- positive control ----------------------------------------------------------

@test "positive control: an agent commit with no trailer reports MISSING" {
  local repo="$BATS_TEST_TMPDIR/missing"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: a commit with no trailer at all" "a.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing Agent-Attribution trailer"
}

@test "positive control: the pre-#154 wording cannot distinguish the two modes" {
  # Proves the failure mode is real: a trailer with a following paragraph
  # yields an empty trailer-parser result, exactly as a genuinely absent one
  # does. (A trailer that is merely preceded by a blank line still parses — git
  # treats the final paragraph as the trailer block — so the displacing
  # paragraph, or a wrapped value, is what makes a trailer invisible.)
  local repo="$BATS_TEST_TMPDIR/raw"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: displaced trailer

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=conventional-agents-maintenance

Co-Authored-By: Someone <someone@example.com>
" "b.txt"

  local sha parsed body_has
  sha="$(git -C "$repo" rev-parse HEAD)"
  parsed="$(git -C "$repo" log -1 --format='%(trailers:key=Agent-Attribution,only)' "$sha" | tr -d '\n')"
  body_has="$(git -C "$repo" log -1 --format=%B "$sha" | grep -c '^Agent-Attribution:' || true)"

  [ -z "$parsed" ]
  [ "$body_has" -gt 0 ]
}

# --- the fix -------------------------------------------------------------------

@test "malformed: a body-present trailer the parser ignores reports MALFORMED" {
  local repo="$BATS_TEST_TMPDIR/malformed"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  # Trailer present, but a following Co-authored-by: paragraph keeps it out of
  # the final block — git's trailer parser never sees it.
  plant_agent_commit "$repo" "feat: displaced trailer

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=conventional-agents-maintenance

Co-Authored-By: Someone <someone@example.com>
" "c.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "malformed Agent-Attribution trailer"
  ! echo "$output" | grep -qF "missing Agent-Attribution trailer"
}

@test "missing: a genuinely absent trailer is not reported as malformed" {
  local repo="$BATS_TEST_TMPDIR/absent"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: nothing resembling a trailer" "d.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing Agent-Attribution trailer"
  ! echo "$output" | grep -qF "malformed Agent-Attribution trailer"
}

@test "malformed: a trailer wrapped across continuation lines reports MALFORMED" {
  local repo="$BATS_TEST_TMPDIR/wrapped"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  # The second confirmed shape from the trunk audit: the trailer starts, but its
  # value wraps onto the next line, so the line is not a trailer at all —
  # git's parser returns empty while the body plainly shows the string.
  plant_agent_commit "$repo" "feat: wrapped trailer

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash;
role=implementer; session=conventional-agents-maintenance
" "e.txt"

  # Sanity: the parser really does miss it while the body carries it.
  local sha
  sha="$(git -C "$repo" rev-parse HEAD)"
  [ -z "$(git -C "$repo" log -1 --format='%(trailers:key=Agent-Attribution,only)' "$sha" | tr -d '\n')" ]
  [ "$(git -C "$repo" log -1 --format=%B "$sha" | grep -c '^Agent-Attribution:' || true)" -gt 0 ]

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "malformed Agent-Attribution trailer"
}

@test "well-formed: a correctly placed trailer passes and the check says OK" {
  local repo="$BATS_TEST_TMPDIR/wellformed"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  # Trailer block: no blank line before it, nothing after it.
  plant_agent_commit "$repo" "feat: a conforming commit

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=conventional-agents-maintenance
" "f.txt"

  run_lint "$repo"

  echo "$output" | grep -qF "OK"
  ! echo "$output" | grep -qF "BAD"
}

@test "well-formed: a mode= trailer (ADR-0021) also passes" {
  local repo="$BATS_TEST_TMPDIR/mode"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: autonomous actor

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=conventional-agents-maintenance; mode=autonomous
" "g.txt"

  run_lint "$repo"

  echo "$output" | grep -qF "OK"
  ! echo "$output" | grep -qF "BAD"
}

@test "range: a null-hash endpoint fails closed instead of auditing zero commits (issue #194)" {
  # The endpoint-wise check resolved each endpoint separately; the null object
  # hash passes `rev-parse --verify` but `rev-list "<null>..HEAD"` fails, so the
  # audit loop iterated nothing and printed OK. That is exactly the range shape
  # GitHub produces for github.event.before on a new-branch push. The whole
  # range must resolve.
  local repo="$BATS_TEST_TMPDIR/nullrange"
  build_scratch_repo "$repo"
  seed_commit "$repo"

  run env CA_TARGET_REPO="$repo" COMMIT_RANGE="0000000000000000000000000000000000000000..HEAD" \
    bash "$LINT_SCRIPT"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "unavailable locally"
  ! echo "$output" | grep -qF "OK   "
}

@test "range: an empty but resolvable range still audits nothing and passes (caller's declaration)" {
  # A == B is a legitimate declaration (a push with no new commits). Resolution
  # must distinguish it from an unresolvable range: it yields no output commits
  # without error.
  local repo="$BATS_TEST_TMPDIR/emptyrange"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  local head
  head="$(git -C "$repo" rev-parse HEAD)"

  run env CA_TARGET_REPO="$repo" COMMIT_RANGE="$head..$head" bash "$LINT_SCRIPT"

  echo "$output" | grep -qF "OK   "
  ! echo "$output" | grep -qF "unavailable locally"
}

# --- scope: human commits carry no obligation ----------------------------------

@test "scope: a human-authored commit with no trailer is not an offender" {
  local repo="$BATS_TEST_TMPDIR/human"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  printf 'human change\n' > "$repo/h.txt"
  git -C "$repo" add -A
  git -C "$repo" -c user.name="Joey Clark" -c user.email="administrator@ajoeofalltrades.dev" \
    commit -q -m "feat: human commit, no trailer expected"

  run_lint "$repo"

  echo "$output" | grep -qF "OK"
  ! echo "$output" | grep -qF "BAD"
}

@test "malformed: a displaced prose line is not classified as a trailer" {
  # The body-scan matches the canonical trailer shape (`Agent-Attribution:`
  # followed by the `actor=` key), not any line with the token. A prose
  # mention — displaced out of the trailer block, like a real offender — is
  # still a failing commit, but its remedy is "write the trailer", not
  # "move the line": it reports MISSING, not MALFORMED.
  local repo="$BATS_TEST_TMPDIR/prose"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: prose mention

Agent-Attribution: see CONTRIBUTING.md for the trailer format

Co-Authored-By: Someone <someone@example.com>
" "i.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing Agent-Attribution trailer"
  ! echo "$output" | grep -qF "malformed Agent-Attribution trailer"
}
