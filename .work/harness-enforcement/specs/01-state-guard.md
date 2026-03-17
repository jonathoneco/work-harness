# 01: State Mutation Guard (`state-guard.sh`)

## Overview

PostToolUse hook that validates state.json after every Write/Edit. Prevents state machine corruption — the most critical enforcement mechanism.

## Trigger

- **Event:** PostToolUse
- **Matcher:** `Write|Edit`
- **Condition:** Only activates when the written file path matches `.work/*/state.json`

## Validation Rules

### Rule 1: `current_step` must be in `steps` array

```bash
current=$(jq -r '.current_step' "$state_file")
valid=$(jq -r --arg cs "$current" '[.steps[].name] | index($cs) != null' "$state_file")
if [ "$valid" != "true" ]; then
  echo "State guard: current_step '$current' not found in steps array" >&2
  exit 2
fi
```

### Rule 2: Exactly one step has `status: "active"`

```bash
active_count=$(jq '[.steps[] | select(.status == "active")] | length' "$state_file")
if [ "$active_count" -ne 1 ]; then
  echo "State guard: expected exactly 1 active step, found $active_count" >&2
  exit 2
fi
```

### Rule 3: Active step matches `current_step`

```bash
active_step=$(jq -r '.steps[] | select(.status == "active") | .name' "$state_file")
if [ "$active_step" != "$current" ]; then
  echo "State guard: active step '$active_step' does not match current_step '$current'" >&2
  exit 2
fi
```

### Rule 4: No backwards transitions

Cannot change `completed` → `active` or `completed` → `not_started`. This requires comparing against the previous state, which PostToolUse hooks cannot do (they only see the result).

**Alternative approach:** Validate structural invariants instead. Steps must follow the pattern: `[completed|skipped]* -> active -> not_started*`. A step marked `skipped` is treated the same as `completed` for ordering purposes — it means the step was intentionally bypassed.

```bash
# Steps must follow: [completed|skipped]* -> active -> not_started*
# A skipped step was intentionally bypassed and counts as "done" for ordering
found_current=false
for row in $(jq -c '.steps[]' "$state_file"); do
  name=$(echo "$row" | jq -r '.name')
  status=$(echo "$row" | jq -r '.status')
  if [ "$name" = "$current" ]; then
    found_current=true
    [ "$status" = "active" ] || fail
  elif [ "$found_current" = "false" ]; then
    # Before current: must be completed or skipped
    [ "$status" = "completed" ] || [ "$status" = "skipped" ] || fail
  else
    # After current: must be not_started
    [ "$status" = "not_started" ] || fail
  fi
done
```

### Rule 5: Tier is valid

```bash
tier=$(jq -r '.tier' "$state_file")
if ! echo "$tier" | grep -qE '^[123]$'; then
  echo "State guard: invalid tier '$tier' (must be 1, 2, or 3)" >&2
  exit 2
fi
```

### Rule 6: Active tasks have null `archived_at`

```bash
archived=$(jq -r '.archived_at // "null"' "$state_file")
active_count=$(jq '[.steps[] | select(.status == "active")] | length' "$state_file")
if [ "$archived" != "null" ] && [ "$active_count" -gt 0 ]; then
  # Archived tasks: all steps must be completed or skipped, no active steps allowed
  echo "State guard: archived task has active steps" >&2
  exit 2
fi
```

### Rule 7: `updated_at` format validation

If `updated_at` is present, validate it's a valid ISO 8601 timestamp. This catches corruption without requiring comparison against previous state.

```bash
updated_at=$(jq -r '.updated_at // "null"' "$state_file")
if [ "$updated_at" != "null" ]; then
  if ! echo "$updated_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
    echo "State guard: updated_at '$updated_at' is not valid ISO 8601" >&2
    exit 2
  fi
fi
```

## File Path Detection

The hook fires on ALL Write/Edit operations. Must check the file path early:

```bash
# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only validate state.json files in .work/
# Note: FILE_PATH from tool_input is always absolute. No symlink normalization
# needed since Claude Code resolves paths before passing to hooks.
if ! echo "$FILE_PATH" | grep -qE '\.work/[^/]+/state\.json$'; then
  exit 0
fi
```

## Error Messages

All messages prefixed with `State guard:` for easy identification. Include the specific violation and which field is wrong.

## Files to Create

- `.claude/hooks/state-guard.sh` (~60 lines)

## Files to Modify

- `.claude/settings.json` — add PostToolUse hook entry

## Testing

1. Write state.json with `current_step: "nonexistent"` → expect block
2. Write state.json with 2 active steps → expect block
3. Write state.json with active step not matching current_step → expect block
4. Write state.json with completed step after active step → expect block
5. Write valid state.json → expect allow
6. Write non-state.json file → expect allow (hook ignores)
