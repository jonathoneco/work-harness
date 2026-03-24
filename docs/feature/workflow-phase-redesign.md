# W3: Workflow Phase Redesign

**Status**: Plan
**Tier**: T3 Initiative
**Epic**: work-harness-pim

## What

The work harness's phase system is forward-only — agents cannot push back, advisories are ambiguous, and there is no path for standalone research. W3 replaces the linear phase model with one that supports pushback (explore clarity), forced resolution (ASK verdicts replacing ADVISORY), and empowered agents (plan agent with inline research capability), while adding a standalone `work-research` command and improving adversarial eval with pluggable framings.

## Components

| ID | Component | Scope | Phase |
|----|-----------|-------|-------|
| C01 | Step Lifecycle Extension | Small | 1 |
| C02 | Verdict System Redesign | Medium | 1 |
| C03 | Approval Ceremony Tiering | Medium | 2 |
| C04 | Explore Phase Clarity | Medium | 2 |
| C05 | Plan Agent Redesign | Small | 2 |
| C06 | Phase B Finding Resolution | Small | 2 |
| C07 | work-research Command | Medium | 3 |
| C08 | Adversarial Eval Improvements | Medium | 3 |

## Key Decisions

- Replace ADVISORY verdict with ASK — forces user response, eliminates ambiguity
- Plan agent empowered with inline Explore subagents (up to 3, capped) for gap-filling — no formal loopback machinery
- Step lifecycle unchanged (`not_started → active → completed`) — no re-entry mechanics needed
- Risk-based approval ceremony: early transitions (research→plan) are high-risk hard stops; late transitions (implement phases) are low-risk auto-advance
- Adversarial eval is optional during plan/spec, not a mandatory step; supports pluggable framings
- Changes apply to T2 and T3; T1 (work-fix) is unaffected
- All 9 items ship as one initiative in 3 dependency-ordered phases

## Key Files

- `claude/skills/work-harness/references/state-conventions.md` — step lifecycle, state schema
- `claude/skills/work-harness/phase-review.md` — verdict system (PASS/ASK/BLOCKING)
- `claude/skills/work-harness/step-transition.md` — approval ceremony, risk tiering
- `claude/skills/work-harness/step-agents.md` — plan agent template (inline research capability)
- `claude/commands/work-deep.md` — T3 command (research, plan, implement step sections)
- `claude/commands/work-feature.md` — T2 command (plan step section)
- `claude/commands/work-research.md` — new standalone research command
- `claude/skills/adversarial-eval.md` — new adversarial eval skill

## Work Items

- [ ] Explore phase: build clarity — nail down intention, push back, ask questions before planning
- [ ] Plan mode redesign — pointed design questions with options, ability to expand
- [ ] Review timing — phased review only at end of back-and-forth, not mid-conversation
- [ ] Open questions: tackle immediately when possible
- [ ] Aggressive Phase B finding resolution — handle findings immediately unless design concern
- [ ] Advisory notes -> direct clarification asks
- [ ] `work-research` support — research-only path for pure research tasks
- [ ] First-class research/design loop — formal support for repeated research/design pattern
- [ ] General adversarial-eval improvements — flush out perspectives into argued positions

## Implementation Notes

_(to be populated during implementation)_
