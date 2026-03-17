# 07: Parallel Agent Streams

## Overview

Rewrite decompose and implement steps so streams are designed as parallel agent workloads, not worktree branches. The lead agent spawns one subagent per independent stream in the same repository.

## Current Behavior

Decompose creates streams as logical groupings. Implement optionally suggests git worktrees for parallel execution:

```bash
# Parallel execution (optional): For independent streams, use parallel worktrees:
git worktree add .worktrees/<name>-stream-N -b workflow/<name>-stream-N $(git branch --show-current)
```

This has problems:
- Worktree overhead isn't worth it for most tasks
- Branch management adds complexity
- Merge conflicts between stream branches
- Not integrated with Claude Code's native Agent tool

## Target Behavior

### Decompose Changes

Each stream's execution doc becomes a self-contained agent prompt:

```markdown
## Stream A: <name>

**Work items:** W-01, W-02, W-03
**Specs:** 01, 02, 03
**Files touched:** <list>
**Dependencies:** None (Phase 1)

### Instructions

You are implementing Stream A of the <task> initiative.

1. Run `bd ready` to find your unblocked work items
2. For each item:
   - `bd update <id> --status=in_progress`
   - Read the spec at `docs/feature/<name>/NN-*.md` (or `.work/<name>/specs/NN-*.md`)
   - Implement per spec
   - Run `make test`
   - `bd close <id> --reason="<summary>"`
3. When all items complete, report back to the lead agent

### Acceptance Criteria
[Copied from relevant specs]
```

### Implement Changes

Replace worktree instructions with agent-per-stream execution:

```
1. Read decompose handoff: `.work/<name>/streams/handoff-prompt.md`
2. Identify Phase 1 streams (no dependencies)
3. Spawn one subagent per Phase 1 stream:
   - Each agent gets: stream execution doc + `skills: [work-harness, code-quality]`
   - Each agent works in the same repo (no worktrees, no branches)
   - Each agent claims and closes its own beads issues
4. Monitor completion:
   - When all Phase 1 agents finish, identify Phase 2 streams
   - Spawn Phase 2 agents (their dependencies are now satisfied)
   - Repeat until all phases complete
5. When all work items closed: advance to review
```

## Conflict Avoidance

Streams are designed with non-overlapping file sets. The decompose step must verify:
- No file appears in more than one stream within the same phase
- If overlap is unavoidable, serialize those streams (put them in different phases)

This is a decompose-time constraint, not a runtime check.

## Changes to `/work-deep`

### Decompose Section

Replace step 4 ("Stream execution documents"):

```
4. **Stream agent prompts**: For each stream, write a self-contained execution doc
   in `.work/<name>/streams/<stream-letter>.md`:
   - Work items with beads IDs and spec references
   - Files to create/modify (must not overlap with other same-phase streams)
   - Acceptance criteria from specs
   - Agent instructions (claim, implement, test, close pattern)
```

### Implement Section

Replace steps 2-3:

```
2. **Phase execution**: For each phase in order:
   a. Identify streams ready to execute (all dependencies satisfied)
   b. Spawn one subagent per stream with `skills: [work-harness, code-quality]`
   c. Each agent receives its stream doc from `.work/<name>/streams/<stream-letter>.md`
   d. Wait for all phase agents to complete
   e. Run `make test && make build` to verify phase integration
   f. Proceed to next phase

3. Remove all worktree references.
```

## Files to Modify

- `.claude/commands/work-deep.md` — decompose section (stream docs format), implement section (agent execution)

## Testing

- Create a mock Tier 3 task with 2 independent streams
- Verify decompose produces agent-ready stream docs
- Verify implement spawns parallel agents that each claim/close their own issues
- Verify Phase 2 agents only launch after Phase 1 completes
