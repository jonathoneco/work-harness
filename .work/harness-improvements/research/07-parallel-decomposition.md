# Parallel Decomposition Research

## Three Tiers of Parallelism in Claude Code

| Tier | Mechanism | Coordination | Context | Best For |
|------|-----------|-------------|---------|----------|
| Subagents | Background agents in one session | Results return to lead | Shared (exhaustible) | 2-3 small streams |
| Agent Teams | Multiple Claude instances | Shared task list + mailbox | Independent | 3+ large streams |
| Worktrees | Independent sessions on branches | Manual | Fully isolated | Multi-session work |

## Current Harness: Streams Model (Sound)
The existing pattern from harness-modularization works:
- Phase 1: Sequential foundation (W-01 -> W-02 -> W-03)
- Phase 2: Parallel streams B, C, D (no file overlap)
- Phase 3: Integration point (W-10)

## What the Decompose Step Should Add

### Stream Documents Need
- **Isolation mode**: `worktree` for file-modifying, `none` for read-only
- **Agent type**: Which agent definition to use
- **Skills to load**: Explicit skill list
- **Estimated scope**: Small/medium/large (determines parallelism strategy)
- **Input/output artifacts**: What reads from prior phases, what produces for dependents
- **File ownership manifest**: Explicit files this stream may create/modify

### Execution Plan
- Phase map: which streams run in which phase
- Parallelism strategy per phase: subagent vs agent-team vs worktree
- Gate criteria between phases
- Critical path duration estimate

### File Conflict Matrix
- Matrix of stream-pairs showing shared files
- If conflicts: merge into same stream or define merge protocol

## Hybrid Strategy (Recommended)
- **Small parallel (2-3 streams, <1 session each)**: Subagents with `isolation: worktree`
- **Large parallel (3+ streams, multi-session)**: Agent teams with shared task list
- **Research/investigation**: Subagents (fast, read-only)
- **Integration phases**: Single agent in main session

## Anti-Patterns
- Over-parallelization: >5 streams degrades coordination
- Premature parallelization: foundation code must be sequential
- Context exhaustion: many subagents fill lead's context window
- Shared state problems: design phases so all inputs available at phase start
