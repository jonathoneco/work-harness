# W4: Skills Pipeline

**Status**: Plan
**Tier**: 3 (Initiative)
**Epic**: work-harness-alc
**Issue**: work-harness-bn1

## What

The work harness has 42 skill+command files but the skill layer hasn't kept pace with W1-W3's workflow machinery. The skills pipeline addresses three gaps: (1) building a research-informed **language pack library** covering anti-patterns, good practices, and idiomatic recommendations per language -- starting with Python, TypeScript, and Rust as baseline entries alongside the existing Go pack; (2) creating new commands for workflow-meta, dev-update, dump, and state-driven PR lifecycle handling; (3) establishing skill lifecycle management with metadata on all 23 existing skills, staleness detection, and an update command.

## Components

| ID | Component | Scope | Phase |
|----|-----------|-------|-------|
| C01 | Language packs (Python, TS, Rust) | Medium | 2 |
| C02 | Framework packs (React, Next.js) | Medium | 2 |
| C03 | Go pack refactoring | Small | 2 |
| C04 | Pack discovery extension | Small | 1 |
| C05 | AMA skill enrichment | Small | 1 |
| C06 | Codex-review skill enrichment | Small | 1 |
| C07 | Context-docs skill enrichment | Small | 1 |
| C08 | `/workflow-meta` command | Medium | 3 |
| C09 | `/dev-update` command+skill | Medium | 3 |
| C10 | `/work-dump` command | Medium | 3 |
| C11 | PR handling: state-driven | Medium | 3 |
| C12 | Agency-agents curation docs | Medium | 4 |
| C13 | Skill metadata + update command | Large | 1 |
| C14 | install.sh updates | Small | 4 |

## Key Decisions

- Language and framework packs written from scratch, curated from authoritative sources with AI-specific focus (DD-1)
- Dev updates output markdown, no external integrations (DD-2)
- `/work-dump` outputs plan, no auto-create beads issues (DD-3)
- Skill metadata added to ALL 23 existing skills now -- no tech debt (DD-4)
- PR handling is state-driven -- infers action from PR state, no explicit flags (DD-5)
- Config injection consolidation deferred -- tracked in futures (DD-6)

## Key Files

- `claude/skills/code-quality/references/python-*.md` (new, format TBD by spec research)
- `claude/skills/code-quality/references/typescript-*.md` (new, format TBD by spec research)
- `claude/skills/code-quality/references/rust-*.md` (new, format TBD by spec research)
- `claude/commands/workflow-meta.md` (new)
- `claude/commands/dev-update.md` (new)
- `claude/commands/work-dump.md` (new)
- `claude/commands/work-skill-update.md` (new)
- `claude/commands/pr-prep.md` (modified -- state-driven refactor)
- `claude/commands/ama.md` (modified)
- `claude/skills/work-harness/codex-review.md` (modified)
- `claude/skills/work-harness/context-docs.md` (modified)
- `claude/skills/workflow-meta.md` (modified)
- `claude/skills/work-harness/agency-curation.md` (new)
- `claude/skills/work-harness/skill-lifecycle.md` (new)
- `claude/skills/work-harness/dev-update.md` (new)
- `install.sh` (modified)
- All 23 existing skill/command files (metadata addition)

## Work Items

1. `workflow-meta` proper workflow -- kick off workflow with pre-seeded context/intention
2. Skill: dev update dump for Richard -- generate status updates from workflow artifacts
3. Skill: proactive skill updating -- metadata on all skills, staleness detection, update command
4. Skill: PR handling -- state-driven PR lifecycle (infer from PR state, not flags)
5. Skills for new tech stack -- research-informed language pack library
6. Flush out harness skills -- fill gaps in existing skill coverage
7. Dump command -- decompose work into well-scoped workflows
8. Skill: deep Notion exploration -- push back against shallow exploration (blocked on OAuth)
9. Language-specific packs -- library of anti-patterns, good practices, idiomatic recommendations
10. Agency-agents deep integration -- curated agent subset per stack in harness.yaml
11. Multi-language project support -- deferred to schema v2 (review_routing workaround suffices)
