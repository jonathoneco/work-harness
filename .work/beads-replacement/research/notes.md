# Beads Replacement Research — Consolidated Notes

## Research Coverage
- 01-integration-map.md: Complete mapping of all beads touchpoints in the harness
- 02-pain-points.md: Context costs, API complexity, daemon stability, value-vs-cost analysis
- 03-alternatives.md: 12 alternatives evaluated with comparison matrix
- 04-value-analysis.md: Feature-by-feature usage frequency and essentiality assessment

## Cross-Cutting Findings

### 1. Beads is an Audit Log, Not a Task Tracker
The most important finding: beads is being used as an **audit log** (documenting what happened) rather than a **task tracker** (coordinating what to do next). Most issues are terminal state — created and closed within seconds during gate transitions. The "designed" features (dependencies, ready queries) are never invoked in actual command logic.

### 2. The Context Cost is Astronomical
- 126-line global rule file loaded for ALL projects (~600-800 tokens)
- 20+ beads:* skill entries registered
- 10+ commands embed beads instructions
- Session start hook injects additional context
- **Estimated total**: 1,500-2,500 tokens consumed before user says a word

### 3. State Duplication is the Root Problem
Task data lives in BOTH `.work/*/state.json` AND `.beads/issues.jsonl`. Every create/update/close is duplicated. The harness already has a complete task lifecycle in state.json — beads is a parallel bookkeeping system.

### 4. The Daemon is Unnecessary Complexity
- SQLite + WAL + daemon + socket for what amounts to CRUD on 108 JSONL lines
- Auto-import/export cycles between SQLite and JSONL create sync friction
- Dolt/VC layer is configured but never used

### 5. Only 3 Features Provide Real Value
1. **Audit trail** (issue create/close with timestamps) — replaceable by state.json extension
2. **Finding triage** (beads_issue_id for deferred findings) — replaceable by deferred-findings.json
3. **Session enforcement** (beads-check.sh hook) — replaceable by active-task-dir check

### 6. Top 3 Replacement Candidates
1. **Custom JSONL Tracker** (~200-400 line shell script): Minimum context, zero deps, tailored to actual needs
2. **GitHub Issues + gh CLI**: Zero context cost (models know gh), but requires network
3. **Hybrid state.json + per-task JSONL**: Most radical simplification — T1/T2 need no separate tracker at all

### 7. Migration Surface
- 14+ command files with ~120 `bd` invocations
- 3 hooks (beads-check.sh, artifact-gate.sh, state-guard.sh)
- 1 global rule file (beads-workflow.md)
- state.json field mappings (issue_id, beads_epic_id, gate_id)
- 108 existing issues in .beads/issues.jsonl
