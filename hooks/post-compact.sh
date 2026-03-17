#!/bin/sh
# harness: suggest re-grounding after context compaction
# Scans for active tasks and outputs tier-appropriate re-entry command
set -eu

command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 0; }

for state_file in .work/*/state.json; do
    [ -f "$state_file" ] || continue

    archived=$(jq -r '.archived_at // empty' "$state_file" 2>/dev/null)
    [ -n "$archived" ] && continue

    name=$(jq -r '.title // empty' "$state_file" 2>/dev/null)
    tier=$(jq -r '.tier // empty' "$state_file" 2>/dev/null)
    step=$(jq -r '.current_step // empty' "$state_file" 2>/dev/null)

    [ -z "$name" ] && continue

    case "$tier" in
        1) cmd="work-fix" ;;
        2) cmd="work-feature" ;;
        3) cmd="work-deep" ;;
        *) cmd="work-reground" ;;
    esac

    echo "Active task: $name (step: $step). Run /$cmd to re-ground."
done

exit 0
