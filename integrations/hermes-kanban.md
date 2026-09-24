# Proposed Binding: Hermes Kanban

This is a **draft**, not a conforming substrate binding. `ADR-0024` requires all
six capabilities to be realized before a binding is merged. The mapping below
records both the actual Hermes CLI mechanism and the remaining gaps. It does
not change the GitHub binding or make GitHub a framework dependency.

| Capability | Hermes mechanism | Current claim |
| --- | --- | --- |
| 1. Work item | Board-scoped task with title/body | Native |
| 2. Type | `[feature]`, `[bug]`, or `[task]` title prefix | **Not yet conforming:** no verified attributable Type mutation history |
| 3. Phase | `triage`/`todo` → Backlog, `ready` → Approved, `running` → In Progress, `review` → In Review, `done` → Done | Native status; approval authority is a separate governance rule |
| 4. Parked state | `blocked` with `needs_input` reason | Readable; suppression remains an agent convention |
| 5. Activity record | Task events and comments | **Not yet verified:** transition retention and actor attribution |
| 6. Enumerability | `list --json --archived`, `show --json` | Native on-demand read; live event feed is optional |

## CLI examples

Use an isolated Hermes home for tests. In normal use, the board belongs to the
active `$HERMES_HOME` and may be shared with other profiles; do not create a
second board with the same slug to test this binding.

```bash
hermes kanban boards create conventional-agents
hermes kanban --board conventional-agents create '[task] Review a change' --body 'Brief'
hermes kanban --board conventional-agents list --json --archived
hermes kanban --board conventional-agents show <task-id> --json
hermes kanban --board conventional-agents promote <task-id> 'human approved'
hermes kanban --board conventional-agents claim <task-id>
hermes kanban --board conventional-agents block --kind needs_input <task-id> 'awaiting human decision'
```

The global `--board` option precedes the subcommand. `create` accepts a
positional title, not `--title`; JSON output is `--json`, not `--format json`.
Atomic claim protects against concurrent workers, not against an unauthorized
promotion. `scheduled` is a timer wait and must not stand in for the
human-input parked state. A task in `review` is distinct from `running`.

## Boundaries that still need proof

- **Type:** Hermes has no native Type field. The title prefix gives a closed
  vocabulary only by convention. Before declaring this binding conforming,
  demonstrate an attributable record of *every* Type change (including `specify`
  on triage tasks), and reject absent or ambiguous prefixes at the autonomous
  gate. A Git pre-commit hook cannot intercept writes to Hermes's SQLite board.
- **Activity:** Verify that transitions have ordered, actor-attributable,
  non-retractable records through supported tools. A CLI caller's
  `--created-by` argument is not proof of its real profile, and filesystem
  access to SQLite is not an access-control boundary. Establish the threat
  model for direct database edits and `gc` retention.
- **Parked state:** Workers must not unblock a `needs_input` task without a
  human decision. A dependency block and a timed schedule are not the
  `question` parked state. Demonstrate that dispatcher promotion cannot
  silently clear a human-input block.
- **Human interaction:** The CLI is a local work queue; it does not itself
  provide a shared, durable review/approval interface. A binding must describe
  how a human records Type and approvals without confusing worker assignment
  with authorization.

No GitHub↔Hermes synchronization is proposed here. A future Hermes *runtime*
configuration binding under `ADR-0039` is distinct from this work-item
substrate binding under `ADR-0024`. See `FS-0038` and `PLAN-0044` for the
proposed proof and test obligations.
