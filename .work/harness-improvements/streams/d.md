---
stream: D
phase: 1
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - hooks/post-compact.sh
---

# Stream D: Auto-Reground (C6)

**Phase:** 1 (no dependencies, immediately ready)
**Work Items:** W-06 (work-harness-63k)
**Spec:** 06

---

## Overview

Enhance the existing `hooks/post-compact.sh` to automatically detect the active task after context compaction, resolve the most relevant handoff prompt, and inject it directly into the post-compact output. This eliminates the manual `/work-reground` step — the agent regains task context immediately after compaction.

Currently the hook outputs a single-line suggestion ("Run /work-deep to re-ground."). After this work item, it outputs a delimiter-wrapped block containing the actual handoff prompt content (or a state.json summary fallback), giving the agent enough context to continue without a separate reground invocation.

---

## W-06: Auto-Reground Enhancement — spec 06

**Issue:** work-harness-63k
**Spec:** `.work/harness-improvements/specs/06-auto-reground.md`

### Files to Modify

| File | Action | Description |
|------|--------|-------------|
| `hooks/post-compact.sh` | Modify | Add `resolve_handoff` function, replace single-line output with structured context injection, add error handling for corrupt state |

### Implementation Notes

**Step 1: Add `resolve_handoff` function**

Add a shell function to `hooks/post-compact.sh` implementing 3-tier resolution:

1. Read `current_step` from state.json
2. Check `.work/<task-dir>/<current_step>/handoff-prompt.md` — use if exists
3. If not found, derive previous step from the `steps` array in state.json (the step at index-1 of `current_step`'s position). Check `.work/<task-dir>/<previous_step>/handoff-prompt.md` — use if exists
4. If neither exists, fall back to a summary from state.json: task title, tier, current step, step statuses

The function prints resolved content to stdout. It must not exit the script on failure — if resolution fails entirely, it prints nothing.

**Step 2: Extract previous step from state.json**

Previous step derivation must work for any step ordering (not just the default 7-step Tier 3 sequence). Use jq to find `current_step`'s index in the steps array and read index-1. If `current_step` is the first step (index 0), there is no previous step — skip to the state.json fallback.

**Step 3: Replace existing output with enhanced output**

Replace the current single-line output with structured output:

```
--- Active Task Context ---
Task: <title> (Tier <N>, step: <current_step>)

<handoff prompt content, or state.json summary if no handoff found>

Suggested: Run /<cmd> to continue.
--- End Task Context ---
```

Delimiter lines make the injected context visually distinct. Handoff content is included verbatim (not summarized or truncated — handoff prompts are already concise).

**Step 4: Handle corrupt or missing state.json gracefully (Advisory B2)**

All jq operations must use `2>/dev/null` and check for empty/null results. Failure modes:

- **state.json not valid JSON**: jq fails silently, task is skipped
- **Valid JSON but missing expected fields**: `resolve_handoff` returns empty, output falls back to the simple one-line message
- **Handoff prompt file exists but is empty**: Treated as "not found," resolution continues to next tier
- **All resolution tiers fail**: Output the simple one-line message (current behavior), not the enhanced format

The hook must never exit with a non-zero code due to state parsing failures.

**Step 5: Ensure compact-only behavior**

Verify the hook only runs on PostCompact. No code paths trigger on resume, startup, or other events. The hook reads from stdin, processes active tasks, and outputs context. It does not modify any files, state, or configuration.

**Step 6: Lint and validate**

Run `shellcheck` on the modified `hooks/post-compact.sh`. Fix any warnings. Ensure POSIX sh compatibility (no bashisms).

### Acceptance Criteria

- **AC-01**: `resolve_handoff` function implements 3-tier resolution: current step handoff, previous step handoff, state.json fallback -- verified by `manual-test`
- **AC-02**: `resolve_handoff` derives previous step from the steps array order in state.json, not from hardcoded step names -- verified by `structural-review`
- **AC-03**: Previous step derivation handles edge case where current_step is the first step in the array -- verified by `manual-test`
- **AC-04**: Post-compact output includes delimiter-wrapped task context section with handoff content -- verified by `manual-test`
- **AC-05**: Output preserves the existing suggested command (work-fix/work-feature/work-deep) based on tier -- verified by `manual-test`
- **AC-06**: Hook exits 0 even when state.json is unparseable, missing fields, or handoff files are absent -- verified by `manual-test`
- **AC-07**: When all resolution tiers fail, output falls back to the existing single-line message format -- verified by `manual-test`
- **AC-08**: Hook is read-only — it does not modify state.json, handoff files, or any other files -- verified by `structural-review`
- **AC-09**: Hook only produces output (no file writes, no state mutations, no external commands beyond jq) -- verified by `shellcheck` + `structural-review`
- **AC-10**: shellcheck passes with no warnings on hooks/post-compact.sh -- verified by `shellcheck`

### Dependency Constraints

- **Upstream:** None — Phase 1, immediately ready
- **Downstream:** Stream E (W-07) depends on this completing. C7 Step 2 refactors `post-compact.sh` to source `hooks/lib/common.sh`, so the auto-reground logic from C6 must be in place first.

### Claim and Close

```bash
bd update work-harness-63k --status=in_progress
# ... implement ...
bd close work-harness-63k --reason="Auto-reground: post-compact.sh injects handoff prompt content after compaction"
```
