# Model Selection Analysis

## Decision: Opus Everywhere

No evidence of meaningful quality differences per task type. User preference: max power, cost not a concern.

## Available Models

- `opus` — Claude Opus 4.6 (default, inherited from parent)
- `sonnet` — Claude Sonnet 4.6
- `haiku` — Claude Haiku 4.5

## Analysis by Task Type

| Step | Cognitive Demand | Could Sonnet/Haiku Handle? | Risk of Downgrade |
|------|-----------------|---------------------------|-------------------|
| Research | Medium (search + shallow synthesis) | Probably | Low — bounded scope |
| Plan | High (multi-doc synthesis, tradeoffs) | Risky | High — compounds downstream |
| Spec | High (precision, contracts) | Risky | High — imprecise specs → bad implementation |
| Decompose | High (systems thinking, DAG) | Risky | Medium — structural errors |
| Implement | High (code gen, conventions) | Probably Sonnet | Medium — depends on complexity |
| Review | Medium (pattern matching, rules) | Probably Sonnet | Low — structured criteria |
| Phase A/B validation | Low-Medium (checklists) | Probably Haiku | Low — binary checks |

## Key Insight: Fast Mode

Fast mode is Opus with faster output, NOT a different model. Max power is preserved even in fast mode.

## Recommendation

Keep Opus everywhere. The only future exception worth testing: Phase A validation agents (simple checklist verification) could potentially use Haiku for speed, but the savings are minimal and not worth the complexity of model routing.

Revisit only if:
1. Token usage data shows Explore agents consistently under-utilizing their context
2. Quality metrics (if ever instrumented) show equivalent output from Sonnet
3. Parallel volume scales to 10+ simultaneous agents where cost/speed matters
