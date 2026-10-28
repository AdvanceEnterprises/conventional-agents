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
# an explicit COMMIT_RANGE, so the shallow-clone guard is exercised. The
# ambient range is cleared explicitly: the `validation` CI job exports
# COMMIT_RANGE (lint-docs.yml), and the script's explicit-range escape hatch
# would otherwise short-circuit the guard before it runs — the fixture then
# asserts against a code path it never reached (PR #255 review round B).
run_lint_default_range() {
  local repo="$1"
  run env -u COMMIT_RANGE CA_TARGET_REPO="$repo" bash "$LINT_SCRIPT"
}

# Exercise the guard with a deterministic probe result. The real shallow clone
# is still created and asserted below, but the guard's `git rev-parse` result is
# injected in the same Bash process so Git transport/version differences cannot
# turn the fixture into a vacuous fallback test. Each probe is recorded so the
# test can assert it targeted the repo under audit: without that assertion a
# guard that drops -C "$REPO" (probing the caller CWD) passes unchanged.
run_lint_with_shallow_state() {
  local repo="$1" state="$2" probe_log="$BATS_TEST_TMPDIR/shallow-probe.log"
  run env -u COMMIT_RANGE CA_TARGET_REPO="$repo" CA_TEST_SHALLOW_STATE="$state" \
    CA_TEST_PROBE_LOG="$probe_log" LINT_SCRIPT="$LINT_SCRIPT" bash -c '
_git_shim() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --is-shallow-repository)
        # Record the probe argv verbatim: the target assertion below depends
        # on seeing the -C <repo> the guard is expected to pass.
        printf "%s\n" "$*" >> "$CA_TEST_PROBE_LOG"
        printf "%s\n" "$CA_TEST_SHALLOW_STATE"
        return 0
        ;;
    esac
  done
  command git "$@"
}
git() {
  _git_shim "$@"
}
. "$LINT_SCRIPT"
'
}

# The guard must read the shallow state of the repository under audit, not of
# whatever directory the lint harness happens to run from (PR #255 round B).
assert_shallow_probe_targeted() {
  local repo="$1" probe_log="$BATS_TEST_TMPDIR/shallow-probe.log"
  [ -s "$probe_log" ] || {
    echo "no shallow-state probe was recorded at $probe_log" >&2
    return 1
  }
  grep -qF -- "-C $repo rev-parse --is-shallow-repository" "$probe_log"
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
  # Keep the fixture deterministic across Git versions: the clone must really
  # report shallow, and the guard receives that same state through the
  # in-process probe seam used by the unknown-state case below.
  [ "$(git -C "$shallow" rev-parse --is-shallow-repository)" = true ]

  run_lint_with_shallow_state "$shallow" true
  assert_shallow_probe_targeted "$shallow"

  if [ "$status" -eq 0 ]; then
    printf 'DEBUG shallow-state=true output:\\n%s\\n' "$output" >&3
  fi
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

  run_lint_with_shallow_state "$repo" unknown
  assert_shallow_probe_targeted "$repo"

  if [ "$status" -eq 0 ]; then
    printf 'DEBUG shallow-state=unknown output:\\n%s\\n' "$output" >&3
  fi
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cannot determine whether the repository is shallow"
}

@test "shallow clone that still resolves a release tag fails closed (issue #221)" {
  # The fail-open shape #221 reports: `git clone --depth N` fetches the tags
  # that point into its window, so `git describe` succeeds even when the
  # ATTRIBUTION_MIN_ANCHOR floor does not exist locally. Pre-fix the guard ran
  # only when NO anchor resolved, so the shallow clone anchored to v3.0.0 and
  # reported OK while a full clone — anchored to the v2.1.0 floor — caught the
  # offender. Shallow state is now decided before anchor selection.
  local source="$BATS_TEST_TMPDIR/tagged-source"
  local full="$BATS_TEST_TMPDIR/tagged-full"
  local shallow="$BATS_TEST_TMPDIR/tagged-shallow"
  build_scratch_repo "$source"
  seed_commit "$source"
  # The floor: resolvable only with the full history.
  git -C "$source" tag v2.1.0
  # Offender: agent-authored, no trailer, behind the release tag.
  plant_agent_commit "$source" "feat: offender behind the release tag" "t0.txt"
  printf 'release prep\n' > "$source/release.txt"
  git -C "$source" add -A
  git -C "$source" -c user.name="Joey Clark" -c user.email="administrator@ajoeofalltrades.dev" \
    commit -q -m "chore: release prep"
  git -C "$source" tag v3.0.0
  local i
  for i in 1 2 3; do
    printf 'post %d\n' "$i" > "$source/post-$i.txt"
    git -C "$source" add -A
    git -C "$source" -c user.name="Joey Clark" -c user.email="administrator@ajoeofalltrades.dev" \
      commit -q -m "chore: post-release $i"
  done

  git clone -q --no-local "$source" "$full"
  git clone -q --no-local --depth 4 "file://$source" "$shallow"

  # Reference: the offender is real — the full clone, anchored at the floor,
  # fails. Without this the case could pass vacuously on an empty range.
  run env -u COMMIT_RANGE CA_TARGET_REPO="$full" bash "$LINT_SCRIPT"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing Agent-Attribution trailer"

  [ "$(git -C "$shallow" rev-parse --is-shallow-repository)" = true ]
  # Preconditions that make this the fail-open case rather than the no-anchor
  # one: a recent release tag resolves locally while the floor does not.
  [ -n "$(git -C "$shallow" describe --first-parent --tags --match 'v*' --abbrev=0 HEAD)" ]
  ! git -C "$shallow" rev-parse --verify --quiet v2.1.0

  run_lint_with_shallow_state "$shallow" true
  assert_shallow_probe_targeted "$shallow"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ATTRIBUTION_MIN_ANCHOR"
  echo "$output" | grep -qF "git fetch --unshallow"
  ! echo "$output" | grep -qE "OK[[:space:]]+tagged-shallow"
}

@test "CA_SKIP_ATTRIBUTION=1 still reports SKIP on a shallow clone" {
  # The documented opt-out (scripts/README.md): an unconfigured instance that
  # sets CA_SKIP_ATTRIBUTION=1 gets SKIP, never a failure. The shallow guard is
  # part of the attribution audit, so it must not turn that opt-out into a hard
  # failure (PR #255 review round B).
  local source="$BATS_TEST_TMPDIR/skip-source"
  local shallow="$BATS_TEST_TMPDIR/skip-shallow"
  build_scratch_repo "$source"
  seed_commit "$source"
  plant_agent_commit "$source" "feat: agent change

Agent-Attribution: actor=hermes-agent; model=deepseek-v4.1-flash; role=implementer; session=skip-fixture" "k1.txt"

  git clone -q --no-local --depth 1 "file://$source" "$shallow"
  [ "$(git -C "$shallow" rev-parse --is-shallow-repository)" = true ]

  run env -u COMMIT_RANGE -u AGENT_EMAILS -u CRON_AGENT_EMAILS CA_SKIP_ATTRIBUTION=1 \
    CA_TARGET_REPO="$shallow" bash "$LINT_SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "SKIP"
  echo "$output" | grep -qF "CA_SKIP_ATTRIBUTION=1"
  ! echo "$output" | grep -qF "repository is shallow"
}
