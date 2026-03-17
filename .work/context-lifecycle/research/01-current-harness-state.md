# Current Harness State: Context Document Management

## Summary

The work harness has no automated context lifecycle management. All context freshness depends on manual discipline or the compaction protocol (which itself is a prompt instruction subject to drift).

## Key Findings

### Self-Re-Invocation: None

Work commands never use `Skill()` to re-invoke themselves at step transitions. The flow is:

1. Step completes → Phase A/B review runs automatically
2. Present summary → STOP → wait for user acknowledgment
3. On approval → create gate issue → update state.json
4. Tell user: "Run `/compact` then `/work-deep` to start next step"
5. Stop.

If user says "proceed" instead of "/work-deep", the agent continues inline with stale context. The fallback ("re-read rule files") is itself a prompt instruction — ironic because it's subject to the same instruction drift it's trying to prevent.

### Compaction Protocol: Prompt-Level Only

- **Tier 3**: Mandatory at every step transition (5 points in work-deep.md)
- **Tier 2**: Recommended, not mandatory (2 points in work-feature.md)
- **Tier 1**: No compaction protocol
- **Fallback**: "re-read handoff prompt + specific rule files" — varies by transition

The fallback varies per transition:

- research → plan: code-quality.md, architecture-decisions.md
- plan → spec: same
- spec → decompose: code-quality.md, beads-workflow.md
- decompose → implement: code-quality.md, beads-workflow.md, architecture-decisions.md
- implement → review: code-quality.md + latest checkpoint

### Skill Loading: Static, Never Refreshed

- Skills use file-pattern activation (e.g., code-quality activates when editing .go files)
- Loaded once at session start based on file patterns
- Propagated to subagents via explicit `skills: [name]` in spawn directives
- **Never re-read mid-session** — no refresh mechanism exists
- Only serena-activate has a manual re-initialization command

### Archive Housekeeping: File-Focused, Not Knowledge-Focused

Archive process includes:

- Archive summary generation
- Futures promotion to `docs/futures/`
- Findings summary
- Beads closure + git commit

Archive does NOT include:

- Scanning skills/rules for stale references
- Checking if new patterns should propagate to skills
- Updating deprecated approaches table
- Validating skill frontmatter

### Skill Frontmatter: Minimal

All skills use only `name` + `description`. No fields for:

- `version` or `last_validated` timestamps
- `tech_deps` (what technologies the skill covers)
- `depends_on` (skill dependencies)
- Deprecation markers

### Deprecated Approaches Table: Manual Only

17-entry table in `.claude/rules/beads-workflow.md`. Referenced in:

- Research phase instructions (via Explore agent prompts)
- bd search skip patterns

Not integrated into:

- Any automated hook or script
- Archive-time validation
- Session start checks
- Skill/rule staleness detection

## Implications for Design

1. **Self-re-invocation** is the highest-impact mechanism — it directly addresses the "proceed vs /work-deep" behavioral gap
2. **Archive housekeeping** fills a complete void — currently zero knowledge cleanup at archive time
3. **Frontmatter tech_deps** enables automated cross-referencing with deprecated table
4. **Deprecated table diffing** can be layered on top of frontmatter once tech_deps exist
