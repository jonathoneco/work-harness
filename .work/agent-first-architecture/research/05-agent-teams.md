# Agent Teams Feature

## Status: Enabled and Available

User has experimental flag enabled. Not blocked.

## API Surface

**TeamCreate**: Natural language invocation — lead spawns teammates based on description.
- Config stored at `~/.claude/teams/{team-name}/config.json`
- Shared task list at `~/.claude/tasks/{team-name}/`

**TeamDelete**: Lead-only cleanup. Fails if teammates still active.

## Communication Model

- **Shared Task List**: All agents see pending/in-progress/completed tasks with dependency resolution
- **Mailbox**: Direct messaging between teammates (not lead-mediated)
- **File Locking**: Prevents race conditions on task claiming
- **Broadcast**: Send to all teammates (use sparingly, token cost)

## Key Advantages Over Manual Subagents

| Feature | Manual Subagents | Agent Teams |
|---------|-----------------|-------------|
| Inter-agent comms | None (lead-mediated) | Direct mailbox |
| Task coordination | Lead orchestrates | Shared task list, self-claim |
| Context windows | Shared/exhaustible | Independent per teammate |
| File conflicts | No protection | File locking |
| Discovery | None | Teammates discover each other via config |

## Constraints

- **No session resumption**: Teammates disappear on `/resume` or `/rewind`
- **One team per session**
- **No nested teams**: Teammates can't create sub-teams (but CAN spawn subagents)
- **File partitioning required**: Two teammates editing same file → overwrites
- **Hung teammates block TeamDelete**
- **Task status can lag**: Teammates sometimes fail to mark tasks complete

## Best Fit for Harness

| Use Case | Fit | Rationale |
|----------|-----|-----------|
| Parallel research (3+ topics) | Strong | Clear boundaries, no file conflicts, read-only |
| Multi-angle review | Strong | Independent reviewers, no shared state |
| Parallel implementation streams | Good | File ownership already partitioned by stream docs |
| Adversarial evaluation | Strong | Competing hypothesis pattern well-documented |
| Plan/spec steps | Weak | Need user interaction, sequential by nature |
| Decompose | Moderate | Could parallelize stream doc creation if scope is large |

## Session Resumption Workaround

Since the harness already uses file-based handoff prompts and state.json (not in-memory state), the "no session resumption" limitation is less severe:
- Team work should be scoped to complete within a single session/step
- Results written to `.work/` files persist across sessions
- Lead can re-create team after resume if needed

## Integration Recommendation

Start with **research and review steps** — they have:
- Clear task boundaries
- No file mutation conflicts
- Well-defined deliverables (notes, findings)
- Natural parallelism

Extend to **implement step** once patterns are proven — stream docs already provide file ownership partitioning.
