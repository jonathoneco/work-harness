---
stream: E
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/commands/ama.md
---

# Stream E — AMA Skill Enrichment (Phase 2)

## Work Items
- **W-04** (work-harness-alc.4): AMA skill enrichment

## Spec References
- Spec 06: C05 (AMA enrichment — answer strategies, depth calibration, uncertainty handling)

## What To Do

Enrich `claude/commands/ama.md` by adding three new sections after the existing "Response guidelines" section. The file already has its `meta` block from Stream A (Phase 1).

### 1. Add Answer Strategies by Question Type

Four templates: Architecture, "How does X work?", "Why was X done this way?", "What's the status of X?"

Each template has a numbered priority order for information sources referencing concrete sources (beads, git log, docs/feature, harness.yaml).

See spec 06, C05 Step 1 for exact content.

### 2. Add Depth Calibration

Table with 4 rows mapping question signals to depth levels (Quick, Medium, Deep) with approach descriptions.

See spec 06, C05 Step 2 for exact content.

### 3. Add Uncertainty Handling ("When You Don't Know")

3 numbered steps: say so explicitly, share what was found, suggest next steps.
Must include "Never fabricate an answer" statement.

See spec 06, C05 Step 3 for exact content.

### Rules
- Do NOT modify existing "How to answer questions" section or its 3 priority steps
- Add new sections AFTER existing content

## Acceptance Criteria
- AC-C05-1.1: Four answer strategy templates present
- AC-C05-1.2: Each template has numbered priority order
- AC-C05-1.3: Templates reference concrete sources
- AC-C05-2.1: Depth calibration table with 4 rows
- AC-C05-2.2: Each depth level has approach description
- AC-C05-3.1: Uncertainty handling with 3 numbered steps
- AC-C05-3.2: "Never fabricate an answer" stated explicitly

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta block to ama.md)
