---
meta:
  stack: ["rust"]
  version: 1
  last_reviewed: 2026-03-25
---

# Rust Anti-Patterns

These rules target mistakes that AI coding assistants frequently introduce in Rust code. Research shows AI-generated Rust has 1.7x more issues than human-written Rust, largely because models fight the borrow checker, over-clone, and reach for unsafe when they cannot satisfy lifetime constraints. Every rule has a concrete BAD/GOOD example.

## Anti-pattern: Unnecessary clone()
**Severity**: warn

Calling `.clone()` to satisfy the borrow checker when the value can be borrowed or moved instead. AI-generated code clones aggressively to silence compiler errors without understanding ownership.

**Why**: Unnecessary clones allocate heap memory and copy data for no reason. In hot paths this causes measurable performance degradation, and it obscures the actual ownership semantics of the code.

```rust
// BAD
fn process(items: &[String]) {
    for item in items {
        let owned = item.clone();
        println!("{}", owned);
    }
}
```

```rust
// GOOD
fn process(items: &[String]) {
    for item in items {
        println!("{}", item);
    }
}
```

## Anti-pattern: unwrap() in Production Code
**Severity**: error

Using `.unwrap()` or `.expect()` on `Result` or `Option` in library or application code that runs in production. These calls panic on failure, crashing the entire program or task.

**Why**: A panic in a web server handler, background job, or library function takes down the process or poisons a thread pool. Callers have no way to recover. Use pattern matching or the `?` operator to propagate errors instead.

```rust
// BAD
fn read_config(path: &str) -> Config {
    let contents = std::fs::read_to_string(path).unwrap();
    serde_json::from_str(&contents).unwrap()
}
```

```rust
// GOOD
fn read_config(path: &str) -> Result<Config, Box<dyn std::error::Error>> {
    let contents = std::fs::read_to_string(path)?;
    let config = serde_json::from_str(&contents)?;
    Ok(config)
}
```

## Anti-pattern: Using unsafe to Fight the Borrow Checker
**Severity**: error

Wrapping code in `unsafe` blocks to bypass borrow checker errors instead of restructuring ownership. AI models reach for unsafe when they cannot figure out how to satisfy lifetime constraints.

**Why**: The borrow checker exists to prevent data races, use-after-free, and aliased mutation. Using unsafe to silence it reintroduces exactly those bugs. Almost every borrow checker error has a safe solution involving restructured ownership, interior mutability (`RefCell`, `Mutex`), or index-based access.

```rust
// BAD
fn update_items(items: &mut Vec<String>) {
    // unsafe cast to bypass simultaneous borrow
    let ptr = items as *mut Vec<String>;
    for i in 0..items.len() {
        unsafe {
            (*ptr).push(format!("copy-{}", (*ptr)[i]));
        }
    }
}
```

```rust
// GOOD
fn update_items(items: &mut Vec<String>) {
    let new_items: Vec<String> = items.iter()
        .map(|item| format!("copy-{}", item))
        .collect();
    items.extend(new_items);
}
```

## Anti-pattern: Manual Loop Instead of Iterator Chain
**Severity**: warn

Writing manual index-based loops with mutable accumulators when an iterator chain (map, filter, collect) expresses the same logic more clearly and safely.

**Why**: Iterator chains are optimized by LLVM as well or better than manual loops, and they eliminate off-by-one errors, bounds-check overhead, and mutable state. AI code frequently defaults to C-style loops that miss these benefits.

```rust
// BAD
fn get_even_squares(nums: &[i32]) -> Vec<i32> {
    let mut result = Vec::new();
    for i in 0..nums.len() {
        if nums[i] % 2 == 0 {
            result.push(nums[i] * nums[i]);
        }
    }
    result
}
```

```rust
// GOOD
fn get_even_squares(nums: &[i32]) -> Vec<i32> {
    nums.iter()
        .filter(|n| *n % 2 == 0)
        .map(|n| n * n)
        .collect()
}
```

## Anti-pattern: Premature Lifetime Annotations
**Severity**: warn

Adding explicit lifetime annotations when the compiler can infer them via lifetime elision rules. AI models add `'a` parameters everywhere as a cargo-cult response to lifetime errors, making signatures noisy and rigid.

**Why**: Unnecessary lifetime annotations clutter function signatures and can over-constrain the API, making it harder for callers to use. The elision rules handle the common cases correctly. Add explicit lifetimes only when the compiler asks for them or when the relationship between input and output lifetimes is ambiguous.

```rust
// BAD
fn first_word<'a>(s: &'a str) -> &'a str {
    s.split_whitespace().next().unwrap_or("")
}

fn len<'a>(s: &'a str) -> usize {
    s.len()
}
```

```rust
// GOOD
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

fn len(s: &str) -> usize {
    s.len()
}
```

## Anti-pattern: String Parameters Instead of &str
**Severity**: warn

Requiring `String` in function parameters when the function only reads the string data. This forces callers to allocate and clone even when they already have a `&str` or string literal.

**Why**: Accepting `&str` allows callers to pass `&String`, string literals, and slices without allocation. Requiring `String` forces unnecessary `.to_string()` or `.to_owned()` calls at every call site, wasting memory and CPU.

```rust
// BAD
fn greet(name: String) {
    println!("Hello, {}!", name);
}

fn main() {
    let name = "Alice";
    greet(name.to_string()); // forced allocation
}
```

```rust
// GOOD
fn greet(name: &str) {
    println!("Hello, {}!", name);
}

fn main() {
    let name = "Alice";
    greet(name); // no allocation needed
}
```

## Anti-pattern: Missing Error Context in ? Chains
**Severity**: warn

Using the `?` operator to propagate errors without adding context about what operation failed. Long chains of bare `?` produce error messages like "No such file or directory" with no indication of which file or which step in the pipeline failed.

**Why**: In production, a bare IO error from three levels deep gives no clue about what the application was trying to do. Wrapping with `map_err` or using `anyhow`/`thiserror` context adds the "what was happening" to the "what went wrong".

```rust
// BAD
fn load_user_settings(user_id: u64) -> Result<Settings, Box<dyn std::error::Error>> {
    let path = format!("/etc/app/users/{}.toml", user_id);
    let content = std::fs::read_to_string(&path)?;
    let settings: Settings = toml::from_str(&content)?;
    Ok(settings)
}
```

```rust
// GOOD
use anyhow::{Context, Result};

fn load_user_settings(user_id: u64) -> Result<Settings> {
    let path = format!("/etc/app/users/{}.toml", user_id);
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("read settings file for user {}", user_id))?;
    let settings: Settings = toml::from_str(&content)
        .with_context(|| format!("parse settings for user {}", user_id))?;
    Ok(settings)
}
```

## Best Practice: Use impl Trait in Argument Position
**Severity**: info

Accept `impl Trait` in function arguments instead of concrete types when the function only needs the trait's behavior. This makes APIs more flexible without the complexity of explicit generics.

**Why**: Accepting `impl AsRef<Path>` instead of `&Path` lets callers pass `String`, `PathBuf`, `&str`, or `&Path` directly. AI code tends to use concrete types everywhere, forcing callers through unnecessary conversions.

```rust
// BAD
fn file_exists(path: &std::path::Path) -> bool {
    path.exists()
}

fn main() {
    let p = String::from("/tmp/test");
    file_exists(std::path::Path::new(&p)); // caller must convert
}
```

```rust
// GOOD
fn file_exists(path: impl AsRef<std::path::Path>) -> bool {
    path.as_ref().exists()
}

fn main() {
    file_exists("/tmp/test");       // &str works
    file_exists(String::from("/tmp/test")); // String works
}
```

## Best Practice: Derive Common Traits
**Severity**: info

Derive `Debug`, `Clone`, `PartialEq`, and other standard traits on structs and enums unless there is a specific reason not to. AI-generated types frequently omit derives, making them unusable in tests, collections, and debug output.

**Why**: Without `Debug`, types cannot be printed in error messages or test assertions (`assert_eq!` requires both `Debug` and `PartialEq`). Without `Clone`, types cannot be easily duplicated when needed. Missing derives force workarounds that are more complex and error-prone.

```rust
// BAD
struct Config {
    host: String,
    port: u16,
    retries: u32,
}
// cannot println!("{:?}", config) or assert_eq!(a, b)
```

```rust
// GOOD
#[derive(Debug, Clone, PartialEq)]
struct Config {
    host: String,
    port: u16,
    retries: u32,
}
```

## Best Practice: Use Cow for Flexible Ownership
**Severity**: info

Use `Cow<'_, str>` (or `Cow<'_, [T]>`) when a function sometimes needs to own data and sometimes can borrow it. This avoids forcing an allocation in the common case while still supporting the owned case.

**Why**: AI code either always clones (wasteful) or always borrows (inflexible). `Cow` gives zero-cost borrowing when possible and allocates only when mutation or ownership is actually needed, which is the idiomatic Rust approach for string-processing functions.

```rust
// BAD
fn normalize(input: &str) -> String {
    if input.contains(' ') {
        input.replace(' ', "_") // allocation needed
    } else {
        input.to_string() // unnecessary allocation
    }
}
```

```rust
// GOOD
use std::borrow::Cow;

fn normalize(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        Cow::Owned(input.replace(' ', "_"))
    } else {
        Cow::Borrowed(input) // zero-cost when no modification needed
    }
}
```

## Idiomatic: Use if let for Single-Pattern Matching
**Severity**: info

Use `if let` when matching on a single variant of an enum. A full `match` with a wildcard arm is unnecessarily verbose for single-pattern checks.

**Why**: AI models default to `match` for every enum check, producing verbose code with an empty `_ => {}` arm. `if let` communicates "I only care about this one case" more clearly and is the idiomatic Rust pattern for optional unwrapping and single-variant checks.

```rust
// BAD
match config.log_file {
    Some(ref path) => {
        setup_file_logging(path);
    }
    _ => {}
}
```

```rust
// GOOD
if let Some(ref path) = config.log_file {
    setup_file_logging(path);
}
```

## Idiomatic: Use Entry API for HashMap Insert-or-Update
**Severity**: info

Use the `entry()` API on `HashMap` instead of checking `contains_key()` then inserting. The entry API performs a single lookup instead of two and is the idiomatic pattern.

**Why**: The contains-then-insert pattern does two hash lookups and two key comparisons. The entry API does one. AI code frequently writes the two-step version because it maps more directly from pseudocode, missing the purpose-built API.

```rust
// BAD
use std::collections::HashMap;

fn count_words(words: &[&str]) -> HashMap<String, usize> {
    let mut counts = HashMap::new();
    for word in words {
        if counts.contains_key(*word) {
            *counts.get_mut(*word).unwrap() += 1;
        } else {
            counts.insert(word.to_string(), 1);
        }
    }
    counts
}
```

```rust
// GOOD
use std::collections::HashMap;

fn count_words(words: &[&str]) -> HashMap<String, usize> {
    let mut counts = HashMap::new();
    for word in words {
        *counts.entry(word.to_string()).or_insert(0) += 1;
    }
    counts
}
```

## Idiomatic: Use ? Operator Over match on Result
**Severity**: info

Use the `?` operator to propagate errors instead of writing a full `match` on every `Result`. The `?` operator is syntactic sugar for the early-return-on-error pattern and is far more readable.

**Why**: AI models frequently expand every `Result` into a `match` with explicit `Ok` and `Err` arms, making functions three times longer than necessary. The `?` operator achieves the same thing in one character and is the standard Rust idiom.

```rust
// BAD
fn read_and_parse(path: &str) -> Result<Data, Box<dyn std::error::Error>> {
    let content = match std::fs::read_to_string(path) {
        Ok(c) => c,
        Err(e) => return Err(Box::new(e)),
    };
    let data = match serde_json::from_str(&content) {
        Ok(d) => d,
        Err(e) => return Err(Box::new(e)),
    };
    Ok(data)
}
```

```rust
// GOOD
fn read_and_parse(path: &str) -> Result<Data, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string(path)?;
    let data = serde_json::from_str(&content)?;
    Ok(data)
}
```

## Performance: Avoid Allocation in Hot Loops
**Severity**: warn

Allocating `String`, `Vec`, or other heap types inside tight loops when a pre-allocated buffer or stack-local variable would suffice. AI code frequently creates new allocations per iteration.

**Why**: Each heap allocation goes through the global allocator, which is orders of magnitude slower than stack access. In hot loops processing thousands or millions of items, per-iteration allocation dominates runtime. Pre-allocate outside the loop and reuse with `clear()`.

```rust
// BAD
fn process_lines(input: &str) -> Vec<String> {
    let mut results = Vec::new();
    for line in input.lines() {
        let mut buffer = String::new(); // allocation per iteration
        buffer.push_str("PREFIX: ");
        buffer.push_str(line);
        results.push(buffer);
    }
    results
}
```

```rust
// GOOD
fn process_lines(input: &str) -> Vec<String> {
    let mut results = Vec::new();
    let mut buffer = String::new(); // allocate once
    for line in input.lines() {
        buffer.clear(); // reuse without reallocating
        buffer.push_str("PREFIX: ");
        buffer.push_str(line);
        results.push(buffer.clone()); // clone only for the output
    }
    results
}
```

## Security: Validate Array Indices Before Access
**Severity**: error

Accessing slices or arrays with unchecked indices from external input (user data, parsed values, network packets). Out-of-bounds access in Rust panics, which is a denial-of-service vector.

**Why**: Unlike C, Rust does not have buffer overflows from out-of-bounds access -- it panics instead. But a panic in a server handler or data pipeline is still a crash. Validate indices against the actual length, or use `.get()` which returns `Option` instead of panicking.

```rust
// BAD
fn get_field(record: &[&str], index: usize) -> &str {
    record[index] // panics if index >= record.len()
}
```

```rust
// GOOD
fn get_field<'a>(record: &'a [&str], index: usize) -> Option<&'a str> {
    record.get(index).copied()
}
```

## Anti-pattern: Ignoring Clippy Warnings Without Justification
**Severity**: warn

Adding `#[allow(clippy::...)]` attributes to silence Clippy warnings without a comment explaining why the lint does not apply. AI code often blanket-allows warnings to make the code compile clean.

**Why**: Clippy warnings usually indicate real issues. Silencing them without justification hides bugs and prevents future maintainers from understanding whether the allow was intentional or just a workaround. If the lint truly does not apply, document why.

```rust
// BAD
#[allow(clippy::needless_return)]
#[allow(clippy::redundant_clone)]
#[allow(clippy::unwrap_used)]
fn process(data: &str) -> String {
    let result = data.to_string().clone();
    return result.unwrap();
}
```

```rust
// GOOD
// Clippy flags this as redundant, but the trait bound requires an owned String
// and the input may alias the output buffer in concurrent contexts.
#[allow(clippy::redundant_clone)]
fn process(data: &str) -> String {
    let result = data.to_string().clone();
    result
}
```

## Anti-pattern: Box<dyn Error> Instead of Custom Error Type
**Severity**: warn

Using `Box<dyn Error>` or `Box<dyn std::error::Error>` as the error type in library or application code instead of defining a proper error enum. AI code defaults to the most generic error type to avoid writing boilerplate.

**Why**: `Box<dyn Error>` erases the error variant, making it impossible for callers to match on specific failure modes and handle them differently. A typed error enum (via `thiserror`) enables pattern matching, retries on transient errors, and meaningful error messages for users.

```rust
// BAD
fn connect(url: &str) -> Result<Connection, Box<dyn std::error::Error>> {
    let parsed = url::Url::parse(url)?;
    let conn = TcpStream::connect(parsed.socket_addrs(|| None)?
        .first()
        .ok_or("no addresses")?)?;
    Ok(Connection::new(conn))
}
```

```rust
// GOOD
use thiserror::Error;

#[derive(Debug, Error)]
enum ConnectError {
    #[error("invalid URL: {0}")]
    InvalidUrl(#[from] url::ParseError),
    #[error("DNS resolution failed: no addresses for host")]
    NoAddresses,
    #[error("TCP connection failed: {0}")]
    TcpFailed(#[from] std::io::Error),
}

fn connect(url: &str) -> Result<Connection, ConnectError> {
    let parsed = url::Url::parse(url)?;
    let addr = parsed.socket_addrs(|| None)?
        .into_iter()
        .next()
        .ok_or(ConnectError::NoAddresses)?;
    let conn = TcpStream::connect(addr)?;
    Ok(Connection::new(conn))
}
```

## Idiomatic: Use Default Trait Implementation
**Severity**: info

Implement the `Default` trait (or derive it) on types that have a sensible default state instead of providing a `new()` constructor with no arguments. This enables integration with `..Default::default()` struct update syntax and generic code that requires `Default`.

**Why**: AI code frequently writes `Type::new()` functions that return hardcoded defaults without implementing `Default`. This misses integration with `Option::unwrap_or_default()`, `Vec::resize_with`, struct update syntax, and any generic code bounded on `T: Default`.

```rust
// BAD
struct ServerConfig {
    host: String,
    port: u16,
    max_connections: usize,
}

impl ServerConfig {
    fn new() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 8080,
            max_connections: 100,
        }
    }
}
```

```rust
// GOOD
#[derive(Debug)]
struct ServerConfig {
    host: String,
    port: u16,
    max_connections: usize,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 8080,
            max_connections: 100,
        }
    }
}

// Now works with struct update syntax:
// let config = ServerConfig { port: 3000, ..Default::default() };
```
