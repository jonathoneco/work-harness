---
name: adversarial-eval
description: "Optional adversarial evaluation protocol for design decisions with meaningful trade-offs. Invocable by plan and spec agents when facing non-trivial architectural choices. Provides structured debate framings with position elicitation."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Adversarial Eval

Structured debate protocol for design decisions where reasonable people could disagree.
Agents invoke this during plan or spec steps — it is never mandatory.

## When to Invoke

Invoke when facing a design decision with meaningful trade-offs where reasonable
people could disagree. Examples: build vs buy, ship now vs polish, one architecture
vs another.

Do NOT invoke for:
- Clear-cut decisions with an obvious best option
- Implementation details (naming, file placement)
- Decisions already made by the user

## Protocol

### Phase 0: Position Elicitation

Before the evaluation begins, ask the user:

> Before the evaluation begins, what is your current position on **[decision]**?
> Options: **[Position A label]** / **[Position B label]** / **No position** / **Skip**
>
> This helps calibrate the debate and track whether the evaluation shifts your thinking.

Record the user's response. If the user says "no position" or "skip", proceed
without anchoring. The initial position is compared to the final recommendation
in synthesis.

### Phase 1: Opening Arguments

Present the strongest case for each position:

1. **Position A** — Steel-man argument referencing the framing's evaluation criteria
2. **Position B** — Steel-man argument referencing the framing's evaluation criteria

Each argument should be concrete and grounded in the project's actual context,
not generic. Reference specific files, constraints, or requirements.

### Phase 2: Rebuttal

For each position, present the strongest counterarguments:

1. **Against Position A** — What Position B advocates would say in response
2. **Against Position B** — What Position A advocates would say in response

Rebuttals must address the actual arguments made, not straw-man versions.

### Phase 3: Synthesis

Produce the synthesis output (see format below). The synthesis informs but does
not replace the agent's decision — the agent makes the final call.

## Framing Registry

Each framing shapes the debate. Schema:

```yaml
name: string          # kebab-case identifier
description: string   # one-line summary
position_a:
  label: string       # short label (e.g., "Ship Now")
  prompt: string      # what this position argues
position_b:
  label: string
  prompt: string
evaluation_criteria:   # what the synthesis weighs
  - string
```

### Built-in Framings

**ship-vs-polish**
- Description: Ship the MVP now vs invest in polish first
- Position A: "Ship Now" — The current implementation is good enough to deliver value. Delaying costs more than iterating post-release.
- Position B: "Polish First" — Investing in quality now avoids costly rework and protects user trust. The gap between MVP and production-ready is smaller than it appears.
- Criteria: time-to-value, technical debt risk, user impact, iteration cost

**build-vs-buy**
- Description: Build custom vs use an existing tool or library
- Position A: "Build Custom" — A custom solution fits our exact needs, avoids lock-in, and gives us full control over the implementation.
- Position B: "Use Existing" — An existing tool reduces development time, provides battle-tested reliability, and lets us focus on our core problem.
- Criteria: maintenance burden, fit to requirements, total cost, lock-in risk

**paradigm-choice**
- Description: Approach A vs Approach B for a technical design decision
- Position A: "Approach A" — [Customized by agent based on the specific decision]
- Position B: "Approach B" — [Customized by agent based on the specific decision]
- Criteria: complexity, extensibility, team familiarity

## Framing Selection

Select the framing that best matches the decision:

| Decision Type | Suggested Framing |
|---------------|-------------------|
| Release timing, MVP scope | ship-vs-polish |
| Dependency adoption, tool choice | build-vs-buy |
| Architecture, design pattern | paradigm-choice |

If no built-in framing fits, construct an ad-hoc framing using `paradigm-choice`
as a base — customize the position labels, prompts, and evaluation criteria for
the specific decision.

Before starting the eval, state which framing you chose and why. The user can
override the framing choice (e.g., "use build-vs-buy instead").

## Synthesis Output Format

```markdown
## Adversarial Eval: [Decision Name]

**Framing**: [framing name]
**User's initial position**: [position from Phase 0, or "none stated"]

### Position A: [label]
[Summary of strongest arguments]

### Position B: [label]
[Summary of strongest arguments]

### Recommendation
[Which position is stronger and why, referencing evaluation criteria]

### Conditions
[Under what conditions the recommendation would change]

### Position Shift
[Whether the recommendation differs from the user's initial position, and why]
```

Incorporate the synthesis into the architecture document (plan step) or spec
at the relevant design decision. The synthesis informs the decision — it does
not replace the agent's judgment.

## Custom Framings

Projects can define custom framings in `.claude/harness.yaml`:

```yaml
adversarial_eval:
  framings:
    - name: monolith-vs-service
      description: Keep in monolith vs extract to service
      position_a:
        label: "Keep Monolith"
        prompt: "The monolith is simpler to deploy, debug, and reason about. Extraction adds operational complexity without proven need."
      position_b:
        label: "Extract Service"
        prompt: "A separate service enables independent scaling, deployment, and team ownership. The boundary is clear enough to extract cleanly."
      evaluation_criteria:
        - operational complexity
        - scaling needs
        - team boundaries
        - deployment independence
```

Custom framings use the same schema as built-ins and are available alongside them.
