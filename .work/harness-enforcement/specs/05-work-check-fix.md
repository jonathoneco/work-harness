# 05: work-check.sh Timestamp Fix

## Overview

Fix the checkpoint staleness detection in `work-check.sh`. Currently checks binary existence; should check recency.

**Prerequisite:** state.json must have an `updated_at` field (declared in spec 00). All state mutations update this field. If `updated_at` is missing, the hook skips the staleness check for that task.

## Current Behavior

```bash
has_checkpoint=$(find "$task_dir" -path '*/checkpoints/*.md' 2>/dev/null | head -1)
if [ -z "$has_checkpoint" ]; then
  echo "Note: Task '$task_name' (Tier $tier) has no checkpoints..."
fi
```

This warns if zero checkpoints exist, but passes if ANY checkpoint exists — even a stale one from days ago.

## Target Behavior

```bash
# Get state.json updated_at timestamp (epoch seconds)
updated_at=$(jq -r '.updated_at // empty' "$state_file")
if [ -z "$updated_at" ]; then
  continue  # No timestamp to compare against
fi
# Validate ISO 8601 before parsing
if ! echo "$updated_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'; then
  continue  # Invalid format, skip
fi
updated_epoch=$(date -d "$updated_at" +%s 2>/dev/null || continue)

# Get latest checkpoint timestamp (file modification time)
latest_checkpoint=$(find "$task_dir" -path '*/checkpoints/*.md' -printf '%T@\n' 2>/dev/null | sort -rn | head -1)

if [ -z "$latest_checkpoint" ]; then
  echo "Note: Task '$task_name' (Tier $tier) has no checkpoints. Consider running /work-checkpoint." >&2
elif [ "${latest_checkpoint%.*}" -lt "$updated_epoch" ]; then
  echo "Note: Task '$task_name' (Tier $tier) has a stale checkpoint. Consider running /work-checkpoint." >&2
fi
```

## Relationship to artifact-gate

work-check.sh provides proactive warnings (exit 0, non-blocking). artifact-gate.sh provides hard enforcement (exit 2, blocking). They complement each other — work-check suggests checkpointing before it's too late; artifact-gate blocks if required artifacts are missing.

## Files to Modify

- `.claude/hooks/work-check.sh` — replace checkpoint detection logic

## Testing

1. Task with no checkpoints → expect "no checkpoints" warning
2. Task with checkpoint newer than updated_at → expect no warning
3. Task with checkpoint older than updated_at → expect "stale checkpoint" warning
4. Tier 1 task → expect no warning (skip)
