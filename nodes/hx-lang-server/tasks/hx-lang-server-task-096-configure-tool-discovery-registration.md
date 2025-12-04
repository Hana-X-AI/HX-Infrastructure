# Task: Configure Tool Discovery and Registration

**Task ID**: hx-lang-server-task-096-configure-tool-discovery-registration
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-095 (v1.0 fallback mechanism)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 40 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-019)

---

## Objective

Configure automatic tool discovery from the FastMCP gateway and register discovered tools with LangGraph agents. This enables the Tool Agent to invoke MCP tools dynamically without hardcoded tool definitions.

**Requirement (FR-019)**: Service MUST support tool discovery and invocation for Crawl4AI MCP

---

## Prerequisites

- [ ] v1.0 fallback mechanism implemented (task-095)
- [ ] MCP client module configured (task-091)
- [ ] Tool namespace handling implemented (task-093)

---

## Implementation Steps

### Step 1: Create Tool Registry Module

Create file `/opt/hx-lang-server/app/mcp/registry.py`:

```python
"""
MCP Tool Registry for hx-lang-server.

Provides automatic tool discovery from FastMCP gateway and
registration of discovered tools for use by LangGraph agents.

Per FR-019: Support tool discovery and invocation for Crawl4AI MCP.
"""

import logging
from typing import Dict, Any, Optional, List, Set
from dataclasses import dataclass, field
import asyncio

from .client import MCPClientManager, get_mcp_client
from .namespace import (
    parse_tool_name,
    get_namespace,
    is_known_namespace,
    filter_tools_by_namespace,
    group_tools_by_namespace,
    KNOWN_NAMESPACES,
)
from .protocol import get_feature_detector

logger = logging.getLogger(__name__)


@dataclass
class RegisteredTool:
    """Represents a registered MCP tool."""
    name: str                          # Full namespaced name
    namespace: Optional[str]           # Source namespace
    base_name: str                     # Name without namespace
    description: str                   # Tool description
    input_schema: Dict[str, Any]       # JSON schema for parameters
    langchain_tool: Any               # LangChain tool object
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "name": self.name,
            "namespace": self.namespace,
            "base_name": self.base_name,
            "description": self.description,
            "input_schema": self.input_schema,
            "metadata": self.metadata,
        }


class MCPToolRegistry:
    """
    Registry for MCP tools discovered from FastMCP gateway.

    Provides:
    - Automatic tool discovery on startup
    - Tool caching with refresh capability
    - Namespace-based filtering
    - LangChain tool conversion
    """

    def __init__(self):
        self._tools: Dict[str, RegisteredTool] = {}
        self._raw_tools: List[Any] = []
        self._discovery_complete: bool = False
        self._last_discovery_time: Optional[float] = None
        self._discovery_lock: asyncio.Lock = asyncio.Lock()

    async def discover_tools(self, force_refresh: bool = False) -> int:
        """
        Discover tools from FastMCP gateway.

        Args:
            force_refresh: Force rediscovery even if cached

        Returns:
            Number of tools discovered
        """
        async with self._discovery_lock:
            if self._discovery_complete and not force_refresh:
                logger.debug("Using cached tool discovery results")
                return len(self._tools)

            logger.info("Starting MCP tool discovery from gateway")

            try:
                # Get MCP client
                mcp_manager = await get_mcp_client()

                # Discover tools
                raw_tools = await mcp_manager.get_tools(refresh=force_refresh)
                self._raw_tools = raw_tools

                # Register each tool
                self._tools.clear()
                for tool in raw_tools:
                    await self._register_tool(tool)

                # Mark discovery complete
                self._discovery_complete = True
                import time
                self._last_discovery_time = time.time()

                logger.info(
                    f"MCP tool discovery complete: {len(self._tools)} tools registered",
                    extra={
                        "tool_count": len(self._tools),
                        "namespaces": list(self.get_namespaces()),
                    }
                )

                return len(self._tools)

            except Exception as e:
                logger.error(
                    f"MCP tool discovery failed: {e}",
                    exc_info=True
                )
                raise

    async def _register_tool(self, tool: Any) -> None:
        """
        Register a single tool from discovery.

        Args:
            tool: LangChain tool object from discovery
        """
        try:
            # Extract tool information
            name = getattr(tool, 'name', None)
            if not name:
                logger.warning("Tool has no name, skipping registration")
                return

            description = getattr(tool, 'description', '')
            input_schema = getattr(tool, 'args_schema', None)

            # Parse namespace
            parsed = parse_tool_name(name)

            # Create registered tool
            registered = RegisteredTool(
                name=name,
                namespace=parsed.namespace,
                base_name=parsed.base_name,
                description=description,
                input_schema=input_schema.schema() if input_schema else {},
                langchain_tool=tool,
                metadata={
                    "is_namespaced": parsed.is_namespaced,
                    "known_namespace": is_known_namespace(parsed.namespace) if parsed.namespace else False,
                }
            )

            self._tools[name] = registered

            logger.debug(
                f"Registered tool: {name}",
                extra={
                    "tool_name": name,
                    "namespace": parsed.namespace,
                    "base_name": parsed.base_name,
                }
            )

        except Exception as e:
            logger.warning(f"Failed to register tool: {e}")

    def get_tool(self, name: str) -> Optional[RegisteredTool]:
        """
        Get a registered tool by name.

        Args:
            name: Full tool name

        Returns:
            RegisteredTool or None
        """
        return self._tools.get(name)

    def get_langchain_tool(self, name: str) -> Optional[Any]:
        """
        Get the LangChain tool object for a tool name.

        Args:
            name: Full tool name

        Returns:
            LangChain tool object or None
        """
        registered = self._tools.get(name)
        return registered.langchain_tool if registered else None

    def get_all_tools(self) -> List[RegisteredTool]:
        """
        Get all registered tools.

        Returns:
            List of RegisteredTool objects
        """
        return list(self._tools.values())

    def get_langchain_tools(self) -> List[Any]:
        """
        Get all LangChain tool objects for use with agents.

        Returns:
            List of LangChain tool objects
        """
        return [t.langchain_tool for t in self._tools.values()]

    def get_tools_by_namespace(self, namespace: str) -> List[RegisteredTool]:
        """
        Get tools from a specific namespace.

        Args:
            namespace: Namespace to filter by (e.g., 'crawl4ai')

        Returns:
            List of RegisteredTool objects from namespace
        """
        return [
            t for t in self._tools.values()
            if t.namespace == namespace
        ]

    def get_namespaces(self) -> Set[str]:
        """
        Get all namespaces with registered tools.

        Returns:
            Set of namespace strings
        """
        return {t.namespace for t in self._tools.values() if t.namespace}

    def list_tools(self, namespace: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        List tools with optional namespace filter.

        Args:
            namespace: Optional namespace filter

        Returns:
            List of tool information dicts
        """
        tools = self._tools.values()

        if namespace:
            tools = [t for t in tools if t.namespace == namespace]

        return [
            {
                "name": t.name,
                "namespace": t.namespace,
                "description": t.description[:100] + "..." if len(t.description) > 100 else t.description,
            }
            for t in tools
        ]

    def search_tools(self, query: str) -> List[RegisteredTool]:
        """
        Search tools by name or description.

        Args:
            query: Search query string

        Returns:
            List of matching RegisteredTool objects
        """
        query_lower = query.lower()
        return [
            t for t in self._tools.values()
            if query_lower in t.name.lower() or query_lower in t.description.lower()
        ]

    def is_discovery_complete(self) -> bool:
        """Check if tool discovery has completed."""
        return self._discovery_complete

    def get_discovery_stats(self) -> Dict[str, Any]:
        """
        Get tool discovery statistics.

        Returns:
            Dict with discovery stats
        """
        tools_by_namespace = {}
        for t in self._tools.values():
            ns = t.namespace or "_local"
            if ns not in tools_by_namespace:
                tools_by_namespace[ns] = 0
            tools_by_namespace[ns] += 1

        return {
            "discovery_complete": self._discovery_complete,
            "last_discovery_time": self._last_discovery_time,
            "total_tools": len(self._tools),
            "namespaces": list(self.get_namespaces()),
            "tools_by_namespace": tools_by_namespace,
        }


# Singleton instance
_tool_registry: Optional[MCPToolRegistry] = None


async def get_tool_registry() -> MCPToolRegistry:
    """
    Get or create the tool registry singleton.

    Returns:
        MCPToolRegistry instance
    """
    global _tool_registry

    if _tool_registry is None:
        _tool_registry = MCPToolRegistry()

    return _tool_registry


async def discover_and_register_tools(force_refresh: bool = False) -> int:
    """
    Convenience function to discover and register tools.

    Args:
        force_refresh: Force rediscovery

    Returns:
        Number of tools discovered
    """
    registry = await get_tool_registry()
    return await registry.discover_tools(force_refresh)


async def get_crawl4ai_tools() -> List[Any]:
    """
    Get LangChain tools specifically from crawl4ai namespace.

    Per FR-019: Support tool discovery and invocation for Crawl4AI MCP.

    Returns:
        List of LangChain tools from crawl4ai
    """
    registry = await get_tool_registry()

    if not registry.is_discovery_complete():
        await registry.discover_tools()

    crawl4ai_registered = registry.get_tools_by_namespace("crawl4ai")

    return [t.langchain_tool for t in crawl4ai_registered]


async def get_tools_for_agent(
    namespaces: Optional[List[str]] = None
) -> List[Any]:
    """
    Get LangChain tools for use with a LangGraph agent.

    Args:
        namespaces: Optional list of namespaces to include.
                   If None, returns all tools.

    Returns:
        List of LangChain tool objects
    """
    registry = await get_tool_registry()

    if not registry.is_discovery_complete():
        await registry.discover_tools()

    if namespaces is None:
        return registry.get_langchain_tools()

    tools = []
    for ns in namespaces:
        tools.extend([
            t.langchain_tool
            for t in registry.get_tools_by_namespace(ns)
        ])

    return tools
```

### Step 2: Update MCP Module Init

Update `/opt/hx-lang-server/app/mcp/__init__.py` to export registry:

```python
"""MCP Client Integration Module for hx-lang-server."""

from .client import MCPClientManager, get_mcp_client
from .gateway import (
    get_gateway_url,
    get_gateway_mcp_endpoint,
    get_server_config,
    check_gateway_health,
    GATEWAY_HOSTNAME,
    GATEWAY_PORT,
)
from .namespace import (
    parse_tool_name,
    build_namespaced_name,
    get_namespace,
    get_base_name,
    is_known_namespace,
    filter_tools_by_namespace,
    group_tools_by_namespace,
    validate_namespaced_tool,
    ToolNamespaceResolver,
    NAMESPACE_SEPARATOR,
    KNOWN_NAMESPACES,
    ParsedToolName,
)
from .protocol import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    get_feature_detector,
    detect_server_version,
    V1_0_FEATURES,
    V1_1_FEATURES,
)
from .fallback import (
    FallbackReason,
    FallbackContext,
    MCPFallbackHandler,
    get_fallback_handler,
    with_v10_fallback,
)
from .registry import (
    RegisteredTool,
    MCPToolRegistry,
    get_tool_registry,
    discover_and_register_tools,
    get_crawl4ai_tools,
    get_tools_for_agent,
)

__all__ = [
    # Client
    "MCPClientManager",
    "get_mcp_client",
    # Gateway
    "get_gateway_url",
    "get_gateway_mcp_endpoint",
    "get_server_config",
    "check_gateway_health",
    "GATEWAY_HOSTNAME",
    "GATEWAY_PORT",
    # Namespace
    "parse_tool_name",
    "build_namespaced_name",
    "get_namespace",
    "get_base_name",
    "is_known_namespace",
    "filter_tools_by_namespace",
    "group_tools_by_namespace",
    "validate_namespaced_tool",
    "ToolNamespaceResolver",
    "NAMESPACE_SEPARATOR",
    "KNOWN_NAMESPACES",
    "ParsedToolName",
    # Protocol
    "MCPVersion",
    "MCPFeature",
    "ServerCapabilities",
    "MCPFeatureDetector",
    "get_feature_detector",
    "detect_server_version",
    "V1_0_FEATURES",
    "V1_1_FEATURES",
    # Fallback
    "FallbackReason",
    "FallbackContext",
    "MCPFallbackHandler",
    "get_fallback_handler",
    "with_v10_fallback",
    # Registry
    "RegisteredTool",
    "MCPToolRegistry",
    "get_tool_registry",
    "discover_and_register_tools",
    "get_crawl4ai_tools",
    "get_tools_for_agent",
]
```

### Step 3: Verify Module Structure

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Verify imports
python -c "
from app.mcp import (
    RegisteredTool,
    MCPToolRegistry,
    get_tool_registry,
    discover_and_register_tools,
    get_crawl4ai_tools,
    get_tools_for_agent,
)

print('RegisteredTool:', RegisteredTool)
print('MCPToolRegistry:', MCPToolRegistry)
print('get_tool_registry:', get_tool_registry)
print('discover_and_register_tools:', discover_and_register_tools)
print('get_crawl4ai_tools:', get_crawl4ai_tools)
print('get_tools_for_agent:', get_tools_for_agent)
print('All registry imports successful')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Registry module | `/opt/hx-lang-server/app/mcp/registry.py` | Tool discovery |
| Updated module init | `/opt/hx-lang-server/app/mcp/__init__.py` | Registry exports |

---

## Verification Steps

- [ ] `registry.py` module created
- [ ] RegisteredTool dataclass captures tool information
- [ ] MCPToolRegistry.discover_tools() discovers from gateway
- [ ] MCPToolRegistry.get_langchain_tools() returns LangChain tools
- [ ] MCPToolRegistry.get_tools_by_namespace() filters by namespace
- [ ] get_crawl4ai_tools() returns crawl4ai namespace tools
- [ ] get_tools_for_agent() returns tools for LangGraph agents

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    RegisteredTool,
    MCPToolRegistry,
    get_tool_registry,
)

tests_passed = 0

# Test 1: RegisteredTool dataclass
tool = RegisteredTool(
    name='crawl4ai__smart_crawl_url',
    namespace='crawl4ai',
    base_name='smart_crawl_url',
    description='Crawl a URL',
    input_schema={'type': 'object'},
    langchain_tool=None,
)
assert tool.name == 'crawl4ai__smart_crawl_url'
tests_passed += 1

# Test 2: RegisteredTool.to_dict()
tool_dict = tool.to_dict()
assert 'name' in tool_dict
assert 'namespace' in tool_dict
tests_passed += 1

# Test 3: MCPToolRegistry instantiation
registry = MCPToolRegistry()
assert registry._tools == {}
assert registry._discovery_complete == False
tests_passed += 1

# Test 4: Registry methods exist
assert hasattr(registry, 'discover_tools')
assert hasattr(registry, 'get_tool')
assert hasattr(registry, 'get_langchain_tools')
assert hasattr(registry, 'get_tools_by_namespace')
tests_passed += 1

# Test 5: get_discovery_stats
stats = registry.get_discovery_stats()
assert 'discovery_complete' in stats
assert 'total_tools' in stats
tests_passed += 1

print(f'All {tests_passed} registry tests passed!')
"
```

---

## Acceptance Criteria

1. **AC-096-1**: RegisteredTool dataclass captures name, namespace, description, schema
2. **AC-096-2**: MCPToolRegistry.discover_tools() discovers tools from gateway
3. **AC-096-3**: MCPToolRegistry.get_langchain_tools() returns LangChain-compatible tools
4. **AC-096-4**: MCPToolRegistry.get_tools_by_namespace("crawl4ai") filters correctly
5. **AC-096-5**: get_crawl4ai_tools() returns Crawl4AI tools (per FR-019)
6. **AC-096-6**: get_tools_for_agent() returns tools ready for LangGraph
7. **AC-096-7**: Tool discovery results are cached until refresh

---

## Rollback Procedure

```bash
sudo rm /opt/hx-lang-server/app/mcp/registry.py

# Restore previous __init__.py (from task-095 state)
```

---

## Notes

- FR-019 requires support for tool discovery and invocation for Crawl4AI MCP
- get_crawl4ai_tools() specifically addresses this requirement
- Tool discovery is async and should run during application startup
- Registry caches tools to avoid repeated discovery calls
- LangChain tool objects are preserved for direct use with LangGraph
- force_refresh parameter allows manual tool cache invalidation
- Discovery statistics help with monitoring and debugging

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
