# Futures: Context Document Lifecycle

## freshness_class field
**Horizon**: next | **Domain**: lifecycle
Enum field on context documents (slow/medium/fast/frozen) enabling differentiated scan cadences. Currently all documents are scanned identically at archive time. Becomes meaningful when session-start or periodic scans are added.

## last_reviewed field
**Horizon**: next | **Domain**: lifecycle
ISO date tracking when a document was last validated for accuracy (distinct from git modification history). Currently no component consumes this field. Becomes useful when scan frequency varies by document class.

## Session-start staleness warnings
**Horizon**: quarter | **Domain**: lifecycle
At session start, optionally warn if context documents reference deprecated technologies. Lower priority than archive-time scanning. Could use the same tech manifest + deprecated table cross-reference.
