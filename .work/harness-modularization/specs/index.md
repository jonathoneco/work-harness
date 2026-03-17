# Spec Index — harness-modularization

| Spec | Title | Component | Phase | Status | Dependencies |
|------|-------|-----------|-------|--------|-------------|
| 00 | Cross-cutting contracts | — | — | complete | — |
| 01 | Repo scaffold | C1 | 1 | complete | 00 |
| 02 | Config reader | C10 | 1 | complete | 00, 01 |
| 03 | Settings merger | C8 | 1 | complete | 00, 01 |
| 04 | Commands | C2 | 2 | complete | 00, 01 |
| 05 | Skills | C3 | 2 | complete | 00, 01 |
| 06 | Agents | C4 | 2 | complete | 00, 01 |
| 07 | Rules | C5 | 2 | complete | 00, 01 |
| 08 | Hooks | C6 | 2 | complete | 00, 01, 02 |
| 09 | Schema migrator | C9 | 2 | complete | 00, 01, 02 |
| 10 | Install script | C7 | 3 | complete | 00, 01, 02, 03, 08, 09 |
| 11 | harness-init | C11 | 4 | complete | 00, 01, 02 |
| 12 | harness-update | C12 | 4 | complete | 00, 01, 02 |
| 13 | harness-doctor | C13 | 4 | complete | 00, 01, 02 |

## Deferred Questions Resolution Map

| DQ# | Question | Resolved In | Section |
|-----|----------|-------------|---------|
| DQ1 | Hook registration format per hook | Spec 00 (format), Spec 08 (per-hook details) | 00§6, 08§2 |
| DQ2 | CLAUDE.md appended content | Spec 00 (tag format), Spec 10 (content) | 00§7, 10§3 |
| DQ3 | Config injection boilerplate | Spec 00 | 00§8 |
| DQ4 | Migration function signatures | Spec 09 | 09§3 |
| DQ5 | Conflict detection for existing files | Spec 10 | 10§4 |
| DQ6 | harness-init interactive flow | Spec 11 | 11§3 |

## Phase → Spec Mapping

- **Phase 1 (Foundation):** 01, 02, 03 — can be built in parallel
- **Phase 2 (Core):** 04-09 — content (04-07) parallel with infra (08-09)
- **Phase 3 (Install):** 10 — depends on 02, 03, 08, 09
- **Phase 4 (Commands):** 11-13 — can be built in parallel after 02
