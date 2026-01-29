# agent-dev-kit

Prescriptive framework for LLM-driven development workflows. Guidelines, templates, and patterns for building and maintaining software with AI assistance.

## Philosophy

This framework is based on evidence-based practices, not opinions. Every guideline has a rationale rooted in:
- Real-world testing and iteration
- Framework-agnostic principles (applies to Python, Bash, Node, etc.)
- Practical constraints of LLM-assisted development
- Operational clarity and auditability

**Core principle:** Evidence over preference.

## What's Included

### Guidelines

Language-specific best practices for code quality, testing, and implementation:

- **Bash**: Style, testing patterns, and implementation guidance
- **Python**: Style, testing patterns, and implementation guidance
- **Role Contract**: LLM agent role definition and responsibilities

See `guidelines/` directory.

### Templates

Reusable document and code templates for common development activities:

- **Core**: Feature specifications, ADRs, architecture, change plans
- **Reviewer**: PR review, spec review, and test review templates
- **Python Tests**: Unit test, integration test, and test configuration templates

See `templates/` directory.

ADR canonical sources:
- ADR templates live in `vendor/madr/template`.
- Additional ADR documentation lives in `vendor/madr/docs`.

### Architecture

This project's architecture follows ARC42, documented in
`vendor/arc42-template/dist/arc42-template-EN-withhelp-markdown/`. 
You may need to first unzip the archive in 'vendor/arc42-template/dist/' to view the markdown content.

## Installation

### As a Git Submodule (Recommended)

For projects that want to stay in sync with upstream changes:

```bash
cd /path/to/your-project
git submodule add https://github.com/anthropics/agent-dev-kit.git .agents
git submodule update --init
```

Then reference guidelines and templates from `.agents/`:

```bash
cat .agents/guidelines/bash/BASH_STYLE_GUIDE.md
cat .agents/templates/core/feature-spec.md
```

Update to latest version:

```bash
cd .agents
git pull origin main
cd ..
git add .agents
git commit -m "Update agent-dev-kit to latest"
```

Note: Full upstream projects are included as git submodules, as documented in
`docs/decisions/ADR-0003.md`.

### Manual Copy

For one-time use or custom modifications:

```bash
git clone https://github.com/anthropics/agent-dev-kit.git
cp -r agent-dev-kit/.agents /path/to/your-project/
```

## Usage

### As Project Documentation

Reference in your project's `CLAUDE.md` (Claude Code guidance file):

```markdown
## Agent Guidelines

The development process follows evidence-based practices defined in agent-dev-kit:

- [Bash Style Guide](./.agents/guidelines/bash/BASH_STYLE_GUIDE.md)
- [Bash Testing Guide](./.agents/guidelines/bash/BASH_TESTING_GUIDE.md)
- [Role Contract](./.agents/guidelines/ROLE_CONTRACT.md)
```

### As Development Templates

Use templates to bootstrap common development activities:

```bash
# Start a new feature with a spec
cp .agents/templates/core/feature-spec.md SPEC-MY-FEATURE.md
# Edit and iterate

# Record architectural decisions
cp .agents/templates/core/adr-full-madr.md docs/adr/ADR-0001.md

# Plan a change
cp .agents/templates/core/change-plan.md PLAN-REFACTOR-AUTH.md
```

### For Code Review

Use reviewer templates to standardize feedback:

```bash
# Review a pull request
cat .agents/templates/reviewer/pr-review-template.md

# Review test coverage
cat .agents/templates/reviewer/test-review-template.md
```

## Projects Using This

- [Deploy Ducky](https://github.com/anthropics/deploy-ducky) – Deployment platform kit with embedded guidelines

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT License. See [LICENSE](./LICENSE) for details.

---

**Framework Version:** 1.0.0
**Last Updated:** 2026-01-27
