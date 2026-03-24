# Research Note: Option A — Two-Phase Explore Step

## Summary of Position

Option A merges the current separate research and plan steps into a single "explore" step with two internal modes:

1. **Discover** — parallel team buckshot where multiple agents research in parallel, producing raw findings
2. **Synthesize** — a single agent reads those findings and builds an architecture/plan, with the built-in ability to spawn targeted Explore subagents when it encounters gaps (no formal loopback, just native capability)

The gate moves to the end of explore (before spec), not between research and plan. The synthesize agent can investigate gaps in-flow without triggering a formal step transition.

---

## Productivity / Work Research

### The Double Diamond: Diverge Then Converge

The British Design Council's Double Diamond (2005) models creative work as two cycles of diverge-then-converge: Discover (diverge) → Define (converge) → Develop (diverge) → Deliver (converge). Option A's Discover/Synthesize maps cleanly onto the first diamond — broad exploration followed by convergent synthesis into a problem definition.

Key insight from the model: **the stages are iterative**. The Design Council explicitly states "you can (and should) loop back when new evidence emerges" and that "fast, repeated Discover/Define cycles beat one big pass." This supports Option A's approach of allowing the synthesize agent to re-enter discovery mode organically rather than requiring a formal step transition.

However, the Double Diamond also treats each phase as **cognitively distinct**. Divergence requires expansive, non-judgmental thinking; convergence requires evaluative, narrowing thinking. Research on cognitive load and creativity finds these are fundamentally incompatible mental modes — "it's impossible and contradictory to engage in both kinds of thinking at the same time" ([Asana](https://asana.com/resources/convergent-vs-divergent), [NN/g](https://www.nngroup.com/articles/diverge-converge/)).

**Implication for Option A**: The two-mode structure is well-aligned with how creative cognition actually works. The key question is whether mode transitions within a single step preserve the cognitive discipline that separate steps enforce.

### OODA Loops: Orientation as the Core Activity

John Boyd's OODA loop (Observe → Orient → Decide → Act) is relevant because Orient — the sensemaking phase — is where the real work happens. Gordon Brander [argues](https://newsletter.squishy.computer/p/tools-for-thought-in-your-ooda-loop) that "the timescale at which you can make sense is the timescale in which you have agency." Boyd himself didn't imagine a strict sequential flow; he described **iterative feedback loops** where observation and orientation continuously inform each other.

This directly supports Option A: the synthesize agent doing inline research is essentially the Orient phase pulling in more Observation when its model has gaps. The formal loopback mechanism in the current design artificially linearizes what Boyd saw as naturally iterative.

### Cynefin: Probe Before You Plan

Dave Snowden's Cynefin framework distinguishes domains by how much you can know upfront. For complex problems (most non-trivial software work), the prescribed approach is **probe → sense → respond** — you must experiment before you can understand, and understanding precedes planning. This argues against rigid phase separation: you often cannot know what research is needed until you start planning, and planning reveals what you don't know.

Cynefin's prescription maps well to Option A: the Discover phase probes broadly, then the Synthesize phase senses patterns and responds with architecture — but can probe again when sensing reveals gaps.

### Agile Spikes: Time-Boxed Exploration

The agile spike concept (from Extreme Programming) represents "just enough" research to reduce risk before committing to implementation. Spikes are deliberately **not separated from planning** — they are a planning tool. A spike's output feeds directly into sprint planning decisions. The separation is between exploration and commitment, not between research and planning.

This maps directly to Option A's gate placement: the gate sits at the boundary between exploration (the entire explore step) and commitment (spec/decompose/implement), not between research and planning sub-activities.

### Dimitri Glazkov's Framing vs. Solving Distinction

[Glazkov](https://glazkov.com/2021/10/24/framing-and-solving-diverge-converge-exercises/) distinguishes two types of diverge-converge exercises: **framing** (understanding the full picture by synthesizing perspectives) vs. **solving** (choosing among alternatives). The research-to-plan transition is fundamentally a framing exercise — you are building a complete picture, not eliminating options. This argues for keeping research and planning tightly coupled, since premature separation can apply "solving" elimination logic to what should be a "framing" synthesis activity.

### NN/g: Strict Phase Discipline Matters

The Nielsen Norman Group's research on diverge-converge workshops [emphasizes](https://www.nngroup.com/articles/diverge-converge/) that mixing phases causes groupthink, bias contamination, and unequal participation. They advocate "strictly enforcing divergent and convergent time."

**Counter-argument for Option A**: While this applies to multi-human workshops (where social dynamics cause contamination), it maps differently to multi-agent systems where each agent operates in an isolated context window. The parallel Discover agents already have strict phase separation by architecture. The risk is in the Synthesize agent — if it attempts to both synthesize and research simultaneously, it may lose coherence.

---

## Agentic Workflow Research

### The RPI Pattern (Research, Plan, Implement)

The dominant agentic coding workflow pattern in 2025-2026 is RPI — Research, Plan, Implement — popularized by Dex Horthy's "Ralph loops" ([LinearB](https://linearb.io/blog/dex-horthy-humanlayer-rpi-methodology-ralph-loop)). Key principles:

- **Fresh context windows per phase** prevent compounding confusion
- **Written artifacts** (RESEARCH.md, PLAN.md) serve as ground truth between sessions
- The "Dumb Zone" concept: model performance degrades when context exceeds ~40% capacity, driving explicit compaction points between phases

Tyler Burleigh's [RPIR variant](https://tylerburleigh.com/blog/2026/02/22/) adds review gates: Research → Research Review → Planning → Plan Review. He found that "getting the research right prevents bad assumptions from cascading into the plan."

**Implication for Option A**: The RPI community's emphasis on context resets between research and planning is the strongest argument against merging them. However, Option A's architecture partially addresses this: the Discover agents have their own context windows (natural reset), and the Synthesize agent starts with a fresh context reading distilled findings (another natural reset). The question is whether the Synthesize agent's inline research degrades its context over time.

### Anthropic's Multi-Agent Research System

Anthropic's own [engineering blog](https://www.anthropic.com/engineering/multi-agent-research-system) describes their production multi-agent research system with exactly the pattern Option A proposes:

1. **Lead agent plans** and spawns 3-5 parallel subagents
2. **Subagents research independently** with separate context windows
3. **Lead agent synthesizes** findings and decides whether additional research is needed
4. If gaps exist, the lead spawns more subagents — no formal loopback, just built-in capability

Key findings from their experience:
- Early versions spawned 50+ subagents for simple queries — **explicit scaling rules** were needed
- Subagents return condensed summaries (1,000-2,000 tokens) to prevent context pollution
- The lead saves plans to external memory before context exhaustion
- Current architecture is synchronous, creating bottlenecks when any subagent delays

This is essentially Option A's architecture validated in production at Anthropic.

### Anthropic's Context Engineering Guidelines

Anthropic's [context engineering guide](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) makes the case for **context-aware phase separation**: sub-agent architectures for parallel exploration, compaction for sequential work, note-taking for iterative milestones. The overarching principle: "treat context as a finite, precious resource, carefully curating what crosses phase boundaries."

This supports Option A's gate at the end of explore: the Synthesize agent's output is the curated artifact that crosses the boundary into spec. Raw research findings never cross the gate.

### Deep Agent Architecture

The [Deep Agent architecture](https://dev.to/apssouza22/a-deep-dive-into-deep-agent-architecture-for-ai-coding-assistants-3c8b) for coding assistants uses a pattern closely aligned with Option A:

- **Explorer** agents (read-only) produce "distilled contexts" — refined knowledge, not raw data
- An **Orchestrator** synthesizes discoveries into strategic plans
- A shared **Context Store** accumulates knowledge, enabling "compound intelligence where the system gets smarter as it works"
- The Orchestrator cannot directly access code — "forced delegation prevents shortcuts"

The key insight: exploration and synthesis are architecturally separated by context boundaries (different agents), but logically unified in a single workflow phase.

### Google Research: When Multi-Agent Systems Work

Google's [research on scaling agent systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/) found:

- Multi-agent systems excel on **parallelizable tasks** (+81% on financial analysis)
- They **degrade on sequential reasoning** (39-70% worse) due to communication fragmentation
- Centralized orchestrators contain error amplification (4.4x vs 17.2x in independent systems)
- The orchestrator acts as a "validation bottleneck" that catches errors before propagation

**Implication for Option A**: The Discover phase (parallelizable research) is exactly where multi-agent shines. The Synthesize phase (sequential reasoning building an architecture) should be single-agent. This validates the two-mode structure.

### gstack (Garry Tan)

[gstack](https://github.com/garrytan/gstack) structures work as: Think → Plan → Build → Review → Test → Ship → Reflect. Notably, "Think" and "Plan" are separate but tightly coupled — each skill "knows what came before it" and feeds directly into the next. The workflow is sequential with artifacts as handoff points. This is closer to the current separate-step approach than Option A, but gstack's phases are much lighter-weight than formal gated steps.

### The Context Pollution Problem

Multiple sources converge on context pollution as the key risk when combining phases:

- Microsoft Research found **memory interference**: information from one task contaminates reasoning about another when sharing a context window
- The RPI community's "Dumb Zone" concept: performance degrades past ~40% context utilization
- Anthropic recommends sub-agents returning only "condensed summaries (1,000-2,000 tokens)" to prevent pollution

Option A mitigates this by design: Discover agents have isolated contexts, and the Synthesize agent reads distilled findings. But if the Synthesize agent spawns many inline research subagents, its own context accumulates their returns, potentially hitting the Dumb Zone.

---

## Strongest Arguments For

1. **Matches how sensemaking actually works.** OODA, Cynefin, and the Double Diamond all describe research and planning as iteratively interleaved, not strictly sequential. The formal loopback mechanism fights the natural cognitive flow. Option A aligns the workflow with how experts actually think.

2. **Eliminates artificial friction.** The current loopback machinery adds ceremony to something that should be fluid. When the plan agent discovers a gap, it should just investigate it — not file a formal request to re-enter the research step, wait for approval, restart research, re-gate, and re-enter planning.

3. **Validated architecture.** Anthropic's own multi-agent research system and the Deep Agent architecture both implement essentially this pattern in production: parallel exploration → single-agent synthesis with inline research capability.

4. **Better gate placement.** Moving the gate to the end of explore (before spec) puts the human review point at the true commitment boundary — between exploration and commitment, not between two sub-activities of exploration. This matches the agile spike concept: the important boundary is between investigation and execution.

5. **Natural context firewall.** The Discover → Synthesize transition already creates a context reset: Discover agents run in isolated windows and produce distilled summaries; the Synthesize agent starts fresh reading those summaries. This provides the context firewall benefit of the current gate without the step-transition overhead.

6. **Simpler state model.** One step with two modes is simpler than two steps with loopback machinery. Less state to track, fewer transitions to manage, fewer edge cases in the step lifecycle.

7. **Preserves parallel buckshot.** The Discover mode keeps the valuable pattern of multiple agents exploring in parallel, which the user explicitly wants to preserve.

---

## Strongest Arguments Against

1. **Context degradation in the Synthesize agent.** If the Synthesize agent spawns many inline research subagents, its context accumulates their returns. Each "quick investigation" adds tokens. Over enough iterations, the agent hits the Dumb Zone (~40% context) and synthesis quality degrades — exactly the problem that separate steps with context resets solve. The RPI community's emphasis on fresh context windows per phase is grounded in hard experience.

2. **Loss of the mid-process review point.** The current gate between research and plan gives the human a chance to review research findings before planning begins. With Option A, the human doesn't see anything until the full explore step is done. If the Discover phase went in the wrong direction, the error compounds through Synthesize before anyone catches it. The gate between research and plan currently acts as an early-warning system.

3. **Cognitive discipline of separate phases.** NN/g's research shows that strictly enforcing divergent and convergent phases produces better outcomes. Even though agents don't have the same social dynamics as humans, mixing "go broad" and "narrow down" in a single step may reduce the quality of both. The mode labels (Discover/Synthesize) help, but there is no hard enforcement — the Synthesize agent might skip straight to planning without adequate exploration, or keep exploring when it should be converging.

4. **Harder to debug and audit.** With separate steps, each has clear inputs, outputs, and a state transition. With a combined step, the internal mode transitions are implicit. If the output is poor, was it because Discover was insufficient? Synthesize was sloppy? Inline research was wrong? The audit trail is murkier.

5. **Risk of the "one more search" anti-pattern.** Without a formal boundary, the Synthesize agent may fall into unlimited inline research — repeatedly spawning subagents to fill gaps that lead to more gaps. The current loopback mechanism, while clunky, forces a deliberate decision: "is this gap significant enough to warrant re-entering research?" That forcing function has value.

6. **Synthesizer bottleneck at scale.** Google's research shows centralized orchestrators become bottlenecks at 10-20 agents. If the Synthesize agent is coordinating both synthesis and inline research, it takes on a dual role that could overwhelm it on complex initiatives. The current separation naturally distributes this cognitive load.

7. **Asymmetry with the rest of the workflow.** If every other phase transition in the harness (spec → decompose → implement → review) has a gate with artifacts, but explore is a monolithic step with internal modes, the workflow model becomes inconsistent. Users must learn two mental models: gated steps and internal modes.

---

## Key Sources

### Productivity / Work Frameworks
- [Double Diamond (Wikipedia)](https://en.wikipedia.org/wiki/Double_Diamond_(design_process_model)) — Diverge/converge model from British Design Council
- [NN/g: Diverge-and-Converge Technique](https://www.nngroup.com/articles/diverge-converge/) — Why mixing phases undermines effectiveness
- [Gordon Brander: Tools for Thought in Your OODA Loop](https://newsletter.squishy.computer/p/tools-for-thought-in-your-ooda-loop) — Orientation as the key sensemaking phase
- [Cynefin Framework (Wikipedia)](https://en.wikipedia.org/wiki/Cynefin_framework) — Probe-sense-respond for complex domains
- [Dimitri Glazkov: Framing and Solving Diverge-Converge Exercises](https://glazkov.com/2021/10/24/framing-and-solving-diverge-converge-exercises/) — Framing (synthesis) vs solving (elimination) distinction
- [Asana: Convergent vs Divergent Thinking](https://asana.com/resources/convergent-vs-divergent) — Cognitive incompatibility of simultaneous divergent/convergent thinking
- [SAFe: Spikes](https://framework.scaledagile.com/spikes) — Time-boxed research as a planning tool in agile

### Agentic Workflow / AI Coding
- [Anthropic: How We Built Our Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) — Production parallel-research-then-synthesize architecture
- [Anthropic: Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Context pollution, sub-agent isolation, phase separation strategies
- [LinearB: Ralph Loops / RPI Methodology](https://linearb.io/blog/dex-horthy-humanlayer-rpi-methodology-ralph-loop) — Research-Plan-Implement with ruthless context resets
- [Tyler Burleigh: Research, Plan, Implement, Review](https://tylerburleigh.com/blog/2026/02/22/) — RPIR variant with review gates between phases
- [AIMultiple: Optimizing Agentic Coding](https://aimultiple.com/agentic-coding) — RPI workflow and context contamination concerns
- [Deep Agent Architecture](https://dev.to/apssouza22/a-deep-dive-into-deep-agent-architecture-for-ai-coding-assistants-3c8b) — Explorer/Orchestrator/Coder separation with distilled contexts
- [Google Research: Towards a Science of Scaling Agent Systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/) — When multi-agent helps vs hurts; error amplification data
- [garrytan/gstack (GitHub)](https://github.com/garrytan/gstack) — Think → Plan → Build workflow with artifact handoffs
- [Microsoft Research: CORPGEN](https://www.marktechpost.com/2026/02/26/microsoft-research-introduces-corpgen-to-manage-multi-horizon-tasks-for-autonomous-ai-agents-using-hierarchical-planning-and-memory/) — Memory interference in shared context windows

### Multi-Agent Architecture
- [Medium: Multi-Agent System Patterns](https://medium.com/@mjgmario/multi-agent-system-patterns-a-unified-guide-to-designing-agentic-architectures-04bb31ab9c41) — Orchestrator-worker pattern, synthesis failure as primary failure mode
- [LangChain: Choosing the Right Multi-Agent Architecture](https://blog.langchain.com/choosing-the-right-multi-agent-architecture/) — Centralized vs distributed coordination trade-offs
- [Google: Multi-Agent Design Patterns (InfoQ)](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/) — Eight essential patterns including parallel dispatch and synthesis
