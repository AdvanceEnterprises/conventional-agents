#!/usr/bin/env bats
# FS-0040 — governed-ID claim audit coverage (issues #179 and #186)

setup() {
  # The duplicate is created only for the duration of this test. Using the
  # active worktree keeps local runs honest while the new gate is uncommitted;
  # teardown removes it even when the assertion fails.
  export WORKTREE="$(git rev-parse --show-toplevel)"
  export DUPLICATE="$WORKTREE/docs/specifications/FS-9999-duplicate-claim.md"
  export DUPLICATE_PLAN="$WORKTREE/docs/change-plans/PLAN-0046-duplicate-claim.md"
  export DUPLICATE_ADR="$WORKTREE/docs/decisions/ADR-9999-duplicate-claim.md"
  rm -f "$DUPLICATE"
  rm -f "$DUPLICATE_PLAN"
  rm -f "$DUPLICATE_ADR"
}

teardown() {
  rm -f "$DUPLICATE"
  rm -f "$DUPLICATE_PLAN"
  rm -f "$DUPLICATE_ADR"
}

@test "local duplicate detection names every governed document claiming the ID" {
  cp "$WORKTREE/docs/specifications/FS-0040-governed-id-claim-audit.md" "$DUPLICATE"

  run bash -c "cd '$WORKTREE' && bash scripts/check-status.sh"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ERROR: duplicate governed ID FS-0040 is claimed by:"
  echo "$output" | grep -qF "docs/specifications/FS-0040-governed-id-claim-audit.md"
  echo "$output" | grep -qF "docs/specifications/FS-9999-duplicate-claim.md"
}

@test "local duplicate detection derives PLAN claims from governed filenames" {
  cp "$WORKTREE/docs/change-plans/PLAN-0046-implement-fs-0040-governed-id-claim-audit.md" "$DUPLICATE_PLAN"

  run bash -c "cd '$WORKTREE' && bash scripts/check-status.sh"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ERROR: duplicate governed ID PLAN-0046 is claimed by:"
  echo "$output" | grep -qF "docs/change-plans/PLAN-0046-implement-fs-0040-governed-id-claim-audit.md"
  echo "$output" | grep -qF "docs/change-plans/PLAN-0046-duplicate-claim.md"
}

@test "local duplicate detection covers the ADR registry (FS-0040 SC-3)" {
  # MM3 round-B finding (PR #206): SC-3 claims ADR duplicate detection but no
  # fixture exercised the $ADR_DIR branch of rule 4. Copy a real ADR and give
  # the copy the same front-matter id: so the registry scan must flag it.
  local source_adr
  source_adr="$(ls "$WORKTREE"/docs/decisions/ADR-*.md | head -1)"
  sed -n '1,5p' "$source_adr" > "$DUPLICATE_ADR"
  adr_id="$(sed -nE 's/^id:[[:space:]]*"?([A-Z]+-[0-9]+)"?.*/\1/p' "$source_adr" | head -1)"

  run bash -c "cd '$WORKTREE' && bash scripts/check-status.sh"

  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "ERROR: duplicate governed ID $adr_id is claimed by:"
  echo "$output" | grep -qF "docs/decisions/ADR-9999-duplicate-claim.md"
}

@test "claim audit binding is report-only and exposes strict mode" {
  local audit="$WORKTREE/integrations/github/bin/gh-pr-claim-audit.sh"

  [ -x "$audit" ]
  ! grep -E -q -- 'gh api .*(-X|--method) (POST|PATCH|PUT|DELETE)|gh pr merge|gh project item-edit|gh issue edit' "$audit"
  run bash "$audit" --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF -- "--strict"
}
