# Spec 02: Verdict System Redesign

**Component**: C02
**Phase**: 1 (Foundation)
**Dependencies**: C01 (Spec 01 — state schema extensions)
**Cross-cutting contracts**: Spec 00 — ASK verdict format, response recording, risk classification

## Overview and Scope

**Does**:
1. Replace ADVISORY with ASK in `phase-review.md` — the verdict protocol and agent instructions
2. Update `step-transition.md` — ASK verdict presentation, response collection, gate file recording
3. Define the interaction flow: Phase review → ASK questions → user response → gate recording → approval ceremony

**Does NOT**:
- Implement risk-based ceremony tiering (Spec 03)
- Change Phase A/B review structure (phases remain as-is)
- Modify retry logic for BLOCKING verdicts (unchanged: max 2 attempts)
- Change which agent types handle which transitions (mapping unchanged)

## Implementation Steps

### Step 1: Replace ADVISORY with ASK in phase-review.md

**Action**: Update the verdict type definitions, agent instructions, and retry logic in `phase-review.md`.

**Acceptance criteria**:
- [ ] AC-1.1: Verdict types section lists exactly three types: PASS, ASK, BLOCKING
- [ ] AC-1.2: ASK definition reads: "Specific questions requiring user response before the transition proceeds. Agent must provide 1-5 questions per Spec 00 format."
- [ ] AC-1.3: The string "ADVISORY" does not appear anywhere in `phase-review.md`
- [ ] AC-1.4: Phase A agent instructions include: "If structural issues require clarification (e.g., ambiguous file naming, missing but possibly intentional artifacts), emit ASK with specific questions rather than PASS with concerns or BLOCKING with assumptions"
- [ ] AC-1.5: Phase B agent instructions include: "If quality issues require the user's judgment (e.g., trade-off decisions, scope questions, priority calls), emit ASK rather than making the call yourself"

### Step 2: Update verdict flow in phase-review.md

**Action**: Update the verdict flow documentation to show ASK as an intermediate path between PASS and BLOCKING.

**Acceptance criteria**:
- [ ] AC-2.1: Flow diagram shows: Phase A → {PASS → Phase B, ASK → user response → Phase B, BLOCKING → fix → retry}
- [ ] AC-2.2: Flow diagram shows: Phase B → {PASS → ceremony, ASK → user response → record → ceremony, BLOCKING → fix → retry}
- [ ] AC-2.3: ASK verdicts from Phase A are resolved BEFORE Phase B begins (Phase B receives resolved context)
- [ ] AC-2.4: Retry loop documentation unchanged: "loop until PASS or ASK, or 2 BLOCKING attempts exhausted"

### Step 3: Update step-transition.md for ASK handling

**Action**: Add ASK verdict handling between the verdict receipt and approval ceremony stages in `step-transition.md`.

**Acceptance criteria**:
- [ ] AC-3.1: New section "ASK Verdict Resolution" exists between "Phase Review" and "Approval Ceremony" sections
- [ ] AC-3.2: Section describes: (1) present questions under `## Questions Before Advancing` heading, (2) hard stop for user response, (3) collect answers, (4) record in gate file per Spec 00 format
- [ ] AC-3.3: After all asks are resolved, flow proceeds to approval ceremony (existing behavior for PASS)
- [ ] AC-3.4: If user's response to an ASK reveals a new blocking issue, the agent may re-classify to BLOCKING and trigger a fix cycle

### Step 4: Update gate file writing in step-transition.md

**Action**: Extend the gate file creation logic to include the `## Resolved Asks` section.

**Acceptance criteria**:
- [ ] AC-4.1: Gate file template includes `## Resolved Asks` section per Spec 00 format
- [ ] AC-4.2: Section is populated only when ASK verdicts occurred; omitted entirely for pure PASS transitions
- [ ] AC-4.3: Both Phase A and Phase B asks are recorded with their responses

### Step 5: Update step-transition.md verdict references

**Action**: Replace all remaining ADVISORY references in `step-transition.md` with the new verdict handling.

**Acceptance criteria**:
- [ ] AC-5.1: The string "ADVISORY" does not appear anywhere in `step-transition.md`
- [ ] AC-5.2: Any logic that previously treated ADVISORY as "log and proceed" is replaced with ASK handling (present, collect, record)

## Interface Contracts

**Exposes**:
- Updated `phase-review.md`: Phase review protocol with PASS/ASK/BLOCKING verdicts
- Updated `step-transition.md`: Transition protocol with ASK resolution flow
- ASK verdict handling that downstream specs (03, 06) build upon

**Consumes**:
- Spec 00, Contract 1: ASK verdict format and response recording
- Spec 01: Updated `state-conventions.md` with ASK documentation

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/phase-review.md` | Replace ADVISORY with ASK in verdict types, agent instructions, and flow |
| Modify | `claude/skills/work-harness/step-transition.md` | Add ASK verdict resolution flow, update gate file template |

## Testing Strategy

1. **Grep verification**: Search both files for "ADVISORY" — should return 0 matches in each
2. **Verdict completeness**: Grep for "PASS", "ASK", "BLOCKING" in `phase-review.md` — all three must appear in verdict definitions
3. **Flow consistency**: Read the verdict flow in `phase-review.md` and verify ASK is an intermediate path (not terminal like PASS, not retry-loop like BLOCKING)
4. **Gate file template**: Verify `step-transition.md` gate file template includes `## Resolved Asks` with Phase A and Phase B subsections
5. **Section ordering**: Verify `step-transition.md` has ASK resolution BETWEEN phase review and approval ceremony
6. **End-to-end trace**: Walk through a hypothetical transition where Phase B returns ASK with 2 questions — verify the protocol covers: present questions → collect answers → record in gate → proceed to ceremony
