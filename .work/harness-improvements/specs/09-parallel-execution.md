# Spec 09: Parallel Execution v2 (C9)

**Component:** C9 -- Phase 3, Scope M, Priority P1
**Requires:** C7 (Skill Library), C8 (Dynamic Delegation), C1 (Stream Docs Enhancement)

## Overview

Integrate the enhanced stream doc format (C1), modular skill library (C7), and dynamic delegation router (C8) into a unified parallel execution system. Currently, stream docs inline all agent guidance, delegation is ad-hoc, and file ownership conflicts are only caught manually. This spec wires those three foundations together so that decompose produces leaner stream docs referencing shared skills, implement auto-routes agents via stream doc metadata, and phase gating enforces file ownership boundaries.

## Scope

**In scope:**
- Stream docs reference skills by slug instead of inlining guidance text
- Delegation router reads stream doc metadata (`agent_type`, `skills`, `isolation`) to configure agent spawns
- Phase gating calls delegation router for review agent selection
- File ownership manifest validation at phase boundaries
- Updates to decompose and implement step sections in `claude/commands/work-deep.md`

**Out of scope:**
- Stream doc format changes (delivered by C1)
- Skill extraction and file creation (delivered by C7)
- Delegation router core logic (delivered by C8)
- Worktree orchestration tooling (future enhancement -- documented in futures)
- Agent team lifecycle management beyond what Claude Code natively provides

## Implementation Steps

### Step 1: Update decompose step to emit skill-referenced stream docs

Modify the decompose step in `claude/commands/work-deep.md` to instruct the decompose agent to reference skills by slug in stream docs instead of inlining step-specific guidance.

**Changes to decompose step (item 4, "Stream execution documents"):**

Replace the current stream doc content specification with:

```markdown
4. **Stream execution documents**: For each stream, write a self-contained agent prompt in `.work/<name>/streams/<stream-letter>.md`:
   - Stream identity and work items (beads IDs)
   - Spec references for each work item
   - Metadata block (YAML frontmatter per spec 01's 7-field schema):
     ```yaml
     ---
     stream: A
     phase: 1
     isolation: <inline|subagent|worktree>
     agent_type: <general-purpose|Explore|Plan>
     skills: [code-quality, work-harness]
     scope_estimate: <S|M|L>
     file_ownership:
       - path/to/file1.go
       - path/to/file2.md
     ---
     ```
   - Acceptance criteria per work item (reference spec ACs by ID, do not duplicate full text)
   - Dependency constraints (what must complete before this stream starts)
   - Do NOT inline skill content -- reference by slug. Agents receive skill content via `skills:` propagation at spawn time.
```

Add a new validation substep to the decompose auto-advance Phase A checklist:

```markdown
- Does every stream doc have a valid metadata block with all 7 fields (stream, phase, isolation, agent_type, skills, scope_estimate, file_ownership)?
- Do stream doc `skills:` lists reference only slugs that exist in `claude/skills/`?
```

**AC-01**: `Stream docs produced by the decompose step contain YAML frontmatter with all 7 fields per spec 01: stream, phase, isolation, agent_type, skills, scope_estimate, and file_ownership` -- verified by `structural-review`

**AC-02**: `Stream docs reference skills by slug (e.g., code-quality) and do not inline skill content text` -- verified by `structural-review`

### Step 2: Update implement step to use delegation router

Modify the implement step in `claude/commands/work-deep.md` to read stream doc metadata and route agent spawns through the delegation pattern established by C8.

**Changes to implement step (item 2, "Parallel agent execution"):**

Replace the current agent spawn instructions with:

```markdown
2. **Parallel agent execution**: For each independent stream from the streams handoff:
   a. Read the stream doc's YAML frontmatter to determine execution parameters
   b. **Agent type selection** (from stream doc `agent_type` field):
      - `general-purpose`: Spawn with full read/write access (default for implementation)
      - `Explore`: Spawn read-only (for research/validation streams)
      - `Plan`: Spawn in plan mode (for design/decomposition streams)
   c. **Skill propagation**: Include all slugs from the stream doc `skills:` field in the agent spawn. The delegation router (C8) resolves slugs to skill file paths.
   d. **Isolation mode** (from stream doc `isolation` field):
      - `inline`: Execute in current context (small, fast work items)
      - `subagent`: Spawn as subagent (default for most implementation work)
      - `worktree`: Notify user that worktree isolation is recommended; provide the stream doc path for manual worktree setup
   e. Each subagent receives: its stream execution doc + relevant specs
   f. Subagents claim work with `bd update <id> --status=in_progress` and close with `bd close <id>`
   g. Lead agent monitors completion and launches next-phase agents when dependencies clear
```

**AC-03**: `Implement step reads stream doc frontmatter and spawns agents with the specified agent_type and skills` -- verified by `manual-test`

**AC-04**: `Agents spawned for isolation=worktree streams receive a notification to the user rather than attempting worktree creation` -- verified by `manual-test`

### Step 3: Integrate phase gating with delegation router for review agents

Update the implement step's phase gating logic to use stream doc metadata and harness.yaml `review_routing` for selecting review agents at phase boundaries.

**Changes to implement step (item 3, "Phase gating"):**

Add review agent selection logic:

```markdown
3. **Phase gating** (enforced -- see Inter-Step Quality Review Protocol): After each implementation phase completes:
   - **File ownership validation**: Before running reviews, verify no file appears in more than one stream's `file_ownership` list within the completed phase. If conflicts exist, report them as BLOCKING and list the conflicting files and streams.
   - **Phase A -- Artifact validation**: Spawn Explore agent (read-only) to check implementations match spec file lists and acceptance criteria. Additionally verify:
     - Each stream's modifications are within its declared `file_ownership` list
     - No undeclared files were created or modified by a stream agent
   - **Phase B -- Quality review**: Select review agent using this precedence:
     1. If `review_routing` is configured in `harness.yaml`: match changed file patterns against routing table to select agents
     2. If stream docs specify an `agent_type` override for review: use that
     3. Otherwise: use the `work-review` agent
   - Review agent receives `skills:` from the union of all completed streams' skill lists
   - Write results to `.work/<name>/implement/phase-N-validation.jsonl`
```

**AC-05**: `Phase boundary validation detects when a file appears in multiple streams' file_ownership lists and reports BLOCKING` -- verified by `manual-test`

**AC-06**: `Phase boundary validation detects when a stream agent modified files outside its declared file_ownership list` -- verified by `manual-test`

**AC-07**: `Review agent selection follows the precedence: harness.yaml review_routing > stream doc override > work-review default` -- verified by `structural-review`

### Step 4: Add file ownership manifest to decompose validation

Add a cross-stream file ownership validation step to the decompose auto-advance process.

**Add to decompose Phase A checklist:**

```markdown
- Is every file in the codebase claimed by at most one stream per phase? Cross-check all stream docs' `file_ownership` lists within each phase. Report any file that appears in multiple streams within the same phase as a conflict.
```

**Add to decompose Phase B checklist:**

```markdown
- Do file ownership boundaries align with module boundaries? (A stream should not own scattered files across unrelated packages -- it should own a cohesive set.)
```

**AC-08**: `Decompose Phase A validation catches file ownership conflicts across streams within the same phase` -- verified by `structural-review`

### Step 5: Update manifest.jsonl schema

Extend the stream manifest to include the new metadata fields for cross-referencing.

**Updated manifest.jsonl line format:**

```json
{
  "work_item": "W-01",
  "title": "state-guard.sh",
  "spec": "01",
  "beads_id": "abc123",
  "stream": "a",
  "phase": 1,
  "isolation": "subagent",
  "agent_type": "general-purpose",
  "skills": ["code-quality", "work-harness"],
  "scope_estimate": "S",
  "file_ownership": ["hooks/state-guard.sh"]
}
```

**AC-09**: `manifest.jsonl entries include stream, phase, isolation, agent_type, skills, scope_estimate, and file_ownership fields mirroring spec 01's stream doc metadata` -- verified by `structural-review`

## Interface Contracts

### Consumes

| Interface | From | Description |
|-----------|------|-------------|
| Enhanced stream doc format | C1 | YAML frontmatter with 7 fields: stream, phase, isolation, agent_type, skills, scope_estimate, file_ownership |
| Skill slugs | C7 | Skill files at `claude/skills/<slug>.md` or `claude/skills/<slug>/<slug>.md` |
| Delegation routing pattern | C8 | Step-level agent type and skill routing via command instructions |
| `review_routing` config | harness.yaml | File pattern to agent mapping for review agent selection |

### Exposes

| Interface | To | Description |
|-----------|------|-------------|
| File ownership validation | Implement step consumers | Phase boundary check that no file is claimed by multiple streams |
| Skill-referenced stream docs | Agent spawning | Stream docs that reference skills by slug, reducing doc size |
| Extended manifest.jsonl | Downstream tooling | Stream metadata for cross-referencing and scheduling |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update decompose step (item 4) to emit skill-referenced stream docs with metadata; update implement step (items 2-3) to use delegation router and file ownership validation; add Phase A/B checklist items |

## Testing Strategy

| Test | Method | Covers |
|------|--------|--------|
| Stream doc frontmatter is valid YAML with required fields | `structural-review` | AC-01 |
| Stream docs contain skill slugs, not inlined content | `structural-review` | AC-02 |
| Implement step instructions reference frontmatter fields | `structural-review` | AC-03 |
| Worktree isolation produces user notification | `manual-test` | AC-04 |
| File ownership conflict detection across streams | `manual-test` | AC-05, AC-06 |
| Review agent selection precedence documented correctly | `structural-review` | AC-07 |
| Decompose Phase A catches cross-stream file conflicts | `structural-review` | AC-08 |
| manifest.jsonl schema includes new fields | `structural-review` | AC-09 |
| End-to-end: run decompose on a multi-stream task, verify stream docs have metadata, then run implement and verify agents are spawned per metadata | `integration-test` | AC-01 through AC-09 |

## Deferred Questions Resolution

No deferred questions were assigned to this spec. C9 builds on resolved questions from C1 (stream doc format), C7 (skill granularity), and C8 (skills field verification).

## Advisory Notes Resolution

No advisory notes were directly assigned to C9. The relevant advisories are addressed in upstream specs:
- **A1** (C8 skills field verification): Resolved in Spec 08. C9 consumes whichever injection mechanism C8 established (frontmatter or prompt-based).
- **A4** (Phase 4 timing): Not applicable to C9 (Phase 3 component).
