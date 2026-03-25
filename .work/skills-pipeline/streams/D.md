---
stream: D
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/code-quality.md
---

# Stream D — Pack Discovery Extension (Phase 2)

## Work Items
- **W-03** (work-harness-alc.3): Pack discovery extension

## Spec References
- Spec 00: Contract 2 (frontmatter schema)
- Spec 02: C04 (discovery extension — framework + frontend directives)

## What To Do

Modify `claude/skills/code-quality.md` to add framework and frontend pack discovery directives alongside the existing language pack directive.

### 1. Add Framework-Specific Anti-Patterns section

After the existing "Language-Specific Anti-Patterns" section, add:

```markdown
## Framework-Specific Anti-Patterns

Read `references/<framework>-anti-patterns.md` where `<framework>` is `stack.framework`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.framework` is absent,
or no matching file exists, skip this section.

Adding a new framework pack requires only creating one file at `references/<framework>-anti-patterns.md` — no changes to this file or any other file are needed.
```

### 2. Add Frontend-Specific Anti-Patterns section

After the framework section, add:

```markdown
## Frontend-Specific Anti-Patterns

Read `references/<frontend>-anti-patterns.md` where `<frontend>` is `stack.frontend`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.frontend` is absent,
or no matching file exists, skip this section.

Adding a new frontend pack requires only creating one file at `references/<frontend>-anti-patterns.md` — no changes to this file or any other file are needed.
```

### 3. Update existing Language directive wording

Update the skip clause to be consistent with new sections:
> If no `harness.yaml` exists, `stack.language` is absent or `other`, or no matching file exists, skip this section.

### 4. Bump meta.version to 2

The `meta` block (added by Stream A in Phase 1) should be updated:
```yaml
meta:
  stack: ["all"]
  version: 2          # bumped from 1 due to discovery extension
  last_reviewed: 2026-03-24
```

## Acceptance Criteria
- AC-C04-1.1: "Framework-Specific Anti-Patterns" section exists
- AC-C04-1.2: Directive references `stack.framework` from harness.yaml
- AC-C04-1.3: File pattern `references/<framework>-anti-patterns.md` specified
- AC-C04-1.4: Skip behavior documented (no harness.yaml, absent field, no matching file)
- AC-C04-2.1: "Frontend-Specific Anti-Patterns" section exists
- AC-C04-2.2: Directive references `stack.frontend`
- AC-C04-2.3: File pattern specified
- AC-C04-2.4: Skip behavior documented
- AC-C04-3.1: Language directive includes "no matching file exists" skip clause
- AC-C04-3.2: All three directives use consistent wording
- AC-C04-4.1: meta.version is 2

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta block to code-quality.md)
