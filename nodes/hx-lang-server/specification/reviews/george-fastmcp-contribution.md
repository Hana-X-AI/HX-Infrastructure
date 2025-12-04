# Specification Contribution: George (FastMCP Gateway SME)

**Contribution Date:** 2025-12-01
**Specification Version:** 1.0
**Contributor Role:** FastMCP Gateway SME
**Focus Areas:** MCP Client Integration, Transport Configuration, Tool Namespace Handling

---

## Executive Summary

This contribution provides comprehensive guidance for implementing MCP client integration in hx-lang-server using `langchain-mcp-adapters`. The current specification correctly identifies hx-lang-server as an MCP CLIENT (not server), but requires additional detail on transport selection, tool namespace handling, connection lifecycle management, and error handling patterns. This document provides production-ready code examples, architectural clarifications, and specific recommendations for node-spec.md updates.

**Key Contributions:**
1. Complete MCP client architecture with MultiServerMCPClient configuration
2. Transport selection guidance (streamable_http vs sse vs stdio)
3. Tool namespace handling for gateway-prefixed tools
4. Connection lifecycle integration with FastAPI lifespan
5. MCP-specific error handling and circuit breaker patterns
6. Production-ready code examples
7. Validation and testing recommendations

---

## 1. MCP Client Architecture

### 1.1 Architectural Clarification

The specification correctly states (lines 420-423):

> **IMPORTANT:** hx-lang-server is an MCP **CLIENT**, not an MCP server.
> - **MCP Servers:** hx-fastmcp-server, hx-crawl4ai-mcp-server, hx-docling-mcp-server
> - **MCP Client:** hx-lang-server (consumes tools via langchain-mcp-adapters)

**This is correct and MUST be preserved.** I want to provide additional architectural context:

```
MCP Architecture in HX-Infrastructure
======================================

                    MCP CLIENT LAYER (hx-lang-server)
                    ================================

   +-----------------------------------------------------------------+
   |                     hx-lang-server                               |
   |                                                                  |
   |  +----------------------------------------------------------+   |
   |  |              Tool Agent (MCP Consumer)                   |   |
   |  |                                                           |   |
   |  |  +----------------------------------------------------+  |   |
   |  |  |    langchain-mcp-adapters                          |  |   |
   |  |  |    MultiServerMCPClient                            |  |   |
   |  |  |                                                    |  |   |
   |  |  |  - get_tools() -> Tool schemas                     |  |   |
   |  |  |  - call_tool() -> Tool invocation                  |  |   |
   |  |  +----------------------------------------------------+  |   |
   |  +----------------------------------------------------------+   |
   |                           |                                      |
   |                           | streamable_http transport            |
   |                           v                                      |
   +---------------------------+--------------------------------------+
                               |
                               | HTTP/JSON-RPC over MCP Protocol
                               |
                    MCP SERVER LAYER (hx-fastmcp-server)
                    ====================================
                               |
   +---------------------------v--------------------------------------+
   |                    hx-fastmcp-server                             |
   |                    (FastMCP Gateway)                             |
   |                    hx-fastmcp-server.hx.dev.local:8000           |
   |                                                                  |
   |  +----------------------------------------------------------+   |
   |  |              FastMCP Server Composition                  |   |
   |  |                                                           |   |
   |  |  gateway = FastMCP("HX MCP Gateway")                     |   |
   |  |  gateway.mount(crawl4ai_server, prefix="crawl4ai")       |   |
   |  |  gateway.mount(docling_server, prefix="docling")         |   |
   |  +----------------------------------------------------------+   |
   |                           |                                      |
   |              +------------+------------+                         |
   |              |                         |                         |
   |              v                         v                         |
   |  +--------------------+   +--------------------+                 |
   |  | hx-crawl4ai-mcp    |   | hx-docling-mcp     |                 |
   |  |                    |   |                    |                 |
   |  | Tools:             |   | Tools:             |                 |
   |  | - crawl4ai__       |   | - docling__        |                 |
   |  |   smart_crawl_url  |   |   convert_document |                 |
   |  | - crawl4ai__       |   | - docling__        |                 |
   |  |   crawl_url        |   |   extract_tables   |                 |
   |  +--------------------+   +--------------------+                 |
   +------------------------------------------------------------------+
```

### 1.2 Why MCP Client, Not MCP Server

**Rationale for hx-lang-server as MCP CLIENT:**

1. **Separation of Concerns**: hx-lang-server is an ORCHESTRATION layer that coordinates work, not a tool provider. Raw capabilities (crawling, document processing, vector search) are exposed by dedicated MCP servers.

2. **Unified Tool Access**: By consuming tools from the FastMCP gateway, hx-lang-server gets automatic access to all tools mounted on the gateway without direct dependencies on individual MCP servers.

3. **Dynamic Discovery**: New MCP servers mounted on hx-fastmcp-server become automatically available to hx-lang-server through `get_tools()` without code changes.

4. **Reduced Complexity**: Running an MCP server on hx-lang-server would duplicate functionality already provided by the gateway and create circular dependency risks.

**RECOMMENDATION:** Add this rationale to the specification to prevent future confusion.

---

## 2. Transport Configuration

### 2.1 Transport Selection

The `langchain-mcp-adapters` library supports three transport types:

| Transport | Use Case | Protocol | When to Use |
|-----------|----------|----------|-------------|
| `stdio` | Local processes | Process pipes | Local MCP servers spawned as subprocesses |
| `streamable_http` | HTTP servers | HTTP POST + SSE | **Recommended for hx-fastmcp-server** |
| `sse` | Legacy SSE servers | HTTP GET + SSE | Older MCP servers using pure SSE |

**For hx-lang-server connecting to hx-fastmcp-server:**

```python
# RECOMMENDED: streamable_http transport
# This is the modern HTTP transport for FastMCP 2.x servers

mcp_client = MultiServerMCPClient({
    "fastmcp": {
        "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        "transport": "streamable_http"
    }
})
```

### 2.2 Transport Configuration Deep Dive

**streamable_http (Recommended)**

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

# Full configuration with all options
mcp_config = {
    "hx_gateway": {
        # Required: MCP endpoint URL
        "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",

        # Required: Transport type
        "transport": "streamable_http",

        # Optional: HTTP headers for authentication (if needed in future)
        "headers": {
            "X-API-Key": "${MCP_API_KEY}"  # If gateway requires auth
        },

        # Optional: Connection timeout in seconds (default varies)
        "timeout": 30.0
    }
}

client = MultiServerMCPClient(mcp_config)
```

**sse Transport (Legacy)**

```python
# Only use if hx-fastmcp-server exposes SSE-only endpoint
mcp_config = {
    "hx_gateway": {
        "url": "http://hx-fastmcp-server.hx.dev.local:8000/sse",
        "transport": "sse"
    }
}
```

**stdio Transport (Not applicable)**

```python
# stdio is for LOCAL process-based servers
# NOT applicable for hx-lang-server connecting to remote gateway
# Example for reference only:
mcp_config = {
    "local_server": {
        "command": "python",
        "args": ["/path/to/local_mcp_server.py"],
        "transport": "stdio"
    }
}
```

### 2.3 Specification Update Required

**Current Specification (lines 430-437):**
```python
mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)
```

**Recommended Update:**

```python
from langchain_mcp_adapters.client import MultiServerMCPClient
from typing import Optional
import os

def create_mcp_client(
    gateway_url: Optional[str] = None,
    timeout: float = 30.0,
    api_key: Optional[str] = None
) -> MultiServerMCPClient:
    """
    Create configured MCP client for hx-fastmcp-server gateway.

    Args:
        gateway_url: FastMCP gateway URL (default from env)
        timeout: Connection timeout in seconds
        api_key: Optional API key for authenticated access

    Returns:
        Configured MultiServerMCPClient
    """
    url = gateway_url or os.getenv(
        "FASTMCP_URL",
        "http://hx-fastmcp-server.hx.dev.local:8000/mcp"
    )

    config = {
        "hx_gateway": {
            "url": url,
            "transport": "streamable_http",
            "timeout": timeout,
        }
    }

    # Add authentication header if API key provided
    if api_key:
        config["hx_gateway"]["headers"] = {"X-API-Key": api_key}

    return MultiServerMCPClient(config)
```

---

## 3. Tool Namespace Handling

### 3.1 Gateway Prefix Pattern

The FastMCP gateway applies prefixes to all mounted server tools to prevent naming collisions. The prefix pattern follows this format:

```
{mount_prefix}__{original_tool_name}
```

**Example Tool Names from hx-fastmcp-server:**

| Mounted Server | Mount Prefix | Original Tool | Gateway Tool Name |
|----------------|--------------|---------------|-------------------|
| hx-crawl4ai-mcp | crawl4ai | smart_crawl_url | `crawl4ai__smart_crawl_url` |
| hx-crawl4ai-mcp | crawl4ai | crawl_url | `crawl4ai__crawl_url` |
| hx-docling-mcp | docling | convert_document | `docling__convert_document` |
| hx-docling-mcp | docling | extract_tables | `docling__extract_tables` |

**Note:** The double underscore (`__`) is the standard delimiter. This may vary based on FastMCP gateway configuration. Verify with actual gateway deployment.

### 3.2 Tool Discovery Pattern

```python
from langchain_mcp_adapters.client import MultiServerMCPClient
from langgraph.prebuilt import ToolNode
from typing import Dict, List, Any

class MCPToolManager:
    """Manages MCP tool discovery and invocation."""

    def __init__(self, client: MultiServerMCPClient):
        self.client = client
        self._tools: List[Any] = []
        self._tool_map: Dict[str, str] = {}  # friendly_name -> gateway_name

    async def discover_tools(self) -> List[Any]:
        """
        Discover all available tools from MCP gateway.

        Returns:
            List of LangChain-compatible tool objects
        """
        self._tools = await self.client.get_tools()

        # Build friendly name mapping
        self._tool_map = {}
        for tool in self._tools:
            # Extract friendly name by removing gateway prefix
            # e.g., "crawl4ai__smart_crawl_url" -> "smart_crawl_url"
            parts = tool.name.split("__", 1)
            if len(parts) == 2:
                prefix, friendly_name = parts
                self._tool_map[friendly_name] = tool.name
                self._tool_map[f"{prefix}:{friendly_name}"] = tool.name
            else:
                # No prefix, use original name
                self._tool_map[tool.name] = tool.name

        return self._tools

    def get_tool_node(self) -> ToolNode:
        """Create LangGraph ToolNode with discovered tools."""
        if not self._tools:
            raise RuntimeError("Tools not discovered. Call discover_tools() first.")
        return ToolNode(self._tools)

    def get_gateway_tool_name(self, friendly_name: str) -> str:
        """
        Resolve friendly tool name to gateway tool name.

        Args:
            friendly_name: Tool name without prefix (e.g., "smart_crawl_url")
                          or with prefix (e.g., "crawl4ai:smart_crawl_url")

        Returns:
            Full gateway tool name (e.g., "crawl4ai__smart_crawl_url")
        """
        if friendly_name in self._tool_map:
            return self._tool_map[friendly_name]
        # Already a gateway name
        return friendly_name

    def list_tools_by_domain(self) -> Dict[str, List[str]]:
        """
        Group available tools by domain/prefix.

        Returns:
            Dict mapping domain prefix to list of tool names
        """
        domains: Dict[str, List[str]] = {}
        for tool in self._tools:
            parts = tool.name.split("__", 1)
            if len(parts) == 2:
                domain, tool_name = parts
            else:
                domain = "default"
                tool_name = tool.name

            if domain not in domains:
                domains[domain] = []
            domains[domain].append(tool_name)

        return domains
```

### 3.3 Tool Invocation in Tool Agent

```python
from typing import TypedDict, Annotated, List, Optional
from langgraph.graph import StateGraph
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage

class ToolAgentState(TypedDict):
    """State for Tool Agent within LangGraph."""
    messages: Annotated[List[BaseMessage], add_messages]
    tool_results: Optional[dict]
    tool_invocation_count: int
    last_tool_error: Optional[str]

async def tool_agent_node(
    state: ToolAgentState,
    mcp_tool_manager: MCPToolManager
) -> dict:
    """
    Tool Agent node that invokes MCP tools.

    This node:
    1. Extracts tool calls from the last message
    2. Resolves gateway tool names
    3. Invokes tools via MCP client
    4. Returns results to state
    """
    from langchain_core.messages import ToolMessage

    last_message = state["messages"][-1]

    if not hasattr(last_message, "tool_calls") or not last_message.tool_calls:
        return {"tool_results": None}

    tool_node = mcp_tool_manager.get_tool_node()

    # ToolNode handles the actual invocation
    # It returns ToolMessage objects with results
    result = await tool_node.ainvoke(state)

    # Update invocation count
    new_count = state.get("tool_invocation_count", 0) + len(last_message.tool_calls)

    return {
        "messages": result.get("messages", []),
        "tool_results": {"invocation_count": new_count},
        "tool_invocation_count": new_count,
        "last_tool_error": None
    }
```

### 3.4 Specification Update for Tool Namespace

**Current Specification (lines 449-454):**
```python
### Tool Namespace Handling

FastMCP gateway prefixes tools with server name. The client must handle:
- `crawl4ai__smart_crawl_url` (not `smart_crawl_url`)
- `docling__convert_document` (not `convert_document`)
```

**Recommended Addition:**

Add the `MCPToolManager` class and document the namespace resolution pattern. Also add:

```markdown
### Tool Namespace Convention

**Prefix Format:** `{mount_prefix}__{tool_name}`
**Delimiter:** Double underscore (`__`)

**Tool Discovery Flow:**
1. `get_tools()` returns all gateway-prefixed tool names
2. Tool Agent receives tool calls with gateway names
3. ToolNode invokes tools using gateway names
4. Results returned to LangGraph state

**Best Practices:**
- Always use discovered tool names from `get_tools()`
- Do not hardcode tool names - discover dynamically
- Log discovered tools at startup for debugging
- Implement tool caching to avoid repeated discovery calls
```

---

## 4. MCP Error Handling

### 4.1 MCP-Specific Errors

The MCP client can encounter several error categories:

| Error Type | Cause | Handling |
|------------|-------|----------|
| Connection Refused | Gateway unreachable | Circuit breaker, retry with backoff |
| Timeout | Slow tool execution | Configurable timeout, async patterns |
| Tool Not Found | Invalid tool name | Validate against discovered tools |
| Tool Execution Error | Tool logic failure | Return error to agent, log details |
| Protocol Error | MCP version mismatch | Version validation at startup |

### 4.2 Circuit Breaker Pattern

```python
import asyncio
from datetime import datetime, timedelta
from typing import Optional, Callable, TypeVar, Any
from enum import Enum
from dataclasses import dataclass, field
import structlog

logger = structlog.get_logger()

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject calls
    HALF_OPEN = "half_open"  # Testing recovery

@dataclass
class CircuitBreaker:
    """Circuit breaker for MCP client operations."""

    name: str
    failure_threshold: int = 5
    recovery_timeout: float = 60.0  # seconds
    half_open_max_calls: int = 3

    _state: CircuitState = field(default=CircuitState.CLOSED, init=False)
    _failure_count: int = field(default=0, init=False)
    _last_failure_time: Optional[datetime] = field(default=None, init=False)
    _half_open_calls: int = field(default=0, init=False)

    @property
    def state(self) -> CircuitState:
        """Get current circuit state, checking for recovery."""
        if self._state == CircuitState.OPEN:
            if self._last_failure_time:
                elapsed = datetime.now() - self._last_failure_time
                if elapsed > timedelta(seconds=self.recovery_timeout):
                    self._state = CircuitState.HALF_OPEN
                    self._half_open_calls = 0
                    logger.info(
                        "circuit_breaker_half_open",
                        circuit=self.name
                    )
        return self._state

    def record_success(self) -> None:
        """Record successful call."""
        if self._state == CircuitState.HALF_OPEN:
            self._half_open_calls += 1
            if self._half_open_calls >= self.half_open_max_calls:
                self._state = CircuitState.CLOSED
                self._failure_count = 0
                logger.info(
                    "circuit_breaker_closed",
                    circuit=self.name
                )
        elif self._state == CircuitState.CLOSED:
            self._failure_count = 0

    def record_failure(self) -> None:
        """Record failed call."""
        self._failure_count += 1
        self._last_failure_time = datetime.now()

        if self._failure_count >= self.failure_threshold:
            self._state = CircuitState.OPEN
            logger.warning(
                "circuit_breaker_open",
                circuit=self.name,
                failure_count=self._failure_count
            )

    def can_execute(self) -> bool:
        """Check if call can proceed."""
        state = self.state  # Triggers recovery check
        if state == CircuitState.CLOSED:
            return True
        if state == CircuitState.HALF_OPEN:
            return True
        return False


T = TypeVar("T")

class MCPClientWithCircuitBreaker:
    """MCP client wrapper with circuit breaker protection."""

    def __init__(
        self,
        client: "MultiServerMCPClient",
        circuit_breaker: Optional[CircuitBreaker] = None
    ):
        self.client = client
        self.circuit = circuit_breaker or CircuitBreaker(name="mcp_gateway")

    async def get_tools(self) -> list:
        """Get tools with circuit breaker protection."""
        if not self.circuit.can_execute():
            raise MCPCircuitOpenError(
                f"Circuit breaker open for {self.circuit.name}"
            )

        try:
            tools = await self.client.get_tools()
            self.circuit.record_success()
            return tools
        except Exception as e:
            self.circuit.record_failure()
            logger.error(
                "mcp_get_tools_failed",
                error=str(e),
                circuit_state=self.circuit.state.value
            )
            raise

    async def call_tool(
        self,
        tool_name: str,
        arguments: dict,
        timeout: float = 30.0
    ) -> Any:
        """Call tool with circuit breaker and timeout."""
        if not self.circuit.can_execute():
            raise MCPCircuitOpenError(
                f"Circuit breaker open for {self.circuit.name}"
            )

        try:
            # Apply timeout
            result = await asyncio.wait_for(
                self.client.call_tool(tool_name, arguments),
                timeout=timeout
            )
            self.circuit.record_success()
            return result
        except asyncio.TimeoutError:
            self.circuit.record_failure()
            logger.error(
                "mcp_tool_timeout",
                tool=tool_name,
                timeout=timeout
            )
            raise MCPToolTimeoutError(
                f"Tool {tool_name} timed out after {timeout}s"
            )
        except Exception as e:
            self.circuit.record_failure()
            logger.error(
                "mcp_tool_failed",
                tool=tool_name,
                error=str(e)
            )
            raise


class MCPCircuitOpenError(Exception):
    """Raised when circuit breaker is open."""
    pass


class MCPToolTimeoutError(Exception):
    """Raised when tool execution times out."""
    pass


class MCPToolNotFoundError(Exception):
    """Raised when requested tool is not found."""
    pass
```

### 4.3 Retry Logic with Exponential Backoff

```python
import asyncio
import random
from typing import TypeVar, Callable, Awaitable

T = TypeVar("T")

async def retry_with_backoff(
    func: Callable[[], Awaitable[T]],
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 30.0,
    jitter: bool = True,
    retryable_exceptions: tuple = (ConnectionError, TimeoutError)
) -> T:
    """
    Retry async function with exponential backoff.

    Args:
        func: Async function to retry
        max_retries: Maximum retry attempts
        base_delay: Initial delay between retries (seconds)
        max_delay: Maximum delay between retries (seconds)
        jitter: Add randomness to delay
        retryable_exceptions: Exception types that trigger retry

    Returns:
        Function result on success

    Raises:
        Last exception if all retries exhausted
    """
    last_exception = None

    for attempt in range(max_retries + 1):
        try:
            return await func()
        except retryable_exceptions as e:
            last_exception = e

            if attempt == max_retries:
                logger.error(
                    "retry_exhausted",
                    attempts=max_retries + 1,
                    error=str(e)
                )
                raise

            # Calculate delay with exponential backoff
            delay = min(base_delay * (2 ** attempt), max_delay)

            # Add jitter to prevent thundering herd
            if jitter:
                delay = delay * (0.5 + random.random())

            logger.warning(
                "retry_attempt",
                attempt=attempt + 1,
                max_retries=max_retries,
                delay=delay,
                error=str(e)
            )

            await asyncio.sleep(delay)

    raise last_exception  # Should never reach here
```

### 4.4 Specification Update for Error Handling

**Add new section to node-spec.md:**

```markdown
### MCP Error Handling Requirements

**FR-MCP-001**: Service MUST implement circuit breaker for MCP gateway connectivity
- Failure threshold: 5 consecutive failures
- Recovery timeout: 60 seconds
- Half-open test calls: 3 successful calls to close circuit

**FR-MCP-002**: Service MUST implement retry with exponential backoff for transient MCP failures
- Max retries: 3
- Base delay: 1 second
- Max delay: 30 seconds
- Jitter: Enabled

**FR-MCP-003**: Service MUST handle MCP-specific error types:
- MCPCircuitOpenError: Return degraded response, log warning
- MCPToolTimeoutError: Increase timeout counter metric, return timeout error
- MCPToolNotFoundError: Log error, return tool not found error to agent

**FR-MCP-004**: Service MUST validate MCP protocol version at startup
- Expected: MCP Protocol 1.0
- Fail startup if incompatible version detected
```

---

## 5. Connection Lifecycle Management

### 5.1 FastAPI Lifespan Integration

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from langchain_mcp_adapters.client import MultiServerMCPClient
import structlog

logger = structlog.get_logger()

# Global MCP client and tool manager
mcp_client: MultiServerMCPClient = None
mcp_tool_manager: MCPToolManager = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI lifespan context manager for MCP client lifecycle.

    This ensures:
    1. MCP client is created and connected at startup
    2. Tools are discovered and cached
    3. Client is properly closed on shutdown
    """
    global mcp_client, mcp_tool_manager

    logger.info("mcp_client_starting")

    # Create MCP client
    mcp_client = MultiServerMCPClient({
        "hx_gateway": {
            "url": settings.fastmcp_url,
            "transport": "streamable_http",
            "timeout": 30.0
        }
    })

    # Wrap with circuit breaker
    protected_client = MCPClientWithCircuitBreaker(mcp_client)

    # Create tool manager and discover tools
    mcp_tool_manager = MCPToolManager(protected_client)

    try:
        # Discover available tools at startup
        tools = await retry_with_backoff(
            mcp_tool_manager.discover_tools,
            max_retries=3,
            retryable_exceptions=(ConnectionError, TimeoutError)
        )

        logger.info(
            "mcp_tools_discovered",
            tool_count=len(tools),
            domains=list(mcp_tool_manager.list_tools_by_domain().keys())
        )

    except Exception as e:
        logger.error(
            "mcp_startup_failed",
            error=str(e)
        )
        # Allow startup but mark MCP as degraded
        # Service can still function without MCP tools

    yield  # Application runs here

    # Cleanup on shutdown
    logger.info("mcp_client_stopping")

    # Close MCP client connections
    if hasattr(mcp_client, 'close'):
        await mcp_client.close()

    logger.info("mcp_client_stopped")


# FastAPI app with lifespan
app = FastAPI(
    title="hx-lang-server",
    lifespan=lifespan
)
```

### 5.2 Connection Health Checking

```python
from datetime import datetime
from typing import Dict, Any

async def check_mcp_health() -> Dict[str, Any]:
    """
    Check MCP gateway health for /health endpoint.

    Returns:
        Health status dict with status and details
    """
    health_result = {
        "status": "unknown",
        "gateway_url": settings.fastmcp_url,
        "last_check": datetime.now().isoformat(),
        "tool_count": 0,
        "error": None
    }

    if mcp_client is None:
        health_result["status"] = "not_initialized"
        return health_result

    try:
        # Attempt to get tools as health check
        tools = await asyncio.wait_for(
            mcp_client.get_tools(),
            timeout=5.0  # Short timeout for health check
        )

        health_result["status"] = "healthy"
        health_result["tool_count"] = len(tools)

    except asyncio.TimeoutError:
        health_result["status"] = "timeout"
        health_result["error"] = "Gateway health check timed out"

    except MCPCircuitOpenError:
        health_result["status"] = "circuit_open"
        health_result["error"] = "Circuit breaker is open due to failures"

    except Exception as e:
        health_result["status"] = "unhealthy"
        health_result["error"] = str(e)

    return health_result


# Integration with existing health endpoint
@app.get("/health")
async def health_check() -> HealthResponse:
    """Comprehensive health check including MCP."""
    dependencies = {
        "postgres": await check_postgres(),
        "redis": await check_redis(),
        "ollama_general": await check_ollama(settings.ollama_general_url),
        "ollama_code": await check_ollama(settings.ollama_code_url),
        "lightrag": await check_lightrag(),
        "fastmcp": await check_mcp_health(),  # MCP health check
    }

    # Determine overall status
    all_healthy = all(
        d.get("status") == "healthy"
        for d in dependencies.values()
    )

    # MCP degraded is acceptable (non-critical)
    mcp_status = dependencies.get("fastmcp", {}).get("status")
    if mcp_status in ("circuit_open", "timeout") and not all_healthy:
        overall_status = "degraded"
    elif all_healthy:
        overall_status = "healthy"
    else:
        overall_status = "unhealthy"

    return HealthResponse(
        status=overall_status,
        version=__version__,
        uptime_seconds=get_uptime(),
        dependencies=dependencies
    )
```

### 5.3 Reconnection Handling

```python
class MCPConnectionManager:
    """Manages MCP client connection with auto-reconnection."""

    def __init__(
        self,
        config: dict,
        reconnect_interval: float = 30.0,
        max_reconnect_attempts: int = 10
    ):
        self.config = config
        self.reconnect_interval = reconnect_interval
        self.max_reconnect_attempts = max_reconnect_attempts

        self._client: Optional[MultiServerMCPClient] = None
        self._connected: bool = False
        self._reconnect_task: Optional[asyncio.Task] = None
        self._reconnect_attempts: int = 0

    async def connect(self) -> None:
        """Establish initial connection."""
        self._client = MultiServerMCPClient(self.config)

        try:
            # Verify connection by getting tools
            await self._client.get_tools()
            self._connected = True
            self._reconnect_attempts = 0
            logger.info("mcp_connected")
        except Exception as e:
            self._connected = False
            logger.error("mcp_connect_failed", error=str(e))
            raise

    async def ensure_connected(self) -> MultiServerMCPClient:
        """Ensure client is connected, reconnecting if needed."""
        if not self._connected and self._reconnect_task is None:
            self._reconnect_task = asyncio.create_task(self._reconnect())

        if not self._connected:
            raise MCPNotConnectedError("MCP client not connected")

        return self._client

    async def _reconnect(self) -> None:
        """Background reconnection task."""
        while self._reconnect_attempts < self.max_reconnect_attempts:
            self._reconnect_attempts += 1

            logger.info(
                "mcp_reconnecting",
                attempt=self._reconnect_attempts,
                max_attempts=self.max_reconnect_attempts
            )

            try:
                await self.connect()
                self._reconnect_task = None
                return
            except Exception as e:
                logger.warning(
                    "mcp_reconnect_failed",
                    attempt=self._reconnect_attempts,
                    error=str(e)
                )
                await asyncio.sleep(self.reconnect_interval)

        logger.error("mcp_reconnect_exhausted")
        self._reconnect_task = None

    async def close(self) -> None:
        """Close connection and cancel reconnection."""
        if self._reconnect_task:
            self._reconnect_task.cancel()

        if self._client and hasattr(self._client, 'close'):
            await self._client.close()

        self._connected = False


class MCPNotConnectedError(Exception):
    """Raised when MCP client is not connected."""
    pass
```

---

## 6. MCP Protocol Version Compatibility

### 6.1 Version Requirements

| Component | Minimum Version | Recommended Version |
|-----------|-----------------|---------------------|
| langchain-mcp-adapters | 0.1.0 | 0.2.0+ |
| MCP Protocol | 1.0 | 1.0 |
| FastMCP (gateway) | 2.2.0 | 2.4.0+ |

### 6.2 Version Validation at Startup

```python
from packaging import version

REQUIRED_MCP_PROTOCOL = "1.0"
REQUIRED_LANGCHAIN_MCP_ADAPTERS = "0.1.0"

async def validate_mcp_compatibility() -> bool:
    """
    Validate MCP protocol and library compatibility at startup.

    Returns:
        True if compatible, raises exception if not
    """
    # Check langchain-mcp-adapters version
    try:
        import langchain_mcp_adapters
        installed_version = getattr(
            langchain_mcp_adapters,
            "__version__",
            "0.0.0"
        )

        if version.parse(installed_version) < version.parse(REQUIRED_LANGCHAIN_MCP_ADAPTERS):
            raise MCPCompatibilityError(
                f"langchain-mcp-adapters {installed_version} < "
                f"{REQUIRED_LANGCHAIN_MCP_ADAPTERS}"
            )

        logger.info(
            "mcp_adapter_version_ok",
            version=installed_version
        )

    except ImportError:
        raise MCPCompatibilityError("langchain-mcp-adapters not installed")

    # Check MCP protocol version from gateway (if exposed)
    # This is optional - not all gateways expose version
    try:
        # Future: Query gateway for protocol version
        # For now, assume compatible if connection works
        pass
    except Exception:
        logger.warning("mcp_protocol_version_check_skipped")

    return True


class MCPCompatibilityError(Exception):
    """Raised when MCP compatibility check fails."""
    pass
```

### 6.3 Specification Update for Version Requirements

**Update dependencies section (lines 582-609):**

Add under Python Dependencies:

```
# MCP Client
langchain-mcp-adapters>=0.1.0  # MCP tool integration
# Note: Requires MCP Protocol 1.0 compatibility
# Note: hx-fastmcp-server must be FastMCP >= 2.2.0
```

---

## 7. Production-Ready Integration Example

### 7.1 Complete MCP Module

```python
"""
MCP Client Module for hx-lang-server.

This module provides MCP client integration for consuming tools
from the hx-fastmcp-server gateway.

File: /opt/hx-lang-server/app/mcp/__init__.py
"""

from .client import (
    MCPClientWithCircuitBreaker,
    MCPToolManager,
    MCPConnectionManager,
    create_mcp_client,
)

from .errors import (
    MCPCircuitOpenError,
    MCPToolTimeoutError,
    MCPToolNotFoundError,
    MCPNotConnectedError,
    MCPCompatibilityError,
)

from .health import check_mcp_health

__all__ = [
    "MCPClientWithCircuitBreaker",
    "MCPToolManager",
    "MCPConnectionManager",
    "create_mcp_client",
    "MCPCircuitOpenError",
    "MCPToolTimeoutError",
    "MCPToolNotFoundError",
    "MCPNotConnectedError",
    "MCPCompatibilityError",
    "check_mcp_health",
]
```

### 7.2 Tool Agent Integration

```python
"""
Tool Agent implementation with MCP integration.

File: /opt/hx-lang-server/app/agents/tool_agent.py
"""

from typing import Dict, Any, Optional
from langchain_core.messages import AIMessage, ToolMessage
from langgraph.prebuilt import ToolNode
import structlog

from app.mcp import MCPToolManager, MCPToolTimeoutError, MCPCircuitOpenError
from app.state import AgentState

logger = structlog.get_logger()


class ToolAgent:
    """
    Tool Agent that invokes MCP tools via gateway.

    This agent:
    1. Receives tool calls from supervisor/other agents
    2. Resolves tool names to gateway format
    3. Invokes tools via MCP client
    4. Returns results to state
    """

    def __init__(self, mcp_tool_manager: MCPToolManager):
        self.tool_manager = mcp_tool_manager
        self._tool_node: Optional[ToolNode] = None

    async def initialize(self) -> None:
        """Initialize agent with discovered tools."""
        await self.tool_manager.discover_tools()
        self._tool_node = self.tool_manager.get_tool_node()

        logger.info(
            "tool_agent_initialized",
            tools=list(self.tool_manager.list_tools_by_domain().keys())
        )

    async def __call__(self, state: AgentState) -> Dict[str, Any]:
        """
        Process tool calls from state.

        Args:
            state: Current agent state with messages

        Returns:
            State update with tool results
        """
        if self._tool_node is None:
            logger.error("tool_agent_not_initialized")
            return {"last_tool_error": "Tool agent not initialized"}

        last_message = state["messages"][-1]

        # Check if there are tool calls to process
        if not isinstance(last_message, AIMessage):
            return {}

        if not last_message.tool_calls:
            return {}

        logger.info(
            "tool_agent_processing",
            tool_count=len(last_message.tool_calls),
            tools=[tc["name"] for tc in last_message.tool_calls]
        )

        try:
            # Invoke tools via ToolNode
            result = await self._tool_node.ainvoke(state)

            # Update invocation count
            new_count = state.get("tool_invocation_count", 0) + len(last_message.tool_calls)

            logger.info(
                "tool_agent_complete",
                invocation_count=new_count
            )

            return {
                "messages": result.get("messages", []),
                "tool_invocation_count": new_count,
                "last_tool_error": None
            }

        except MCPCircuitOpenError as e:
            logger.warning("tool_agent_circuit_open", error=str(e))
            return {
                "messages": [
                    ToolMessage(
                        content=f"Tool service temporarily unavailable: {e}",
                        tool_call_id=last_message.tool_calls[0]["id"]
                    )
                ],
                "last_tool_error": "circuit_open"
            }

        except MCPToolTimeoutError as e:
            logger.warning("tool_agent_timeout", error=str(e))
            return {
                "messages": [
                    ToolMessage(
                        content=f"Tool execution timed out: {e}",
                        tool_call_id=last_message.tool_calls[0]["id"]
                    )
                ],
                "last_tool_error": "timeout"
            }

        except Exception as e:
            logger.error("tool_agent_error", error=str(e))
            return {
                "messages": [
                    ToolMessage(
                        content=f"Tool execution failed: {e}",
                        tool_call_id=last_message.tool_calls[0]["id"]
                    )
                ],
                "last_tool_error": str(e)
            }
```

---

## 8. Validation of Current Specification

### 8.1 Correct Elements (No Changes Needed)

| Section | Lines | Assessment |
|---------|-------|------------|
| MCP Client Architecture Clarification | 420-423 | **Correct** - Properly identifies hx-lang-server as CLIENT |
| MCP Library Selection | 25, 279, 589 | **Correct** - langchain-mcp-adapters is appropriate |
| Tool Namespace Handling | 449-454 | **Correct** - Acknowledges prefix pattern |
| FastMCP Gateway Endpoint | 434, 578, 643 | **Correct** - Uses hx-fastmcp-server.hx.dev.local:8000 |
| FR-017 through FR-020 | 89-93 | **Correct** - Proper MCP requirements |

### 8.2 Recommended Additions

| Topic | Current State | Recommendation |
|-------|---------------|----------------|
| Transport Type | Specified as streamable_http | Add transport selection rationale |
| Error Handling | Not specified | Add FR-MCP-001 through FR-MCP-004 |
| Circuit Breaker | Not specified | Add to NFR section |
| Connection Lifecycle | Brief mention | Add lifespan integration pattern |
| Version Requirements | Not specified | Add version table |
| Tool Caching | Mentioned in charter review | Add implementation pattern |
| Health Check | Has FastMCP in dependencies | Ensure MCP-specific health check |

### 8.3 Recommended Corrections

| Topic | Current State | Correction |
|-------|---------------|------------|
| Client Configuration | Uses `servers=` parameter | Should use dict directly |
| Tool Name Format | Shows `crawl4ai__` | Verify actual delimiter with gateway |
| Environment Variable | `FASTMCP_URL` | Should end with `/mcp` endpoint |

---

## 9. Summary of Recommendations

### 9.1 High Priority (Add to Specification)

1. **Add MCP Error Handling Section** with FR-MCP-001 through FR-MCP-004
2. **Add Circuit Breaker Requirement** to NFR section
3. **Add Version Requirements Table** for MCP components
4. **Add Lifespan Integration Pattern** for connection lifecycle

### 9.2 Medium Priority (Enhance Specification)

5. **Expand Tool Namespace Section** with MCPToolManager pattern
6. **Add MCP Health Check Pattern** to monitoring section
7. **Add Reconnection Handling** requirements
8. **Document Transport Selection Rationale**

### 9.3 Low Priority (Clarifications)

9. **Verify Tool Name Delimiter** with actual gateway configuration
10. **Document Tool Caching Strategy** for performance
11. **Add MCP Metrics** to observability section

---

## 10. Coordination Notes

### 10.1 Dependencies on Other SMEs

| SME | Coordination Topic |
|-----|-------------------|
| **Sophia (LangGraph)** | Tool Agent node integration with MCP tools |
| **Bob (FastAPI)** | Lifespan integration, health endpoint |
| **David (Crawl4AI MCP)** | Validate tool schemas and naming |
| **William (Infrastructure)** | Network connectivity, DNS resolution |

### 10.2 Validation Requirements

Before implementation:
1. Verify hx-fastmcp-server is operational and accepting connections
2. Confirm tool prefix delimiter format (`__` vs `_`)
3. Validate MCP protocol version compatibility
4. Test tool discovery with actual gateway

---

**Signature:** George (FastMCP Gateway SME)
**Date:** 2025-12-01
**Review Status:** CONTRIBUTION COMPLETE
