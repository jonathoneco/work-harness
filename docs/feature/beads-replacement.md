# Beads Replacement Research
**Status:** Complete | **Tier:** R | **Beads:** work-harness-pd1

## What
Evaluated alternatives to beads for low-level AI-agent issue tracking. Beads consumes 1,500-2,500 tokens of context per session while functioning as an audit log, not the task tracker it was designed to be — its coordination features (deps, ready queries) are never invoked.

## Key Findings
- Beads is an **audit log masquerading as a task tracker** — most issues are terminal state (created and closed within seconds during gates)
- **1,500-2,500 tokens** consumed per session before user says a word (global rules + skills + hooks + command instructions)
- **State duplication** is the root problem: task data lives in both state.json and beads
- Only 3 features provide real value: audit trail, finding triage, session enforcement — all replaceable
- "Designed" features (dependencies, ready queries) are documented in templates but **never called** in actual command logic
- 12 alternatives evaluated; top 3: custom JSONL tracker, GitHub Issues + gh, hybrid state.json extension

## Recommendation
Build a custom minimal tracker (`wt`) — ~200-400 line shell script wrapping `jq` on `.issues/issues.jsonl`. Implements 6 commands (create, list, show, update, close, search). Reduces context from ~2,000 tokens to ~100. Migration: mechanical swap of `bd X` → `wt X` across ~20 files.

## Deliverable
See `.work/beads-replacement/research/deliverable.md` for the full research report.
