---
stream: G
phase: 3
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: L
file_ownership:
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
  - claude/commands/work-fix.md
---

# Stream G: Phase 3 — Dynamic Delegation & Parallel Execution v2

## Stream Identity

- **Stream:** G
- **Phase:** 3
- **Work Items:**
  - W-09 (work-harness-ent): Dynamic delegation routing — spec 08
  - W-10 (work-harness-eec): Parallel execution v2 — spec 09

Both work items modify `claude/commands/work-deep.md` and must execute sequentially (C9 depends on C8).

## File Ownership

| File | Action | Work Items |
|------|--------|------------|
| `claude/commands/work-deep.md` | Modify | W-09, W-10 |
| `claude/commands/work-feature.md` | Modify | W-09 |
| `claude/commands/work-fix.md` | Modify | W-09 |
| `claude/agents/test-skills-verify.md` | Create then Delete | W-09 (temporary, deleted after verification) |
| `.work/harness-improvements/research/skills-frontmatter-verification.md` | Create | W-09 |

## Dependency Constraints

Stream G depends on:

- **W-07 (work-harness-ba9)** and **W-08 (work-harness-a4i)** — all of C7 (Skill Library) must be complete. C8's routing tables reference skills that C7 creates, and C9 consumes the delegation pattern C8 establishes.
- **C1 (Stream Docs Enhancement)** — C9 consumes the enhanced stream doc format with 7-field YAML frontmatter.

Stream G cannot begin execution until all Phase 2 work (C7) is complete.

## Execution Order

Execute sequentially: **W-09 first** (C8: Dynamic Delegation), **then W-10** (C9: Parallel Execution v2).

- W-10 depends on W-09 because C9 integrates the delegation router that C8 creates.
- Both modify `claude/commands/work-deep.md`, so they cannot run in parallel.

---

## W-09: Dynamic Delegation Routing (work-harness-ent)

**Spec reference:** `.work/harness-improvements/specs/08-dynamic-delegation.md` (C8)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/agents/test-skills-verify.md` | Create then Delete | Temporary test agent for `skills:` frontmatter verification |
| `.work/harness-improvements/research/skills-frontmatter-verification.md` | Create | Verification result record |
| `claude/commands/work-deep.md` | Modify | Add Step Routing Table, update step routers to use it, update Skill Propagation section |
| `claude/commands/work-feature.md` | Modify | Add Step Routing Table, update step routers, update Skill Propagation |
| `claude/commands/work-fix.md` | Modify | Add Step Routing Table, update step routers, update Skill Propagation |

### Acceptance Criteria

**AC-01**: `Verification result is recorded with evidence before any subsequent C8 steps begin` -- verified by `file-exists` (`.work/harness-improvements/research/skills-frontmatter-verification.md`)

**AC-02**: `Test agent file is deleted after verification` -- verified by `file-exists` (absence of `claude/agents/test-skills-verify.md`)

**AC-03**: `Each tier command contains a Step Routing Table section with columns: Step, Agent Type, Skills, Context Sources` -- verified by `structural-review`

**AC-04**: `Every step in each command's steps array has a corresponding row in its routing table` -- verified by `structural-review`

**AC-05**: `The implemented injection mechanism matches the verification result from Step 1 (Path A if supported, Path B if not)` -- verified by `structural-review`

**AC-06**: `For Path B, each skill injection fragment specifies exact file paths (not just skill names)` -- verified by `structural-review`

**AC-07**: `Each agent spawn instruction in updated commands references the routing table rather than hardcoding agent type and skills inline` -- verified by `structural-review`

**AC-08**: `The review step in each command continues to delegate to /work-review (no routing table override for review)` -- verified by `structural-review`

**AC-09**: `An audit of rule files is documented (either in the commit message or in a research note) listing each rule file and whether it is cross-cutting or step-specific` -- verified by `structural-review`

**AC-10**: `Any step-specific guidance found in rules is either migrated to a skill/reference doc or documented with rationale for keeping it in rules` -- verified by `structural-review`

**AC-11**: `Each command's Skill Propagation section references the routing table as the source of truth, not a hardcoded list` -- verified by `structural-review`

### Implementation Notes

C8 replaces implicit, ad-hoc agent delegation with explicit step-level routing tables. This is a 6-step implementation:

#### Step 1: Verify `skills:` frontmatter support (BLOCKING GATE)

**This step must complete before any other C8 work begins.**

Verify whether Claude Code agent YAML frontmatter supports the `skills:` field natively:

1. Create a test agent file at `claude/agents/test-skills-verify.md` with `skills: [work-harness]` in its frontmatter.
2. Spawn the test agent and evaluate whether it reports access to work-harness skill content.
3. Record the result in `.work/harness-improvements/research/skills-frontmatter-verification.md` with: date, result (supported/unsupported), evidence, implementation path (A or B).
4. Delete the test agent file.

**Path A (frontmatter supported):** Agent spawns include `skills:` in YAML frontmatter or spawn parameters. No additional prompt text needed — Claude Code handles it natively.

**Path B (frontmatter unsupported):** Agent spawns include explicit skill loading instructions in prompt text with exact file paths:
```
Before starting work, read and follow these skills:
1. Read `claude/skills/work-harness/task-discovery.md` for task discovery conventions.
2. Read `claude/skills/work-harness/step-transition.md` for step transition protocol.
3. Read `claude/skills/code-quality/code-quality.md` for quality standards.

Then proceed with: <step-specific prompt>
```

Both paths must be understood before proceeding. The verification result also informs W-10 (C9).

#### Step 2: Define step-level routing tables

Add explicit routing tables to each tier command. Format:

**work-deep.md (Tier 3):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| research | Explore | work-harness, code-quality | beads issues, managed docs (C3) |
| plan | Plan | work-harness, code-quality | research handoff prompt |
| spec | Plan | work-harness, code-quality | plan handoff prompt, architecture.md |
| decompose | Plan | work-harness, code-quality | spec handoff prompt, all spec files |
| implement | general-purpose | work-harness, code-quality | stream doc, relevant specs, managed docs (C3) |
| review | (via /work-review) | code-quality | diff since base_commit |

**work-feature.md (Tier 2):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| plan | Explore + Plan | work-harness, code-quality | beads issues, managed docs (C3) |
| implement | general-purpose | work-harness, code-quality | plan document, managed docs (C3) |
| review | (via /work-review) | code-quality | diff since base_commit |

**work-fix.md (Tier 1):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| implement | general-purpose | work-harness, code-quality | beads issues |
| review | inline (no agent spawn) | code-quality | diff since base_commit |

#### Step 3: Implement skill injection mechanism

Implement Path A or Path B based on Step 1 verification result. For Path B, define reusable skill injection fragments per step with exact file paths.

#### Step 4: Update command step routers

Modify each command's step router to consult its routing table when spawning agents, replacing ad-hoc skill propagation with routing table references.

Changes per command:

| Command | Steps Updated | Nature of Change |
|---------|---------------|-----------------|
| `work-deep.md` | research, plan, spec, decompose, implement | Replace ad-hoc skill propagation with routing table reference |
| `work-feature.md` | plan, implement | Replace ad-hoc skill propagation with routing table reference |
| `work-fix.md` | implement | Replace ad-hoc skill propagation with routing table reference |

Review steps continue to delegate to `/work-review` unchanged.

#### Step 5: Migrate phase-specific guidance from rules to skills

Audit all rule files in `claude/rules/`. For each rule, determine if it is cross-cutting (stays in rules) or step-specific (migrate to skill). Based on the spec's assessment, most rules are genuinely cross-cutting. If the audit confirms this, document "no migration needed" with evidence.

#### Step 6: Update Skill Propagation documentation

Replace hardcoded skill lists in each command's Skill Propagation section with a reference to the Step Routing Table as the single source of truth.

---

## W-10: Parallel Execution v2 (work-harness-eec)

**Spec reference:** `.work/harness-improvements/specs/09-parallel-execution.md` (C9)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update decompose step (item 4) to emit skill-referenced stream docs with metadata; update implement step (items 2-3) to use delegation router and file ownership validation; add Phase A/B checklist items; update manifest.jsonl schema |

### Acceptance Criteria

**AC-01**: `Stream docs produced by the decompose step contain YAML frontmatter with all 7 fields per spec 01: stream, phase, isolation, agent_type, skills, scope_estimate, and file_ownership` -- verified by `structural-review`

**AC-02**: `Stream docs reference skills by slug (e.g., code-quality) and do not inline skill content text` -- verified by `structural-review`

**AC-03**: `Implement step reads stream doc frontmatter and spawns agents with the specified agent_type and skills` -- verified by `manual-test`

**AC-04**: `Agents spawned for isolation=worktree streams receive a notification to the user rather than attempting worktree creation` -- verified by `manual-test`

**AC-05**: `Phase boundary validation detects when a file appears in multiple streams' file_ownership lists and reports BLOCKING` -- verified by `manual-test`

**AC-06**: `Phase boundary validation detects when a stream agent modified files outside its declared file_ownership list` -- verified by `manual-test`

**AC-07**: `Review agent selection follows the precedence: harness.yaml review_routing > stream doc override > work-review default` -- verified by `structural-review`

**AC-08**: `Decompose Phase A validation catches file ownership conflicts across streams within the same phase` -- verified by `structural-review`

**AC-09**: `manifest.jsonl entries include stream, phase, isolation, agent_type, skills, scope_estimate, and file_ownership fields mirroring spec 01's stream doc metadata` -- verified by `structural-review`

### Implementation Notes

C9 integrates C1 (stream doc format), C7 (skill library), and C8 (delegation router) into a unified parallel execution system. This is a 5-step implementation:

#### Step 1: Update decompose step to emit skill-referenced stream docs

Modify the decompose step in `work-deep.md` (item 4, "Stream execution documents") to:
- Require YAML frontmatter with all 7 fields per spec 01's schema
- Instruct agents to reference skills by slug, not inline skill content
- Add validation substeps to decompose Phase A checklist:
  - Does every stream doc have a valid metadata block with all 7 fields?
  - Do stream doc `skills:` lists reference only slugs that exist in `claude/skills/`?

#### Step 2: Update implement step to use delegation router

Modify the implement step in `work-deep.md` (item 2, "Parallel agent execution") to:
- Read stream doc YAML frontmatter for execution parameters
- Select agent type from stream doc `agent_type` field (general-purpose, Explore, Plan)
- Propagate all slugs from stream doc `skills:` field via the C8 injection mechanism
- Handle isolation modes: `inline` (execute in current context), `subagent` (spawn as subagent), `worktree` (notify user, provide stream doc path)
- Each subagent receives: stream execution doc + relevant specs
- Lead agent monitors completion and launches next-phase agents when dependencies clear

#### Step 3: Integrate phase gating with delegation router for review agents

Update implement step phase gating logic to:
- **File ownership validation**: Before reviews, verify no file appears in more than one stream's `file_ownership` list. Report conflicts as BLOCKING.
- **Phase A — Artifact validation**: Spawn Explore agent to check implementations match spec. Verify each stream's modifications stay within its declared `file_ownership` list.
- **Phase B — Quality review**: Select review agent with precedence:
  1. If `review_routing` configured in `harness.yaml`: match file patterns to select agents
  2. If stream docs specify `agent_type` override for review: use that
  3. Otherwise: use `work-review` agent
- Review agent receives `skills:` from the union of all completed streams' skill lists
- Write results to `.work/<name>/implement/phase-N-validation.jsonl`

#### Step 4: Add file ownership manifest to decompose validation

Add cross-stream file ownership validation to decompose auto-advance:
- **Phase A checklist**: Is every file claimed by at most one stream per phase? Report conflicts.
- **Phase B checklist**: Do file ownership boundaries align with module boundaries? (Streams should own cohesive file sets, not scattered files across unrelated packages.)

#### Step 5: Update manifest.jsonl schema

Extend stream manifest entries to include all metadata fields:
```json
{
  "work_item": "W-01",
  "title": "...",
  "spec": "01",
  "beads_id": "abc123",
  "stream": "a",
  "phase": 1,
  "isolation": "subagent",
  "agent_type": "general-purpose",
  "skills": ["code-quality", "work-harness"],
  "scope_estimate": "S",
  "file_ownership": ["path/to/file.go"]
}
```
