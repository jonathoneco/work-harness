#!/bin/sh
# harness: block session end if completed steps lack required artifacts
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

if ! harness_find_active_tasks > /dev/null 2>&1; then
  exit 0
fi

# Map step names to their artifact directories
step_dir() {
  case "$1" in
    research)  printf 'research' ;;
    plan)      printf 'plan' ;;
    spec)      printf 'specs' ;;
    decompose) printf 'streams' ;;
    *)         printf '%s' "$1" ;;
  esac
}

for state_file in "$HOOK_CWD"/.work/*/state.json; do
  [ -f "$state_file" ] || continue

  archived=$(jq -r '.archived_at // "null"' "$state_file")
  [ "$archived" = "null" ] || continue

  tier=$(jq -r '.tier' "$state_file")
  # Only enforce for Tier 2-3
  [ "$tier" -ge 2 ] 2>/dev/null || continue

  task_dir=$(dirname "$state_file")
  task_name=$(jq -r '.name' "$state_file")

  # Skip legacy format (steps as string array, not object array)
  if harness_is_legacy_format "$state_file"; then
    continue
  fi

  # Rule 1: Completed steps must have handoff prompts
  for step_name in research plan spec decompose; do
    status=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .status // "not_started"' "$state_file")
    [ "$status" = "completed" ] || continue

    dir=$(step_dir "$step_name")
    handoff="$task_dir/$dir/handoff-prompt.md"

    if [ ! -s "$handoff" ]; then
      harness_error "step '$step_name' is completed but handoff-prompt.md is missing at $handoff"
      harness_error "create the handoff prompt before ending the session."
      exit 2
    fi
  done

  # Rule 2: Completed research must have index
  research_status=$(jq -r '.steps[] | select(.name == "research") | .status // "not_started"' "$state_file")
  if [ "$research_status" = "completed" ]; then
    if [ ! -f "$task_dir/research/index.md" ]; then
      harness_error "research is completed but research/index.md is missing"
      exit 2
    fi
  fi

  # Rules 3 and 5 only apply to new-schema tasks (have updated_at field)
  has_updated_at=$(jq 'has("updated_at")' "$state_file")
  if [ "$has_updated_at" = "true" ]; then
    spec_status=$(jq -r '.steps[] | select(.name == "spec") | .status // "not_started"' "$state_file")

    # Rule 3: Completed spec must have spec files in .work/<name>/specs/
    if [ "$spec_status" = "completed" ]; then
      specs_dir="$task_dir/specs"
      if [ ! -d "$specs_dir" ]; then
        harness_error "spec is completed but .work/$task_name/specs/ directory missing"
        exit 2
      fi
      spec_count=$(find "$specs_dir" -maxdepth 1 -name '*.md' ! -name 'handoff-prompt.md' ! -name 'index.md' 2>/dev/null | wc -l)
      if [ "$spec_count" -eq 0 ]; then
        harness_error "spec is completed but no spec files in $specs_dir"
        exit 2
      fi
    fi

    # Rule 5: Spec files must NOT be in docs/feature/<name>/
    if [ "$spec_status" = "completed" ]; then
      old_specs=$(find "$HOOK_CWD/docs/feature/$task_name" -maxdepth 1 -name '[0-9][0-9]-*.md' 2>/dev/null | wc -l)
      if [ "$old_specs" -gt 0 ]; then
        harness_error "spec files found in docs/feature/$task_name/ — move to .work/$task_name/specs/"
        exit 2
      fi
    fi
  fi

  # Rule 4: Completed steps must have gate IDs
  for step_name in research plan spec decompose; do
    status=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .status // "not_started"' "$state_file")
    [ "$status" = "completed" ] || continue

    gate_id=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .gate_id // "null"' "$state_file")
    if [ "$gate_id" = "null" ]; then
      harness_error "step '$step_name' is completed but has no gate_id"
      harness_error "create a gate issue before advancing."
      exit 2
    fi
  done
done

exit 0
