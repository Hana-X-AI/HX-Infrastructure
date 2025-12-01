# FastMCP Framework - Comprehensive Research Summary

**Research Date**: November 25, 2025
**Repository**: /home/agent0/HX-Infrastructure/hx-knowledge/repos/fastmcp-main
**Focus**: Production deployment patterns, architecture, and integration with Docling-MCP

---

## 1. FASTMCP ARCHITECTURE & DESIGN PHILOSOPHY

### 1.1 Core Philosophy
- **Primary Goal**: Fastest path from idea to production-ready MCP server
- **Approach**: High-level Pythonic interface built on official MCP SDK (mcp>=1.12.4)
- **Target Audience**: Python developers building MCP applications
- **Production Focus**: Enterprise auth, deployment tools, testing utilities, client libraries

**Confidence Level**: HIGH

### 1.2 Layered Architecture

```
FastMCP Server/Client Layer
    ↓
Component Management (ToolManager, ResourceManager, PromptManager, Middleware)
    ↓
Advanced Patterns (Composition, Proxying, OpenAPI Integration)
    ↓
Enterprise Features (OAuth2, Auth, Rate Limiting)
    ↓
Official MCP Protocol (mcp library)
```

### 1.3 Key Design Principles
1. **Decorator-Based Registration**: Simple `@mcp.tool`, `@mcp.resource`, `@mcp.prompt`
2. **Async-First**: Full async/await support throughout
3. **Type-Safe**: Pydantic for schema generation from type hints
4. **Transport Agnostic**: Same code works with stdio, HTTP, SSE, in-memory
5. **Composition**: Mount servers to create gateway patterns
6. **Testing-Friendly**: FastMCPTransport for in-memory testing

**Confidence Level**: HIGH

---

## 2. CORE SERVER PRIMITIVES

### 2.1 FastMCP Server Class

**Initialization**:
```python
mcp = FastMCP(
    name="ServerName",              # Required
    instructions="Description",     # Optional
    version="1.0.0",               # Semantic version
    auth=None,                     # AuthProvider or None
    middleware=[],                 # Middleware stack
    lifespan=None,                 # Async context manager
    dependencies=[],               # Python dependencies for deployment
    mask_error_details=False,      # Production error masking
    tool_serializer=None,          # Custom serializer
    include_tags=None,             # Filter by tags (whitelist)
    exclude_tags=None,             # Filter by tags (blacklist)
    on_duplicate_tools="warn",     # warn/error/replace/ignore
)
```

**Key Methods**:
- `@mcp.tool` - Register callable tools
- `@mcp.resource(uri)` - Register read-only resources
- `@mcp.prompt` - Register reusable prompts
- `await mcp.run()` - Run with specified transport
- `mcp.mount(server, prefix)` - Live-link sub-server composition
- `mcp.import_server(server, prefix)` - Static copy composition
- `mcp.as_proxy(target)` - Create proxy wrapper
- `mcp.from_openapi(spec, client)` - Generate from OpenAPI
- `mcp.from_fastapi(app, client)` - Generate from FastAPI
- `mcp.http_app()` - Create Starlette ASGI app
- `mcp.add_middleware()` - Add request/response middleware

**Confidence Level**: HIGH

### 2.2 Tool Registration

**Basic Pattern**:
```python
@mcp.tool
def tool_name(param: str) -> str:
    """Tool description."""
    return result

@mcp.tool
async def async_tool(url: str) -> dict:
    """Async tool."""
    async with httpx.AsyncClient() as client:
        return await client.get(url).json()
```

**Features**:
- Automatic JSON schema generation from type hints
- Docstring becomes tool description
- Sync and async functions supported
- Return types: str, dict, list, Image, Audio, bytes, custom classes
- Tags for categorization: `@mcp.tool(tags={"category"})`
- Enable/disable: `@mcp.tool(enabled=False)`
- Custom name/description: `@mcp.tool(name="custom", description="...")`
- Error handling with ToolError exceptions
- Custom serializers for non-JSON returns

**Confidence Level**: HIGH

### 2.3 Resource Management

**Static Resources**:
```python
@mcp.resource(uri="config://version")
def get_version() -> str:
    return "2.0.1"
```

**Dynamic Resource Templates** (parameterized):
```python
@mcp.resource(uri="users://{user_id}/profile")
def get_profile(user_id: int) -> dict:
    return database.get_user_profile(user_id)

# Client reads: "users://123/profile" → calls get_profile(user_id=123)
```

**File Resources**:
```python
from fastmcp.resources import FileResource

mcp.add_resource(FileResource(uri="file:///path/to/file.txt"))
mcp.add_resource(FileResource(uri="files://project/", path="/path/to/dir"))
```

**Features**:
- URI-based addressing with custom protocols
- Parameter extraction from URI templates with `{placeholders}`
- Sync and async support
- Tags and metadata
- Enable/disable functionality
- Auto-detection of MIME types for files

**Confidence Level**: HIGH

### 2.4 Prompt Management

**Basic Pattern**:
```python
@mcp.prompt
def summarize_request(text: str) -> str:
    """Generate a prompt asking for a summary."""
    return f"Please summarize:\n\n{text}"
```

**Advanced (Message Objects)**:
```python
from mcp.types import Message

@mcp.prompt
def multi_turn(topic: str) -> list[Message]:
    """Generate multi-turn conversation."""
    return [
        Message(role="system", content="You are helpful."),
        Message(role="user", content=f"Tell me about {topic}")
    ]
```

**Features**:
- String or Message return types
- Parameter extraction from prompt arguments
- Tags and metadata
- Enable/disable functionality

**Confidence Level**: HIGH

### 2.5 Context Object (Dependency Injection)

**Injection Pattern**:
```python
from fastmcp import Context

@mcp.tool
async def process(uri: str, ctx: Context):
    """Access MCP capabilities."""
    await ctx.info(f"Processing {uri}...")
    data = await ctx.read_resource(uri)
    summary = await ctx.sample(f"Summarize: {data.content[:500]}")
    await ctx.report_progress(50, "Halfway done")
    return summary.text
```

**Context Capabilities**:
- **Logging**: `ctx.info()`, `ctx.error()`, `ctx.warning()`, `ctx.debug()`, `ctx.critical()`
- **LLM Sampling**: `ctx.sample(messages, max_tokens)` - Request completions from client's LLM
- **Resource Access**: `ctx.read_resource(uri)` - Access server resources
- **Progress Reporting**: `ctx.report_progress(current, total, message)`
- **HTTP Requests**: `ctx.http_request(method, url, ...)` - Make HTTP requests via MCP
- **Session Info**: Access to session metadata and client capabilities

**Confidence Level**: HIGH

---

## 3. TRANSPORT LAYER ARCHITECTURE

### 3.1 Transport Types

**STDIO (Default)** - Best for local tools
```python
mcp.run(transport="stdio")  # Default
```
- Parent process communicates via stdin/stdout
- Low overhead
- No network overhead
- Best for: Local tools, Claude desktop, editor integrations

**Streamable HTTP** - Recommended for network deployments
```python
mcp.run(transport="http", host="0.0.0.0", port=8000, path="/mcp")
```
- MCP-optimized HTTP with streaming
- Stateful sessions
- Better performance than SSE
- Recommended for production

**SSE (Server-Sent Events)** - Legacy support
```python
mcp.run(transport="sse", host="127.0.0.1", port=8000)
```
- Unidirectional server → client streaming
- Lower performance than Streamable HTTP
- Compatible with existing SSE clients

**In-Memory** - For testing
```python
async with Client(server_instance) as client:
    # Direct in-process connection
```
- No process spawning
- No network overhead
- Perfect for unit tests

**Confidence Level**: HIGH

### 3.2 Transport Configuration

**HTTP/Streamable HTTP Specifics**:
```python
app = mcp.http_app(
    path="/mcp",                    # Endpoint path
    middleware=[],                  # ASGI middleware list
    transport="http"                # "http", "sse", "streamable-http"
)

# Or run directly
mcp.run(
    transport="http",
    host="127.0.0.1",              # Bind address
    port=8000,                      # Bind port
    path="/mcp",                    # Endpoint path
    uvicorn_config={                # Additional Uvicorn settings
        "timeout_graceful_shutdown": 0,
        "lifespan": "on"
    },
    middleware=[],                  # ASGI middleware
    stateless_http=False            # Stateless mode option
)
```

**Returned ASGI App** (`StarletteWithLifespan`):
- Can be integrated with FastAPI, Starlette, other ASGI frameworks
- Lifespan context manager for startup/shutdown
- Middleware integration support

**Confidence Level**: HIGH

### 3.3 Client Transports

**StreamableHttpTransport**:
```python
from fastmcp.client import StreamableHttpTransport

transport = StreamableHttpTransport(
    url="http://localhost:8000/mcp",
    headers={"X-Custom": "value"},
    auth=None  # or OAuth/BearerAuth
)

async with Client(transport) as client:
    tools = await client.list_tools()
```

**SSETransport**:
```python
from fastmcp.client import SSETransport

transport = SSETransport(
    url="http://example.com/sse",
    headers={},
    auth=None,
    sse_read_timeout=300  # seconds
)
```

**StdioTransport** (for local scripts):
```python
from fastmcp.client import StdioTransport, PythonStdioTransport

transport = PythonStdioTransport(script_path="server.py")
# or generic
transport = StdioTransport(command="python", args=["server.py"])
```

**FastMCPTransport** (in-memory, testing):
```python
from fastmcp.client import FastMCPTransport

server = FastMCP("Test Server")
# ... define server tools ...

transport = FastMCPTransport(server)
async with Client(transport) as client:
    result = await client.call_tool("tool_name", {})
```

**Auto-Detection**:
```python
# FastMCP auto-detects transport from argument type
client = Client("http://localhost:8000/mcp")        # → StreamableHttpTransport
client = Client("./server.py")                      # → PythonStdioTransport
client = Client(server_instance)                    # → FastMCPTransport
client = Client({"mcpServers": {...}})             # → MCPConfigTransport
```

**Confidence Level**: HIGH

---

## 4. SERVER COMPOSITION PATTERNS

### 4.1 Mounting Servers (Live Link)

**Pattern**:
```python
gateway = FastMCP("Gateway")

# Mount sub-servers with prefixes
gateway.mount(server=weather_app, prefix="weather")
gateway.mount(server=news_app, prefix="news")

# Tools prefixed: weather_get_forecast, news_get_headlines
# Resources: weather://weather/forecast, news://headlines
```

**Characteristics**:
- **Live Link**: Changes to sub-servers reflect immediately
- **Shared State**: Sub-servers maintain independent state
- **Dynamic**: Can mount/unmount at runtime
- **Use Case**: Microservice composition, plugin architectures

**Confidence Level**: HIGH

### 4.2 Importing Servers (Static Copy)

**Pattern**:
```python
dest_app = FastMCP("Destination")
dest_app.import_server(server=source_app, prefix="util")

# Tool is now: util_tool_name
# Changes to source_app DO NOT affect dest_app
```

**Characteristics**:
- **Static Copy**: Snapshot taken at import time
- **Independence**: Source and destination decoupled
- **Performance**: No indirection overhead
- **Use Case**: Shared component libraries, template servers

**Confidence Level**: HIGH

### 4.3 FastMCP Gateway Pattern for Hana-X

**Example Implementation**:
```python
from fastmcp import FastMCP

hx_gateway = FastMCP(
    "Hana-X MCP Gateway",
    instructions="Unified MCP tool access for Hana-X agents"
)

# Mount domain-specific servers
hx_gateway.mount(server=crawl4ai_server, prefix="crawl")
hx_gateway.mount(server=memory_server, prefix="memory")
hx_gateway.mount(server=filesystem_server, prefix="fs")
hx_gateway.mount(server=web_search_server, prefix="search")
hx_gateway.mount(server=n8n_server, prefix="workflow")

# Gateway-level tools
@hx_gateway.tool
def list_available_domains() -> list[str]:
    """List all mounted MCP domains."""
    return ["crawl", "memory", "fs", "search", "workflow"]

# Run on HTTP transport
hx_gateway.run(transport="http", host="0.0.0.0", port=8000)
```

**Benefits**:
- **Unified Interface**: Single MCP endpoint for all agents
- **Modular Development**: Each domain developed independently
- **Selective Access**: Mount/unmount based on permissions
- **Testing**: Test domain servers in isolation
- **Scalability**: Add capabilities by mounting servers

**Confidence Level**: HIGH

---

## 5. PROXY SERVERS

### 5.1 Basic Proxy Pattern

**Create Proxy**:
```python
original = FastMCP("Original")

@original.tool
def echo(message: str) -> str:
    return f"Echo: {message}"

# Create proxy wrapping original
proxy = FastMCP.as_proxy(original, name="Proxy")

# Proxy forwards all original capabilities
# Client → Proxy → Original
```

### 5.2 Proxy with URL Wrapping

```python
# Wrap remote server
proxy = FastMCP.as_proxy("http://remote-server.example.com/mcp")

# Bridge Stdio to HTTP
from fastmcp.client import FastMCPTransport

proxy = FastMCP.as_proxy(
    FastMCPTransport(local_stdio_server),
    name="HTTP Bridge"
)

proxy.run(transport="http", host="0.0.0.0", port=8000)
```

### 5.3 Proxy Capabilities

**Interception & Modification**:
```python
proxy = FastMCP.as_proxy(original_server)

# Override specific tools
@proxy.tool
def echo(message: str, extra: str = "") -> str:
    """Override with additional parameter."""
    return f"Proxied Echo: {message} {extra}"

# Add new tools
@proxy.tool
def proxy_only_tool() -> str:
    return "Proxy-specific functionality"
```

**Component Precedence**:
1. Local components on proxy
2. Mirrored components from proxied server
3. Disabled local components hide mirrored ones

**Use Cases**:
- **Transport Bridging**: Stdio ↔ HTTP, SSE ↔ Stdio
- **Security Layer**: Add auth, filter tools, audit logs
- **Enhancement**: Caching, aggregation, monitoring
- **Hana-X Applications**: Agent-specific filtering, security zones, observability

**Confidence Level**: HIGH

---

## 6. AUTHENTICATION & SECURITY

### 6.1 Enterprise OAuth Providers

**Supported Providers**:
- Google
- GitHub
- Microsoft Azure
- Auth0
- WorkOS
- Descope
- JWT/Custom
- API Keys
- Bearer tokens

**Server-Side Protection**:
```python
from fastmcp.server.auth import GoogleProvider

auth = GoogleProvider(
    client_id="...",
    client_secret="...",
    base_url="https://myserver.com"
)

mcp = FastMCP("Protected Server", auth=auth)
```

**Client-Side OAuth**:
```python
async with Client(
    "https://protected-server.com/mcp",
    auth="oauth"
) as client:
    # Automatic browser-based OAuth flow
    result = await client.call_tool("protected_tool")
```

### 6.2 Authentication Features

**Production-Ready**:
- Persistent token storage
- Automatic token refresh
- Comprehensive error handling
- Browser-based OAuth flows
- Environment variable support

**Advanced Architecture**:
- Full OIDC support
- Dynamic Client Registration (DCR)
- OAuth proxy pattern (unique to FastMCP)

**Confidence Level**: HIGH

---

## 7. MIDDLEWARE SYSTEM

### 7.1 Middleware Architecture

**Pattern**:
```python
from fastmcp.server.middleware import Middleware, MiddlewareContext

@dataclass(kw_only=True, frozen=True)
class MiddlewareContext(Generic[T]):
    message: T                              # Request message
    fastmcp_context: Context | None = None # MCP context
    source: Literal["client", "server"]    # Origin
    type: Literal["request", "notification"]
    method: str | None = None              # MCP method
    timestamp: datetime                    # Timestamp

# Middleware function
async def my_middleware(
    context: MiddlewareContext[Any],
    call_next: Callable
) -> Any:
    # Before
    logger.info(f"Processing {context.method}")
    
    # Next
    result = await call_next(context)
    
    # After
    logger.info(f"Completed {context.method}")
    return result

mcp.add_middleware(my_middleware)
```

### 7.2 Built-In Middleware

**Logging Middleware**:
```python
from fastmcp.server.middleware import LoggingMiddleware

middleware = LoggingMiddleware(
    logger=logger,
    log_level=logging.DEBUG,
    include_payloads=True,
    include_payload_length=True,
    estimate_payload_tokens=True,
    max_payload_length=1000,
    structured_logging=True
)

mcp.add_middleware(middleware)
```

**Rate Limiting Middleware**:
```python
from fastmcp.server.middleware import RateLimitingMiddleware

middleware = RateLimitingMiddleware(
    max_requests_per_minute=100
)
```

**Error Handling Middleware**:
```python
from fastmcp.server.middleware import ErrorHandlingMiddleware

middleware = ErrorHandlingMiddleware(
    mask_error_details=True,
    log_errors=True
)
```

**Timing Middleware**:
```python
from fastmcp.server.middleware import TimingMiddleware

middleware = TimingMiddleware(
    log_slow_requests=True,
    slow_request_threshold=1.0  # seconds
)
```

**Confidence Level**: HIGH

---

## 8. CLIENT LIBRARY

### 8.1 FastMCP Client Class

**Basic Usage**:
```python
from fastmcp import Client

async def main():
    async with Client("http://localhost:8000/mcp") as client:
        # List tools
        tools = await client.list_tools()
        
        # Call tool
        result = await client.call_tool("add", {"a": 5, "b": 3})
        
        # List resources
        resources = await client.list_resources()
        
        # Read resource
        data = await client.read_resource("config://version")
        
        # Get prompt
        prompt = await client.get_prompt("summarize", {"text": "..."})
```

### 8.2 Multi-Server Client

**MCP Config Pattern**:
```python
config = {
    "mcpServers": {
        "weather": {
            "url": "https://weather-api.example.com/mcp"
        },
        "assistant": {
            "command": "python",
            "args": ["./assistant_server.py"]
        }
    }
}

async with Client(config) as client:
    # Tools prefixed by server name
    forecast = await client.call_tool("weather_get_forecast", {"city": "London"})
    answer = await client.call_tool("assistant_answer_question", {"query": "What is MCP?"})
```

### 8.3 Client Callbacks & Handlers

**Sampling Handler** (LLM completions from server):
```python
async def sampling_handler(messages, max_tokens=100):
    response = await openai_client.chat.completions.create(
        model="gpt-4",
        messages=messages,
        max_tokens=max_tokens
    )
    return response.choices[0].message.content

client = Client(transport, sampling_handler=sampling_handler)
```

**Log Handler**:
```python
async def log_handler(level: str, message: str, logger_name: str):
    print(f"[{logger_name}] {level}: {message}")

client = Client(transport, log_handler=log_handler)
```

**Progress Handler**:
```python
async def progress_handler(progress: int, total: int, message: str):
    percent = (progress / total * 100) if total else 0
    print(f"Progress: {percent:.1f}% - {message}")

client = Client(transport, progress_handler=progress_handler)
```

**Roots Handler** (filesystem access):
```python
from fastmcp.client.roots import RootsList

roots = RootsList([
    {"uri": "file:///allowed/path", "name": "Allowed Directory"}
])

client = Client(transport, roots=roots)
```

**Confidence Level**: HIGH

---

## 9. OPENAPI INTEGRATION

### 9.1 Generate Server from OpenAPI

**Pattern**:
```python
from fastmcp import FastMCP

spec = {
    "openapi": "3.1.0",
    "info": {"title": "API", "version": "1.0"},
    "paths": {
        "/users": {
            "get": {
                "operationId": "listUsers",
                "responses": {"200": {"description": "Users list"}}
            }
        }
    }
}

async with httpx.AsyncClient() as client:
    server = FastMCP.from_openapi(spec, client)
    # Tools created from operations automatically
```

### 9.2 Generate Server from FastAPI

```python
from fastapi import FastAPI
from fastmcp import FastMCP

app = FastAPI()

@app.get("/data")
async def get_data():
    return {"data": "value"}

async with httpx.AsyncClient() as client:
    server = FastMCP.from_fastapi(app, client)
```

### 9.3 Route Mapping

**Component Types**:
- `MCPType.TOOL` - Callable operations (default)
- `MCPType.RESOURCE` - Static data endpoints
- `MCPType.RESOURCE_TEMPLATE` - Parameterized endpoints
- `MCPType.EXCLUDE` - Skip route

**Route Map Configuration**:
```python
from fastmcp.server.openapi import RouteMap, MCPType

route_maps = [
    RouteMap(
        methods=["GET"],
        pattern=r"/api/users/.*",
        mcp_type=MCPType.RESOURCE_TEMPLATE,
        tags={"user"},
        mcp_tags={"fastmcp-user"}
    )
]

server = FastMCP.from_openapi(
    spec,
    client,
    route_map_fn=None,  # or custom mapping function
    route_maps=route_maps
)
```

**Supported Parameter Handling**:
- Query parameters (form, deepObject styles)
- Path parameters (simple style)
- Header parameters
- Request body (JSON)
- Array and object parameters with explode variations

**Confidence Level**: MEDIUM

---

## 10. DEPLOYMENT PATTERNS

### 10.1 Development Deployment

**Local Stdio (Default)**:
```python
if __name__ == "__main__":
    mcp.run()  # Uses stdio transport by default
```
- Lowest overhead
- Best for: local tools, development

### 10.2 Production HTTP Deployment

**Standalone with Uvicorn**:
```python
if __name__ == "__main__":
    mcp.run(
        transport="http",
        host="0.0.0.0",
        port=8000,
        path="/mcp"
    )
```

**Integrated with ASGI Framework**:
```python
from fastapi import FastAPI

fastapi_app = FastAPI()
mcp = FastMCP("My Server")

# Create MCP ASGI app
mcp_app = mcp.http_app(path="/mcp")

# Mount at path
fastapi_app.mount("/mcp", mcp_app)

# Run with FastAPI
# uvicorn app:fastapi_app --host 0.0.0.0 --port 8000
```

### 10.3 Docker Deployment

**Dockerfile**:
```dockerfile
FROM python:3.10

WORKDIR /app
COPY . .

RUN pip install -e .

EXPOSE 8000

CMD ["python", "-c", "from my_server import mcp; mcp.run(transport='http', host='0.0.0.0', port=8000)"]
```

**Docker Compose**:
```yaml
services:
  mcp-server:
    image: mcp-server:latest
    ports:
      - "8000:8000"
    environment:
      - FASTMCP_LOG_LEVEL=INFO
```

### 10.4 Environment Configuration

**Settings**:
- `FASTMCP_LOG_LEVEL` - Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- `FASTMCP_LOG_ENABLED` - Enable/disable logging (true/false)
- `FASTMCP_ENABLE_RICH_TRACEBACKS` - Rich error formatting (true/false)
- `FASTMCP_SERVER_AUTH` - Auth provider (google, github, azure, etc.)

**Configuration File** (`fastmcp.json`):
```json
{
  "entrypoint": "my_server.py",
  "environment": {
    "dependencies": ["pandas", "requests"],
    "variables": {
      "API_KEY": "sk-...",
      "LOG_LEVEL": "INFO"
    }
  }
}
```

**Confidence Level**: HIGH

---

## 11. MONITORING & OBSERVABILITY

### 11.1 Built-In Logging

**Logger Access**:
```python
from fastmcp.utilities.logging import get_logger

logger = get_logger(__name__)

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.critical("Critical message")
```

### 11.2 Logging Middleware

```python
from fastmcp.server.middleware.logging import LoggingMiddleware

middleware = LoggingMiddleware(
    log_level=logging.DEBUG,
    include_payloads=True,
    include_payload_length=True,
    estimate_payload_tokens=True,
    max_payload_length=1000,
    methods=["tools/call"],  # Filter by method
    structured_logging=True,
    payload_serializer=None  # Custom serializer
)

mcp.add_middleware(middleware)
```

### 11.3 Performance Monitoring

```python
from fastmcp.server.middleware.timing import TimingMiddleware

timing_mw = TimingMiddleware(
    log_slow_requests=True,
    slow_request_threshold=1.0  # seconds
)

mcp.add_middleware(timing_mw)
```

### 11.4 Context Logging

```python
@mcp.tool
async def my_tool(data: str, ctx: Context):
    await ctx.debug("Detailed debug info")
    await ctx.info(f"Processing {data}")
    await ctx.warning("Warning condition detected")
    await ctx.error("Error occurred")
    return result
```

**Confidence Level**: MEDIUM

---

## 12. TESTING FRAMEWORK

### 12.1 In-Memory Testing

**Pattern**:
```python
from fastmcp import FastMCP, Client

async def test_server():
    # Create server in test
    server = FastMCP("Test Server")
    
    @server.tool
    def add(a: int, b: int) -> int:
        return a + b
    
    # Test with in-memory transport
    async with Client(server) as client:
        result = await client.call_tool("add", {"a": 2, "b": 3})
        assert result.content[0].text == "5"
```

### 12.2 Test Utilities

**Temporary Settings**:
```python
from fastmcp.utilities.tests import temporary_settings

with temporary_settings(log_level='DEBUG'):
    # Log level is DEBUG within this block
    pass
```

**Process-Based Testing** (SSE):
```python
from fastmcp.utilities.tests import run_server_in_process

def run_server():
    mcp.run(transport="sse", port=8888)

with run_server_in_process(run_server) as server_url:
    # Server running, accessible at server_url
    async with Client(server_url) as client:
        # Test client
        pass
```

**Confidence Level**: MEDIUM

---

## 13. KEY DEPENDENCIES

### Core Dependencies
```
mcp>=1.12.4,<2.0.0          # Official MCP SDK
httpx>=0.28.1               # Async HTTP client
pydantic>=2.11.7            # Data validation
rich>=13.9.4                # Rich console output
uvicorn                     # ASGI server
starlette                   # ASGI framework
openapi-pydantic>=0.5.1     # OpenAPI parsing
authlib>=1.5.2              # OAuth support
websockets>=15.0.1          # WebSocket support
```

### Optional Dependencies
```
openai>=1.102.0             # For sampling examples
fastapi>=0.115.12           # For FastAPI integration
```

**Confidence Level**: HIGH

---

## 14. PRODUCTION DEPLOYMENT CONSIDERATIONS FOR DOCLING-MCP

### 14.1 Architecture Pattern

**Recommended Setup**:
```python
# docling_server.py
from fastmcp import FastMCP
from docling import DocumentConverter

mcp = FastMCP(
    name="Docling MCP Server",
    instructions="Document conversion and extraction server",
    version="1.0.0",
)

converter = DocumentConverter()

@mcp.tool
async def convert_document(file_path: str, output_format: str) -> dict:
    """Convert document to specified format."""
    result = await converter.convert(file_path, output_format)
    return {"success": True, "output": str(result)}

@mcp.resource(uri="documents://{doc_id}")
async def get_document(doc_id: str) -> dict:
    """Retrieve document metadata."""
    return {"id": doc_id, "status": "ready"}

if __name__ == "__main__":
    # HTTP for production
    mcp.run(transport="http", host="0.0.0.0", port=8000)
```

### 14.2 Deployment Checklist

**Pre-Deployment**:
- [ ] Error handling with `mask_error_details=True`
- [ ] Logging middleware configured
- [ ] Authentication provider configured
- [ ] Resource limits defined
- [ ] Health checks implemented

**Middleware Stack**:
```python
# Order matters - added first runs last
mcp.add_middleware(ErrorHandlingMiddleware(...))
mcp.add_middleware(RateLimitingMiddleware(...))
mcp.add_middleware(LoggingMiddleware(...))
mcp.add_middleware(TimingMiddleware(...))
```

**Lifespan Management**:
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(mcp: FastMCP):
    # Startup
    await converter.initialize()
    print("Docling converter initialized")
    
    yield
    
    # Shutdown
    await converter.cleanup()
    print("Docling converter cleaned up")

mcp = FastMCP(
    name="Docling MCP Server",
    lifespan=lifespan
)
```

**Confidence Level**: HIGH

---

## 15. PERFORMANCE CHARACTERISTICS

### 15.1 Latency Profile

**Transport Comparison**:
| Transport | Latency | Overhead | Use Case |
|-----------|---------|----------|----------|
| Stdio | <1ms | Minimal (IPC) | Local tools |
| HTTP | 5-50ms | Network + protocol | Production network |
| SSE | 10-100ms | Connection overhead | Legacy clients |
| In-Memory | <0.1ms | Function call | Testing |

### 15.2 Scaling Considerations

**Stateless HTTP**:
- Multiple instances behind load balancer
- Sessions managed by clients
- No server-side state sharing

**Stateful HTTP** (default):
- Session maintained per connection
- Not suitable for load balancing
- Better for single-server deployments

**Confidence Level**: MEDIUM

---

## 16. KNOWN LIMITATIONS & EDGE CASES

### 16.1 OpenAPI Integration Limitations

**Parameter Edge Cases**:
- Parameter name collisions between path/query and body get `__location` suffixes
- Complex array serialization has limited support
- Cookie parameters parsed but not used in requests
- Non-standard parameter combinations may not serialize correctly

**Schema Limitations**:
- External references (`$ref` to external files) not supported
- Circular references may cause issues
- Polymorphism (`oneOf`/`anyOf`/`allOf`) has limited support

**Response Handling**:
- Multiple content types: only JSON-compatible used for schema
- Error responses not used for output schema generation
- Response headers not captured or exposed

**Confidence Level**: MEDIUM

### 16.2 Composition Limitations

**Mount vs Import**:
- **Mount**: Live link, performance overhead
- **Import**: Static copy, no dynamic updates
- Choose based on whether sub-server is expected to change

**URI Format Considerations**:
- Protocol prefix required: `weather://forecast` not `forecast`
- Resource prefix format can be "protocol" (default) or "path"

**Confidence Level**: HIGH

---

## 17. SUMMARY TABLE

| Aspect | Confidence | Notes |
|--------|-----------|-------|
| **Core Primitives** | HIGH | Decorator-based tools/resources/prompts well-established |
| **Transport Layer** | HIGH | Stdio, HTTP, SSE, in-memory all mature |
| **Server Composition** | HIGH | Mount and import patterns proven |
| **Client Library** | HIGH | Multiple transport support, well-documented |
| **Authentication** | HIGH | Enterprise OAuth providers fully supported |
| **Middleware System** | HIGH | Complete request/response pipeline support |
| **OpenAPI Integration** | MEDIUM | Works well for standard APIs, edge cases exist |
| **Deployment** | HIGH | Production-ready with monitoring/logging |
| **Testing Framework** | MEDIUM | Good in-memory support, process-based testing available |
| **Performance** | MEDIUM | Suitable for most workloads, not optimized for extreme scale |
| **Documentation** | HIGH | Comprehensive docs and examples |

---

## 18. RECOMMENDATIONS FOR DOCLING-MCP DEPLOYMENT

### 18.1 Architecture

**Recommended**: HTTP transport with Uvicorn
```python
mcp.run(transport="http", host="0.0.0.0", port=8000, path="/mcp")
```

**Benefits**:
- Stateful sessions for document processing workflows
- Proper HTTP semantics
- Easy integration with reverse proxies
- Monitoring via HTTP status codes

### 18.2 Configuration

**Environment**:
```bash
export FASTMCP_LOG_LEVEL=INFO
export FASTMCP_ENABLE_RICH_TRACEBACKS=false  # Production
```

**Middleware Stack**:
1. Error Handling (mask errors)
2. Rate Limiting (if needed)
3. Logging (structured)
4. Timing (performance monitoring)

### 18.3 Testing Strategy

- Unit tests: In-memory client (`FastMCPTransport`)
- Integration tests: Process-based testing
- End-to-end: HTTP client testing

### 18.4 Monitoring

- Structured logging with payload inspection
- Timing middleware for slow requests
- Tool execution success/failure tracking
- Resource utilization monitoring

**Confidence Level**: HIGH

---

## CONCLUSION

FastMCP is a production-ready, comprehensive framework for MCP server and client development. Its strengths are:

1. **Simplicity**: Decorator-based registration makes code clean
2. **Flexibility**: Multiple transports and composition patterns
3. **Production Features**: Auth, middleware, monitoring, testing
4. **Pythonic**: Natural async/await, type-safe with Pydantic
5. **Extensibility**: Custom serializers, middleware, transport bridges

**Best suited for**:
- Production MCP servers (Docling-MCP)
- Microservice composition (Hana-X gateway patterns)
- Complex workflows requiring stateful sessions
- Multi-agent systems with unified tool access

**Key takeaway for Docling-MCP**: FastMCP handles all protocol details, allowing focus on document conversion logic. HTTP transport deployment with structured logging provides production-ready observability.

