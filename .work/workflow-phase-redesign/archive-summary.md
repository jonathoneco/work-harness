# Archive Summary: workflow-phase-redesign

**Tier:** 3
**Duration:** 2026-03-23T18:00:00Z -> 2026-03-24T20:55:00Z
**Sessions:** 5+ (research, plan, spec, decompose+implement, review)
**Beads epic:** work-harness-pim

## What Was Built

Redesigned the work harness phase system to support bidirectional communication, forced resolution of ambiguity, and standalone research. Key changes:

1. **Verdict system**: Replaced ADVISORY (log-only) with ASK (requires user response). Verdicts are now PASS/ASK/BLOCKING with explicit question format and response recording in gate files.
2. **Risk-based ceremony**: Step transitions classified by risk (high/medium/low). Low-risk transitions auto-advance; high-risk require approval ceremony. Configurable via `ceremony: always` override.
3. **Explore clarity**: Optional scope validation questionnaires in research and plan steps. Pushback escalation with re-scoping choices.
4. **Plan agent inline research**: Plan agents can spawn up to 3 read-only Explore subagents for gap-filling during planning (1,500 token cap each).
5. **Immediate finding resolution**: Phase B findings during implementation can be fixed inline if in-scope, localized, non-architectural, and not design concerns (max 3 per transition).
6. **Tier R / work-research**: New standalone research command with lightweight 3-step lifecycle (assess, research, synthesize). No review gates.
7. **Adversarial eval**: 4-phase debate protocol (position elicitation, opening arguments, rebuttal, synthesis) with 3 built-in framings and custom framing support via harness.yaml.

## Key Files

Created:
- `claude/commands/work-research.md` — Tier R command (249 lines)
- `claude/skills/adversarial-eval.md` — adversarial eval skill (165 lines)

Modified:
- `claude/skills/work-harness/references/state-conventions.md` — Tier R, ASK verdicts, ceremony config
- `claude/skills/work-harness/phase-review.md` — verdict system, finding resolution
- `claude/skills/work-harness/step-transition.md` — risk classification, auto-advance protocol
- `claude/skills/work-harness/step-agents.md` — plan agent inline research, adversarial eval injection
- `claude/skills/work-harness/references/gate-protocol.md` — ASK verdicts, Resolved Asks section
- `claude/commands/work-deep.md` — scope validation, handoff validation, ceremony references
- `claude/commands/work-feature.md` — task understanding check, ceremony references
- `claude/skills/work-harness.md` — Tier R, command list
- `claude/skills/workflow-meta.md` — command count
- `claude/rules/workflow.md` — command table

## Findings Summary

- 6 total findings (6 fixed, 0 deferred)
- Critical: 1 (gate-protocol.md ADVISORY remnant — fixed)
- Important: 3 (gate template, feature doc, command list — all fixed)
- Suggestion: 2 (tier field docs, ASK format template — both fixed)

## Futures Promoted

See `.work/workflow-phase-redesign/futures.md` for deferred enhancements from research and spec phases.
