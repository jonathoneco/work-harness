# Spec 06: Auto-Reground (C6)

**Component**: C6 — Phase 1, Scope S, Priority P8

## Overview

After context compaction, the agent loses all working memory of the active task. The existing `hooks/post-compact.sh` outputs a one-line suggestion to run a reground command, but this requires the user to manually invoke reground and wait for context to reload. C6 enhances the post-compact hook to automatically detect the active task, resolve the most relevant handoff prompt, and inject it directly into the post-compact output so the agent regains task context immediately after compaction.

## Scope

**In scope:**
- Enhancing `hooks/post-compact.sh` to inject handoff prompt content
- Handoff prompt resolution logic (current step, previous step, state.json fallback)
- Graceful handling of missing or corrupt state files
- Compact-only behavior (no changes to resume or startup paths)

**Out of scope:**
- Changes to `workflow-detect.md` rule (startup detection, unchanged)
- Changes to `/work-reground` command (remains available for manual use)
- Memory enrichment via MCP KG servers (C11, Phase 4 — advisory B3)
- Hook lib extraction (C7, Phase 2 — C6 is self-contained in the existing hook file)
- Multi-task disambiguation (if multiple active tasks exist, inject the first found — same behavior as current hook)

## Implementation Steps

### Step 1: Add handoff prompt resolution function

Add a shell function `resolve_handoff` to `hooks/post-compact.sh` that implements the resolution order:

1. Read `current_step` from state.json
2. Check `.work/<task-dir>/<current_step>/handoff-prompt.md` — if it exists, use it (this covers the case where the step has been completed and we're transitioning)
3. If not found, derive the previous step from the `steps` array in state.json (the step immediately before `current_step` in array order). Check `.work/<task-dir>/<previous_step>/handoff-prompt.md` — if it exists, use it (this covers mid-step, where the current step hasn't produced a handoff yet but the previous step's handoff provides entry context)
4. If neither exists, fall back to extracting a summary from state.json: task title, tier, current step, and step statuses

The function prints the resolved content to stdout. It must not exit the script on failure — if resolution fails entirely, it prints nothing.

**AC-01**: `resolve_handoff function implements 3-tier resolution: current step handoff, previous step handoff, state.json fallback` -- verified by `manual-test`

**AC-02**: `resolve_handoff derives previous step from the steps array order in state.json, not from hardcoded step names` -- verified by `structural-review`

### Step 2: Extract previous step from state.json

The previous step derivation must work for any step ordering (not just the default 7-step Tier 3 sequence). Implementation:

```sh
# Get the index of current_step in the steps array, then read index-1
prev_step=$(jq -r --arg cs "$current_step" '
  .steps | to_entries[]
  | select(.value.name == $cs)
  | .key as $idx
  | if $idx > 0 then .key - 1 else empty end
' "$state_file" | head -1 | xargs -I{} jq -r ".steps[{}].name" "$state_file")
```

If `current_step` is the first step (e.g., "assess"), there is no previous step — skip directly to the state.json fallback.

**AC-03**: `Previous step derivation handles edge case where current_step is the first step in the array` -- verified by `manual-test`

### Step 3: Replace the existing output with enhanced output

Replace the current single-line output:
```
Active task: $name (step: $step). Run /$cmd to re-ground.
```

With structured output that includes the injected handoff content:

```
--- Active Task Context ---
Task: <title> (Tier <N>, step: <current_step>)

<handoff prompt content, or state.json summary if no handoff found>

Suggested: Run /<cmd> to continue.
--- End Task Context ---
```

The delimiter lines (`---`) make the injected context visually distinct in the post-compact output. The handoff content is included verbatim (not summarized or truncated by the hook — the handoff prompts are already written to be concise).

**AC-04**: `Post-compact output includes delimiter-wrapped task context section with handoff content` -- verified by `manual-test`

**AC-05**: `Output preserves the existing suggested command (work-fix/work-feature/work-deep) based on tier` -- verified by `manual-test`

### Step 4: Handle corrupt or missing state.json gracefully (Advisory B2)

All jq operations must use `2>/dev/null` and check for empty/null results. Specific failure modes:

- **state.json is not valid JSON**: jq fails silently, `archived` check returns empty, task is skipped (existing behavior preserved)
- **state.json is valid JSON but missing expected fields** (e.g., no `current_step`): `resolve_handoff` returns empty, output falls back to the simple one-line message from the current hook
- **Handoff prompt file exists but is empty**: Treated as "not found," resolution continues to next tier
- **All resolution tiers fail**: Output the simple one-line message (current behavior), not the enhanced format

The hook must never exit with a non-zero code due to state parsing failures. Advisory B2 is satisfied: warn and proceed, never block compaction.

**AC-06**: `Hook exits 0 even when state.json is unparseable, missing fields, or handoff files are absent` -- verified by `manual-test`

**AC-07**: `When all resolution tiers fail, output falls back to the existing single-line message format` -- verified by `manual-test`

### Step 5: Ensure compact-only behavior

Verify that the hook only runs on the PostCompact event. The hook is already registered as a post-compact hook (filename `post-compact.sh` in `hooks/`). No changes are needed to hook registration — only to the hook's internal logic.

Confirm: no code paths in the enhanced hook trigger on resume, startup, or other events. The hook reads from stdin (PostCompact event payload), processes active tasks, and outputs context. It does not modify any files, state, or configuration.

**AC-08**: `Hook is read-only — it does not modify state.json, handoff files, or any other files` -- verified by `structural-review`

**AC-09**: `Hook only produces output (no file writes, no state mutations, no external commands beyond jq)` -- verified by `shellcheck` + `structural-review`

### Step 6: Lint and validate

Run `shellcheck` on the modified `hooks/post-compact.sh`. Fix any warnings. Ensure POSIX sh compatibility (no bashisms).

**AC-10**: `shellcheck passes with no warnings on hooks/post-compact.sh` -- verified by `shellcheck`

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| Post-compact task context output | Claude Code (post-compact event) | Structured text block with handoff content injected after compaction |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| `.work/*/state.json` | Work harness state | Active task detection, current step, steps array |
| `.work/<name>/<step>/handoff-prompt.md` | Step transition logic in work-deep.md | Handoff prompts written at step boundaries |
| PostCompact event | Claude Code hooks system | Triggers hook execution |

### Does NOT consume (by design)

| Interface | Reason |
|-----------|--------|
| MCP memory servers | Advisory B3: C6 ships without memory awareness. C11 may enrich this later. |
| `hooks/lib/common.sh` | C7 (Phase 2) extracts shared utilities. C6 is self-contained in Phase 1. |

## Files

| File | Action | Description |
|------|--------|-------------|
| `hooks/post-compact.sh` | Modify | Add `resolve_handoff` function, replace single-line output with structured context injection, add error handling for corrupt state |

## Testing Strategy

| What | Method | Pass Criteria |
|------|--------|---------------|
| Shell correctness | `shellcheck` | No warnings, POSIX sh compatible |
| Happy path: current step handoff exists | `manual-test` | Hook outputs delimiter-wrapped content from current step's handoff-prompt.md |
| Fallback: only previous step handoff exists | `manual-test` | Hook outputs delimiter-wrapped content from previous step's handoff-prompt.md |
| Fallback: no handoff exists | `manual-test` | Hook outputs state.json summary (title, tier, step, statuses) |
| Full fallback: corrupt state.json | `manual-test` | Hook exits 0 with no output (or existing one-line format) |
| Full fallback: missing fields in state.json | `manual-test` | Hook exits 0, outputs one-line message |
| Empty handoff file treated as missing | `manual-test` | Resolution skips empty file and continues to next tier |
| First step (no previous) | `manual-test` | Previous step derivation skips gracefully to state.json fallback |
| Read-only behavior | `structural-review` | No file writes, no state mutations in hook code |
| Multi-task (edge case) | `manual-test` | First active task found is used (matches current behavior) |

### Manual Test Procedure

To test the hook manually, create a mock environment:

```sh
# Create test task directory
mkdir -p /tmp/test-harness/.work/test-task/research

# Write a minimal state.json
cat > /tmp/test-harness/.work/test-task/state.json << 'EOF'
{
  "title": "Test Task",
  "tier": 3,
  "current_step": "plan",
  "steps": [
    {"name": "assess", "status": "completed"},
    {"name": "research", "status": "completed"},
    {"name": "plan", "status": "active"}
  ],
  "archived_at": null
}
EOF

# Write a mock handoff prompt
cat > /tmp/test-harness/.work/test-task/research/handoff-prompt.md << 'EOF'
Research found 3 key areas. Focus on X, Y, Z during planning.
EOF

# Run the hook (from the test directory)
cd /tmp/test-harness && echo '{}' | /path/to/hooks/post-compact.sh
```

Verify output includes the research handoff content (previous step fallback, since plan has no handoff yet).

## Advisory Notes Resolution

| Note | Resolution |
|------|------------|
| **B2**: When state.json is unparseable, output warning and proceed without context injection. Never block compaction for corrupt state. | Implemented in Step 4. All jq operations use `2>/dev/null`. Unparseable state causes the task to be skipped entirely (existing loop behavior). Missing fields cause fallback to single-line output. Hook always exits 0. |
| **B3**: C6 ships WITHOUT memory awareness. Memory enrichment (C11) is a future enhancement, not something C6 designs for now. | Documented in the "Does NOT consume" table under Interface Contracts. The hook has no MCP dependencies. C11 may later wrap or extend the hook, but C6 does not design hook points for that — C11 owns its own integration strategy. |
