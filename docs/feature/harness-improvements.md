# Harness Improvements — Research & Triage

**Tier**: 3 (Initiative)
**Status**: archived
**Epic**: work-harness-65t

## What

Systematic improvement of the work-harness across 11 components: reducing ~700 lines of duplication through modular shared skills, enabling smarter agent delegation with step-level routing, auto-maintaining project docs via manifest, enhancing parallel work decomposition with hybrid execution strategies, integrating Codex for optional review delegation, and improving developer experience with file-based review, auto-reground, and cross-session memory.

## Components

| # | Component | Phase | Scope | Description |
|---|-----------|-------|-------|-------------|
| C1 | Stream Docs Enhancement | 1 | M | Enhanced stream doc format with isolation mode, agent type, skills, file ownership |
| C2 | Code Quality Enhancement | 1 | M | Security anti-patterns, AI config linting refs, parallel review pattern |
| C3 | Context Doc System | 1 | L | Manifest-driven auto-maintenance and agent context injection of project docs |
| C4 | Gate Protocol | 1 | M | File-based review UX with gate files, SOP, rollback convention |
| C5 | Research Protocol | 1 | S | Research agents self-write notes; lead synthesizes handoff only |
| C6 | Auto-Reground | 1 | S | Post-compact handoff injection (compact-only, no resume/startup) |
| C7 | Skill Library | 2 | L | Extracted shared skills: task-discovery, step-transition, phase-review + hooks DRY |
| C8 | Dynamic Delegation | 3 | M | Step-level agent/skill routing; phase guidance as on-demand skills |
| C9 | Parallel Execution v2 | 3 | M | Operational integration of modular skills with parallel decomposition |
| C10 | Codex Integration | 4 | M | Optional headless Codex review with graceful degradation |
| C11 | Memory Integration | 4 | L | work-log MCP KG server for cross-project journal and /handoff command |

## Implementation Phases

- **Phase 1** (independent, parallel): C1-C6 — no prerequisites, all can run concurrently
- **Phase 2** (foundation): C7 — skill extraction enables Phase 3
- **Phase 3** (integration): C8 → C9 — delegation then parallel execution
- **Phase 4** (extensions): C10, C11 — can run in parallel after Phase 1

## Key Decisions (from Spec)

- **DQ-1**: Auto-detection uses 18 stack-to-doctype mappings across language/framework/database/frontend config fields
- **DQ-2**: `step-transition` stays as ONE skill — approval ceremony, gate creation, and state update always co-occur
- **DQ-3**: `skills:` frontmatter support must be verified during C8 implementation; dual paths designed (frontmatter vs prompt injection)
- **DQ-4**: Codex findings use JSONL matching existing `findings.jsonl` schema for clean merge
- **DQ-5**: Work-log KG uses 4 entity types (WorkSession, Decision, Blocker, Accomplishment) and 5 relation types
- **DQ-6**: Hook utilities integrated into `hooks/lib/common.sh` following existing `lib/config.sh` sourcing pattern
- **C8 blocking gate**: `skills:` field verification is a prerequisite for Phase 3 implementation
- **C6 isolation**: Ships without memory awareness; C11 owns future enrichment path
- **C10 timing**: Can start as soon as C2 completes, not after all of Phase 1

## Completed

**Archived:** 2026-03-18 | **Findings:** 5 (all fixed) | **Sessions:** 4

Delivered 11 components across 4 phases: 20 new files created (6 skills, 8 references, 1 command, 1 rule, 1 hook library, 3 templates/docs), 28 files modified (9 commands, 8 hooks, 4 skills/refs, install.sh, lib/config.sh, templates). All review findings addressed — schema duality resolved, install.sh hardened, docs corrected.
