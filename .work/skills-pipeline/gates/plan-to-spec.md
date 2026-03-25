# Gate: Plan → Spec (W4 Skills Pipeline)

## Summary

Plan step produced an architecture document with 6 design decisions and 14 components across 4 phases. Key evolution during planning: language packs expanded from "3 anti-pattern files" to a from-scratch library of anti-patterns + good practices + idiomatic recommendations (informed by per-language research into PEP 8, Clippy, typescript-eslint, etc.). Framework packs (React, Next.js) added. External vendor libraries evaluated and rejected (too young, not AI-specific). Skill metadata expanded to cover all 23 existing skills immediately. PR handling redesigned from flag-driven to state-driven. Supplementary research note (`05-language-pack-formats.md`) produced during inline research.

## Review Results

### Phase A -- Artifact Validation
**Verdict**: PASS

- [PASS] Goal coverage — all 11 research items addressed (8 implemented, 3 excluded with rationale: Notion blocked on OAuth, multi-language deferred, config consolidation deferred)
- [PASS] Component boundaries — 14 components with non-overlapping file ownership, no conflicts
- [PASS] Technology choices justified — 6 design decisions with rationale and mechanism sections; from-scratch vs. vendor decision documented with research backing
- [PASS] Dependency order correct — Phase 1 foundational (metadata + discovery), Phase 2 content (packs), Phase 3 commands, Phase 4 integration; parallel execution within phases confirmed
- [PASS] Scope exclusions explicit — 5 exclusions documented with rationale, all tracked in futures.md
- [PASS] Handoff accurately summarizes — component IDs, phases, scopes, design decisions all consistent between architecture.md and handoff-prompt.md
- [PASS] Feature summary matches — docs/feature/skills-pipeline.md component table matches architecture

### Phase B -- Quality Review
**Verdict**: PASS

- [SKIP] Architecture decisions alignment — `.claude/rules/architecture-decisions.md` does not exist
- [PASS] Component layering — new commands follow established YAML frontmatter + step-based patterns; new skills follow existing patterns; discovery extension replicates existing file-presence mechanism
- [PASS] Design patterns appropriate — markdown/skill project uses declarative frontmatter metadata (not constructor injection); appropriate for the domain
- [PASS] Failure modes — missing packs result in graceful skip (existing pattern); PR state detection edge cases explicitly deferred to spec
- [PASS] Not over-engineered — 14 components justified by genuine independence; most are Small scope; no unnecessary abstraction layers
- [PASS] Handoff instructions clear — spec ordering, dependencies, and research pointers all explicit; spec agent can produce specs from handoff + architecture alone

## Advisory Notes

1. **Research note contradicts DD-1**: The `05-language-pack-formats.md` "Recommended Approach" section advocates vendoring, but DD-1 rejects this. Handoff updated to warn spec agent to follow DD-1, not the research note's conclusion.

2. **Existing workflow-meta skill**: `claude/skills/workflow-meta.md` already exists (83 lines). The spec for C08 (new `/workflow-meta` command) must define how the command relates to the existing skill. Handoff updated with this note.

3. **Skill count verification needed**: "23 existing skills" should be verified during spec — actual count may differ slightly. Spec for C13 should enumerate files.

4. **No harness.yaml in this repo**: Discovery extension (C04) should document graceful skip behavior for absent `stack.framework`/`stack.frontend` fields, matching existing `stack.language` behavior.

## Deferred Items

- Multi-language schema v2 (futures.md — next horizon)
- Notion deep exploration (futures.md — blocked on OAuth)
- Config injection consolidation (futures.md — quarter horizon)
- Automated skill testing framework (futures.md — someday)
- External pack vendoring (futures.md — next horizon, revisit if libraries mature)

## Next Step

Spec step writes detailed implementation specifications for each of the 14 components. Spec 00 (cross-cutting contracts) is written first to define the entry format standard, frontmatter schema, and shared patterns. Then component specs follow the dependency order in the handoff. The spec agent reads the plan handoff prompt and architecture document as primary inputs.

## Your Response
<!-- Review the above and respond here:
     - "approved" to advance
     - Questions or feedback (will trigger discussion)
-->
