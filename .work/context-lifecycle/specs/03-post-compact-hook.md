# Spec 03: PostCompact Hook (C3)

**Component**: C3 | **Scope**: Small | **Phase**: 1 | **Dependencies**: spec 00

## Overview

A PostCompact hook that mechanically injects a re-grounding reminder after context compaction. This is HOOK-DRIVEN (deterministic, fires every time) rather than PROMPT-DRIVEN (best-effort, subject to drift). The hook outputs a system message suggesting re-invocation — it does not execute skills directly.

## Implementation Steps

### Step 1: Create the hook script

**File**: `scripts/hooks/post-compact.sh`

**Behavior**:
1. Scan `.work/*/state.json` for files where `archived_at` is `null`
2. For each active task, read `name`, `tier`, and `current_step`
3. Determine the tier-appropriate command:
   - Tier 1 → `/work-fix`
   - Tier 2 → `/work-feature`
   - Tier 3 → `/work-deep`
4. Output a re-grounding suggestion

**Script** (POSIX sh):
```sh
#!/bin/sh
# PostCompact hook: suggest re-grounding after context compaction

found=0

for state_file in .work/*/state.json; do
    [ -f "$state_file" ] || continue

    # Check if task is active (archived_at is null)
    archived=$(grep -o '"archived_at": *null' "$state_file")
    [ -z "$archived" ] && continue

    # Extract fields
    name=$(grep -o '"name": *"[^"]*"' "$state_file" | head -1 | sed 's/.*: *"//;s/"//')
    tier=$(grep -o '"tier": *[0-9]*' "$state_file" | head -1 | sed 's/.*: *//')
    step=$(grep -o '"current_step": *"[^"]*"' "$state_file" | head -1 | sed 's/.*: *"//;s/"//')

    # Map tier to command
    case "$tier" in
        1) cmd="work-fix" ;;
        2) cmd="work-feature" ;;
        3) cmd="work-deep" ;;
        *) cmd="work-reground" ;;
    esac

    echo "Active task: $name (step: $step). Run /$cmd to re-ground."
    found=1
done

# Silent exit if no active tasks (correct behavior, not a fallback)
exit 0
```

**Acceptance criteria**:
- Script is POSIX sh compatible (no bashisms)
- Script is executable (`chmod +x`)
- Outputs one line per active task
- Outputs nothing if no active tasks exist
- Outputs nothing if `.work/` directory doesn't exist
- Always exits 0 (hook errors must not block compaction)

### Step 2: Register the hook in settings.json

**File**: `.claude/settings.json`

Add a PostCompact hook entry to the existing `hooks` object, matching the nested format used by existing hooks:

```json
{
  "hooks": {
    "PostCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/hooks/post-compact.sh"
          }
        ]
      }
    ]
  }
}
```

**Acceptance criteria**:
- Hook is registered under `PostCompact` event
- Uses the existing nested format: `matcher` + `hooks` array of `{type, command}` objects
- Matcher is `""` (empty string = match all, consistent with existing SessionStart hook)
- Command path is relative to project root
- Existing hooks are preserved (add to the object, don't replace)

## Interface Contracts

**Exposes**:
- System message after compaction: `"Active task: <name> (step: <step>). Run /<cmd> to re-ground."`
- The message appears at the END of the context window (post-compaction position = highest attention)

**Consumes**:
- `.work/*/state.json` — reads `name`, `tier`, `current_step`, `archived_at`
- Spec 00: state.json contract for field names

**Interaction with C2 (self-re-invocation)**:
- C3 handles the compaction path → user ran `/compact`, hook fires, suggests re-invocation
- C2 handles the inline-continue path → user says "continue", agent calls Skill()
- They are complementary, not redundant

## Files to Create/Modify

| File | Action |
|------|--------|
| `scripts/hooks/` | **Create directory** (does not exist yet) |
| `scripts/hooks/post-compact.sh` | **Create** |
| `.claude/settings.json` | **Modify** — add PostCompact hook entry |

## Testing Strategy

- **Manual test**: Run the script directly in a shell with an active task present, verify output
- **Manual test**: Run with no active tasks, verify silent exit
- **Manual test**: Run with `.work/` missing, verify silent exit
- **shellcheck**: Run `shellcheck scripts/hooks/post-compact.sh` to verify POSIX compliance
- **Integration test**: After hook registration, run `/compact` and verify the message appears

## Edge Cases

| Case | Behavior |
|------|----------|
| Multiple active tasks | Output one line per task (unusual but possible during escalation) |
| No active tasks | Silent exit (exit 0, no output) |
| `.work/` doesn't exist | Silent exit (glob pattern fails, loop body never runs) |
| Malformed state.json | grep patterns fail silently, task skipped |
| state.json with archived_at set | Skipped (not active) |

## Deferred Question Resolution

**Q3 — PostCompact hook details**:
- **Error handling**: Always exit 0. The hook is advisory — errors in the hook must never prevent compaction from completing. If grep/sed fail on a malformed file, that task is silently skipped.
- **Output format**: Single line per active task: `Active task: <name> (step: <step>). Run /<cmd> to re-ground.`
- **Multiple active tasks**: Show all. This is unusual (typically one active task) but possible during tier escalation or if a task was left unarchived.
