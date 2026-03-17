# Futures — Context Document Lifecycle

## Next
- **freshness_class field**: Enum field on context documents (slow/medium/fast/frozen) enabling differentiated scan cadences. Currently all documents are scanned identically at archive time. Becomes meaningful when session-start or periodic scans are added.
- **last_reviewed field**: ISO date tracking when a document was last validated for accuracy (distinct from git modification history). Currently no component consumes this field. Becomes useful when scan frequency varies by document class.

## Quarter
- **Session-start staleness warnings**: At session start, optionally warn if context documents reference deprecated technologies. Lower priority than archive-time scanning. Could use the same tech manifest + deprecated table cross-reference.
