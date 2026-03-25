---
description: "Decompose a work description into well-scoped workflows with dependencies and tags"
user_invocable: true
skills: [work-harness]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-25
---

# /work-dump $ARGUMENTS

Decompose a work description into well-scoped beans issues with dependencies and tags. Outputs a markdown plan for human review — does not auto-create issues.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Parse Input

`$ARGUMENTS` is a free-text description of the work to decompose. If empty, ask the user to describe the work.

Read project context to inform decomposition:
- `.claude/harness.yaml` for stack configuration (language, framework, database)
- `CLAUDE.md` for project conventions
- `bn list --status=open` for existing open issues (avoid duplicates)

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
- No `database` in harness.yaml -> skip `[DB]` domain
- No `frontend` in harness.yaml -> skip `[UX]` domain
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

~~~markdown
## Dependency Graph

```
[DB] Schema changes
  +-- [API] Endpoint implementation
       +-- [Service] Business logic
       |    +-- [Integration] External service
       +-- [UX] Frontend components
```

**Parallel tracks**:
- Track 1: [DB] -> [API] -> [Service]
- Track 2: [UX] (independent after API exists)
~~~

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
bn create --title="[DB] ..." --type=task --priority=2
bn create --title="[API] ..." --type=task --priority=2
# ... etc
bn dep add <api-id> <db-id>
# ... etc
```
```

## Step 6: User Review

Present the plan and wait for user feedback. The user may:
- Approve and create issues manually using the provided `bn create` commands
- Request changes to scope, dependencies, or issue count
- Dismiss the decomposition entirely

Do NOT create issues automatically.
