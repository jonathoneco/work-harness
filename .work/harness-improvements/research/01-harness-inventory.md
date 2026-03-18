# Harness Inventory

## Current State (v0.1.0)

| Category | Count | Lines | Key Files |
|----------|-------|-------|-----------|
| Commands | 16 | 2,512 | work-deep.md (417), harness-init.md (266), pr-prep.md (206) |
| Skills | 5 core + 8 refs | 948 | work-harness.md (122), code-quality.md (65) |
| Agents | 4 | 270 | work-review.md (94), work-research.md (63) |
| Rules | 2 | 55 | workflow.md, workflow-detect.md |
| Hooks | 8 | 754 | state-guard.sh (123), artifact-gate.sh (140) |
| Lib | 4 | 387 | config.sh (171), merge.sh (108) |
| Templates | 2 | 110 | harness.yaml.template, beads-workflow.md.template |
| **Total** | **~60 files** | **~4,926** | |

## Agent Definitions
- **Builder** (work-implement.md, 51 lines) — acceptEdits mode
- **Auditor** (work-review.md, 94 lines) — plan mode (read-only)
- **Scout** (work-research.md, 63 lines) — plan mode (read-only)
- **Architect** (work-spec.md, 62 lines)

## Key Pattern
All agents reference skills informally in markdown body rather than via YAML frontmatter `skills:` field. This should be migrated to the official mechanism.
