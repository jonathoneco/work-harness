---
stream: C
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
---

# Stream C: Step Agent Dispatcher

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-03 | work-harness-gm5 | Step Agent Dispatcher | 03 |

## Dependency Constraints

- Depends on: Stream A (W-01) and Stream B (W-02) — dispatcher reads templates from step-agents.md and uses context seeding protocol
- Must complete before Phase 2 streams (D, E)

## Spec Reference

Read `.work/agent-first-architecture/specs/03-step-agent-dispatcher.md` for full details.
Also read specs 00, 01, 02 for contracts consumed by the dispatcher.

## Files to Create/Modify

| Action | File | What to Do |
|--------|------|------------|
| Modify | `claude/commands/work-deep.md` | Replace inline plan/spec/decompose instructions with dispatch blocks |
| Modify | `claude/commands/work-feature.md` | Replace inline plan step instructions with dispatch block |

## Implementation Notes

### Dispatch Block Pattern (spec 03 Step 1)

Replace each step's inline instructions with a dispatch block that:
1. Reads `step-agents.md` for the template
2. Fills variables from state.json (`{name}`, `{title}`, `{tier}`, `{current_step}`, `{base_commit}`, `{beads_epic_id}`)
3. Spawns foreground agent (`mode: "default"`, `subagent_type: "general-purpose"`)
4. Parses completion signal (spec 00 section 6)
5. Verifies artifacts exist
6. Presents summary to user with feedback loop
7. Handles re-spawn (max 2 attempts, spec 00 section 5)

### Specific Replacements

- **work-deep.md plan step** (spec 03 Step 2): Replace inline instructions between step header and auto-advance block
- **work-deep.md spec step** (spec 03 Step 3): Same pattern for spec
- **work-deep.md decompose step** (spec 03 Step 4): Same pattern for decompose. Note: decompose agent creates beads issues
- **work-feature.md plan step** (spec 03 Step 5): Same dispatch block — steps are building blocks, identical regardless of tier

### Preserve (Do NOT Modify)

- Step Router logic
- Auto-advance blocks (Phase A/B validation, verdict handling, state transition, compaction)
- Research step (changed by spec 05 in Phase 2)
- Implement step (stream-based delegation, unchanged)
- Review step (delegates to /work-review, unchanged)
- Inter-Step Quality Review Protocol section
- Context Compaction Protocol section

## Acceptance Criteria

Reference spec 03 acceptance criteria:
- Plan/spec/decompose steps in work-deep.md use dispatch blocks
- Dispatch blocks read template from step-agents.md
- Dispatch blocks fill variables from state.json
- Agent spawned with `mode: "default"`, `subagent_type: "general-purpose"`
- Feedback loop supports 2 re-spawns before escalation
- Auto-advance blocks unchanged
- Research, implement, review steps not modified
- work-feature.md plan step uses same dispatch block
