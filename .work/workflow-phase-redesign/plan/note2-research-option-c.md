# Option C: Adaptive Research Depth — Research Notes

## Summary of Position

Option C makes the buckshot research phase conditional on the task's design_novelty score from the assessment. High novelty tasks (score 2) get the full parallel research phase followed by a gate, then planning. Low/medium novelty tasks (score 0-1) skip directly to planning, but the plan agent retains the ability to spawn Explore subagents for inline research as needed. The core insight: not all tasks need the same process depth, so the workflow should adapt.

This maps directly onto the Cynefin framework's central thesis — different problem domains demand different decision-making approaches, and applying the wrong approach is actively harmful in both directions.

---

## Productivity/Work Research

### The Cynefin Framework: Different Problems, Different Processes

The Cynefin framework (Snowden, 1999) provides the strongest theoretical backing for Option C. It defines five decision-making domains, each prescribing a fundamentally different approach:

- **Clear/Obvious domain** (known knowns): "Sense → Categorize → Respond" — apply best practice. No exploration needed.
- **Complicated domain** (known unknowns): "Sense → Analyze → Respond" — expert analysis required, but the problem space is knowable.
- **Complex domain** (unknown unknowns): "Probe → Sense → Respond" — experimentation and investigation must precede action because cause and effect are only visible in retrospect.

The framework explicitly warns against applying the wrong domain's approach: treating a complex problem as merely complicated leads to false confidence and wrong solutions; treating a clear problem as complex wastes resources on unnecessary exploration.

This maps almost perfectly to the Option C branching:
- design_novelty=0 (known pattern) → Clear/Complicated domain → skip research, plan directly
- design_novelty=2 (new subsystem) → Complex domain → probe first (buckshot research), then plan

**Source**: [Cynefin Framework — Wikipedia](https://en.wikipedia.org/wiki/Cynefin_framework); [Cynefin Framework — Mindtools](https://www.mindtools.com/atddimk/the-cynefin-framework/); Snowden & Boone, "A Leader's Framework for Decision Making," [HBR 2007](https://hbr.org/2007/11/a-leaders-framework-for-decision-making)

### Situational Leadership: Match the Response to the Situation

Hersey-Blanchard Situational Leadership theory argues that effective leadership requires adjusting approach based on the task and the follower's development level. Complex tasks require coaching/supporting styles; routine tasks benefit from delegating. The parallel to Option C: the harness plays the "leader" role, and the appropriate leadership style (heavy research scaffolding vs. lightweight planning) should match the task's characteristics.

Key insight from World Consulting Group: "Complex tasks require a different approach than simpler tasks, with complex tasks requiring leaders to manage multiple moving pieces, while simple tasks tend to require more straightforward solutions."

**Source**: [Understanding Task Complexity in Leadership Styles — World Consulting Group](https://www.worldconsulting.group/leadership-style-selection-criteria-task-complexity); [Situational Leadership — The Decision Lab](https://thedecisionlab.com/reference-guide/management/situational-leadership-theory)

### The Asymmetric Cost of Skipping vs. Overdoing Discovery

Research on the discovery phase in software development reveals a heavily asymmetric cost profile:

- **Cost of skipping discovery**: Projects spending <5% of budget on requirements work experienced 80-200% cost overruns. Fixing a requirements error in production costs 10-100x more than catching it during planning. CB Insights found 42% of startups fail because they build products nobody wants — a discovery failure.
- **Cost of excessive discovery**: The Double Diamond design process literature warns against "overloading discovery with unnecessary detail" — the goal is clarity, not perfection. But critically, the literature overwhelmingly advises to "limit discovery, don't skip it."

This suggests the risk profile for Option C is asymmetric: **under-researching a novel task (false negative) is far more costly than over-researching a routine task (false positive)**. This has implications for where to set the threshold.

**Source**: [Hidden Costs of Skipping Product Discovery — Thilo Schinke](https://thiloschinke.medium.com/the-hidden-costs-of-skipping-product-discovery-and-how-to-avoid-them-7ce27c8342ce); [Why Skipping Discovery Is the Most Expensive Decision — Teque](https://www.teque.co.uk/why-skipping-discovery-is-the-most-expensive-decision-in-software/); [Double Diamond — Design Council](https://www.designcouncil.org.uk/our-resources/the-double-diamond/)

### R&D Portfolio Management: Right-Sizing Investment to Uncertainty

R&D organizations inherently manage portfolios with different uncertainty levels. Modern R&D strategy literature describes a standard five-stage pipeline (discovery → concept validation → prototype → pilot → scale-up) where "strategic decision making in the early discovery phase sets the foundation for high-impact outcomes." Organizations allocate varying research depth based on problem novelty — high-uncertainty/high-reward projects get more front-end exploration.

**Source**: [Building an R&D Strategy for Modern Times — McKinsey](https://www.mckinsey.com/capabilities/strategy-and-corporate-finance/our-insights/building-an-r-and-d-strategy-for-modern-times); [R&D Guide — ITONICS](https://www.itonics-innovation.com/guides/research-and-development)

---

## Agentic Workflow Research

### Anthropic's Routing Pattern: The Exact Architecture Option C Proposes

Anthropic's "Building Effective Agents" guide describes a **routing pattern** that is essentially what Option C implements: "Routing classifies an input and directs it to a specialized followup task." Simple queries route to lightweight handlers; complex ones route to heavy-duty pipelines. Anthropic explicitly recommends "finding the simplest solution possible, and only increasing complexity when needed" and warns to "add complexity only when it demonstrably improves outcomes."

Option C is a direct instantiation of this pattern — the assessment's design_novelty score is the classifier, and the two paths (buckshot research → gate → plan vs. plan-with-inline-research) are the specialized downstream processes.

**Source**: [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents)

### Plan-and-Act: Separation of Planning and Execution

The Plan-and-Act framework (2025) demonstrates that explicit separation of planning from execution improves agent performance substantially. Key findings:

- A well-formed plan alone improved WebArena-Lite accuracy from 9.85% to 44.24%, even with an untrained executor.
- **Dynamic replanning** (updating the plan after each step rather than relying on a static initial plan) yielded a 10.31% improvement, achieving 57.58% state-of-the-art accuracy.

This supports having a planning phase, but the dynamic replanning result is particularly relevant: it suggests that planning should be adaptive and responsive to discovered information, which aligns with Option C's "plan agent with inline research powers" model for the low-novelty path.

**Source**: [Plan-and-Act: Improving Planning of Agents for Long-Horizon Tasks — arXiv](https://arxiv.org/html/2503.09572v3)

### Recovery Over Prevention: Implications for Misclassification Risk

Snorkel AI's analysis of 4,000 errors across 8 frontier coding models found that **recovery, not avoidance, separates success from failure**:

- Passed and failed tasks encounter similar error counts (2.09 vs 2.71 per task).
- Passed tasks recover from 95.0% of errors vs. 73.5% for failed tasks — a 21.5 percentage point gap.
- Reasoning errors (not mechanical errors) constitute the majority of non-recoverable failures.

**Implication for Option C**: If the assessment misclassifies a novel task as routine, the plan agent's ability to spawn Explore subagents acts as a recovery mechanism. The question is whether inline research is sufficient recovery, or whether the structural absence of buckshot research creates a reasoning error that is harder to recover from.

**Source**: [Coding Agents Don't Need to Be Perfect, They Need to Recover — Snorkel AI](https://snorkel.ai/blog/coding-agents-dont-need-to-be-perfect-they-need-to-recover/)

### LLM Self-Assessment: The Calibration Problem

Research on LLM confidence calibration reveals a serious concern for Option C's reliance on assessment accuracy:

- LLMs exhibit the **Dunning-Kruger effect**: "poorly performing models didn't adjust confidence downward on difficult tasks." Gemini models maintained 95-99% confidence regardless of actual performance.
- The worst miscalibration gaps occur precisely where they're most dangerous — on hard/novel tasks. Kimi K2 maintained 97.9% confidence while achieving only 3.9% accuracy on open-ended recall tasks.
- "Models exhibiting Dunning-Kruger patterns are particularly dangerous because they express high confidence precisely when they are most likely to be wrong."
- **One bright spot**: Claude Sonnet models showed "the highest confidence variability (std = 41.0), indicating appropriate modulation of confidence based on question difficulty."

**Implication**: The design_novelty score is assessed by the LLM itself during triage. If the model underestimates novelty on truly novel tasks (the Dunning-Kruger risk), the system routes to the wrong path. However, the harness mitigates this by presenting the assessment to the user for override, adding a human check on the classification.

**Source**: [The Dunning-Kruger Effect in Large Language Models — arXiv](https://arxiv.org/html/2603.09985v1); [Overconfidence in LLM-as-a-Judge — arXiv](https://arxiv.org/html/2508.06225v2); [Do Large Language Models Know What They Are Capable Of? — arXiv](https://arxiv.org/html/2512.24661v1)

### Task Routing in Agent Systems: The Specialist Pattern

Research on why AI agent projects fail (90% failure rate past proof-of-concept) highlights the value of routing to specialist paths:

- A router choosing between 4 specialists is "dramatically simpler" than one agent routing 20 tools (tool routing accuracy: 95% with 5 tools, ~70% with 25 tools).
- The "God Agent Anti-Pattern" — a monolithic agent handling everything — is the #1 architectural failure mode.
- The recommended approach: "decompose into specialist agents" with focused system prompts.

Option C embodies this specialist pattern: the "full research" path is a specialist workflow for novel problems, while the "plan-with-research-powers" path is a specialist for known-pattern problems. Each gets a context window tuned to its needs.

**Source**: [Why 90% of AI Agent Projects Fail — DEV Community](https://dev.to/nebulagg/why-90-of-ai-agent-projects-fail-and-the-patterns-that-fix-it-1dma)

### Meta-Learning: Task-Difficulty-Aware Strategy Selection

The meta-learning literature provides a formal framework for what Option C proposes informally. Task-Difficulty-Aware Meta-Learning (TDAS) explicitly models that "not all tasks are equally important during training" and uses adaptive sampling to allocate effort proportionally. This is the machine learning formalization of the intuition behind Option C: assess difficulty first, then allocate appropriate process resources.

**Source**: [Task-Difficulty-Aware Meta-Learning with Adaptive Update Strategies — ACM](https://dl.acm.org/doi/10.1145/3583780.3615074); [Meta-Learning in Neural Networks: A Survey — arXiv](https://arxiv.org/pdf/2004.05439)

---

## Strongest Arguments For

1. **Cynefin alignment is compelling**: The framework is specifically about matching decision-making process to problem domain. Clear/complicated problems genuinely don't benefit from the "probe" phase that complex problems require. This isn't a shortcut — it's the correct approach per the framework.

2. **Reduces friction for common tasks**: Most development tasks are not novel (design_novelty=0 or 1). Forcing parallel research for "add another CRUD endpoint following existing patterns" wastes tokens, time, and context window. Option C eliminates this overhead for the majority case.

3. **The assessment infrastructure already exists**: The triage system already computes design_novelty as part of its 3-factor scoring. Option C reuses this existing data point for routing rather than adding new machinery. This is arguably the lowest-implementation-complexity option.

4. **Anthropic's own guidance validates the pattern**: The routing pattern from "Building Effective Agents" is exactly this architecture — classify, then route to specialized handlers. This is battle-tested in production agent systems.

5. **Inline research as fallback provides safety net**: Even on the "skip research" path, the plan agent retains the ability to spawn Explore subagents. This means a misclassified task can still access research capabilities — it just won't get the structured parallel exploration. The recovery path exists.

6. **Eliminates the loopback machinery entirely**: By removing the formal research-then-plan-then-loopback-to-research flow for low-novelty tasks, the overall system becomes simpler. The high-novelty path keeps the clean research → gate → plan flow without loopback. This directly addresses the user's observation that loopback feels "over-engineered."

7. **Context window efficiency**: For routine tasks, skipping a full research phase means the plan agent starts with a clean context window rather than one loaded with research synthesis artifacts. Per the "Context Window Bankruptcy" failure mode, this is a real operational advantage.

---

## Strongest Arguments Against

1. **The Dunning-Kruger risk is real and asymmetric**: LLM self-assessment is systematically overconfident on hard tasks. If the model underestimates design_novelty on a genuinely novel task, it routes to the lightweight path. The cost of this error is high (discovery-phase cost savings literature: 10-100x multiplier on downstream rework). The cost of the reverse error (over-researching a routine task) is much lower (wasted tokens, ~15 minutes). **The asymmetry argues for a bias toward more research, not less.**

2. **Binary branching is a crude model of reality**: Option C creates two paths based on a single score. But novelty is a spectrum, and tasks often have mixed profiles (e.g., known pattern + unfamiliar integration point). A binary branch can't express "do a little research" — it's either full buckshot or nothing structured. This loses the ability to modulate research depth smoothly.

3. **The Double Diamond warns against skipping discovery**: Design process literature consistently advises to "limit discovery, don't skip it." Even for seemingly known problems, "the Discover phase gets cut short, which is a massive mistake, because when you build on a foundation of shaky or incomplete assumptions, you almost always end up solving the wrong problem." Option C skips discovery entirely for score 0-1 tasks.

4. **Inline research is qualitatively different from buckshot research**: Buckshot research sends multiple parallel Explore agents to investigate different facets simultaneously, producing a broad landscape scan. Inline research during planning is serial, reactive, and narrowly scoped to what the planner thinks it needs. These are not equivalent capabilities — a planner doing inline research will miss things that parallel exploration would surface, because it doesn't know what it doesn't know.

5. **Branching adds maintenance complexity to the harness**: Two workflow paths means two code paths to maintain, test, and debug. Every future change to the research or plan phases must be considered for both paths. The "God Agent" anti-pattern literature warns that complexity grows non-linearly with branching. While two paths is manageable, it sets a precedent for more conditional logic.

6. **Assessment score was designed for tier routing, not phase routing**: The design_novelty score was created to route tasks to the right tier (Fix/Feature/Initiative), not to control which phases within a tier execute. Reusing it for a different purpose may create surprising coupling — a change to the triage criteria for tier routing could inadvertently change which tasks get research phases.

7. **The gate's value as a context firewall is lost on the lightweight path**: One of the user's stated preferences is the gate as a review point and context firewall between research and planning. On the score 0-1 path, there is no gate — the plan agent proceeds directly. This means there's no forced pause for the user to review research findings before planning begins, even though the planner may have done significant inline research.

8. **"Unknown unknowns" are by definition hard to assess up front**: A design_novelty score of 0 means "known pattern, existing precedent." But the assessment happens before deep investigation. The agent may not know enough at assessment time to recognize that a seemingly routine task conceals novel complexity. This is the fundamental epistemological challenge: you can't always know what you don't know before you start looking.

---

## Key Sources

### Theoretical Frameworks
- [Cynefin Framework — Wikipedia](https://en.wikipedia.org/wiki/Cynefin_framework)
- [The Cynefin Framework — Mindtools](https://www.mindtools.com/atddimk/the-cynefin-framework/)
- [A Leader's Framework for Decision Making — HBR](https://hbr.org/2007/11/a-leaders-framework-for-decision-making)
- [Understanding Task Complexity in Leadership Styles — World Consulting Group](https://www.worldconsulting.group/leadership-style-selection-criteria-task-complexity)
- [Situational Leadership Theory — The Decision Lab](https://thedecisionlab.com/reference-guide/management/situational-leadership-theory)

### Discovery Phase Research
- [Hidden Costs of Skipping Product Discovery — Thilo Schinke / Medium](https://thiloschinke.medium.com/the-hidden-costs-of-skipping-product-discovery-and-how-to-avoid-them-7ce27c8342ce)
- [Why Skipping Discovery Is the Most Expensive Decision — Teque](https://www.teque.co.uk/why-skipping-discovery-is-the-most-expensive-decision-in-software/)
- [Double Diamond Process — Design Council](https://www.designcouncil.org.uk/our-resources/the-double-diamond/)
- [Double Diamond Process — UXPin](https://www.uxpin.com/studio/blog/double-diamond-design-process/)

### Agentic AI Architecture
- [Building Effective Agents — Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [Plan-and-Act: Improving Planning of Agents for Long-Horizon Tasks — arXiv](https://arxiv.org/html/2503.09572v3)
- [Routing for AI Agents — Niva Labs](https://www.nivalabs.ai/blogs/routing-for-ai-agents-building-adaptive-and-context-aware-systems)
- [Why 90% of AI Agent Projects Fail — DEV Community](https://dev.to/nebulagg/why-90-of-ai-agent-projects-fail-and-the-patterns-that-fix-it-1dma)

### LLM Calibration and Self-Assessment
- [The Dunning-Kruger Effect in Large Language Models — arXiv](https://arxiv.org/html/2603.09985v1)
- [Overconfidence in LLM-as-a-Judge — arXiv](https://arxiv.org/html/2508.06225v2)
- [Do Large Language Models Know What They Are Capable Of? — arXiv](https://arxiv.org/html/2512.24661v1)

### Agent Recovery and Error Handling
- [Coding Agents Don't Need to Be Perfect, They Need to Recover — Snorkel AI](https://snorkel.ai/blog/coding-agents-dont-need-to-be-perfect-they-need-to-recover/)
- [Evaluating AI Agents: Real-World Lessons — Amazon/AWS](https://aws.amazon.com/blogs/machine-learning/evaluating-ai-agents-real-world-lessons-from-building-agentic-systems-at-amazon/)

### Meta-Learning and Adaptive Strategy
- [Task-Difficulty-Aware Meta-Learning with Adaptive Update Strategies — ACM](https://dl.acm.org/doi/10.1145/3583780.3615074)
- [Meta-Learning in Neural Networks: A Survey — arXiv](https://arxiv.org/pdf/2004.05439)

### R&D and Process Management
- [Building an R&D Strategy for Modern Times — McKinsey](https://www.mckinsey.com/capabilities/strategy-and-corporate-finance/our-insights/building-an-r-and-d-strategy-for-modern-times)
- [A Framework for R&D — Matt Aimonetti / Medium](https://medium.com/@mattetti/a-framework-for-r-d-6aaaf8c05841)
- [Managing Complexity in Projects: Extending the Cynefin Framework — ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2666721521000119)
