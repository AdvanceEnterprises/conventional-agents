#!/usr/bin/env bash

# Build an isolated target repository and deterministic gh/git/sleep doubles.
setup_binding_fixture() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    BINDING_ROOT="$REPO_ROOT/integrations/github"
    SUBMODULE_INIT="$BINDING_ROOT/bin/gh-submodule-init.sh"
    LABEL_PROVISION="$BINDING_ROOT/bin/gh-label-provision.sh"
    BOARD_AUDIT="$BINDING_ROOT/bin/gh-board-audit.sh"
    TARGET_ROOT="$BATS_TEST_TMPDIR/target"
    FAKE_BIN="$BATS_TEST_TMPDIR/bin"
    FAKE_GH_TRACE="$BATS_TEST_TMPDIR/gh.trace"
    FAKE_GIT_TRACE="$BATS_TEST_TMPDIR/git.trace"
    FAKE_GIT_ASKPASS_TRACE="$BATS_TEST_TMPDIR/git-askpass.trace"
    FAKE_SLEEP_TRACE="$BATS_TEST_TMPDIR/sleep.trace"
    FAKE_GH_LABELS="$BATS_TEST_TMPDIR/labels"
    FAKE_GH_ISSUES="$BATS_TEST_TMPDIR/issues"
    FAKE_GH_GRAPHQL_DIR="$BATS_TEST_TMPDIR/graphql"
    GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"

    mkdir -p "$TARGET_ROOT" "$FAKE_BIN" "$FAKE_GH_GRAPHQL_DIR"
    (cd "$TARGET_ROOT" && git init -q && git remote add origin https://github.com/example/target.git)
    : > "$FAKE_GH_TRACE"
    : > "$FAKE_GIT_TRACE"
    : > "$FAKE_GIT_ASKPASS_TRACE"
    : > "$FAKE_SLEEP_TRACE"
    : > "$FAKE_GH_LABELS"
    : > "$FAKE_GH_ISSUES"
    : > "$GIT_CONFIG_GLOBAL"

    export REPO_ROOT BINDING_ROOT SUBMODULE_INIT LABEL_PROVISION BOARD_AUDIT
    export TARGET_ROOT FAKE_BIN FAKE_GH_TRACE FAKE_GIT_TRACE FAKE_GIT_ASKPASS_TRACE FAKE_SLEEP_TRACE
    export FAKE_GH_LABELS FAKE_GH_ISSUES FAKE_GH_GRAPHQL_DIR GIT_CONFIG_GLOBAL
    # Binding commands may be exercised with an explicit Bash 3.2 binary.
    export TEST_BASH="${CA_BASH_FOR_TESTS:-bash}"
    export CA_TARGET_REPO="$TARGET_ROOT"
    export CA_GITHUB_REPOSITORY="example/target"
    export CA_FRAMEWORK_REPOSITORY="example/framework"
    export CA_GRAPHQL_MIN_INTERVAL=0
    export CA_GRAPHQL_MAX_ATTEMPTS=3
    export CA_GRAPHQL_BACKOFF_BASE_SECONDS=1
    export CA_GRAPHQL_BACKOFF_MAX_SECONDS=60
    export CA_RATE_LIMIT_BUFFER_SECONDS=0
    export FAKE_GH_AUTH=ok
    export FAKE_GH_VISIBILITY=public
    export FAKE_GH_ISSUE_RC=0
    export FAKE_GH_GRAPHQL_COUNT_FILE="$BATS_TEST_TMPDIR/graphql.count"
    printf '0\n' > "$FAKE_GH_GRAPHQL_COUNT_FILE"
    export REAL_GIT="$(command -v git)"
    export PATH="$FAKE_BIN:$PATH"

    cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'gh' >> "$FAKE_GH_TRACE"
for argument in "$@"; do
    printf ' %q' "$argument" >> "$FAKE_GH_TRACE"
done
printf '\n' >> "$FAKE_GH_TRACE"

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
    if [[ "${FAKE_GH_AUTH:-ok}" == "fail" ]]; then
        printf 'not authenticated\n' >&2
        exit 1
    fi
    printf 'authenticated\n'
    exit 0
fi

[[ "${1:-}" == "api" ]] || { printf 'unsupported fake gh command\n' >&2; exit 1; }
shift
endpoint="${1:-}"
shift || true

if [[ "$endpoint" == "graphql" ]]; then
    count="$(<"$FAKE_GH_GRAPHQL_COUNT_FILE")"
    count=$((count + 1))
    printf '%s\n' "$count" > "$FAKE_GH_GRAPHQL_COUNT_FILE"
    response_file="$FAKE_GH_GRAPHQL_DIR/$count.out"
    error_file="$FAKE_GH_GRAPHQL_DIR/$count.err"
    rc_file="$FAKE_GH_GRAPHQL_DIR/$count.rc"
    [[ -f "$response_file" ]] || { printf 'missing fake GraphQL response %s\n' "$count" >&2; exit 1; }
    if [[ -s "$response_file" ]]; then
        printf '%s\n' "$(<"$response_file")"
    fi
    if [[ -s "$error_file" ]]; then
        printf '%s\n' "$(<"$error_file")" >&2
    fi
    if [[ -f "$rc_file" ]]; then
        exit "$(<"$rc_file")"
    fi
    exit 0
fi

if [[ "$endpoint" == repos/*/labels\?* ]]; then
    if [[ -s "$FAKE_GH_LABELS" ]]; then
        printf '%s\n' "$(<"$FAKE_GH_LABELS")"
    fi
    exit 0
fi

if [[ "$endpoint" == repos/*/labels ]]; then
    method=GET
    label_name=""
    previous=""
    while (( $# > 0 )); do
        case "$1" in
            --method)
                method="$2"
                shift 2
                ;;
            -f)
                if [[ "$2" == name=* ]]; then
                    label_name="${2#name=}"
                fi
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    if [[ "$method" == "POST" ]]; then
        if [[ -n "${FAKE_GH_LABEL_POST_RESPONSE:-}" ]]; then
            printf '%s\n' "$FAKE_GH_LABEL_POST_RESPONSE"
            exit "${FAKE_GH_LABEL_POST_RC:-1}"
        fi
        if [[ -s "$FAKE_GH_LABELS" ]]; then
            previous="$(<"$FAKE_GH_LABELS")"
        fi
        if ! printf '%s\n' "$previous" | grep -F -x -q -- "$label_name"; then
            printf '%s\n' "$previous" "$label_name" | sed '/^$/d' > "$FAKE_GH_LABELS.tmp"
            mv "$FAKE_GH_LABELS.tmp" "$FAKE_GH_LABELS"
        fi
    fi
    printf '{}\n'
    exit 0
fi

if [[ "$endpoint" == repos/*/issues\?* ]]; then
    if [[ "${FAKE_GH_ISSUE_RC:-0}" != "0" ]]; then
        printf 'fake issue enumeration failure\n' >&2
        exit "$FAKE_GH_ISSUE_RC"
    fi
    if [[ -s "$FAKE_GH_ISSUES" ]]; then
        printf '%s\n' "$(<"$FAKE_GH_ISSUES")"
    fi
    exit 0
fi

if [[ "$endpoint" == repos/* ]]; then
    [[ "${FAKE_GH_VISIBILITY:-public}" != "error" ]] || { printf 'fake visibility failure\n' >&2; exit 1; }
    printf '%s\n' "${FAKE_GH_VISIBILITY:-public}"
    exit 0
fi

printf 'unsupported fake API endpoint: %s\n' "$endpoint" >&2
exit 1
EOF
    chmod +x "$FAKE_BIN/gh"

    cat > "$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'git' >> "$FAKE_GIT_TRACE"
for argument in "$@"; do
    printf ' %q' "$argument" >> "$FAKE_GIT_TRACE"
done
printf '\n' >> "$FAKE_GIT_TRACE"
if [[ "${1:-}" == "submodule" ]]; then
    printf '%s\n' "${GIT_ASKPASS:-}" > "$FAKE_GIT_ASKPASS_TRACE"
    if [[ -n "${FAKE_GIT_SUBMODULE_ERROR:-}" ]]; then
        printf '%s\n' "$FAKE_GIT_SUBMODULE_ERROR" >&2
    fi
    exit "${FAKE_GIT_SUBMODULE_RC:-0}"
fi
exec "$REAL_GIT" "$@"
EOF
    chmod +x "$FAKE_BIN/git"

    cat > "$FAKE_BIN/sleep" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FAKE_SLEEP_TRACE"
EOF
    chmod +x "$FAKE_BIN/sleep"
}

write_graphql_step() {
    local step="$1"
    local output="$2"
    local error_output="${3:-}"
    local return_code="${4:-0}"

    printf '%s\n' "$output" > "$FAKE_GH_GRAPHQL_DIR/$step.out"
    printf '%s\n' "$error_output" > "$FAKE_GH_GRAPHQL_DIR/$step.err"
    printf '%s\n' "$return_code" > "$FAKE_GH_GRAPHQL_DIR/$step.rc"
}

set_fake_labels() {
    printf '%s\n' "$1" > "$FAKE_GH_LABELS"
}

set_fake_issues() {
    printf '%s\n' "$1" > "$FAKE_GH_ISSUES"
}

assert_trace_has() {
    local pattern="$1"
    grep -F -q -- "$pattern" "$FAKE_GH_TRACE" "$FAKE_GIT_TRACE" "$FAKE_SLEEP_TRACE"
}

assert_no_api_trace() {
    ! grep -F -q -- 'gh api' "$FAKE_GH_TRACE"
}
