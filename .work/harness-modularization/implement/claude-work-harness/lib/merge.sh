#!/bin/sh
# harness: settings merge/de-merge for ~/.claude/settings.json
# Component: C8
set -eu

# R1: jq dependency check at source time
command -v jq >/dev/null 2>&1 || {
  echo "harness: jq required but not found. Run install.sh to verify." >&2
  exit 2
}

# Merge harness hook entries into an existing settings.json.
# Usage: harness_merge_hooks <settings_file> <hooks_json>
#   settings_file: absolute path to settings.json
#   hooks_json: JSON array of {event, matcher, command} objects
# Returns: 0 on success, 1 on jq/write failure.
harness_merge_hooks() {
  hm_settings_file="$1"
  hm_hooks_json="$2"

  # Create file if absent
  if [ ! -f "$hm_settings_file" ]; then
    printf '{}\n' > "$hm_settings_file"
  fi

  hm_result=$(jq --argjson new_hooks "$hm_hooks_json" '
    # Ensure .hooks exists
    .hooks //= {} |
    # Fold each new hook into the structure
    reduce ($new_hooks[]) as $h (.;
      ($h.event) as $event |
      ($h.matcher) as $matcher |
      {"type": "command", "command": $h.command} as $hook_obj |
      # Ensure event array exists
      .hooks[$event] //= [] |
      # Find index of entry with matching matcher
      (.hooks[$event] | map(.matcher == $matcher) | index(true)) as $idx |
      if $idx == null then
        # No matching matcher entry — add new one
        .hooks[$event] += [{"matcher": $matcher, "hooks": [$hook_obj]}]
      elif (.hooks[$event][$idx].hooks | map(.command == $h.command) | any) then
        # Command already present — skip
        .
      else
        # Matcher exists but command is new — append to hooks sub-array
        .hooks[$event][$idx].hooks += [$hook_obj]
      end
    )
  ' "$hm_settings_file") || {
    echo "harness: failed to merge hooks into $hm_settings_file" >&2
    return 1
  }

  printf '%s\n' "$hm_result" > "$hm_settings_file"
}

# Remove harness hook entries from settings.json.
# Usage: harness_demerge_hooks <settings_file> <hooks_json>
#   settings_file: absolute path to settings.json
#   hooks_json: JSON array of {event, matcher, command} objects to remove
# Returns: 0 on success (including if file absent), 1 on jq/write failure.
harness_demerge_hooks() {
  hd_settings_file="$1"
  hd_hooks_json="$2"

  if [ ! -f "$hd_settings_file" ]; then
    return 0
  fi

  hd_result=$(jq --argjson rm_hooks "$hd_hooks_json" '
    reduce ($rm_hooks[]) as $h (.;
      ($h.event) as $event |
      ($h.matcher) as $matcher |
      if .hooks[$event] then
        # Remove the command from matching matcher entry
        .hooks[$event] = [
          .hooks[$event][] |
          if .matcher == $matcher then
            .hooks = [.hooks[] | select(.command != $h.command)] |
            select(.hooks | length > 0)
          else
            .
          end
        ] |
        # Remove event key if array is now empty
        if (.hooks[$event] | length) == 0 then
          .hooks |= del(.[$event])
        else . end
      else . end
    ) |
    # Remove hooks key if now empty
    if (.hooks // {} | length) == 0 then del(.hooks) else . end
  ' "$hd_settings_file") || {
    echo "harness: failed to de-merge hooks from $hd_settings_file" >&2
    return 1
  }

  printf '%s\n' "$hd_result" > "$hd_settings_file"
}

# Top-level orchestrator for settings merges. Called by install.sh.
# Currently delegates to harness_merge_hooks. Exists as stable entry point
# so future settings merge operations can be added without changing install.sh.
# Usage: harness_merge_settings <settings_file> <hooks_json>
# Returns: exit code from harness_merge_hooks.
harness_merge_settings() {
  harness_merge_hooks "$1" "$2"
}
