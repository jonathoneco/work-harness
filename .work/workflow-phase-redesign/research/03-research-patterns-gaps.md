# Research Patterns and Gaps

## Questions to Answer

1. How is the research step structured in work-deep? (team creation, topic planning, synthesis)
2. What does the research handoff prompt look like?
3. Is there a pattern for "research-only" tasks that don't need implementation?
4. What does the research/design loop look like in practice — repeated cycles of investigate/design?
5. How would work-research differ from work-deep's research step?
6. What would first-class support for the research/design loop entail?

---

## Findings

### 1. Research Step Structure in work-deep

**Team-based parallel exploration with synthesized handoff:**

The research step executes through a structured team protocol:

- **Team creation**: `TeamCreate("research-{name}")` at step start
- **Topic assignment**: Lead identifies research topics (typically 4-8), creates shared task list with one task per topic
- **Task schema**: Each task contains topic description, target file path, expected format, and specific questions to answer
- **Team execution**: Teammates self-claim tasks from shared list, write findings to assigned files (pattern: `.work/{name}/research/NN-{topic-slug}.md`)
- **Teammate prompts**: Standardized 6-section format with task context, rules (code-quality + work-harness skills), topic-specific instructions
- **Lead synthesis**: Lead does NOT write research findings — teammates do. Lead's role: synthesize, index, generate handoff prompt
- **Completion detection**: Lead polls task list, reads each note, verifies content quality and format compliance

**Example (agent-first-architecture):**
- 6 parallel research topics: architecture, Agent tool API, prior art, opportunity analysis, Agent Teams, model selection
- Each topic assigned to a teammate; all executed in parallel
- Synthesized into index.md and handoff-prompt.md by lead

**Duration**: Flexible — depends on complexity. Typically completes in 1-2 sessions per topic.

### 2. Research Handoff Prompt Structure

**Synthesis artifact produced by the lead after teammates complete.**

Standard structure:

```
# Research Handoff: {Title}

## What This Step Produced
{Summary of coverage, numbers of artifacts, key phase results}

## Key Findings
{Consolidated insights across topics — numbered, actionable}

## Key Artifacts
{File paths to research notes with one-liners}

## Decisions Made
{Numbered decisions made during research}

## Open Questions for {Next Step}
{Items the next step must address}

## Instructions for {Next Step}
{Numbered, step-specific guidance}
```

**Key pattern**: References file paths to research notes rather than copying content inline. This preserves context separation between steps and allows lead to present handoff without replicating findings.

**Critical functions**:
- Single bridge between research and plan steps
- Surfaces only actionable open questions
- Directs planning with specific instructions
- Consolidates cross-topic implications

**Tool**: Not automatically generated. Synthesized by lead via reading all research notes, identifying patterns, and structuring as handoff.

### 3. Research-Only Task Pattern

**No formal support exists.**

Current state:
- Research is exclusively a step within work-deep (Tier 3)
- Tier 1 (Fix) and Tier 2 (Feature) have no research step
- If a user needs pure research (no implementation), they currently:
  - Create a Tier 3 task and run research step
  - Stop after research and archive (no plan/spec/implement)
  - This works but is awkward — carries forward all Tier 3 infrastructure

**Implicit gaps**:
- No direct "research this topic and produce findings" command
- No clean artifact handoff for research-only outputs (research notes + handoff prompt)
- No natural archive point (research completes, plan not needed)
- No automatic transition to implementation (research-only tasks can't transition forward)

**Design question**: Should research-only be a Tier 1 (assess + research + review) with minimal setup? Or a separate command entirely?

### 4. Research/Design Loop Pattern

**No first-class support; would require design changes.**

Current linear flow:
```
research → plan → spec → decompose → implement → review
```

What repeated loops would look like:
```
research → [design loop: plan ↔ research + revise ↔ plan + refine] → spec → ...
```

**Current workarounds**:
- Research → Plan → (user feedback) → BLOCKED (no re-research mechanism)
- No way to trigger new research after planning begins
- Phase B review can catch missing research, but no automated path to research again
- Users manually run research agents inline if new questions surface during planning

**Why it doesn't exist**:
- Step transitions are linear and unidirectional (no backward movement allowed)
- State machine assumes each step completes once
- Handoff prompts are one-way (research → plan, not bidirectional)
- Review gates happen AFTER each step, not during design iterations

**Implications for W3:**
- Requires either (a) new looping command that alternates research/design, (b) modify step transitions to allow re-entry to research, or (c) formalize inline research pattern

### 5. How work-research Would Differ from work-deep's Research Step

**Hypothetical work-research command characteristics:**

| Aspect | work-deep Research | Hypothetical work-research |
|--------|-------------------|---------------------------|
| **Tier** | Part of Tier 3 | New: probably Tier 1 or distinct |
| **Steps** | assess → research → [plan/spec/...] | assess → research → review (+ archive) |
| **Team creation** | Yes (parallel topics) | Yes (same protocol) |
| **Handoff artifact** | Handoff prompt for plan step | Handoff prompt + findings summary for user |
| **Next step** | Automatic forward to plan | User decides what to do (implementation, more research, etc.) |
| **State management** | Full state.json with 7 steps | Simplified state.json with 3 steps |
| **Review gate** | Phase A/B for plan readiness | Phase A/B for research completeness |
| **Archive trigger** | Automatic after review | User manually triggers after review |
| **Beads integration** | Full epic + stream issues | Simpler: epic + task only, no streams |
| **Output expectation** | Research notes + handoff for planners | Research notes + synthesis + recommendations |

**Key difference**: work-research is **output-final** (research results are the deliverable), while work-deep's research is **forward-feeding** (research results feed into planning).

### 6. First-Class Research/Design Loop Support

**What it would require:**

**1. New command or flow variant:**
- Either `/work-research-loop` or a variant of `/work-deep` that allows re-entry
- State model that permits research → plan → [decision] → research+revise → plan+refine

**2. Conditional step routing:**
- After plan step, allow two outcomes: (a) approve and proceed to spec, or (b) "needs more research" and loop back
- Requires state.json to support step re-entry (currently disallowed)
- Alternative: allow inline research within plan (less structured)

**3. Interaction model for loop decisions:**
- How does user signal "loop back to research"? New approval signal? Feedback on plan?
- When does team teardown happen? Only at final loop exit, or after each research cycle?
- How do research artifacts accumulate across loops? (append to existing notes, or separate per-cycle directories?)

**4. Handoff adaptations:**
- Plan→Research handoff (reverse direction) specifying what needs investigating
- Cycle numbering in artifact paths: `research/cycle-1/`, `research/cycle-2/`?
- Accumulated findings across cycles or per-cycle isolation?

**5. Review timing adjustment:**
- Currently: Phase A/B reviews run after each step
- Looping pattern: Phase B review might run MID-loop (design review during plan) vs after plan completes
- Interaction: Does user review plan and then decide to loop, or does loop happen based on Phase B advisory findings?

**6. Team lifecycle:**
- Current: team destroyed after research completes
- Looping: team persists across cycles, or recreated per cycle?
- Teammate context: do teammates stay assigned to same topics, or re-claim per cycle?

---

## Implications

### For W3 Planning

1. **work-research as new first-class command is justified:**
   - Pure research tasks exist (evidence: W3 itself is research task in isolation)
   - Current workaround (create Tier 3, run research, archive) is awkward
   - Estimated scope: new command file + simplified state schema + beads integration

2. **Research/design loop requires design decision before implementation:**
   - Three viable approaches: (a) looping variant of work-deep, (b) new work-research-loop command, (c) formalize inline research pattern
   - Key constraint: one re-entry mechanism to avoid combinatorial explosion (don't support arbitrary re-entry to any step)
   - Recommended: single back-edge from plan → research only (most common research/design pattern)

3. **Research/design loop requires state model changes:**
   - Current invariant: "each step completes once" must be relaxed
   - Minimum change: allow research step to be re-entered from plan step only
   - Alternative: use `current_step: "research-loop"` to indicate looping context, maintain same artifacts

4. **Handoff patterns are well-established and reusable:**
   - Template in context-seeding.md can be extended
   - Research→Plan handoff exists and works well
   - Reverse (Plan→Research) handoff would follow same pattern

### For Teammates

1. **Context seeding works well; no changes needed:**
   - Standard preamble + task context + skills injection is clear
   - Teammates correctly interpret "write to X only, lead handles index/handoff"
   - Example: agent-first-architecture research had zero context confusion

2. **Topic parallelism scales:**
   - 6 topics ran in parallel without contention
   - File ownership model (each teammate owns one research note) prevents races
   - Task list provides natural coordination surface

---

## Open Questions for Planning

1. **work-research scope**: Should it be a minimal Tier 1 variant, or more capable variant with phases? Prototype estimate: 3-6 work items?

2. **Research/design loop approach**: Single back-edge (plan → research only)? Full arbitrary re-entry? Separate looping command? Trade-offs between flexibility and complexity?

3. **Loop state representation**: Use step re-entry in state.json, or introduce loop counters/cycle markers? Keep artifact structure flat or nest by cycle?

4. **Plan→Research handoff**: What should trigger loop decision? (a) user feedback during plan, (b) Phase B review findings, (c) explicit user signal during review?

5. **Team persistence across loops**: Recreate team per cycle, or persist across cycles? Cost vs benefit?

6. **Documentation and user discovery**: How prominent should these new commands/patterns be? Mention in roadmap, skills, or keep exploratory?

7. **Interaction with other W3 items**: How does research/design loop interact with "explore phase clarity" and "plan mode redesign"? (Likely: all three improve research/design loop experience)
