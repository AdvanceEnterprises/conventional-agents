#!/usr/bin/env bash
# sync-skills.sh — refresh the Claude Code plugin's skill copies from source.
#
# The plugin's skills/ directory mirrors the framework's skills/ (SC-11/SC-12):
# - Every skill listed in skills/index.md becomes invocable in Claude Code.
# - The copies are byte-identical to source; no dialect transformation is
#   applied (ADR-0038 §5 — source skills carry only spec fields).
#
# Run from within the repository it should sync (or with CA_TARGET_REPO set to
# that repository's working tree — the FS-0024/ADR-0033 caller-cwd convention).
# The resolved target must be inside a git working tree: a run from a
# directory git disclaims fails loudly instead of writing plugin scaffolding
# outside any repository (issue #204). A target naming a subdirectory maps to
# the work-tree top level, and a bare repository and a missing git binary get
# their own diagnostics.
#
# Exits non-zero if any expected skill fails to copy — a source skill missing
# its SKILL.md counts as a failed copy, not a silent skip (issue #204).

set -eu

# ----- Target resolution (issue #204) ----------------------------------------
# Before this guard, the target defaulted to the literal working directory:
# from a non-git cwd the script wrote integrations/runtimes/claude-code/skills
# scaffolding outside any repository and printed "synced N skills" at exit 0,
# and from a checkout subdirectory it failed with a misleading "no skills/"
# error. Resolution is repository-relative now (FS-0024/ADR-0033): the target
# names a repository.
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: 'git' was not found on PATH — sync-skills needs git to resolve and verify the target repository." >&2
  exit 2
fi
if [ -n "${CA_TARGET_REPO:-}" ]; then
  TARGET_DIR="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)" || {
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 2
  }
else
  TARGET_DIR="$PWD"
fi
if [ "$(git -C "$TARGET_DIR" rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  if [ "$(git -C "$TARGET_DIR" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
    echo "ERROR: '$TARGET_DIR' is a bare git repository — it has no working tree to sync into." >&2
  else
    echo "ERROR: '$TARGET_DIR' is not inside a git working tree." >&2
  fi
  echo "       Run this script from within the repository it should sync, or set" >&2
  echo "       CA_TARGET_REPO to that repository's working tree. (issue #204)" >&2
  exit 2
fi
# Repository-relative: a subdirectory target maps to the work-tree top level,
# exactly as the working-directory default does (ADR-0033).
ROOT="$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null)"
PLUGIN_SKILLS="$ROOT/integrations/runtimes/claude-code/skills"
SHIPPED_SKILLS_DIR="$ROOT/skills"

# Skills listed in skills/index.md that ship in the plugin. `example-skill`
# is a template, explicitly excluded from the runtime binding (ADR-0038
# Category 2 cleanup tracks its fate separately). The deprecated
# `git-gh-workflow` router is NOT shipped; its five successors are
# (skills/index.md).
readonly SKILLS=(
  role-aware-session
  framework-consumer-integration
  framework-health-audit
  document-lifecycle
  testing-guide
  git-commit-identity
  git-branch-and-commit
  gh-pr-workflow
  versioning-and-releases
  work-item-stance
)

[ -d "$SHIPPED_SKILLS_DIR" ] || {
  echo "ERROR: no skills/ dir under $ROOT — run me from a framework checkout" >&2
  exit 2
}

mkdir -p "$PLUGIN_SKILLS"
failures=0
for skill in "${SKILLS[@]}"; do
  src="$SHIPPED_SKILLS_DIR/$skill"
  if [ ! -f "$src/SKILL.md" ]; then
    # A listed skill without a SKILL.md is a failed copy, not a skip: the
    # plugin would ship without a skill the list promises (issue #204). The
    # counter feeds the final check below, which was previously unreachable —
    # a run that copied nothing printed "synced 0 skills" and exited 0.
    echo "ERROR: $skill has no SKILL.md — cannot sync" >&2
    failures=$((failures + 1))
    continue
  fi
  mkdir -p "$PLUGIN_SKILLS/$skill"
  cp "$src/SKILL.md" "$PLUGIN_SKILLS/$skill/SKILL.md"
  # Supporting files travel with the skill. A skill may keep on-demand material
  # in a sibling references/ directory and cite it by a path relative to its own
  # SKILL.md (skills/AUTHORING.md rule 4 relocates overflow there). Copying only
  # SKILL.md leaves those citations pointing at files that are not in the plugin,
  # which fails check-status.sh rule 8 (FS-0022 §1c) on the synced tree.
  if [ -d "$src/references" ]; then
    mkdir -p "$PLUGIN_SKILLS/$skill/references"
    cp "$src"/references/*.md "$PLUGIN_SKILLS/$skill/references/" 2>/dev/null || true
  fi
done

n=0
for f in "$PLUGIN_SKILLS"/*/SKILL.md; do
  [ -e "$f" ] && n=$((n+1))
done
echo "synced $n skills into $PLUGIN_SKILLS"

# The skill catalog travels with the copies. Each source SKILL.md may cite the
# catalog as `../index.md` relative to its own directory; that resolves to
# skills/index.md in the framework checkout, so it must also resolve from
# integrations/runtimes/claude-code/skills/<skill>/ in the plugin.
if [ -f "$SHIPPED_SKILLS_DIR/index.md" ]; then
  cp "$SHIPPED_SKILLS_DIR/index.md" "$PLUGIN_SKILLS/index.md"
fi

[ "$failures" -eq 0 ] || {
  echo "ERROR: $failures skill(s) failed to sync" >&2
  exit 1
}
exit 0
