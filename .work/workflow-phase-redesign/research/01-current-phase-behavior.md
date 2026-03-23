# Current Phase Behavior Research

## Questions Investigated

1. **Phase Structure**: How do explore/plan/implement/review phases differ across tier levels?
2. **User Interaction**: Where is user involvement in each phase, and when are decisions made?
3. **Pushback Mechanisms**: When and how do phases push back on assumptions or request clarification?
4. **Dispatch & Prompting**: Which phases are dispatched to agents vs inline? What prompts drive them?
5. **Pain Points**: Where are the identified gaps—lack of pushback, no pre-plan questions, advisory notes?

---

## Findings

### Phase Structure Across Tiers

**Tier 1 (work-fix)**: assess → implement → review
- 3 steps, highly linear
- No research or planning phase
- Implementation is inline (no dispatch)
- Review is inline mini-review (lightweight anti-pattern check, not /work-review)

**Tier 2 (work-feature)**: assess → plan → implement → review
- 4 steps
- Plan is dispatched to general-purpose agent
- Implement is inline
- Review delegates to /work-review (optional, not mandatory)

**Tier 3 (work-deep)**: assess → research → plan → spec → decompose → implement → review
- 7 steps
- Research is dispatched to Explore agent
- Plan/spec/decompose are dispatched to general-purpose agents
- Implement spawns parallel subagents per stream
- Review is mandatory, delegates to /work-review
- Each transition includes Phase A (artifact validation) + Phase B (quality review)

---

### Prompts and Dispatch Mechanisms

**Research Step (T3 only)**
- Dispatched to Explore agent (read-only)
- No fixed prompt template—lead agent plans research topics, creates team, monitors
- Teammates self-claim topics from shared task list
- Output: research notes indexed in research/index.md + handoff-prompt.md
- **Pain Point**: No mechanism for research to surface incomplete coverage before planning starts

**Plan Step (T2 & T3)**
- Dispatched to general-purpose agent
- **Prompt template**: Fixed template in step-agents.md
  - Identity: "Create an architecture document"
  - Input: Read research handoff (T3) or task description (T2)
  - Output: architecture.md + plan/handoff-prompt.md
- **No clarifying questions**: Plan template does not ask agent to validate assumptions or request more research
- **No explicit pushback**: If findings are incomplete, plan proceeds anyway (Phase B review *might* catch it, but not guaranteed)
- **Decision flow**: Open questions from research → design decisions in architecture (no back-and-forth)

**Spec Step (T3 only)**
- Dispatched to general-purpose agent
- **Prompt template**: Fixed template in step-agents.md
  - Input: plan/handoff-prompt.md + architecture.md
  - Output: component specs (00-cross-cutting + NN-<slug>) + spec/index.md + spec/handoff-prompt.md
- **No clarifying questions**: Spec template assumes plan is complete; no mechanism to request plan clarification
- **Phase ordering**: Specs follow plan dependency order without validating order correctness

**Decompose Step (T3 only)**
- Dispatched to general-purpose agent
- **Prompt template**: Fixed template in step-agents.md
  - Input: spec/handoff-prompt.md + all spec files
  - Output: beads issues (with spec references) + stream docs + streams/manifest.jsonl + streams/handoff-prompt.md
- **No validation of implementation feasibility**: Decompose groups work into streams but doesn't validate if streams are actually parallelizable

**Implement Step (T1, T2, T3)**
- T1: Inline (lead agent)
- T2: Inline (lead agent)
- T3: Parallel subagents per stream
  - Subagent prompt includes 6-section structure with Identity + Task Context + Rules + Instructions + Output Expectations + Completion
  - Each stream gets a `.work/<name>/streams/<letter>.md` doc with YAML frontmatter (stream, phase, isolation, agent_type, skills, scope_estimate, file_ownership)
  - Streams execute in phase order; within phase, subagents spawn in parallel
- **Within-phase gating**: Phase A (file ownership validation) + Phase B (spec compliance) after each phase completes
- **No cross-phase feedback loop**: If a stream's implementation reveals issues with a dependency, only BLOCKING findings stop progress

**Review Step (T1, T2, T3)**
- T1: Inline mini-review (lightweight anti-pattern check)
- T2: Delegates to /work-review (optional)
- T3: Mandatory /work-review (spawns 9+ specialist agents)
- Findings stored in `.work/<name>/review/findings.jsonl` (append-only)
- Verdicts: OPEN, FIXED, PARTIAL, NEW
- Finding severity: critical, important, suggestion

---

### Phase Review Protocol (Two-Phase Quality Gate)

**Phase A — Artifact Validation**
- Spawns Explore agent (read-only)
- Validates structural completeness: "Did you produce what you said?"
- Checklist items are step-specific (remains in command definitions, not reusable)
- Verdict: PASS, ADVISORY, BLOCKING
- **Scope**: Structural only (files exist, naming conventions, indexing)

**Phase B — Quality Review**
- Spawns step-appropriate agent (Plan agent for design steps, Review agent for implement)
- Evaluates substance: "Is what you produced good enough?"
- Checklist items are step-specific
- Verdict: PASS, ADVISORY, BLOCKING
- **Retry logic**: Max 2 re-review attempts on BLOCKING; after 2 failures, escalate to user
- **Does NOT automatically request more work**: ADVISORY verdicts log notes but don't force iteration

**Verdict Handling**
- PASS: Present results, proceed to approval ceremony
- ADVISORY: Include full notes in transition summary, proceed to approval ceremony
  - **Pain Point**: Advisory verdicts don't block, but also don't trigger re-planning or additional investigation
- BLOCKING: Report findings, fix issues, re-run Phase B (max 2 attempts)

---

### User Interaction and Pushback Points

**Work-Fix (T1)**
- User invokes /work-fix
- Assess runs (3-factor depth score) — if score >= 2, presents mismatch but user decides final tier
- Implement runs inline (no agent dispatch, no user input during work)
- Review runs inline (no formal gate)
- **Pushback**: Minimal. Only at tier mismatch.

**Work-Feature (T2)**
- User invokes /work-feature
- Assess runs — if score >= 2, presents mismatch, user decides
- Plan dispatches to agent (user reviews artifacts, or says "proceed")
- If user has feedback: construct re-spawn prompt with "Previous Attempt" section, re-spawn agent (max 2 re-spawns before asking user how to proceed)
- **Pushback**: User can request re-planning, but no mechanism for plan agent to ask clarifying questions before writing plan
- **Decision point**: After plan, user approves before implementing
- Implement runs inline
- Review delegates to /work-review (optional)

**Work-Deep (T3)**
- User invokes /work-deep
- Assess runs — if score >= 4, confirms Tier 3
- Research dispatches team (lead monitors completion, reads findings, synthesizes handoff)
- After research, Phase A + Phase B reviews run automatically
- **Pushback**: Phase B review might surface incomplete findings, but ADVISORY verdicts don't force iteration
- User approves research results before plan starts
- Plan dispatches agent (user reviews, or says "proceed")
- User feedback → re-spawn (max 2 re-spawns)
- **Pain Point**: "No questions before planning" — plan agent doesn't ask clarifying questions; it assumes research is complete
- Phase A + Phase B reviews run automatically after plan
- User approves plan results before spec
- Spec, decompose, implement follow same pattern
- **Within-implement**: Phase A + Phase B reviews after each implementation phase

---

### Handoff Prompts and Context Boundaries

**Handoff Contract**
- Each step writes a handoff-prompt.md for the next step
- Handoff is the "firewall" — next step reads handoff, NOT raw notes
- Handoff includes: what step produced, summary of findings/decisions, items deferred, instructions for next step
- **Example flow**: research/handoff-prompt.md references research note file paths but doesn't copy findings inline
- **Effect**: Prevents context bloat but limits ability to revisit assumptions or re-examine evidence

**No Feedback Loop**
- Once a handoff is written, there's no mechanism for the next step to request more investigation
- If plan agent reads research/handoff-prompt.md and finds gaps, plan proceeds anyway (relying on Phase B review to catch it)
- If Phase B review finds issues, blocking verdict forces a fix, but not additional research

---

### Skill Injection and Agent Prompting

**Fixed Prompt Templates**
- Plan agent template: fixed in step-agents.md
- Spec agent template: fixed in step-agents.md
- Decompose agent template: fixed in step-agents.md
- Skills injected via explicit Read instructions (not YAML frontmatter, which doesn't support skills:)

**Missing Scaffolding**
- No built-in mechanism for agents to ask clarifying questions
- No "checklist of unknowns" that agents must resolve before proceeding
- Agents are expected to self-direct (e.g., "open questions from research → design decisions") without structured input validation

---

### Verdict Escalation and Blocking

**Phase B Retry Logic**
- BLOCKING verdicts trigger up to 2 re-review attempts
- If still BLOCKING after 2 attempts, escalate to user
- **No escalation within a step**: Only escalation is to user, not to lead agent with instructions to fix and re-check

**ADVISORY Handling**
- ADVISORY verdicts are logged in gate issues but don't block or force iteration
- **Unclear impact**: User sees advisory notes but unclear if they should trigger re-work or are purely informational

---

### Pain Points Identified in Findings

1. **Lack of Pushback**
   - Phase B reviews use verdict protocol (PASS/ADVISORY/BLOCKING) but ADVISORY is non-blocking
   - No mechanism for agents to surface confidence levels or request additional work
   - Reviews validate substance (Phase B) but don't surface when substance is "good enough but not ideal"

2. **No Questions Before Planning**
   - Plan agent receives fixed prompt template with no mechanism to ask clarifying questions
   - Assumes research handoff is complete; if gaps exist, only Phase B review detects them
   - No structured "validation checklist" that plan agent runs through before committing to architecture

3. **Advisory Notes Instead of Direct Asks**
   - ADVISORY verdicts in Phase B don't block but also don't prescribe next steps
   - Result: User sees "advisory: this design decision is questionable" but unclear if it's "fix it" or "proceed with caution"
   - No distinction between "concerning but acceptable" and "should probably revisit"

4. **One-Way Handoff Gates**
   - Handoff prompts bridge sessions but don't allow reverse communication
   - If next step needs clarification, they must request it in Phase B review (reactive) rather than up front (proactive)

5. **Dispatch Rigidity**
   - Fixed agent types per step: plan/spec/decompose all use general-purpose agents
   - No mechanism to route to specialized agents (e.g., database architect for data-heavy specs)

---

## Implications

1. **Phase Behavior is Deterministic but Rigid**
   - Each tier has a fixed phase sequence defined in state.json
   - Transitions are gated by two-phase review, but verdict protocol has limited expressiveness (ADVISORY doesn't force iteration)
   - No loop-back mechanisms within phases—only forward progression or escalation to user

2. **Pushback Happens at Boundaries (Phase B), Not Within Phases**
   - Plan agent doesn't push back on incomplete research (Phase B does)
   - Spec agent doesn't push back on incomplete architecture (Phase B does)
   - Result: Agents proceed assuming completeness; reviews catch issues after the fact

3. **Handoff Prompts Drive Session Continuity But Limit Flexibility**
   - Handoff is "firewall" to prevent context bloat (good for session continuity)
   - But prevents step agents from re-examining original evidence or requesting backfill
   - Once a handoff is written, it's assumed complete for planning purposes

4. **Verdict Protocol Lacks Nuance**
   - PASS/ADVISORY/BLOCKING is binary-ish: either proceed or block
   - ADVISORY is ambiguous: doesn't distinguish "proceed with caution" from "minor note, proceed normally"
   - No mechanism for Phase B agent to say "this needs more research but doesn't block implementation"

5. **Review is Self-Driven but Approval is Manual**
   - Phase A + B run automatically, but every transition waits for explicit user approval
   - Result: Review findings don't auto-remediate; user must decide what to do with BLOCKING verdicts

---

## Open Questions

1. **How should plan agents handle incomplete research?**
   - Should they ask clarifying questions up front (before writing plan)?
   - Should they create a pre-plan checklist and validate research against it?
   - Or should Phase B review continue to surface issues after the fact?

2. **What's the intended use of ADVISORY verdicts?**
   - Are they meant to be "inform the user but proceed normally"?
   - Or "inform the user and suggest re-work but don't block"?
   - Current behavior: included in gate file but don't trigger re-planning

3. **Should step agents have authority to request prior steps re-open?**
   - If plan detects incomplete research, should it open a "backfill" task for research to complete?
   - Or should it proceed and let Phase B review catch the issue?

4. **How rigid is the phase sequence?**
   - Can a task skip a phase (e.g., Tier 3 without research)?
   - Currently: tier pre-selects steps; no mechanism to skip

5. **What's the ideal granularity for Phase B checklists?**
   - Currently: checklists are embedded in command definitions per step
   - Should they be reusable across commands (e.g., plan-to-spec checklist applies to both T2 and T3)?

6. **How should implement phase gating work for multi-phase streams?**
   - Currently: After each phase, run Phase A + B reviews
   - What if a later phase reveals issues with an earlier phase's assumptions?
   - Can a stream re-open a prior phase, or must it escalate to user?

7. **Should dispatch routing be rule-based or fixed per step?**
   - Currently: plan → general-purpose, spec → general-purpose
   - Should spec step route to database architect for data-heavy specs?
   - Or database architect for data-heavy specs, API designer for API-heavy specs?

---

## Summary

Current phase behavior is **deterministic and gated but lacks expressiveness**. Each tier has a fixed phase sequence with two-phase reviews at transitions, but the verdict protocol (PASS/ADVISORY/BLOCKING) is binary-ish. The "lack of pushback" manifests as:

- **ADVISORY verdicts don't force iteration**: Phase B can flag "this is questionable" but ADVISORY status doesn't trigger re-planning
- **No pre-step validation**: Plan agents receive fixed prompts without structured validation against research completeness
- **One-way handoffs**: Handoff prompts allow next steps to proceed without explicitly validating prior step completeness

The user's described pain points (lack of pushback, no pre-plan questions, advisory notes instead of asks) stem from this design: phases are optimized for forward momentum and context continuity (via handoffs), but at the cost of proactive validation and iterative refinement within phases.

The redesign opportunity is to add **structured validation gates within phases** (before dispatching to the next step) and **nuanced pushback mechanisms** (ADVISORY that surfaces what needs re-work vs what's acceptable as-is).
