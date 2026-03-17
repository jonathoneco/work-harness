#!/bin/sh
# harness: warn about stale/missing checkpoints for active tasks at session end
# Component: C6
# Event: Stop
# Matcher: (empty)
set -eu

# Dependency check: jq required for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 2; }

# Read JSON context from stdin
INPUT=$(cat)

# Prevent infinite loop: if stop hook already fired, allow stop
STOP_ACTIVE=$(printf '%s\n' "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')

# Resolve harness directory from this script's location
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if command -v yq >/dev/null 2>&1; then
  . "$HARNESS_DIR/lib/config.sh"

  # Graceful skip: no harness.yaml means project is not harness-enabled
  if ! harness_has_config "$CWD"; then
    exit 0
  fi

  # Validate config parses (R2: malformed = exit 2, not silent skip)
  if ! harness_validate_config "$CWD"; then
    echo "harness: .claude/harness.yaml is malformed — fix or remove it" >&2
    exit 2
  fi
fi

# Only check in projects with active work tasks
if [ ! -d "$CWD/.work" ]; then
  exit 0
fi

# Check for active Tier 2-3 tasks without checkpoints
for state_file in "$CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue
  archived=$(jq -r '.archived_at // "null"' "$state_file")
  [ "$archived" = "null" ] || continue

  tier=$(jq -r '.tier' "$state_file")

  # Only warn for Tier 2-3 (Tier 1 is single-session)
  [ "$tier" -ge 2 ] 2>/dev/null || continue

  task_dir=$(dirname "$state_file")
  task_name=$(jq -r '.name' "$state_file")

  # Find any checkpoint files
  has_checkpoint=$(find "$task_dir" -path '*/checkpoints/*.md' 2>/dev/null | head -1)

  if [ -z "$has_checkpoint" ]; then
    echo "harness: work-check: task '$task_name' (Tier $tier) has no checkpoints. Consider running /work-checkpoint before ending." >&2
  fi
done

exit 0  # Always non-blocking
