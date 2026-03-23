# Research Handoff: W3 Workflow Phase Redesign

## What This Step Produced

5 research topics investigated in parallel across current phase behavior, review lifecycle, research patterns, adversarial eval, and prior art. All topics complete with findings, implications, and open questions.

## Key Findings

### 1. Phases are forward-only and lack pushback mechanisms
Current phase sequence (research → plan → spec → decompose → implement → review) is linear and unidirectional. No step can request re-entry to a prior step. Plan agents receive research handoff and proceed without validating completeness or asking clarifying questions. The "lack of pushback" manifests as: no pre-step validation, one-way handoffs, and ADVISORY verdicts that don't force iteration.

**Sources**: `research/01-current-phase-behavior.md` (§Findings, §Pain Points), `research/05-prior-art.md` (§Implications)

### 2. ADVISORY verdicts are ambiguous and underused
Phase B reviews produce PASS/ADVISORY/BLOCKING verdicts. ADVISORY is meant to "log but don't block," but in practice it's unclear whether advisory notes mean "proceed with caution" or "should probably revisit." No distinction between acceptable trade-offs and genuine concerns that should trigger re-work.

**Sources**: `research/01-current-phase-behavior.md` (§Verdict Protocol), `research/02-review-finding-lifecycle.md` (§Finding Categorization)

### 3. Review timing is end-of-step, not end-of-back-and-forth
Phase A/B reviews run at step transitions only. Within a step (e.g., during plan agent's work), there's no mid-step review. Ad-hoc reviews require manual `/work-review` trigger. The approval ceremony is a hard stop that creates a context switch — user must read gate file in editor, provide feedback, return to terminal.

**Sources**: `research/02-review-finding-lifecycle.md` (§Review Timing, §Approval Ceremony)

### 4. No research-only workflow exists
Research is exclusively a step within work-deep (T3). Pure research tasks must create a T3 task, run research, then awkwardly archive without plan/spec/implement. A dedicated `work-research` command would be output-final (research is the deliverable) vs forward-feeding (research feeds planning).

**Sources**: `research/03-research-patterns-gaps.md` (§Research-Only Task Pattern, §How work-research Would Differ)

### 5. Research/design loop requires state model changes
Current invariant: "each step completes once." Looping between research and plan requires relaxing this. Three approaches: (a) allow plan→research back-edge, (b) new looping command, (c) formalize inline research during plan. Recommended: single back-edge from plan→research only.

**Sources**: `research/03-research-patterns-gaps.md` (§Research/Design Loop Pattern, §First-Class Support)

### 6. Adversarial eval framing is too narrow
"Ship It vs Do It Right" works for scope/timing decisions (~70% of cases) but fails for non-deferrable design decisions (API v1 vs v2, build vs buy, paradigm choices). Positions are assigned by the command, not discovered from user context. Missing: Step 0 to elicit actual positions, alternative framings, conditional verdicts.

**Sources**: `research/04-adversarial-eval.md` (§Current Framing, §Alternative Framings, §Flushing Out)

### 7. Solid foundation from W2 — no architectural blockers
W2 (Agent-First Architecture) established agent delegation, 6-section prompt structure, teams protocol, and step agent templates. Context-Lifecycle formalized gate approval ceremonies. W3 builds on these — no need to rebuild the delegation layer.

**Sources**: `research/05-prior-art.md` (§W2, §Harness-Improvements, §Context-Lifecycle)

## Key Artifacts

- `research/01-current-phase-behavior.md` — Phase structure across tiers, prompt dispatch, pain points
- `research/02-review-finding-lifecycle.md` — Phase A/B protocol, finding lifecycle, gate integration
- `research/03-research-patterns-gaps.md` — Research step mechanics, work-research gap, loop patterns
- `research/04-adversarial-eval.md` — Eval structure, framing limitations, improvement directions
- `research/05-prior-art.md` — W2/harness-improvements/context-lifecycle precedents, design gaps

## Decisions Made

1. All 9 W3 work items are confirmed as genuine gaps with evidence from current codebase
2. Research/design loop: recommended approach is single back-edge (plan→research) not arbitrary re-entry
3. work-research: justified as new command (not T3 workaround) — output-final vs forward-feeding
4. Adversarial eval: expansion direction is pluggable framings + Step 0 position elicitation

## Open Questions for Planning

1. **Scope and phasing**: Should all 9 items ship as one initiative, or be phased? Some items are tightly coupled (explore clarity + plan mode redesign + advisory→asks), others are independent (work-research, adversarial eval).

2. **Cross-tier impact**: Most changes target T3 (work-deep). Should explore clarity and plan redesign also apply to T2 (work-feature)? T1 (work-fix) is likely unaffected.

3. **ADVISORY verdict redesign**: Should ADVISORY split into subcategories (e.g., ADVISORY-CONCERN vs ADVISORY-NOTE)? Or should all advisories become direct clarification asks to the user?

4. **Research/design loop trigger**: What triggers a loop-back from plan to research? (a) user feedback, (b) Phase B findings, (c) plan agent self-detects gaps? Need to decide before speccing state model changes.

5. **Approval ceremony weight**: Should low-risk transitions (implement phase N→N+1) get lighter approval? Auto-approve on PASS? Or keep hard stops everywhere for safety?

6. **Adversarial eval integration**: Should adversarial eval be optionally triggerable during plan/spec phases? Or remain a standalone command?

7. **Step re-entry mechanics**: If plan loops back to research, does research step status change from "completed" to "active" again? Or introduce a new "re-entered" status? How do cycle artifacts accumulate?

## Instructions for Planning

1. Read this handoff and the research artifacts listed above (reference file paths, don't copy inline)
2. Group the 9 work items into implementation phases based on coupling and dependencies
3. For each phase, identify which command/skill files need modification
4. Address the 7 open questions above — each needs a design decision before spec
5. Consider which changes are T3-only vs cross-tier
6. Produce architecture.md with component design, dependency order, and scope exclusions
