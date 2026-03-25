---
stream: N
phase: 4
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/agency-curation.md
  - claude/commands/harness-doctor.md
  - claude/skills/work-harness.md
  - VERSION
  - claude/rules/workflow.md
---

# Stream N — Integration (Phase 4)

## Work Items
- **W-14** (work-harness-alc.14): Agency-agents curation
- **W-15** (work-harness-alc.15): install.sh + VERSION + workflow.md

## Spec References
- Spec 13: C12 (agency-curation skill, harness-doctor Check 8)
- Spec 14: C14 (install.sh verification, VERSION bump, workflow.md update)

## What To Do

### W-14: Agency-Agents Curation (spec 13)

#### 1. Create agency-curation skill

Create `claude/skills/work-harness/agency-curation.md`:
- Frontmatter: name, description, meta block
- Per-stack agent recommendations (5 profiles: Go Backend, Python Backend, TS/React Frontend, Fullstack, Rust)
- Each profile: Essential + Recommended tiers + review_routing YAML example
- Agent selection criteria (relevance, signal-to-noise, availability)
- Missing agent guidance

See spec 13, C12 Step 1 for full content.

#### 2. Add Check 8 to harness-doctor

Modify `claude/commands/harness-doctor.md` (already has meta from Phase 1):
- Add Check 8: Agency-Agents Recommendations
- Read stack config, cross-reference against agency-curation skill recommendations
- Report PASS (all essentials installed), WARN (missing essentials), or PASS (no profile match)
- Update summary from 7 to 8 checks

See spec 13, C12 Step 2 for full check definition.

#### 3. Update work-harness.md references

Add:
```markdown
- **agency-curation** — Per-stack agent recommendations for review routing (path: `claude/skills/work-harness/agency-curation.md`)
```

Note: `work-harness.md` was modified by Stream C (skill-lifecycle ref) and Stream M (dev-update ref). This adds a third reference.

### W-15: Install Verification + VERSION + Workflow.md (spec 14)

#### 4. Verify auto-discovery

Run `(cd claude && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)` and confirm all 12 new W4 files appear. See spec 14, C14 Step 1 for the full file list.

No install.sh code changes needed (auto-discovery).

#### 5. Bump VERSION

Read current VERSION, bump minor component (e.g., 0.5.0 -> 0.6.0).
Single line, no `v` prefix, no trailing newline.

#### 6. Update workflow.md command table

Add 4 new commands to `claude/rules/workflow.md`:

| Command | Purpose |
|---------|---------|
| `/workflow-meta` | Enter harness self-modification mode |
| `/dev-update` | Generate developer status update |
| `/work-dump` | Decompose work into scoped workflows |
| `/work-skill-update` | Scan skills for staleness |

#### 7. Verify no hook changes

Confirm `harness_hook_entries()` is unchanged.

#### 8. Run full install verification

`CLAUDE_DIR=/tmp/test-install ./install.sh --force` — verify all 12 new files installed.

## Acceptance Criteria

W-14 (spec 13):
- AC-C12-1.1: Curation skill exists at path
- AC-C12-1.2: At least 5 stack profiles
- AC-C12-1.3: Essential + Recommended tiers per profile
- AC-C12-1.4: review_routing YAML example per profile
- AC-C12-1.5: Agent selection criteria (3 criteria)
- AC-C12-2.1: Check 8 added to harness-doctor
- AC-C12-2.2: Check reads stack config
- AC-C12-2.3: Missing essentials reported as WARN
- AC-C12-2.4: Summary updated from 7 to 8 checks
- AC-C12-3.1: work-harness.md References includes agency-curation

W-15 (spec 14):
- AC-C14-1.1: All 12 new files in auto-discovery output
- AC-C14-1.2: No install.sh code changes needed
- AC-C14-2.1: VERSION bumped (minor)
- AC-C14-2.2: VERSION format correct (single line, no v prefix)
- AC-C14-3.1: workflow.md includes all 4 new commands
- AC-C14-3.2: Descriptions match frontmatter
- AC-C14-4.1: harness_hook_entries() unchanged
- AC-C14-5.1: Clean install succeeds
- AC-C14-5.2: All 12 new files present
- AC-C14-5.3: Manifest includes all 12 files

## Dependency Constraints
- Requires ALL Phase 1-3 streams complete
- This is the final integration stream — verifies everything works together
