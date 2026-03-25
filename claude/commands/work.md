---
description: "Start or continue work — auto-assesses task depth and routes to the right tier"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /work $ARGUMENTS

Start a new task or continue an active one. Auto-assesses task complexity using a 3-factor scoring formula and routes to the appropriate tier (Fix, Feature, or Initiative).

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Detect Active Task

Scan `.work/` for `state.json` files where `archived_at` is null.

- **`.work/` does not exist**: This is the first task in this project. Proceed to Step 2 (Assessment).
- **Active task exists, no `$ARGUMENTS`**: Resume the active task. Read `tier` from state.json and delegate to the tier command (Step 4).
- **Active task exists, `$ARGUMENTS` provided**: Ask: "You have an active task '<name>'. Continue with it, or archive it and start a new one?"
- **Multiple active tasks**: Present a list with tier and current step. Ask user to choose.
- **No active tasks** (all archived): Proceed to Step 2.
- **`$ARGUMENTS` references a beads issue** (e.g., "rag-1234"): Read issue details with `bd show` and use as context for assessment.

## Step 2: Assessment

If `$ARGUMENTS` is empty: check conversation context and `git diff` for implicit task context. If context is available, infer the task description and present for confirmation. If no context, ask: "What would you like to work on?"

Apply the 3-factor depth assessment:

| Factor | Score | Criteria |
|--------|-------|----------|
| Scope Spread | 0-2 | 0: single file, 1: 2 layers, 2: 3+ layers |
| Design Novelty | 0-2 | 0: known pattern, 1: adaptation, 2: new subsystem |
| Decomposability | 0-2 | 0: atomic, 1: 2-3 subtasks, 2: phased breakdown |
| Bulk Modifier | -1 or 0 | -1: mechanical repetition, 0: normal |

```
score = scope_spread + design_novelty + decomposability + bulk_modifier
```

Present the assessment:

```
## Assessment: <title>

| Factor | Score | Rationale |
|--------|-------|-----------|
| Scope Spread | <0-2> | <one-line> |
| Design Novelty | <0-2> | <one-line> |
| Decomposability | <0-2> | <one-line> |
| Bulk Modifier | <-1 or 0> | <one-line or "N/A"> |
| **Total** | **<score>** | |

**Tier <N> (<Label>)** — <steps list>

Proceed with this assessment, or override? (e.g., "treat as Tier 2")
```

If score is on a boundary (1 or 3): "Score is on the Tier X/Y boundary. Consider overriding if this feels more like a [Feature/Fix]."

Handle user response:
- **Accept**: proceed with assessed tier
- **Override**: record override in `assessment.rationale`: "User override: Tier N -> Tier M. Original score: S". Use overridden tier.
- **More context**: user provides additional info, re-assess

## Step 3: State Initialization

1. Derive task name from title: lowercase, replace non-alnum with `-`, collapse consecutive hyphens, trim, truncate to 40 chars, add suffix if `.work/<name>/` exists
2. Capture `base_commit`: `git rev-parse HEAD`
3. Create `.work/<name>/` directory
4. Write `state.json` with tier-appropriate fields:
   - `steps` array of step objects per tier. Each entry: `{"name": "<step>", "status": "<status>"}`. T1 steps: assess, implement, review. T2 steps: assess, plan, implement, review. T3 steps: assess, research, plan, spec, decompose, implement, review. Initial: assess=`active`, all others=`not_started`.
   - `current_step`: `assess`
   - `assessment`: null (populated after assessment completes)
   - All other fields per state conventions
5. Create or claim beads issue:
   - T1-T2: `bd create --title="<title>" --type=task --priority=2` then `bd update <id> --status=in_progress`
   - T3: Create epic + initial issue
6. T2-T3: Create `docs/feature/<name>.md` summary file
7. T3: Create `.work/<name>/research/`, `plan/`, `specs/`, `streams/` directories
8. Populate `assessment` field with scoring result. Mark `assess` step as `completed`. Advance `current_step` to next step.

## Step 4: Delegate to Tier Command

After assessment and state initialization, delegate to the tier-specific command which contains the full step logic, instructions, and step router for that tier. Use the Skill tool to invoke the appropriate command:

| Tier | Command | Skill invocation |
|------|---------|-----------------|
| 1 | `/work-fix` | `Skill("work-fix")` |
| 2 | `/work-feature` | `Skill("work-feature")` |
| 3 | `/work-deep` | `Skill("work-deep")` |

The tier command will detect the active task (created in Step 3), read `current_step` from state.json, and route to the correct step. Do NOT pass `$ARGUMENTS` — the tier command reads context from state.json.

**Why delegate?** Each tier command has detailed step-by-step instructions, context-gathering patterns, and review protocols specific to that tier. Inlining condensed versions here would duplicate and diverge from the authoritative source.

## Escalation Handling

If during any step the task reveals higher complexity:

1. User says "escalate to Tier 2/3" (or the agent recognizes the need)
2. Follow escalation protocol: update `tier`, insert new steps before `implement` in canonical order, reset `implement`/`review` to `not_started`, set `current_step` to first new step
3. Create beads epic if escalating to T3, create `docs/feature/<name>.md` if escalating to T2-3
4. Append note to `assessment.rationale`
5. Re-read state and route to new `current_step`

## Skill Propagation

When spawning subagents:
- **Implementation agents**: `skills: [work-harness, code-quality]`
- **Review agents**: `skills: [code-quality]` only (review agents receive context from the review command, not from the harness skill)
