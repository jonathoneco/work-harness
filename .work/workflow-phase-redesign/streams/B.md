---
stream: B
phase: 2a
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/step-transition.md
  - claude/skills/work-harness/phase-review.md
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
---

# Stream B: Ceremony Tiering + Finding Resolution (Phase 2a)

## Work Items

| W-ID | Beads ID | Spec | Title |
|------|----------|------|-------|
| W-03 | work-harness-pim.3 | 03 | Approval ceremony tiering |
| W-06 | work-harness-pim.6 | 06 | Phase B finding resolution |

## Internal Ordering

W-03 and W-06 are independent (C03 and C06 both depend only on C02). Within this stream, do W-03 first because it modifies `step-transition.md` which W-06 does not touch, minimizing conflict risk. Then W-06 modifies `phase-review.md` and `work-deep.md`.

File coordination within stream:
- `step-transition.md`: Only W-03 modifies it (risk classification, auto-advance, ceremony override)
- `phase-review.md`: Only W-06 modifies it (finding resolution protocol)
- `work-deep.md`: W-03 updates transition references, W-06 updates implement step — different sections
- `work-feature.md`: Only W-03 modifies it (transition references)

## W-03: Approval Ceremony Tiering (spec 03)

**Files**: `claude/skills/work-harness/step-transition.md`, `claude/commands/work-deep.md`, `claude/commands/work-feature.md`

**Implementation steps** (from spec 03):
1. Add "Risk Classification" section to step-transition.md with static risk table and resolution rules
2. Update approval ceremony to auto-advance for low-risk PASS (notification only, no user input)
3. Add `ceremony: always` override check from `.claude/harness.yaml`
4. Update work-deep.md inter-step review to reference risk-based ceremony
5. Update work-feature.md transition instructions to reference risk-based ceremony
6. Add T2 risk mappings (plan→implement: medium, implement→review: low) to the table

**Acceptance criteria**: See spec 03 AC-1.1 through AC-6.2.

**Testing**: Table completeness check, auto-advance walkthrough, hard stop walkthrough, ASK override check, ceremony:always simulation, gate file creation for auto-advanced transitions.

## W-06: Phase B Finding Resolution (spec 06)

**Files**: `claude/skills/work-harness/phase-review.md`, `claude/commands/work-deep.md`

**Implementation steps** (from spec 06):
1. Define immediate resolution criteria (in-scope, no arch changes, ≤3 files, not design concern)
2. Add "Immediate Finding Resolution" section to phase-review.md (implementation phases only)
3. Extend gate file format with `## Finding Resolution` section (Resolved Immediately + Deferred to Review)
4. Update work-deep.md implement step to reference finding resolution protocol
5. Add re-review threshold: >5 deferred findings suggests early `/work-review`

**Acceptance criteria**: See spec 06 AC-1.1 through AC-5.3.

**Testing**: Criteria specificity, protocol completeness walkthrough, deferral path walkthrough, ASK fallback, max-3 cap, gate file format, re-review threshold.

## Dependency Constraints

- Requires Phase 1 (Stream A) to complete first — builds on C02's verdict system
- Must complete before Phase 2b (Stream C) to avoid file conflicts on `work-deep.md` and `work-feature.md`
