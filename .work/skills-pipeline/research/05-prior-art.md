# Prior Art & External Integrations

## Research Questions

1. What existing work has been done on skills, delegation, and agent orchestration?
2. What external tools and MCP servers are currently integrated?
3. What context exists around "dev update dump for Richard" and "deep Notion exploration"?
4. What deferred items from previous workflows impact W4 scope?
5. Are there roadmap dependencies or ordering constraints?

---

## Findings

### 1. Skills & Agent Integration (Prior Work)

**Closed beads issues with direct relevance:**

- **W-05: Agent Teams Integration** (`work-harness-h54`) — Completed. Created `teams-protocol.md` with:
  - Team naming conventions
  - Task schema for multi-agent work
  - 6-section teammate prompt template
  - Completion detection and failure handling
  - Replaced manual Explore spawning with TeamCreate/TeamDelete pattern

- **W-06: /delegate Skill** (`work-harness-1bh`) — Completed. Created `/delegate` command with:
  - 6-category keyword routing table
  - Context-aware prompt construction (with/without active task)
  - 6-section agent prompt structure
  - Skill injection following context-seeding protocol
  - Depends on teams-protocol.md and delegation-audit work

- **W-04: Delegation Audit & Fix** (`work-harness-nz6`) — Completed. Formalizes agent prompts in work-fix.md and work-feature.md.

**Pattern established:** Skills are implemented as `.md` files in `claude/skills/` with frontmatter (`name`, `description`, `type`), referenced by commands via `skills: [name]` directives. Agents inherit skills via context-seeding protocol.

### 2. External Tool Integrations

**MCP Servers (Knowledge Graph & LSP):**

- **work-log** — Cross-project work journaling. Configured in mcp.json as KG server. Entities: WorkSession, Decision, Blocker, Accomplishment. Accessed via `mcp__work_log__*` tools (used by `/handoff` command). Setup guide: `claude/skills/work-harness/references/work-log-setup.md`

- **personal-agent** — Project-specific knowledge routing. Same KG package as work-log. Memory routing rules: cross-project info → work-log, project-specific → personal-agent.

- **Serena** — LSP-backed code navigation. 19 tools available (find_symbol, find_referencing_symbols, get_symbols_overview, rename_symbol, etc.). Skills file: `claude/skills/serena-activate.md`. Configured in `.serena/project.yml` with bash language server. Notion integration pending OAuth setup (noted in W1 quick-wins).

**Code Review & Quality:**

- **Codex CLI** — Optional second-opinion review via `codex exec`. Integrated into `/work-review`. Read-only sandbox mode. JSONL output with severity/category/file/line/message/suggestion. Known hallucination patterns documented (phantom race conditions, misunderstood control flow, framework false positives, missing null checks, imaginary API misuse). Findings always verified by Claude before inclusion. Skill file: `claude/skills/work-harness/codex-review.md`

- **code-quality skill** — Universal anti-pattern rules (8 rules: fail closed, never swallow errors, never fabricate data, handle both branches, constructor injection, return complete results, no divergent interfaces, no shims). References language-specific packs at `references/<language>-anti-patterns.md`.

**Decision Support:**

- **adversarial-eval skill** — Structured debate for design decisions with trade-offs. 3 built-in framings (ship-vs-polish, build-vs-buy, paradigm-choice). Custom framings via `harness.yaml`. Phase 0 (position elicitation) → Phase 1 (opening arguments) → Phase 2 (rebuttal) → Phase 3 (synthesis). Skill file: `claude/skills/adversarial-eval.md`

**Issue Tracking:**

- **beads** — Git-backed issue tracker. Core workflow: `bd ready` → claim → implement → `bd close`. Configured in `.beads/config.yaml`. Integrated with harness via state.json `issue_id` field (note: docs reference `{beads_issue_id}` but schema field is `issue_id` — fixed in W3 bugs).

**Version Control & CI:**

- GitHub/Dolt: `git pull` at session start, `git push` to share work, `bd vc commit` to commit beads changes.

### 3. "Dev Update Dump for Richard" Context

**Work Item:** Skills-pipeline.md item #2 — "Generate status updates from workflow artifacts"

**Strategic context (from harness-roadmap.md W5: Human-in-the-Loop Reporting):**

- W5 depends on W4 skills infrastructure
- Broader theme: "produce useful artifacts for Richard and manage living docs"
- Related items in W5: summary on archive, artifact approval pipeline, local context doc updates
- No Notion/deep exploration mentioned for this item specifically — appears to be artifact-driven (extracting state from `.work/` JSON, findings.jsonl, etc.)

**Implications:**
- Richard (likely the project stakeholder) needs digestible status artifacts from workflow execution
- Skill should transform structured workflow data (state.json, findings, checkpoints) into narrative updates
- Likely output format: markdown summary email or document

### 4. "Deep Notion exploration" Context

**Work Item:** Skills-pipeline.md item #8 — "Push back against shallow exploration"

**Evidence from work-harness-resource research notes:**

Sessions 6 and 8 attempted Notion exploration with documented challenges:
- **Pagination failure (Session 8):** Notion researcher agent only read first page of blocks; user caught gap explicitly
- **MCP permission blocking:** Sub-agents cannot approve interactive MCP tool permissions (Notion OAuth)
- **Token debugging consumed 15 minutes:** Shell variable expansion issues (${NOTION_TOKEN} unexpanded, missing closing quote)

**Roadmap context (harness-roadmap.md W1 quick-wins):**
- "Notion pending OAuth setup" — Serena OAuth integration not yet complete
- W4 item #8 framed as pushback against **shallow** exploration — implies need for systematic, paginated, comprehensive Notion reading

**Phase B review finding (work-harness-resource):** "Notion gap (S6)" — detected as a blocking issue by parallel phase A + B review

**Implications:**
- Skill should enforce comprehensive exploration: pagination, recursive traversal, all blocks/children read
- Requires Notion OAuth token configuration (waiting on Serena setup)
- Skill should catch common failure modes: incomplete pagination, shallow reading, token issues
- Sub-agents delegating Notion work will fail on permissions — may need main-thread retry pattern

### 5. Deferred Items from Previous Workflows

**From W3 (Workflow Phase Redesign) futures.md:**

- **Phase-specific review agents** — Dedicated spec-review vs impl-review agents with different checklists (defer to next iteration)
- **Finding auto-expiry** — Auto-expire OPEN findings when code diff covers the reported file/line (requires git diff analysis)
- **Dispatch routing by domain** — Route spec agents to specialized agents (database architect, API designer) based on spec content (requires agent registry)
- **Conditional verdicts in adversarial eval** — Allow "MVP if X, DEFER if Y" instead of pure binary (verdict format redesign needed)
- **Dynamic risk classification** — Auto-escalate ceremony weight based on task complexity, artifact size, prior loop-back count
- **Multi-step loop chains** — Extend loops beyond plan→research (e.g., spec→plan, decompose→spec)

**From W2 (Agent-First Architecture) futures.md:**

- **Inter-agent communication protocol** — Light message-passing (SendMessage + named agents) for cooperative research agents building on each other's findings
- **Model selection per step type** — Different models for different task types (deferred, low priority, user prefers max power by default)
- **Agent Teams for implement step** — Currently used in research; implement step parallel execution deferred to Phase 2/3

### 6. Roadmap Dependencies & Ordering

**W4 Skills Pipeline positioning (from harness-roadmap.md):**

```
W2 (Agent-First) ✓ done
    ↓
W3 (Phase Redesign) ✓ done
    ↓
W4 (Skills Pipeline) ← current [Tier 2 feature, P3, iterative, can interleave with W3]
    ↓
W5 (Human-in-the-Loop Reporting) [depends on W4 skills infrastructure]
```

**Execution notes:**
- W4 is marked "iterative, can interleave" — not strictly sequential
- W7 (Harness Internals) must precede W4's "tracker abstraction" item
- W4 enables: W5 reporting, W6 session continuity (doc generation), W8 external integrations

### 7. Skill Ecosystem Architecture

**Pattern observed across existing skills:**

| Skill | Trigger | Purpose | Config |
|-------|---------|---------|--------|
| code-quality | Editing source, /work-review | Universal anti-pattern rules | Language pack via `harness.yaml` |
| work-harness | .work/ exists | Harness conventions | Step agents via step-agents.md |
| serena-activate | Session start (hook) | LSP activation | `.serena/project.yml` |
| codex-review | /work-review when `which codex` | Second-opinion review | Optional, graceful fallback |
| adversarial-eval | plan/spec steps (agent-invoked) | Design decision debate | Custom framings via `harness.yaml` |

**Skill propagation mechanism:**
- Commands include `skills: [skill-name]` in frontmatter
- Step agents inherit skills via context-seeding protocol (6-section structure with skill matrix)
- Subagents receive skills via `skills: [skill-name]` when spawned

---

## Implications

1. **W4 Item #2 (Dev Updates):** Implementation should extract from state.json + findings.jsonl + checkpoints, not require new artifact collection. Template-based generation likely sufficient. Could leverage work-log entities if available.

2. **W4 Item #8 (Deep Notion):** Requires:
   - Notion OAuth token provisioning in harness config
   - Pagination guardrails (enforce recursive traversal)
   - Explicit error handling for permission failures
   - Possibly a companion "Notion pagination audit" step that validates full content was read
   - Cannot delegate to sub-agents — main-thread retry pattern needed

3. **Deferred work cohesion:** W3 deferred items (agent registry, dispatch routing, conditional verdicts) would improve W4 items #5, #9, #10. But W4 can proceed without them as MVP.

4. **External integration growth:** Pattern shows MCP servers provide structure (work-log KG, personal-agent KG, Serena LSP) while skills provide logic (codex-review, adversarial-eval, code-quality). W4 should follow this pattern for new integrations (e.g., "Notion reader skill" vs "Notion MCP server").

5. **Language-specific anti-patterns (W4 item #9):** Already has architecture template via code-quality.md references pattern. Implementation is straightforward — create `references/<language>-anti-patterns.md` files and wire into code-quality skill.

6. **Agency-agents deep integration (W4 item #10):** Feasible with `harness.yaml` extension. Define `recommended_agents_per_stack` mapping (e.g., `go: [security-engineer, database-optimizer, performance-benchmarker]`). Not blocking other W4 items.

---

## Open Questions

1. **Who is Richard?** Is he the project stakeholder/user, or a reference person in documentation? Affects tone/detail of "dev update dump."

2. **Notion content scope:** What Notion spaces/pages should the "deep exploration" skill cover? All shared docs, or specific playbooks/specs?

3. **Token handling:** Should Notion token be in `.claude/settings.local.json`, environment variable, or harness.yaml? Any rotation/expiry requirements?

4. **W5 reporting dependency:** Does W4 skills infra need to be complete before W5 starts, or can they run in parallel once basic skills exist?

5. **Adversarial eval custom framings:** Should harness ship with framework-specific framings (e.g., `monolith-vs-service` for architecture work), or leave as project-specific only?

6. **Anti-pattern pack modularization:** Should language packs be distributed as separate git repos (AUR-style) or vendored in harness repo?

7. **Message-passing for agents:** W2 futures mention inter-agent communication protocol. Should W4 skills assume agents can message each other, or will that remain deferred to later tier?
