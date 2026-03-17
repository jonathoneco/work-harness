# Spec 04: Commands (C2)

**Component:** C2 — Content Files: Commands
**Phase:** 2 (Core)
**Scope:** Medium (extract + parameterize)
**Dependencies:** C1 (repo scaffold — directories must exist)
**References:** [architecture.md](architecture.md) section "C2: Content Files — Commands", [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md) section 8

---

## 1. Overview

Extract 10 workflow commands from their current project-embedded locations into the harness repo at `claude/commands/`. Each command is a markdown file interpreted by Claude Code at invocation time. Commands must be project-agnostic: no references to specific projects, frameworks, or domain concepts. Commands that spawn subagents or produce handoff prompts must include the config injection directive (spec 00 section 8) so that project-specific stack context flows into subagent prompts at runtime.

### Scope Boundaries

- **In scope:** 10 work commands, config injection directives, removal of project-specific references
- **Out of scope:** `harness-init.md`, `harness-update.md`, `harness-doctor.md` (those are C11-C13, separate specs), project-specific commands like `ama.md` or `adversarial-eval.md`

---

## 2. Command Inventory

| # | File | Description | Spawns Subagents | Produces Handoff Prompts |
|---|------|-------------|:---:|:---:|
| 1 | `work.md` | Auto-assess task depth and route to tier | Yes (delegates to tier commands) | Yes |
| 2 | `work-deep.md` | Multi-session initiative (Tier 3) | Yes (research, plan, spec, review agents) | Yes (step transitions) |
| 3 | `work-feature.md` | Feature build in 1-2 sessions (Tier 2) | Yes (review agent) | Yes (step transitions) |
| 4 | `work-fix.md` | Single-session bug fix (Tier 1) | Yes (review agent) | Yes (auto-archive) |
| 5 | `work-review.md` | Specialist review agents + finding tracking | Yes (review routing agents) | No |
| 6 | `work-checkpoint.md` | Save progress for session continuity | No | Yes (checkpoint file) |
| 7 | `work-reground.md` | Recover context after break/compaction | No | No (read-only) |
| 8 | `work-redirect.md` | Record dead end and pivot | No | Yes (redirect record) |
| 9 | `work-status.md` | Show active task progress | No | No (read-only) |
| 10 | `work-archive.md` | Verify completion and archive | No | No |

---

## 3. Config Injection Directive

Every command file must include this directive block verbatim, placed immediately after the YAML frontmatter and title heading (before Step 1). This is the standard from spec 00 section 8:

```markdown
**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.
```

### Placement

For commands that spawn subagents (work, work-deep, work-feature, work-fix, work-review), the directive appears right after the description paragraph. For commands that only produce handoff prompts (work-checkpoint, work-redirect), it appears in the same location. For read-only commands (work-reground, work-status, work-archive), it still appears — the directive self-gates on "if you produce subagent prompts or handoff prompts," so it's a no-op for read-only commands but provides consistency.

**Rationale for universal inclusion:** All 10 commands get the directive rather than only the 7 that need it. This avoids a maintenance trap where a command later gains handoff capability but the implementer forgets to add the directive. The directive is self-gating — it only activates when the command actually produces qualifying output.

---

## 4. Parameterization Checklist

What must be generalized (project-specific references to remove):

| Reference Type | Current State | Action |
|---------------|--------------|--------|
| Project-specific domain terms | Already absent from work commands | Verify: no "gaucho", "loan", "mortgage", "borrower" |
| Framework references | Already absent | Verify: no "chi", "pgx", "HTMX", "Next.js" |
| Hardcoded file paths | `.claude/rules/architecture-decisions.md` referenced in work-deep.md | Keep as-is — this is a harness-init template path, not project-specific |
| Hardcoded file paths | `.claude/rules/code-quality.md` referenced in work-deep.md | Keep as-is — this is a harness-managed rule |
| Hardcoded file paths | `.claude/rules/beads-workflow.md` referenced in work-deep.md | Keep as-is — this is a harness-init template |
| Skill references | `skills: [code-quality]` in agent spawn directives | Keep as-is — harness-owned skill name |
| Beads commands | `bd show`, `bd close`, `bd update` | Keep as-is — beads is a hard dependency |
| `.work/` directory structure | Used throughout | Keep as-is — harness convention |
| `docs/feature/` summary files | Referenced in work-deep.md | Keep as-is — harness convention |
| `docs/futures/` future ideas | Referenced in work-archive.md | Keep as-is — harness convention |
| `.claude/tech-deps.yml` | Referenced in work-archive.md for tech manifest scan | Keep as-is — harness convention for dependency tracking |

**Assessment:** The existing work commands are already largely project-agnostic. The primary extraction work is: (1) adding the config injection directive to each, (2) verifying no project-specific references crept in, (3) adding YAML frontmatter if missing.

---

## 5. Files to Create

All paths relative to harness repo root (`claude-work-harness/`).

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work.md` | Create | Auto-assess and route — extracted from source |
| `claude/commands/work-deep.md` | Create | Tier 3 initiative — extracted from source |
| `claude/commands/work-feature.md` | Create | Tier 2 feature — extracted from source |
| `claude/commands/work-fix.md` | Create | Tier 1 fix — extracted from source |
| `claude/commands/work-review.md` | Create | Review with specialist agents — extracted from source |
| `claude/commands/work-checkpoint.md` | Create | Session checkpoint — extracted from source |
| `claude/commands/work-reground.md` | Create | Context recovery — extracted from source |
| `claude/commands/work-redirect.md` | Create | Dead end pivot — extracted from source |
| `claude/commands/work-status.md` | Create | Status display — extracted from source |
| `claude/commands/work-archive.md` | Create | Task archive — extracted from source |

---

## 6. Implementation Steps

### 6.1 Extract and Verify Source Content

- [ ] **6.1.1** Read all 10 source commands from the current project's `.claude/commands/` directory
- [ ] **6.1.2** For each command, scan for project-specific references: search for "gaucho", "HTMX", "htmx", "loan", "borrower", "mortgage", "chi", "pgx", "Textract", "Bedrock", "Next.js", "WorkOS"
- [ ] **6.1.3** Document any project-specific references found (expected: none based on pre-analysis)

### 6.2 Add Config Injection Directive

- [ ] **6.2.1** For each of the 10 commands, insert the config injection directive block (section 3 above) immediately after the title heading and description paragraph, before Step 1
- [ ] **6.2.2** Verify directive text matches spec 00 section 8 exactly (word-for-word)

### 6.3 Verify YAML Frontmatter

- [ ] **6.3.1** Each command must have YAML frontmatter with `description` and `user_invocable: true`
- [ ] **6.3.2** Verify existing frontmatter is preserved; add if missing

### 6.4 Write Command Files

- [ ] **6.4.1** Write all 10 files to `claude/commands/` in the harness repo
- [ ] **6.4.2** Verify file naming matches kebab-case convention (spec 00 section 2)

### 6.5 Final Verification

- [ ] **6.5.1** Grep all 10 files for project-specific terms (section 6.1.2 list) — zero matches expected
- [ ] **6.5.2** Grep all 10 files for "Config injection" — 10 matches expected (one per file)
- [ ] **6.5.3** Verify all 10 files have YAML frontmatter with `user_invocable: true`
- [ ] **6.5.4** Verify no files reference skills, agents, or rules that don't exist in the harness (cross-check against C3, C4, C5 file lists)

---

## 7. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| 10 command files in `claude/commands/` | C7 (install.sh copies to `~/.claude/commands/`) | Valid Claude Code command format: YAML frontmatter + markdown body |
| `/work` entry point | Users, `workflow.md` rule (C5) | Auto-assess and route; reads `.work/` for state |
| `/work-deep`, `/work-feature`, `/work-fix` | `/work` command (delegates after tier assessment) | Tier-specific workflow; each reads `state.json` |
| `/work-review` | `/work-deep`, `/work-feature`, `/work-fix` (invoked during review step) | Reads `review_routing` from `harness.yaml` if present |
| `/work-checkpoint`, `/work-reground`, `/work-redirect`, `/work-status`, `/work-archive` | Users (direct invocation) | Utility commands operating on `.work/` state |

### Consumes

| What | Provided By | Contract |
|------|------------|----------|
| `.claude/harness.yaml` | Project (created by C11 harness-init) | Optional. If present, config injection reads stack context. If absent, directive is skipped. |
| `.work/<name>/state.json` | Created by work commands at runtime | Task state: tier, current_step, steps array, issue_id, timestamps |
| `bd` CLI | External dependency (beads) | Issue tracking: `bd show`, `bd update`, `bd close`, `bd create` |
| Workflow agents (C4) | `claude/agents/` | `work-review.md` spawns review agents; tier commands may spawn `work-research.md`, `work-implement.md` |
| Skills (C3) | `claude/skills/` | Commands reference `skills: [code-quality, work-harness]` in agent spawn directives |
| `review_routing` config | `harness.yaml` | `work-review.md` reads routing to determine which agents to spawn per file pattern |

---

## 8. Testing Strategy

Commands are markdown files — no unit tests. Verification is structural:

### Automated Checks (run by implementer)

```sh
# All 10 commands exist
for cmd in work work-deep work-feature work-fix work-review work-checkpoint work-reground work-redirect work-status work-archive; do
  [ -f "claude/commands/${cmd}.md" ] && echo "PASS: ${cmd}.md" || echo "FAIL: ${cmd}.md missing"
done

# All have config injection directive
for cmd in claude/commands/work*.md; do
  grep -q "Config injection" "$cmd" && echo "PASS: $(basename $cmd) has config injection" || echo "FAIL: $(basename $cmd) missing config injection"
done

# All have YAML frontmatter
for cmd in claude/commands/work*.md; do
  head -1 "$cmd" | grep -q "^---" && echo "PASS: $(basename $cmd) has frontmatter" || echo "FAIL: $(basename $cmd) missing frontmatter"
done

# No project-specific references
for cmd in claude/commands/work*.md; do
  if grep -qiE "gaucho|htmx|loan|borrower|mortgage|chi router|pgx|textract|workos" "$cmd"; then
    echo "FAIL: $(basename $cmd) has project-specific references"
  else
    echo "PASS: $(basename $cmd) clean"
  fi
done
```

### Manual Verification

- Install harness, run `/work` in a test project with `harness.yaml` — verify config injection produces "Project Stack Context" in subagent prompts
- Run `/work` in a project without `harness.yaml` — verify no config injection section appears, no errors
- Run each of the 10 commands and verify they reference only harness-owned paths (`.work/`, `docs/feature/`, `.claude/harness.yaml`)

---

## 9. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| Command invoked in project without `harness.yaml` | Config injection directive self-gates: "If `.claude/harness.yaml` exists" — omits preamble silently |
| Command invoked in project with malformed `harness.yaml` | Claude reads the file and gets parse issues — no shell script involved, so no exit code. Claude should note the parse failure in its response. |
| `work-review` invoked with no `review_routing` in config | Falls back to reviewing all changed files without agent routing — the command already handles this case |
| Multiple active tasks | Commands already handle this: present list, ask user to choose |
| No `.work/` directory | Commands already handle this: create it on first task |

---

## 10. Acceptance Criteria

1. - [ ] All 10 command files exist at `claude/commands/<name>.md`
2. - [ ] Each command has YAML frontmatter with `description` and `user_invocable: true`
3. - [ ] Each command contains the config injection directive from spec 00 section 8
4. - [ ] Zero project-specific references: no "gaucho", "HTMX", "loan", "borrower", "mortgage", "chi", "pgx", "Textract", "WorkOS"
5. - [ ] Commands that spawn subagents reference only harness-owned agents (`work-research`, `work-review`, `work-implement`, `work-spec`)
6. - [ ] Commands that reference skills use only harness-owned skill names (`code-quality`, `work-harness`)
7. - [ ] Commands that reference rules use only harness-managed rule paths (`architecture-decisions.md`, `code-quality.md`, `beads-workflow.md`)
8. - [ ] File naming follows kebab-case convention per spec 00 section 2
9. - [ ] Config injection directive text is identical across all 10 files (copy-paste consistency)
10. - [ ] `work-review.md` reads `review_routing` from `harness.yaml` for agent selection
