---
meta:
  stack: ["react"]
  version: 1
  last_reviewed: 2026-03-25
---

# React Anti-Patterns

These rules target React-specific anti-patterns that AI coding assistants frequently produce. Every rule has a concrete BAD/GOOD example with JSX/TSX code. General JavaScript/TypeScript anti-patterns belong in the TypeScript pack; universal rules (error swallowing, fail-closed, etc.) are in `code-quality.md`.

## Anti-pattern: Hooks Called Conditionally
**Severity**: error

Hooks must be called in the same order on every render. Placing hooks inside conditionals, loops, or early returns violates the Rules of Hooks and causes React to associate hook state with the wrong call index.

**Why**: React relies on call order to track hook state. Conditional hooks cause state corruption -- one component's `useState` reads another's value, producing impossible UI states and crashes that are extremely difficult to diagnose.

```tsx
// BAD
function UserProfile({ userId }: { userId: string | null }) {
  if (!userId) {
    return <p>Please log in</p>;
  }
  // Hook called after early return -- violates Rules of Hooks
  const [user, setUser] = useState<User | null>(null);
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);
  return <p>{user?.name}</p>;
}
```

```tsx
// GOOD
function UserProfile({ userId }: { userId: string | null }) {
  const [user, setUser] = useState<User | null>(null);
  useEffect(() => {
    if (userId) {
      fetchUser(userId).then(setUser);
    }
  }, [userId]);
  if (!userId) {
    return <p>Please log in</p>;
  }
  return <p>{user?.name}</p>;
}
```

## Anti-pattern: Missing Dependency Array in useEffect
**Severity**: error

Every value from the component scope that the effect reads must appear in the dependency array. Omitting dependencies creates stale closures where the effect captures an outdated value and never re-runs when it changes.

**Why**: Stale closures are the most common source of "works on first render, breaks on update" bugs in React. The effect keeps referencing the initial value of the omitted dependency, producing silently wrong behavior that passes manual testing.

```tsx
// BAD
function SearchResults({ query }: { query: string }) {
  const [results, setResults] = useState<Item[]>([]);
  useEffect(() => {
    // query is used but missing from deps -- effect never re-runs on query change
    fetchResults(query).then(setResults);
  }, []);
  return <ResultList items={results} />;
}
```

```tsx
// GOOD
function SearchResults({ query }: { query: string }) {
  const [results, setResults] = useState<Item[]>([]);
  useEffect(() => {
    let cancelled = false;
    fetchResults(query).then((data) => {
      if (!cancelled) setResults(data);
    });
    return () => { cancelled = true; };
  }, [query]);
  return <ResultList items={results} />;
}
```

## Anti-pattern: Object/Array Literal in JSX Props
**Severity**: warn

Passing object or array literals directly in JSX creates a new reference on every render. Child components that rely on referential equality (via `React.memo`, `useMemo`, or dependency arrays) will re-render unnecessarily.

**Why**: Every render allocates a new object, breaking memoization boundaries. In lists or frequently-updating parents, this causes cascading re-renders that degrade performance with no visible code bug.

```tsx
// BAD
function Dashboard() {
  return (
    <Chart
      options={{ responsive: true, animation: false }}
      data={[1, 2, 3]}
    />
  );
}
```

```tsx
// GOOD
const CHART_OPTIONS = { responsive: true, animation: false } as const;
const DEFAULT_DATA = [1, 2, 3];

function Dashboard() {
  return <Chart options={CHART_OPTIONS} data={DEFAULT_DATA} />;
}
```

## Anti-pattern: State Updates in Render
**Severity**: error

Calling `setState` directly in the render body (outside of event handlers, effects, or callbacks) triggers a re-render during rendering, causing an infinite loop that crashes the application.

**Why**: React re-renders when state changes. If rendering itself changes state, React enters an unbounded render cycle. The app freezes or crashes with "Too many re-renders" -- an error that is obvious in development but can slip through if the setState is conditional.

```tsx
// BAD
function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = useState(0);
  // setState during render -- infinite loop
  setCount(initialCount);
  return <p>{count}</p>;
}
```

```tsx
// GOOD
function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = useState(initialCount);
  useEffect(() => {
    setCount(initialCount);
  }, [initialCount]);
  return <p>{count}</p>;
}
```

## Anti-pattern: useEffect as Event Handler
**Severity**: warn

Using `useEffect` to respond to user actions (clicks, form submissions, navigation) instead of handling them directly in event handlers. Effects are for synchronization with external systems, not for reacting to discrete user events.

**Why**: Effect-based event handling introduces unnecessary render cycles, race conditions with cleanup, and makes the data flow harder to follow. The action happens on the next render instead of at the point of interaction, creating timing bugs and stale state.

```tsx
// BAD
function SubmitButton({ formData }: { formData: FormData }) {
  const [submitted, setSubmitted] = useState(false);
  useEffect(() => {
    if (submitted) {
      postForm(formData);
      setSubmitted(false);
    }
  }, [submitted, formData]);
  return <button onClick={() => setSubmitted(true)}>Submit</button>;
}
```

```tsx
// GOOD
function SubmitButton({ formData }: { formData: FormData }) {
  const handleSubmit = () => {
    postForm(formData);
  };
  return <button onClick={handleSubmit}>Submit</button>;
}
```

## Anti-pattern: Index as Key in Dynamic Lists
**Severity**: warn

Using the array index as the `key` prop in lists where items can be reordered, inserted, or deleted. React uses keys to match elements across renders; index-based keys cause incorrect element reuse after mutations.

**Why**: When items shift position, their index changes but the key stays the same for that position. React reuses the wrong DOM element and component state -- input values appear in the wrong row, animations fire on the wrong item, and uncontrolled components display stale data.

```tsx
// BAD
function TodoList({ todos }: { todos: Todo[] }) {
  return (
    <ul>
      {todos.map((todo, index) => (
        // Index key breaks when items are reordered or deleted
        <li key={index}>
          <input defaultValue={todo.text} />
        </li>
      ))}
    </ul>
  );
}
```

```tsx
// GOOD
function TodoList({ todos }: { todos: Todo[] }) {
  return (
    <ul>
      {todos.map((todo) => (
        <li key={todo.id}>
          <input defaultValue={todo.text} />
        </li>
      ))}
    </ul>
  );
}
```

## Best Practice: Use useCallback for Memoized Callbacks
**Severity**: info

When passing callbacks to memoized child components, wrap them in `useCallback` to maintain referential stability. Without it, `React.memo` on the child is ineffective because the callback is a new function reference every render.

**Why**: A `React.memo` wrapper is pointless if the parent passes a new function on every render. `useCallback` preserves the reference until its dependencies change, allowing memoized children to skip re-rendering.

```tsx
// BAD
function Parent({ items }: { items: Item[] }) {
  // New function reference every render -- defeats React.memo on Child
  const handleClick = (id: string) => {
    console.log("clicked", id);
  };
  return items.map((item) => (
    <MemoizedChild key={item.id} onClick={handleClick} item={item} />
  ));
}
```

```tsx
// GOOD
function Parent({ items }: { items: Item[] }) {
  const handleClick = useCallback((id: string) => {
    console.log("clicked", id);
  }, []);
  return items.map((item) => (
    <MemoizedChild key={item.id} onClick={handleClick} item={item} />
  ));
}
```

## Best Practice: Lift State Up Instead of Prop Drilling
**Severity**: info

When multiple sibling components need access to the same state, lift it to their nearest common parent rather than passing props through intermediate components that do not use them.

**Why**: Prop drilling through three or more levels creates tight coupling between components that have no interest in the data. Changes to the state shape require updating every intermediate component. Lifting state or using context reduces this coupling.

```tsx
// BAD
function App() {
  const [user, setUser] = useState<User | null>(null);
  return <Layout user={user} setUser={setUser} />;
}
function Layout({ user, setUser }: Props) {
  // Layout doesn't use user/setUser -- just passes them through
  return <Sidebar user={user} setUser={setUser} />;
}
function Sidebar({ user, setUser }: Props) {
  return <UserMenu user={user} setUser={setUser} />;
}
```

```tsx
// GOOD
const UserContext = createContext<UserContextType | null>(null);

function App() {
  const [user, setUser] = useState<User | null>(null);
  return (
    <UserContext.Provider value={{ user, setUser }}>
      <Layout />
    </UserContext.Provider>
  );
}
function Layout() {
  return <Sidebar />;
}
function Sidebar() {
  return <UserMenu />;
}
function UserMenu() {
  const { user, setUser } = useContext(UserContext)!;
  return <p>{user?.name}</p>;
}
```

## Idiomatic: Use Fragment Instead of Wrapping div
**Severity**: info

When a component needs to return multiple elements, use `<>...</>` (Fragment) instead of wrapping them in a `<div>`. Unnecessary wrapper divs pollute the DOM and can break CSS layouts that depend on direct parent-child relationships.

**Why**: Extra wrapper divs interfere with flex/grid layouts, table structures, and accessibility semantics. Fragments group elements without adding DOM nodes, preserving the intended layout hierarchy.

```tsx
// BAD
function UserInfo({ user }: { user: User }) {
  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}
```

```tsx
// GOOD
function UserInfo({ user }: { user: User }) {
  return (
    <>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </>
  );
}
```

## Idiomatic: Prefer Controlled Components for Forms
**Severity**: info

Use controlled components (state-driven value) for form inputs instead of uncontrolled components (DOM-driven value with refs). Controlled components keep React as the single source of truth for form data.

**Why**: Uncontrolled components make it difficult to validate on change, conditionally disable submit, or reset forms programmatically. The form state lives in the DOM instead of React state, creating a second source of truth that can diverge.

```tsx
// BAD
function LoginForm() {
  const emailRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Must read DOM to get values -- no live validation possible
    login(emailRef.current!.value, passwordRef.current!.value);
  };
  return (
    <form onSubmit={handleSubmit}>
      <input ref={emailRef} type="email" />
      <input ref={passwordRef} type="password" />
      <button type="submit">Log in</button>
    </form>
  );
}
```

```tsx
// GOOD
function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const isValid = email.includes("@") && password.length >= 8;
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login(email, password);
  };
  return (
    <form onSubmit={handleSubmit}>
      <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
      <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button type="submit" disabled={!isValid}>Log in</button>
    </form>
  );
}
```

## Performance: Avoid Inline Functions in Render for Lists
**Severity**: warn

Defining callback functions inline within `map()` iterations creates a new function for every item on every render. For large lists, this defeats memoization and increases garbage collection pressure.

**Why**: Each render creates N new function objects for N list items. Memoized children cannot skip re-rendering because every callback is a new reference. The cost scales linearly with list size and render frequency.

```tsx
// BAD
function ItemList({ items }: { items: Item[] }) {
  return (
    <ul>
      {items.map((item) => (
        <MemoizedItem
          key={item.id}
          item={item}
          // New function per item per render
          onDelete={() => deleteItem(item.id)}
        />
      ))}
    </ul>
  );
}
```

```tsx
// GOOD
function ItemList({ items }: { items: Item[] }) {
  const handleDelete = useCallback((id: string) => {
    deleteItem(id);
  }, []);
  return (
    <ul>
      {items.map((item) => (
        <MemoizedItem
          key={item.id}
          item={item}
          onDelete={handleDelete}
        />
      ))}
    </ul>
  );
}
// MemoizedItem calls onDelete(item.id) internally
```

## Security: Avoid dangerouslySetInnerHTML with User Input
**Severity**: error

Never pass user-provided or unsanitized content to `dangerouslySetInnerHTML`. This bypasses React's built-in XSS protection and injects raw HTML directly into the DOM.

**Why**: React escapes text content by default, preventing XSS. `dangerouslySetInnerHTML` disables this protection entirely. If the HTML contains `<script>` tags or event handler attributes from user input, the attacker's code executes in every visitor's browser.

```tsx
// BAD
function Comment({ body }: { body: string }) {
  // User-supplied body injected as raw HTML -- XSS vulnerability
  return <div dangerouslySetInnerHTML={{ __html: body }} />;
}
```

```tsx
// GOOD
import DOMPurify from "dompurify";

function Comment({ body }: { body: string }) {
  const sanitized = DOMPurify.sanitize(body);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

## Anti-pattern: Stale State in Async Callbacks
**Severity**: warn

Referencing state variables directly inside `setTimeout`, `setInterval`, or promise chains captures the value at the time the closure was created. Subsequent state updates are invisible to the callback.

**Why**: JavaScript closures capture variables by value for primitives. An async callback scheduled during render N reads render N's state value, even if the user has since triggered render N+5. This produces off-by-many bugs in counters, polling, and debounced operations.

```tsx
// BAD
function Timer() {
  const [count, setCount] = useState(0);
  const handleStart = () => {
    setInterval(() => {
      // count is always 0 -- captured at closure creation time
      setCount(count + 1);
    }, 1000);
  };
  return <button onClick={handleStart}>Start ({count})</button>;
}
```

```tsx
// GOOD
function Timer() {
  const [count, setCount] = useState(0);
  const handleStart = () => {
    setInterval(() => {
      // Functional update reads current state, not stale closure value
      setCount((prev) => prev + 1);
    }, 1000);
  };
  return <button onClick={handleStart}>Start ({count})</button>;
}
```

## Anti-pattern: Direct DOM Manipulation
**Severity**: warn

Using `document.getElementById`, `document.querySelector`, or other direct DOM APIs to modify elements that React manages. This bypasses React's virtual DOM and causes the real DOM to diverge from React's internal representation.

**Why**: React assumes it owns the DOM subtree it renders. Direct mutations are overwritten on the next render, or worse, they persist and conflict with React's reconciliation -- producing visual glitches, lost event handlers, or crashes during hydration.

```tsx
// BAD
function Highlight({ id }: { id: string }) {
  useEffect(() => {
    // Direct DOM manipulation -- React doesn't know about this
    const el = document.getElementById(id);
    if (el) {
      el.style.backgroundColor = "yellow";
      el.classList.add("highlighted");
    }
  }, [id]);
  return <div id={id}>Content</div>;
}
```

```tsx
// GOOD
function Highlight({ isActive }: { isActive: boolean }) {
  return (
    <div
      style={{ backgroundColor: isActive ? "yellow" : undefined }}
      className={isActive ? "highlighted" : undefined}
    >
      Content
    </div>
  );
}
```

## Best Practice: Use Error Boundaries for Resilient UIs
**Severity**: info

Wrap component subtrees in error boundaries to catch rendering errors and display a fallback UI instead of crashing the entire application. Without error boundaries, a single component error unmounts the whole React tree.

**Why**: In production, any component can throw during render (bad data shape, null access, third-party library error). Without an error boundary, the user sees a white screen with no recovery path. Error boundaries isolate failures to the affected subtree and allow the rest of the app to remain functional.

```tsx
// BAD
function App() {
  return (
    <main>
      <Header />
      {/* If Dashboard throws, the entire app crashes */}
      <Dashboard />
      <Footer />
    </main>
  );
}
```

```tsx
// GOOD
class DashboardErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };
  static getDerivedStateFromError() {
    return { hasError: true };
  }
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    reportError(error, info);
  }
  render() {
    if (this.state.hasError) {
      return <p>Something went wrong loading the dashboard.</p>;
    }
    return this.props.children;
  }
}

function App() {
  return (
    <main>
      <Header />
      <DashboardErrorBoundary>
        <Dashboard />
      </DashboardErrorBoundary>
      <Footer />
    </main>
  );
}
```
