# Handoff: Decompose → Implement

## What This Step Produced

5 work items across 4 streams in 2 phases, with beads issues and dependencies configured.

### Key Artifacts
- `.work/context-lifecycle/streams/a-tech-manifest.md` — Stream A execution doc
- `.work/context-lifecycle/streams/b-work-command-updates.md` — Stream B execution doc (C2 + C5 combined)
- `.work/context-lifecycle/streams/c-post-compact-hook.md` — Stream C execution doc
- `.work/context-lifecycle/streams/d-archive-housekeeping.md` — Stream D execution doc
- `.work/context-lifecycle/streams/manifest.jsonl` — Work item → beads ID → stream mapping

## Concurrency Map

```
Phase 1 (parallel — no inter-dependencies):
  Stream A: W-01 (rag-kcqx7) — Create tech-deps.yml         [project repo]
  Stream B: W-02 (rag-dk3o5) + W-03 (rag-mtm7w) — Work cmd updates  [dotfiles repo]
  Stream C: W-04 (rag-wy5t4) — PostCompact hook              [project repo]

Phase 2 (depends on Stream A):
  Stream D: W-05 (rag-sodgj) — Archive housekeeping           [dotfiles repo]
```

**Critical path**: Stream A → Stream D

### Work Item Summary

| W# | Beads ID | Stream | Phase | Spec | Title | Repo |
|----|----------|--------|-------|------|-------|------|
| W-01 | rag-kcqx7 | A | 1 | 01 | Create tech-deps.yml | gaucho |
| W-02 | rag-dk3o5 | B | 1 | 02 | Add self-re-invocation | dotfiles |
| W-03 | rag-mtm7w | B | 1 | 05 | Fix gate approval protocol | dotfiles |
| W-04 | rag-wy5t4 | C | 1 | 03 | Create PostCompact hook | gaucho |
| W-05 | rag-sodgj | D | 2 | 04 | Add archive housekeeping | dotfiles |

### File Overlap Verification
- **Stream A**: `.claude/tech-deps.yml` (new) — no conflicts
- **Stream B**: `work-deep.md`, `work-feature.md`, `work-fix.md` — internal to stream, ordered (W-03 first, W-02 second)
- **Stream C**: `scripts/hooks/post-compact.sh` (new), `.claude/settings.json` — no conflicts with other streams
- **Stream D**: `work-archive.md` — no conflicts (Phase 2, different file from Stream B)

No file appears in more than one stream.

### Cross-Repo Note
Streams A and C modify gaucho project files. Streams B and D modify dotfiles repo files. Implementation agents for B and D need access to `~/src/dotfiles/home/.claude/commands/`.

## Instructions for Implement Step

1. Read this handoff — do NOT re-read individual specs (the stream execution docs contain everything needed)
2. **Phase 1**: Launch 3 parallel agents — one per stream (A, B, C)
   - Each agent reads its stream execution doc and the relevant specs
   - Agents claim issues with `bd update <id> --status=in_progress` and close with `bd close <id>`
3. **Phase 1 validation**: After all 3 streams complete, run Phase A + Phase B review
4. **Phase 2**: Launch Stream D agent (only after W-01 is closed)
5. **Phase 2 validation**: Review Stream D output
6. **Final verification**: Run `shellcheck scripts/hooks/post-compact.sh`, verify YAML parses
