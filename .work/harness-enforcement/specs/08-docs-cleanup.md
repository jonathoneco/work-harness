# 08: Docs Cleanup — Single Summary File

## Overview

Move detailed spec files from `docs/feature/<name>/` (a directory) to `.work/<name>/specs/` (working artifacts). Replace the directory with a single summary file at `docs/feature/<name>.md`.

## Current Behavior

The spec step writes numbered spec files to `docs/feature/<name>/`:

```
docs/feature/harness-enforcement/
├── 00-cross-cutting-contracts.md     (4.3 KB)
├── 01-state-guard.md                 (4.2 KB)
├── 02-artifact-gate.md               (4.2 KB)
├── 03-review-verify.md               (4.2 KB)
├── 04-command-auto-advance.md        (11.3 KB)
├── 05-work-check-fix.md              (2.3 KB)
├── 06-step-output-review.md          (5.5 KB)
└── architecture.md                   (7.4 KB)
```

This creates noise in `docs/feature/` — detailed specs are working artifacts consumed during implementation, not published documentation.

## Target Behavior

```
docs/feature/harness-enforcement.md          # Single summary file (~1 page)

.work/harness-enforcement/specs/
├── 00-cross-cutting-contracts.md            # Detailed specs (working artifacts)
├── 01-state-guard.md
├── ...
├── architecture.md
└── index.md                                 # Already exists
```

### Summary File Format

`docs/feature/<name>.md`:

```markdown
# <Title>

**Status:** <in-progress|completed|archived>
**Tier:** <1|2|3>
**Beads:** <epic_id or issue_id>
**Started:** <date>

## What

<1-2 paragraphs: what this feature/initiative does and why>

## Key Decisions

<Bulleted list of important design decisions — distilled from specs>

## Components

| Component | Status | Description |
|-----------|--------|-------------|
| <name> | <done|in-progress|planned> | <one-line> |

## Files

<Key files created or modified by this work>
```

### Lifecycle

- **Created at plan step**: initial version with What + Components (from architecture)
- **Updated at spec step**: Key Decisions added (from spec handoff)
- **Updated at archive**: Status set to "archived", final file list

## Changes to `/work-deep`

### State Initialization (Step 3)

Replace:
```
6. Create directories:
   - `docs/feature/<name>/`
```

With:
```
6. Create directories:
   - `.work/<name>/specs/` (if not exists)
   No docs/feature/<name>/ directory created — summary file written at plan step.
```

### Plan Step

Add after writing architecture document:
```
Write architecture document to `.work/<name>/specs/architecture.md` (not `docs/feature/<name>/`).

Create initial summary file at `docs/feature/<name>.md` with:
- Status: in-progress
- Tier, beads ID, start date
- What section (from architecture problem statement + goals)
- Components table (from architecture component map, all "planned")
```

### Spec Step

Replace:
```
3. Numbered specs: For each component, write `docs/feature/<name>/NN-<slug>.md`
```

With:
```
3. Numbered specs: For each component, write `.work/<name>/specs/NN-<slug>.md`
```

Add after spec completion:
```
Update `docs/feature/<name>.md`: add Key Decisions section from spec handoff.
```

### Implement Step

Spec references change from `docs/feature/<name>/0N-*.md` to `.work/<name>/specs/0N-*.md`.

### Archive Step

```
Update `docs/feature/<name>.md`: set status to "archived", add final file list.
```

## Changes to `/work-feature` and `/work-fix`

### `/work-feature`

Replace:
```
6. Create `docs/feature/<name>/` directory
```

With:
```
6. Summary file created at plan step (see plan section).
```

Plan step writes approach doc to `.work/<name>/plan/approach.md` and creates `docs/feature/<name>.md` summary.

### `/work-fix`

No docs changes — Tier 1 tasks don't produce feature docs.

## Changes to Spec 00 (Cross-Cutting Contracts)

Update Path Conventions:

```
- Feature summary: `docs/feature/<name>.md` (single file, not directory)
- Spec files: `.work/<name>/specs/NN-<slug>.md`
- Architecture: `.work/<name>/specs/architecture.md`
```

## Changes to Spec 02 (Artifact Gate)

Update spec file existence check:

```
- Spec step completed → at least one `.work/<name>/specs/` spec file exists
```

(Was: `docs/feature/<name>/` spec file exists)

## Files to Modify

- `.claude/commands/work-deep.md` — state init, plan step, spec step, implement step references
- `.claude/commands/work-feature.md` — state init, plan step
- `.claude/commands/work-archive.md` — summary file update
- `docs/feature/harness-enforcement/00-cross-cutting-contracts.md` → moves to `.work/harness-enforcement/specs/`

## Migration Note

Existing `docs/feature/harness-enforcement/` directory with spec files can be moved to `.work/harness-enforcement/specs/` as part of this work item. A summary file `docs/feature/harness-enforcement.md` replaces it.

## Testing

- Create a new Tier 2 task, verify specs land in `.work/<name>/specs/`
- Verify `docs/feature/<name>.md` summary is created at plan step
- Verify artifact-gate checks `.work/<name>/specs/` not `docs/feature/<name>/`
- Verify archive updates the summary file status
