# Handoff Prompt: Research -> Plan

## What Research Produced

8 research notes + 2 proposed additions from review discussion, indexed at `.work/harness-improvements/research/index.md`. Full review with 3 rounds of feedback at `.work/harness-improvements/research/REVIEW.md`.

## Improvement Areas (10 total)

### 1. Command Modularization (02-duplication-analysis.md)
~700 lines of duplication across 80+ occurrences. Top extractions:
- **task-discovery** skill (7 commands repeat active task finding)
- **step-transition** skill (10+ identical approval ceremonies)
- **phase-review** skill (5 identical review blocks in work-deep.md)
- **hooks/lib/common.sh** (hook boilerplate DRY)

### 2. Dynamic Delegation (08-dynamic-delegation.md)
- Commands already function as routers — enhance with explicit agent/skill mapping per step
- **Verify whether agent YAML frontmatter `skills:` field is supported** — needs testing
- Move phase-specific guidance from rules (always loaded) to skills (on-demand)

### 3. Auto-Reground (08-dynamic-delegation.md)
- **Compact-only**: Enhance existing `post-compact.sh` to inject relevant handoff prompt
- No change on resume (context already in conversation)
- No auto-reground on startup (existing workflow-detect.md rule handles notification)

### 4. Code Quality References (03-code-quality-refs.md)
- **sec-context** — drop-in security anti-patterns for LLM context
- **agnix** — linter for AI configs (230+ rules)
- Expand `code-quality/references/` with language-specific anti-pattern files
- Consider 9-parallel-review-agents pattern for work-review

### 5. Context Doc Lifecycle (04-context-doc-lifecycle.md)
- **Interpretation B**: Harness auto-maintains docs via manifest in `harness.yaml`
- Auto-detect relevant doc types from project stack config
- Manifest-driven: `docs.managed[]` with type and path
- Not just manage but **leverage** these docs — agents use them as context
- Doc types: endpoints, components, env-setup, architecture, dependencies

### 6. Codex Integration (05-codex-integration.md)
- `codex exec --output-schema --sandbox read-only` for headless review
- Or native MCP server: `codex --mcp`
- **Optional with graceful degradation** if not installed
- Codex findings always verified by Claude, never auto-actioned
- Phased: skill first, MCP later, dual-review eventually

### 7. Parallel Decomposition (07-parallel-decomposition.md)
- Existing streams model validated by harness-modularization task
- Add to stream docs: isolation mode, agent type, skills, scope estimate, file ownership manifest
- Hybrid strategy: subagents (small), agent teams (large), worktrees (multi-session)
- **Agent Teams confirmed stable enough** to build on (user uses extensively)

### 8. Memory Integration (06-memory-integration.md)
- **Two MCP KG servers**: `personal-agent` (project-level) and `work-log` (user-level via harness)
- User-level for cross-project work journal and end-of-day handoffs
- Rules-based routing policy to direct Claude to correct server
- `/handoff` command captures daily progress to work-log memory

### 9. Agent-Written Research Notes (from review discussion)
- Research agents write their own `.work/<name>/research/NN-topic.md` files directly
- Lead provides task context in agent prompts for grounding
- Lead synthesizes handoff prompt only (cross-references, dependencies, open questions)

### 10. File-Based Review UX (from review discussion)
- Gate files at `.work/<name>/gates/<gate-name>.md`
- Naming: `<from>-to-<to>.md`, `implement-phase-N.md`, `review-<timestamp>.md`
- SOP: create → user reviews in editor → iterate with round markers → approve → commit
- Rollback gates: new file referencing original, originals never modified
- SOP reference doc at `skills/work-harness/references/gate-protocol.md`

## Resolved Decisions

| Question | Decision |
|----------|----------|
| Modularization scope | Refactor existing commands |
| Memory scoping | User-level, with work-journal for end-of-day handoffs |
| Memory MCP naming | `personal-agent` and `work-log` |
| Memory MCP routing | Descriptive names + rule-based routing policy |
| Codex dependency | Optional with graceful degradation |
| Codex hallucinations | Always verify, never auto-action |
| Context doc scope | Interpretation B — harness auto-maintains via manifest |
| Context doc leverage | Not just maintain but use as agent context |
| Agent Teams | Stable enough to build on |
| Auto-reground | Compact-only (enhance existing post-compact.sh) |
| Gate files | `.work/<name>/gates/` with SOP for creation, iteration, rollback |
| Priority | parallel decomp → code quality → context docs → delegation → modularization → file review → agent notes → auto-reground → codex → memory |

## Inter-Area Dependencies

```
Command Modularization ──> Dynamic Delegation (modular skills enable explicit routing)
Command Modularization ──> Parallel Decomposition (shared skills reduce stream doc size)
Auto-Reground ──> Memory Integration (reground could leverage memory for richer context)
Dynamic Delegation ──> Parallel Decomposition (agent routing needed before parallel agents)
Code Quality Refs ──> Codex Integration (quality schema needed before Codex review schema)
```

**Independent** (can start anytime): Auto-Reground, Code Quality Refs, Context Doc Lifecycle
**Foundation** (enables others): Command Modularization
**Dependent**: Dynamic Delegation, Parallel Decomposition, Codex Integration, Memory Integration

## Artifacts
- Research notes: `.work/harness-improvements/research/01-08*.md`
- Research index: `.work/harness-improvements/research/index.md`
- Review file (3 rounds): `.work/harness-improvements/research/REVIEW.md`
- Futures: `.work/harness-improvements/futures.md`
- Feature summary: `docs/feature/harness-improvements.md`

## Instructions for Plan Step
1. Read this handoff prompt as primary input (do NOT re-read individual research notes)
2. Respect the user's priority ordering when sequencing work
3. Note that priority ordering may conflict with inter-area dependencies — resolve this
4. Group improvements into implementation phases
5. Produce architecture document at `.work/harness-improvements/specs/architecture.md`
6. Update `docs/feature/harness-improvements.md` with component list
