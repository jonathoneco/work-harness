# 00: Cross-Cutting Contracts

Shared conventions consumed by all enforcement components.

## Hook Structure Convention

All hooks follow the same skeleton:

```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)

# 1. Prevent infinite loop on stop hooks
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# 2. Extract working directory
CWD=$(echo "$INPUT" | jq -r '.cwd')

# 3. Early exit if no .work/ directory
if [ ! -d "$CWD/.work" ]; then
  exit 0
fi

# 4. Hook-specific logic
# ...

# 5. Exit codes:
#    0 = allow (no issues found)
#    2 = block (violation detected)
```

## Exit Code Contract

| Code | Meaning | When to Use |
|------|---------|-------------|
| 0 | Allow | No violations, or not applicable |
| 2 | Block | Critical violation that must be fixed |

Stderr messages are displayed to the user when exit 2 fires. Keep them actionable: state the problem and suggest the fix command.

## State.json Schema (Additions)

New fields added by this work:

```json
{
  "updated_at": "2026-03-15T10:00:00Z",
  "reviewed_at": "2026-03-15T10:00:00Z"
}
```

### `updated_at`

- **Type**: ISO 8601 timestamp string
- **Set by**: every state.json mutation (any command that writes state.json must update this)
- **Initial value**: set to `created_at` at task creation
- **Graceful handling**: hooks must handle absent `updated_at` (pre-existing tasks created before this field was added). If absent, skip checks that depend on it.

### `reviewed_at`

- **Type**: ISO 8601 timestamp string or `null`
- **Initial value**: `null` (set at task creation)
- **Set by**: `/work-review` command on successful completion (even if 0 findings)
- Re-running `/work-review` overwrites the timestamp with the current time
- **Graceful handling**: hooks must handle absent `reviewed_at` (pre-existing tasks). If absent AND task has no `reviewed_at` key at all, skip review verification for that task.

### `docs_path` (deprecated)

- **Type**: string (file path) — formerly pointed to `docs/feature/<name>/` directory
- **Status**: Deprecated by Component 8 (docs cleanup). New tasks should NOT set this field.
- **Migration**: existing tasks may still have it. Hooks should ignore it — use `.work/<name>/specs/` for spec file validation instead.
- **Removal**: will be cleaned up during W-14 (doc migration)

### `steps[].gate_id`

- **Type**: string (beads issue ID) or absent
- **Set by**: auto-advancement logic when creating gate issues
- **Applicable steps**: research, plan, spec, decompose (not applicable to other steps)

### `steps[]` Object Schema

Each entry in the `steps` array has this structure:

```json
{
  "name": "string",           // Step identifier (e.g., "research", "plan", "spec")
  "status": "string",         // One of: "not_started", "active", "completed", "skipped"
  "gate_id": "string",        // Optional. Beads issue ID, set by auto-advancement
  "started_at": "string",     // Optional. ISO 8601, set when step becomes active
  "completed_at": "string"    // Optional. ISO 8601, set when step is completed
}
```

### `sessions` Array (optional)

```json
"sessions": [
  { "started_at": "ISO 8601", "checkpoint_file": "path/to/checkpoint.md" }
]
```

Set by `/work-checkpoint`. Tracks session boundaries for multi-session tasks.

### State Initialization

When a task is created, state.json must include:
- `created_at`: current ISO 8601 timestamp
- `updated_at`: same as `created_at` (updated on every subsequent mutation)
- `reviewed_at`: `null` (set only by `/work-review`)

### Existing Fields Validated

- `current_step`: string, must match one `steps[].name`
- `steps[].status`: one of `"not_started"`, `"active"`, `"completed"`, `"skipped"`
- `tier`: integer 1-3
- `archived_at`: null (active) or ISO timestamp (archived)

### Numbering Note

**Components 1-6** refer to the enforcement infrastructure built by this work. **Steps 1-7** (assess, research, plan, spec, decompose, implement, review) refer to the `/work-deep` workflow stages. These are independent numbering systems.

## Active Task Detection

Reusable pattern across all hooks:

```bash
for state_file in "$CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue
  archived=$(jq -r '.archived_at // "null"' "$state_file")
  [ "$archived" = "null" ] || continue
  # Process active task...
done
```

**Multiple active tasks**: Hooks iterate all active tasks in `.work/` independently. Each task is validated separately — a violation in any one task triggers the block.

## Path Conventions

- State files: `.work/<name>/state.json`
- Handoff prompts: `.work/<name>/<step>/handoff-prompt.md`
- Research index: `.work/<name>/research/index.md`
- Spec files: `.work/<name>/specs/NN-<slug>.md` (working artifacts)
- Architecture: `.work/<name>/specs/architecture.md`
- Feature summary: `docs/feature/<name>.md` (single file, not directory)
- Futures: `.work/<name>/futures.md` (task-level, any step can append)
- Promoted futures: `docs/futures/<name>.md`
- Stream agent prompts: `.work/<name>/streams/<stream-letter>.md`
- Findings: `.work/<name>/review/findings.jsonl`

### Step-to-Directory Mapping

| Step name | Directory / path | Notes |
|-----------|-----------------|-------|
| `spec` | `specs/` | Plural — specs + architecture live here |
| `decompose` | `streams/handoff-prompt.md` | Handoff lives under `streams/`, not `decompose/` |
| All others | Directory matches step name | e.g., `research/`, `plan/`, `implement/` |

## State Mutation Rule

Every command that mutates state.json must update the `updated_at` field to the current ISO 8601 timestamp.

## Hook Registration

All new hooks added to `.claude/settings.json`. PostToolUse hooks use `matcher: "Write|Edit"`. Stop hooks use `matcher: ""`.

New hooks are appended to existing arrays — never replace existing hooks.

## Dependency Order

Components 1-3 (hooks) and 5 (bugfix) are independent — implement in parallel.
Component 4 (command auto-advancement) depends on hooks being deployed first.
Components 7-9 (harness QoL) are independent of hooks — implement in parallel with Components 1-3.
