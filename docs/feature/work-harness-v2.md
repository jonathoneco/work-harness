# Adaptive Work Harness v2

**Status:** archived
**Tier:** 3
**Dates:** 2026-03-13 — 2026-03-14
**Beads:** rag-7toh

## What

Replaced the fragmented tooling landscape (3 skills + 13 workflow commands) with a unified adaptive-depth work harness. A single system that assesses task complexity via a 3-factor formula, selects the appropriate depth tier (Fix/Feature/Initiative), and executes with scaled phases and review gates. All tasks flow through the same state model, commands, and review infrastructure.

## Why

The previous system had `/fix-issue`, `/add-feature`, `/review` skills and 13 `workflow-*` commands with no shared state model. This created cognitive overhead, inconsistent enforcement, and subagent blindness (skills couldn't propagate context to spawned agents).

## Key Decisions

- **3 depth tiers**: Fix (T1), Feature (T2), Initiative (T3) validated against 18 historical tasks with 83% exact match
- **Commands + skills hybrid**: Commands handle invocation/args; skills handle auto-loading knowledge and subagent propagation
- **LLM-based triage**: 3-factor formula (scope spread + design novelty + decomposability) with mechanical bulk modifier
- **Full rewrite, no shims**: No backward compatibility layers since no active workflows existed during migration

## Components

- **`/work` command**: Auto-triage entry point that assesses and routes to the right tier
- **Tier shortcuts**: `/work-fix`, `/work-feature`, `/work-deep` skip triage for known complexity
- **State model**: Shared JSON schema in `.work/` with dynamic `steps` array across all tiers
- **Review gate**: Scaled per tier -- Stop hook for T1, manual `/work-review` for T2/T3, mandatory pre-archive for T3
- **work-harness skill**: Auto-loads context and propagates to subagents via `skills:` frontmatter

## Specs

Detailed specs at `.workflows/archive/work-harness-v2/specs/`.
