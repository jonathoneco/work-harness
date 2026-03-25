# Pass 8: Recommendations — Prioritized Action List

## Quick Wins (< 1 session each)

### QW-1: Install ccost for cost visibility
**Effort:** 10 minutes | **Impact:** HIGH
**Source:** ccost (carlosarraes/ccost) — Go binary, zero deps, multi-currency
**Why:** Every power user surveyed tracks costs. We have zero visibility. ccost parses ~/.claude/projects/ JSONL natively. Go binary aligns with our stack.
**Action:** `go install github.com/carlosarraes/ccost@latest` + add alias to shell config.

### QW-2: Install Lasso hooks for prompt injection scanning
**Effort:** 30 minutes | **Impact:** MEDIUM-HIGH
**Source:** Lasso claude-hooks — PostToolUse scanning, 50+ patterns, warning-based
**Why:** Multiple CVEs (2025-2026) demonstrated real prompt injection through project files. Lasso is low-friction (warning-only, no false-positive blocking), open-source, and integrates with our existing hook architecture.
**Action:** Clone repo, run installer, configure PostToolUse hooks alongside our existing hooks.

### QW-3: Add context health status line
**Effort:** 30 minutes | **Impact:** MEDIUM
**Source:** Van der Herten's status line approach — green/yellow/red at 40/60/80%
**Why:** Context health is the single best predictor of session quality. The 35-minute cliff and degradation at 50% utilization are well-documented. A visual indicator tells you when to compact or start fresh.
**Action:** Shell script or hook that reads /context output and sets a status indicator. Could integrate with swaync notifications or tmux status bar.

### QW-4: Add code examples to CLAUDE.md
**Effort:** 20 minutes | **Impact:** MEDIUM
**Source:** Research showing 3-5 code examples reduce correction requests by 40%
**Why:** Our CLAUDE.md has conventions but few examples. "A 5-line example is more effective than 20 lines of explanation."
**Action:** Add 3-5 Go code examples to CLAUDE.md for our most common patterns (error wrapping, table-driven tests, constructor injection, structured logging).

### QW-5: Add "surface failures only" mode to hooks
**Effort:** 30 minutes | **Impact:** MEDIUM
**Source:** HumanLayer finding — hooks surfacing verification only on failure are "the highest-leverage things we have spent time on"
**Why:** Some hooks should run silently on success and only surface on failure. Currently all hooks either pass or block. A warning mode enables back-pressure without interruption.
**Action:** Add `HARNESS_HOOK_MODE=warn` support to common.sh, used by non-critical hooks.

## Small Features (1-2 sessions each)

### SF-1: Cost-per-feature hook
**Effort:** 1 session | **Impact:** HIGH
**Source:** No existing tool provides cost-per-feature. Requires correlating JSONL timestamps with beads issue boundaries.
**Why:** "What did that feature cost?" is the question every power user wants answered. ccost gives session-level costs; we need task-level.
**Action:** Build a hook or CLI that reads JSONL entries between `bd update --status=in_progress` and `bd close` timestamps, sums token costs. Store result in beads issue notes.

### SF-2: CLAUDE.md flywheel skill (/capture-lesson)
**Effort:** 1 session | **Impact:** HIGH
**Source:** Cherny's CLAUDE.md update flywheel, MindStudio binary eval approach
**Why:** Automated mistake-to-rule capture compounds improvements. Currently we update CLAUDE.md manually and inconsistently.
**Action:** New skill that prompts: "What did Claude get wrong this session?" → extracts patterns → appends to .claude/rules/ → commits. Could also parse session logs for correction patterns.

### SF-3: TDD enforcement hook
**Effort:** 1 session | **Impact:** MEDIUM-HIGH
**Source:** Shankar's "Block-at-Submit" pattern, Vincent's Superpowers, TDD Guard (nizos)
**Why:** Every practitioner surveyed who enforces TDD reports it as "the single best quality signal." Tests catch context drift before it compounds.
**Action:** PreToolUse hook wrapping git commit that runs `go test ./...` first. Creates /tmp/agent-pre-commit-pass only after successful tests. Configurable per-project via harness.yaml.

### SF-4: Structured handoff extraction
**Effort:** 1 session | **Impact:** MEDIUM
**Source:** Continuous-Claude-v3 ledger format, Shankar's "Document & Clear"
**Why:** Our handoff prompts vary in quality. Formalizing what they capture ensures consistent session bridging.
**Action:** Update handoff skill to systematically extract: decisions made (what + why), files modified (with brief rationale), patterns discovered, mistakes made, remaining work, context health at handoff time.

### SF-5: Binary eval runner for skills
**Effort:** 1-2 sessions | **Impact:** HIGH (compounds)
**Source:** DSPy prompt compilation pattern, MindStudio binary eval approach
**Why:** The single highest-leverage self-improvement mechanism. Every automated improvement to a skill instruction improves all future invocations. A 50-line test harness passes inputs to skills, collects outputs, runs pass/fail assertions.
**Action:** Go script that: (1) loads a skill + test cases, (2) runs skill with test inputs, (3) evaluates outputs against assertions, (4) reports pass/fail. Initially manual test cases; later, automated mutation loop.

## Larger Initiatives (multi-session)

### LI-1: Self-improving skill pipeline
**Effort:** 3-5 sessions | **Impact:** VERY HIGH (compounds)
**Source:** DSPy prompt compilation, MindStudio overnight optimization, Osmani's compound learning
**Why:** Builds on SF-5 (binary eval runner). Adds automated mutation: the system proposes skill instruction changes, evaluates them, keeps improvements. Can run overnight. Every improvement compounds across all future invocations.
**Action:** Extend eval runner with: mutation proposals (LLM suggests instruction changes), A/B evaluation (run both versions against test suite), promotion (keep better version), logging (track improvement over time).
**Prerequisite:** SF-5 (binary eval runner)

### LI-2: Context-mode integration or Go-native equivalent
**Effort:** 2-3 sessions | **Impact:** MEDIUM-HIGH
**Source:** context-mode (mksglu) — 98% reduction in tool output tokens, sessions from ~30 min to ~3 hours
**Why:** Session longevity is a binding constraint for T3/Initiative tasks. Compressing tool outputs while retaining searchability could be transformative.
**Concern:** context-mode is Node.js. We'd need to either accept the Node dependency or build a Go-native equivalent using SQLite FTS5.
**Action:** Evaluate context-mode against actual Serena output sizes. If the compression quality holds, either use it directly or build a Go equivalent as a PreToolUse/PostToolUse hook.

### LI-3: Typed agent I/O contracts
**Effort:** 2 sessions | **Impact:** MEDIUM
**Source:** PydanticAI type contracts pattern
**Why:** Agent outputs that don't match expected schemas silently propagate errors. Go struct unmarshaling provides natural validation.
**Action:** Define Go structs for common agent output formats (research notes, review findings, implementation reports). Build a validation hook that checks agent outputs against schemas before they're consumed by the next step.

## Things to Drop or Simplify

### DROP-1: Don't adopt any agent framework
**Evidence:** The law firm CTO built 900 agents with raw API calls. 45% of LangChain users never shipped; 23% ripped it out. Anthropic recommends raw API + simple patterns. 12-Factor Agents manifesto: "own your control flow."
**Our position:** Our Go + filesystem + git + hooks approach IS the framework. Adding LangGraph/DSPy/PydanticAI would add abstraction layers over patterns we already implement natively.

### DROP-2: Don't add more MCP servers
**Evidence:** MCP costs 7-32x more tokens than CLI equivalents. Our current 3 MCPs (Serena, work-log, personal-agent) all manage genuinely stateful resources. Context7 is irrelevant (Go, not JS frameworks). GitHub MCP is 17x worse than `gh` CLI.
**Our position:** Current MCP stack is right-sized. Resist MCP sprawl.

### DROP-3: Don't install external session multiplexers (yet)
**Evidence:** Native agent teams (Feb 2026) are catching up. Our subagent delegation pattern handles current needs. Claude Squad is the strongest external option but may become redundant within 6 months.
**Our position:** Wait for native teams to stabilize. Use subagents for parallel work.

### SIMPLIFY-1: Make teams protocol optional for simple parallel work
**Current:** Teams protocol prescribes naming, task schemas, teammate prompts for all parallel agent work.
**Proposed:** Teams protocol for research/review steps (complex coordination needed). Plain subagent calls for simple parallel tasks (implementation across 2-3 files).

## Things to Watch

### WATCH-1: Native Agent Teams maturity
**Signal:** Session resumption for teammates, nested team support, exit from experimental flag.
**Impact:** If stable, replaces our Teams protocol for complex coordination. If unstable, validates our custom approach.
**Check:** Monthly — test with a real multi-domain task.

### WATCH-2: MCP Tasks primitive (SEP-1686)
**Signal:** Agent-to-agent coordination with retry semantics and expiry policies.
**Impact:** Could complement or replace beads for intra-session coordination.
**Check:** Quarterly — monitor MCP spec releases.

### WATCH-3: Skill ecosystem convergence
**Signal:** Package manager, versioning, testing infrastructure, cross-tool compatibility standards.
**Impact:** If converges, changes build-vs-buy calculus for skills. If fragments, validates our custom approach.
**Check:** Quarterly — monitor VoltAgent cross-tool compatibility.

### WATCH-4: Go MCP SDK and Google ADK maturity
**Signal:** Google ADK for Go reaching v1.0, mcp-go adding agent-to-agent communication.
**Impact:** If we ever need custom MCP servers, these are the tools.
**Check:** Quarterly — check release notes.

### WATCH-5: context-mode or Go-native equivalent
**Signal:** Go port, validated quality on Go codebases, or competitive Go-native project.
**Impact:** Could extend session longevity significantly for T3 tasks.
**Check:** Monthly — monitor repo and alternatives.

### WATCH-6: Gemini CLI as free-tier supplement
**Signal:** Google maintaining 1,000 requests/day free tier, Gemini 2.5 Pro quality on Go code.
**Impact:** Free second opinions, quick tasks, prototyping without token cost.
**Check:** Try it for a week on T1/Fix tasks.

## Priority Matrix

| # | Item | Effort | Impact | Priority |
|---|------|--------|--------|----------|
| QW-1 | Install ccost | 10 min | HIGH | **Do first** |
| QW-2 | Lasso security hooks | 30 min | MED-HIGH | **Do first** |
| SF-2 | CLAUDE.md flywheel skill | 1 session | HIGH | **Do soon** |
| SF-1 | Cost-per-feature hook | 1 session | HIGH | **Do soon** |
| SF-5 | Binary eval runner | 1-2 sessions | HIGH (compounds) | **Do soon** |
| QW-3 | Context health status | 30 min | MEDIUM | **Do soon** |
| SF-3 | TDD enforcement hook | 1 session | MED-HIGH | **Do next** |
| QW-4 | CLAUDE.md code examples | 20 min | MEDIUM | **Do next** |
| QW-5 | Hook warning mode | 30 min | MEDIUM | **Do next** |
| SF-4 | Structured handoff extraction | 1 session | MEDIUM | **Do next** |
| LI-1 | Self-improving skill pipeline | 3-5 sessions | VERY HIGH | **Plan** |
| LI-2 | Context-mode integration | 2-3 sessions | MED-HIGH | **Evaluate** |
| LI-3 | Typed agent I/O contracts | 2 sessions | MEDIUM | **Plan** |
