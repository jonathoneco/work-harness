# Spec 07: Rules (C5)

**Component:** C5 — Content Files: Rules
**Phase:** 2 (Core)
**Scope:** Small
**Dependencies:** C1 (repo scaffold — directories must exist), C2 (commands — referenced by `workflow.md`)
**References:** [architecture.md](architecture.md) section "C5: Content Files — Rules", [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md) section 2

---

## 1. Overview

Create 2 rule files that Claude Code loads automatically at session start. Rules are persistent context — unlike commands (invoked explicitly) or skills (loaded by agent prompts), rules are always active for every session in every project where they're installed. These rules provide the ambient workflow context that makes the harness discoverable and enforces session discipline.

The two rules serve complementary purposes:
- **`workflow.md`** — Convention reference: tells Claude Code about available commands, principles, and expected behavior patterns. This is the "manual" that's always loaded.
- **`workflow-detect.md`** — Session start behavior: detects active tasks and prompts the user to reground. This is the "autorun" that fires at session start.

### Scope Boundaries

- **In scope:** 2 rule files, command reference table, detection logic
- **Out of scope:** `beads-workflow.md` (project-level rule created by C11 harness-init, not shipped globally), `architecture-decisions.md` (project-level rule, optional scaffold from harness-init), `code-quality.md` rule (this is a skill in C3, not a rule)

### Why Rules vs Skills

Rules are loaded unconditionally by Claude Code for every session. Skills are loaded selectively by agent prompts (`skills: [name]`). These two files need unconditional loading because:
- `workflow.md` must always be available so Claude knows about `/work` commands without the user having to activate anything
- `workflow-detect.md` must fire at session start to detect active tasks — it can't wait for explicit activation

---

## 2. Rule Content Specifications

### 2.1 `workflow.md` — Harness Conventions and Command Reference

**Purpose:** Persistent context that teaches Claude Code about the work harness methodology. Loaded for every session so commands are always discoverable.

**Must include:**

#### Command Reference Table
All 10 work commands with description. This table must match the commands shipped in C2 exactly:

```markdown
| Command | Purpose |
|---------|---------|
| `/work <description>` | Auto-assess task depth and route to the right tier |
| `/work-fix <description>` | Quick fix — single-session with auto-review |
| `/work-feature <description>` | Feature — plan, implement, review in 1-2 sessions |
| `/work-deep <description>` | Initiative — multi-session with research, specs, phased implementation |
| `/work-review` | Run specialist review agents, track findings |
| `/work-status [name]` | Show active task progress and suggested next action |
| `/work-checkpoint [--step-end]` | Save session progress, optionally advance step |
| `/work-reground [name]` | Recover context after a break or compaction |
| `/work-redirect <reason>` | Record a dead end and pivot |
| `/work-archive [name]` | Archive a completed task |
```

#### Key Principles
- Context via files, not memory: steps produce handoff prompts and checkpoints for session continuity
- Handoff prompts are the firewall: never re-read raw research notes — use handoff prompt summaries
- 3 tiers: Fix (T1), Feature (T2), Initiative (T3) — auto-detected by triage
- Steps are data: the `steps` array in `state.json` defines available phases per tier
- Beads integration: every task has a beads issue; Tier 3 tasks have an epic
- State committed to git: `.work/` directory is tracked

#### Session Start Guidance
- If `.work/` contains active tasks (state.json where `archived_at` is null), run `/work-reground` to recover context before making changes

**Must NOT include:**
- Project-specific references
- Detailed command logic (commands define their own behavior)
- Configuration values (those come from `harness.yaml`)
- References to specific languages, frameworks, or databases

### 2.2 `workflow-detect.md` — Active Task Detection

**Purpose:** Session-start behavior that scans for active tasks and notifies the user. Fires automatically when Claude Code loads rules.

**Must include the detection algorithm:**

1. Look for `.work/*/state.json` files
2. For each, check if `archived_at` is null (meaning active)
3. If active tasks exist, display a brief notification:
   ```
   Active task detected: <name> (Tier <N>)
   Current step: <step> (status: <status>)
   Run /work-status for details or /work-reground to recover context.
   ```
4. If `.work/` exists but only archived tasks:
   ```
   No active tasks. Start a new one with /work <description>.
   ```
5. If no `.work/` directory exists, do nothing.

**Must NOT include:**
- Project-specific references
- Automatic action beyond notification (detection only — user decides what to do)
- State modification (purely read-only)

---

## 3. Parameterization Checklist

| Reference Type | Current State | Action |
|---------------|--------------|--------|
| Project-specific domain terms | Already absent from both rules | Verify: scan for "gaucho", "loan", "mortgage", etc. |
| `docs/feature/` reference | Present in current `workflow.md` ("summary files in `docs/feature/`") | Keep as-is — harness convention, not project-specific |
| Command list | Must enumerate all 10 commands | Verify matches C2 command inventory exactly |
| `.work/` directory structure | Used throughout | Keep as-is — harness convention |
| Beads references | Mentioned in principles | Keep as-is — beads is a hard dependency |
| Tier definitions | Already generic | Keep as-is |

**Assessment:** Both rules are already project-agnostic in the source. The extraction is straightforward: copy, verify no project-specific references, ensure command table is complete.

---

## 4. Files to Create

All paths relative to harness repo root (`claude-work-harness/`).

| File | Action | Description |
|------|--------|-------------|
| `claude/rules/workflow.md` | Create | Harness conventions, command reference, key principles |
| `claude/rules/workflow-detect.md` | Create | Active task detection at session start |

---

## 5. Implementation Steps

### 5.1 Write `workflow.md`

- [ ] **5.1.1** Write the command reference table with all 10 commands (matching C2 inventory from spec 04 section 2)
- [ ] **5.1.2** Write the key principles section (6 principles listed in section 2.1)
- [ ] **5.1.3** Write the session start guidance
- [ ] **5.1.4** Verify no project-specific references
- [ ] **5.1.5** Write file to `claude/rules/workflow.md`

### 5.2 Write `workflow-detect.md`

- [ ] **5.2.1** Write the detection algorithm (5-step logic from section 2.2)
- [ ] **5.2.2** Verify notification format includes task name, tier, current step, and status
- [ ] **5.2.3** Verify graceful handling when `.work/` doesn't exist (step 5: do nothing)
- [ ] **5.2.4** Verify no project-specific references
- [ ] **5.2.5** Write file to `claude/rules/workflow-detect.md`

### 5.3 Cross-Reference Verification

- [ ] **5.3.1** Verify `workflow.md` command table lists exactly the 10 commands from spec 04 (no more, no less)
- [ ] **5.3.2** Verify `workflow-detect.md` references commands that exist (`/work-status`, `/work-reground`, `/work`)
- [ ] **5.3.3** Grep both files for project-specific terms — zero matches

---

## 6. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `workflow.md` rule | All Claude Code sessions (loaded automatically) | Persistent context: command table, principles, session guidance |
| `workflow-detect.md` rule | All Claude Code sessions (loaded automatically) | Session-start behavior: scans `.work/`, displays notification |
| Command reference table | Users (discoverability) | Lists all 10 `/work-*` commands with descriptions |

### Consumes

| What | Provided By | Contract |
|------|------------|----------|
| `.work/<name>/state.json` | Created by commands (C2) at runtime | `workflow-detect.md` reads to detect active tasks |
| 10 work commands (C2) | `claude/commands/` | `workflow.md` references by name in command table; must stay in sync |

### Sync Contract

The command reference table in `workflow.md` must stay synchronized with the actual commands in `claude/commands/`. If a command is added, renamed, or removed in C2, `workflow.md` must be updated to match. This is a manual sync — there is no automated enforcement. The `workflow-meta.md` skill (C3) documents this maintenance requirement.

---

## 7. Testing Strategy

### Automated Checks

```sh
# Both rules exist
for rule in workflow workflow-detect; do
  [ -f "claude/rules/${rule}.md" ] && echo "PASS: ${rule}.md" || echo "FAIL: ${rule}.md missing"
done

# workflow.md references all 10 commands
for cmd in work work-fix work-feature work-deep work-review work-status work-checkpoint work-reground work-redirect work-archive; do
  grep -q "/${cmd}" claude/rules/workflow.md && echo "PASS: /${cmd} referenced" || echo "FAIL: /${cmd} missing from workflow.md"
done

# No project-specific references
for rule in claude/rules/workflow*.md; do
  if grep -qiE "gaucho|htmx|loan|borrower|mortgage|chi router|pgx|textract|workos" "$rule"; then
    echo "FAIL: $(basename $rule) has project-specific references"
  else
    echo "PASS: $(basename $rule) clean"
  fi
done

# workflow-detect.md references key commands
grep -q "/work-status" claude/rules/workflow-detect.md && echo "PASS: references /work-status" || echo "FAIL"
grep -q "/work-reground" claude/rules/workflow-detect.md && echo "PASS: references /work-reground" || echo "FAIL"
grep -q "/work " claude/rules/workflow-detect.md && echo "PASS: references /work" || echo "FAIL"

# workflow-detect.md mentions state.json
grep -q "state.json" claude/rules/workflow-detect.md && echo "PASS: mentions state.json" || echo "FAIL"

# workflow-detect.md mentions archived_at
grep -q "archived_at" claude/rules/workflow-detect.md && echo "PASS: mentions archived_at" || echo "FAIL"
```

### Manual Verification

- Start a new Claude Code session in a project with an active task in `.work/` — verify the detection notification appears
- Start a session in a project with only archived tasks — verify "No active tasks" message
- Start a session in a project with no `.work/` directory — verify no notification (silent)
- Check that `/work` commands listed in `workflow.md` are discoverable via Claude Code's command completion

---

## 8. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| `.work/` exists but is empty (no subdirectories) | `workflow-detect.md` step 1 finds no `state.json` files — falls through to step 5 (do nothing) |
| `state.json` exists but is malformed JSON | Claude reads it and encounters parse error — should note the error in output rather than crashing silently |
| Multiple active tasks detected | `workflow-detect.md` should display each one (the current source handles this) |
| Command added to C2 but not to `workflow.md` | Sync drift — caught by manual review. `workflow-meta.md` skill documents the maintenance requirement. |
| Rules loaded in project without beads | Rules still load fine — they reference beads in principles but don't execute `bd` commands |

---

## 9. Acceptance Criteria

1. - [ ] Both rule files exist at `claude/rules/workflow.md` and `claude/rules/workflow-detect.md`
2. - [ ] `workflow.md` contains a command reference table listing all 10 work commands
3. - [ ] `workflow.md` command table matches C2 inventory exactly (same commands, same descriptions)
4. - [ ] `workflow.md` contains the 6 key principles (context via files, handoff prompts, 3 tiers, steps are data, beads integration, state in git)
5. - [ ] `workflow.md` contains session start guidance referencing `/work-reground`
6. - [ ] `workflow-detect.md` implements the 5-step detection algorithm
7. - [ ] `workflow-detect.md` notification format includes task name, tier, current step, and status
8. - [ ] `workflow-detect.md` is silent when no `.work/` directory exists
9. - [ ] Zero project-specific references in either file: no "gaucho", "HTMX", "loan", "borrower", "mortgage", "chi", "pgx"
10. - [ ] File naming follows kebab-case convention per spec 00 section 2
