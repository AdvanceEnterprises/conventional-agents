#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const ALLOWED_EXACT_SOURCES = new Set(['README.md', 'AGENTS.md', 'INTEGRATION.md']);
const ALLOWED_SOURCE_ROOTS = [
  'guidelines/',
  'roles/',
  'skills/',
  'templates/',
  'workflows/',
  'integrations/',
  'runbooks/',
];
// Stored lowercase; the lookup folds case so `backlog.md` and `BACKLOG.md`
// both fail closed with the same denied-source diagnostic (MM3 finding 2, PR #208).
const DENIED_EXACT_SOURCES = new Set(['backlog.md']);
const DENIED_PREFIXES = [
  'vendor/',
  'test/',
  'docs/decisions/',
  'docs/specifications/',
  'docs/change-plans/',
  'docs/proposals/',
  'docs/orchestration/',
  '.claude/',
  '.github/',
  'config/',
  'benchmark/',
  '_site/',
];
const DENIED_FILE_PATTERNS = [/\.log$/i, /\.log\./i, /^docs\/validation-baseline/i];

function usage() {
  console.log(`Usage: node scripts/check-site-publication.mjs [options]

Validates the curated site manifest, reviewed canonical sources, generated
artifact inventory, project-site paths, and accessible HTML structure.

Options:
  --root <path>       Validate this repository target (or use CA_TARGET_REPO).
  --manifest <path>   Read a manifest from this path, relative to the target.
  --manifest-only     Skip generated artifact and HTML checks.
  --help              Show this help.

A target without site/ is a successful consumer-repository skip.`);
}

function parseArgs(argv) {
  const options = { manifestOnly: false, manifest: null, root: null };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--help' || argument === '-h') {
      usage();
      process.exit(0);
    }
    if (argument === '--manifest-only') {
      options.manifestOnly = true;
      continue;
    }
    if (argument === '--root' || argument === '--manifest') {
      const value = argv[index + 1];
      if (!value) throw new Error(`${argument} requires a value`);
      options[argument === '--root' ? 'root' : 'manifest'] = value;
      index += 1;
      continue;
    }
    throw new Error(`unknown option: ${argument}`);
  }
  return options;
}

function git(args, root, allowFailure = false) {
  try {
    return execFileSync('git', args, {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', allowFailure ? 'ignore' : 'pipe'],
    }).trim();
  } catch (error) {
    if (allowFailure) return '';
    throw error;
  }
}

function resolveRepositoryRoot(requestedRoot) {
  if (requestedRoot || process.env.CA_TARGET_REPO) {
    return path.resolve(requestedRoot || process.env.CA_TARGET_REPO);
  }
  return git(['rev-parse', '--show-toplevel'], process.cwd());
}

function fail(errors) {
  if (errors.length === 0) return;
  for (const error of errors) console.error(`FAIL: ${error}`);
  process.exitCode = 1;
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    throw new Error(`cannot read JSON manifest ${filePath}: ${error.message}`);
  }
}

function isPathSafe(relativePath) {
  return (
    typeof relativePath === 'string' &&
    relativePath.length > 0 &&
    !relativePath.startsWith('/') &&
    !relativePath.includes('\\') &&
    !relativePath.includes('\0') &&
    !relativePath.split('/').includes('..') &&
    !relativePath.split('/').includes('.') &&
    !/[\*?{}[\]]/.test(relativePath) &&
    path.posix.normalize(relativePath) === relativePath &&
    !relativePath.endsWith('/')
  );
}

function deniedReason(relativePath) {
  const normalized = relativePath.toLowerCase();
  // Case-fold the denied-exact lookup too, so a case-variant source (e.g.
  // `backlog.md`) fails closed with the same denied-source diagnostic instead
  // of falling through to the allowed-roots error (MM3 finding 2, PR #208).
  if (DENIED_EXACT_SOURCES.has(normalized)) return `denied source ${relativePath}`;
  for (const prefix of DENIED_PREFIXES) {
    if (normalized.startsWith(prefix.toLowerCase())) return `denied path ${relativePath}`;
  }
  for (const pattern of DENIED_FILE_PATTERNS) {
    if (pattern.test(relativePath)) return `denied log or baseline path ${relativePath}`;
  }
  return null;
}

function isAllowedSource(relativePath) {
  return ALLOWED_EXACT_SOURCES.has(relativePath) ||
    ALLOWED_SOURCE_ROOTS.some((prefix) => relativePath.startsWith(prefix));
}

function normalizeBasePath(value) {
  if (value === '/') return '/';
  if (typeof value !== 'string' || !value.startsWith('/')) return null;
  if (value.includes('//') || value.includes('..')) return null;
  return value.endsWith('/') ? value : `${value}/`;
}

function sha256(filePath) {
  return `sha256:${crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex')}`;
}

function ensureRegularFile(root, relativePath, errors, label) {
  const absolutePath = path.join(root, relativePath);
  const segments = relativePath.split('/');
  let current = root;
  for (const segment of segments) {
    current = path.join(current, segment);
    let stat;
    try {
      stat = fs.lstatSync(current);
    } catch {
      errors.push(`${label} is missing: ${relativePath}`);
      return null;
    }
    if (stat.isSymbolicLink()) {
      errors.push(`${label} uses a symlink, which is not publishable: ${relativePath}`);
      return null;
    }
    // The per-segment walk already rejects symlinked directories; the same
    // loop also covers the leaf, so a final lstatSync here is authoritative
    // and no symlink-resolving statSync is needed for the regular-file check.
    if (current === absolutePath && !stat.isFile()) {
      errors.push(`${label} is not a regular file: ${relativePath}`);
      return null;
    }
  }
  return absolutePath;
}

function routeToOutput(route) {
  if (route === '/') return 'index.html';
  if (route === '/404.html') return '404.html';
  const trimmed = route.replace(/^\//, '').replace(/\/$/, '');
  return `${trimmed}/index.html`;
}

function validateManifest(root, manifest, errors) {
  if (manifest?.manifest_version !== 1) errors.push('manifest_version must be 1');
  const basePath = normalizeBasePath(manifest?.base_path);
  if (!basePath) errors.push('base_path must be a single-slash-prefixed path with no doubled separators');
  if (!/^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(manifest?.source_repository || '')) {
    errors.push('source_repository must be an HTTPS GitHub repository URL without a trailing slash');
  }
  if (!manifest?.source_revision || (manifest.source_revision !== 'build' && !/^[0-9a-f]{7,64}$/.test(manifest.source_revision))) {
    errors.push('source_revision must be build or a hexadecimal Git revision');
  }
  if (!Array.isArray(manifest?.pages) || manifest.pages.length === 0) {
    errors.push('pages must be a non-empty array');
    return { basePath, pages: [], assets: [] };
  }

  const pages = [];
  const routes = new Map();
  const sourcePaths = new Map();
  for (const [index, page] of manifest.pages.entries()) {
    const label = `pages[${index}]`;
    for (const field of ['route', 'title', 'audience', 'kind', 'template', 'source']) {
      if (!page?.[field]) errors.push(`${label} is missing ${field}`);
    }
    if (typeof page?.route !== 'string' || !page.route.startsWith('/') || page.route.includes('..') || page.route.includes('//')) {
      errors.push(`${label} has an unsafe route: ${page?.route}`);
    } else if (routes.has(page.route)) {
      errors.push(`duplicate route ${page.route} in ${label} and pages[${routes.get(page.route)}]`);
    } else {
      routes.set(page.route, index);
    }
    if (!['rendered', 'link-only'].includes(page?.kind)) errors.push(`${label} has invalid kind ${page?.kind}`);
    if (page?.kind === 'rendered') {
      if (!['guide', 'summary'].includes(page.content_kind)) errors.push(`${label} has invalid content_kind ${page.content_kind}`);
      if (!/^sha256:[0-9a-f]{64}$/.test(page.reviewed_source_digest || '')) errors.push(`${label} has invalid reviewed_source_digest`);
    }
    if (!isPathSafe(page?.template || '')) {
      errors.push(`${label} has an unsafe template path: ${page?.template}`);
    } else {
      const templatePath = path.join(root, 'site', 'src', page.template);
      if (!fs.existsSync(templatePath) || !fs.statSync(templatePath).isFile()) errors.push(`${label} template is missing: ${page.template}`);
    }
    const source = page?.source;
    if (!isPathSafe(source || '')) {
      errors.push(`${label} has an unsafe source path: ${source}`);
    } else {
      const denied = deniedReason(source);
      if (denied) errors.push(`${label} ${denied}`);
      if (!isAllowedSource(source)) errors.push(`${label} source is outside the validator-owned allowed roots: ${source}`);
      const previous = sourcePaths.get(source.toLowerCase());
      if (previous && previous !== source) errors.push(`case-folding collision between source paths ${previous} and ${source}`);
      sourcePaths.set(source.toLowerCase(), source);
      const sourcePath = ensureRegularFile(root, source, errors, `${label} source`);
      if (sourcePath && page.kind === 'rendered' && sha256(sourcePath) !== page.reviewed_source_digest) {
        errors.push(`${label} reviewed source digest does not match ${source}`);
      }
    }
    pages.push(page);
  }

  if (!routes.has('/404.html')) errors.push('manifest must declare a /404.html page');

  const assets = Array.isArray(manifest.assets) ? manifest.assets : [];
  if (!Array.isArray(manifest.assets)) errors.push('assets must be an array');
  const assetSet = new Set();
  for (const [index, asset] of assets.entries()) {
    if (!isPathSafe(asset) || !asset.startsWith('assets/')) errors.push(`assets[${index}] is not a safe site asset path: ${asset}`);
    if (assetSet.has(asset)) errors.push(`duplicate asset ${asset}`);
    assetSet.add(asset);
    if (isPathSafe(asset)) ensureRegularFile(root, path.join('site', 'src', asset), errors, `assets[${index}]`);
  }

  const outputs = new Map();
  for (const page of pages) {
    const output = routeToOutput(page.route);
    if (outputs.has(output)) errors.push(`routes ${outputs.get(output)} and ${page.route} produce the same artifact ${output}`);
    outputs.set(output, page.route);
  }
  return { basePath, pages, assets, outputs };
}

function validateApproval(root, manifest, errors, usingDefaultManifest) {
  const approval = manifest.publication_approval;
  if (!approval || !/^[0-9a-f]{40}$/.test(approval.commit || '')) {
    errors.push('publication_approval.commit must be a full Git commit SHA');
    return;
  }
  const commitBody = git(['show', '-s', '--format=%B', approval.commit], root, true);
  if (!commitBody) {
    errors.push(`publication approval commit is not present in the target history: ${approval.commit}`);
    return;
  }
  if (!/^Approved-By:\s*.+$/m.test(commitBody)) errors.push(`approval commit ${approval.commit} has no Approved-By trailer`);
  if (!/^Approved-Artifacts:\s*.+$/m.test(commitBody)) errors.push(`approval commit ${approval.commit} has no Approved-Artifacts trailer`);
  if (!commitBody.includes('site/**')) errors.push(`approval commit ${approval.commit} does not attest site/**`);
  for (const source of approval.reviewed_source_paths || []) {
    if (!ALLOWED_EXACT_SOURCES.has(source) && !ALLOWED_SOURCE_ROOTS.some((prefix) => source.startsWith(prefix))) {
      errors.push(`publication approval lists a source outside the fixed allowed roots: ${source}`);
    }
    if (!commitBody.includes(source)) errors.push(`approval commit ${approval.commit} does not name reviewed source ${source}`);
  }

  if (!usingDefaultManifest) return;
  const latestManifestCommit = git(['log', '-1', '--format=%H', '--', 'site/content-manifest.json'], root, true);
  if (!latestManifestCommit) return;
  const status = git(['status', '--porcelain', '--', 'site/content-manifest.json'], root, true);
  if (status) errors.push('site/content-manifest.json has uncommitted changes; record a new ADR-0026 publication approval before changing it');
  if (latestManifestCommit !== approval.commit) {
    const implementationBody = git(['show', '-s', '--format=%B', latestManifestCommit], root, true);
    if (!implementationBody.includes(`Publication-Approval: ${approval.commit}`)) {
      errors.push(`manifest revision ${latestManifestCommit} lacks Publication-Approval: ${approval.commit}`);
    }
    const parent = git(['rev-parse', `${latestManifestCommit}^`], root, true);
    if (parent !== approval.commit) {
      errors.push(`manifest revision ${latestManifestCommit} must directly follow recorded approval ${approval.commit}`);
    }
  }
}

function listFiles(directory, prefix = '') {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const relative = prefix ? `${prefix}/${entry.name}` : entry.name;
    const absolute = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`generated artifact is a symlink: ${relative}`);
    if (entry.isDirectory()) files.push(...listFiles(absolute, relative));
    else if (entry.isFile()) files.push(relative);
    else throw new Error(`generated artifact is not a regular file: ${relative}`);
  }
  return files;
}

function validateHtml(root, manifest, inventory, errors) {
  const outputRoot = path.join(root, '_site');
  const revision = process.env.SITE_SOURCE_REVISION || git(['rev-parse', 'HEAD'], root, true) || manifest.source_revision;
  const repository = manifest.source_repository.replace(/\/$/, '');
  for (const page of inventory.pages) {
    const output = path.join(outputRoot, routeToOutput(page.route));
    if (!fs.existsSync(output)) continue;
    const html = fs.readFileSync(output, 'utf8');
    const count = (pattern) => (html.match(pattern) || []).length;
    if (count(/<title\b/gi) !== 1) errors.push(`${page.route} must contain exactly one title`);
    if (count(/<h1\b/gi) !== 1) errors.push(`${page.route} must contain exactly one h1`);
    for (const landmark of ['<header', '<nav', '<main', '<footer']) {
      if (!html.includes(landmark)) errors.push(`${page.route} is missing semantic landmark ${landmark}`);
    }
    if (!html.includes('class="skip-link"') || !html.includes('href="#main-content"')) errors.push(`${page.route} is missing a skip link`);
    const expectedKind = page.kind === 'link-only' ? 'link-only' : page.content_kind;
    if (!html.includes(`name="conventional-agents:content-kind" content="${expectedKind}"`)) errors.push(`${page.route} has the wrong content-kind marker`);
    if (!html.includes(`name="conventional-agents:source-path" content="${page.source}"`)) errors.push(`${page.route} has the wrong source-path marker`);
    if (!html.includes(`${repository}/blob/${revision}/${page.source}`)) errors.push(`${page.route} is missing its SHA-pinned source link`);
    if (!html.includes('repository access may be required')) errors.push(`${page.route} must state the source access boundary`);
    if (/<script\b/i.test(html)) errors.push(`${page.route} must not require JavaScript`);
    const links = [...html.matchAll(/(?:href|src)="([^"]+)"/g)].map((match) => match[1]);
    for (const link of links) {
      if (link.startsWith('#') || /^(?:https?:|mailto:|tel:|data:|\/\/)/i.test(link)) continue;
      if (!link.startsWith(inventory.basePath)) errors.push(`${page.route} has a root-relative or unprefixed internal URL: ${link}`);
    }
    if (page.route === '/404.html' && !html.includes(`href="${inventory.basePath}"`)) errors.push('404 page must link back to the project-site base path');
  }
}

function validateArtifacts(root, manifest, inventory, errors) {
  const outputRoot = path.join(root, '_site');
  if (!fs.existsSync(outputRoot)) {
    errors.push('_site is missing; run the site build before the full publication check');
    return;
  }
  let actual;
  try {
    actual = listFiles(outputRoot).sort();
  } catch (error) {
    errors.push(error.message);
    return;
  }
  const expected = [...new Set([...inventory.outputs.keys(), ...inventory.assets])].sort();
  const missing = expected.filter((file) => !actual.includes(file));
  const extra = actual.filter((file) => !expected.includes(file));
  if (missing.length) errors.push(`artifact inventory is missing: ${missing.join(', ')}`);
  if (extra.length) errors.push(`artifact inventory contains undeclared files: ${extra.join(', ')}`);
  validateHtml(root, manifest, inventory, errors);
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const root = resolveRepositoryRoot(options.root);
  const siteDirectory = path.join(root, 'site');
  if (!fs.existsSync(siteDirectory)) {
    console.log(`SKIP: no site directory at ${root}`);
    return;
  }
  const manifestPath = options.manifest ? path.resolve(root, options.manifest) : path.join(siteDirectory, 'content-manifest.json');
  const manifest = readJson(manifestPath);
  const errors = [];
  const inventory = validateManifest(root, manifest, errors);
  const configuredBasePath = normalizeBasePath(process.env.SITE_BASE_PATH || manifest.base_path);
  if (configuredBasePath && inventory.basePath && configuredBasePath !== inventory.basePath) {
    errors.push(`SITE_BASE_PATH ${configuredBasePath} differs from manifest base_path ${inventory.basePath}`);
  }
  if (configuredBasePath) inventory.basePath = configuredBasePath;
  validateApproval(root, manifest, errors, !options.manifest);
  if (!options.manifestOnly) validateArtifacts(root, manifest, inventory, errors);
  if (errors.length) {
    fail(errors);
    return;
  }
  if (options.manifestOnly) console.log(`PASS: publication manifest (${inventory.pages.length} pages, ${inventory.assets.length} assets)`);
  else console.log(`PASS: publication artifact (${inventory.pages.length} pages, ${inventory.assets.length} assets)`);
}

try {
  main();
} catch (error) {
  console.error(`FAIL: ${error.message}`);
  process.exitCode = 1;
}
