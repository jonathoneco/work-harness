# Skills Frontmatter Verification

**Date**: 2026-03-18
**Result**: unsupported
**Implementation path**: B (prompt injection)

## Empirical Test

A test agent was created at `claude/agents/test-skills-verify.md` with `skills: [work-harness]` in YAML frontmatter and spawned with instructions to report on its context. Results:

1. **Content from `claude/skills/work-harness.md` present?** NO — the agent confirmed no skill content was automatically loaded
2. **Can describe skill contents without reading files?** NO — the agent could not describe work-harness skill contents (only saw references from CLAUDE.md/workflow rules, not the skill file itself)
3. **Were skill files auto-injected?** NO — "Claude Code does not appear to resolve the `skills:` frontmatter field by loading the referenced skill files into the agent's context"

The test agent file was deleted after verification.

**Conclusion**: Claude Code agent YAML frontmatter recognizes `name`, `description`, `allowedTools`, and `disallowedTools`, but ignores `skills:`. All agent spawn instructions must use Path B: explicit skill loading instructions in the prompt text with exact file paths.

## Implications

All agent spawn instructions in commands must use Path B: explicit skill loading instructions in the agent prompt text with exact file paths to skill files. This applies to both W-09 (step-level routing) and W-10 (stream-level routing).

## Rule Audit (C8 Step 5)

**Date**: 2026-03-18

All rule files in `claude/rules/` audited for cross-cutting vs step-specific classification:

| Rule File | Classification | Rationale |
|-----------|---------------|-----------|
| `workflow.md` | Cross-cutting | Session-level workflow detection, active task table, sync contract — applies to all steps and all tiers |
| `workflow-detect.md` | Cross-cutting | Session start detection, active task notification — applies regardless of current step |

**Result**: No migration needed. Both rules are genuinely cross-cutting — they apply at the session level, not within specific workflow steps. No step-specific guidance found in rules that should move to skills.
