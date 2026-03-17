---
description: "Build a feature — plan, implement, and review in 1-2 sessions"
user_invocable: true
---

# /work-feature $ARGUMENTS

Build a feature in 1-2 sessions. Pre-selects Tier 2, runs assessment to confirm, then flows through assess -> plan -> implement -> review.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Detect Active Task

Scan `.work/` for `state.json` files where `archived_at` is null.

- **Active Tier 2 task exists**: Resume it. Read `current_step` and jump to the Step Router.
- **Active task of different tier exists**: "You have an active Tier <N> task '<name>'. Continue with it, or archive it and start a new one?"
- **No active task**: Proceed to assessment.
- **`$ARGUMENTS` references a beads issue**: Read issue details with `bd show`.

## Step 2: Assessment (Tier 2 pre-selected)

Apply the 3-factor depth assessment against `$ARGUMENTS` and conversation context.

**If assessment agrees** (score 2-3): Proceed, noting "Assessment confirms Tier 2."

**If assessment disagrees**: Present mismatch and ask user. Their choice is final.

## Step 3: State Initialization

1. Derive name from title (kebab-case, max 40 chars, unique)
2. Capture `base_commit`: `git rev-parse HEAD`
3. Create `.work/<name>/` directory
4. Write `state.json`:
   - `tier`: 2
   - `steps`: array of step objects: `[{"name": "assess", "status": "completed"}, {"name": "plan", "status": "active"}, {"name": "implement", "status": "not_started"}, {"name": "review", "status": "not_started"}]`
   - `current_step`: `plan`
   - `assessment`: populated with scoring
   - `created_at`: current ISO 8601 timestamp
   - `updated_at`: same as `created_at`
   - `reviewed_at`: `null`
5. Create beads issue:
   ```bash
   bd create --title="[Feature] <title>" --type=feature --priority=2
   bd update <id> --status=in_progress
   ```
6. Create `docs/feature/<name>.md` summary file
7. Store `issue_id` in state.json

## Step Router

### When current_step = "plan"

1. **Search for context**: Check closed beads issues and existing code for related work:
   ```
   Agent(subagent_type="Explore", prompt="Search beads issues and code for context about <feature>.
   Run: bd search '<keyword>' --limit 10
   Return: related files, patterns, prior decisions.")
   ```

   **If the plan step involves substantial research** (spawning multiple agents, analyzing external data, producing intermediate artifacts): create `.work/<name>/research/` and direct all agents to write outputs there. Agent prompts must include an explicit output path: `"Write results to .work/<name>/research/<filename>.md"`. Never write task artifacts to `/tmp/` — they must be task-scoped and persistent.

2. **Write approach document**: Create a lightweight plan (NOT a full architecture doc):
   - **Files to modify/create** — list with one-line descriptions
   - **Approach** — 1-2 paragraphs describing the implementation strategy
   - **Test strategy** — how to verify the feature works
   - **Subtask breakdown** — if the feature decomposes into 2-3 subtasks, create beads issues:
     ```bash
     bd create --title="[Service] <subtask>" --type=task --priority=2
     bd create --title="[API] <subtask>" --type=task --priority=2
     bd dep add <api-id> <service-id>  # API depends on Service
     ```

3. **Futures**: If planning reveals deferred enhancements, append to `.work/<name>/futures.md`.

4. **Present for review**: Show the plan to the user. End with: "Ready to advance to **implement**? (yes/no)". Do NOT update state.json in the same turn as presenting the plan.

5. **If user asks questions or gives feedback**: Answer, then re-present: "Ready to advance to **implement**? (yes/no)"

6. **On explicit approval** (yes, proceed, approve, lgtm, go ahead, continue): Advance — mark `plan` as `completed`, set `implement` to `active`, update `current_step`.

7. **Context compaction** (recommended): Tell the user: "Plan complete. Recommend: `/compact` then `/work-feature` to start **implement** with clean context." If user continues without compacting, re-invoke via `Skill('work-feature')`, then proceed normally.

### When current_step = "implement"

1. **Subtask execution**: If plan created subtasks, work through them via `bd ready`:
   ```bash
   bd ready                              # Find next unblocked task
   bd update <id> --status=in_progress   # Claim it
   # ... implement ...
   bd close <id> --reason="Implemented: <summary>"
   ```

2. **Context**: Read the plan document. Search closed issues for patterns.

3. **Skill propagation**: When spawning implementation subagents: `skills: [work-harness, code-quality]`

4. **Testing**: Run the project's test command after each logical unit. Commit with conventional commits.

5. **Futures**: If implementation reveals deferred enhancements, append to `.work/<name>/futures.md`.

6. **Multi-session**: If work spans sessions, suggest `/work-checkpoint` before ending. On resume, `/work-feature` detects the active task and continues.

7. **Present results**: When all implementation is complete, summarize what was done. End with: "Ready to advance to **review**? (yes/no)". Do NOT update state.json in the same turn.

8. **If user asks questions or gives feedback**: Answer, then re-present: "Ready to advance to **review**? (yes/no)"

9. **On explicit approval**: Mark `implement` as `completed`, set `review` to `active`.

10. **Context compaction** (recommended): Tell the user: "Implementation complete. Recommend: `/compact` then `/work-feature` to start **review** with clean context." If user continues without compacting, re-invoke via `Skill('work-feature')`, then proceed normally.

### When current_step = "review"

1. **Run review**: Instruct the user to run `/work-review` for a full multi-agent review.

2. **On clean review** (no critical OPEN findings): Mark `review` as `completed`. Task remains active until explicit `/work-archive`.

3. **On findings**: Address critical and important findings. Re-run `/work-review` after fixes.

4. **Archive**: When ready, run `/work-archive` to close the task. The archive gate requires all critical AND important findings to be FIXED or have `beads_issue_id`.

## Escalation Handling

If the task reveals Tier 3 complexity during implementation:

1. Update `tier` to 3
2. Insert `research`, `spec`, `decompose` steps before `implement`
3. Reset `implement` and `review` to `not_started`
4. Set `current_step` to `research`
5. Create beads epic, set `beads_epic_id`
6. Create research/specs/streams directories in `.work/<name>/`
7. Append escalation note to `assessment.rationale`
