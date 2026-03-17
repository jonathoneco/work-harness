# Spec 08: Hooks (C6)

**Component:** C6 — Hooks
**Phase:** 2 (Core)
**Scope:** Medium (parameterize 7 existing hooks to read harness.yaml via lib/config.sh)
**Dependencies:** C1 (repo scaffold), C10 (config reader)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)
**Resolves:** DQ1 (exact hook registration format per hook)

---

## 1. Overview

Seven hooks live in `hooks/` at the harness repo root. They are not copied to `~/.claude/` — instead, `settings.json` references them by absolute path (e.g., `/home/user/src/claude-work-harness/hooks/state-guard.sh`). This means hook updates are instant via `git pull` with no re-install.

All hooks are parameterized: they source `lib/config.sh` (C10) and read project config from `.claude/harness.yaml` at runtime. Hooks that ran with hardcoded project-specific values in the current codebase (e.g., Go-specific anti-patterns in `review-gate.sh`, Go-specific file extensions in `beads-check.sh`) now derive those values from the config.

### Current State vs Target State

| Hook | Current (gaucho-specific) | Target (harness-generic) |
|------|--------------------------|--------------------------|
| `state-guard.sh` | Hardcoded jq validation | Same logic, add config.sh preamble + graceful skip |
| `work-check.sh` | Hardcoded `.work/` checks | Same logic, add config.sh preamble + graceful skip |
| `beads-check.sh` | Hardcoded `.go|.js|.ts|.py|.sql|.html|.css` extensions | Read `extensions` from harness.yaml |
| `review-gate.sh` | Hardcoded Go anti-patterns (`_, _ =`, etc.) | Read `anti_patterns` from harness.yaml |
| `artifact-gate.sh` | Hardcoded step→dir mapping | Same logic, add config.sh preamble + graceful skip |
| `review-verify.sh` | Hardcoded review checks | Same logic, add config.sh preamble + graceful skip |
| `pr-gate.sh` | Hardcoded `gofmt`, `golangci-lint`, `go build` | Read `build.format`, `build.lint`, `build.build` from harness.yaml |

---

## 2. Hook Registration Table (DQ1 Resolution)

This is the definitive hook-to-event mapping. The install script (C7) registers these in `~/.claude/settings.json`.

| Hook | Event | Matcher | Behavior | Blocking? |
|------|-------|---------|----------|-----------|
| `state-guard.sh` | `PostToolUse` | `Write\|Edit` | Validates `.work/*/state.json` after writes | Yes (exit 2) |
| `work-check.sh` | `Stop` | (empty) | Warns about stale checkpoints on session end | No (exit 0 always) |
| `beads-check.sh` | `Stop` | (empty) | Blocks session end if code changed without claimed beads issue | Yes (exit 2) |
| `review-gate.sh` | `Stop` | (empty) | Blocks session end if anti-patterns detected in diff | Yes (exit 2) |
| `artifact-gate.sh` | `Stop` | (empty) | Blocks session end if completed steps lack required artifacts | Yes (exit 2) |
| `review-verify.sh` | `Stop` | (empty) | Blocks session end if archived tasks lack review evidence | Yes (exit 2) |
| `pr-gate.sh` | `PreToolUse` | `Bash` | Blocks `git push` if format/lint/build checks fail | Yes (exit 2) |

### Resulting settings.json Structure

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "<harness-dir>/hooks/state-guard.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "<harness-dir>/hooks/work-check.sh"
          },
          {
            "type": "command",
            "command": "<harness-dir>/hooks/beads-check.sh"
          },
          {
            "type": "command",
            "command": "<harness-dir>/hooks/review-gate.sh"
          },
          {
            "type": "command",
            "command": "<harness-dir>/hooks/artifact-gate.sh"
          },
          {
            "type": "command",
            "command": "<harness-dir>/hooks/review-verify.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "<harness-dir>/hooks/pr-gate.sh"
          }
        ]
      }
    ]
  }
}
```

Where `<harness-dir>` is the absolute path to the harness repo clone (stored in manifest).

### Manifest hooks_added Entries

Each hook produces one entry in the manifest's `hooks_added` array:

```json
[
  {"event": "PostToolUse", "matcher": "Write|Edit", "command": "<harness-dir>/hooks/state-guard.sh"},
  {"event": "Stop", "matcher": "", "command": "<harness-dir>/hooks/work-check.sh"},
  {"event": "Stop", "matcher": "", "command": "<harness-dir>/hooks/beads-check.sh"},
  {"event": "Stop", "matcher": "", "command": "<harness-dir>/hooks/review-gate.sh"},
  {"event": "Stop", "matcher": "", "command": "<harness-dir>/hooks/artifact-gate.sh"},
  {"event": "Stop", "matcher": "", "command": "<harness-dir>/hooks/review-verify.sh"},
  {"event": "PreToolUse", "matcher": "Bash", "command": "<harness-dir>/hooks/pr-gate.sh"}
]
```

---

## 3. Common Preamble

Every hook starts with the same preamble structure. This ensures consistent behavior per R1 (dep checking) and R2 (malformed config handling).

```sh
#!/bin/sh
# harness: <brief description>
# Component: C6
# Event: <event name>
# Matcher: <matcher pattern>
set -eu

# Read JSON context from stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')

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
```

**Key points:**
- `HARNESS_DIR` is resolved from the script's own path (`dirname "$0"/..`), not from the manifest. Hooks always live in the repo.
- `harness_has_config` and `harness_validate_config` come from `lib/config.sh` (C10).
- The `jq` dependency check happens inside `lib/config.sh` (it validates its own deps on source).
- Hooks that don't need harness.yaml values (e.g., `state-guard.sh` only validates state.json structure) still run the preamble for consistency but their core logic doesn't call `harness_config_get`.

---

## 4. Per-Hook Specifications

### 4.1 state-guard.sh

**Event:** PostToolUse
**Matcher:** `Write|Edit`
**Purpose:** Prevents `.work/*/state.json` corruption by validating structure after every write/edit.

**Config dependency:** None. This hook validates state.json structure regardless of project config. It still sources config.sh and checks for harness.yaml for consistent preamble, but the core logic is config-independent.

**Logic (unchanged from current):**
1. Extract `file_path` from tool input JSON
2. If path does not match `.work/*/state.json` — exit 0
3. If file doesn't exist — exit 0
4. Validate: tier is 1-3
5. Detect legacy format (steps as string array) — exit 0 if legacy
6. Validate: `current_step` exists and is in steps array
7. Validate: exactly one active step (or zero if archived)
8. Validate: active step matches `current_step`
9. Validate: step ordering — `[completed|skipped]* -> active -> not_started*`
10. Validate: `updated_at` is ISO 8601 if present

**Differences from current:** Adds config.sh preamble. Converts from `#!/bin/bash` to `#!/bin/sh`. Removes bash-specific `pipefail` (not available in POSIX sh). Uses POSIX-compatible constructs only. Note: the `while read` + process substitution (`< <(jq ...)`) is a bashism — replace with `jq -c '.steps[]' "$FILE_PATH" | while IFS= read -r row; do ... done`.

- [ ] **AC-1.1** Exits 0 when file_path is not a state.json
- [ ] **AC-1.2** Exits 2 with descriptive message when tier is invalid
- [ ] **AC-1.3** Exits 2 when step ordering is violated
- [ ] **AC-1.4** Exits 0 when harness.yaml is absent (graceful skip still runs validation — state-guard is useful even without config)
- [ ] **AC-1.5** Exits 2 when harness.yaml is present but malformed
- [ ] **AC-1.6** No bashisms — passes `shellcheck -s sh`

**Special note:** `state-guard.sh` is unusual among the hooks. Its core logic (validating state.json) is valuable regardless of whether the project has `harness.yaml`. The preamble's "graceful skip" for missing harness.yaml should NOT skip state-guard validation. Instead: the harness.yaml check is informational only for this hook. The hook always validates state.json files it sees, but only emits the malformed-config error if harness.yaml exists and is broken.

Revised preamble for state-guard only:
```sh
# state-guard always runs (state.json validation is config-independent)
# But still validate config if present (R2)
if harness_has_config "$CWD" && ! harness_validate_config "$CWD"; then
  echo "harness: .claude/harness.yaml is malformed — fix or remove it" >&2
  exit 2
fi
```

### 4.2 work-check.sh

**Event:** Stop
**Matcher:** (empty)
**Purpose:** Warns about stale/missing checkpoints for active Tier 2-3 tasks at session end.

**Config dependency:** None directly. Work task structure is config-independent.

**Logic (unchanged from current):**
1. Check `stop_hook_active` — exit 0 if true (prevent infinite loop)
2. If no `.work/` directory — exit 0
3. For each active (non-archived) state.json where tier >= 2:
   - If no `updated_at` field, check for any checkpoint file existence
   - If `updated_at` present, compare against latest checkpoint file mtime
   - Warn (to stderr) if checkpoint is stale or missing
4. Always exit 0 (non-blocking — advisory only)

**Differences from current:** Adds config.sh preamble. Converts to POSIX sh. Replaces `find -printf '%T@\n'` (GNU find extension) with portable alternative: `stat -c '%Y'` or `ls -lt`.

- [ ] **AC-2.1** Exits 0 when no `.work/` directory exists
- [ ] **AC-2.2** Emits warning to stderr for stale checkpoints
- [ ] **AC-2.3** Always exits 0 (never blocks session end)
- [ ] **AC-2.4** Exits 0 when harness.yaml is absent
- [ ] **AC-2.5** Exits 2 when harness.yaml is present but malformed
- [ ] **AC-2.6** No bashisms

### 4.3 beads-check.sh

**Event:** Stop
**Matcher:** (empty)
**Purpose:** Blocks session end if code files were changed (staged) without a claimed beads issue.

**Config dependency:** `extensions` array from harness.yaml. Used to determine which file extensions count as "code files" in the git diff check.

**Current hardcoded:** `grep -E '\.(go|js|ts|py|sql|html|css)$|Dockerfile|docker-compose.*\.yml|Makefile'`
**Target parameterized:** Read `extensions` from harness.yaml, build the grep pattern dynamically. Always include `Dockerfile|docker-compose.*\.yml|Makefile` as infrastructure files regardless of config.

**Logic:**
1. Check `stop_hook_active` — exit 0 if true
2. If no `.beads/` directory — exit 0 (project doesn't use beads)
3. Source config.sh, check harness.yaml
4. Read `extensions` array from harness.yaml via `harness_config_list extensions`
5. Build grep pattern from extensions (e.g., `[".go", ".sql"]` becomes `\.(go|sql)$`)
6. Append infrastructure file patterns: `Dockerfile|docker-compose.*\.yml|Makefile`
7. Check staged changes (`git diff --cached --name-only`) against pattern
8. Exclude `.work/` paths from "code modified" detection
9. If code changes found, check for in_progress beads issue (`bd list --status=in_progress`)
10. If no claimed issue — exit 2 with guidance message

**Fallback when extensions is empty or absent:** Use a sensible default set: `\.(go|py|ts|js|rs|sql|html|css)$`. This ensures beads enforcement works even for projects that haven't configured extensions.

- [ ] **AC-3.1** Reads extensions from harness.yaml when present
- [ ] **AC-3.2** Uses fallback extensions when harness.yaml has no extensions field
- [ ] **AC-3.3** Exits 0 when no `.beads/` directory
- [ ] **AC-3.4** Exits 2 with guidance when code changed without claimed issue
- [ ] **AC-3.5** Excludes `.work/` paths from code detection
- [ ] **AC-3.6** Exits 0 when harness.yaml is absent (graceful skip)
- [ ] **AC-3.7** Exits 2 when harness.yaml is present but malformed

### 4.4 review-gate.sh

**Event:** Stop
**Matcher:** (empty)
**Purpose:** Blocks session end if anti-patterns are detected in the session diff.

**Config dependency:** `anti_patterns` array from harness.yaml. Each entry has `pattern` (regex) and `description` (human-readable).

**Current hardcoded:**
```
critical_patterns=(
  '_, _ ='              # Swallowed error return
  '_ = .*\.Exec\('      # Swallowed DB exec
  '_ = .*\.Render\('    # Swallowed template render
)
```
**Target parameterized:** Read anti_patterns from harness.yaml.

**Logic:**
1. Check `stop_hook_active` — exit 0 if true
2. If no `.work/` directory or no active tasks — exit 0
3. Source config.sh, check harness.yaml
4. Read `anti_patterns` array from harness.yaml
5. If anti_patterns is empty — exit 0 (no patterns to check)
6. Get session diff (`git diff HEAD`), exclude test files
7. For each anti_pattern, grep the diff for the pattern
8. If any critical matches found — exit 2 with findings to stderr
9. If no matches — exit 0

**Pattern iteration:** Since POSIX sh has no arrays, iterate using yq to output one pattern per line, then read with a `while read` loop:

```sh
harness_config_list 'anti_patterns[].pattern' "$CWD" | while IFS= read -r pattern; do
  description=$(harness_config_get "anti_patterns[] | select(.pattern == \"$pattern\") | .description" "$CWD")
  matches=$(echo "$diff_output" | grep -n "^+" | grep -E "$pattern" || true)
  if [ -n "$matches" ]; then
    found_critical=true
    # accumulate findings...
  fi
done
```

- [ ] **AC-4.1** Reads anti_patterns from harness.yaml
- [ ] **AC-4.2** Exits 0 when anti_patterns is empty or absent
- [ ] **AC-4.3** Exits 2 with pattern description when matches found
- [ ] **AC-4.4** Excludes test files from pattern matching
- [ ] **AC-4.5** Exits 0 when no active tasks in `.work/`
- [ ] **AC-4.6** Exits 0 when harness.yaml is absent
- [ ] **AC-4.7** Exits 2 when harness.yaml is present but malformed

### 4.5 artifact-gate.sh

**Event:** Stop
**Matcher:** (empty)
**Purpose:** Blocks session end if completed workflow steps lack required artifacts (handoff prompts, research index, spec files, gate IDs).

**Config dependency:** None directly. Artifact requirements are workflow-structural, not project-specific.

**Logic (unchanged from current):**
1. Check `stop_hook_active` — exit 0 if true
2. If no `.work/` directory — exit 0
3. For each active (non-archived) task with tier >= 2 and non-legacy step format:
   - **Rule 1:** Completed steps (research, plan, spec, decompose) must have handoff prompts
   - **Rule 2:** Completed research must have `research/index.md`
   - **Rule 3:** Completed spec must have spec files in `.work/<name>/specs/`
   - **Rule 4:** Completed steps must have `gate_id` set
   - **Rule 5:** Spec files must not be in `docs/feature/<name>/` (legacy location)
4. Exit 2 on any violation

- [ ] **AC-5.1** Blocks when completed step lacks handoff prompt
- [ ] **AC-5.2** Blocks when completed research lacks index.md
- [ ] **AC-5.3** Blocks when completed spec lacks spec files
- [ ] **AC-5.4** Blocks when completed step lacks gate_id
- [ ] **AC-5.5** Exits 0 when harness.yaml is absent
- [ ] **AC-5.6** Exits 2 when harness.yaml is present but malformed

### 4.6 review-verify.sh

**Event:** Stop
**Matcher:** (empty)
**Purpose:** Blocks session end if archived Tier 2-3 tasks lack review evidence, or if review step is marked completed without `reviewed_at` timestamp.

**Config dependency:** None directly. Review requirements are workflow-structural.

**Logic (unchanged from current):**
1. Check `stop_hook_active` — exit 0 if true
2. If no `.work/` directory — exit 0
3. For each state.json with tier >= 2 and non-legacy step format:
   - **Check 1:** Archived task with `reviewed_at` field present must have a non-null value
   - **Check 2:** Review step marked completed must have `reviewed_at` set
4. Exit 2 on violation

- [ ] **AC-6.1** Blocks when archived task lacks review evidence
- [ ] **AC-6.2** Blocks when review step completed without reviewed_at
- [ ] **AC-6.3** Skips tasks without `reviewed_at` field (predates enforcement)
- [ ] **AC-6.4** Exits 0 when harness.yaml is absent
- [ ] **AC-6.5** Exits 2 when harness.yaml is present but malformed

### 4.7 pr-gate.sh

**Event:** PreToolUse
**Matcher:** `Bash`
**Purpose:** Gates `git push` commands — runs formatting, linting, and build checks before allowing push. Only fires when the current branch has an open PR.

**Config dependency:** `build.format`, `build.lint`, `build.build` from harness.yaml. These replace the hardcoded `gofmt`, `golangci-lint`, and `go build` commands.

**Current hardcoded:**
```sh
gofmt -l . && gofmt -w .
golangci-lint run --fix ./...
golangci-lint run ./...
go build ./cmd/server
```

**Target parameterized:**
```sh
format_cmd=$(harness_config_get 'build.format' "$CWD")
lint_cmd=$(harness_config_get 'build.lint' "$CWD")
build_cmd=$(harness_config_get 'build.build' "$CWD")
```

**Logic:**
1. Extract tool_name from input — exit 0 if not `Bash`
2. Extract command — exit 0 if not `git push`
3. Source config.sh, check harness.yaml. If absent — exit 0 (no checks for non-harness projects)
4. Check for open PR on current branch (`gh pr view`) — exit 0 if no PR
5. Read `build.format` — if non-empty, run it. If it changes files, block with message listing changed files.
6. Read `build.lint` — if non-empty, run it. If it fails, block with lint output.
7. Read `build.build` — if non-empty, run it. If it fails, block with build output.
8. If all pass — exit 0

**Key design difference from current:** The current pr-gate.sh does auto-fix (`gofmt -w`, `golangci-lint --fix`). The parameterized version cannot assume the format/lint commands support auto-fix. Instead:
- `build.format` is expected to be the format-in-place command (e.g., `gofmt -w .`). The hook runs it, then checks `git diff --name-only` for changes.
- `build.lint` is the lint check command. No auto-fix attempt — the hook reports failures.

- [ ] **AC-7.1** Only fires on `git push` commands
- [ ] **AC-7.2** Reads build.format from harness.yaml
- [ ] **AC-7.3** Reads build.lint from harness.yaml
- [ ] **AC-7.4** Reads build.build from harness.yaml
- [ ] **AC-7.5** Skips checks when no open PR on branch
- [ ] **AC-7.6** Blocks push when format command changes files
- [ ] **AC-7.7** Blocks push when lint command fails
- [ ] **AC-7.8** Blocks push when build command fails
- [ ] **AC-7.9** Exits 0 when harness.yaml is absent
- [ ] **AC-7.10** Exits 2 when harness.yaml is present but malformed
- [ ] **AC-7.11** Skips empty build commands (e.g., if build.lint is not set)

---

## 5. Files to Create

All paths relative to harness repo root.

| File | Description |
|------|-------------|
| `hooks/state-guard.sh` | PostToolUse: state.json validation |
| `hooks/work-check.sh` | Stop: checkpoint freshness warning |
| `hooks/beads-check.sh` | Stop: beads workflow enforcement |
| `hooks/review-gate.sh` | Stop: anti-pattern detection |
| `hooks/artifact-gate.sh` | Stop: artifact completeness validation |
| `hooks/review-verify.sh` | Stop: review evidence verification |
| `hooks/pr-gate.sh` | PreToolUse: pre-push format/lint/build |

All hooks must be `chmod +x`.

---

## 6. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| 7 executable hook scripts | C7 (install.sh registers them) | Each script at `<harness-dir>/hooks/<name>.sh`, absolute path in settings.json |
| Hook registration table (section 2) | C7 (install.sh), C8 (merge.sh) | Event + matcher + command path per hook |

### Consumes

| What | From | Contract |
|------|------|----------|
| `lib/config.sh` | C10 | `harness_has_config`, `harness_validate_config`, `harness_config_get`, `harness_config_list` |
| `.claude/harness.yaml` | Project (C11 creates it) | Schema v1 per spec 00 section 4 |
| JSON context on stdin | Claude Code runtime | `{"cwd": "...", "tool_name": "...", "tool_input": {...}, "stop_hook_active": bool}` |
| `jq` binary | System | R1: checked by config.sh on source |
| `yq` binary | System | R1: checked by config.sh on source |
| `bd` binary | System | Used only by beads-check.sh (`bd list --status=in_progress`) |
| `gh` binary | System | Used only by pr-gate.sh (`gh pr view`) |

---

## 7. Testing Strategy

Hooks are shell scripts. Testing is manual + structural verification.

### Structural Checks (automatable)

```sh
# All hooks are executable
for hook in hooks/*.sh; do
  [ -x "$hook" ] && echo "PASS: $hook executable" || echo "FAIL: $hook not executable"
done

# All hooks have POSIX shebang
for hook in hooks/*.sh; do
  head -1 "$hook" | grep -q '#!/bin/sh' && echo "PASS: $hook shebang" || echo "FAIL: $hook shebang"
done

# All hooks source config.sh
for hook in hooks/*.sh; do
  grep -q 'lib/config.sh' "$hook" && echo "PASS: $hook sources config.sh" || echo "FAIL: $hook missing config.sh"
done

# All hooks check harness_has_config or harness_validate_config
for hook in hooks/*.sh; do
  grep -q 'harness_has_config\|harness_validate_config' "$hook" \
    && echo "PASS: $hook checks config" || echo "FAIL: $hook missing config check"
done

# No bashisms (requires shellcheck)
for hook in hooks/*.sh; do
  shellcheck -s sh "$hook" && echo "PASS: $hook shellcheck" || echo "FAIL: $hook shellcheck"
done
```

### Scenario Testing (manual)

Each hook should be tested in these scenarios:

| Scenario | Expected |
|----------|----------|
| No `.claude/harness.yaml` in CWD | exit 0 (graceful skip) |
| Malformed `.claude/harness.yaml` (invalid YAML) | exit 2 with descriptive error |
| Valid harness.yaml, no trigger condition | exit 0 |
| Valid harness.yaml, trigger condition met | Hook-specific behavior (block or warn) |
| `jq` not on PATH | exit 2 with "jq required" message |
| `yq` not on PATH | exit 2 with "yq required" message |

---

## 8. Edge Cases and Error Handling

| Scenario | Hook(s) | Handling |
|----------|---------|----------|
| harness.yaml has empty `extensions` array | beads-check | Use fallback extensions set |
| harness.yaml has empty `anti_patterns` array | review-gate | Exit 0 (nothing to check) |
| harness.yaml has empty `build.*` fields | pr-gate | Skip that check step |
| All `build.*` fields empty | pr-gate | Exit 0 (no checks to run) |
| `gh` not installed | pr-gate | Skip PR check, exit 0 (can't determine PR status) |
| `bd` not installed | beads-check | Exit 0 (can't enforce beads without bd) |
| anti_pattern regex is invalid | review-gate | grep will fail — catch and warn, don't block |
| state.json with legacy string steps | state-guard | Exit 0 (skip validation for legacy format) |
| `.work/` exists but no state.json files | all Stop hooks | Glob matches nothing — loop body doesn't execute |
| Multiple active tasks | all Stop hooks | Check each independently |
| `stop_hook_active` is true | Stop hooks | Exit 0 immediately (prevent infinite loop) |
| Git not initialized in CWD | beads-check, review-gate, pr-gate | `git diff` returns empty — exit 0 |
| Symlinked harness.yaml | all | `harness_has_config` follows symlinks (default `[ -f ]` behavior) |

---

## 9. POSIX Compatibility Notes

The current hooks use bash features that must be replaced:

| Bashism | Where Used | POSIX Replacement |
|---------|-----------|-------------------|
| `set -euo pipefail` | All hooks | `set -eu` (no pipefail in POSIX sh) |
| `${critical_patterns[@]}` (arrays) | review-gate | `while read` loop from yq output |
| `< <(jq ...)` (process substitution) | state-guard | Pipe: `jq ... \| while read` |
| `[[ ]]` double brackets | N/A (not currently used) | `[ ]` single brackets |
| `echo -e` | review-gate | `printf '%s\n'` |
| `find -printf` | work-check | `stat -c '%Y'` or `ls -lt` based extraction |

---

## 10. Example Invocations

Hooks are invoked by Claude Code, not by users. The JSON context is piped to stdin.

### PostToolUse (state-guard)
```sh
echo '{"tool_name":"Edit","tool_input":{"file_path":"/home/user/project/.work/my-task/state.json"},"cwd":"/home/user/project"}' \
  | /home/user/src/claude-work-harness/hooks/state-guard.sh
```

### Stop (beads-check)
```sh
echo '{"cwd":"/home/user/project","stop_hook_active":false}' \
  | /home/user/src/claude-work-harness/hooks/beads-check.sh
```

### PreToolUse (pr-gate)
```sh
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin feature/my-branch"},"cwd":"/home/user/project"}' \
  | /home/user/src/claude-work-harness/hooks/pr-gate.sh
```
