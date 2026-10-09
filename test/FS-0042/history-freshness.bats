#!/usr/bin/env bats
# FS-0042 — history-aware freshness audit coverage (issue #183)

HISTORY_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-freshness-history.sh"

new_repo() {
  local repo="$1"
  mkdir -p "$repo/workflows" "$repo/guidelines"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config user.email "fixture@example.test"
}

commit_at() {
  local repo="$1" date="$2" message="$3"
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git -C "$repo" commit -q -m "$message"
}

write_doc() {
  local repo="$1" date="$2" body="$3"
  cat > "$repo/workflows/session.md" <<EOF
---
updated: $date
type: workflow
---
# Session workflow

$body
EOF
  git -C "$repo" add workflows/session.md
}

run_history() {
  local repo="$1"
  shift
  run env CA_TARGET_REPO="$repo" TZ=UTC bash "$HISTORY_SCRIPT" "$@"
}

@test "substantive history newer than updated fails strict mode" {
  local repo="$BATS_TEST_TMPDIR/substantive"
  new_repo "$repo"
  write_doc "$repo" "2026-10-01" "baseline"
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: add workflow"
  printf 'substantive edit\n' >> "$repo/workflows/session.md"
  git -C "$repo" add workflows/session.md
  commit_at "$repo" "2026-10-02T01:00:00Z" "docs: change workflow"
  cp "$repo/workflows/session.md" "$BATS_TEST_TMPDIR/substantive.before"

  run_history "$repo" --strict

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "DRIFT: workflows/session.md"
  echo "$output" | grep -qF "updated: 2026-10-01"
  echo "$output" | grep -qF "2026-10-02"
  cmp -s "$repo/workflows/session.md" "$BATS_TEST_TMPDIR/substantive.before"
  [ -z "$(git -C "$repo" status --porcelain)" ]
}

@test "freshness-only commit is diagnostic and does not fail strict mode" {
  local repo="$BATS_TEST_TMPDIR/metadata-only"
  new_repo "$repo"
  write_doc "$repo" "2026-10-01" "baseline"
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: add workflow"
  sed -i.bak 's/^updated: 2026-10-01$/updated: 2026-10-02/' "$repo/workflows/session.md"
  rm -f "$repo/workflows/session.md.bak"
  git -C "$repo" add workflows/session.md
  commit_at "$repo" "2026-10-03T01:00:00Z" "docs: refresh freshness metadata"

  run_history "$repo" --strict

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "DIAGNOSTIC: workflows/session.md"
  ! echo "$output" | grep -qF "DRIFT:"
}

@test "clean history passes when declared date is current" {
  local repo="$BATS_TEST_TMPDIR/clean"
  new_repo "$repo"
  write_doc "$repo" "2026-10-02" "current"
  commit_at "$repo" "2026-10-02T01:00:00Z" "docs: add current workflow"

  run_history "$repo" --strict

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "check-freshness-history: OK"
  ! echo "$output" | grep -qF "DRIFT:"
}

@test "shallow history fails closed and names every affected document" {
  local source="$BATS_TEST_TMPDIR/shallow-source"
  local shallow="$BATS_TEST_TMPDIR/shallow"
  new_repo "$source"
  write_doc "$source" "2026-10-01" "baseline"
  commit_at "$source" "2026-10-01T01:00:00Z" "docs: add workflow"
  git clone -q --depth 1 "file://$source" "$shallow"

  run_history "$shallow" --strict

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "unavailable history for workflows/session.md"
  echo "$output" | grep -qF "checkout is shallow"
}

@test "non-governed tracked Markdown is outside the companion scope" {
  local repo="$BATS_TEST_TMPDIR/scope"
  new_repo "$repo"
  write_doc "$repo" "2026-10-02" "current"
  commit_at "$repo" "2026-10-02T01:00:00Z" "docs: add workflow"
  mkdir -p "$repo/docs/specifications"
  cat > "$repo/docs/specifications/stale.md" <<'EOF'
---
updated: 2020-01-01
---
# Outside scope
EOF
  git -C "$repo" add docs/specifications/stale.md
  commit_at "$repo" "2026-10-03T01:00:00Z" "docs: add outside-scope file"

  run_history "$repo" --strict

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "docs/specifications/stale.md"
}

@test "help and npm entry document strict mode" {
  run bash "$HISTORY_SCRIPT" --help

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF -- "--strict"
  echo "$output" | grep -qF "Exit codes"
  grep -qF '"check:freshness:history"' "$BATS_TEST_DIRNAME/../../package.json"
}
