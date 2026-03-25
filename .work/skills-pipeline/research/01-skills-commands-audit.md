# W4: Skills & Commands Inventory Audit

**Date**: 2026-03-24
**Researcher**: researcher-01
**Status**: Complete

---

## Questions Guiding This Audit

1. **What exists?** Complete inventory of all skills and commands
2. **How are they structured?** Patterns in naming, frontmatter, organization
3. **How are they invoked?** Via Skill tool, agent prompts, or commands?
4. **What coverage gaps exist?** W4 work items vs current inventory
5. **What quality/completeness gaps exist?** Thin stubs, outdated references, missing implementations

---

## Findings

### 1. Skills Inventory (23 files, 3029 lines total)

#### Core Skills (Top-level)
| Skill | Lines | Description | Status |
|-------|-------|-------------|--------|
| `work-harness.md` | 133 | Adaptive work harness conventions — state model, triage, review gates, escalation | ✅ Complete |
| `code-quality.md` | 85 | Universal code quality anti-patterns and correctness rules | ✅ Complete |
| `workflow-meta.md` | 82 | Self-hosting skill — conventions for improving the work harness itself | ✅ Complete |
| `adversarial-eval.md` | 165 | Adversarial evaluation protocol for design decisions with trade-offs | ✅ Complete |
| `serena-activate.md` | 55 | Initialize Serena LSP tools for semantic code navigation | ✅ Complete |

#### Work-Harness Subsystem (11 reference docs + 6 implementations)
| Document | Lines | Purpose |
|----------|-------|---------|
| `step-agents.md` | 332 | Prompt templates for plan/spec/decompose agents |
| `phase-review.md` | 212 | Two-phase inter-step quality review protocol |
| `step-transition.md` | 219 | Step transition protocol, approval ceremony, state update |
| `context-seeding.md` | 139 | Context injection protocol for step agents |
| `teams-protocol.md` | 90 | Agent Teams usage and coordination |
| `task-discovery.md` | 95 | Active task detection and tier-command mapping |
| `context-docs.md` | 99 | Manifest-driven documentation injection |
| `codex-review.md` | 76 | Codex integration for optional second-opinion review |
| `references/state-conventions.md` | 172 | State.json schema and lifecycle |
| `references/gate-protocol.md` | 119 | Gate file SOP and conventions |
| `references/review-methodology.md` | 114 | Code review process, finding lifecycle, severity gates |
| `references/triage-criteria.md` | 101 | 3-factor depth assessment formula and scoring |
| `references/depth-escalation.md` | 85 | When and how to escalate between tiers |
| `references/work-log-entities.md` | 80 | Work-log MCP entity types and relations |
| `references/work-log-setup.md` | 50 | Work-log MCP server configuration guide |

#### Code-Quality Subsystem (4 reference language packs)
| Document | Lines | Purpose |
|----------|-------|---------|
| `references/go-anti-patterns.md` | 215 | Go-specific anti-patterns with examples |
| `references/security-antipatterns.md` | 123 | LLM-generated security mistakes |
| `references/parallel-review.md` | 75 | 9-agent concurrent review pattern |
| `references/ai-config-linting.md` | 113 | Claude Code config linting rules |

**Observation**: Code-quality has only ONE language pack (Go). No Python, TypeScript, Rust, etc. packs exist yet.

### 2. Commands Inventory (19 files, 3379 lines total)

#### Work Tier Commands
| Command | Lines | Tier | Invocable | Purpose |
|---------|-------|------|-----------|---------|
| `/work` | 112 | Router | ✅ Yes | Start/continue work — auto-assesses depth |
| `/work-fix` | 171 | T1 | ✅ Yes | Single-session bug fix with auto-review |
| `/work-feature` | 238 | T2 | ✅ Yes | Feature — plan, implement, review in 1-2 sessions |
| `/work-deep` | 590 | T3 | ✅ Yes | Initiative — research, plan, spec, decompose, implement, review |
| `/work-research` | 249 | R | ✅ Yes | Standalone research — investigate with synthesis |

#### State & Workflow Commands
| Command | Lines | Purpose | Status |
|---------|-------|---------|--------|
| `/work-status` | 86 | Show active task progress and suggested next action | ✅ Complete |
| `/work-checkpoint` | 141 | Save session progress for continuity | ✅ Complete |
| `/work-archive` | 197 | Archive completed task with verification | ✅ Complete |
| `/work-redirect` | 99 | Record dead end and pivot direction | ✅ Complete |
| `/work-reground` | 71 | Recover context after break or compaction | ✅ Complete |

#### Review & Quality Commands
| Command | Lines | Purpose | Status |
|---------|-------|---------|--------|
| `/work-review` | 208 | Run specialist agents and track findings | ✅ Complete |
| `/pr-prep` | 206 | Fix lint/build issues and create/update PR | ✅ Complete |
| `/adversarial-eval` | 105 | Debate design decision with opposing positions | ✅ Complete |

#### Utilities & Support
| Command | Lines | Purpose | Status |
|---------|-------|---------|--------|
| `/delegate` | 104 | Delegate sub-task to specialist agent | ✅ Complete |
| `/handoff` | 174 | Capture daily work progress to work-log | ✅ Complete |
| `/ama` | 63 | Ask anything about project — lightweight codebase Q&A | ✅ Thin |

#### Harness Admin
| Command | Lines | Purpose | Status |
|---------|-------|---------|--------|
| `/harness-init` | 266 | Initialize project for work harness | ✅ Complete |
| `/harness-doctor` | 185 | Health check — read-only validation | ✅ Complete |
| `/harness-update` | 114 | Check version compatibility | ✅ Complete |

### 3. Skill/Command Invocation Pattern

**How skills are used:**
- **Direct skill invocation** (via Skill tool): `Skill(skill: "adversarial-eval", args: "...")`
- **Skill propagation** (frontmatter): Commands and step agents use `skills: [code-quality, work-harness]` to inject knowledge into subagents
- **Auto-activation**: Work harness skills activate automatically when `.work/` exists with active tasks

**How commands are used:**
- **User invocable**: All work commands have `user_invocable: true` in frontmatter
- **Invocation method**: `/work <args>` syntax (slash commands via Skill tool)
- **No direct agent prompts**: Commands are not agent definition files; they're orchestration scripts that spawn agents

---

## Coverage Analysis: W4 Work Items vs Existing Implementation

### W4 Scope (10 items from beads epic)

| Item | Title | Current Coverage | Gap Assessment |
|------|-------|------------------|-----------------|
| a | workflow-meta proper workflow | ✅ **COMPLETE** — `claude/skills/workflow-meta.md` fully documents self-hosting conventions | None |
| b | dev update dump for Richard | ❌ **NO COVERAGE** — No "dev update" export skill/command exists | **Critical** |
| c | proactive skill updating | ⚠️ **PARTIAL** — `workflow-meta.md` documents structure; no automation for detecting stale skills or suggesting updates | **Important** |
| d | PR handling | ✅ **COVERED** — `/pr-prep` exists and handles lint/build fixes and PR creation | Minimal |
| e | skills for new tech stack | ⚠️ **PARTIAL** — Language pack infrastructure exists (`code-quality/` pattern), but only Go pack implemented | **Critical** |
| f | flush out harness skills | ⚠️ **PARTIAL** — Most work-harness subsystem documented; `/ama` is thin; some references lack examples | **Important** |
| g | dump command | ❌ **NO COVERAGE** — No general-purpose "dump" command (output harness state/config) | **Important** |
| h | deep Notion exploration | ❌ **EXTERNAL SYSTEM** — No Notion integration skill/command exists (blocked on Notion API access) | **Blocked** |
| i | language-specific anti-pattern packs | ⚠️ **PARTIAL** — Go pack exists; Python, TypeScript, Rust, C++, Java need to be added | **Critical** |
| j | agency-agents deep integration | ❌ **PARTIAL** — `teams-protocol.md` covers Agent Teams basics; deep integration patterns (RAII-like cleanup, complex coordination) underdocumented | **Important** |
| k | multi-language project support | ❌ **BLOCKED** — `harness.yaml` has `stack.language` field; no mechanism to support projects with multiple languages | **Important** |

### Summary: Coverage by Item

- **Complete (2)**: a, d
- **Partial (5)**: c, e, f, i, j
- **No Coverage (3)**: b, g, h
- **Blocked/External (1)**: h, k

---

## Quality & Completeness Gaps

### 1. Thin/Underdeveloped Stubs

| Component | Issue | Severity |
|-----------|-------|----------|
| `/ama` command | 63 lines — very lightweight; no examples of complex queries | Minor |
| `codex-review.md` | Only documents activation; no troubleshooting or examples | Minor |
| `context-docs.md` | Describes manifest-driven injection; no worked examples | Important |

### 2. Missing Language Packs

Only **Go** has an anti-patterns pack. These are needed:
- Python (Django/FastAPI/Async patterns)
- TypeScript/JavaScript (async/await, React, callback hell)
- Rust (ownership, borrowing, error handling)
- Java (checked exceptions, null safety)
- C++ (memory management, RAII)

Current status: `code-quality.md` has directive infrastructure; just missing content files.

### 3. Notion Integration (W4 Item h)

No skill/command exists. Requires:
- Notion API client setup
- Query/export patterns
- Integration with work harness state

**Blocker**: Notion API token management not defined.

### 4. Multi-Language Support (W4 Item k)

Current harness assumes **single language per project** (`stack.language` in `harness.yaml`). Projects like:
- Frontend (TypeScript) + Backend (Go) + DevOps (Terraform/Shell)
- Monorepo with multiple languages

**Gap**: No mechanism to route code-quality rules or anti-pattern selection based on file type.

### 5. Development Update Dump (W4 Item b)

No `/dev-update` or similar command. Needed for:
- Export active task summary
- Extract commits since session start
- Generate "what happened today" for stakeholder updates

**Similar to**: `/handoff`, but for human-readable output instead of work-log MCP.

### 6. General Dump Command (W4 Item g)

No `/dump` or `/status-dump` command. Useful for:
- Export full harness state (all .work/ directories)
- Show config from harness.yaml
- List active beads issues
- Output for bug reports or onboarding

---

## Structural Observations

### Frontmatter Conventions (Skills)

```yaml
---
name: <kebab-case>
description: "One-liner describing activation and purpose"
---
```

All skills use this. **No variations or inconsistencies found.**

### Frontmatter Conventions (Commands)

```yaml
---
description: "One-liner for help text"
user_invocable: true
skills: [optional, skill, list]  # Propagate to subagents
---
```

All user-invocable commands follow this. **Consistent.**

### Naming Convention

- **Skills**: Kebab-case file names, match frontmatter `name` field
- **Commands**: Kebab-case file names, correspond to slash command names
- **References**: Subdirectories under skill (`skill/references/`)

**No inconsistencies found.**

### Organization Patterns

1. **Flat list of commands** — 19 user-invocable commands at `claude/commands/`
2. **Hierarchical skills** — Core skills + work-harness subsystem (15 docs) + code-quality subsystem (5 docs)
3. **References are siblings** — Supplementary docs live in `references/` subdirectories

**Clean separation of concerns.**

---

## Implications

### 1. Critical Work Items (W4)

These blocks downstream users:
- **W4.e** (Skills for new tech stack) — Developers in Python/TypeScript/Rust hit missing anti-pattern guidance
- **W4.b** (Dev update dump) — No structured export for stakeholder updates
- **W4.i** (Language-specific packs) — Go-only, others need coverage

### 2. Architectural Constraints Discovered

- **Single-language assumption**: Current harness assumes one `stack.language` per project. Multi-language projects require refactor.
- **Skill activation is implicit**: Skills activate when `.work/` exists; no per-project opt-in/opt-out mechanism
- **No skill versioning**: Skills are bundled with harness; no way to pin versions per project or disable specific skills

### 3. Maintenance Burden

The harness now has **23 skills + 19 commands = 42 invocable units**. Adding new language packs or skills is mechanical (just add file), but:
- Command table in `workflow.md` must be manually synced
- `install.sh` file list must be manually updated
- No automated tooling to detect drift

---

## Open Questions

### Design Decisions

1. **Multi-language projects**: Should harness.yaml support `stack.languages: [go, typescript]` with per-language rules routing, or keep single-language and require separate projects?

2. **Skill opt-in**: Should projects be able to disable skills (e.g., "don't activate adversarial-eval" or "use custom code-quality rules")? Current system activates all skills unconditionally.

3. **Notion integration**: Should Notion access be:
   - Built-in to harness (requires all users have Notion token)?
   - Optional skill (activated only in projects with Notion config)?
   - External MCP server (keep harness harness-focused)?

4. **Language pack versioning**: As new Python/TypeScript/Rust packs are added, should they be versioned separately from harness releases?

### Implementation Questions

1. **Dev update dump**: Should `/dev-update <recipient>` export to:
   - Markdown file (user manually sends)?
   - Slack/Discord (requires token)?
   - Stdout for piping?
   - All of the above?

2. **Dump command**: What should `/dump` output?
   - `.work/*/state.json` (JSON tree)?
   - Human-readable summary (Markdown)?
   - Config from harness.yaml?
   - Git status?
   - All of above with selectable flags?

3. **Automation for stale skills**: How should proactive skill updating work?
   - Agent that checks files monthly?
   - Git hook that flags changes to skills when merging PRs?
   - Manual `/harness-update` extension?

### Dependency Questions

1. **Code-quality references**: Some references (go-anti-patterns, security-antipatterns) cite Go-specific or security-specific issues. Should they:
   - Stay language-neutral and build language-pack specializations?
   - Move into language packs?
   - Remain global?

2. **Work-log MCP**: Several commands and skills reference the work-log MCP server. Is it:
   - Always installed?
   - Optional?
   - Gracefully degraded if missing?

---

## Recommendations for W4 Implementation

### High Priority
1. **Implement language packs**: Python, TypeScript, Rust — minimal viable content for each
2. **Dev update dump**: `/dev-update-dump` command (simple, blocks stakeholder updates)
3. **Notion integration**: Assess Notion API feasibility; defer if API complexity too high

### Medium Priority
1. **General dump command**: `/dump` with selectable sections
2. **Skill automation**: Detect missing language packs, suggest adding them
3. **Improve thin stubs**: `/ama` and `codex-review.md` need better examples

### Lower Priority
1. **Multi-language support**: Deferred until projects need it; document current single-language assumption
2. **Skill opt-in/opt-out**: Not yet requested; can add if projects want to customize skill loading

---

## Files & Structure Summary

### Total Inventory
- **Skills**: 23 files (5 core + 6 work-harness implementations + 11 references + 4 code-quality references), 3029 lines
- **Commands**: 19 files (5 tier + 5 state + 3 review + 4 utilities + 3 admin), 3379 lines
- **Total**: 42 skill+command files, 6408 lines

### Largest Components
1. `work-deep.md` (590 lines) — Tier 3 initiative orchestration
2. `step-agents.md` (332 lines) — Agent prompt templates
3. `phase-review.md` (212 lines) — Transition review protocol
4. `go-anti-patterns.md` (215 lines) — Language pack (only one)

### Add-Missing High-Impact Files
1. `code-quality/references/python-anti-patterns.md`
2. `code-quality/references/typescript-anti-patterns.md`
3. `commands/dev-update-dump.md`
4. `commands/dump.md`
5. `skills/notion-integration.md` (if feasible)

---

## Conclusion

The harness has a **solid foundation** with comprehensive work management (5 tier commands, 10 state/review utilities) and **clear extension points** (language packs, skill propagation).

**Critical gaps** are:
- Single language pack (Go only; Python/TypeScript/Rust needed)
- No dev update export (blocks stakeholder communication)
- No multi-language support (architectural assumption)
- Notion integration undefined (blocked on feasibility)

**The infrastructure for solving these is already in place** — adding language packs is just files; dev/dump commands follow existing patterns. **W4 is primarily filling in content and small new commands, not architectural rework.**
