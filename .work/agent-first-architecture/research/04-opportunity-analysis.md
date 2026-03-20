# Opportunity Analysis: Agent-First Architecture

## Core Thesis

The current harness executes plan/spec/decompose **inline** in the lead agent's context window.
This wastes the lead's context on detailed work that could be delegated to specialized agents.

## What "Steps as Agents" Means

**Current**: Lead reads handoff → executes step logic → writes artifacts → runs Phase A/B → advances state.
**Proposed**: Lead reads handoff → spawns step agent with context → agent produces artifacts → lead runs Phase A/B → advances state.

### Benefits
1. **Context isolation** — each step agent gets a clean window focused on its task
2. **Parallel steps** — research agents for different topics already run in parallel; extend to plan/spec
3. **Specialist agents** — Plan agent for architecture, spec agent for detailed contracts
4. **Reduced lead context burn** — lead orchestrates, doesn't execute

### Risks
1. **Context seeding quality** — agent only knows what's in its prompt. Must seed with right artifacts.
2. **Artifact format consistency** — agents must produce files in expected format for next step.
3. **State management complexity** — lead must still own state.json writes, more coordination needed.
4. **User interaction gap** — steps that need user Q&A (plan, spec) are harder to run as agents.

## Decomposition: Which W2 Items to Tackle

| Item | Complexity | Dependency | Recommendation |
|------|-----------|------------|----------------|
| Steps as agents | High | Foundation for others | Phase 1 — do first |
| Decompose as agents, not worktrees | Medium | Steps as agents | Phase 1 — part of same change |
| Delegation with proper context | Medium | Steps as agents | Phase 1 — context seeding is core |
| Parallelize decomposition | Medium | Steps as agents | Phase 2 — optimize after basic delegation works |
| Subagent delegation audit | Low | Steps as agents | Phase 2 — audit after new patterns established |
| `/delegate` skill | Medium | Audit results | Phase 3 — needs stable patterns to route to |
| Agent Teams integration | Medium | Steps as agents | Phase 2 or 3 — enabled, explore for parallel step execution |

## Key Design Questions for Planning

1. **Which steps should be agents vs inline?**
   - Research: already agents (Explore). Keep.
   - Plan: candidate for agent (Plan type). But needs user interaction for Q&A.
   - Spec: strong candidate (Plan type). Mostly artifact production.
   - Decompose: strong candidate (Plan type). Produces stream docs + beads issues.
   - Implement: already agents (per stream). Keep.
   - Review: already delegated to /work-review. Keep.

2. **How to handle user interaction within agent-executed steps?**
   - Option A: Agent produces draft, returns to lead, lead presents to user
   - Option B: Agent runs in foreground, user interacts directly
   - Option C: Agent produces draft + questions list, lead mediates

3. **What context does each step agent need?**
   - Previous step's handoff prompt (always)
   - Relevant rule files (code-quality, architecture-decisions)
   - Task state.json (for metadata, not step logic)
   - Beads issue context (for scope)

4. **How to validate agent output before advancing?**
   - Current Phase A/B protocol works — just validate agent-produced artifacts
   - May need additional validation for format compliance

5. **Should agents write state.json or only artifacts?**
   - Keep current pattern: agents write artifacts, lead writes state
   - Lead reads agent output, validates, then advances state

6. **How does `/delegate` skill differ from step routing?**
   - Step routing: tier command routes to step handler
   - `/delegate`: user-facing skill that routes arbitrary tasks to appropriate agent
   - Could share underlying routing logic
