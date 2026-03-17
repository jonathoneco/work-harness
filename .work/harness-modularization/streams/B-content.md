# Stream B: Content

**Phase:** 2 (runs after Phase 1 — Stream A must complete)
**Work Items:** W-04 (rag-um0k7), W-05 (rag-6plf9), W-06 (rag-fs6ap), W-07 (rag-7ypmv)
**Execution Order:** All parallel within stream (no inter-dependencies)
**Dependencies:** W-01 (scaffold exists)

---

## Overview

This stream creates all content files: commands, skills, agents, and rules. These are markdown files that get copied to `~/.claude/` on install. They have no code dependencies on each other — just need the directory structure from W-01.

**Source material:** Current files in `gaucho/.claude/` and `dotfiles/home/.claude/` — parameterize by removing hard-coded Go/HTMX references and adding config injection directives.

---

## W-04: Work Commands (10 commands) — spec 04

**Issue:** rag-um0k7
**Spec:** `.work/harness-modularization/specs/04-commands.md`

### Files to Create

```
claude/commands/
  work.md
  work-deep.md
  work-fix.md
  work-feature.md
  work-review.md
  work-status.md
  work-checkpoint.md
  work-reground.md
  work-redirect.md
  work-archive.md
```

### Key Requirements

- Each command includes the **config injection directive** (spec 00 §8):
  > If `.claude/harness.yaml` exists in the current project directory, read it and include a "Project Stack Context" section (language, framework, database, build commands) in all subagent prompts and handoff prompts you produce.
- Remove hard-coded references to Go, HTMX, chi, pgx — replace with config-driven references
- Preserve all functional behavior from current commands
- Commands reference skills by name (e.g., `skills: [work-harness, code-quality]`)

### Parameterization Checklist (per spec 04)

For each command, verify:
- [ ] No hard-coded language references (Go, Python, etc.)
- [ ] No hard-coded framework references (chi, HTMX, etc.)
- [ ] Config injection directive present
- [ ] Skill references use generic names
- [ ] Agent references use generic names
- [ ] Build/test/lint commands read from config, not hard-coded

### Acceptance Criteria

1. All 10 command files exist in `claude/commands/`
2. Each includes config injection directive
3. No hard-coded technology references remain
4. Commands are functionally equivalent to current versions
5. Skill and agent references use generic harness names

### On Completion

```bash
bd close rag-um0k7 --reason="10 work commands parameterized with config injection directive"
```

---

## W-05: Skills + Language Packs — spec 05

**Issue:** rag-6plf9
**Spec:** `.work/harness-modularization/specs/05-skills.md`

### Files to Create

```
claude/skills/
  work-harness.md
  code-quality.md
  dev-env.md
  workflow-meta.md
  code-quality/references/
    go-anti-patterns.md
```

### Key Requirements

- `work-harness.md`: Adaptive work harness conventions — state model, triage, review gates
- `code-quality.md`: Anti-pattern rules with config-driven language pack selection
  - Includes directive: "If harness.yaml exists, load `references/<language>-anti-patterns.md` for language-specific patterns"
- `dev-env.md`: Dev environment dependency awareness
- `workflow-meta.md`: Iterate on harness infrastructure
- `go-anti-patterns.md`: Go-specific anti-patterns (error swallowing, fabricated data, etc.)
- Language pack extensibility: document how to add `python-anti-patterns.md`, `typescript-anti-patterns.md`, etc.

### Acceptance Criteria

1. All 4 skill files exist
2. go-anti-patterns.md language pack exists in references/
3. code-quality.md references language packs via config directive
4. No hard-coded technology references in skill descriptions
5. Language pack extensibility contract documented

### On Completion

```bash
bd close rag-6plf9 --reason="4 skills + go language pack created with extensibility contract"
```

---

## W-06: Workflow Agents (4 agents) — spec 06

**Issue:** rag-fs6ap
**Spec:** `.work/harness-modularization/specs/06-agents.md`

### Files to Create

```
claude/agents/
  work-research.md
  work-review.md
  work-implement.md
  work-spec.md
```

### Key Requirements

- Each agent has: description, tool restrictions, permission mode, skill references
- `work-review.md`: Review agent with `skills: [code-quality]`, read-only tools
- `work-implement.md`: Implementation agent with `skills: [work-harness, code-quality]`, full tool access
- `work-research.md`: Research agent with `skills: [work-harness, code-quality]`, read-only tools
- `work-spec.md`: Spec writing agent with `skills: [code-quality]`, read-only tools
- HTMX references generalized to "UI/API Correctness" pattern
- No hard-coded technology stack references

### Acceptance Criteria

1. All 4 agent files exist
2. Each has tool restrictions and permission mode defined
3. Skill references are correct per agent type
4. No hard-coded Go/HTMX references
5. Review agent is read-only

### On Completion

```bash
bd close rag-fs6ap --reason="4 workflow agents created with tool restrictions and skill refs"
```

---

## W-07: Rules (2 rules) — spec 07

**Issue:** rag-7ypmv
**Spec:** `.work/harness-modularization/specs/07-rules.md`

### Files to Create

```
claude/rules/
  workflow.md
  workflow-detect.md
```

### Key Requirements

- `workflow.md`: Command table listing all available work commands (must match C2 command set)
  - **Sync contract**: This table MUST stay synchronized with `claude/commands/` contents
  - Key principles section (context via files, handoff prompts as firewall, 3 tiers, beads integration)
- `workflow-detect.md`: Active task detection at session start
  - Scan `.work/*/state.json` for active tasks
  - Display notification with task name, tier, current step

### Acceptance Criteria

1. Both rule files exist
2. workflow.md command table matches the 10 commands from W-04
3. workflow-detect.md detection logic is complete
4. No hard-coded technology references
5. Sync contract between workflow.md and commands is documented

### On Completion

```bash
bd close rag-7ypmv --reason="2 rules created with command sync contract"
```
