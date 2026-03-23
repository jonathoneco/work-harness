# Spec Index: Agent-First Architecture

| Spec | Title | Component | Status | Dependencies |
|------|-------|-----------|--------|-------------|
| 00 | Cross-cutting contracts | — | complete | — |
| 01 | Context Seeding Protocol | C2 | complete | 00 |
| 02 | Step Agent Prompt Templates | C3 | complete | 00, 01 |
| 03 | Step Agent Dispatcher | C1 | complete | 00, 01, 02 |
| 04 | Delegation Audit & Fix | C4 | complete | 00, 01 |
| 05 | Agent Teams Integration | C5 | complete | 00, 01, 03 |
| 06 | `/delegate` Skill | C6 | complete | 00, 01, 02 |

## Phase Mapping

| Phase | Specs | Description |
|-------|-------|-------------|
| 1 | 01, 02, 03 | Foundation — context protocol, templates, dispatcher |
| 2 | 04, 05 | Optimize — delegation audit, Agent Teams for research |
| 3 | 06 | User-facing — `/delegate` skill |

## Dependency Graph

```
00 (cross-cutting)
├── 01 (context seeding)
│   ├── 02 (prompt templates)
│   │   ├── 03 (dispatcher) ← depends on 01, 02
│   │   └── 06 (delegate) ← depends on 01, 02
│   ├── 04 (audit) ← depends on 01
│   └── 05 (teams) ← depends on 01, 03
```
