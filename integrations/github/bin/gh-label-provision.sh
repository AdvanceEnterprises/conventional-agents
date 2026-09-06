#!/usr/bin/env bash
# gh-label-provision: provision the framework label vocabulary and report drift.
#
# Default mode provisions missing labels. --audit and --dry-run never mutate
# GitHub. Unexpected labels are reported and are never deleted.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$SCRIPT_DIR/../lib/gh-common.sh"

FRAMEWORK_LABELS=(enhancement bug documentation spec plan question)
LABEL_COLOR="0e8a16"

usage() {
    cat <<'EOF'
Usage: gh-label-provision.sh [OPTIONS]

Provision the six framework labels, or inspect label drift without deleting
anything. The command is idempotent: existing labels are left unchanged.

Options:
  --audit                       Report missing and unexpected labels; do not mutate
  --dry-run                     Print mutations that default mode would make
  --extensions PATH             Read caller-supplied extension labels, one per line
  --target PATH                Override CA_TARGET_REPO
  --repository OWNER/NAME       Override CA_GITHUB_REPOSITORY
  --help                        Show this help message

Environment variables:
  CA_TARGET_REPO                Caller repository path override
  CA_GITHUB_REPOSITORY          Caller repository owner/name override
  CA_LABEL_EXTENSIONS_FILE      Extension-label file; relative to the caller root
  GH_TOKEN                      GitHub CLI authentication token
  GITHUB_TOKEN                  Fallback GitHub CLI authentication token

The default extension file is config/github-labels.txt when it exists in the
caller repository. Extension labels are caller data, not part of the shipped
framework vocabulary.

Exit codes:
  0  Provisioning, audit, or dry-run completed
  1  Dependency, authentication, or API failure
EOF
}

array_contains() {
    local wanted="$1"
    shift
    local candidate

    for candidate in "$@"; do
        if [[ "$candidate" == "$wanted" ]]; then
            return 0
        fi
    done
    return 1
}

read_extension_labels() {
    local extension_file="$1"
    local line normalized

    EXTENSION_LABELS=()
    [[ -n "$extension_file" && -f "$extension_file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        normalized="$(printf '%s' "$line" | sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -n "$normalized" ]] || continue
        if ! array_contains "$normalized" "${FRAMEWORK_LABELS[@]}" "${EXTENSION_LABELS[@]}"; then
            EXTENSION_LABELS+=("$normalized")
        fi
    done < "$extension_file"
}

label_in_lines() {
    local wanted="$1"
    local lines="$2"
    local line

    while IFS= read -r line; do
        [[ "$line" == "$wanted" ]] && return 0
    done <<< "$lines"
    return 1
}

main() {
    local target_root repository extension_file current_labels
    local audit=false dry_run=false
    local option_value label response
    local created=0 existing=0
    local -a expected_labels missing_labels unexpected_labels

    while (( $# > 0 )); do
        case "$1" in
            --audit)
                audit=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --extensions)
                (( $# >= 2 )) || { gh_common_error "--extensions requires a file path."; return 1; }
                CA_LABEL_EXTENSIONS_FILE="$2"
                shift 2
                ;;
            --extensions=*)
                CA_LABEL_EXTENSIONS_FILE="${1#*=}"
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
            --repository)
                (( $# >= 2 )) || { gh_common_error "--repository requires owner/name."; return 1; }
                CA_GITHUB_REPOSITORY="$2"
                shift 2
                ;;
            --repository=*)
                CA_GITHUB_REPOSITORY="${1#*=}"
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

    extension_file="${CA_LABEL_EXTENSIONS_FILE:-$target_root/config/github-labels.txt}"
    if [[ "$extension_file" != /* ]]; then
        extension_file="$target_root/$extension_file"
    fi
    if [[ -n "${CA_LABEL_EXTENSIONS_FILE:-}" && ! -f "$extension_file" ]]; then
        gh_common_error "extension-label file '$extension_file' does not exist."
        return 1
    fi
    read_extension_labels "$extension_file"
    expected_labels=("${FRAMEWORK_LABELS[@]}" "${EXTENSION_LABELS[@]}")

    gh_common_auth_check || return 1
    if ! current_labels="$(gh api "repos/$repository/labels?per_page=100" --paginate --jq '.[].name' 2>/dev/null)"; then
        gh_common_error "could not read labels for '$repository'; verify the repository and token scopes."
        return 1
    fi

    missing_labels=()
    for label in "${expected_labels[@]}"; do
        if label_in_lines "$label" "$current_labels"; then
            existing=$((existing + 1))
        else
            missing_labels+=("$label")
        fi
    done

    unexpected_labels=()
    while IFS= read -r label; do
        [[ -n "$label" ]] || continue
        if ! array_contains "$label" "${expected_labels[@]}"; then
            unexpected_labels+=("$label")
        fi
    done <<< "$current_labels"

    if [[ "$audit" == true ]]; then
        printf 'LABEL AUDIT: missing\n'
        if (( ${#missing_labels[@]} == 0 )); then
            printf '  (none)\n'
        else
            for label in "${missing_labels[@]}"; do
                printf '  - %s\n' "$label"
            done
        fi
        printf 'LABEL AUDIT: unexpected\n'
        if (( ${#unexpected_labels[@]} == 0 )); then
            printf '  (none)\n'
        else
            for label in "${unexpected_labels[@]}"; do
                printf '  - %s\n' "$label"
            done
        fi
        if [[ "$dry_run" == true ]]; then
            printf 'DRY RUN: would-create\n'
            if (( ${#missing_labels[@]} == 0 )); then
                printf '  (none)\n'
            else
                for label in "${missing_labels[@]}"; do
                    printf '  - %s\n' "$label"
                done
            fi
        fi
        printf 'LABEL SUMMARY: existing=%d missing=%d unexpected=%d\n' \
            "$existing" "${#missing_labels[@]}" "${#unexpected_labels[@]}"
        return 0
    fi

    if [[ "$dry_run" == true ]]; then
        printf 'DRY RUN: would-create\n'
        if (( ${#missing_labels[@]} == 0 )); then
            printf '  (none)\n'
        else
            for label in "${missing_labels[@]}"; do
                printf '  - %s\n' "$label"
            done
        fi
        printf 'LABEL SUMMARY: created=0 existing=%d would-create=%d unexpected=%d\n' \
            "$existing" "${#missing_labels[@]}" "${#unexpected_labels[@]}"
        return 0
    fi

    for label in "${missing_labels[@]}"; do
        gh_common_auth_check || return 1
        if response="$(gh api "repos/$repository/labels" --method POST \
            -f "name=$label" -f "color=$LABEL_COLOR" 2>&1)"; then
            created=$((created + 1))
        elif printf '%s\n' "$response" \
            | grep -Eiq '"resource"[[:space:]]*:[[:space:]]*"Label"' \
            && printf '%s\n' "$response" \
            | grep -Eiq '"code"[[:space:]]*:[[:space:]]*"already_exists"'; then
            # Concurrent invocations may race on the same create. The desired
            # postcondition is still true, so classify only this specific
            # duplicate-label response as already present.
            existing=$((existing + 1))
        else
            gh_common_error "could not create label '$label' in '$repository'; verify issues:write access."
            return 1
        fi
    done

    printf 'LABEL SUMMARY: created=%d existing=%d unexpected=%d\n' \
        "$created" "$existing" "${#unexpected_labels[@]}"
}

case "${1:-}" in
    --help|-h)
        usage
        ;;
    *)
        main "$@"
        ;;
esac
