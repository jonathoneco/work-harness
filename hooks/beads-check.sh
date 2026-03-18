#!/bin/sh
# harness: block session end if code changed without a claimed beads issue
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

# Only enforce in directories that use beads
if [ ! -d "$HOOK_CWD/.beads" ]; then
  exit 0
fi

# bd required for beads enforcement — graceful skip if not installed
if ! command -v bd >/dev/null 2>&1; then
  exit 0
fi

# Read extensions from harness.yaml; fall back to sensible defaults
ext_list=""
if command -v yq >/dev/null 2>&1; then
  ext_list=$(harness_config_list '.extensions' "$HOOK_CWD")
fi
if [ -n "$ext_list" ]; then
  # Build grep pattern from extensions: strip leading dots, join with |
  # e.g. ".go\n.sql" -> "go|sql"
  ext_pattern=$(printf '%s\n' "$ext_list" | sed 's/^\.//' | grep -v '^$' | tr '\n' '|' | sed 's/|$//')
else
  # Fallback extensions when not configured (or yq unavailable)
  ext_pattern="go|py|ts|js|rs|sql|html|css"
fi

# Build the full grep pattern: code extensions + infrastructure files
if [ -n "$ext_pattern" ]; then
  CODE_PATTERN="\\.($ext_pattern)\$|Dockerfile|docker-compose.*\\.yml|Makefile"
else
  CODE_PATTERN="Dockerfile|docker-compose.*\\.yml|Makefile"
fi

# Only check staged changes — unstaged/untracked may be pre-existing dirty state
ALL_CHANGES=$(cd "$HOOK_CWD" && git diff --cached --name-only 2>/dev/null | grep -E "$CODE_PATTERN" || true)

# Exclude work harness state files from "code modified" detection
ALL_CHANGES=$(printf '%s\n' "$ALL_CHANGES" | grep -v '^\.work/' || true)

# No code changes? Allow stop
if [ -z "$ALL_CHANGES" ]; then
  exit 0
fi

# Code was changed — check for an in_progress beads issue
IN_PROGRESS=$(cd "$HOOK_CWD" && bd list --status=in_progress 2>/dev/null || true)
if [ -n "$IN_PROGRESS" ]; then
  exit 0
fi

# Block: code changes without a claimed issue
harness_error "code files modified but no beads issue claimed. Run: bd ready && bd update <id> --status=in_progress"
exit 2
