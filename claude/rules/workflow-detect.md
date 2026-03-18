# Work Harness Detection

At session start, check for active tasks:

1. Look for `.work/*/state.json` files
2. For each, check if `archived_at` is null (meaning active)
3. If active tasks exist, display a brief notification:

```
Active task detected: <name> (Tier <N>)
Current step: <step> (status: <status>)
Run /work-status for details or /work-reground to recover context.
```

4. If `.work/` exists but only archived tasks:
```
No active tasks. Start a new one with /work <description>.
```

5. If no `.work/` directory exists, do nothing.

## Session End Reminder

When the user signals they are ending a session (e.g., "that's it for today", "wrapping up", "done for now", "EOD"), suggest:

```
Consider running /handoff to capture today's progress before ending.
```

Only suggest if:
- The `work-log` MCP server is available (check for `mcp__work_log__` tools in available tools)
- `/handoff` was not already run this session

Do not suggest if either condition is not met.
