# Security Anti-Patterns

Common security mistakes in LLM-generated code. Each entry documents a pattern to detect, the risk it creates, and a concrete fix. Organized by LLM failure mode rather than traditional security taxonomy.

## Authentication and Authorization

### Hardcoded Credentials
- **Pattern**: API keys, passwords, or tokens appear as string literals in source code (`apiKey := "sk-..."`, `password = "admin123"`)
- **Risk**: Credentials committed to version control are exposed to anyone with repo access and persist in git history even after removal
- **Fix**: Load credentials from environment variables or a secrets manager. Validate they are non-empty at startup and fail closed if missing

### Auth Bypass via Fallback
- **Pattern**: Authentication failure path falls through to allow access (`if err != nil { user = anonymousUser }` or `if !authenticated { proceed() }`)
- **Risk**: Any auth system failure (network timeout, misconfigured provider, malformed token) silently grants access instead of denying it
- **Fix**: Auth failures must return an error or deny access. Never assign a default/anonymous identity on auth failure — return 401/403 and stop processing

### Token Validation Skipped in Error Paths
- **Pattern**: Token validation occurs in the happy path but is bypassed in error handling, retry logic, or fallback code paths
- **Risk**: Attackers can trigger error conditions to bypass token validation entirely
- **Fix**: Validate tokens at the middleware/gateway level before any business logic executes. Token validation must not be conditional on other operations succeeding

### Overly Permissive CORS Configuration
- **Pattern**: CORS headers set to `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true`, or origin validation that accepts any origin containing the target domain
- **Risk**: Enables cross-site request forgery and credential theft from any origin, including attacker-controlled sites
- **Fix**: Allowlist specific origins explicitly. Never combine wildcard origin with credentials. Validate the full origin string, not substrings

### Missing Rate Limiting on Auth Endpoints
- **Pattern**: Login, password reset, and token refresh endpoints have no rate limiting or use limits too high to be effective (e.g., 10000 requests/minute)
- **Risk**: Enables brute-force credential attacks, credential stuffing, and account enumeration at scale
- **Fix**: Apply rate limiting per IP and per account on all auth endpoints. Use progressive delays or account lockout after repeated failures. Typical threshold: 5-10 attempts per minute per account

## Input Handling

### SQL Injection via String Concatenation
- **Pattern**: SQL queries built by concatenating user input (`"SELECT * FROM users WHERE id = '" + userID + "'"`) or using `fmt.Sprintf` for query values
- **Risk**: Attackers can inject arbitrary SQL to read, modify, or delete any data in the database, or escalate to OS-level access
- **Fix**: Use parameterized queries with placeholder syntax (`$1`, `?`, `:name`). Never interpolate user input into SQL strings. Use the database driver's built-in parameter binding

### Command Injection via Unsanitized Shell Arguments
- **Pattern**: User input passed directly to `exec.Command`, `os.system()`, `subprocess.run(shell=True)`, or backtick evaluation without sanitization
- **Risk**: Attackers can inject shell metacharacters (`;`, `|`, `$()`) to execute arbitrary commands on the server
- **Fix**: Use parameterized command execution (pass arguments as array elements, not shell strings). Validate inputs against an allowlist of expected characters. Avoid `shell=True` and equivalent options

### Path Traversal via User-Supplied File Paths
- **Pattern**: User-provided filenames or paths joined directly to a base path without sanitization (`filepath.Join(baseDir, userInput)` where `userInput` can contain `../`)
- **Risk**: Attackers can read or write arbitrary files on the filesystem by traversing outside the intended directory
- **Fix**: Resolve the final path and verify it is still within the intended base directory. Reject paths containing `..` components. Use `filepath.Rel` or equivalent to confirm containment

### Unvalidated Redirect URLs
- **Pattern**: Redirect destination taken from query parameters or form data without validation (`http.Redirect(w, r, r.URL.Query().Get("next"), 302)`)
- **Risk**: Open redirect enables phishing attacks — users trust the original domain but are sent to an attacker-controlled site
- **Fix**: Validate redirect URLs against an allowlist of permitted domains or restrict to relative paths only. Strip any scheme/host from user-supplied redirect targets

### Missing Input Length Limits
- **Pattern**: Text fields, file uploads, or request bodies accepted without size limits or with limits set unreasonably high
- **Risk**: Denial of service via memory exhaustion, storage exhaustion, or processing timeouts from oversized inputs
- **Fix**: Set explicit `MaxBytesReader` or equivalent on all request bodies. Define per-field length limits that match business requirements. Validate before processing, not after

## Secrets and Configuration

### Secrets Logged in Plaintext
- **Pattern**: Structured logging fields containing tokens, passwords, API keys, or session IDs (`slog.Info("request", "auth_header", r.Header.Get("Authorization"))`)
- **Risk**: Secrets persisted in log aggregation systems are accessible to anyone with log access and may be retained indefinitely
- **Fix**: Redact sensitive fields before logging. Use a logging middleware that strips known sensitive headers (`Authorization`, `Cookie`, `X-API-Key`). Never log full request headers or bodies without redaction

### Secrets in Error Messages
- **Pattern**: Error messages returned to API clients include connection strings, API keys, or internal credentials (`return fmt.Errorf("failed to connect to %s with key %s", dbURL, apiKey)`)
- **Risk**: Clients (including attackers) receive internal secrets in error responses, enabling further attacks
- **Fix**: Return generic error messages to clients. Log detailed errors server-side with correlation IDs. Map internal errors to user-safe messages at the API boundary

### Default Secrets That Work in Development
- **Pattern**: Configuration defaults that provide working but insecure secrets (`hmacSecret := os.Getenv("HMAC_SECRET"); if hmacSecret == "" { hmacSecret = "changeme" }`)
- **Risk**: Default secrets deployed to production enable anyone who reads the source to forge tokens, bypass auth, or decrypt data
- **Fix**: Require all secrets via environment variables or secrets manager with no defaults. Fail at startup if any required secret is empty. Use a `.env.example` file with placeholder values for documentation

### Environment Variable Fallbacks That Degrade Security
- **Pattern**: Security-relevant configuration with insecure defaults (`tlsEnabled := os.Getenv("TLS_ENABLED") != "false"` where empty string means disabled, or `if os.Getenv("REQUIRE_AUTH") == "" { requireAuth = false }`)
- **Risk**: Missing environment variables silently disable security features in production deployments
- **Fix**: Security features must default to enabled/strict. Use explicit opt-out rather than opt-in for security controls. Fail closed on missing config: if `TLS_ENABLED` is unset, TLS is required

## Error Handling (Security Impact)

### Stack Traces Exposed in API Responses
- **Pattern**: Error handlers that include stack traces, file paths, or line numbers in HTTP responses (`http.Error(w, fmt.Sprintf("%+v", err), 500)`)
- **Risk**: Stack traces reveal internal file structure, library versions, and code paths that help attackers identify vulnerabilities
- **Fix**: Return generic error messages with correlation IDs to clients. Log stack traces server-side only. Use a centralized error handler that strips internal details at the API boundary

### Detailed Database Errors Returned to Clients
- **Pattern**: Raw database error messages forwarded to API responses (`if err != nil { http.Error(w, err.Error(), 500) }` where `err` comes from a DB query)
- **Risk**: Database errors reveal table names, column names, query structure, and sometimes data values to attackers
- **Fix**: Catch database errors and return generic "internal error" responses. Log the full error server-side. Map specific database errors (unique constraint, not found) to appropriate HTTP status codes without leaking schema details

### Resource Existence Leaked via Error Responses
- **Pattern**: Different error messages for "not found" vs "not authorized" (`404 User not found` vs `403 Access denied`) that let attackers enumerate valid resources
- **Risk**: Attackers can determine which user IDs, email addresses, or resource IDs exist in the system by observing response differences
- **Fix**: Return the same error response for "not found" and "not authorized" on sensitive endpoints. Use `404 Not Found` for both cases, or `403 Forbidden` for both. Log the actual reason server-side

### Catch-All Handlers That Swallow Security Failures
- **Pattern**: Generic exception handlers that catch all errors and continue processing (`try { validateToken() } catch (e) { /* continue */ }` or `defer func() { recover() }()` around auth code)
- **Risk**: Security-critical failures (invalid token, permission denied, tampered data) are silently ignored, allowing unauthorized operations to proceed
- **Fix**: Never use catch-all handlers around security-critical code. Let auth and authorization failures propagate. If you must catch broadly, re-raise security-related exceptions

## Cryptography

### Weak Hash Algorithms for Passwords
- **Pattern**: Passwords hashed with MD5, SHA1, SHA256, or any general-purpose hash — even with salt — instead of a password-specific KDF
- **Risk**: General-purpose hashes are fast to compute, enabling brute-force attacks. GPU-based cracking can test billions of MD5 hashes per second
- **Fix**: Use bcrypt, scrypt, or argon2id for password hashing. These algorithms are deliberately slow and memory-hard. Set cost parameters appropriate for your hardware (bcrypt cost 12+, argon2id with recommended RFC 9106 parameters)

### Hardcoded Initialization Vectors or Nonces
- **Pattern**: Encryption IVs or nonces defined as constants or generated from predictable values (`iv := []byte("1234567890123456")`)
- **Risk**: Reusing IVs with the same key breaks the confidentiality guarantees of most encryption modes (CBC, CTR, GCM). For GCM, IV reuse enables key recovery
- **Fix**: Generate IVs/nonces using a cryptographically secure random number generator (`crypto/rand`) for each encryption operation. For GCM, use 96-bit random nonces. Prepend the IV to the ciphertext for storage

### Non-Cryptographic RNG for Security Values
- **Pattern**: Using `math/rand`, `random.random()`, `Math.random()`, or equivalent non-cryptographic PRNGs to generate tokens, session IDs, nonces, or other security-sensitive values
- **Risk**: Non-cryptographic RNGs have predictable output. Attackers who observe a few values can predict future values and forge tokens or session IDs
- **Fix**: Use `crypto/rand` (Go), `secrets` module (Python), `crypto.randomUUID()`/`crypto.getRandomValues()` (JavaScript), or equivalent cryptographically secure RNG for all security-sensitive values

### Custom Cryptography Implementations
- **Pattern**: Hand-rolled encryption, hashing, or signature verification instead of using standard library functions or well-audited cryptography packages
- **Risk**: Custom crypto implementations almost always contain subtle flaws (timing side channels, padding oracle vulnerabilities, incorrect mode usage) that are not apparent in testing
- **Fix**: Use standard library cryptography (`crypto/*` in Go, `cryptography` package in Python, Web Crypto API in JavaScript). If the standard library does not support your use case, use a well-audited library (libsodium/NaCl). Never implement your own encryption, key derivation, or signature algorithms
