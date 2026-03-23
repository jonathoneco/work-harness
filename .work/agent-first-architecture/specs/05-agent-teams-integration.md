# Spec 05: Agent Teams Integration (C5)

**Component**: C5 — Agent Teams Integration
**Scope**: Medium
**Dependencies**: Spec 00 (cross-cutting contracts), Spec 01 (context seeding), Spec 03 (dispatcher)
**Phase**: 2

## Overview

Replace manual parallel subagent spawning in the research step with Agent Teams (TeamCreate/TeamDelete). Teams provide shared task lists with self-claiming, independent context windows per teammate, and structured completion detection — capabilities beyond manual subagent orchestration.

**Scope**: Research step only (D7 from architecture). Review step Teams integration is deferred until research Teams patterns are proven.

**Key constraint**: Teams disappear on `/resume`. Mitigated by the harness's file-based handoff pattern — research notes persist in `.work/` regardless of team lifetime.

---

## Implementation Steps

### Step 1: Create the teams protocol skill file

**File**: `claude/skills/work-harness/teams-protocol.md` (new)

Define the protocol for using Agent Teams in the harness:

#### 1.1 Team Naming Convention

Pattern: `{step}-{task-name}`

Examples:
- `research-agent-first-arch`
- `review-agent-first-arch` (future)

Names are derived from `state.json` fields. Max length: follow Claude Code constraints.

#### 1.2 Task Schema

Each task in the shared task list has:

```json
{
  "title": "{topic-number}: {topic-title}",
  "description": "Research topic: {topic-description}\nOutput file: .work/{name}/research/{NN}-{topic-slug}.md\nFormat: {note format from research step instructions}",
  "status": "pending"
}
```

Fields:
- `title`: Short identifier matching the research topic assignment
- `description`: Contains the topic scope, target output file path, and expected note format
- `status`: `pending` → `in_progress` → `completed` (managed by Teams infrastructure)

#### 1.3 Teammate Prompt Template

```
## Identity
You are a research teammate investigating "{topic-title}" for task "{title}".

## Task Context
{Standard preamble from spec 00 §2}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/work-harness.md`

## Instructions
1. Claim your topic from the shared task list
2. Investigate: {topic-specific questions from task description}
3. Write findings to: .work/{name}/research/{NN}-{topic-slug}.md
4. Format: Questions → Findings → Implications → Open Questions
5. Mark your task complete when the note is written

## File Ownership
You own ONLY: .work/{name}/research/{NN}-{topic-slug}.md
Do NOT write to any other file. The lead handles index.md and handoff-prompt.md.

## Completion
Mark your task as complete in the shared task list.
```

#### 1.4 Completion Detection

The lead monitors the shared task list:
1. Poll task list for all tasks `completed`
2. When all complete: read each research note, verify content
3. Generate `research/index.md` (lead responsibility, not teammate)
4. Generate `research/handoff-prompt.md` (lead responsibility)
5. Tear down team

#### 1.5 Failure Handling

The lead handles teammate failures case by case. Key principles:
- If a teammate's output file exists with content but the task wasn't marked complete, the lead can use the output and move on
- If a teammate fails entirely, the lead can reassign the topic or investigate it inline
- If the team as a whole isn't working (systemic failures), tear it down and fall back to sequential Explore agents (pre-Teams pattern)
- Research notes persist in `.work/` regardless of team state — Teams disappearing on `/resume` doesn't lose work

### Step 2: Modify research step in work-deep.md

**File**: `claude/commands/work-deep.md`

Replace the current research step's parallel Explore agent spawning with Teams-based execution:

**Current pattern** (manual subagents):
1. Lead identifies research topics
2. Lead spawns one Explore agent per topic
3. Lead waits for all agents
4. Lead synthesizes index and handoff

**New pattern** (Agent Teams):
1. Lead identifies research topics
2. Lead creates team: `TeamCreate("{step}-{name}")`
3. Lead creates shared tasks (one per topic) using the task schema (§1.2)
4. Teammates auto-spawn, self-claim topics, write research notes
5. Lead monitors task list for completion
6. On all complete: lead generates index + handoff (unchanged)
7. Lead tears down team: `TeamDelete("{step}-{name}")`

**Key difference**: The lead no longer assigns specific topics to specific agents. Topics are self-claimed from the shared task list. This enables natural load balancing if some topics are faster than others.

### Step 3: Register in work-harness skill index

Add a reference to `teams-protocol.md` in `claude/skills/work-harness.md`.

---

## Interface Contracts

### Exposes
- **Teams protocol**: Reusable pattern for future Teams integrations (review step)
- **Task schema**: Standard format for shared task list entries
- **Teammate prompt template**: Reusable pattern for teammate prompts
- **Timeout protocol**: Standard approach for handling hung teammates

### Consumes
- **Spec 00 §1**: Agent prompt structure (teammate prompts follow same structure)
- **Spec 00 §2**: Standard preamble (included in teammate prompts)
- **Spec 00 §3**: Skill injection (teammates read same skills)
- **Spec 01**: Context seeding protocol (what research agents receive)
- **Spec 03**: Dispatch pattern (Teams replaces manual dispatch for research)
- **Claude Code Teams API**: `TeamCreate`, `TeamDelete`, `TaskCreate`, `TaskGet`

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/teams-protocol.md` | Teams usage protocol for harness |
| Modify | `claude/commands/work-deep.md` | Replace research step manual subagents with Teams |
| Modify | `claude/skills/work-harness.md` | Add reference to teams-protocol.md |

---

## Testing Strategy

### Protocol Validation
- [ ] Team naming convention produces valid Claude Code team names
- [ ] Task schema contains all fields needed for teammate self-service
- [ ] Teammate prompt template follows spec 00 §1 structure

### Integration Validation
- [ ] Research step creates team, tasks, and tears down correctly
- [ ] Research notes are written to correct paths by teammates
- [ ] Lead generates index and handoff after all topics complete (not teammates)

---

## Acceptance Criteria

- [ ] `teams-protocol.md` exists at `claude/skills/work-harness/teams-protocol.md`
- [ ] Team naming convention documented: `{step}-{task-name}`
- [ ] Task schema documented with title, description, status fields
- [ ] Teammate prompt template follows spec 00 §1 structure
- [ ] Research step in work-deep.md uses TeamCreate/TeamDelete instead of manual subagents
- [ ] Lead still owns index.md and handoff-prompt.md generation (not delegated to teammates)
- [ ] `work-harness.md` references `teams-protocol.md`
