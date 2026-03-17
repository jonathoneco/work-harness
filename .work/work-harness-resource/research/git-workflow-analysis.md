# Git Workflow Analysis Across Mined Sessions

Extracted from 14 sessions across 4 worktrees. 317 total git commands.

## Summary Stats

| Session | Git Cmds | Commits | Pushes | Status/Diff | Branch/PR/Rebase |
|---------|----------|---------|--------|-------------|------------------|
| strip-e41b8c95 (implement) | 84 | 30 | 4 | 38 | 4 (PR create) |
| main-fe7cd6a4 (context-lifecycle) | 84 | 8 | 4 | 22 | 27 (rebase/stash/cherry-pick) |
| ph1-4ba64b10 (harness-enforcement) | 49 | 31 | 1 | 7 | 1 |
| ph1-c1619c39 (harness v2 impl) | 21 | 7 | 2 | 7 | 0 |
| ph1-3186d70b (dev-env-silo) | 21 | 10 | 4 | 1 | 0 |
| strip-4868fe3a (review protocol) | 19 | 4 | 6 | 7 | 0 |
| sr-f392cd9a (wf1-cleanup) | 18 | 1 | 0 | 11 | 0 |
| Others | ~21 | ~8 | ~2 | ~6 | 0 |

## Commit Patterns

### Conventional Commit Prefixes
All commits follow conventional commits. Prefixes observed across sessions:
- `feat:` — new functionality
- `fix:` — bug fixes
- `refactor:` — code restructuring
- `chore:` — state files, archiving, beads sync
- `docs:` — documentation updates

### Staging Discipline
- **Specific file staging (61%)** — `git add .work/strip-api/ internal/handlers/auth.go migrations/041_*`
- **Broad staging (39%)** — `git add .` or `git add -A` (mostly for large deletion phases or chore commits)

### Commit Frequency
- **Heavy implementation sessions** average 1 commit every 2-3 minutes (strip-e41b8c95: 30 commits in ~2 hours)
- **Planning/research sessions** average 2-4 commits total (state.json + artifacts)
- **Harness iteration sessions** commit after each discrete fix

### Commit Scoping
Commits are scoped to logical units:
- Per-phase commits during implementation ("refactor: Phase 2 — auth conversion")
- Separate commits for .work/ state vs code changes
- beads sync commits kept separate (`chore: sync beads JSONL`)

## Push Patterns

### When Pushes Happen
- **After archive** — always push after `/work-archive`
- **After PR creation** — push + PR in the same flow
- **After harness iteration** — push both project and dotfiles repos
- **Cross-repo pushes** — `cd /home/jonco/src/dotfiles && git push` common when harness changes touch both

### Push Frequency
- Strip-api: 4 pushes total (end of each major phase + PR)
- Harness sessions: push after each iteration + push dotfiles
- Total: ~24 pushes across all sessions

## PR Creation

Only one PR was created in the mined sessions:

```bash
gh pr create --title "Strip project to JSON API-only backend" --body "$(cat <<'EOF'
## Summary
Converts gaucho from a monolithic Go+HTMX web app to a pure JSON API backend...
EOF
)"
```

This happened at the end of the strip-api task, after `/work-archive`. The PR was the final artifact.

**Pattern:** The harness does product work on feature branches. PRs are created after the task is complete and archived, not during implementation.

## Branching and Worktree Operations

### Worktree Model
The user maintains multiple git worktrees, each on its own feature branch:
- `gaucho` (main) — harness iteration and coordination
- `gaucho-stripped-api` (feature/stripped-api) — product work
- `gaucho-service-refactor` (feature/service-refactor) — product work
- `gaucho-frontend-infra` (feature/frontend-infra) — product work
- `gaucho-agentic-phase-1` (various feature branches) — older work

Each worktree runs its own Claude Code sessions. The harness is branch-aware (beads issues are per-branch via BEADS_DIR).

### Rebase Operations (context-lifecycle session)

The most complex git workflow was rebasing worktrees to adopt harness improvements from main:

1. `git worktree list` — survey current state
2. `git rebase main` on service-refactor — hit conflict on .review/findings.jsonl
3. `git rebase --skip` then `--continue` with manual conflict resolution
4. `git stash --include-untracked` on frontend-infra before rebase
5. Multiple rebase attempts on frontend-infra (wrong base branch complication)
6. `git branch -f feature/frontend-infra main` — reset branch to main
7. `git cherry-pick 458a2f6 eba0bef` — preserve workflow progress commits
8. `git stash pop` — restore working tree

**Key insight:** Worktree rebasing is the primary mechanism for propagating harness improvements across active feature branches. This is ad-hoc — the harness has no tooling for it.

### Stash Usage
Stash is used defensively during rebases:
- `git stash --include-untracked -m "pre-rebase stash"` before risky operations
- `git stash pop` after success
- `git stash store -m "recovered: ..."` to preserve state after complex recovery

## Git as Verification

### Status/Diff as Checkpoints
99 total status/diff commands across sessions. Primary uses:
1. **Before committing** — `git status --short` to see what's staged
2. **After implementation agents complete** — `git diff --stat` to verify scope
3. **Before step transitions** — verify all changes are committed
4. **Cross-repo verification** — `cd /other-worktree && git status` to check divergence

### Diff for Review
- `git diff <base_commit>..HEAD` used during `/work-review` to scope review
- `git diff` (unstaged) to verify agent edits before staging
- `git diff --stat` for quick summary of change scope

## Cross-Repo Operations

Multiple sessions operated across repos:
- **Project + dotfiles** — harness iteration sessions push to both
- **Multiple worktrees** — rebase operations touch 2-3 worktrees
- **`cd /other/repo && git ...`** — 15+ cross-repo git commands

**Anti-pattern discovered:** When rebasing worktrees, .review/findings.jsonl creates merge conflicts because it's an append-only file modified in multiple branches.

## Patterns for the Guide

1. **Feature branches + worktrees** — each task lives on a feature branch in its own worktree. The harness tracks state per-worktree via `.work/`.

2. **Commits are scoped, not batched** — one logical change per commit, conventional prefixes. State changes and code changes are separate commits.

3. **PRs are post-archive artifacts** — the harness runs the full lifecycle on a feature branch, then a PR is the final deliverable.

4. **Rebasing propagates harness improvements** — when commands/hooks change on main, worktrees rebase to adopt. This is manual and can be complex.

5. **Git status/diff are the human's verification tool** — 99 invocations across sessions, used at every transition point.

6. **Cross-repo pushes are common** — harness changes must land in both project and dotfiles.
