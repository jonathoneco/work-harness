# Memory Routing

Two MCP Knowledge Graph servers are available for persistent memory. Route writes to the correct server based on content type.

## work-log (cross-project work journal)

Use `mcp__work_log__*` tools for:
- Work session summaries and progress
- Decisions made during development (what, why, alternatives)
- Blockers encountered and their resolutions
- Accomplishments and completed work items
- Cross-project patterns and lessons learned

**When**: End-of-session handoffs, decision capture, blocker tracking.
**Entities**: WorkSession, Decision, Blocker, Accomplishment.

## personal-agent (project-specific knowledge)

Use `mcp__personal_agent__*` tools for:
- Architecture decisions specific to this project
- Codebase patterns and conventions
- Project-specific debugging notes
- Dependency quirks and workarounds
- User preferences for this project

**When**: Discovering project patterns, learning codebase conventions, noting project-specific gotchas.

## Routing Decision

Ask: "Would this information be useful when working on a **different** project?"
- **Yes** -> `work-log` (cross-project value)
- **No** -> `personal-agent` (project-specific)

When uncertain, prefer `personal-agent` — project-specific is the safer default. Cross-project observations can always be promoted to `work-log` later.
