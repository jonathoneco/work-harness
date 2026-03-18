# Spec 11: Memory Integration (C11)

**Component:** C11 -- Phase 4, Scope L, Priority P10
**Requires:** None for core functionality. Enriched by C6 (Auto-Reground) as a future enhancement.

## Overview

Add a `work-log` MCP Knowledge Graph server for persistent cross-project work journaling, and a `/handoff` command for capturing daily progress. The existing `personal-agent` KG handles project-specific knowledge; `work-log` handles cross-project work context (what was worked on, decisions made, blockers encountered). A routing rule ensures Claude writes to the correct server. This provides continuity across sessions and projects without relying on conversation history.

## Scope

**In scope:**
- `work-log` MCP KG server configuration
- Entity schema for work journal (sessions, decisions, blockers, accomplishments)
- `/handoff` command for daily progress capture
- Routing rule for `work-log` vs `personal-agent` server selection
- Entity schema documentation

**Out of scope:**
- `personal-agent` MCP server changes (already exists, not part of this initiative)
- Auto-Reground enrichment from memory (future enhancement to C6 -- see Advisory Notes)
- Memory-based agent context injection (future -- agents do not automatically receive memory context)
- KG server implementation (uses existing `@anthropic/mcp-knowledge-graph` or equivalent)
- Memory garbage collection or retention policies (future)
- Querying work-log from within commands automatically (future -- manual `mcp__work_log__*` calls only)

## Implementation Steps

### Step 1: Create work-log MCP server configuration

Document the MCP server configuration for `work-log` to be added to the user's Claude Code MCP settings.

**Server configuration (for `~/.claude/mcp.json` or project `.mcp.json`):**

```json
{
  "mcpServers": {
    "work-log": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-knowledge-graph"],
      "env": {
        "GRAPH_PATH": "~/.local/share/claude/work-log.jsonl"
      }
    }
  }
}
```

**Key decisions:**
- Server name `work-log` is descriptive (not generic like `memory-2`) -- supports routing by name
- Graph file lives in `~/.local/share/claude/` following XDG conventions
- User-level (not project-level) so it spans all projects
- Uses the same KG server package as `personal-agent` for consistency

Create a setup guide at `claude/skills/work-harness/references/work-log-setup.md`:

```markdown
# Work Log MCP Server Setup

## Installation

Add to your global MCP configuration (`~/.claude/mcp.json`):

    {
      "mcpServers": {
        "work-log": {
          "command": "npx",
          "args": ["-y", "@anthropic/mcp-knowledge-graph"],
          "env": {
            "GRAPH_PATH": "~/.local/share/claude/work-log.jsonl"
          }
        }
      }
    }

Ensure the directory exists:

    mkdir -p ~/.local/share/claude

## Verification

After adding the configuration, restart Claude Code and verify:

    mcp__work_log__list_entities

Should return an empty list on first run.
```

**AC-01**: `Setup guide exists at claude/skills/work-harness/references/work-log-setup.md with server configuration and verification steps` -- verified by `file-exists` + `structural-review`

### Step 2: Define entity schema for work-log KG

Document the entity types, relation types, and observation patterns that the work-log KG stores.

**Entity types:**

| Entity Type | Name Pattern | Observations |
|-------------|-------------|--------------|
| `WorkSession` | `session-YYYY-MM-DD-<project>` | date, project, summary |
| `Decision` | `decision-<short-slug>` | what, why, alternatives_considered, decided_at |
| `Blocker` | `blocker-<short-slug>` | what, status (active/resolved), resolution, reported_at, resolved_at |
| `Accomplishment` | `accomplishment-<short-slug>` | what, beads_ids (comma-separated), completed_at |

**Relation types:**

| Relation | From | To | Meaning |
|----------|------|------|---------|
| `session-includes` | WorkSession | Decision/Blocker/Accomplishment | This session produced this entity |
| `decision-for-task` | Decision | Accomplishment | This decision was made in service of this work (created when context links them) |
| `blocked-by` | Accomplishment | Blocker | This work was blocked by this issue |
| `unblocked-by` | Blocker | Decision | This blocker was resolved by this decision |
| `follows-up` | WorkSession | WorkSession | This session continues work from a prior session |

**Observation conventions:**
- Observations are short (one sentence each), factual, not narrative
- Each observation is a separate `add_observation` call (not batched into one long string)
- Dates in ISO 8601 format
- Project names match the `harness.yaml` `project.name` or the git repo name

**AC-02**: `Entity schema is documented with concrete entity types, name patterns, observation fields, and relation types` -- verified by `structural-review`

### Step 3: Create the /handoff command

Create `claude/commands/handoff.md` for capturing daily progress to the work-log KG.

```markdown
---
description: "Capture daily work progress to the work-log memory server"
user_invocable: true
---

# /handoff $ARGUMENTS

Capture what was accomplished, decided, and blocked during this session. Writes entities and relations to the `work-log` MCP Knowledge Graph server.

## Prerequisites

- `work-log` MCP server must be configured and running
- If not available: "work-log MCP server not configured. See claude/skills/work-harness/references/work-log-setup.md for setup instructions." -- stop

## Process

### Step 1: Gather Context

Collect session context from multiple sources:

1. **Active task** (if any): Read `.work/*/state.json` for active task name, current step, tier
2. **Git activity**: `git log --oneline --since="8 hours ago"` for recent commits
3. **Beads activity**: `bd list --status=in_progress` for claimed issues, `bd list --status=closed --since=today` for completed issues (if bd supports --since, otherwise skip)
4. **User input**: If `$ARGUMENTS` provided, use as additional context. If not, synthesize from git and beads data.

### Step 2: Create Session Entity

Create a WorkSession entity for today's work:

    mcp__work_log__create_entities([{
      "name": "session-YYYY-MM-DD-<project>",
      "entityType": "WorkSession",
      "observations": [
        "date: YYYY-MM-DD",
        "project: <project-name>",
        "summary: <1-2 sentence summary of session>"
      ]
    }])

If a session entity already exists for today + project (from an earlier /handoff), create a relation `follows-up` from the new session to the existing one instead of overwriting.

### Step 3: Create Accomplishment Entities

For each completed work item or significant progress:

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

### Step 4: Create Decision Entities

For each significant decision made during the session:

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

If the decision relates to a specific accomplishment from Step 3, also create:

    mcp__work_log__add_relations([{
      "from": "decision-<slug>",
      "to": "accomplishment-<slug>",
      "relationType": "decision-for-task"
    }])

### Step 5: Create Blocker Entities

For each blocker encountered or resolved:

    mcp__work_log__create_entities([{
      "name": "blocker-<slug>",
      "entityType": "Blocker",
      "observations": [
        "what: <the blocker>",
        "status: active|resolved",
        "reported_at: <timestamp>"
      ]
    }])

If resolved, add resolution observation and relation:

    mcp__work_log__add_observations([{
      "entityName": "blocker-<slug>",
      "contents": ["resolution: <how it was resolved>", "resolved_at: <timestamp>"]
    }])

    mcp__work_log__add_relations([{
      "from": "blocker-<slug>",
      "to": "decision-<slug>",
      "relationType": "unblocked-by"
    }])

### Step 6: Present Summary

Display what was captured:

    ## Handoff Summary

    **Session**: session-YYYY-MM-DD-<project>
    **Accomplishments**: N items
    **Decisions**: N items
    **Blockers**: N active, N resolved

    Entities written to work-log. Run `mcp__work_log__search_nodes("session-YYYY-MM-DD")` to review.

## Minimal Mode

If `$ARGUMENTS` is "quick" or "q": skip Steps 4-5 (decisions and blockers), only capture accomplishments. For end-of-day quick captures when the user just wants to log what got done.
```

**AC-03**: `Command file exists at claude/commands/handoff.md with valid frontmatter` -- verified by `file-exists`

**AC-04**: `Command checks for work-log MCP server availability before proceeding` -- verified by `structural-review`

**AC-05**: `Command creates WorkSession, Accomplishment, Decision, and Blocker entities with correct entity types and observation formats` -- verified by `structural-review`

**AC-06**: `Command supports a minimal "quick" mode that only captures accomplishments` -- verified by `structural-review`

### Step 4: Create memory routing rule

Create `claude/rules/memory-routing.md` to guide Claude on which MCP KG server to use for different types of information.

```markdown
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

When uncertain, prefer `personal-agent` -- project-specific is the safer default. Cross-project observations can always be promoted to `work-log` later.
```

**AC-07**: `Routing rule exists at claude/rules/memory-routing.md with clear criteria for work-log vs personal-agent` -- verified by `file-exists` + `structural-review`

**AC-08**: `Routing rule uses the "different project" test as the primary decision criterion` -- verified by `structural-review`

### Step 5: Update workflow-detect rule for handoff reminder

Add an end-of-session reminder to `claude/rules/workflow-detect.md` (or the relevant session-end detection point) suggesting `/handoff` before ending a session.

**Append to workflow-detect.md:**

```markdown
## Session End Reminder

When the user signals they are ending a session (e.g., "that's it for today", "wrapping up", "done for now", "EOD"), suggest:

```
Consider running /handoff to capture today's progress before ending.
```

Only suggest if the `work-log` MCP server is available (check for `mcp__work_log__` tools in available tools). Do not suggest if `/handoff` was already run this session.
```

**AC-09**: `workflow-detect.md includes a session-end reminder for /handoff that is conditional on work-log availability` -- verified by `structural-review`

### Step 6: Document entity schema in a reference file

Create `claude/skills/work-harness/references/work-log-entities.md` documenting the full entity schema for reference by the handoff command and future consumers.

This file contains the entity types table, relation types table, observation conventions, and name pattern rules from Step 2 in a standalone reference format following the reference doc format from Spec 00.

**AC-10**: `Entity schema reference exists at claude/skills/work-harness/references/work-log-entities.md with entity types, relations, and observation conventions` -- verified by `file-exists` + `structural-review`

## Interface Contracts

### Consumes

| Interface | From | Description |
|-----------|------|-------------|
| MCP KG server tools | `@anthropic/mcp-knowledge-graph` | `create_entities`, `add_relations`, `add_observations`, `search_nodes` |
| Active task state | `.work/*/state.json` | Task name, step, tier for session context |
| Git history | `git log` | Recent commits for session summary |
| Beads issues | `bd list`, `bd show` | Claimed and completed issues for accomplishments |

### Exposes

| Interface | To | Description |
|-----------|------|-------------|
| `/handoff` command | User | Daily progress capture command |
| Memory routing rule | All Claude sessions | Guidance on which KG server to write to |
| `work-log` entities | Future C6 enrichment | WorkSession, Decision, Blocker, Accomplishment entities queryable via MCP |
| Setup guide | User | Installation and verification instructions |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/handoff.md` | Create | Daily progress capture command |
| `claude/rules/memory-routing.md` | Create | Routing rule for work-log vs personal-agent |
| `claude/skills/work-harness/references/work-log-setup.md` | Create | MCP server setup guide |
| `claude/skills/work-harness/references/work-log-entities.md` | Create | Entity schema reference |
| `claude/rules/workflow-detect.md` | Modify | Add session-end reminder for /handoff |

## Testing Strategy

| Test | Method | Covers |
|------|--------|--------|
| Setup guide has valid server config JSON | `structural-review` | AC-01 |
| Entity schema has all four entity types with observations | `structural-review` | AC-02 |
| handoff.md has valid frontmatter and process steps | `structural-review` | AC-03, AC-04, AC-05, AC-06 |
| Routing rule has clear decision criteria | `structural-review` | AC-07, AC-08 |
| workflow-detect.md has conditional session-end reminder | `structural-review` | AC-09 |
| Entity schema reference file exists and is complete | `structural-review` | AC-10 |
| End-to-end with work-log configured: run `/handoff`, verify entities created via `mcp__work_log__search_nodes` | `integration-test` | AC-03, AC-05 |
| End-to-end without work-log: run `/handoff`, verify graceful error message | `manual-test` | AC-04 |
| End-to-end quick mode: run `/handoff q`, verify only accomplishments captured | `manual-test` | AC-06 |

## Deferred Questions Resolution

### DQ-5: C11 entity schema -- entities/relations/observations for work-log KG

**Resolution:** Four concrete entity types with structured observations:

**Entities:**
- `WorkSession` (name: `session-YYYY-MM-DD-<project>`) -- observations: date, project, summary
- `Decision` (name: `decision-<short-slug>`) -- observations: what, why, alternatives_considered, decided_at
- `Blocker` (name: `blocker-<short-slug>`) -- observations: what, status, resolution, reported_at, resolved_at
- `Accomplishment` (name: `accomplishment-<short-slug>`) -- observations: what, beads_ids, completed_at

**Relations:**
- `session-includes`: WorkSession -> Decision/Blocker/Accomplishment (session produced this entity)
- `decision-for-task`: Decision -> Accomplishment (decision in service of work)
- `blocked-by`: Accomplishment -> Blocker (work blocked by issue)
- `unblocked-by`: Blocker -> Decision (blocker resolved by decision)
- `follows-up`: WorkSession -> WorkSession (continuation of prior session)

This schema is intentionally minimal. New entity types (e.g., `LessonLearned`, `Pattern`) can be added as observations accumulate and patterns emerge. The KG is schema-flexible -- adding types requires only updating the entity schema reference doc, not changing any code.

## Advisory Notes Resolution

### B3: C11/C6 enrichment framing

C6 (Auto-Reground) ships without memory awareness. The enrichment path -- C6's post-compact hook pulling relevant context from work-log -- is documented here as a **future capability**, not a C11 deliverable.

**Future enrichment path (not implemented in this spec):**
When C6's post-compact hook runs, it could query `mcp__work_log__search_nodes` for the current project and recent sessions, then include relevant decisions and active blockers in the injected handoff context. This would provide session-to-session continuity beyond what handoff prompts capture.

**Why not now:** C6 is a shell hook (`post-compact.sh`) that reads files and outputs text. MCP tool calls are not available from shell hooks -- they require Claude agent context. The enrichment path would need either: (a) a command-level integration point (not a hook), or (b) a mechanism for hooks to trigger MCP queries. Neither exists today. Designing for this future in C6 now would violate the "no shims" principle.

### A4: Phase 4 timing precision

C11's core functionality (work-log server, /handoff command, routing rule) can start independently -- it has no hard dependency on any Phase 1 component. The C6 enrichment path is the only connection to C6, and since it is deferred to a future enhancement, C11 can be implemented at any time.

The practical constraint is that the `personal-agent` MCP server must already be configured (it is -- per architecture doc), so that the routing rule can reference both servers.
