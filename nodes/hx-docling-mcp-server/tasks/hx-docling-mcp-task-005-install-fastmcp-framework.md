# Task 005: Install FastMCP Framework

**Task ID**: hx-docling-mcp-task-005
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: Tasks 001-004 (infrastructure and Python environment) (prerequisite for all other MCP tasks)
**Parallel Execution**: No

## Objective

Install and configure the FastMCP framework within the Python virtual environment to provide MCP protocol server implementation with minimal boilerplate.

## Prerequisites

- Python 3.11+ virtual environment created at `/opt/docling-mcp/venv`
- pip upgraded to latest version
- Internet connectivity for PyPI package downloads

## Steps

### 1. Verify Virtual Environment

```bash
# Verify virtual environment exists
test -d /opt/docling-mcp/venv || (echo "ERROR: venv not found" && exit 1)

# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Verify Python version
python --version
# Expected: Python 3.11.x or higher
```

### 2. Install FastMCP Framework

```bash
# Install fastmcp from PyPI
pip install fastmcp==0.5.0

# Verify installation
pip show fastmcp
# Expected output should include:
# Name: fastmcp
# Version: 0.5.0
# Summary: Fast Model Context Protocol server implementation
```

### 3. Install FastMCP Dependencies

```bash
# FastMCP dependencies (automatically installed with fastmcp)
# Verify critical dependencies present:
pip list | grep -E "(pydantic|uvicorn|starlette|sse-starlette)"

# Expected packages:
# pydantic               2.10.x
# pydantic-core          2.x.x
# uvicorn                0.x.x  (ASGI server for HTTP transport)
# starlette              0.x.x  (Web framework for FastMCP)
# sse-starlette          1.x.x  (Server-Sent Events transport)
```

### 4. Verify FastMCP Import

```bash
# Test FastMCP import in Python
python -c "from fastmcp import FastMCP; print(f'FastMCP version: {FastMCP.__module__}')"

# Expected: FastMCP version: fastmcp.server
```

### 5. Create FastMCP Server Skeleton

```bash
# Create application directory structure
mkdir -p /opt/docling-mcp/application/docling_mcp/{tools,processors,clients,utils,models}

# Create __init__.py files
touch /opt/docling-mcp/application/docling_mcp/__init__.py
touch /opt/docling-mcp/application/docling_mcp/tools/__init__.py
touch /opt/docling-mcp/application/docling_mcp/processors/__init__.py
touch /opt/docling-mcp/application/docling_mcp/clients/__init__.py
touch /opt/docling-mcp/application/docling_mcp/utils/__init__.py
touch /opt/docling-mcp/application/docling_mcp/models/__init__.py

# Create main server.py entry point
cat > /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'
"""
Docling MCP Server - Main Entry Point

FastMCP-based MCP protocol server for document processing.
"""

from fastmcp import FastMCP
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastMCP server
mcp = FastMCP(
    "docling-mcp-server",
    version="1.0.0"
)

# Placeholder for tool imports (will be added in subsequent tasks)
# from .tools.conversion import register_conversion_tools
# from .tools.generation import register_generation_tools
# from .tools.manipulation import register_manipulation_tools

def main():
    """Main entry point for Docling MCP Server."""
    logger.info("Starting Docling MCP Server...")
    logger.info(f"Server name: {mcp.name}")
    logger.info(f"Server version: {mcp.version}")

    # Transport configuration will be added in subsequent tasks
    # mcp.add_transport("http", host="192.168.10.217", port=8000)
    # mcp.add_transport("sse", host="192.168.10.217", port=8000)
    # mcp.add_transport("stdio")

    logger.info("Docling MCP Server initialized (transport configuration pending)")

    # Server will be started in transport configuration task
    # mcp.run()

if __name__ == "__main__":
    main()
EOF

# Set ownership
chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application
chmod 644 /opt/docling-mcp/application/docling_mcp/server.py
```

### 6. Test FastMCP Server Skeleton

```bash
# Test server.py import
cd /opt/docling-mcp/application
python -c "from docling_mcp.server import mcp; print(f'Server: {mcp.name} v{mcp.version}')"

# Expected: Server: docling-mcp-server v1.0.0
```

## Deliverables

- FastMCP framework installed in virtual environment: `/opt/docling-mcp/venv/lib/python3.11/site-packages/fastmcp/`
- Application directory structure created: `/opt/docling-mcp/application/docling_mcp/`
- Main server.py entry point created with FastMCP initialization
- All dependencies verified via `pip list`

## Verification

### Success Criteria

```bash
# 1. FastMCP package installed
pip show fastmcp | grep "Version: 0.5.0"
# Result: PASS if version matches

# 2. FastMCP import works
python -c "from fastmcp import FastMCP" && echo "PASS: FastMCP import successful"
# Result: PASS if no errors

# 3. Server skeleton created
test -f /opt/docling-mcp/application/docling_mcp/server.py && echo "PASS: server.py created"
# Result: PASS if file exists

# 4. Server initialization works
cd /opt/docling-mcp/application && python -c "from docling_mcp.server import mcp; assert mcp.name == 'docling-mcp-server'" && echo "PASS: Server initialized"
# Result: PASS if assertion succeeds

# 5. Directory structure correct
ls -d /opt/docling-mcp/application/docling_mcp/tools/ && echo "PASS: tools/ directory exists"
ls -d /opt/docling-mcp/application/docling_mcp/processors/ && echo "PASS: processors/ directory exists"
# Result: PASS if both directories exist
```

### Expected Output

All 5 verification checks should output "PASS". If any check fails, review the corresponding step and retry.

## Rollback

If FastMCP installation fails or is incompatible:

```bash
# 1. Uninstall fastmcp
pip uninstall -y fastmcp

# 2. Remove application directory
rm -rf /opt/docling-mcp/application/docling_mcp/

# 3. Document failure reason
echo "FastMCP installation failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log

# 4. Escalate to Agent Zero
# Report: FastMCP framework incompatibility or installation failure
```

## Notes

- **FastMCP Version**: 0.5.0 is production-ready per research findings (documented in charter Phase 4 research)
- **Pydantic Version**: FastMCP requires pydantic ~2.10.0 (automatically installed as dependency)
- **Transport Configuration**: Deferred to Task 006 (HTTP transport) and Task 007 (SSE/stdio transports)
- **Tool Registration**: Deferred to Tasks 002-005 (conversion, generation, manipulation tools)

## References

- **Charter**: Section "Technology Stack" (lines 329-330): "FastMCP (Python): MCP protocol framework for server implementation"
- **Specification**: Section 4.3.1 "FastMCP Framework" (lines 1823-1862): FastMCP architecture details
- **Architecture**: Section 2.1 "FastMCP Framework Architecture" (lines 292-346): Framework components and features
- **Configuration**: Section 3.2 "Python Dependencies" (lines 244-314): requirements.txt with fastmcp==0.5.0
