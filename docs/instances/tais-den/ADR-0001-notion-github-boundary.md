---
type: adr
id: ADR-0001
status: proposed
decision_scope: instance
reversible: yes
related_specs: []
superseded_by: null
instance: tais-den
---

# ADR-0001: Notion vs GitHub boundary for documentation and project management

## Status

- Proposed

## Context and Problem Statement

Tai Solstag uses both Notion and GitHub for documentation, project management,
and task tracking. Both tools are available and capable, but without an explicit
boundary, the same information ends up in both places with different levels of
completeness, creating confusion about which is authoritative.

The current landscape:

- **Notion** hosts the Portfolio Home, Project Home database (with Status,
  Domain, Goals, Current State per project), a cross-project Task Board (with
  Status, Energy, Mode, Size, Orbit fields), and a Knowledge Base organized by
  Orbits (Personal Projects, The Den, City/State, National/Global).
- **GitHub** hosts code repositories, Issues, Pull Requests, CI/CD, and
  in-repo documentation (ADRs, Feature Specs, Change Plans, arc42, SKILL.md
  files, AGENTS.md).
- **GitHub Projects** provides per-org project boards (Rollup, Pack Protocol,
  etc.) that overlap with the Notion Task Board.

The initial intuition is: **GitHub for code projects, Notion for everything
else.** But there is unavoidable crossover:

1. **Project status** — A code project's real status is determined by repo
   activity (open PRs, recent commits, CI state), but it's displayed in
   Notion's Project Home database. These drift apart.
2. **Tasks** — Code tasks need to be linked to PRs and CI, but the unified
   Task Board in Notion is the place where Tai decides what to work on next.
3. **Knowledge** — Project-specific knowledge lives partly in Notion (meeting
   notes, cross-project context) and partly in the repo (ADRs, specs). The
   boundary between "belongs in the repo" and "belongs in Notion" is unclear.

This ADR defines the boundary and the workflow for each crossover area.

## Decision Drivers

- **Repo canonicality** — The repo is always the source of truth for anything
  that is versioned, reviewed via PR, or consumed by agents at runtime.
  Notion is the source of truth for things that are not code-related.
- **Single source of truth per artifact** — Every piece of information has
  exactly one authoritative location. The other side may link to it or
  summarize it, but never duplicate it as canonical.
- **Low friction** — The boundary should not create busywork. If updating the
  boundary is more work than the drift it prevents, the boundary is wrong.
- **Agent compatibility** — Agents working in repos read from the filesystem
  and GitHub. They should not need Notion access for code work. Agents that
  have Notion access may update Notion as a side effect, but Notion is never
  the runtime source of truth for agent behavior.
- **Tai's workflow** — Tai plans and prioritizes in Notion (filtered by Energy,
  Mode, Orbit). The boundary must respect this as the primary planning surface.

## Considered Options

### Option A: Notion is the unified source of truth for everything

All project status, tasks, and documentation live in Notion. GitHub is used
only for code storage and PRs. In-repo documentation (ADRs, specs) is
summarized in Notion and the repo links to Notion for the canonical version.

### Option B: GitHub is the unified source of truth for everything

All project status, tasks, and documentation live in GitHub (Issues, Projects,
READMEs, wiki). Notion is used only for life logistics (Who's Who, Household,
Emergency) and personal knowledge that has no code relationship.

### Option C: Repo-canonical with Notion as planning surface (chosen)

The repo is canonical for anything versioned, reviewed, or agent-consumed.
Notion is the planning and orientation surface. The boundary is defined by
artifact type, not by project type.

## Decision Outcome

**Chosen option: Option C — Repo-canonical with Notion as planning surface.**

### The boundary

```
┌─────────────────────────────────────────────────┐
│                   NOTION                         │
│  Portfolio Home · Project Registry · Task Board  │
│  Knowledge Base · Orbits · Life Logistics        │
│  Meeting notes · Research · Cross-cutting docs   │
│  Project status snapshots (Current State field)  │
│  Links TO GitHub repos, issues, and files        │
└────────────────────┬────────────────────────────┘
                     │  bidirectional links
                     ▼
┌─────────────────────────────────────────────────┐
│                   GITHUB                         │
│  Code · PRs · Issues · CI/CD                     │
│  ADRs · Feature Specs · Change Plans             │
│  arc42 · SKILL.md · AGENTS.md                    │
│  Changelogs · Release artifacts                  │
│  Links TO Notion project pages                   │
└─────────────────────────────────────────────────┘
```

### Per-artifact source of truth

| Artifact | Source of Truth | Notion's Role |
|---|---|---|
| Code | GitHub | Link to repo |
| ADRs | GitHub (`docs/decisions/ADR-XXXX.md`) | One-line summary of outcome, link to file |
| Feature Specs | GitHub (`docs/specifications/FS-XXXX.md`) | Not tracked in Notion |
| Change Plans | GitHub (`docs/change-plans/PLAN-XXXX.md`) | Not tracked in Notion |
| arc42 architecture | GitHub (`docs/ARC42.md`) | Link to file |
| SKILL.md / AGENTS.md | GitHub (filesystem) | Not tracked in Notion |
| Changelog / Releases | GitHub (CHANGELOG.md, Releases) | Link to latest release |
| Project status (code) | **Derived from repo activity** | Dashboard display, updated by periodic sweep |
| Project status (non-code) | Notion (Project Home DB) | Full source of truth |
| Tasks (code) | GitHub Issues (working copy) | Planning entry with link to issue |
| Tasks (non-code) | Notion Task Board | Full source of truth |
| Knowledge Base (life) | Notion | Full source of truth |
| Knowledge Base (project context) | Notion (summaries + links) | Reference desk; canonical docs are in repo |
| Who's Who / Contacts | Notion | Full source of truth |
| Key Dates / Deadlines | Notion | Full source of truth |

### Workflow: Project status

For code projects, the `Status` field in Notion's Project Home database is a
**dashboard display**, not the source of truth. The real status is derived from
repo state:

| Repo State | Derived Status |
|---|---|
| No repo exists yet | 🌱 Not Started |
| Repo exists, no recent activity (>30d since last commit) | 🟡 Next Up |
| Open PRs, recent commits, active issues | 🔵 Active |
| Explicit pause signal (e.g., `PAUSED.md` in repo root) | ⏸️ Paused |
| Open blocker issue or blocked PR | 🔴 Blocked |
| All FS/PLAN docs at `implemented`, no open issues | ✅ Complete |
| Repo archived on GitHub | 🗃️ Archived |

The `Current State` text field in Notion is a **freeform note** that an agent
or human writes after a work session, summarizing what happened and the current
repo state. It is not authoritative — it's a convenience summary.

A periodic sweep (cron or manual) may update Notion's `Status` field to match
repo state, but the repo is always the canonical source.

### Workflow: Tasks

**Notion is where Tai decides what to do. GitHub is where the work happens.**

1. **Planning** — Tai browses the Notion Task Board, filtered by Energy, Mode,
   Orbit, or Status. Tasks are created and prioritized here.
2. **Dispatch** — When a code task is ready to execute, a GitHub Issue is
   created in the relevant repo. The Notion task gets a `GitHub Issue URL`
   link. The Notion status moves to `🔵 In Progress`.
3. **Execution** — The agent (or human) works from the GitHub Issue. PRs are
   linked, CI runs, review happens — all in GitHub.
4. **Reconciliation** — When the GitHub Issue closes, the Notion task is marked
   `✅ Done`. This may be done manually, by the agent as its last step, or by
   a periodic sweep.

The `Mode` field on the Task Board determines the workflow:

| Mode | Planning | Execution | Reconciliation |
|---|---|---|---|
| 🧠 Human Only | Notion | Notion (no GitHub issue) | Notion |
| 🤖 Agentic | Notion | GitHub Issue → PR → merge | Agent updates Notion on completion |
| 🤝 Hybrid | Notion | GitHub Issue → PR → human review | Agent or human updates Notion |

Non-code tasks (research, life logistics, planning) live entirely in Notion
with no GitHub counterpart.

### Workflow: Knowledge Base

For each code project, the Notion page should contain:

1. **A one-paragraph summary** of what the project is and its current state.
2. **Links to canonical documents** in the repo, using a consistent section:

   ```
   ## Repo Canonical Docs
   - [ADR-0011: Multi-Identity Model](<repo-url>/blob/trunk/docs/decisions/ADR-0011.md)
   - [arc42 Architecture](<repo-url>/blob/trunk/docs/ARC42.md)
   - [AGENTS.md](<repo-url>/blob/trunk/AGENTS.md)
   ```

3. **Context that does not belong in the repo** — meeting notes, rationale too
   ephemeral for an ADR, personal reflections, cross-project connections.
4. **A link to the GitHub repo** (already present in `Key Artifacts`).

The Notion page should **never** contain a canonical document that belongs in
the repo. If a detailed spec is being written in Notion, it should be moved to
the repo instead. Notion gets the summary + link.

### What about GitHub Projects?

GitHub Projects (the per-org boards like Tais-Den Rollup, Pack Protocol, etc.)
are **optional supplements** for code-specific views. They are not the canonical
task board. The Notion Task Board is the unified planning surface. GitHub
Projects may be used for sprint-level or repo-level views that are convenient
during execution, but they are never the source of truth for task status.

## Consequences

### Positive

- Every artifact has exactly one authoritative location. No more "is the
  latest version in Notion or the repo?"
- Tai can plan and prioritize in Notion (the tool optimized for that) without
  worrying about repo state drift.
- Agents working in repos read from the filesystem and GitHub — they don't
  need Notion access for code work.
- The `Mode` field on the Task Board cleanly encodes the workflow for each
  task type.
- Project status is derived from real activity, not manual updates.

### Negative

- The Notion Task Board and GitHub Issues will be out of sync between dispatch
  and reconciliation. This is acceptable — the Notion task is the planning
  entry, the GitHub Issue is the working copy. They are not mirrors.
- Project status in Notion may lag behind repo activity if the periodic sweep
  is not running. This is acceptable — the repo is canonical, Notion is a
  dashboard.
- Creating a GitHub Issue for every code task adds a step. This is acceptable
  because the issue is where the actual work happens (PR linking, CI, review).

### Neutral

- The boundary requires judgment for edge cases (e.g., a task that starts as
  research in Notion and later becomes a code task). The rule is: when it
  becomes a code task, create the GitHub Issue and link it.
- Instance ADRs like this one live in `docs/instances/tais-den/` in the
  conventional-agents repo, not in the framework's `docs/decisions/`. This
  keeps the framework clean while versioning instance-specific decisions.

## Validation

We will consider this decision successful if:

1. After 3 months, there are no cases of "I can't find the latest version of
   this document" due to Notion/GitHub ambiguity.
2. Tai reports that the Notion Task Board is the primary planning surface and
   GitHub Issues are the primary execution surface, with clear linkage between
   them.
3. No canonical project documentation (ADRs, specs, arc42) exists in Notion
   that should be in the repo.
4. Agents working in repos do not need Notion access to understand the
   project's conventions and current state.

## Links

- conventional-agents ADR-0016: Instance conventions
- conventional-agents `docs/instances/README.md`
- Notion: [🧭 Portfolio Home](https://app.notion.com/p/3630562868cb8100ab11f65c433fd78f)
- Notion: [📋 Task Board](https://app.notion.com/p/21d5f6928e484c42b0ebce79215a6227)
- Notion: [📁 Project Home](https://app.notion.com/p/cc241faf4d654d55a0ddebaef0508dab)
- Notion: [🏠 Knowledge Base Home](https://app.notion.com/p/38d0562868cb81f5b682ec7d4b679ff9)
