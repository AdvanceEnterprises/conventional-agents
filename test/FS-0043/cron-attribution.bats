#!/usr/bin/env bats
# FS-0043 — boundary-aware cron attribution enforcement (issue #187)
#
# These fixtures use real Git commits and explicit author/committer timestamps.
# The audit must grandfather history at or before the boundary, require a
# terminal mode=autonomous marker after it, and never mutate the repository.

LINT_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/cross-repo-lint.sh"
BOUNDARY="2026-10-03T00:00:00Z"

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
      -c user.email="hermes-cron@tais-den.dev" commit -q -F "$msgfile"
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
      -c user.email="hermes-agent@tais-den.dev" commit -q -m "feat: interactive agent without autonomous marker"

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
