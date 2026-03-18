# Gate: Plan -> Spec

## What Plan Produced

- **Architecture document**: `.work/harness-improvements/specs/architecture.md`
  - 11 components across 4 implementation phases
  - Resolved priority vs dependency conflict for Parallel Decomposition
  - Clear component boundaries, interfaces, and data flows
- **Updated feature summary**: `docs/feature/harness-improvements.md`
  - Full component table with phase, scope, description
- **Handoff prompt**: `.work/harness-improvements/plan/handoff-prompt.md`
  - Spec ordering with dependencies, deferred questions, instructions

### Components (11)

| Phase | Components |
|-------|-----------|
| 1 (independent) | C1: Stream Docs, C2: Code Quality, C3: Context Docs, C4: Gate Protocol, C5: Research Protocol, C6: Auto-Reground |
| 2 (foundation) | C7: Skill Library |
| 3 (integration) | C8: Dynamic Delegation, C9: Parallel Execution v2 |
| 4 (extensions) | C10: Codex Integration, C11: Memory Integration |

### Key Design Decision

Parallel Decomposition (priority #1) depends on Command Modularization (#5) and Dynamic Delegation (#4). Split into:
- Phase 1 (C1): stream doc format and strategy improvements (immediate value)
- Phase 3 (C9): operational integration after modular skills exist

## Review Results

### Phase A — Artifact Validation: PASS

All 8 checklist items passed:
- All 10 research goals mapped to architecture components
- No overlapping responsibilities between components
- Technology choices justified per component
- Dependency ordering correct (Phase 1 -> 2 -> 3, Phase 4 after Phase 1)
- Scope exclusions explicit and comprehensive
- Handoff prompt complete with spec ordering and deferred questions
- Feature summary updated with component table

### Phase B — Quality Review: ADVISORY

| Criterion | Verdict |
|-----------|---------|
| Technology choices | PASS — stays within shell/markdown/YAML/JSONL |
| Component layering | PASS — no circular dependencies |
| Constructor injection | ADVISORY |
| Fail-closed behavior | ADVISORY |
| Over-engineering check | ADVISORY |
| Priority vs dependency | PASS |

## Advisory Notes (carry forward to spec step)

### From Phase A

**A1**: C8 `skills:` field verification should be tracked as a blocking gate for Phase 3 implementation.

**A2**: C3 auto-detection spec should include concrete examples (e.g., `framework: nextjs` -> suggest `components` and `endpoints` docs).

**A3**: Data flow diagram could explicitly show where Gate Protocol (C4) is invoked in the command execution flow.

**A4**: Phase 4 timing could be more precise: "Phase 4 can start as soon as C2 completes" rather than "after Phase 1 completes."

**A5**: Consider adding deferred question: "C7 skill extraction — should hook utilities be a separate deliverable or integrated into existing hooks/lib/common.sh?"

### From Phase B

**B1 (Constructor injection)**: C7 spec should explicitly state that `hooks/lib/common.sh` follows the existing `lib/config.sh` sourcing pattern. Spec should enumerate which boilerplate portions move into the shared library vs. remain per-hook.

**B2 (Fail-closed)**: C6 spec should document behavior when `state.json` is unparseable. Likely: output warning and proceed without context injection (don't block compaction for corrupt state).

**B3 (Over-engineering)**: C11/C6 enrichment should be explicitly framed as a future enhancement to C6, not something C6 designs for now. C6 ships without memory awareness.

### Informational (no action needed)

- No `.claude/rules/architecture-decisions.md` exists — quality review checklist references to it are vacuous for this project
- Architecture uses `skills/...` paths; actual codebase uses `claude/skills/...` prefix — intent is clear from context

## Deferred Questions for Spec

1. C3 auto-detection heuristics — which stack config fields map to which doc types?
2. C7 skill extraction granularity — one `step-transition` skill or split?
3. C8 skills field verification — does agent YAML frontmatter support `skills:` natively?
4. C10 output schema — structured format for Codex findings
5. C11 entity schema — entities/relations/observations for work-log KG
6. C7 hook utilities — separate deliverable or integrate into common.sh? (from A5)

## Next Step: Spec

The spec step will:
1. Write cross-cutting contracts (spec 00) — shared schemas, naming, path conventions
2. Write 11 numbered specs (01-11), one per component
3. Phase 1 specs (01-06) can be written in parallel
4. Each spec: overview, implementation steps with acceptance criteria, interface contracts, files, testing strategy
5. Address deferred questions within relevant specs
6. Carry forward advisory notes as spec requirements

## Your Response

<!-- Review the above and respond here:
     - "approved" to advance to spec
     - Questions or feedback (will trigger discussion)
-->
