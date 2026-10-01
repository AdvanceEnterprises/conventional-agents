#!/usr/bin/env bats
# FS-0030 SC-18 through SC-20 and SC-24 — Claude Code runtime binding:
# report-only audit behaviour, plugin manifest validity, no-mutation source.
#
# Issue #204 adds target-resolution cases: both binding scripts must resolve
# the repository containing the caller's working directory (CA_TARGET_REPO
# overriding), must reject a directory git disclaims with a loud, distinct
# diagnostic, and must map a subdirectory target to the work-tree top level.
# Every fixture that previously ran against a bare mktemp directory is now a
# git work tree, because that is what the scripts require.

BINDING_DIR="test/../integrations/runtimes/claude-code"
AUDIT="$BINDING_DIR/bin/ca-runtime-audit.sh"
SYNC="$BINDING_DIR/bin/sync-skills.sh"

load "./helpers"

# Absolute audit path for invocations that cd elsewhere first.
audit_abs() {
    echo "$(cd "$(dirname "$AUDIT")" && pwd)/$(basename "$AUDIT")"
}

# Absolute sync path, anchored on this suite's own location so it resolves
# regardless of the cwd bats was invoked from.
SYNC_ABS="$BATS_TEST_DIRNAME/../../integrations/runtimes/claude-code/bin/sync-skills.sh"

@test "SC-18: ca-runtime-audit.sh --help prints usage and exits 0" {
    run "$TEST_BASH" "$AUDIT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ca-runtime-audit.sh"* ]]
    [[ "$output" == *"--strict"* ]]
    [[ "$output" == *"CA_TARGET_REPO"* ]]
}

@test "SC-19: audit reports divergences and exits 0 by default; --strict exits 1" {
    fixture="$BATS_TEST_TMPDIR/divergent"
    mkdir -p "$fixture/.claude"
    ( cd "$fixture" && git init -q )
    # A .claude/ dir with no settings.json and no CLAUDE.md at repo root
    # = divergence for CLAUDE.md, advisory for settings/hooks.
    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$AUDIT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[warn]"* ]]

    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$AUDIT" --strict
    [ "$status" -eq 1 ]
}

@test "SC-19: audit passes a conforming .claude/ with no warnings" {
    fixture="$BATS_TEST_TMPDIR/conforming"
    mkdir -p "$fixture/.claude/hooks"
    ( cd "$fixture" && git init -q )
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
    fixture="$BATS_TEST_TMPDIR/relative"
    mkdir -p "$fixture/.claude/hooks"
    ( cd "$fixture" && git init -q )
    cp "$BINDING_DIR/settings.fragment.json" "$fixture/.claude/settings.json"
    cp "$BINDING_DIR/hooks/hooks.json" "$fixture/.claude/hooks/hooks.json"
    printf '# CLAUDE.md\n\n@AGENTS.md\n' > "$fixture/CLAUDE.md"
    # Resolve the audit to an absolute path BEFORE cd'ing — a relative path
    # would expand against the fixture's cwd, not the framework checkout.
    audit_path="$(audit_abs)"
    output="$(cd "$fixture" && env CA_TARGET_REPO="." "$TEST_BASH" "$audit_path" --strict 2>&1)"
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

# --- issue #204: target resolution -------------------------------------------

@test "target: audit fails loudly from a non-git cwd instead of certifying nothing (issue #204)" {
    # Pre-fix, a non-git cwd received a confident "[info] no .claude/ directory
    # — nothing to audit" with exit 0 (and --strict still exited 0): a verdict
    # about a directory that is not a repository at all.
    nongit="$BATS_TEST_TMPDIR/not-a-repo"
    mkdir -p "$nongit"
    run "$TEST_BASH" -c "cd '$nongit' && bash '$(audit_abs)'"
    [ "$status" -eq 2 ]
    [[ "$output" == *"not inside a git working tree"* ]]
    ! echo "$output" | grep -qF "nothing to audit"
}

@test "target: audit rejects CA_TARGET_REPO at a non-repo directory (issue #204)" {
    nongit="$BATS_TEST_TMPDIR/not-a-repo-override"
    mkdir -p "$nongit"
    run env CA_TARGET_REPO="$nongit" "$TEST_BASH" "$AUDIT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"not inside a git working tree"* ]]
}

@test "target: audit rejects a bare repository with its own diagnostic (issue #204)" {
    bare="$BATS_TEST_TMPDIR/bare.git"
    ( cd "$BATS_TEST_TMPDIR" && git init -q --bare "$bare" )
    run env CA_TARGET_REPO="$bare" "$TEST_BASH" "$AUDIT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare git repository"* ]]
    ! echo "$output" | grep -qF "not inside a git working tree"
}

@test "target: audit names a missing git binary instead of blaming the directory (issue #204)" {
    fakebin="$BATS_TEST_TMPDIR/fakebin"
    mkdir -p "$fakebin"
    ln -s "$(command -v bash)" "$fakebin/bash"
    run env PATH="$fakebin" bash "$(audit_abs)"
    [ "$status" -eq 2 ]
    [[ "$output" == *"git' was not found on PATH"* ]]
}

@test "target: audit maps a subdirectory target to the work-tree top level (issue #204)" {
    # Pre-fix, CA_TARGET_REPO=<repo>/sub reported "no .claude/ directory —
    # nothing to audit" for a repository whose root does carry .claude/.
    fixture="$BATS_TEST_TMPDIR/subdir-target"
    mkdir -p "$fixture/.claude" "$fixture/some/nested/dir"
    ( cd "$fixture" && git init -q )
    run env CA_TARGET_REPO="$fixture/some/nested/dir" "$TEST_BASH" "$AUDIT"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -qF "nothing to audit"
    [[ "$output" == *"[warn]"* ]]   # the root's real .claude/ was audited
}

@test "target: sync fails loudly from a non-git cwd and writes nothing (issue #204)" {
    # Pre-fix, a non-git cwd with a skills/ tree received "synced N skills" at
    # exit 0 and had plugin scaffolding written beneath it (the write-side
    # shape of #202).
    nongit="$BATS_TEST_TMPDIR/sync-nongit"
    mkdir -p "$nongit/skills/testing-guide"
    printf '# copy\n' > "$nongit/skills/testing-guide/SKILL.md"
    run "$TEST_BASH" -c "cd '$nongit' && bash '$SYNC_ABS'"
    [ "$status" -eq 2 ]
    [[ "$output" == *"not inside a git working tree"* ]]
    [ ! -d "$nongit/integrations" ]
}

@test "target: sync names a missing git binary (issue #204)" {
    fakebin="$BATS_TEST_TMPDIR/sync-fakebin"
    mkdir -p "$fakebin"
    ln -s "$(command -v bash)" "$fakebin/bash"
    run env PATH="$fakebin" bash "$SYNC_ABS"
    [ "$status" -eq 2 ]
    [[ "$output" == *"git' was not found on PATH"* ]]
}

@test "target: sync maps a subdirectory target to the work-tree top level (issue #204)" {
    fixture="$BATS_TEST_TMPDIR/sync-subdir"
    mkdir -p "$fixture/some/nested/dir"
    ( cd "$fixture" && git init -q )
    # Minimal source skills for every shipped name, so the run can fully sync.
    for s in role-aware-session framework-consumer-integration framework-health-audit \
             document-lifecycle testing-guide git-commit-identity git-branch-and-commit \
             gh-pr-workflow versioning-and-releases work-item-stance; do
        mkdir -p "$fixture/skills/$s"
        printf '# %s\n' "$s" > "$fixture/skills/$s/SKILL.md"
    done
    run env CA_TARGET_REPO="$fixture/some/nested/dir" "$TEST_BASH" "$SYNC"
    [ "$status" -eq 0 ]
    [[ "$output" == *"synced 10 skills"* ]]
    [ -f "$fixture/integrations/runtimes/claude-code/skills/testing-guide/SKILL.md" ]
}

@test "target: sync counts a missing source SKILL.md as a failed copy, not a skip (issue #204)" {
    # Pre-fix, the failures counter was never incremented, so a run that
    # copied almost nothing printed "synced 1 skills" and exited 0 while the
    # header contract said it "exits non-zero if any expected skill fails to
    # copy".
    fixture="$BATS_TEST_TMPDIR/sync-partial"
    mkdir -p "$fixture/skills/testing-guide"
    printf '# only this one\n' > "$fixture/skills/testing-guide/SKILL.md"
    ( cd "$fixture" && git init -q )
    run env CA_TARGET_REPO="$fixture" "$TEST_BASH" "$SYNC"
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot sync"* ]]
    [[ "$output" == *"skill(s) failed to sync"* ]]
}
