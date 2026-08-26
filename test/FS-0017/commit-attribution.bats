#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
}

# Known actor emails for this repository. Update this list when adding
# new actors or rotating aliases.
#
# The authoritative list is the actor table in
# workflows/git-and-gh-conventions.md §"The convention" — the current-state
# document for ADR-0018 as amended by ADR-0029. This array must stay in sync
# with it; it drifted once already, failing a legitimate commit because an
# actor documented there was missing here.
ACTOR_EMAILS=(
  "taisden@tais-den.dev"
  "hermes-agent@tais-den.dev"
  "hermes-cron@tais-den.dev"
  "codex@tais-den.dev"
  "codex-cron@tais-den.dev"
  "claude-code@tais-den.dev"
  "ajoeofalltrades@users.noreply.github.com"
)

# How many recent commits to enforce the convention on. ADR-0018
# takes effect going forward; we don't enforce on legacy history.
RECENT_COMMIT_COUNT=5

# Default GitHub identity email for this repo (used when no
# distinguishing email override is in effect).
DEFAULT_EMAIL="ajoeofalltrades@users.noreply.github.com"

# Regex that matches a well-formed Agent-Attribution: trailer.
# Format: Agent-Attribution: actor=<name>; model=<model>; role=<role>; session=<session-mode>
agent_attribution_pattern() {
  printf '^Agent-Attribution:[[:space:]]*actor=[^;]+;[[:space:]]*model=[^;]+;[[:space:]]*role=[^;]+;[[:space:]]*session=[^;]+$'
}

@test "workflow doc teaches the single-identity convention" {
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Single-identity workflow with agent co-attribution"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "hermes-agent@tais-den.dev"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Co-authored-by:"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Agent-Attribution:"
}

@test "skill teaches the single-identity convention" {
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "Single-Identity Workflow"
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "hermes-agent@tais-den.dev"
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "Co-authored-by:"
  assert_file_contains "$REPO_ROOT/skills/git-gh-workflow/SKILL.md" "Agent-Attribution:"
}

@test "PR body template includes Agent Attribution section" {
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "Agent Attribution"
  assert_file_contains "$REPO_ROOT/workflows/git-and-gh-conventions.md" "session=architecture-planning"
}

@test "ADR-0018 exists with accepted status" {
  # ADR-0018 was accepted in a prior session (commit 987db28). It is the single-identity
  # workflow decision in force.
  assert_file_exists "$REPO_ROOT/docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md"
  assert_file_contains "$REPO_ROOT/docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md" "status: accepted"
}

@test "ADR-0011 cross-references ADR-0018" {
  assert_file_contains "$REPO_ROOT/docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md" "ADR-0018"
}

@test "roles/ contains README.md and a delegating ROLE_CONTRACT.md" {
  # Per PLAN-0022 §5a, roles/ROLE_CONTRACT.md was restored as a delegating document
  # (not a byte-identical duplicate of guidelines/ROLE_CONTRACT.md). It states that
  # this project adopts the framework contract unmodified and points at guidelines/.
  # FS-0017/PLAN-0017's removal of a byte-identical duplicate remains correct; the
  # failure mode PLAN-0017 objected to (a byte-identical duplicate drifting) is
  # prevented by the delegating structure, not by file absence.
  assert_file_exists "$REPO_ROOT/roles/README.md"
  assert_file_exists "$REPO_ROOT/roles/ROLE_CONTRACT.md"
  # Delegating structure: not a byte-identical duplicate.
  if diff -q "$REPO_ROOT/roles/ROLE_CONTRACT.md" "$REPO_ROOT/guidelines/ROLE_CONTRACT.md" >/dev/null 2>&1; then
    echo "FAIL: roles/ROLE_CONTRACT.md is a byte-identical duplicate of guidelines/ROLE_CONTRACT.md (ADR-0030 rule 1)"
    return 1
  fi
  # States that the project adopts the framework contract unmodified.
  assert_file_contains "$REPO_ROOT/roles/ROLE_CONTRACT.md" "guidelines/ROLE_CONTRACT.md"
}

@test "FS-0017 and PLAN-0017 exist with implemented status" {
  assert_file_exists "$REPO_ROOT/docs/specifications/FS-0017-single-identity-commit-attribution.md"
  assert_file_contains "$REPO_ROOT/docs/specifications/FS-0017-single-identity-commit-attribution.md" "status: implemented"
  assert_file_exists "$REPO_ROOT/docs/change-plans/PLAN-0017-implement-fs-0017-single-identity-commit-attribution.md"
  assert_file_contains "$REPO_ROOT/docs/change-plans/PLAN-0017-implement-fs-0017-single-identity-commit-attribution.md" "status: implemented"
}

@test "recent commits have known actor emails" {
  local sha email
  while read -r sha; do
    [[ -z "$sha" ]] && continue
    email="$(git -C "$REPO_ROOT" log -1 --format='%ae' "$sha")"
    local known=false
    for known_email in "${ACTOR_EMAILS[@]}"; do
      if [[ "$email" == "$known_email" ]]; then
        known=true
        break
      fi
    done
    if [[ "$known" == "false" ]]; then
      echo "commit $sha has unknown author email: $email"
      git -C "$REPO_ROOT" log -1 --format='  subject: %s' "$sha"
      return 1
    fi
  done < <(git -C "$REPO_ROOT" log -n "$RECENT_COMMIT_COUNT" --format='%H')
}

@test "recent default-email commits have Co-authored-by trailers" {
  # A commit with the default `ajoeofalltrades@users.noreply.github.com`
  # email must include a `Co-authored-by:` trailer naming another actor.
  # Commits with `taisden@tais-den.dev` or `hermes-agent@tais-den.dev`
  # are self-identifying and need no trailer.
  local sha email message trailer_lines
  while read -r sha; do
    [[ -z "$sha" ]] && continue
    email="$(git -C "$REPO_ROOT" log -1 --format='%ae' "$sha")"
    if [[ "$email" == "$DEFAULT_EMAIL" ]]; then
      message="$(git -C "$REPO_ROOT" log -1 --format='%B' "$sha")"
      trailer_lines="$(printf '%s\n' "$message" | git -C "$REPO_ROOT" interpret-trailers --parse | grep -i '^Co-authored-by:' || true)"
      if [[ -z "$trailer_lines" ]]; then
        echo "commit $sha uses default email but has no Co-authored-by trailer:"
        git -C "$REPO_ROOT" log -1 --format='  subject: %s' "$sha"
        return 1
      fi
    fi
  done < <(git -C "$REPO_ROOT" log -n "$RECENT_COMMIT_COUNT" --format='%H')
}

@test "recent commits with agent emails carry Agent-Attribution trailers" {
  # Commits authored by an agent email must include at least one
  # well-formed Agent-Attribution: trailer recording actor, model,
  # role, and session mode.
  local sha email message trailer_lines pattern
  pattern="$(agent_attribution_pattern)"
  while read -r sha; do
    [[ -z "$sha" ]] && continue
    email="$(git -C "$REPO_ROOT" log -1 --format='%ae' "$sha")"
    case "$email" in
      hermes-agent@tais-den.dev)
        message="$(git -C "$REPO_ROOT" log -1 --format='%B' "$sha")"
        trailer_lines="$(printf '%s\n' "$message" | git -C "$REPO_ROOT" interpret-trailers --parse | grep -i '^Agent-Attribution:' || true)"
        if [[ -z "$trailer_lines" ]]; then
          echo "commit $sha authored by agent ($email) has no Agent-Attribution trailer:"
          git -C "$REPO_ROOT" log -1 --format='  subject: %s' "$sha"
          return 1
        fi
        if ! printf '%s\n' "$trailer_lines" | grep -Eq "$pattern"; then
          echo "commit $sha Agent-Attribution trailer(s) lack required fields:"
          printf '%s\n' "$trailer_lines" | sed 's/^/    /'
          return 1
        fi
        ;;
    esac
  done < <(git -C "$REPO_ROOT" log -n "$RECENT_COMMIT_COUNT" --format='%H')
}