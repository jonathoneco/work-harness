# Handoff: Spec → Decompose

## What This Step Produced

6 specification documents (00-05) defining detailed implementation contracts for all 5 components, plus cross-cutting contracts. All 7 deferred questions from the plan step are resolved.

### Key Artifacts
- `.work/context-lifecycle/specs/00-cross-cutting-contracts.md` — Shared schemas: tech identifier format, manifest schema, document location resolution, staleness report format, approval signal definitions, state.json contract, file path conventions
- `.work/context-lifecycle/specs/01-tech-manifest.md` — C1: `.claude/tech-deps.yml` creation and bootstrapping
- `.work/context-lifecycle/specs/02-self-re-invocation.md` — C2: Skill() re-invocation at step gates in work commands
- `.work/context-lifecycle/specs/03-post-compact-hook.md` — C3: PostCompact hook script + settings.json registration
- `.work/context-lifecycle/specs/04-archive-housekeeping.md` — C4: Deprecated table diff + staleness scan + report/issues
- `.work/context-lifecycle/specs/05-gate-approval.md` — C5: Explicit approval protocol with re-confirmation
- `.work/context-lifecycle/specs/index.md` — Spec index with dependency ordering and deferred question resolutions

## Spec Summary

### Components and File Impact

| Spec | Component | Files Modified | Repo |
|------|-----------|---------------|------|
| 01 | C1: Tech Manifest | `.claude/tech-deps.yml` (new) | gaucho |
| 02 | C2: Self-Re-Invocation | `work-deep.md`, `work-feature.md`, `work-fix.md` | dotfiles |
| 03 | C3: PostCompact Hook | `scripts/hooks/post-compact.sh` (new), `.claude/settings.json` | gaucho |
| 04 | C4: Archive Housekeeping | `work-archive.md` | dotfiles |
| 05 | C5: Gate Approval | `work-deep.md`, `work-feature.md`, `work-fix.md` | dotfiles |

### Dependency Graph
- **Phase 1** (parallel): C1, C2, C3, C5
- **Phase 2** (depends on C1): C4
- **Critical path**: C1 → C4
- Note: C2 and C5 both modify the same files (work-*.md) — they can be combined into a single stream to avoid merge conflicts

### Key Design Decisions Made in Specs
1. **Tech identifier format**: Lowercase kebab-case, case-insensitive match after normalization (strip parentheticals, replace spaces with hyphens)
2. **Self-re-invocation wording**: Plain language, no aggressive framing. "Re-invoke this command via Skill('<command>') to refresh instructions."
3. **PostCompact hook**: POSIX sh, always exit 0, one line per active task, silent when no active tasks
4. **Staleness report**: 3-section markdown (stale deps, manifest gaps, unresolved entries) + beads issues for findings
5. **Approval signals**: Explicit list in spec 00. "Ready to advance?" prompt. Re-confirmation after Q&A. State updates NEVER in same turn as results.
6. **Cleanup issue sequencing**: Independent — resolve before or during implementation, not a formal Phase 0
7. **Manifest bootstrapping**: Manual creation. Archive scan catches gaps going forward.

### Shared File Overlap
C2 and C5 both modify `work-deep.md`, `work-feature.md`, `work-fix.md`. Recommend combining into one stream to avoid merge conflicts. C2 modifies the Context Compaction Protocol section and transition step h. C5 modifies transition steps e-g and the Inter-Step Quality Review Protocol.

## Instructions for Decompose Step

1. Read this handoff — do NOT re-read individual specs in full (this handoff captures the structure)
2. Break specs into work items (one beads issue per atomic implementation unit)
3. Group into streams considering the shared file overlap between C2 and C5
4. Create the concurrency map — Phase 1 (parallel) and Phase 2 (sequential)
5. Write stream execution documents
6. Track in `.work/context-lifecycle/streams/manifest.jsonl`

### Suggested Stream Decomposition
- **Stream A**: C1 (tech manifest) — standalone, project repo, small
- **Stream B**: C2 + C5 (re-invocation + approval fix) — combined, dotfiles repo, medium (shared files)
- **Stream C**: C3 (PostCompact hook) — standalone, project repo, small
- **Stream D**: C4 (archive housekeeping) — Phase 2, dotfiles repo, depends on Stream A completion
