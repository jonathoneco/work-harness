# Spec C02: Framework Packs (React, Next.js)

**Component**: C02 — Framework packs
**Phase**: 2 (Content Packs)
**Status**: complete
**Dependencies**: Spec 00 (entry format standard), Spec C04 (framework discovery directive)

---

## Overview and Scope

Creates from-scratch framework packs for React and Next.js, targeting anti-patterns that AI coding assistants frequently produce in these frameworks. These are discovered via `stack.framework` and `stack.frontend` from `harness.yaml`, using the directives added in C04.

**What this does**:
- Creates `references/react-anti-patterns.md` (12-15 entries)
- Creates `references/nextjs-anti-patterns.md` (12-15 entries)

**What this does NOT do**:
- Create packs for other frameworks (gin, django, etc. -- deferred to futures)
- Modify `code-quality.md` (done in C04)
- Create language packs (done in C01)

---

## Implementation Steps

### Step 1: Create React Anti-Patterns Pack

Create `claude/skills/code-quality/references/react-anti-patterns.md`.

Content focuses on what AI gets wrong when generating React code: incorrect hook usage, unnecessary re-renders, stale closures, and JSX anti-patterns.

**Required entries** (minimum 12, target 15):

| # | Category | Rule Name | Severity | Focus |
|---|----------|-----------|----------|-------|
| 1 | Anti-pattern | Hooks Called Conditionally | error | Rules of Hooks |
| 2 | Anti-pattern | Missing Dependency Array in useEffect | error | Stale closure bugs |
| 3 | Anti-pattern | Object/Array Literal in JSX Props | warn | Unnecessary re-renders |
| 4 | Anti-pattern | State Updates in Render | error | Infinite render loop |
| 5 | Anti-pattern | useEffect as Event Handler | warn | Misuse of effects |
| 6 | Anti-pattern | Index as Key in Dynamic Lists | warn | React reconciliation |
| 7 | Best Practice | Use useCallback for Memoized Callbacks | info | Performance |
| 8 | Best Practice | Lift State Up Instead of Prop Drilling | info | Component design |
| 9 | Idiomatic | Use Fragment Instead of Wrapping div | info | Clean DOM |
| 10 | Idiomatic | Prefer Controlled Components for Forms | info | React forms |
| 11 | Performance | Avoid Inline Functions in Render for Lists | warn | Re-render cost |
| 12 | Security | Avoid dangerouslySetInnerHTML with User Input | error | XSS risk |
| 13 | Anti-pattern | Stale State in Async Callbacks | warn | Closure capture |
| 14 | Anti-pattern | Direct DOM Manipulation | warn | Bypasses React |
| 15 | Best Practice | Use Error Boundaries for Resilient UIs | info | Production resilience |

**Acceptance Criteria**:
- AC-C02-1.1: File exists at `claude/skills/code-quality/references/react-anti-patterns.md`
- AC-C02-1.2: Contains at least 12 entries
- AC-C02-1.3: Every entry follows Spec 00 Contract 1 format
- AC-C02-1.4: Code examples use `tsx` or `jsx` as the code fence language
- AC-C02-1.5: BAD/GOOD comments use `// BAD` and `// GOOD`
- AC-C02-1.6: Entries are React-specific (not general JavaScript/TypeScript -- those belong in C01)

### Step 2: Create Next.js Anti-Patterns Pack

Create `claude/skills/code-quality/references/nextjs-anti-patterns.md`.

Content focuses on Next.js-specific mistakes: SSR/SSG confusion, App Router vs Pages Router mistakes, server component misuse, and data fetching anti-patterns.

**Required entries** (minimum 12, target 15):

| # | Category | Rule Name | Severity | Focus |
|---|----------|-----------|----------|-------|
| 1 | Anti-pattern | Client Hooks in Server Components | error | App Router fundamentals |
| 2 | Anti-pattern | fetch() Without Caching Strategy | warn | Next.js caching model |
| 3 | Anti-pattern | window/document Access in Server Context | error | SSR/SSG |
| 4 | Anti-pattern | Large Client Bundle from Server Data | warn | Performance |
| 5 | Anti-pattern | Missing loading.tsx or error.tsx | warn | App Router conventions |
| 6 | Anti-pattern | Using getServerSideProps in App Router | error | Pages vs App Router |
| 7 | Best Practice | Use Server Components by Default | info | App Router design |
| 8 | Best Practice | Use next/image for Image Optimization | info | Built-in optimization |
| 9 | Best Practice | Use next/link for Client-Side Navigation | info | Client-side routing |
| 10 | Idiomatic | Colocate Route Handlers with Pages | info | App Router convention |
| 11 | Performance | Avoid Dynamic Rendering When Static Suffices | warn | Build-time optimization |
| 12 | Security | Validate API Route Inputs Server-Side | error | Server trust boundary |
| 13 | Anti-pattern | Mixing use client with Server-Only Imports | error | Module boundary |
| 14 | Anti-pattern | Prop Drilling Through Layout to Pages | warn | App Router context |
| 15 | Performance | Use Streaming SSR for Long Operations | info | Next.js 14+ |

**Acceptance Criteria**:
- AC-C02-2.1: File exists at `claude/skills/code-quality/references/nextjs-anti-patterns.md`
- AC-C02-2.2: Contains at least 12 entries
- AC-C02-2.3: Every entry follows Spec 00 Contract 1 format
- AC-C02-2.4: Code examples use `tsx` or `typescript` as the code fence language
- AC-C02-2.5: Entries are Next.js-specific (not general React -- those belong in the React pack)
- AC-C02-2.6: Entries distinguish between App Router (primary) and Pages Router where relevant

---

## Interface Contracts

### Exposes

- **react-anti-patterns.md**: Discovered via `stack.framework: react` or `stack.frontend: react`
- **nextjs-anti-patterns.md**: Discovered via `stack.framework: nextjs` or `stack.frontend: nextjs`

### Consumes

- **Spec 00 Contract 1**: Entry format standard
- **Spec C04**: Framework/frontend discovery directives in `code-quality.md`
- **Spec 00 Contract 4**: File placement conventions

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/code-quality/references/react-anti-patterns.md` | React pack (~150-250 lines) |
| Create | `claude/skills/code-quality/references/nextjs-anti-patterns.md` | Next.js pack (~150-250 lines) |

**Total**: 2 new files, 0 modified files

---

## Testing Strategy

1. **Format compliance**: Same as C01 -- verify all entries follow Spec 00 Contract 1

2. **Framework specificity**: Verify React entries don't overlap with TypeScript pack (C01) and Next.js entries don't overlap with React pack. Each pack should be additive, not duplicative.

3. **Discovery integration**: Set `stack.framework: react` in a test harness.yaml and verify the framework directive in `code-quality.md` would load `react-anti-patterns.md`. Repeat with `stack.frontend: nextjs`.

4. **App Router accuracy**: For Next.js pack, verify entries reference App Router patterns (current) rather than deprecated Pages Router patterns. Where Pages Router is referenced, it should be in the context of "don't use this in App Router."
