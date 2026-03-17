---
description: "Ask anything about this project — architecture, codebase, infra, design decisions, or how things work."
user_invocable: true
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
