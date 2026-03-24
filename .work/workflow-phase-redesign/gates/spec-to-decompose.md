# Gate: Spec → Decompose (W3 Workflow Phase Redesign)

## Summary

Spec step produced 9 specification documents (1 cross-cutting contracts + 8 component specs) across 3 implementation phases. Resolved 9 design decisions deferred from planning: ASK verdict UX, static risk classification, explore clarity as within-step protocol, clarity vs inline research distinction, finding resolution criteria, Tier R no-gates lifecycle, skippable Phase 0 elicitation, and T2 risk mappings. 2 new futures added (automated framing selection, Tier R→T2/T3 escalation).

Artifacts:

- `.work/workflow-phase-redesign/specs/00-cross-cutting-contracts.md` — ASK format, risk table, inline research constraints
- `.work/workflow-phase-redesign/specs/01-state-schema-extensions.md` through `08-adversarial-eval-improvements.md` — 8 component specs
- `.work/workflow-phase-redesign/specs/index.md` — spec tracking table
- `.work/workflow-phase-redesign/specs/handoff-prompt.md` — handoff for decompose step
- `docs/feature/workflow-phase-redesign.md` — updated with "Resolved During Spec" decisions

## Review Results

### Phase A -- Artifact Validation

**Verdict**: ASK (resolved)

| Item | Status | Notes |
|------|--------|-------|
| All specs reference Spec 00 | PASS | Specs 01-07 declare Spec 00 dependencies; Spec 08 correctly declares "None" (self-contained) |
| Path conventions consistent | PASS | All paths follow `claude/` root consistently |
| All state.json fields declared | PASS | Verdict types, Tier R schema, ceremony config all documented |
| Code examples match behavior | PASS | ASK format, risk table, questionnaire, gate file structure all match |
| Testing strategies concrete | PASS | Grep verification, scenario walkthroughs, template checks — all actionable |
| Edge cases documented | PASS | Max caps, invalid states, override interactions all covered |

**Resolved Ask**: Spec 07 incorrectly listed Spec 00 (ASK verdict format) as a cross-cutting contract dependency. Tier R uses Spec 04's clarity questionnaire for scope validation, not ASK verdicts. Fixed: removed Spec 00 reference, updated to "None (scope validation uses Spec 04 clarity questionnaire, not ASK verdicts)".

### Phase B -- Quality Review

**Verdict**: PASS

| Item | Status | Notes |
|------|--------|-------|
| Acceptance criteria testable and unambiguous | PASS | All specs use grep-verifiable criteria, exact string matching, section existence checks |
| Interface contracts consistent (no divergent copies) | PASS | ASK format defined once in Spec 00, consumed by reference; risk table extended (not duplicated) by Spec 03 |
| Error paths and fail-closed behavior | PASS | Ambiguity defaults to ASK, BLOCKING has retry limits, resolution capped, audit trails preserved |
| Implementation steps ordered correctly | PASS | Phase 1→2→3 dependency chain correct; within-spec ordering respects dependencies |
| Specs avoid over-engineering | PASS | Static risk, inline protocols, capped mechanisms, complexity deferred to futures |

**Minor observations (non-blocking)**:
1. Spec 03 Step 6 (T2 risk mappings) listed after command updates — works because Step 1 AC-1.3 already adds T2 rows, but could be reordered for clarity
2. Spec 00 risk table is T3-focused; T2 entries added by Spec 03 — intentional separation of concerns
3. Tier R doesn't specify behavior for insufficient research — intentional lightweight design (synthesize works with whatever research produced)

## Advisory Notes

1. Spec 03 Step 6 ordering: An implementer reading linearly may wonder why T2 risk mappings are defined after command updates that reference them. Step 1 AC-1.3 handles this, but consider reordering during decompose for clarity.

## Deferred Items

- 3 items deferred from specs to futures.md: dynamic risk classification, automated adversarial eval framing selection, Tier R→T2/T3 escalation
- Phase B minor observations noted above are implementation awareness items for the decompose step

## Next Step

The **decompose** step will break the 8 component specs into executable work items with beads issues and a concurrency map. Phase 1 is sequential (C01→C02, single stream). Phase 2 can parallelize: C03+C06 independent of C04→C05. Phase 3 can parallelize: C07 and C08 independent. File conflicts (work-deep.md touched by 4 Phase 2 specs) must be sequenced within streams.

## Your Response

<!-- Review the above and respond here:
     - "approved" to advance
     - Questions or feedback (will trigger discussion)
-->
