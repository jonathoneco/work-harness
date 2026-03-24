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
- **Output**: A verdict (PASS, ASK, or BLOCKING) with per-item results

The calling command supplies the checklist. Example format:

```
Validate the following for the <step> step of task <name>:
- [ ] <checklist item 1>
- [ ] <checklist item 2>
- [ ] <checklist item N>

For each item, report: PASS, ASK (needs clarification), or BLOCKING (must fix).
Overall verdict: PASS if all items pass. ASK if any items need clarification but none are blocking. BLOCKING if any item is blocking.
```

If structural issues require clarification (e.g., ambiguous file naming, missing but possibly intentional artifacts), emit ASK with specific questions rather than PASS with concerns or BLOCKING with assumptions.

## Phase B -- Quality Review

### Purpose

Evaluate the substance and quality of the step's deliverables. This is a "is what you produced good enough?" check.

### Agent Template

Spawn a **step-appropriate agent** (read-only) with:

- **Agent type**: Selected from the Transition-Agent Mapping table below
- **Skills**: `skills: [code-quality]`
- **Context**: Agent reads `.claude/rules/architecture-decisions.md` (if it exists)
- **Checklist**: Provided by the calling command (step-specific quality items)
- **Output**: A verdict (PASS, ASK, or BLOCKING) with per-item results and detailed findings

If quality issues require the user's judgment (e.g., trade-off decisions, scope questions, priority calls), emit ASK rather than making the call yourself.

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

### ASK

Specific questions requiring user response before the transition proceeds. Agent output format:

```
**Verdict**: ASK

**Questions**:
1. [Question text — specific, actionable, answerable in 1-3 sentences]
2. [Question text]

**Context**: [Why these questions matter for the transition]
```

Maximum 5 questions per ASK verdict. Questions must reference specific artifacts, decisions, or gaps — not vague concerns. An ASK with 0 questions is invalid — emit PASS instead.

- Present questions to the user under a `## Questions Before Advancing` heading
- Hard stop — no timeout, no auto-advance
- Collect user responses before proceeding
- Record questions and responses in the gate file `## Resolved Asks` section

### BLOCKING

Substantive issues that must be fixed before the transition can proceed:
- Report the blocking findings to the lead agent
- The lead agent fixes the issues (or directs a subagent to fix them)
- Re-run Phase B with the same checklist
- **Maximum 2 re-review attempts.** If still BLOCKING after 2 attempts, escalate to the user: "Phase B review found blocking issues after 2 fix attempts. Here are the remaining issues: [list]. How would you like to proceed?"

## Verdict Flow

```
Phase A:
  PASS     → proceed to Phase B
  ASK      → present questions → collect user response → proceed to Phase B
  BLOCKING → fix issues → retry Phase A

Phase B:
  PASS     → proceed to approval ceremony
  ASK      → present questions → collect user response → record in gate file → proceed to approval ceremony
  BLOCKING → fix issues → retry Phase B
```

ASK verdicts from Phase A are resolved BEFORE Phase B begins. Phase B receives the resolved context.

## Retry Logic

```
attempt = 1
while verdict == BLOCKING and attempt <= 2:
    fix the blocking issues
    re-run the phase
    attempt += 1

if verdict == PASS or verdict == ASK:
    proceed (ASK requires user resolution first)
elif verdict == BLOCKING:
    escalate to user -- do not auto-advance
```

Loop until PASS or ASK, or 2 BLOCKING attempts exhausted.

The retry limit applies per phase. Phase A failures are typically structural (missing files) and are fixed once, not retried in a loop.

## Immediate Finding Resolution

Scoped to **implementation phase transitions only** (implement phase N → N+1, implement → review). Does not apply to earlier step transitions (research → plan, plan → spec, etc.) where findings are handled by verdicts.

### Immediate Resolution Criteria

A Phase B finding qualifies for immediate resolution when ALL of the following are true:

1. **In-scope files**: The finding is about code in the current implementation scope (files being modified in this phase)
2. **No architectural changes**: The fix does not require new components, interface changes, or structural redesign
3. **Localized**: The fix affects 3 or fewer files
4. **Not a design concern**: The finding is a concrete code issue (e.g., "this function doesn't handle the nil case"), not a design-level concern (e.g., "this approach may not scale")

Findings that fail any criterion are **deferred** to the review step: cross-component issues, architectural changes, design-level concerns, or out-of-scope files.

If the implementer is unsure whether a finding qualifies, emit ASK to the user with the finding details and proposed fix per the Spec 00 ASK format.

### Resolution Protocol

1. Phase B reviewer identifies a finding
2. Check against the four immediate resolution criteria above
3. **If qualifiable**: Fix inline, re-verify the specific finding (not a full Phase B re-review), log as RESOLVED in the gate file
4. **If not qualifiable**: Log as DEFERRED in the gate file
5. **Maximum 3 immediate resolutions per transition** — if more findings qualify, defer the extras. Too many inline fixes suggests deeper issues.

### Gate File Finding Resolution Section

For implementation transition gate files, add a `## Finding Resolution` section after `## Resolved Asks` and before the approval record. Omit the section entirely if no findings exist in either category. This section only appears in gate files for implementation transitions.

```markdown
## Finding Resolution

### Resolved Immediately
1. **Finding**: [description]
   **Fix**: [what was changed]
   **Files**: [affected files]

### Deferred to Review
1. **Finding**: [description]
   **Reason**: [why deferred — architectural, cross-component, etc.]
```

### Re-Review Threshold

If more than 5 findings are deferred across implementation phases (cumulative), emit a notification suggesting early `/work-review`:

```
Warning: 6 deferred findings accumulated across implementation phases.
Consider running /work-review early to address systemic issues.
```

This is a suggestion, not a hard stop — the implementer may continue if the findings are non-blocking.

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
