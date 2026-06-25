#!/usr/bin/env bats
# Smoke tests for scripts/render_contributor_prompt.py.
#
# These tests run the script against fixture YAML files and assert that
# the rendered output contains the expected structural elements:
#   - one rendered section per contributor
#   - the FS-0015 transparency block in external-cli and hermes-chat, not in research-pass
#   - the shared claim envelope note in all contracts
#   - the substituted task framing, supporting_roles, and guardrails
#   - gate overlap is rejected without --allow-gate-overlap
#   - JSON schema validation rejects non-schema files
#
# Run with:
#     npm install    # if not already installed
#     npx bats test/render_contributor_prompt.bats

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SCRIPT="$REPO_ROOT/scripts/render_contributor_prompt.py"

    # Fixture: a parameter file with three contributors, one per render_mode.
    FIXTURE_DIR="$(mktemp -d)"
    FIXTURE="$FIXTURE_DIR/smoke.yaml"
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
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "claude-code"
    model: "claude-sonnet-4"
    render_mode: "external-cli"
    active_contributor_role: "Reviewer"
    attribution_label: "claude-contrib-1"
    structured_output:
      contract: "research_brief"
      brief_format_path: "references/research-brief-template.md"
    guardrails:
      may_modify: []
      must_not_modify: []
        - "docs/decisions/ADR-0013.md"
  - target: "qwen3-coder-next"
    model: "qwen3-coder-next"
    render_mode: "hermes-chat"
    provider: "ollama-cloud"
    toolsets: "file,web"
    active_contributor_role: "Reviewer"
    attribution_label: "qwen3-contrib-1"
    structured_output:
      contract: "research_brief"
      brief_format_path: "references/research-brief-template.md"
    guardrails:
      may_modify: []
      must_not_modify: []
        - "docs/decisions/ADR-0013.md"
  - target: "gemini"
    model: "gemini-2.5-pro"
    render_mode: "research-pass"
    provider: "ollama-cloud"
    toolsets: "file,web"
    active_contributor_role: "Reviewer"
    attribution_label: "gemini-contrib-1"
    structured_output:
      contract: "research_brief"
      brief_format_path: "references/research-brief-template.md"

input_sources: []
  - "templates/contributor/contributor-prompt.md"
  - "docs/specifications/FS-0015-role-selection-and-session-modes.md"
YAML

    OUT="$(mktemp -d)/out.md"
}

teardown() {
    rm -rf "$FIXTURE_DIR"
    rm -rf "$(dirname "$OUT")"
}

@test "render_contributor_prompt renders one section per contributor" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -c '^## ' "$OUT"
    [ "$status" -eq 0 ]
    [ "$output" -eq 3 ]
    run grep -q '^## claude-code$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## qwen3-coder-next$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## gemini$' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt includes FS-0015 transparency in external-cli and hermes-chat only" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    # transparency count should be exactly 2 (claude-code + qwen3-coder-next)
    run grep -c 'TRANSPARENCY STATEMENT' "$OUT"
    [ "$status" -eq 0 ]
    [ "$output" -eq 2 ]
}

@test "render_contributor_prompt research-pass produces no transparency block" {
    python3 "$SCRIPT" --params "$FIXTURE" --target gemini --output "$OUT"
    run grep -q 'TRANSPARENCY STATEMENT' "$OUT"
    [ "$status" -eq 1 ]
    run grep -q 'This is a research pass' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt substitutes task framing and branch" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -q 'tightened' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'pilot/multi-model-001' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt lists are on separate lines below their labels" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -E 'Artifact scope.*: - ' "$OUT"
    [ "$status" -eq 1 ]
    run grep -E '^- templates/contributor/contributor-prompt.md$' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt includes must_not_modify guardrail" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -q 'docs/decisions/ADR-0013.md' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt --target produces only that contributor's section" {
    python3 "$SCRIPT" --params "$FIXTURE" --target claude-code --output "$OUT"
    run grep -q '^## claude-code$' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q '^## qwen3-coder-next$' "$OUT"
    [ "$status" -eq 1 ]
    run grep -q '^## gemini$' "$OUT"
    [ "$status" -eq 1 ]
}

@test "render_contributor_prompt renders attribution trailer per render mode" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    # external-cli: 'Assisted-By: claude-sonnet-4'
    run grep -q 'Assisted-By: claude-sonnet-4$' "$OUT"
    [ "$status" -eq 0 ]
    # hermes-chat: 'Assisted-By: hermes (qwen3-coder-next)'
    run grep -q 'Assisted-By: hermes (qwen3-coder-next)' "$OUT"
    [ "$status" -eq 0 ]
    # research-pass: 'Assisted-By: hermes (gemini-2.5-pro)'
    run grep -q 'Assisted-By: hermes (gemini-2.5-pro)' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt includes shared claim envelope fields" {
    python3 "$SCRIPT" --params "$FIXTURE" --output "$OUT"
    run grep -q 'claim_id' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'source_citation' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'contributor_position' "$OUT"
    [ "$status" -eq 0 ]
    run grep -q 'confidence' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt validates session.mode against FS-0015 enumeration" {
    BAD="$FIXTURE_DIR/bad-mode.yaml"
    sed 's/Architecture Planning/Make Things Up/' "$FIXTURE" > "$BAD"
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a valid FS-0015 mode"* ]]
}

@test "render_contributor_prompt rejects gate.model == contributors[].model without --allow-gate-overlap" {
    OVERLAP="$FIXTURE_DIR/overlap.yaml"
    cat > "$OVERLAP" <<'YAML'
task:
  id: "overlap-test"
  framing: "test"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "deepseek-test"
    model: "deepseek-v4-pro"
    render_mode: "hermes-chat"
    provider: "ollama-cloud"
    toolsets: "file,web"
    active_contributor_role: "Reviewer"
    attribution_label: "deepseek-contrib-1"
    structured_output:
      contract: "research_brief"

gate:
  enabled: true
  model: "deepseek-v4-pro"
  provider: "ollama-cloud"
YAML
    run python3 "$SCRIPT" --params "$OVERLAP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"also appears in contributors[].model"* ]]

    # With --allow-gate-overlap, it succeeds
    run python3 "$SCRIPT" --params "$OVERLAP" --allow-gate-overlap
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt errors clearly on missing required key" {
    BAD="$FIXTURE_DIR/bad.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "bad"
  framing: "x"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing required"* ]]
}

@test "render_contributor_prompt rejects hermes-chat without provider" {
    BAD="$FIXTURE_DIR/no-provider.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "np"
  framing: "x"
  artifact_scope: []
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "hermes-chat"
    active_contributor_role: "Reviewer"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"but no provider"* ]]
}

@test "render_contributor_prompt rejects non-JSON-schema file for json_schema contract" {
    BAD="$FIXTURE_DIR/bad-schema.yaml"
    SCHEMA_FILE="$FIXTURE_DIR/not-a-schema.json"
    echo "this is not JSON" > "$SCHEMA_FILE"
    cat > "$BAD" <<YAML
task:
  id: "ns"
  framing: "x"
  artifact_scope: []
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "external-cli"
    active_contributor_role: "Reviewer"
    attribution_label: "x-1"
    structured_output:
      contract: "json_schema"
      schema_path: "$SCHEMA_FILE"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not valid JSON"* ]]
}

@test "render_contributor_prompt rejects active_contributor_role not in supporting_roles" {
    BAD="$FIXTURE_DIR/bad-role-rel.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "rr"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "external-cli"
    active_contributor_role: "Implementer"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is not in session.supporting_roles"* ]]
}

@test "render_contributor_prompt rejects empty supporting_roles with accountable mode" {
    BAD="$FIXTURE_DIR/bad-empty-roles.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "er"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []

contributors: []
  - target: "test"
    model: "x"
    render_mode: "external-cli"
    active_contributor_role: "Reviewer"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"supporting_roles is empty"* ]]
}

@test "render_contributor_prompt rejects missing active_contributor_role with accountable mode" {
    BAD="$FIXTURE_DIR/bad-no-active.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "na"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "external-cli"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no active_contributor_role"* ]]
}

@test "render_contributor_prompt rejects invalid primary_role" {
    BAD="$FIXTURE_DIR/bad-primary.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "bp"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Supreme Leader"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "external-cli"
    active_contributor_role: "Reviewer"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a valid FS-0014 role"* ]]
}

@test "render_contributor_prompt renders attribution_label in transparency statement" {
    python3 "$SCRIPT" --params "$FIXTURE" --target claude-code --output "$OUT"
    run grep -q 'My attribution label: claude-contrib-1' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt uses attribution_label as claim-ID namespace" {
    python3 "$SCRIPT" --params "$FIXTURE" --target claude-code --output "$OUT"
    run grep -q 'C-claude-contrib-1-001' "$OUT"
    [ "$status" -eq 0 ]
}

@test "render_contributor_prompt rejects hermes-chat without toolsets" {
    BAD="$FIXTURE_DIR/no-toolsets.yaml"
    cat > "$BAD" <<'YAML'
task:
  id: "nt"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []
    - "Reviewer"

contributors: []
  - target: "test"
    model: "x"
    render_mode: "hermes-chat"
    provider: "ollama-cloud"
    active_contributor_role: "Reviewer"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$BAD"
    [ "$status" -eq 1 ]
    [[ "$output" == *"but no toolsets"* ]]
}

@test "render_contributor_prompt research-pass exempt from role relationship checks" {
    # research-pass contributors are advisory and should not trigger
    # the supporting_roles / active_contributor_role checks.
    RP="$FIXTURE_DIR/rp-exempt.yaml"
    cat > "$RP" <<'YAML'
task:
  id: "rp"
  framing: "x"
  artifact_scope: []
    - "x"
  branch: "main"
  excluded_artifacts: []

session:
  mode: "Architecture Planning"
  primary_role: "Head Architect"
  supporting_roles: []

contributors: []
  - target: "test"
    model: "x"
    render_mode: "research-pass"
    provider: "ollama-cloud"
    toolsets: "file,web"
    attribution_label: "x-1"
    structured_output:
      contract: "research_brief"
YAML
    run python3 "$SCRIPT" --params "$RP"
    [ "$status" -eq 0 ]
}