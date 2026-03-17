#!/bin/sh
# harness: validate .work/*/state.json structure after writes
# Component: C6
# Event: PostToolUse
# Matcher: Write|Edit
set -eu

# Dependency check: jq required for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 2; }

# Read JSON context from stdin
INPUT=$(cat)
CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')

# Resolve harness directory from this script's location
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$HARNESS_DIR/lib/config.sh"

# state-guard always runs (state.json validation is config-independent)
# But still validate config if present (R2)
if harness_has_config "$CWD" && ! harness_validate_config "$CWD"; then
  echo "harness: .claude/harness.yaml is malformed — fix or remove it" >&2
  exit 2
fi

# Extract file path from tool input — only validate state.json files in .work/
FILE_PATH=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.file_path // empty')
if ! printf '%s\n' "$FILE_PATH" | grep -qE '\.work/[^/]+/state\.json$'; then
  exit 0
fi

# Verify the file exists (it should, since PostToolUse fires after write)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Rule 5: Tier is valid (1-3)
tier=$(jq -r '.tier // "null"' "$FILE_PATH")
if ! printf '%s\n' "$tier" | grep -qE '^[123]$'; then
  echo "harness: state-guard: invalid tier '$tier' (must be 1, 2, or 3)" >&2
  exit 2
fi

# Detect steps format: array of objects (new) vs array of strings (legacy)
steps_type=$(jq -r '.steps[0] | type' "$FILE_PATH" 2>/dev/null)
if [ "$steps_type" = "string" ]; then
  # Legacy format — skip validation (pre-enforcement task)
  exit 0
fi

# Rule 1: current_step must exist and be in steps array
current=$(jq -r '.current_step // "null"' "$FILE_PATH")
if [ "$current" = "null" ] || [ -z "$current" ]; then
  echo "harness: state-guard: current_step is null or missing" >&2
  exit 2
fi
valid=$(jq -r --arg cs "$current" '[.steps[].name] | index($cs) != null' "$FILE_PATH")
if [ "$valid" != "true" ]; then
  echo "harness: state-guard: current_step '$current' not found in steps array" >&2
  exit 2
fi

# Rule 2: Exactly one step has status "active" (unless archived)
archived=$(jq -r '.archived_at // "null"' "$FILE_PATH")
active_count=$(jq '[.steps[] | select(.status == "active")] | length' "$FILE_PATH")

if [ "$archived" = "null" ]; then
  # Active task: must have exactly one active step
  if [ "$active_count" -ne 1 ]; then
    echo "harness: state-guard: expected exactly 1 active step, found $active_count" >&2
    exit 2
  fi

  # Rule 3: Active step matches current_step
  active_step=$(jq -r '.steps[] | select(.status == "active") | .name' "$FILE_PATH")
  if [ "$active_step" != "$current" ]; then
    echo "harness: state-guard: active step '$active_step' does not match current_step '$current'" >&2
    exit 2
  fi

  # Rule 4: Steps must follow [completed|skipped]* -> active -> not_started*
  found_current=false
  jq -c '.steps[]' "$FILE_PATH" | while IFS= read -r row; do
    name=$(printf '%s\n' "$row" | jq -r '.name')
    status=$(printf '%s\n' "$row" | jq -r '.status')
    if [ "$name" = "$current" ]; then
      found_current=true
      if [ "$status" != "active" ]; then
        echo "harness: state-guard: current step '$name' has status '$status', expected 'active'" >&2
        exit 2
      fi
    elif [ "$found_current" = "false" ]; then
      # Before current: must be completed or skipped
      if [ "$status" != "completed" ] && [ "$status" != "skipped" ]; then
        echo "harness: state-guard: step '$name' before current_step has status '$status' (expected completed or skipped)" >&2
        exit 2
      fi
    else
      # After current: must be not_started
      if [ "$status" != "not_started" ]; then
        echo "harness: state-guard: step '$name' after current_step has status '$status' (expected not_started)" >&2
        exit 2
      fi
    fi
  done || exit 2
else
  # Rule 6: Archived tasks must have no active steps
  if [ "$active_count" -gt 0 ]; then
    echo "harness: state-guard: archived task has active steps" >&2
    exit 2
  fi
fi

# Rule 7: updated_at format validation (if present)
updated_at=$(jq -r '.updated_at // "null"' "$FILE_PATH")
if [ "$updated_at" != "null" ]; then
  if ! printf '%s\n' "$updated_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
    echo "harness: state-guard: updated_at '$updated_at' is not valid ISO 8601" >&2
    exit 2
  fi
fi

exit 0
