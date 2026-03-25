---
meta:
  stack: ["nextjs"]
  version: 1
  last_reviewed: 2026-03-25
---

# Next.js Anti-Patterns

These rules target mistakes AI coding assistants frequently make when generating Next.js code, particularly with the App Router (Next.js 13+). Every rule has a concrete BAD/GOOD example. Rules here are Next.js-specific -- general React anti-patterns belong in `react-anti-patterns.md` and universal rules are in `code-quality.md`.

## Anti-pattern: Client Hooks in Server Components
**Severity**: error

Using React hooks like `useState`, `useEffect`, or `useContext` inside a Server Component. Server Components run on the server and do not have access to React's client-side hook system.

**Why**: Server Components cannot maintain client state or run effects. The build will fail with "You're importing a component that needs useState" or similar errors, but AI-generated code frequently omits the `"use client"` directive when hooks are present.

```tsx
// BAD
// app/dashboard/page.tsx — Server Component by default
import { useState } from "react";

export default function DashboardPage() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

```tsx
// GOOD
// app/dashboard/counter.tsx — explicitly marked as Client Component
"use client";

import { useState } from "react";

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

## Anti-pattern: fetch() Without Caching Strategy
**Severity**: warn

Calling `fetch()` in Server Components without specifying a caching strategy. Next.js extends `fetch` with caching options, and the defaults have changed across versions, leading to unpredictable behavior.

**Why**: Without an explicit `cache` or `next.revalidate` option, the caching behavior depends on the Next.js version and surrounding context. This causes inconsistent data freshness between development and production, and between static and dynamic rendering.

```typescript
// BAD
// app/products/page.tsx
async function getProducts() {
  const res = await fetch("https://api.example.com/products");
  return res.json();
}
```

```typescript
// GOOD
// app/products/page.tsx — explicit revalidation strategy
async function getProducts() {
  const res = await fetch("https://api.example.com/products", {
    next: { revalidate: 3600 },
  });
  return res.json();
}
```

## Anti-pattern: window/document Access in Server Context
**Severity**: error

Accessing `window`, `document`, `localStorage`, or other browser-only APIs in Server Components, server-side utilities, or at module scope in files that run during SSR.

**Why**: Server Components execute on the server where browser globals do not exist. This causes `ReferenceError: window is not defined` at build time or runtime, crashing the render.

```tsx
// BAD
// app/layout.tsx — Server Component
export default function RootLayout({ children }: { children: React.ReactNode }) {
  const theme = localStorage.getItem("theme") ?? "light";
  return (
    <html data-theme={theme}>
      <body>{children}</body>
    </html>
  );
}
```

```tsx
// GOOD
// app/layout.tsx — Server Component delegates to client
import { ThemeProvider } from "./theme-provider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}

// app/theme-provider.tsx — Client Component reads localStorage
"use client";

import { useEffect, useState } from "react";

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState("light");

  useEffect(() => {
    setTheme(localStorage.getItem("theme") ?? "light");
  }, []);

  return <div data-theme={theme}>{children}</div>;
}
```

## Anti-pattern: Large Client Bundle from Server Data
**Severity**: warn

Passing large server-fetched datasets directly as props from a Server Component to a Client Component. The entire dataset gets serialized into the HTML payload and downloaded by the browser.

**Why**: Server Component props are serialized into the RSC payload. Passing a full dataset (e.g., 1000 rows) to a Client Component that only renders 10 at a time bloats the initial page load and wastes bandwidth.

```tsx
// BAD
// app/users/page.tsx — Server Component
import { UserTable } from "./user-table";

export default async function UsersPage() {
  const allUsers = await db.query("SELECT * FROM users"); // 10,000 rows
  return <UserTable users={allUsers} />;
}
```

```tsx
// GOOD
// app/users/page.tsx — Server Component sends only the first page
import { UserTable } from "./user-table";

export default async function UsersPage() {
  const firstPage = await db.query("SELECT * FROM users LIMIT 25 OFFSET 0");
  const totalCount = await db.query("SELECT COUNT(*) FROM users");
  return <UserTable initialUsers={firstPage} totalCount={totalCount} />;
}
```

## Anti-pattern: Missing loading.tsx or error.tsx
**Severity**: warn

Omitting `loading.tsx` and `error.tsx` convention files in route segments that perform async data fetching. Without these, users see no feedback during loading and unhandled errors crash the entire page.

**Why**: Next.js App Router uses `loading.tsx` to show instant loading UI via React Suspense and `error.tsx` as an error boundary. Without them, slow fetches show a blank page and thrown errors propagate up to the nearest error boundary (or the root, crashing the app).

```tsx
// BAD
// app/dashboard/page.tsx — async page with no loading or error handling
export default async function DashboardPage() {
  const data = await fetchDashboardData(); // slow call, no loading UI
  return <Dashboard data={data} />;
}
// No loading.tsx or error.tsx in app/dashboard/
```

```tsx
// GOOD
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />;
}

// app/dashboard/error.tsx
"use client";

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong loading the dashboard.</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}

// app/dashboard/page.tsx
export default async function DashboardPage() {
  const data = await fetchDashboardData();
  return <Dashboard data={data} />;
}
```

## Anti-pattern: Using getServerSideProps in App Router
**Severity**: error

Using Pages Router data-fetching functions (`getServerSideProps`, `getStaticProps`, `getStaticPaths`) inside the App Router (`app/` directory). These functions do not exist in the App Router.

**Why**: The App Router replaced Pages Router data-fetching with async Server Components, `generateStaticParams()`, and the `fetch()` API with caching. Using Pages Router patterns in App Router silently does nothing -- the functions are never called and the component receives no data.

```tsx
// BAD
// app/blog/[slug]/page.tsx — Pages Router pattern in App Router
export async function getStaticProps({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);
  return { props: { post } };
}

export async function getStaticPaths() {
  const slugs = await getAllSlugs();
  return { paths: slugs.map((s) => ({ params: { slug: s } })), fallback: false };
}

export default function BlogPost({ post }: { post: Post }) {
  return <article>{post.content}</article>;
}
```

```tsx
// GOOD
// app/blog/[slug]/page.tsx — App Router pattern
export async function generateStaticParams() {
  const slugs = await getAllSlugs();
  return slugs.map((slug) => ({ slug }));
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);
  return <article>{post.content}</article>;
}
```

## Best Practice: Use Server Components by Default
**Severity**: info

Adding `"use client"` to components that do not need client-side interactivity. Server Components should be the default in the App Router -- only add `"use client"` when the component genuinely needs hooks, event handlers, or browser APIs.

**Why**: Unnecessary `"use client"` directives push components (and their dependencies) into the client JavaScript bundle, increasing bundle size and hydration cost. Server Components render on the server with zero client JS.

```tsx
// BAD
// app/components/user-profile.tsx
"use client"; // unnecessary — this component has no interactivity

interface Props {
  name: string;
  email: string;
}

export function UserProfile({ name, email }: Props) {
  return (
    <div>
      <h2>{name}</h2>
      <p>{email}</p>
    </div>
  );
}
```

```tsx
// GOOD
// app/components/user-profile.tsx — Server Component (no directive needed)
interface Props {
  name: string;
  email: string;
}

export function UserProfile({ name, email }: Props) {
  return (
    <div>
      <h2>{name}</h2>
      <p>{email}</p>
    </div>
  );
}
```

## Best Practice: Use next/image for Image Optimization
**Severity**: info

Using raw `<img>` tags instead of the `next/image` component. Next.js provides automatic image optimization including lazy loading, responsive sizing, and format conversion.

**Why**: Raw `<img>` tags skip Next.js image optimization, serving unoptimized images at full resolution regardless of viewport size. This hurts Core Web Vitals (LCP) and wastes bandwidth, especially on mobile.

```tsx
// BAD
export function Hero() {
  return <img src="/hero.png" alt="Hero image" width={1200} height={600} />;
}
```

```tsx
// GOOD
import Image from "next/image";

export function Hero() {
  return <Image src="/hero.png" alt="Hero image" width={1200} height={600} priority />;
}
```

## Best Practice: Use next/link for Client-Side Navigation
**Severity**: info

Using raw `<a>` tags for internal navigation instead of the `next/link` component. The `Link` component enables client-side navigation with prefetching, avoiding full page reloads.

**Why**: Raw `<a>` tags trigger a full page reload, discarding client-side state, React tree, and cached data. `next/link` performs client-side transitions and prefetches linked routes on hover/viewport, making navigation near-instant.

```tsx
// BAD
export function Nav() {
  return (
    <nav>
      <a href="/about">About</a>
      <a href="/blog">Blog</a>
    </nav>
  );
}
```

```tsx
// GOOD
import Link from "next/link";

export function Nav() {
  return (
    <nav>
      <Link href="/about">About</Link>
      <Link href="/blog">Blog</Link>
    </nav>
  );
}
```

## Idiomatic: Colocate Route Handlers with Pages
**Severity**: info

Placing API route handlers in a centralized `app/api/` directory when they only serve a single page. App Router supports colocating `route.ts` files alongside `page.tsx` in the same route segment.

**Why**: Centralizing all API routes in `app/api/` creates artificial distance between related code. Colocating route handlers with their consuming pages makes the relationship explicit and simplifies maintenance.

```typescript
// BAD
// app/api/dashboard/stats/route.ts — far from the page that uses it
import { NextResponse } from "next/server";

export async function GET() {
  const stats = await getDashboardStats();
  return NextResponse.json(stats);
}

// app/dashboard/page.tsx — fetches from distant API route
export default async function DashboardPage() {
  const res = await fetch("/api/dashboard/stats");
  const stats = await res.json();
  return <StatsDisplay stats={stats} />;
}
```

```typescript
// GOOD
// app/dashboard/page.tsx — Server Component fetches directly, no API route needed
export default async function DashboardPage() {
  const stats = await getDashboardStats();
  return <StatsDisplay stats={stats} />;
}

// If a client needs the data, colocate the route handler:
// app/dashboard/stats/route.ts
import { NextResponse } from "next/server";

export async function GET() {
  const stats = await getDashboardStats();
  return NextResponse.json(stats);
}
```

## Performance: Avoid Dynamic Rendering When Static Suffices
**Severity**: warn

Using `cookies()`, `headers()`, or `searchParams` in pages that do not need per-request data, forcing dynamic rendering on every request instead of being statically generated at build time.

**Why**: Dynamic rendering opts the page out of static generation, meaning every request hits the server. For pages with content that changes infrequently, this wastes server resources and increases time-to-first-byte.

```typescript
// BAD
// app/about/page.tsx — reads cookies unnecessarily, forcing dynamic render
import { cookies } from "next/headers";

export default async function AboutPage() {
  const cookieStore = cookies(); // forces dynamic rendering
  const theme = cookieStore.get("theme")?.value;
  return (
    <div data-theme={theme}>
      <h1>About Us</h1>
      <p>We build software.</p>
    </div>
  );
}
```

```typescript
// GOOD
// app/about/page.tsx — static content, no dynamic APIs
export default function AboutPage() {
  return (
    <div>
      <h1>About Us</h1>
      <p>We build software.</p>
    </div>
  );
}

// Theme is handled by a Client Component (e.g., ThemeProvider) that reads
// cookies on the client side, keeping this page statically generated.
```

## Security: Validate API Route Inputs Server-Side
**Severity**: error

Trusting client-provided data in Route Handlers or Server Actions without validation. API routes in Next.js run on the server and are the trust boundary -- all inputs must be validated and sanitized.

**Why**: Route Handlers are publicly accessible HTTP endpoints. Without server-side validation, attackers can send malformed data, bypass client-side checks, and exploit injection vulnerabilities. Client-side validation is for UX only.

```typescript
// BAD
// app/api/users/route.ts — trusts client input directly
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const body = await request.json();
  // No validation — body.email could be anything, body.role could be "admin"
  await db.insert("users", body);
  return NextResponse.json({ success: true });
}
```

```typescript
// GOOD
// app/api/users/route.ts — validates and sanitizes input
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  // role is not accepted from client — assigned server-side
});

export async function POST(request: NextRequest) {
  const parsed = CreateUserSchema.safeParse(await request.json());
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  await db.insert("users", { ...parsed.data, role: "user" });
  return NextResponse.json({ success: true }, { status: 201 });
}
```

## Anti-pattern: Mixing use client with Server-Only Imports
**Severity**: error

Importing server-only modules (database clients, `fs`, Node.js crypto, `server-only` marked packages) in files marked with `"use client"`. This breaks the module boundary between server and client.

**Why**: Client Components are bundled for the browser. Importing server-only code into a Client Component either fails at build time (if using the `server-only` package) or ships server secrets and Node.js APIs to the browser, causing runtime crashes or security leaks.

```tsx
// BAD
// app/components/admin-panel.tsx
"use client";

import { db } from "@/lib/db"; // server-only database client
import { useState } from "react";

export function AdminPanel() {
  const [users, setUsers] = useState([]);

  async function loadUsers() {
    const result = await db.query("SELECT * FROM users"); // crashes in browser
    setUsers(result.rows);
  }

  return <button onClick={loadUsers}>Load Users</button>;
}
```

```tsx
// GOOD
// app/components/admin-panel.tsx
"use client";

import { useState } from "react";

export function AdminPanel() {
  const [users, setUsers] = useState([]);

  async function loadUsers() {
    const res = await fetch("/api/admin/users");
    setUsers(await res.json());
  }

  return <button onClick={loadUsers}>Load Users</button>;
}

// app/api/admin/users/route.ts — server-only code stays on the server
import { db } from "@/lib/db";
import { NextResponse } from "next/server";

export async function GET() {
  const result = await db.query("SELECT id, name, email FROM users");
  return NextResponse.json(result.rows);
}
```

## Anti-pattern: Prop Drilling Through Layout to Pages
**Severity**: warn

Passing data from a layout to its child pages via props or React Context that requires `"use client"` on the layout. Layouts in App Router cannot pass props to their `children` -- children are rendered independently.

**Why**: In the App Router, `children` in a layout is an opaque React node, not a component you can pass props to. Attempting to prop-drill through layouts leads to convoluted workarounds that break streaming, caching, and partial rendering.

```tsx
// BAD
// app/dashboard/layout.tsx — trying to pass data to children
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCurrentUser();
  // Cannot pass user to children — children is an opaque ReactNode
  return (
    <div>
      <Sidebar user={user} />
      {/* This does NOT pass user to the page */}
      {React.cloneElement(children as React.ReactElement, { user })}
    </div>
  );
}
```

```tsx
// GOOD
// app/dashboard/layout.tsx — layout handles its own concerns
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCurrentUser();
  return (
    <div>
      <Sidebar user={user} />
      {children}
    </div>
  );
}

// app/dashboard/page.tsx — page fetches its own data independently
export default async function DashboardPage() {
  const user = await getCurrentUser(); // deduplicated by Next.js request memoization
  return <DashboardContent user={user} />;
}
```

## Performance: Use Streaming SSR for Long Operations
**Severity**: info

Blocking the entire page render on a single slow data fetch instead of using React Suspense boundaries to stream content progressively. Next.js App Router supports streaming out of the box.

**Why**: Without streaming, the entire page waits for the slowest data source before any HTML is sent to the client. Streaming with Suspense boundaries lets fast sections render immediately while slow sections show fallback UI, improving perceived performance and time-to-first-byte.

```tsx
// BAD
// app/dashboard/page.tsx — entire page blocked on slowest fetch
export default async function DashboardPage() {
  const stats = await getStats();           // 100ms
  const activity = await getRecentActivity(); // 3000ms — blocks everything
  const alerts = await getAlerts();          // 200ms

  return (
    <div>
      <StatsPanel stats={stats} />
      <ActivityFeed activity={activity} />
      <AlertsList alerts={alerts} />
    </div>
  );
}
```

```tsx
// GOOD
// app/dashboard/page.tsx — streams sections independently
import { Suspense } from "react";

export default async function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />
      </Suspense>
      <Suspense fallback={<ActivitySkeleton />}>
        <ActivityFeed />
      </Suspense>
      <Suspense fallback={<AlertsSkeleton />}>
        <AlertsList />
      </Suspense>
    </div>
  );
}

// Each component is an async Server Component that fetches its own data
async function StatsPanel() {
  const stats = await getStats();
  return <StatsPanelView stats={stats} />;
}

async function ActivityFeed() {
  const activity = await getRecentActivity(); // slow, but doesn't block others
  return <ActivityFeedView activity={activity} />;
}

async function AlertsList() {
  const alerts = await getAlerts();
  return <AlertsListView alerts={alerts} />;
}
```
