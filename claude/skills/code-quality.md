---
name: code-quality
description: "Universal code quality anti-patterns and correctness rules. Activates when editing source files or running code review commands. Propagate to review agents and implementation subagents via skills: [code-quality] frontmatter."
meta:
  stack: ["all"]
  version: 2
  last_reviewed: 2026-03-24
---

# Code Quality

This skill provides anti-pattern detection rules and correctness checklists
that apply to any codebase. It exists as a skill (not a rule) so that it
propagates to subagents — review agents, implementation agents, and any
spawned helper all inherit this knowledge.

## When This Activates

- Editing source code files
- Running code review commands (`/work-review`)
- Spawning review or implementation agents

## Universal Rules

These rules apply regardless of language or framework.

### 1. Fail closed, never fail open

Missing configuration, secrets, or dependencies = **hard error**, not a graceful fallback. Never generate unsigned tokens, skip auth checks, or degrade security because a secret is not set. If a required value is absent, return an error or refuse to start.

### 2. Never swallow errors

Every error return must be checked. No discarding error returns from database calls, template renders, or JSON encodes. If an operation can fail, handle the failure — log it, return it, or both.

### 3. Never fabricate data

When an operation fails or a dependency is nil, **do not** return synthetic defaults (fake IDs, empty JSON, zero values with nil error). Fabricated data looks valid to callers and hides wiring/infrastructure failures.

### 4. Always handle both branches

If you write a conditional that checks for success, you **must** handle the failure path. Conditional-only-on-success leaves the failure path with stale/zero data and no indication anything went wrong.

### 5. Constructor injection only

All dependencies must be available at construction time. Do not use setter injection or post-construction callbacks. If this creates a circular dependency, restructure the initialization order — do not paper over it with setters and nil-check guards.

### 6. Return complete results

Functions that claim to analyze multiple inputs must actually analyze all of them. Do not short-circuit on the first match when the contract implies comprehensive analysis.

### 7. No divergent interface copies

Consumer-side interface narrowing (small interfaces at the call site) is fine. But do not create multiple interfaces with the **same name and similar method sets** that diverge over time. If the same interface name exists in three packages with three different signatures, that is a bug.

### 8. No shims or backward compatibility

Do not add migration fallbacks, future-proofing abstractions, or compatibility layers unless explicitly requested. Build for what is needed now. If requirements change, refactor then. This includes: config knobs for unused targets, query-time data fallbacks, cleanup code for removed features, and compatibility wrappers for deprecated approaches.

## How to Use

When writing or reviewing code, check against these 8 universal rules. When spawning subagents that will write or review code, include `skills: [code-quality]` in the agent spawn to propagate these rules.

## Parallel Review

For substantial diffs (50+ lines across 3+ files), use the 9-parallel-review-agents
pattern instead of a single sequential review. Each agent covers one quality dimension
(correctness, error handling, security, performance, API contract, test coverage,
maintainability, concurrency, config/infra). A lead agent spawns all 9 in parallel,
collects findings, deduplicates, and presents a consolidated report.

See `references/parallel-review.md` for the full pattern, agent prompt template,
and when-to-use guidance.

## Language-Specific Anti-Patterns

Read `references/<language>-anti-patterns.md` where `<language>` is `stack.language`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.language` is absent or `other`,
or no matching file exists, skip this section.

Adding a new language pack requires only creating one file at `references/<language>-anti-patterns.md` — no changes to this file or any other file are needed.

## Framework-Specific Anti-Patterns

Read `references/<framework>-anti-patterns.md` where `<framework>` is `stack.framework`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.framework` is absent,
or no matching file exists, skip this section.

Adding a new framework pack requires only creating one file at `references/<framework>-anti-patterns.md` — no changes to this file or any other file are needed.

## Frontend-Specific Anti-Patterns

Read `references/<frontend>-anti-patterns.md` where `<frontend>` is `stack.frontend`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.frontend` is absent,
or no matching file exists, skip this section.

Adding a new frontend pack requires only creating one file at `references/<frontend>-anti-patterns.md` — no changes to this file or any other file are needed.

## Complementary Tools

- **Codex second-opinion review** -- When available, `/work-review` automatically runs Codex as a second reviewer. Codex findings are verified against these same quality rules before inclusion. See the `codex-review` skill for details.

## References
- **Security Anti-Patterns** -- Common security mistakes in LLM-generated code (path: `references/security-antipatterns.md`)
- **AI Config Linting** -- Rules for Claude Code and harness configuration files (path: `references/ai-config-linting.md`)
- **Parallel Review** -- 9-agent concurrent review pattern (path: `references/parallel-review.md`)
