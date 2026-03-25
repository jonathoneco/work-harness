# Build beans (bn) — sh+jq issue tracker replacing beads
**Status:** Archived | **Tier:** 2 | **Beans:** work-harness-6l1

## What
Built a minimal POSIX sh + jq issue tracker (`bn`) to replace beads (`bd`). Single shell script (~450 lines) operating on `.beans/issues.jsonl` — a git-tracked JSONL file with `merge=union` for conflict-free merging. No daemon, no database, no external runtime dependencies. Migrated entire harness (31 files) from `bd` to `bn`. Context injection dropped from ~2,000 tokens to ~80 tokens.

## Components

| # | Component | File | Description |
|---|-----------|------|-------------|
| C1 | Core script | `bin/bn` | Entry point, arg parsing, all commands (~450 lines) |
| C2 | Init | (in C1) | Creates `.beans/`, config, JSONL, gitattributes |
| C3 | CRUD | (in C1) | create, show, update, close, list |
| C4 | Search | (in C1) | grep + jq full-text search |
| C5 | Dependencies | (in C1) | dep add, dep rm, ready filter |
| C6 | Merge/dedup | (in C1) | Dedup-on-read, compact-on-read |
| C7 | Locking | (in C1) | flock wrapper for concurrent access |
| C8 | Migration | (in C1) | migrate-from-beads jq transformer |
| C9 | Workflow rule | `~/.claude/rules/beans-workflow.md` | Minimal context injection (~21 lines) |
| C10 | Check hook | `hooks/beans-check.sh` | Enforces issue-before-code |
| C11 | Command updates | `claude/commands/work-*.md` | bd → bn mechanical swap (31 files) |
| C12 | Migration prompt | `claude/commands/migrate-to-beans.md` | Legacy project migration guide |

## Key Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| DD-1 | Single JSONL file, snake_case fields | Matches beads format, simple grep/jq |
| DD-2 | `{project}-{4hex}` IDs | Matches beads, preserves existing refs |
| DD-3 | 10 commands, no daemon commands | Only what the harness actually uses |
| DD-4 | merge=union + dedup-on-read | No merge conflicts, proven by seeds |
| DD-5 | flock + atomic rename | Safe concurrent access without daemon |
| DD-6 | grep -iF + jq for search | Fixed-string search, no regex surprises |
| DD-7 | ~21-line rule file (~80 tokens) | Down from 126 lines / ~2,000 tokens |
| DD-8 | Migration preserves beads IDs | state.json and commit refs stay valid |
| DD-9 | `bin/bn` in harness repo | Single file, symlinked via install.sh |
| DD-10 | Direct bd→bn, no compat layer | Clean break per code-quality rule 8 |

## Completed
Archived 2026-03-25. 11 review findings (5 critical, 5 important, 1 suggestion), all fixed. Delivered: `bin/bn` script, 31-file harness migration, hooks, install.sh integration, `/migrate-to-beans` command, beans-workflow.md rule, and beads data migration (110 issues).
