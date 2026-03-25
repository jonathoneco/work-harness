# /migrate-to-beans

Migrate this project from beads to beans issue tracking.

## Steps

### Data
1. **Data migration**: Run `bn migrate-from-beads` to convert `.beads/issues.jsonl` → `.beans/issues.jsonl`

### Workflow artifacts
2. **State files**: For each `.work/*/state.json`:
   - Rename `beads_epic_id` → `epic_id`
   - Rename `beads_epic` → `epic_id`
   - Remove `beads_issue_id` if present (the canonical field is `issue_id`, already correct)
   - Keep `issue_id` as-is (IDs are preserved)
   - In `.work/*/review/findings.jsonl`: rename `beads_issue_id` → `tracking_issue_id`
3. **Handoff prompts**: In `.work/*/research/handoff-prompt.md` and `.work/*/plan/handoff-prompt.md`:
   - Replace `bd` → `bn` in command references
   - Replace `.beads/` → `.beans/` in file paths
   - Replace `beads` → `beans` in prose
4. **Project rules**: If the project has local rule files referencing beads:
   - Update `bd` → `bn` references
   - Update `.beads/` → `.beans/` paths

### Claude Code config
5. **Global settings** (`~/.claude/settings.json`):
   - Permissions: replace `"Bash(bd *)"` with `"Bash(bn *)"` in the allow list
   - Permissions: remove `"Bash(beads-sandbox-init*)"` if present
   - Hooks: replace `beads-check.sh` with `beans-check.sh` in Stop hooks
   - Plugins: remove `"beads@beads-marketplace": true` from `enabledPlugins`
6. **Project local settings** (`.claude/settings.local.json`):
   - Remove any stale beads permission entries (e.g., `"Bash(bash /tmp/beads_check.sh)"`)

### Git hooks
7. **Remove beads git hooks**:
   - `.git/hooks/post-merge` — beads import hook (beans doesn't need it, JSONL is git-native)
   - `.git/hooks/pre-commit` — beads daemon flush hook (beans has no daemon)
   - Only remove if these hooks are beads-specific (check for "beads" in the file header)

### Global rules
8. **Verify beans-workflow.md exists**: Check `~/.claude/rules/beans-workflow.md` is in place
9. **Remove beads-workflow.md**: Delete `~/.claude/rules/beads-workflow.md` after confirming beans rule works

### Verify and cleanup
10. **Verify**: `grep -r 'beads\|\.beads\|bd ' claude/ | grep -v beans` should return nothing (`.work/` archives may have historical beads references — that's expected)
11. **Cleanup**: After verification, `rm -rf .beads/` (the old beads directory)
12. **Commit**: Stage and commit all changes
