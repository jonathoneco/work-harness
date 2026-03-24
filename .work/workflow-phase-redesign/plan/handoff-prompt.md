# Plan Handoff: W3 Workflow Phase Redesign

## What This Step Produced

Architecture document at `.work/workflow-phase-redesign/specs/architecture.md` containing 7 design decisions, 8 components across 3 implementation phases.

## Architecture Summary

The redesign replaces the forward-only phase system with one that supports pushback (explore clarity), forced resolution (ASK verdicts replacing ADVISORY), and empowered agents (plan agent with inline research capability). Three implementation phases build from foundational state model changes through workflow mechanics to new capabilities. The research/design loop machinery was intentionally eliminated in favor of giving the plan agent inline Explore subagent capability — simpler, no state changes needed.

### Component Table

| ID | Component | Scope | Phase | Spec | Dependencies | Key Files |
|----|-----------|-------|-------|------|-------------|-----------|
| C01 | Step Lifecycle Extension | S | 1 | 01 | None | `references/state-conventions.md` |
| C02 | Verdict System Redesign | M | 1 | 02 | C01 | `phase-review.md`, `step-transition.md` |
| C03 | Approval Ceremony Tiering | M | 2 | 03 | C02 | `step-transition.md`, `work-deep.md`, `work-feature.md` |
| C04 | Explore Phase Clarity | M | 2 | 04 | C02 | `work-deep.md` (research step), `work-feature.md` (plan step) |
| C05 | Plan Agent Redesign | S | 2 | 05 | C02, C04 | `step-agents.md`, `work-deep.md`, `work-feature.md` |
| C06 | Phase B Finding Resolution | S | 2 | 06 | C02 | `work-deep.md` (implement step), `phase-review.md` |
| C07 | work-research Command | M | 3 | 07 | C01, C04 | `work-research.md` (new), `state-conventions.md`, `workflow-meta.md` |
| C08 | Adversarial Eval Improvements | M | 3 | 08 | C05 | `adversarial-eval.md` (new), `step-agents.md` |

## Design Decisions Summary

1. **DD-1 Scope/phasing**: All 9 items ship as one initiative in 3 phases (foundation, mechanics, capabilities)
2. **DD-2 Cross-tier impact**: Explore clarity + plan redesign apply to T2 and T3; T1 unaffected
3. **DD-3 ADVISORY redesign**: Replace ADVISORY with ASK verdict that requires user response before advancing
4. **DD-4 Research gaps**: Empower plan agent with inline Explore subagents (up to 3, capped) instead of formal loopback machinery
5. **DD-5 Approval ceremony**: Risk-based tiering — auto-advance on PASS for low-risk, hard stop for medium/high. Early transitions (research→plan, plan→spec) are high-risk; late transitions (implement phases) are low-risk
6. **DD-6 Adversarial eval**: Optional tool invocable during plan/spec phases, not a mandatory step
7. **DD-7 Step lifecycle**: Unchanged — `not_started → active → completed`. No re-entry mechanics needed

## Items Deferred to Spec

1. ASK verdict UX — presentation format, multi-question batching, gate file recording
2. Explore clarity protocol — pushback mechanism, structured questionnaire format, answer feedback
3. work-research state model — Tier R steps, state.json schema additions, synthesize step
4. Adversarial eval framing registry — registration, selection, built-in framing templates
5. Risk classification tuning — static vs dynamic risk, `ceremony: always` override interaction
6. Finding resolution boundary — immediate resolution criteria, re-review thresholds
7. Plan agent inline research bounds — Explore subagent constraints, token caps, scope limits

## Instructions for Spec Step

1. **Start with Spec 00** (cross-cutting contracts): Define the shared conventions used by multiple components:
   - ASK verdict format and response recording protocol (used by C02, C03, C06)
   - Risk classification table (used by C03)
   - Plan agent inline research constraints (used by C05)

2. **Write specs in dependency order**:
   - Spec 01 (C01) and Spec 02 (C02) first — Phase 1 foundation
   - Spec 03-06 (C03, C04, C05, C06) next — Phase 2 mechanics
   - Spec 07-08 (C07, C08) last — Phase 3 capabilities

3. **Cross-reference spec 00** from every component spec for shared schemas and conventions.

4. **Phase 2 internal ordering**: C05 depends on C04; spec 05 should reference patterns from spec 04. C03 and C06 are independent of C04/C05 and can be written in any order.
