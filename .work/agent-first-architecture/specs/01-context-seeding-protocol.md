# Spec 01: Context Seeding Protocol (C2)

**Component**: C2 — Context Seeding Protocol
**Scope**: Small
**Dependencies**: Spec 00 (cross-cutting contracts)
**Phase**: 1

## Overview

Define a referenceable protocol for seeding step agents with exactly the right context. This is a **documentation artifact** — a new skill file at `claude/skills/work-harness/context-seeding.md` — consumed by command files when constructing agent prompts.

The protocol standardizes what each step agent receives and, critically, what it does NOT receive. Handoff prompts are the only bridge between steps (D2 from architecture).

---

## Implementation Steps

### Step 1: Create the context seeding skill file

**File**: `claude/skills/work-harness/context-seeding.md` (new)

**Contents:**

#### 1.1 Standard Preamble

The preamble template from spec 00 §2, formatted as a referenceable block that dispatchers copy when constructing prompts.

#### 1.2 Per-Step Context Table

| Step | Primary Input | Additional Context | Does NOT Receive |
|------|--------------|-------------------|------------------|
| Research | Task description from state.json | Topic assignments, output format template | Prior step artifacts (none exist) |
| Plan | `.work/{name}/research/handoff-prompt.md` | — | Individual research notes, raw research data |
| Spec | `.work/{name}/plan/handoff-prompt.md` | `.work/{name}/specs/architecture.md` | Research notes, raw plan discussion |
| Decompose | `.work/{name}/specs/handoff-prompt.md` | All spec files (`specs/*.md`) | Research notes, plan notes |
| Implement | `.work/{name}/streams/handoff-prompt.md` | Stream doc, relevant specs only | Other streams' docs, research/plan notes |
| Review | Full diff (`git diff {base_commit}...HEAD`) | Findings template, quality checklist | Step-internal artifacts |

**Key rule**: The "Does NOT Receive" column is as important as what agents DO receive. Over-seeding wastes context and confuses agents.

#### 1.3 Handoff Prompt Contract

Handoff prompts follow a consistent structure:

```markdown
# {Step} Handoff: {Task Title}

## What This Step Produced
{Summary of artifacts, decisions, key findings}

## Key Artifacts
{List of file paths with one-line descriptions}

## Decisions Made
{Numbered list of decisions with brief rationale}

## Open Questions / Deferred Items
{Items the next step should address}

## Instructions for {Next Step} Step
{Numbered instructions specific to the next step}
```

The handoff prompt is the ONLY bridge between steps. It references file paths to artifacts — it does not copy artifact content inline.

#### 1.4 Rule File Injection

Every agent reads rule files via the skill injection pattern (spec 00 §3). The per-step skill matrix from spec 00 §3 defines which skills each step reads.

#### 1.5 Managed Docs Injection (conditional)

If `.claude/harness.yaml` exists and defines `docs.managed`:
- The lead reads the managed doc paths
- Includes a "Managed Project Docs" section in the agent's Instructions with the file paths
- The agent reads these files as part of its work

If no `harness.yaml`: skip entirely. Do not reference managed docs.

#### 1.6 Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|-------------|----------------|-----------------|
| Copying research notes into plan agent prompt | Wastes context, bypasses handoff firewall | Reference handoff prompt only |
| Including ALL spec files in implement agent prompt | Agent only needs its stream's specs | Include only relevant specs per stream |
| Passing conversation history to agents | Agents are stateless, conversation is lead-specific | Use handoff prompts and state.json only |
| Injecting rules as inline text | Duplicates content, risks divergence | Use skill injection (read file references) |
| Including futures.md in step agent prompts | Futures are deferred items, not actionable context | Only the lead manages futures |

### Step 2: Register in work-harness skill index

Add a reference to `context-seeding.md` in `claude/skills/work-harness.md` so it's discoverable.

---

## Interface Contracts

### Exposes
- **Standard preamble template**: Used by spec 02 (prompt templates) and spec 03 (dispatcher) to construct agent prompts
- **Per-step context table**: Used by spec 03 (dispatcher) to determine what to pass to each step agent
- **Anti-patterns list**: Used by spec 04 (delegation audit) to check existing agent spawns

### Consumes
- **Spec 00 §2**: Standard preamble format
- **Spec 00 §3**: Skill injection convention
- **State.json fields**: From spec 00 §8

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/context-seeding.md` | Context seeding protocol definition |
| Modify | `claude/skills/work-harness.md` | Add reference to context-seeding.md |

---

## Testing Strategy

### Verification Checklist
- [ ] Every step in the per-step context table has a defined primary input
- [ ] Every step has a "Does NOT Receive" column entry
- [ ] The handoff prompt contract matches the structure used by existing handoff prompts (`.work/agent-first-architecture/research/handoff-prompt.md` and `plan/handoff-prompt.md`)
- [ ] Anti-patterns list covers the common mistakes observed in current ad-hoc delegation
- [ ] Skill injection list matches spec 00 §3 per-step skill matrix

### Integration Test
After implementation, the dispatcher (spec 03) should be able to construct a complete agent prompt by:
1. Reading state.json for preamble variables
2. Referencing context-seeding.md for per-step context rules
3. Using spec 02 templates for step-specific instructions
No ad-hoc context assembly should be needed.

---

## Acceptance Criteria

- [ ] `context-seeding.md` exists at `claude/skills/work-harness/context-seeding.md`
- [ ] Standard preamble template matches spec 00 §2 exactly
- [ ] Per-step context table covers all 6 delegated steps (research, plan, spec, decompose, implement, review)
- [ ] Handoff prompt contract is documented with required sections
- [ ] Anti-patterns list has ≥5 entries with rationale
- [ ] `work-harness.md` references `context-seeding.md`
