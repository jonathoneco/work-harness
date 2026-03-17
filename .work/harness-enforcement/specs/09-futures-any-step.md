# 09: Futures at Any Step

## Overview

Make futures saveable at every workflow step and every tier, not just during research and redirects. Move storage from `.work/<name>/research/futures.md` to `.work/<name>/futures.md`.

## Current Behavior

Futures can only be captured in two places:
1. **Research step** (Tier 3 only): explicitly documented in `/work-deep`
2. **Dead-end redirects** (any tier): via `/work-redirect`

This means futures discovered during plan, spec, decompose, implement, or review steps have no capture path. Agents save them to Claude memories instead, losing the structured format and promotion path.

## Target Behavior

- **Any step, any tier** can append futures to `.work/<name>/futures.md`
- Storage is task-level, not research-specific
- Same format as today (title, horizon, domain, identified date, description, context, prerequisites)
- Same promotion path at archive (`.work/<name>/futures.md` → `docs/futures/<name>.md`)

## Storage Change

**Before:** `.work/<name>/research/futures.md`
**After:** `.work/<name>/futures.md`

The file is created on first write — no need to pre-create it at state initialization.

## Format (Unchanged)

```markdown
## <title>

**Horizon**: <next|quarter|someday>
**Domain**: <inferred from context>
**Identified**: <YYYY-MM-DD>

<2-4 sentence description: what the enhancement does, why it matters>

**Context**: <relative path to research notes or step artifact>
**Prerequisites**: <what must be done first, or "None">
```

## Changes to `/work-deep`

### Research Step

Replace:
```
5. **Futures**: If research reveals deferred enhancements, capture them in
   `.work/<name>/research/futures.md`
```

With:
```
5. **Futures**: If research reveals deferred enhancements, append to
   `.work/<name>/futures.md`
```

### All Other Steps (plan, spec, decompose, implement, review)

Add to each step section:

```
**Futures**: If you discover deferred enhancements or out-of-scope improvements
during this step, append them to `.work/<name>/futures.md` using the standard
futures format. Do not save futures to Claude memories — use the futures file.
```

This is a single line added to each step — not a major structural change.

### Auto-Advance Addition

In the auto-advance block (spec 04), after writing the handoff prompt and before creating the gate issue, add:

```
   a2. If futures were discovered during this step, verify they were appended
       to `.work/<name>/futures.md` (not saved to Claude memories)
```

This is advisory, not blocking — a reminder to the agent, not a hook check.

## Changes to `/work-feature`

Add to plan and implement steps:

```
**Futures**: If you discover deferred enhancements, append to `.work/<name>/futures.md`.
```

## Changes to `/work-fix`

Add to implement step:

```
**Futures**: If you discover deferred enhancements, append to `.work/<name>/futures.md`.
```

## Changes to `/work-archive`

### Step 7: Promote Futures

Replace:
```
If `.work/<name>/research/futures.md` exists and has entries:
```

With:
```
If `.work/<name>/futures.md` exists and has entries:
```

### Git Commit

Replace:
```
git add docs/futures/<name>.md  # if futures were promoted
```

With (same — no change needed, path is the same on the docs/ side):
```
git add docs/futures/<name>.md  # if futures were promoted
```

## Changes to `/work-redirect`

Replace:
```
If yes, append to `.work/<name>/research/futures.md`
```

With:
```
If yes, append to `.work/<name>/futures.md`
```

## Files to Modify

- `.claude/commands/work-deep.md` — all step sections + research section path change
- `.claude/commands/work-feature.md` — plan and implement sections
- `.claude/commands/work-fix.md` — implement section
- `.claude/commands/work-archive.md` — promotion path
- `.claude/commands/work-redirect.md` — futures append path

## Testing

- Create a Tier 2 task, discover a future during implement, verify it lands in `.work/<name>/futures.md`
- Create a Tier 3 task, discover futures at research and spec steps, verify both append to the same file
- Archive a task with futures, verify promotion to `docs/futures/<name>.md`
- Verify old path `.work/<name>/research/futures.md` is no longer referenced anywhere
