# Context Document Lifecycle Management

**Status:** archived | **Tier:** 3 | **Beads:** rag-hc9ou

## What

Adds lifecycle management to context documents (skills, specs, rules) through 5 mechanisms: self-re-invocation at step gates for instruction fidelity, PostCompact hook for mechanical re-grounding after compaction, project-level tech manifest for staleness detection without modifying portable dotfiles skills, deprecated table diffing to auto-flag stale references, and archive-time housekeeping to scan all documents on task completion. Also fixes the gate approval bug where answering follow-up questions or presenting results was treated as implicit approval.

## Components

| # | Component | Scope | Key Files |
|---|-----------|-------|-----------|
| C1 | Project-Level Tech Manifest | Small | `.claude/tech-deps.yml` (new) |
| C2 | Self-Re-Invocation at Step Gates | Medium | `work-deep.md`, `work-feature.md`, `work-fix.md` |
| C3 | PostCompact Hook | Small | `.claude/settings.json`, `scripts/hooks/post-compact.sh` |
| C4 | Archive-Time Housekeeping | Medium | `work-archive.md` |
| C5 | Gate Approval Re-Confirmation | Small–Medium | `work-deep.md`, `work-feature.md`, `work-fix.md` |

## Key Decisions

- **Project-level manifest, not skill frontmatter**: Skills stay in dotfiles (portable). Project declares deps in `.claude/tech-deps.yml`.
- **Both Skill() + PostCompact**: Step gates use prompt-driven re-invocation; compaction uses hook-driven re-grounding
- **Scan all documents at archive**: Set is small (~30 files), making selective scanning needless complexity
- **Fail-closed for archive scan**: Scan errors block archive — no silent skipping
- **freshness_class and last_reviewed deferred**: No consumer in current architecture; deferred to futures
- **Explicit approval signals**: "Ready to advance?" prompt with re-confirmation after Q&A; state updates never in same turn as results
- **Tech identifiers**: Lowercase kebab-case, case-insensitive match against deprecated table
- **PostCompact hook**: POSIX sh, always exit 0, advisory suggestion (not automatic re-invocation)
