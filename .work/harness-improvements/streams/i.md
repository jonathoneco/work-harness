---
stream: I
phase: 4
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/handoff.md
  - claude/rules/memory-routing.md
  - claude/skills/work-harness/references/work-log-entities.md
  - claude/skills/work-harness/references/work-log-setup.md
  - claude/rules/workflow-detect.md
---

# Stream I: Phase 4 — Memory Integration

## Stream Identity

- **Stream:** I
- **Phase:** 4
- **Work Items:**
  - W-12 (work-harness-0nd): Memory integration — spec 11

## File Ownership

| File | Action | Work Items |
|------|--------|------------|
| `claude/commands/handoff.md` | Create | W-12 |
| `claude/rules/memory-routing.md` | Create | W-12 |
| `claude/skills/work-harness/references/work-log-setup.md` | Create | W-12 |
| `claude/skills/work-harness/references/work-log-entities.md` | Create | W-12 |
| `claude/rules/workflow-detect.md` | Modify | W-12 |

## Dependency Constraints

Stream I has no hard dependencies. It can begin execution at any time during Phase 4.

- **C6 (Auto-Reground) enrichment is future-only** — the path where C6's post-compact hook queries work-log for context is documented as a future enhancement, not a C11 deliverable. C11 does not depend on C6 completion.
- **`personal-agent` MCP server must already be configured** (it is, per architecture doc) so the routing rule can reference both servers.

---

## W-12: Memory Integration (work-harness-0nd)

**Spec reference:** `.work/harness-improvements/specs/11-memory-integration.md` (C11)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness/references/work-log-setup.md` | Create | MCP server setup guide with configuration and verification steps |
| `claude/skills/work-harness/references/work-log-entities.md` | Create | Entity schema reference with entity types, relations, and observation conventions |
| `claude/commands/handoff.md` | Create | Daily progress capture command writing to work-log KG |
| `claude/rules/memory-routing.md` | Create | Routing rule for work-log vs personal-agent server selection |
| `claude/rules/workflow-detect.md` | Modify | Add session-end reminder for /handoff |

### Acceptance Criteria

**AC-01**: `Setup guide exists at claude/skills/work-harness/references/work-log-setup.md with server configuration and verification steps` -- verified by `file-exists` + `structural-review`

**AC-02**: `Entity schema is documented with concrete entity types, name patterns, observation fields, and relation types` -- verified by `structural-review`

**AC-03**: `Command file exists at claude/commands/handoff.md with valid frontmatter` -- verified by `file-exists`

**AC-04**: `Command checks for work-log MCP server availability before proceeding` -- verified by `structural-review`

**AC-05**: `Command creates WorkSession, Accomplishment, Decision, and Blocker entities with correct entity types and observation formats` -- verified by `structural-review`

**AC-06**: `Command supports a minimal "quick" mode that only captures accomplishments` -- verified by `structural-review`

**AC-07**: `Routing rule exists at claude/rules/memory-routing.md with clear criteria for work-log vs personal-agent` -- verified by `file-exists` + `structural-review`

**AC-08**: `Routing rule uses the "different project" test as the primary decision criterion` -- verified by `structural-review`

**AC-09**: `workflow-detect.md includes a session-end reminder for /handoff that is conditional on work-log availability` -- verified by `structural-review`

**AC-10**: `Entity schema reference exists at claude/skills/work-harness/references/work-log-entities.md with entity types, relations, and observation conventions` -- verified by `file-exists` + `structural-review`

### Implementation Notes

C11 adds a `work-log` MCP Knowledge Graph server for persistent cross-project work journaling and a `/handoff` command for daily progress capture. This is a 6-step implementation:

#### Step 1: Create work-log MCP server setup guide

Create `claude/skills/work-harness/references/work-log-setup.md` with:
- Server configuration JSON for `~/.claude/mcp.json` (server name `work-log`, using `@anthropic/mcp-knowledge-graph`, graph file at `~/.local/share/claude/work-log.jsonl`)
- Directory creation command (`mkdir -p ~/.local/share/claude`)
- Verification step (`mcp__work_log__list_entities` should return empty list on first run)

#### Step 2: Define entity schema for work-log KG

Document the entity schema in `claude/skills/work-harness/references/work-log-entities.md`:

**Entity types:**
- `WorkSession` (name: `session-YYYY-MM-DD-<project>`) — observations: date, project, summary
- `Decision` (name: `decision-<short-slug>`) — observations: what, why, alternatives_considered, decided_at
- `Blocker` (name: `blocker-<short-slug>`) — observations: what, status (active/resolved), resolution, reported_at, resolved_at
- `Accomplishment` (name: `accomplishment-<short-slug>`) — observations: what, beads_ids (comma-separated), completed_at

**Relation types:**
- `session-includes`: WorkSession -> Decision/Blocker/Accomplishment
- `decision-for-task`: Decision -> Accomplishment
- `blocked-by`: Accomplishment -> Blocker
- `unblocked-by`: Blocker -> Decision
- `follows-up`: WorkSession -> WorkSession

**Conventions:**
- Observations are short (one sentence each), factual, not narrative
- Each observation is a separate `add_observation` call
- Dates in ISO 8601 format
- Project names match `harness.yaml` `project.name` or git repo name

#### Step 3: Create the /handoff command

Create `claude/commands/handoff.md` with valid frontmatter (`description`, `user_invocable: true`).

Process steps:
1. **Gather Context**: Read active task state, git log (last 8 hours), beads activity, user arguments
2. **Create Session Entity**: WorkSession with date, project, summary observations. Handle duplicate sessions via `follows-up` relation.
3. **Create Accomplishment Entities**: For each completed work item, with `session-includes` relation
4. **Create Decision Entities**: For each significant decision, with `session-includes` relation and optional `decision-for-task` cross-link
5. **Create Blocker Entities**: For each blocker (active or resolved), with resolution observations and `unblocked-by` relation if resolved
6. **Present Summary**: Display counts of accomplishments, decisions, blockers

**Minimal mode**: When `$ARGUMENTS` is "quick" or "q", skip Steps 4-5, only capture accomplishments.

**Prerequisite check**: If `work-log` MCP server is not available, display setup instructions and stop.

#### Step 4: Create memory routing rule

Create `claude/rules/memory-routing.md` describing routing between two KG servers:
- `work-log` (cross-project): work sessions, decisions, blockers, accomplishments, cross-project patterns
- `personal-agent` (project-specific): architecture decisions, codebase patterns, debugging notes, dependency quirks

**Primary decision criterion**: "Would this information be useful when working on a **different** project?" Yes -> work-log, No -> personal-agent. When uncertain, prefer personal-agent.

#### Step 5: Update workflow-detect rule for handoff reminder

Append a "Session End Reminder" section to `claude/rules/workflow-detect.md`:
- Trigger on session-end signals ("that's it for today", "wrapping up", "done for now", "EOD")
- Suggest `/handoff` only if `work-log` MCP server is available (check for `mcp__work_log__` tools)
- Do not suggest if `/handoff` was already run this session

#### Step 6: Document entity schema reference

Ensure `claude/skills/work-harness/references/work-log-entities.md` (from Step 2) is a standalone reference file following the reference doc format from Spec 00, containing the full entity types table, relation types table, observation conventions, and name pattern rules.
