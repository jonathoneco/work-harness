---
description: "Review current work — runs specialist agents and tracks findings"
user_invocable: true
---

# Work Review

Run a structured code review on the active task. Spawns specialist review agents, collects findings into `.work/<name>/review/findings.jsonl`, creates beads issues for critical/important findings, and manages the finding lifecycle across re-reviews.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `$ARGUMENTS` — optional: specific files or commit range to review. If omitted, reviews all changes since task creation.

## Process

### Step 1: Detect Task and Scope

1. Find the active task via state discovery: scan `.work/` for `state.json` where `archived_at` is null
2. If no active task: "No active task found. Run /work to start one." — stop
3. Read `state.json` to get `base_commit`, `issue_id`, `task_name` (the directory name), `tier`
4. Determine review scope:
   - **Default**: all files changed since task creation:
     ```bash
     git diff <base_commit>..HEAD    # committed changes
     git diff                         # uncommitted changes
     ```
     This captures ALL changes across the task, even spanning multiple sessions/commits.
   - **If `$ARGUMENTS` specifies files or commit range**: use that scope instead
5. Read existing findings from `.work/<name>/review/findings.jsonl` for this task:
   - Filter lines where `task_name` matches the active task
   - For each finding ID, the last line with that ID is the current state
   - Identify all OPEN findings (for re-review context)
6. Determine if this is a **first review** or **re-review** based on whether OPEN findings exist

### Step 2: Select and Spawn Review Agents

Analyze changed files to determine which agents to spawn.

**If `review_routing` is configured in `.claude/harness.yaml`**: Use the routing table to select agents. Each entry maps file patterns to agent names. Match changed files against patterns and collect the set of agents to spawn.

**If no `review_routing` configured**: Use the `work-review` agent as the default reviewer for all files. The `security-reviewer` agent is always included if it exists.

For each selected agent:
- Spawn with `skills: [code-quality]` propagated at spawn time
  (do NOT propagate `work-harness` — review agents receive review context directly)
- Provide the diff and list of changed files as context
- If re-review: provide existing OPEN findings with instructions: "These findings were identified in a prior review. Check whether each has been fixed."

Launch all selected agents in parallel. Wait for all agents to complete.

### Step 3: Collect and Process Findings

Parse each agent's structured output. Agents return findings as:

```markdown
### [SEVERITY] Title
- **Category**: <category>
- **File**: <relative path>
- **Line**: <line number or "file-level">
- **Description**: <detailed explanation>
- **Suggested fix**: <what to change>
```

Assign sequential IDs AFTER collecting from ALL agents:
- Format: `f-YYYYMMDD-NNN` (e.g., `f-20260314-001`)
- Read `.work/<name>/review/findings.jsonl` to find last ID for today's date
- Increment from there, or start at 001 if first finding today
- IDs are monotonically increasing — never reuse or backfill

For each finding, construct the `findings.jsonl` record:
```json
{
  "id": "<assigned ID>",
  "task_name": "<from active task .work/ directory name>",
  "issue_id": "<from state.json>",
  "severity": "<critical|important|suggestion>",
  "category": "<from agent output>",
  "title": "<from agent output>",
  "description": "<from agent output>",
  "file": "<from agent output>",
  "line": "<from agent output, or null>",
  "status": "OPEN",
  "found_at": "<current ISO 8601 timestamp>",
  "found_by": "<agent kebab-case file name, e.g. code-reviewer>",
  "resolved_at": null,
  "resolution": null,
  "beads_issue_id": null
}
```

### Step 4: Create Beads Issues for Critical/Important Findings

For each finding with severity `critical` or `important`:
1. Create beads issue:
   ```bash
   bd create --title="[Review] <finding title>" --type=bug --priority=<P>
   ```
   - `critical` -> priority 1
   - `important` -> priority 2
2. Populate the finding record's `beads_issue_id` field before writing to JSONL

### Step 5: Re-review Reconciliation (re-review only)

Only runs if existing OPEN findings were passed to agents:

1. For each existing OPEN finding:
   - If agent returned `[FIXED]`: append new record with same finding ID, `status: "FIXED"`, `resolved_at` = now, `resolution` from agent
   - If agent returned `[PARTIAL]`: append new record with same finding ID, `status: "PARTIAL"`, `resolved_at` = now, `resolution` from agent
   - If agent did not mention it: finding remains OPEN (no new record needed)

2. For new findings from agents (not matching any existing finding):
   - Write with `status: "NEW"` (not "OPEN") to distinguish from first-pass findings
   - Create beads issues for critical/important NEW findings

### Step 6: Write Findings

1. Ensure review directory exists: `mkdir -p .work/<name>/review/`
2. Append all finding records to `.work/<name>/review/findings.jsonl` (one JSON object per line)
3. **NEVER overwrite or modify existing lines** — findings.jsonl is append-only
4. For re-review status updates (FIXED/PARTIAL), append NEW lines with the same finding ID but updated status. The latest line for a given ID is the current state.

### Step 7: Present Review Summary

```
## Review Summary: <task_name>

| Severity | Count | Status |
|----------|-------|--------|
| Critical | <N> | <blocked/all fixed> |
| Important | <N> | <N open, N fixed> |
| Suggestion | <N> | |
| **Total** | **<N>** | |

### Critical Findings (must fix)
- [f-20260314-001] <title> — <file>:<line>
  <one-line description>

### Important Findings (should fix)
- [f-20260314-002] <title> — <file>:<line>

### Suggestions
- [f-20260314-003] <title>

### Previously Open -> Now Fixed
- [f-20260313-001] <title> — Fixed
```

If critical findings remain OPEN:
"<N> critical findings require attention before this task can be archived."

If no findings: "Clean review — no findings."

### Step 8: Update Task State

If this review is running during the review step of the active task:

1. **Clean review** (no critical OPEN findings):
   - Set `reviewed_at` to current ISO 8601 timestamp in state.json (mechanical evidence that review ran)
   - Also update `updated_at` to current ISO 8601 timestamp (per state mutation rule)
   - Mark review step as `completed` (set `completed_at`, update `current_step`)
   - **Tier 1**: auto-archive (set `archived_at`, close beads issue with `bd close <issue_id>`)
   - **Tier 2-3**: task remains active until explicit `/work-archive`
   - **Wait for user acknowledgment** before proceeding

2. **Critical findings remain OPEN**:
   - Do NOT advance the step — review is incomplete
   - Suggest: "Fix the critical findings and re-run /work-review"

**Important distinction**: Review step completes when no CRITICAL findings are OPEN. But `/work-archive` enforces a stricter gate: all critical AND important findings must be FIXED or have `beads_issue_id`. Important findings do not block review step completion — they block archive.

## Key principles

- **Agents return findings, the command manages state.** Agents do NOT write to findings.jsonl. This command handles ID assignment, status management, and file writes.
- **Append-only.** findings.jsonl is never modified in place. Status updates are new lines with the same ID.
- **IDs assigned centrally.** Finding IDs are assigned AFTER all agents complete, preventing conflicts from parallel agents.
- **Re-review is additive.** Existing OPEN findings that agents don't mention remain OPEN. Only explicit [FIXED] or [PARTIAL] markers trigger status updates.
- **`found_by` uses file names.** Agent identification uses kebab-case file names (e.g., `code-reviewer`, `security-reviewer`), not nicknames.
