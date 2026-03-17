# Spec 03: Settings Merger (C8)

**Component:** C8 — Settings Merger (`lib/merge.sh`)
**Phase:** 1 (Foundation)
**Scope:** Medium (one of the hardest components — jq merge logic with idempotency constraints)
**Dependencies:** C1 (repo scaffold)
**Depended on by:** C7 (install script — calls merge on install, de-merge on uninstall)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md) (especially sections 5, 6)

---

## 1. Overview

`lib/merge.sh` provides jq-based merge and de-merge operations for `~/.claude/settings.json`. The install script (C7) calls these functions to register hooks during install and remove them during uninstall.

This is the highest-risk library component because it modifies a file the user may have manually edited. The merge must be:
- **Additive**: Only add harness entries. Never remove or overwrite user entries.
- **Idempotent**: Running install twice produces the same settings.json as running it once.
- **Reversible**: De-merge cleanly removes exactly what merge added, using the manifest as the source of truth.
- **Safe**: If settings.json is absent, create it. If it exists but has no hooks, add the hooks key. If it has hooks, append to them.

---

## 2. Files to Create

| Path (repo-relative) | Description |
|----------------------|-------------|
| `lib/merge.sh` | Settings merge/de-merge library (sourced, not executed) |

---

## 3. Function Specifications

### 3.1 `harness_merge_hooks <settings_file> <hooks_json>`

Merge harness hook entries into an existing settings.json.

**Parameters:**
- `settings_file` — absolute path to `settings.json` (typically `~/.claude/settings.json`)
- `hooks_json` — JSON string representing the hooks to add (array of objects matching manifest `hooks_added` schema)

**Input `hooks_json` format** (array of manifest hook entries):
```json
[
  {
    "event": "PostToolUse",
    "matcher": "Write|Edit",
    "command": "/home/user/src/claude-work-harness/hooks/state-guard.sh"
  },
  {
    "event": "Stop",
    "matcher": "",
    "command": "/home/user/src/claude-work-harness/hooks/work-check.sh"
  }
]
```

**Behavior:**
1. If `settings_file` does not exist, create it with `{}`
2. Read existing settings JSON
3. For each hook entry in `hooks_json`:
   a. Look up `settings.hooks.<event>` array
   b. Search for an existing entry with matching `matcher` value
   c. If a matching event+matcher entry exists, check its `hooks` sub-array for an entry with the same `command` path
   d. If command already present: **skip** (idempotent — no duplicate)
   e. If matcher entry exists but command is new: **append** command to the entry's `hooks` sub-array
   f. If no matching event+matcher entry: **create** a new entry in the event array
4. Write the updated JSON back to `settings_file` (pretty-printed, 2-space indent)
5. Return 0 on success

**Claude Code settings.json hook structure** (target format):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Mapping from manifest entry to settings entry:**
- Manifest `event` -> settings key under `hooks`
- Manifest `matcher` -> entry's `matcher` field
- Manifest `command` -> added to entry's `hooks` array as `{"type": "command", "command": "<path>"}`

---

### 3.2 `harness_demerge_hooks <settings_file> <hooks_json>`

Remove harness hook entries from settings.json, using manifest data as the source of truth.

**Parameters:**
- `settings_file` — absolute path to `settings.json`
- `hooks_json` — JSON string (same format as `harness_merge_hooks`) describing what to remove

**Behavior:**
1. If `settings_file` does not exist: return 0 (nothing to remove)
2. Read existing settings JSON
3. For each hook entry in `hooks_json`:
   a. Look up `settings.hooks.<event>` array
   b. Find the entry with matching `matcher`
   c. Remove the command entry from that entry's `hooks` sub-array where `command` matches
   d. If the entry's `hooks` sub-array is now empty, remove the entire matcher entry
   e. If the event array is now empty, remove the event key from `settings.hooks`
4. If `settings.hooks` is now empty (`{}`), remove the `hooks` key entirely
5. Write updated JSON back to `settings_file`
6. Return 0 on success

**Critical invariant:** Only remove entries whose `command` path matches exactly. Never touch entries added by the user or other tools.

---

### 3.3 `harness_merge_settings <settings_file> <hooks_json>`

Top-level orchestrator called by install.sh. Currently a thin wrapper that calls `harness_merge_hooks`. Exists as the stable entry point so future settings merge operations (beyond hooks) can be added without changing install.sh.

**Parameters:**
- `settings_file` — absolute path to `settings.json`
- `hooks_json` — JSON string of hook entries to merge

**Behavior:**
1. Call `harness_merge_hooks "$settings_file" "$hooks_json"`
2. (Future: merge other settings sections here)
3. Return the exit code from the merge

---

## 4. Implementation Steps

- [ ] **4.1** Create `lib/merge.sh` with file header per spec 00 section 9
- [ ] **4.2** Add jq dependency check at the top of the file (R1): `command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found. Run install.sh to verify." >&2; exit 2; }`
- [ ] **4.3** Implement `harness_merge_hooks` — core merge logic
- [ ] **4.4** Implement `harness_demerge_hooks` — core removal logic
- [ ] **4.5** Implement `harness_merge_settings` — orchestrator wrapper
- [ ] **4.6** Verify: merge into empty file creates correct structure
- [ ] **4.7** Verify: merge into file with existing hooks appends without duplicates
- [ ] **4.8** Verify: running merge twice produces identical output (idempotency)
- [ ] **4.9** Verify: de-merge removes only harness entries, preserves user entries
- [ ] **4.10** Verify: de-merge of last hook under an event removes the event key
- [ ] **4.11** Verify: de-merge of all hooks removes the `hooks` key entirely
- [ ] **4.12** Verify: settings.json formatting is preserved (2-space indent, trailing newline)

---

## 5. Interface Contracts

### Exposes

| Function | Consumers | Contract |
|----------|-----------|----------|
| `harness_merge_hooks` | `harness_merge_settings`, C7 | Merges hook entries into settings.json. Idempotent. Creates file if absent. |
| `harness_demerge_hooks` | C7 (uninstall) | Removes hook entries from settings.json. Safe if file absent. Cleans up empty structures. |
| `harness_merge_settings` | C7 (install) | Top-level entry point for all settings merges. Currently delegates to `harness_merge_hooks`. |

### Consumes

| What | Source | Contract |
|------|--------|----------|
| `jq` binary | System PATH | Must be installed. Checked at source-time (R1). |
| `hooks_json` input | C7 (install.sh builds this from the hook registry) | Array of `{event, matcher, command}` objects per manifest schema (spec 00 section 5) |
| `settings.json` | `~/.claude/settings.json` | May or may not exist. May have user-added content. |

### Sourcing Contract

This file is **sourced**, not executed:
```sh
. "$HARNESS_DIR/lib/merge.sh"
```

The jq dependency check runs at source time.

---

## 6. Implementation Notes

### jq Merge Strategy

The core merge is a jq filter that processes the hooks_json array and folds each entry into the existing settings. The key insight: jq's `reduce` over the hooks array, building up the settings object entry by entry.

**Pseudocode for merge:**
```
for each hook in hooks_json:
  event = hook.event
  matcher = hook.matcher
  command = hook.command
  new_hook_obj = {"type": "command", "command": command}

  if .hooks[event] does not exist:
    create .hooks[event] = [{"matcher": matcher, "hooks": [new_hook_obj]}]
  elif no entry in .hooks[event] has .matcher == matcher:
    append {"matcher": matcher, "hooks": [new_hook_obj]} to .hooks[event]
  elif entry exists but no hook in .hooks has .command == command:
    append new_hook_obj to that entry's .hooks array
  else:
    skip (already present)
```

**jq implementation approach:**

```sh
harness_merge_hooks() {
  hm_settings_file="$1"
  hm_hooks_json="$2"

  # Create file if absent
  if [ ! -f "$hm_settings_file" ]; then
    echo '{}' > "$hm_settings_file"
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
```

### jq De-merge Strategy

**Pseudocode for de-merge:**
```
for each hook in hooks_json:
  event = hook.event
  matcher = hook.matcher
  command = hook.command

  find entry in .hooks[event] where .matcher == matcher
  remove hook from entry's .hooks where .command == command
  if entry's .hooks is now empty, remove the entry
  if .hooks[event] is now empty, remove the event key
if .hooks is now empty, remove .hooks key
```

```sh
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
```

### File Safety

Settings.json writes use a write-to-stdout-then-redirect pattern, not in-place editing. jq reads the entire file into memory, transforms it, and outputs to stdout. The shell redirect atomically replaces the file content.

**Concern:** If jq fails mid-stream, the redirect could truncate the file. Mitigation: capture jq output to a variable first, check exit code, then write.

```sh
result=$(jq '...' "$file") || { echo "harness: jq failed" >&2; return 1; }
printf '%s\n' "$result" > "$file"
```

This pattern is used in both merge and de-merge (shown in the implementation above).

### POSIX Compliance

The jq filters themselves are not subject to POSIX sh constraints — they are jq expressions passed as string arguments. The shell code wrapping them follows POSIX sh conventions:
- No arrays (hooks_json is a JSON string, not a shell array)
- Variable names use function-unique prefixes (`hm_` for merge, `hd_` for de-merge) to avoid collisions when sourced

---

## 7. Testing Strategy

Manual testing via shell invocations against fixture files. The merge/de-merge cycle is the core correctness property, so test fixtures cover the full lifecycle.

### Test Fixtures

```sh
# Setup
MERGE_TEST_DIR=$(mktemp -d)

# Fixture 1: Empty settings (file does not exist)
# (no file created — merge should create it)

# Fixture 2: Settings with no hooks key
echo '{"env": {"FOO": "bar"}}' > "$MERGE_TEST_DIR/no-hooks.json"

# Fixture 3: Settings with existing user hooks
cat > "$MERGE_TEST_DIR/user-hooks.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/my-custom-hook.sh"
          }
        ]
      }
    ]
  },
  "env": {
    "FOO": "bar"
  }
}
EOF

# Fixture 4: Settings with harness hooks already present (for idempotency test)
cat > "$MERGE_TEST_DIR/already-merged.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/src/claude-work-harness/hooks/state-guard.sh"
          }
        ]
      }
    ]
  }
}
EOF

# Standard harness hooks input
HOOKS_JSON='[
  {"event":"PostToolUse","matcher":"Write|Edit","command":"/home/user/src/claude-work-harness/hooks/state-guard.sh"},
  {"event":"Stop","matcher":"","command":"/home/user/src/claude-work-harness/hooks/work-check.sh"}
]'
```

### Test Cases

| # | Test | Setup | Action | Expected |
|---|------|-------|--------|----------|
| 1 | Merge into nonexistent file | No file | `harness_merge_hooks /tmp/new.json "$HOOKS_JSON"` | File created with both hooks in correct structure |
| 2 | Merge into empty object | `echo '{}' > f` | `harness_merge_hooks f "$HOOKS_JSON"` | `hooks` key added with both entries |
| 3 | Merge into file with no hooks key | Use `no-hooks.json` | Merge | `hooks` key added, `env` key preserved |
| 4 | Merge preserves user hooks | Use `user-hooks.json` | Merge | User's Bash hook preserved, harness hooks added alongside |
| 5 | Idempotency | Use `already-merged.json` | Merge same hooks again | No change — no duplicate entries |
| 6 | Idempotency byte-identical | Merge, save checksum, merge again | Compare checksums | Checksums match |
| 7 | Two hooks same event different matcher | Hooks with same event, different matchers | Merge | Both appear as separate entries under the same event |
| 8 | Two hooks same event+matcher | Hooks with same event and matcher, different commands | Merge | Both commands in same entry's hooks sub-array |
| 9 | De-merge removes harness hooks | Merged state | `harness_demerge_hooks` | Only harness hooks removed |
| 10 | De-merge preserves user hooks | Merged state with user hooks | De-merge | User hooks intact |
| 11 | De-merge cleans empty event | Only harness hooks under event | De-merge | Event key removed |
| 12 | De-merge cleans empty hooks object | All hooks are harness-added | De-merge | `hooks` key removed entirely |
| 13 | De-merge on nonexistent file | No file | De-merge | Exit 0, no error |
| 14 | De-merge on file with no hooks | File with `env` only | De-merge | File unchanged |
| 15 | Full lifecycle | Empty file | Merge, verify, de-merge, verify | File returns to `{}` after full cycle |
| 16 | Preserves JSON formatting | File with 2-space indent | Merge | Output uses 2-space indent (jq default) |
| 17 | Preserves non-hooks keys | File with `env`, `permissions` | Merge + de-merge | Non-hooks keys untouched throughout |

---

## 8. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| jq not installed | Source-time exit 2 with message (R1) |
| settings.json does not exist | `harness_merge_hooks` creates it with `{}`. `harness_demerge_hooks` returns 0. |
| settings.json is empty file (0 bytes) | jq will fail to parse. Return exit 1 with error message. Caller should handle (install.sh can seed `{}`). |
| settings.json contains invalid JSON | jq fails. Exit 1 with descriptive error message. Do not attempt to fix — user must repair manually. |
| settings.json is read-only | Write fails. Shell redirect error propagates. Exit 1. |
| hooks_json is empty array `[]` | `reduce` over empty array is a no-op. File unchanged. Return 0. |
| hooks_json is malformed JSON | jq `--argjson` fails. Exit 1 with error. |
| Existing hook has same event+matcher but different hook type (not "command") | The dedup check is on `command` path within the `hooks` sub-array. Non-command hooks are ignored during both merge and de-merge — they belong to the user. |
| Settings.json has additional top-level keys (env, permissions, etc.) | jq preserves all keys not touched by the filter. Verified by test case 17. |
| Concurrent access (two install.sh processes) | Not guarded. Document as unsupported — don't run install.sh concurrently. |
| Very large settings.json | jq loads entire file into memory. Not a practical concern — settings.json is small. |
| Hook command path contains special characters (spaces, etc.) | JSON string quoting handles this. The command path is stored as a JSON string value, not interpolated into shell. |
| Merge called with hooks for event that has null value (`"Stop": null`) | jq `//= []` normalizes null to empty array before processing. |
| De-merge called for hook that was never merged | No matching entry found. File unchanged. Return 0. |
| File ends without trailing newline | `printf '%s\n'` ensures trailing newline on output. |
| settings.json has trailing comma (invalid JSON) | jq fails. Exit 1. User must fix. |

---

## 9. Acceptance Criteria

1. `lib/merge.sh` exists and is a valid POSIX sh file (no bashisms in shell code)
2. Sourcing the file when jq is present produces no output and no side effects
3. Sourcing the file when jq is missing exits 2 with a descriptive stderr message (R1)
4. `harness_merge_hooks` creates settings.json if absent
5. `harness_merge_hooks` adds hooks key to settings.json that lacks it
6. `harness_merge_hooks` appends harness hooks without removing user hooks
7. `harness_merge_hooks` is idempotent — running twice produces byte-identical output
8. `harness_merge_hooks` correctly maps manifest format (`{event, matcher, command}`) to Claude Code settings format (`hooks.<event>[].{matcher, hooks[].{type, command}}`)
9. `harness_demerge_hooks` removes exactly the harness-added entries
10. `harness_demerge_hooks` preserves all user-added hooks
11. `harness_demerge_hooks` cleans up empty structures (empty hooks arrays, empty event keys, empty hooks object)
12. `harness_demerge_hooks` is safe on nonexistent files (returns 0)
13. Full lifecycle (merge then de-merge) returns settings.json to its pre-merge state
14. All error messages use the `harness:` prefix and write to stderr
15. All exit codes follow spec 00 section 3 (0 = success, 1 = general error, 2 = blocked)
16. Output JSON uses 2-space indentation with trailing newline
