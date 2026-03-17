# Go Anti-Patterns

These rules exist because agent-generated code repeatedly introduced these anti-patterns, causing silent production bugs. Every rule has a concrete WRONG/RIGHT example.

## Fail closed, never fail open

Missing configuration, secrets, or dependencies = **hard error**, not a graceful fallback. Never generate unsigned tokens, skip auth checks, or degrade security because a secret is not set. If a required value is absent, return an error or refuse to start.

```go
// BAD — silent security degradation
if hmacSecret == "" {
    return makeUnsignedToken(...)
}

// GOOD — fail closed
if hmacSecret == "" {
    return "", fmt.Errorf("WEBHOOK_HMAC_SECRET is required")
}
```

## Never swallow errors

Every error return must be checked. No `_, _ =` on DB calls, no `_ =` on template renders or JSON encodes. If an operation can fail, handle the failure — log it, return it, or both.

```go
// BAD — caller never knows the DB write failed
_, _ = s.pool.Exec(ctx, "UPDATE ...", args...)

// BAD — client gets empty/broken response silently
_ = json.NewEncoder(w).Encode(data)

// GOOD
if _, err := s.pool.Exec(ctx, "UPDATE ...", args...); err != nil {
    return fmt.Errorf("update record: %w", err)
}
```

## Never fabricate data

When an operation fails or a dependency is nil, **do not** return synthetic defaults (fake UUIDs, empty JSON, zero values with nil error). Fabricated data looks valid to callers and hides wiring/infrastructure failures.

```go
// BAD — masks that the DB pool is nil
if s.pool == nil {
    return uuid.New(), 3, 0.40, nil
}

// GOOD
if s.pool == nil {
    return uuid.Nil, 0, 0, fmt.Errorf("service: database pool is nil")
}
```

## Always handle both branches

If you write `if err == nil { ... }`, you **must** write an else that handles the error. Conditional-only-on-success leaves the failure path with stale/zero data and no indication anything went wrong.

```go
// BAD — page renders with Count=0 on error, no indication of failure
if err == nil {
    data.Count = len(items)
}

// GOOD
items, err := s.ListItems(ctx)
if err != nil {
    slog.Error("list items", "error", err)
    http.Error(w, "Internal Server Error", 500)
    return
}
data.Count = len(items)
```

## Constructor injection only

All dependencies must be available at construction time via `NewXxxService(...)`. Do not use setter injection (`SetXxxDependency`) or post-construction callbacks. If this creates a circular dependency, **restructure the initialization order** — do not paper over it with setters and nil-check guards.

```go
// BAD — setter injection with nil-check guards everywhere
type Service struct {
    pool   *pgxpool.Pool
    sender Sender // nil until SetSender called
}

func (s *Service) SetSender(sender Sender) {
    s.sender = sender
}

func (s *Service) Send(ctx context.Context, msg Message) error {
    if s.sender == nil {
        return fmt.Errorf("sender not configured")
    }
    return s.sender.Send(ctx, msg)
}

// GOOD — constructor injection, all deps required at creation
func NewService(pool *pgxpool.Pool, sender Sender) *Service {
    return &Service{pool: pool, sender: sender}
}
```

## Return complete results

Functions that claim to analyze multiple inputs must actually analyze all of them. Do not short-circuit on the first match when the contract implies comprehensive analysis.

```go
// BAD — only compares first pair, ignores remaining sources
func compareCrossSources(sources []Source) ([]Discrepancy, error) {
    if len(sources) < 2 {
        return nil, nil
    }
    return compare(sources[0], sources[1])
}

// GOOD — compares all pairs
func compareCrossSources(sources []Source) ([]Discrepancy, error) {
    var results []Discrepancy
    for i := 0; i < len(sources); i++ {
        for j := i + 1; j < len(sources); j++ {
            discs, err := compare(sources[i], sources[j])
            if err != nil {
                return nil, fmt.Errorf("compare %s vs %s: %w", sources[i].Name, sources[j].Name, err)
            }
            results = append(results, discs...)
        }
    }
    return results, nil
}
```

## No divergent copies of the same interface

Go idiom is to define small interfaces at the consumer site — that is fine. A handler that only needs `LogAuditEvent()` should define a narrow interface locally. But do not create multiple interfaces with the **same name and similar method sets** that diverge over time. If `AuditLogger` exists in three packages with three different method signatures, that is a bug, not consumer-site narrowing.

```go
// BAD — three packages, same name, divergent signatures
// package handlers
type AuditLogger interface {
    LogAuditEvent(ctx context.Context, event AuditEvent) error
}

// package services
type AuditLogger interface {
    LogAuditEvent(ctx context.Context, action string, details map[string]any) error
    ListAuditEvents(ctx context.Context, entityID uuid.UUID) ([]AuditEvent, error)
}

// package middleware
type AuditLogger interface {
    Log(ctx context.Context, msg string)
}

// GOOD — one canonical interface, consumer-site narrowing with different names
// package audit (canonical)
type Logger interface {
    LogAuditEvent(ctx context.Context, event AuditEvent) error
    ListAuditEvents(ctx context.Context, entityID uuid.UUID) ([]AuditEvent, error)
}

// package handlers (narrow consumer interface — different name)
type AuditEventLogger interface {
    LogAuditEvent(ctx context.Context, event AuditEvent) error
}
```

## No shims, scaffolding, or backward compatibility

**This is the single most common agent anti-pattern.** Agents repeatedly add "just in case" flexibility, migration fallbacks, and compatibility layers that silently accumulate as technical debt.

**YOU MUST NOT add any of the following without explicit user request:**

- **Config knobs for unused targets** — If you deploy to one provider, do not add config overrides for other providers. Build for what you use.
- **Migration/data fallbacks** — Do not add `COALESCE` or `CASE WHEN column IS NULL` to handle rows that "might predate" a migration. If old data needs backfilling, write a migration to backfill it.
- **Cleanup code for removed features** — If a feature was replaced, do not add code to clean up old state "in case it exists." The old system is gone. Remove references, do not maintain them.
- **Setter injection to avoid refactoring** — If a dependency is not available at construction time, restructure the initialization order. Do not add `SetXxxDependency()` methods with nil-check guards.
- **"Future-proofing" abstractions** — Do not add interfaces, factories, or strategy patterns for hypothetical future requirements. Build what is needed now. If requirements change, refactor then.
- **Compatibility wrappers for deprecated approaches** — If something is deprecated, do not write code that accommodates it.

**The test:** If you are about to add code that handles a scenario the system does not currently face, **stop**. Either the scenario is real and needs a migration/cleanup, or it is hypothetical and the code should not exist.

## Missing error wrapping

Always wrap errors with context when returning them up the call stack. Bare `return err` loses context about where the error originated.

```go
// BAD — no context on where the error came from
func (s *Service) GetItem(ctx context.Context, id uuid.UUID) (*Item, error) {
    item, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    return item, nil
}

// GOOD — wrapped with context
func (s *Service) GetItem(ctx context.Context, id uuid.UUID) (*Item, error) {
    item, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("get item %s: %w", id, err)
    }
    return item, nil
}
```

## Bare fmt.Println instead of structured logging

Use the project's structured logging library (typically `slog`) instead of `fmt.Println` or `log.Println`. Structured logging enables filtering, correlation, and production observability.

```go
// BAD — unstructured, not filterable, lost in production
fmt.Println("processing document", docID)

// GOOD — structured, includes context fields
slog.Info("processing document", "document_id", docID, "stage", "extraction")
```
