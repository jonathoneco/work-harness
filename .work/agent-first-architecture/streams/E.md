---
stream: E
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/teams-protocol.md
  - claude/commands/work-deep.md
  - claude/skills/work-harness.md
---

# Stream E: Agent Teams Integration

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-05 | work-harness-h54 | Agent Teams Integration | 05 |

## Dependency Constraints

- Depends on: Phase 1 complete (Streams A, B, C — W-01, W-02, W-03)
- Parallel with: Stream D (spec 04) — see file ownership notes below
- Must complete before Phase 3 (Stream F)

## Spec Reference

Read `.work/agent-first-architecture/specs/05-agent-teams-integration.md` for full details.
Also read specs 00 and 01 for contracts consumed.

## Files to Create/Modify

| Action | File | Sections Owned |
|--------|------|---------------|
| Create | `claude/skills/work-harness/teams-protocol.md` | Full file — Teams usage protocol |
| Modify | `claude/commands/work-deep.md` | Research step ONLY |
| Modify | `claude/skills/work-harness.md` | Add reference to teams-protocol.md |

## File Ownership Notes — Phase 2 Conflict Resolution

Stream D and Stream E both modify `work-deep.md` but own different sections:
- **Stream E owns**: research step ONLY
- **Stream D owns**: implement step, review step

**Do NOT modify any section outside the research step in work-deep.md.**

## Implementation Notes

### Step 1: Create teams-protocol.md

Write `claude/skills/work-harness/teams-protocol.md` with:
- Team naming convention: `{step}-{task-name}` (from state.json)
- Task schema: title, description (with output file path), status
- Teammate prompt template following spec 00 section 1 structure
- Completion detection: lead monitors task list, generates index/handoff
- Failure handling: case-by-case principles (see spec 05 section 1.5)

### Step 2: Replace research step in work-deep.md

Replace current manual Explore agent spawning with Teams-based execution:

**Current**: Lead spawns one Explore agent per topic, waits, synthesizes
**New**: Lead creates team (`TeamCreate`), creates shared tasks, teammates self-claim, lead monitors, generates index + handoff, tears down team (`TeamDelete`)

Key differences:
- Topics are self-claimed from shared task list (natural load balancing)
- Teammates use the prompt template from teams-protocol.md
- Lead still owns index.md and handoff-prompt.md generation

### Step 3: Register in work-harness.md

Add reference to `teams-protocol.md` in the skill index.

## Acceptance Criteria

Reference spec 05 acceptance criteria:
- `teams-protocol.md` exists at correct path
- Team naming convention documented
- Task schema with title, description, status documented
- Teammate prompt template follows spec 00 section 1 structure
- Research step uses TeamCreate/TeamDelete instead of manual subagents
- Lead still owns index.md and handoff-prompt.md generation
- `work-harness.md` references teams-protocol.md
