#!/usr/bin/env bats
# FS-0038: static checks always run; CLI probes use an isolated Hermes home.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
}

@test "FS-0038: candidate states all six capability mappings" {
  run grep -cE '^\| [1-6]\. ' "$REPO_ROOT/docs/proposals/hermes-kanban-substrate-binding.md"
  [ "$status" -eq 0 ]
  [ "$output" -eq 6 ]
}

@test "FS-0038: candidate does not claim complete conformance" {
  run grep -F 'internal design candidate' "$REPO_ROOT/docs/proposals/hermes-kanban-substrate-binding.md"
  [ "$status" -eq 0 ]
  [ ! -e "$REPO_ROOT/integrations/hermes-kanban.md" ]
}

@test "FS-0038: isolated board can create and enumerate a task" {
  command -v hermes >/dev/null || skip 'Hermes CLI unavailable; static checks still run'
  export HERMES_HOME="$(mktemp -d)"
  trap 'rm -rf "$HERMES_HOME"' EXIT
  run hermes kanban boards create ca-fs0038-probe
  [ "$status" -eq 0 ]
  run hermes kanban --board ca-fs0038-probe create '[task] probe' --body Brief --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status": "ready"'* ]]
  run hermes kanban --board ca-fs0038-probe list --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'[task] probe'* ]]
}
