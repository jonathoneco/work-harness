# Stream C: PostCompact Hook (C3)

**Phase**: 1 (parallel) | **Work Items**: W-04 (rag-wy5t4) | **Spec**: 03

## Context

Create a PostCompact hook that mechanically suggests re-grounding after context compaction. This is the hook-driven complement to C2's prompt-driven re-invocation. The hook fires deterministically after every `/compact`.

## Work Item: W-04 — Create PostCompact hook

**Beads ID**: rag-wy5t4

### Steps

1. **Create the hooks directory**: `mkdir -p scripts/hooks/`
   Note: Existing hooks live in `.claude/hooks/` (behavioral guards: state-guard, beads-check, review-gate, etc.). This hook goes in `scripts/hooks/` because it's informational (always exits 0, advisory output) rather than a behavioral guard. Do NOT relocate to `.claude/hooks/`.

2. **Write the hook script**: Create `scripts/hooks/post-compact.sh` (POSIX sh):
   ```sh
   #!/bin/sh
   # PostCompact hook: suggest re-grounding after context compaction

   found=0

   for state_file in .work/*/state.json; do
       [ -f "$state_file" ] || continue

       archived=$(grep -o '"archived_at": *null' "$state_file")
       [ -z "$archived" ] && continue

       name=$(grep -o '"name": *"[^"]*"' "$state_file" | head -1 | sed 's/.*: *"//;s/"//')
       tier=$(grep -o '"tier": *[0-9]*' "$state_file" | head -1 | sed 's/.*: *//')
       step=$(grep -o '"current_step": *"[^"]*"' "$state_file" | head -1 | sed 's/.*: *"//;s/"//')

       case "$tier" in
           1) cmd="work-fix" ;;
           2) cmd="work-feature" ;;
           3) cmd="work-deep" ;;
           *) cmd="work-reground" ;;
       esac

       echo "Active task: $name (step: $step). Run /$cmd to re-ground."
       found=1
   done

   exit 0
   ```

3. **Make executable**: `chmod +x scripts/hooks/post-compact.sh`

4. **Register in settings.json**: Add PostCompact hook to `.claude/settings.json` using the existing nested format:
   ```json
   "PostCompact": [
     {
       "matcher": "",
       "hooks": [
         {
           "type": "command",
           "command": "scripts/hooks/post-compact.sh"
         }
       ]
     }
   ]
   ```
   Add this to the existing `hooks` object — do NOT replace other hooks.

5. **Validate**:
   - Run `shellcheck scripts/hooks/post-compact.sh`
   - Test manually with an active task present
   - Test with no active tasks (verify silent exit)

### Acceptance Criteria
- `scripts/hooks/` directory exists
- Script is POSIX sh compatible (passes shellcheck)
- Script is executable
- Outputs one line per active task with correct command suggestion
- Silent exit when no active tasks
- Always exits 0
- Hook registered in settings.json using the nested `{matcher, hooks: [{type, command}]}` format
- Existing hooks preserved

### Files to Create/Modify
- `scripts/hooks/` (new directory)
- `scripts/hooks/post-compact.sh` (new file)
- `.claude/settings.json` (modify — add PostCompact entry)

### Spec Reference
- `.work/context-lifecycle/specs/03-post-compact-hook.md`
- `.work/context-lifecycle/specs/00-cross-cutting-contracts.md` (state.json contract)

### Dependencies
- None (Phase 1, parallel with Streams A and B)

### Claim and Close
```bash
bd update rag-wy5t4 --status=in_progress
# ... implement ...
bd close rag-wy5t4
```
