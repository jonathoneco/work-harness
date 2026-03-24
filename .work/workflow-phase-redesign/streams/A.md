---
stream: A
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/references/state-conventions.md
  - claude/skills/work-harness/phase-review.md
  - claude/skills/work-harness/step-transition.md
---

# Stream A: Foundation (Phase 1)

## Work Items

| W-ID | Beads ID | Spec | Title |
|------|----------|------|-------|
| W-01 | work-harness-pim.1 | 01 | State schema extensions |
| W-02 | work-harness-pim.2 | 02 | Verdict system redesign |

## Internal Ordering

W-01 (spec 01) MUST complete before W-02 (spec 02). C02 depends on C01's updated state-conventions.md.

## W-01: State Schema Extensions (spec 01)

**File**: `claude/skills/work-harness/references/state-conventions.md`

**Implementation steps** (from spec 01):
1. Replace all ADVISORY references with ASK in verdict type docs
2. Add "Gate File Format" section with `## Resolved Asks` template (from Spec 00, Contract 1)
3. Add "Ceremony Configuration" section documenting `workflow.ceremony` setting
4. Add Tier R row to step names table (steps: assess, research, synthesize)

**Acceptance criteria**: See spec 01 AC-1.1 through AC-4.3.

**Testing**: Grep for "ADVISORY" (0 matches), verify "ASK" in verdict defs, verify new sections exist, verify Tier R row with correct steps.

## W-02: Verdict System Redesign (spec 02)

**Files**: `claude/skills/work-harness/phase-review.md`, `claude/skills/work-harness/step-transition.md`

**Implementation steps** (from spec 02):
1. Replace ADVISORY with ASK in phase-review.md verdict types, agent instructions, flow
2. Update verdict flow diagram: Phase A → {PASS/ASK/BLOCKING}, Phase B → {PASS/ASK/BLOCKING}
3. Add "ASK Verdict Resolution" section to step-transition.md between Phase Review and Approval Ceremony
4. Extend gate file template in step-transition.md with `## Resolved Asks` section
5. Remove all remaining ADVISORY references in step-transition.md

**Acceptance criteria**: See spec 02 AC-1.1 through AC-5.2.

**Testing**: Grep both files for "ADVISORY" (0 matches), verify ASK is intermediate path in flow, verify gate file template has Resolved Asks section, end-to-end trace for Phase B ASK with 2 questions.

## Dependency Constraints

- None — this is Phase 1, the foundation for all subsequent work.
- Must complete before Phase 2a (Stream B) and Phase 2b (Stream C) can start.
