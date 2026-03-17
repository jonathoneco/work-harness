# 10: Doc Migration for Previous Workflows

## Overview

One-time migration to align existing `docs/feature/<name>/` directories with the new layout (Component 8): specs move to `.work/<name>/specs/`, `docs/feature/<name>.md` becomes a single summary file.

## Scope

171 files across 11 directories. Three categories:

### Active `.work/` tasks

| Directory | Files | Action |
|-----------|-------|--------|
| harness-enforcement | 11 | Move specs from `docs/feature/harness-enforcement/` to `.work/harness-enforcement/specs/`. Create `docs/feature/harness-enforcement.md` summary. |
| phase-2 | 1 | Convert `docs/feature/phase-2/` dir to `docs/feature/phase-2.md`. Move `architecture.md` to `.work/phase-2/specs/`. |
| dev-env-silo | 1 | Convert `docs/feature/dev-env-silo/` dir to `docs/feature/dev-env-silo.md`. Move `architecture.md` to `.work/dev-env-silo/specs/`. |

### Archived workflows (`.workflows/archive/`)

| Directory | Files | Action |
|-----------|-------|--------|
| work-harness-v2 | 23 | Move specs to `.workflows/archive/work-harness-v2/specs/`. Create summary at `docs/feature/work-harness-v2.md`. |
| shim-removal | 27 | Move to `.workflows/archive/shim-removal/specs/`. Create summary. |
| phase-0-code-review | 20 | Move to `.workflows/archive/phase-0-code-review/specs/`. Create summary. |
| phase-1-code-review | 22 | Move to `.workflows/archive/phase-1-code-review/specs/`. Create summary. |

### Active legacy workflows (`.workflows/`)

| Directory | Files | Action |
|-----------|-------|--------|
| phase-1-implementation | 30 | Move to `.workflows/phase-1-implementation/specs/`. Create summary. |
| tailwind-upgrade | 13 | Move to `.workflows/tailwind-upgrade/specs/`. Create summary. |

### Orphaned

| Directory | Files | Action |
|-----------|-------|--------|
| agentic-push | 23 | No `.work/` or `.workflows/` dir. Archive to `.workflows/archive/agentic-push/specs/` or delete after user review. |

## External Reference Updates

10+ hardcoded references to `docs/feature/<name>/` pattern:

| File | Reference | Change To |
|------|-----------|-----------|
| `.claude/commands/work.md` | "Create `docs/feature/<name>/`" | "Create `docs/feature/<name>.md`" |
| `.claude/commands/work-deep.md` | "Write `docs/feature/<name>/00-cross-cutting-contracts.md`" | "Write `.work/<name>/specs/00-cross-cutting-contracts.md`" |
| `.claude/commands/work-deep.md` | "Write `docs/feature/<name>/NN-<slug>.md`" | "Write `.work/<name>/specs/NN-<slug>.md`" |
| `.claude/commands/work-feature.md` | "Create `docs/feature/<name>/` directory" | "Create `docs/feature/<name>.md` summary" |
| `.claude/commands/work-reground.md` | "plan document (if exists in `docs/feature/<name>/`)" | "plan document in `.work/<name>/`" |
| `.claude/skills/work-harness/references/state-conventions.md` | docs_path field definition | Update to `.md` file, not directory |
| `.claude/skills/work-harness/references/depth-escalation.md` | "Create `docs/feature/<name>/`" | "Create `docs/feature/<name>.md`" |
| `.claude/agents/work-spec.md` | "`docs/feature/*/`" | "`.work/<name>/specs/`" |
| `.claude/rules/workflow.md` | "standalone documentation in `docs/feature/`" | "summary files in `docs/feature/`" |

## Summary File Template

Each `docs/feature/<name>.md` summary follows this format:

```markdown
# <Title>

**Status:** completed | active | archived
**Tier:** 1 | 2 | 3
**Dates:** <created> — <completed/ongoing>
**Beads:** <epic-id>

## What

<2-3 sentence description of what was built>

## Why

<Motivation — what problem this solved>

## Key Decisions

- <Decision 1>: <rationale>
- <Decision 2>: <rationale>

## Components

- <Component 1>: <one-line description>
- <Component 2>: <one-line description>

## Specs

Detailed specs at `.work/<name>/specs/` (or `.workflows/archive/<name>/specs/` for archived work).
```

## Ordering

Depends on W-12 (docs cleanup) being implemented first — W-12 changes the commands to use the new layout; W-14 migrates existing data to match.

## Testing

1. After migration, verify no broken references: `grep -r 'docs/feature/.*/' .claude/ --include='*.md'` should return 0 results (no directory references remaining)
2. Verify all summary files exist: `ls docs/feature/*.md`
3. Verify specs moved: `ls .work/*/specs/*.md` and `ls .workflows/archive/*/specs/*.md`
