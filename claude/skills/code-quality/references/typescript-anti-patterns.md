---
meta:
  stack: ["typescript"]
  version: 1
  last_reviewed: 2026-03-25
---

# TypeScript Anti-Patterns

These rules target TypeScript-specific mistakes that AI coding assistants repeatedly introduce. Every rule has a concrete BAD/GOOD example. Rules here complement the universal rules in `code-quality.md` — language-agnostic concerns (error swallowing, fail-open, fabricated data) are covered there and not duplicated here.

## Anti-pattern: Abuse of `any` Type
**Severity**: error

Using `any` disables TypeScript's type system, silencing all compile-time checks on the annotated value. AI-generated code frequently sprinkles `any` to make the compiler stop complaining rather than fixing the actual type issue.

**Why**: `any` propagates — a single `any` infects every value that touches it, creating invisible gaps in type safety that surface as runtime crashes in production.

```typescript
// BAD
function processResponse(data: any) {
  return data.results.map((item: any) => item.name.toUpperCase());
}
```

```typescript
// GOOD
interface ApiResponse {
  results: Array<{ name: string }>;
}

function processResponse(data: ApiResponse) {
  return data.results.map((item) => item.name.toUpperCase());
}
```

## Anti-pattern: Unawaited Promise
**Severity**: error

Calling an async function without `await`, `.then()`, or `.catch()` discards its result and any errors it throws. The operation fires and is silently forgotten.

**Why**: Unawaited promises run concurrently with no error handling. Failures crash the process with an unhandled rejection or vanish entirely. The calling code proceeds as if the operation completed successfully.

```typescript
// BAD
async function saveAndNotify(user: User) {
  await db.save(user);
  sendWelcomeEmail(user); // async function — promise floats
}
```

```typescript
// GOOD
async function saveAndNotify(user: User) {
  await db.save(user);
  await sendWelcomeEmail(user);
}
```

## Anti-pattern: Non-null Assertion After Optional Chaining
**Severity**: error

Using `!` (non-null assertion) on the result of an optional chain (`?.`) defeats the safety that optional chaining provides. If the chain short-circuits to `undefined`, the assertion lies to the compiler.

**Why**: The non-null assertion tells TypeScript "trust me, this is not null" — but the optional chain exists precisely because it might be. The result is a runtime `TypeError` that the type system was supposed to prevent.

```typescript
// BAD
const street = user?.address?.street!;
console.log(street.toUpperCase()); // runtime crash if address is undefined
```

```typescript
// GOOD
const street = user?.address?.street;
if (street) {
  console.log(street.toUpperCase());
}
```

## Anti-pattern: Truthiness Filtering Removes Valid Falsy Values
**Severity**: warn

Using `.filter(Boolean)` or `.filter(x => !!x)` to remove nullish values also removes `0`, `""`, and `false` — legitimate values in many domains.

**Why**: AI-generated code uses truthiness filtering as a shorthand for null removal. In arrays of numbers this silently drops zeros; in arrays of strings it drops empty strings. The data loss is invisible until it causes incorrect calculations or missing entries.

```typescript
// BAD
const scores: (number | null)[] = [0, 10, null, 5, 0, null];
const valid = scores.filter(Boolean); // [10, 5] — zeros are gone
```

```typescript
// GOOD
const scores: (number | null)[] = [0, 10, null, 5, 0, null];
const valid = scores.filter((s): s is number => s !== null); // [0, 10, 5, 0]
```

## Anti-pattern: typeof null Returns "object"
**Severity**: warn

`typeof null === "object"` is a well-known JavaScript specification quirk. Code that uses `typeof x === "object"` to validate an object will incorrectly accept `null`.

**Why**: AI frequently generates `typeof` checks for runtime type narrowing and forgets the null edge case. This leads to `null` being treated as a valid object, causing property access crashes downstream.

```typescript
// BAD
function processConfig(config: unknown) {
  if (typeof config === "object") {
    return Object.keys(config); // TypeError if config is null
  }
}
```

```typescript
// GOOD
function processConfig(config: unknown) {
  if (typeof config === "object" && config !== null) {
    return Object.keys(config);
  }
}
```

## Anti-pattern: Missing Exhaustive Check in Switch
**Severity**: error

A `switch` on a discriminated union that lacks a `default` exhaustiveness check will silently skip new variants added in the future. The code compiles but does nothing for unhandled cases.

**Why**: Discriminated unions grow over time. Without an exhaustive check, adding a new variant compiles successfully but falls through silently at runtime. A `never` assertion in the default branch turns this into a compile-time error.

```typescript
// BAD
type Shape = { kind: "circle"; radius: number } | { kind: "square"; side: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    // "square" case missing — returns undefined silently
  }
}
```

```typescript
// GOOD
function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "square":
      return shape.side ** 2;
    default: {
      const _exhaustive: never = shape;
      throw new Error(`Unhandled shape: ${JSON.stringify(_exhaustive)}`);
    }
  }
}
```

## Anti-pattern: Import Type Used as Value
**Severity**: warn

Importing a type without the `type` keyword includes it in the runtime bundle. Conversely, using `import type` and then referencing the import as a value (e.g., in `instanceof`) causes a runtime error because the import is erased.

**Why**: TypeScript erases `import type` declarations at compile time. Code that mixes type-only and value imports confuses bundlers, causes runtime `ReferenceError`s, and bloats bundles with unnecessary imports.

```typescript
// BAD
import type { ValidationError } from "./errors";

function isValidationError(err: unknown): boolean {
  return err instanceof ValidationError; // runtime error — erased import
}
```

```typescript
// GOOD
import { ValidationError } from "./errors";

function isValidationError(err: unknown): boolean {
  return err instanceof ValidationError;
}
```

## Best Practice: Use readonly for Immutable Properties
**Severity**: info

Properties that should not change after construction should be marked `readonly`. This prevents accidental mutation and communicates intent.

**Why**: Without `readonly`, nothing prevents a consumer from reassigning a property that was meant to be set once. The mutation may not cause an immediate bug but corrupts assumptions elsewhere in the codebase.

```typescript
// BAD
interface Config {
  apiUrl: string;
  maxRetries: number;
}

const config: Config = { apiUrl: "https://api.example.com", maxRetries: 3 };
config.maxRetries = -1; // no error — silently corrupts config
```

```typescript
// GOOD
interface Config {
  readonly apiUrl: string;
  readonly maxRetries: number;
}

const config: Config = { apiUrl: "https://api.example.com", maxRetries: 3 };
config.maxRetries = -1; // compile-time error
```

## Best Practice: Prefer unknown Over any for External Data
**Severity**: warn

When accepting data from external boundaries (API responses, JSON parsing, user input), use `unknown` instead of `any`. This forces callers to validate the data before using it.

**Why**: `any` silently bypasses all type checks, meaning malformed external data flows unchecked into business logic. `unknown` requires explicit narrowing, ensuring validation happens before the data is used.

```typescript
// BAD
function handleWebhook(payload: any) {
  db.save(payload.event.id, payload.event.data); // no validation
}
```

```typescript
// GOOD
function handleWebhook(payload: unknown) {
  if (!isWebhookPayload(payload)) {
    throw new Error("Invalid webhook payload");
  }
  db.save(payload.event.id, payload.event.data);
}

function isWebhookPayload(data: unknown): data is WebhookPayload {
  return (
    typeof data === "object" &&
    data !== null &&
    "event" in data &&
    typeof (data as Record<string, unknown>).event === "object"
  );
}
```

## Best Practice: Use Type Guards Over Type Assertions
**Severity**: warn

Type assertions (`as SomeType`) tell the compiler to trust you without any runtime check. Type guards (`is SomeType`) perform actual validation and narrow the type safely.

**Why**: Type assertions are lies you tell the compiler. If the data does not actually match the asserted type, the mismatch only surfaces as a confusing runtime error far from the assertion site. Type guards catch the mismatch at the boundary.

```typescript
// BAD
function getUser(data: unknown): User {
  return data as User; // no runtime validation — could be anything
}
```

```typescript
// GOOD
function isUser(data: unknown): data is User {
  return (
    typeof data === "object" &&
    data !== null &&
    "id" in data &&
    "name" in data &&
    typeof (data as Record<string, unknown>).id === "string" &&
    typeof (data as Record<string, unknown>).name === "string"
  );
}

function getUser(data: unknown): User {
  if (!isUser(data)) {
    throw new Error("Invalid user data");
  }
  return data;
}
```

## Idiomatic: Use Optional Chaining Over Nested Checks
**Severity**: info

Deeply nested property access should use optional chaining (`?.`) instead of verbose null-check chains. This is more concise and less error-prone.

**Why**: Nested `&&` chains are verbose, fragile, and easy to get wrong. Optional chaining is a language feature designed for this exact purpose and reads more clearly.

```typescript
// BAD
const city =
  user && user.address && user.address.city ? user.address.city : undefined;
```

```typescript
// GOOD
const city = user?.address?.city;
```

## Idiomatic: Use Nullish Coalescing Over Logical OR for Defaults
**Severity**: info

Use `??` (nullish coalescing) instead of `||` (logical OR) when providing default values. `||` triggers on any falsy value (`0`, `""`, `false`), while `??` triggers only on `null` and `undefined`.

**Why**: Using `||` for defaults silently replaces legitimate falsy values. A timeout of `0` becomes the default timeout; an empty string becomes the default string. `??` preserves intentional falsy values.

```typescript
// BAD
function getTimeout(options: { timeout?: number }) {
  const timeout = options.timeout || 5000; // timeout of 0 becomes 5000
  return timeout;
}
```

```typescript
// GOOD
function getTimeout(options: { timeout?: number }) {
  const timeout = options.timeout ?? 5000; // timeout of 0 is preserved
  return timeout;
}
```

## Idiomatic: Use as const for Literal Types
**Severity**: info

Use `as const` assertions to preserve literal types in object and array declarations instead of getting widened types like `string` or `number`.

**Why**: Without `as const`, TypeScript widens literals to their base type. This prevents using the value where a literal type is expected and defeats discriminated union narrowing. `as const` preserves the exact literal types.

```typescript
// BAD
const ROLES = {
  ADMIN: "admin",
  USER: "user",
  GUEST: "guest",
}; // type: { ADMIN: string; USER: string; GUEST: string }

function checkRole(role: "admin" | "user" | "guest") { /* ... */ }
checkRole(ROLES.ADMIN); // error: string is not assignable to "admin" | "user" | "guest"
```

```typescript
// GOOD
const ROLES = {
  ADMIN: "admin",
  USER: "user",
  GUEST: "guest",
} as const; // type: { readonly ADMIN: "admin"; readonly USER: "user"; readonly GUEST: "guest" }

function checkRole(role: "admin" | "user" | "guest") { /* ... */ }
checkRole(ROLES.ADMIN); // works — ROLES.ADMIN is type "admin"
```

## Performance: Avoid enum at Runtime
**Severity**: info

Using TypeScript `enum` declarations instead of `const enum` or union types. Regular enums generate runtime JavaScript objects with reverse mappings, adding bundle size and indirection. AI agents default to `enum` because it looks like other languages' enums.

**Why**: TypeScript enums compile to IIFE objects with bidirectional string-to-number mappings. This adds runtime overhead and bundle size. Union types (`"admin" | "user"`) are zero-cost at runtime — they exist only at compile time. `const enum` inlines values but has limitations with `--isolatedModules`.

```typescript
// BAD
enum Status {
  Active = "active",
  Inactive = "inactive",
  Pending = "pending",
}
// Compiles to: var Status; (function(Status) { ... })(Status || (Status = {}));

function isActive(status: Status): boolean {
  return status === Status.Active;
}
```

```typescript
// GOOD
type Status = "active" | "inactive" | "pending";

function isActive(status: Status): boolean {
  return status === "active";
}
// Zero runtime cost — Status is erased at compile time
```

## Security: Validate External Data at Runtime, Not Just Compile-Time
**Severity**: error

TypeScript types are erased at compile time. Casting API responses or user input to a TypeScript interface provides zero runtime safety. External data must be validated at runtime using a schema library or manual checks.

**Why**: Type erasure means `as ApiResponse` does not check anything at runtime. Malformed data passes through unchecked, causing downstream crashes or data corruption. This is the TypeScript equivalent of trusting user input.

```typescript
// BAD
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return data as User; // no runtime validation — trusting the network
}
```

```typescript
// GOOD
import { z } from "zod";

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data: unknown = await response.json();
  return UserSchema.parse(data); // throws on invalid data
}
```

## Anti-pattern: Async Function Without Try-Catch or .catch()
**Severity**: warn

An async function that calls other async operations without any error handling lets exceptions propagate as unhandled promise rejections, potentially crashing the process.

**Why**: AI-generated async code often handles only the happy path. Without try-catch or `.catch()`, any thrown error becomes an unhandled rejection. In Node.js, unhandled rejections terminate the process by default.

```typescript
// BAD
async function syncData() {
  const users = await fetchUsers();
  const orders = await fetchOrders();
  await mergeRecords(users, orders);
  // if any call throws, the rejection is unhandled
}

// caller does not catch either
syncData();
```

```typescript
// GOOD
async function syncData() {
  try {
    const users = await fetchUsers();
    const orders = await fetchOrders();
    await mergeRecords(users, orders);
  } catch (error) {
    logger.error("Data sync failed", { error });
    throw error; // re-throw for caller to handle
  }
}

// caller handles errors
syncData().catch((err) => process.exit(1));
```

## Anti-pattern: Using delete Operator on Object Properties
**Severity**: warn

The `delete` operator removes a property from an object, which changes the object's hidden class in V8 and triggers a deoptimization from fast (monomorphic) to slow (dictionary) mode.

**Why**: V8 optimizes objects into C-struct-like representations (hidden classes). `delete` forces a transition to a hash-map representation, degrading property access performance by 10-100x for that object and any objects sharing the same hidden class chain.

```typescript
// BAD
function sanitizeUser(user: Record<string, unknown>) {
  delete user.password;
  delete user.ssn;
  return user;
}
```

```typescript
// GOOD
function sanitizeUser(user: Record<string, unknown>) {
  const { password, ssn, ...sanitized } = user;
  return sanitized;
}
```

## Best Practice: Use Discriminated Unions Over Optional Fields
**Severity**: info

When a type has mutually exclusive states, use a discriminated union with a `kind` or `type` tag instead of a flat interface with many optional fields. This makes impossible states unrepresentable.

**Why**: Optional fields allow combinations that make no semantic sense (e.g., both `error` and `data` present, or neither). Discriminated unions force each state to carry exactly the fields it needs, and TypeScript's control flow analysis narrows them automatically.

```typescript
// BAD
interface ApiResult {
  status: "success" | "error" | "loading";
  data?: UserData;
  error?: string;
  retryAfter?: number;
}

function handle(result: ApiResult) {
  if (result.status === "success") {
    console.log(result.data!.name); // forced non-null assertion
  }
}
```

```typescript
// GOOD
type ApiResult =
  | { status: "loading" }
  | { status: "success"; data: UserData }
  | { status: "error"; error: string; retryAfter?: number };

function handle(result: ApiResult) {
  if (result.status === "success") {
    console.log(result.data.name); // narrowed automatically — no assertion needed
  }
}
```
