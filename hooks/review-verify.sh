#!/bin/sh
# harness: block session end if archived tasks lack review evidence
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

if [ ! -d "$HOOK_CWD/.work" ]; then
  exit 0
fi

for state_file in "$HOOK_CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue

  tier=$(jq -r '.tier' "$state_file")
  [ "$tier" -ge 2 ] 2>/dev/null || continue

  task_name=$(jq -r '.name' "$state_file")

  # Skip legacy format (steps as string array, not object array)
  if harness_is_legacy_format "$state_file"; then
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
        harness_error "task '$task_name' is archived but review was never run"
        harness_error "run /work-review before archiving."
        exit 2
      fi
    fi
  fi

  # Check 2: Review step marked completed must have evidence
  review_status=$(jq -r '(.steps[] | select(.name == "review") | .status) // "not_started"' "$state_file")
  if [ "$review_status" = "completed" ]; then
    reviewed=$(jq -r '.reviewed_at // "null"' "$state_file")
    if [ "$reviewed" = "null" ]; then
      harness_error "task '$task_name' review step is 'completed' but reviewed_at is not set"
      harness_error "run /work-review to set the reviewed_at timestamp."
      exit 2
    fi
  fi
done

exit 0
