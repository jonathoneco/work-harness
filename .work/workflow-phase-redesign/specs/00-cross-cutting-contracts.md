# Spec 00: Cross-Cutting Contracts

Shared schemas, conventions, and interface contracts consumed by multiple component specs. All specs reference this document for common formats.

## Contract 1: ASK Verdict Format and Response Recording

_Consumers: Spec 02 (verdict system), Spec 03 (ceremony tiering), Spec 06 (finding resolution)_

### Verdict Output Format

Phase review agents (Phase A and Phase B) emit ASK verdicts in this format:

```
**Verdict**: ASK

**Questions**:
1. [Question text — specific, actionable, answerable]
2. [Question text]
...

**Context**: [Why these questions matter for the transition]
```

**Rules**:
- Each question must be answerable in 1-3 sentences
- Maximum 5 questions per ASK verdict (prioritize by impact if more exist)
- Questions must reference specific artifacts, decisions, or gaps — not vague concerns
- An ASK with 0 questions is invalid — emit PASS instead

### Presentation to User

When the step-transition protocol receives an ASK verdict:

1. Present all questions in a numbered list under a `## Questions Before Advancing` heading
2. Hard stop — no timeout, no auto-advance
3. User may answer inline (all at once) or ask for clarification on specific questions
4. Each question is resolved when the user provides an answer or explicitly acknowledges the concern ("acknowledged", "yes that's fine", etc.)

### Response Recording in Gate File

Gate files (`.work/<name>/gates/<from>-to-<to>.md`) gain a `## Resolved Asks` section:

```markdown
## Resolved Asks

### Phase A Asks

_(none)_

### Phase B Asks

**Q1**: [Original question text]
**A1**: [User's response — verbatim or summarized]

**Q2**: [Original question text]
**A2**: [User's response]
```

Placement: after the verdict summary, before the approval record. If no ASK items exist for either phase, that subsection shows `_(none)_`. If neither phase has ASKs, the entire section is omitted.

### State Tracking

ASK resolution is recorded only in gate files. The step status object in `state.json` gains no new fields for ASK tracking. The existing `gate_file` field already points to where asks are recorded.

**Rationale**: ASK responses are qualitative text, not structured data. They belong in the markdown gate file, not the JSON state model.

---

## Contract 2: Risk Classification Table

_Consumers: Spec 03 (ceremony tiering)_

Step transitions have a static risk level that determines approval ceremony weight:

| Transition              | Base Risk | Ceremony on PASS |
|-------------------------|-----------|------------------|
| research → plan         | high      | hard stop        |
| plan → spec             | high      | hard stop        |
| spec → decompose        | medium    | hard stop        |
| decompose → implement   | medium    | hard stop        |
| implement phase N → N+1 | low       | auto-advance     |
| implement → review      | low       | auto-advance     |

### Risk Resolution Rules

1. **PASS + low risk**: auto-advance with notification (no user input)
2. **PASS + medium/high risk**: hard stop approval ceremony
3. **ASK** (any risk): hard stop — resolve asks first, then approval ceremony
4. **BLOCKING** (any risk): hard stop — fix issues, retry review (max 2 attempts)

### `ceremony: always` Override

Users may set `ceremony: always` in `.claude/harness.yaml` to force hard stops on all transitions:

```yaml
workflow:
  ceremony: always  # Options: "auto" (default, risk-based), "always"
```

When set:
- All PASS verdicts require approval ceremony (no auto-advance)
- ASK and BLOCKING behavior unchanged (already hard stops)

### Auto-Advance Notification Format

When auto-advancing (low-risk PASS, no `ceremony: always`):

```
Phase review passed — advancing to {next_step}
  Verdict: PASS | Risk: low | Gate: {gate_id}
```

Informational only. No user input required.

---

## Contract 3: Plan Agent Inline Research Constraints

_Consumers: Spec 05 (plan agent redesign)_

When the plan agent encounters gaps in the research handoff, it may spawn Explore subagents under these constraints:

| Constraint      | Limit                                    |
|-----------------|------------------------------------------|
| Max subagents   | 3 per plan agent invocation              |
| Scope per agent | Single targeted question                 |
| Return format   | Summary, max 1,500 tokens per agent      |
| Allowed tools   | Read-only (Glob, Grep, Read, Bash read)  |
| Prohibited      | Write, Edit, Agent (no nested spawning)  |

### Usage Protocol

1. Plan agent identifies a specific gap in the research handoff
2. Plan agent spawns an Explore subagent with a targeted question
3. Subagent returns a summary within token cap
4. Plan agent incorporates findings into the architecture document
5. Plan agent notes inline-researched gaps in the handoff prompt under "Inline Research Performed"

### When NOT to Use Inline Research

- Research was fundamentally insufficient (key topics not covered) — the plan→spec gate catches this
- Gap requires user input (business decision, priority call) — emit ASK verdict instead
- Gap requires external research (web search, API docs) — emit ASK verdict instead

Inline research fills the 10-20% of gaps that only become visible during planning. It is not a substitute for the research step.
