# Spec 06: Phase B Finding Resolution

**Component**: C06
**Phase**: 2 (Workflow Mechanics)
**Dependencies**: C02 (Spec 02 — verdict system redesign)
**Cross-cutting contracts**: Spec 00 — ASK verdict format (for findings that need user judgment)

## Overview and Scope

**Does**:
1. Add an immediate resolution protocol to `phase-review.md` for Phase B findings during implementation phases
2. Update implement step section in `work-deep.md` to support inline finding resolution
3. Define criteria for which findings can be resolved immediately vs deferred to review

**Does NOT**:
- Change findings during non-implementation phases (research→plan, plan→spec findings are handled by verdicts, not finding resolution)
- Remove the review step or reduce its scope (review still catches what was missed)
- Auto-expire findings based on git diff (deferred — see futures.md)
- Change the findings.jsonl format or finding lifecycle

## Implementation Steps

### Step 1: Define immediate resolution criteria

**Action**: Establish clear rules for which Phase B findings can be resolved during implementation vs which must be deferred to the review step.

**Acceptance criteria**:
- [ ] AC-1.1: Immediate resolution criteria are defined as ALL of:
  - Finding is about code in the current implementation scope (files being modified in this phase)
  - Fix does not require architectural changes (no new components, no interface changes)
  - Fix is localized (affects ≤3 files)
  - Finding is not a design concern (e.g., "this approach may not scale" is deferred, "this function doesn't handle the nil case" is immediate)
- [ ] AC-1.2: Deferred criteria are the inverse: cross-component, architectural, design-level, or out-of-scope findings are logged and deferred to the review step
- [ ] AC-1.3: If the implementer is unsure whether a finding qualifies for immediate resolution, they emit ASK to the user with the finding details and proposed fix

### Step 2: Add immediate resolution protocol to phase-review.md

**Action**: Add a section to `phase-review.md` describing the immediate resolution flow for implementation-phase transitions.

**Acceptance criteria**:
- [ ] AC-2.1: New section "Immediate Finding Resolution" exists, scoped to implementation phase transitions only (implement phase N→N+1, implement→review)
- [ ] AC-2.2: Protocol is: (1) Phase B reviewer identifies finding, (2) checks against immediate resolution criteria, (3) if qualifiable: fix inline, re-verify the specific fix, log as RESOLVED in gate file, (4) if not qualifiable: log as DEFERRED in gate file
- [ ] AC-2.3: Re-verification of immediate fixes is limited to the specific finding — not a full Phase B re-review
- [ ] AC-2.4: Maximum 3 immediate resolutions per transition (if more exist, defer the rest — too many inline fixes suggests deeper issues)

### Step 3: Update gate file format for finding resolution

**Action**: Extend the gate file to record finding resolution outcomes.

**Acceptance criteria**:
- [ ] AC-3.1: Gate file gains a `## Finding Resolution` section (after `## Resolved Asks`, before approval record)
- [ ] AC-3.2: Section format:
  ```markdown
  ## Finding Resolution

  ### Resolved Immediately
  1. **Finding**: [description]
     **Fix**: [what was changed]
     **Files**: [affected files]

  ### Deferred to Review
  1. **Finding**: [description]
     **Reason**: [why deferred — architectural, cross-component, etc.]
  ```
- [ ] AC-3.3: If no findings in either category, section is omitted
- [ ] AC-3.4: This section only appears in gate files for implementation transitions

### Step 4: Update work-deep.md implement step

**Action**: Update the implement step section in `work-deep.md` to reference the immediate resolution protocol.

**Acceptance criteria**:
- [ ] AC-4.1: Implement step notes that Phase B findings during implementation phases may be resolved immediately per the protocol in `phase-review.md`
- [ ] AC-4.2: The implement step does not duplicate the resolution criteria — it references `phase-review.md`
- [ ] AC-4.3: The Phase B pre-screen before the review step (existing behavior) now also considers previously-resolved findings as resolved

### Step 5: Update re-review threshold

**Action**: Define when accumulated deferred findings trigger an early re-review.

**Acceptance criteria**:
- [ ] AC-5.1: If more than 5 findings are deferred across implementation phases, a notification suggests running `/work-review` early
- [ ] AC-5.2: This is a suggestion, not a hard stop — the implementer may continue if the findings are non-blocking
- [ ] AC-5.3: The threshold is documented in `phase-review.md` alongside the immediate resolution protocol

## Interface Contracts

**Exposes**:
- Immediate finding resolution protocol in `phase-review.md` — available to any implementation-phase transition
- Gate file `## Finding Resolution` section format

**Consumes**:
- Spec 00, Contract 1: ASK verdict format (for findings that need user judgment before resolution)
- Spec 02: Updated verdict system (finding resolution integrates with the ASK flow)

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/phase-review.md` | Add "Immediate Finding Resolution" section with criteria, protocol, and re-review threshold |
| Modify | `claude/commands/work-deep.md` | Update implement step to reference immediate resolution protocol |

## Testing Strategy

1. **Criteria specificity**: Verify immediate resolution criteria are testable — each criterion has a clear yes/no answer
2. **Protocol completeness**: Walk through a finding that meets all immediate-resolution criteria — verify fix, re-verify, log path is complete
3. **Deferral path**: Walk through a finding that fails one criterion — verify it's logged as deferred
4. **ASK fallback**: Walk through an ambiguous finding — verify the implementer emits ASK to the user
5. **Cap enforcement**: Verify the max-3-immediate-resolutions-per-transition rule is documented
6. **Gate file format**: Verify the Finding Resolution section format is specified with both Resolved and Deferred subsections
7. **Re-review threshold**: Verify the 5-deferred-findings notification threshold is documented
