# Spec 01: State Schema Extensions

**Component**: C01 (originally "Step Lifecycle Extension")
**Phase**: 1 (Foundation)
**Dependencies**: None
**Cross-cutting contracts**: Spec 00 — ASK verdict recording format, risk classification table

> **Name correction**: DD-7 confirms the step lifecycle is unchanged (`not_started → active → completed`). This component is about extending `state-conventions.md` to document schemas used by the new verdict system and ceremony tiering — not about lifecycle changes.

## Overview and Scope

**Does**: Extends `state-conventions.md` with documentation for:
1. The new verdict type set (PASS/ASK/BLOCKING replacing PASS/ADVISORY/BLOCKING)
2. Gate file format extension for ASK response recording
3. Ceremony configuration schema
4. Tier R (research-only) step definitions for the future `work-research` command

**Does NOT**:
- Change the step lifecycle state machine (DD-7)
- Add new fields to the step status object in state.json
- Modify any command or skill files (those are handled by downstream specs)

## Implementation Steps

### Step 1: Update verdict type documentation

**Action**: In `state-conventions.md`, replace all references to the ADVISORY verdict with ASK.

**Acceptance criteria**:
- [ ] AC-1.1: The string "ADVISORY" does not appear anywhere in `state-conventions.md`
- [ ] AC-1.2: The verdict types listed are exactly: PASS, ASK, BLOCKING
- [ ] AC-1.3: ASK is described as: "Specific questions that must be answered before the transition proceeds. Responses recorded in the gate file."

### Step 2: Document gate file format extension

**Action**: Add a "Gate File Format" section to `state-conventions.md` documenting the structure of `.work/<name>/gates/<from>-to-<to>.md`, including the new `## Resolved Asks` section.

**Acceptance criteria**:
- [ ] AC-2.1: Gate file format section exists with the template from Spec 00, Contract 1
- [ ] AC-2.2: The section specifies that `## Resolved Asks` is present only when ASK verdicts occurred
- [ ] AC-2.3: The section documents placement: after verdict summary, before approval record

### Step 3: Document ceremony configuration

**Action**: Add a "Ceremony Configuration" section to `state-conventions.md` documenting the `workflow.ceremony` setting in `.claude/harness.yaml`.

**Acceptance criteria**:
- [ ] AC-3.1: Section documents `ceremony: auto` (default) and `ceremony: always` options
- [ ] AC-3.2: Section references the risk classification table from Spec 00, Contract 2

### Step 4: Add Tier R step definitions

**Action**: Add Tier R (research-only) to the step names table in `state-conventions.md`.

**Acceptance criteria**:
- [ ] AC-4.1: Step names table includes a row for Tier R with steps: `assess, research, synthesize`
- [ ] AC-4.2: Tier R is documented as created by the `work-research` command
- [ ] AC-4.3: The `tier` field documentation lists valid values as `1, 2, 3, "R"`

## Interface Contracts

**Exposes**:
- Updated `state-conventions.md` as the single source of truth for state schema, now including verdict types, gate file format, ceremony config, and Tier R

**Consumes**:
- Spec 00: ASK verdict recording format (Contract 1)
- Spec 00: Risk classification table (Contract 2)

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/references/state-conventions.md` | Replace ADVISORY with ASK in verdict types, add gate file format section, add ceremony config section, add Tier R step definitions |

## Testing Strategy

1. **Grep verification**: Search `state-conventions.md` for "ADVISORY" — should return 0 matches
2. **Grep verification**: Search `state-conventions.md` for "ASK" — should appear in verdict type definitions
3. **Section existence**: Verify "Gate File Format", "Ceremony Configuration" sections exist
4. **Tier R row**: Verify step names table has Tier R entry with correct steps
5. **Cross-reference**: Verify gate file format matches Spec 00, Contract 1 template exactly
