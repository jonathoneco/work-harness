# Futures: W3 Workflow Phase Redesign

Deferred enhancements discovered during research.

- **Phase-specific review agents**: Dedicated spec-review vs impl-review agents with different checklists (from topic 02, 05). Not in W3 scope but would improve review quality.
- **Finding auto-expiry**: Auto-expire OPEN findings when code diff covers the reported file/line (from topic 02). Requires deeper integration with git diff analysis.
- **Dispatch routing by domain**: Route spec agents to specialized agents (database architect, API designer) based on spec content (from topic 01). Requires agent registry and routing rules.
- **Conditional verdicts in adversarial eval**: Allow "MVP if X, DEFER if Y" instead of pure binary (from topic 04). Requires verdict format redesign.

## Dynamic Risk Classification
**Horizon**: next
**Domain**: workflow
Static risk assignments (DD-5) work for initial release, but risk should eventually factor in task complexity, artifact size, and prior loop-back count. A dynamic risk model would auto-escalate ceremony weight when a task has already looped back or when the diff is large.

## Multi-Step Loop Chains
**Horizon**: quarter
**Domain**: workflow
W3 supports plan→research loop-back only. Future work could extend loops to other step pairs (e.g., spec→plan when spec writing reveals architectural gaps, or decompose→spec when work item granularity reveals spec ambiguity). Requires generalizing the re-entry mechanics beyond the research/plan pair.

## Adversarial Eval History and Learning
**Horizon**: someday
**Domain**: adversarial-eval
Track adversarial eval outcomes across tasks to identify patterns in decision quality. Over time, the system could suggest framings based on decision type and recommend positions based on historical outcomes in similar contexts.

## Automated Adversarial Eval Framing Selection
**Horizon**: next
**Domain**: adversarial-eval
Agent manually selects framing based on decision type. Future work: automatic selection based on decision classification (e.g., dependency decisions → build-vs-buy, timing decisions → ship-vs-polish). Discovered during spec 08.

## Tier R to T2/T3 Escalation
**Horizon**: next
**Domain**: workflow
If a `work-research` task reveals implementation need, the user must currently start a new T2/T3 task. Direct escalation from Tier R (adding plan/spec/implement steps in-place) would reduce friction. Discovered during spec 07.
