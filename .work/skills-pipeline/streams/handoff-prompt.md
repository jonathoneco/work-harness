# Decompose Handoff: W4 Skills Pipeline

**Task**: skills-pipeline | **Tier**: 3 | **Epic**: work-harness-alc
**Decompose completed**: 2026-03-24

## What This Step Produced

- **16 work items** as beads issues (work-harness-alc.1 through work-harness-alc.15 + work-harness-52s)
- **15 stream execution documents** (A through O)
- **4 phases** with dependency ordering
- **Manifest**: `.work/skills-pipeline/streams/manifest.jsonl`

## Concurrency Map

```
Phase 1 (2 parallel streams):
  ├── Stream A: W-01 metadata tagging [L] ──┐
  └── Stream B: W-12 Go pack refactor [S]   │ (independent, no file overlap)
                                             │
Phase 2 (5 parallel streams, after Phase 1): │
  ├── Stream C: W-02 skill lifecycle [M] ────┤ (needs work-harness.md from A)
  ├── Stream D: W-03 discovery ext [S] ──────┤ (needs code-quality.md from A)
  ├── Stream E: W-04 AMA enrichment [S] ─────┤ (needs ama.md from A)
  ├── Stream F: W-05 codex-review [S] ───────┤ (needs codex-review.md from A)
  └── Stream G: W-06 context-docs [S] ───────┘ (needs context-docs.md from A)
                                             │
Phase 3 (8 parallel streams, after Phase 2): │
  ├── Stream H: W-07 Python pack [M] ────────┤ (needs discovery from D)
  ├── Stream I: W-08 TypeScript pack [M] ────┤ (needs discovery from D)
  ├── Stream J: W-09 Rust pack [M] ──────────┤ (needs discovery from D)
  ├── Stream K: W-10 React pack [M] ─────────┤ (needs discovery from D)
  ├── Stream L: W-11 Next.js pack [M] ───────┤ (needs discovery from D)
  ├── Stream M: W-13 new commands [M] ───────┤ (needs work-harness.md from C)
  └── Stream O: W-16 pr-prep refactor [M] ───┘ (needs pr-prep.md meta from A)
                                             │
Phase 4 (1 stream, after all above):         │
  └── Stream N: W-14 + W-15 integration [M] ─┘
```

### Critical Path

```
W-01 (A) → W-03 (D) → W-07..W-11 (H-L) → W-15 (N)
```

The critical path runs through metadata tagging, discovery extension, content packs, and integration verification. Total of 4 sequential phases.

### File Ownership Verification

No file appears in more than one stream within the same phase:
- Phase 1: Stream A owns 32 skill/command files; Stream B owns `go-anti-patterns.md` (reference file, not in A's scope)
- Phase 2: Each stream owns a distinct file (C: work-harness.md + 2 new; D: code-quality.md; E: ama.md; F: codex-review.md; G: context-docs.md)
- Phase 3: Streams H-L each create one unique new file; Stream M creates 4 new files + modifies work-harness.md (which was last modified in Phase 2 by C); Stream O modifies pr-prep.md (no overlap with M)
- Phase 4: Stream N creates 1 new file + modifies harness-doctor.md, work-harness.md, VERSION, workflow.md

## Stream Summary Table

| Stream | Phase | Scope | Work Items | Key Files |
|--------|-------|-------|------------|-----------|
| A | 1 | L | W-01 | 32 existing skill/command files (meta tagging) |
| B | 1 | S | W-12 | `references/go-anti-patterns.md` |
| C | 2 | M | W-02 | `skill-lifecycle.md` (new), `work-skill-update.md` (new), `work-harness.md` |
| D | 2 | S | W-03 | `code-quality.md` |
| E | 2 | S | W-04 | `ama.md` |
| F | 2 | S | W-05 | `codex-review.md` |
| G | 2 | S | W-06 | `context-docs.md` |
| H | 3 | M | W-07 | `references/python-anti-patterns.md` (new) |
| I | 3 | M | W-08 | `references/typescript-anti-patterns.md` (new) |
| J | 3 | M | W-09 | `references/rust-anti-patterns.md` (new) |
| K | 3 | M | W-10 | `references/react-anti-patterns.md` (new) |
| L | 3 | M | W-11 | `references/nextjs-anti-patterns.md` (new) |
| M | 3 | M | W-13 | `workflow-meta.md` (new), `dev-update.md` cmd+skill (new), `work-dump.md` (new), `work-harness.md` |
| O | 3 | M | W-16 | `pr-prep.md` (state machine rewrite) |
| N | 4 | M | W-14, W-15 | `agency-curation.md` (new), `harness-doctor.md`, `work-harness.md`, `VERSION`, `workflow.md` |

## Instructions for Implement Step

### Execution Order
1. Launch Phase 1 streams (A, B) in parallel
2. Wait for Phase 1 to complete
3. Launch Phase 2 streams (C, D, E, F, G) in parallel
4. Wait for Phase 2 to complete
5. Launch Phase 3 streams (H, I, J, K, L, M, O) in parallel — note M also needs C complete, which is Phase 2
6. Wait for Phase 3 to complete
7. Launch Phase 4 stream (N)

### Per-Stream Agent Setup
Each stream document (`.work/skills-pipeline/streams/<letter>.md`) contains:
- Frontmatter with `file_ownership` list — agent must NOT modify files outside this list
- Beads issue IDs to claim (`bd update <id> --status=in_progress`)
- Spec references for full implementation details
- Acceptance criteria to verify before marking complete

### Agent Prompt Pattern
For each stream, the implement step should:
1. Read the stream document
2. Read referenced specs for full details
3. Claim the beads issues
4. Implement the work items
5. Verify acceptance criteria
6. Close the beads issues with reason

### Conflict Prevention
- Agents must respect `file_ownership` — no file appears in multiple streams per phase
- `work-harness.md` is the only file modified across phases (C in Phase 2, M in Phase 3, N in Phase 4) — sequential access prevents conflicts
- `pr-prep.md` is isolated in Stream O (Phase 3) after metadata tagging by Stream A (Phase 1) — no conflict
- Metadata tagging (Stream A) must complete before any Phase 2 enrichment streams start

### Deferred Items
None added during decompose — all deferred items from the spec step are already in `futures.md`.
