# Prior Art from Closed Issues

## Harness-Improvements (archived 2026-03-18)

Delivered 11 components across 4 phases. Key foundations for W2:

- **C1**: Stream Docs Enhancement — isolation mode, agent type, skills, file ownership fields
- **C5**: Research Protocol — agents self-write notes; lead synthesizes handoff only
- **C8**: Dynamic Delegation — step-level agent/skill routing with phase guidance
- **C9**: Parallel Execution v2 — operational integration with parallel decomposition

## Key Decisions Already Made

1. **Skills field uses Path B** (prompt injection, not YAML frontmatter) — verified during C8 implementation
2. **Routing tables as single source of truth** for skill propagation
3. **Handoff prompts are the firewall** — next step reads only the handoff, not raw artifacts
4. **File-based review UX** — user prefers gate files over terminal scrolling
5. **Context compaction at step boundaries** — step-transition enforces this
6. **Auto-reground on compact only** — user wants choice on startup

## Established Patterns to Build On

- Agent delegation router (harness.yaml > stream doc > work-review defaults)
- Stream doc format (7 YAML frontmatter fields)
- Managed docs system (context-docs.md) for agent context injection
- Gate protocol (file-based, structured sections)

## Deprecated Patterns (Do NOT Follow)

- Worktrees for parallel work → being replaced by agent delegation
- Skills field in YAML frontmatter → not supported, use prompt injection
- Inline skill code in stream docs → use slug references only
