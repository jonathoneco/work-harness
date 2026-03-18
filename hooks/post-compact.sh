#!/bin/sh
# harness: inject task context after context compaction
# Component: C6
# Event: PostCompact
# Scans for active tasks, resolves the most relevant handoff prompt,
# and outputs structured context so the agent can continue without
# a manual /work-reground invocation.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

harness_require_jq

# resolve_handoff <task_dir> <state_file>
# Implements 3-tier handoff resolution:
#   1. Current step's handoff-prompt.md
#   2. Previous step's handoff-prompt.md
#   3. State.json summary fallback
# Prints resolved content to stdout. Prints nothing on total failure.
resolve_handoff() {
    _task_dir="$1"
    _state_file="$2"

    _current_step=$(jq -r '.current_step // empty' "$_state_file" 2>/dev/null)
    [ -z "$_current_step" ] && return 0

    # Tier 1: current step's handoff prompt
    _handoff="${_task_dir}/${_current_step}/handoff-prompt.md"
    if [ -f "$_handoff" ] && [ -s "$_handoff" ]; then
        cat "$_handoff"
        return 0
    fi

    # Tier 2: previous step's handoff prompt
    _prev_step=$(jq -r --arg cs "$_current_step" '
        .steps
        | to_entries[]
        | select(.value.name == $cs)
        | if .key > 0 then .key - 1 else empty end
    ' "$_state_file" 2>/dev/null \
        | head -1 \
        | xargs -I{} jq -r '.steps[{}].name' "$_state_file" 2>/dev/null)

    if [ -n "$_prev_step" ]; then
        _handoff="${_task_dir}/${_prev_step}/handoff-prompt.md"
        if [ -f "$_handoff" ] && [ -s "$_handoff" ]; then
            cat "$_handoff"
            return 0
        fi
    fi

    # Tier 3: state.json summary fallback
    _title=$(jq -r '.title // "unknown"' "$_state_file" 2>/dev/null)
    _tier=$(jq -r '.tier // "?"' "$_state_file" 2>/dev/null)
    _steps_summary=$(jq -r '
        .steps[]
        | "  - " + .name + ": " + .status
    ' "$_state_file" 2>/dev/null)

    if [ -n "$_steps_summary" ]; then
        printf 'Task: %s (Tier %s)\nCurrent step: %s\n\nStep statuses:\n%s\n' \
            "$_title" "$_tier" "$_current_step" "$_steps_summary"
        return 0
    fi

    # Total failure — print nothing
    return 0
}

# PostCompact hooks receive no stdin JSON — use harness_find_active_tasks directly
_active_tasks=$(harness_find_active_tasks 2>/dev/null) || exit 0
[ -z "$_active_tasks" ] && exit 0

printf '%s\n' "$_active_tasks" | while IFS= read -r state_file; do
    [ -f "$state_file" ] || continue

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

    # Resolve handoff content from the task directory
    task_dir=$(dirname "$state_file")
    handoff_content=$(resolve_handoff "$task_dir" "$state_file")

    if [ -n "$handoff_content" ]; then
        # Enhanced output with injected context
        printf '%s\n' "--- Active Task Context ---"
        printf 'Task: %s (Tier %s, step: %s)\n\n' "$name" "$tier" "$step"
        printf '%s\n\n' "$handoff_content"
        printf 'Suggested: Run /%s to continue.\n' "$cmd"
        printf '%s\n' "--- End Task Context ---"
    else
        # Fallback to simple one-line message
        echo "Active task: $name (step: $step). Run /$cmd to re-ground."
    fi
done

exit 0
