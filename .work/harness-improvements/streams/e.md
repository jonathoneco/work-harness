---
stream: E
phase: 2
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - hooks/lib/common.sh
  - hooks/state-guard.sh
  - hooks/post-compact.sh
  - hooks/work-check.sh
  - hooks/artifact-gate.sh
  - hooks/review-verify.sh
  - hooks/review-gate.sh
  - hooks/beads-check.sh
  - hooks/pr-gate.sh
---

# Stream E: Hook Utilities Library (C7, Steps 1-2)

**Phase:** 2 (depends on W-06)
**Work Items:** W-07 (work-harness-ba9)
**Spec:** 07, Steps 1-2

---

## Overview

Extract ~120 lines of repeated boilerplate from 7+ hooks into `hooks/lib/common.sh`, then migrate all existing hooks to source the shared library. This is the shell-side half of C7 (Skill Library). The markdown-side (skills extraction and command refactoring) is handled by Stream F.

The shared library follows the existing `lib/config.sh` sourcing pattern: functions live in a `lib/` directory and are sourced by consumers at startup.

---

## W-07: Hook Utilities Library — spec 07, Steps 1-2

**Issue:** work-harness-ba9
**Spec:** `.work/harness-improvements/specs/07-skill-library.md` (Steps 1-2 only)

### Files

| File | Action | Description |
|------|--------|-------------|
| `hooks/lib/common.sh` | Create | Shared hook utilities: jq check, stdin reading, config init, task scanning, legacy format detection, error formatting |
| `hooks/state-guard.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/post-compact.sh` | Modify | Source common.sh, replace ~5 lines of boilerplate |
| `hooks/work-check.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/artifact-gate.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/review-verify.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/review-gate.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/beads-check.sh` | Modify | Source common.sh, replace ~18 lines of boilerplate |
| `hooks/pr-gate.sh` | Modify | Source common.sh, replace ~5 lines of boilerplate |

### Implementation Notes

#### Step 1: Create `hooks/lib/common.sh`

Build the shared hook utility library. This file is sourced by hooks, not executed directly.

**Boilerplate to extract** (currently repeated across 7 hooks):

| Boilerplate Pattern | Current Locations | Function Name |
|---------------------|-------------------|---------------|
| jq dependency check + exit 0 | All 7 hooks | `harness_require_jq` |
| Read JSON from stdin, extract `cwd` | 6 hooks (all PostToolUse/Stop) | `harness_read_hook_input` |
| Stop hook infinite-loop guard | 4 hooks (Stop event hooks) | `harness_stop_guard` |
| Harness dir resolution + config.sh sourcing + config validation | 6 hooks | `harness_init_config` |
| Active task scanning (`.work/*/state.json` where `archived_at` null) | 4 hooks | `harness_find_active_tasks` |
| Legacy format detection (string vs object steps) | 3 hooks | `harness_is_legacy_format` |
| Formatted error output to stderr | All 7 hooks | `harness_warn`, `harness_error` |

**Boilerplate that remains per-hook:**

- Tool matcher logic (specific to each hook's purpose)
- Business logic (validation rules, enforcement checks)
- Exit code decisions (pass/warn/block — hook-specific)

**Sourcing pattern** (follows `lib/config.sh` convention):

```sh
# In hook files:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
```

**Function contracts:**

- `harness_require_jq` — exits 0 if jq missing (hooks must not block on missing optional deps). No output on success.
- `harness_read_hook_input` — reads stdin into `HOOK_INPUT` global, extracts `HOOK_CWD`. Must be called exactly once per hook invocation.
- `harness_stop_guard` — checks `stop_hook_active` in `HOOK_INPUT`, exits 0 if true. Call after `harness_read_hook_input`.
- `harness_init_config` — resolves `HARNESS_DIR`, sources `config.sh` if yq available, validates config if present. Sets `HARNESS_CONFIG_AVAILABLE` (true/false). Exits 0 if no harness.yaml (project not harness-enabled).
- `harness_find_active_tasks` — prints one state.json path per line for active tasks in `$HOOK_CWD`. Returns 1 if no `.work/` directory or no active tasks.
- `harness_is_legacy_format <state_file>` — returns 0 if steps array uses string format (legacy), 1 if object format (current).
- `harness_warn <message>` — prints `harness: <hook-name>: <message>` to stderr. Hook name derived from `$0`.
- `harness_error <message>` — same format as `harness_warn`.

Every function must have a comment documenting its contract (inputs, outputs, exit codes).

#### Step 2: Migrate hooks to use `hooks/lib/common.sh`

Update each existing hook to source `common.sh` and replace inline boilerplate with function calls.

**Migration pattern per hook:**

Before:
```sh
command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 2; }
INPUT=$(cat)
STOP_ACTIVE=$(printf '%s\n' "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then exit 0; fi
CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if command -v yq >/dev/null 2>&1; then
  . "$HARNESS_DIR/lib/config.sh"
  if ! harness_has_config "$CWD"; then exit 0; fi
  if ! harness_validate_config "$CWD"; then
    echo "harness: .claude/harness.yaml is malformed" >&2; exit 2
  fi
fi
```

After:
```sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

harness_require_jq
harness_read_hook_input
harness_stop_guard          # only for Stop event hooks
harness_init_config
```

**Hooks to migrate:**

| Hook | Lines Removed | Functions Used |
|------|---------------|----------------|
| `state-guard.sh` | ~18 | `require_jq`, `read_hook_input`, `init_config` |
| `post-compact.sh` | ~5 | `require_jq`, `find_active_tasks` |
| `work-check.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks` |
| `artifact-gate.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks`, `is_legacy_format` |
| `review-verify.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks`, `is_legacy_format` |
| `review-gate.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config` |
| `beads-check.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config` |
| `pr-gate.sh` | ~5 | `require_jq`, `read_hook_input` |

**Important:** `post-compact.sh` does not use `harness_read_hook_input` because PostCompact hooks receive no stdin JSON. It uses only `harness_require_jq` and `harness_find_active_tasks`.

### Acceptance Criteria

- **AC-01**: `shellcheck hooks/lib/common.sh` passes with no errors -- verified by `shellcheck`
- **AC-02**: Every function in `common.sh` has a comment documenting its contract (inputs, outputs, exit codes) -- verified by `structural-review`
- **AC-03**: `common.sh` uses POSIX sh only (no bashisms) -- verified by `shellcheck -s sh`
- **AC-04**: Each migrated hook passes `shellcheck` -- verified by `shellcheck`
- **AC-05**: Each migrated hook produces identical behavior to the pre-migration version when run with the same stdin JSON input -- verified by `manual-test` (pipe mock JSON, compare output and exit code)
- **AC-06**: `post-compact.sh` continues to work without `harness_read_hook_input` (PostCompact hooks receive no stdin JSON) -- verified by `manual-test`

### Dependency Constraints

- **Upstream:** W-06 (work-harness-63k, Stream D) must complete first. C6 modifies `post-compact.sh` with auto-reground logic; this stream then refactors that hook (along with all others) to source `common.sh`.
- **Downstream:** None within this initiative. The shared library is consumed by existing hooks and is available for future hooks.

### Claim and Close

```bash
bd update work-harness-ba9 --status=in_progress
# ... implement ...
bd close work-harness-ba9 --reason="Hook utilities library created, all 8 hooks migrated to source common.sh"
```
