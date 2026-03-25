---
name: context-docs
description: "Manifest-driven system for injecting project documentation into agent context"
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Context Doc System

Declares, auto-detects, and injects project documentation into agent context so spawned agents start with relevant project knowledge. Projects declare managed docs in `harness.yaml` under `docs.managed`. When absent, the system infers useful doc types from the stack config.

## When This Activates

- `harness.yaml` has `docs.managed` entries (explicit manifest)
- `harness.yaml` has no `docs.managed` key and has stack config fields (auto-detection)

## Reading the Manifest

Parse `docs.managed` from `harness.yaml`. Each entry has:
- `type`: doc type identifier (lowercase, hyphenated, unique within the array)
- `path`: project-relative path to the markdown file (must end in `.md`)

```yaml
docs:
  managed:
    - type: endpoints
      path: docs/endpoints.md
    - type: components
      path: docs/components.md
```

**Validation rules:**
- Reject duplicate `type` values within `docs.managed`
- Reject paths not ending in `.md`
- Array may be empty (`[]`) — explicit opt-out of auto-detection
- Key may be absent — triggers auto-detection

## Auto-Detection

When `docs.managed` is absent from `harness.yaml` (key not present at all), suggest doc types based on stack config fields. When `docs.managed` is present (even as empty array `[]`), auto-detection does not run.

**Detection mapping:**

| Stack Field | Value | Suggested Doc Types |
|-------------|-------|-------------------|
| `language` | `go` | `packages` |
| `language` | `python` | `packages`, `models` |
| `language` | `typescript` | `packages` |
| `framework` | `nextjs` | `components`, `endpoints`, `env-setup` |
| `framework` | `django` | `endpoints`, `models`, `env-setup` |
| `framework` | `rails` | `endpoints`, `models`, `env-setup` |
| `framework` | `gin` | `endpoints` |
| `framework` | `echo` | `endpoints` |
| `framework` | `fiber` | `endpoints` |
| `framework` | `fastapi` | `endpoints`, `models` |
| `framework` | `flask` | `endpoints` |
| `framework` | `react` | `components` |
| `framework` | `vue` | `components` |
| `framework` | `svelte` | `components` |
| `framework` | `htmx` | `endpoints`, `components` |
| `database` | `postgres` | `schema`, `migrations` |
| `database` | `mysql` | `schema`, `migrations` |
| `database` | `sqlite` | `schema` |
| `database` | `mongodb` | `schema` |
| `frontend` | any non-null value | `components` |

**Default paths by type:**

| Doc Type | Default Path |
|----------|-------------|
| `endpoints` | `docs/endpoints.md` |
| `components` | `docs/components.md` |
| `models` | `docs/models.md` |
| `schema` | `docs/schema.md` |
| `migrations` | `docs/migrations.md` |
| `packages` | `docs/packages.md` |
| `env-setup` | `docs/env-setup.md` |

**Behavior:** Read stack fields, apply the mapping table, deduplicate results, and present suggestions to the user. The user adds their selections to `harness.yaml` or sets `docs.managed: []` to suppress future suggestions.

## Configuration Examples

### Go API project
```yaml
stack:
  language: go
  framework: gin
  database: postgres
docs:
  managed:
    - type: endpoints
      path: docs/endpoints.md
    - type: schema
      path: docs/schema.md
    - type: packages
      path: docs/packages.md
```

### Next.js fullstack project
```yaml
stack:
  language: typescript
  framework: nextjs
  database: postgres
  frontend: nextjs
docs:
  managed:
    - type: endpoints
      path: docs/endpoints.md
    - type: components
      path: docs/components.md
    - type: schema
      path: docs/schema.md
    - type: env-setup
      path: docs/env-setup.md
```

### Python ML project (explicit opt-out)
```yaml
stack:
  language: python
docs:
  managed: []  # No managed docs -- project uses Sphinx
```

## Agent Context Injection

When spawning agents (research, plan, or implement), include managed doc paths in the agent prompt using this format:

```markdown
## Managed Project Docs
The following project documents are maintained and should be consulted:
- endpoints: docs/endpoints.md
- components: docs/components.md
```

**Injection rules:**
- Research agents: receive all managed doc paths (full project context)
- Plan agents: receive all managed doc paths
- Implement agents: receive managed doc paths relevant to their stream's file scope (or all, if relevance cannot be determined)

## Doc Maintenance

When agents make code changes that may affect managed docs (e.g., adding new endpoints, modifying schema), they should flag the potentially affected doc type in their completion message. This is advisory only — agents do not auto-update managed docs.

If a managed doc path does not exist on disk, note it as missing but do not block work. The user is responsible for creating and maintaining managed doc files.

## Edge Cases

### Missing doc file on disk
When a managed doc path does not exist on disk:
- **Agent behavior**: Note it as missing in context injection ("endpoints: docs/endpoints.md [MISSING]")
- **Do not block**: Missing docs should not prevent work from proceeding
- **Do not auto-create**: The user is responsible for creating managed doc files

### Stale docs
When an agent makes code changes that affect a managed doc area (e.g., adding a new endpoint):
- Flag the doc type in the completion message: "Note: endpoints doc may need updating (new `/api/v2/users` endpoint added)"
- Do NOT auto-update the doc file
- Include the specific change that may affect the doc

### Conflicting auto-detection
When multiple stack fields suggest the same doc type:
- Deduplicate: If both `framework: nextjs` and `frontend: nextjs` suggest `components`, include it once
- Use the default path from the mapping table
- This is expected and not an error

### No harness.yaml
When `.claude/harness.yaml` does not exist:
- Skip context-docs entirely
- No error, no warning
- Commands proceed without managed doc context

## Agent Doc Impact Flagging

When implementation agents make changes that may affect managed docs, they should flag the impact in their completion output:

### What triggers a flag
- Adding/removing/renaming API endpoints → flag `endpoints`
- Adding/removing/renaming UI components → flag `components`
- Modifying database schema or migrations → flag `schema`, `migrations`
- Adding/removing packages or dependencies → flag `packages`
- Changing environment variables → flag `env-setup`

### Flag format in agent completion
```
Doc impact: [type] may need updating — [specific change description]
```

### What does NOT trigger a flag
- Internal refactoring that doesn't change public interfaces
- Test changes
- Documentation changes (already being updated)
- Configuration changes that don't affect the managed doc types
