# Specs Index — Harness Improvements

| Spec | Title | Component | Phase | Status | Dependencies |
|------|-------|-----------|-------|--------|-------------|
| 00 | Cross-cutting contracts | — | — | complete | — |
| 01 | Stream Docs Enhancement | C1 | 1 | complete | 00 |
| 02 | Code Quality Enhancement | C2 | 1 | complete | 00 |
| 03 | Context Doc System | C3 | 1 | complete | 00 |
| 04 | Gate Protocol | C4 | 1 | complete | 00 |
| 05 | Research Protocol | C5 | 1 | complete | 00 |
| 06 | Auto-Reground | C6 | 1 | complete | 00 |
| 07 | Skill Library | C7 | 2 | complete | 00 |
| 08 | Dynamic Delegation | C8 | 3 | complete | 07 |
| 09 | Parallel Execution v2 | C9 | 3 | complete | 01, 07, 08 |
| 10 | Codex Integration | C10 | 4 | complete | 02 |
| 11 | Memory Integration | C11 | 4 | complete | 00, optionally 06 |

## Deferred Questions Resolved

| # | Question | Resolution | Spec |
|---|----------|-----------|------|
| DQ-1 | C3 auto-detection heuristics | Concrete mapping table: 18 mappings across language/framework/database/frontend | 03 |
| DQ-2 | C7 skill extraction granularity | Keep `step-transition` as ONE skill — ceremony, gate, state update always used together | 07 |
| DQ-3 | C8 skills field verification | Verify during implementation; dual paths (frontmatter vs prompt injection) | 08 |
| DQ-4 | C10 output schema | JSONL matching findings.jsonl: severity/category/file/line/message/suggestion | 10 |
| DQ-5 | C11 entity schema | 4 entity types (WorkSession, Decision, Blocker, Accomplishment), 5 relation types | 11 |
| DQ-6 | C7 hook utilities scope | Integrated into `hooks/lib/common.sh` following `lib/config.sh` pattern | 07 |

## Advisory Notes Addressed

| Note | Spec | How Addressed |
|------|------|--------------|
| A1 | 08 | Step 1 is a blocking gate — verify skills: field before C8 implementation |
| A2 | 03 | 18-entry auto-detection mapping table with concrete examples |
| A3 | 04 | Full invocation point diagram in Gate Protocol spec |
| A4 | 10, 11 | C10 starts after C2; C11 starts independently |
| A5 | 07 | Integrated into hooks/lib/common.sh (not separate deliverable) |
| B1 | 07 | Explicit sourcing pattern following lib/config.sh; boilerplate enumeration |
| B2 | 06 | All jq calls use 2>/dev/null; corrupt state = graceful skip; always exit 0 |
| B3 | 06, 11 | C6 ships without memory awareness; enrichment documented as future in C11 |
