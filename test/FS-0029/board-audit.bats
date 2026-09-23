#!/usr/bin/env bats
# FS-0029 SC-18 through SC-23 — read-only Project board audit.

load "./helpers"

setup() {
    setup_binding_fixture
}

board_with_drift() {
    write_graphql_step 1 $'__PROJECT_PRESENT__\nitem-101\x1fIssue\x1f101\x1fexample/target\x1f__UNSET__\x1fIn Progress\nitem-102\x1fIssue\x1f102\x1fexample/target\x1ffeature\x1f__UNSET__\n__DONE__'
    set_fake_issues $'101\thttps://example.invalid/issues/101\n102\thttps://example.invalid/issues/102\n103\thttps://example.invalid/issues/103'
}

board_with_non_issue_drift() {
    write_graphql_step 1 $'__PROJECT_PRESENT__\nitem-pr-201\x1fPullRequest\x1f\x1f\x1f__UNSET__\x1f__UNSET__\n__DONE__'
    set_fake_issues ''
}

@test "SC-18: board audit source contains no mutating project or issue operation" {
    ! grep -E -n -- 'item-add|item-edit|--single-select-option-id|issue edit|issue create' "$BOARD_AUDIT"
}

@test "board audit supports the FS-0011 Doc Type compatibility field" {
    grep -F -q 'Doc Type' "$BOARD_AUDIT"
    grep -F -q 'Issue Type' "$BOARD_AUDIT"
}

@test "SC-19 and SC-22: audit reports three drift categories and exits zero" {
    board_with_drift

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    [[ "$output" == *"BOARD AUDIT: unset-issue-type"* ]]
    [[ "$output" == *"example/target#101"* ]]
    [[ "$output" == *"BOARD AUDIT: unset-status"* ]]
    [[ "$output" == *"example/target#102"* ]]
    [[ "$output" == *"BOARD AUDIT: open-issues-without-project-item"* ]]
    [[ "$output" == *"example/target#103"* ]]
    [[ "$output" == *"BOARD SUMMARY: unset-issue-type=1 unset-status=1 absent-from-board=1"* ]]
}

@test "SC-22: strict mode makes findings fail while default mode stays informational" {
    board_with_drift

    run "$TEST_BASH" "$BOARD_AUDIT" --strict --project 2 --owner example --repository example/target
    [ "$status" -eq 1 ]
    [[ "$output" == *"--strict treats findings as a failure"* ]]
}

@test "SC-23: a missing project is a clean, explicit report" {
    write_graphql_step 1 '__NO_PROJECT__'

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    [[ "$output" == *"BOARD AUDIT: project=absent"* ]]
    [[ "$output" == *"project-absent=1"* ]]
}

@test "SC-20: successive GraphQL calls honor the configurable interval" {
    write_graphql_step 1 $'__PROJECT_PRESENT__\n__NEXT_CURSOR__\x1fcursor-one'
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MIN_INTERVAL=3

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '3' "$FAKE_SLEEP_TRACE"
}

@test "SC-21: reset timestamp is honored with a buffer before retry" {
    write_graphql_step 1 '' '{"type":"RATE_LIMIT","resetAt":"102"}' 1
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MAX_ATTEMPTS=2
    export CA_NOW_EPOCH=100
    export CA_RATE_LIMIT_BUFFER_SECONDS=1

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '3' "$FAKE_SLEEP_TRACE"
    ! grep -F -q 'rate_limit' "$FAKE_GH_TRACE"
}

@test "SC-21: Retry-After is honored when no reset timestamp is supplied" {
    write_graphql_step 1 '' 'RATE_LIMIT Retry-After: 4' 1
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MAX_ATTEMPTS=2

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '4' "$FAKE_SLEEP_TRACE"
}

@test "SC-21: rate-limit retry uses bounded exponential backoff without a reset" {
    write_graphql_step 1 '' 'RATE_LIMIT secondary burst limit' 1
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MAX_ATTEMPTS=2
    export CA_GRAPHQL_BACKOFF_BASE_SECONDS=2

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '2' "$FAKE_SLEEP_TRACE"
}

@test "SC-21: reset waits honor the server value beyond the exponential cap" {
    write_graphql_step 1 '' '{"type":"RATE_LIMIT","resetAt":"1100"}' 1
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MAX_ATTEMPTS=2
    export CA_GRAPHQL_BACKOFF_MAX_SECONDS=60
    export CA_NOW_EPOCH=100
    export CA_RATE_LIMIT_BUFFER_SECONDS=1

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '1001' "$FAKE_SLEEP_TRACE"
}

@test "SC-21: Retry-After waits honor the server value beyond the exponential cap" {
    write_graphql_step 1 '' 'RATE_LIMIT Retry-After: 3600' 1
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MAX_ATTEMPTS=2
    export CA_GRAPHQL_BACKOFF_MAX_SECONDS=60

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    grep -F -q '3600' "$FAKE_SLEEP_TRACE"
}

@test "SC-21: excessive server-directed waits fail instead of sleeping unbounded" {
    write_graphql_step 1 '' '{"type":"RATE_LIMIT","resetAt":"5000"}' 1
    export CA_GRAPHQL_MAX_ATTEMPTS=2
    export CA_GRAPHQL_SERVER_WAIT_MAX_SECONDS=3600
    export CA_NOW_EPOCH=100
    export CA_RATE_LIMIT_BUFFER_SECONDS=1

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -ne 0 ]
    [[ "$output" == *"server-directed wait"* ]]
    ! grep -F -q '4901' "$FAKE_SLEEP_TRACE"
}

@test "successful Project content named Rate limited is not retried" {
    write_graphql_step 1 $'__PROJECT_PRESENT__\nRate limited\n__DONE__'
    set_fake_issues ''

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    [ "$(<"$FAKE_GH_GRAPHQL_COUNT_FILE")" -eq 1 ]
}

@test "unknown owner type is reported as an API error without rate-limit retries" {
    write_graphql_step 1 '' 'unknown owner type' 1

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -ne 0 ]
    [ "$(<"$FAKE_GH_GRAPHQL_COUNT_FILE")" -eq 1 ]
    [[ "$output" == *"GraphQL request failed"* ]]
}

@test "GraphQL progress diagnostics stay on stderr, outside parsed board data" {
    write_graphql_step 1 $'__PROJECT_PRESENT__\n__NEXT_CURSOR__\x1fcursor-one'
    write_graphql_step 2 $'__PROJECT_PRESENT__\n__DONE__'
    export CA_GRAPHQL_MIN_INTERVAL=1

    "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target \
        > "$BATS_TEST_TMPDIR/board.stdout" 2> "$BATS_TEST_TMPDIR/board.stderr"
    [ "$?" -eq 0 ]
    ! grep -F -q 'INFO:' "$BATS_TEST_TMPDIR/board.stdout"
    grep -F -q 'INFO:' "$BATS_TEST_TMPDIR/board.stderr"
}

@test "board audit counts non-Issue Project items for field drift" {
    board_with_non_issue_drift

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    [[ "$output" == *"item:item-pr-201 (PullRequest)"* ]]
    [[ "$output" == *"BOARD SUMMARY: unset-issue-type=1 unset-status=1 absent-from-board=0"* ]]
}

@test "regression #171: a PullRequest with set fields is not counted as drift" {
    # Tab is IFS whitespace, so a tab-delimited row with empty middle cells
    # collapses and shifts every later field — which reported every
    # PullRequest as both type-unset and status-unset. Rows now use \x1f.
    write_graphql_step 1 $'__PROJECT_PRESENT__\nitem-pr-301\x1fPullRequest\x1f\x1f\x1ffeature\x1fIn Review\n__DONE__'
    set_fake_issues ''

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -eq 0 ]
    [[ "$output" == *"BOARD SUMMARY: unset-issue-type=0 unset-status=0 absent-from-board=0"* ]]
    [[ "$output" != *"item:item-pr-301"* ]]
}

@test "SC-23: API failure is operationally distinct from drift" {
    board_with_drift
    export FAKE_GH_ISSUE_RC=1

    run "$TEST_BASH" "$BOARD_AUDIT" --project 2 --owner example --repository example/target
    [ "$status" -ne 0 ]
    [[ "$output" == *"could not enumerate open Issues"* ]]
    [[ "$output" != *"BOARD SUMMARY"* ]]
}
