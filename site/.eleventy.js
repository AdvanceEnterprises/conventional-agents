const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const siteRoot = __dirname;
const repositoryRoot = path.resolve(siteRoot, '..');
const manifest = JSON.parse(
  fs.readFileSync(path.join(siteRoot, 'content-manifest.json'), 'utf8'),
);

function normalizeBasePath(value) {
  const candidate = value || '/conventional-agents/';
  if (candidate === '/') return '/';
  const withLeadingSlash = candidate.startsWith('/') ? candidate : `/${candidate}`;
  return withLeadingSlash.endsWith('/') ? withLeadingSlash : `${withLeadingSlash}/`;
}

function gitRevision() {
  if (process.env.SITE_SOURCE_REVISION) return process.env.SITE_SOURCE_REVISION;
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: repositoryRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return manifest.source_revision === 'build' ? 'unknown' : manifest.source_revision;
  }
}

function sourceUrl(source) {
  const repository = manifest.source_repository.replace(/\/$/, '');
  const revision = gitRevision();
  const encodedSource = source.split('/').map(encodeURIComponent).join('/');
  return `${repository}/blob/${revision}/${encodedSource}`;
}

module.exports = function configure(eleventyConfig) {
  const basePath = normalizeBasePath(process.env.SITE_BASE_PATH || manifest.base_path);
  const revision = gitRevision();

  eleventyConfig.addGlobalData('manifest', manifest);
  eleventyConfig.addGlobalData('site', {
    basePath,
    sourceRepository: manifest.source_repository,
    sourceRevision: revision,
  });
  eleventyConfig.addFilter('sourceUrl', sourceUrl);
  eleventyConfig.addPassthroughCopy({ 'src/assets': 'assets' });

  return {
    dir: {
      input: 'src',
      includes: '_includes',
      output: '../_site',
    },
    markdownTemplateEngine: false,
    htmlTemplateEngine: 'njk',
    templateFormats: ['njk'],
  };
};
