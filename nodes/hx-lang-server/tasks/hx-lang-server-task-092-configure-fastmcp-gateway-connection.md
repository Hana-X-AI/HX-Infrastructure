# Task: Configure FastMCP Gateway Connection

**Task ID**: hx-lang-server-task-092-configure-fastmcp-gateway-connection
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-091 (MCP client module)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 25 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-018)

---

## Objective

Configure the FastMCP gateway connection parameters for hx-lang-server to connect to hx-fastmcp-server.hx.dev.local. This includes environment variable configuration, connection settings, and health check integration.

**Requirement (FR-018)**: Service MUST connect to FastMCP gateway at hx-fastmcp-server.hx.dev.local

---

## Prerequisites

- [ ] MCP client module created (task-091)
- [ ] Environment configuration module exists (task-141/142)
- [ ] Network connectivity to hx-fastmcp-server.hx.dev.local:8000

---

## Implementation Steps

### Step 1: Verify Environment Variable in Settings

Ensure `/opt/hx-lang-server/app/config.py` includes FastMCP URL:

```python
# In Settings class
fastmcp_url: str = Field(
    default="http://hx-fastmcp-server.hx.dev.local:8000",
    description="FastMCP gateway URL"
)
```

### Step 2: Update Environment File

Add to `/opt/hx-lang-server/.env`:

```bash
# MCP Gateway Configuration
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000
```

### Step 3: Create Gateway Connection Configuration Module

Create file `/opt/hx-lang-server/app/mcp/gateway.py`:

```python
"""
FastMCP Gateway Connection Configuration.

Configures connection to hx-fastmcp-server.hx.dev.local which provides
unified access to all MCP servers in the HX-Infrastructure ecosystem.

Available MCP servers via gateway:
- hx-crawl4ai-mcp-server (crawl4ai__* tools)
- hx-docling-mcp-server (docling__* tools)
"""

import logging
from typing import Dict, Any, Optional
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# FastMCP Gateway Configuration Constants
GATEWAY_HOSTNAME = "hx-fastmcp-server.hx.dev.local"
GATEWAY_PORT = 8000
GATEWAY_MCP_PATH = "/mcp"
GATEWAY_HEALTH_PATH = "/health"

# Connection timeouts (seconds)
CONNECT_TIMEOUT = 10.0
READ_TIMEOUT = 30.0
WRITE_TIMEOUT = 30.0

# Retry configuration
MAX_RETRIES = 3
RETRY_BACKOFF_FACTOR = 1.5


def get_gateway_url() -> str:
    """
    Get the FastMCP gateway base URL.

    Returns:
        Gateway URL from settings or default
    """
    return getattr(settings, 'fastmcp_url', f"http://{GATEWAY_HOSTNAME}:{GATEWAY_PORT}")


def get_gateway_mcp_endpoint() -> str:
    """
    Get the full MCP endpoint URL.

    Returns:
        Full URL for MCP protocol endpoint
    """
    return f"{get_gateway_url()}{GATEWAY_MCP_PATH}"


def get_gateway_health_endpoint() -> str:
    """
    Get the health check endpoint URL.

    Returns:
        Full URL for health check endpoint
    """
    return f"{get_gateway_url()}{GATEWAY_HEALTH_PATH}"


def get_server_config() -> Dict[str, Any]:
    """
    Get MultiServerMCPClient configuration for FastMCP gateway.

    Returns:
        Configuration dict for langchain-mcp-adapters
    """
    return {
        "fastmcp": {
            "transport": "streamable_http",
            "url": get_gateway_mcp_endpoint(),
        }
    }


def get_httpx_timeout() -> httpx.Timeout:
    """
    Get httpx timeout configuration for gateway requests.

    Returns:
        Configured httpx.Timeout object
    """
    return httpx.Timeout(
        connect=CONNECT_TIMEOUT,
        read=READ_TIMEOUT,
        write=WRITE_TIMEOUT,
        pool=None,  # No pool timeout
    )


async def check_gateway_health() -> Dict[str, Any]:
    """
    Check FastMCP gateway health status.

    Returns:
        Health status dict with 'healthy' boolean and details

    Example:
        {
            "healthy": True,
            "gateway_url": "http://hx-fastmcp-server.hx.dev.local:8000",
            "response_time_ms": 45.2,
            "server_info": {...}
        }
    """
    import time

    health_url = get_gateway_health_endpoint()
    start_time = time.time()

    try:
        async with httpx.AsyncClient(timeout=get_httpx_timeout()) as client:
            response = await client.get(health_url)
            response_time_ms = (time.time() - start_time) * 1000

            if response.status_code == 200:
                server_info = response.json() if response.content else {}
                logger.info(
                    "FastMCP gateway health check passed",
                    extra={
                        "gateway_url": get_gateway_url(),
                        "response_time_ms": round(response_time_ms, 2)
                    }
                )
                return {
                    "healthy": True,
                    "gateway_url": get_gateway_url(),
                    "response_time_ms": round(response_time_ms, 2),
                    "server_info": server_info
                }
            else:
                logger.warning(
                    f"FastMCP gateway returned non-200 status: {response.status_code}",
                    extra={
                        "gateway_url": get_gateway_url(),
                        "status_code": response.status_code
                    }
                )
                return {
                    "healthy": False,
                    "gateway_url": get_gateway_url(),
                    "error": f"HTTP {response.status_code}",
                    "response_time_ms": round(response_time_ms, 2)
                }

    except httpx.ConnectError as e:
        logger.error(
            f"Cannot connect to FastMCP gateway: {e}",
            extra={"gateway_url": get_gateway_url()}
        )
        return {
            "healthy": False,
            "gateway_url": get_gateway_url(),
            "error": f"Connection failed: {str(e)}"
        }
    except httpx.TimeoutException as e:
        logger.error(
            f"FastMCP gateway connection timeout: {e}",
            extra={"gateway_url": get_gateway_url()}
        )
        return {
            "healthy": False,
            "gateway_url": get_gateway_url(),
            "error": f"Timeout: {str(e)}"
        }
    except Exception as e:
        logger.error(
            f"FastMCP gateway health check failed: {e}",
            extra={"gateway_url": get_gateway_url()}
        )
        return {
            "healthy": False,
            "gateway_url": get_gateway_url(),
            "error": str(e)
        }
```

### Step 4: Update MCP Module Init

Update `/opt/hx-lang-server/app/mcp/__init__.py`:

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

__all__ = [
    "MCPClientManager",
    "get_mcp_client",
    "get_gateway_url",
    "get_gateway_mcp_endpoint",
    "get_server_config",
    "check_gateway_health",
    "GATEWAY_HOSTNAME",
    "GATEWAY_PORT",
]
```

### Step 5: Verify Network Connectivity

```bash
# Test DNS resolution
nslookup hx-fastmcp-server.hx.dev.local

# Test HTTP connectivity
curl -s -o /dev/null -w "%{http_code}" http://hx-fastmcp-server.hx.dev.local:8000/health

# Test from Python
source /opt/hx-lang-server/venv/bin/activate
python -c "
import httpx
import asyncio

async def test():
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get('http://hx-fastmcp-server.hx.dev.local:8000/health')
            print(f'Gateway health check: HTTP {resp.status_code}')
            if resp.status_code == 200:
                print('Gateway is reachable and healthy')
        except Exception as e:
            print(f'Gateway connection failed: {e}')

asyncio.run(test())
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Gateway configuration module | `/opt/hx-lang-server/app/mcp/gateway.py` | Connection configuration |
| Environment variable | `/opt/hx-lang-server/.env` | FASTMCP_URL setting |
| Updated module init | `/opt/hx-lang-server/app/mcp/__init__.py` | Gateway exports |

---

## Verification Steps

- [ ] FASTMCP_URL environment variable is set in `.env`
- [ ] `gateway.py` module created with connection functions
- [ ] `__init__.py` exports gateway functions
- [ ] DNS resolution works for hx-fastmcp-server.hx.dev.local
- [ ] HTTP connectivity works to gateway health endpoint

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Verify environment variable
grep FASTMCP_URL /opt/hx-lang-server/.env

# Verify module imports
python -c "
from app.mcp import (
    get_gateway_url,
    get_gateway_mcp_endpoint,
    get_server_config,
    check_gateway_health,
    GATEWAY_HOSTNAME,
    GATEWAY_PORT,
)

print(f'Gateway hostname: {GATEWAY_HOSTNAME}')
print(f'Gateway port: {GATEWAY_PORT}')
print(f'Gateway URL: {get_gateway_url()}')
print(f'MCP endpoint: {get_gateway_mcp_endpoint()}')
print(f'Server config: {get_server_config()}')
print('All imports successful')
"

# Test health check function
python -c "
import asyncio
from app.mcp import check_gateway_health

async def test():
    result = await check_gateway_health()
    print(f'Health check result: {result}')
    return result['healthy']

healthy = asyncio.run(test())
print(f'Gateway healthy: {healthy}')
"
```

---

## Acceptance Criteria

1. **AC-092-1**: FASTMCP_URL environment variable configured in `.env`
2. **AC-092-2**: Gateway module provides get_gateway_url() returning correct URL
3. **AC-092-3**: Gateway module provides get_gateway_mcp_endpoint() for MCP protocol
4. **AC-092-4**: Gateway module provides get_server_config() for MultiServerMCPClient
5. **AC-092-5**: check_gateway_health() returns health status dict
6. **AC-092-6**: Network connectivity verified to hx-fastmcp-server.hx.dev.local:8000

---

## Rollback Procedure

```bash
# Remove gateway module
sudo rm /opt/hx-lang-server/app/mcp/gateway.py

# Remove environment variable
sudo sed -i '/FASTMCP_URL/d' /opt/hx-lang-server/.env

# Restore original __init__.py
sudo -u hx-lang-server bash -c 'cat > /opt/hx-lang-server/app/mcp/__init__.py << EOF
"""MCP Client Integration Module for hx-lang-server."""

from .client import MCPClientManager, get_mcp_client

__all__ = ["MCPClientManager", "get_mcp_client"]
EOF'
```

---

## Notes

- FastMCP gateway provides unified access to all MCP servers in HX-Infrastructure
- Gateway hostname uses DNS (hx-fastmcp-server.hx.dev.local), NOT hardcoded IP
- Default port 8000 is standard for FastMCP HTTP transport
- streamable_http transport recommended per FastMCP v2.0 documentation
- Health check integration enables dependency status in `/health` endpoint
- Connection timeouts configured for production reliability

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
