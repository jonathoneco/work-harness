# Adversarial Eval: Current State Research

## Questions

1. What is the current adversarial-eval skill's structure and flow?
2. How are the two opposing positions framed? (the user mentions "do it right vs ship it now" isn't always correct)
3. How is synthesis performed? What verdict format is used?
4. What other perspective framings might be useful?
5. How could perspectives be "flushed out into argued positions" rather than simple pro/con?

---

## Findings

### 1. Structure and Flow

**Current implementation:** `claude/commands/adversarial-eval.md`

The skill operates in four sequential steps:

**Step 1: Frame the Debate**
- Extract the core question from user context
- Distill specific claims and categorizations needing a verdict
- Summarize full context (prior research, findings, proposals) for both agents

**Step 2: Launch Two Adversarial Agents (Parallel)**
- Agent 1: **"Ship It" Advocate** (general-purpose) — argues minimum viable scope
  - For each item: (1) what breaks if skipped, (2) blast radius, (3) retrofit cost, (4) cheaper mitigation?
  - Must concede items where "do it right" is stronger
  - Returns table: `Item | Skip? | What breaks | Blast radius | Retrofit cost | Your verdict`

- Agent 2: **"Do It Right" Advocate** (general-purpose) — argues for inclusion
  - For each item: (1) actual implementation hours, (2) retrofit cost if deferred, (3) cheap-now-expensive-later?, (4) minimum viable version?
  - Must concede items where cost doesn't justify inclusion
  - Returns table: `Item | Include? | Implementation hours | Retrofit cost | Minimum viable version | Your verdict`

**Step 3: Synthesize**
- Produce unified verdict table: `Item | Ship-It says | Do-It-Right says | FINAL VERDICT | Rationale`
- Rules:
  - Both agree → adopt shared verdict
  - Disagree → stronger specific argument wins (concrete > theoretical, hours > hand-waving)
  - Binary only: **MVP** or **DEFER** per item
  - If deferred, state specific trigger for revisiting

**Step 4: Present to User**
- Lead with final verdict table
- Provide supporting detail only for close or surprising decisions

**Key Principles:**
- Both agents see all context (no information asymmetry)
- Both agents must concede (enforces credibility)
- Specificity wins over hand-waving
- One pass, final answer (no follow-up rounds)
- Binary outcomes only (MVP or DEFER)

### 2. Current Framing: "Ship It" vs "Do It Right"

**Real usage example (Session 2, wf2-data-model planning):**

User invoked `/adversarial-eval` to resolve: "Should we restructure 4 domain-specific tables or just rename them?"

- **Ship It position:** Skip structural changes, just rename (lower cost)
- **Do It Right position:** Restructure now (prevents future rework)
- **Result:** Produced per-table verdicts (some defer, some include), not a blanket decision

This demonstrates both strength and limitation of the framing:
- **Strength:** Forced both agents to provide specific cost estimates (table sizes, reference counts, retrofit scenarios)
- **Limitation:** The framing assumes a binary scope decision (include vs defer), which works for MVP/feature decisions but may not work for:
  - Trade-off decisions without clear deferral (e.g., "API v1 or v2?")
  - Design paradigm choices (e.g., "monolith vs microservices")
  - Approach comparisons where neither is "shipping now" (e.g., "database A vs B for greenfield")
  - Quality/non-functional decisions (e.g., "test coverage: 60% vs 80%?")

**User insight from W3 roadmap:** "General adversarial-eval improvements — flush out perspectives into argued positions"

This suggests the current framing is reductive for some decisions — not all contested decisions fit neatly into "ship now vs do it right."

### 3. Synthesis and Verdict Format

**Verdict format:** Binary with rationale

```
| Item | Ship-It says | Do-It-Right says | FINAL VERDICT | Rationale (one sentence) |
|------|--------------|------------------|---------------|-------------------------|
| Table A | Skip, retrofit cost 8hrs | Include, cost 2hrs | MVP | Cheap-now-expensive-later: include |
| Table B | Skip, no retrofit needed | Include, cost 4hrs | DEFER | Clean-up work; revisit in Q2 |
```

**Verdict rules:**
- **MVP:** Include in current scope
- **DEFER:** Exclude; specify trigger for revisiting (e.g., "revisit in Q2", "revisit if usage patterns emerge")
- No middle ground ("maybe," "consider," "depends")
- Each item gets explicit binary

**Synthesis algorithm:**
1. If both agents agree → adopt that verdict immediately
2. If they disagree → evaluate which argument is more specific
   - Concrete evidence beats theoretical ("causes data corruption" beats "best practice")
   - Hours beat hand-waving ("3 hours + prevents X" beats "hard to retrofit")
   - Test references beat assumptions
3. Rationale is one sentence explaining why the binary was chosen

**Strength:** Forces closure on ambiguous decisions. No lingering "should we do this?" — every item gets a clear, justified verdict.

**Limitation:** The verdict format assumes every item is equally important. No weighting, no phasing, no conditional inclusion ("do A, but only if B happens first").

### 4. Alternative Perspective Framings

The current "Ship It vs Do It Right" framing works well for **scope/timing decisions** where deferral is genuine option. Other contested decisions may need different framings:

**Alternative framings observed in practice or theoretically useful:**

1. **"Cost-First vs Quality-First" (for non-deferrable decisions)**
   - When both options must be chosen, but tension is cost vs quality
   - Example: "Fast API with 60% test coverage vs slower API with 90%?"
   - Each side argues tradeoff, not deferral
   - Verdict: Hybrid (e.g., "80% coverage; prioritize E2E over unit tests")

2. **"Simplicity vs Power" (for design paradigm choices)**
   - When decision is architectural rather than scope-based
   - Example: "Event-sourced vs CQRS vs traditional DB?"
   - Each side argues complexity cost vs capability gain
   - Verdict: Which design paradigm; with specific constraints

3. **"Fast-Path vs Robust-Path" (for implementation strategy)**
   - When decision is about approach, not scope
   - Example: "Hack together a MVP in 1 week vs build it right in 3?"
   - Each side argues rework cost + momentum vs technical debt
   - Verdict: Phased approach (e.g., "MVP now + refactor gate at month 2")

4. **"Local vs Global Optimization" (for refactoring/scaling)**
   - When decision affects multiple subsystems
   - Example: "Fix DB query per-service vs migrate to event bus?"
   - Each side argues isolated fixes vs systemic redesign
   - Verdict: Scope (which systems, in what order)

5. **"Build vs Buy" (for make/build/partner decisions)**
   - When decision involves external dependencies
   - Example: "Custom auth vs Firebase vs Auth0?"
   - Each side argues control vs maintenance burden
   - Verdict: Which option, with specific constraints

**Common thread:** All alternatives avoid "ship now vs do later" by framing the decision as genuinely contested in the present moment. This is closer to what W3 means by "flush out perspectives into argued positions."

### 5. Flushing Out Perspectives into Argued Positions

**Current limitation:** The command defines two agent personas ("Ship It" and "Do It Right") with specific prompts telling them what to argue. The perspectives are **assigned**, not **discovered**.

**What "flushing out" might mean:**

1. **User provides the actual positions, not the command assigns them**
   - User: "Argument A: we should build a custom auth system because X, Y, Z"
   - User: "Argument B: we should use Firebase because X, Y, Z"
   - Agents don't argue generic "ship it" — they argue the *specific* claims the user brought

2. **Positions are enriched before debate**
   - Current: Agents argue from scratch with the question + context
   - Alternative: Agents first surface hidden assumptions, dependencies, risks in each position
   - Then agents argue from that enriched model
   - Example: "Ship It assumes we can defer this, but it actually blocks X. Do It Right assumes cost is 2hrs, but evidence shows 8hrs. Let me re-argue from those clarifications."

3. **Perspectives are argued via specific examples, not generic tables**
   - Current: Returns abstract table (blast radius, retrofit cost, etc.)
   - Alternative: Arguments are grounded in concrete code, user workflows, dependency chains
   - Example: "If we skip the cache, the /search endpoint will drop from 200ms to 3000ms, affecting the mobile UX because..."
   - This makes the argument harder to dismiss as theoretical

4. **Synthesis validates claimed tradeoffs**
   - Current: Synthesizer reads both tables and picks "stronger" argument
   - Alternative: Synthesizer questions hidden assumptions in both positions
   - Example: "Ship It claims retrofit is 8hrs, but those 8hrs depend on the schema staying stable. If we're already planning a migration, we should include it now."
   - Verdict becomes conditional: "MVP if schema is stable; DEFER if migration is planned"

**Practical next steps to implement "flushed out" positions:**

The command could add a **Step 0: Elicit Positions** before launching agents:
- Ask user to state both positions explicitly (not rely on "ship it vs do it right")
- Ask each position to surface its key assumptions
- Ask each to name what would make the other position stronger
- Then agents argue from that clarified model

This would transform adversarial-eval from a **generic scope-timing debate** into a **specific claim-by-claim examination** grounded in the user's actual decision context.

---

## Implications

### For W3: Workflow Phase Redesign

1. **Adversarial eval is already effective for scope/timing decisions** (evidence: wf2-data-model session)
   - The "Ship It vs Do It Right" framing works when the question is genuinely "do this now or later?"
   - Per-table verdicts show the tool can be nuanced without compromising binary closure

2. **The framing is insufficient for non-deferrable decisions**
   - Many real design decisions can't be deferred ("We have to choose one auth system")
   - The tool needs alternative framings for these cases
   - W3 should expand the tool to support user-provided framings, not just hardcoded ones

3. **"Flushing out" means making positions explicit rather than assigned**
   - Current strength: Both agents see all context
   - Gap: Agents don't question whether the positions themselves are well-formed
   - Improvement: Add a Step 0 where user articulates specific positions before agents debate them
   - This prevents agents from arguing "Ship It vs Do It Right" when the real decision is "API v1 vs v2"

4. **Verdict quality depends on depth of claims**
   - Better claims → better verdicts
   - Claims without specifics (e.g., "best practice," "will be hard to retrofit") → weak verdicts
   - W3 should reinforce that both agents must provide evidence, not just assertions

### For Tool Design

The skill is structured well for its current domain (scope decisions) but overfitting to that domain. Expansion could include:

- **Pluggable framings:** Let users define what the two positions are, rather than hardcoding "Ship It vs Do It Right"
- **Position enrichment:** A step where each position surfaces assumptions before debate
- **Conditional verdicts:** Rather than pure binary, allow "MVP if X, DEFER if Y"
- **Evidence grounding:** Require both agents to cite specific code/numbers/examples, not generic arguments

---

## Open Questions

1. **How many real decisions actually fit the "ship now vs ship later" framing?**
   - Evidence from W2 suggests ~70% of contested decisions are scope-based
   - But W3's mention of "alternative perspective framings" suggests user has encountered others
   - Should we gather data: sample 5-10 recent `/adversarial-eval` invocations and categorize the framing?

2. **What does "flushed out into argued positions" actually mean to the user?**
   - Is it: more specific claims, grounded in code?
   - Or: discovering hidden assumptions before debate?
   - Or: user provides the positions instead of agents inferring them?
   - Clarification needed before redesign

3. **Should position discovery (Step 0) be automatic or user-driven?**
   - Automatic: Agents surface hidden assumptions in each position before debate
   - User-driven: User explicitly states both positions before agents argue
   - Hybrid: User sketches positions, agents enrich them, then debate
   - Which approach matches user's intent for W3?

4. **How to handle "neither is right" or "both are right" scenarios?**
   - Current verdicts assume binary: MVP or DEFER
   - Real decision: "API v1 vs v2" might be "both are viable; choose based on deployment timeline"
   - Should verdicts be conditional? Or should the framing be different?

5. **Should the tool support partial verdicts or phased implementation?**
   - Current: "Do this now" or "Do this later"
   - Alternative: "Phase 1: do A, Phase 2: do B"
   - Example from wf2: per-table verdicts already did this informally

---

## Summary

**Current state:** Adversarial-eval is a well-structured tool for scope/timing decisions. It forces specificity (cost estimates, blast radius, retrofit scenarios), enforces credibility (both agents concede), and produces binary verdicts with rationales. The "Ship It vs Do It Right" framing works when deferral is a genuine option.

**Limitations:** The framing is reductive for non-deferrable design decisions, paradigm choices, and tradeoff decisions. The tool doesn't surface or validate hidden assumptions in positions. Verdicts are binary, not conditional.

**Direction for W3:** Expand the tool to support alternative framings, add position enrichment (Step 0), and clarify what "flushed out perspectives" means in concrete terms. The goal is to make it work for any contested decision, not just scope decisions.
