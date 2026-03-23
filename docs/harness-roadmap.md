# Harness Roadmap

Decomposed from iteration dump — 2026-03-19.

## Execution Order

```
W1 (Quick Wins)           <- do now, unblocks daily friction
W2 (Agent-First)          <- foundational, most items depend on this
W3 (Phase Redesign)       <- builds on W2's agent architecture
W7 (Internals)            <- enables W4's tracker abstraction
W4 (Skills Pipeline)      <- iterative, can interleave with W3
W5 (Reporting)            <- depends on W4 skills infra
W6 (Session Continuity)   <- independent, can parallel with W3-W5
W8 (External Integration) <- independent, can parallel
W9 (Dashboard/TUI)        <- last, depends on stable internals
```

---

## W1: Quick Wins & Hygiene

**Tier**: T1 batch | **Priority**: P2 | **Do first**

Small fixes that reduce daily friction. Knock these out in a single session.

- [x] **Add Serena commands to allowlist** — added all 19 Serena MCP tools to `.claude/settings.local.json` (Notion pending OAuth setup)
- [x] **Clean up `.review/findings`** — pruned stale findings.jsonl from 3 archived tasks
- [x] **Fix: docs cleanup** — consolidated `docs/futures/` (3 files) into single `docs/futures.md`
- [x] **Fix: futures should save at any step** — added futures instruction to review step in `work-deep.md` and `work-feature.md`
- [x] **Remove annoying `rm -rf` blocks** — removed blanket deny; falls through to `acceptEdits` (prompted, not blocked)

---

## W2: Agent-First Architecture

**Tier**: T3 initiative | **Priority**: P2-P3 | **High impact, foundational**

Core thesis: _The harness should delegate to specialized agents with proper context, not worktrees._

- [ ] **Fix: decompose as agents, not worktrees** — fundamental architecture shift
- [ ] **Steps as agents** — each workflow phase runs as a named subagent
- [ ] **Parallelize decomposition** — specific agents for research, planning, spec (current flow is serial)
  - intermediate step for reasoning about what research to do
- [ ] **`/delegate` skill** — auto-routing to the right agent based on task characteristics
- [ ] **Delegation with proper context as a priority** — agents get seeded with relevant artifacts, not raw dumps
- [ ] **Subagent delegation audit** — fix current delegation gaps
- [ ] **Agent Teams integration** — experimental but promising for large parallel work. _Blocked_: requires experimental flag, no session resumption, API may change

---

## W3: Workflow Phase Redesign

**Tier**: T3 initiative | **Priority**: P3 | **High impact, depends on W2**

Core thesis: _Rethink how phases work — better exploration, smarter review, research-first paths._

- [ ] **Explore phase: build clarity** — nail down intention, push back, ask questions before planning
- [ ] **Plan mode redesign** — inspired by Claude's plan mode: pointed design questions with options, ability to expand
- [ ] **Phase-aware review** — phased review should change depending on phase (Phase A review != Phase B review)
- [ ] **Review timing** — phased review only at end of back-and-forth, not mid-conversation
- [ ] **Open questions: tackle immediately** — "deferred" questions are usually better scoped to resolve now
- [ ] **Aggressive Phase B finding resolution** — handle findings immediately unless it's a design concern
- [ ] **Advisory notes -> direct clarification asks** — don't just note, ask
- [ ] **`work-research` support** — research-only path for pure research tasks (e.g., product-agent-scope)
- [ ] **First-class research/design loop** — repeated research/design workflow pattern needs formal support
- [ ] **General adversarial-eval improvements** — flush out perspectives into argued positions

---

## W4: Skills Pipeline

**Tier**: T2 feature | **Priority**: P3 | **Iterative, can interleave with W3**

Core thesis: _Build out the skill ecosystem — new skills, updating, better integration._

- [ ] **`workflow-meta` proper workflow** — should kick off a workflow with pre-seeded context/intention
- [ ] **Skill: dev update dump for Richard** — generate status updates from workflow artifacts
- [ ] **Skill: proactive skill updating** — skills evolve as the project evolves
- [ ] **Skill: PR handling** — PR review, CI checks, merge workflow
- [ ] **Skills for new tech stack** — project-specific skill generation
- [ ] **Flush out harness skills** — fill gaps in existing skill coverage
- [ ] **Dump command** — decompose a chunk of work into well-scoped workflows (this process, as a command)
- [ ] **Skill: deep Notion exploration** — push back against shallow exploration
- [ ] **Language-specific anti-pattern packs** — ship Go, Python, TypeScript, Rust references as optional add-ons via `harness.yaml`
- [ ] **Agency-agents deep integration** — curated agent subset recommendation per stack in `harness.yaml`
- [ ] **Multi-language project support** — projects using Go + TypeScript need both anti-pattern packs active simultaneously

---

## W5: Human-in-the-Loop Reporting

**Tier**: T2 feature | **Priority**: P3 | **Depends on W4 skills infra**

Core thesis: _The harness should produce useful artifacts for Richard and manage living docs._

- [ ] **Summary on archive** — auto-generate human-readable summary when archiving
- [ ] **Artifact approval pipeline** — pipeline for artifact creation that seeks Richard's approval/input
- [ ] **API route management** — harness knows about and maintains API route documentation
- [ ] **Local context doc updates** — keep project docs in sync with implementation
- [ ] **Traffic-based API docs** — Levo.ai/Treblle for always-in-sync endpoint documentation
- [ ] **DocAgent pattern** — multi-agent doc generation with topologically sorted dependency order

---

## W6: Session Continuity & Memory

**Tier**: T3 initiative | **Priority**: P3 | **Independent, can parallel with W3-W5**

Core thesis: _Sessions should be named, resumable, and hand off cleanly._

- [ ] **Daily handoff prompts** — end-of-day summaries across all sessions for cross-session continuity
- [ ] **Cross-session memory improvements** — better memory persistence and recall
- [ ] **Named chat sessions** — easier resuming and understanding
- [ ] **Disconnected Claude sessions** — server-based approach (not tmux)
- [ ] **Serena memory integration** — harness should use Serena's memory feature
- [ ] **Session-start staleness warnings** — warn if context documents reference deprecated technologies
- [ ] **freshness_class field** — enum on context docs (slow/medium/fast/frozen) for differentiated scan cadences
- [ ] **last_reviewed field** — ISO date tracking when a document was last validated for accuracy

---

## W7: Harness Internals Modernization

**Tier**: T2 feature | **Priority**: P3 | **Enables W4's tracker abstraction**

Core thesis: _The internal architecture needs cleanup — smaller files, pluggable tracker._

- [ ] **Modularize work files** — break up large command/skill files
- [ ] **Beads swap-in / harness-managed tasks** — harness owns task tracking, beads is one backend
- [ ] **Tracker agnostic interface** — abstract the tracker so it works with any issue tracker
- [ ] **Plugin conversion** — convert harness from global install to Claude Code plugin format. _Blocked_: plugin format has security restrictions (no hooks/mcpServers)
- [ ] **Plugin marketplace integration** — distribute as a Claude Code plugin if plugin system matures
- [ ] **Harness versioning** — semantic versioning on install script + migration notes for breaking changes
- [ ] **Stow compatibility** — install.sh writes directly to `~/.claude/` which conflicts with GNU Stow directory symlinks

---

## W8: External Tool Integration

**Tier**: T2 feature | **Priority**: P3-P4 | **Independent, can parallel**

Core thesis: _Connect the harness with CI, desktop, and dev environment tooling._

- [ ] **Check PR conclusions / CI** — monitor CI status, surface failures
- [ ] **Claude Code & Claude Desktop integration** — bridge CLI and desktop workflows
- [ ] **Dev-env maintenance** — harness helps keep dev environment healthy
- [ ] **Dev-env skill generalization** — pull dependency awareness from gaucho's dev-env skill into harness as a generic feature
- [ ] **agnix CI integration** — lint harness configs in CI pipeline. _Blocked_: need baseline configs first
- [ ] **GitHub Agentic Workflows** — markdown-defined CI automations (in technical preview)
- [ ] **Storybook MCP** — expose component patterns as machine-readable context. _Blocked_: frontend-project-specific

---

## W9: Harness Dashboard & TUI

**Tier**: T3 initiative | **Priority**: P4 | **Last, depends on stable internals**

Core thesis: _Visual layer over the harness for monitoring and control._

- [ ] **TUI around workflow harness** — terminal UI for task management
- [ ] **Agent dashboard with colors** — visual distinction between agents/sessions
- [ ] **Session names in dashboard** — at-a-glance understanding of what's running

---

## Someday

Items without a clear workflow home or with distant horizons.

- **Hybrid memory (vector + graph)** — Mem0-style architecture; filesystem is competitive per Letta benchmark
- **Multi-model review consensus** — expand beyond Claude + Codex
- **Automated CLAUDE.md drift detection** — CI job comparing codebase structure against context files
- **CI/CD integration** — harness hooks running in CI with headless mode
- **Shared review agent registry** — community-contributed review agents as add-on packs
- **Harness analytics** — track hook fires, command usage, task tier distribution
- **Temporal knowledge graph** — Zep/Graphiti for cross-project knowledge with validity windows
