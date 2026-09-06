#!/usr/bin/env bash
# gh-board-audit: report GitHub Project drift without mutating the board.
#
# The command enumerates one Project v2 board and the target repository's open
# Issues. It reports drift for human or consumer-side reconciliation; it never
# changes an issue, project item, field, or board membership.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$SCRIPT_DIR/../lib/gh-common.sh"

BOARD_QUERY='query($owner: String!, $number: Int!, $cursor: String) {
  repositoryOwner(login: $owner) {
    __typename
    ... on Organization {
      projectV2(number: $number) {
        title
        items(first: 100, after: $cursor) {
          nodes {
            content {
              __typename
              ... on Issue {
                number
                repository { nameWithOwner }
              }
            }
            fieldValues(first: 50) {
              nodes {
                __typename
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
    ... on User {
      projectV2(number: $number) {
        title
        items(first: 100, after: $cursor) {
          nodes {
            content {
              __typename
              ... on Issue {
                number
                repository { nameWithOwner }
              }
            }
            fieldValues(first: 50) {
              nodes {
                __typename
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
  }
}'

BOARD_FILTER='if ((.errors // []) | length) > 0 then
  "__GRAPHQL_ERROR__"
elif .data.repositoryOwner == null then
  "__OWNER_NOT_FOUND__"
elif ((.data.repositoryOwner | objects | has("projectV2")) | not) or .data.repositoryOwner.projectV2 == null then
  "__NO_PROJECT__"
else
  "__PROJECT_PRESENT__",
  (.data.repositoryOwner.projectV2.items.nodes[]?
    | [(.content.__typename // ""),
       (.content.number // ""),
       (.content.repository.nameWithOwner // ""),
       (([.fieldValues.nodes[]? | select((.field.name // "") == "Issue Type") | .name] | first) // "__UNSET__"),
       (([.fieldValues.nodes[]? | select((.field.name // "") == "Status") | .name] | first) // "__UNSET__")]
    | @tsv),
  (if .data.repositoryOwner.projectV2.items.pageInfo.hasNextPage
   then "__NEXT_CURSOR__\t" + (.data.repositoryOwner.projectV2.items.pageInfo.endCursor // "")
   else "__DONE__"
   end)
end'

usage() {
    cat <<'EOF'
Usage: gh-board-audit.sh [OPTIONS]

Report Project v2 drift without changing GitHub. The report separates unset
Issue Type, unset Status, and open Issues absent from the selected project.

Options:
  --project NUMBER              Project number; overrides CA_GITHUB_PROJECT_NUMBER
  --owner OWNER                 Project owner; defaults to repository owner
  --repository OWNER/NAME       Target repository; overrides CA_GITHUB_REPOSITORY
  --target PATH                 Caller repository path; overrides CA_TARGET_REPO
  --strict                      Exit 1 when drift findings exist
  --help                        Show this help message

Environment variables:
  CA_GITHUB_PROJECT_NUMBER      Project number, or config/project.yml is read
  CA_GITHUB_OWNER               Project owner override
  CA_GITHUB_REPOSITORY          Target repository owner/name override
  CA_TARGET_REPO                Caller repository path override
  CA_GRAPHQL_MIN_INTERVAL       Minimum seconds between GraphQL calls (default: 7)
  CA_GRAPHQL_MAX_ATTEMPTS       Maximum attempts for a rate-limited call (default: 3)
  CA_GRAPHQL_BACKOFF_BASE_SECONDS  Initial exponential-backoff seconds (default: 1)
  CA_GRAPHQL_BACKOFF_MAX_SECONDS   Maximum exponential-backoff wait (default: 60)
  CA_RATE_LIMIT_BUFFER_SECONDS  Buffer added to a reported reset or retry wait (default: 1)
  CA_NOW_EPOCH                  Test/operator override for the current epoch

Exit codes:
  0  Enumeration completed, including with drift findings
  1  Missing dependency, configuration/API failure, or --strict findings
EOF
}

# Read the project number from the consumer-owned metadata template when the
# operator did not provide it explicitly. This is intentionally narrow rather
# than a general YAML parser; the shipped config has a flat project block.
read_project_number_from_config() {
    local target_root="$1"
    local config_file="$target_root/config/project.yml"
    local project_number

    [[ -f "$config_file" ]] || return 0
    project_number="$(awk '
        /^project:/ { in_project = 1; next }
        in_project && /^[^[:space:]]/ { exit }
        in_project && /^[[:space:]]+number:/ {
            sub(/^[[:space:]]+number:[[:space:]]*/, "")
            print
            exit
        }
    ' "$config_file")"
    project_number="$(printf '%s' "$project_number" | tr -d '[:space:]"')"
    printf '%s\n' "$project_number"
}

# Find a board issue key in the parallel arrays without associative arrays so
# the command remains compatible with the Bash 3.2 baseline.
board_issue_index() {
    local wanted="$1"
    local index

    for index in "${!board_issue_keys[@]}"; do
        if [[ "${board_issue_keys[$index]}" == "$wanted" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
    done
    return 1
}

# Append an Issue item and its two relevant single-select values.
record_board_item() {
    local number="$1"
    local repository="$2"
    local issue_type="$3"
    local status="$4"
    local key="${repository}#${number}"

    [[ -n "$number" && -n "$repository" ]] || return 0
    if [[ "$issue_type" == "__UNSET__" ]]; then
        issue_type=""
    fi
    if [[ "$status" == "__UNSET__" ]]; then
        status=""
    fi
    if board_issue_index "$key" >/dev/null; then
        return 0
    fi
    board_issue_keys+=("$key")
    board_issue_types+=("$issue_type")
    board_issue_statuses+=("$status")
}

main() {
    local target_root repository owner project_number config_number
    local cursor="" board_output response_file line field_a field_b field_c field_d field_e
    local project_present=false project_absent=false next_cursor=""
    local strict=false
    local issue_output issue_number issue_url issue_key index
    local unset_type=0 unset_status=0 absent_from_board=0
    local -a board_issue_keys=() board_issue_types=() board_issue_statuses=()
    local -a absent_issue_keys=()

    while (( $# > 0 )); do
        case "$1" in
            --project)
                (( $# >= 2 )) || { gh_common_error "--project requires a numeric project number."; return 1; }
                CA_GITHUB_PROJECT_NUMBER="$2"
                shift 2
                ;;
            --project=*)
                CA_GITHUB_PROJECT_NUMBER="${1#*=}"
                shift
                ;;
            --owner)
                (( $# >= 2 )) || { gh_common_error "--owner requires a GitHub owner name."; return 1; }
                CA_GITHUB_OWNER="$2"
                shift 2
                ;;
            --owner=*)
                CA_GITHUB_OWNER="${1#*=}"
                shift
                ;;
            --repository)
                (( $# >= 2 )) || { gh_common_error "--repository requires owner/name."; return 1; }
                CA_GITHUB_REPOSITORY="$2"
                shift 2
                ;;
            --repository=*)
                CA_GITHUB_REPOSITORY="${1#*=}"
                shift
                ;;
            --target)
                (( $# >= 2 )) || { gh_common_error "--target requires a repository path."; return 1; }
                CA_TARGET_REPO="$2"
                shift 2
                ;;
            --target=*)
                CA_TARGET_REPO="${1#*=}"
                shift
                ;;
            --strict)
                strict=true
                shift
                ;;
            --help|-h)
                usage
                return 0
                ;;
            *)
                gh_common_error "unknown option '$1'; use --help for usage."
                return 1
                ;;
        esac
    done

    gh_common_require_base_tools || return 1
    target_root="$(gh_common_resolve_target_root)" || return 1
    repository="$(gh_common_resolve_repository "$target_root")" || return 1
    owner="${CA_GITHUB_OWNER:-$(gh_common_repository_owner "$repository")}"
    project_number="${CA_GITHUB_PROJECT_NUMBER:-}"
    if [[ -z "$project_number" ]]; then
        config_number="$(read_project_number_from_config "$target_root")"
        project_number="$config_number"
    fi
    if [[ ! "$project_number" =~ ^[0-9]+$ ]]; then
        gh_common_error "a numeric project number is required; pass --project or set CA_GITHUB_PROJECT_NUMBER (config/project.yml is also supported)."
        return 1
    fi
    if [[ -z "$owner" ]]; then
        gh_common_error "a GitHub project owner is required; pass --owner or set CA_GITHUB_OWNER."
        return 1
    fi

    while :; do
        gh_common_auth_check || return 1
        response_file="$(mktemp)"
        if [[ -n "$cursor" ]]; then
            if ! gh_common_graphql "$BOARD_QUERY" "$BOARD_FILTER" \
                -F "owner=$owner" -F "number=$project_number" -F "cursor=$cursor" > "$response_file"; then
                rm -f "$response_file"
                return 1
            fi
        else
            if ! gh_common_graphql "$BOARD_QUERY" "$BOARD_FILTER" \
                -F "owner=$owner" -F "number=$project_number" -F cursor=null > "$response_file"; then
                rm -f "$response_file"
                return 1
            fi
        fi
        board_output="$(<"$response_file")"
        rm -f "$response_file"

        next_cursor=""
        while IFS= read -r line; do
            case "$line" in
                INFO:*)
                    ;;
                __PROJECT_PRESENT__)
                    project_present=true
                    ;;
                __NO_PROJECT__)
                    project_absent=true
                    ;;
                __GRAPHQL_ERROR__)
                    gh_common_error "GitHub returned a GraphQL error while enumerating project '$project_number'; verify project access and retry."
                    return 1
                    ;;
                __OWNER_NOT_FOUND__)
                    gh_common_error "GitHub owner '$owner' was not found or is not a supported project owner."
                    return 1
                    ;;
                __NEXT_CURSOR__$'\t'*)
                    next_cursor="${line#*$'\t'}"
                    ;;
                __DONE__)
                    ;;
                *)
                    IFS=$'\t' read -r field_a field_b field_c field_d field_e <<< "$line"
                    if [[ "$field_a" == "Issue" ]]; then
                        record_board_item "$field_b" "$field_c" "$field_d" "$field_e"
                    fi
                    ;;
            esac
        done <<< "$board_output"

        [[ -n "$next_cursor" ]] || break
        cursor="$next_cursor"
    done

    if [[ "$project_absent" == true && "$project_present" == false ]]; then
        printf 'BOARD AUDIT: project=absent owner=%s number=%s\n' "$owner" "$project_number"
        printf 'BOARD SUMMARY: project-absent=1 unset-issue-type=0 unset-status=0 absent-from-board=0\n'
        return 0
    fi
    if [[ "$project_present" != true ]]; then
        gh_common_error "the GitHub response did not contain a usable Project v2 board."
        return 1
    fi

    for index in "${!board_issue_keys[@]}"; do
        if [[ -z "${board_issue_types[$index]}" ]]; then
            unset_type=$((unset_type + 1))
        fi
        if [[ -z "${board_issue_statuses[$index]}" ]]; then
            unset_status=$((unset_status + 1))
        fi
    done

    gh_common_auth_check || return 1
    if ! issue_output="$(gh api "repos/$repository/issues?state=open&per_page=100" \
        --paginate --jq '.[] | select(.pull_request == null) | [.number, .html_url] | @tsv' 2>/dev/null)"; then
        gh_common_error "could not enumerate open Issues for '$repository'; verify the repository and token scopes."
        return 1
    fi
    while IFS=$'\t' read -r issue_number issue_url; do
        [[ -n "$issue_number" ]] || continue
        issue_key="${repository}#${issue_number}"
        if ! board_issue_index "$issue_key" >/dev/null; then
            absent_issue_keys+=("$issue_key")
        fi
    done <<< "$issue_output"
    absent_from_board="${#absent_issue_keys[@]}"

    printf 'BOARD AUDIT: project=present owner=%s number=%s\n' "$owner" "$project_number"
    printf 'BOARD AUDIT: unset-issue-type\n'
    for index in "${!board_issue_keys[@]}"; do
        if [[ -z "${board_issue_types[$index]}" ]]; then
            printf '  - %s\n' "${board_issue_keys[$index]}"
        fi
    done
    printf 'BOARD AUDIT: unset-status\n'
    for index in "${!board_issue_keys[@]}"; do
        if [[ -z "${board_issue_statuses[$index]}" ]]; then
            printf '  - %s\n' "${board_issue_keys[$index]}"
        fi
    done
    printf 'BOARD AUDIT: open-issues-without-project-item\n'
    if (( absent_from_board == 0 )); then
        printf '  (none)\n'
    else
        for issue_key in "${absent_issue_keys[@]}"; do
            printf '  - %s\n' "$issue_key"
        done
    fi
    printf 'BOARD SUMMARY: unset-issue-type=%d unset-status=%d absent-from-board=%d\n' \
        "$unset_type" "$unset_status" "$absent_from_board"

    if [[ "$strict" == true ]] && (( unset_type > 0 || unset_status > 0 || absent_from_board > 0 )); then
        gh_common_error "board drift found; --strict treats findings as a failure."
        return 1
    fi
    return 0
}

case "${1:-}" in
    --help|-h)
        usage
        ;;
    *)
        main "$@"
        ;;
esac
