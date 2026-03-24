# Architecture: W3 Workflow Phase Redesign

## Problem Statement

The work harness's phase system is forward-only and lacks mechanisms for pushback, clarification, or iteration. Research agents cannot ask follow-up questions. Plan agents proceed without validating research completeness. ADVISORY verdicts are ambiguous — they neither block progress nor elicit user clarification. Reviews run only at step boundaries, creating ceremony overhead for low-risk transitions. There is no research-only workflow, forcing pure research tasks into an awkward T3 lifecycle. The adversarial eval framing covers scope/timing decisions well but fails for non-deferrable design choices.

These gaps compound: forward-only phases mean mistakes propagate unchecked, ambiguous advisories mean concerns are logged but never resolved, and missing research-first paths mean the harness cannot support all work patterns.

**Why now**: W2 (Agent-First Architecture) established the delegation layer, teams protocol, and step agent templates that make these improvements feasible. The infrastructure is in place; the workflow logic needs to catch up.

## Goals

1. Add pushback and clarification mechanisms so agents can request information before proceeding
2. Replace ambiguous ADVISORY verdicts with direct clarification asks that require user response
3. Support a research/design loop so plan agents can trigger targeted re-research
4. Create a `work-research` command for standalone research tasks
5. Enable Phase B findings to be resolved immediately during implementation (not deferred to review)
6. Improve adversarial eval with pluggable framings and position elicitation
7. Right-size approval ceremonies — lighter gates for low-risk transitions

**Non-goals**:

- Changing the tier system (T1/T2/T3 remain as-is)
- Rewriting the teams protocol or agent delegation layer (W2 output, stable)
- Implementing phase-specific review agents (future enhancement, tracked in futures.md)
- Adding real-time mid-step review (review remains at step boundaries, but boundaries become smarter)
- Automated finding auto-expiry based on git diff analysis

## Design Decisions

### DD-1: Scope and phasing — all 9 items ship as one initiative, grouped into 3 implementation phases

**Decision**: Ship all 9 work items as a single W3 initiative, organized into 3 phases by dependency coupling.

**Rationale**: The 9 items cluster into 3 natural groups: (a) foundational state model changes that enable everything else (step re-entry, advisory redesign), (b) workflow mechanics that build on those foundations (explore clarity, plan redesign, finding resolution, review timing), (c) new capabilities (work-research, research/design loop, adversarial eval). Splitting into separate initiatives would create cross-initiative dependencies and require coordinating state model changes across multiple .work/ directories. Phasing within one initiative is cleaner.

**Mechanism**: Phase 1 changes the state model and verdict system. Phase 2 uses the new state model to implement workflow improvements. Phase 3 adds new standalone capabilities. Each phase has a gate review before the next begins.

### DD-2: Cross-tier impact — explore clarity and plan redesign apply to T2 and T3; T1 unaffected

**Decision**: Explore clarity (pre-plan pushback) applies to T2 (`work-feature`) and T3 (`work-deep`). Plan mode redesign applies to both tiers. T1 (`work-fix`) is unaffected — it has no plan step.

**Rationale**: T2 already dispatches plan agents and would benefit from the same clarification mechanisms. The additional complexity is minimal — the plan agent template is shared via `step-agents.md`. T1 is assess-implement-review with no plan or research step, so none of these changes apply.

**Mechanism**: Modifications to `step-agents.md` (plan agent template) automatically propagate to both T2 and T3 dispatchers. Command-level changes (`work-feature.md`, `work-deep.md`) handle tier-specific differences in the plan step sections. In T3, explore clarity happens before the research step (pushback on research scope). In T2, explore clarity happens at the start of the plan step (pushback on task understanding before planning begins).

### DD-3: ADVISORY verdict redesign — replace ADVISORY with ASK verdict that requires user response

**Decision**: Eliminate the ADVISORY verdict category. Replace with ASK — a verdict that presents a specific question to the user and blocks until answered. The answer is recorded in the gate file.

**Rationale**: ADVISORY's problem is ambiguity: "log but don't block" means concerns are noted but never resolved. Splitting into subcategories (ADVISORY-CONCERN vs ADVISORY-NOTE) adds complexity without solving the root problem. Converting all advisories to direct asks forces resolution at the point of discovery. The user either addresses the concern or explicitly acknowledges it, either way producing a decision record.

**Mechanism**: Phase review produces three verdict types: PASS, ASK (with specific questions), BLOCKING. When Phase B returns ASK, the transition protocol presents the questions to the user before the approval ceremony. The user's responses are recorded in the gate file's "Resolved Asks" section. Only then does the approval prompt appear. This adds one interaction round to transitions that surface concerns but eliminates the ambiguity of unresolved advisories. The phase-review skill and step-transition skill are both updated.

### DD-4: Research gaps during planning — empower the plan agent with inline research capability

**Decision**: Instead of formal loopback machinery between plan and research steps, give the plan agent the ability to spawn capped Explore subagents when it encounters gaps in the research handoff. No state changes, no re-entry, no cycle management — just an empowered agent with permission to investigate.

**Rationale**: A structured adversarial debate evaluated three alternatives: (a) merging research+plan into a single "explore" step with internal modes, (b) keeping separate steps but empowering the plan agent with inline research, (c) adaptive routing based on design_novelty scores. All three converged on the same functional core — a plan agent with Explore subagent capability — differing only on gate placement and ceremony. The formal loopback (plan→research back-edge with re-entry status, cycle directories, loop counters) adds state machine complexity for something the plan agent can handle with a few targeted subagent calls. The research→plan gate already provides context distillation; the plan agent fills the last 10-20% of gaps that only become visible during the act of planning.

**Mechanism**: The plan agent template in `step-agents.md` gains one instruction: "If you encounter gaps in the research handoff, you may spawn up to 3 Explore subagents with targeted questions. Each subagent returns a summary (max 1,500 tokens). Incorporate findings into your architecture document." No new completion signals, no state transitions, no dispatcher changes. If research was fundamentally insufficient, this surfaces naturally in plan quality — the plan→spec gate catches it.

### DD-5: Approval ceremony weight — auto-advance on PASS for low-risk transitions; hard stop for others

**Decision**: Introduce a `risk_level` attribute on step transitions. Low-risk transitions (PASS verdict, no ASK items) auto-advance with a notification. Medium/high-risk transitions retain the hard stop approval ceremony.

**Rationale**: Keeping hard stops everywhere creates ceremony fatigue — users approve transitions reflexively rather than reviewing carefully. But removing all stops loses the safety net for genuinely important transitions. Tiered ceremony weight matches the actual risk.

**Mechanism**: Risk is determined by two factors: (1) transition type (research→plan is lower risk than spec→decompose), (2) verdict (PASS is lower risk than ASK). The step-transition skill gains a risk classification table:

| Transition              | Base Risk |
| ----------------------- | --------- |
| research → plan         | high      |
| plan → spec             | high      |
| spec → decompose        | medium    |
| decompose → implement   | medium    |
| implement phase N → N+1 | low       |
| implement → review      | low       |

Early transitions are high-risk because mistakes in research and planning propagate through every downstream step. Late transitions are low-risk because solid plans and validation hooks put implementation on rails.

If verdict is PASS and base risk is low: auto-advance with notification ("Advancing to next phase — validation passed"). If verdict is ASK or base risk is medium+: hard stop. BLOCKING always requires fix + hard stop. The user can override with a `ceremony: always` setting in `harness.yaml` to force hard stops everywhere.

### DD-6: Adversarial eval integration — optionally triggerable during plan and spec phases

**Decision**: Adversarial eval becomes an optional tool that the plan and spec agents can invoke when facing non-trivial design decisions. It is not a standalone step or mandatory gate.

**Rationale**: Making adversarial eval a mandatory step adds weight to every initiative regardless of whether design trade-offs exist. Making it entirely standalone means it is disconnected from the workflow where decisions happen. Optional invocation during plan/spec phases means it activates when needed — at the point where design decisions are being made.

**Mechanism**: A new `adversarial-eval` skill describes the protocol. Plan and spec agents receive it via skill injection. When the agent identifies a design decision with meaningful trade-offs, it can spawn an adversarial eval sub-process. The eval produces a recommendation that the agent incorporates into its design decision. The skill supports pluggable framings beyond "Ship It vs Do It Right" — each framing is a named template (e.g., `build-vs-buy`, `api-versioning`, `paradigm-choice`). A Step 0 position elicitation phase asks the user for their initial position before the eval begins.

### DD-7: Step lifecycle remains unchanged — no re-entry mechanics needed

**Decision**: The step lifecycle stays as-is: `not_started → active → completed`. No `re-entered` status, no `loop_count`, no cycle directories.

**Rationale**: DD-4's decision to empower the plan agent with inline research eliminates the need for step re-entry. Research gaps are filled in-flow during planning rather than by rewinding to a prior step. This keeps the state model simple and the step lifecycle linear — each step completes once.

## Component Map

| ID  | Component                     | Scope  | Files                                                                                                                                                                     | Dependencies  |
| --- | ----------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| C01 | Step Lifecycle Extension      | Small  | `claude/skills/work-harness/references/state-conventions.md`                                                                                                              | None          |
| C02 | Verdict System Redesign       | Medium | `claude/skills/work-harness/phase-review.md`, `claude/skills/work-harness/step-transition.md`                                                                             | C01           |
| C03 | Approval Ceremony Tiering     | Medium | `claude/skills/work-harness/step-transition.md`, `claude/commands/work-deep.md`, `claude/commands/work-feature.md`                                                        | C02           |
| C04 | Explore Phase Clarity         | Medium | `claude/commands/work-deep.md` (research step section), `claude/commands/work-feature.md` (plan step section)                                                             | C02           |
| C05 | Plan Agent Redesign           | Small  | `claude/skills/work-harness/step-agents.md` (plan template), `claude/commands/work-deep.md` (plan step section), `claude/commands/work-feature.md` (plan step section)    | C02, C04      |
| C06 | Phase B Finding Resolution    | Small  | `claude/commands/work-deep.md` (implement step section), `claude/skills/work-harness/phase-review.md`                                                                     | C02           |
| C07 | work-research Command         | Medium | `claude/commands/work-research.md` (new), `claude/skills/work-harness/references/state-conventions.md`, `claude/skills/workflow-meta.md`                                  | C01, C04      |
| C08 | Adversarial Eval Improvements | Medium | `claude/skills/adversarial-eval.md` (new), `claude/skills/work-harness/step-agents.md` (plan + spec templates)                                                            | C05           |

## Data Flow Diagrams

### Current Phase Flow (Linear)

```
research ──► plan ──► spec ──► decompose ──► implement ──► review
    │          │        │          │              │           │
    ▼          ▼        ▼          ▼              ▼           ▼
 handoff    handoff  handoff   handoff       phase-gate    findings
 prompt     prompt   prompt    prompt        per phase     .jsonl
```

### Redesigned Phase Flow (With Asks and Inline Research)

```
research ──► plan ──► spec ──► decompose ──► implement ──► review
    │          │        │          │              │           │
    ▼          ▼        ▼          ▼              ▼           ▼
 handoff    handoff  handoff    handoff       phase-gate   findings
 prompt     prompt   prompt     prompt        per phase    .jsonl
    │          │
    │          ├── [inline Explore subagents] ──► fill gaps
    │          │
    │          ├── [ASK] ──► user response ──► gate file
    │          │
    │          └── [adversarial-eval] ──► recommendation
    │
    └── [explore clarity] ──► pushback questions ──► user response
```

### Verdict Flow (Redesigned)

```
Phase A (artifact validation)
    │
    ├── PASS ──► Phase B
    ├── BLOCKING ──► fix ──► retry Phase A
    └── ASK ──► user response ──► Phase B
                                      │
Phase B (quality review)              │
    │                                 │
    ├── PASS + low-risk ──► auto-advance (notify)
    ├── PASS + medium/high-risk ──► approval ceremony (hard stop)
    ├── ASK ──► user response ──► record in gate ──► approval ceremony
    └── BLOCKING ──► fix ──► retry Phase B (max 2)
                                      │
                                      └── still BLOCKING ──► escalate to user
```

### work-research Flow (New)

```
/work-research <topic>
    │
    ▼
assess (Tier R) ──► research ──► synthesize ──► archive
    │                   │             │
    ▼                   ▼             ▼
 state.json        research/      research/
 (tier: "R")       notes.md       deliverable.md
                                  (output-final)
```

## Phased Implementation

### Phase 1: Foundation (C01, C02) — State model and verdict system

**Components**: C01 (Step Lifecycle Extension), C02 (Verdict System Redesign)

**Rationale**: Every other component depends on either the updated state conventions or the new verdict system (ASK replacing ADVISORY). These must land first.

**Changes**:

- C01: Update `state-conventions.md` with any new fields needed for ASK verdict recording and ceremony tiering. Step lifecycle remains `not_started → active → completed` (no re-entry).
- C02: Replace ADVISORY with ASK in `phase-review.md`. Update verdict protocol: ASK requires user response before approval. Update `step-transition.md` to handle ASK verdict presentation and response recording.

**Dependency**: None (foundation).

### Phase 2: Workflow Mechanics (C03, C04, C05, C06) — Ceremony, explore, plan, findings

**Components**: C03 (Approval Ceremony Tiering), C04 (Explore Phase Clarity), C05 (Plan Agent Redesign), C06 (Phase B Finding Resolution)

**Rationale**: These components implement the core workflow improvements that depend on the Phase 1 foundations. C03 uses the new verdict types. C04 adds explore clarity. C05 adds inline research capability to the plan agent. C06 uses the new verdict system.

**Internal ordering**:

- C03 can proceed in parallel with C04 (independent file sets except `step-transition.md` overlap — C03 modifies the approval ceremony section, C04 modifies the research step section of `work-deep.md`)
- C05 depends on C04 (plan pushback builds on explore clarity patterns)
- C06 depends on C02 (uses ASK verdict mechanics for immediate finding resolution)

**Changes**:

- C03: Add risk classification table to `step-transition.md`. Update `work-deep.md` and `work-feature.md` transition sections to use risk-based ceremony.
- C04: Add pre-research clarification protocol to `work-deep.md` research step. Explore agent can emit pushback questions before proceeding.
- C05: Update plan agent template in `step-agents.md` to add inline Explore subagent capability (up to 3 capped subagents for gap-filling). Update plan step sections in `work-deep.md` and `work-feature.md`.
- C06: Update implement step section in `work-deep.md` to resolve Phase B findings immediately when possible. Update `phase-review.md` with immediate-resolution protocol for implementation phases.

### Phase 3: New Capabilities (C07, C08) — Research command, adversarial eval

**Components**: C07 (work-research Command), C08 (Adversarial Eval Improvements)

**Rationale**: These are new standalone capabilities that build on the Phase 1+2 foundations. C07 creates a new command file. C08 creates a new skill file. Both are independent of each other.

**Internal ordering**:

- C07 depends on C01 (state model for research-only tier) and C04 (explore clarity patterns)
- C08 depends on C05 (plan agent template modifications for skill injection)
- C07 and C08 are independent of each other

**Changes**:

- C07: Create `work-research.md` command. Define Tier R (research-only) steps: assess, research, synthesize. Update `workflow-meta.md` and command reference table.
- C08: Create `adversarial-eval.md` skill with pluggable framings and Step 0 elicitation. Update plan and spec agent templates in `step-agents.md` to include adversarial-eval skill injection.

## Scope Exclusions

1. **No changes to the tier system**: T1/T2/T3 classification, scoring formula, and escalation mechanics remain unchanged. The new Tier R for work-research is an addition, not a modification.
2. **No changes to the teams protocol**: Agent delegation, task schema, teammate prompts, and completion detection (W2 output) are stable and not modified.
3. **No mid-step real-time review**: Reviews remain at step boundaries. The improvement is smarter boundaries (ASK instead of ADVISORY, immediate finding resolution), not continuous review.
4. **No finding auto-expiry**: Findings remain manually managed. Auto-expiry based on git diff analysis is a future enhancement.
5. **No phase-specific review agents**: Review agents remain generic. Specialized spec-review vs impl-review agents are a future enhancement.
6. **No dispatch routing by domain**: Agent routing remains skill-based, not domain-based.
7. **No conditional verdicts**: Verdicts remain categorical (PASS/ASK/BLOCKING). "MVP if X, DEFER if Y" verdicts are a future enhancement.
8. **No changes to T1 (work-fix)**: T1 has no plan, research, or review ceremony — none of the W3 improvements apply.

## Deferred to Spec

1. **ASK verdict UX**: Exact format for presenting ASK questions to the user. How are multi-question ASK verdicts presented? One at a time or batched? How is the response recorded in gate files?
2. **Explore clarity protocol**: Exact pushback mechanism. Does the explore agent produce a structured questionnaire? How are answers fed back into the research scope?
3. **work-research state model**: Exact steps for Tier R. Does it reuse the existing state.json schema or need new fields? How does synthesize differ from a normal handoff?
4. **Adversarial eval framing registry**: How are framings registered and selected? Is the selection automatic (based on decision type) or manual (user/agent chooses)?
5. **Risk classification tuning**: The risk table in DD-5 uses static assignments. Should risk be dynamic based on task complexity or artifact size? How does `ceremony: always` interact with auto-advance notifications?
6. **Finding resolution boundary**: Which Phase B findings can be resolved immediately vs which must go through a full re-review cycle? What is the criteria for "resolve immediately"?
7. **Plan agent inline research bounds**: Exact constraints on Explore subagent spawning during planning — token caps, scope limits, how inline findings are incorporated into the architecture document.
