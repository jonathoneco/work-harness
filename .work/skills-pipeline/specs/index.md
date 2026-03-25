# Spec Index: W4 Skills Pipeline

| Spec | Component | Title | Phase | Status | Dependencies |
|------|-----------|-------|-------|--------|--------------|
| 00 | — | Cross-cutting contracts | All | complete | — |
| 01 | C13 | Skill metadata + update command | 1 | complete | Spec 00 |
| 02 | C04 | Pack discovery extension | 1 | complete | Spec 00 |
| 03 | C01 | Language packs (Python, TS, Rust) | 2 | complete | Spec 00, 02 |
| 04 | C02 | Framework packs (React, Next.js) | 2 | complete | Spec 00, 02 |
| 05 | C03 | Go pack refactoring | 2 | complete | Spec 00 |
| 06 | C05 | AMA skill enrichment | 1 | complete | Spec 00 (via C13) |
| 07 | C06 | Codex-review skill enrichment | 1 | complete | Spec 00 (via C13) |
| 08 | C07 | Context-docs skill enrichment | 1 | complete | Spec 00 (via C13) |
| 09 | C08 | `/workflow-meta` command | 3 | complete | Spec 00 |
| 10 | C09 | `/dev-update` command + skill | 3 | complete | Spec 00 |
| 11 | C10 | `/work-dump` command | 3 | complete | Spec 00 |
| 12 | C11 | PR handling: state-driven | 3 | complete | Spec 00 |
| 13 | C12 | Agency-agents curation docs | 4 | complete | Spec 00, 01 |
| 14 | C14 | install.sh updates | 4 | complete | Specs 09-12 |

## File Inventory

### New Files (12)

| File | Source Spec |
|------|------------|
| `claude/skills/code-quality/references/python-anti-patterns.md` | 03 (C01) |
| `claude/skills/code-quality/references/typescript-anti-patterns.md` | 03 (C01) |
| `claude/skills/code-quality/references/rust-anti-patterns.md` | 03 (C01) |
| `claude/skills/code-quality/references/react-anti-patterns.md` | 04 (C02) |
| `claude/skills/code-quality/references/nextjs-anti-patterns.md` | 04 (C02) |
| `claude/commands/workflow-meta.md` | 09 (C08) |
| `claude/commands/dev-update.md` | 10 (C09) |
| `claude/skills/work-harness/dev-update.md` | 10 (C09) |
| `claude/commands/work-dump.md` | 11 (C10) |
| `claude/commands/work-skill-update.md` | 01 (C13) |
| `claude/skills/work-harness/skill-lifecycle.md` | 01 (C13) |
| `claude/skills/work-harness/agency-curation.md` | 13 (C12) |

### Modified Files (36)

| File | Source Spec | Change |
|------|------------|--------|
| 32 skill/command files | 01 (C13) | Add `meta` frontmatter block |
| `claude/skills/code-quality.md` | 02 (C04) | Add framework/frontend discovery directives |
| `claude/skills/code-quality/references/go-anti-patterns.md` | 05 (C03) | Reformat to standard entry format |
| `claude/commands/ama.md` | 06 (C05) | Add answer strategies, depth calibration |
| `claude/skills/work-harness/codex-review.md` | 07 (C06) | Add diff prep, multi-file handling |
| `claude/skills/work-harness/context-docs.md` | 08 (C07) | Add examples, edge cases |
| `claude/commands/pr-prep.md` | 12 (C11) | Replace Steps 8-9 with state machine |
| `claude/commands/harness-doctor.md` | 13 (C12) | Add Check 8 (agency-agents) |
| `claude/skills/work-harness.md` | 01, 10, 13 | Add references (skill-lifecycle, dev-update, agency-curation) |
| `VERSION` | 14 (C14) | Minor version bump |
| `claude/rules/workflow.md` | 14 (C14) | Add 4 new commands to table |
