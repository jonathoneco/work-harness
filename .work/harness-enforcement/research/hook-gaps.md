# Hook Enforcement Audit

## Deployed Hooks (3)

| Hook | Event | Blocks? | What It Checks |
|------|-------|---------|---------------|
| `review-gate.sh` | Stop | Yes (exit 2) | Critical anti-patterns in diff: `_, _=`, `*.Exec(`, `*.Render(` |
| `beads-check.sh` | Stop | Yes (exit 2) | Code files staged without an in_progress beads issue |
| `work-check.sh` | Stop | No (exit 0) | Warn if Tier 2-3 task has no checkpoints (incomplete logic) |

All 3 work correctly within their scope. No bugs found.

## Missing Hooks (from spec 09)

| Hook | Purpose | Impact of Missing |
|------|---------|-------------------|
| Step validation | Validate state.json mutations — current_step in steps array, only one active step, timestamps present | Agent can corrupt state machine |
| Artifact check | Verify handoff-prompt.md exists before step advancement | Agent can advance without handoff, breaking multi-session continuity |
| Finding triage check | Block archive with untriaged critical/important findings | Agent can archive without proper review |
| Beads integration check | Verify issue_id, epic_id, gate_id fields populated | State.json can be incomplete without detection |
| findings.jsonl protection | Block edits (only allow appends) to findings file | Agent could modify/delete findings |

## work-check.sh Logic Bug

Current: warns if ANY checkpoint exists (binary check).
Spec: should warn if `updated_at` in state.json is newer than latest checkpoint timestamp.
Impact: Stale checkpoints pass validation.

## Key Insight

Hooks are **deterministic and cannot be bypassed** by the LLM — they run in a shell subprocess. This makes them the most reliable enforcement mechanism. The gap is not capability, it's coverage.
