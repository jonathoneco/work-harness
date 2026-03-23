# Spec 00: Cross-Cutting Contracts

## Overview

Shared conventions, schemas, and interfaces consumed by all component specs (01-06). This document is the canonical reference for agent prompt structure, naming, retry protocols, and quality signals across the agent-first architecture.

All component specs MUST reference this document. No spec may define its own prompt structure, retry protocol, or naming convention — use the contracts defined here.

---

## 1. Agent Prompt Structure

Every step agent prompt follows this section order:

```
## Identity
You are a {step} agent for the work harness.
Your task: {one-line summary}

## Task Context
{Standard preamble — see §2}

## Rules
Read and follow these before proceeding:
{Skill injection list — see §3}

## Instructions
{Step-specific instructions — from spec 02 templates}

## Output Expectations
{What artifacts to produce, where to write them}

## Completion
{What to return to the lead when done}
```

### Section Requirements

| Section | Required | Purpose |
|---------|----------|---------|
| Identity | Yes | Primes the agent's role and scope |
| Task Context | Yes | Standard preamble from context seeding protocol (spec 01) |
| Rules | Yes | Skill injection — always includes code-quality.md |
| Instructions | Yes | Step-specific work instructions |
| Output Expectations | Yes | Artifact locations, format requirements |
| Completion | Yes | Return message format for the lead |

**No additional sections.** If a step needs extra context (e.g., user feedback on re-spawn), it goes under a "Previous Attempt" section inserted between Rules and Instructions (see §5).

---

## 2. Standard Preamble Template

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

**Variable substitution**: The lead reads `state.json` and `harness.yaml` at dispatch time, fills all variables. No variable syntax is passed to agents — all values are resolved before prompt construction.

---

## 3. Skill Injection Convention

Claude Code agents do not support `skills:` in YAML frontmatter. Skills are injected as explicit read instructions in the Rules section:

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

**Why plan/spec/review skip `work-harness`**: These agents produce design artifacts (architecture docs, specs, review findings) — they don't need to understand harness conventions like state management, step transitions, or beads workflows. Only steps that interact with harness infrastructure (decompose creates beads issues, implement follows stream conventions, research writes to harness-structured directories) need the `work-harness` skill.

**No optional skills.** If `harness.yaml` defines managed docs, the lead includes them in the Instructions section as inline context, not as a skill reference.

---

## 4. Naming Conventions

### Agent `description` Parameter
3-5 word summary: `"{step} {task-name-abbreviated}"`

Examples:
- `"plan agent-first-arch"`
- `"spec agent-first-arch"`
- `"decompose agent-first-arch"`

### Agent `subagent_type` Parameter
All step agents use the default (`"general-purpose"`). Step agents need full tool access (Read, Write, Edit, Bash, Glob, Grep).

### Agent `mode` Parameter
All step agents use `mode: "default"` (D4 from architecture). Every step produces file artifacts requiring write permission.

### File Path Convention
All paths in agent prompts are project-relative. Never absolute, never `~`.

---

## 5. Retry/Feedback Protocol

When the lead re-spawns an agent after user feedback or validation failure (D5 from architecture):

### Re-spawn Prompt Structure

Insert a "Previous Attempt" section between Rules and Instructions:

```
## Previous Attempt
The previous attempt produced artifacts that need revision.

### Artifacts Written
{List of files the agent wrote}

### Feedback
{User feedback OR validation findings — verbatim}

### Specific Issues to Fix
1. {Concrete issue}
2. {Concrete issue}
```

The Instructions section changes to:

```
## Instructions
Revise the artifacts in place. Address each issue listed above.
Do NOT start from scratch — read the existing artifacts and modify them.
{Original step-specific instructions follow, for reference}
```

### Retry Limit

The existing harness convention applies: max 2 re-spawn attempts, then escalate to user. The lead uses judgment on how to present the situation — no prescribed escalation format.

---

## 6. Completion Signal Format

Every step agent returns a structured summary as its final message:

```
Step: {step}
Status: complete
Artifacts:
- {path}: {one-line description}
Summary: {2-3 sentence summary of what was produced}
Deferred: {items for futures.md, or "none"}
```

The lead uses this to:
1. Verify artifacts exist (file check)
2. Present summary to user
3. Trigger Phase A/B validation

---

## 7. Agent Failure Handling

If an agent fails (error, timeout, no output, malformed signal), the lead handles it case by case. The key principle: **never delete partial artifacts**. If the agent wrote something useful, the re-spawn prompt should point to existing files and ask the agent to complete or revise them. This aligns with draft-and-present (D1).

The harness's existing 2-retry limit applies. Beyond that, escalate to the user.

---

## 8. State.json Interaction Contract

### Fields Read by Dispatcher (spec 03)

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Task identification, path construction |
| `title` | string | Human-readable title for prompts |
| `tier` | number | Route to correct template |
| `current_step` | string | Select agent template |
| `base_commit` | string | Included in preamble for agents |
| `beads_epic_id` | string | Issue tracking context |
| `steps[].status` | string | Verify step is active before dispatching |

### Write Rules
- **Agents NEVER modify state.json.** Only the lead (work-deep.md dispatcher) writes to state.json.
- **Agents NEVER create beads issues.** Exception: decompose agent creates work item issues (spec 02 defines this explicitly).
- **Agents write to `.work/<name>/<step>/` only.** No writes outside the step's directory except `docs/feature/<name>.md` (plan and spec agents update this).

---

## 9. Regression Testing Strategy

Quality is measured through existing Phase A/B review gates. If agent-delegated steps produce lower-quality artifacts than inline execution, it will show up as increased BLOCKING verdicts and more user feedback rounds. The lead adjusts prompt templates based on observed patterns — no prescribed thresholds or formal comparison protocol.

The harness is a prompt-based system producing markdown artifacts. Automated testing is not applicable.

---

## Acceptance Criteria

- [ ] All component specs (01-06) reference this document for prompt structure, naming, and retry protocol
- [ ] No spec defines its own prompt section ordering or retry behavior
- [ ] State.json interaction contract is respected: agents never write to state.json
- [ ] Failure handling preserves partial artifacts on re-spawn
