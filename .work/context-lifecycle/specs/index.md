# Spec Index: Context Document Lifecycle Management

| Spec | Title | Status | Dependencies |
|------|-------|--------|-------------|
| 00 | Cross-cutting contracts | complete | — |
| 01 | Project-level tech manifest (C1) | complete | 00 |
| 02 | Self-re-invocation at step gates (C2) | complete | 00 |
| 03 | PostCompact hook (C3) | complete | 00 |
| 04 | Archive-time housekeeping (C4) | complete | 00, 01 |
| 05 | Gate approval re-confirmation (C5) | complete | 00 |

## Dependency Ordering

```
Spec 00 (cross-cutting contracts)
├── Spec 01 (C1: tech manifest)        ─┐
├── Spec 02 (C2: self-re-invocation)    │ Phase 1 (parallel)
├── Spec 03 (C3: PostCompact hook)      │
├── Spec 05 (C5: gate approval fix)    ─┘
└── Spec 04 (C4: archive housekeeping) ── Phase 2 (depends on C1)
```

## Implementation Phases

- **Phase 1**: Specs 01, 02, 03, 05 — all independent, can be implemented in parallel
- **Phase 2**: Spec 04 — depends on spec 01 (needs tech manifest to exist)
- **Critical path**: Spec 01 → Spec 04

## Deferred Questions Resolved

| # | Question | Resolution | Resolved In |
|---|----------|------------|-------------|
| 1 | Tech manifest identifier format | Lowercase kebab-case, case-insensitive match after normalization | Spec 00 |
| 2 | Self-re-invocation wording | Plain language, no aggressive framing | Spec 02 |
| 3 | PostCompact hook details | POSIX sh, always exit 0, one line per active task | Spec 03 |
| 4 | Staleness report format | Markdown table with 3 sections + beads issues | Spec 00 |
| 5 | Skill location resolution | Category-based path resolution with project-overrides-dotfiles | Spec 00 |
| 6 | Cleanup issue sequencing | Not Phase 0 — independent, can resolve before or during implementation | Spec 04 (notes) |
| 7 | Manifest bootstrapping | Manual creation, archive scan catches gaps going forward | Spec 01 |

## Cross-Repo File Impact

| Repo | Files Modified | Specs |
|------|---------------|-------|
| gaucho (project) | `.claude/tech-deps.yml` (new), `.claude/settings.json`, `scripts/hooks/post-compact.sh` (new) | 01, 03 |
| dotfiles | `~/.claude/commands/work-deep.md`, `work-feature.md`, `work-fix.md`, `work-archive.md` | 02, 04, 05 |
