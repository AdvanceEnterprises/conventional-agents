#!/usr/bin/env bats
# FS-0029 SC-12 through SC-17 — label provisioning and drift reporting.

load "./helpers"

setup() {
    setup_binding_fixture
}

@test "SC-12: default mode creates only missing framework labels" {
    set_fake_labels $'enhancement\nquestion'

    run "$TEST_BASH" "$LABEL_PROVISION"
    [ "$status" -eq 0 ]
    [[ "$output" == *"created=4"* ]]
    [[ "$output" == *"existing=2"* ]]
    ! grep -F -q 'name=enhancement' "$FAKE_GH_TRACE"
    grep -F -q 'name=bug' "$FAKE_GH_TRACE"
    grep -F -q 'name=documentation' "$FAKE_GH_TRACE"
    grep -F -q 'name=spec' "$FAKE_GH_TRACE"
    grep -F -q 'name=plan' "$FAKE_GH_TRACE"
}

@test "SC-13: a second provision run creates nothing" {
    set_fake_labels $'enhancement\nbug\ndocumentation\nspec\nplan\nquestion'

    run "$TEST_BASH" "$LABEL_PROVISION"
    [ "$status" -eq 0 ]
    [[ "$output" == *"created=0"* ]]
    ! grep -F -q -- '--method POST' "$FAKE_GH_TRACE"
}

@test "SC-14 and SC-16: audit separates missing and unexpected without mutation" {
    set_fake_labels $'enhancement\nquestion\nconsumer-only'

    run "$TEST_BASH" "$LABEL_PROVISION" --audit
    [ "$status" -eq 0 ]
    [[ "$output" == *"LABEL AUDIT: missing"* ]]
    [[ "$output" == *"bug"* ]]
    [[ "$output" == *"LABEL AUDIT: unexpected"*"consumer-only"* ]]
    ! grep -F -q -- '--method POST' "$FAKE_GH_TRACE"
    ! grep -F -q -- 'issue edit' "$FAKE_GH_TRACE"
}

@test "SC-15: dry-run composes with audit and prints the would-create set" {
    set_fake_labels $'enhancement\nquestion\nconsumer-only'

    run "$TEST_BASH" "$LABEL_PROVISION" --audit --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN: would-create"* ]]
    [[ "$output" == *"bug"* ]]
    [[ "$output" == *"consumer-only"* ]]
    ! grep -F -q -- '--method POST' "$FAKE_GH_TRACE"
}

@test "SC-17: shipped vocabulary is exactly the FS-0018 six" {
    run grep -F 'FRAMEWORK_LABELS=' "$LABEL_PROVISION"
    [ "$status" -eq 0 ]
    [[ "$output" == *"enhancement bug documentation spec plan question"* ]]
    [[ "$output" != *"propagation"* ]]
}

@test "extension labels come from caller data without changing the framework set" {
    local extension_file="$TARGET_ROOT/config/github-labels.txt"
    mkdir -p "$(dirname "$extension_file")"
    printf '%s\n' 'consumer-extension' > "$extension_file"
    set_fake_labels $'enhancement\nbug\ndocumentation\nspec\nplan\nquestion'

    run "$TEST_BASH" "$LABEL_PROVISION" --extensions "$extension_file"
    [ "$status" -eq 0 ]
    grep -F -q 'name=consumer-extension' "$FAKE_GH_TRACE"
    grep -F -q 'created=1' <<< "$output"
}

@test "label validation failures do not masquerade as duplicate-label races" {
    set_fake_labels ''
    export FAKE_GH_LABEL_POST_RESPONSE='{"message":"Validation Failed","errors":[{"resource":"Label","code":"invalid","field":"name"}]}'
    export FAKE_GH_LABEL_POST_RC=1

    run "$TEST_BASH" "$LABEL_PROVISION"
    [ "$status" -ne 0 ]
    [[ "$output" == *"could not create label"* ]]
    ! grep -q '[^[:space:]]' "$FAKE_GH_LABELS"
}

@test "the specific duplicate-label response is treated as already existing" {
    set_fake_labels ''
    export FAKE_GH_LABEL_POST_RESPONSE='{"message":"Validation Failed","errors":[{"resource":"Label","code":"already_exists","field":"name"}]}'
    export FAKE_GH_LABEL_POST_RC=1

    run "$TEST_BASH" "$LABEL_PROVISION"
    [ "$status" -eq 0 ]
    [[ "$output" == *"created=0 existing=6"* ]]
}
