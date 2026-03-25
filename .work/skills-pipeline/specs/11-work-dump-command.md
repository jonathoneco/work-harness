# Spec C10: `/work-dump` Command

**Component**: C10 — `/work-dump` command
**Phase**: 3 (New Commands)
**Status**: complete
**Dependencies**: Spec 00 (config injection, frontmatter schema)

---

## Overview and Scope

Creates the `/work-dump` command for decomposing a work description into well-scoped workflows (beads issues with dependencies and tags). The command outputs an advisory decomposition plan as structured markdown -- it does NOT auto-create issues (DD-3).

**What this does**:
- Creates `claude/commands/work-dump.md`
- Accepts a work description and produces a decomposition plan
- Identifies domain boundaries, suggests issue tags, dependency ordering
- Outputs markdown that the user reviews before manually creating issues

**What this does NOT do**:
- Auto-create beads issues (DD-3: advisory not autonomous)
- Replace the T3 decompose step (that is for active tasks; this is a standalone tool)
- Require an active `.work/` task to run

---

## Implementation Steps

### Step 1: Create Command File

Create `claude/commands/work-dump.md`:

```yaml
---
description: "Decompose a work description into well-scoped workflows with dependencies and tags"
user_invocable: true
skills: [work-harness]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

### Step 2: Define Command Structure

```markdown
# /work-dump $ARGUMENTS

Decompose a work description into well-scoped beads issues with dependencies and tags. Outputs a markdown plan for human review — does not auto-create issues.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Parse Input

`$ARGUMENTS` is a free-text description of the work to decompose. If empty, ask the user to describe the work.

Read project context to inform decomposition:
- `.claude/harness.yaml` for stack configuration (language, framework, database)
- `CLAUDE.md` for project conventions
- `bd list --status=open` for existing open issues (avoid duplicates)

## Step 2: Identify Domains

Analyze the work description and project stack to identify domain boundaries:

| Domain Signal | Tag | Examples |
|--------------|-----|---------|
| Database schema changes | `[DB]` | Migrations, new tables, index changes |
| API endpoints | `[API]` | New routes, request/response changes |
| Service/business logic | `[Service]` | New services, business rules |
| UI components | `[UX]` | New pages, component changes |
| Infrastructure | `[Infra]` | Deployment, CI/CD, config changes |
| Refactoring | `[Refactor]` | Code restructuring, interface changes |
| Bug fixes | `[Bug]` | Defect corrections |
| Integration | `[Integration]` | External service connections |
| Feature (cross-cutting) | `[Feature]` | End-to-end feature spanning multiple domains |

Apply the project's stack to filter relevant domains:
- No `database` in harness.yaml → skip `[DB]` domain
- No `frontend` in harness.yaml → skip `[UX]` domain
- Etc.

## Step 3: Decompose into Issues

For each identified domain boundary, create a suggested issue:

### Decomposition Heuristics

1. **One domain per issue**: Each issue should touch one domain (DB, API, Service, UX, etc.)
2. **Natural dependencies**: DB before API, API before UX, Service before Integration
3. **Independent when possible**: Prefer issues that can be worked in parallel
4. **Atomic scope**: Each issue should be completable in 1-2 sessions
5. **No cross-domain coupling**: If an issue needs changes in 2+ domains, split it

### Issue Template

For each suggested issue:
```markdown
### [Tag] Issue title

**Type**: task | bug | feature
**Priority**: P2 (default, user adjusts)
**Estimated tier**: T1 (fix) | T2 (feature)

**Description**:
Problem: [what this issue addresses]
Solution: [what to implement]
Files: [likely files to modify, based on project structure]

**Dependencies**: [issue numbers this depends on, or "none"]
```

## Step 4: Suggest Dependency Graph

Present the dependency ordering:

```markdown
## Dependency Graph

```
[DB] Schema changes
  └── [API] Endpoint implementation
       ├── [Service] Business logic
       │    └── [Integration] External service
       └── [UX] Frontend components
```

**Parallel tracks**:
- Track 1: [DB] → [API] → [Service]
- Track 2: [UX] (independent after API exists)
```

## Step 5: Output Plan

Present the full decomposition plan:

```markdown
# Work Decomposition: [title derived from description]

## Summary
[1-2 sentences summarizing the decomposition]
[N issues across M domains, K parallel tracks]

## Issues

[All issues from Step 3, numbered I-1, I-2, etc.]

## Dependency Graph

[From Step 4]

## Creation Commands

When ready, create issues with:
```bash
bd create --title="[DB] ..." --type=task --priority=2
bd create --title="[API] ..." --type=task --priority=2
# ... etc
bd dep add <api-id> <db-id>
# ... etc
```
```

## Step 6: User Review

Present the plan and wait for user feedback. The user may:
- Approve and create issues manually using the provided `bd create` commands
- Request changes to scope, dependencies, or issue count
- Dismiss the decomposition entirely

Do NOT create issues automatically.
```

**Acceptance Criteria**:
- AC-C10-2.1: Command file has the 6-step structure (parse, domains, decompose, dependencies, output, review)
- AC-C10-2.2: Domain identification uses project stack context from harness.yaml
- AC-C10-2.3: Issue template includes tag, type, priority, description, and dependencies
- AC-C10-2.4: Dependency graph visualization is included
- AC-C10-2.5: `bd create` commands are provided for copy-paste execution
- AC-C10-2.6: Command explicitly does NOT create issues (DD-3)
- AC-C10-2.7: Command includes config injection directive

---

## Interface Contracts

### Exposes

- **`/work-dump` command**: User-facing decomposition tool

### Consumes

- **Spec 00 Contract 3**: Config injection directive
- **`work-harness` skill**: Loaded for tier/step knowledge
- **`harness.yaml`**: Stack context for domain filtering
- **Beads**: `bd list --status=open` for duplicate detection

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/commands/work-dump.md` | Decomposition command (~120-150 lines) |

**Total**: 1 new file, 0 modified files

---

## Testing Strategy

1. **Basic decomposition**: Run `/work-dump "Build a user authentication system with OAuth and RBAC"` and verify the output includes multiple issues across domains with dependency ordering.

2. **Stack-aware filtering**: Run in a project with `stack.language: go` and no frontend. Verify `[UX]` issues are not suggested.

3. **Existing issue awareness**: Run in a project with open beads issues. Verify the decomposition notes potential overlaps with existing issues.

4. **No auto-creation**: Verify the command outputs `bd create` commands but does not execute them.

5. **Empty input**: Run `/work-dump` with no arguments. Verify it prompts the user for a description.
