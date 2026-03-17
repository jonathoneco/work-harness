#!/bin/sh
# harness: block session end if anti-patterns detected in session diff
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

# Only run if .work/ exists with active tasks
if [ ! -d "$CWD/.work" ]; then
  exit 0
fi

# Check for active tasks (any state.json where archived_at is null)
active_task=false
for state_file in "$CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue
  archived=$(jq -r '.archived_at // "null"' "$state_file")
  if [ "$archived" = "null" ]; then
    active_task=true
    break
  fi
done

if [ "$active_task" = "false" ]; then
  exit 0
fi

# Read anti_patterns from harness.yaml
patterns_json=$(harness_config_get '.anti_patterns' "$CWD")
if [ -z "$patterns_json" ]; then
  # No anti_patterns configured — nothing to check
  exit 0
fi

# Get pattern count
pattern_count=$(printf '%s\n' "$patterns_json" | yq eval 'length' - 2>/dev/null || printf '0')
if [ "$pattern_count" = "0" ] || [ "$pattern_count" = "null" ]; then
  exit 0
fi

# Get session diff (staged + unstaged changes)
diff_output=$(cd "$CWD" && git diff HEAD 2>/dev/null || true)
if [ -z "$diff_output" ]; then
  exit 0
fi

# Exclude test files from pattern matching (higher false positive rate)
diff_output=$(printf '%s\n' "$diff_output" | grep -v '_test\.' || true)
if [ -z "$diff_output" ]; then
  exit 0
fi

# Check diff for each anti-pattern
found_critical=false
findings=""

idx=0
while [ "$idx" -lt "$pattern_count" ]; do
  pattern=$(printf '%s\n' "$patterns_json" | yq eval ".[$idx].pattern" - 2>/dev/null)
  description=$(printf '%s\n' "$patterns_json" | yq eval ".[$idx].description" - 2>/dev/null)

  if [ -z "$pattern" ] || [ "$pattern" = "null" ]; then
    idx=$(( idx + 1 ))
    continue
  fi

  # Catch invalid regex gracefully — warn but don't block
  matches=$(printf '%s\n' "$diff_output" | grep -n "^+" | grep -E "$pattern" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    found_critical=true
    findings="$findings
  - Pattern: $pattern ($description)
    $matches"
  fi

  idx=$(( idx + 1 ))
done

if [ "$found_critical" = "true" ]; then
  printf 'harness: review-gate: potential anti-patterns detected in session diff:\n' >&2
  printf '%s\n' "$findings" >&2
  printf '\nFix these before ending the session, or run /work-review for full analysis.\n' >&2
  exit 2
fi

exit 0
