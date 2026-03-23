---
stream: D
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
  - claude/commands/work-fix.md
---

# Stream D: Delegation Audit & Fix

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-04 | work-harness-nz6 | Delegation Audit & Fix | 04 |

## Dependency Constraints

- Depends on: Phase 1 complete (Streams A, B, C — W-01, W-02, W-03)
- Parallel with: Stream E (spec 05) — see file ownership notes below
- Must complete before Phase 3 (Stream F)

## Spec Reference

Read `.work/agent-first-architecture/specs/04-delegation-audit-fix.md` for full details.
Also read specs 00 and 01 for the standards being audited against.

## Files to Create/Modify

| Action | File | Sections Owned |
|--------|------|---------------|
| Modify | `claude/commands/work-deep.md` | Implement step agent spawns, review step agent spawns |
| Modify | `claude/commands/work-feature.md` | Plan Explore agent, implement agent spawns |
| Modify | `claude/commands/work-fix.md` | Implement agent spawn (if any) |

## File Ownership Notes — Phase 2 Conflict Resolution

Stream D and Stream E both modify `work-deep.md` but own different sections:
- **Stream D owns**: implement step, review step (Phase B agents)
- **Stream E owns**: research step ONLY

**Do NOT modify the research step** — Stream E (spec 05) replaces it entirely with Agent Teams. The research step fix from spec 04 (inconsistent skill injection) is subsumed by spec 05's rewrite.

## Implementation Notes

### Audit Scope

Inventory every agent spawn across work-deep.md, work-feature.md, work-fix.md. For each, verify:
1. Standard preamble present (spec 00 section 2)
2. Correct skill injection (spec 00 section 3 matrix)
3. Follows per-step context table (spec 01)
4. Prompt follows 6-section structure (spec 00 section 1)

### Known Fixes (from spec 04 Step 2)

| Gap | Location | Fix |
|-----|----------|-----|
| Implementation agents: stack context missing | work-deep.md implement step | Add stack context block when harness.yaml exists |
| Review agents: code-quality.md sometimes missing | work-deep.md Phase B agents | Ensure all Phase B review agents read code-quality.md |
| Tier 2 plan step: ad-hoc Explore agent context | work-feature.md plan step | Formalize with standard preamble and skill injection |

### Verify No Over-Seeding

Check each agent spawn against spec 01's "Does NOT Receive" column. Remove any excess context.

## Acceptance Criteria

Reference spec 04 acceptance criteria:
- All implement agent spawns include stack context when harness.yaml exists
- All Phase B review agents read code-quality.md
- Tier 2 plan step Explore agent has standard preamble and skill injection
- No agent spawn violates spec 01 anti-patterns
- Each modified agent spawn follows spec 00 section 1 structure
- Research step NOT modified (owned by Stream E)
- ~~Research agent skill injection consistency~~ — subsumed by Stream E's full research step rewrite
