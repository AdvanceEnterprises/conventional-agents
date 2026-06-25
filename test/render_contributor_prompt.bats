#!/usr/bin/env bats
# Smoke tests for scripts/render_contributor_prompt.py.
#
# These tests run the script against a small fixture YAML and assert that
# the rendered output contains the expected structural elements:
#   - three paste-ready sections (Claude, Codex, Gemini)
#   - the FS-0015 transparency block in Claude and Codex only
#   - the research-pass framing in Gemini only
#   - the substituted task framing and guardrails
#
# Run with:
#     npm install    # if not already installed
#     npx bats test/render_contributor_prompt.bats

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SCRIPT="$REPO_ROOT/scripts/render_contributor_prompt.py"
    FIXTURE="$(mktemp -d)/smoke.yaml"
    cat > "$FIXTURE" <<'YAML'
task:
  id: "smoke-test-001"
  framing: |
    Review the proposed contributor prompt template and identify
    any places where the FS-0015 transparency statement could be
    tightened.
  artifact_scope: []
    - "templates/contributor/contributor-prompt.md"
  branch: "pilot/multi-model-001"
  excluded_artifacts: []
    - "docs/decisions/ADR-0013.md"

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  contributor_role: "Head Architect"
  attribution_label: "claude-contrib-1"

structured_output:
  contract: "research_brief"
  brief_format_path: "references/research-brief-template.md"

input_sources: []
  - "templates/contributor/contributor-prompt.md"
  - "docs/specifications/FS-0015-role-selection-and-session-modes.md"

guardrails:
  may_modify: []
  must_not_modify: []
    - "docs/decisions/ADR-0013.md"
    - "docs/decisions/ADR-0016.md"
  attribution_trailers: []
    - "Assisted-By: claude-sonnet-4"
    - "Contributor-Session: <session-id>"
YAML
    OUT="$(mktemp)/out.md"
}

teardown() {
    rm -rf "$(dirname "$FIXTURE")"
    rm -rf "$(dirname "$OUT")"
}

@test "render_contributor_prompt renders three sections" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -c '^## ' "$OUT"
    [ "$status" -eq 0 ]
    [ "$output" -eq 3 ]
    run grep -q '^## Claude Code$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## Codex CLI$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## Gemini$' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt includes FS-0015 transparency in Claude and Codex only" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    # transparency count should be exactly 2 (Claude + Codex)
    run grep -c 'TRANSPARENCY STATEMENT' "$OUT"
    [ "$status" -eq 0 ]
    [ "$output" -eq 2 ]
}

@test "render_contributor_prompt substitutes task framing and branch" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -q 'tightened' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'pilot/multi-model-001' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt includes must_not_modify guardrail" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -q 'docs/decisions/ADR-0013.md' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'docs/decisions/ADR-0016.md' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt --target gemini produces only the Gemini section" {
    python3 "$SCRIPT" --params "$FIXTURE" --target gemini --output "$OUT"
    run grep -q '^## Gemini$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## Claude Code$' "$OUT"
    [ "$status" -eq 1 ]
    run grep -q '^## Codex CLI$' "$OUT"
    [ "$status" -eq 1 ]
    run grep -q 'TRANSPARENCY STATEMENT' "$OUT"
    [ "$status" -eq 1 ]
    run grep -q 'This is a research pass' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt errors clearly on missing required key" {
    BAD="$(mktemp -d)/bad.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "bad"
  framing: "x"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing required key"* ]]
    rm -rf "$(dirname "$BAD")"
}
