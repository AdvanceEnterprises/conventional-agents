#!/usr/bin/env bats
# FS-0030 SC-18 through SC-20 and SC-24 — Claude Code runtime binding:
# report-only audit behaviour, plugin manifest validity, no-mutation source.

BINDING_DIR="test/../integrations/runtimes/claude-code"
AUDIT="$BINDING_DIR/bin/ca-runtime-audit.sh"
SYNC="$BINDING_DIR/bin/sync-skills.sh"

load "./helpers"

@test "SC-18: ca-runtime-audit.sh --help prints usage and exits 0" {
    run "$TEST_BASH" "$AUDIT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ca-runtime-audit.sh"* ]]
    [[ "$output" == *"--strict"* ]]
    [[ "$output" == *"CA_TARGET_REPO"* ]]
}

@test "SC-19: audit reports divergences and exits 0 by default; --strict exits 1" {
    fixture="$(mktemp -d)"
    mkdir -p "$fixture/.claude"
    # A .claude/ dir with no settings.json and no CLAUDE.md at repo root
    # = divergence for CLAUDE.md, advisory for settings/hooks.
    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$AUDIT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[warn]"* ]]

    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$AUDIT" --strict
    [ "$status" -eq 1 ]
}

@test "SC-19: audit passes a conforming .claude/ with no warnings" {
    fixture="$(mktemp -d)"
    mkdir -p "$fixture/.claude/hooks"
    cp "$BINDING_DIR/settings.fragment.json" "$fixture/.claude/settings.json"
    cp "$BINDING_DIR/hooks/hooks.json" "$fixture/.claude/hooks/hooks.json"
    printf '# CLAUDE.md\n\n@AGENTS.md\n' > "$fixture/CLAUDE.md"
    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$AUDIT" --strict
    [ "$status" -eq 0 ]
    [[ "$output" != *"[warn]"* ]]
}

@test "SC-20 + SC-24: audit source performs no mutation and no vendor-path reads" {
    run grep -nE 'gh |git (add|commit|push|rm|mv|checkout)|> |>> ' "$AUDIT"
    [ "$status" -eq 1 ]   # grep found nothing → exit 1
    # No vendor/ segment in any path the audit reads or constructs. A prose
    # mention of vendor/ in a comment or usage string is permitted; the
    # executable-path form is not.
    run grep -nE 'vendor/[A-Za-z]' "$AUDIT"
    [ "$status" -eq 1 ]
    run bash -n "$AUDIT"
    [ "$status" -eq 0 ]
}

@test "SC-24: sync-skills.sh copies ships 10 skills and is bash -n clean" {
    run bash -n "$SYNC"
    [ "$status" -eq 0 ]
    run env CA_TARGET_REPO="$(pwd)" "$TEST_BASH" "$SYNC"
    [ "$status" -eq 0 ]
    [[ "$output" == *"synced 10 skills"* ]]
}

@test "FS-0030: CA_TARGET_REPO resolves a relative path from another cwd" {
    fixture="$(mktemp -d)"
    mkdir -p "$fixture/.claude/hooks"
    cp "$BINDING_DIR/settings.fragment.json" "$fixture/.claude/settings.json"
    cp "$BINDING_DIR/hooks/hooks.json" "$fixture/.claude/hooks/hooks.json"
    printf '# CLAUDE.md\n\n@AGENTS.md\n' > "$fixture/CLAUDE.md"
    audit_abs="$(cd "$(dirname "$AUDIT")" && pwd)/$(basename "$AUDIT")"
    output="$(cd "$fixture" && env CA_TARGET_REPO="." "$TEST_BASH" "$audit_abs" --strict 2>&1)"
    status=$?
    [ "$status" -eq 0 ]
}

@test "FS-0030: plugin manifest is valid JSON with a name and version" {
    run jq -e -r '.name, .version' "$BINDING_DIR/.claude-plugin/plugin.json"
    [ "$status" -eq 0 ]
    [[ "$output" == *"conventional-agents"* ]]
}

@test "FS-0030: no runtime dialect is written into source skills (ADR-0038)" {
    # SC-12: bindings may not add metadata.hermes.* into skills/*/SKILL.md.
    # The plugin's own copies are allowed their dialect; the source is not.
    run grep -rn "metadata.hermes" skills/ --include="SKILL.md"
    [ "$status" -eq 1 ]
}
