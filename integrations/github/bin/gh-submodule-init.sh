#!/usr/bin/env bash
# gh-submodule-init: initialise the framework submodule with a fail-closed
# public/private authentication regime.
#
# The command is one-shot. A caller owns its trigger and its repository policy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$SCRIPT_DIR/../lib/gh-common.sh"

usage() {
    cat <<'EOF'
Usage: gh-submodule-init.sh [OPTIONS]

Initialise the framework submodule from the caller's repository. Public
framework repositories use no credential. Private repositories require a
credential and configure the rewrite at global git scope before cloning.

Options:
  --framework-repository OWNER/NAME  Override CA_FRAMEWORK_REPOSITORY
  --target PATH                     Override CA_TARGET_REPO
  --help                            Show this help message

Environment variables:
  CA_FRAMEWORK_REPOSITORY  Framework GitHub repository as owner/name
  CA_FRAMEWORK_TOKEN       Credential for a private framework repository
  GH_TOKEN                 Fallback credential for a private framework repository
  GITHUB_TOKEN             Fallback credential for a private framework repository
  CA_GIT_HOST              GitHub host for the scoped insteadOf rewrite (default: github.com)
  CA_TARGET_REPO           Caller repository path override
  CA_GITHUB_REPOSITORY     Caller repository owner/name override

Exit codes:
  0  Submodules are initialised
  1  Dependency, visibility, authentication, or checkout failure
EOF
}

main() {
    local target_root framework_repository visibility token

    while (( $# > 0 )); do
        case "$1" in
            --framework-repository)
                (( $# >= 2 )) || { gh_common_error "--framework-repository requires owner/name."; return 1; }
                CA_FRAMEWORK_REPOSITORY="$2"
                shift 2
                ;;
            --framework-repository=*)
                CA_FRAMEWORK_REPOSITORY="${1#*=}"
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
    framework_repository="$(gh_common_resolve_framework_repository)" || return 1
    visibility="$(gh_common_repository_visibility "$framework_repository")" || return 1

    case "$visibility" in
        public)
            # A public repository must not receive a token or a warning about one.
            gh_common_update_submodules "$target_root" || return 1
            gh_common_info "submodules initialized for public framework $framework_repository without a credential."
            ;;
        private)
            token="$(gh_common_framework_token)"
            if [[ -z "$token" ]]; then
                gh_common_error "framework repository '$framework_repository' is private; set CA_FRAMEWORK_TOKEN (or GH_TOKEN/GITHUB_TOKEN) before retrying."
                return 1
            fi
            if ! gh_common_configure_git_credentials "$token" "$framework_repository"; then
                gh_common_error "could not configure the global git credential rewrite for '$framework_repository'."
                return 1
            fi
            gh_common_update_submodules "$target_root" || return 1
            gh_common_info "submodules initialized for private framework $framework_repository with a scoped global credential rewrite."
            ;;
        *)
            gh_common_error "visibility '$visibility' is not supported; refusing to initialize submodules."
            return 1
            ;;
    esac
}

case "${1:-}" in
    --help|-h)
        usage
        ;;
    *)
        main "$@"
        ;;
esac
