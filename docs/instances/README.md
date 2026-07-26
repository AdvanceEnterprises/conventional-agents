# Instance Conventions

This directory holds **instance-specific** architecture decisions — local
adaptations of the conventional-agents framework that apply to a particular
consumer's setup, not to the framework itself.

## Structure

```
docs/instances/
├── README.md                    # This file
└── <instance-name>/
    ├── INSTANCE.md              # Instance metadata (optional)
    ├── ADR-0001.md              # Instance-specific decisions
    └── ...
```

## Rules

- Instance ADRs use the same MADR template as framework ADRs, with
  `decision_scope: instance`.
- Instance ADRs are NOT listed in `docs/decisions/README.md`.
- Instance ADRs do NOT require FS/PLAN lifecycle — they may be created or
  updated directly via PR.
- Instance ADRs may reference framework ADRs as constraints.

See ADR-0016 for the full rationale and rules.

## Instance Index

| Instance | Description | ADRs |
|---|---|---|
| `tais-den` | Tai Solstag's personal development setup | ADR-0001 |
