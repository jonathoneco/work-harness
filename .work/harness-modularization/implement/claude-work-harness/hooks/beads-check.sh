#!/bin/sh
# harness: block session end if code changed without a claimed beads issue
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

# Only enforce in directories that use beads
if [ ! -d "$CWD/.beads" ]; then
  exit 0
fi

# bd required for beads enforcement — graceful skip if not installed
if ! command -v bd >/dev/null 2>&1; then
  exit 0
fi

# Read extensions from harness.yaml; fall back to sensible defaults
ext_list=$(harness_config_list '.extensions' "$CWD")
if [ -n "$ext_list" ]; then
  # Build grep pattern from extensions: strip leading dots, join with |
  # e.g. ".go\n.sql" -> "go|sql"
  ext_pattern=$(printf '%s\n' "$ext_list" | sed 's/^\.//' | grep -v '^$' | tr '\n' '|' | sed 's/|$//')
else
  # Fallback extensions when not configured
  ext_pattern="go|py|ts|js|rs|sql|html|css"
fi

# Build the full grep pattern: code extensions + infrastructure files
if [ -n "$ext_pattern" ]; then
  CODE_PATTERN="\\.($ext_pattern)\$|Dockerfile|docker-compose.*\\.yml|Makefile"
else
  CODE_PATTERN="Dockerfile|docker-compose.*\\.yml|Makefile"
fi

# Only check staged changes — unstaged/untracked may be pre-existing dirty state
ALL_CHANGES=$(cd "$CWD" && git diff --cached --name-only 2>/dev/null | grep -E "$CODE_PATTERN" || true)

# Exclude work harness state files from "code modified" detection
ALL_CHANGES=$(printf '%s\n' "$ALL_CHANGES" | grep -v '^\.work/' || true)

# No code changes? Allow stop
if [ -z "$ALL_CHANGES" ]; then
  exit 0
fi

# Code was changed — check for an in_progress beads issue
IN_PROGRESS=$(cd "$CWD" && bd list --status=in_progress 2>/dev/null || true)
if [ -n "$IN_PROGRESS" ]; then
  exit 0
fi

# Block: code changes without a claimed issue
echo "harness: beads-check: code files modified but no beads issue claimed. Run: bd ready && bd update <id> --status=in_progress" >&2
exit 2
