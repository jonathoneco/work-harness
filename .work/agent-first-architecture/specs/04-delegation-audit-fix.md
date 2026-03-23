# Spec 04: Delegation Audit & Fix (C4)

**Component**: C4 — Delegation Audit & Fix
**Scope**: Small
**Dependencies**: Spec 00 (cross-cutting contracts), Spec 01 (context seeding protocol)
**Phase**: 2

## Overview

Audit all existing agent spawning patterns across `work-deep.md`, `work-feature.md`, and `work-fix.md` against the context seeding protocol (spec 01). Fix gaps where agents receive inconsistent or incomplete context.

This is a targeted edit pass — each fix is a small change to an existing agent spawn to align it with the context seeding protocol. No new agent spawns are added.

---

## Implementation Steps

### Step 1: Audit existing agent spawns

Inventory every `Agent(...)` call or agent spawning instruction across the three command files. For each, check:

1. Does the agent receive the standard preamble (spec 00 §2)?
2. Does the agent receive the correct skill injection (spec 00 §3)?
3. Does the agent follow the per-step context table (spec 01) — receiving what it should and NOT receiving what it shouldn't?
4. Does the agent's prompt follow the section structure (spec 00 §1)?

### Step 2: Fix known gaps from research

The research step identified these specific gaps:

| Gap | Location | Fix |
|-----|----------|-----|
| Research agents: inconsistent skill injection | `work-deep.md` research step | Ensure all research Explore agents get `skills: [work-harness, code-quality]` in their prompt (as read instructions) |
| Implementation agents: stack context missing | `work-deep.md` implement step | Add stack context block (spec 00 §2) to stream agent prompts when `harness.yaml` exists |
| Review agents: architecture-decisions.md sometimes missing | `work-deep.md` Phase B agents | Ensure Phase B review agents always read `claude/skills/code-quality.md` |
| Tier 2 plan step: ad-hoc Explore agent context | `work-feature.md` plan step | Formalize the Explore agent prompt with standard preamble and skill injection |

### Step 3: Standardize prompt structure

For each agent spawn that doesn't follow spec 00 §1 section ordering, restructure the prompt. Focus on:
- Adding Identity section where missing
- Adding Task Context preamble where missing
- Ensuring Rules section uses skill injection pattern (not inline rule text)
- Ensuring Completion section defines expected return format

### Step 4: Verify no over-seeding

Check each agent spawn against the "Does NOT Receive" column in spec 01's per-step context table. Remove any context that agents shouldn't receive (e.g., research notes passed to implement agents).

---

## Interface Contracts

### Exposes
Nothing new — this spec fixes existing code to comply with specs 00 and 01.

### Consumes
- **Spec 00 §1**: Agent prompt structure (target format for all agent spawns)
- **Spec 00 §2**: Standard preamble template
- **Spec 00 §3**: Skill injection convention
- **Spec 01**: Per-step context table and anti-patterns

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/commands/work-deep.md` | Fix research, implement, and review agent spawns |
| Modify | `claude/commands/work-feature.md` | Fix Tier 2 plan step Explore agent and implement agent spawns |
| Modify | `claude/commands/work-fix.md` | Fix Tier 1 implement agent spawn (if any) |

---

## Testing Strategy

### Audit Checklist
- [ ] Every agent spawn in work-deep.md follows spec 00 §1 section ordering
- [ ] Every agent spawn includes standard preamble (spec 00 §2)
- [ ] Every agent spawn uses skill injection pattern (spec 00 §3)
- [ ] No agent receives context it shouldn't per spec 01 anti-patterns

### Before/After Comparison
For each modified agent spawn, verify:
- Agent still receives all necessary context for its task
- No context was accidentally removed
- Skill injection uses file references, not inline text

---

## Acceptance Criteria

- [ ] All research agent spawns in work-deep.md include consistent skill injection (code-quality + work-harness)
- [ ] All implement agent spawns include stack context when harness.yaml exists
- [ ] All Phase B review agents read code-quality.md
- [ ] Tier 2 plan step Explore agent has standard preamble and skill injection
- [ ] No agent spawn violates spec 01 anti-patterns (no over-seeding)
- [ ] Each modified agent spawn follows spec 00 §1 section ordering
