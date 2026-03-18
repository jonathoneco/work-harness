#!/bin/sh
# harness: block session end if anti-patterns detected in session diff
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

# Only run if .work/ exists with active tasks
if [ ! -d "$HOOK_CWD/.work" ]; then
  exit 0
fi

# Check for active tasks (any state.json where archived_at is null)
active_task=false
for state_file in "$HOOK_CWD"/.work/*/state.json; do
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

# Anti-pattern checking requires yq for config reading
if command -v yq >/dev/null 2>&1; then
  # Read anti_patterns from harness.yaml
  patterns_json=$(harness_config_get '.anti_patterns' "$HOOK_CWD")
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
  diff_output=$(cd "$HOOK_CWD" && git diff HEAD 2>/dev/null || true)
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
fi

exit 0
