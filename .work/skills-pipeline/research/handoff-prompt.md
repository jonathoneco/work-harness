# Research Handoff: W4 Skills Pipeline

**Task**: skills-pipeline | **Tier**: 3 | **Epic**: work-harness-alc
**Research completed**: 2026-03-24

## Research Summary

Four topics investigated across parallel agents. Full notes at `.work/skills-pipeline/research/`.

### Current State

- **42 skill+command files** (23 skills, 19 commands, ~6400 lines) — solid foundation
- **Extension model**: 4 layers (config → skill discovery → agent definition → runtime injection)
- **Only Go anti-pattern pack exists** — Python, TypeScript, Rust packs missing
- **harness.yaml** supports stack config, review routing, build commands, docs.managed
- **File-presence discovery** for language packs — zero-friction to add new ones

### Key Findings Per W4 Item

| Item | Finding | Complexity |
|------|---------|-----------|
| **workflow-meta** | Currently passive reference; needs active `/workflow-meta` command with pre-seeded context, sync validation, version bumping enforcement | Medium — new command, reuse existing patterns |
| **dev update dump** | No coverage. Artifacts exist (state.json, findings, checkpoints). Needs transformation skill + command | Medium — new command + skill |
| **proactive skill updating** | Needs: skill metadata (language, version), staleness detection hook, `/work-skill-update` command | High — new metadata schema + hook + command |
| **PR handling** | `/pr-prep` covers lint/build/PR creation. Gaps: CI monitoring, review setup, merge coordination, post-merge cleanup | Medium — extend existing command or new `/pr-review` |
| **skills for new tech stack** | File-presence discovery works now. Just add files at `references/<language>-anti-patterns.md` | Low — content creation only |
| **flush out harness skills** | `/ama` thin (63 lines), `codex-review.md` thin, `context-docs.md` lacks examples | Low — content enrichment |
| **dump command** | Extract decomposition logic from T3 decompose step as standalone `/work-dump` with multiple strategies | Medium — new command, reuse decompose logic |
| **deep Notion exploration** | Blocked: Notion OAuth pending. Prior failures: pagination incomplete, MCP permission blocking in subagents | Blocked — prerequisite OAuth setup |
| **anti-pattern packs** | Go pack exists (215 lines). Add Python, TypeScript, Rust following same pattern | Low — content creation |
| **agency-agents integration** | review_routing already supports arbitrary agents. Needs: curation docs per stack, harness-doctor validation, harness-init auto-seeding | Medium — docs + validation logic |
| **multi-language support** | `stack.language` is singular. Workaround: review_routing already routes by file pattern. Full support needs schema v2 with `languages: []` array | High — schema change + migration |

### Design Decisions for Planning

1. **Anti-pattern packs are pure content** — no code changes needed, file-presence discovery handles everything
2. **New commands follow established patterns** — YAML frontmatter, step-by-step, config injection, skill propagation
3. **Notion is blocked** — defer until OAuth configured; document as future item
4. **Multi-language is schema v2** — defer full support; document workaround (review_routing by pattern)
5. **Proactive skill updating is the most complex item** — new metadata, hook, command; consider deferring to later wave

### Recommended Prioritization for Plan Step

**Wave 1 (Low-complexity, high-value):**
- Anti-pattern packs (Python, TypeScript, Rust) — pure content
- Flush out harness skills — content enrichment
- Skills for new tech stack — content + docs

**Wave 2 (Medium-complexity, new capabilities):**
- Dev update dump — new command + skill
- Dump command — extract decompose logic
- Workflow-meta command — active entry point
- PR handling — extend or add command
- Agency-agents curation — docs + validation

**Wave 3 (High-complexity or blocked):**
- Proactive skill updating — metadata + hook + command
- Multi-language support — schema v2
- Notion exploration — blocked on OAuth

### Open Questions for Planning

1. Should anti-pattern packs match Go pack's structure exactly, or evolve the format?
2. For dev updates: markdown file output, or integrate with Slack/email?
3. Should `/work-dump` auto-create beads issues, or just output a plan?
4. Is multi-language support needed now, or can the review_routing workaround suffice?
5. Should skill metadata be added to all existing skills, or only new ones?
6. Config injection logic is duplicated across commands — consolidate in this wave?

### Dead Ends

None identified — all items have viable paths (Notion deferred, not dead).

### Research Note Paths

- `01-skills-commands-audit.md` — full inventory of 42 files with coverage analysis
- `02-harness-extension-points.md` — 4-layer extension model, multi-language design space
- `03-workflow-meta-lifecycle.md` — workflow-meta evolution, skill lifecycle, dump command design
- `04-external-integrations.md` — PR gaps, Notion blockers, dev update artifact mapping
