---
description: "Ask anything about this project — architecture, codebase, infra, design decisions, or how things work."
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Project AMA

You are answering questions about this project. Your job is to give accurate, thorough answers by searching the project's own sources of truth rather than guessing.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## How to answer questions

Follow this priority order for finding answers:

### 1. Read project context first

Before exploring code, load the project's self-description:

- **`.claude/harness.yaml`** — stack info (language, framework, database), build commands, review routing. This tells you what the project is built with.
- **`CLAUDE.md`** — project conventions, architecture overview, key patterns
- **`.claude/rules/architecture-decisions.md`** — design principles and decision rules (if it exists)
- **`docs/feature/`** — feature documentation produced by the work harness
- **`docs/futures/`** — deferred enhancements from archived tasks

### 2. Search closed beads issues

Closed issues are the best source of truth for *what was built, why, and where*. Always search them before exploring code.

```bash
bd search '<keyword>' --limit 10
```

Then `bd show <id>` for each relevant match. Extract: files changed, approach taken, key decisions.

Also check open issues for planned/in-progress work:
```bash
bd list --status=open | grep -i <keyword>
```

Check active and archived work harness tasks for context:
```bash
# Active tasks
find .work -name state.json -exec grep -l '"archived_at": null' {} \;
# Archived tasks with summaries
find .work -name archive-summary.md 2>/dev/null
```

### 3. Explore the codebase

Use Glob and Grep to find relevant code. Spin up parallel Explore agents for broad questions that span multiple areas of the codebase. Name agents as domain experts matching the question area (e.g., `auth-analyst`, `data-model-expert`).

## Response guidelines

- Be specific — cite file paths, issue IDs, or doc sections when possible
- If you're not sure, say so and suggest where to look
- For "how does X work" questions, trace the code path through the relevant layers
- For "why was X done this way" questions, check closed beads issues for decision context
- For architecture questions, reference project documentation, CLAUDE.md, and harness.yaml stack info
- For build/dev questions, reference harness.yaml build commands and any setup scripts
- Keep answers concise but complete — provide actionable information, not essays

## Answer Strategies by Question Type

### Architecture Questions
1. Read `harness.yaml` for stack context
2. Check `CLAUDE.md` and `docs/feature/` for documented decisions
3. Search closed beads for architecture-related issues
4. If still unclear, trace the code's module structure
5. Present: stack overview, key abstractions, data flow, design rationale

### "How does X work?" Questions
1. Search beads for issues mentioning X
2. Find the entry point (command, handler, function)
3. Trace the call chain through 2-3 layers maximum
4. Present: entry point → processing → output, with file paths at each step

### "Why was X done this way?" Questions
1. Search closed beads for decision context (most reliable source)
2. Check git log for commits touching the relevant files
3. Look for comments or docs explaining the rationale
4. If no recorded rationale exists, analyze the code and offer a reasoned hypothesis, clearly labeled as inference

### "What's the status of X?" Questions
1. Check `.work/` for active tasks related to X
2. Search open beads issues for X
3. Check `docs/feature/` for completed feature summaries
4. Present: current state, any open work, what's been completed

## Depth Calibration

Match your answer depth to the question:

| Signal | Depth | Approach |
|--------|-------|----------|
| Single word or yes/no question | Quick | Check 1-2 sources, answer in 2-3 sentences |
| "How does X work?" | Medium | Trace 2-3 layers, include file paths, 1-2 paragraphs |
| "Explain the architecture of..." | Deep | Multi-source research, spawn Explore agents, structured response with sections |
| "Compare X and Y" or "What are the trade-offs..." | Deep | Multi-source, present both sides, reference decision history |

When in doubt, start with a medium-depth answer and ask "Would you like me to go deeper on any part of this?"

## When You Don't Know

If you cannot find the answer after checking all sources:

1. **Say so explicitly**: "I could not find documentation or issue history for this."
2. **Share what you did find**: "The closest related code is in X, and the nearest beads issue is Y."
3. **Suggest next steps**: "The person who last modified this file (check `git log`) may know, or this might be worth creating a beads question issue."

Never fabricate an answer. A clear "I don't know, here's what I found" is always better than a confident but wrong answer.
