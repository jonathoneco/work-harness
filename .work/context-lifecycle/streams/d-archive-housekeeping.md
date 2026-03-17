# Stream D: Archive Housekeeping (C4)

**Phase**: 2 (sequential — depends on Stream A) | **Work Items**: W-05 (rag-sodgj) | **Spec**: 04

## Context

Add staleness scanning to the archive process. Three new steps inserted into `work-archive.md` between "Generate archive summary" (step 4) and "Set archived_at" (step 5). The scan uses the tech manifest created by Stream A (C1).

**DEPENDENCY**: Stream A must complete first — the archive scan reads `.claude/tech-deps.yml`.

## Work Item: W-05 — Add archive housekeeping steps

**Beads ID**: rag-sodgj (depends on rag-kcqx7)

### Steps

1. **Read current work-archive.md**: File is at `~/src/dotfiles/home/.claude/commands/work-archive.md`. Understand the current 9-step structure.

2. **Insert Step 5: Deprecated Table Diff** — after current step 4 (Generate archive summary):
   - Read `base_commit` from state.json
   - Run `git diff <base_commit>...HEAD -- .claude/rules/beads-workflow.md`
   - Parse for new rows in deprecated approaches table
   - Store `newly_deprecated` list
   - Git diff failure = **STOP archive** (fail-closed)

3. **Insert Step 6: Staleness Scan**:
   - Read `.claude/tech-deps.yml` — missing = **STOP archive** (fail-closed)
   - Read deprecated table from beads-workflow.md
   - Check declared deps against deprecated set
   - Content grep newly deprecated items across all context documents
   - Manifest completeness check
   - Produce staleness report (3 sections per spec 00 format)

4. **Insert Step 7: Staleness Report & Issues**:
   - If clean: print "Staleness scan: clean (N documents checked)"
   - If findings: print report, create `[Housekeeping]` beads issues (P3 for stale deps, P4 for manifest gaps)
   - Findings do NOT block archive — only scan ERRORS block

5. **Renumber existing steps**: Update all step numbers to match new 12-step order:
   | # | Step |
   |---|------|
   | 1-4 | Unchanged |
   | 5 | Deprecated table diff (NEW) |
   | 6 | Staleness scan (NEW) |
   | 7 | Staleness report & issues (NEW) |
   | 8 | Set archived_at (was 5) |
   | 9 | Close beads (was 6) |
   | 10 | Promote futures (was 7) |
   | 11 | Git commit (was 8) |
   | 12 | Report (was 9) |

6. **Add error handling summary** to the archive command documentation.

### Acceptance Criteria
- 3 new steps inserted at the correct position (between step 4 and old step 5)
- Deprecated table diff uses `base_commit` from state.json
- Missing manifest = hard error (archive stops)
- YAML parse error = hard error (archive stops)
- Git diff failure = hard error (archive stops)
- Stale findings create beads issues but do NOT block archive
- Staleness report follows spec 00 format (3 sections)
- All existing steps renumbered correctly
- No existing step logic is altered (only numbering changes)

### Files to Modify
- `~/src/dotfiles/home/.claude/commands/work-archive.md`

### Spec References
- `.work/context-lifecycle/specs/04-archive-housekeeping.md`
- `.work/context-lifecycle/specs/00-cross-cutting-contracts.md` (staleness report format, tech identifier format, document location resolution)
- `.work/context-lifecycle/specs/01-tech-manifest.md` (manifest schema)

### Dependencies
- **Blocked by**: Stream A (W-01, rag-kcqx7) — manifest must exist before archive can reference it
- Run `bd ready` before starting — this issue will only appear when W-01 is closed

### Claim and Close
```bash
bd update rag-sodgj --status=in_progress
# ... implement ...
bd close rag-sodgj
```
