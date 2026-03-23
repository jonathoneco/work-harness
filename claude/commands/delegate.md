---
description: "Delegate a sub-task to a specialist agent with proper context seeding"
user_invocable: true
---

# /delegate $ARGUMENTS

Delegate a sub-task to a specialist agent with proper context seeding. The description is natural language — the command infers the task type, constructs an appropriate agent prompt, and returns the output.

## Examples
- `/delegate research how Agent Teams handles session resume`
- `/delegate write tests for the context seeding protocol`
- `/delegate review the dispatcher changes for edge cases`

## Step 1: Route the Task

Match the first keyword(s) of `$ARGUMENTS` against this routing table:

| Pattern | Route To | Agent Config |
|---------|----------|-------------|
| "research" / "investigate" / "explore" / "find" / "search" | Explore agent | `subagent_type: "Explore"` |
| "review" / "check" / "audit" / "validate" | Review agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "write" / "create" / "implement" / "add" / "build" | Implementation agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "plan" / "design" / "architect" / "outline" | Plan agent | `subagent_type: "Plan"` |
| "test" / "verify" | Test agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| (ambiguous / no match) | General agent | `subagent_type: "general-purpose"`, `mode: "default"` |

Pattern matching is keyword-based on the first word(s) of the description. If ambiguous, default to general-purpose.

## Step 2: Build Context

### With Active Task
If `.work/` contains an active task (state.json where `archived_at` is null):

1. Read state.json for: name, title, tier, current_step, base_commit, beads_epic_id
2. Build the standard preamble:
   ```
   ## Task Context
   - Task: {name} (Tier {tier})
   - Title: {title}
   - Step: {current_step}
   - Base commit: {base_commit}
   - Epic: {beads_epic_id}
   ```
3. If `.claude/harness.yaml` exists, append stack context block

### Without Active Task
Skip the Task Context preamble. Use minimal context — just the user's description and skill injection.

## Step 3: Construct and Spawn Agent

Build the agent prompt following the 6-section structure:

```
## Identity
You are a delegate agent for the work harness.
Your task: {$ARGUMENTS}

## Task Context
{Standard preamble from Step 2, or omit if no active task}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
{If active task and route is write/create/implement/research/test: also include}
2. Read `claude/skills/work-harness.md`
{Plan/design/review routes receive code-quality only, per the spec 00 skill matrix.}

## Instructions
{$ARGUMENTS — the user's full description}

{If active task, include relevant context:}
- Current step artifacts are in `.work/{name}/{current_step}/`
- Task specs are in `.work/{name}/specs/`

## Output Expectations
Write artifacts to appropriate locations within the project.
Return a summary of what you did, including file paths for any artifacts created or modified.

## Completion
Return:
Task: {$ARGUMENTS (abbreviated)}
Status: complete
Artifacts:
- {path}: {description}
Summary: {what was done}
```

Spawn the agent:
```
Agent(
  description: "delegate {first 3-5 words of $ARGUMENTS}",
  prompt: {constructed prompt},
  mode: {from routing table},
  subagent_type: {from routing table}
)
```

## Step 4: Return Output

Present the agent's return to the user:
- Show the completion summary
- List artifacts created/modified
- If the agent failed or returned incomplete results, report what happened
