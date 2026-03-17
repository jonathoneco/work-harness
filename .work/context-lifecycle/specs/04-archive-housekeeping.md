# Spec 04: Archive-Time Housekeeping (C4)

**Component**: C4 | **Scope**: Medium | **Phase**: 2 | **Dependencies**: spec 00, spec 01 (C1)

## Overview

Extend the archive process with three new sub-steps: deprecated table diffing, staleness scanning, and report generation with beads issue creation. These are inserted into `work-archive.md` between the existing "Promote futures" step and the "Set archived_at" step. The scan is fail-closed — errors block archive completion.

## Implementation Steps

### Step 1: Add deprecated table diff sub-step to work-archive.md

**Insertion point**: After "Promote futures" (current step 7), before "Set archived_at" (current step 5 — renumbered after insertion).

**New step: Deprecated Table Diff**

```markdown
### Step N: Deprecated Table Diff

1. Read `base_commit` from `.work/<name>/state.json`
2. Run: `git diff <base_commit>...HEAD -- .claude/rules/beads-workflow.md`
3. Parse the diff for new rows in the "Deprecated Approaches" table:
   - New rows are lines starting with `+|` that contain a pipe-delimited entry
   - Extract the "Deprecated" column value from each new row
   - Normalize to lowercase kebab-case per spec 00 identifier rules
4. If new deprecated entries found: store as `newly_deprecated` list for the staleness scan
5. If no diff or no new entries: `newly_deprecated` is empty (not an error)
6. If git diff fails: **STOP archive** — report the error and ask user to resolve
```

**Acceptance criteria**:
- Diff is computed from `base_commit` (stored in state.json at task creation) to HEAD
- Only the deprecated approaches table section is relevant — ignore other changes to the file
- New row detection is robust: matches `+|` prefix lines with pipe-delimited content
- Git diff failure is a hard error (fail-closed)

### Step 2: Add staleness scan sub-step to work-archive.md

**New step: Staleness Scan**

```markdown
### Step N+1: Staleness Scan

1. Read `.claude/tech-deps.yml` (the tech manifest from C1)
   - If file is missing: **STOP archive** — "Tech manifest not found. Create `.claude/tech-deps.yml` before archiving."
   - If YAML parse fails: **STOP archive** — report parse error
2. Read the current deprecated approaches table from `.claude/rules/beads-workflow.md`
3. Build a set of deprecated technology identifiers (normalized per spec 00)
4. **Declared dependency check**: For each manifest entry:
   a. For each `dep` in the entry's `deps` list:
   b. Normalize and check against the deprecated set
   c. If match: flag as "stale declared dependency"
5. **Content grep for newly deprecated** (only if `newly_deprecated` is non-empty):
   a. For each newly deprecated item:
   b. Resolve all document paths per spec 00 location rules
   c. Grep each file for the deprecated technology name (case-insensitive)
   d. Flag any matches as "undeclared stale reference"
6. **Manifest completeness check** (content grep for all deprecated items):
   a. For each deprecated technology in the table:
   b. Grep all context documents for references
   c. If a reference is found but the document has no corresponding `dep` in the manifest:
   d. Flag as "manifest gap"
7. Produce staleness report per spec 00 format
```

**Acceptance criteria**:
- Missing manifest is a hard error (fail-closed)
- YAML parse error is a hard error (fail-closed)
- Content grep is case-insensitive
- Both declared deps AND undeclared content references are checked
- Manifest gaps are detected (references found by grep but not declared in manifest)

### Step 3: Add report and issue creation sub-step

**New step: Staleness Report & Issues**

```markdown
### Step N+2: Staleness Report & Issues

1. If staleness report is empty (no findings):
   - Print: "Staleness scan: clean (N documents checked)"
   - Continue to next archive step
2. If findings exist:
   - Print the full staleness report (format per spec 00)
   - For each stale finding, create a beads issue:
     ```bash
     bd create --title="[Housekeeping] <document>: stale <dep> reference" \
       --type=task --priority=3 \
       --description="Staleness scan found <dep> reference in <document>. <dep> is deprecated (replaced by <replacement>). Action: <suggested-action>"
     ```
   - For each manifest gap, create a beads issue:
     ```bash
     bd create --title="[Housekeeping] Update tech manifest: <document> uses <dep>" \
       --type=task --priority=4 \
       --description="Content grep found <dep> reference in <document> but it is not declared in .claude/tech-deps.yml"
     ```
   - Present findings to user
3. Findings do NOT block archive completion — they are tracked as separate issues
   - Rationale: The scan is fail-closed for ERRORS (can't read manifest, can't parse YAML, git diff fails). But findings themselves are informational — they create follow-up work, not blockers.
```

**Acceptance criteria**:
- Clean scan prints a single summary line
- Each stale finding creates a beads issue with `[Housekeeping]` tag
- Stale dependency issues are P3 (low priority)
- Manifest gap issues are P4 (backlog)
- Findings do not block archive — only scan ERRORS block
- Report is printed to console before issues are created

### Step 4: Update the archive step numbering

The existing archive process (in work-archive.md) has 9 steps:
1. Find task → 2. Verify completion → 3. Check finding triage → 4. Generate archive summary → 5. Set archived_at → 6. Close beads → 7. Promote futures → 8. Git commit → 9. Report

New housekeeping steps are inserted AFTER "Generate archive summary" (step 4) and BEFORE "Set archived_at" (step 5). This ensures staleness is checked before the task is marked archived.

New order:

| # | Step | Source |
|---|------|--------|
| 1 | Find task | Existing |
| 2 | Verify completion | Existing |
| 3 | Check finding triage (T2-3) | Existing |
| 4 | Generate archive summary (T3) | Existing |
| 5 | **Deprecated table diff** | **NEW** |
| 6 | **Staleness scan** | **NEW** |
| 7 | **Staleness report & issues** | **NEW** |
| 8 | Set `archived_at` | Existing (was 5) |
| 9 | Close beads issue/epic | Existing (was 6) |
| 10 | Promote futures | Existing (was 7) |
| 11 | Git commit | Existing (was 8) |
| 12 | Report | Existing (was 9) |

**Acceptance criteria**:
- New steps are inserted between "Generate archive summary" (current step 4) and "Set archived_at" (current step 5)
- Existing step references in the document are updated to match new numbering
- The fail-closed behavior is clear: steps 5-6 can halt the archive; step 7 findings create issues but don't block

## Interface Contracts

**Exposes**:
- Staleness report (printed to console)
- Beads issues tagged `[Housekeeping]` for each finding

**Consumes**:
- Spec 00: technology identifier format, staleness report format, document location resolution
- Spec 01 (C1): `.claude/tech-deps.yml` manifest
- `.claude/rules/beads-workflow.md`: deprecated approaches table
- `.work/<name>/state.json`: `base_commit` for diff calculation

## Files to Create/Modify

| File | Action |
|------|--------|
| `~/.claude/commands/work-archive.md` | **Modify** — insert 3 new steps, renumber existing |

## Testing Strategy

- **Manual test with clean project**: Run archive with no deprecated deps → verify "clean" output
- **Manual test with stale dep**: Add a known-deprecated dep to manifest, run archive → verify report and issue creation
- **Manual test with manifest gap**: Reference a deprecated tech in a document without declaring it → verify gap detection
- **Error path test**: Temporarily rename tech-deps.yml, run archive → verify it stops with clear error
- **No automated tests**: This is a prompt-driven process in a markdown command file

## Error Handling Summary

| Error | Behavior | Rationale |
|-------|----------|-----------|
| Missing `.claude/tech-deps.yml` | **STOP archive** | Can't scan without manifest — fail closed |
| YAML parse error in manifest | **STOP archive** | Corrupt manifest means unreliable scan — fail closed |
| `git diff` failure | **STOP archive** | Can't determine newly deprecated items — fail closed |
| Document name doesn't resolve | Flag in report as "unresolved" | Advisory — may be a manifest typo |
| grep finds no matches | Normal — document is clean | Expected for most documents |
| Stale findings exist | Create issues, continue archive | Findings are follow-up work, not blockers |
