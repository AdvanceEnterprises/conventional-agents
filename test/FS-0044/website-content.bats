#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  VALIDATOR="$REPO_ROOT/scripts/check-site-publication.mjs"
  MANIFEST="$REPO_ROOT/site/content-manifest.json"
}

@test "FS-0044 implementation surface exists" {
  for path in \
    "$REPO_ROOT/site/.eleventy.js" \
    "$REPO_ROOT/site/package.json" \
    "$REPO_ROOT/site/package-lock.json" \
    "$REPO_ROOT/site/content-manifest.json" \
    "$REPO_ROOT/site/src/_includes/layout.njk" \
    "$REPO_ROOT/site/src/index.njk" \
    "$REPO_ROOT/site/src/adopt.njk" \
    "$REPO_ROOT/site/src/contribute.njk" \
    "$REPO_ROOT/site/src/404.njk" \
    "$REPO_ROOT/site/src/assets/site.css" \
    "$VALIDATOR" \
    "$REPO_ROOT/.github/workflows/pages.yml"; do
    assert_file_exists "$path"
  done
}

@test "the content manifest declares curated rendered and link-only pages" {
  run node - "$MANIFEST" <<'NODE'
const fs = require('node:fs');
const manifest = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!Array.isArray(manifest.pages) || manifest.pages.length < 3) {
  throw new Error('expected at least three curated pages');
}
const kinds = new Set(manifest.pages.map((page) => page.kind));
if (!kinds.has('rendered') || !kinds.has('link-only')) {
  throw new Error('manifest must contain rendered and link-only entries');
}
for (const page of manifest.pages) {
  for (const field of ['route', 'title', 'audience', 'kind', 'source']) {
    if (!page[field]) throw new Error(`missing ${field}`);
  }
  if (typeof page.route !== 'string' || !page.route.startsWith('/') || page.route.includes('..')) {
    throw new Error(`invalid route: ${page.route}`);
  }
  if (page.kind === 'rendered') {
    if (!['guide', 'summary'].includes(page.content_kind)) {
      throw new Error(`invalid content kind: ${page.content_kind}`);
    }
    if (!/^sha256:[0-9a-f]{64}$/.test(page.reviewed_source_digest)) {
      throw new Error(`invalid reviewed digest for ${page.route}`);
    }
    if (!page.template) throw new Error(`missing template for ${page.route}`);
  }
}
NODE
  [ "$status" -eq 0 ]
}

@test "the validator accepts the manifest and fixed publication policy" {
  run node "$VALIDATOR" --manifest-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS: publication manifest"* ]]
}

@test "a target without site exits with an explicit skip" {
  local target
  target="$(mktemp -d)"
  run env CA_TARGET_REPO="$target" node "$VALIDATOR"
  rm -rf "$target"
  [ "$status" -eq 0 ]
  [[ "$output" == "SKIP: no site directory at $target" ]]
}

@test "the validator rejects denied canonical sources" {
  local manifest_copy
  manifest_copy="$(mktemp)"
  node - "$MANIFEST" "$manifest_copy" <<'NODE'
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
source.pages[0].source = 'docs/decisions/ADR-0044-curated-public-github-pages-derivative.md';
fs.writeFileSync(process.argv[3], JSON.stringify(source));
NODE
  run node "$VALIDATOR" --manifest-only --manifest "$manifest_copy"
  rm -f "$manifest_copy"
  [ "$status" -ne 0 ]
  [[ "$output" == *"denied"* || "$output" == *"docs/decisions"* ]]
}

@test "the validator rejects duplicate routes" {
  local manifest_copy
  manifest_copy="$(mktemp)"
  node - "$MANIFEST" "$manifest_copy" <<'NODE'
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
source.pages[1].route = source.pages[0].route;
fs.writeFileSync(process.argv[3], JSON.stringify(source));
NODE
  run node "$VALIDATOR" --manifest-only --manifest "$manifest_copy"
  rm -f "$manifest_copy"
  [ "$status" -ne 0 ]
  [[ "$output" == *"duplicate route"* ]]
}

@test "the validator rejects a stale reviewed source digest" {
  local manifest_copy
  manifest_copy="$(mktemp)"
  node - "$MANIFEST" "$manifest_copy" <<'NODE'
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const page = source.pages.find((entry) => entry.kind === 'rendered');
page.reviewed_source_digest = `sha256:${'0'.repeat(64)}`;
fs.writeFileSync(process.argv[3], JSON.stringify(source));
NODE
  run node "$VALIDATOR" --manifest-only --manifest "$manifest_copy"
  rm -f "$manifest_copy"
  [ "$status" -ne 0 ]
  [[ "$output" == *"digest"* ]]
}

@test "the validator rejects traversal and case-folded source paths" {
  local manifest_copy
  manifest_copy="$(mktemp)"
  node - "$MANIFEST" "$manifest_copy" <<'NODE'
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
source.pages[0].source = '../README.md';
source.pages[1].source = 'readme.md';
fs.writeFileSync(process.argv[3], JSON.stringify(source));
NODE
  run node "$VALIDATOR" --manifest-only --manifest "$manifest_copy"
  rm -f "$manifest_copy"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsafe source path"* ]]
  [[ "$output" == *"case-folding collision"* ]]
}

@test "the validator rejects symlinked canonical sources" {
  local manifest_copy symlink_path
  manifest_copy="$(mktemp)"
  symlink_path="$REPO_ROOT/guidelines/FS-0044-test-link.md"
  ln -s ../README.md "$symlink_path"
  node - "$MANIFEST" "$manifest_copy" <<'NODE'
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
source.pages[0].source = 'guidelines/FS-0044-test-link.md';
fs.writeFileSync(process.argv[3], JSON.stringify(source));
NODE
  run node "$VALIDATOR" --manifest-only --manifest "$manifest_copy"
  rm -f "$manifest_copy" "$symlink_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"symlink"* ]]
}

@test "the validator normalizes a project-site base path without a trailing slash" {
  run env SITE_BASE_PATH=/conventional-agents node "$VALIDATOR" --manifest-only
  [ "$status" -eq 0 ]
}

@test "the Pages workflow has an unfiltered PR build and trunk-only deployment" {
  local workflow="$REPO_ROOT/.github/workflows/pages.yml"
  assert_file_contains "$workflow" "node-version: 24"
  assert_file_contains "$workflow" "npm ci --prefix site"
  assert_file_contains "$workflow" "npm run site:check"
  # Deployment actions are SHA-pinned with the release tag kept as a comment
  # (Kimi K2.7 review finding 2, PR #208); match either pinned or tag form.
  if ! grep -qE 'actions/configure-pages@[0-9a-f]{40} # v5' "$workflow"; then
    assert_file_contains "$workflow" "actions/configure-pages@v5"
  fi
  assert_file_contains "$workflow" "actions/upload-pages-artifact@v3"
  if ! grep -qE 'actions/deploy-pages@[0-9a-f]{40} # v4' "$workflow"; then
    assert_file_contains "$workflow" "actions/deploy-pages@v4"
  fi
  assert_file_contains "$workflow" "name: github-pages"
  assert_file_contains "$workflow" "github.ref == 'refs/heads/trunk'"
  local deploy_block
  deploy_block="$(grep -A14 -F -- "  deploy:" "$workflow")"
  [[ "$deploy_block" == *"if: github.ref == 'refs/heads/trunk'"* ]]
  if ! grep -qE 'actions/configure-pages@[0-9a-f]{40} # v5' <<< "$deploy_block"; then
    [[ "$deploy_block" == *"actions/configure-pages@v5"* ]]
  fi
  if grep -qE '^      paths:' "$workflow"; then
    echo "Pages workflow must not path-filter pull requests"
    return 1
  fi
}

@test "generated output is ignored but canonical source is not" {
  assert_file_contains "$REPO_ROOT/.gitignore" "_site/"
  if grep -qE '^site/$' "$REPO_ROOT/.gitignore"; then
    echo "site source must remain trackable"
    return 1
  fi
}
