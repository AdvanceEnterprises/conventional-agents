#!/usr/bin/env bats
# FS-0041 — status-vs-delivery consistency audit (issue #188)

DELIVERY_SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-delivery-status.sh"

new_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config user.email "fixture@example.test"
}

commit_at() {
  local repo="$1" date="$2" message="$3"
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git -C "$repo" commit -q -m "$message"
}

write_pair() {
  local repo="$1" fs_status="$2" plan_status="$3" test_required="$4" created="$5" touches="$6"
  cat > "$repo/docs/specifications/FS-0001-fixture.md" <<EOF
---
type: feature-spec
id: FS-0001
status: $fs_status
title: Fixture feature
test_required: $test_required
interfaces:
  - scripts/impl.sh
created: 2026-10-01
updated: 2026-10-01
---
# Feature Spec: Fixture feature

## Status

- $fs_status
EOF
  cat > "$repo/docs/change-plans/PLAN-0001-fixture.md" <<EOF
---
type: change-plan
id: PLAN-0001
status: $plan_status
related_specs: [FS-0001]
created: $created
updated: 2026-10-01
touches:
$touches
---
# PLAN-0001: Fixture implementation
EOF
  git -C "$repo" add docs
}

add_delivery() {
  local repo="$1"
  mkdir -p "$repo/test/FS-0001" "$repo/scripts"
  printf '#!/usr/bin/env bash\n' > "$repo/scripts/impl.sh"
  printf '@test "fixture" { true; }\n' > "$repo/test/FS-0001/suite.bats"
  printf '### Changed\n\n- FS-0001 / PLAN-0001 fixture delivery.\n' > "$repo/CHANGELOG.md"
  git -C "$repo" add -A
}

run_delivery() {
  local repo="$1"
  shift
  run env CA_TARGET_REPO="$repo" bash "$DELIVERY_SCRIPT" "$@"
}

@test "complete delivered draft pair is reported with evidence and remediation" {
  local repo="$BATS_TEST_TMPDIR/draft"
  new_repo "$repo"
  write_pair "$repo" draft draft true 2026-10-01 '  - scripts/impl.sh
  - test/FS-0001/**'
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: declare fixture plan"
  add_delivery "$repo"
  commit_at "$repo" "2026-10-02T01:00:00Z" "feat: deliver FS-0001"
  cp -a "$repo" "$BATS_TEST_TMPDIR/draft-before"

  run_delivery "$repo"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "DRIFT: FS-0001 / PLAN-0001"
  echo "$output" | grep -qF "FS status=draft, PLAN status=draft"
  echo "$output" | grep -qF "scripts/impl.sh"
  echo "$output" | grep -qF "test/FS-0001/suite.bats"
  echo "$output" | grep -qF "CHANGELOG.md"
  echo "$output" | grep -qF "human review should reconcile"
  [ -z "$(git -C "$repo" status --porcelain)" ]
  cmp -s "$repo/docs/specifications/FS-0001-fixture.md" "$BATS_TEST_TMPDIR/draft-before/docs/specifications/FS-0001-fixture.md"
}

@test "approved and in-progress pairs are also reported" {
  local repo="$BATS_TEST_TMPDIR/approved"
  new_repo "$repo"
  write_pair "$repo" approved in-progress false 2026-10-01 '  - scripts/impl.sh'
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: approve fixture plan"
  mkdir -p "$repo/scripts"
  printf '#!/usr/bin/env bash\n' > "$repo/scripts/impl.sh"
  printf '### Changed\n\n- FS-0001 implementation.\n' > "$repo/CHANGELOG.md"
  git -C "$repo" add -A
  commit_at "$repo" "2026-10-02T01:00:00Z" "feat: deliver approved fixture"

  run_delivery "$repo"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "FS status=approved, PLAN status=in-progress"
}

@test "pre-existing paths without post-created history are not reported" {
  local repo="$BATS_TEST_TMPDIR/preexisting"
  new_repo "$repo"
  mkdir -p "$repo/scripts"
  printf '#!/usr/bin/env bash\n' > "$repo/scripts/impl.sh"
  write_pair "$repo" draft draft false 2026-10-03 '  - scripts/impl.sh'
  printf '### Older\n' > "$repo/CHANGELOG.md"
  git -C "$repo" add -A
  commit_at "$repo" "2026-10-01T01:00:00Z" "chore: pre-existing fixture"

  run_delivery "$repo"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "no post-2026-10-03 history"
  ! echo "$output" | grep -qF "DRIFT:"
}

@test "partial or unresolved implementation surfaces are not over-claimed" {
  local repo="$BATS_TEST_TMPDIR/partial"
  new_repo "$repo"
  write_pair "$repo" draft draft false 2026-10-01 '  - scripts/impl.sh
  - scripts/missing.sh'
  commit_at "$repo" "2026-10-01T01:00:00Z" "docs: declare partial fixture"
  mkdir -p "$repo/scripts"
  printf '#!/usr/bin/env bash\n' > "$repo/scripts/impl.sh"
  git -C "$repo" add -A
  commit_at "$repo" "2026-10-02T01:00:00Z" "feat: deliver only one path"

  run_delivery "$repo"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "does not resolve in the tracked current tree"
  ! echo "$output" | grep -qF "DRIFT:"
}

@test "documentation-only and terminal pairs are quiet" {
  local docs_repo="$BATS_TEST_TMPDIR/docs-only"
  new_repo "$docs_repo"
  write_pair "$docs_repo" draft draft false 2026-10-01 '  - docs/notes.md
  - CHANGELOG.md'
  printf '# Notes\n' > "$docs_repo/docs/notes.md"
  printf '### Notes\n' > "$docs_repo/CHANGELOG.md"
  git -C "$docs_repo" add -A
  commit_at "$docs_repo" "2026-10-02T01:00:00Z" "docs: documentation-only fixture"

  run_delivery "$docs_repo"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "no implementation surface"

  local terminal_repo="$BATS_TEST_TMPDIR/terminal"
  new_repo "$terminal_repo"
  write_pair "$terminal_repo" implemented implemented false 2026-10-01 '  - scripts/impl.sh'
  mkdir -p "$terminal_repo/scripts"
  printf '#!/usr/bin/env bash\n' > "$terminal_repo/scripts/impl.sh"
  git -C "$terminal_repo" add -A
  commit_at "$terminal_repo" "2026-10-02T01:00:00Z" "feat: terminal fixture"
  run_delivery "$terminal_repo"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "no non-terminal FS/primary-PLAN pairs"
}

@test "shallow history is an explicit unavailable result" {
  local source="$BATS_TEST_TMPDIR/shallow-source"
  local shallow="$BATS_TEST_TMPDIR/shallow"
  new_repo "$source"
  write_pair "$source" draft draft false 2026-10-01 '  - scripts/impl.sh'
  commit_at "$source" "2026-10-01T01:00:00Z" "docs: declare shallow fixture"
  mkdir -p "$source/scripts"
  printf '#!/usr/bin/env bash\n' > "$source/scripts/impl.sh"
  printf '### Changed\n\n- FS-0001.\n' > "$source/CHANGELOG.md"
  git -C "$source" add -A
  commit_at "$source" "2026-10-02T01:00:00Z" "feat: deliver shallow fixture"
  git clone -q --depth 1 "file://$source" "$shallow"

  run_delivery "$shallow"

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "unavailable delivery history"
  echo "$output" | grep -qF "scripts/impl.sh"
}

@test "help and npm registration are present" {
  run bash "$DELIVERY_SCRIPT" --help

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "check-delivery-status.sh"
  grep -qF '"check:delivery"' "$BATS_TEST_DIRNAME/../../package.json"
}
