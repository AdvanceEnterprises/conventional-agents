#!/usr/bin/env bats
# FS-0043 — boundary-aware cron attribution enforcement (issue #187)
#
# These fixtures use real Git commits and explicit author/committer timestamps.
# The audit must grandfather history at or before the boundary, require a
# terminal mode=autonomous marker after it, and never mutate the repository.

LINT_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/cross-repo-lint.sh"
BOUNDARY="2026-10-03T00:00:00Z"

# The script ships empty actor-email defaults (FS-0047 SC-9): the framework
# instance configures its allowlists explicitly. These fixtures plant cron
# commits as hermes-cron@advance.enterprises, so the harness exports the same set
# the instance tooling uses.
export AGENT_EMAILS="hermes-agent@advance.enterprises hermes-cron@advance.enterprises codex@advance.enterprises codex-cron@advance.enterprises claude-code@advance.enterprises github.marten@fwd.mtnden.org"
export CRON_AGENT_EMAILS="hermes-cron@advance.enterprises codex-cron@advance.enterprises"

build_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans" "$repo/docs/decisions"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Joey Clark"
  git -C "$repo" config user.email "administrator@ajoeofalltrades.dev"
  printf '# Specs\n' > "$repo/docs/specifications/README.md"
  printf '# Plans\n' > "$repo/docs/change-plans/README.md"
  printf '# Decisions\n' > "$repo/docs/decisions/README.md"
  printf 'baseline\n' > "$repo/baseline.txt"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "chore: baseline"
}

plant_cron_commit() {
  local repo="$1" date="$2" message="$3" file="$4"
  local msgfile="$BATS_TEST_TMPDIR/cron-message"
  printf '%s\n' "$message" > "$msgfile"
  printf 'cron content for %s\n' "$file" > "$repo/$file"
  git -C "$repo" add -A
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git -C "$repo" -c user.name="Hermes Agent (cron)" \
      -c user.email="hermes-cron@advance.enterprises" commit -q -F "$msgfile"
}

plant_human_commit() {
  local repo="$1" file="$2"
  printf 'human content\n' > "$repo/$file"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "feat: attended change"
}

run_lint() {
  local repo="$1"
  local boundary="${2:-$BOUNDARY}"
  local range
  range="$(git -C "$repo" rev-parse HEAD~1)..$(git -C "$repo" rev-parse HEAD)"
  run env CA_TARGET_REPO="$repo" COMMIT_RANGE="$range" \
    CRON_ATTRIBUTION_BOUNDARY="$boundary" bash "$LINT_SCRIPT"
}

cron_trailer() {
  local mode="$1"
  if [ "$mode" = "autonomous" ]; then
    printf '%s' 'Agent-Attribution: actor=hermes-agent; model=provider/model; role=Implementer; session=cron-fixture; mode=autonomous'
  else
    printf '%s' 'Agent-Attribution: actor=hermes-agent; model=provider/model; role=Implementer; session=cron-fixture'
  fi
}

@test "post-boundary cron commit without marker fails" {
  local repo="$BATS_TEST_TMPDIR/post-boundary-missing"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-03T01:00:00Z" "feat: missing autonomous marker

$(cron_trailer missing)" "post.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cron attribution missing terminal mode=autonomous"
  ! echo "$output" | grep -qF "grandfathered"
}

@test "post-boundary cron commit with terminal marker passes" {
  local repo="$BATS_TEST_TMPDIR/post-boundary-pass"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-03T01:00:00Z" "feat: autonomous marker

$(cron_trailer autonomous)" "pass.txt"

  run_lint "$repo"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "cron boundary enforced"
  ! echo "$output" | grep -qF "missing terminal mode=autonomous"
}

@test "mode marker in the middle of the trailer is not terminal" {
  local repo="$BATS_TEST_TMPDIR/middle-marker"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-03T01:00:00Z" "feat: non-terminal marker

Agent-Attribution: actor=hermes-agent; model=provider/model; role=Implementer; session=cron-fixture; mode=autonomous; extra=value" "middle.txt"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "wrong format"
  echo "$output" | grep -qF "cron attribution missing terminal mode=autonomous"
}

@test "pre-boundary cron commit is grandfathered" {
  local repo="$BATS_TEST_TMPDIR/pre-boundary"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-02T23:59:59Z" "feat: historical cron shape

$(cron_trailer missing)" "old.txt"

  run_lint "$repo"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "cron attribution grandfathered"
  ! echo "$output" | grep -qF "missing terminal mode=autonomous"
}

@test "interactive agent behavior is unchanged" {
  local repo="$BATS_TEST_TMPDIR/interactive"
  build_repo "$repo"
  printf 'interactive content\n' > "$repo/interactive.txt"
  git -C "$repo" add -A
  GIT_AUTHOR_DATE="2026-10-03T01:00:00Z" GIT_COMMITTER_DATE="2026-10-03T01:00:00Z" \
    git -C "$repo" -c user.name="Hermes Agent" \
      -c user.email="hermes-agent@advance.enterprises" commit -q -m "feat: interactive agent without autonomous marker"

  run_lint "$repo"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "missing Agent-Attribution trailer"
  ! echo "$output" | grep -qF "missing terminal mode=autonomous"
}

@test "invalid boundary fails loudly" {
  local repo="$BATS_TEST_TMPDIR/invalid-boundary"
  build_repo "$repo"
  plant_human_commit "$repo" "human.txt"

  run_lint "$repo" "not-a-boundary"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "invalid CRON_ATTRIBUTION_BOUNDARY"
}

@test "date-only boundary is rejected instead of delegated to date parsing" {
  local repo="$BATS_TEST_TMPDIR/date-only-boundary"
  build_repo "$repo"
  plant_human_commit "$repo" "human.txt"

  run_lint "$repo" "2026-10-03"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "invalid CRON_ATTRIBUTION_BOUNDARY"
}

@test "cron enforcement is report-only" {
  local repo="$BATS_TEST_TMPDIR/read-only"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-03T01:00:00Z" "feat: bad but readable

$(cron_trailer missing)" "readonly.txt"
  local before after
  before="$(git -C "$repo" rev-parse HEAD^{tree})"

  run_lint "$repo"

  after="$(git -C "$repo" rev-parse HEAD^{tree})"
  [ "$status" -ne 0 ]
  [ "$before" = "$after" ]
}

@test "an unreadable cron timestamp fails closed instead of grandfathering" {
  local repo="$BATS_TEST_TMPDIR/unreadable-timestamp"
  local fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  build_repo "$repo"
  plant_cron_commit "$repo" "2026-10-03T01:00:00Z" "feat: unreadable timestamp

$(cron_trailer missing)" "unreadable.txt"
  local real_git
  real_git="$(command -v git)"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/git" <<EOF
#!/usr/bin/env bash
# Shim used only by this fixture: make committer-time (%ct) lookups return an
# empty value so the audit's numeric validation must reject the commit,
# exercising the fail-closed branch (Kimi K2.7 finding 1, PR #206). Only the
# format pattern %ct is intercepted; every other invocation (init, add,
# commit, rev-parse, trailer reads) passes through to the real binary.
for arg in "\$@"; do
  case "\$arg" in
    *%ct*)
      exit 0
      ;;
  esac
done
exec "$real_git" "\$@"
EOF
  chmod +x "$fake_bin/git"

  local range
  range="$(git -C "$repo" rev-parse HEAD~1)..$(git -C "$repo" rev-parse HEAD)"
  run env PATH="$fake_bin:$PATH" CA_TARGET_REPO="$repo" COMMIT_RANGE="$range" \
    CRON_ATTRIBUTION_BOUNDARY="$BOUNDARY" bash "$LINT_SCRIPT"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "cron attribution timestamp unreadable"
  ! echo "$output" | grep -qF "grandfathered"
}
