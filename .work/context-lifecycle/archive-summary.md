# Archive Summary: context-lifecycle

**Tier:** 3
**Duration:** 2026-03-15T23:30:00Z → 2026-03-16T07:00:00Z
**Sessions:** 3
**Beads epic:** rag-hc9ou

## What Was Built

Added systematic lifecycle management to context documents (skills, specs, rules) across 5 mechanisms:

1. **Tech manifest** (`.claude/tech-deps.yml`): YAML mapping context docs to technology dependencies, used by archive-time housekeeping to detect stale references. Identifiers are lowercase kebab-case.

2. **Self-re-invocation**: When a user continues after compaction without running `/compact`, work commands re-invoke themselves via `Skill('<command-name>')` to refresh instructions at the end of the context window.

3. **Gate approval protocol fix** (rag-idnu7): All step transitions now require explicit approval signals (yes/proceed/approve/lgtm/go ahead/continue). State.json is never updated in the same turn as presenting results. Q&A re-confirmation prevents accidental advancement.

4. **PostCompact hook** (`scripts/hooks/post-compact.sh`): POSIX sh hook using jq to detect active tasks and suggest the correct re-grounding command per tier. Always exits 0 (advisory).

5. **Archive housekeeping**: 3 new steps in work-archive.md — deprecated table diff (git diff against base_commit), staleness scan (check deps against deprecated set), and staleness report & issues (create [Housekeeping] beads issues). Fail-closed for scan errors; findings don't block archive.

## Key Files

**New files:**
- `.claude/tech-deps.yml` — technology dependency manifest
- `scripts/hooks/post-compact.sh` — PostCompact hook

**Modified files (both gaucho + dotfiles):**
- `.claude/commands/work-deep.md` — gate approval protocol + self-re-invocation
- `.claude/commands/work-feature.md` — gate approval + self-re-invocation
- `.claude/commands/work-fix.md` — gate approval
- `.claude/commands/work-archive.md` — archive housekeeping steps (6-8)
- `.claude/settings.json` — PostCompact hook registration

## Findings Summary
- 2 total findings (0 fixed, 0 deferred — both suggestions, non-blocking)
- f-20260316-001: post-compact.sh grep/sed parsing → addressed by jq rewrite
- f-20260316-002: pre-existing cross-repo divergence → addressed by syncing dotfiles

## Staleness Report
- 3 stale declared deps in commands/ama (all intentional historical context) → rag-rd8pg (P4)
- 0 manifest gaps
- 15 documents checked

## Futures Promoted
- freshness_class field (next)
- last_reviewed field (next)
- Session-start staleness warnings (quarter)
