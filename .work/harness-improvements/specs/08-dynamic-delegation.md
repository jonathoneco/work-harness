# Spec 08: Dynamic Delegation (C8)

## Overview

Replace implicit, ad-hoc agent delegation in commands with explicit step-level routing tables that map each step to its agent type, required skills, and context sources. This moves phase-specific guidance from rules (always loaded for every step) into skills (loaded only when relevant), reducing context pollution and enabling agents to receive precisely the context they need for their assigned step.

## Scope

### In Scope

- Step-level routing tables embedded in command definitions (work-deep, work-feature, work-fix)
- Prerequisite verification: test whether Claude Code agent YAML frontmatter `skills:` field is natively supported
- Fallback mechanism: prompt-based skill injection if `skills:` frontmatter is unsupported
- Migration of step-specific guidance from rules to skills
- Agent spawn patterns that consume routing table entries

### Out of Scope

- Creating new skills (those are C7's deliverable; C8 consumes them)
- Stream doc agent routing (C9 concern -- C8 provides the per-step routing that C9 extends to per-stream routing)
- Review agent selection logic (stays in `/work-review` command, which already has its own routing via `review_routing` in harness.yaml)
- Changes to state.json schema
- Changes to hook behavior

## Implementation Steps

### Step 1: Verify `skills:` frontmatter support (BLOCKING GATE)

Before any other C8 work begins, verify whether Claude Code agent YAML frontmatter supports the `skills:` field natively.

**Verification procedure:**

1. Create a test agent file at `claude/agents/test-skills-verify.md`:
   ```markdown
   ---
   name: test-skills-verify
   description: "Temporary agent to test skills: frontmatter support"
   skills:
     - work-harness
   ---

   # Test Agent

   Report whether you have access to the work-harness skill content.
   List any skill-provided context you can see.
   ```

2. Spawn the test agent via `Agent(agent="test-skills-verify", prompt="Report what skills or skill content you have access to.")`.

3. Evaluate the agent's response:
   - **If the agent reports access to work-harness skill content**: `skills:` is natively supported. Record result, delete test agent, proceed with frontmatter-based skill injection (Path A).
   - **If the agent does NOT report skill content**: `skills:` is not supported. Record result, delete test agent, proceed with prompt-based skill injection (Path B).

4. Record the verification result in `.work/<task>/research/skills-frontmatter-verification.md`:
   ```markdown
   # Skills Frontmatter Verification

   **Date**: <date>
   **Result**: supported | unsupported
   **Evidence**: <what the test agent reported>
   **Implementation path**: A (frontmatter) | B (prompt injection)
   ```

5. Delete the test agent file after verification.

**AC-01**: Verification result is recorded with evidence before any subsequent C8 steps begin -- verified by `file-exists` (`.work/<task>/research/skills-frontmatter-verification.md`).

**AC-02**: Test agent file is deleted after verification -- verified by `file-exists` (absence of `claude/agents/test-skills-verify.md`).

### Step 2: Define step-level routing tables

Add explicit routing tables to each tier command. The routing table maps each step to its agent configuration.

**Routing table format (embedded in command markdown):**

```markdown
## Step Routing Table

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| research | Explore | work-harness, code-quality | beads issues, managed docs |
| plan | Plan | work-harness, code-quality | research handoff |
| spec | Plan | work-harness, code-quality | plan handoff, architecture.md |
| decompose | Plan | work-harness, code-quality | spec handoff, all specs |
| implement | general-purpose | work-harness, code-quality | stream doc, relevant specs, managed docs |
| review | (delegates to /work-review) | code-quality | diff since base_commit |
```

**Routing tables per command:**

**work-deep.md (Tier 3):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| research | Explore | work-harness, code-quality | beads issues, managed docs (C3) |
| plan | Plan | work-harness, code-quality | research handoff prompt |
| spec | Plan | work-harness, code-quality | plan handoff prompt, architecture.md |
| decompose | Plan | work-harness, code-quality | spec handoff prompt, all spec files |
| implement | general-purpose | work-harness, code-quality | stream doc, relevant specs, managed docs (C3) |
| review | (via /work-review) | code-quality | diff since base_commit |

**work-feature.md (Tier 2):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| plan | Explore + Plan | work-harness, code-quality | beads issues, managed docs (C3) |
| implement | general-purpose | work-harness, code-quality | plan document, managed docs (C3) |
| review | (via /work-review) | code-quality | diff since base_commit |

**work-fix.md (Tier 1):**

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| implement | general-purpose | work-harness, code-quality | beads issues |
| review | inline (no agent spawn) | code-quality | diff since base_commit |

**AC-03**: Each tier command contains a Step Routing Table section with columns: Step, Agent Type, Skills, Context Sources -- verified by `structural-review`.

**AC-04**: Every step in each command's `steps` array has a corresponding row in its routing table -- verified by `structural-review`.

### Step 3: Implement skill injection mechanism

Based on the Step 1 verification result, implement the appropriate skill injection mechanism.

**Path A -- Frontmatter-based (if `skills:` is supported):**

Agent spawns include `skills:` in the YAML frontmatter or spawn parameters:

```markdown
Agent(agent_type="Explore", skills=["work-harness", "code-quality"],
      prompt="<step-specific prompt>")
```

No additional prompt text needed for skill injection -- Claude Code handles it natively.

**Path B -- Prompt-based (if `skills:` is unsupported):**

Agent spawns include explicit skill loading instructions in the prompt text:

```markdown
Agent(agent_type="Explore", prompt="
Before starting work, read and follow these skills:
1. Read `claude/skills/work-harness/task-discovery.md` for task discovery conventions.
2. Read `claude/skills/work-harness/step-transition.md` for step transition protocol.
3. Read `claude/skills/code-quality/code-quality.md` for quality standards.

Then proceed with: <step-specific prompt>")
```

**Skill injection helper** (documented in `step-transition` skill or as a section in work-deep):

For Path B, define a reusable prompt fragment pattern per step that commands can reference:

```markdown
### Skill Injection Fragments

**research-agent-skills:**
> Read `claude/skills/work-harness/task-discovery.md` and
> `claude/skills/code-quality/code-quality.md`. Follow their conventions.

**plan-agent-skills:**
> Read `claude/skills/work-harness/step-transition.md` and
> `claude/skills/code-quality/code-quality.md`. Follow their conventions.

**implement-agent-skills:**
> Read `claude/skills/work-harness.md` (parent skill with all references) and
> `claude/skills/code-quality/code-quality.md`. Follow their conventions.
```

**AC-05**: The implemented injection mechanism matches the verification result from Step 1 (Path A if supported, Path B if not) -- verified by `structural-review`.

**AC-06**: For Path B, each skill injection fragment specifies exact file paths (not just skill names) -- verified by `structural-review`.

### Step 4: Update command step routers to use routing tables

Modify each command's step router to consult its routing table when spawning agents.

**Current pattern (implicit delegation in work-deep):**

```markdown
### When current_step = "research"
...
2. **Structured exploration via parallel subagents**: Launch Explore agents
   to investigate aspects of the task. Spawn with `skills: [work-harness, code-quality]`.
```

**New pattern (explicit routing-table-driven delegation):**

```markdown
### When current_step = "research"
...
2. **Agent delegation**: Consult the Step Routing Table for this step:
   - **Agent type**: Explore (read-only)
   - **Skills**: work-harness, code-quality (inject per Step 3 mechanism)
   - **Context**: Provide beads issue details and managed docs (if C3 configured)

   Launch parallel Explore agents for each research topic.
```

**Changes per command:**

| Command | Steps Updated | Nature of Change |
|---------|---------------|-----------------|
| `work-deep.md` | research, plan, spec, decompose, implement | Replace ad-hoc skill propagation with routing table reference |
| `work-feature.md` | plan, implement | Replace ad-hoc skill propagation with routing table reference |
| `work-fix.md` | implement | Replace ad-hoc skill propagation with routing table reference |

The review step in each command already delegates to `/work-review`, which has its own agent selection logic. No change needed for review steps.

**AC-07**: Each agent spawn instruction in updated commands references the routing table rather than hardcoding agent type and skills inline -- verified by `structural-review`.

**AC-08**: The review step in each command continues to delegate to `/work-review` (no routing table override for review) -- verified by `structural-review`.

### Step 5: Migrate phase-specific guidance from rules to skills

Identify guidance currently in rules files that is step-specific and should only load when relevant.

**Audit approach:**

1. List all rule files in `claude/rules/` that contain step-specific instructions
2. For each rule, determine which steps actually need the guidance
3. If guidance applies to all steps: leave in rules (appropriate for always-on context)
4. If guidance applies to specific steps: move to the relevant skill or create a new reference doc

**Candidates for migration:**

| Rule Content | Current Location | Target | Rationale |
|-------------|-----------------|--------|-----------|
| Architecture decision checks | `architecture-decisions.md` | Stays in rules | Applies to all steps (plan, spec, implement, review all check against it) |
| Code quality anti-patterns | `code-quality.md` (rule) | Stays in rules | Applies to all implementation and review contexts |
| Beads workflow | `beads-workflow.md` | Stays in rules | Applies to all steps (every step creates/closes issues) |

**Assessment**: Based on the current rule files, most guidance is genuinely cross-cutting (architecture decisions apply everywhere, code quality applies everywhere, beads workflow applies everywhere). The primary win of C8 is not moving rules to skills -- it is making the agent spawn pattern explicit and consistent so that agents receive exactly the skills and context they need, rather than relying on implicit propagation.

If the audit reveals step-specific guidance that is currently in rules, it will be migrated. If not, this step produces a documented "no migration needed" result with the audit evidence.

**AC-09**: An audit of rule files is documented (either in the commit message or in a research note) listing each rule file and whether it is cross-cutting or step-specific -- verified by `structural-review`.

**AC-10**: Any step-specific guidance found in rules is either migrated to a skill/reference doc or documented with rationale for keeping it in rules -- verified by `structural-review`.

### Step 6: Update Skill Propagation documentation

Update the Skill Propagation sections in each command to reflect the routing table rather than ad-hoc skill lists.

**Current pattern (at bottom of each command):**

```markdown
## Skill Propagation

- **Implementation agents**: `skills: [work-harness, code-quality]`
- **Review agents** (via `/work-review`): `skills: [code-quality]` only
- **Research agents**: `skills: [work-harness, code-quality]`
```

**New pattern:**

```markdown
## Skill Propagation

Agent skills are determined by the **Step Routing Table** above. Each step
specifies the exact skills to propagate. The routing table is the single
source of truth for agent configuration -- do not hardcode skill lists
in step instructions.

For the skill injection mechanism, see Step 3 of this command's implementation
(Path A: frontmatter, Path B: prompt injection).
```

**AC-11**: Each command's Skill Propagation section references the routing table as the source of truth, not a hardcoded list -- verified by `structural-review`.

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| Step Routing Tables | Step routers in work-deep, work-feature, work-fix | Per-step agent type, skills, and context source mapping |
| Skill injection mechanism | All agent spawn sites in commands | Frontmatter-based (Path A) or prompt-based (Path B) skill loading |
| Skills frontmatter verification result | C9 (Parallel Execution v2) | Whether `skills:` works natively, informing C9's stream-level routing |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| `task-discovery` skill | C7 | Referenced in routing tables for research and plan steps |
| `step-transition` skill | C7 | Referenced in routing tables for step advancement |
| `phase-review` skill | C7 | Referenced in routing tables for review phases |
| `code-quality` skill | Existing | Propagated to agents per routing table |
| `work-harness` skill | Existing (updated by C7) | Propagated to agents per routing table |
| `review_routing` config | harness.yaml | Review step delegates to `/work-review` which reads this config |
| Context Doc manifest | C3 (if implemented) | Routing table references "managed docs" as a context source |

### Dependency

C8 has a hard dependency on C7 (Skill Library). The routing tables reference skills that C7 creates. C8 implementation must not begin until C7 is complete.

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/agents/test-skills-verify.md` | Create then Delete | Temporary test agent for skills frontmatter verification |
| `.work/<task>/research/skills-frontmatter-verification.md` | Create | Verification result record |
| `claude/commands/work-deep.md` | Modify | Add Step Routing Table, update step routers to use it, update Skill Propagation section |
| `claude/commands/work-feature.md` | Modify | Add Step Routing Table, update step routers, update Skill Propagation |
| `claude/commands/work-fix.md` | Modify | Add Step Routing Table, update step routers, update Skill Propagation |

## Testing Strategy

### Structural Review

1. **Routing table completeness**: Every step in each command's `steps` array has a corresponding routing table row
2. **Skill path accuracy**: All skill paths referenced in routing tables or injection fragments resolve to files that exist (created by C7 or pre-existing)
3. **Consistency**: The same step across commands uses the same agent type and skills (e.g., `implement` always gets `work-harness` + `code-quality`)
4. **No orphaned propagation**: After updating Skill Propagation sections, no command has a hardcoded skill list that contradicts its routing table

### Manual Test

1. **Verification test**: Run the skills frontmatter verification (Step 1) and confirm the result is recorded
2. **Agent spawn test**: On the active harness-improvements task, trigger a step that spawns an agent (e.g., a Phase B review agent) and verify it receives the correct skills and context per the routing table
3. **Fallback test**: If Path B (prompt injection), verify that agents spawned with prompt-based skill loading actually read and follow the referenced skill files

### Integration

1. **End-to-end**: Run `/work-deep` on a test task, advance through at least one step transition, and verify that agents spawned during the step match the routing table specification
2. **Review delegation**: Run `/work-review` and verify it continues to use its own routing logic (not overridden by the step routing table)

## Deferred Questions Resolution

### Deferred Question 3: Does Claude Code agent YAML frontmatter support `skills:` natively?

**Question**: Does Claude Code agent YAML frontmatter support `skills:` natively?

**Resolution**: This must be VERIFIED during implementation, not assumed. Step 1 of this spec defines a concrete verification procedure with a test agent. The spec provides two complete implementation paths:

- **Path A (supported)**: Use native frontmatter `skills:` field. Simplest approach, no prompt overhead.
- **Path B (unsupported)**: Inject skill references via prompt text with explicit file paths. More verbose but functionally equivalent.

The verification result is recorded as a project artifact so future specs (C9) can reference it without re-testing. Neither path blocks implementation -- the spec is designed to proceed regardless of the verification outcome.

## Advisory Notes Resolution

### Advisory A1: `skills:` field verification as Phase 3 blocking gate

**Resolution**: Addressed by making Step 1 a BLOCKING GATE within this spec. Step 1 must complete before Steps 2-6 begin. The verification procedure is concrete (create test agent, spawn it, evaluate response, record result, clean up). The two implementation paths (A and B) ensure that the verification result determines the approach but never blocks progress entirely.

The gate is scoped to C8 implementation, not to all of Phase 3. C9 (Parallel Execution v2) can begin planning while C8 verification runs, since C9 depends on C8's routing tables (which are independent of the injection mechanism) rather than on the specific injection path chosen.
