# Research Handoff: Agent-First Architecture

## What This Step Produced

6 research notes covering current architecture, Agent tool API surface, prior art from closed issues, opportunity analysis, Agent Teams feature, and model selection analysis.

## Key Findings

### 1. Current Delegation Gap
The harness executes plan, spec, and decompose steps **inline** in the lead agent's context window. Only research, implement, and review actually spawn subagents. This is the core opportunity — delegating these middle steps to specialized agents would free the lead to orchestrate rather than execute.

### 2. Agent Tool API Has Untapped Features
- `run_in_background` — not used, could enable async step execution
- `name` + SendMessage — not used, could enable agent coordination
- `model` override — not used; user preference is max power (Opus) by default, only relevant if models differ markedly per task type
- Custom `subagent_type` strings — minimally used, could enable domain-expert naming
- Agent Teams (TeamCreate/TeamDelete) — enabled and available, not yet used in harness

### 3. Foundational Infrastructure Exists
Harness-improvements (archived 2026-03-18) already delivered:
- Stream doc format with 7 YAML frontmatter fields (C1)
- Dynamic delegation routing tables (C8)
- Research protocol with self-writing agents (C5)
- Parallel execution v2 with phase gating (C9)

These provide the scaffolding. W2 extends delegation from implement-only to ALL steps.

### 4. Agent Teams: Real Coordination Infrastructure
Agent Teams (TeamCreate/TeamDelete) are **enabled and available**. They provide capabilities beyond manual subagents:
- **Shared task list** with dependency resolution and self-claiming
- **Direct mailbox** between teammates (not lead-mediated)
- **File locking** to prevent race conditions
- **Independent context windows** per teammate

Key constraint: **no session resumption** — teammates disappear on `/resume`. Mitigated by the harness's file-based handoff pattern (results persist in `.work/`). Best fit: research and review steps (clear boundaries, no file mutations, natural parallelism). Extend to implement once proven.

### 5. Model Selection: Opus Everywhere
No evidence of meaningful quality differences per task type. User preference: max power (Opus), cost not a concern. Fast mode is Opus with faster output, not a different model. Defer model routing — revisit only with performance data.

### 6. Skill Injection Remains Path B (Prompt-Based)
Skills are injected via Read instructions in agent prompts. YAML frontmatter `skills:` is not supported. This is a known verbosity cost but works reliably. No change needed for W2.

### 7. Phased Implementation Recommended

| Phase | Items | Rationale |
|-------|-------|-----------|
| 1 | Steps as agents + decompose-as-agents + context seeding | Foundation — must work before optimizing |
| 2 | Parallelize decomposition + delegation audit + Agent Teams exploration | Optimize once basic delegation works; Teams is enabled and available |
| 3 | `/delegate` skill | Needs stable patterns to route to |

## Key Artifacts

- `.work/agent-first-architecture/research/01-current-architecture.md` — full architecture map
- `.work/agent-first-architecture/research/02-agent-tool-api.md` — API surface inventory
- `.work/agent-first-architecture/research/03-prior-art.md` — closed issue findings
- `.work/agent-first-architecture/research/04-opportunity-analysis.md` — design analysis
- `.work/agent-first-architecture/research/05-agent-teams.md` — Teams API, communication model, constraints
- `.work/agent-first-architecture/research/06-model-selection.md` — Opus everywhere decision
- `.work/agent-first-architecture/research/index.md` — topic index
- `.work/agent-first-architecture/futures.md` — 4 deferred enhancements

## Open Questions for Planning

1. **User interaction model for agent-executed steps**: Plan step often requires back-and-forth with the user. Options: (a) agent produces draft, lead presents; (b) agent runs foreground, user interacts directly; (c) agent produces draft + question list, lead mediates.

2. **Context seeding contract**: What exact artifacts does each step agent receive? Need a formal "step context spec" — previous handoff + rules + state metadata.

3. **Artifact format validation**: Agent-produced artifacts must match expected formats for Phase A/B validation. Should we add schema validation or rely on Phase A structural checks?

4. **Step agent mode selection**: Which permission mode for each step agent? Plan/spec could be `plan` mode (read-only-ish), while decompose needs `default` (creates beads issues).

5. **Failure/retry protocol**: When a step agent produces artifacts that fail Phase A validation, what's the retry strategy? Re-spawn with feedback, or escalate to lead?

6. **Tier 2 applicability**: Should Tier 3 be the proving ground for 1-2 iterations before extending to Tier 2? What success criteria trigger that extension?

7. **Agent Teams integration points**: Which steps benefit most from Teams (shared task list, mailbox) vs plain subagents? Research and review are strong candidates — what's the minimum viable Teams integration?

## Instructions for Plan Step

1. Read this handoff prompt as primary input
2. Design an architecture document addressing the 6 open questions above
3. Define component boundaries: which commands change, what new agents are needed, how context flows
4. Use the phased implementation recommendation as starting structure
5. Write architecture to `.work/agent-first-architecture/specs/architecture.md`
6. Consider: the goal is to change HOW steps execute (via agents), not WHAT they produce (artifacts stay the same)
