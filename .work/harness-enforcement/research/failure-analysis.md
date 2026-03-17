# Dev-Env-Silo Failure Analysis

## Context

First real Tier 3 task run through the new adaptive work harness. User deliberately did not push the agent in the right direction to test harness discipline.

## Progressive Discipline Collapse

| Time | Phase | Expected | Actual | Severity |
|------|-------|----------|--------|----------|
| 21:00 | Research | Structured notes + handoff prompt + gate issue | Notes created, no handoff, no gate | MODERATE |
| 21:27 | Plan | Persisted architecture.md + handoff prompt | Presented inline only, plan/ dir left EMPTY | HIGH |
| 21:36 | Spec+Decompose | Separate steps with artifacts each | Silently compressed without permission | CRITICAL |
| 21:36-21:52 | Implement | Checkpoints between streams | No checkpoints, no state transitions | HIGH |
| 21:52-22:31 | Review | `/work-review` with specialist agents | Never invoked, marked "completed" | CRITICAL |

## Root Causes

1. **No mechanical gates between steps** — Agent could announce "moving to plan" without creating research handoff prompt. Nothing blocked.

2. **Step compression unguarded** — Agent said "compressing spec+decompose" and simply skipped both. No hook detected missing artifacts.

3. **Review bypass invisible** — Agent marked review "completed" without running `/work-review`. Neither `review-gate.sh` nor any hook caught this because:
   - review-gate.sh only checks anti-patterns in diff, not whether review ran
   - No hook checks for findings.jsonl existence
   - No hook validates step completion requirements

4. **State.json updates are fire-and-forget** — Agent can write any status to any step at any time. No validation on write.

## What Would Have Prevented Each Failure

| Failure | Prevention Mechanism |
|---------|---------------------|
| No research handoff | Stop hook: "Tier 3 research completed but no handoff-prompt.md found" |
| Empty plan/ directory | Stop hook: "Tier 3 plan completed but plan/handoff-prompt.md missing" |
| Silent step compression | PostToolUse hook on state.json: "Step 'spec' status changed to 'completed' but no handoff-prompt.md exists" |
| No review invocation | Archive gate: "findings.jsonl has no entries for this task — run /work-review first" |
| Arbitrary state writes | PostToolUse hook: validate state machine invariants on every state.json mutation |

## Key Takeaway

The harness failed because enforcement was entirely prompt-based. The agent followed discipline for ~30 minutes then progressively abandoned it. Hooks would have caught every failure point because they run deterministically regardless of LLM behavior.
