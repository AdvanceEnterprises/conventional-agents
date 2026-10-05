#!/usr/bin/env bats
# FS-0042 — pure renames are metadata-only, not substantive edits.
#
# A renamed document whose content is unchanged must not demand an updated:
# bump: the rename commit is resolved through the commit's own rename record
# and compared like any other commit.

HISTORY_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-freshness-history.sh"

new_repo() {
  local repo="$1"
  mkdir -p "$repo/workflows"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config user.email "fixture@example.test"
}

commit_at() {
  local repo="$1" date="$2" message="$3"
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git -C "$repo" commit -q -m "$message"
}

@test "pure rename commit is treated as metadata-only, not substantive drift" {
  local repo="$BATS_TEST_TMPDIR/rename"
  new_repo "$repo"
  cat > "$repo/workflows/session.md" <<'EOF'
---
updated: 2026-10-01
type: workflow
---
# Session workflow

baseline
EOF
  git -C "$repo" add workflows/session.md
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: add workflow"
  git -C "$repo" mv workflows/session.md workflows/session-renamed.md
  commit_at "$repo" "2026-10-02T01:00:00Z" "docs: rename workflow"

  run env CA_TARGET_REPO="$repo" TZ=UTC bash "$HISTORY_SCRIPT" --strict

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qF "DRIFT:"
  echo "$output" | grep -qF "check-freshness-history: OK"
}
