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

# The script ships empty actor-email defaults (FS-0047 SC-9): the framework
# instance configures its allowlists explicitly. The scratch repos below
# author commits under these identities, so the diagnostic harness exports
# the same set the instance tooling uses.
export AGENT_EMAILS="hermes-agent@advance.enterprises hermes-cron@advance.enterprises codex@advance.enterprises codex-cron@advance.enterprises claude-code@advance.enterprises github.marten@fwd.mtnden.org"
export CRON_AGENT_EMAILS="hermes-cron@advance.enterprises codex-cron@advance.enterprises"

# A scratch repository with the minimum cross-repo-lint needs to reach check 1:
# a resolvable default branch. The doc checks (2/3) pass trivially on the empty
# docs tree; scope each case to the attribution check's own output.
build_scratch_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans" "$repo/docs/decisions"
  ( cd "$repo" && git init -q -b trunk )
  # Repo-local identity (not -c overrides): the human-commit scope case below
  # overrides the identity inline, which takes precedence over this config.
  git -C "$repo" config user.name "Hermes Agent"
  git -C "$repo" config user.email "hermes-agent@advance.enterprises"
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
  # Give the scratch repo a synthetic origin/trunk so default-range tests can
  # resolve the script's fallback without a real remote.
  git -C "$repo" update-ref refs/remotes/origin/trunk HEAD
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
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
  # Assert on the check-1 success line for THIS repo by its structural shape
  # (OK + repo name), not a prose phrase — robust to summary rewording while
  # still guarding the exact failure mode: pre-fix, the audit loop iterated
  # zero commits and printed its per-repo OK line.
  ! echo "$output" | grep -qE "OK[[:space:]]+nullrange"
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

  [ "$status" -eq 0 ]
  echo "$output" | grep -qE "OK[[:space:]]+emptyrange"
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

# --- shallow-clone guard (issue #221) ------------------------------------------

# Run the attribution check with the script's default range resolution, not
# an explicit COMMIT_RANGE, so the shallow-clone guard is exercised.
run_lint_default_range() {
  local repo="$1"
  run env CA_TARGET_REPO="$repo" bash "$LINT_SCRIPT"
}

# Plant N human commits so origin/trunk~20 resolves when the repo is not shallow.
seed_many_commits() {
  local repo="$1" n="${2:-21}" i
  for (( i=0; i<n; i++ )); do
    printf 'content %d\n' "$i" > "$repo/many-$i.txt"
    git -C "$repo" add -A
    git -C "$repo" -c user.name="Joey Clark" -c user.email="administrator@ajoeofalltrades.dev" \
      commit -q -m "chore: many baseline $i"
  done
  # Tests that rely on the script's default range need a synthetic origin/trunk
  # because the repo is a local scratch with no real remote.
  git -C "$repo" update-ref refs/remotes/origin/trunk HEAD
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
}

@test "shallow clone with no reachable anchor fails closed (issue #221)" {
  local source="$BATS_TEST_TMPDIR/shallow-source"
  local shallow="$BATS_TEST_TMPDIR/shallow-clone"
  build_scratch_repo "$source"
  seed_commit "$source"
  # A few agent commits so the repo has real history, but no release tags and
  # no ATTRIBUTION_MIN_ANCHOR floor (v2.1.0 does not exist here).
  plant_agent_commit "$source" "feat: first agent change

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=shallow-fixture" "s1.txt"
  plant_agent_commit "$source" "feat: second agent change

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=shallow-fixture" "s2.txt"

  git clone -q --no-local --depth 1 "file://$source" "$shallow"
  # Keep the fixture deterministic across Git versions: the shallow marker is
  # the state under test, so make it explicit even if a local file transport
  # elects not to honor --depth.
  git -C "$shallow" rev-parse HEAD > "$shallow/.git/shallow"

  run_lint_default_range "$shallow"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "repository is shallow"
  echo "$output" | grep -qF "git fetch --unshallow"
  # The vacuous OK line from the pre-fix shape must not appear.
  ! echo "$output" | grep -qE "OK[[:space:]]+shallow-clone"
}

@test "non-shallow repo with no anchor falls back to ~20 and passes" {
  local repo="$BATS_TEST_TMPDIR/non-shallow-fallback"
  build_scratch_repo "$repo"
  seed_many_commits "$repo" 22

  run_lint_default_range "$repo"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qE "OK[[:space:]]+non-shallow-fallback"
}

@test "explicit COMMIT_RANGE on shallow clone bypasses the guard" {
  local source="$BATS_TEST_TMPDIR/explicit-source"
  local shallow="$BATS_TEST_TMPDIR/explicit-shallow"
  build_scratch_repo "$source"
  seed_commit "$source"
  plant_agent_commit "$source" "feat: agent change

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=explicit-fixture" "e1.txt"

  git clone -q --depth 1 "file://$source" "$shallow"

  local head
  head="$(git -C "$shallow" rev-parse HEAD)"
  run env CA_TARGET_REPO="$shallow" COMMIT_RANGE="$head..$head" bash "$LINT_SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qE "OK[[:space:]]+explicit-shallow"
  ! echo "$output" | grep -qF "repository is shallow"
}

@test "unknown shallow state fails closed" {
  local repo="$BATS_TEST_TMPDIR/unknown-shallow"
  build_scratch_repo "$repo"
  seed_commit "$repo"
  plant_agent_commit "$repo" "feat: agent change

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=unknown-fixture" "u1.txt"

  # Run the script from the same Bash process as the shim. This avoids
  # PATH/BASH_ENV differences between GitHub runner images while preserving
  # the real Git command for every operation except the probe under test.
  run env CA_TARGET_REPO="$repo" bash -c '
_git_real() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --is-shallow-repository)
        return 1
        ;;
    esac
  done
  command git "$@"
}
git() {
  _git_real "$@"
}
. "$1"
' "$LINT_SCRIPT" "$LINT_SCRIPT"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot determine whether the repository is shallow"
}
