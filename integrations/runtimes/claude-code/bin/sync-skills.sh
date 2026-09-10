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
done

n=0
for f in "$PLUGIN_SKILLS"/*/SKILL.md; do
  [ -e "$f" ] && n=$((n+1))
done
echo "synced $n skills into $PLUGIN_SKILLS"

[ "$failures" -eq 0 ] || {
  echo "ERROR: $failures skill(s) failed to sync" >&2
  exit 1
}
exit 0
