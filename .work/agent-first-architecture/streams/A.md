---
stream: A
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/work-harness/context-seeding.md
  - claude/skills/work-harness.md
---

# Stream A: Context Seeding Protocol

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-01 | work-harness-4ei | Context Seeding Protocol | 01 |

## Dependency Constraints

- No dependencies — this is the first stream in Phase 1
- Must complete before Stream B (spec 02 references this protocol)

## Spec Reference

Read `.work/agent-first-architecture/specs/01-context-seeding-protocol.md` for full details.

## Files to Create/Modify

| Action | File | What to Do |
|--------|------|------------|
| Create | `claude/skills/work-harness/context-seeding.md` | Context seeding protocol with standard preamble, per-step context table, handoff contract, anti-patterns |
| Modify | `claude/skills/work-harness.md` | Add reference to `context-seeding.md` in the skill index |

## Implementation Notes

1. Create the directory `claude/skills/work-harness/` if it doesn't exist
2. Write `context-seeding.md` with all sections from spec 01:
   - Standard preamble (from spec 00 section 2)
   - Per-step context table covering all 6 delegated steps
   - Handoff prompt contract with required sections
   - Rule file injection (referencing spec 00 section 3)
   - Managed docs injection (conditional on harness.yaml)
   - Anti-patterns list (5+ entries with rationale)
3. Add a line in `work-harness.md` referencing the new file

## Acceptance Criteria

Reference spec 01 acceptance criteria:
- `context-seeding.md` exists at correct path
- Standard preamble matches spec 00 section 2
- Per-step context table covers all 6 steps with "Does NOT Receive" column
- Handoff prompt contract documented
- Anti-patterns list has 5+ entries
- `work-harness.md` references the new file
