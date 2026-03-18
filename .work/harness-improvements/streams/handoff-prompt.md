# Handoff Prompt: Decompose -> Implement

## What Decompose Produced

12 work items across 9 streams in 4 phases, all tracked in beads with dependency ordering.

### Concurrency Map

```
Phase 1 (4 parallel streams, 57 ACs):
  Stream A ──┬── C1 + C3 + C5 (work-deep.md + context docs + research protocol)
  Stream B ──┤── C2 (code quality references)
  Stream C ──┤── C4 (gate protocol SOP)
  Stream D ──┘── C6 (auto-reground)
                    │
Phase 2 (2 parallel streams, 22 ACs):
  Stream E ──┬── C7 hooks (hooks/lib/common.sh + migrate 8 hooks)
  Stream F ──┘── C7 skills (3 skills + 9 command refs + parent skill)
                    │
Phase 3 (1 stream, sequential, 20 ACs):
  Stream G ────── C8 → C9 (delegation routing → parallel execution v2)
                    │
Phase 4 (2 parallel streams, 17 ACs):
  Stream H ──┬── C10 (codex review integration)
  Stream I ──┘── C11 (memory integration)
```

### Work Item → Stream Mapping

| W-Item | Beads ID | Stream | Phase | Spec | Title |
|--------|----------|--------|-------|------|-------|
| W-01 | work-harness-uzd | A | 1 | 01 | Stream doc YAML frontmatter |
| W-02 | work-harness-e2h | A | 1 | 03 | Context doc system |
| W-03 | work-harness-fp6 | A | 1 | 05 | Research protocol |
| W-04 | work-harness-xu1 | B | 1 | 02 | Code quality references |
| W-05 | work-harness-i41 | C | 1 | 04 | Gate protocol SOP |
| W-06 | work-harness-63k | D | 1 | 06 | Auto-reground enhancement |
| W-07 | work-harness-ba9 | E | 2 | 07 | Hook utilities library |
| W-08 | work-harness-a4i | F | 2 | 07 | Extracted skills + command refs |
| W-09 | work-harness-ent | G | 3 | 08 | Dynamic delegation routing |
| W-10 | work-harness-eec | G | 3 | 09 | Parallel execution v2 |
| W-11 | work-harness-xv5 | H | 4 | 10 | Codex review integration |
| W-12 | work-harness-0nd | I | 4 | 11 | Memory integration |

### Critical Path

```
W-01/02/03 (Phase 1) → W-08 (Phase 2) → W-09 → W-10 (Phase 3)
W-06 (Phase 1) → W-07 (Phase 2) → W-09 (Phase 3)
```

Longest path: 4 phases, ~4 implementation sessions minimum.

### Key Design Decisions Made During Decompose

1. **C1+C3+C5 merged into Stream A** — all three modify `claude/commands/work-deep.md`, so file ownership constraint requires one stream. Sequential execution within the stream: W-01 → W-02 → W-03.
2. **C7 split into two streams** (E: hooks, F: skills) — hooks/lib/common.sh + hook migration is independent from skill extraction + command refactoring. Different file sets, no conflicts within Phase 2.
3. **C8+C9 sequential in one stream** — C9 hard-depends on C8, both modify work-deep.md. Stream G executes W-09 then W-10.
4. **Phase 4 truly parallel** — C10 depends only on C2 (done in Phase 1), C11 has no hard dependencies. Both could theoretically start earlier, but kept in Phase 4 for organizational clarity.
5. **Stream C→F AC delegation** — Stream C (spec 04, Gate Protocol) creates the SOP reference but cannot modify work-deep.md or work-harness.md (owned by Stream F in Phase 2). Seven ACs from spec 04 (AC-04-07, AC-09-11) are delegated to Stream F, which integrates gate file operations during command refactoring.

### Dependency Graph (beads)

```
W-01 ─────────┐
W-02 ─────────┼──→ W-08 ──┐
W-03 ─────────┘           │
                           ├──→ W-09 ──→ W-10
W-06 ──→ W-07 ────────────┘

W-04 ──→ W-11

W-05 (no downstream deps)
W-12 (no dependencies)
```

### File Ownership by Phase

**Phase 1:**
- Stream A: `work-deep.md`, `context-docs.md`, `work-implement.md`, `harness.yaml.template`
- Stream B: `security-antipatterns.md`, `ai-config-linting.md`, `parallel-review.md`, `code-quality.md`
- Stream C: `gate-protocol.md`, `state-conventions.md`
- Stream D: `post-compact.sh`

**Phase 2:**
- Stream E: `hooks/lib/common.sh`, all 8 `hooks/*.sh`
- Stream F: `task-discovery.md`, `step-transition.md`, `phase-review.md`, `work-harness.md`, 9 command files

**Phase 3:**
- Stream G: `work-deep.md`, `work-feature.md`, `work-fix.md`

**Phase 4:**
- Stream H: `codex-review.md`, `code-quality.md`, `work-review.md`
- Stream I: `handoff.md`, `memory-routing.md`, `work-log-entities.md`, `work-log-setup.md`, `workflow-detect.md`

No file appears in two streams within the same phase.

### Stream Execution Docs

Self-contained agent prompts at `.work/harness-improvements/streams/<letter>.md`:
- `a.md` — Stream A (C1+C3+C5, Phase 1, 24 ACs)
- `b.md` — Stream B (C2, Phase 1, 12 ACs)
- `c.md` — Stream C (C4, Phase 1, 11 ACs)
- `d.md` — Stream D (C6, Phase 1, 10 ACs)
- `e.md` — Stream E (C7 hooks, Phase 2, 6 ACs)
- `f.md` — Stream F (C7 skills, Phase 2, 16 ACs)
- `g.md` — Stream G (C8→C9, Phase 3, 20 ACs)
- `h.md` — Stream H (C10, Phase 4, 7 ACs)
- `i.md` — Stream I (C11, Phase 4, 10 ACs)

### Manifest

`.work/harness-improvements/streams/manifest.jsonl` — maps all 12 work items to beads IDs, streams, phases, components, and specs.

## Instructions for Implement Step

1. Read this handoff prompt as primary input
2. For each phase, spawn one agent per stream with its stream execution doc
3. Each agent claims its work items (`bd update <id> --status=in_progress`) and closes them when done (`bd close <id>`)
4. Phase gating: after each phase completes, run Phase A + Phase B quality review before starting the next phase
5. Stream A (Phase 1) is the largest single-session stream (24 ACs) — consider splitting into sub-sessions if the agent context is at risk
6. C8 Step 1 (Stream G, W-09) has a BLOCKING GATE: verify `skills:` frontmatter support before proceeding
7. File ownership is validated per phase — no file may be modified by agents in different streams within the same phase
8. Multi-session implementation is expected — use `/work-checkpoint` at session boundaries
