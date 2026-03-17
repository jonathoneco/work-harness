# Research Index — Harness Modularization

| Topic | Summary | Status | File |
|-------|---------|--------|------|
| File inventory | 48 gaucho files, 51 dotfiles files classified as general/must-parameterize/project-specific | explored | `01-file-inventory.md` |
| Diff analysis | 42 identical, 3 diverged, 7 gaucho-only, 6 dotfiles-only | explored | `02-diff-analysis.md` |
| Parameterization audit | 50+ hard-coded refs across 8 categories (Go, HTMX, domain, infra, paths, build, tech-deps, settings) | explored | `03-parameterization-audit.md` |
| Settings merge | Hook merge strategy via jq, path resolution, idempotent install, uninstall tracking | explored | `04-settings-merge.md` |
| Evolution history | 4-phase timeline (fragmented → v2 → enforcement → modularization), 6 key decisions, 6 lessons | explored | `05-evolution-history.md` |
| Workflow-meta skill | Self-hosting mechanism for harness improvements, ships with harness | explored | `06-workflow-meta-skill.md` |
| Config schema | Proposed `.claude/harness.yaml` with project identity, stack, build commands, layer routing, features | explored | `07-config-schema-design.md` |
| Agency-agents overlap | 160+ agent repo, 10 overlapping agents. Don't ship review agents — use agency-agents. Harness owns workflow, agency owns expertise. | explored | `08-agency-agents-overlap.md` |
| Runtime selection | No native conditional activation. All global files always loaded. Selection at command/prompt level via harness.yaml. | explored | `09-runtime-selection.md` |
| harness-init design | Creates project grounding only (harness.yaml, beads-workflow template, settings.json). Everything else global. | explored | `10-harness-init-design.md` |
