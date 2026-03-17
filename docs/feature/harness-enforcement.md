# Harden Work Harness Enforcement

**Status:** active
**Tier:** 3
**Dates:** 2026-03-14 — ongoing
**Beads:** rag-rne9

## What

Mechanical guardrails for the work harness that prevent LLM discipline collapse during multi-session tasks. Hooks validate post-conditions (state integrity, artifact existence, review execution) that cannot be bypassed by the agent, replacing reliance on prompt-based compliance.

## Why

Stress testing during the dev-env-silo task revealed progressive discipline collapse: the agent abandoned step gates, skipped artifact creation, and marked review "completed" without running it. Prompt-based enforcement degrades under context pressure.

## Key Decisions

- **Hooks enforce, commands orchestrate**: Hooks are deterministic guardrails; commands handle steering and auto-advancement between steps
- **Validate post-conditions, not intentions**: Check "did the file get created?" not "did the LLM plan to create it?"
- **Blocking vs warning severity**: Exit 2 (blocking) for state corruption, stderr warnings for missing artifacts

## Components

- **State Mutation Guard** (`state-guard.sh`): PostToolUse hook validating state.json integrity after writes
- **Artifact Gate** (`artifact-gate.sh`): Stop hook ensuring handoff prompts and spec files exist for completed steps
- **Review Gate**: Pre-archive validation that review was actually executed with findings
- **Auto-advance Flow**: Commands self-drive between steps so users interact via natural language

## Specs

Detailed specs at `.work/harness-enforcement/specs/`.
