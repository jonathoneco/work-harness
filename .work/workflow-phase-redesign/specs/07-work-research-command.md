# Spec 07: work-research Command

**Component**: C07
**Phase**: 3 (New Capabilities)
**Dependencies**: C01 (Spec 01 — state schema extensions for Tier R), C04 (Spec 04 — explore clarity patterns)
**Cross-cutting contracts**: None (scope validation uses Spec 04 clarity questionnaire, not ASK verdicts)

## Overview and Scope

**Does**:
1. Create `claude/commands/work-research.md` — a new command for standalone research tasks
2. Define Tier R: a research-only lifecycle with steps `assess → research → synthesize`
3. Define the synthesize step — produces a research deliverable distinct from a handoff prompt
4. Update `claude/skills/workflow-meta.md` to include the new command in the reference table

**Does NOT**:
- Modify existing T1/T2/T3 workflows (Tier R is additive, not a modification)
- Create a plan, spec, decompose, or implement step for Tier R
- Support tier escalation from R to T2/T3 (research tasks stay research-only; if the user wants to implement findings, they start a new task)
- Add inter-step quality review for Tier R (lightweight lifecycle — no Phase A/B gates between steps)

## Implementation Steps

### Step 1: Define Tier R lifecycle

**Action**: Establish the Tier R step sequence and state model.

**Acceptance criteria**:
- [ ] AC-1.1: Tier R has exactly 3 steps: `assess`, `research`, `synthesize`
- [ ] AC-1.2: `assess` is pre-completed at task creation (same pattern as T1/T2/T3)
- [ ] AC-1.3: `research` is the active step after creation
- [ ] AC-1.4: `synthesize` produces the final deliverable — no step follows it
- [ ] AC-1.5: After `synthesize` completes, the task is eligible for archiving

### Step 2: Define state.json schema for Tier R

**Action**: Specify the state.json structure for a Tier R task.

**Acceptance criteria**:
- [ ] AC-2.1: `tier` field is set to `"R"` (string, not integer — distinguishes from numeric tiers)
- [ ] AC-2.2: Steps array contains: `[{name: "assess", status: "completed"}, {name: "research", status: "active"}, {name: "synthesize", status: "not_started"}]`
- [ ] AC-2.3: No `gate_file` or `gate_id` fields on step status objects (Tier R has no inter-step gates)
- [ ] AC-2.4: Handoff prompt is written between research and synthesize (research → synthesize handoff)
- [ ] AC-2.5: Standard fields (`assessment`, `beads_issue`, `created_at`, `updated_at`, `archived_at`) are present and follow existing conventions

### Step 3: Create work-research.md command file

**Action**: Write the command file following existing command conventions (YAML frontmatter, config injection, step-by-step instructions).

**Acceptance criteria**:
- [ ] AC-3.1: YAML frontmatter includes: `name: work-research`, `description`, `allowed-tools`, `config-injection` for harness.yaml
- [ ] AC-3.2: Command accepts a `<topic>` argument (the research subject)
- [ ] AC-3.3: Initialization creates `.work/<topic-slug>/` directory with `research/` subdirectory
- [ ] AC-3.4: Initialization creates a beads issue (type: `task`, tagged `[Research]`) — NOT an epic (Tier R is lightweight)
- [ ] AC-3.5: Initialization creates `docs/feature/<topic-slug>.md` summary file with Status: Research

### Step 4: Define research step for Tier R

**Action**: Specify the research step behavior, reusing patterns from `work-deep.md`'s research step.

**Acceptance criteria**:
- [ ] AC-4.1: Research step follows the same team-dispatch pattern as T3 research: create team, spawn parallel research agents per topic, collect findings
- [ ] AC-4.2: Research step includes the scope validation from Spec 04 (explore clarity) — before dispatching, validate scope with the user
- [ ] AC-4.3: Research output goes to `.work/<name>/research/notes.md` (same convention as T3)
- [ ] AC-4.4: Research step writes a handoff prompt at `.work/<name>/research/handoff-prompt.md` for the synthesize step

### Step 5: Define synthesize step for Tier R

**Action**: Define the synthesize step — a new step type unique to Tier R.

**Acceptance criteria**:
- [ ] AC-5.1: Synthesize step reads the research handoff prompt
- [ ] AC-5.2: Synthesize step produces `.work/<name>/research/deliverable.md` — a structured research report
- [ ] AC-5.3: Deliverable format includes: Executive Summary, Findings (organized by topic), Recommendations, Open Questions, Sources/References
- [ ] AC-5.4: Synthesize step updates `docs/feature/<name>.md` with key findings
- [ ] AC-5.5: After synthesize completes, the command suggests archiving: "Research complete. Run `/work-archive` to archive."

### Step 6: Define transition between research and synthesize

**Action**: Specify how the research→synthesize transition works (no inter-step review for Tier R).

**Acceptance criteria**:
- [ ] AC-6.1: No Phase A/B review between research and synthesize (Tier R is lightweight)
- [ ] AC-6.2: Transition is automatic: when research step completes, synthesize step activates
- [ ] AC-6.3: State update follows the same atomic write pattern as other tiers (mark research completed, activate synthesize)
- [ ] AC-6.4: Context compaction follows T2 pattern: "Recommend `/compact` then `/work-research`"

### Step 7: Update workflow-meta.md command table

**Action**: Add `work-research` to the command reference table.

**Acceptance criteria**:
- [ ] AC-7.1: Command table in `workflow-meta.md` includes a row for `work-research`
- [ ] AC-7.2: The sync point note in `workflow-meta.md` accounts for the new command
- [ ] AC-7.3: The `workflow.md` rule file's command table is also updated to include `/work-research`

## Interface Contracts

**Exposes**:
- `work-research` command — invocable via `/work-research <topic>`
- Tier R state model — documented in `state-conventions.md` (Spec 01)
- Synthesize step — new step type, potentially reusable in future tiers

**Consumes**:
- Spec 01: Tier R step definitions in `state-conventions.md`
- Spec 04: Explore clarity pattern (scope validation at research step start)
- Existing patterns: Team dispatch from `work-deep.md` research step, state update from `step-transition.md`

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/commands/work-research.md` | New Tier R command: assess, research, synthesize |
| Modify | `claude/skills/workflow-meta.md` | Add work-research to command reference table and sync points |
| Modify | `claude/rules/workflow.md` | Add `/work-research` to the command reference table |

## Testing Strategy

1. **Command structure**: Verify `work-research.md` has valid YAML frontmatter with correct name and config-injection
2. **Step sequence**: Verify state.json initialization has exactly 3 steps in correct order and status
3. **Tier value**: Verify tier is `"R"` (string) not a number
4. **No gates**: Verify no Phase A/B review or gate file references in the command
5. **Scope validation**: Verify research step includes explore clarity protocol from Spec 04
6. **Deliverable format**: Verify synthesize step specifies the deliverable structure
7. **Command table sync**: Verify both `workflow-meta.md` and `workflow.md` include the new command
8. **Beads integration**: Verify a beads issue (not epic) is created at initialization
