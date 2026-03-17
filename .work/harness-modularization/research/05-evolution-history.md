# Harness Evolution & Institutional Knowledge

## Timeline

### Phase 1: Fragmented (pre-2026-03-13)
- 3 skills: `fix-issue`, `add-feature`, `review`
- 13 `workflow-*` commands with loose coordination
- No shared state model, no multi-session context bridge

### Phase 2: Unified v2 (2026-03-13 to 2026-03-14)
- Epic: `rag-7toh` (closed)
- Replaced 13 commands + 3 skills with 10 commands + 2 skills
- 3-factor depth assessment (scope_breadth + uncertainty + session_span)
- Shared JSON state model in `.work/`
- Structured file handoffs between phases

### Phase 3: Mechanical Enforcement (2026-03-14 to 2026-03-15)
- Epic: `rag-rne9`
- **Problem**: Stress testing revealed progressive discipline collapse — agent abandoned step gates, skipped artifacts, faked reviews
- **Solution**: Hooks enforce what prompts cannot
- Key hooks: state-guard.sh, artifact-gate.sh, review-verify.sh
- Added auto-advancement, step output review gates, `reviewed_at` timestamp

### Phase 4: Modularization (2026-03-15 to NOW)
- Epic: `rag-7bfsr` (current)
- Extract general harness into standalone repo

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Hooks enforce, commands orchestrate | Prompt compliance degrades under context pressure |
| Validate post-conditions, not intentions | "Did file get created?" > "Did LLM plan to create it?" |
| Multi-session context via file handoffs | Session is stateless; handoff prompts are the firewall |
| Exit 2 for critical, stderr for warnings | Blocking state corruption; non-blocking for warnings |
| Unified state model across all tiers | Eliminates cognitive overhead, shared review infrastructure |
| Project-level hooks in `.claude/hooks/` | Team consistency over personal preference |

## Lessons Learned

1. **Context compaction is a step boundary** — handoff prompts must capture everything
2. **Step transitions must present before advancing** — discovered via rag-exshk
3. **Explicit compaction instructions needed at gates** — added via rag-g4dv3
4. **`.review/` directory abuse** — PreToolUse hook blocks writes, redirects to `.work/<name>/review/`
5. **Inter-step quality gates catch compounding errors** — Phase A (artifacts) + Phase B (quality)
6. **Parallel streams, not branches** — decompose outputs stream docs, implement spawns agents per stream

## Prior Art & Artifacts
- `.work/harness-enforcement/specs/` — 12-component breakdown
- `docs/workflow-harness-guide.md` — full user guide (10 sections)
- `docs/feature/work-harness-v2.md` — archived v2 spec
- `docs/feature/harness-enforcement.md` — enforcement spec
