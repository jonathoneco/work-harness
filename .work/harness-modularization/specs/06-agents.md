# Spec 06: Agents (C4)

**Component:** C4 — Content Files: Agents
**Phase:** 2 (Core)
**Scope:** Small
**Dependencies:** C1 (repo scaffold — directories must exist), C3 (skills — agents reference skills)
**References:** [architecture.md](architecture.md) section "C4: Content Files — Agents", [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md) sections 2, 8

---

## 1. Overview

Create 4 workflow agents that the harness owns. These agents are spawned by work commands (C2) during workflow execution. They are workflow infrastructure — not domain experts. Domain expertise agents (e.g., `code-reviewer.md`, `security-reviewer.md`) come from [agency-agents](https://github.com/...) or custom project agents and are referenced by name in `harness.yaml` `review_routing`.

### Key Distinction

- **Workflow agents** (this spec): Owned by the harness. Implement workflow methodology. Installed globally.
- **Domain expertise agents** (NOT this spec): Owned by agency-agents or individual projects. Implement domain knowledge (Go patterns, security auditing, etc.). Referenced by name in `review_routing` but not shipped by the harness.

### Scope Boundaries

- **In scope:** 4 workflow agent files, skill references, project-agnostic content
- **Out of scope:** Domain expertise agents, review routing logic (that's in `work-review.md` command C2), agency-agents integration

---

## 2. Agent Inventory

| # | File | Persona | Tools | Permission Mode | Spawned By |
|---|------|---------|-------|----------------|------------|
| 1 | `work-research.md` | "Scout" — research specialist | Read, Grep, Glob, Bash (read-only), WebSearch, WebFetch | `plan` | `work-deep.md` (research step) |
| 2 | `work-review.md` | "Auditor" — post-implementation reviewer | Read, Grep, Glob, Bash (read-only) | `plan` | `work-review.md` command, tier commands (review step) |
| 3 | `work-implement.md` | "Builder" — implementation specialist | All tools (full read/write) | `acceptEdits` | `work-deep.md` (implement step), `work-feature.md` (implement step) |
| 4 | `work-spec.md` | "Architect" — specification writer | All tools (write restricted to `.work/`) | `default` | `work-deep.md` (spec step) |

---

## 3. Agent Content Specifications

### 3.1 `work-research.md` — Scout

**Purpose:** Explore, investigate, and document findings in structured format. Read-only mode — gathers information but never modifies application code.

**Must include:**
- Persona: "Scout" research specialist
- Tools allowed: Read, Grep, Glob, Bash (read-only commands only), WebSearch, WebFetch
- Tools disallowed: Edit, Write, NotebookEdit (with exception: may suggest file contents in output for the orchestrating session to write)
- Permission mode: `plan`
- Research workflow (ordered):
  1. Search closed beads first (`bd search`, `bd show`)
  2. Explore codebase (Glob, Grep for patterns, file paths, test coverage)
  3. Web research (WebSearch/WebFetch for external best practices, library docs)
  4. Trace code paths following project layering
  5. Check dependency manifests
- Output format: structured research notes with sections for Key Findings, Relevant Code (with file paths), Prior Art (from beads), Implications for Design, Open Questions
- Stop hook verification checklist: file paths are specific, findings documented, dead ends noted, open questions actionable
- **Skills reference:** `skills: [work-harness]`

**Config injection:** Include the directive from spec 00 section 8. Scout receives stack context so it can tailor research to the project's language and framework.

### 3.2 `work-review.md` — Auditor

**Purpose:** Post-implementation review. Checks for regressions, missed edge cases, pattern violations, correctness. Read-only mode.

**Must include:**
- Persona: "Auditor" review specialist
- Tools allowed: Read, Grep, Glob, Bash (read-only commands only)
- Tools disallowed: Edit, Write, NotebookEdit (reviews but does not fix)
- Permission mode: `plan`
- Review focus areas (generalized — no project-specific checklist items):
  1. Pattern compliance: code follows project conventions in CLAUDE.md
  2. Security: no SQL injection, no XSS, auth applied, no hardcoded secrets
  3. Test coverage: new functions have tests, edge cases covered
  4. Database: parameterized queries, migrations have up/down, transactions where needed
  5. Spec compliance: acceptance criteria met, interface contracts honored
- Output format: prioritized findings with severity (Critical / Important / Suggestion), each with file:line, impact, and suggested fix
- Compliance summary checklist
- Stop hook verification: all findings have severity, all have file paths, spec compliance checked, no false positives
- **Skills reference:** `skills: [code-quality, work-harness]`

**Config injection:** Include the directive from spec 00 section 8. Auditor receives stack context to calibrate review expectations.

**Parameterization note:** The current source has a "UI Correctness" review focus area with HTMX-specific items (target/container IDs, partial updates). This must be generalized to "UI/API Correctness" covering response format consistency, endpoint behavior, and request/response contracts without referencing any specific frontend framework.

### 3.3 `work-implement.md` — Builder

**Purpose:** Execute implementation specs and produce production-quality code following project patterns.

**Must include:**
- Persona: "Builder" implementation specialist
- Tools allowed: All tools (full read/write/execute access)
- Permission mode: `acceptEdits`
- Pattern guidance (generalized):
  - Follow conventions defined in project's CLAUDE.md
  - Handler/controller patterns: match existing naming and signatures
  - Service layer: constructor injection, project error handling style
  - Configuration: follow project's approach (env vars, config files, etc.)
  - Logging: use project's logging library and conventions
  - Tests: follow existing test patterns
  - When in doubt, read an existing file in the same layer and follow it
- Implementation workflow:
  1. Claim beads issue (`bd update <id> --status=in_progress`)
  2. Read context: stream doc, spec doc, existing code
  3. Implement in order per work item ordering
  4. Verify: run project verification commands after each significant change
  5. Close issue (`bd close <id>`)
  6. Sync beads (`bd sync`)
- Stop hook verification: tests pass, build succeeds, beads issue claimed, acceptance criteria met, no debug code, error handling follows conventions
- **Skills reference:** `skills: [code-quality, work-harness]`

**Config injection:** Include the directive from spec 00 section 8. Builder receives stack context to know which build/test/lint commands to run.

### 3.4 `work-spec.md` — Architect

**Purpose:** Produce detailed, implementation-ready specification documents.

**Must include:**
- Persona: "Architect" specification writer
- Tools allowed: All tools (needs to write spec files and explore codebase)
- Write path restriction: may ONLY write to `.work/*/specs/` — must NOT modify application code
- Permission mode: `default`
- Spec conventions:
  1. No YAML frontmatter — use metadata tables
  2. Source citations — trace to architecture.md sections
  3. Cross-cutting contracts in `00-cross-cutting-contracts.md`
  4. Acceptance criteria as checklists (`- [ ]` format)
  5. Codebase file path references use actual project paths
  6. Existing Code Context sections list what already exists
  7. Key Files to Create/Modify tables per spec
  8. Interface contracts: "Exposes" + "Consumes" sections
  9. Implementation prompts as final section
- Spec writing workflow:
  1. Read architecture.md thoroughly
  2. Spin up parallel Explore agents per major spec area
  3. Write `00-cross-cutting-contracts.md` first
  4. Write numbered specs in dependency order
  5. Each spec has: overview, source citations, files, dependencies, steps, acceptance criteria, interface contracts
- Stop hook verification: every spec has acceptance criteria, every spec has file paths, cross-cutting contracts doc exists, source citations present, no application code modified
- **Skills reference:** `skills: [work-harness]`

**Config injection:** Include the directive from spec 00 section 8. Architect receives stack context to write stack-aware specs.

---

## 4. Parameterization Checklist

| Reference Type | Current State | Action |
|---------------|--------------|--------|
| HTMX-specific review items | `work-review.md` has "UI Correctness" with HTMX references (target/container IDs, partial updates) | Generalize to "UI/API Correctness" covering response format consistency and request/response contracts |
| Project-specific domain terms | Already absent from all 4 agents | Verify: scan for "gaucho", "loan", "mortgage", etc. |
| Framework references | Already absent | Verify: no "chi", "pgx", "HTMX" |
| Skill references | `skills: [code-quality]` used in agents | Keep as-is — harness-owned skill name |
| Beads commands | `bd update`, `bd close`, `bd sync` | Keep as-is — beads is a hard dependency |
| `.work/` directory references | Spec-only write path restriction | Keep as-is — harness convention |
| Tool lists per agent | Already generic Claude Code tool names | Keep as-is |

---

## 5. Files to Create

All paths relative to harness repo root (`claude-work-harness/`).

| File | Action | Description |
|------|--------|-------------|
| `claude/agents/work-research.md` | Create | Scout — read-only research specialist |
| `claude/agents/work-review.md` | Create | Auditor — post-implementation reviewer |
| `claude/agents/work-implement.md` | Create | Builder — implementation specialist |
| `claude/agents/work-spec.md` | Create | Architect — specification writer |

---

## 6. Implementation Steps

### 6.1 Extract and Generalize Agent Content

- [ ] **6.1.1** Read all 4 source agents from current project's `.claude/agents/`
- [ ] **6.1.2** Scan each for project-specific references: "gaucho", "HTMX", "htmx", "loan", "borrower", "mortgage", "chi", "pgx", "Next.js"
- [ ] **6.1.3** Generalize `work-review.md` "UI Correctness" section: replace HTMX-specific items (target/container IDs, partial updates, swap attributes) with generic UI/API correctness items (response format consistency, endpoint behavior, request/response contract adherence)

### 6.2 Add Config Injection Directive

- [ ] **6.2.1** Add the config injection directive (spec 00 section 8) to each agent file, after the persona description and before the workflow section
- [ ] **6.2.2** Verify directive text matches spec 00 section 8 exactly

### 6.3 Add Skill References

- [ ] **6.3.1** `work-research.md`: add `skills: [work-harness]`
- [ ] **6.3.2** `work-review.md`: add `skills: [code-quality, work-harness]`
- [ ] **6.3.3** `work-implement.md`: add `skills: [code-quality, work-harness]`
- [ ] **6.3.4** `work-spec.md`: add `skills: [work-harness]`

### 6.4 Write Agent Files

- [ ] **6.4.1** Write all 4 files to `claude/agents/` in the harness repo
- [ ] **6.4.2** Verify file naming follows kebab-case convention (spec 00 section 2)

### 6.5 Final Verification

- [ ] **6.5.1** Grep all 4 files for project-specific terms — zero matches
- [ ] **6.5.2** Grep all 4 files for "Config injection" — 4 matches (one per file)
- [ ] **6.5.3** Verify each agent references only harness-owned skills (`work-harness`, `code-quality`)
- [ ] **6.5.4** Verify no agent references domain expertise agents by name (those are configured via `review_routing` in `harness.yaml`, not hardcoded)
- [ ] **6.5.5** Verify tool restrictions: Scout and Auditor are read-only (Edit/Write disallowed), Builder has full access, Architect writes only to `.work/*/specs/`

---

## 7. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `work-research.md` agent | `work-deep.md` command (research step) | Read-only agent, returns structured research notes |
| `work-review.md` agent | `work-review.md` command, tier commands (review step) | Read-only agent, returns prioritized findings with severity |
| `work-implement.md` agent | `work-deep.md` (implement step), `work-feature.md` (implement step) | Read/write agent, claims beads issues, produces code |
| `work-spec.md` agent | `work-deep.md` (spec step) | Write-restricted agent, produces spec files in `.work/*/specs/` |

### Consumes

| What | Provided By | Contract |
|------|------------|----------|
| `work-harness` skill (C3) | `claude/skills/work-harness.md` | Workflow methodology knowledge |
| `code-quality` skill (C3) | `claude/skills/code-quality.md` | Universal quality rules + language pack |
| `.claude/harness.yaml` | Project config | Stack context for config injection directive |
| `bd` CLI | External dependency (beads) | Issue tracking commands |
| `.work/<name>/state.json` | Created by commands at runtime | Task state for context |
| `.work/<name>/specs/` | Created by Architect agent | Spec output directory |

---

## 8. Testing Strategy

### Automated Checks

```sh
# All 4 agents exist
for agent in work-research work-review work-implement work-spec; do
  [ -f "claude/agents/${agent}.md" ] && echo "PASS: ${agent}.md" || echo "FAIL: ${agent}.md missing"
done

# All have config injection directive
for agent in claude/agents/work-*.md; do
  grep -q "Config injection" "$agent" && echo "PASS: $(basename $agent) has config injection" || echo "FAIL: $(basename $agent) missing config injection"
done

# No project-specific references
for agent in claude/agents/work-*.md; do
  if grep -qiE "gaucho|htmx|loan|borrower|mortgage|chi router|pgx|textract" "$agent"; then
    echo "FAIL: $(basename $agent) has project-specific references"
  else
    echo "PASS: $(basename $agent) clean"
  fi
done

# Skill references present
grep -q "code-quality" claude/agents/work-review.md && echo "PASS: review has code-quality skill" || echo "FAIL"
grep -q "code-quality" claude/agents/work-implement.md && echo "PASS: implement has code-quality skill" || echo "FAIL"
grep -q "work-harness" claude/agents/work-research.md && echo "PASS: research has work-harness skill" || echo "FAIL"
grep -q "work-harness" claude/agents/work-spec.md && echo "PASS: spec has work-harness skill" || echo "FAIL"

# Read-only agents don't allow Edit/Write
for agent in work-research work-review; do
  grep -q "Edit.*Write.*NotebookEdit" "claude/agents/${agent}.md" && echo "PASS: ${agent} disallows writes" || echo "WARN: ${agent} check write restriction manually"
done
```

### Manual Verification

- Spawn each agent in a test session and verify it receives stack context from `harness.yaml`
- Verify Scout cannot write files (read-only enforcement)
- Verify Auditor cannot write files
- Verify Architect can write to `.work/*/specs/` but refuses to modify application code
- Verify Builder has full tool access

---

## 9. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| Agent spawned in project without `harness.yaml` | Config injection directive skips — agent operates without stack context |
| `work-review.md` agent vs `work-review.md` command (same name in different directories) | No conflict — commands are in `commands/`, agents in `agents/`. Claude Code distinguishes by invocation method |
| Agent references a skill not installed | Claude Code warns about missing skill — `/harness-doctor` (C13) also checks this |
| Architect agent tries to write outside `.work/*/specs/` | Agent definition restricts write paths — Claude Code may not enforce this mechanically, but the agent text instructs the LLM to refuse |
| Builder agent invoked without a beads issue claimed | Agent workflow starts with "Claim beads issue" — if no issue exists, agent should create one first (per beads-workflow rules) |

---

## 10. Acceptance Criteria

1. - [ ] All 4 agent files exist at `claude/agents/work-<name>.md`
2. - [ ] Each agent has a clear persona name and description
3. - [ ] Each agent specifies allowed/disallowed tools
4. - [ ] Each agent specifies a permission mode (`plan`, `acceptEdits`, or `default`)
5. - [ ] Each agent includes the config injection directive from spec 00 section 8
6. - [ ] Each agent references at least one harness-owned skill (`work-harness` and/or `code-quality`)
7. - [ ] Zero project-specific references: no "gaucho", "HTMX", "loan", "borrower", "mortgage", "chi", "pgx"
8. - [ ] `work-review.md` review focus areas are generalized (no HTMX-specific items)
9. - [ ] `work-research.md` and `work-review.md` are read-only (Edit/Write explicitly disallowed)
10. - [ ] `work-spec.md` restricts writes to `.work/*/specs/` only
11. - [ ] No agent hardcodes domain expertise agent names (those come from `review_routing`)
12. - [ ] File naming follows kebab-case convention per spec 00 section 2
