#!/bin/sh
# harness: warn about stale/missing checkpoints for active tasks at session end
# Component: C6
# Event: Stop
# Matcher: (empty)
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

harness_require_jq
harness_read_hook_input
harness_stop_guard
harness_init_config

# Only check in projects with active work tasks
if ! harness_find_active_tasks > /dev/null 2>&1; then
  exit 0
fi

# Check for active Tier 2-3 tasks without checkpoints
for state_file in "$HOOK_CWD"/.work/*/state.json; do
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
    harness_warn "task '$task_name' (Tier $tier) has no checkpoints. Consider running /work-checkpoint before ending."
  fi
done

exit 0  # Always non-blocking
