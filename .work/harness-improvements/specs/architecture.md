# Harness Improvements — Architecture

## Problem Statement

The work-harness has ~4,926 lines across ~60 files. Research identified ~700 lines of duplication across 80+ occurrences and 10 improvement areas spanning agent routing, context management, code quality, parallel execution, and developer experience.

**Goals:**
1. Reduce duplication through modular shared skills
2. Enable smarter agent delegation with step-level skill/rule routing
3. Improve context lifecycle management (auto-maintained docs, compact-only reground)
4. Better parallel work decomposition with hybrid execution strategies
5. Integrate external review tools (Codex) with graceful degradation
6. Improve developer experience (file-based review, auto-reground, agent self-writing)
7. Integrate memory for cross-session context via MCP KG servers

## Component Map

10 components organized by implementation phase. Scope estimates in T-shirt sizes (S/M/L).

### Phase 1 — Independent (no prerequisites)

These components have no inter-area dependencies and can be implemented in any order or in parallel.

| # | Component | Scope | Priority | Files Touched |
|---|-----------|-------|----------|---------------|
| C1 | Stream Docs Enhancement | M | P1 | commands/work-deep.md, streams/*.md template |
| C2 | Code Quality Enhancement | M | P2 | skills/code-quality/references/*, skills/code-quality/code-quality.md |
| C3 | Context Doc System | L | P3 | harness.yaml schema, new skill, hooks |
| C4 | Gate Protocol | M | P6 | new reference doc, commands/work-*.md |
| C5 | Research Protocol | S | P7 | commands/work-deep.md (research section) |
| C6 | Auto-Reground | S | P8 | hooks/post-compact.sh |

### Phase 2 — Foundation (enables Phase 3)

| # | Component | Scope | Priority | Files Touched |
|---|-----------|-------|----------|---------------|
| C7 | Skill Library | L | P5 | new skills/*, commands/work-*.md, hooks/lib/ |

### Phase 3 — Integration (requires Phase 2)

| # | Component | Scope | Priority | Files Touched |
|---|-----------|-------|----------|---------------|
| C8 | Dynamic Delegation | M | P4 | commands/work-deep.md, agent defs |
| C9 | Parallel Execution v2 | M | P1 | commands/work-deep.md (decompose/implement) |

### Phase 4 — Extensions (requires Phases 1+)

| # | Component | Scope | Priority | Files Touched |
|---|-----------|-------|----------|---------------|
| C10 | Codex Integration | M | P9 | new skill, commands/work-review.md |
| C11 | Memory Integration | L | P10 | new MCP config, new command, new rule |

---

## Priority vs Dependency Resolution

**Conflict:** Parallel Decomposition is user priority #1 but depends on Command Modularization (#5) and Dynamic Delegation (#4).

**Resolution — split delivery:**
- **Phase 1 (C1):** Deliver the *format and strategy* improvements to stream docs — enhanced fields (isolation mode, agent type, skills, scope estimate, file ownership manifest), hybrid execution strategy documentation (subagents/agent teams/worktrees), and agent type selection guidance. This addresses the most impactful part of parallel decomposition without needing modular skills.
- **Phase 3 (C9):** Deliver the *operational integration* — stream docs reference shared skills (reducing size), delegation router selects agent types automatically, phase gating integrates with delegation. This requires the Skill Library (C7) and Dynamic Delegation (C8) from Phases 2-3.

Independent items (C2-C6) start immediately in Phase 1, ordered by user priority within the phase.

---

## Component Details

### C1: Stream Docs Enhancement (Phase 1, M)

**What:** Enhance the stream execution document format used during the decompose step. Currently, stream docs contain work items, spec references, files, and acceptance criteria. Add structured fields for parallel execution.

**New fields in stream docs:**
- `isolation`: `inline` | `subagent` | `worktree` — execution isolation mode
- `agent_type`: which agent type to spawn (e.g., `general-purpose`, `Explore`, custom)
- `skills`: list of skill slugs the agent needs
- `scope_estimate`: T-shirt size for scheduling
- `file_ownership`: explicit list of files this stream may modify (for conflict detection)

**Hybrid execution strategy reference:**
- Subagents: for small, single-session work items
- Agent teams: for large work items needing coordination (confirmed stable enough to build on)
- Worktrees: for multi-session parallel work requiring git isolation

**Interfaces:**
- Consumed by: decompose step (writes stream docs), implement step (reads and spawns agents)
- Produces: enhanced `.work/<name>/streams/<stream>.md` files

---

### C2: Code Quality Enhancement (Phase 1, M)

**What:** Expand the code-quality references library with curated external resources and add the parallel review pattern.

**New reference files:**
- `skills/code-quality/references/security-antipatterns.md` — curated from sec-context (25+ security anti-patterns for LLM context)
- `skills/code-quality/references/ai-config-linting.md` — curated from agnix (230+ rules for AI config files)
- Language-specific anti-pattern files under `skills/code-quality/references/language-specific/`

**Parallel review pattern:**
- Document the 9-parallel-review-agents pattern in the code-quality skill
- Each agent covers a different quality dimension (security, performance, error handling, etc.)
- Agents run concurrently; lead synthesizes findings

**Interfaces:**
- Consumed by: review agents (via `skills: [code-quality]`), Codex Integration (C10)
- Produces: reference docs loaded as agent context

---

### C3: Context Doc System (Phase 1, L)

**What:** Harness auto-maintains project documentation via a manifest in `harness.yaml`. Auto-detects relevant doc types from project stack config. Agents use these docs as context.

**Manifest schema (in harness.yaml):**
```yaml
docs:
  managed:
    - type: endpoints       # API endpoint inventory
      path: docs/endpoints.md
    - type: components      # Frontend component tree
      path: docs/components.md
    - type: env-setup       # Environment setup guide
      path: docs/env-setup.md
    - type: architecture    # System architecture
      path: docs/architecture.md
    - type: dependencies    # Key dependency versions
      path: docs/dependencies.md
```

**Auto-detection:** When `docs.managed` is empty or absent, detect doc types from `harness.yaml` stack config (e.g., if `framework: nextjs`, suggest `components` and `endpoints` docs).

**Agent context injection:** Implementation and research agents receive managed doc paths as context. The skill/command that spawns agents reads the manifest and includes relevant doc content.

**Interfaces:**
- Configuration: `harness.yaml` `docs.managed[]`
- Consumed by: agent spawning logic in commands
- Produces: maintained doc files at configured paths

---

### C4: Gate Protocol (Phase 1, M)

**What:** Formalize the file-based review UX pattern across all stages that require user review and approval. Replaces inline terminal review with structured files the user reviews in their editor.

**Directory convention:** `.work/<name>/gates/`

**File naming:**
- Step transitions: `<from>-to-<to>.md` (e.g., `research-to-plan.md`)
- Implementation phases: `implement-phase-N.md`
- Ad-hoc reviews: `review-<timestamp>.md`

**File structure:**
```markdown
# Gate: <title>

## Summary
<what this step produced>

## Review Results
### Phase A — Artifact Validation
<verdict and details>

### Phase B — Quality Review
<verdict and details>

## Advisory Notes
<full advisory notes>

## Deferred Items
<open questions, futures>

## Next Step
<what the next step involves>

## Your Response
<!-- Review the above and respond here:
     - "approved" to advance
     - Questions or feedback (will trigger discussion)
-->
```

**Rollback gates:** When revisiting a previously approved gate, create a new file referencing the original. Originals are never modified post-approval.

**SOP reference:** `skills/work-harness/references/gate-protocol.md`

**Interfaces:**
- Consumed by: all step transition logic in commands
- Produces: gate files at `.work/<name>/gates/`
- User interaction: create file → user reviews in editor → iterate with round markers → approve → commit

---

### C5: Research Protocol (Phase 1, S)

**What:** Research agents write their own `.work/<name>/research/NN-topic.md` files directly, rather than returning findings to the lead for transcription.

**Agent prompt pattern:**
- Lead provides: task context, topic scope, target file path, index format
- Agent writes: research note file directly
- Lead synthesizes: handoff prompt only (cross-references, dependencies, open questions)

**Benefits:** Agents are maximally grounded in their research context when writing notes. Lead avoids being a bottleneck transcriber.

**Tradeoff:** Research notes may not be grounded in the broader task context. Mitigated by lead providing task context in agent prompts and synthesizing the handoff.

**Interfaces:**
- Changes: research step instructions in commands/work-deep.md
- Produces: agent-written research files

---

### C6: Auto-Reground (Phase 1, S)

**What:** Enhance existing `hooks/post-compact.sh` to inject the relevant handoff prompt after compaction. Compact-only — no change on resume or startup.

**Behavior:**
1. On compact: detect active task from `.work/*/state.json`
2. Read `current_step` from state
3. Find the most recent handoff prompt for the current or previous step
4. Inject a summary into the post-compact output

**Handoff prompt resolution order:**
1. `.work/<name>/<current_step>/handoff-prompt.md` (if transitioning)
2. `.work/<name>/<previous_step>/handoff-prompt.md` (if mid-step)
3. Fall back to state.json summary

**No changes on:**
- Resume (context already in conversation from previous session)
- Startup (existing workflow-detect.md rule handles notification; user may not be entering a workflow)

**Interfaces:**
- Modifies: `hooks/post-compact.sh`
- Reads: `.work/*/state.json`, handoff prompt files

---

### C7: Skill Library (Phase 2, L)

**What:** Extract repeated logic from commands into shared skills. This is the foundation that enables Dynamic Delegation (C8) and Parallel Execution v2 (C9).

**Extracted skills:**

| Skill | Occurrences | Lines Saved | Source Pattern |
|-------|-------------|-------------|----------------|
| `task-discovery` | 7 commands | ~100 | Active task finding, state.json reading |
| `step-transition` | 10+ | ~150 | Approval ceremony, gate issue creation, state update |
| `phase-review` | 5 | ~100 | Review block template (Phase A + Phase B) |

**Shared hook utilities:**
- `hooks/lib/common.sh` — DRY hook boilerplate (state detection, logging, error handling)
- Currently each hook repeats: state file discovery, JSON parsing, error output formatting

**Skill structure:**
```
skills/work-harness/
  task-discovery.md     # Find active task, read state, present status
  step-transition.md    # Approval ceremony, gate file, state update
  phase-review.md       # Phase A + B review template
  references/
    gate-protocol.md    # Gate file SOP (from C4)
```

**Interfaces:**
- Consumed by: all work-* commands (via `skills: [work-harness]`)
- Enables: Dynamic Delegation (C8) — skills become routable units
- Enables: Parallel Execution v2 (C9) — shared skills reduce stream doc size

---

### C8: Dynamic Delegation (Phase 3, M)

**What:** Commands explicitly map agent types and skills to each step, replacing implicit/ad-hoc delegation. Phase-specific guidance moves from rules (always loaded) to skills (on-demand).

**Step-level routing table (in command definitions):**
```
step: research
  agent_type: Explore
  skills: [work-harness, code-quality]
  context: [research handoff, managed docs]

step: plan
  agent_type: Plan
  skills: [work-harness, code-quality]
  context: [research handoff]

step: implement
  agent_type: general-purpose (or per review_routing in harness.yaml)
  skills: [work-harness, code-quality]
  context: [stream doc, relevant specs, managed docs]
```

**Prerequisite verification:** Test whether agent YAML frontmatter `skills:` field is actually supported by Claude Code. If not, skills must be injected via agent prompt text.

**Phase-specific guidance migration:**
- Move step-specific instructions from rules (loaded for all steps) to skills (loaded for relevant steps only)
- Reduces context pollution — agents only see guidance relevant to their step

**Interfaces:**
- Requires: Skill Library (C7) — skills must exist before routing to them
- Consumed by: work-deep command step router
- Produces: properly configured agent spawns

---

### C9: Parallel Execution v2 (Phase 3, M)

**What:** Full operational integration of parallel decomposition with modular skills and dynamic delegation.

**Enhancements over C1 (format-only):**
- Stream docs reference shared skills by slug instead of inlining guidance
- Delegation router auto-selects agent types based on stream doc metadata
- Phase gating integrates with delegation router for automated review agent selection
- File ownership manifests enforced at phase boundaries (verify no conflicts)

**Interfaces:**
- Requires: Skill Library (C7), Dynamic Delegation (C8), Stream Docs Enhancement (C1)
- Consumed by: decompose and implement steps

---

### C10: Codex Integration (Phase 4, M)

**What:** Optional integration with OpenAI Codex for delegated code review. Graceful degradation if Codex is not installed.

**Phased approach:**
1. **Skill first:** `skills/work-harness/codex-review.md` wrapping `codex exec --output-schema --sandbox read-only`
2. **MCP later:** `codex --mcp` as native MCP server (when stable)
3. **Dual-review eventually:** Claude + Codex review in parallel, findings merged

**Safety rules:**
- Optional with graceful degradation (check `which codex` before use)
- Codex findings always verified by Claude, never auto-actioned
- Known hallucination patterns documented: phantom race conditions, misunderstood control flow, framework false positives

**Interfaces:**
- Requires: Code Quality Enhancement (C2) — quality schema informs Codex output schema
- Consumed by: work-review command
- Produces: findings merged into `review/findings.jsonl`

---

### C11: Memory Integration (Phase 4, L)

**What:** Two MCP Knowledge Graph servers for persistent memory across sessions and projects.

**Servers:**
- `personal-agent` — project-level KG (already exists in user's personal-agent project)
- `work-log` — user-level KG for cross-project work journal and end-of-day handoffs

**Work journal pattern:**
- `/handoff` command captures daily progress to `work-log` memory
- Entities: tasks, decisions, blockers, accomplishments
- Relations: task-worked-on, decision-made-for, blocked-by

**Routing policy:**
- Rule-based: descriptive server names + routing rule
- `work-log`: work journal entries, cross-project context, session summaries
- `personal-agent`: project-specific knowledge, architecture decisions, codebase patterns

**Interfaces:**
- Enriched by: Auto-Reground (C6) — compact reground could pull relevant memory
- Produces: persistent cross-session context
- Configuration: MCP server config in Claude Code settings

---

## Data Flow

### Command Execution Flow
```
User runs /work-deep
  → Task Discovery (C7) → finds active task, reads state.json
  → Step Router → reads current_step
    → Dynamic Delegation (C8) → selects agent type, skills per step
      → Agent spawned with:
          Skills from Skill Library (C7)
          Code Quality refs (C2)
          Context Docs (C3, if configured)
          Stream Doc (C1, during implement)
      → Agent executes work
  → Step Transition (C7) → approval ceremony
    → Gate Protocol (C4) → writes gate file, user reviews in editor
    → Auto-Reground (C6) → on next compact, injects handoff
```

### Review Flow
```
/work-review
  → Phase Review (C7) → review template
  → Code Quality refs (C2) → loaded as agent context
  → Codex Review (C10, optional) → headless review
  → Claude verifies Codex findings
  → Merged findings → review/findings.jsonl
```

### Memory Flow
```
Session end → /handoff → work-log MCP (C11) → persistent journal
Session start → post-compact.sh (C6) → injects handoff context
Cross-session → work-log MCP → provides historical context on demand
```

---

## Implementation Phases — Summary

| Phase | Components | Prerequisites | Parallelism |
|-------|-----------|---------------|-------------|
| 1 | C1, C2, C3, C4, C5, C6 | None | All 6 can run in parallel |
| 2 | C7 | None (but sequenced after Phase 1 for cleaner integration) | Sequential |
| 3 | C8, C9 | C7 (Skill Library) | C8 before C9 |
| 4 | C10, C11 | C2 (for C10), C6 (enriches C11) | Can run in parallel |

**Critical path:** Phase 1 (parallel) → Phase 2 (C7) → Phase 3 (C8 → C9)

**Phase 4 can start after Phase 1 completes** (C10 needs C2, C11 is enriched by C6).

---

## Scope Exclusions

- **No new CLI tool development** — all changes are to existing command/skill/hook/rule files or new files within the established harness structure
- **No breaking changes to state.json schema** — additions only (new optional fields)
- **No changes to beads workflow** — beads integration remains as-is
- **Agent YAML frontmatter `skills:` field** — if verification shows it's unsupported, C8 adapts to prompt-based skill injection (not blocked)
- **Codex MCP mode** — Phase 4 starts with CLI exec; MCP is a future enhancement within C10
- **personal-agent MCP server** — already exists, not part of this initiative (only `work-log` is new)

## Questions Deferred to Spec

1. **C3 auto-detection heuristics:** Exactly which stack config fields map to which doc types?
2. **C7 skill extraction granularity:** Should `step-transition` be one skill or split into `approval-ceremony` + `state-update`?
3. **C8 skills field verification:** Does Claude Code agent YAML frontmatter support `skills:` natively? This determines implementation approach for C8.
4. **C10 output schema design:** What structured format should Codex findings use for reliable parsing?
5. **C11 entity schema:** What entities/relations/observations should the work-log KG track?
