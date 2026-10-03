#!/usr/bin/env bash
# gh-pr-claim-audit: report governed-ID claim, collision, and citation drift.
#
# The command is read-only. It enumerates open pull requests (drafts included),
# compares governed paths with the default branch, and uses visible open-PR
# renames as the only source of retired-ID citation mappings.
# Bash 3.2 compatible: no associative arrays and no network writes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$SCRIPT_DIR/../lib/gh-common.sh"

usage() {
    cat <<'EOF'
Usage: gh-pr-claim-audit.sh [OPTIONS]

Report governed-ID claims, default-branch collisions, and stale citations
without changing GitHub or the local worktree. Open pull requests include
Drafts. A citation finding is emitted only when an open PR visibly renames a
governed document and a sibling PR adds a line citing the retired ID.

Options:
  --repository OWNER/NAME       Target repository; overrides CA_GITHUB_REPOSITORY
  --target PATH                 Caller repository path; overrides CA_TARGET_REPO
  --strict                      Exit 1 when findings exist
  --json                        Emit machine-readable JSON
  --help                        Show this help message

Environment variables:
  CA_GITHUB_REPOSITORY          Target repository owner/name override
  CA_TARGET_REPO                Caller repository path override
  CA_REST_MIN_INTERVAL          Seconds between REST calls (default: 0)

Exit codes:
  0  Audit completed; findings are informational unless --strict is used
  1  --strict was supplied and one or more findings exist
  2  Usage, authentication, repository, or GitHub API failure
EOF
}

# Return FS/PLAN/ADR ID for a governed document path, or empty for other files.
governed_id_for_path() {
    local path="$1"
    printf '%s\n' "$path" | sed -nE \
        's#^docs/specifications/(FS-[0-9][0-9][0-9][0-9])(-[^/]*)?\.md$#\1#p;
         s#^docs/change-plans/(PLAN-[0-9][0-9][0-9][0-9])(-[^/]*)?\.md$#\1#p;
         s#^docs/decisions/(ADR-[0-9][0-9][0-9][0-9])(-[^/]*)?\.md$#\1#p'
}

json_escape() {
    local value="$1"
    value="$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g; :a;N;$!ba;s/\n/\\n/g')"
    printf '%s' "$value"
}

claim_index() {
    local wanted_id="$1" wanted_pr="$2" wanted_path="$3" index
    for index in "${!claim_ids[@]}"; do
        if [[ "${claim_ids[$index]}" == "$wanted_id" &&
              "${claim_prs[$index]}" == "$wanted_pr" &&
              "${claim_paths[$index]}" == "$wanted_path" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
    done
    return 1
}

record_claim() {
    local id="$1" pr="$2" path="$3"
    if ! claim_index "$id" "$pr" "$path" >/dev/null; then
        claim_ids+=("$id")
        claim_prs+=("$pr")
        claim_paths+=("$path")
    fi
}

rename_index() {
    local old_id="$1" new_id="$2" pr="$3" index
    for index in "${!rename_old_ids[@]}"; do
        if [[ "${rename_old_ids[$index]}" == "$old_id" &&
              "${rename_new_ids[$index]}" == "$new_id" &&
              "${rename_prs[$index]}" == "$pr" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
    done
    return 1
}

record_rename() {
    local old_id="$1" new_id="$2" pr="$3" path="$4"
    if ! rename_index "$old_id" "$new_id" "$pr" >/dev/null; then
        rename_old_ids+=("$old_id")
        rename_new_ids+=("$new_id")
        rename_prs+=("$pr")
        rename_paths+=("$path")
    fi
}

file_index() {
    local wanted_pr="$1" wanted_path="$2" index
    for index in "${!file_prs[@]}"; do
        if [[ "${file_prs[$index]}" == "$wanted_pr" &&
              "${file_paths[$index]}" == "$wanted_path" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
    done
    return 1
}

record_file_patch() {
    local pr="$1" path="$2" patch="$3"
    if ! file_index "$pr" "$path" >/dev/null; then
        file_prs+=("$pr")
        file_paths+=("$path")
        file_patches+=("$patch")
    fi
}

# Emit one finding in the selected output format and increment FINDING_COUNT.
emit_claim_finding() {
    local class="$1" id="$2" default_paths="$3" index claims_text="" claims_json="" escaped_path escaped_id
    escaped_id="$(json_escape "$id")"
    for index in "${!claim_ids[@]}"; do
        [[ "${claim_ids[$index]}" == "$id" ]] || continue
        escaped_path="$(json_escape "${claim_paths[$index]}")"
        if [[ -n "$claims_text" ]]; then claims_text="$claims_text, "; fi
        claims_text="${claims_text}#${claim_prs[$index]} ${claim_paths[$index]}"
        if [[ -n "$claims_json" ]]; then claims_json="$claims_json,"; fi
        claims_json="${claims_json}{\"pr\":${claim_prs[$index]},\"path\":\"$escaped_path\"}"
    done

    if [[ "$OUTPUT_JSON" == true ]]; then
        if [[ "$class" == "default-branch-collision" ]]; then
            local defaults_json="" default_path escaped_default
            while IFS= read -r default_path; do
                [[ -n "$default_path" ]] || continue
                escaped_default="$(json_escape "$default_path")"
                if [[ -n "$defaults_json" ]]; then defaults_json="$defaults_json,"; fi
                defaults_json="${defaults_json}\"$escaped_default\""
            done <<< "$default_paths"
            FINDINGS_JSON+=("{\"class\":\"$class\",\"id\":\"$escaped_id\",\"claims\":[$claims_json],\"default_paths\":[$defaults_json]}")
        else
            FINDINGS_JSON+=("{\"class\":\"$class\",\"id\":\"$escaped_id\",\"claims\":[$claims_json]}")
        fi
    else
        echo "FINDING: $class id=$id claims=$claims_text"
        if [[ "$class" == "default-branch-collision" ]]; then
            echo "  default-branch paths: $(printf '%s' "$default_paths" | tr '\n' ', ' | sed 's/, $//')"
        fi
    fi
    FINDING_COUNT=$((FINDING_COUNT + 1))
}

emit_citation_finding() {
    local old_id="$1" new_id="$2" rename_pr="$3" citations_text="" citations_json="" index escaped_path escaped_old escaped_new
    escaped_old="$(json_escape "$old_id")"
    escaped_new="$(json_escape "$new_id")"
    for index in "${!citation_prs[@]}"; do
        [[ "${citation_mapping[$index]}" == "$old_id->$new_id#$rename_pr" ]] || continue
        escaped_path="$(json_escape "${citation_paths[$index]}")"
        if [[ -n "$citations_text" ]]; then citations_text="$citations_text, "; fi
        citations_text="${citations_text}#${citation_prs[$index]} ${citation_paths[$index]}"
        if [[ -n "$citations_json" ]]; then citations_json="$citations_json,"; fi
        citations_json="${citations_json}{\"pr\":${citation_prs[$index]},\"path\":\"$escaped_path\"}"
    done
    if [[ "$OUTPUT_JSON" == true ]]; then
        FINDINGS_JSON+=("{\"class\":\"citation-drift\",\"old_id\":\"$escaped_old\",\"new_id\":\"$escaped_new\",\"rename_pr\":$rename_pr,\"citations\":[$citations_json]}")
    else
        echo "FINDING: citation-drift old_id=$old_id new_id=$new_id rename_pr=#$rename_pr citations=$citations_text"
    fi
    FINDING_COUNT=$((FINDING_COUNT + 1))
}

main() {
    local target_root repository default_branch open_prs_file pr_number
    local files_file file_line status filename previous_filename patch_text id old_id new_id
    local tree_file tree_path claim_id index path_count default_paths default_count
    local mapped citation_line citation_id citation_new citation_pr citation_path
    local strict=false
    local -a claim_ids=() claim_prs=() claim_paths=()
    local -a rename_old_ids=() rename_new_ids=() rename_prs=() rename_paths=()
    local -a file_prs=() file_paths=() file_patches=()
    local -a citation_prs=() citation_paths=() citation_mapping=()
    local -a default_paths_all=() default_ids=()
    local -a FINDINGS_JSON=()
    local FINDING_COUNT=0
    local OUTPUT_JSON=false

    while (( $# > 0 )); do
        case "$1" in
            --repository)
                (( $# >= 2 )) || { gh_common_error "--repository requires owner/name."; return 2; }
                CA_GITHUB_REPOSITORY="$2"
                shift 2
                ;;
            --repository=*)
                CA_GITHUB_REPOSITORY="${1#*=}"
                shift
                ;;
            --target)
                (( $# >= 2 )) || { gh_common_error "--target requires a repository path."; return 2; }
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
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --help|-h)
                usage
                return 0
                ;;
            *)
                gh_common_error "unknown option '$1'; use --help for usage."
                return 2
                ;;
        esac
    done

    gh_common_require_base_tools || return 2
    gh_common_auth_check || return 2
    target_root="$(gh_common_resolve_target_root)" || return 2
    repository="$(gh_common_resolve_repository "$target_root")" || return 2

    tree_file="$(mktemp)"
    open_prs_file="$(mktemp)"
    if ! gh api "repos/$repository" --jq '.default_branch' > "$tree_file"; then
        rm -f "$tree_file" "$open_prs_file"
        gh_common_error "could not read the default branch for '$repository'."
        return 2
    fi
    default_branch="$(tr -d '[:space:]' < "$tree_file")"
    if [[ -z "$default_branch" ]]; then
        rm -f "$tree_file" "$open_prs_file"
        gh_common_error "GitHub returned an empty default branch for '$repository'."
        return 2
    fi

    if ! gh api "repos/$repository/git/trees/$default_branch?recursive=1" --jq '.tree[]? | select(.type == "blob") | .path' > "$tree_file"; then
        rm -f "$tree_file" "$open_prs_file"
        gh_common_error "could not enumerate the default-branch tree for '$repository'."
        return 2
    fi
    while IFS= read -r tree_path; do
        [[ -n "$tree_path" ]] || continue
        id="$(governed_id_for_path "$tree_path")"
        [[ -n "$id" ]] || continue
        default_paths_all+=("$tree_path")
        default_ids+=("$id")
    done < "$tree_file"

    if ! gh api --paginate "repos/$repository/pulls?state=open&per_page=100" --jq '.[] | [.number] | @tsv' > "$open_prs_file"; then
        rm -f "$tree_file" "$open_prs_file"
        gh_common_error "could not enumerate open pull requests for '$repository'."
        return 2
    fi

    while IFS= read -r pr_number; do
        [[ -n "$pr_number" ]] || continue
        files_file="$(mktemp)"
        gh_common_sleep "${CA_REST_MIN_INTERVAL:-0}"
        if ! gh api --paginate "repos/$repository/pulls/$pr_number/files?per_page=100" \
            --jq '.[] | [(.status // "__CA_EMPTY__"), (.filename // "__CA_EMPTY__"), (.previous_filename // "__CA_EMPTY__"), (.patch // "__CA_EMPTY__")] | @tsv' > "$files_file"; then
            rm -f "$tree_file" "$open_prs_file" "$files_file"
            gh_common_error "could not enumerate files for open pull request #$pr_number."
            return 2
        fi
        while IFS="$(printf '\t')" read -r status filename previous_filename patch_text; do
            [[ "$filename" != "__CA_EMPTY__" && -n "$filename" ]] || continue
            [[ "$status" != "__CA_EMPTY__" ]] || status=""
            [[ "$previous_filename" != "__CA_EMPTY__" ]] || previous_filename=""
            [[ "$patch_text" != "__CA_EMPTY__" ]] || patch_text=""
            id="$(governed_id_for_path "$filename")"
            if [[ -n "$id" && "$status" != "removed" ]]; then
                record_claim "$id" "$pr_number" "$filename"
            fi
            if [[ "$status" == "renamed" ]]; then
                old_id="$(governed_id_for_path "$previous_filename")"
                new_id="$(governed_id_for_path "$filename")"
                if [[ -n "$old_id" && -n "$new_id" && "$old_id" != "$new_id" ]]; then
                    record_rename "$old_id" "$new_id" "$pr_number" "$filename"
                fi
            fi
            patch_text="$(printf '%b' "${patch_text:-}")"
            record_file_patch "$pr_number" "$filename" "$patch_text"
        done < "$files_file"
        rm -f "$files_file"
    done < "$open_prs_file"
    rm -f "$tree_file" "$open_prs_file"

    # Group open-PR claims by ID. A collision exists only when the same ID is
    # claimed under more than one distinct path; two PRs editing the same path
    # are concurrent edits, not a registry collision.
    for claim_id in "${claim_ids[@]}"; do
        [[ -n "$claim_id" ]] || continue
        path_count=0
        default_paths=""
        for index in "${!claim_ids[@]}"; do
            [[ "${claim_ids[$index]}" == "$claim_id" ]] || continue
            path="${claim_paths[$index]}"
            case $'\n'"${default_paths}"$'\n' in *$'\n'"${path}"$'\n'*) ;; *) path_count=$((path_count + 1)); default_paths="${default_paths}"$'\n'"${path}" ;; esac
        done
        if (( path_count > 1 )); then
            # Emit once per ID, even when several claim entries share it.
            case $'\n'"${emitted_claim_ids:-}"$'\n' in *$'\n'"${claim_id}"$'\n'*) ;; *)
                emit_claim_finding "claim-collision" "$claim_id" ""
                emitted_claim_ids="${emitted_claim_ids:-}"$'\n'"${claim_id}"
                ;;
            esac
        fi
    done

    # Compare each claimed ID with all default-branch owners under a different
    # path. The same branch path is an in-place update and is intentionally safe.
    for claim_id in "${claim_ids[@]}"; do
        [[ -n "$claim_id" ]] || continue
        default_paths=""
        for index in "${!default_ids[@]}"; do
            [[ "${default_ids[$index]}" == "$claim_id" ]] || continue
            path="${default_paths_all[$index]}"
            if [[ -n "$default_paths" ]]; then default_paths="${default_paths}"$'\n'; fi
            default_paths="${default_paths}${path}"
        done
        [[ -n "$default_paths" ]] || continue
        default_count=0
        while IFS= read -r path; do
            [[ -n "$path" ]] && default_count=$((default_count + 1))
        done <<< "$default_paths"
        [[ "$default_count" -gt 0 ]] || continue
        local has_different=false
        for index in "${!claim_ids[@]}"; do
            [[ "${claim_ids[$index]}" == "$claim_id" ]] || continue
            while IFS= read -r path; do
                [[ -n "$path" && "$path" != "${claim_paths[$index]}" ]] && has_different=true
            done <<< "$default_paths"
        done
        if [[ "$has_different" == true ]]; then
            case $'\n'"${emitted_default_ids:-}"$'\n' in *$'\n'"${claim_id}"$'\n'*) ;; *)
                emit_claim_finding "default-branch-collision" "$claim_id" "$default_paths"
                emitted_default_ids="${emitted_default_ids:-}"$'\n'"${claim_id}"
                ;;
            esac
        fi
    done

    # For each observed open-PR rename, scan sibling PR added lines only. The
    # rename PR itself is excluded so its removed old side and its own context
    # cannot become a citation finding.
    for index in "${!rename_old_ids[@]}"; do
        old_id="${rename_old_ids[$index]}"
        new_id="${rename_new_ids[$index]}"
        citation_pr="${rename_prs[$index]}"
        citation_mapping_key="${old_id}->${new_id}#${citation_pr}"
        citation_prs=()
        citation_paths=()
        citation_mapping=()
        for mapped in "${!file_prs[@]}"; do
            [[ "${file_prs[$mapped]}" != "$citation_pr" ]] || continue
            citation_line="$(printf '%s\n' "${file_patches[$mapped]}" | grep -E '^\+[^+]' | grep -E "(^|[^A-Za-z0-9_-])${old_id}([^A-Za-z0-9_-]|$)" || true)"
            [[ -n "$citation_line" ]] || continue
            citation_prs+=("${file_prs[$mapped]}")
            citation_paths+=("${file_paths[$mapped]}")
            citation_mapping+=("$citation_mapping_key")
        done
        if (( ${#citation_prs[@]} > 0 )); then
            emit_citation_finding "$old_id" "$new_id" "$citation_pr"
        fi
    done

    if [[ "$OUTPUT_JSON" == true ]]; then
        local joined=""
        for index in "${!FINDINGS_JSON[@]}"; do
            [[ -n "$joined" ]] && joined="$joined,"
            joined="${joined}${FINDINGS_JSON[$index]}"
        done
        printf '{"repository":"%s","default_branch":"%s","findings":[%s]}\n' \
            "$(json_escape "$repository")" "$(json_escape "$default_branch")" "$joined"
    else
        echo "PR CLAIM AUDIT: repository=$repository default_branch=$default_branch"
        echo "PR CLAIM AUDIT SUMMARY: findings=$FINDING_COUNT"
    fi

    if [[ "$strict" == true && "$FINDING_COUNT" -gt 0 ]]; then
        return 1
    fi
    return 0
}

main "$@"
