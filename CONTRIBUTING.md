# Contributing to conventional-agents

Thank you for contributing! This framework is built on evidence-based practices, and we welcome contributions that strengthen that foundation.

## Philosophy

Every guideline and template in this project must be:

1. **Evidence-based** – Rooted in real-world experience, testing, or documented rationale (not opinion)
2. **Framework-agnostic** – Applicable across Python, Bash, Node.js, and other languages/runtimes
3. **Prescriptive** – Clear, actionable, and defensible (not vague or aspirational)
4. **Auditable** – Easy for developers and LLMs to understand and follow

We prioritize clarity and simplicity over comprehensiveness.

## What to Contribute

### ✅ Good Contributions

- **Bug fixes** in guidelines or templates (typos, incorrect examples, broken links)
- **Clarifications** that improve understanding without changing substance
- **New language guides** (e.g., Go, Rust) following the existing structure
- **Evidence-based refinements** (e.g., "We found X pattern reduces bugs by Y%")
- **Template improvements** with clear rationale
- **Documentation** that fills gaps or improves accessibility

### ❌ What Not to Contribute

- **Opinions without evidence** ("I prefer X style" without data or rationale)
- **Framework-specific rules** (e.g., "use Jest because it's popular")
- **Subjective preferences** (code formatting trends, language features you like)
- **Aspirational content** ("best practices" that aren't grounded in practice)
- **Large additions** without community discussion (open an issue first)

## Process

### 1. Open an Issue

Before submitting a PR, open an issue describing:

- **What** – The specific guideline, template, or gap
- **Why** – The evidence or rationale (e.g., "Current guidance causes X problem", "We've tested Y approach and found...")
- **Context** – Link to deploy-ducky or other projects using this framework

Example:

```text
Title: Clarify Bash quoting rules for variables with spaces

Description:
The current BASH_STYLE_GUIDE.md section on quoting is ambiguous.
We found that omitting quotes causes failures in 15% of scripts handling filenames.
Proposed: Add explicit rule: "Always quote variables unless you specifically need word-splitting."
Evidence: Tested on 100+ scripts in deploy-ducky; all failures resolved with quotes.
```text

### 2. Get Feedback

Maintainers will discuss:

- Is the evidence compelling?
- Does it apply broadly (or just to your use case)?
- Is the language clear and actionable?
- Does it fit the existing structure?

### 3. Submit a PR

Once aligned on approach:

1. Fork the repository
2. Create a branch: `git checkout -b fix/issue-name`
3. Make focused changes (one issue per PR)
4. Include rationale in commit messages:

   ```text

   Update BASH_STYLE_GUIDE: Always quote variables

   Evidence: Analysis of 100+ deploy-ducky scripts shows 15% failure rate
   without quotes when handling filenames with spaces. This change reduces
   failures to 0% while maintaining backwards compatibility.

   Fixes #123

   ```text

5. Push and open a PR

### 4. Review and Merge

PRs will be reviewed for:

- **Correctness** – Does the change work?
- **Clarity** – Is it clear enough for humans and LLMs?
- **Evidence** – Is there real rationale?
- **Scope** – Is it focused and not overreaching?

## Structure

### Guidelines

Located in `guidelines/[language]/`:

```text
guidelines/
├── ROLE_CONTRACT.md          # LLM agent responsibilities
├── bash/
│   ├── BASH_STYLE_GUIDE.md
│   ├── BASH_TESTING_GUIDE.md
│   └── BASH_IMPLEMENTATION_GUIDE.md
├── javascript/
│   ├── JS_STYLE_GUIDE.md
│   ├── JS_TESTING_GUIDE.md
│   └── JS_IMPLEMENTATION_GUIDE.md
└── python/
    ├── PYTHON_STYLE_GUIDE.md
    ├── PYTHON_TESTING_GUIDE.md
    └── PYTHON_IMPLEMENTATION_GUIDE.md
```text

When adding a new language:

1. Create `guidelines/[language]/` directory
2. Add three guides: Style, Testing, Implementation
3. Follow the structure and tone of existing guides
4. Include rationale sections

### Templates

Located in `templates/[type]/`:

```text
templates/
├── core/                      # Core development documents
├── reviewer/                  # Review templates
└── python/tests/              # Language-specific test templates
```text

When adding a new template:

1. Keep it focused on one task (e.g., "PR review", not "code review + design review")
2. Include placeholder sections (marked with `<!-- TODO -->` or similar)
3. Add a brief preamble explaining purpose and usage
4. Use realistic examples

## Code of Conduct

This project follows the [Anthropic Code of Conduct](https://www.anthropic.com/policies/code-of-conduct). Be respectful, assume good intent, and focus on evidence and clarity.

## Questions?

Open an issue or discussion in the repository. Maintainers are here to help clarify expectations and align on approach.

---

**Thank you for helping make LLM-driven development more reliable and repeatable!**
