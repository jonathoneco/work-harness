# Triage Criteria

The adaptive work harness uses a 3-factor depth assessment to determine task complexity and route to the appropriate tier.

## Scoring Formula

```
score = scope_spread + design_novelty + decomposability + bulk_modifier
```

## Factor Rubrics

### Scope Spread (0-2): How many files/packages/layers does this touch?

| Score | Criteria | Examples |
|-------|----------|---------|
| 0 | Single file or tightly-coupled pair (handler + test) | Fix a typo, add a validation check, update a query |
| 1 | Multiple files in the same package/layer, or 2 layers (e.g., handler + service) | Add a new endpoint with service method, update a template + handler |
| 2 | Spans 3+ packages/layers (handler + service + database + template + HTMX) | New feature with migration, API, business logic, and UI |

### Design Novelty (0-2): Known pattern or new design?

| Score | Criteria | Examples |
|-------|----------|---------|
| 0 | Known pattern, existing precedent in codebase | Add another CRUD endpoint following existing patterns |
| 1 | Minor adaptation of known pattern, or pattern exists but needs modification | Extend existing workflow with a new step, add pagination to an existing list |
| 2 | New subsystem, no precedent, requires research or design decisions | New auth system, new LLM pipeline, new state management approach |

### Decomposability (0-2): Can this be done as a single unit?

| Score | Criteria | Examples |
|-------|----------|---------|
| 0 | Single atomic change, no meaningful breakdown | Bug fix, config change, one-line feature flag |
| 1 | 2-3 distinct subtasks, but can be done in one session | Add endpoint + write tests + update template |
| 2 | Requires phased breakdown, multiple sessions, or parallel workstreams | Rebuild auth system, migrate storage backend, add real-time features |

### Bulk Modifier (-1 or 0): Mechanical repetition?

| Value | Criteria | Examples |
|-------|----------|---------|
| -1 | Task is mostly mechanical repetition across many files (high scope spread but low complexity per file) | Rename a function across 20 files, add error wrapping to all handlers, update import paths |
| 0 | Normal — no bulk repetition factor | Most tasks |

## Score-to-Tier Mapping

| Score | Tier | Label | Steps |
|-------|------|-------|-------|
| 0-1 | 1 | Fix | assess, implement, review |
| 2-3 | 2 | Feature | assess, plan, implement, review |
| 4+ | 3 | Initiative | assess, research, plan, spec, decompose, implement, review |

**Minimum score**: -1 (all zeros + bulk modifier) → Tier 1
**Maximum score**: 6 (all twos, no bulk modifier) → Tier 3

## Assessment Presentation Format

After scoring, present the assessment to the user:

```
## Assessment: <title>

| Factor | Score | Rationale |
|--------|-------|-----------|
| Scope Spread | <0-2> | <one-line explanation> |
| Design Novelty | <0-2> | <one-line explanation> |
| Decomposability | <0-2> | <one-line explanation> |
| Bulk Modifier | <-1 or 0> | <one-line explanation or "N/A"> |
| **Total** | **<score>** | |

**Tier <N> (<Label>)** — <steps list>

Proceed with this assessment, or override? (e.g., "treat as Tier 2")
```

**Boundary scores** (1 or 3): Note "Score is on the Tier X/Y boundary. Consider overriding if this feels more like a [Feature/Fix]."

## Override Protocol

When the user overrides:

1. Accept the override — the user knows more about the task than the triage engine
2. Update the `assessment` object with the original scoring BUT set `tier` to the user's choice
3. Append override note to `rationale`: "User override: Tier N → Tier M. Original score: S"
4. Create state.json with the overridden tier's step sequence

Override does NOT change the scoring factors — it only changes the tier routing. The original scoring is preserved for audit trail.

## Assessment Object Schema

```json
{
  "scope_spread":    "number — 0-2",
  "design_novelty":  "number — 0-2",
  "decomposability": "number — 0-2",
  "bulk_modifier":   "number — -1 or 0",
  "score":           "number — sum of above four fields",
  "rationale":       "string — one-line explanation"
}
```

The assessment populates the `assessment` field in state.json when the assess step completes. It is `null` until then.
