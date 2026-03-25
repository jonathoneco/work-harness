# Skills Spec, MCP Go SDK & Specification Roadmap

Research addendum covering Anthropic's Skills API, the official MCP Go SDK,
the MCP specification roadmap, and reference server implementations.

Sources examined:
- `anthropics/anthropic-cookbook` (skills directory, custom_skills, skill_utils.py)
- `modelcontextprotocol/go-sdk` v1.4.1 (server.go, client.go, tool.go, transport.go, content.go, resource.go, prompt.go, AGENTS.md, docs/, examples/)
- `modelcontextprotocol/specification` (schema/2025-11-25/schema.ts, lifecycle, transports, tools, tasks specs)
- `modelcontextprotocol/servers` (memory, everything, filesystem, sequential-thinking, fetch, git, time)
- MCP official documentation (modelcontextprotocol.io): roadmap, MCP Apps, Triggers/Events charter, SEPs

---

## 1. Official Skills Specification

### Important Caveat

There is **no canonical open-source SKILL.md specification** in the way we assumed.
Anthropic's "Skills" are an **API-level feature** (beta), not a Claude Code / agent
framework feature. The Skills system documented in `anthropics/anthropic-cookbook/skills/`
is:

1. A **server-side API** accessed via `client.beta.skills.*` endpoints
2. Requires three beta headers: `code-execution-2025-08-25`, `files-api-2025-04-14`,
   `skills-2025-10-02`
3. Skills are **uploaded directory bundles** containing a `SKILL.md` file plus optional
   `scripts/` and `resources/` directories
4. They execute in a **sandboxed code execution environment** on Anthropic's servers

This is fundamentally different from our local markdown-based skills system.

### Format & Frontmatter

The Anthropic API Skills `SKILL.md` format uses minimal YAML frontmatter:

```yaml
---
name: analyzing-financial-statements
description: This skill calculates key financial ratios...
---
```

**Supported frontmatter fields** (from cookbook examples):
- `name` (string, required) -- skill identifier, kebab-case
- `description` (string, required) -- what the skill does

That's it. The frontmatter is intentionally minimal. All behavioral instructions go in the
markdown body.

### Skill Directory Structure

```
my_skill/
  SKILL.md        # Required: instructions + frontmatter
  scripts/        # Optional: executable code (Python)
  resources/      # Optional: templates, sample data
```

**Size constraint**: Maximum 8MB total for the skill directory (validated by
`validate_skill_directory()` in the SDK).

### Built-in Skills

Four built-in skills ship with the API:
- **excel** (xlsx): spreadsheets with formulas/charts
- **powerpoint** (pptx): presentations
- **pdf**: formatted documents
- **word** (docx): rich text documents

These are activated by tool name (e.g., `code_execution_20250825`) and load
on-demand to optimize token usage -- "progressive disclosure."

### Activation Patterns

Skills in the API are activated **explicitly per-request** via the `container` parameter
in message requests, specifying skill IDs and version numbers. There is no auto-activation
or always-on concept at the API level.

The cookbook mentions that "Skills load only when needed, optimizing token usage" --
suggesting the API dynamically injects skill instructions into context only when the
model's tool use triggers them.

### Tool Restrictions

No evidence of tool restriction features (skills that limit which tools the agent can
use) in the API-level Skills system. Skills **provide** tools via code execution; they
don't restrict other tools.

### Versioning

Skills support explicit versioning via the API:
- `create_skill_version(client, skill_id, skill_path)` -- add new version
- `list_skill_versions(client, skill_id)` -- enumerate versions
- `get_skill_version(client, skill_id, version)` -- fetch specific version

### Comparison to Our Format

| Feature | Anthropic API Skills | Our Work Harness Skills |
|---------|---------------------|----------------------|
| **Format** | SKILL.md + scripts/ + resources/ | Single .md file with YAML frontmatter |
| **Frontmatter** | `name`, `description` only | `name`, `description`, `meta.stack`, `meta.version`, `meta.last_reviewed` |
| **Execution** | Server-side sandboxed code exec | Local context injection (markdown instructions) |
| **Activation** | Explicit per-request via API | On-demand via commands, implicit via context |
| **Versioning** | API-managed versions | `meta.version` field (manual) |
| **Tool restrictions** | None | None |
| **Size** | 8MB max (directory bundle) | No formal limit |
| **Propagation** | N/A | Via `skills: [name]` frontmatter to subagents |
| **References** | Scripts and resource files in bundle | Separate reference .md files in subdirectories |

**Assessment**: Our skill format and the API Skills are solving fundamentally different
problems. The API Skills are server-side code execution packages. Our skills are
agent-context knowledge packages. They are not competing formats -- they're complementary.

Our format is well-suited for its purpose. The `meta` fields we use (stack, version,
last_reviewed) are reasonable extensions beyond the minimal API spec. We are not
"non-conformant" because there is no local-agent skill specification to conform to.

**Notable from the MCP Roadmap**: The MCP roadmap's "On the Horizon" section mentions
"investigating a Skills primitive for composed capabilities" as a future extension track.
This suggests a formal MCP-level Skills specification may eventually emerge, but it does
not exist yet.

---

## 2. MCP Go SDK

### Repository Stats

- **Repo**: `modelcontextprotocol/go-sdk`
- **Latest release**: v1.4.1 (2026-03-13)
- **Stars**: 4,226 | **Forks**: 385 | **Open issues**: 51
- **Created**: 2025-04-23
- **Go version**: 1.25.0
- **License**: Apache 2.0 (new contributions) / MIT (existing)
- **MCP spec support**: 2025-11-25 (latest), 2025-06-18, 2025-03-26, 2024-11-05

### API Surface

The SDK is organized into four importable packages:

| Package | Purpose |
|---------|---------|
| `mcp` | Primary APIs for clients and servers |
| `jsonrpc` | JSON-RPC 2.0 for custom transports |
| `auth` | OAuth primitives |
| `oauthex` | OAuth extensions (Protected Resource Metadata) |

#### Core Types

```go
// Server
type Server struct { ... }
type ServerOptions struct {
    Instructions    string
    Logger          *slog.Logger
    PageSize        int              // default 1000
    KeepAlive       time.Duration
    Capabilities    *ServerCapabilities
    SchemaCache     *SchemaCache
    // Handlers
    InitializedHandler          func(...)
    RootsListChangedHandler     func(...)
    ProgressNotificationHandler func(...)
    CompletionHandler           func(...)
    SubscribeHandler            func(...)
    UnsubscribeHandler          func(...)
}

// Client
type Client struct { ... }
type ClientOptions struct {
    Logger                      *slog.Logger
    KeepAlive                   time.Duration
    Capabilities                *ClientCapabilities
    CreateMessageHandler        func(...)  // sampling
    CreateMessageWithToolsHandler func(...) // sampling with tools
    ElicitationHandler          func(...)
    // Notification handlers
    ToolListChangedHandler      func(...)
    PromptListChangedHandler    func(...)
    ResourceListChangedHandler  func(...)
    ResourceUpdatedHandler      func(...)
    LoggingMessageHandler       func(...)
    ProgressNotificationHandler func(...)
}
```

#### Session Types

```go
type ServerSession struct { ... }
// Methods: ID(), Ping(), ListRoots(), CreateMessage(),
//          CreateMessageWithTools(), Elicit(), Log(),
//          NotifyProgress(), InitializeParams(), Close(), Wait()

type ClientSession struct { ... }
// Methods: Close(), Wait(), Ping(), ListPrompts(), GetPrompt(),
//          ListTools(), CallTool(), SetLoggingLevel(),
//          ListResources(), ListResourceTemplates(), ReadResource(),
//          Complete(), Subscribe(), Unsubscribe(), NotifyProgress()
// Iterators: Tools(), Resources(), ResourceTemplates(), Prompts()
```

### Transport Support

| Transport | Type | Description |
|-----------|------|-------------|
| `StdioTransport` | Built-in | stdin/stdout, newline-delimited JSON |
| `IOTransport` | Built-in | Arbitrary io.ReadCloser/io.WriteCloser |
| `InMemoryTransport` | Built-in | In-process testing |
| `LoggingTransport` | Wrapper | Wraps any transport, writes RPC logs |
| `CommandTransport` | Client-side | Launches server as subprocess |
| Streamable HTTP | In `examples/` | Available via http sub-package |

The `Transport` interface is minimal:
```go
type Transport interface {
    Connect(ctx context.Context) (Connection, error)
}

type Connection interface {
    Read(context.Context) (jsonrpc.Message, error)
    Write(context.Context, jsonrpc.Message) error
    Close() error
    SessionID() string
}
```

### Tool Definition Patterns

**Low-level handler** (manual schema, manual marshaling):
```go
type ToolHandler func(context.Context, *CallToolRequest) (*CallToolResult, error)
server.AddTool(&Tool{Name: "foo", Description: "..."}, handler)
```

**Typed generic handler** (recommended -- auto schema, auto validation):
```go
type Input struct {
    Name string `json:"name" jsonschema:"the name to greet"`
}
type Output struct {
    Greeting string `json:"greeting"`
}

func SayHi(ctx context.Context, req *CallToolRequest, input Input) (
    *CallToolResult, Output, error,
) {
    return nil, Output{Greeting: "Hi " + input.Name}, nil
}

mcp.AddTool(server, &mcp.Tool{Name: "greet", Description: "say hi"}, SayHi)
```

The generic `AddTool[In, Out]` automatically:
- Generates JSON Schema from Go struct tags
- Validates inputs against schema
- Marshals/unmarshals input and output
- Handles error wrapping

**Tool name constraints**: 1-128 chars, alphanumeric + underscore/hyphen/period.

### Resource and Prompt Support

**Resources**:
```go
server.AddResource(&Resource{URI: "file:///data.json", ...}, handler)
server.AddResourceTemplate(&ResourceTemplate{URITemplate: "file:///{path}"}, handler)
// ResourceHandler: func(ctx, *ReadResourceRequest) (*ReadResourceResult, error)
```

**Prompts**:
```go
server.AddPrompt(&Prompt{Name: "review", ...}, handler)
// PromptHandler: func(ctx, *GetPromptRequest) (*GetPromptResult, error)
```

Both support pagination (default page size 1000), list-changed notifications, and
dynamic add/remove at runtime.

### Content Types

Seven content types implement the `Content` interface:
- `TextContent` -- text with annotations
- `ImageContent` -- base64-encoded image with MIME type
- `AudioContent` -- base64-encoded audio with MIME type
- `ResourceLink` -- reference to a resource by URI
- `EmbeddedResource` -- inline resource content
- `ToolUseContent` -- tool invocation (sampling messages only)
- `ToolResultContent` -- tool result (sampling messages only)

### Middleware Support

```go
server.AddSendingMiddleware(middleware ...Middleware)   // outgoing
server.AddReceivingMiddleware(middleware ...Middleware)  // incoming
```

Middleware wraps the JSON-RPC method handler, enabling logging, auth checks,
rate limiting, etc.

### Maturity Assessment

**Strengths**:
- Official SDK, actively maintained (4 releases in 6 weeks)
- Supports all four MCP spec versions including latest 2025-11-25
- Strong type safety with generic tool handlers
- Comprehensive transport support including HTTP
- Rich example directory (15+ examples: hello, memory, everything, sse, middleware,
  rate-limiting, auth, distributed, elicitation, proxy, sequential-thinking, etc.)
- Conformance test suite against official spec
- `slog` integration for structured logging
- Session management with keepalive
- Resource subscriptions and change notifications

**Weaknesses/Gaps**:
- Go 1.25 requirement (bleeding edge)
- Client-side OAuth still "experimental"
- `rough_edges.md` documents known API limitations
- 51 open issues

**Verdict**: Production-ready for building custom MCP servers. The typed tool handler
pattern is excellent. The conformance test suite is a strong signal of quality. This is
the right SDK for our Go harness.

### Building Custom Servers

What a custom MCP server for our harness would look like:

```go
package main

import (
    "context"
    "log"
    "github.com/modelcontextprotocol/go-sdk/mcp"
)

type IssueInput struct {
    Title    string `json:"title" jsonschema:"issue title"`
    Type     string `json:"type" jsonschema:"task, bug, feature, or epic"`
    Priority int    `json:"priority" jsonschema:"0=critical through 4=backlog"`
}

type IssueOutput struct {
    ID     string `json:"id"`
    Status string `json:"status"`
}

func CreateIssue(ctx context.Context, req *mcp.CallToolRequest, input IssueInput) (
    *mcp.CallToolResult, IssueOutput, error,
) {
    // Call beans CLI or directly manipulate beans storage
    id := createBeansIssue(input)
    return nil, IssueOutput{ID: id, Status: "open"}, nil
}

func main() {
    server := mcp.NewServer(
        &mcp.Implementation{Name: "harness-server", Version: "v0.1.0"},
        &mcp.ServerOptions{Instructions: "Harness state and issue tracking"},
    )

    mcp.AddTool(server, &mcp.Tool{
        Name:        "create_issue",
        Description: "Create a new beans issue",
    }, CreateIssue)

    // Add resources for reading harness state
    server.AddResource(&mcp.Resource{
        URI:         "harness://state/active-tasks",
        Description: "List of active work tasks",
    }, activeTasksHandler)

    if err := server.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
        log.Fatal(err)
    }
}
```

Key patterns for custom servers:
1. Use `AddTool[In, Out]` generic for type-safe tools with auto-generated schemas
2. Use `StdioTransport` for Claude Code integration (same as existing MCP servers)
3. Resources for read-only state (harness state, issue lists, cost data)
4. Tools for write operations (create/update issues, checkpoint, etc.)
5. Middleware for logging and error standardization

---

## 3. MCP Specification Roadmap

### Current Spec: 2025-11-25

The latest released specification (2025-11-25) introduced several major features:

#### Tasks Primitive (Experimental)

Tasks are **durable state machines** enabling "call-now/fetch-later" workflows.
This is the most significant new primitive.

**Key concepts**:
- **Requestor/Receiver model**: Either client or server can initiate tasks
- **Requestor-driven polling**: Requestors control polling and orchestration
- **Task states**: `working` -> `input_required` -> `completed`/`failed`/`cancelled`
- **TTL-based lifecycle**: Tasks expire after a configurable duration

**Capability negotiation**:
```json
{
  "capabilities": {
    "tasks": {
      "list": {},
      "cancel": {},
      "requests": {
        "tools": { "call": {} }
      }
    }
  }
}
```

**Tool-level granularity** via `execution.taskSupport`:
- `"forbidden"` (default) -- tool cannot be invoked as task
- `"optional"` -- client may invoke as task or normal request
- `"required"` -- client must invoke as task

**Protocol flow**:
1. Client sends `tools/call` with `task` field (includes optional `ttl`)
2. Server returns `CreateTaskResult` with `taskId`, `status: "working"`, `pollInterval`
3. Client polls via `tasks/get` respecting `pollInterval`
4. When complete, client calls `tasks/result` to get actual tool output
5. Task deleted after TTL expiration

**`input_required` status**: When a task-augmented tool call needs user input (e.g.,
elicitation), the task moves to `input_required`. The client calls `tasks/result` which
blocks and delivers the elicitation request. After the user responds, the task moves back
to `working`.

**Security**: Task IDs must be bound to authorization context when available. Without
context-binding, use cryptographically secure IDs with sufficient entropy and shorter TTLs.

#### Elicitation

Servers can request structured input from users via forms (`mode: "form"`) or URLs
(`mode: "url"`). Returns `action: "accept" | "decline" | "cancel"` with optional content.

#### Sampling with Tools

Servers can request LLM completions that include tool use capability, via
`CreateMessageWithToolsParams`.

#### Tool Annotations

```typescript
interface ToolAnnotations {
    title?: string;
    readOnlyHint?: boolean;
    destructiveHint?: boolean;
    idempotentHint?: boolean;
    openWorldHint?: boolean;
}
```

#### Output Schemas

Tools can declare `outputSchema` for structured results (JSON Schema), enabling
`structuredContent` in responses alongside unstructured `content`.

#### Content Types Expanded

- `ResourceLink` -- reference to a resource without inlining it
- `ToolUseContent` and `ToolResultContent` -- for sampling messages

### MCP Apps (Extension, Final Status)

MCP Apps (SEP-1865) is a **finalized extension** enabling servers to deliver interactive
HTML interfaces rendered in sandboxed iframes within the host application.

**Architecture**:
- Tools declare UI via `_meta.ui.resourceUri` pointing to `ui://` resources
- Host preloads HTML resource before tool execution
- Rendered in sandboxed iframe with postMessage communication
- Bidirectional JSON-RPC protocol (MCP dialect) between app and host
- CSP controls for external resource loading

**Key capabilities**:
- Interactive data visualization, forms, dashboards
- Bidirectional data flow (app calls tools, host pushes data)
- Integration with host's connected capabilities
- Security via iframe sandboxing

**Supported by**: Claude, Claude Desktop, VS Code GitHub Copilot, Goose, Postman, MCPJam

**Relevance to our harness**: Low for terminal-native workflows. MCP Apps are designed
for GUI hosts. However, if we ever build a web dashboard for harness state visualization,
this pattern would be relevant.

### Server Cards

Mentioned in the roadmap under "Transport Evolution and Scalability":
- A standard for exposing structured server metadata via `.well-known` URL
- Enables browsers, crawlers, and registries to discover server capabilities without
  connecting
- Owned by a dedicated **Server Card WG**
- Coordinates with broader industry AI-catalog effort

**Status**: Working Group formed, active development. No released spec yet.

### Triggers/Events

A **Working Group** was chartered on 2026-03-24 (yesterday!) to define how MCP servers
proactively notify clients of state changes.

**Mission**: Define a standardized callback mechanism (webhooks or similar) for
server-initiated notifications with defined ordering guarantees across all transports.

**Scope**:
- SEPs defining trigger/callback mechanism, subscription lifecycle, delivery semantics
- Reference implementations in Tier-1 SDKs
- Cross-cutting with Tasks (webhook-style task completion notifications)

**Target**: SEP RFC by end of April 2026, reference implementations to follow.

**Status**: Ideating phase, very early. Currently clients learn about server-side state
changes by polling or holding SSE connections open. This WG will define push-based
alternatives.

### Roadmap Priority Areas (Updated 2026-03-05)

1. **Transport Evolution**: Stateless Streamable HTTP, horizontal scaling, session
   resumption, Server Cards
2. **Agent Communication**: Tasks primitive production hardening -- retry semantics,
   expiry policies, operational issues from production deployments
3. **Governance Maturation**: Contributor ladder, delegation model, charter templates
4. **Enterprise Readiness**: Audit trails, enterprise auth (SSO/SAML), gateway/proxy
   patterns, configuration portability

### On the Horizon (Lower Priority)

- **Triggers and Event-Driven Updates** (WG just chartered)
- **Result Type Improvements**: Streamed results, reference-based results
- **Security & Authorization**: DPoP, Workload Identity Federation
- **Extensions Ecosystem**: Maturing ext-auth, ext-apps; **investigating a Skills
  primitive for composed capabilities**

---

## 4. Reference Server Patterns

### Architecture Patterns

All seven reference servers in `modelcontextprotocol/servers` are TypeScript/Node.js
implementations using the official TS SDK. They demonstrate consistent patterns:

#### Tool Registration Pattern

```typescript
server.registerTool(
    "tool_name",
    {
        title: "Display Title",
        description: "What it does",
        inputSchema: ZodSchema,
        outputSchema: ZodSchema,     // optional
        annotations: {
            readOnlyHint: true,      // optional behavior hints
            destructiveHint: false,
        }
    },
    async (args) => {
        // Validate path / inputs
        const result = await doWork(args);
        return {
            content: [{ type: "text", text: JSON.stringify(result) }],
            structuredContent: { content: result }  // optional
        };
    }
);
```

#### Dual-Format Responses

Reference servers return both unstructured (`content` array with TextContent) and
structured (`structuredContent`) responses. This supports both text-based display and
programmatic consumption.

#### Security Patterns (Filesystem Server)

The filesystem server demonstrates best practices for security:
- **Path validation**: All operations go through `validatePath()` against allowed directories
- **Symlink resolution**: Resolve symlinks at startup to prevent path traversal
- **Dual path tracking**: Track both original and resolved paths for macOS `/tmp` -> `/private/tmp`
- **Graceful degradation**: Skip inaccessible directories with warnings, fail if none accessible
- **Dynamic roots**: Support runtime directory updates via `roots/list_changed` notifications

#### Resource Subscriptions (Everything Server)

The everything server demonstrates subscription patterns:
- Clients subscribe to resource URIs
- Server sends `notifications/resources/updated` when resources change
- Supports both individual resources and template-based resources

### Notable Implementations

#### Memory Server
- Knowledge graph stored in JSONL format
- Entities, Relations, Observations as graph primitives
- 8 tools: CRUD operations + search + read_graph
- Environment-configurable storage path (`MEMORY_FILE_PATH`)
- Backward-compatible migration from JSON to JSONL
- **Pattern we should follow**: This is almost exactly what a harness-state MCP server
  would look like

#### Sequential Thinking Server
- Single tool with dynamic thought count
- Supports branching analysis paths
- Returns both text content and structured JSON output
- **Pattern**: Good model for a "reasoning step" tool in our harness

#### Everything Server
- Comprehensive reference implementing ALL MCP features:
  - 18 tools (echo, sampling, elicitation, structured content, etc.)
  - Resources and resource templates
  - 4 prompt types (simple, with-args, completions, embedded-resource)
  - All three transports (stdio, SSE, streamable HTTP)
  - Conditional tool registration based on client capabilities
- **Pattern**: Good integration test reference

#### Filesystem Server
- 11 tools covering read/write/search/metadata operations
- `edit_file` with dry-run preview capability
- `read_media_file` with base64 encoding and MIME detection
- `directory_tree` with exclude patterns
- **Pattern**: Security-first design, tool annotations (readOnlyHint, destructiveHint)

---

## 5. Implications for Our Harness

### Adopt Now

1. **Build a beans/harness MCP server in Go** using the official SDK. The `mcp` package's
   typed tool handler pattern is excellent for our use case. Target tools:
   - `create_issue`, `update_issue`, `close_issue`, `list_issues`, `search_issues`
   - `get_task_state`, `list_active_tasks`, `checkpoint_task`
   - `get_cost_summary`, `track_cost` (if we add cost tracking)

2. **Use the memory server pattern** as architectural reference. Our harness state is
   essentially a knowledge graph (tasks, steps, findings, decisions). JSONL storage,
   entity-based CRUD, search tools.

3. **Add tool annotations** to any custom MCP tools: `readOnlyHint`, `destructiveHint`,
   `idempotentHint`. These are cheap to add and help model behavior.

4. **Use `structuredContent` alongside `content`** in tool responses for programmatic
   consumption.

5. **Our skill format is fine as-is**. There is no local-agent skill spec to conform to.
   Our `meta` extensions (stack, version, last_reviewed) are reasonable. The MCP roadmap
   hints at a future Skills primitive, but it doesn't exist yet.

### Prepare For

1. **Tasks primitive**: When Tasks matures from experimental, our harness could expose
   long-running operations (multi-step implementations, research phases) as tasks.
   The `input_required` state maps well to review gates. Don't build for this yet, but
   keep the architecture compatible.

2. **Triggers/Events**: The WG just chartered. When a push-based notification mechanism
   lands, our MCP server could notify Claude Code about state changes (new issues,
   completed tasks) instead of requiring polling. This is 3-6 months out minimum.

3. **Server Cards**: When `.well-known` discovery lands, we could make our harness
   server discoverable by any MCP client. Low priority but worth tracking.

4. **MCP-level Skills primitive**: The roadmap mentions "investigating a Skills primitive
   for composed capabilities" as an extension track. This could eventually replace or
   formalize our markdown-based skill system. Watch this space.

### Skip / Low Priority

1. **MCP Apps**: Terminal-native workflow means interactive HTML UIs are not relevant
   unless we build a web dashboard.

2. **Streamable HTTP transport**: StdioTransport is the right choice for local Claude Code
   integration. HTTP transport is for remote/multi-client servers.

3. **OAuth/auth extensions**: Our MCP servers are local, single-user. Auth adds complexity
   without benefit for our use case.

### Architecture Decision

**Recommended first MCP server**: A `harness-state` server exposing:
- **Resources**: `harness://tasks/{name}/state` (read task state),
  `harness://tasks/active` (list active tasks)
- **Tools**: `get_task_state`, `list_active_tasks`, `update_task_step`,
  `add_finding`, `checkpoint`
- **Transport**: StdioTransport (launched by Claude Code config)

This replaces ad-hoc file reads with a structured, typed interface and enables
better agent coordination. The Go SDK's typed handler pattern means we get
JSON Schema validation for free.

**Estimated effort**: 1-2 days for a minimal viable server with the Go SDK. The
API surface is clean and the examples are comprehensive.
