#!/usr/bin/env bash
# gh-common: shared, caller-relative helpers for the GitHub binding commands.
#
# The library is Bash 3.2 compatible. It deliberately contains no scheduler,
# repository-specific identifiers, or mutating work-item operation.
set -euo pipefail

GH_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GH_COMMON_GRAPHQL_CALLS=0

# Print an actionable error without terminating the caller.
gh_common_error() {
    printf 'ERROR: %s\n' "$*" >&2
}

# Print normal progress information.
gh_common_info() {
    printf 'INFO: %s\n' "$*"
}

# Require a command before a later operation depends on it.
gh_common_require_command() {
    local command_name="$1"
    local remediation="${2:-Install '$command_name' and retry.}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        gh_common_error "'$command_name' is required; $remediation"
        return 1
    fi
}

# Require the GitHub CLI and git for every binding command.
gh_common_require_base_tools() {
    gh_common_require_command gh "Install GitHub CLI and retry."
    gh_common_require_command git "Install git and retry."
}

# Verify GitHub CLI authentication before any API call.
gh_common_auth_check() {
    if ! gh auth status >/dev/null 2>&1; then
        gh_common_error "GitHub CLI is not authenticated; run 'gh auth status' and authenticate before retrying."
        return 1
    fi
}

# Resolve the repository that the caller means to operate on.
#
# CA_TARGET_REPO is a filesystem path override. Without it, resolution is
# caller-relative so a vendored copy operates on the host repository.
gh_common_resolve_target_root() {
    local target_root

    if [[ -n "${CA_TARGET_REPO:-}" ]]; then
        if ! target_root="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"; then
            gh_common_error "CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory."
            return 1
        fi
    else
        if ! target_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
            gh_common_error "cannot resolve the caller's repository; run from inside a git repository or set CA_TARGET_REPO."
            return 1
        fi
    fi

    printf '%s\n' "$target_root"
}

# Extract owner/repository from a GitHub remote URL.
gh_common_repository_from_remote() {
    local remote_url="$1"
    local repository

    remote_url="${remote_url%.git}"
    repository="$(printf '%s\n' "$remote_url" | sed -nE 's#.*github\.com[:/]([^/]+/[^/]+)$#\1#p')"
    if [[ -z "$repository" ]]; then
        return 1
    fi
    printf '%s\n' "$repository"
}

# Resolve the target repository slug, with an explicit caller override.
gh_common_resolve_repository() {
    local target_root="$1"
    local remote_url repository

    if [[ -n "${CA_GITHUB_REPOSITORY:-}" ]]; then
        repository="$CA_GITHUB_REPOSITORY"
    else
        if ! remote_url="$(git -C "$target_root" remote get-url origin 2>/dev/null)"; then
            gh_common_error "cannot resolve the GitHub repository; set CA_GITHUB_REPOSITORY to owner/name."
            return 1
        fi
        if ! repository="$(gh_common_repository_from_remote "$remote_url")"; then
            gh_common_error "origin is not a github.com remote; set CA_GITHUB_REPOSITORY to owner/name."
            return 1
        fi
    fi

    if [[ "$repository" != */* || "$repository" == */*/* ]]; then
        gh_common_error "CA_GITHUB_REPOSITORY must be owner/name, got '$repository'."
        return 1
    fi
    printf '%s\n' "$repository"
}

# Resolve the framework repository from the caller's explicit value or its own
# git remote. Consumers should set CA_FRAMEWORK_REPOSITORY when the framework
# remote is not available from the checked-out binding copy.
gh_common_resolve_framework_repository() {
    local framework_root remote_url repository

    if [[ -n "${CA_FRAMEWORK_REPOSITORY:-}" ]]; then
        repository="$CA_FRAMEWORK_REPOSITORY"
    else
        framework_root="$(cd "$GH_COMMON_DIR/../../.." && pwd)"
        if ! remote_url="$(git -C "$framework_root" remote get-url origin 2>/dev/null)"; then
            gh_common_error "cannot resolve the framework repository; set CA_FRAMEWORK_REPOSITORY to owner/name."
            return 1
        fi
        if ! repository="$(gh_common_repository_from_remote "$remote_url")"; then
            gh_common_error "the framework remote is not a github.com URL; set CA_FRAMEWORK_REPOSITORY to owner/name."
            return 1
        fi
    fi

    if [[ "$repository" != */* || "$repository" == */*/* ]]; then
        gh_common_error "CA_FRAMEWORK_REPOSITORY must be owner/name, got '$repository'."
        return 1
    fi
    printf '%s\n' "$repository"
}

# Return the first owner/name component of a repository slug.
gh_common_repository_owner() {
    printf '%s\n' "${1%%/*}"
}

# Return the repository-name component of a repository slug.
gh_common_repository_name() {
    printf '%s\n' "${1#*/}"
}

# Read the token used only for private framework submodule checkout.
gh_common_framework_token() {
    if [[ -n "${CA_FRAMEWORK_TOKEN:-}" ]]; then
        printf '%s\n' "$CA_FRAMEWORK_TOKEN"
    elif [[ -n "${GH_TOKEN:-}" ]]; then
        printf '%s\n' "$GH_TOKEN"
    elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
        printf '%s\n' "$GITHUB_TOKEN"
    else
        printf '%s\n' ""
    fi
}

# Resolve the git host used by the credential rewrite.
gh_common_git_host() {
    printf '%s\n' "${CA_GIT_HOST:-github.com}"
}

# Ask GitHub for repository visibility. Authentication is checked first.
gh_common_repository_visibility() {
    local repository="$1"
    local visibility

    gh_common_auth_check || return 1
    if ! visibility="$(gh api "repos/$repository" --jq '.visibility' 2>/dev/null)"; then
        gh_common_error "cannot determine visibility for '$repository'; verify access with 'gh auth status' and retry."
        return 1
    fi

    visibility="$(printf '%s' "$visibility" | tr -d '[:space:]')"
    case "$visibility" in
        public|private)
            printf '%s\n' "$visibility"
            ;;
        *)
            gh_common_error "GitHub returned an unknown visibility for '$repository'; refusing to guess public or private."
            return 1
            ;;
    esac
}

# Configure a scoped global insteadOf rewrite for a private framework clone.
# The token is never printed by this function.
gh_common_configure_git_credentials() {
    local token="$1"
    local repository="$2"
    local host="${3:-$(gh_common_git_host)}"

    git config --global \
        "url.https://x-access-token:${token}@${host}/${repository}/.insteadOf" \
        "https://${host}/${repository}/" >/dev/null 2>&1
}

# Initialise submodules from the caller's target repository.
gh_common_update_submodules() {
    local target_root="$1"

    if ! (cd "$target_root" && git submodule update --init) >/dev/null 2>&1; then
        gh_common_error "submodule initialisation failed; verify git access and the configured credential."
        return 1
    fi
}

# Sleep without doing work when the configured interval is zero.
gh_common_sleep() {
    local seconds="$1"

    if [[ "$seconds" == "0" ]]; then
        return 0
    fi
    sleep "$seconds"
}

# Pace successive GraphQL calls. The default protects the invisible secondary
# burst limit; tests and controlled operators may set the interval to zero.
gh_common_pace_graphql() {
    local interval="${CA_GRAPHQL_MIN_INTERVAL:-7}"

    if [[ ! "$interval" =~ ^[0-9]+$ ]]; then
        gh_common_error "CA_GRAPHQL_MIN_INTERVAL must be a non-negative integer."
        return 1
    fi
    if (( GH_COMMON_GRAPHQL_CALLS > 0 && interval > 0 )); then
        gh_common_info "pacing the next GraphQL call for ${interval}s"
        gh_common_sleep "$interval"
    fi
    GH_COMMON_GRAPHQL_CALLS=$((GH_COMMON_GRAPHQL_CALLS + 1))
}

# Determine whether captured gh output represents a rate-limit response.
gh_common_is_rate_limited() {
    local output="$1"

    if printf '%s\n' "$output" | grep -Eiq \
        '(^|[^[:alnum:]])RATE_LIMIT(ED)?([^[:alnum:]]|$)|rate limit|secondary rate|unknown owner type|HTTP[^0-9]*(403|429)|status[^0-9]*(403|429)|(^|[[:space:]])Retry-After:[[:space:]]*[0-9]+'; then
        return 0
    fi
    return 1
}

# Extract a Retry-After value from a response or error message.
gh_common_retry_after() {
    local output="$1"
    local value

    value="$(printf '%s\n' "$output" | sed -nE 's/.*[Rr]etry-[Aa]fter:[[:space:]]*([0-9]+).*/\1/p' | head -1)"
    if [[ -z "$value" ]]; then
        value="$(printf '%s\n' "$output" | sed -nE 's/.*"retry_after"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' | head -1)"
    fi
    printf '%s\n' "$value"
}

# Extract a reset timestamp, accepting epoch seconds or an ISO timestamp.
gh_common_reset_epoch() {
    local output="$1"
    local reset_value reset_epoch

    reset_value="$(printf '%s\n' "$output" | sed -nE 's/.*"resetAt"[[:space:]]*:[[:space:]]*"?([^",} ]+)"?.*/\1/p' | head -1)"
    if [[ -z "$reset_value" ]]; then
        reset_value="$(printf '%s\n' "$output" | sed -nE 's/.*"reset_at"[[:space:]]*:[[:space:]]*"?([^",} ]+)"?.*/\1/p' | head -1)"
    fi
    if [[ -z "$reset_value" ]]; then
        printf '%s\n' ""
        return 0
    fi

    if [[ "$reset_value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$reset_value"
        return 0
    fi
    if reset_epoch="$(date -d "$reset_value" +%s 2>/dev/null)" && [[ -n "$reset_epoch" ]]; then
        printf '%s\n' "$reset_epoch"
        return 0
    fi
    if reset_epoch="$(date -j -f '%Y-%m-%dT%H:%M:%SZ' "$reset_value" +%s 2>/dev/null)" && [[ -n "$reset_epoch" ]]; then
        printf '%s\n' "$reset_epoch"
        return 0
    fi
    printf '%s\n' ""
}

# Calculate a bounded wait for a rate-limited GraphQL call.
gh_common_rate_wait() {
    local output="$1"
    local attempt="$2"
    local retry_after reset_epoch now_epoch buffer base maximum wait multiplier

    buffer="${CA_RATE_LIMIT_BUFFER_SECONDS:-1}"
    base="${CA_GRAPHQL_BACKOFF_BASE_SECONDS:-1}"
    maximum="${CA_GRAPHQL_BACKOFF_MAX_SECONDS:-60}"

    retry_after="$(gh_common_retry_after "$output")"
    if [[ -n "$retry_after" ]]; then
        wait=$((retry_after + buffer))
    else
        reset_epoch="$(gh_common_reset_epoch "$output")"
        if [[ -n "$reset_epoch" ]]; then
            now_epoch="${CA_NOW_EPOCH:-$(date +%s)}"
            wait=$((reset_epoch - now_epoch + buffer))
            if (( wait < buffer )); then
                wait="$buffer"
            fi
        else
            multiplier=1
            for (( i = 1; i < attempt; i++ )); do
                multiplier=$((multiplier * 2))
            done
            wait=$((base * multiplier))
        fi
    fi

    [[ "$wait" =~ ^[0-9]+$ ]] || wait="$base"
    (( wait > maximum )) && wait="$maximum"
    printf '%s\n' "$wait"
}

# Remove an optional HTTP response header block emitted by gh --include.
gh_common_body_only() {
    local response="$1"

    if printf '%s\n' "$response" | grep -qE '^HTTP/[0-9]'; then
        printf '%s\n' "$response" | awk 'BEGIN { body = 0 } { sub(/\r$/, "") } body { print } !body && /^$/ { body = 1 }'
    else
        printf '%s\n' "$response"
    fi
}

# Run a GraphQL request with pacing and bounded rate-limit backoff.
#
# Arguments:
#   $1  GraphQL query
#   $2  gh --jq filter (empty for raw response)
#   $@ after $2  additional gh api arguments, such as -F owner=...
#
# The function prints the filtered response on success and returns non-zero on
# authentication, transport, malformed, or exhausted-rate-limit failure.
gh_common_graphql() {
    local query="$1"
    local jq_filter="$2"
    shift 2
    local max_attempts="${CA_GRAPHQL_MAX_ATTEMPTS:-3}"
    local attempt=1
    local output error_output combined body
    local args api_args error_file wait_seconds

    api_args=("$@")

    if [[ ! "$max_attempts" =~ ^[1-9][0-9]*$ ]]; then
        gh_common_error "CA_GRAPHQL_MAX_ATTEMPTS must be a positive integer."
        return 1
    fi

    while (( attempt <= max_attempts )); do
        gh_common_auth_check || return 1
        gh_common_pace_graphql || return 1
        output=""
        error_output=""
        args=(graphql --include -f "query=$query")
        for api_arg in "${api_args[@]}"; do
            args+=("$api_arg")
        done
        if [[ -n "$jq_filter" ]]; then
            args+=(--jq "$jq_filter")
        fi

        error_file="$(mktemp)"
        if output="$(gh api "${args[@]}" 2>"$error_file")"; then
            error_output="$(<"$error_file")"
            rm -f "$error_file"
            combined="$output
$error_output"
            if ! gh_common_is_rate_limited "$combined"; then
                body="$(gh_common_body_only "$output")"
                printf '%s\n' "$body"
                return 0
            fi
        else
            error_output="$(<"$error_file")"
            rm -f "$error_file"
            combined="$output
$error_output"
            if ! gh_common_is_rate_limited "$combined"; then
                gh_common_error "GraphQL request failed; verify repository access and run 'gh auth status'."
                return 1
            fi
        fi

        if (( attempt == max_attempts )); then
            gh_common_error "GraphQL request remained rate-limited after ${max_attempts} attempts; wait for the reset window and retry."
            return 1
        fi

        wait_seconds="$(gh_common_rate_wait "$combined" "$attempt")"
        if [[ -n "$(gh_common_reset_epoch "$combined")" ]]; then
            gh_common_info "GraphQL rate limit encountered; waiting ${wait_seconds}s for the reported reset window before retry ${attempt}/${max_attempts}."
        elif [[ -n "$(gh_common_retry_after "$combined")" ]]; then
            gh_common_info "GraphQL rate limit encountered; honoring Retry-After for ${wait_seconds}s before retry ${attempt}/${max_attempts}."
        else
            gh_common_info "GraphQL rate limit encountered; backing off ${wait_seconds}s before retry ${attempt}/${max_attempts}."
        fi
        gh_common_sleep "$wait_seconds"
        attempt=$((attempt + 1))
    done

    gh_common_error "GraphQL request failed unexpectedly."
    return 1
}
