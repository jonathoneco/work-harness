# Archive Summary: harness-improvements

**Tier:** 3
**Duration:** 2026-03-17 → 2026-03-18
**Sessions:** 4 (research, plan+spec, decompose, implement+review)
**Beads epic:** work-harness-65t

## What Was Built

Systematic improvement of the work-harness across 11 components in 4 phases:

- **Phase 1** (4 streams): Stream doc YAML frontmatter with 7-field schema, context doc system with auto-detection, research protocol with agent-writes-directly pattern, code quality references (security antipatterns, AI config linting, parallel review), gate protocol SOP, auto-reground 3-tier handoff resolution
- **Phase 2** (2 streams): Hook utilities library (`hooks/lib/common.sh` with 8 functions, all 8 hooks migrated), 3 extracted skills (task-discovery, step-transition, phase-review), 9 commands refactored to reference skills, gate protocol integrated into work-deep auto-advance blocks
- **Phase 3** (1 stream): Dynamic delegation routing with step routing tables and Path B prompt-based skill injection, parallel execution v2 with file ownership validation and review agent precedence
- **Phase 4** (2 streams): Optional Codex review integration with hallucination pattern detection, memory integration with /handoff command, work-log KG entity schema, and routing rule

## Key Files

### Created (20 files)
- `hooks/lib/common.sh` — shared hook utilities
- `claude/skills/work-harness/task-discovery.md` — active task finding algorithm
- `claude/skills/work-harness/step-transition.md` — approval ceremony + gate creation
- `claude/skills/work-harness/phase-review.md` — two-phase review framework
- `claude/skills/work-harness/context-docs.md` — manifest-driven doc system
- `claude/skills/work-harness/codex-review.md` — optional Codex integration
- `claude/skills/work-harness/references/gate-protocol.md` — gate file SOP
- `claude/skills/work-harness/references/work-log-setup.md` — MCP server setup
- `claude/skills/work-harness/references/work-log-entities.md` — KG entity schema
- `claude/skills/code-quality/references/security-antipatterns.md` — 22 entries
- `claude/skills/code-quality/references/ai-config-linting.md` — 20 entries
- `claude/skills/code-quality/references/parallel-review.md` — 9-dimension review
- `claude/commands/handoff.md` — daily progress capture
- `claude/rules/memory-routing.md` — work-log vs personal-agent routing

### Modified (28 files)
- 9 command files (skill references, routing tables, gate integration)
- 8 hook files (migrated to source common.sh)
- 4 skill/reference files (updated references, schema fixes)
- `install.sh` (improved error handling)
- `lib/config.sh` (docs.managed validation)
- `templates/harness.yaml.template` (docs.managed section)

## Findings Summary
- 5 total findings (5 fixed, 0 deferred)
- 2 important: schema cross-reference inconsistency + step_status deprecation (both fixed)
- 3 suggestions: install.sh improvements + doc count fix (all fixed)

## Futures Promoted
- Plugin conversion, agent teams integration, agnix CI, Storybook MCP
- Temporal knowledge graph, traffic-based API docs, DocAgent pattern
- Hybrid memory, multi-model review consensus, automated CLAUDE.md drift detection
