---
name: context-seeding
description: "Context seeding protocol for step agent prompts — standard preamble, per-step context table, handoff contract, anti-patterns"
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Context Seeding Protocol

Protocol for seeding step agents with exactly the right context. Consumed by
command files and the dispatcher when constructing agent prompts.

The protocol standardizes what each step agent receives and, critically, what it
does NOT receive. Handoff prompts are the only bridge between steps.

---

## 1. Standard Preamble

Every step agent prompt includes this preamble, filled by the lead at dispatch
time from `state.json`:

```
## Task Context
- Task: {name} (Tier {tier})
- Title: {title}
- Step: {current_step}
- Base commit: {base_commit}
- Epic: {beads_epic_id}
```

### Stack Context Block (conditional)

Appended to the preamble only if `.claude/harness.yaml` exists:

```
## Stack Context
- Language: {stack.language}
- Framework: {stack.framework}
- Database: {stack.database}
- Build commands: {stack.build_commands}
```

**Variable substitution**: The lead reads `state.json` and `harness.yaml` at
dispatch time, fills all variables. No variable syntax is passed to agents -- all
values are resolved before prompt construction.

---

## 2. Per-Step Context Table

| Step | Primary Input | Additional Context | Does NOT Receive |
|------|--------------|-------------------|------------------|
| Research | Task description from state.json | Topic assignments, output format template | Prior step artifacts (none exist) |
| Plan | `.work/{name}/research/handoff-prompt.md` | -- | Individual research notes, raw research data |
| Spec | `.work/{name}/plan/handoff-prompt.md` | `.work/{name}/specs/architecture.md` | Research notes, raw plan discussion |
| Decompose | `.work/{name}/specs/handoff-prompt.md` | All spec files (`specs/*.md`) | Research notes, plan notes |
| Implement | `.work/{name}/streams/handoff-prompt.md` | Stream doc, relevant specs only | Other streams' docs, research/plan notes |
| Review | Full diff (`git diff {base_commit}...HEAD`) | Findings template, quality checklist | Step-internal artifacts |

**Key rule**: The "Does NOT Receive" column is as important as what agents DO
receive. Over-seeding wastes context and confuses agents.

---

## 3. Handoff Prompt Contract

Handoff prompts follow a consistent structure:

```markdown
# {Step} Handoff: {Task Title}

## What This Step Produced
{Summary of artifacts, decisions, key findings}

## Key Artifacts
{List of file paths with one-line descriptions}

## Decisions Made
{Numbered list of decisions with brief rationale}

## Open Questions / Deferred Items
{Items the next step should address}

## Instructions for {Next Step} Step
{Numbered instructions specific to the next step}
```

The handoff prompt is the ONLY bridge between steps. It references file paths to
artifacts -- it does not copy artifact content inline.

---

## 4. Rule File Injection

Every agent reads rule files via the skill injection pattern (spec 00, section 3).
Skills are injected as explicit read instructions in the Rules section:

```
## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/work-harness.md`
```

### Per-Step Skill Matrix

| Step | Required Skills | Condition |
|------|----------------|-----------|
| Plan | code-quality | Always |
| Spec | code-quality | Always |
| Decompose | code-quality, work-harness | Always |
| Research | code-quality, work-harness | Always |
| Implement | code-quality, work-harness | Always |
| Review | code-quality | Always |

**Why plan/spec/review skip `work-harness`**: These agents produce design
artifacts (architecture docs, specs, review findings) -- they don't need to
understand harness conventions like state management, step transitions, or beads
workflows. Only steps that interact with harness infrastructure (decompose
creates beads issues, implement follows stream conventions, research writes to
harness-structured directories) need the `work-harness` skill.

---

## 5. Managed Docs Injection (conditional)

If `.claude/harness.yaml` exists and defines `docs.managed`:
- The lead reads the managed doc paths
- Includes a "Managed Project Docs" section in the agent's Instructions with
  the file paths
- The agent reads these files as part of its work

If no `harness.yaml`: skip entirely. Do not reference managed docs.

---

## 6. Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|-------------|----------------|-----------------|
| Copying research notes into plan agent prompt | Wastes context, bypasses handoff firewall | Reference handoff prompt only |
| Including ALL spec files in implement agent prompt | Agent only needs its stream's specs | Include only relevant specs per stream |
| Passing conversation history to agents | Agents are stateless, conversation is lead-specific | Use handoff prompts and state.json only |
| Injecting rules as inline text | Duplicates content, risks divergence | Use skill injection (read file references) |
| Including futures.md in step agent prompts | Futures are deferred items, not actionable context | Only the lead manages futures |
