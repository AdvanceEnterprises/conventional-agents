#!/usr/bin/env bats
# FS-0031 — governed-agent benchmark harness (scripts/bench-run.sh).
#
# Covers SC-1..SC-6 with mock drivers — no live model calls, no network.
# The runner clones the card's base repo; tests use a LOCAL scratch repo as
# the base so nothing touches the network.

load "../FS-0001/helpers.bash"

setup() {
  BENCH_RUN="$BATS_TEST_DIRNAME/../../scripts/bench-run.sh"
  SCHEMA="$BATS_TEST_DIRNAME/../../benchmark/task-card.schema.json"
  [ -f "$BENCH_RUN" ] && [ -f "$SCHEMA" ] || {
    echo "harness files not found near $BATS_TEST_DIRNAME"
    return 1
  }
  export BENCH_REPORT_DIR="$BATS_TEST_TMPDIR/reports"
}

# Build a scratch base repo with one commit, plus a task card pointing at it.
build_base_and_card() {
  local base="$BATS_TEST_TMPDIR/base"
  mkdir -p "$base"
  git -C "$base" init -q -b trunk
  git -C "$base" config user.name "Test"
  git -C "$base" config user.email "test@example.com"
  echo "hello" > "$base/README.md"
  git -C "$base" add README.md
  git -C "$base" commit -qm "init"
  local sha
  sha="$(git -C "$base" rev-parse --short=7 HEAD)"

  local card="$BATS_TEST_TMPDIR/card.md"
  cat > "$card" <<EOF
---
schema_version: 1
id: test-card
title: "Test card"
base_repo: "$base"
base_commit: "$sha"
prompt: "Do the thing."
permitted_paths: ["README.md"]
forbidden_paths: []
required_plan_fields: ["scope"]
required_evidence_fields: ["diff"]
governance_checks:
  - id: no-op
    description: "trivially passes"
    command: "true"
scenarios:
  escalation:
    present: true
    description: "escalation scenario"
  adversarial:
    present: true
    description: "adversarial instruction"
budget:
  timeout_seconds: 60
---
EOF
  echo "$card"
}

@test "SC-1: runner sets up worktree, runs driver, captures action log" {
  local card
  card="$(build_base_and_card)"
  run "$BENCH_RUN" "$card" baseline bash -c 'echo "driver ran"; exit 0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"REPORT:"* ]]
  local report
  report="$(echo "$output" | grep -o 'REPORT: .*' | cut -d' ' -f2)"
  [ -f "$report" ]
  # action log captured
  jq -e '.evidence.action_log' "$report" >/dev/null
  local log
  log="$(jq -r '.evidence.action_log' "$report")"
  [ -f "$log" ]
  grep -q "driver ran" "$log"
}

@test "SC-1b: driver failure is task failure, not harness failure" {
  local card
  card="$(build_base_and_card)"
  run "$BENCH_RUN" "$card" baseline bash -c 'echo "boom"; exit 3'
  [ "$status" -eq 0 ]
  local report
  report="$(echo "$output" | grep -o 'REPORT: .*' | cut -d' ' -f2)"
  [ "$(jq -r '.functional.status' "$report")" = "fail" ]
  [ "$(jq -r '.functional.driver_exit' "$report")" = "3" ]
}

@test "SC-2: schema validation — unknown version rejected" {
  local card
  card="$(build_base_and_card)"
  sed -i 's/schema_version: 1/schema_version: 99/' "$card"
  run "$BENCH_RUN" "$card" baseline
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported schema_version"* ]]
}

@test "SC-2b: schema validation — missing required field rejected" {
  local card
  card="$(build_base_and_card)"
  sed -i '/^forbidden_paths:/d' "$card"
  run "$BENCH_RUN" "$card" baseline
  [ "$status" -eq 1 ]
  [[ "$output" == *"schema validation"* ]]
}

@test "SC-3: report separates functional, governance, evidence" {
  local card
  card="$(build_base_and_card)"
  run "$BENCH_RUN" "$card" baseline bash -c 'exit 0'
  [ "$status" -eq 0 ]
  local report
  report="$(echo "$output" | grep -o 'REPORT: .*' | cut -d' ' -f2)"
  jq -e '.functional and .governance and .evidence' "$report" >/dev/null
  [ "$(jq -r '.governance.passed' "$report")" = "1" ]
  [ "$(jq -r '.governance.total' "$report")" = "1" ]
}

@test "SC-4: same card runs under two conditions with distinct drivers" {
  local card
  card="$(build_base_and_card)"
  run "$BENCH_RUN" "$card" baseline bash -c 'echo baseline; exit 0'
  [ "$status" -eq 0 ]
  run "$BENCH_RUN" "$card" gated bash -c 'echo gated; exit 0'
  [ "$status" -eq 0 ]
  local r1 r2
  r1="$(echo "$output" | grep -o 'REPORT: .*' | cut -d' ' -f2)"
  # second run's report
  r2="$(ls -t "$BENCH_REPORT_DIR" | head -1)"
  [ "$(jq -r '.condition' "$BENCH_REPORT_DIR/$r2")" = "gated" ]
  grep -q "gated" "$(jq -r '.evidence.action_log' "$BENCH_REPORT_DIR/$r2")"
}

@test "SC-5: pilot card declares escalation + adversarial scenarios" {
  local pilot="$BATS_TEST_DIRNAME/../../benchmark/task-cards/pilot-001.md"
  [ -f "$pilot" ]
  local fm
  fm="$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n==2{exit}' "$pilot")"
  local json
  json="$(python3 -c "import json,sys,yaml; print(json.dumps(yaml.safe_load(sys.argv[1])))" "$fm")"
  [ "$(echo "$json" | jq -r '.scenarios.escalation.present')" = "true" ]
  [ "$(echo "$json" | jq -r '.scenarios.adversarial.present')" = "true" ]
}

@test "SC-6: report includes overhead and failures fields" {
  local card
  card="$(build_base_and_card)"
  # add a failing governance check inside the governance_checks list
  python3 - "$card" <<'PYEOF'
import sys, yaml
p = sys.argv[1]
with open(p) as f:
    text = f.read()
fm = text.split("---")[1]
data = yaml.safe_load(fm)
data["governance_checks"].append({
    "id": "always-fails",
    "description": "fails deterministically",
    "command": "false",
})
new_fm = yaml.safe_dump(data, sort_keys=False, default_flow_style=False)
with open(p, "w") as f:
    f.write("---\n" + new_fm + "---\n")
PYEOF
  run "$BENCH_RUN" "$card" baseline bash -c 'exit 0'
  [ "$status" -eq 0 ]
  local report
  report="$(echo "$output" | grep -o 'REPORT: .*' | cut -d' ' -f2)"
  jq -e '.overhead.wall_seconds' "$report" >/dev/null
  [ "$(jq -r '.failures | length' "$report")" -ge 1 ]
  [ "$(jq -r '.governance.passed' "$report")" = "1" ]
  [ "$(jq -r '.governance.total' "$report")" = "2" ]
}
