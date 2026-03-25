# Plan Handoff: W4 Skills Pipeline

**Task**: skills-pipeline | **Tier**: 3 | **Epic**: work-harness-alc
**Plan completed**: 2026-03-24 (revised v3)

## What This Step Produced

- **Architecture document**: `.work/skills-pipeline/specs/architecture.md`
- **Design decisions**: 6
- **Components**: 14 (3 content pack groups, 1 discovery extension, 3 skill enrichments, 4 new commands, 1 curation, 1 metadata+lifecycle, 1 install.sh)
- **Phases**: 4
- **Supplementary research**: `.work/skills-pipeline/research/05-language-pack-formats.md`

## Architecture Summary

The skills pipeline fills the skill layer of the work harness with from-scratch language packs (Python, TypeScript, Rust) and framework packs (React, Next.js, etc.), active commands for workflow-meta/dev-update/dump/PR lifecycle, enrichment of thin existing skills, agency-agents curation, and a proactive skill updating system with metadata on ALL existing skills plus staleness detection. Pack content is written from scratch, curated from authoritative sources with AI-specific focus (what LLMs get wrong).

### Key Decisions

1. **From-scratch packs, not vendored** -- External rule libraries (awesome-rules, claude-rules) evaluated and rejected: too young, not AI-specific. Our research identified 15+ high-impact patterns per language from authoritative sources. We write curated, AI-focused packs.
2. **Framework packs alongside language packs** -- `stack.framework` and `stack.frontend` already exist in harness.yaml. Discovery extended in `code-quality.md` with the same file-presence pattern.
3. **Skill metadata on all 23 existing skills now** -- no deferred tech debt.
4. **PR handling is state-driven** -- infers actions from PR state, no explicit flags.
5. **Standard entry format** -- severity + category + BAD/GOOD code pairs + rationale (informed by Clippy + community research).

### Components Table

| ID | Component | Scope | Phase | Spec | Dependencies | Key Files |
|----|-----------|-------|-------|------|--------------|-----------|
| C01 | Language packs (Python, TS, Rust) | Medium | 2 | C01 | None | `references/{python,typescript,rust}-*.md` |
| C02 | Framework packs (React, Next.js) | Medium | 2 | C02 | None | `references/{react,nextjs}-*.md` |
| C03 | Go pack refactoring | Small | 2 | C03 | None | `references/go-anti-patterns.md` |
| C04 | Pack discovery extension | Small | 1 | C04 | None | `claude/skills/code-quality.md` |
| C05 | AMA skill enrichment | Small | 1 | C05 | None | `claude/commands/ama.md` |
| C06 | Codex-review skill enrichment | Small | 1 | C06 | None | `claude/skills/work-harness/codex-review.md` |
| C07 | Context-docs skill enrichment | Small | 1 | C07 | None | `claude/skills/work-harness/context-docs.md` |
| C08 | `/workflow-meta` command | Medium | 3 | C08 | None | `claude/commands/workflow-meta.md` |
| C09 | `/dev-update` command+skill | Medium | 3 | C09 | None | `claude/commands/dev-update.md` |
| C10 | `/work-dump` command | Medium | 3 | C10 | None | `claude/commands/work-dump.md` |
| C11 | PR handling: state-driven | Medium | 3 | C11 | None | `claude/commands/pr-prep.md` |
| C12 | Agency-agents curation docs | Medium | 4 | C12 | None | `claude/skills/work-harness/agency-curation.md` |
| C13 | Skill metadata + update command | Large | 1 | C13 | None | All 23 existing skill/command files |
| C14 | install.sh updates | Small | 4 | C14 | C08-C10, C13 | `install.sh` |

## Design Decisions Summary

1. **DD-1**: Language and framework packs written from scratch, curated from authoritative sources with AI-specific focus
2. **DD-2**: Dev updates output markdown files, no external integrations -- artifacts not side effects
3. **DD-3**: `/work-dump` outputs a plan, does not auto-create beads issues -- advisory not autonomous
4. **DD-4**: Skill metadata added to ALL 23 existing skills now -- no tech debt, subagent-friendly
5. **DD-5**: PR handling is state-driven -- infer action from PR existence, labels, description, CI status, changes
6. **DD-6**: Config injection consolidation deferred -- tracked in futures.md

## Items Deferred to Spec

1. Language pack content per language: which anti-patterns, practices, idioms to include (Spec C01)
2. Framework pack content: which frameworks, what anti-patterns per framework (Spec C02)
3. Go pack refactoring scope (Spec C03)
4. Discovery directive specifics: glob patterns for framework/frontend (Spec C04)
5. AMA enrichment specifics (Spec C05)
6. Context-docs enrichment specifics (Spec C07)
7. `/workflow-meta` pre-seeded context format and sync validation (Spec C08)
8. `/dev-update` artifact reading strategy and prioritization (Spec C09)
9. `/work-dump` decomposition heuristics and domain boundary detection (Spec C10)
10. PR state detection reliability and edge cases (Spec C11)
11. Agency-agents curation per stack recommendations (Spec C12)
12. Skill metadata schema finalization (Spec C13)
13. Cross-cutting contracts: entry format standard, frontmatter schema, config injection, install.sh registration (Spec 00)

## Inline Research Performed

1. **Gap**: Research handoff did not investigate external rule libraries or per-language community sources
   **Finding**: External libraries (awesome-rules, claude-rules) evaluated but rejected — too young, not AI-specific. Per-language research identified authoritative sources: PEP 8/Ruff/Little Book (Python), typescript-eslint/Effective TS (TypeScript), Clippy/rust-unofficial-patterns (Rust). All permissively licensed.
   **Impact**: Confirmed from-scratch approach with research-informed content. Added research note `05-language-pack-formats.md`.

## Instructions for Spec Step

Write specs in this order:

1. **Spec 00 (cross-cutting contracts)** first -- defines the entry format standard (severity + category + BAD/GOOD pairs), frontmatter schema (including `meta` block), config injection pattern, and install.sh registration protocol. All other specs reference these contracts.
2. **Spec C13 (skill metadata)** -- defines the metadata schema, retroactive tagging plan for all 23 skills, staleness detection rules, and `/work-skill-update` command. References Spec 00 for frontmatter conventions.
3. **Spec C04 (discovery extension)** -- specifies the new directives in `code-quality.md` for `stack.framework` and `stack.frontend` discovery. Small but foundational for C01-C02.
4. **Specs C01-C03 (packs)** -- can be combined into one spec or split. C01: language packs per language (Python, TS, Rust). C02: framework packs (React, Next.js). C03: Go pack refactoring. See `05-language-pack-formats.md` for source material and recommended anti-patterns per language.
5. **Specs C05-C07 (skill enrichment)** -- one spec per skill. Read the current file, specify what to add.
6. **Specs C08-C11 (new commands)** -- one spec per command. Follow existing command patterns (`pr-prep.md` as reference). C11 must specify the state machine for state-driven PR handling.
7. **Spec C12 (agency-agents curation)** -- curation docs per stack plus harness-doctor validation rules.
8. **Spec C14 (install.sh updates)** -- last, since it registers everything from Phases 1-4.

Each spec should reference Spec 00 for cross-cutting contracts rather than re-defining shared patterns.

**Important for C01-C02**: Research is complete (see `05-language-pack-formats.md`). The spec agent should reference that note for per-language source material, top anti-patterns, and the entry format standard. Packs are from scratch but informed by authoritative sources — not ad-hoc. **Note**: The research note's "Recommended Approach" section advocates vendoring — this was subsequently evaluated and rejected (DD-1). Follow DD-1 (from-scratch), not the research note's conclusion.

**Important for C08**: The skill `claude/skills/workflow-meta.md` already exists (83 lines). The spec for the new `/workflow-meta` *command* must define how it relates to the existing skill: does the command load it via `skills:` frontmatter? Augment it? Replace it?

**Advisory**: The "23 existing skills" count (DD-4/C13) should be verified during spec — the exact count may differ. The spec for C13 should enumerate the files to tag.
