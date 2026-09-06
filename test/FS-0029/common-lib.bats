#!/usr/bin/env bats
# FS-0029 SC-1 through SC-5 — shared command behaviour.

load "./helpers"

setup() {
    setup_binding_fixture
}

@test "SC-1: every binding command documents its interface in --help" {
    local command
    for command in "$SUBMODULE_INIT" "$LABEL_PROVISION" "$BOARD_AUDIT"; do
        run bash "$command" --help
        [ "$status" -eq 0 ]
        [[ "$output" == *"--help"* ]]
        [[ "$output" == *"CA_TARGET_REPO"* ]]
    done
}

@test "SC-2: unauthenticated API commands fail before an API call" {
    write_graphql_step 1 '__NO_PROJECT__'
    FAKE_GH_AUTH=fail run bash "$LABEL_PROVISION" --audit
    [ "$status" -ne 0 ]
    [[ "$output" == *"gh auth status"* ]]
    assert_no_api_trace
}

@test "SC-3: CA_TARGET_REPO resolves the caller target from outside that repository" {
    write_graphql_step 1 '__NO_PROJECT__'
    local elsewhere="$BATS_TEST_TMPDIR/elsewhere"
    mkdir -p "$elsewhere"

    run bash -c "cd '$elsewhere' && CA_TARGET_REPO='$TARGET_ROOT' CA_GITHUB_REPOSITORY='example/target' bash '$LABEL_PROVISION' --audit"
    [ "$status" -eq 0 ]
    [[ "$output" == *"LABEL SUMMARY"* ]]
    grep -F -q 'repos/example/target/labels' "$FAKE_GH_TRACE"
}

@test "SC-4: shipped command sources contain no vendor path reads" {
    ! grep -R -n -F -- 'vendor/' "$BINDING_ROOT/bin" "$BINDING_ROOT/lib"
}

@test "SC-5: a visibility API failure names the condition and remediation" {
    FAKE_GH_VISIBILITY=error run bash "$SUBMODULE_INIT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot determine visibility"* ]]
    [[ "$output" == *"gh auth status"* ]]
}

@test "repository resolution strips .git from HTTPS and SSH remotes" {
    run bash -c "source '$BINDING_ROOT/lib/gh-common.sh'; gh_common_repository_from_remote 'https://github.com/example/target.git'; gh_common_repository_from_remote 'git@github.com:example/target.git'"
    [ "$status" -eq 0 ]
    [ "$output" = $'example/target\nexample/target' ]
}
