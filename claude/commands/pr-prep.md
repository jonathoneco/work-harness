---
description: "Fix lint/build issues and create or update PR — intelligent fixer using code-quality rules"
user_invocable: true
skills: [code-quality]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
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

## Step 8: Review PR Title and Description

Skip this step if `$ARGUMENTS` contains `--no-pr`.

### Step 8a: Check for Existing PR

Check if a PR already exists for the current branch:
```bash
gh pr view --json number,title,body,baseRefName 2>/dev/null
```

If this succeeds, a PR exists — proceed to **Step 8b** (review existing PR).

If this fails (no PR for this branch), proceed to **Step 8c** (create new PR).

### Step 8b: Review Existing PR

1. Parse the PR metadata from the `gh pr view` output above.

2. Fetch the full diff against the base branch:
```bash
git log <baseRefName>..HEAD --oneline
git diff <baseRefName>...HEAD --stat
```

3. **Evaluate accuracy** — compare the current title and body against what the commits actually do:
   - Does the title accurately describe the change? (under 70 chars, focuses on the "what")
   - Does the body cover the key changes? Are there commits not reflected in the description?
   - Are there claims in the body that are no longer true (e.g., referencing removed code)?

4. **If the title and body are already accurate**, report "PR description is up to date" and skip to Step 9. Do NOT rewrite for style — only update when the content is materially wrong or incomplete.

5. **If updates are needed**, draft the new title and/or body and show the diff to the user:
   ```
   Current title: <old>
   Proposed title: <new>

   Body changes: <summary of what changed and why>
   ```

   Wait for user approval, then apply:
   ```bash
   gh pr edit --title "..." --body "$(cat <<'EOF'
   ...
   EOF
   )"
   ```

Skip to Step 9.

### Step 8c: Create New PR

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

## Step 9: Report

Report to the user:
- Number of code issues fixed, by category (if any)
- Whether PR title/description was updated (and what changed)
- Any issues that could not be auto-fixed
- "Ready to push." if all clear
