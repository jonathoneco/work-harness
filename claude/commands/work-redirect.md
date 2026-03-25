---
description: "Record a dead end — document what failed and pivot to a new direction"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Work Redirect

Document a dead end and pivot to a new direction. Preserves learning from failed approaches so future sessions do not repeat them.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `$ARGUMENTS` — reason for the redirect (brief description of why the current approach is being abandoned)

## Process

### Step 1: Find active task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).

- If no active task: "No active task. Run /work to start one."
- Read `state.json` to determine `current_step`

### Step 2: Gather details

If `$ARGUMENTS` is a brief phrase (fewer than ~20 words), prompt the user for:

- **What was tried** — the specific approach, tool, library, or architecture explored
- **Why it failed** — concrete reason (performance, complexity, incompatibility, cost, etc.)

If the conversation context already contains this information, synthesize it directly without prompting.

### Step 3: Draft dead-end entry

Prepare the entry for `.work/<name>/<step>/dead-ends.md` (create file if not exists, append if exists):

```markdown
## Dead End: <date>

**Step:** <current_step>
**Reason:** $ARGUMENTS

**What was tried:**
[Summarized from conversation context — what approach was attempted]

**Why it failed:**
[Summarized — what went wrong, what was learned]

**Pivot direction:**
[What to try next, based on conversation context]
```

### Step 4: Present for review

Present the draft to the user for approval before writing.

### Step 5: Write and commit

On approval:

1. Create directory if needed: `mkdir -p .work/<name>/<step>/`
2. Append the entry to `.work/<name>/<step>/dead-ends.md`
3. Git commit: `git add .work/<name>/ && git commit -m "docs: record dead end in <name> — <brief topic>"`

### Step 6: Optional futures capture

Ask: "Should any part of this be captured as a future enhancement?"

If yes, append to `.work/<name>/futures.md`:

```markdown
## <title>

**Horizon**: <next|quarter|someday>
**Domain**: <inferred from context>
**Identified**: <current date>

<2-4 sentence description: what the enhancement does, why it matters>

**Context**: <relative path to dead-ends.md entry>
**Prerequisites**: <what must be done first, or "None">
```

### Step 7: Return to work

After recording, ask the user what direction to try next:

1. **Continue in the same step** with a different approach
2. **Checkpoint and pause** — run `/work-checkpoint` to save progress

## Key principles

- **Dead ends are valuable.** They prevent future sessions from wasting time on the same approach. Write enough detail that someone reading the entry months later understands what happened.
- **This does NOT change task state.** The step remains active, the tier is unchanged. A redirect is informational — it documents what was tried.
- **Be concrete.** "It didn't work" is not a useful dead-end entry. Specify what was tried, what broke, and what the failure taught us.
- **Always record before pivoting.** Never abandon an approach without documenting it first.
