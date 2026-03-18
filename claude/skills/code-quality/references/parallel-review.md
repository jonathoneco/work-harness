# Parallel Review

A coordination pattern for thorough code review using 9 specialized agents running concurrently. Each agent focuses on one quality dimension, reads the full diff, and produces findings in a structured format. A lead agent collects, deduplicates, and presents consolidated results.

## Overview

When reviewing a significant diff (50+ changed lines across 3+ files), a single sequential review tends to focus on surface issues and miss cross-cutting concerns. The parallel review pattern addresses this by spawning 9 agents, each an expert in one quality dimension. Running in parallel keeps total review time close to the time of the slowest single agent rather than 9x sequential.

## The 9 Review Dimensions

| # | Dimension | Focus | Agent Type |
|---|-----------|-------|------------|
| 1 | Correctness | Logic errors, off-by-one, wrong comparisons, missing null checks | Explore |
| 2 | Error Handling | Swallowed errors, missing error paths, bare returns, panic recovery | Explore |
| 3 | Security | Auth bypass, injection, secrets exposure, crypto misuse (see `security-antipatterns.md`) | Explore |
| 4 | Performance | N+1 queries, unnecessary allocations, missing indexes, blocking in async paths | Explore |
| 5 | API Contract | Breaking changes, missing validation, inconsistent response shapes, undocumented fields | Explore |
| 6 | Test Coverage | Untested code paths, missing edge cases, test quality (not just existence) | Explore |
| 7 | Maintainability | Dead code, unclear naming, excessive coupling, missing abstractions (or excessive ones) | Explore |
| 8 | Concurrency | Race conditions, missing synchronization, deadlock potential, shared mutable state | Explore |
| 9 | Config and Infra | AI config linting rules (see `ai-config-linting.md`), environment assumptions, deployment concerns | Explore |

## Agent Prompt Template

Use this template when spawning each review agent. Replace `[DIMENSION]` with the agent's assigned dimension and `[DIFF_CONTENT]` with the diff or a command to obtain it.

```
You are reviewing a code diff for [DIMENSION] issues only.

Diff: [DIFF_CONTENT or git diff command]
Specs: [RELEVANT_SPEC_PATHS]

Report findings in the standard work-review format:

### [SEVERITY] Title
- **Category**: [DIMENSION]
- **File**: <relative path>
- **Line**: <line number or "file-level">
- **Description**: <detailed explanation>
- **Suggested fix**: <what to change>

Severity levels: critical | important | suggestion

If you find no issues in your dimension, report "No [DIMENSION] issues found."
Do not report issues outside your assigned dimension.
```

## Lead Agent Responsibilities

The lead agent orchestrates the review process:

1. **Spawn** all 9 agents in parallel with the same diff
2. **Collect** findings from all agents as they complete
3. **Deduplicate** — same file + same line + similar finding = one entry, keeping the most detailed description
4. **Sort** by severity (critical first, then important, then suggestion)
5. **Present** consolidated findings to the user in a single report

## When to Use

- **Implementation phase gating reviews** — Inter-Step Quality Review Protocol, Phase B
- **`/work-review` command** — when thoroughness matters
- **Pre-merge reviews** — any review where catching issues is more important than review speed
- **Threshold**: 50+ changed lines across 3+ files

## When NOT to Use

- **Small changes** — under 50 changed lines or only 1-2 files. A single review agent is sufficient
- **Time-critical hotfixes** — use a single focused review instead of waiting for 9 agents
- **Pure documentation changes** — only dimensions 5 (API Contract) and 7 (Maintainability) are relevant; spawn just those two instead of all 9

## Cross-References

- **Security dimension** agents should load `security-antipatterns.md` for the full anti-pattern catalog
- **Config/Infra dimension** agents should load `ai-config-linting.md` for AI tooling config rules
- **All agents** inherit universal rules from the `code-quality` skill when spawned with `skills: [code-quality]`
