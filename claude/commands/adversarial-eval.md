---
description: "Adversarial evaluation of a proposed approach. Two agents argue opposing positions, then a synthesis produces a final verdict."
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Adversarial Evaluation

Evaluate the topic or approach described by the user using a structured adversarial debate between two agents, followed by a synthesis that produces a clear, final verdict.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## When to use

Use when the user asks you to evaluate, debate, or stress-test a proposed approach — especially when prior discussion has produced conflicting recommendations or flip-flopping.

## Process

### Step 1: Frame the debate

Identify the core question from the user's message and conversation context. Distill the specific claims, proposals, or categorizations that need a verdict. Summarize the full context (prior research, findings, proposals) so both agents have the same information.

### Step 2: Launch two adversarial agents in parallel

**Agent 1: "Ship It" Advocate** (subagent_type: general-purpose)

Prompt template:
```
You are the "SHIP IT" advocate in an adversarial evaluation. Your job is to argue for the minimum viable scope. You must be specific and concrete — no hand-waving.

FULL CONTEXT:
{paste all relevant prior findings, proposals, and discussion}

THE QUESTION:
{the specific question being evaluated}

For EVERY item under debate:
1. What SPECIFICALLY breaks if we skip this? Not theoretically — concretely, given the actual scale, timeline, and constraints.
2. If something does break, what's the blast radius? One user annoyed? Data corruption? Legal exposure?
3. What's the ACTUAL cost to fix it later vs now? "Hard to retrofit" is not an answer — explain the specific retrofit scenario and its cost in hours.
4. Is there a cheaper mitigation that achieves 80% of the benefit?

You MUST concede items where the "do it right" argument is genuinely stronger. Credibility comes from knowing which battles to pick, not from arguing everything should be deferred.

Return a table: | Item | Skip? | What breaks | Blast radius | Retrofit cost | Your verdict |
```

**Agent 2: "Do It Right" Advocate** (subagent_type: general-purpose)

Prompt template:
```
You are the "DO IT RIGHT" advocate in an adversarial evaluation. Your job is to argue for items that belong in the current scope. You must be specific about costs — no fear-mongering.

FULL CONTEXT:
{paste all relevant prior findings, proposals, and discussion}

THE QUESTION:
{the specific question being evaluated}

For EVERY item under debate:
1. What's the ACTUAL implementation cost in hours? Not "a few days" — hours, with a breakdown of what those hours contain.
2. What's the concrete retrofit cost if deferred? Specify: can you add it later with zero rework, or does deferring create irreversible state?
3. Is this a "cheap now, expensive later" item or a "same cost whenever" item?
4. If you're arguing to include it, what's the MINIMUM viable version? Not the ideal version — the smallest thing that prevents the problem.

You MUST concede items where the cost genuinely doesn't justify inclusion now. Credibility comes from prioritization, not from arguing everything is critical.

Return a table: | Item | Include? | Implementation hours | Retrofit cost | Minimum viable version | Your verdict |
```

### Step 3: Synthesize

After both agents return, produce a single unified table:

```
| Item | Ship-It says | Do-It-Right says | FINAL VERDICT | Rationale (one sentence) |
```

Rules for the synthesis:
- When both agents agree → adopt their shared verdict
- When they disagree → the stronger SPECIFIC argument wins (concrete > theoretical, hours > hand-waving)
- Mark each item with a clear binary: **MVP** or **DEFER**
- No "maybe" or "consider" — every item gets a verdict
- If an item is deferred, state the specific trigger for revisiting

### Step 4: Present to user

Show the final table with clear verdicts. Lead with the table, then provide supporting detail only for items where the decision was close or surprising.

## Key principles

- **Both agents see all context.** No information asymmetry.
- **Both agents must concede.** An advocate who argues everything is a bad advocate.
- **Specificity wins.** "This takes 3 hours and prevents silent data corruption" beats "this is best practice."
- **One pass, final answer.** No follow-up rounds. The synthesis is the verdict.
- **Binary outcomes only.** MVP or DEFER. No middle ground.

## Example invocation

User: "We've been going back and forth on whether to add caching to the API layer. Run an adversarial eval."

→ Frame the debate from conversation context
→ Launch Ship-It and Do-It-Right agents in parallel with full context
→ Synthesize into final verdict table
