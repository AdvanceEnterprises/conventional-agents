#!/usr/bin/env bash
# sync-skills.sh — refresh the Claude Code plugin's skill copies from source.
#
# The plugin's skills/ directory mirrors the framework's skills/ (SC-11/SC-12):
# - Every skill listed in skills/index.md becomes invocable in Claude Code.
# - The copies are byte-identical to source; no dialect transformation is
#   applied (ADR-0038 §5 — source skills carry only spec fields).
#
# Run from the repository root (or with CA_TARGET_REPO set to the repository
# root — FS-0024/ADR-0033 caller-cwd convention).
#
# Exits non-zero if any expected skill fails to copy.

set -eu

TARGET_DIR="${CA_TARGET_REPO:-$PWD}"
ROOT="$(cd "$TARGET_DIR" && pwd)"
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
    echo "WARN: $skill has no SKILL.md — skipping" >&2
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
