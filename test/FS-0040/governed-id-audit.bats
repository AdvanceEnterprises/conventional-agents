#!/usr/bin/env bats
# FS-0040 — governed-ID claim audit coverage (issues #179 and #186)

setup() {
  # The duplicate is created only for the duration of this test. Using the
  # active worktree keeps local runs honest while the new gate is uncommitted;
  # teardown removes it even when the assertion fails.
  export WORKTREE="$(git rev-parse --show-toplevel)"
  export DUPLICATE="$WORKTREE/docs/specifications/FS-9999-duplicate-claim.md"
  rm -f "$DUPLICATE"
}

teardown() {
  rm -f "$DUPLICATE"
}

@test "local duplicate detection names every governed document claiming the ID" {
  cp "$WORKTREE/docs/specifications/FS-0040-governed-id-claim-audit.md" "$DUPLICATE"

  run bash -c "cd '$WORKTREE' && bash scripts/check-status.sh"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ERROR: duplicate governed ID FS-0040 is claimed by:"
  echo "$output" | grep -qF "docs/specifications/FS-0040-governed-id-claim-audit.md"
  echo "$output" | grep -qF "docs/specifications/FS-9999-duplicate-claim.md"
}

@test "claim audit binding is report-only and exposes strict mode" {
  local audit="$WORKTREE/integrations/github/bin/gh-pr-claim-audit.sh"

  [ -x "$audit" ]
  ! grep -E -q -- 'gh api .*(-X|--method) (POST|PATCH|PUT|DELETE)|gh pr merge|gh project item-edit|gh issue edit' "$audit"
  run bash "$audit" --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF -- "--strict"
}
