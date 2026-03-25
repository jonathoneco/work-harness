---
meta:
  stack: ["go"]
  version: 2
  last_reviewed: 2026-03-25
---

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

## Anti-pattern: Goroutine leak from unbuffered channel
**Severity**: error

Do not spawn a goroutine that sends to a channel when there is no guaranteed receiver. If the receiver exits early (due to context cancellation, timeout, or error), the sender goroutine blocks forever, leaking memory and a stack.

**Why**: Leaked goroutines accumulate silently. Each holds its stack (~8 KB minimum) and any heap objects it references. Under load, thousands of leaked goroutines cause OOM crashes with no obvious cause in metrics.

```go
// BAD
// if ctx is cancelled before result is read, the goroutine hangs forever
func fetchData(ctx context.Context, url string) (*Result, error) {
    ch := make(chan *Result)
    go func() {
        r, _ := http.Get(url)
        defer r.Body.Close()
        var result Result
        json.NewDecoder(r.Body).Decode(&result)
        ch <- &result // blocks forever if nobody reads
    }()
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    case result := <-ch:
        return result, nil
    }
}
```

```go
// GOOD
// buffered channel lets the goroutine complete even if the receiver is gone
func fetchData(ctx context.Context, url string) (*Result, error) {
    ch := make(chan *Result, 1)
    go func() {
        r, err := http.Get(url)
        if err != nil {
            return
        }
        defer r.Body.Close()
        var result Result
        if err := json.NewDecoder(r.Body).Decode(&result); err != nil {
            return
        }
        ch <- &result // never blocks: buffer size 1
    }()
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    case result := <-ch:
        return result, nil
    }
}
```

## Anti-pattern: Nil pointer on interface value
**Severity**: error

An interface value is only `nil` when both its type and value are nil. If you assign a typed nil pointer to an interface, `interface != nil` evaluates to true, but calling methods on the underlying pointer still panics.

**Why**: This is one of Go's most common gotchas. AI agents frequently return a typed nil pointer from a function with an interface return type, then callers check `if err != nil` or `if result != nil` and proceed, hitting a nil dereference panic at runtime.

```go
// BAD
// returns (*MyError)(nil) which is NOT a nil interface
func validate(input string) error {
    var err *MyError
    if len(input) == 0 {
        err = &MyError{Msg: "empty input"}
    }
    return err // caller sees err != nil even when input is valid
}
```

```go
// GOOD
// return an explicit nil interface value on the success path
func validate(input string) error {
    if len(input) == 0 {
        return &MyError{Msg: "empty input"}
    }
    return nil
}
```

## Anti-pattern: Context cancellation not propagated
**Severity**: warn

Always pass the parent context through to downstream calls. Do not create a new `context.Background()` or `context.TODO()` inside a function that already receives a context parameter. This breaks the cancellation chain.

**Why**: When a caller cancels its context (e.g., HTTP request disconnects), downstream work should stop promptly. Using `context.Background()` inside the call chain means the downstream operation runs to completion even after the caller is gone, wasting resources and potentially writing stale results.

```go
// BAD
// parent cancellation is ignored; the DB query runs to completion
func (s *Service) GetReport(ctx context.Context, id uuid.UUID) (*Report, error) {
    rows, err := s.pool.Query(context.Background(), "SELECT ...", id)
    if err != nil {
        return nil, fmt.Errorf("query report: %w", err)
    }
    defer rows.Close()
    return scanReport(rows)
}
```

```go
// GOOD
// parent context flows through; cancellation propagates to the DB driver
func (s *Service) GetReport(ctx context.Context, id uuid.UUID) (*Report, error) {
    rows, err := s.pool.Query(ctx, "SELECT ...", id)
    if err != nil {
        return nil, fmt.Errorf("query report: %w", err)
    }
    defer rows.Close()
    return scanReport(rows)
}
```

## Anti-pattern: Defer in loop
**Severity**: warn

Do not use `defer` inside a `for` loop. Deferred calls execute when the enclosing *function* returns, not when the loop iteration ends. Resources opened in the loop pile up until the function exits.

**Why**: In a loop processing thousands of items, each iteration opens a resource (file, connection, response body) and defers its close. None close until the loop finishes. This causes file descriptor exhaustion, memory spikes, or connection pool starvation.

```go
// BAD
// all file handles stay open until processAll returns
func processAll(paths []string) error {
    for _, path := range paths {
        f, err := os.Open(path)
        if err != nil {
            return fmt.Errorf("open %s: %w", path, err)
        }
        defer f.Close() // deferred until function returns, not loop iteration
        if err := process(f); err != nil {
            return fmt.Errorf("process %s: %w", path, err)
        }
    }
    return nil
}
```

```go
// GOOD
// extract loop body into a function so defer runs each iteration
func processAll(paths []string) error {
    for _, path := range paths {
        if err := processOne(path); err != nil {
            return err
        }
    }
    return nil
}

func processOne(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("open %s: %w", path, err)
    }
    defer f.Close()
    if err := process(f); err != nil {
        return fmt.Errorf("process %s: %w", path, err)
    }
    return nil
}
```

## Anti-pattern: Slice append aliasing
**Severity**: warn

When a function receives a slice parameter and appends to it, the append may or may not allocate a new backing array depending on capacity. If it does not, the caller's underlying array is silently mutated. Do not append to slice parameters unless the function clearly owns the slice.

**Why**: Slice aliasing bugs are extremely hard to diagnose. The behavior depends on the slice's current length vs. capacity, which changes at runtime. Tests pass with small inputs (triggers reallocation) but production data with pre-allocated capacity causes silent data corruption.

```go
// BAD
// if items has spare capacity, caller's backing array is corrupted
func addDefaults(items []Item) []Item {
    items = append(items, Item{Name: "default-timeout", Value: "30s"})
    items = append(items, Item{Name: "default-retries", Value: "3"})
    return items
}
```

```go
// GOOD
// copy into a new slice to avoid aliasing the caller's backing array
func addDefaults(items []Item) []Item {
    result := make([]Item, len(items), len(items)+2)
    copy(result, items)
    result = append(result, Item{Name: "default-timeout", Value: "30s"})
    result = append(result, Item{Name: "default-retries", Value: "3"})
    return result
}
```

## Anti-pattern: init() function abuse
**Severity**: warn

Do not put complex logic, I/O operations, or side effects in `init()` functions. Use `init()` only for simple variable registration (e.g., `flag.StringVar`, driver registration). Everything else belongs in explicit constructors or setup functions.

**Why**: `init()` runs before `main()` with no way to pass arguments, return errors, or control execution order across packages. Complex init logic makes tests non-deterministic (global state set before TestMain), prevents dependency injection, and turns import order into a hidden dependency graph.

```go
// BAD
// init connects to a real database; tests import this package and fail
func init() {
    var err error
    db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil {
        log.Fatal(err)
    }
    if err := db.Ping(); err != nil {
        log.Fatal(err)
    }
    if err := runMigrations(db); err != nil {
        log.Fatal(err)
    }
}
```

```go
// GOOD
// explicit setup function that can be called with test config
func NewDB(dsn string) (*sql.DB, error) {
    db, err := sql.Open("postgres", dsn)
    if err != nil {
        return nil, fmt.Errorf("open database: %w", err)
    }
    if err := db.Ping(); err != nil {
        return nil, fmt.Errorf("ping database: %w", err)
    }
    if err := runMigrations(db); err != nil {
        return nil, fmt.Errorf("run migrations: %w", err)
    }
    return db, nil
}
```

## Anti-pattern: Shadow variable with :=
**Severity**: warn

Do not use `:=` in an inner scope when you intend to assign to an outer variable. The short declaration creates a new variable that shadows the outer one, leaving the outer variable unchanged. This is especially dangerous with `err`.

**Why**: Variable shadowing with `:=` is the most common source of "impossible" bugs in Go. The code compiles and runs, but the outer `err` remains nil while the inner `err` captures the real error. The function then proceeds as if no error occurred, leading to nil pointer panics or corrupt data downstream.

```go
// BAD
// the outer err stays nil; the function returns (result, nil) even on failure
func loadConfig(path string) (*Config, error) {
    var cfg *Config
    var err error
    if path != "" {
        cfg, err := parseFile(path) // shadows outer cfg and err
        if err != nil {
            return nil, fmt.Errorf("parse config: %w", err)
        }
        cfg.Source = path // assigns to inner cfg, lost after this block
    }
    return cfg, err // returns (nil, nil) -- caller thinks success
}
```

```go
// GOOD
// use = to assign to the already-declared outer variables
func loadConfig(path string) (*Config, error) {
    var cfg *Config
    var err error
    if path != "" {
        cfg, err = parseFile(path) // assigns to outer cfg and err
        if err != nil {
            return nil, fmt.Errorf("parse config: %w", err)
        }
        cfg.Source = path
    }
    return cfg, err
}
```
