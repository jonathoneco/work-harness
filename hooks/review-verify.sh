#!/bin/sh
# harness: block session end if archived tasks lack review evidence
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

if [ ! -d "$CWD/.work" ]; then
  exit 0
fi

for state_file in "$CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue

  tier=$(jq -r '.tier' "$state_file")
  [ "$tier" -ge 2 ] 2>/dev/null || continue

  task_name=$(jq -r '.name' "$state_file")

  # Skip legacy format (steps as string array, not object array)
  steps_type=$(jq -r '.steps[0] | type' "$state_file" 2>/dev/null)
  if [ "$steps_type" = "string" ]; then
    continue
  fi

  # Check 1: Archived Tier 2-3 must have review evidence
  # Only enforce for tasks that have the reviewed_at field (even if null)
  # Tasks without the field predate this enforcement
  archived=$(jq -r '.archived_at // "null"' "$state_file")
  if [ "$archived" != "null" ]; then
    has_field=$(jq 'has("reviewed_at")' "$state_file")
    if [ "$has_field" = "true" ]; then
      reviewed=$(jq -r '.reviewed_at // "null"' "$state_file")
      if [ "$reviewed" = "null" ]; then
        echo "harness: review-verify: task '$task_name' is archived but review was never run" >&2
        echo "harness: review-verify: run /work-review before archiving." >&2
        exit 2
      fi
    fi
  fi

  # Check 2: Review step marked completed must have evidence
  review_status=$(jq -r '(.steps[] | select(.name == "review") | .status) // "not_started"' "$state_file")
  if [ "$review_status" = "completed" ]; then
    reviewed=$(jq -r '.reviewed_at // "null"' "$state_file")
    if [ "$reviewed" = "null" ]; then
      echo "harness: review-verify: task '$task_name' review step is 'completed' but reviewed_at is not set" >&2
      echo "harness: review-verify: run /work-review to set the reviewed_at timestamp." >&2
      exit 2
    fi
  fi
done

exit 0
