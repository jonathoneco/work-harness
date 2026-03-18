---
stream: A
phase: 1
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: L
file_ownership:
  - claude/commands/work-deep.md
  - claude/skills/work-harness/context-docs.md
  - claude/agents/work-implement.md
  - templates/harness.yaml.template
---

# Stream A: Phase 1 — Command & Protocol Enhancements

## Stream Identity

- **Stream:** A
- **Phase:** 1
- **Work Items:**
  - W-01 (work-harness-uzd): Stream doc YAML frontmatter
  - W-02 (work-harness-e2h): Context doc system
  - W-03 (work-harness-fp6): Research protocol

All three work items modify `claude/commands/work-deep.md` and must execute sequentially.

## File Ownership

| File | Action | Work Items |
|------|--------|------------|
| `claude/commands/work-deep.md` | Modify | W-01, W-02, W-03 |
| `claude/skills/work-harness/context-docs.md` | Create | W-02 |
| `claude/agents/work-implement.md` | Modify | W-02 |
| `templates/harness.yaml.template` | Modify | W-02 |

## Dependency Constraints

No Phase 1 dependencies. This stream is immediately ready for execution.

## Execution Order

Execute sequentially: W-01 first, then W-02, then W-03. All three modify `claude/commands/work-deep.md`, so they cannot run in parallel.

---

## W-01: Stream Doc YAML Frontmatter (work-harness-uzd)

**Spec reference:** `.work/harness-improvements/specs/01-stream-docs.md` (C1)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update decompose step (stream doc format, reference tables) and implement step (routing logic) |

### Acceptance Criteria

**AC-01**: `Stream docs in .work/<name>/streams/<letter>.md contain valid YAML frontmatter with all 7 fields` -- verified by `structural-review`

**AC-02**: `No file path appears in file_ownership of more than one stream within the same phase` -- verified by `manual-test` (decompose review agent checks this)

**AC-03**: `The decompose step instructions in work-deep.md include the isolation mode selection table and heuristic` -- verified by `structural-review`

**AC-04**: `The decompose step instructions include the agent type selection table` -- verified by `structural-review`

**AC-05**: `The decompose step in work-deep.md instructs agents to produce stream docs with YAML frontmatter containing all 7 fields` -- verified by `structural-review`

**AC-06**: `The decompose step includes isolation mode and agent type selection reference tables` -- verified by `structural-review`

**AC-07**: `The implement step reads isolation mode from frontmatter and routes execution accordingly` -- verified by `structural-review`

**AC-08**: `The implement step uses agent_type and skills from frontmatter when spawning subagents` -- verified by `structural-review`

**AC-09**: `The decompose Phase A checklist includes frontmatter validation and file_ownership conflict detection` -- verified by `structural-review`

### Implementation Notes

This work item defines the enhanced stream doc format with YAML frontmatter (7 fields: `stream`, `phase`, `isolation`, `agent_type`, `skills`, `scope_estimate`, `file_ownership`), documents the hybrid execution strategy (inline/subagent/worktree isolation modes), documents agent type selection guidance, and updates both the decompose and implement steps in `work-deep.md`.

Key changes to `work-deep.md`:
1. **Decompose step** — Update "Stream execution documents" section to require YAML frontmatter with all 7 fields. Add isolation mode selection table with the 3 modes and selection heuristic. Add agent type selection table (general-purpose, Explore, Plan, custom). Update Phase A decompose validation checklist to include frontmatter validation and file_ownership conflict detection.
2. **Implement step** — Update "Parallel agent execution" to read frontmatter and route by isolation mode: `inline` (lead executes directly), `subagent` (spawn with specified agent_type and skills), `worktree` (inform user). Execute inline streams first, then spawn subagent streams in parallel within each phase.

---

## W-02: Context Doc System (work-harness-e2h)

**Spec reference:** `.work/harness-improvements/specs/03-context-docs.md` (C3)

### Files

| File | Action | Description |
|------|--------|-------------|
| `templates/harness.yaml.template` | Modify | Add commented `docs.managed` section with examples |
| `claude/skills/work-harness/context-docs.md` | Create | Context doc system skill with auto-detection mapping and injection instructions |
| `claude/commands/work-deep.md` | Modify | Add managed doc reading and injection in research, plan, and implement steps |
| `claude/agents/work-implement.md` | Modify | Add managed docs section to agent instructions |

### Acceptance Criteria

**AC-01**: `harness.yaml` template includes a commented-out `docs.managed` section with example entries -- verified by `structural-review`

**AC-02**: `lib/config.sh` validation rejects duplicate `type` values within `docs.managed` and paths not ending in `.md` -- verified by `manual-test`

**AC-03**: When `docs.managed` key is absent and stack config has `framework: nextjs` and `database: postgres`, auto-detection suggests `components`, `endpoints`, `env-setup`, `schema`, `migrations` with default paths -- verified by `manual-test`

**AC-04**: When `docs.managed` is present (even as empty array `[]`), auto-detection does not run -- verified by `manual-test`

**AC-05**: Duplicate doc types from multiple stack fields are deduplicated (e.g., `framework: nextjs` and `frontend: react` both suggest `components`, but it appears only once) -- verified by `manual-test`

**AC-06**: Skill file exists at `claude/skills/work-harness/context-docs.md` with valid frontmatter (`name`, `description`) and all four sections -- verified by `structural-review`

**AC-07**: `work-deep.md` research step instructions include reading `docs.managed` and passing paths to research agents -- verified by `structural-review`

**AC-08**: `work-deep.md` implement step instructions include reading `docs.managed` and passing paths to implementation agents -- verified by `structural-review`

**AC-09**: `work-implement.md` includes a "Managed Docs" section instructing the agent to read harness.yaml for managed doc paths -- verified by `structural-review`

### Implementation Notes

This work item introduces a manifest-driven system for injecting project documentation into agent context.

Key changes:
1. **`templates/harness.yaml.template`** — Add a `docs:` section with commented-out `managed:` array showing example entries (type + path pairs).
2. **`claude/skills/work-harness/context-docs.md`** — New skill file documenting the system. Sections: activation conditions, reading the manifest, auto-detection heuristics (mapping table from stack config fields to suggested doc types), agent context injection instructions, doc maintenance guidance.
3. **`claude/commands/work-deep.md`** — In research step: read `docs.managed` and pass all managed doc paths to research agents. In plan step: pass all managed doc paths. In implement step: pass relevant managed doc paths to implementation agents. Injection format: `## Managed Project Docs` section listing type and path.
4. **`claude/agents/work-implement.md`** — Add a "Managed Docs" section instructing the agent to read `docs.managed` from `harness.yaml` before starting implementation.

Auto-detection heuristic: when `docs.managed` key is absent, infer doc types from stack config (`language`, `framework`, `database`, `frontend` fields). When present (even empty), auto-detection is suppressed.

---

## W-03: Research Protocol (work-harness-fp6)

**Spec reference:** `.work/harness-improvements/specs/05-research-protocol.md` (C5)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update `When current_step = "research"` section with agent-writes-directly protocol |

### Acceptance Criteria

**AC-01**: `Research agent prompt template in work-deep.md contains all five required fields (task context, topic scope, target file path, index entry format, note format)` -- verified by `structural-review`

**AC-02**: `Research note format is documented in the research step instructions and contains all four sections (Questions, Findings, Implications, Open Questions)` -- verified by `structural-review`

**AC-03**: `Research step instructions explicitly state that agents write files directly and the lead does not transcribe` -- verified by `structural-review`

**AC-04**: `Research step instructions list four specific lead synthesis responsibilities (verify coverage, identify gaps, synthesize handoff, reference-not-copy)` -- verified by `structural-review`

**AC-05**: `Updated research step in work-deep.md follows the 7-point process flow and is consistent with the Inter-Step Quality Review Protocol` -- verified by `structural-review`

**AC-06**: `No changes to steps other than research in work-deep.md` -- verified by `structural-review`

### Implementation Notes

This work item changes the research protocol so Explore agents write their own note files directly instead of returning findings for the lead to transcribe.

Key changes to the `When current_step = "research"` section of `work-deep.md`:
1. **Research agent prompt template** — Define a structured prompt with 5 required fields: task context, topic scope, target file path, index entry format, note format.
2. **Research note format** — 4-section markdown structure: Questions, Findings, Implications, Open Questions.
3. **Agent file-writing responsibilities** — Each Explore agent writes its research note to the assigned file path, appends its index entry to `research/index.md`, optionally writes to `research/dead-ends.md` or `futures.md`.
4. **Lead synthesis protocol** — After agents complete, the lead: (1) verifies coverage, (2) identifies gaps and re-spawns if needed, (3) synthesizes a reference-based handoff prompt, (4) references note file paths instead of copying content.
5. **Updated process flow** — 7-point flow: read context, plan topics, spawn agents with template, verify coverage, synthesize handoff, handle dead ends/futures, auto-advance with quality review.

Important constraint: no changes to steps other than `research` in `work-deep.md` (AC-06).
