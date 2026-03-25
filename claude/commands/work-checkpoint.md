---
description: "Save a checkpoint — captures progress for session continuity"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Work Checkpoint

Save current session progress for continuity across sessions. Optionally mark the current step as complete and advance to the next step.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `[--step-end]` — if present, marks the current step as completed and advances to the next step.

## Process

### Step 1: Find active task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).

- If no active task: "No active task. Run /work to start one."
- If multiple active tasks: list them and ask user to specify
- Read `state.json` to determine `current_step` and tier

### Step 2: Generate checkpoint file

Create `.work/<name>/<step>/checkpoints/<YYYY-MM-DD-HHMMSS>.md`:

```markdown
# Checkpoint: <step> — <YYYY-MM-DD HH:MM>

## Accomplished This Session
- [Summarize what was done based on conversation context]
- [Files created or modified]
- [Decisions made]

## Files Modified
- `path/to/file` — brief description of changes

## Remaining Work
- [What still needs to be done in this step]
- [Incomplete items or next steps]

## Open Questions
- [Unresolved questions or decisions pending user input]

## Resumption Prompt
> [A self-contained prompt that a new Claude Code session could use to pick up
> exactly where this one left off. Include: what was accomplished, what's next,
> key files to read first, any decisions currently in flight. This prompt should
> be detailed enough that the next session needs no additional context beyond
> reading the referenced files.]
```

Synthesize each section from conversation context. The **Resumption Prompt** is the most important section — it must be self-contained and actionable.

### Step 3: Present for review

**Before writing the file**, present the draft to the user — specifically highlight the **Resumption Prompt** section. Ask: "Here's the draft checkpoint. Does the resumption prompt capture where we are? Anything to add or correct?"

**Do NOT write the checkpoint file until the user approves the content.**

### Step 4: Write checkpoint and update state

On approval:

1. Create the checkpoint directory if needed: `mkdir -p .work/<name>/<step>/checkpoints/`
2. Write the checkpoint file
3. Update `state.json`:
   - Add session entry to `sessions` array: `{"started_at": "<ISO 8601>", "checkpoint_file": "<step>/checkpoints/<timestamp>.md"}`
   - Update `updated_at`
4. Git commit: `git add .work/<name>/ && git commit -m "chore: checkpoint <name> (<step>)"`

### Step 5: If `--step-end` is specified

Follow the **step-transition** protocol (`claude/skills/work-harness/step-transition.md`) for the step advancement, with these checkpoint-specific additions:

#### 5a: Generate handoff prompt (Tier 3 only)

Write `.work/<name>/<step>/handoff-prompt.md`:

```markdown
# Handoff: <step> -> <next-step>

## What This Step Produced
- [Summary of all deliverables from this step]
- [Key artifacts and their file paths]

## Key Artifacts
| File | Purpose |
|------|---------|
| `.work/<name>/<step>/...` | Description |
| `docs/feature/<name>.md` | Summary file |

## Decisions Made
- [Decision 1 — rationale]

## Open Questions Carried Forward
- [Questions the next step needs to address]

## Instructions for Next Step (<next-step>)
[Explicit, actionable instructions for what the next session should do.
Include: what to read first, what to produce, constraints from this step.]
```

**Present handoff prompt for user approval before advancing step state.**

#### 5b: Advance step via step-transition protocol

On approval, perform the state update as a single atomic write per the step-transition protocol:
- Mark current step `completed` with `completed_at`
- Set next step to `active` with `started_at`
- Update `current_step` and `updated_at`
- For Tier 3: create gate issue, record `gate_id` in step status

If this was the last step:
- Tier 1: auto-archive (set `archived_at`, close beans issue)
- Tier 2-3: task remains active until `/work-archive`

#### 5c: Git commit

```bash
git add .work/<name>/
git commit -m "chore: complete <step> for <name>"
```

### Tier adaptation

- **Tier 1**: Checkpoints are rare (single-session). Skip handoff prompts on `--step-end`.
- **Tier 2**: Checkpoints at session boundaries. Handoff prompts optional on `--step-end`.
- **Tier 3**: Full checkpoint + handoff prompt + gate issue mechanism on `--step-end`.

## Key principles

- **The resumption prompt is everything.** A checkpoint without a good resumption prompt is just a log entry. Invest time in making it self-contained and actionable.
- **Handoff prompts bridge sessions.** The current session has all the context — the next session has none. The handoff prompt is the only bridge.
- **Always present for review.** Never commit checkpoint or handoff content without user sign-off.
- **Step advancement is one-way.** Completing a step cannot be undone. If the user needs to revisit, they update state.json manually.
