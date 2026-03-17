# Handoff: Plan → Spec

## What This Step Produced

Architecture document at `.work/context-lifecycle/specs/architecture.md` defining 5 components across 2 implementation phases, plus feature summary at `docs/feature/context-lifecycle.md`.

### Key Artifacts
- `.work/context-lifecycle/specs/architecture.md` — Full architecture: problem statement, component map, data flow, dependency graph, technology choices, cross-repo design
- `docs/feature/context-lifecycle.md` — Summary with component list and key decisions

## Architecture Summary

### Components

| # | Component | Scope | Phase |
|---|-----------|-------|-------|
| C1 | Project-Level Tech Manifest (`.claude/tech-deps.yml`) | Small | 1 |
| C2 | Self-Re-Invocation at Step Gates (Skill() calls in work commands) | Medium | 1 |
| C3 | PostCompact Hook (shell script + settings.json entry) | Small | 1 |
| C4 | Archive-Time Housekeeping (deprecated diff + staleness scan + beads issues) | Medium | 2 |
| C5 | Gate Approval Re-Confirmation (all state transitions require explicit approval) | Small–Medium | 1 |

### Dependency Graph
- **Phase 1** (parallel): C1, C2, C3, C5 — no inter-dependencies
- **Phase 2** (depends on C1): C4 — archive housekeeping needs tech manifest
- **Critical path**: C1 → C4

### Key Design Decisions
- **Project-level manifest, not skill frontmatter** (Approach B): Skills live in dotfiles (portable across projects). The PROJECT declares its tech dependencies in `.claude/tech-deps.yml`. Teammates get the manifest in the repo. Skills stay project-agnostic.
- **Fail-closed for archive scan**: Scan errors block archive completion — do not silently skip
- **Both Skill() + PostCompact**: Step gates use prompt-driven re-invocation; compaction uses hook-driven re-grounding
- **Scan all documents**: Set is small (~30 files), making selective scanning needless complexity
- **freshness_class and last_reviewed deferred**: Premature — no consumer in current architecture

### Cross-Repo Design
- Skills in `~/src/dotfiles/home/.claude/skills/` → portable, no project-specific frontmatter
- Commands + rules in `<project>/.claude/` → project-specific, shared with team
- Tech manifest in `<project>/.claude/tech-deps.yml` → project declares deps, references skills by name

## Questions Deferred to Spec

1. **Tech manifest identifier format**: How do values map to deprecated table entries? Case normalization?
2. **Self-re-invocation wording**: Exact prompt language for work commands (avoid aggressive "CRITICAL/MUST")
3. **PostCompact hook details**: Error handling, output format, multiple active tasks edge case
4. **Staleness report format**: Structured output format
5. **Skill location resolution**: Glob patterns for finding skill files referenced in the manifest
6. **Cleanup issue sequencing**: Should rag-e690r, rag-odxhb, rag-vzsgp be Phase 0 prerequisites?
7. **Manifest bootstrapping**: How to generate the initial manifest for an existing project

## Instructions for Spec Step

1. Read this handoff — do NOT re-read the architecture document in full (this handoff is the firewall)
2. Write cross-cutting contracts (spec 00) defining shared schemas: tech manifest format, staleness report format, approval signal definitions
3. Write one numbered spec per component (specs 01-05)
4. Resolve the 7 deferred questions above within the specs
5. Establish dependency ordering for specs
6. Track specs in `.work/context-lifecycle/specs/index.md`
