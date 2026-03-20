# Futures: Agent-First Architecture

## Inter-Agent Communication Protocol
**Horizon**: quarter | **Domain**: harness-internals
Currently agents can't communicate with each other — all coordination is lead-mediated via files. A lightweight message-passing protocol (via SendMessage + named agents) could enable cooperative research agents that build on each other's findings.

## Model Selection Per Step Type
**Horizon**: someday | **Domain**: optimization
Only relevant if different models perform markedly differently at different tasks. User preference is max power (Opus) by default — cost is not a concern. Revisit only with evidence of meaningful quality differences per task type.

## Agent Teams Integration
**Horizon**: next | **Domain**: harness-internals
Native TeamCreate/TeamDelete tools are enabled and available. Could replace manual phase-gated parallelism for parallel step execution. Remaining concerns: no session resumption, API may change. Worth exploring in Phase 2/3 of W2 implementation.

## Findings JSONL Compaction
**Horizon**: quarter | **Domain**: harness-internals
Append-only findings.jsonl grows with full record duplicates on status updates. For large reviews (100+ findings), this creates bloat. A compaction mechanism could deduplicate while preserving audit trail.
