# Spec C11: PR Handling — State-Driven

**Component**: C11 — PR handling: state-driven
**Phase**: 3 (New Commands)
**Status**: complete
**Dependencies**: Spec 00 (config injection, frontmatter schema)

---

## Overview and Scope

Refactors the existing `/pr-prep` command from a linear lint-fix-create flow to a state-driven system that infers the appropriate action from the current PR lifecycle state (DD-5). The existing lint/build/fix cycle (Steps 0-7) is preserved. The PR management section (currently Steps 8-9) is replaced with a state machine.

**What this does**:
- Replaces Steps 8-9 of `pr-prep.md` with a state machine
- Adds PR state detection logic
- Adds new states: CI failing, needs reviewers, description stale, merged/cleanup
- Preserves the existing lint/build/fix cycle (Steps 0-7)
- Adds `--force-<action>` escape hatch for overriding state inference

**What this does NOT do**:
- Change the lint/build/fix cycle (Steps 0-7 remain as-is)
- Add new lint strategies or build commands
- Integrate with external CI systems (uses `gh` CLI only)

---

## Implementation Steps

### Step 1: Define State Machine

The PR state machine detects the current state and routes to the appropriate action:

```
┌─────────────────────────────────────────┐
│            /pr-prep invoked             │
│         (after lint/build/fix)          │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│ Detect PR state via     │
│ gh pr view + gh run list│
└─────────┬───────────────┘
          │
    ┌─────┴──────┬──────────┬──────────┬──────────┬──────────┐
    ▼            ▼          ▼          ▼          ▼          ▼
 NO_PR      NO_DESC    CI_FAIL    CI_PASS    STALE_DESC  MERGED
 exists     /labels    ing        no revw    ription
    │            │          │          │          │          │
    ▼            ▼          ▼          ▼          ▼          ▼
 Create PR   Generate   Report    Suggest    Update     Cleanup
             desc+      failures  reviewers  desc       branch
             labels     + offer              to match   + bd close
                        fix                  changes
```

### Step 2: Define State Detection Logic

Replace the existing Step 8 with state detection:

```markdown
## Step 8: PR State Detection

Skip this step if `$ARGUMENTS` contains `--no-pr`.

Detect the current PR lifecycle state:

### Detection Sequence

Run these checks in order. The FIRST matching state determines the action.

1. **Check if PR exists**:
   ```bash
   gh pr view --json number,title,body,baseRefName,state,labels,reviewRequests,isDraft 2>&1
   ```
   If command fails (exit code != 0) → state is `NO_PR`

2. **Check if PR is merged**:
   If `state == "MERGED"` → state is `MERGED`

3. **Check if PR is draft**:
   If `isDraft == true` → state is `DRAFT` (treat as `NO_DESC` if description is empty, otherwise skip PR management -- drafts are WIP)

4. **Check CI status**:
   ```bash
   gh run list --branch "$(git branch --show-current)" --limit 5 --json status,conclusion,name
   ```
   If any run has `conclusion == "failure"` and the run is for the latest commit → state is `CI_FAIL`

5. **Check description quality**:
   If `body` is empty or fewer than 20 characters, or `labels` is empty → state is `NO_DESC`

6. **Check description staleness**:
   ```bash
   git log $(gh pr view --json baseRefName -q '.baseRefName')..HEAD --oneline
   ```
   Compare commit count with what the PR description covers. If there are commits not reflected in the description (heuristic: description mentions fewer files than the diff touches) → state is `STALE_DESC`

7. **Check reviewer assignment**:
   If `reviewRequests` is empty → state is `NEEDS_REVIEWERS`

8. **Default**: If none of the above match → state is `UP_TO_DATE` (no action needed)
```

**Acceptance Criteria**:
- AC-C11-2.1: State detection sequence is defined with 8 ordered checks
- AC-C11-2.2: Each state has explicit detection criteria referencing specific `gh` commands
- AC-C11-2.3: `NO_PR` state is detected first (before any other checks)
- AC-C11-2.4: `MERGED` state is detected before checking CI or description

### Step 3: Define State Actions

```markdown
## Step 9: Execute State Action

Based on the detected state, execute the corresponding action:

### NO_PR — Create PR
(Preserved from existing Step 8c — create new PR flow)
1. Determine base branch
2. Push current branch
3. Gather context
4. Draft PR title and body
5. Show to user for approval
6. Create with `gh pr create`

### NO_DESC — Generate Description
1. Fetch full diff against base branch
2. Draft title and body from diff analysis
3. Show to user for approval
4. Apply with `gh pr edit --title "..." --body "..."`
5. If labels are empty, suggest labels based on changed files

### CI_FAIL — Report and Offer Fix
1. List failing runs with their names and failure reasons:
   ```bash
   gh run view <run-id> --log-failed 2>&1 | tail -50
   ```
2. Present failures to user
3. Offer to fix: "Would you like me to analyze and fix these CI failures?"
4. If user accepts, analyze failure logs and apply fixes (same approach as lint fix)
5. If user declines, report the failures and exit

### NEEDS_REVIEWERS — Suggest Reviewers
1. Read `review_routing` from `.claude/harness.yaml` (if available)
2. Map changed files to reviewer areas
3. Suggest reviewers:
   ```
   Based on changes to [areas], suggested reviewers:
   - @reviewer1 (area: backend)
   - @reviewer2 (area: frontend)
   ```
4. If no `review_routing` configured, suggest based on `git log --format='%ae' -- <changed-files> | sort -u`
5. Wait for user approval before assigning

### STALE_DESC — Update Description
(Preserved from existing Step 8b — review existing PR flow)
1. Fetch current title and body
2. Compare against actual changes
3. Draft updated title/body
4. Show diff to user for approval
5. Apply with `gh pr edit`

### MERGED — Cleanup
1. Report: "PR #N has been merged."
2. Clean up local branch:
   ```bash
   git checkout $(gh pr view --json baseRefName -q '.baseRefName')
   git pull
   git branch -d <merged-branch>
   ```
3. Close associated beads issue:
   ```bash
   bd close <issue-id> --reason="PR #N merged"
   ```
   (If no beads issue is associated, skip)
4. Report cleanup results

### DRAFT — Work in Progress
1. If description is empty, treat as `NO_DESC` (generate description for the draft)
2. If description exists, report: "PR #N is a draft. No action needed."

### UP_TO_DATE — No Action
Report: "PR #N is up to date. No action needed."
```

**Acceptance Criteria**:
- AC-C11-3.1: Each of the 8 states has a defined action sequence
- AC-C11-3.2: `NO_PR` action preserves the existing create-PR flow from Step 8c
- AC-C11-3.3: `CI_FAIL` action retrieves actual failure logs
- AC-C11-3.4: `MERGED` action cleans up local branch and closes beads issue
- AC-C11-3.5: All actions that modify the PR wait for user approval
- AC-C11-3.6: `NEEDS_REVIEWERS` uses `review_routing` from harness.yaml when available

### Step 4: Add Force Override Flags

```markdown
## Force Override

The user can bypass state detection with explicit flags:

| Flag | Forces State |
|------|-------------|
| `--create-only` | `NO_PR` (create even if PR exists — useful for targeting a different base) |
| `--update-desc` | `STALE_DESC` (force description update) |
| `--cleanup` | `MERGED` (force cleanup even if state detection fails) |

These flags skip state detection entirely and go directly to the specified action.
```

**Acceptance Criteria**:
- AC-C11-4.1: Three force override flags are documented
- AC-C11-4.2: Each flag maps to a specific state action
- AC-C11-4.3: Flags skip state detection when provided

### Step 5: Handle Edge Cases

```markdown
## Edge Cases

| Scenario | Handling |
|----------|----------|
| `gh` CLI not installed | Report error: "gh CLI required for PR management. Install: https://cli.github.com/" |
| Not authenticated with gh | Report error: "Not authenticated. Run: gh auth login" |
| No remote configured | Report error: "No remote configured for current branch" |
| Force-pushed branch | State detection uses latest commit; force push does not affect state machine |
| Multiple failing CI runs | Report all failures, not just the latest |
| PR closed (not merged) | Detect via `state == "CLOSED"` → report "PR was closed without merging" |
| Branch behind base | Warn: "Branch is N commits behind base. Consider rebasing before PR actions." |
```

**Acceptance Criteria**:
- AC-C11-5.1: Seven edge cases are documented with explicit handling
- AC-C11-5.2: gh CLI availability is checked before state detection

---

## Interface Contracts

### Exposes

- **Refactored `/pr-prep` command**: State-driven PR lifecycle management
- **State machine**: 8 states with detection and action logic

### Consumes

- **Spec 00 Contract 3**: Config injection directive (already present in pr-prep.md)
- **`code-quality` skill**: Already loaded via existing `skills:` frontmatter
- **`harness.yaml`**: `review_routing` for reviewer suggestions, `build` for lint/build commands
- **`gh` CLI**: GitHub CLI for all PR operations
- **Beads**: For `MERGED` cleanup (closing associated issue)

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/commands/pr-prep.md` | Replace Steps 8-9 with state machine |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **State detection — no PR**: On a branch with no PR, run `/pr-prep --no-pr` first to skip, then `/pr-prep` to verify it detects `NO_PR` and offers to create.

2. **State detection — existing PR**: On a branch with an existing PR, verify the command detects the correct state (likely `UP_TO_DATE` or `STALE_DESC`).

3. **Force override**: Run `/pr-prep --update-desc` on a PR that is up-to-date. Verify it forces the description update flow regardless of state.

4. **CI failure detection**: On a branch with a failing CI run, verify `CI_FAIL` is detected and failure logs are retrieved.

5. **Edge case — no gh**: Temporarily alias `gh` to a nonexistent command, verify the error message is clear.

6. **Existing Steps 0-7 preserved**: Verify the lint/build/fix cycle in Steps 0-7 is unchanged from the current file.
