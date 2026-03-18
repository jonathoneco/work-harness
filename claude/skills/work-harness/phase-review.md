---
name: phase-review
description: "Two-phase inter-step quality review protocol -- Phase A artifact validation and Phase B quality review with verdict handling. Used by work-deep at every step transition and extensible to other tier commands."
---

# Phase Review

Shared protocol for the two-phase inter-step quality review that runs at every step transition. Provides the framework for spawning review agents, collecting verdicts, and handling results. Step-specific checklist items remain in the calling command definitions -- this skill provides the template and protocol, not the checklists themselves.

## When This Activates

- Any step transition that runs the Inter-Step Quality Review Protocol
- Primarily used by `/work-deep` (Tier 3) at every transition
- Extensible to `/work-feature` (Tier 2) for plan-to-implement transitions

## Phase A -- Artifact Validation

### Purpose

Verify structural completeness of the step's deliverables. This is a "did you produce what you said you would?" check.

### Agent Template

Spawn an **Explore agent** (read-only) with:

- **Agent type**: `Explore` (read-only access, cannot modify files)
- **Task**: Validate that all expected artifacts exist, are indexed, and follow naming conventions
- **Checklist**: Provided by the calling command (step-specific items)
- **Output**: A verdict (PASS, ADVISORY, or BLOCKING) with per-item results

The calling command supplies the checklist. Example format:

```
Validate the following for the <step> step of task <name>:
- [ ] <checklist item 1>
- [ ] <checklist item 2>
- [ ] <checklist item N>

For each item, report: PASS, ADVISORY (minor issue, note it), or BLOCKING (must fix).
Overall verdict: PASS if all items pass. ADVISORY if any items are advisory but none blocking. BLOCKING if any item is blocking.
```

## Phase B -- Quality Review

### Purpose

Evaluate the substance and quality of the step's deliverables. This is a "is what you produced good enough?" check.

### Agent Template

Spawn a **step-appropriate agent** (read-only) with:

- **Agent type**: Selected from the Transition-Agent Mapping table below
- **Skills**: `skills: [code-quality]`
- **Context**: Agent reads `.claude/rules/architecture-decisions.md` (if it exists)
- **Checklist**: Provided by the calling command (step-specific quality items)
- **Output**: A verdict (PASS, ADVISORY, or BLOCKING) with per-item results and detailed findings

## Transition-Agent Mapping

| Transition | Phase B Agent Type | Quality Focus |
|-----------|-------------------|---------------|
| research -> plan | Plan agent | Coverage vs task scope, evidence-based findings, alignment with architecture decisions |
| plan -> spec | Plan agent | Tech choices vs decision rules, component layering, constructor injection, fail-closed |
| spec -> decompose | Plan agent | Implementability, interface consistency, testable acceptance criteria, edge cases |
| decompose -> implement | Plan agent | Granularity, stream/code boundary alignment, phase ordering, parallelism |
| implement phases (N -> N+1) | Review agent (per `review_routing` in harness.yaml, or `work-review` agent) | Spec compliance, code-quality anti-patterns, test coverage |
| implement -> review | Review agent (per `review_routing` in harness.yaml, or `work-review` agent) | Pre-screen full diff for obvious issues before formal review |

## Verdict Protocol

### PASS

No issues found. Present results in the transition summary and proceed to the approval ceremony (see `step-transition` skill).

### ADVISORY

Minor notes that do not block progress:
- Log the advisory notes in the gate issue description (if gate issues are created)
- Include full advisory notes in the transition summary -- do not abbreviate or hide them
- Proceed to the approval ceremony

### BLOCKING

Substantive issues that must be fixed before the transition can proceed:
- Report the blocking findings to the lead agent
- The lead agent fixes the issues (or directs a subagent to fix them)
- Re-run Phase B with the same checklist
- **Maximum 2 re-review attempts.** If still BLOCKING after 2 attempts, escalate to the user: "Phase B review found blocking issues after 2 fix attempts. Here are the remaining issues: [list]. How would you like to proceed?"

## Retry Logic

```
attempt = 1
while verdict == BLOCKING and attempt <= 2:
    fix the blocking issues
    re-run Phase B
    attempt += 1

if verdict == BLOCKING:
    escalate to user -- do not auto-advance
```

The retry limit applies to Phase B only. Phase A failures are typically structural (missing files) and are fixed once, not retried in a loop.

## Checklist Reference

**Checklists remain in command definitions.** This skill provides the framework (agent types, verdict protocol, retry logic); the calling command provides the checklist items specific to each transition.

For example, the research-to-plan transition checklist in `work-deep.md` includes items like "Do findings cover the full task scope?" -- these are step-specific and belong in the command, not in this skill.

## Self-Driven Reviews

Reviews are self-driven -- Phase A and Phase B run automatically without user interaction. The user is only involved when:
- Results are presented for acknowledgment (approval ceremony, handled by `step-transition` skill)
- BLOCKING verdicts persist after 2 retry attempts (escalation)

## References

- **step-transition** -- Approval ceremony and state update after reviews complete (path: `claude/skills/work-harness/step-transition.md`)
- **state-conventions** -- State.json schema, step lifecycle (path: `claude/skills/work-harness/references/state-conventions.md`)
