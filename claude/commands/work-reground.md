---
description: "Recover context — re-read task state and artifacts after a break or compaction"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Work Reground

Read-only context recovery. Loads the minimal set of artifacts needed to resume work on the active task. Use at the start of a new session or after context compaction.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `$ARGUMENTS` — optional task name. If omitted, auto-detect from `.work/`.

## Process

### Step 1: Find task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).

If `$ARGUMENTS` is provided, use `.work/<name>/state.json` directly. Otherwise, the discovery algorithm finds the active task (handles none, one, or multiple active tasks).

### Step 2: Read state

Read `.work/<name>/state.json`. Extract `tier`, `current_step`, `issue_id`, `title`.

### Step 3: Load minimal context based on tier and step

| Tier | What to Read |
|------|-------------|
| 1 | state.json + beans issue details (`bn show <issue_id>`) |
| 2 | state.json + plan document (if exists in `.work/<name>/`) + beans issue |
| 3 | state.json + current step's handoff prompt (if exists at `.work/<name>/<prev-step>/handoff-prompt.md`) + latest checkpoint resumption prompt |

For Tier 3, determine the previous step's handoff prompt path:
- Find the step before `current_step` in the `steps` array
- Check `.work/<name>/<prev-step>/handoff-prompt.md`
- Also check for the latest file in `.work/<name>/<current_step>/checkpoints/`

If a listed file does not exist, note its absence but continue with what is available.

### Step 4: Check for open findings

If `.work/<name>/review/findings.jsonl` exists, count OPEN findings for this task (last line per finding ID).

### Step 5: Present focused summary

```
## Regrounded: <name> (Tier <N>)

**Current step:** <step> (<status>)
**Last checkpoint:** <date> — "<resumption prompt excerpt>"
**Key files:** <list from checkpoint or handoff prompt>
**Open findings:** <N> (if any)
```

Keep the summary brief. The user can read individual files for more detail.

### Step 6: No state changes

This command is purely a context-loading operation. It does not modify state.json, create files, or update beans issues.

## Key principles

- **Minimal context, maximum orientation.** Load only what is needed for the current step. Earlier steps are summarized by their handoff prompts — do not re-read their raw artifacts.
- **Handoff prompts are primary.** When a previous step produced a handoff prompt, that is the most important file to read. It was written with full context specifically to bootstrap the next session.
- **Read-only, always.** This command only reads and summarizes. Use `/work-checkpoint` to save state.
- **Use subagents for parallel reads.** When loading multiple files, use parallel subagent reads to keep the main context window lean.
