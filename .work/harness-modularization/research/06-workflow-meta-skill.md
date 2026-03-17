# Workflow-Meta Skill

## Location
`/home/jonco/src/dotfiles/home/.claude/skills/workflow-meta/SKILL.md`

## Purpose
Single-session harness improvements. For targeted changes to commands, skills, agents, or hooks. Escalates to `/work-deep` for multi-session overhauls.

## Process
1. Load harness inventory (scan all `.claude/` directories)
2. Validate harness health (frontmatter, state integrity, hook executability, beads consistency)
3. Search prior art (beads issues, dead-ends)
4. Break down improvement into beads issues
5. Implement sequentially via `bd ready`
6. Verify (read back files, shellcheck hooks)

## Key Patterns
- **Path portability**: Always project-relative paths, never absolute
- **Self-referential**: Can modify itself (acknowledges recursion)
- **Templates enforced**: Commands need `description` + `user_invocable: true` frontmatter; skills need `name` + `description`; agents need structured headers; hooks need `set -euo pipefail`

## Relevance to Extraction
This skill should ship with the harness — it's the self-hosting mechanism. The harness repo uses its own workflow to improve itself. The skill is already general-purpose with no tech-specific references.
