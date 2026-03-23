# W3 Prior Art: Closed Issues & Design Decisions

**Research Date**: 2026-03-23
**Scope**: Closed beads issues, git history, and architecture documentation for W3: Workflow Phase Redesign
**Investigator**: research-prior-art-investigator

---

## Questions Guiding W3

W3 Workflow Phase Redesign targets 9 major work items across 3 dimensions:
1. **Explore Phase**: Build clarity — nail down intention, push back, ask questions before planning
2. **Plan Mode**: Pointed design questions with options, ability to expand (Claude-inspired)
3. **Review & Timing**: Phase-aware review (Phase A ≠ Phase B); only at end of back-and-forth, not mid-conversation
4. **Question Handling**: Open questions tackled immediately when possible, not deferred
5. **Finding Resolution**: Aggressive Phase B handling — resolve immediately unless design concern
6. **Advisory Notes**: Convert to direct clarification asks instead of annotations
7. **Research Path**: Dedicated `work-research` command for pure research tasks
8. **Research/Design Loop**: Formal support for repeated research/design workflow pattern
9. **Adversarial Eval**: Improved perspective flushing into argued positions

---

## Findings from Closed Issues & Architecture

### W2: Agent-First Architecture (Closed Epic work-harness-ihi)

**Status**: Archived 2026-03-23 | **Findings**: 14 (all fixed)

**What it established**:
- Shifted execution from inline (lead bottleneck) to delegated agents with proper context seeding
- Introduced **6-section agent prompt structure**: Identity, Task Context, Rules, Instructions, Output Expectations, Completion
- Formalized **step agent templates** for plan, spec, decompose phases (step-agents.md)
- Introduced **Agent Teams integration** for parallel research step execution (teams-protocol.md)
- Established `/delegate` command for ad-hoc agent routing via keyword-based inference

**Key Decision Pattern**: "Draft-and-present" — agents produce artifacts, lead presents to user (not inline review)

**Implications for W3**:
- Foundation exists for delegating phases to specialized agents
- Teams already enable parallel research workstreams
- Prompt structure is well-defined; W3 can refine *which* phases need design rethinking, not rebuild the delegation layer

---

### Harness-Improvements (Closed Epic work-harness-65t)

**Status**: Archived 2026-03-18 | **Findings**: 5 (all fixed)

**What it uncovered about current phase design**:
- C4: **Gate Protocol** — File-based review UX with gate files; revealed mid-phase review timing issues
- C2: **Code Quality Enhancement** — Parallel review pattern; identified need for phased review guidance
- C5: **Research Protocol** — Research agents self-write notes; lead synthesizes handoff only (pattern: avoid mid-phase consolidation)
- **C8 Gate**: Discovered `skills:` field verification as blocker for phase-level agent/skill routing

**Review Findings Fixed**:
- Plan agent template assumes research handoff exists → breaks Tier 2
- Decompose agent template missing bash code fencing (minor)
- Review section had incomplete guidance on phase transitions

**Implications for W3**:
- Phase-aware guidance is incomplete across tiers
- Review timing is a real problem: happens mid-conversation, not end of back-and-forth
- Phase A (plan) and Phase B (implement) have different review needs, not currently distinguished
- Skills routing per phase wasn't fully realized; W3 may need to complete this work

---

### Context-Lifecycle (Closed Epic rag-hc9ou)

**Status**: Archived | **What it solved**:
- Self-re-invocation at step gates for instruction fidelity (guards against staleness)
- PostCompact hook for mechanical re-grounding after context compaction
- **C5: Gate Approval Re-Confirmation** — Explicit approval signals after presenting results (not implicit)

**Key insight**: "Explicit approval signals — results and state updates never in same turn" prevents hidden phase transitions

**Implications for W3**:
- Phase transitions are formally gated with approval, not automatic
- Question handling (W3 goal) could benefit from explicit question-resolution signals vs. advisory notes
- Phase design should respect the gate-approval pattern established in Context-Lifecycle

---

### Historical W1 and W2 Gate Issues

**Closed issues referencing review and phase logic**:
- `work-harness-5ts` [P1 bug]: "Plan agent template assumes research handoff exists" — breaks Tier 2
  - Root cause: Phase dependency not flexible (T3 research → plan, but T2 jumps plan)
- `work-harness-6y8` [P1 bug]: Teams protocol teammate prompt had wrong section count (7 vs 6)
  - Indicates phase-specific prompts need careful tuning

**Closed issues on review**:
- 10+ issues tagged [Review] from harness-improvements and agent-first-architecture
- Pattern: Review findings are batch-fixed, not handled mid-phase
- Suggests current review timing is "end of initiative," not "end of each phase"

---

## Architecture Decision Precedents

### Current Phase Structure (Tier 3: work-deep.md)

Steps in execution order: `assess → research → plan → spec → decompose → implement → review`

**Current characteristics**:
- Linear sequence; plan assumes research is complete and handed off
- Review happens once at the end, after all implementation
- Agent spawning per step (parallel only within research via Teams)
- One-size-fits-all review guidance (no phase-specific advice)

### Current Skill Injection Pattern

Three-layer system (from work-deep.md):
1. Step Agent Dispatcher — routes phase + context to specialized agents
2. Context Seeding Protocol — 6-section prompts with managed docs
3. Skill Matrix — code-quality + work-harness skills per phase

**Gap W3 addresses**: No phase-aware review guidance; no plan-phase design questions template

---

## Implications for W3 Design

### 1. **Explore Phase Clarity**
- **Prior art**: Research agents already have structured protocol (teams-protocol.md)
- **Gap**: Explore phase doesn't exist as a formal phase in T2/T3 workflows; rethinking needed on when exploration is appropriate
- **Decision needed**: Is explore a standalone phase (new) or baked into research?

### 2. **Plan Mode Design (Claude Inspiration)**
- **Prior art**: None. Current plan phase produces a plan document, no interactive options/expansion
- **Gap**: No design questions; no "here are 3 approaches, which interests you?" capability
- **Decision needed**: Should plan-phase agent prompt include design question templates + option generation?

### 3. **Phase-Aware Review**
- **Prior art**: Review happens once, uses generic `code-quality` skill
- **Gap**: No distinction between Phase A (design/spec review) and Phase B (implementation review)
- **Decision needed**: Create separate review agents/skills for spec-review vs. implementation-review?

### 4. **Review Timing**
- **Prior art**: Gate approval exists (explicit approval after presenting results)
- **Gap**: Current practice is end-of-initiative review; mid-phase review happens informally
- **Decision needed**: Should every phase end with a gate+review cycle, not just the final review?

### 5. **Open Question Handling**
- **Prior art**: Advisory notes in review findings (from harness-improvements research); context-lifecycle established explicit approval patterns
- **Gap**: Questions in findings are annotations, not resolution triggers
- **Decision needed**: Convert findings questions to direct clarification asks in the phase prompt?

### 6. **Finding Resolution (Phase B)**
- **Prior art**: Review findings are collected end-of-phase; harness-improvements showed batch fixing
- **Gap**: No guidance on "handle immediately unless design concern"
- **Decision needed**: Should implement phase check findings against deploy-blocking criteria?

### 7. **Research-First Paths**
- **Prior art**: W2 established parallel research via Agent Teams
- **Gap**: No `work-research` command; pure research tasks get routed through T1/T2/T3 general workflow
- **Decision needed**: New T0 tier for pure research? Or add optional research-only mode to existing commands?

### 8. **First-Class Research/Design Loop**
- **Prior art**: Research → Plan → Spec sequence exists in T3, but can't cycle back
- **Gap**: If research discovers design issues, must restart plan (no loop)
- **Decision needed**: Allow research/plan phases to cycle back to research if needed?

### 9. **Adversarial Eval Improvements**
- **Prior art**: Adversarial-eval skill/command exists (from `/work-deep` optional steps)
- **Gap**: Not integrated into standard workflow; hard to invoke perspective-flushing
- **Decision needed**: Should certain phases (plan, spec) spawn adversarial eval to test assumptions?

---

## Open Questions Requiring Planning Phase Input

1. **Scope**: Are all 9 W3 items in-scope for this initiative, or phased across multiple initiatives?
2. **Tier 1/2 Impact**: Current changes are all Tier 3 (work-deep). Should `work-feature` and `work-fix` also be rethought?
3. **Backwards Compatibility**: If plan mode changes, do existing task workflows (in progress) resume with old or new behavior?
4. **Agent Skill Coverage**: Do new phase distinctions require new skills/agents, or can existing agents adapt?
5. **Review Agent Specialization**: Should there be dedicated spec-review, impl-review, and research-review agents, or one polymorphic agent?
6. **Gate Behavior**: Should every phase gate include a review, or only certain phases (plan, impl)?
7. **Adversarial Eval Trigger**: Auto-trigger on certain phases, or user-initiated via command?
8. **Research-Only Command Scope**: Should `work-research` be a new T0 tier, or a flag on existing commands?
9. **Cycles & Backtracking**: Should research/plan/spec phases allow cycling back, or remain linear?
10. **Deprecated Features**: If plan mode changes, what happens to existing explore/plan/review structure? Sunset or parallel support?

---

## Conclusion

**Solid Foundation**: W2 and Harness-Improvements established agent delegation, phase routing, and gate approval patterns. Context-Lifecycle formalized approval ceremonies.

**Known Gaps**:
- Plan phase lacks design question generation and option exploration
- Review is one-size-fits-all, not phase-aware
- Review timing is end-of-initiative, not end-of-phase
- No dedicated research-only workflow
- Phase sequences don't allow cycling (research → plan → spec is linear, can't loop back)

**Ready for Planning**: All 9 W3 items have clear prior art to build on. No blocking architectural holes. Planning phase should address tier-scoping and agent/skill design questions above.
