#!/bin/sh
# harness: gate git push — run format/lint/build checks before allowing push
# Component: C6
# Event: PreToolUse
# Matcher: Bash
set -eu

# Dependency check: jq required for JSON parsing
command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 2; }

# Read JSON context from stdin
INPUT=$(cat)

# Extract the command being run — only gate git push
TOOL=$(printf '%s\n' "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

CMD=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.command // empty')

# Only gate git push commands
if ! printf '%s\n' "$CMD" | grep -qE '^\s*git\s+push'; then
  exit 0
fi

CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')

# Resolve harness directory from this script's location
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if command -v yq >/dev/null 2>&1; then
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
fi

cd "$CWD"

# Check if current branch has an active PR — graceful skip if gh not installed
if ! command -v gh >/dev/null 2>&1; then
  exit 0
fi
if ! gh pr view --json state -q '.state' 2>/dev/null | grep -q "OPEN"; then
  exit 0
fi

echo "harness: pr-gate: PR detected on this branch — running pre-push checks..." >&2

# Build command checks require yq for config reading
if command -v yq >/dev/null 2>&1; then
  # Read build commands from harness.yaml
  format_cmd=$(harness_config_get '.build.format' "$CWD")
  lint_cmd=$(harness_config_get '.build.lint' "$CWD")
  build_cmd=$(harness_config_get '.build.build' "$CWD")

  # If no build commands configured, nothing to check
  if [ -z "$format_cmd" ] && [ -z "$lint_cmd" ] && [ -z "$build_cmd" ]; then
    exit 0
  fi

  # 1. Format check
  if [ -n "$format_cmd" ]; then
    eval "$format_cmd" 2>&1 || echo "harness: pr-gate: format command failed (non-fatal)" >&2
    CHANGED=$(git diff --name-only 2>/dev/null || true)
    if [ -n "$CHANGED" ]; then
      COUNT=$(printf '%s\n' "$CHANGED" | wc -l)
      echo "harness: pr-gate: BLOCKED: format command changed $COUNT file(s). Review and commit before pushing:" >&2
      printf '%s\n' "$CHANGED" | sed 's/^/  /' >&2
      exit 2
    fi
  fi

  # 2. Lint check
  if [ -n "$lint_cmd" ]; then
    LINT_OUTPUT=$(eval "$lint_cmd" 2>&1) || {
      echo "harness: pr-gate: BLOCKED: lint errors found:" >&2
      printf '%s\n' "$LINT_OUTPUT" >&2
      exit 2
    }
  fi

  # 3. Build check
  if [ -n "$build_cmd" ]; then
    BUILD_OUTPUT=$(eval "$build_cmd" 2>&1) || {
      echo "harness: pr-gate: BLOCKED: build failed:" >&2
      printf '%s\n' "$BUILD_OUTPUT" >&2
      exit 2
    }
  fi
fi

exit 0
