#!/bin/sh
# harness: gate git push — run format/lint/build checks before allowing push
# Component: C6
# Event: PreToolUse
# Matcher: Bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

harness_require_jq
harness_read_hook_input

# Extract the command being run — only gate git push
TOOL=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

CMD=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.command // empty')

# Only gate git push commands
if ! printf '%s\n' "$CMD" | grep -qE '^\s*git\s+push'; then
  exit 0
fi

harness_init_config

cd "$HOOK_CWD"

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
  format_cmd=$(harness_config_get '.build.format' "$HOOK_CWD")
  lint_cmd=$(harness_config_get '.build.lint' "$HOOK_CWD")
  build_cmd=$(harness_config_get '.build.build' "$HOOK_CWD")

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
