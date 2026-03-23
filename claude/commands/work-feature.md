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

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).
This command expects Tier 2. Apply tier-specific handling:
- **Matching tier (Tier 2)**: Resume at `current_step`. Jump to the Step Router.
- **Different tier**: "You have an active Tier <N> task '<name>'. Continue with it, or archive it and start a new one?"
- **No active task**: Proceed to assessment.

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

---

## Step Routing Table

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| plan | general-purpose | code-quality | beads issues, managed docs |
| implement | general-purpose | code-quality, work-harness | plan document, managed docs |
| review | (delegates to /work-review) | code-quality | diff since base_commit |

### Skill Injection (Path B — Prompt-Based)

Claude Code agent YAML frontmatter does not natively support `skills:`. When spawning agents, include explicit skill loading instructions in the prompt. Consult the routing table above for which skills each step requires, then inject them using these fragments:

**plan-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the planning task below.

**implement-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the implementation task below.

**review-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the review task below.

---

### When current_step = "plan"

### Dispatch: Plan Agent

1. **Construct prompt**: Read `claude/skills/work-harness/step-agents.md` for the plan agent template.
   Fill variables from state.json:
   - `{name}` ← state.name
   - `{title}` ← state.title
   - `{tier}` ← state.tier
   - `{current_step}` ← state.current_step
   - `{base_commit}` ← state.base_commit
   - `{beads_epic_id}` ← state.beads_epic_id (if null, omit the Epic line from the preamble)

2. **Spawn agent**:
   ```
   Agent(
     description: "plan {name-abbreviated}",
     prompt: {constructed prompt},
     mode: "default",
     subagent_type: "general-purpose"
   )
   ```

3. **Read return**: Parse the agent's completion signal (see completion format in `claude/skills/work-harness/step-agents.md`).

4. **Verify artifacts**: Check that expected artifacts exist:
   - `.work/<name>/specs/architecture.md`
   - `.work/<name>/plan/handoff-prompt.md`
   - `docs/feature/<name>.md`
   If artifacts missing: re-spawn the agent (preserve existing partial artifacts per spec 00 §7).

5. **Present to user**: Show the agent's summary. Include:
   - What the agent produced (artifact list with paths)
   - Key decisions or notable items
   - Ask: "Review the artifacts, or proceed to validation?"

6. **Handle user feedback**:
   - If user approves or says "proceed": continue to auto-advance.
   - If user has feedback: construct re-spawn prompt with a "Previous Attempt" section listing artifacts written and user feedback verbatim, inserted between Rules and Instructions. Re-spawn the agent. Return to step 3.
   - After 2 re-spawns with unresolved feedback, ask the user how to proceed.

7. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`) for plan -> implement: Present the plan to the user. STOP and wait for explicit approval. On approval: mark `plan` as `completed`, set `implement` to `active`, update `current_step` in a single state.json write. Tier 2 adaptations apply (gate issue optional, compaction recommended). Tell the user: "Plan complete. Recommend: `/compact` then `/work-feature` to start **implement** with clean context." If user continues without compacting, re-invoke via `Skill('work-feature')`, then proceed normally.

### When current_step = "implement"

1. **Subtask execution**: If plan created subtasks, work through them via `bd ready`:
   ```bash
   bd ready                              # Find next unblocked task
   bd update <id> --status=in_progress   # Claim it
   # ... implement ...
   bd close <id> --reason="Implemented: <summary>"
   ```

2. **Context**: Read the plan document. Search closed issues for patterns.

3. **Implementation subagents**: When spawning implementation subagents for subtasks, construct prompts with the standard 6-section structure:

   ```
   ## Identity
   You are an implementation agent for the work harness.
   Your task: {one-line summary of subtask}

   ## Task Context
   - Task: {name} (Tier {tier})
   - Title: {title}
   - Step: implement
   - Base commit: {base_commit}
   - Issue: {issue_id}
   ```

   If `.claude/harness.yaml` exists, append the stack context block:

   ```
   ## Stack Context
   - Language: {stack.language}
   - Framework: {stack.framework}
   - Database: {stack.database}
   - Build commands: {stack.build_commands}
   ```

   Then include Rules (inject skills per the `implement-agent-skills` fragment), Instructions (subtask details + relevant plan sections), Output Expectations, and Completion (standard completion signal format).

4. **Testing**: Run the project's test command after each logical unit. Commit with conventional commits.

5. **Futures**: If implementation reveals deferred enhancements, append to `.work/<name>/futures.md`.

6. **Multi-session**: If work spans sessions, suggest `/work-checkpoint` before ending. On resume, `/work-feature` detects the active task and continues.

7. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`) for implement -> review: Present implementation summary. STOP and wait for explicit approval. On approval: mark `implement` as `completed`, set `review` to `active` in a single state.json write. Tell the user: "Implementation complete. Recommend: `/compact` then `/work-feature` to start **review** with clean context." If user continues without compacting, re-invoke via `Skill('work-feature')`, then proceed normally.

### When current_step = "review"

1. **Run review**: Instruct the user to run `/work-review` for a full multi-agent review.

2. **On clean review** (no critical OPEN findings): Mark `review` as `completed`. Task remains active until explicit `/work-archive`.

3. **On findings**: Address critical and important findings. Re-run `/work-review` after fixes.

4. **Futures**: If review reveals deferred enhancements or improvements, append to `.work/<name>/futures.md`.

5. **Archive**: When ready, run `/work-archive` to close the task. The archive gate requires all critical AND important findings to be FIXED or have `beads_issue_id`.

## Escalation Handling

If the task reveals Tier 3 complexity during implementation:

1. Update `tier` to 3
2. Insert `research`, `spec`, `decompose` steps before `implement`
3. Reset `implement` and `review` to `not_started`
4. Set `current_step` to `research`
5. Create beads epic, set `beads_epic_id`
6. Create research/specs/streams directories in `.work/<name>/`
7. Append escalation note to `assessment.rationale`

## Skill Propagation

Agent skills are determined by the **Step Routing Table** above. Each step
specifies the exact skills to propagate. The routing table is the single
source of truth for agent configuration — do not hardcode skill lists
in step instructions.

For the skill injection mechanism, see the **Skill Injection (Path B — Prompt-Based)**
section above. Skills are injected via explicit `Read` instructions in agent prompts
because Claude Code agent frontmatter does not support `skills:` natively.
