# Option B: Research Gate + Empowered Plan Agent

## Summary of Position

Keep the research-then-plan gate as a review point and context firewall, but drop the formal loopback machinery. Instead, give the plan agent the ability to spawn Explore subagents for targeted inline research when it discovers gaps — no state changes, no re-entry, just capability. Research does broad parallel "buckshot" exploration. The gate reviews and distills it into a handoff. The plan agent starts from the handoff but can pull more information as needed.

This is essentially the "handoff with empowerment" model: you give the downstream agent a solid briefing AND the tools to fill gaps on its own, rather than forcing it to rewind the process.

---

## Productivity / Work Research

### The "Just Enough" Upfront Pattern

Agile methodology has extensively studied the tension between upfront research and on-demand investigation. The consensus position, articulated clearly by [Thoughtworks](https://www.thoughtworks.com/insights/blog/providing-just-enough-design-can-make-agile-software-delivery-more-successful), is "just enough design" — establish sufficient direction upfront to prevent costly late-stage overhauls, while preserving flexibility for refinements as understanding deepens. This maps directly to Option B: research provides the "just enough," the gate validates it, and the plan agent handles refinement.

The anti-patterns on both ends are well-documented:
- **Big Design Up Front (BDUF)**: Exhaustive research phases produce waste because requirements shift, discoveries invalidate assumptions, and the handoff becomes a massive document nobody fully absorbs. Research on large-scale agile projects confirms that "big up-front specifications would probably cause a lot of waste" ([ScienceDirect, Requirements engineering in large-scale agile](https://www.sciencedirect.com/science/article/pii/S0164121220302417)).
- **No Design Up Front**: Skipping research entirely leads to "on par" products that fail to delight, because teams lack the strategic context to make good architectural decisions ([Thoughtworks](https://www.thoughtworks.com/insights/blog/providing-just-enough-design-can-make-agile-software-delivery-more-successful)).

### Agile Spikes as Analogous Pattern

The closest analogy in agile practice is the **spike** — a time-boxed research task aimed at reducing uncertainty before committing to implementation ([Mountain Goat Software](https://www.mountaingoatsoftware.com/blog/spikes)). Spikes are typically 1-3 days, focused on answering specific questions, and their output feeds directly into planning. Option B's research phase functions like a spike, while the plan agent's inline research mirrors how developers naturally do small investigations during sprint planning when a spike's findings don't fully cover a question.

### Just-in-Time Information Gathering

JIT requirements gathering — knowing "just enough to enable work to be done" rather than figuring everything out upfront — is a well-established agile practice ([AgileRant](https://www.agilerant.info/just-in-time-requirements/)). Benefits include avoiding wasted effort on requirements that change, and getting faster feedback loops. However, pure JIT fails for knowledge work that requires significant design thinking before coding begins. The evidence suggests JIT works best as a **supplement to** rather than **replacement for** some upfront investigation.

### Set-Based Concurrent Engineering

Toyota's [set-based concurrent engineering](https://www.lean.org/lexicon-terms/set-based-concurrent-engineering/) provides another supporting lens. The principle is: explore multiple options broadly first, then narrow progressively as you learn. Option B's research phase does the broad exploration (buckshot), while the plan agent narrows toward a specific approach — with the freedom to do targeted investigation when the narrowing process reveals gaps. This "takes less time and costs less in the long term than typical point-based systems that select a design solution early" because it defers irreversible decisions until uncertainty resolves.

### Handoff with Empowerment in Human Teams

Research on agile knowledge transfer ([Thoughtworks, Agile Knowledge Transfer](https://www.thoughtworks.com/insights/blog/introduction-agile-knowledge-transfer)) and self-organizing teams ([Mountain Goat Software](https://www.mountaingoatsoftware.com/blog/the-role-of-leaders-on-a-self-organizing-team)) shows that the most effective handoffs combine structured knowledge transfer with autonomy. Leadership "should be diffused rather than centralized" — transferred to whoever has the relevant knowledge for the current task. The gate serves as the structured handoff; the plan agent's empowerment is the autonomy. This matches how real consulting engagements work: researchers brief the strategist, but the strategist can ask follow-up questions and pull additional data.

---

## Agentic Workflow Research

### ReAct: The Dominant Interleaved Pattern

The [ReAct framework](https://research.google/blog/react-synergizing-reasoning-and-acting-in-language-models/) (Yao et al., 2023) is the most well-studied pattern for interleaving reasoning with information gathering. Key findings:

- **Interleaving beats pure reasoning**: Chain-of-thought without external verification leads to hallucinated facts. ReAct's action steps let agents gather real information during reasoning, significantly reducing fabrication ([Prompt Engineering Guide](https://www.promptingguide.ai/techniques/react)).
- **Trade-off is speed vs. correctness**: Each reasoning loop requires additional model calls, increasing latency and cost. But accuracy improves substantially ([IBM, ReAct Agents](https://www.ibm.com/think/topics/react-agent)).
- **Works best for complex, unpredictable scenarios**: Where the path forward is unclear and the agent needs to adapt based on what it finds. Less valuable for straightforward tasks where the plan is obvious.

This directly supports Option B's core mechanic: the plan agent reasons about the research handoff, identifies gaps, and spawns targeted actions (Explore subagents) to fill them — classic ReAct within the planning phase.

### Plan-Then-Execute vs. Interleaved Planning

The agentic AI community has formalized this tension into two named patterns:

- **Plan-Then-Execute**: Generate a complete plan upfront, then execute it. Improves tool use accuracy from 72% to 94% and reduces hallucinations by ~60%. Best when the action set is known and the environment is predictable ([Agentic Patterns](https://agentic-patterns.com/patterns/plan-then-execute-pattern/)).
- **ReAct / Interleaved**: Alternate between reasoning and acting. Better when discovering information along the way or when circumstances change.

Option B is neither pure pattern — it's the **hybrid** that practitioners increasingly recommend. Research does broad plan-then-execute style work. The plan agent uses interleaved ReAct-style reasoning. This "compositional approach captures the best of both worlds: the reliability of a high-level plan and the adaptability of an exploratory sub-agent" ([Allen Hutchison, How Agents Think](https://allen.hutchison.org/2025/09/20/how-agents-think/)).

The 2025 consensus is that **planning before execution improves task completion rates by 40-70%** and reduces hallucinations by ~60%, validating the separate research phase. But rigid plans that can't adapt to new information are brittle.

### Context Engineering: The Firewall Argument

[Anthropic's context engineering guide](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) articulates the core principle: find "the smallest set of high-signal tokens that maximize the likelihood of some desired outcome." This is the strongest argument for the gate as a context firewall:

- Research generates massive context (parallel agent explorations, code analysis, documentation reads). Dumping all of that into the plan agent's window causes **context rot** — performance degrades as windows fill, even well within technical limits.
- The "lost in the middle" phenomenon ([Liu et al., 2023](https://arxiv.org/abs/2307.03172)) shows LLM performance drops 30%+ when relevant information is buried in the middle of context. A handoff summary moves the signal to the beginning of the plan agent's clean context.
- Sub-agent architectures are the recommended pattern: "specialized agents handle focused tasks with clean context windows, returning condensed summaries (typically 1,000-2,000 tokens) to the main coordinator."

The gate is not just a review point — it's a **context distillation layer** that prevents the plan agent from drowning in raw research output.

### Agentic RAG: Autonomous Retrieval Decisions

The [Agentic RAG survey](https://arxiv.org/abs/2501.09136) (2025) documents how modern agents make autonomous retrieval decisions. Key principles:

- **Query complexity classification**: Agents assess whether existing knowledge suffices before retrieving. Simple questions skip retrieval; complex ones trigger multi-step investigation.
- **Corrective retrieval**: When initial results prove insufficient, agents flag gaps and perform additional targeted searches.
- **Satisfaction-based termination**: Agents exit the research loop once sufficient information is gathered, rather than exhausting all possible sources.

This validates the plan agent's ability to spawn targeted Explore subagents: it's the same pattern as agentic RAG's corrective retrieval, just at a higher level of abstraction.

### Sub-Agent Patterns in Practice

[Claude Code's architecture](https://code.claude.com/docs/en/sub-agents) and the [OpenDev terminal agent paper](https://arxiv.org/html/2603.05344v1) both implement the exact pattern Option B describes:

- **Explore agents**: Read-only, fast, optimized for searching and analyzing code without making changes. Configurable thoroughness levels.
- **Context isolation**: Subagents don't inherit accumulated context, so heavy exploration doesn't bloat the main conversation.
- **Parallel execution**: Multiple subagents can research different areas simultaneously, each returning a summary.

The OpenDev paper specifically notes that the Plan subagent "explores the codebase, analyzes patterns, and produces a structured plan" and can be "spawned concurrently with other subagents for parallel analysis."

### Anthropic's Multi-Agent Research System

[Anthropic's own multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) implements a pattern highly relevant to Option B. The lead agent:
- Decomposes queries into subtasks with explicit specifications
- Delegates to subagents with clear boundaries
- "Synthesizes results and decides whether more research is needed — if so, it can create additional subagents or refine its strategy"
- Uses satisfaction-based termination rather than exhaustion-based

This is the plan agent's inline research capability at scale — the coordinator doesn't rewind state, it just spawns more focused investigation as needed.

### Agent Autonomy Research

[Anthropic's measurement of agent autonomy](https://www.anthropic.com/research/measuring-agent-autonomy) in Claude Code reveals that experienced users grant **more autonomy** (auto-approve from 20% to 40%+) while simultaneously **interrupting more strategically** (5% to 9%). Success rates doubled while interventions per session dropped from 5.4 to 3.3. This suggests the right model is "trust but verify" — give the plan agent autonomy to investigate, but maintain the gate as a strategic intervention point.

---

## Strongest Arguments For

### 1. Matches How Investigation Actually Works

Planning naturally elucidates what research is needed. The artificial separation of "all research must be done before planning begins" doesn't match how experts work — they research broadly, form hypotheses, investigate specific questions that arise from the hypothesis, and iterate. Option B preserves this natural flow without the ceremony of formal loopbacks.

### 2. Context Firewall Provides Real Value

The gate isn't just process overhead. It's a context distillation layer that:
- Prevents the plan agent from drowning in raw research output (context rot)
- Moves high-signal information to the beginning of a clean context window (avoiding lost-in-the-middle)
- Provides a human review point for research quality
- Creates a handoff document that serves as session continuity across context compactions

### 3. Eliminates Loopback Complexity Without Losing Capability

The formal loopback machinery (C07, DD-4, DD-7) adds state management complexity for a scenario that can be handled more naturally. A plan agent spawning an Explore subagent is a few tool calls — no state transitions, no re-entry protocols, no tracking of which research gaps triggered which loopbacks.

### 4. Aligns with Proven Agent Architecture Patterns

The hybrid pattern — structured phases with inline ReAct-style investigation — is the consensus recommendation in the agentic AI community. Planning before execution improves outcomes 40-70%, while rigid plans without adaptation are brittle. Option B gets both benefits.

### 5. Sub-Agent Isolation Keeps Context Clean

When the plan agent spawns an Explore subagent, that subagent gets a clean context window for its focused investigation. Results come back as a condensed summary. This avoids the context bloat that would occur if the plan agent did all the investigation inline in its own conversation.

### 6. Scales Gracefully with Complexity

Simple tasks: research provides everything, plan agent doesn't need inline investigation. Complex tasks: research covers the broad landscape, plan agent fills specific gaps. The same architecture handles both without different code paths.

### 7. Preserves Buckshot Research Value

The parallel team research phase remains — that's where broad exploration, multiple perspectives, and discovery of unknowns happens. Option B doesn't diminish this; it just stops pretending that broad research will cover 100% of what the planner needs.

---

## Strongest Arguments Against

### 1. Risk of Plan Agent Scope Creep

Without constraints, the plan agent's "targeted research" could expand into a second full research phase, undermining the purpose of the original research step. Research on agent autonomy consistently warns about scope creep: "what starts as a minor oversight can escalate" ([AWS, Agentic AI Security](https://aws.amazon.com/blogs/security/the-agentic-ai-security-scoping-matrix-a-framework-for-securing-autonomous-ai-systems/)). The plan agent needs clear boundaries on how much inline research it can do.

**Mitigation**: Time-box or token-budget the plan agent's research capability. Cap the number of Explore subagents it can spawn. Make the boundary explicit in the system prompt: "You may spawn up to N Explore subagents for targeted gap-filling. If you need broad re-investigation, flag it as a finding rather than doing it yourself."

### 2. Blurs Accountability Between Phases

If the plan agent does significant research, it becomes harder to assess whether the research phase did its job well. Was the research handoff inadequate, or did the plan agent just discover genuinely new questions? Over time, the research phase could atrophy if the plan agent always fills gaps, reducing it to a formality.

**Mitigation**: Track what the plan agent investigates inline. If patterns emerge (the plan agent consistently researches the same category of gap), feed that back into the research phase's prompt to improve coverage.

### 3. Added Latency from Inline Investigation

Every Explore subagent the plan agent spawns adds latency to the planning phase. If the plan agent spawns multiple subagents, planning could take significantly longer than if all research was complete upfront. The ReAct pattern's tradeoff of "speed for thoughtfulness" ([IBM](https://www.ibm.com/think/topics/react-agent)) applies here.

**Mitigation**: The added latency from targeted subagents is almost certainly less than the latency of a formal loopback (which restarts the entire research phase). The comparison isn't "fast planning" vs. "slow planning" — it's "inline investigation" vs. "full phase restart."

### 4. Research Quality May Suffer Without Feedback Pressure

The formal loopback was a signal back to the research phase: "you missed something." Without that feedback loop, the research step has no mechanism to learn from its gaps. The research prompt could stagnate, consistently missing the same categories of information.

**Mitigation**: Post-planning review can capture what the plan agent had to research inline. Periodically update the research phase's instructions based on these patterns. This is a maintenance concern, not an architectural flaw.

### 5. Subagent Results Can Propagate Errors

If a plan agent's Explore subagent returns incorrect or misleading information, that error enters the plan without the same review that gate-passed research receives. The plan agent is operating in a less scrutinized mode than the research phase.

**Mitigation**: The plan itself goes through review (implementation gate). Errors from inline research will surface there. The risk is real but bounded — inline research is targeted and small, not broad and sweeping.

### 6. Harder to Reproduce and Debug

A deterministic research-then-plan pipeline is easier to debug than one where the plan agent makes autonomous decisions about what to investigate. If a plan comes out wrong, tracing whether the issue was in research, the handoff, or the plan agent's inline investigation adds complexity.

**Mitigation**: Log all subagent spawns and their results. The plan agent should annotate its plan with sources: "Based on research handoff finding X" vs. "Based on inline investigation of Y."

---

## Key Sources

### Productivity and Work Methodology
- [Thoughtworks: Just Enough Design](https://www.thoughtworks.com/insights/blog/providing-just-enough-design-can-make-agile-software-delivery-more-successful) — "Just enough" upfront design balances direction with flexibility
- [Mountain Goat Software: Agile Spikes](https://www.mountaingoatsoftware.com/blog/spikes) — Time-boxed research tasks for reducing uncertainty
- [AgileRant: Just-in-Time Requirements](https://www.agilerant.info/just-in-time-requirements/) — JIT information gathering as agile practice
- [Lean Enterprise Institute: Set-Based Concurrent Engineering](https://www.lean.org/lexicon-terms/set-based-concurrent-engineering/) — Explore broadly, narrow progressively
- [Mountain Goat Software: Self-Organizing Teams](https://www.mountaingoatsoftware.com/blog/the-role-of-leaders-on-a-self-organizing-team) — Diffused leadership and autonomy
- [Thoughtworks: Agile Knowledge Transfer](https://www.thoughtworks.com/insights/blog/introduction-agile-knowledge-transfer) — Structured handoffs with team autonomy
- [Lean Startup Methodology](https://theleanstartup.com/principles) — Build-measure-learn loop; plan in reverse from what you need to learn
- [Kromatic: Build Measure Learn](https://kromatic.com/blog/build-measure-learn-vs-learn-measure-build/) — Learning-first inversion of the loop

### Agentic AI Architecture
- [ReAct: Synergizing Reasoning and Acting (Yao et al., 2023)](https://arxiv.org/abs/2210.03629) — Original ReAct paper on interleaving reasoning with tool use
- [Google Research: ReAct Blog Post](https://research.google/blog/react-synergizing-reasoning-and-acting-in-language-models/) — Summary of ReAct findings
- [IBM: What is a ReAct Agent?](https://www.ibm.com/think/topics/react-agent) — Thought-action-observation cycle and tradeoffs
- [Prompt Engineering Guide: ReAct](https://www.promptingguide.ai/techniques/react) — Practical ReAct implementation guidance
- [Allen Hutchison: How Agents Think](https://allen.hutchison.org/2025/09/20/how-agents-think/) — Hybrid patterns composing Plan-Execute with ReAct subagents
- [Agentic Patterns: Plan-Then-Execute](https://agentic-patterns.com/patterns/plan-then-execute-pattern/) — Structured planning pattern with execution separation
- [Agentic RAG Survey (2025)](https://arxiv.org/abs/2501.09136) — Autonomous retrieval decisions and corrective retrieval
- [Anthropic: Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) — Lead agent that spawns subagents and decides when more research is needed
- [Anthropic: Measuring Agent Autonomy](https://www.anthropic.com/research/measuring-agent-autonomy) — Autonomy levels, trust-but-verify pattern

### Context Engineering
- [Anthropic: Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Minimal effective context, progressive disclosure, sub-agent isolation
- [Liu et al.: Lost in the Middle (2023)](https://arxiv.org/abs/2307.03172) — 30%+ performance degradation when information is buried in context
- [Factory.ai: The Context Window Problem](https://factory.ai/news/context-window-problem) — Context as scarce resource, progressive distillation
- [Inkeep: Context Engineering — Why Agents Fail](https://inkeep.com/blog/context-engineering-why-agents-fail) — Context rot, tool bloat, 5-7 tools per agent recommendation
- [jroddev: Context Window Management in Agentic Systems](https://blog.jroddev.com/context-window-management-in-agentic-systems/) — Phase firewalls, memory separation, plan-execute isolation

### Agent Architecture and Coding Agents
- [OpenDev: Building AI Coding Agents for the Terminal](https://arxiv.org/html/2603.05344v1) — Dual-mode planning/execution, sub-agent patterns, context engineering as first-class concern
- [Claude Code: Sub-agents Documentation](https://code.claude.com/docs/en/sub-agents) — Explore agents, context isolation, parallel execution
- [Builder.io: Devin vs Cursor (2026)](https://www.builder.io/blog/devin-vs-cursor) — Plan-first vs iterative investigation workflows in coding agents
- [AWS: Agentic AI Security Scoping](https://aws.amazon.com/blogs/security/the-agentic-ai-security-scoping-matrix-a-framework-for-securing-autonomous-ai-systems/) — Scope creep risks with autonomous agents
- [Kore.ai: Decline of AI Agents, Rise of Agentic Workflows](https://www.kore.ai/ai-insights/the-decline-of-ai-agents-and-rise-of-agentic-workflows/) — Structured systems beat unbounded agent freedom
