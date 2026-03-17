# 04: Command Auto-Advancement

## Overview

Modify `/work-deep` so that step completion automatically flows into the next step. The user interacts via natural language, not manual slash commands.

## Current Behavior

Each step section in `/work-deep` ends with:
> Use `/work-checkpoint --step-end` to advance, or present the handoff prompt and ask user if ready to advance.

This creates friction — the user must explicitly invoke advancement. If the LLM doesn't prompt for it, steps get stuck.

## Target Behavior

Each step section ends with:
1. Create handoff-prompt.md automatically
2. Create gate issue automatically
3. Present brief summary: "Research complete. Key findings: [summary]. Advancing to plan."
4. Update state.json (step completed, next step active, current_step advanced)
5. Fall through to next step's logic immediately

The user can interrupt with questions or redirects. Default is forward flow.

## Changes to `/work-deep` Step Router

### Pattern for Each Step Section

Replace the current ending:
```
8. **Gate review and advance**: Create gate issue. Use `/work-checkpoint --step-end`.
```

With:
```
8. **Auto-advance**:
   a. Write the handoff prompt to `.work/<name>/<step>/handoff-prompt.md`
   b. Create gate issue: `bd create --title="[Gate] <name>: <step> → <next-step>"`
   c. Update state.json: mark current step completed (with gate_id), activate next step, update current_step
   d. Present brief summary to user: what this step produced, key artifacts, advancing to next step
   e. Continue to next step section immediately
```

## Handoff Prompt Templates

Each step's handoff prompt follows a consistent structure with step-specific content.

### Common Structure

All handoff prompts include:
- What this step produced (artifacts, decisions, key outputs)
- Key artifacts and their file paths
- Decisions made during this step
- Open questions for the next step
- Instructions for the next step

### Research → Plan Handoff
- Topic summaries with status (explored/dead-end/future)
- Key findings that affect architecture
- Dead ends to avoid in planning
- Futures deferred to later work
- Questions the plan must address

### Plan → Spec Handoff
- Architecture document location and summary
- Component list with scope estimates
- Technology choices and rationale
- Phase ordering (what must come first)
- Instructions: write one spec per component, cross-cutting contracts first

### Spec → Decompose Handoff
- Spec index with dependency ordering
- Components ready for work breakdown
- Identified parallelization opportunities
- Instructions: create beads issues per work item, build concurrency map

### Decompose → Implement Handoff
- Work item manifest (beads IDs, titles, dependencies)
- Concurrency map (parallel vs sequential streams)
- Phase ordering (which streams first)
- Instructions: use `bd ready` to find unblocked work, claim before implementing

## Gate Issue Template

Auto-created gate issues use this format:

Title: `[Gate] <task-name>: <current-step> → <next-step>`
Type: task
Priority: 2
Description: Not required — the gate issue is a marker, not a work item. Close it when the user approves advancement.

## State Mutation During Auto-Advance

When advancing from step A to step B, the command performs these atomic mutations to state.json:

1. Set `steps[A].status` = `"completed"`
2. Set `steps[A].gate_id` = `"<beads-issue-id>"` (the gate issue just created)
3. Set `steps[B].status` = `"active"`
4. Set `current_step` = `"B"`
5. Set `updated_at` = current ISO 8601 timestamp

These 5 fields must be written in a single state.json write (not 5 separate edits) to maintain state machine consistency. The state-guard hook validates the result after write.

## Context Reset at Step Transitions

Advisory rules loaded at session start (code-quality, architecture-decisions, beads-workflow, etc.) degrade as conversation grows. Step transitions are natural compaction points — the handoff prompt captures everything needed for the next step, making prior tool call noise expendable.

### The Problem

A Tier 3 workflow can accumulate 50+ tool calls across research → plan → spec. By the time the agent reaches decompose, early context (including critical rules like "no shims", "fail closed", "never fabricate data") has been pushed out. The agent progressively loses its constraints — exactly the failure mode observed in dev-env-silo.

### The Solution: Compact and Re-Ground at Each Gate

At each step transition, after writing the handoff prompt but before starting the next step:

1. **Handoff prompt written** — all essential context from step A is on disk
2. **Step output review** (spec 06) — spawn review agent to validate step A's output. If BLOCKING findings, fix and update the handoff prompt before continuing.
3. **Re-read rules** — reload the relevant rules/skills for step B:
   - `.claude/rules/code-quality.md` (always)
   - `.claude/rules/architecture-decisions.md` (if file exists — for plan/spec/implement steps)
   - `.claude/rules/beads-workflow.md` (for decompose/implement steps)
   - The work-harness skill (always — auto-loaded when `.work/` exists)
   - If a rule file doesn't exist, skip it gracefully (not all projects have all rule files)
4. **Read the handoff prompt** — recover step A's output from the file (which may have been updated by review fixes in step 2)
5. **Continue to step B** — with fresh context and re-loaded rules

Note: The agent re-reads rules from disk using the Read tool. This naturally refreshes advisory content that may have degraded in the conversation. There is no programmatic "trigger compaction" — the re-reads themselves combat context degradation by putting rules back at the top of working memory.

### Implementation Pattern

Add to the auto-advance block:

```
8. **Auto-advance**:
   a. Write the handoff prompt to `.work/<name>/<step-dir>/handoff-prompt.md`
   b. Run step output review (spec 06) — fix BLOCKING findings, update handoff if needed
   c. Create gate issue
   d. Update state.json
   e. Present brief summary to user
   f. **Context refresh**:
      - Re-read `.claude/rules/code-quality.md` (always)
      - Re-read step-relevant rules (if files exist)
      - Re-read the handoff prompt (may have been updated by review fixes)
   g. Continue to next step section
```

### Why This Works

- The handoff prompt is the **firewall** — it captures everything needed from step A, so compacting away the raw tool calls loses nothing
- Rules are **re-loaded from disk**, not recalled from earlier in the conversation — they're fresh, not degraded
- The cost is ~3 file reads per transition — trivial compared to the risk of constraint degradation

### Which Rules to Re-Load Per Step

| Next Step | Rules to Re-Read |
|-----------|-----------------|
| research | code-quality, architecture-decisions |
| plan | code-quality, architecture-decisions |
| spec | code-quality, architecture-decisions |
| decompose | code-quality, beads-workflow |
| implement | code-quality, beads-workflow, architecture-decisions |
| review | code-quality |

The work-harness skill is always active (auto-loaded when `.work/` exists), so it doesn't need explicit re-reading.

## Gate Semantics

Every step transition **waits for user acknowledgment**. The pattern is:

1. Step logic completes
2. Handoff prompt written to disk
3. Step output review runs (spec 06)
4. Gate issue created in beads
5. State.json updated (step A completed, step B active)
6. **Context refresh** — re-read rules and handoff prompt
7. **Brief summary presented to user** — what was produced, what comes next
8. **Wait for user** — agent does NOT continue until user acknowledges

The user responds naturally:
- "Looks good, continue" → agent proceeds to next step
- "I have questions about X" → agent answers, then waits again
- "Go back and investigate Y" → agent redirects
- "Let's checkpoint here" → agent saves progress, pauses

**"Self-driving" means the agent stays on the harness rails and handles all bookkeeping automatically. It does NOT mean the agent advances without the user.** The harness drives the mechanics; the user controls the pace.

Archive also requires explicit `/work-archive` — it is never automatic.

## Decompose Step: Work Item Creation

During decompose, auto-advancement includes creating beads work items:

1. Read spec handoff for component list
2. For each component/work item:
   - Create beads issue with title referencing the spec: `bd create --title="[<tag>] W-NN: <title> — spec NN" --type=task --priority=2`
   - This naming convention is required — spec 06 review agents verify every spec component maps to a work item by checking title references
   - Set dependencies between issues matching spec ordering
3. Create stream execution documents in `.work/<name>/streams/`
4. Build concurrency map (which streams can run in parallel)
5. Write streams/handoff-prompt.md with manifest of all created issues

The decompose step WAITS for user approval before advancing to implement, because work item creation is a significant commitment. Present: "Created N work items across M streams. [list]. Ready to implement?"

### Steps That Auto-Advance

| Step | Next Step | Auto-Advance? |
|------|-----------|---------------|
| assess | research | Yes |
| research | plan | Yes |
| plan | spec | Yes |
| spec | decompose | Yes |
| decompose | implement | Yes — but note streams/work items created |
| implement | review | Yes — when all beads issues closed |
| review | (archive) | No — user invokes `/work-archive` explicitly |

### Review → Archive is NOT Auto-Advanced

Archive is a deliberate action. The review step completes and presents: "Review complete. N findings addressed. Run `/work-archive` when ready."

## Self-Driving Interaction Model

```
User: /work-deep Rebuild auth system
Agent: [assessment] Score: 6. Tier 3. Creating task...
       [research] Launching 3 research agents...
       Research complete. 4 notes indexed. Key findings: [brief].
       Advancing to plan.
       [plan] Writing architecture document...
       Architecture: 3 components, 2 phases. [summary]
       Advancing to spec.
User: Wait — I have a question about the auth middleware approach.
Agent: [pauses] Sure, what's your question?
User: Why not use WorkOS directly instead of wrapping it?
Agent: [answers] ... Updated architecture to reflect this.
       Continuing to spec.
       [spec] Writing 3 component specs...
```

## Files to Modify

- `.claude/commands/work-deep.md` — rewrite step endings for auto-advancement
- Ensure each step section has a clear "auto-advance" block at the end

## Dependency

This component depends on Components 1-3 (hooks) being deployed. The auto-advancement relies on hooks to catch any malformed state transitions. Without hooks, auto-advancement could silently corrupt state.

## Testing

End-to-end: Create a small Tier 3 task, invoke `/work-deep`, verify:
1. Steps flow automatically from assess → research → plan → ...
2. Handoff prompts created at each transition
3. Gate issues created at each transition
4. State.json updated correctly at each transition
5. User can interrupt and resume at any gate
