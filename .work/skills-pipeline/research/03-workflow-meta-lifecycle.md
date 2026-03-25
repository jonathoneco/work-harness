# Research: Workflow-Meta, Skill Lifecycle & Dump Command

## Questions

1. What does workflow-meta do today, and what would "proper workflow" for it mean?
2. How does workflow-meta relate to skill lifecycle and skill updates?
3. What would "proactive skill updating" look like — how could skills detect staleness?
4. What would a "dump command" add beyond the current `/decompose` step?
5. How do these three concepts (workflow-meta, skill lifecycle, dump) form a coherent system?

---

## Findings

### 1. Workflow-Meta Today: Self-Hosting Conventions

**Current Scope**: `claude/skills/workflow-meta.md` documents how to modify the harness itself:
- Component modification conventions (commands, skills, agents, rules, hooks)
- Adding new language packs (dynamic directive mechanism)
- Testing changes (local install, test with/without harness.yaml)
- Version bumping (semver: PATCH for fixes, MINOR for features, MAJOR for breaking)
- **Critical sync point**: `workflow.md` command table must match `claude/commands/` inventory

**What It Does Well**:
- Clear operational rules for harness development
- Documents the constraint that all 11 work commands + `/delegate` must be synced in workflow.md
- Establishes semver discipline

**What It Lacks**:
- No "entry point" — doesn't tell you how to *start* improving the harness
- No workflow for proposing new commands/skills with review gates
- No ceremony for skill updates (when stack changes, skills should evolve too)
- No integration with beads for harness changes (work items are created manually, not via commands)
- Doesn't address skill versioning or compatibility

---

### 2. "Proper Workflow" for Workflow-Meta: Pre-Seeded Intention Entry Point

**Current State**: The harness has implicit entry points:
- `/work` → auto-assess and route to tier command (generic, task-agnostic)
- `/work-fix`, `/work-feature`, `/work-deep` → preset tier (explicit tier choice)
- `/work-research` → standalone research (no implementation)
- `/delegate` → ad-hoc subtask to specialist agent

**What "Proper Workflow" Could Mean** (for harness development itself):
- A `workflow-meta` command that starts with **pre-seeded context** about what you're improving
- Instead of: "I'm working on the harness, let me assess task complexity"
- Should be: "I want to add a new skill for Go testing patterns, here's why"
- Example flow:
  ```
  /workflow-meta --type=skill --title="Go testing patterns"

  → Detects: You're modifying workflow-harness repo
  → Reads your intention: skill creation for Go
  → Pre-populates assessment with harness-specific criteria
  → Routes to appropriate tier (likely T2: modify skill system)
  → Seeds agent context with: workflow-meta skill, code-quality skill, references to existing skills
  → Kicks off with approval gates to ensure harness quality
  ```

**Implication**: `workflow-meta` today is a *reference guide*. A proper workflow would make it an *active entry point* that enforces its own constraints (sync checks, version bumping, testing gates).

**How to Implement**:
1. Extract workflow-meta discipline into a dedicated command (`/workflow-meta`)
2. Command pre-seeds based on change type: `--type=[skill|command|agent|rule|hook]`
3. Command auto-validates against sync points (e.g., if you're adding a command, remind you to update workflow.md)
4. Command creates beads issue tagged `[Harness]`
5. Implementation includes harness-testing gates (verify install.sh works, hooks fire, etc.)

---

### 3. Skill Lifecycle & Proactive Updating: From Static to Reactive

**Current Skill Lifecycle** (from prior research):
1. **Creation**: Manual, markdown file with YAML frontmatter
2. **Distribution**: Git-checked (per project + global harness)
3. **Activation**: Explicit agent-level declaration (`skills: [name]`)
4. **Updates**: Manual file edits
5. **Versioning**: None explicit; relies on git history

**Gap**: No mechanism to detect when a skill is stale relative to its intended context.

**What "Proactive Skill Updating" Would Require**:

#### Phase 1: Skill Metadata (Foundation)
Enhance YAML frontmatter to include:
```yaml
---
name: go-testing
description: "Go testing patterns and best practices"
language: go                              # NEW
min_language_version: "1.18"              # NEW
frameworks: [testify, gopkg.in/check.v1]  # NEW
last_updated: 2026-03-24                  # NEW
harness_version: ">=1.0"                  # NEW
---
```

#### Phase 2: Staleness Detection (Hook + Check)
Add hook that runs on git commits:
```sh
# hooks/check-skill-staleness.sh
# Triggered: BeforeCommit
# Logic:
# 1. Detect if harness.yaml changed (stack config)
# 2. Compare old stack to new stack (language version bump? new framework?)
# 3. For each project skill, check metadata:
#    - Is language version in [min_version, max_version]?
#    - Are declared frameworks still in use?
#    - Is harness_version compatible?
# 4. If mismatch: flag skill as stale in findings.jsonl
# 5. Suggest: run /work-skill-update <skill-name>
```

#### Phase 3: Update Workflow (Command)
New command: `/work-skill-update <skill-name>`
- Tier 2: simple refresh of existing skill
- Detects staleness reason (language upgrade, new framework, etc.)
- Uses research agents to gather new patterns/best practices
- Produces updated skill file
- Gates update via review phase
- Closes beads issue

#### Phase 4: Auto-Generation (Optional)
When harness.yaml changes to a new language/framework:
```
detect new language: Python
→ check if python-patterns.md exists globally
→ if not: suggest /work-skill-generate python-patterns
→ or: auto-create in .claude/skills/ (ephemeral, not checked in)
```

**Key Design Decision**: Should skill updates be:
- **Automatic** (silent git commit if no conflicts)?
- **Gated** (review phase, beads issue, requires approval)?
- **Suggested** (flag as stale, let user decide)?

**Recommendation**: Gated. Skills affect every agent's context; breaking changes should require approval.

---

### 4. Dump Command: Extracting Decomposition Beyond Tier 3

**Current Decomposition** (from prior research):
- **Where**: `/decompose` step (Tier 3 only, available in multi-session initiatives)
- **What it does**:
  - Accepts a spec from the `spec` step
  - Produces stream document per phase
  - Creates beads subtasks with dependencies chained
- **Limitation**: Only works within active Tier 3 task context

**What a Standalone `/work-dump` Command Would Add**:

#### Use Case 1: Ad-Hoc Decomposition (No Active Task)
```
User: /work-dump "Refactor payment system to support new provider"

→ Command creates lightweight beads epic (not a task)
→ Spawns research agent to understand current system
→ Decomposes into 8-12 subtasks:
   - [Payment] Audit current provider integration
   - [Payment] Design new provider abstraction
   - [DB] Migrate payment schema
   - [API] Add provider selection endpoint
   - [API] Update payment flow
   - [Test] Expand payment tests
   - [Docs] Update payment integration guide
   → Creates beads subtasks with dependencies
   → (Optional) Auto-kicks off /work-feature for each subtask
```

#### Use Case 2: Spec-Driven Decomposition (From Existing Spec File)
```
User: /work-dump --spec=.work/my-feature/specs/decomposition.md

→ Parses spec file (structured format)
→ Creates epic + subtasks with inheritance
→ Respects phase sequencing from spec
→ Seeds beads issues with acceptance criteria from spec
```

#### Use Case 3: Intelligent Decomposition (AI-Powered)
```
User: /work-dump "Add OAuth2 support to auth system"

→ Research agents analyze current auth system
→ Propose decomposition by layer (API, middleware, storage)
→ OR by phase (research, design, implement, test, docs)
→ OR by team (backend auth, frontend integration, infra)
→ User chooses strategy
→ Generates subtasks with intelligent task names and priorities
```

**Key Differences from Current `/decompose` Step**:
| Aspect | Current Decompose | Proposed Dump |
|--------|----------|---------|
| **Context** | Requires active Tier 3 task | Standalone, no active task needed |
| **Input** | Spec from spec step | Free-form description or spec file |
| **Output** | Stream documents + beads subtasks | Beads epic + subtasks only |
| **Strategy** | Phase-based (hardcoded) | Multiple options (layer, feature, team, phase) |
| **Subtask Creation** | Manual subtask creation in beads | Auto-create with dependencies |
| **Follow-up** | User manually starts `/work` per subtask | Optional auto-start /work-feature per subtask |

**How to Implement `/work-dump`**:
1. Extract decomposition logic from `/work-deep` (decompose step)
2. Make it strategy-pluggable (phase, layer, feature, team)
3. Create beads epic + subtasks automatically
4. Seed subtask descriptions with: acceptance criteria, estimated scope, dependencies
5. Optional: Offer to kick off `/work-feature` for each subtask in sequence
6. Gate via single review artifact (validate that decomposition is logical, scopes are balanced, dependencies are correct)

---

### 5. How Workflow-Meta, Skill Lifecycle, and Dump Fit Together

**System Model**:
```
Workflow-Meta (Harness Developer Workflow)
  ├─ Entry: /workflow-meta --type=[skill|command|agent|rule|hook]
  ├─ Seeds with: harness-specific context (what you're changing, why)
  ├─ Produces: beads issue [Harness], code changes, gate artifacts
  └─ Output: merged change to work-harness repo
     └─ Triggers skill validation/versioning checks

  └─ Skill Lifecycle (Project-Level Skill Management)
      ├─ Detection: Hook notices harness.yaml change or skill staleness
      ├─ Action: /work-skill-update <name> to refresh stale skill
      ├─ Output: Updated skill file, beads issue [Skill Update], gate artifacts
      └─ Metadata: Skills declare language/framework/version requirements
         └─ Enables: staleness detection, compatibility checking

      └─ Dump Command (Workflow Decomposition)
          ├─ Entry: /work-dump <description> or /work-dump --spec=<file>
          ├─ Seeds with: research of current system, decomposition strategy
          ├─ Output: beads epic + subtasks, dependencies chained
          └─ Follow-up: Optional auto-start /work-feature per subtask
             └─ Each subtask inherits context from dump epic
```

**Coherence**:
1. **Workflow-meta** manages *harness quality* — ensuring the tool itself stays consistent
2. **Skill lifecycle** manages *project context* — ensuring skills evolve with the project stack
3. **Dump command** manages *work decomposition* — ensuring complex work gets scoped into bite-sized tasks

All three enable **intentional, structured work**: you're not just saying "I want to work on X"; you're saying "I want to work on X because [context], which decomposes into [these subtasks], using [these skills]."

---

### 6. Workflow-Meta as Active, Not Passive

**Current Problem**: `workflow-meta.md` is a reference guide, not a guard. You can:
- Add a command without updating `workflow.md` table
- Modify a skill without checking harness version compatibility
- Create a hook without registering it in `install.sh`
- Forget to version bump

**Proposed Solution**: `/workflow-meta` command enforces the constraints *by design*:
```
/workflow-meta --type=command --title="Add new /work-something command"
  ↓
  Workflow-meta recognizes you're modifying work-harness
  ↓
  Pre-seeds context:
    - You're adding a command
    - Remind you: must add entry to workflow.md command table
    - Remind you: must include config injection directive
    - Remind you: must update install.sh
    - Remind you: must run harness-doctor to validate
  ↓
  Routes to Tier 2 (command addition is a feature)
  ↓
  Plan step includes: "Review sync points"
  ↓
  Implementation: your agent writes command + updates tables
  ↓
  Review gate: "Verify workflow.md table matches claude/commands/"
           "Verify install.sh includes new command"
           "Verify harness-doctor passes"
```

**Benefits**:
- Catches sync point violations before they happen
- Ensures version bumping is never forgotten
- Seeds agents with harness knowledge automatically
- Creates beads issue for traceability

---

## Implications

### For Workflow-Meta Design
1. **Current skill is reference + future command is enforcement**
   - Keep the markdown guide (valuable reference)
   - Add `/workflow-meta` command that actively enforces the rules

2. **Skill versioning is a prerequisite for proactive updates**
   - Can't detect staleness without knowing what a skill requires
   - Metadata additions should happen before skill lifecycle feature

3. **Update ceremonies matter**
   - Auto-updating skills is risky (could break agent behavior)
   - Better: detect staleness, suggest update, gate with review

### For Skill Lifecycle Design
1. **Staleness detection is hook-based**
   - Detect `harness.yaml` changes
   - Check skill metadata against new config
   - Flag for review, not auto-fix

2. **Skill updates should go through beads**
   - Create issue: `[Skill Update] Go patterns v1 → v2`
   - Attach to epic for multi-language projects
   - Gate via review phase

3. **Metadata is the linchpin**
   - Skills must declare `language`, `min_version`, `frameworks`
   - This enables all downstream automation

### For Dump Command Design
1. **Extract, don't duplicate decomposition logic**
   - Current `/decompose` step is powerful
   - Reuse its logic, surface it as standalone command

2. **Intelligent decomposition is AI-powered**
   - Multiple strategy options (phase, layer, feature, team)
   - Research agents analyze context and propose splits
   - User approves strategy before subtask creation

3. **Seamless continuation**
   - Epic should capture decomposition decision
   - Subtasks inherit epic context
   - Optional auto-start /work-feature for each subtask

---

## Open Questions

1. **Should `/workflow-meta` auto-update `workflow.md` table, or is it a manual sync?**
   - Auto-update risks merge conflicts if multiple people editing
   - Manual sync is error-prone but gives developer control
   - Recommend: **auto-validate on review gate**, let human approve changes

2. **When should skill staleness checks fire?**
   - Option A: Hook on every commit (expensive, noisy)
   - Option B: Hook on harness.yaml changes only (more targeted)
   - Option C: Scheduled check (e.g., weekly /work-skill-audit)
   - Recommend: **Option B** (when stack changes, skills should be audited)

3. **Should `/work-dump` auto-start subtasks, or just create them?**
   - Auto-start: faster iteration, but might overwhelm user with tasks
   - Just create: gives user control, but manual follow-up
   - Recommend: **Optional flag** (`/work-dump --auto-start`), default is create-only

4. **How deep should skill metadata be?**
   - Minimal: `language`, `min_version`
   - Rich: above + `frameworks`, `databases`, `testing_tools`, `build_systems`
   - Recommend: **Start minimal, expand as use cases emerge**

5. **Can `/work-dump` be used for refactors, or only new features?**
   - Refactors often have complex dependencies
   - Could be powerful for large refactors
   - Recommend: **Support both**, but make refactor strategy different (more emphasis on testing, backward compat)

6. **Should skill updates be part of skill-lifecycle feature, or separate `/work-skill` command?**
   - Together: one command for skill management (`/work-skill --action=update <name>`)
   - Separate: `/work-skill-update` is its own tier command
   - Recommend: **Separate** (simpler, follows existing pattern of tier commands)

---

## Summary

**Workflow-meta** should evolve from a passive reference guide into an **active entry point** (`/workflow-meta` command) that pre-seeds harness development with context and enforces quality gates.

**Skill lifecycle** requires **metadata additions** (language, version requirements) and a **staleness detection hook** that flags skills when project stack changes, triggering a `/work-skill-update` workflow.

**Dump command** should **extract decomposition logic** from the Tier 3 `/decompose` step and surface it as a standalone `/work-dump` command that supports multiple decomposition strategies and auto-creates beads epics.

Together, these three features create a **coherent system** for intentional work: harness developers have a structured workflow, project skills evolve with the codebase, and complex work gets intelligently decomposed into tractable pieces.
