# Task: Configure langchain-mcp-adapters Client Module

**Task ID**: hx-lang-server-task-091-configure-langchain-mcp-adapters-client
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-024 (langchain-mcp-adapters installed)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 30 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-017, FR-020a)

---

## Objective

Configure the langchain-mcp-adapters client module to enable hx-lang-server to function as an MCP CLIENT that connects to external MCP servers (primarily the FastMCP gateway). This establishes the foundation for tool discovery and invocation.

**Architecture Clarification**: hx-lang-server is an MCP CLIENT, NOT an MCP server. It consumes tools from MCP servers via langchain-mcp-adapters.

---

## Prerequisites

- [ ] langchain-mcp-adapters package installed (task-024)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Application directory structure exists at `/opt/hx-lang-server/app/`

---

## Implementation Steps

### Step 1: Create MCP Client Module Directory

```bash
sudo -u hx-lang-server mkdir -p /opt/hx-lang-server/app/mcp
```

### Step 2: Create MCP Client Configuration Module

Create file `/opt/hx-lang-server/app/mcp/__init__.py`:

```python
"""MCP Client Integration Module for hx-lang-server."""

from .client import MCPClientManager, get_mcp_client

__all__ = ["MCPClientManager", "get_mcp_client"]
```

### Step 3: Create MCP Client Manager Module

Create file `/opt/hx-lang-server/app/mcp/client.py`:

```python
"""
MCP Client Manager for hx-lang-server.

This module provides the MCP client configuration for connecting
to FastMCP gateway and invoking MCP tools.

hx-lang-server is an MCP CLIENT (consumer of MCP tools),
NOT an MCP server (provider of MCP tools).
"""

import logging
from typing import Optional, Dict, Any, List
from langchain_mcp_adapters.client import MultiServerMCPClient

from app.config import settings

logger = logging.getLogger(__name__)


class MCPClientManager:
    """
    Manages MCP client connections to FastMCP gateway.

    Provides:
    - Connection lifecycle management
    - Tool discovery caching
    - Error handling and retry logic
    """

    def __init__(self):
        self._client: Optional[MultiServerMCPClient] = None
        self._tools_cache: Optional[List[Any]] = None

    async def initialize(self) -> None:
        """Initialize MCP client connection to FastMCP gateway."""
        logger.info("Initializing MCP client connection")

        # Configure server connections
        # FastMCP gateway provides unified access to all MCP servers
        servers_config = {
            "fastmcp": {
                "transport": "streamable_http",
                "url": f"{settings.fastmcp_url}/mcp",
            }
        }

        self._client = MultiServerMCPClient(servers=servers_config)

        logger.info(
            "MCP client configured",
            extra={
                "gateway_url": settings.fastmcp_url,
                "transport": "streamable_http"
            }
        )

    @property
    def client(self) -> Optional[MultiServerMCPClient]:
        """Return the MCP client instance."""
        return self._client

    async def get_tools(self, refresh: bool = False) -> List[Any]:
        """
        Discover and return available MCP tools.

        Args:
            refresh: Force refresh of tool cache

        Returns:
            List of LangChain-compatible tool objects
        """
        if self._client is None:
            raise RuntimeError("MCP client not initialized. Call initialize() first.")

        if self._tools_cache is None or refresh:
            logger.info("Discovering MCP tools from gateway")
            self._tools_cache = await self._client.get_tools()
            logger.info(
                f"Discovered {len(self._tools_cache)} MCP tools",
                extra={"tool_count": len(self._tools_cache)}
            )

        return self._tools_cache

    async def invoke_tool(
        self,
        tool_name: str,
        arguments: Dict[str, Any]
    ) -> Any:
        """
        Invoke an MCP tool by name.

        Args:
            tool_name: Namespaced tool name (e.g., 'crawl4ai__smart_crawl_url')
            arguments: Tool arguments as dictionary

        Returns:
            Tool invocation result
        """
        if self._client is None:
            raise RuntimeError("MCP client not initialized. Call initialize() first.")

        logger.info(
            f"Invoking MCP tool: {tool_name}",
            extra={
                "tool_name": tool_name,
                "arguments_keys": list(arguments.keys())
            }
        )

        result = await self._client.invoke_tool(tool_name, arguments)

        logger.info(
            f"MCP tool invocation complete: {tool_name}",
            extra={"tool_name": tool_name}
        )

        return result

    async def close(self) -> None:
        """Close MCP client connection."""
        if self._client is not None:
            # Clear cached tools
            self._tools_cache = None
            self._client = None
            logger.info("MCP client connection closed")


# Singleton instance
_mcp_manager: Optional[MCPClientManager] = None


async def get_mcp_client() -> MCPClientManager:
    """
    Get or create the MCP client manager singleton.

    Returns:
        MCPClientManager instance
    """
    global _mcp_manager

    if _mcp_manager is None:
        _mcp_manager = MCPClientManager()
        await _mcp_manager.initialize()

    return _mcp_manager
```

### Step 4: Verify Module Structure

```bash
ls -la /opt/hx-lang-server/app/mcp/
```

Expected output:
```
__init__.py
client.py
```

### Step 5: Verify Python Imports

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server
python -c "
from app.mcp import MCPClientManager, get_mcp_client
print('MCPClientManager imported successfully')
print(f'MCPClientManager class: {MCPClientManager}')
print(f'get_mcp_client function: {get_mcp_client}')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| MCP module directory | `/opt/hx-lang-server/app/mcp/` | Module directory |
| Module init file | `/opt/hx-lang-server/app/mcp/__init__.py` | Module exports |
| MCP client manager | `/opt/hx-lang-server/app/mcp/client.py` | Client implementation |

---

## Verification Steps

- [ ] MCP module directory exists at `/opt/hx-lang-server/app/mcp/`
- [ ] `__init__.py` exports MCPClientManager and get_mcp_client
- [ ] `client.py` contains MCPClientManager class
- [ ] Python imports work without errors
- [ ] MCPClientManager has initialize(), get_tools(), invoke_tool(), close() methods

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Verify file structure
ls -la /opt/hx-lang-server/app/mcp/

# Verify imports
python -c "
from app.mcp import MCPClientManager, get_mcp_client
import inspect

# Verify class methods
methods = [m for m in dir(MCPClientManager) if not m.startswith('_')]
print(f'MCPClientManager methods: {methods}')

# Verify async methods exist
assert hasattr(MCPClientManager, 'initialize'), 'Missing initialize method'
assert hasattr(MCPClientManager, 'get_tools'), 'Missing get_tools method'
assert hasattr(MCPClientManager, 'invoke_tool'), 'Missing invoke_tool method'
assert hasattr(MCPClientManager, 'close'), 'Missing close method'

print('All verification checks passed')
"
```

---

## Acceptance Criteria

1. **AC-091-1**: MCP module directory exists at `/opt/hx-lang-server/app/mcp/`
2. **AC-091-2**: MCPClientManager class is importable from `app.mcp`
3. **AC-091-3**: MCPClientManager supports async initialize/close lifecycle
4. **AC-091-4**: MCPClientManager provides get_tools() for tool discovery
5. **AC-091-5**: MCPClientManager provides invoke_tool() for tool execution
6. **AC-091-6**: Configuration reads FastMCP URL from settings

---

## Rollback Procedure

```bash
sudo rm -rf /opt/hx-lang-server/app/mcp/
```

---

## Notes

- hx-lang-server is an MCP CLIENT, consuming tools from MCP servers
- FastMCP gateway at hx-fastmcp-server.hx.dev.local provides unified tool access
- langchain-mcp-adapters provides LangChain-compatible tool wrappers
- Tool discovery is async - must use `await` for get_tools()
- CAIO decision: MCP v1.1 with feature detection (FR-020a) - implemented in task-094
- Connection uses streamable_http transport per FastMCP v2.0 recommendation
- Singleton pattern ensures single client instance across application

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
