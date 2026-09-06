#!/usr/bin/env bats
# FS-0029 SC-6 through SC-11 — dual-regime submodule initialisation.

load "./helpers"

setup() {
    setup_binding_fixture
}

@test "SC-6: public framework initialises without a credential or warning" {
    run env -u CA_FRAMEWORK_TOKEN -u GH_TOKEN -u GITHUB_TOKEN bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"public framework example/framework"* ]]
    [[ "$output" != *"credential"* ]] || [[ "$output" == *"without a credential"* ]]
    grep -F -q 'git submodule update --init' "$FAKE_GIT_TRACE"
    ! grep -F -q -- 'config --global' "$FAKE_GIT_TRACE"
}

@test "SC-7: private framework without a credential fails closed" {
    FAKE_GH_VISIBILITY=private run env -u CA_FRAMEWORK_TOKEN -u GH_TOKEN -u GITHUB_TOKEN bash "$SUBMODULE_INIT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"CA_FRAMEWORK_TOKEN"* ]]
    ! grep -F -q 'git submodule update --init' "$FAKE_GIT_TRACE"
}

@test "SC-8: private credential configuration is explicitly global" {
    export FAKE_GH_VISIBILITY=private
    export CA_FRAMEWORK_TOKEN='test-only-secret'

    run bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    grep -F -q -- 'git config --global' "$FAKE_GIT_TRACE"
    grep -F -q 'example/framework' "$FAKE_GIT_TRACE"
    ! grep -F -q 'test-only-secret' "$GIT_CONFIG_GLOBAL"
}

@test "SC-9: private credential never appears in combined command output" {
    export FAKE_GH_VISIBILITY=private
    export CA_FRAMEWORK_TOKEN='test-only-secret'

    run bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    [[ "$output" != *"test-only-secret"* ]]
}

@test "SC-10: a second private initialisation leaves global git config byte-identical" {
    export FAKE_GH_VISIBILITY=private
    export CA_FRAMEWORK_TOKEN='test-only-secret'

    run bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    cp "$GIT_CONFIG_GLOBAL" "$BATS_TEST_TMPDIR/first.gitconfig"

    run bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    cmp -s "$BATS_TEST_TMPDIR/first.gitconfig" "$GIT_CONFIG_GLOBAL"
}

@test "credential is not exposed when submodule update fails" {
    export FAKE_GH_VISIBILITY=private
    export CA_FRAMEWORK_TOKEN='test-only-secret'
    export FAKE_GIT_SUBMODULE_RC=1

    run bash "$SUBMODULE_INIT"
    [ "$status" -ne 0 ]
    [[ "$output" != *"test-only-secret"* ]]
    [[ "$output" == *"submodule initialisation failed"* ]]
    ! grep -F -q 'test-only-secret' "$GIT_CONFIG_GLOBAL"
}

@test "private initialisation restores a pre-existing rewrite exactly" {
    old_key='url.https://x-access-token:old-secret@example.com/example/framework/.insteadOf'
    "$REAL_GIT" config --global "$old_key" 'https://example.com/example/framework/'
    cp "$GIT_CONFIG_GLOBAL" "$BATS_TEST_TMPDIR/before.gitconfig"
    export FAKE_GH_VISIBILITY=private
    export CA_FRAMEWORK_TOKEN='test-only-secret'

    run bash "$SUBMODULE_INIT"
    [ "$status" -eq 0 ]
    cmp -s "$BATS_TEST_TMPDIR/before.gitconfig" "$GIT_CONFIG_GLOBAL"
    ! grep -F -q 'test-only-secret' "$GIT_CONFIG_GLOBAL"
}

@test "SC-11: indeterminate visibility fails instead of guessing a regime" {
    FAKE_GH_VISIBILITY=unknown run bash "$SUBMODULE_INIT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown visibility"* ]]
    ! grep -F -q 'git submodule update --init' "$FAKE_GIT_TRACE"
}
