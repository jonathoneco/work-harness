# Review and Finding Lifecycle

## Questions Investigated

1. How does the phase-review skill structure Phase A (artifact validation) vs Phase B (quality review)?
2. How are findings categorized (PASS, ADVISORY, BLOCKING)?
3. When do reviews happen — mid-conversation or at step transitions?
4. How does the current review timing feel — does it interrupt flow?
5. What does "aggressive Phase B finding resolution" mean in practice — what findings get deferred that shouldn't?
6. How does the gate protocol work and how do reviews integrate with gate creation?

---

## Findings

### Phase A vs Phase B Structure

**Phase A -- Artifact Validation** (Explore agent, read-only)
- Purpose: "Did you produce what you said you would?"
- Checks: deliverable existence, indexing, naming conventions
- Scope: structural completeness only — no quality judgment
- Verdict: PASS, ADVISORY, or BLOCKING
- Failure mode: Typically structural (missing files) — fixed once, not retried in loop

**Phase B -- Quality Review** (step-appropriate agent, read-only)
- Purpose: "Is what you produced good enough?"
- Checks: substance, code quality (8 universal rules from code-quality skill), architecture alignment
- Agent type: Varies by transition (Plan agent for spec/decompose, Review agent for implement phase)
- Verdict: PASS, ADVISORY, or BLOCKING
- Failure mode: Substantive issues that require fixing and re-review
- Max retries: 2 attempts on BLOCKING findings — after 2 fixes, escalate to user if still BLOCKING

### Finding Categorization

**Verdict Levels (Phase A & B):**
- **PASS**: No issues found. Proceed to approval ceremony.
- **ADVISORY**: Minor notes that don't block progress. Log in gate description, include full text in summary, proceed to approval.
- **BLOCKING**: Substantive issues that must be fixed. Lead agent fixes or directs subagent. Re-run Phase B. Max 2 attempts.

**Finding Severity (Finding Lifecycle):**
- **Critical**: Must fix immediately. Creates beads issue with P1. Blocks review step completion.
- **Important**: Should fix. Creates beads issue with P2. Does NOT block review step completion, but blocks archive.
- **Suggestion**: Optional improvements. No beads issue created.

**Important distinction**: A **Phase B verdict** (BLOCKING verdict) is different from **finding severity** (critical/important/suggestion). Phase B is about step transition gates. Finding severity is about lifecycle priority.

**Finding Status (lifecycle):**
- **OPEN**: New finding in first review, or not mentioned in re-review
- **FIXED**: Agent confirmed fix in re-review
- **PARTIAL**: Agent confirmed partial fix in re-review
- **NEW**: Finding identified in re-review (not from first pass)

### Review Timing and Triggering

**Two distinct review contexts:**

1. **Step Transitions** (automatic, mandatory)
   - Runs at every step boundary in every tier
   - Phase A: Explore agent validates artifacts
   - Phase B: step-appropriate agent evaluates quality
   - No user interaction — reviews are "self-driven"
   - Results presented in approval ceremony (hard stop, waits for user)
   - Gate files created BEFORE user approval (Tier 3 only)

2. **Ad-Hoc Review** (`/work-review` command)
   - Manual trigger, can run any time (not just step transitions)
   - Spawns specialist agents based on file changes (uses `review_routing` from harness.yaml)
   - Findings collected in `.work/<name>/review/findings.jsonl` (append-only)
   - Finding IDs assigned centrally: `f-YYYYMMDD-NNN`
   - Re-review: agents check existing OPEN findings, mark FIXED/PARTIAL
   - Creates beads issues for critical/important findings automatically

**No mid-conversation reviews** — Phase A/B are step-transition only. Ad-hoc reviews run via `/work-review`.

### Approval Ceremony: Flow Interruption

The approval ceremony is **a hard stop**:
1. Summary presented (artifacts produced, review results, advisory notes, deferred items, next step)
2. **Stop and wait**. Do NOT update state, create gates, or write anything else.
3. User responds with approval signal or questions
4. If questions: answer and re-present confirmation prompt
5. If approval: proceed to gate creation, state update, compaction

**Flow impact**: The ceremony guarantees user review before advancing, but creates a context switch. Developer must context-switch to review gate files in editor, provide feedback, then return to terminal. For Tier 3 (multi-session), this is less disruptive. For Tier 2 (quick feature), the hard stop may feel heavy if reviews are clean.

**Gate files (Tier 3 only)** become the primary review artifact — user reads in editor rather than terminal scroll. This improves UX for complex reviews.

### Finding Resolution Lifecycle

**First Review (`/work-review` or step transition):**
- Agents spawn, analyze changes, return findings
- Command assigns sequential IDs: `f-YYYYMMDD-NNN`
- All findings written to `.work/<name>/review/findings.jsonl` with `status: "OPEN"`
- Findings.jsonl is append-only — never modify in place
- Critical/important findings create beads issues automatically

**Re-Review (agent checks existing OPEN findings):**
- Agents provided with list of OPEN findings from prior review
- Agent checks if each has been fixed
- For each finding:
  - Agent returns `[FIXED]`: append new line with same ID, `status: "FIXED"`, `resolved_at: now`
  - Agent returns `[PARTIAL]`: append new line with same ID, `status: "PARTIAL"`, `resolved_at: now`
  - Agent doesn't mention it: remains OPEN (no new line)
- New findings from re-review written with `status: "NEW"` (not "OPEN")

**"Aggressive Phase B finding resolution"** is implicit:
- Phase B has max 2 retry attempts — if still BLOCKING after 2 fixes, escalate immediately (don't loop)
- Finding resolution is **required for step transition** (Phase B verdict must be PASS/ADVISORY, not BLOCKING)
- But finding resolution is **not enforced across sessions** — OPEN findings can persist across `/work-review` calls if not fixed

**Problem**: Findings that are OPEN in findings.jsonl don't automatically block `/work-archive`. Only findings with `status: "OPEN"` where severity is critical/important would block. But the distinction is fuzzy: a finding can be OPEN forever if the developer doesn't re-run `/work-review` to confirm it's still open or fixed.

### Gate Protocol Integration

**Gate file structure** (Tier 3 only):
- File path: `.work/<name>/gates/<from>-to-<to>.md` (step transition) or `.work/<name>/gates/implement-phase-<N>.md` (phase)
- Sections: Summary, Review Results (Phase A + Phase B), Advisory Notes, Deferred Items, Next Step, Your Response
- Review Results section includes Phase A and Phase B verdicts and per-item details

**Iteration protocol**:
- User provides feedback → round marker added to gate file under "Your Response"
- Agent's response added under the round marker
- Gate file updated with latest feedback, response, and decision (approved/rejected/deferred)

**Immutability**: Once a gate file is approved, it's never modified again. Historical record of the decision.

**Rollback gates**: If implementation reveals plan needs revision, create new gate file that references the original and explains what's changing. Original gate file stays unchanged.

---

## Implications

### For Review UX

1. **Phase A-B separation is sound**: Artifact validation before quality assessment prevents wasted quality review on incomplete deliverables. But adds overhead — two agent spawns instead of one.

2. **Hard approval ceremony guarantees awareness**: User must acknowledge before advancing. Good for high-stakes transitions (research→plan), may feel heavy for low-stakes (implement phase→phase).

3. **Gate files improve transparency** (Tier 3): Primary review artifact is human-readable file, not terminal scroll. User can review in their editor, compare to code changes side-by-side.

4. **Finding lifecycle is durable**: Append-only `.jsonl` prevents accidental data loss. Re-review tracking (FIXED/PARTIAL/NEW) gives clear history. But status tracking requires discipline — if developer doesn't re-run `/work-review`, old OPEN findings persist silently.

### For Finding Management

1. **Critical/important findings auto-create beads issues**: Safety net for tracking. But decouples findings.jsonl from beads — they can drift if one is updated without the other.

2. **Re-review is optional, not automatic**: Developer must manually run `/work-review` to confirm findings are fixed. Findings don't auto-expire if code changes. Risk: developer thinks they fixed something but never confirms.

3. **Phase B verdict ≠ finding severity**: A Phase B verdict of BLOCKING means "can't advance this step", not "critical finding". Could cause confusion. Example: Phase B blocks on a suggestion-level lint issue (BLOCKING verdict), but once fixed, the advisory note carries forward as a reminder.

4. **Finding deferred handling is unclear**: Gate protocol has "Deferred Items" section but no enforcement. Items can be marked deferred and never come back. No auto-creation of follow-up issues.

### Flow Interruption Points

1. **Step transition approval ceremony**: Hard stop for user acknowledgment. User must read gate file and respond before advancing.
   - Impact: Context switch away from implementation
   - Mitigation: Gate files are self-contained, readable in editor
   - Concern: For quick features (Tier 2), may feel like overhead

2. **Phase B blocking verdict retry loop**: Lead agent fixes, re-runs Phase B, up to 2 times. If still blocking, escalates to user.
   - Impact: Pulls implementation sideways into unexpected review cycles
   - Concern: What if the blocking issue requires architecture change? Could be 3-4 iterations before escalation.

3. **Finding re-review requires manual trigger**: No automatic detection of "which findings are still open". Developer must explicitly run `/work-review` again.
   - Impact: Old findings can lurk and be forgotten
   - Concern: Review findings that were "will fix later" can drop out of view

### Potential Friction Points

1. **Phase B max 2 retries**: Clear boundary, but what if the 2nd fix attempt reveals a deeper issue? Escalation to user loses momentum.

2. **Advisory notes in gate files**: Included in summary, but how strongly do they guide next step? Advisory notes that later become blocking findings suggest missed validation.

3. **OPEN vs NEW finding distinction**: Re-review distinguishes OLD findings (OPEN from prior pass) vs NEW findings (found in re-review). But no auto-link between them — developer must manually track "this NEW finding is really the same issue as f-20260314-001 in a different place".

---

## Open Questions

1. **When should Phase A/B run?**
   - Current: mandatory at every step transition
   - Alternative: skip Phase A if artifact already validated in prior step?
   - Alternative: Phase B optional for low-risk transitions (e.g., implement phase 3→4)?

2. **Does the approval ceremony interrupt too much?**
   - Current: hard stop, user must read gate file and respond
   - Alternative: gate file auto-appended to, user reviews asynchronously, responds when ready?
   - Alternative: auto-approval if Phase A/B PASS, require approval only if ADVISORY/BLOCKING?

3. **How should deferred items be tracked?**
   - Current: listed in gate file, no enforcement
   - Alternative: auto-create beads issues for deferred items?
   - Alternative: create a "deferred" label in beads and tag them?

4. **Should finding lifecycle auto-expire or auto-confirm?**
   - Current: OPEN findings persist until explicitly marked FIXED by re-review
   - Alternative: auto-expire OPEN findings if code diff includes the file/line where finding was reported?
   - Alternative: auto-create beads issues for OPEN findings after N days?

5. **Should Phase B verdict affect finding severity?**
   - Current: Phase B verdict (BLOCKING) and finding severity (critical/important/suggestion) are independent
   - Should a BLOCKING Phase B verdict auto-create a critical finding?
   - Or should they remain separate (phase gate vs. lifecycle gate)?

6. **Aggressive Phase B finding resolution — what does it mean?**
   - Spec says "what findings get deferred that shouldn't"
   - Current: Phase B findings either block transition (must fix) or are advisory (can proceed)
   - Are there findings that are currently advisory but should block? (e.g., security issues)
   - Or are there findings that are currently required to fix but should be deferred? (e.g., refactoring-while-fixing)

7. **Should re-review findings (NEW status) get different handling than first-pass findings?**
   - Current: NEW findings are treated same as OPEN (can be critical/important/suggestion)
   - Alternative: flag NEW findings differently to indicate "this was found later, worth double-checking"?

8. **How does the 2-retry limit for Phase B interact with deep issues?**
   - Current: max 2 retries, then escalate to user
   - What if issue requires spec change (e.g., decompose step Phase B blocks because implementation is not feasible)?
   - Current spec says escalate, but does this mean rollback to plan/spec?

