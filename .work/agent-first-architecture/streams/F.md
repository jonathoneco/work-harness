---
stream: F
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/commands/delegate.md
---

# Stream F: /delegate Skill

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-06 | work-harness-1bh | /delegate Skill | 06 |

## Dependency Constraints

- Depends on: Phase 2 complete (Streams D and E — W-04, W-05)
- This is the final stream — no downstream dependencies

## Spec Reference

Read `.work/agent-first-architecture/specs/06-delegate-skill.md` for full details.
Also read specs 00, 01, 02 for contracts consumed.

## Files to Create/Modify

| Action | File | What to Do |
|--------|------|------------|
| Create | `claude/commands/delegate.md` | /delegate command definition |

## Implementation Notes

### Command Interface

`/delegate <description>` — natural language task description.

### Routing Table (spec 06 section 1.3)

| Pattern | Route To | Config |
|---------|----------|--------|
| "research/investigate/explore ..." | Explore agent | `subagent_type: "Explore"`, read-only |
| "review/check/audit ..." | Review agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "write/create/implement ..." | Implementation agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "plan/design/architect ..." | Plan agent | `subagent_type: "Plan"`, read-only |
| "test ..." | Test agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| (ambiguous) | General agent | `subagent_type: "general-purpose"`, `mode: "default"` |

### Prompt Construction

1. Read context seeding protocol (`claude/skills/work-harness/context-seeding.md`)
2. Build prompt using spec 00 section 1 structure (6 sections)
3. If active task: include standard preamble from state.json
4. If no active task: skip preamble, use minimal context
5. Always include skill injection (at minimum: code-quality)
6. Spawn agent with routing config
7. Return agent's output to user

## Acceptance Criteria

Reference spec 06 acceptance criteria:
- `delegate.md` exists at `claude/commands/delegate.md`
- Accepts natural language description
- Routing table covers research, review, implementation, plan, test categories
- Prompt construction follows spec 00 section 1 structure
- Context seeding uses spec 01 protocol
- Works with and without active task
- Agent output returned to user
