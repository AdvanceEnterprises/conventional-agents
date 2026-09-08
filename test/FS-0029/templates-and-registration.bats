#!/usr/bin/env bats
# FS-0029 SC-24 through SC-33 — templates, registration, and documentation.

load "./helpers"

setup() {
    setup_binding_fixture
}

@test "SC-24: shipped templates contain no instance-specific repository data" {
    ! grep -R -n -E 'Tais-Den|ajoeofalltrades|pack-protocol|feral-fleet|[0-9]{6,}|ghp_[A-Za-z0-9]+' \
        "$BINDING_ROOT/ci-templates" "$BINDING_ROOT/templates"
}

@test "SC-25: the GitHub integration layer contains no scheduled trigger" {
    ! grep -R -n -F -- 'schedule:' "$BINDING_ROOT"
}

@test "SC-26: submodule template uses complete history and the shared initializer" {
    local template="$BINDING_ROOT/ci-templates/submodule-checkout.yml"
    grep -F -q 'fetch-depth: 0' "$template"
    grep -F -q 'submodules: true' "$template"
    grep -F -q 'persist-credentials: false' "$template"
    grep -F -q 'gh-submodule-init.sh' "$template"
    ! grep -F -q 'insteadOf' "$template"
}

@test "SC-27: framework pull-request template carries every shipped section" {
    local shipped="$BINDING_ROOT/templates/pull-request.md"
    local adopted="$REPO_ROOT/.github/pull_request_template.md"
    diff -u <(grep '^## ' "$shipped") <(grep '^## ' "$adopted")
}

@test "SC-28 and SC-29: binding README classifies commands and records hazards" {
    local readme="$BINDING_ROOT/README.md"
    grep -F -q 'gh-submodule-init.sh' "$readme"
    grep -F -q '**enforces**' "$readme"
    grep -F -q 'gh-label-provision.sh' "$readme"
    grep -F -q '**provisions**' "$readme"
    grep -F -q 'gh-board-audit.sh' "$readme"
    grep -F -q '**reports**' "$readme"
    grep -F -q -- '--global' "$readme"
    grep -F -q 'unknown owner type' "$readme"
    grep -F -q 'gh pr edit --body' "$readme"
    grep -F -q 'gh api -X PATCH' "$readme"
    grep -F -q 'reviewDecision' "$readme"
    grep -F -q '60 days' "$readme"
}

@test "SC-30: each executable is registered and scripts README explains the boundary" {
    grep -F -q '"github:submodule-init"' "$REPO_ROOT/package.json"
    grep -F -q '"github:label-provision"' "$REPO_ROOT/package.json"
    grep -F -q '"github:board-audit"' "$REPO_ROOT/package.json"
    grep -F -q 'GitHub binding executables' "$REPO_ROOT/scripts/README.md"
    grep -F -q 'not Category 1 governance gates' "$REPO_ROOT/scripts/README.md"
}

@test "SC-31: integration markdown lint is recursive" {
    grep -F -q 'integrations/**/*.md' "$REPO_ROOT/package.json"
}

@test "SC-32: every binding README path resolves" {
    local path
    while IFS= read -r path; do
        [[ -e "$REPO_ROOT/$path" ]]
    done < <(grep -oE '`integrations/[^`]+`' "$BINDING_ROOT/README.md" | tr -d '`')
}

@test "SC-33: all shipped shell files pass bash syntax" {
    local file
    while IFS= read -r file; do
        "$TEST_BASH" -n "$file"
    done < <(find "$BINDING_ROOT" -type f -name '*.sh' -print)
}
