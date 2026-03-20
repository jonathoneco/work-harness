# W2: Agent-First Architecture

**Status:** active
**Tier:** 3
**Priority:** P2

## Goal

The harness should delegate to specialized agents with proper context, not worktrees. Each workflow phase runs as a named subagent with relevant artifacts seeded as context.

## Work Items

- [ ] Fix: decompose as agents, not worktrees — fundamental architecture shift
- [ ] Steps as agents — each workflow phase runs as a named subagent
- [ ] Parallelize decomposition — specific agents for research, planning, spec
- [ ] `/delegate` skill — auto-routing to the right agent based on task characteristics
- [ ] Delegation with proper context — agents get seeded with relevant artifacts, not raw dumps
- [ ] Subagent delegation audit — fix current delegation gaps
- [ ] Agent Teams integration — experimental, blocked on API stability

## Key Files

_To be populated during implementation._
