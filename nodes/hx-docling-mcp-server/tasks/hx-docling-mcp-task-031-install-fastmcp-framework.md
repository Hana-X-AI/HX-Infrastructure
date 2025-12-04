# Task: Install FastMCP Framework

**Task ID**: hx-docling-mcp-task-031-install-fastmcp-framework
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**: hx-docling-mcp-task-030 (Python virtual environment setup)
**Estimated Time**: 30 minutes
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Install the FastMCP framework (version ≥0.2) in the Python virtual environment to provide production-ready MCP server implementation capabilities. FastMCP enables standardized Model Context Protocol (MCP) server creation with support for multiple transport modes (HTTP, SSE, stdio).

---

## Pre-Execution Validation

**CRITICAL**: Check if FastMCP is already installed BEFORE executing installation steps.

```bash
# Activate virtual environment and check for FastMCP installation
source /opt/docling-mcp/venv/bin/activate
python3 -c "import fastmcp; print(f'FastMCP version: {fastmcp.__version__}')" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ VALIDATION: FastMCP already installed - SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION: FastMCP not installed - PROCEED with task"
fi
```

**Validation Logic**:
- If FastMCP import succeeds and version ≥0.2 → SKIP execution, mark task as validated/complete
- If FastMCP not installed or version <0.2 → PROCEED with installation steps
- Document validation results in task execution tracking

---

## Prerequisites

- [ ] Python 3.11 virtual environment created at `/opt/docling-mcp/venv/` (Task 021-030)
- [ ] Virtual environment has upgraded pip, setuptools, wheel
- [ ] Network connectivity to PyPI (https://pypi.org)
- [ ] Service account `docling-mcp` has write permissions to `/opt/docling-mcp/venv/`

---

## Steps

### 1. Activate Python Virtual Environment

```bash
# Switch to service account
sudo -u docling-mcp bash

# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Verify activation
which python3
# Expected: /opt/docling-mcp/venv/bin/python3
```

### 2. Install FastMCP Package

```bash
# Install FastMCP from PyPI with version constraint
pip install "fastmcp>=0.2"

# Verify installation
pip show fastmcp
```

**Expected Output**:
```
Name: fastmcp
Version: 0.2.x (or higher)
Summary: Production-ready MCP server framework
Home-page: https://github.com/jlowin/fastmcp
Author: Jeremiah Lowin
License: MIT
Requires: pydantic, uvicorn, starlette, sse-starlette, httpx
```

### 3. Verify FastMCP Dependencies Installed

FastMCP requires the following dependencies (should install automatically):

```bash
# Verify critical dependencies
pip show pydantic uvicorn starlette sse-starlette httpx

# Check versions
python3 -c "
import fastmcp
import pydantic
import uvicorn
import starlette
print(f'FastMCP: {fastmcp.__version__}')
print(f'Pydantic: {pydantic.__version__}')
print(f'Uvicorn: {uvicorn.__version__}')
print(f'Starlette: {starlette.__version__}')
"
```

**Expected Versions**:
- FastMCP: ≥0.2
- Pydantic: ≥2.0 (required for MCP tool schema validation)
- Uvicorn: ≥0.27 (ASGI server for HTTP transport)
- Starlette: ≥0.36 (web framework for FastMCP)
- sse-starlette: ≥2.0 (Server-Sent Events support)

### 4. Test FastMCP Import and Basic Functionality

Create a minimal test script to verify FastMCP works:

```bash
# Create test script
cat > /tmp/test_fastmcp.py <<'EOF'
"""
Minimal FastMCP server test
"""
from fastmcp import FastMCP

# Create FastMCP instance
mcp = FastMCP("test-server", version="1.0.0")

# Register a simple test tool
@mcp.tool()
def hello_world(name: str) -> str:
    """Test tool that returns a greeting."""
    return f"Hello, {name}!"

# Verify tool registered
print(f"✅ FastMCP instance created: {mcp.name}")
print(f"✅ Tools registered: {len(mcp.list_tools())} tools")
print(f"✅ Tool names: {[t.name for t in mcp.list_tools()]}")
EOF

# Run test
python3 /tmp/test_fastmcp.py

# Cleanup
rm /tmp/test_fastmcp.py
```

**Expected Output**:
```
✅ FastMCP instance created: test-server
✅ Tools registered: 1 tools
✅ Tool names: ['hello_world']
```

### 5. Document Installation

```bash
# Create installation record
cat > /opt/docling-mcp/installation-records/fastmcp-installation.txt <<EOF
FastMCP Framework Installation Record
======================================
Date: $(date -Iseconds)
Task: hx-docling-mcp-task-031-install-fastmcp-framework
User: docling-mcp

Installed Package:
$(pip show fastmcp)

Dependencies:
$(pip list | grep -E 'pydantic|uvicorn|starlette|sse-starlette|httpx')

Python Environment:
$(python3 --version)
Virtual Environment: /opt/docling-mcp/venv/

Verification Test: PASSED
EOF

# Set permissions
chmod 644 /opt/docling-mcp/installation-records/fastmcp-installation.txt
```

### 6. Freeze Requirements

```bash
# Update requirements.txt with installed FastMCP version
pip freeze | grep -E 'fastmcp|uvicorn|starlette|sse-starlette|httpx|pydantic' >> /opt/docling-mcp/requirements.txt

# Deactivate virtual environment
deactivate
```

---

## Verification

**Success Criteria**:

- [ ] FastMCP package installed with version ≥0.2
  ```bash
  source /opt/docling-mcp/venv/bin/activate
  python3 -c "from packaging import version; import fastmcp; assert version.parse(fastmcp.__version__) >= version.parse('0.2'), f'FastMCP version {fastmcp.__version__} is less than required 0.2'"
  ```

- [ ] All required dependencies installed:
  ```bash
  pip show fastmcp pydantic uvicorn starlette sse-starlette httpx
  # All packages should return information (not "WARNING: Package(s) not found")
  ```

- [ ] FastMCP instance creation succeeds (test script passes)
  ```bash
  python3 -c "from fastmcp import FastMCP; mcp = FastMCP('test', version='1.0'); print('✅ FastMCP works')"
  ```

- [ ] Installation record created at `/opt/docling-mcp/installation-records/fastmcp-installation.txt`

- [ ] No import errors or missing dependencies

---

## Rollback

If FastMCP installation fails or causes issues:

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Uninstall FastMCP and dependencies
pip uninstall -y fastmcp sse-starlette

# If complete rollback needed, recreate virtual environment
deactivate
sudo rm -rf /opt/docling-mcp/venv/
# Then re-execute Task 021-030 to recreate venv
```

---

## Notes

### Why FastMCP?

FastMCP provides:
1. **Production-Ready MCP Server**: Complete implementation of Model Context Protocol specification
2. **Multiple Transport Modes**: HTTP, SSE (Server-Sent Events), stdio (for Claude Desktop integration)
3. **Automatic Schema Generation**: JSON Schema generation from Pydantic models for MCP tool definitions
4. **Built-in Error Handling**: MCP-compliant error responses with standard error codes
5. **Authentication Support**: OAuth2 middleware for Phase 2 security requirements

### FastMCP vs Manual MCP Implementation

| Feature | FastMCP | Manual Implementation |
|---------|---------|----------------------|
| Time to implement | <1 hour | 2-3 days |
| MCP spec compliance | Guaranteed (maintained by MCP community) | Manual validation required |
| Transport support | HTTP/SSE/stdio built-in | Must implement each transport |
| Schema validation | Automatic via Pydantic | Manual JSON Schema creation |
| Error handling | Standardized MCP error codes | Custom error handling |

### Integration with Docling MCP Server Architecture

FastMCP serves as the **foundation layer** for all 19 MCP tools:

```
┌─────────────────────────────────────┐
│   MCP Client (Claude Desktop, etc)  │
└────────────┬────────────────────────┘
             │ MCP Protocol (HTTP/SSE/stdio)
             ▼
┌─────────────────────────────────────┐
│      FastMCP Server Instance        │ ◄── This task installs this
│  - Tool discovery                   │
│  - Tool invocation                  │
│  - Schema validation                │
│  - Error handling                   │
└────────────┬────────────────────────┘
             │
    ┌────────┴────────┬─────────────────┐
    ▼                 ▼                 ▼
┌──────────┐   ┌──────────┐    ┌──────────┐
│ Convert  │   │ Generate │    │ Manipulate│
│ Tools    │   │ Tools    │    │ Tools     │
│ (3)      │   │ (11)     │    │ (5)       │
└──────────┘   └──────────┘    └──────────┘
```

### Security Considerations

- **Package Verification**: FastMCP is maintained by the MCP community (GitHub: jlowin/fastmcp)
- **Dependency Audit**: All dependencies (Pydantic, Uvicorn, Starlette) are well-established Python packages
- **Phase 1**: No authentication (hx.dev.local environment with disabled firewalls)
- **Phase 2**: OAuth2 authentication via FastMCP auth middleware (future enhancement)

### Troubleshooting

**Issue**: `pip install fastmcp` fails with dependency resolver conflict

**Solution**:
```bash
# Install with no-dependencies flag, then install dependencies manually
pip install --no-deps fastmcp
pip install pydantic>=2.0 uvicorn>=0.27 starlette>=0.36 sse-starlette>=2.0 httpx>=0.27
```

**Issue**: Import error `ModuleNotFoundError: No module named 'fastmcp'`

**Solution**:
```bash
# Verify virtual environment is activated
which python3
# Should output: /opt/docling-mcp/venv/bin/python3

# If not activated:
source /opt/docling-mcp/venv/bin/activate
```

---

## Related Tasks

**Prerequisites**:
- Task 021-030: Python Virtual Environment Setup (must complete first)

**Next Tasks**:
- Task 032: Initialize FastMCP Server Instance
- Task 033: Configure MCP Transport Modes (HTTP/SSE/stdio)
- Tasks 034-060: Register 19 MCP Tools

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Technology Stack (FastMCP ≥0.2 requirement)
- Section: MCP Tools Specification (19 tools requiring FastMCP)

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
