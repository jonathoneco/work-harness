---
name: teams-protocol
description: "Agent Teams usage protocol — naming, task schema, teammate prompts, completion detection, failure handling"
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Teams Protocol

Protocol for using Agent Teams in the work harness for parallel agent workloads.
Teams replace manual Explore agent spawning with structured TeamCreate/TeamDelete
lifecycle management, shared task lists, and teammate prompts.

## 1. Team Naming Convention

Pattern: `{step}-{name}` where `{step}` and `{name}` come from state.json fields.

Examples:
- `research-agent-first-arch`
- `review-agent-first-arch` (future)

## 2. Task Schema

Each task in the shared task list follows this structure:

```json
{
  "title": "{topic-number}: {topic-title}",
  "description": "Research topic: {topic-description}\nOutput file: .work/{name}/research/{NN}-{topic-slug}.md\nFormat: Questions → Findings → Implications → Open Questions",
  "status": "pending"
}
```

Fields:
- **title**: Short identifier (`NN: topic-title`)
- **description**: Scope + output file path + expected note format
- **status**: `pending` → `in_progress` → `completed`

## 3. Teammate Prompt Template

Each teammate receives a prompt following the 6-section structure from spec 00:

```
## Identity
You are a research teammate investigating "{topic-title}" for task "{title}".

## Task Context
{Standard preamble — filled by lead from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/work-harness.md`

## Instructions
1. Claim your topic from the shared task list
2. Investigate: {topic-specific questions from task description}
3. Write findings to: .work/{name}/research/{NN}-{topic-slug}.md
4. Format: Questions → Findings → Implications → Open Questions
5. You own ONLY: .work/{name}/research/{NN}-{topic-slug}.md — do NOT write to any other file. The lead handles index.md and handoff-prompt.md.

## Output Expectations
Artifact: `.work/{name}/research/{NN}-{topic-slug}.md`
Format: Questions → Findings → Implications → Open Questions

## Completion
1. Mark your task as complete in the shared task list.
2. Return: `Topic: {topic-title} / Status: complete / Artifact: .work/{name}/research/{NN}-{topic-slug}.md / Summary: {1-sentence summary}`
```

Variables are filled from state.json: `{name}`, `{title}`, `{topic-title}`,
and topic-specific questions come from the task description in the shared task list.

## 4. Completion Detection

The lead monitors the shared task list for completion:

1. Poll for all tasks completed
2. Read each research note, verify content exists and follows the expected format
3. Generate `research/index.md` (lead responsibility — teammates do NOT write to index)
4. Generate `research/handoff-prompt.md` (lead responsibility — teammates do NOT write handoff)
5. Tear down team with `TeamDelete("{step}-{name}")`

## 5. Failure Handling

Case-by-case principles:

- **Output exists, task not marked complete**: If a teammate's output file exists
  with valid content but the task was not marked complete in the shared list, the
  lead can use the output. Mark the task complete manually.
- **Teammate fails entirely**: The lead reassigns the topic by creating a new task
  in the shared list, or investigates inline if the team is nearly done.
- **Systemic team failure**: If multiple teammates fail or the team infrastructure
  is unresponsive, tear down the team with `TeamDelete` and fall back to sequential
  Explore agents.
- **Research notes persist**: Notes written to `.work/` survive regardless of team
  state. Teams disappear on `/resume`, but the files remain on disk.
