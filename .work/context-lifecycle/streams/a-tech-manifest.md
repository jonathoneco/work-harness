# Stream A: Tech Manifest (C1)

**Phase**: 1 (parallel) | **Work Items**: W-01 (rag-kcqx7) | **Spec**: 01

## Context

Create `.claude/tech-deps.yml` — a project-level YAML manifest mapping context documents to their technology dependencies. This enables archive-time staleness scanning without modifying portable dotfiles skills.

## Work Item: W-01 — Create tech-deps.yml

**Beads ID**: rag-kcqx7

### Steps

1. **Scan context documents**: Identify all skills, rules, and commands with technology-specific content
   - Skills: `ls ~/.claude/skills/*/SKILL.md`
   - Rules: `ls .claude/rules/*.md`
   - Commands: `ls .claude/commands/*.md` and `ls ~/.claude/commands/*.md`

2. **Identify technology dependencies**: For each document, read content and note technology references. Cross-reference against the deprecated approaches table in `.claude/rules/beads-workflow.md`.

3. **Create the manifest file**: Write `.claude/tech-deps.yml` following the schema in spec 00:
   ```yaml
   skills:
     <skill-name>:
       deps: [<tech-id>, ...]
       references:
         - <filename>.md
   rules:
     <rule-name>:
       deps: [<tech-id>, ...]
   commands:
     <command-name>:
       deps: [<tech-id>, ...]
   ```

4. **Validate**: Confirm YAML parses, all names resolve to files, identifiers are lowercase kebab-case.

### Acceptance Criteria
- File exists at `.claude/tech-deps.yml`
- Follows schema from spec 00 (cross-cutting contracts)
- All document names resolve to existing files
- Technology identifiers are lowercase kebab-case
- `references` field populated for skills with sub-files
- Header comment explains purpose

### Files to Create
- `.claude/tech-deps.yml` (new)

### Spec Reference
- `.work/context-lifecycle/specs/01-tech-manifest.md`
- `.work/context-lifecycle/specs/00-cross-cutting-contracts.md` (schema, identifier format)

### Dependencies
- None (foundational — other streams don't depend on this for Phase 1)
- Stream D (Phase 2) depends on this stream completing

### Claim and Close
```bash
bd update rag-kcqx7 --status=in_progress
# ... implement ...
bd close rag-kcqx7
```
