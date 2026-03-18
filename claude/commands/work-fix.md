---
description: "Quick fix — single-session bug fix with automatic review"
user_invocable: true
---

# /work-fix $ARGUMENTS

Single-session bug fix. Pre-selects Tier 1, runs assessment to confirm, then flows through assess -> implement -> review with auto-archive on clean review.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Detect Active Task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).
This command expects Tier 1. Apply tier-specific handling:
- **Matching tier (Tier 1)**: Resume at `current_step`. Jump to the Step Router.
- **Different tier**: "You have an active Tier <N> task '<name>'. Continue with it, or archive it and start a new one?"
- **No active task**: Proceed to assessment.

## Step 2: Assessment (Tier 1 pre-selected)

Apply the 3-factor depth assessment against `$ARGUMENTS` and conversation context:

| Factor | Score Range | Description |
|--------|------------|-------------|
| Scope Spread | 0-2 | Files/layers touched |
| Design Novelty | 0-2 | Known pattern vs new design |
| Decomposability | 0-2 | Single unit vs phased breakdown |
| Bulk Modifier | -1 or 0 | Mechanical repetition discount |

**If assessment agrees** (score 0-1): Proceed, noting "Assessment confirms Tier 1."

**If assessment disagrees** (score 2+): Present the assessment with mismatch:
"Assessment suggests Tier <M> but you invoked /work-fix (Tier 1). Proceed with Tier 1, or switch to Tier <M>?"
User decides — their choice is final. If they switch, escalate per the escalation protocol.

## Step 3: State Initialization

1. Derive name from title (kebab-case, max 40 chars, unique in `.work/`)
2. Capture `base_commit`: `git rev-parse HEAD`
3. Create `.work/<name>/` directory
4. Write `state.json`:
   - `tier`: 1
   - `steps`: array of step objects: `[{"name": "assess", "status": "completed"}, {"name": "implement", "status": "active"}, {"name": "review", "status": "not_started"}]`
   - `current_step`: `implement`
   - `assessment`: populated with scoring
   - `created_at`: current ISO 8601 timestamp
   - `updated_at`: same as `created_at`
   - `reviewed_at`: `null`
5. Create or claim beads issue:
   ```bash
   bd create --title="[Bug] <title>" --type=bug --priority=2
   bd update <id> --status=in_progress
   ```
6. Store `issue_id` in state.json

## Step Router

---

## Step Routing Table

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| implement | general-purpose | work-harness, code-quality | beads issues |
| review | inline (no agent spawn) | code-quality | diff since base_commit |

### Skill Injection (Path B — Prompt-Based)

Claude Code agent YAML frontmatter does not natively support `skills:`. When spawning agents, include explicit skill loading instructions in the prompt. Consult the routing table above for which skills each step requires, then inject them using these fragments:

**implement-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the implementation task below.

---

### When current_step = "implement"

1. **Search closed issues for context**: Consult the **Step Routing Table** for `implement`. Use a sub-agent to search for prior fixes to similar problems. Inject skills per the `implement-agent-skills` fragment:
   ```
   Agent(subagent_type="Explore", prompt="<implement-agent-skills injection>

   Search closed beads issues for context about <bug>.
   Run: bd search '<keyword>' --limit 10
   Then bd show each relevant match.
   Return: relevant files, patterns, key decisions.")
   ```

2. **Locate the problem**: Use error messages, stack traces, and closed issue context to find the relevant source files. Read them to understand the bug.

3. **Implement the fix**: Make the minimal change needed. Follow code-quality rules — fail closed, never swallow errors, never fabricate data, constructor injection, handle both branches.

4. **Run tests**: Execute the project's test command to verify the fix does not break anything. If the fix area lacks test coverage, add a test case.

5. **Futures**: If the fix reveals deferred enhancements or related issues, append to `.work/<name>/futures.md`.

6. **Git commit**: Stage and commit with conventional commit: `fix: <description>`

7. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`) for implement -> review: Present fix summary. STOP and wait for explicit approval. Tier 1 adaptations apply (no gate issue, no handoff prompt, no compaction prompt). On approval: update state.json in a single write — mark `implement` as `completed`, set `review` to `active`, update `current_step` to `review`.

### When current_step = "review"

**Inline mini-review** — lightweight anti-pattern check (NOT a full `/work-review`):

1. Read diff since `base_commit`:
   ```bash
   git diff <base_commit>..HEAD
   ```

2. Check for critical anti-patterns from the code-quality skill. Verify error handling is correct, no swallowed errors, no fabricated data, both branches handled.

3. **On clean review**: Mark `review` as `completed`. Auto-archive: set `archived_at` to current timestamp. Close beads issue:
   ```bash
   bd close <issue_id> --reason="Fixed: <what was wrong and what was changed>"
   ```

4. **On findings**: Report findings to user with file paths and suggested fixes. After user fixes, re-check the diff. Repeat until clean.

5. **Full review optional**: User can run `/work-review` explicitly for a full multi-agent review, but this is optional for Tier 1.

## Escalation Handling

If the user says "escalate to Tier 2" or "escalate to Tier 3" during implementation:

1. Update `tier` field (1 -> 2 or 1 -> 3)
2. Insert new steps before `implement` in canonical order
3. Reset `implement` and `review` to `not_started`
4. Set `current_step` to first new step (`plan` for T2, `research` for T3)
5. Create `docs/feature/<name>.md` summary file
6. If T3: create beads epic, set `beads_epic_id`
7. Append to `assessment.rationale`: "Escalated from Tier 1 to Tier <N> during implementation"
8. Re-read state and present the new step's interface

## Skill Propagation

Agent skills are determined by the **Step Routing Table** above. Each step
specifies the exact skills to propagate. The routing table is the single
source of truth for agent configuration — do not hardcode skill lists
in step instructions.

For the skill injection mechanism, see the **Skill Injection (Path B — Prompt-Based)**
section above. Skills are injected via explicit `Read` instructions in agent prompts
because Claude Code agent frontmatter does not support `skills:` natively.
