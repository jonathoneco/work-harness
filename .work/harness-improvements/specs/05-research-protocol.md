# Spec 05: Research Protocol (C5)

**Component**: C5 — Phase 1, Scope S, Priority P7

## Overview

Research agents currently return findings to the lead agent for transcription into `.work/<name>/research/NN-topic.md` files. This creates a bottleneck: the lead must context-switch between managing research and manually writing notes. C5 changes the protocol so research agents write their own note files directly, leaving the lead to synthesize the handoff prompt from written artifacts rather than from agent return messages.

## Scope

**In scope:**
- Agent prompt template for research note writing
- Changes to the research step instructions in `commands/work-deep.md`
- Research note file format and index format
- Lead synthesis responsibilities after agent completion

**Out of scope:**
- Changes to other steps (plan, spec, decompose, implement, review)
- Research note quality review (already handled by existing Phase B quality review at the research-to-plan gate)
- Skill-based agent routing (C8, Phase 3)
- Memory integration for cross-session research context (C11, Phase 4)

## Implementation Steps

### Step 1: Define the research agent prompt template

Add a subsection to the research step in `commands/work-deep.md` that specifies the prompt pattern the lead must use when spawning research agents.

The prompt template must include:
- **Task context**: 2-3 sentence summary of the initiative, current goals, and what has been explored so far
- **Topic scope**: Specific area to investigate, bounded by what questions to answer
- **Target file path**: Absolute path to the research note file the agent must write (e.g., `.work/<name>/research/03-hook-patterns.md`)
- **Index entry format**: The exact markdown table row the agent must append to `research/index.md`
- **Note format**: The structure the research note must follow (see Step 2)

**AC-01**: `Research agent prompt template in work-deep.md contains all five required fields (task context, topic scope, target file path, index entry format, note format)` -- verified by `structural-review`

### Step 2: Define the research note format

Each agent-written research note follows this structure:

```markdown
# <Topic Title>

## Questions
- <What this research set out to answer>

## Findings
<Structured findings with evidence — code references, file paths, doc citations>

## Implications
- <How findings affect architecture or implementation decisions>

## Open Questions
- <Unresolved items that need further investigation or planning input>
```

**AC-02**: `Research note format is documented in the research step instructions and contains all four sections (Questions, Findings, Implications, Open Questions)` -- verified by `structural-review`

### Step 3: Define agent file-writing responsibilities

Update the research step process to specify that each spawned Explore agent:
1. Writes its research note to the target file path provided in the prompt
2. Appends its index entry to `.work/<name>/research/index.md`
3. If the agent discovers a dead end, appends to `.work/<name>/research/dead-ends.md` instead of (or in addition to) writing a note
4. If the agent discovers a future enhancement, appends to `.work/<name>/futures.md`

The lead does NOT transcribe agent findings. If an agent fails to write its file (e.g., crashes, times out), the lead re-spawns it with the same prompt.

**AC-03**: `Research step instructions explicitly state that agents write files directly and the lead does not transcribe` -- verified by `structural-review`

### Step 4: Redefine lead responsibilities during research

Update the research step to clarify what the lead does after agents complete:

1. **Verify coverage**: Check that all planned topics have notes in `research/` and entries in `index.md`
2. **Identify gaps**: If any topic was missed or a note is incomplete, re-spawn the agent
3. **Synthesize handoff prompt**: Write `.work/<name>/research/handoff-prompt.md` by reading the agent-written notes and producing:
   - Cross-references between topics (connections agents could not see individually)
   - Dependency relationships discovered across notes
   - Consolidated open questions (deduplicated, prioritized)
   - Research coverage summary (what was investigated, what was skipped and why)
4. The lead does NOT copy findings into the handoff — it references note file paths

**AC-04**: `Research step instructions list four specific lead synthesis responsibilities (verify coverage, identify gaps, synthesize handoff, reference-not-copy)` -- verified by `structural-review`

### Step 5: Update the research step text in work-deep.md

Apply all changes from Steps 1-4 to the `When current_step = "research"` section of `commands/work-deep.md`. The updated process flow becomes:

1. Read the task context (unchanged)
2. Plan research topics and assign file paths (new — explicit topic planning before spawning)
3. Spawn Explore agents with the prompt template from Step 1 (changed — agents write files directly)
4. After agents complete, verify coverage and re-spawn if needed (new)
5. Synthesize handoff prompt (changed — reference-based, not transcription-based)
6. Dead ends and futures handling (unchanged in behavior, clarified as agent responsibility)
7. Auto-advance with quality review (unchanged)

**AC-05**: `Updated research step in work-deep.md follows the 7-point process flow and is consistent with the Inter-Step Quality Review Protocol` -- verified by `structural-review`

**AC-06**: `No changes to steps other than research in work-deep.md` -- verified by `structural-review`

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| Research agent prompt template | Lead agent during research step | Structured prompt with 5 required fields |
| Research note format | Research agents | 4-section markdown structure for findings |
| Lead synthesis protocol | Lead agent after agents complete | Reference-based handoff, not transcription |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| Research step routing | `commands/work-deep.md` | Step Router dispatches to research section |
| Inter-Step Quality Review Protocol | `commands/work-deep.md` | Phase A + B review at research-to-plan gate |
| Research index format | Existing convention | `research/index.md` markdown table |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update `When current_step = "research"` section with agent-writes-directly protocol |

## Testing Strategy

| What | Method | Pass Criteria |
|------|--------|---------------|
| Prompt template completeness | `structural-review` | Template contains all 5 fields from Step 1 |
| Note format documented | `structural-review` | Format section has all 4 required sections |
| Lead responsibilities clear | `structural-review` | Four synthesis responsibilities listed |
| No side effects | `structural-review` | Other steps in work-deep.md are unchanged |
| Integration | `integration-test` | Run `/work-deep` on a test task in research step; verify agents write files directly and lead produces a reference-based handoff |

## Advisory Notes Resolution

No advisory notes from the plan-to-spec gate review apply directly to C5. The spec is self-contained within the research step of `commands/work-deep.md`.
