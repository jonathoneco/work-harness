# Go Anti-Patterns

These rules exist because agent-generated code repeatedly introduced these anti-patterns, causing silent production bugs. Every rule has a concrete BAD/GOOD example.

## Security: Fail closed, never fail open
**Severity**: error

Missing configuration, secrets, or dependencies must cause a hard error, not a graceful fallback. Never generate unsigned tokens, skip auth checks, or degrade security because a secret is not set.

**Why**: Silent security degradation means the system appears to work while running without protection. Production incidents from this class of bug are invisible until exploited.

```go
// BAD
if hmacSecret == "" {
    // silent security degradation
    return makeUnsignedToken(...)
}
```

```go
// GOOD
if hmacSecret == "" {
    return "", fmt.Errorf("WEBHOOK_HMAC_SECRET is required")
}
```

## Anti-pattern: Never swallow errors
**Severity**: error

Every error return must be checked. No `_, _ =` on DB calls, no `_ =` on template renders or JSON encodes. If an operation can fail, handle the failure -- log it, return it, or both.

**Why**: Swallowed errors mean the caller never knows a write failed or a response was broken. Data silently goes missing and users see empty results with no indication of failure.

```go
// BAD
// caller never knows the DB write failed
_, _ = s.pool.Exec(ctx, "UPDATE ...", args...)

// client gets empty/broken response silently
_ = json.NewEncoder(w).Encode(data)
```

```go
// GOOD
if _, err := s.pool.Exec(ctx, "UPDATE ...", args...); err != nil {
    return fmt.Errorf("update record: %w", err)
}
```

## Anti-pattern: Never fabricate data
**Severity**: error

When an operation fails or a dependency is nil, do not return synthetic defaults (fake UUIDs, empty JSON, zero values with nil error). Fabricated data looks valid to callers and hides wiring/infrastructure failures.

**Why**: Fabricated data passes validation and propagates through the system as if real. By the time the bug surfaces, the root cause (a nil dependency or failed call) is far from the symptom.

```go
// BAD
// masks that the DB pool is nil
if s.pool == nil {
    return uuid.New(), 3, 0.40, nil
}
```

```go
// GOOD
if s.pool == nil {
    return uuid.Nil, 0, 0, fmt.Errorf("service: database pool is nil")
}
```

## Anti-pattern: Always handle both branches
**Severity**: error

If you write `if err == nil { ... }`, you must write an else that handles the error. Conditional-only-on-success leaves the failure path with stale/zero data and no indication anything went wrong.

**Why**: The success-only conditional pattern silently drops errors. Page renders with zero counts, API responses with empty fields -- all because the error path falls through with default values.

```go
// BAD
// page renders with Count=0 on error, no indication of failure
if err == nil {
    data.Count = len(items)
}
```

```go
// GOOD
items, err := s.ListItems(ctx)
if err != nil {
    slog.Error("list items", "error", err)
    http.Error(w, "Internal Server Error", 500)
    return
}
data.Count = len(items)
```

## Best Practice: Constructor injection only
**Severity**: warn

All dependencies must be available at construction time via `NewXxxService(...)`. Do not use setter injection (`SetXxxDependency`) or post-construction callbacks. If this creates a circular dependency, restructure the initialization order.

**Why**: Setter injection requires nil-check guards on every method call and makes it possible to use a half-initialized service. Constructor injection guarantees a fully wired service from the moment it exists.

```go
// BAD
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
```

```go
// GOOD
func NewService(pool *pgxpool.Pool, sender Sender) *Service {
    return &Service{pool: pool, sender: sender}
}
```

## Anti-pattern: Return complete results
**Severity**: warn

Functions that claim to analyze multiple inputs must actually analyze all of them. Do not short-circuit on the first match when the contract implies comprehensive analysis.

**Why**: Callers rely on comprehensive results for correctness. A comparison function that silently ignores most of its inputs produces incomplete data that passes downstream validation but misses real discrepancies.

```go
// BAD
// only compares first pair, ignores remaining sources
func compareCrossSources(sources []Source) ([]Discrepancy, error) {
    if len(sources) < 2 {
        return nil, nil
    }
    return compare(sources[0], sources[1])
}
```

```go
// GOOD
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

## Anti-pattern: No divergent copies of the same interface
**Severity**: warn

Consumer-site interface narrowing (small interfaces at the call site) is fine. But do not create multiple interfaces with the same name and similar method sets that diverge over time. If the same interface name exists in three packages with three different signatures, that is a bug.

**Why**: Divergent copies of the same interface make it impossible to tell which is canonical. Each copy evolves independently, methods drift out of sync, and satisfying one interface breaks another.

```go
// BAD
// three packages, same name, divergent signatures
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
```

```go
// GOOD
// one canonical interface, consumer-site narrowing with different names
// package audit (canonical)
type Logger interface {
    LogAuditEvent(ctx context.Context, event AuditEvent) error
    ListAuditEvents(ctx context.Context, entityID uuid.UUID) ([]AuditEvent, error)
}

// package handlers (narrow consumer interface -- different name)
type AuditEventLogger interface {
    LogAuditEvent(ctx context.Context, event AuditEvent) error
}
```

## Anti-pattern: No shims, scaffolding, or backward compatibility
**Severity**: warn

Do not add migration fallbacks, future-proofing abstractions, or compatibility layers unless explicitly requested. Build for what is needed now. If requirements change, refactor then.

**Why**: This is the single most common agent anti-pattern. Agents add "just in case" flexibility that silently accumulates as technical debt. Config knobs for unused targets, query-time data fallbacks, cleanup code for removed features, and compatibility wrappers all add complexity without solving a real problem.

```go
// BAD
// future-proofing: provider abstraction for a single implementation
type StorageProvider interface {
    Upload(ctx context.Context, key string, data []byte) error
}

type S3Provider struct{ client *s3.Client }
type GCSProvider struct{ client *storage.Client }  // not used anywhere
type AzureProvider struct{ client *azblob.Client } // not used anywhere

func NewStorage(provider string) StorageProvider {
    switch provider {
    case "gcs":   return &GCSProvider{}
    case "azure": return &AzureProvider{}
    default:      return &S3Provider{}
    }
}
```

```go
// GOOD
// build for what you use
type Storage struct {
    client *s3.Client
}

func NewStorage(client *s3.Client) *Storage {
    return &Storage{client: client}
}

func (s *Storage) Upload(ctx context.Context, key string, data []byte) error {
    _, err := s.client.PutObject(ctx, &s3.PutObjectInput{
        Bucket: aws.String(bucket),
        Key:    aws.String(key),
        Body:   bytes.NewReader(data),
    })
    return err
}
```

## Idiomatic: Missing error wrapping
**Severity**: warn

Always wrap errors with context when returning them up the call stack. Bare `return err` loses context about where the error originated.

**Why**: Without wrapping, a generic "connection refused" error could come from any of dozens of call sites. Error wrapping with `fmt.Errorf("context: %w", err)` creates a trace that pinpoints the origin.

```go
// BAD
func (s *Service) GetItem(ctx context.Context, id uuid.UUID) (*Item, error) {
    item, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    return item, nil
}
```

```go
// GOOD
func (s *Service) GetItem(ctx context.Context, id uuid.UUID) (*Item, error) {
    item, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("get item %s: %w", id, err)
    }
    return item, nil
}
```

## Best Practice: Bare fmt.Println instead of structured logging
**Severity**: warn

Use the project's structured logging library (typically `slog`) instead of `fmt.Println` or `log.Println`. Structured logging enables filtering, correlation, and production observability.

**Why**: Unstructured print statements cannot be filtered by level, correlated by request ID, or parsed by log aggregation tools. In production they become noise that obscures real signals.

```go
// BAD
fmt.Println("processing document", docID)
```

```go
// GOOD
slog.Info("processing document", "document_id", docID, "stage", "extraction")
```
