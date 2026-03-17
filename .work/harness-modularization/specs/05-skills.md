# Spec 05: Skills (C3)

**Component:** C3 — Content Files: Skills
**Phase:** 2 (Core)
**Scope:** Medium
**Dependencies:** C1 (repo scaffold — directories must exist)
**References:** [architecture.md](architecture.md) section "C3: Content Files — Skills", [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md) sections 4, 8

---

## 1. Overview

Create 4 skill files and 1 language pack reference file for the harness. Skills are markdown files that Claude Code loads to provide domain knowledge to agents and the main session. They live at `claude/skills/` in the harness repo and get installed to `~/.claude/skills/`.

The key design decision (architecture.md Q3 resolution) is **directive-based language selection**: `code-quality.md` contains universal quality principles and includes a directive to read `references/<language>-anti-patterns.md` where `<language>` comes from `harness.yaml`. The language pack files ship in `skills/code-quality/references/`. Only `go-anti-patterns.md` ships in v1; others are added as single files later.

### Scope Boundaries

- **In scope:** 4 skill files, 1 language pack file (`go-anti-patterns.md`), directory structure
- **Out of scope:** Future language packs (python, typescript, rust), domain-specific skills

---

## 2. Skill Inventory

| # | File | Purpose | Used By |
|---|------|---------|---------|
| 1 | `work-harness.md` | Workflow conventions, state management rules, tier system, step lifecycle | All workflow commands, all workflow agents |
| 2 | `code-quality.md` | Universal code quality principles + language pack directive | Review agents, implement agent, any agent with `skills: [code-quality]` |
| 3 | `workflow-meta.md` | Self-hosting: conventions for improving the harness itself | Agents working on harness repo (self-referential) |
| 4 | `serena-activate.md` | LSP integration via Serena MCP tools | SessionStart hook, post-compaction recovery |

### Language Pack

| File | Path | Ships in v1 |
|------|------|:-----------:|
| `go-anti-patterns.md` | `claude/skills/code-quality/references/go-anti-patterns.md` | Yes |
| `python-anti-patterns.md` | `claude/skills/code-quality/references/python-anti-patterns.md` | No (future) |
| `typescript-anti-patterns.md` | `claude/skills/code-quality/references/typescript-anti-patterns.md` | No (future) |
| `rust-anti-patterns.md` | `claude/skills/code-quality/references/rust-anti-patterns.md` | No (future) |

---

## 3. Skill Content Specifications

### 3.1 `work-harness.md`

**Purpose:** Teach Claude Code sessions and agents the workflow methodology.

**Must cover:**
- 3-tier system (Fix T1, Feature T2, Initiative T3) with step definitions per tier
- State management: `.work/<name>/state.json` schema and lifecycle
- Step transitions: Phase A (automated checks) + Phase B (quality review) + user gate
- Handoff prompt convention: summaries for session continuity, never re-read raw research
- Beads integration: every task has an issue, Tier 3 tasks have epics
- Finding lifecycle: JSONL format, severity levels, triage states
- Checkpoint and reground patterns
- Context compaction protocol: what to re-read after `/compact`

**Must NOT contain:**
- Project-specific examples (no "gaucho", no domain terms)
- Config values (those come from `harness.yaml` at runtime)
- Duplicate of command logic (commands define behavior; skill defines concepts)

### 3.2 `code-quality.md`

**Purpose:** Universal code quality principles that apply to any codebase, plus a directive to load language-specific anti-patterns.

**Must contain these universal rules:**
1. Fail closed, never fail open — missing config/secrets = hard error, not fallback
2. Never swallow errors — every error return must be checked
3. Never fabricate data — no synthetic defaults on failure paths
4. Always handle both branches — `if err == nil` must have an `else`
5. Constructor injection only — no setter injection or post-construction callbacks
6. Return complete results — analyze all inputs, not just the first match
7. No divergent interface copies — same-name interfaces must not diverge
8. No shims or backward compatibility — no migration fallbacks unless explicitly requested

**Must contain the language pack directive (exact text):**

```markdown
## Language-Specific Anti-Patterns

Read `references/<language>-anti-patterns.md` where `<language>` is `stack.language`
from `.claude/harness.yaml`. If no `harness.yaml` exists or `stack.language` is `other`,
skip this section.
```

**Must NOT contain:**
- Go-specific examples in the main body (those belong in the language pack)
- Project-specific references
- Framework-specific patterns

### 3.3 `workflow-meta.md`

**Purpose:** Self-hosting skill for when the harness is used to improve itself.

**Must cover:**
- The harness repo is itself a project that uses the harness
- Conventions for modifying commands, skills, agents, rules, hooks
- Testing changes: install locally, verify in a test project
- Version bumping protocol (when to increment MAJOR/MINOR/PATCH)
- How to add a new language pack (create one file, no other changes needed)
- How to add a new hook (create script, add registration to install.sh)

**Must NOT contain:**
- References to any specific project other than the harness itself

### 3.4 `serena-activate.md`

**Purpose:** Activate Serena MCP tools for LSP-backed code navigation.

**Must cover:**
- Activation command: `mcp__serena__activate_project`
- Tool preference table: when to use Serena vs built-in tools (find_symbol vs Grep, get_symbols_overview vs Read, etc.)
- Re-activation after context compaction
- Graceful degradation: if Serena is not available, fall back to built-in tools without error

**Must NOT contain:**
- Project-specific file paths or symbol names

---

## 4. Language Pack: `go-anti-patterns.md`

**Source:** Extract from the current project's code quality enforcement patterns.

**Must contain Go-specific anti-patterns with code examples:**
- Swallowed errors (`_, _ =`)
- Unchecked database exec (`_ = db.Exec(...)`)
- Missing error wrapping (`return err` instead of `fmt.Errorf("context: %w", err)`)
- Nil pointer dereference without check
- Goroutine leak patterns (unbuffered channel, no context cancellation)
- `init()` function abuse
- Interface pollution (declaring interfaces in the implementer package)
- `panic` in library code
- Bare `fmt.Println` instead of structured logging (`slog`)

**Format:** Each anti-pattern has:
1. Name/title
2. Bad example (code block with `// BAD` comment)
3. Good example (code block with `// GOOD` comment)
4. Why it matters (1-2 sentences)

---

## 5. Parameterization Checklist

| Reference Type | Current State | Action |
|---------------|--------------|--------|
| Go-specific rules in code-quality | Currently mixed into universal rules | Separate: universals in `code-quality.md`, Go patterns in `go-anti-patterns.md` |
| Project-specific examples | None expected in skill content | Verify: scan for "gaucho", "loan", domain terms |
| Hardcoded language references | `code-quality.md` currently assumes Go | Replace with language pack directive |
| Serena tool names | Already generic MCP tool names | Keep as-is |
| `.work/` conventions | Already generic | Keep as-is |
| Beads references | Already generic CLI commands | Keep as-is |

---

## 6. Files to Create

All paths relative to harness repo root (`claude-work-harness/`).

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness.md` | Create | Workflow methodology conventions |
| `claude/skills/code-quality.md` | Create | Universal quality rules + language pack directive |
| `claude/skills/workflow-meta.md` | Create | Self-hosting conventions |
| `claude/skills/serena-activate.md` | Create | Serena LSP activation |
| `claude/skills/code-quality/references/go-anti-patterns.md` | Create | Go-specific anti-pattern catalog |

---

## 7. Implementation Steps

### 7.1 Write `work-harness.md`

- [ ] **7.1.1** Draft skill content covering all items in section 3.1
- [ ] **7.1.2** Verify no project-specific references
- [ ] **7.1.3** Verify no overlap with command logic (skill teaches concepts, commands define behavior)
- [ ] **7.1.4** Write file to `claude/skills/work-harness.md`

### 7.2 Write `code-quality.md`

- [ ] **7.2.1** Write the 8 universal quality rules with brief explanations (no language-specific code examples)
- [ ] **7.2.2** Include the language pack directive verbatim from section 3.2
- [ ] **7.2.3** Verify no Go-specific content appears in the main body
- [ ] **7.2.4** Write file to `claude/skills/code-quality.md`

### 7.3 Write `go-anti-patterns.md`

- [ ] **7.3.1** Extract Go-specific anti-patterns from current project's code quality rules
- [ ] **7.3.2** Format each with name, bad example, good example, rationale
- [ ] **7.3.3** Remove any project-specific context (no gaucho domain references in examples)
- [ ] **7.3.4** Write file to `claude/skills/code-quality/references/go-anti-patterns.md`

### 7.4 Write `workflow-meta.md`

- [ ] **7.4.1** Draft self-hosting conventions per section 3.3
- [ ] **7.4.2** Verify only references the harness repo itself, no other projects
- [ ] **7.4.3** Write file to `claude/skills/workflow-meta.md`

### 7.5 Write `serena-activate.md`

- [ ] **7.5.1** Draft Serena activation content per section 3.4
- [ ] **7.5.2** Verify graceful degradation language is present
- [ ] **7.5.3** Write file to `claude/skills/serena-activate.md`

### 7.6 Final Verification

- [ ] **7.6.1** Grep all skill files for project-specific terms — zero matches
- [ ] **7.6.2** Verify `code-quality.md` contains the language pack directive
- [ ] **7.6.3** Verify `go-anti-patterns.md` contains only Go-specific content (no universal rules repeated)
- [ ] **7.6.4** Verify directory structure: `claude/skills/code-quality/references/` exists with `go-anti-patterns.md`
- [ ] **7.6.5** Verify all file names follow kebab-case convention (spec 00 section 2)

---

## 8. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `work-harness.md` skill | Commands (C2) via `skills: [work-harness]` in agent spawns; agents (C4) | Markdown skill file, teaches workflow methodology |
| `code-quality.md` skill | Commands (C2) via `skills: [code-quality]` in agent spawns; agents (C4) | Markdown skill file, universal rules + language pack directive |
| `workflow-meta.md` skill | Self-hosting sessions working on harness repo | Markdown skill file, harness development conventions |
| `serena-activate.md` skill | SessionStart hook, post-compaction hooks | Markdown skill file, LSP tool activation |
| `go-anti-patterns.md` reference | `code-quality.md` directive (when `stack.language` is `go`) | Markdown file with Go anti-pattern catalog |
| Language pack directory contract | Future language packs | File at `references/<language>-anti-patterns.md` — adding a language is a single file addition |

### Consumes

| What | Provided By | Contract |
|------|------------|----------|
| `.claude/harness.yaml` | Project (created by C11 harness-init) | `code-quality.md` directive reads `stack.language` to select language pack |
| `references/<language>-anti-patterns.md` | Self (language packs in same skill directory) | File must exist for the configured language; `other` skips the directive |

---

## 9. Testing Strategy

### Automated Checks

```sh
# All 4 skills + 1 language pack exist
for skill in work-harness code-quality workflow-meta serena-activate; do
  [ -f "claude/skills/${skill}.md" ] && echo "PASS: ${skill}.md" || echo "FAIL: ${skill}.md missing"
done
[ -f "claude/skills/code-quality/references/go-anti-patterns.md" ] \
  && echo "PASS: go-anti-patterns.md" || echo "FAIL: go-anti-patterns.md missing"

# code-quality.md has language pack directive
grep -q "references/<language>-anti-patterns.md" claude/skills/code-quality.md \
  && echo "PASS: language pack directive" || echo "FAIL: missing language pack directive"

# No project-specific references
for f in claude/skills/*.md claude/skills/code-quality/references/*.md; do
  if grep -qiE "gaucho|htmx|loan|borrower|mortgage" "$f"; then
    echo "FAIL: $(basename $f) has project-specific references"
  else
    echo "PASS: $(basename $f) clean"
  fi
done

# go-anti-patterns.md has code examples
grep -c '```go' claude/skills/code-quality/references/go-anti-patterns.md | \
  xargs -I{} sh -c '[ {} -gt 0 ] && echo "PASS: go examples present ({})" || echo "FAIL: no go examples"'
```

### Manual Verification

- In a Go project with `harness.yaml`, trigger `code-quality` skill and verify it reads `go-anti-patterns.md`
- In a Python project with `stack.language: python` and no `python-anti-patterns.md` yet, verify the skill gracefully skips the language pack
- In a project without `harness.yaml`, verify `code-quality` skill skips the language pack directive entirely

---

## 10. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| `stack.language` is `other` | Language pack directive says to skip — no file lookup attempted |
| `stack.language` is `python` but no `python-anti-patterns.md` exists | Claude notes the file doesn't exist; universal rules still apply |
| No `harness.yaml` in project | Language pack directive self-gates: "If no `harness.yaml` exists... skip this section" |
| Serena MCP not installed | `serena-activate.md` specifies graceful degradation to built-in tools |
| `workflow-meta.md` loaded outside harness repo | Skill content is about harness development — not harmful if loaded elsewhere, just irrelevant |

---

## 11. Acceptance Criteria

1. - [ ] All 4 skill files exist at `claude/skills/<name>.md`
2. - [ ] `go-anti-patterns.md` exists at `claude/skills/code-quality/references/go-anti-patterns.md`
3. - [ ] `code-quality.md` contains the language pack directive: "Read `references/<language>-anti-patterns.md` where `<language>` is `stack.language` from `.claude/harness.yaml`"
4. - [ ] `code-quality.md` contains all 8 universal quality rules (listed in section 3.2)
5. - [ ] `code-quality.md` contains NO Go-specific code examples in its main body
6. - [ ] `go-anti-patterns.md` contains Go-specific anti-patterns with bad/good code examples
7. - [ ] Zero project-specific references across all files: no "gaucho", "HTMX", "loan", "borrower", "mortgage", "chi", "pgx"
8. - [ ] `work-harness.md` covers: tier system, state management, step transitions, handoff prompts, beads integration, finding lifecycle
9. - [ ] `serena-activate.md` includes graceful degradation for when Serena is unavailable
10. - [ ] File naming follows kebab-case convention per spec 00 section 2
11. - [ ] Adding a new language pack requires only creating one file (`references/<language>-anti-patterns.md`) — no changes to `code-quality.md` or any other file
