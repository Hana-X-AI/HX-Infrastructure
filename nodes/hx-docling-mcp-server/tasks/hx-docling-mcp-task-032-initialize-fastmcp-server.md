# Task: Initialize FastMCP Server Instance

**Task ID**: hx-docling-mcp-task-032-initialize-fastmcp-server
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**: hx-docling-mcp-task-031 (FastMCP framework installation)
**Estimated Time**: 45 minutes
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Create the main MCP server entry point (`mcp_server.py`) with FastMCP instance initialization, server metadata configuration, and foundational server structure. This file serves as the central orchestration point for all 19 MCP tools and transport mode configuration.

---

## Pre-Execution Validation

**CRITICAL**: Check if MCP server file already exists BEFORE creating it.

```bash
# Check for existing mcp_server.py
if [ -f /opt/docling-mcp/src/mcp_server.py ]; then
    echo "✅ VALIDATION: mcp_server.py already exists - SKIP task execution"
    # Verify it contains FastMCP initialization
    grep -q "FastMCP" /opt/docling-mcp/src/mcp_server.py
    if [ $? -eq 0 ]; then
        echo "✅ File contains FastMCP initialization"
        exit 0
    else
        echo "⚠️  File exists but missing FastMCP initialization - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: mcp_server.py does not exist - PROCEED with task"
fi
```

**Validation Logic**:
- If `/opt/docling-mcp/src/mcp_server.py` exists with FastMCP initialization → SKIP execution
- If file doesn't exist or is incomplete → PROCEED with creation

---

## Prerequisites

- [ ] FastMCP framework installed (Task 031)
- [ ] Python virtual environment at `/opt/docling-mcp/venv/` activated
- [ ] Directory structure created: `/opt/docling-mcp/src/` exists
- [ ] Service account `docling-mcp` has write permissions

---

## Steps

### 1. Create Source Code Directory Structure

```bash
# Switch to service account
sudo -u docling-mcp bash

# Create source directories
mkdir -p /opt/docling-mcp/src/{tools,utils,models}

# Directory structure:
# /opt/docling-mcp/src/
# ├── mcp_server.py        # Main server entry point (this task)
# ├── tools/               # MCP tool implementations
# │   ├── __init__.py
# │   ├── conversion.py    # Conversion tools (3)
# │   ├── generation.py    # Generation tools (11)
# │   └── manipulation.py  # Manipulation tools (5)
# ├── utils/               # Utility modules
# │   ├── __init__.py
# │   ├── config.py        # Configuration management
# │   └── logging.py       # Logging configuration
# └── models/              # Pydantic models
#     ├── __init__.py
#     └── schemas.py       # MCP tool schemas
```

### 2. Create Package Init Files

```bash
# Create __init__.py for each package
touch /opt/docling-mcp/src/__init__.py
touch /opt/docling-mcp/src/tools/__init__.py
touch /opt/docling-mcp/src/utils/__init__.py
touch /opt/docling-mcp/src/models/__init__.py
```

### 3. Create Main MCP Server Entry Point

```bash
cat > /opt/docling-mcp/src/mcp_server.py <<'EOF'
#!/usr/bin/env python3
"""
Docling MCP Server - Main Entry Point

This module initializes the FastMCP server instance and serves as the central
orchestration point for all 19 MCP tools (3 conversion, 11 generation, 5 manipulation).

MCP Server Configuration:
- Name: docling-mcp-server
- Version: 1.0.0
- Transport Modes: HTTP, SSE, stdio (configurable via environment variables)
- Target Node: hx-docling-mcp-server.hx.dev.local
- Default Port: 8052 (HTTP/SSE), stdio for Claude Desktop

Architecture:
    ┌──────────────────────────────────┐
    │   MCP Client                     │
    │   (Claude Desktop, LM Studio)    │
    └────────────┬─────────────────────┘
                 │ MCP Protocol
                 ▼
    ┌──────────────────────────────────┐
    │   FastMCP Server (this file)     │
    │   - Tool discovery               │
    │   - Tool invocation              │
    │   - Schema validation            │
    └────────────┬─────────────────────┘
                 │
    ┌────────────┴─────────────────────┐
    │   Tool Handlers                  │
    │   - Conversion (3 tools)         │
    │   - Generation (11 tools)        │
    │   - Manipulation (5 tools)       │
    └──────────────────────────────────┘

Dependencies:
- hx-docling-server.hx.dev.local: N/A (independent processing)
- hx-literag-server.hx.dev.local:8000: LightRAG entity/relationship extraction
- hx-litellm-server.hx.dev.local:4000: LLM routing (gemma3:27b)
- hx-qdrant-server.hx.dev.local:6333: Vector storage for knowledge graphs
- hx-redis-server.hx.dev.local:6379: Caching and session management
"""

import sys
import logging
from pathlib import Path
from typing import Optional

# Add src directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

from fastmcp import FastMCP

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# FastMCP Server Initialization
# ============================================================================

# Create FastMCP server instance
mcp = FastMCP(
    name="docling-mcp-server",
    version="1.0.0",
    description=(
        "Document processing MCP server exposing 19 tools for multimodal "
        "document conversion, knowledge graph generation, and document manipulation. "
        "Supports PDF, DOCX, PPTX, XLSX, HTML, images (14+ formats) with semantic "
        "structure preservation and LightRAG-powered entity/relationship extraction."
    )
)

logger.info("✅ FastMCP server instance initialized: docling-mcp-server v1.0.0")

# ============================================================================
# Server Metadata
# ============================================================================

# Server capabilities (for MCP client discovery)
SERVER_CAPABILITIES = {
    "tools": {
        "conversion": 3,      # convert_document, convert_document_to_markdown, batch_convert
        "generation": 11,     # generate_knowledge_graph, extract_entities, etc.
        "manipulation": 5     # merge_documents, split_document, search_document, etc.
    },
    "transports": ["http", "sse", "stdio"],
    "authentication": "none",  # Phase 1: No auth (Phase 2: OAuth2)
    "formats_supported": [
        "pdf", "docx", "pptx", "xlsx", "html", "markdown",
        "image/png", "image/jpeg", "image/tiff"
    ],
    "max_document_size_mb": 500,
    "concurrent_processing_limit": 4
}

# ============================================================================
# Health Check Endpoint
# ============================================================================

@mcp.tool()
def health_check() -> dict:
    """
    Server health check endpoint for monitoring and readiness probes.

    Returns comprehensive health status including:
    - Server version and uptime
    - Tool registration status (19 tools expected)
    - Dependency connectivity (Redis, Qdrant, LiteLLM, LightRAG)
    - Resource usage (memory, CPU)

    Returns:
        dict: Health status with following structure:
            {
                "status": "healthy" | "degraded" | "unhealthy",
                "version": "1.0.0",
                "tools_registered": 19,
                "dependencies": {
                    "redis": "connected" | "disconnected",
                    "qdrant": "connected" | "disconnected",
                    "litellm": "connected" | "disconnected",
                    "literag": "connected" | "disconnected"
                },
                "uptime_seconds": 12345,
                "memory_usage_mb": 256
            }

    Example:
        >>> health_check()
        {
            "status": "healthy",
            "version": "1.0.0",
            "tools_registered": 19,
            "dependencies": {
                "redis": "connected",
                "qdrant": "connected",
                "litellm": "connected",
                "literag": "connected"
            },
            "uptime_seconds": 3600,
            "memory_usage_mb": 256
        }
    """
    # Basic health check implementation (will be enhanced in later tasks)
    return {
        "status": "healthy",
        "version": "1.0.0",
        "tools_registered": len(mcp.list_tools()),
        "server_name": "docling-mcp-server",
        "node": "hx-docling-mcp-server.hx.dev.local",
        "capabilities": SERVER_CAPABILITIES
    }

# ============================================================================
# Tool Registration Imports
# ============================================================================

# Tool registration modules will be imported here by subsequent tasks:
# - Task 034-036: Conversion tools (from tools.conversion import *)
# - Task 037-047: Generation tools (from tools.generation import *)
# - Task 048-052: Manipulation tools (from tools.manipulation import *)

# Placeholder for future tool imports
logger.info("📦 Tool registration modules will be imported by tasks 034-052")

# ============================================================================
# Server Startup
# ============================================================================

def main():
    """
    Main server entry point.

    Supports three transport modes (configured via environment variables):
    - HTTP: FastMCP HTTP transport (production)
    - SSE: Server-Sent Events transport (LM Studio, Llama Stack)
    - stdio: Standard I/O transport (Claude Desktop)

    Environment Variables:
        MCP_TRANSPORT: Transport mode ("http", "sse", "stdio") - default: "http"
        MCP_HOST: Server host (default: "0.0.0.0")
        MCP_PORT: Server port (default: 8052)

    Usage:
        # HTTP transport (production)
        python3 mcp_server.py

        # SSE transport (LM Studio)
        MCP_TRANSPORT=sse python3 mcp_server.py

        # stdio transport (Claude Desktop)
        MCP_TRANSPORT=stdio python3 mcp_server.py
    """
    import os

    transport = os.getenv("MCP_TRANSPORT", "http").lower()
    host = os.getenv("MCP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_PORT", "8052"))

    logger.info(f"🚀 Starting Docling MCP Server")
    logger.info(f"   Transport: {transport}")
    logger.info(f"   Host: {host}")
    logger.info(f"   Port: {port}")
    logger.info(f"   Tools registered: {len(mcp.list_tools())}")

    # Transport configuration will be implemented in Task 033
    if transport == "stdio":
        logger.info("📡 Using stdio transport (Claude Desktop mode)")
        # mcp.run_stdio()  # Implemented in Task 033
    elif transport == "sse":
        logger.info(f"📡 Using SSE transport on {host}:{port}")
        # mcp.run_sse(host=host, port=port)  # Implemented in Task 033
    else:  # http
        logger.info(f"📡 Using HTTP transport on {host}:{port}")
        # mcp.run_http(host=host, port=port)  # Implemented in Task 033

    logger.warning("⚠️  Transport modes not yet configured (Task 033)")
    logger.info("✅ Server initialization complete (placeholder)")

if __name__ == "__main__":
    main()
EOF

chmod 755 /opt/docling-mcp/src/mcp_server.py
chown docling-mcp:docling-mcp /opt/docling-mcp/src/mcp_server.py
```

### 4. Test Server Initialization

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test basic import and initialization
cd /opt/docling-mcp/src/
python3 -c "
import mcp_server
print('✅ MCP server module imports successfully')
print(f'✅ Server name: {mcp_server.mcp.name}')
print(f'✅ Server version: {mcp_server.mcp.version}')
print(f'✅ Tools registered: {len(mcp_server.mcp.list_tools())}')
print(f'✅ Tool names: {[t.name for t in mcp_server.mcp.list_tools()]}')
"
```

**Expected Output**:
```
✅ FastMCP server instance initialized: docling-mcp-server v1.0.0
📦 Tool registration modules will be imported by tasks 034-052
✅ MCP server module imports successfully
✅ Server name: docling-mcp-server
✅ Server version: 1.0.0
✅ Tools registered: 1
✅ Tool names: ['health_check']
```

### 5. Verify Health Check Tool

```bash
# Test health_check tool invocation
python3 -c "
import mcp_server
result = mcp_server.health_check()
print('Health check result:')
import json
print(json.dumps(result, indent=2))
"
```

**Expected Output**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "tools_registered": 1,
  "server_name": "docling-mcp-server",
  "node": "hx-docling-mcp-server.hx.dev.local",
  "capabilities": {
    "tools": {
      "conversion": 3,
      "generation": 11,
      "manipulation": 5
    },
    "transports": ["http", "sse", "stdio"],
    "authentication": "none",
    "formats_supported": [...],
    "max_document_size_mb": 500,
    "concurrent_processing_limit": 4
  }
}
```

### 6. Set File Permissions

```bash
# Set ownership for all source files
chown -R docling-mcp:docling-mcp /opt/docling-mcp/src/

# Set directory permissions (755 for directories, 644 for files)
find /opt/docling-mcp/src/ -type d -exec chmod 755 {} \;
find /opt/docling-mcp/src/ -type f -exec chmod 644 {} \;

# Make mcp_server.py executable
chmod 755 /opt/docling-mcp/src/mcp_server.py
```

---

## Verification

**Success Criteria**:

- [ ] File `/opt/docling-mcp/src/mcp_server.py` created with 755 permissions
  ```bash
  ls -la /opt/docling-mcp/src/mcp_server.py
  ```

- [ ] FastMCP instance initialized with correct metadata:
  ```bash
  python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp/src'); import mcp_server; assert mcp_server.mcp.name == 'docling-mcp-server'; assert mcp_server.mcp.version == '1.0.0'"
  ```

- [ ] Health check tool registered and functional:
  ```bash
  python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp/src'); import mcp_server; result = mcp_server.health_check(); assert result['status'] == 'healthy'"
  ```

- [ ] Directory structure created with correct permissions:
  ```bash
  ls -la /opt/docling-mcp/src/ | grep -E 'tools|utils|models'
  ```

- [ ] No import errors or syntax errors:
  ```bash
  python3 -m py_compile /opt/docling-mcp/src/mcp_server.py
  ```

---

## Rollback

If server initialization fails:

```bash
# Remove created files
sudo rm -rf /opt/docling-mcp/src/

# Recreate directory structure (will need to re-execute task)
sudo mkdir -p /opt/docling-mcp/src/
sudo chown docling-mcp:docling-mcp /opt/docling-mcp/src/
```

---

## Notes

### Server Architecture Overview

The `mcp_server.py` file serves as the **central orchestration hub** for the Docling MCP Server:

```
┌─────────────────────────────────────────────────┐
│          mcp_server.py (this task)              │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  FastMCP Instance Initialization         │  │
│  │  - Server metadata (name, version)       │  │
│  │  - Capabilities declaration              │  │
│  │  - Health check tool                     │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Tool Registration (Tasks 034-052)       │  │
│  │  - Import conversion tools (3)           │  │
│  │  - Import generation tools (11)          │  │
│  │  - Import manipulation tools (5)         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Transport Configuration (Task 033)      │  │
│  │  - HTTP transport (production)           │  │
│  │  - SSE transport (LM Studio)             │  │
│  │  - stdio transport (Claude Desktop)      │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Server Startup (main function)          │  │
│  │  - Environment-based transport selection │  │
│  │  - Server lifecycle management           │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### FastMCP Server Capabilities

The `SERVER_CAPABILITIES` dictionary provides **MCP client discovery metadata**:

- **tools**: Tool count by category (conversion, generation, manipulation)
- **transports**: Supported transport modes (HTTP, SSE, stdio)
- **authentication**: Auth mode (none for Phase 1, OAuth2 for Phase 2)
- **formats_supported**: Document formats supported for conversion
- **max_document_size_mb**: Maximum document size (500MB limit)
- **concurrent_processing_limit**: Max parallel conversions (4 workers)

### Health Check Tool Purpose

The `health_check()` tool provides:

1. **Monitoring**: External monitoring systems can poll health status
2. **Readiness Probes**: Kubernetes/systemd can verify server ready to accept requests
3. **Dependency Validation**: Future enhancement will check Redis, Qdrant, LiteLLM, LightRAG connectivity
4. **Tool Count Verification**: Validates all 19 tools registered (currently 1, will be 19 after tasks 034-052)

### Environment Variable Configuration

Server behavior controlled via environment variables:

| Variable | Values | Default | Purpose |
|----------|--------|---------|---------|
| `MCP_TRANSPORT` | http, sse, stdio | http | Transport mode selection |
| `MCP_HOST` | IP address | 0.0.0.0 | Server bind address |
| `MCP_PORT` | Port number | 8052 | Server listen port |

**Production Usage** (systemd service):
```ini
[Service]
Environment="MCP_TRANSPORT=http"
Environment="MCP_HOST=0.0.0.0"
Environment="MCP_PORT=8052"
```

**Claude Desktop Usage** (.claude/config.json):
```json
{
  "mcpServers": {
    "docling": {
      "command": "/opt/docling-mcp/venv/bin/python3",
      "args": ["/opt/docling-mcp/src/mcp_server.py"],
      "env": {
        "MCP_TRANSPORT": "stdio"
      }
    }
  }
}
```

### Next Steps

After this task completes, the following tasks will enhance the server:

1. **Task 033**: Configure transport modes (implement `run_http()`, `run_sse()`, `run_stdio()`)
2. **Tasks 034-036**: Register 3 conversion tools
3. **Tasks 037-047**: Register 11 generation tools
4. **Tasks 048-052**: Register 5 manipulation tools

Once all 19 tools are registered, `health_check()` will report `"tools_registered": 19`.

---

## Related Tasks

**Prerequisites**:
- Task 031: Install FastMCP Framework

**Next Tasks**:
- Task 033: Configure MCP Transport Modes
- Tasks 034-052: Register 19 MCP Tools

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: MCP Tools Specification (19 tools overview)
- Section: Technology Stack (FastMCP server initialization)
- Section: Health Check Requirements

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
