---
description: "Archive a completed task — verify completion and set archived_at"
user_invocable: true
---

# Work Archive

Archive a completed task. Verifies all steps are complete, checks finding triage status, generates an archive summary (Tier 3), and closes beads issues. The `.work/<name>/` directory remains in place with `archived_at` set — it is NOT deleted.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `$ARGUMENTS` — optional task name. If omitted, find active task via discovery.

## Process

### Step 1: Find the task to archive

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).

- If `$ARGUMENTS` specifies a name: use `.work/<name>/state.json`
- If no arguments: discover via the skill's algorithm (scan, filter active)
- If no active tasks: "No active tasks to archive."

### Step 2: Verify completion

Check that all steps in the `steps` array are `completed` or `skipped`:

- If any step is `active` or `not_started`: refuse with "Task is not complete. Current step: <step>. Complete all steps before archiving."

### Step 3: Check review evidence (Tier 2-3 only)

Verify that `/work-review` was actually run:

1. Check `reviewed_at` field in state.json — must be non-null
2. If null: "Review was never run for this task. Run `/work-review` before archiving."

### Step 4: Check finding triage gate (Tier 2-3 only)

Read `.work/<name>/review/findings.jsonl` for this task (filter by `task_name`):

1. For each finding ID, the last line with that ID is the current state
2. All `critical` severity findings must be `FIXED` or have a non-null `beads_issue_id` (deferred with tracking)
3. All `important` severity findings must be `FIXED` or have a non-null `beads_issue_id`
4. `suggestion` findings are NOT gated — they do not block archive

If untriaged critical/important findings exist:

```
Cannot archive — <N> findings need triage:
- <finding-id>: [CRITICAL] <title> (status: OPEN, no beads issue)
- <finding-id>: [IMPORTANT] <title> (status: OPEN, no beads issue)

Run /work-review to reconcile, or create beads issues for deferred findings.
```

### Step 5: Generate archive summary (Tier 3 only)

Write `.work/<name>/archive-summary.md`:

```markdown
# Archive Summary: <name>

**Tier:** <N>
**Duration:** <created_at> -> <archived_at>
**Sessions:** <N>
**Beads epic:** <epic_id>

## What Was Built
[Summarized from conversation context and step artifacts]

## Key Files
[List of files created/modified during this task]

## Findings Summary
- <N> total findings (<N> fixed, <N> deferred)

## Futures Promoted
[Any future enhancements from futures.md promoted to docs/futures/]
```

### Step 6: Deprecated table diff

1. Read `base_commit` from `.work/<name>/state.json`
2. Run: `git diff <base_commit>...HEAD -- .claude/rules/beads-workflow.md`
3. Parse the diff for new rows in the "Deprecated Approaches" table:
   - New rows are lines starting with `+|` that contain a pipe-delimited entry
   - Extract the "Deprecated" column value from each new row
   - Normalize to lowercase kebab-case (lowercase, strip parentheticals, strip text after `/`, replace spaces with hyphens, collapse consecutive hyphens)
4. If new deprecated entries found: store as `newly_deprecated` list for the staleness scan
5. If no diff or no new entries: `newly_deprecated` is empty (not an error)
6. If git diff fails: **STOP archive** — report the error and ask user to resolve

### Step 7: Staleness scan

1. Read `.claude/tech-deps.yml` (the tech manifest)
   - If file is missing: Ask the user: "No `.claude/tech-deps.yml` found. This file tracks technology dependencies for staleness scanning. Would you like to create it now? (yes/no)"
     - If **yes**: Create `.claude/tech-deps.yml` with a scaffold listing the project's key dependencies (infer from harness.yaml `stack.language`, `stack.framework`, `stack.database`, and any package manifests like `go.mod`, `package.json`, etc.). Format: YAML array of `{name, category, deps: []}` entries. Then continue the staleness scan with the new file.
     - If **no**: Skip staleness scan and proceed to Step 9.
   - If YAML parse fails: **STOP archive** — report parse error
2. Read the current deprecated approaches table from `.claude/rules/beads-workflow.md`
3. Build a set of deprecated technology identifiers (normalized)
4. **Declared dependency check**: For each manifest entry, for each `dep` in the entry's `deps` list, normalize and check against the deprecated set. If match: flag as "stale declared dependency"
5. **Content grep for newly deprecated** (only if `newly_deprecated` is non-empty): For each newly deprecated item, resolve all document paths (skills, rules, commands). Grep each file for the deprecated technology name (case-insensitive). Flag matches as "undeclared stale reference"
6. **Manifest completeness check**: For each deprecated technology in the table, grep all context documents for references. If a reference is found but the document has no corresponding `dep` in the manifest: flag as "manifest gap"
7. Produce staleness report:

```
## Staleness Report

### Stale Dependencies
| Document | Dep | Deprecated Entry | Action |
|----------|-----|-----------------|--------|

### Manifest Gaps
| Document | Found Reference | Suggested Dep |
|----------|----------------|---------------|

### Unresolved Entries
| Category | Name | Expected Path |
|----------|------|---------------|
```

### Step 8: Staleness report & issues

1. If staleness report is empty (no findings): Print "Staleness scan: clean (N documents checked)". Continue to next step.
2. If findings exist:
   - Print the full staleness report
   - For each stale finding, create a beads issue:
     ```bash
     bd create --title="[Housekeeping] <document>: stale <dep> reference" \
       --type=task --priority=3
     ```
   - For each manifest gap, create a beads issue:
     ```bash
     bd create --title="[Housekeeping] Update tech manifest: <document> uses <dep>" \
       --type=task --priority=4
     ```
   - Present findings to user
3. Findings do NOT block archive completion — they are tracked as separate issues. Only scan ERRORS (missing manifest, YAML parse, git diff failure) block the archive.

### Step 9: Set archived_at

Update `state.json`:
- Set `archived_at` to current ISO 8601 timestamp
- Update `updated_at`

Update `docs/feature/<name>.md` (if it exists):
- Replace `**Status:** active` with `**Status:** archived`
- Append a `## Completed` section with: archive date, number of findings, key files changed, and a 1-2 sentence summary of what was delivered

### Step 10: Close beads issue/epic

- **Tier 1-2**: `bd close <issue_id> --reason="Task archived: <title>"`
- **Tier 3**: Close all open issues under the epic, then close the epic:
  ```bash
  bd list --status=open --label=workflow:<name>  # find remaining open issues
  bd close <issue-ids> --reason="Task archived"
  bd close <epic_id> --reason="Task archived: <title>"
  ```

### Step 11: Promote futures

If `.work/<name>/futures.md` exists and has entries (also check legacy path `.work/<name>/research/futures.md`):

1. Create `docs/futures/` directory if needed
2. Copy to `docs/futures/<name>.md`
3. Skip entries already marked as adopted

### Step 12: Git commit

```bash
git add .work/<name>/
git add docs/futures/<name>.md  # if futures were promoted
git commit -m "chore: archive <name>"
```

### Step 13: Report

```
Task `<name>` archived.

Location: .work/<name>/ (archived_at set)
Beads: <issue_id> closed

<summary stats if Tier 3: N steps, N sessions, N findings>
```

## Key principles

- **Verify before archiving.** Never archive a task with incomplete steps or untriaged findings without explicit checks. The verification gates exist to catch forgotten work.
- **The `.work/<name>/` directory is NOT deleted.** Archived tasks remain with `archived_at` set. State discovery filters them out.
- **Finding triage gate is strict.** All critical AND important findings must be FIXED or have a `beads_issue_id`. Suggestions are not gated. This is different from the review step gate (which only checks critical).
- **Futures promotion is automatic.** If futures were captured during the task, they are promoted to `docs/futures/` at archive time for discovery by future tasks.
