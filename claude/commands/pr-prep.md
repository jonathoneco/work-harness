---
description: "Fix lint/build issues and create or update PR — intelligent fixer using code-quality rules"
user_invocable: true
skills: [code-quality]
meta:
  stack: ["all"]
  version: 2
  last_reviewed: 2026-03-25
---

# /pr-prep $ARGUMENTS

Intelligent lint/build fixer and PR manager. Fixes code issues that need reasoning, then creates a PR if none exists or ensures an existing PR's title and description accurately reflect what the branch actually does.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 0: Read Build Commands

Read build commands from `.claude/harness.yaml` if it exists:

```yaml
build:
  lint: "<command>"    # e.g., "make lint"
  build: "<command>"   # e.g., "make build"
  test: "<command>"    # e.g., "make test"
  format: "<command>"  # e.g., "gofmt -w ."
```

If no harness.yaml exists, fall back to auto-detection:
- If `Makefile` exists with `lint`/`build`/`test` targets → use `make <target>`
- If `package.json` exists → use `npm run lint`, `npm run build`, `npm test`
- If `Cargo.toml` exists → use `cargo clippy`, `cargo build`, `cargo test`
- Otherwise → ask the user for commands

Store the resolved commands as `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, `$FORMAT_CMD`.

## Step 1: Run Lint and Capture Output

```bash
$LINT_CMD 2>&1
```

If lint passes cleanly, skip to Step 4.

## Step 2: Analyze and Fix Errors

Parse lint errors by category and fix each one. The fix strategy depends on the project language (read from harness.yaml `stack.language`):

**General strategies (all languages):**

| Category | Fix Strategy |
|----------|-------------|
| **Unused functions** | Check callers (use Serena `find_referencing_symbols` if available, else Grep). If truly dead code, delete. |
| **Unused variables** | Remove the variable, or use it if the intent is clear from context. |
| **Missing error checks** | Add error handling per language conventions. |
| **Ineffectual assignments** | Remove or restructure the assignment. |
| **Shadow declarations** | Rename the inner variable. |
| **Other lint issues** | Apply code-quality skill judgment. Read the relevant code, understand intent, fix correctly. |

For each fix:
1. Read the symbol/code containing the error
2. Understand the intent of the code
3. Apply the minimal correct fix — don't refactor surrounding code
4. Move to the next error

## Step 3: Verify Fixes

Run lint again:
```bash
$LINT_CMD 2>&1
```

If errors remain, repeat Step 2 for remaining issues. After 2 failed attempts at the same error, stop and report it to the user.

## Step 4: Build Check

```bash
$BUILD_CMD 2>&1
```

If the build fails, analyze the error and fix. Build errors take priority over any remaining lint warnings.

## Step 5: Optional Tests

If `$ARGUMENTS` contains `--test` or `--full`:
```bash
$TEST_CMD 2>&1
```

Fix any test failures. Otherwise, skip — tests run in CI.

## Step 6: Optional Format

If `$FORMAT_CMD` is set and `$ARGUMENTS` contains `--format`:
```bash
$FORMAT_CMD 2>&1
```

## Step 7: Stage and Commit Code Fixes

If any code was changed in Steps 1-6, stage only the modified files and commit:
```
fix: resolve lint issues for PR
```

If no code changes were needed, skip this step.

## Step 8: PR State Detection

Skip this step if `$ARGUMENTS` contains `--no-pr`.

### Edge Case Pre-checks

Before running state detection, verify prerequisites:

| Scenario | Handling |
|----------|----------|
| `gh` CLI not installed | Report error: "gh CLI required for PR management. Install: https://cli.github.com/" and stop. |
| Not authenticated with gh | Report error: "Not authenticated. Run: `gh auth login`" and stop. |
| No remote configured | Report error: "No remote configured for current branch." and stop. |
| Multiple remotes | Ask user which remote to use. |

Verify with:
```bash
command -v gh >/dev/null 2>&1 || echo "NO_GH"
gh auth status 2>&1 || echo "NO_AUTH"
git remote 2>&1
```

### Force Override Flags

If `$ARGUMENTS` contains a force flag, skip state detection and go directly to the corresponding action in Step 9:

| Flag | Forces State | Use Case |
|------|-------------|----------|
| `--create-only` | `NO_PR` | Create a new PR even if one exists (e.g., targeting a different base) |
| `--update-desc` | `STALE_DESC` | Force description regeneration regardless of current state |
| `--cleanup` | `MERGED` | Force branch cleanup even if state detection fails |

### Detection Sequence

If no force flag is present, run these checks in order. The **first matching state** determines the action.

1. **`NO_PR` — No PR exists for current branch**:
   ```bash
   gh pr view --json number,title,body,baseRefName,state,labels,reviewRequests,isDraft 2>&1
   ```
   If command fails (exit code != 0) → state is `NO_PR`

2. **`MERGED` — PR is merged**:
   If `state == "MERGED"` → state is `MERGED`

3. **`CLOSED` — PR was closed without merging**:
   If `state == "CLOSED"` → report "PR #N was closed without merging" and stop.

4. **`DRAFT` — PR is a draft**:
   If `isDraft == true` → state is `DRAFT`

5. **`CI_FAIL` — CI checks are failing**:
   ```bash
   gh run list --branch "$(git branch --show-current)" --limit 5 --json status,conclusion,name,headSha
   ```
   If any run has `conclusion == "failure"` and `headSha` matches the current HEAD → state is `CI_FAIL`

6. **`NO_DESC` — PR description is empty or placeholder**:
   If `body` is empty or fewer than 20 characters, or `labels` is empty → state is `NO_DESC`

7. **`STALE_DESC` — PR description doesn't match current diff**:
   ```bash
   git log $(gh pr view --json baseRefName -q '.baseRefName')..HEAD --oneline
   ```
   Compare commit count and changed files against what the PR description covers. If there are commits not reflected in the description (heuristic: description mentions fewer files than the diff touches) → state is `STALE_DESC`

8. **`NEEDS_REVIEWERS` — No reviewers assigned**:
   If `reviewRequests` is empty → state is `NEEDS_REVIEWERS`

9. **`UP_TO_DATE` — PR is good, nothing to do**: Default if none of the above match.

### Additional Edge Cases

| Scenario | Handling |
|----------|----------|
| Force-pushed branch | State detection uses latest commit; force push does not affect state machine |
| Multiple failing CI runs | Report all failures, not just the latest |
| Branch behind base | Warn: "Branch is N commits behind base. Consider rebasing before PR actions." |

## Step 9: Execute State Action

Based on the detected state from Step 8, execute the corresponding action.

### NO_PR — Create PR

1. Determine the base branch (default branch of the repo):
   ```bash
   gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
   ```

2. Ensure the current branch is pushed to the remote:
   ```bash
   git push -u origin HEAD
   ```

3. Gather context for the PR description:
   ```bash
   git log <base-branch>..HEAD --oneline
   git diff <base-branch>...HEAD --stat
   ```

4. Draft a PR title (under 70 chars, describes the "what") and body using this format:
   ```
   ## Summary
   <1-3 bullet points describing the key changes>

   ## Test plan
   <bulleted checklist of how to verify the changes>
   ```

5. Show the proposed PR to the user:
   ```
   Proposed PR title: <title>
   Proposed PR body:
   <body>
   ```

   Wait for user approval, then create:
   ```bash
   gh pr create --title "..." --body "$(cat <<'EOF'
   ...
   EOF
   )"
   ```

6. Report the PR URL to the user.

### MERGED — Cleanup

1. Report: "PR #N has been merged."
2. Clean up local branch:
   ```bash
   git checkout $(gh pr view --json baseRefName -q '.baseRefName')
   git pull
   git branch -d <merged-branch>
   ```
3. Close associated beads issue if one exists:
   ```bash
   bd close <issue-id> --reason="PR #N merged"
   ```
   If no beads issue is associated, skip.
4. Report cleanup results.

### DRAFT — Work in Progress

1. If description is empty, treat as `NO_DESC` (generate description for the draft).
2. If description exists, ask user: "PR #N is a draft. Mark as ready for review?" If user accepts:
   ```bash
   gh pr ready
   ```

### CI_FAIL — Report and Offer Fix

1. List failing runs with their names and failure reasons:
   ```bash
   gh run view <run-id> --log-failed 2>&1 | tail -50
   ```
2. Present failures to user.
3. Offer to fix: "Would you like me to analyze and fix these CI failures?"
4. If user accepts, analyze failure logs and apply fixes (same approach as lint fix in Steps 2-3).
5. If user declines, report the failures and exit.

### NO_DESC — Generate Description

1. Fetch full diff against base branch.
2. Draft title and body from diff analysis (same format as NO_PR step 4).
3. Show to user for approval.
4. Apply with:
   ```bash
   gh pr edit --title "..." --body "$(cat <<'EOF'
   ...
   EOF
   )"
   ```
5. If labels are empty, suggest labels based on changed files.

### STALE_DESC — Update Description

1. Fetch current title and body.
2. Compare against actual changes:
   ```bash
   git log <baseRefName>..HEAD --oneline
   git diff <baseRefName>...HEAD --stat
   ```
3. Draft updated title/body reflecting current state of the branch.
4. Show diff to user for approval:
   ```
   Current title: <old>
   Proposed title: <new>

   Body changes: <summary of what changed and why>
   ```
5. Wait for user approval, then apply:
   ```bash
   gh pr edit --title "..." --body "$(cat <<'EOF'
   ...
   EOF
   )"
   ```

### NEEDS_REVIEWERS — Suggest Reviewers

1. Read `review_routing` from `.claude/harness.yaml` (if available).
2. Map changed files to reviewer areas.
3. Suggest reviewers:
   ```
   Based on changes to [areas], suggested reviewers:
   - @reviewer1 (area: backend)
   - @reviewer2 (area: frontend)
   ```
4. If no `review_routing` configured, suggest based on:
   ```bash
   git log --format='%ae' -- <changed-files> | sort -u
   ```
5. Wait for user approval before assigning.

### UP_TO_DATE — No Action

Report: "PR #N is up to date. No action needed."

## Step 10: Report

Report to the user:
- Number of code issues fixed, by category (if any)
- PR state detected and action taken
- Whether PR title/description was created or updated (and what changed)
- Any issues that could not be auto-fixed
- The PR URL (if created or updated)
