#!/bin/sh
# harness: shared hook utilities — sourced by hooks, not executed directly
# Component: C7
#
# Provides common boilerplate functions so hooks can focus on business logic.
# Follows the lib/config.sh sourcing pattern.
#
# Usage in hooks:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   # shellcheck source=lib/common.sh
#   . "$SCRIPT_DIR/lib/common.sh"

# Ensure mise-managed tools are on PATH (hooks run in minimal shell environments)
if [ -d "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims" ]; then
  PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
fi

# Internal: derive hook name from the calling script for log messages.
# Falls back to "unknown" if $0 is unset.
_harness_hook_name() {
  _hhn_base=$(basename "${0:-unknown}" .sh)
  printf '%s' "$_hhn_base"
}

# harness_warn <message>
# Print a warning message to stderr in the standard harness format.
# Inputs:  $1 — message string
# Outputs: "harness: <hook-name>: <message>" on stderr
# Exit:    does not exit; returns 0
harness_warn() {
  printf 'harness: %s: %s\n' "$(_harness_hook_name)" "$1" >&2
}

# harness_error <message>
# Print an error message to stderr in the standard harness format.
# Identical format to harness_warn — the distinction is semantic (callers
# use harness_error before exit 2, harness_warn before continuing).
# Inputs:  $1 — message string
# Outputs: "harness: <hook-name>: <message>" on stderr
# Exit:    does not exit; returns 0
harness_error() {
  printf 'harness: %s: %s\n' "$(_harness_hook_name)" "$1" >&2
}

# harness_require_jq
# Check that jq is available. If missing, exit 0 so hooks never block
# the agent on a missing optional dependency.
# Inputs:  none
# Outputs: none on success; warning to stderr if jq missing
# Exit:    0 if jq missing (graceful skip); returns 0 if jq present
harness_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    harness_warn "jq not found, skipping hook"
    exit 0
  fi
}

# harness_read_hook_input
# Read JSON payload from stdin and extract the working directory.
# Sets two globals:
#   HOOK_INPUT — the full JSON payload
#   HOOK_CWD   — the .cwd field from the payload
# Must be called exactly once per hook invocation (stdin is consumed).
# Inputs:  stdin (JSON from Claude Code hook runner)
# Outputs: sets HOOK_INPUT and HOOK_CWD globals
# Exit:    returns 0
harness_read_hook_input() {
  HOOK_INPUT=$(cat)
  HOOK_CWD=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.cwd')
}

# harness_stop_guard
# Prevent infinite loops in Stop event hooks. If stop_hook_active is true
# in HOOK_INPUT, exit 0 immediately.
# Must be called after harness_read_hook_input.
# Inputs:  HOOK_INPUT global (set by harness_read_hook_input)
# Outputs: none
# Exit:    0 if stop_hook_active is true; returns 0 otherwise
harness_stop_guard() {
  _hsg_active=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
  if [ "$_hsg_active" = "true" ]; then
    exit 0
  fi
}

# harness_init_config
# Resolve the harness directory, source config.sh if yq is available,
# and validate the project's harness.yaml if present.
# Sets HARNESS_DIR global. Sets HARNESS_CONFIG_AVAILABLE (true/false).
# Uses HOOK_CWD if set, otherwise falls back to the CWD variable (for
# hooks that set CWD directly without harness_read_hook_input).
# Inputs:  HOOK_CWD or CWD global — project working directory
#          SCRIPT_DIR global — directory containing the hook script
# Outputs: sets HARNESS_DIR and HARNESS_CONFIG_AVAILABLE globals
# Exit:    0 if no harness.yaml (project not harness-enabled)
#          2 if harness.yaml is malformed
#          returns 0 on success
harness_init_config() {
  _hic_cwd="${HOOK_CWD:-${CWD:-}}"
  HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  # shellcheck disable=SC2034
  HARNESS_CONFIG_AVAILABLE=false

  if command -v yq >/dev/null 2>&1; then
    # shellcheck source=../../lib/config.sh
    . "$HARNESS_DIR/lib/config.sh"

    if ! harness_has_config "$_hic_cwd"; then
      exit 0
    fi

    if ! harness_validate_config "$_hic_cwd"; then
      harness_error ".claude/harness.yaml is malformed — fix or remove it"
      exit 2
    fi

    # shellcheck disable=SC2034
    HARNESS_CONFIG_AVAILABLE=true
  fi
}

# harness_find_active_tasks
# Scan .work/ for active tasks (state.json where archived_at is null).
# Prints one state.json path per line for each active task found.
# Uses HOOK_CWD if set, otherwise falls back to CWD.
# Inputs:  HOOK_CWD or CWD global — project working directory
# Outputs: state.json paths on stdout (one per line)
# Exit:    returns 0 if active tasks found; returns 1 if no .work/
#          directory or no active tasks
harness_find_active_tasks() {
  _hfat_cwd="${HOOK_CWD:-${CWD:-$(pwd)}}"
  _hfat_found=false

  if [ ! -d "$_hfat_cwd/.work" ]; then
    return 1
  fi

  for _hfat_state in "$_hfat_cwd"/.work/*/state.json; do
    [ -f "$_hfat_state" ] || continue

    _hfat_archived=$(jq -r '.archived_at // "null"' "$_hfat_state" 2>/dev/null) || continue
    if [ "$_hfat_archived" = "null" ]; then
      printf '%s\n' "$_hfat_state"
      _hfat_found=true
    fi
  done

  if [ "$_hfat_found" = "false" ]; then
    return 1
  fi
}

# harness_is_legacy_format <state_file>
# Detect whether a state.json uses legacy (string array) or current
# (object array) format for the steps field.
# Inputs:  $1 — path to a state.json file
# Outputs: none
# Exit:    returns 0 if legacy format (string steps)
#          returns 1 if current format (object steps)
harness_is_legacy_format() {
  _hilf_type=$(jq -r '.steps[0] | type' "$1" 2>/dev/null)
  [ "$_hilf_type" = "string" ]
}
