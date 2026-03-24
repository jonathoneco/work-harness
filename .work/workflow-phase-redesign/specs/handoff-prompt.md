# Spec Handoff: W3 Workflow Phase Redesign

## What This Step Produced

9 spec documents (1 cross-cutting contracts + 8 component specs) organized across 3 implementation phases. Each spec defines implementation steps with testable acceptance criteria, interface contracts, file change tables, and testing strategies.

## Spec Index

| Spec | Title | Phase | Files Modified/Created |
|------|-------|-------|----------------------|
| 00 | Cross-cutting contracts | — | _(reference only — defines shared schemas)_ |
| 01 | State schema extensions | 1 | `references/state-conventions.md` |
| 02 | Verdict system redesign | 1 | `phase-review.md`, `step-transition.md` |
| 03 | Approval ceremony tiering | 2 | `step-transition.md`, `work-deep.md`, `work-feature.md` |
| 04 | Explore phase clarity | 2 | `work-deep.md`, `work-feature.md` |
| 05 | Plan agent redesign | 2 | `step-agents.md`, `work-deep.md`, `work-feature.md` |
| 06 | Phase B finding resolution | 2 | `phase-review.md`, `work-deep.md` |
| 07 | work-research command | 3 | `work-research.md` (new), `workflow-meta.md`, `workflow.md` |
| 08 | Adversarial eval improvements | 3 | `adversarial-eval.md` (new), `step-agents.md` |

## Key Design Decisions Resolved During Spec Writing

1. **C01 renamed to "State Schema Extensions"**: DD-7 confirms lifecycle is unchanged; C01 is really about schema documentation for ASK recording, ceremony config, and Tier R — not lifecycle changes.

2. **ASK verdict UX resolved**: Questions presented in a numbered list under `## Questions Before Advancing` heading. Hard stop, no timeout. Max 5 questions per verdict. Responses recorded in gate file `## Resolved Asks` section. No new state.json fields — ASK tracking lives in gate files only.

3. **Risk classification is static**: Risk is determined by transition type (static table), not by task complexity or artifact size. Dynamic risk classification deferred to futures.md.

4. **Explore clarity is a within-step protocol, not a separate step**: Scope validation happens at the START of the research step (T3) or plan step (T2). No new state, no new lifecycle status. Optional — if the agent has no questions, it proceeds directly.

5. **Clarity vs inline research distinction**: Clarity questions go to the *user* (Spec 04). Inline research goes to *Explore subagents* (Spec 05). Ordering: clarity first, then plan agent dispatch with inline research. User-judgment gaps → ASK verdict, not subagents.

6. **Finding resolution criteria**: Immediate resolution requires ALL of: in-scope files, no architectural changes, ≤3 files affected, not a design concern. Max 3 immediate resolutions per transition. >5 deferred findings triggers re-review suggestion.

7. **Tier R has no inter-step review gates**: Lightweight lifecycle — research→synthesize is automatic. No Phase A/B review. No gate files. Follows T2 compaction pattern (recommend, not required).

8. **Adversarial eval Phase 0 is skippable**: User can state "no position" or "skip" and the eval proceeds without anchoring to an initial position.

9. **T2 risk mappings added**: plan→implement is medium (hard stop), implement→review is low (auto-advance). T2 mappings share the risk table with T3.

## Items Deferred from Specs

1. **Dynamic risk classification**: Static risk table works for initial release. Dynamic risk factoring in task complexity, artifact size, and loop-back count deferred to futures.md.
2. **Automated framing selection**: Agent manually selects adversarial eval framing based on decision type. Automatic selection based on decision classification deferred.
3. **Tier R → T2/T3 escalation**: If research reveals implementation need, user starts a new task. Direct escalation from Tier R deferred.

## Instructions for Decompose Step

1. **Read all 8 component specs** — each contains a "Files to Create/Modify" table and "Implementation Steps" with acceptance criteria. These are the inputs for work item creation.

2. **Create work items per implementation step**: Each numbered step in a spec becomes a beads issue. Tag issues with the component ID (e.g., `[C01]`, `[C02]`).

3. **Respect phase ordering**: Phase 1 issues (C01, C02) must complete before Phase 2 issues start. Phase 2 issues (C03-C06) before Phase 3 (C07-C08). Use beads dependencies to enforce.

4. **File conflict awareness**: Several files are modified by multiple specs:
   - `step-transition.md`: Specs 02, 03
   - `phase-review.md`: Specs 02, 06
   - `step-agents.md`: Specs 05, 08
   - `work-deep.md`: Specs 03, 04, 05, 06
   - `work-feature.md`: Specs 03, 04, 05

   Within a phase, order work items so that earlier specs land first for shared files. Across phases this is already handled by phase ordering.

5. **Stream assignment guidance**:
   - Phase 1 is sequential (C01 then C02) — single stream
   - Phase 2 can parallelize: C03+C06 (independent of C04/C05) vs C04 then C05 (dependency chain) — two streams
   - Phase 3 can parallelize: C07 and C08 are independent — two streams
