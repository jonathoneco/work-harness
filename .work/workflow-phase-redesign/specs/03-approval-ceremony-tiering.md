# Spec 03: Approval Ceremony Tiering

**Component**: C03
**Phase**: 2 (Workflow Mechanics)
**Dependencies**: C02 (Spec 02 — verdict system redesign)
**Cross-cutting contracts**: Spec 00 — risk classification table, `ceremony: always` override, auto-advance notification format

## Overview and Scope

**Does**:
1. Add risk-based ceremony logic to `step-transition.md` — auto-advance for low-risk PASS, hard stop for medium/high
2. Update `work-deep.md` transition sections to reference risk-based ceremony
3. Update `work-feature.md` transition sections to reference risk-based ceremony
4. Implement `ceremony: always` override from `harness.yaml`

**Does NOT**:
- Change verdict types (done in Spec 02)
- Change Phase A/B review logic (unchanged)
- Add dynamic risk classification (deferred — see futures.md)
- Modify the approval signal list (yes, proceed, approve, etc. — unchanged)

## Implementation Steps

### Step 1: Add risk classification logic to step-transition.md

**Action**: Add a "Risk Classification" section to `step-transition.md` with the static risk table and resolution rules from Spec 00, Contract 2.

**Acceptance criteria**:
- [ ] AC-1.1: Risk classification section exists with the full transition-to-risk mapping table
- [ ] AC-1.2: Section includes all four resolution rules (PASS+low, PASS+medium/high, ASK, BLOCKING)
- [ ] AC-1.3: The table covers all T2 transitions: plan→implement, implement→review
- [ ] AC-1.4: The table covers all T3 transitions: research→plan, plan→spec, spec→decompose, decompose→implement, implement phases, implement→review

### Step 2: Implement auto-advance for low-risk PASS

**Action**: Update the approval ceremony section in `step-transition.md` to skip the ceremony for low-risk PASS transitions.

**Acceptance criteria**:
- [ ] AC-2.1: When verdict is PASS and risk is low, the protocol emits the auto-advance notification (per Spec 00 format) and proceeds directly to state update
- [ ] AC-2.2: The notification includes verdict, risk level, and gate ID
- [ ] AC-2.3: No user input is solicited during auto-advance
- [ ] AC-2.4: Gate file and gate issue are still created for auto-advanced transitions (audit trail preserved)

### Step 3: Implement `ceremony: always` override

**Action**: Add override check at the start of the ceremony decision logic.

**Acceptance criteria**:
- [ ] AC-3.1: If `.claude/harness.yaml` contains `workflow.ceremony: always`, all transitions use hard stop ceremony regardless of risk level
- [ ] AC-3.2: Default behavior when `workflow.ceremony` is absent or set to `auto` is risk-based tiering
- [ ] AC-3.3: The override is checked once per transition, not per-phase

### Step 4: Update work-deep.md transition references

**Action**: Update the inter-step quality review instructions in `work-deep.md` to reference risk-based ceremony.

**Acceptance criteria**:
- [ ] AC-4.1: The inter-step quality review section references the risk classification in `step-transition.md` rather than hardcoding "approval ceremony" for all transitions
- [ ] AC-4.2: Implementation phase transitions (phase N→N+1, implement→review) are noted as low-risk auto-advance candidates
- [ ] AC-4.3: Research→plan and plan→spec transitions are noted as high-risk hard stops

### Step 5: Update work-feature.md transition references

**Action**: Update transition instructions in `work-feature.md` to reference risk-based ceremony.

**Acceptance criteria**:
- [ ] AC-5.1: The plan→implement transition in `work-feature.md` references the risk classification
- [ ] AC-5.2: T2 plan→implement maps to the same risk level as T3's equivalent early transition (medium risk — hard stop)
- [ ] AC-5.3: T2 implement→review maps to low risk (auto-advance candidate)

### Step 6: Define T2 risk mappings

**Action**: Add T2-specific rows to the risk classification table since T2 has fewer transitions.

**Acceptance criteria**:
- [ ] AC-6.1: Risk table includes: `plan → implement` (medium, hard stop) and `implement → review` (low, auto-advance)
- [ ] AC-6.2: T2 risk mappings are in the same table as T3 mappings, with a tier column or annotation

## Interface Contracts

**Exposes**:
- Risk-based ceremony protocol in `step-transition.md` — consumed by any command that triggers step transitions
- `ceremony: always` override mechanism

**Consumes**:
- Spec 00, Contract 2: Risk classification table and resolution rules
- Spec 02: Updated verdict system (ASK handling must complete before ceremony decision)

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/step-transition.md` | Add risk classification section, modify approval ceremony to support auto-advance, add `ceremony: always` check |
| Modify | `claude/commands/work-deep.md` | Update inter-step review instructions to reference risk-based ceremony |
| Modify | `claude/commands/work-feature.md` | Update transition instructions to reference risk-based ceremony |

## Testing Strategy

1. **Table completeness**: Verify risk table covers every valid step transition for T2 and T3
2. **Auto-advance path**: Walk through an implement→review transition with PASS verdict — should auto-advance with notification, no approval prompt
3. **Hard stop path**: Walk through a research→plan transition with PASS verdict — should show approval ceremony
4. **ASK override**: Walk through a low-risk transition with ASK verdict — should hard stop despite low risk
5. **ceremony: always**: Simulate `ceremony: always` config — verify all transitions show approval ceremony
6. **Gate file creation**: Verify gate files are still created for auto-advanced transitions
