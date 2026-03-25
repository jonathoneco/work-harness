---
description: "Capture daily work progress to the work-log memory server"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /handoff $ARGUMENTS

Capture what was accomplished, decided, and blocked during this session. Writes entities and relations to the `work-log` MCP Knowledge Graph server.

## Prerequisites

Check for `work-log` MCP server availability by confirming `mcp__work_log__` tools exist in the available tool set.

- If not available: "work-log MCP server not configured. See `claude/skills/work-harness/references/work-log-setup.md` for setup instructions." — stop.

## Process

### Step 1: Gather Context

Collect session context from multiple sources:

1. **Active task** (if any): Read `.work/*/state.json` for active task name, current step, tier
2. **Git activity**: `git log --oneline --since="8 hours ago"` for recent commits
3. **Beads activity**: `bd list --status=in_progress` for claimed issues, `bd list --status=closed --since=today` for completed issues (if `bd` supports `--since`, otherwise skip)
4. **User input**: If `$ARGUMENTS` is provided (and is not "quick" or "q"), use as additional context. If not provided, synthesize from git and beads data.

### Step 2: Create Session Entity

Create a WorkSession entity for today's work:

```
mcp__work_log__create_entities([{
  "name": "session-YYYY-MM-DD-<project>",
  "entityType": "WorkSession",
  "observations": [
    "date: YYYY-MM-DD",
    "project: <project-name>",
    "summary: <1-2 sentence summary of session>"
  ]
}])
```

Determine `<project>` from `harness.yaml` `project.name` or the git repo name.

If a session entity already exists for today + project (check via `mcp__work_log__search_nodes("session-YYYY-MM-DD-<project>")`), create the new session with a suffix (e.g., `session-YYYY-MM-DD-<project>-2`) and add a `follows-up` relation from the new session to the existing one.

### Step 3: Create Accomplishment Entities

For each completed work item or significant progress:

```
mcp__work_log__create_entities([{
  "name": "accomplishment-<slug>",
  "entityType": "Accomplishment",
  "observations": [
    "what: <description>",
    "beads_ids: <comma-separated IDs if applicable>",
    "completed_at: <timestamp>"
  ]
}])

mcp__work_log__add_relations([{
  "from": "session-YYYY-MM-DD-<project>",
  "to": "accomplishment-<slug>",
  "relationType": "session-includes"
}])
```

### Step 4: Create Decision Entities

*Skipped in minimal mode.*

For each significant decision made during the session:

```
mcp__work_log__create_entities([{
  "name": "decision-<slug>",
  "entityType": "Decision",
  "observations": [
    "what: <the decision>",
    "why: <rationale>",
    "alternatives_considered: <what else was evaluated>",
    "decided_at: <timestamp>"
  ]
}])

mcp__work_log__add_relations([{
  "from": "session-YYYY-MM-DD-<project>",
  "to": "decision-<slug>",
  "relationType": "session-includes"
}])
```

If the decision relates to a specific accomplishment from Step 3, also create:

```
mcp__work_log__add_relations([{
  "from": "decision-<slug>",
  "to": "accomplishment-<slug>",
  "relationType": "decision-for-task"
}])
```

### Step 5: Create Blocker Entities

*Skipped in minimal mode.*

For each blocker encountered or resolved:

```
mcp__work_log__create_entities([{
  "name": "blocker-<slug>",
  "entityType": "Blocker",
  "observations": [
    "what: <the blocker>",
    "status: active|resolved",
    "reported_at: <timestamp>"
  ]
}])

mcp__work_log__add_relations([{
  "from": "session-YYYY-MM-DD-<project>",
  "to": "blocker-<slug>",
  "relationType": "session-includes"
}])
```

If resolved, add resolution observations and relation:

```
mcp__work_log__add_observations([{
  "entityName": "blocker-<slug>",
  "contents": ["resolution: <how it was resolved>", "resolved_at: <timestamp>"]
}])

mcp__work_log__add_relations([{
  "from": "blocker-<slug>",
  "to": "decision-<slug>",
  "relationType": "unblocked-by"
}])
```

If a blocker blocked a specific accomplishment, also create:

```
mcp__work_log__add_relations([{
  "from": "accomplishment-<slug>",
  "to": "blocker-<slug>",
  "relationType": "blocked-by"
}])
```

### Step 6: Present Summary

Display what was captured:

```
## Handoff Summary

**Session**: session-YYYY-MM-DD-<project>
**Accomplishments**: N items
**Decisions**: N items
**Blockers**: N active, N resolved

Entities written to work-log. Run `mcp__work_log__search_nodes("session-YYYY-MM-DD")` to review.
```

## Minimal Mode

If `$ARGUMENTS` is "quick" or "q": skip Steps 4-5 (decisions and blockers), only capture the session and accomplishments. For end-of-day quick captures when the user just wants to log what got done.

## Entity Schema Reference

See `claude/skills/work-harness/references/work-log-entities.md` for the full entity types, relation types, observation conventions, and name pattern rules.
