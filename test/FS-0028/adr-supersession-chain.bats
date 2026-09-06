#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

# Rule 5b (FS-0028) — ADR supersession chain gate.
#
# The fixture ADR-9996 is fully wired (file + README row + H1) so that a
# well-formed chain yields a genuinely clean `check-status` run — not merely
# the absence of rule 5b's error amid rule-3 index noise. Failure tests mutate
# the same fixture and assert the specific error the rule is meant to produce.

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  ADR_DIR="$REPO_ROOT/docs/decisions"
  ADR_README="$ADR_DIR/README.md"
  FIXTURE="$ADR_DIR/ADR-9996-supersession-fixture.md"
  README_BACKUP=$(mktemp)
  cp "$ADR_README" "$README_BACKUP"
}

teardown() {
  rm -f "$FIXTURE" "${FIXTURE}.bak"
  cp "$README_BACKUP" "$ADR_README"
  rm -f "$README_BACKUP"
}

write_fixture() {
  # $1 = status, $2 = superseded_by line(s), $3 = README status column
  cat > "$FIXTURE" <<FIXTURE_EOF
---
type: adr
id: ADR-9996
status: $1
superseded_by: $2
title: Supersession chain test fixture
created: 2026-09-01
updated: 2026-09-01
---

# ADR-9996: Supersession chain test fixture

## Context and Problem Statement

Fixture for FS-0028 rule 5b tests.

## Considered Options

- None — test fixture.

## Decision Outcome

This is a test fixture.

## Consequences

None — removed at teardown.

## Validation

Exercised by test/FS-0028/adr-supersession-chain.bats.
FIXTURE_EOF
  echo "| ADR-9996 | Supersession chain test fixture | $3 |" >> "$ADR_README"
}

@test "supersession: a superseded ADR without a replacement is flagged" {
  write_fixture "superseded" "null" "superseded"
  run bash "$CHECK"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "ADR-9996 is 'superseded' but has no replacement"
}

@test "supersession: a dangling replacement id is flagged" {
  write_fixture "superseded" "ADR-9999" "superseded"
  run bash "$CHECK"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "ADR-9996 superseded_by: 'ADR-9999' does not resolve"
}

@test "supersession: a non-superseded ADR declaring a replacement is flagged" {
  write_fixture "accepted" "ADR-0000" "accepted"
  run bash "$CHECK"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F "only a 'superseded' ADR may declare a replacement"
}

@test "supersession: a well-formed chain passes the full check" {
  write_fixture "superseded" "ADR-0000" "superseded"
  run bash "$CHECK"
  echo "$output"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "ADR-9996"
}

@test "supersession: list-shaped superseded_by is parsed and resolves" {
  write_fixture "superseded" "null" "superseded"
  # Multi-entry list shape: superseded_by: [ADR-0000, ADR-0001]
  sed -i.bak 's/^superseded_by: null$/superseded_by: [ADR-0000, ADR-0001]/' "$FIXTURE"
  rm -f "${FIXTURE}.bak"
  run bash "$CHECK"
  echo "$output"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "ADR-9996"
}

@test "supersession: a double-quoted scalar id is normalised before resolution" {
  write_fixture "superseded" '"ADR-0000"' "superseded"
  run bash "$CHECK"
  echo "$output"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "ADR-9996"
}

@test "supersession: YAML block list shape resolves each entry" {
  write_fixture "superseded" "null" "superseded"
  # Block list shape:
  #   superseded_by:
  #     - ADR-0000
  #     - ADR-0001
  sed -i.bak '/^superseded_by: null$/c\
superseded_by:\
  - ADR-0000\
  - ADR-0001' "$FIXTURE"
  rm -f "${FIXTURE}.bak"
  run bash "$CHECK"
  echo "$output"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -F "ADR-9996"
}

@test "supersession: rule is documented in scripts/README.md" {
  assert_file_contains "$REPO_ROOT/scripts/README.md" "ADR supersession chain"
  assert_file_contains "$REPO_ROOT/scripts/README.md" "FS-0028"
}
