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
