# 06: Step Output Review Gates

## Overview

After each major step completes, before auto-advancing, spawn a critical review agent to validate the step's output. Catches consistency errors, missing fields, path mismatches, and underspecified logic before they compound into implementation failures.

## Motivation

During the harness-enforcement workflow itself, a spec review agent caught 7 blocking issues (missing fields, path mismatches, underspecified state mutations) that would have caused implementation failures. This was accidental — the user requested a review. It should be systematic.

## Reviewed Steps

| Step | Review Happens | What's Reviewed |
|------|---------------|-----------------|
| plan | Before advancing to spec | Architecture document |
| spec | Before advancing to decompose | All spec files + cross-cutting contracts |
| decompose | Before advancing to implement | Work items, dependencies, stream docs |
| implement | Already exists as step 7 (`/work-review`) | Code changes |

Research is NOT reviewed — it's exploratory and the plan step synthesizes it. Assess is too brief. Review (step 7) is already a review.

## Review Agent Specification

### Agent Type

Explore agent (read-only). The review agent reads artifacts but does not modify them.

### Agent Prompt Pattern

```
Review the {step} output for task '{name}' with a critical eye.

Read all files in {artifact_paths}.

Check for:
1. Internal consistency — do artifacts reference each other correctly?
2. Path conventions — do paths match the step-to-directory mapping?
   (spec -> specs/, decompose -> streams/, all others match step name)
3. Missing declarations — are all fields/types used in later specs declared in 00?
4. Edge cases — are boundary conditions documented?
5. Dependency ordering — are dependencies between components correct?
6. Completeness — does every component from the architecture have a spec?

Return findings as:
- BLOCKING: issues that will cause implementation failures
- IMPORTANT: issues that should be fixed but won't break implementation
- CLEAN: no issues found

For each finding, state: what's wrong, where it is, and what the fix should be.
```

### Step-Specific Review Focus

#### Plan Review
- Does the architecture cover all goals from the research handoff?
- Are component boundaries clear (no overlapping responsibilities)?
- Are technology choices justified?
- Is the dependency order between components correct?
- Are scope exclusions explicit?

#### Spec Review
- Do all specs reference the cross-cutting contracts (spec 00)?
- Are path conventions consistent across all specs?
- Are all state.json fields used in specs declared in spec 00?
- Do code examples match the described behavior?
- Are testing strategies concrete (not just "test X works")?
- Are edge cases for each rule documented?

#### Decompose Review
- Does every spec component map to at least one work item? (Each beads work item title should reference the spec component it implements, e.g., `W-01: state-guard.sh — spec 01`)
- Are beads issue dependencies consistent with spec dependency ordering?
- Can claimed "parallel" streams actually run in parallel (no hidden deps)?
- Do stream execution docs have acceptance criteria?
- Is the concurrency map consistent with the dependency graph?

## Integration with Auto-Advancement (Spec 04)

The review happens between step completion and state advancement:

```
Step A logic completes
  ↓
Handoff prompt written to disk
  ↓
★ Review agent spawned (read-only, checks step A output)
  ↓
If BLOCKING findings:
  → Present findings to user
  → Fix issues (still in step A)
  → Re-run review agent
  → Loop until clean or user overrides
  ↓
If CLEAN or IMPORTANT-only:
  → Present brief review summary
  → Gate issue created
  → State advanced to step B
  → Continue to step B logic
```

### Handoff/Review Feedback Loop

If the review finds BLOCKING issues:
1. Agent presents findings to user
2. Agent fixes the issues (still in step A — state hasn't advanced yet)
3. Agent **updates the handoff prompt** to reflect the fixes
4. Agent re-runs the review agent (or the user says "good enough")
5. Once clean, proceed with gate issue creation and state advancement

The handoff prompt is a living document until the step advances. After state advancement, it's frozen.

### User Override

If the review agent flags issues the user considers false positives:
- User says "skip" or "those are fine" → advance without fixing
- Override is logged as a comment on the gate issue: `bd comment <gate-id> "User override: skipped findings [list]"`
- This provides an audit trail for why known issues weren't fixed
- This is a conscious user decision, not the agent skipping enforcement

## Files to Create

None — this is integrated into the `/work-deep` command changes (spec 04).

## Files to Modify

- `.claude/commands/work-deep.md` — add review agent spawning to plan, spec, and decompose step sections

## Dependency

Depends on Component 4 (auto-advancement) — the review gates are part of the auto-advance flow.

## Testing

1. Complete plan step with inconsistent architecture → expect review agent catches it
2. Complete spec step with missing field declarations → expect BLOCKING finding
3. Complete decompose with missing work items → expect BLOCKING finding
4. Complete spec step with clean output → expect "review clean" and auto-advance
5. User override on IMPORTANT finding → expect advancement proceeds
