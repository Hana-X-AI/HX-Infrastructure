# Task: Configure MCP Transport Modes (HTTP, SSE, stdio)

**Task ID**: hx-docling-mcp-task-033-configure-transport-modes
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**: hx-docling-mcp-task-032 (FastMCP server initialization)
**Estimated Time**: 1 hour
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Configure three MCP transport modes in `mcp_server.py` to support different client types:
- **HTTP Transport**: Production deployment with REST-like MCP protocol over HTTP
- **SSE Transport**: Server-Sent Events for LM Studio, Llama Stack (long-running connections)
- **stdio Transport**: Standard I/O for Claude Desktop integration

Each transport provides the same 19 MCP tools with identical functionality, differing only in communication protocol.

---

## Pre-Execution Validation

**CRITICAL**: Check if transport configuration already exists BEFORE modifying server file.

```bash
# Check if transport methods are already implemented
if [ -f /opt/docling-mcp/src/mcp_server.py ]; then
    grep -q "mcp.run_http" /opt/docling-mcp/src/mcp_server.py && \
    grep -q "mcp.run_sse" /opt/docling-mcp/src/mcp_server.py && \
    grep -q "mcp.run_stdio" /opt/docling-mcp/src/mcp_server.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: Transport modes already configured - SKIP task execution"
        exit 0
    else
        echo "❌ VALIDATION: Transport modes not configured - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: mcp_server.py not found - ERROR (Task 032 must complete first)"
    exit 1
fi
```

**Validation Logic**:
- If all three transport methods (`run_http`, `run_sse`, `run_stdio`) present → SKIP
- If server file exists but transports missing → PROCEED with configuration
- If server file doesn't exist → ERROR (dependency failure)

---

## Prerequisites

- [ ] FastMCP server initialized (Task 032)
- [ ] File `/opt/docling-mcp/src/mcp_server.py` exists
- [ ] Uvicorn installed in virtual environment (dependency of FastMCP)
- [ ] Service account `docling-mcp` has write permissions

---

## Steps

### 1. Backup Existing Server File

```bash
# Switch to service account
sudo -u docling-mcp bash

# Create backup
cp /opt/docling-mcp/src/mcp_server.py /opt/docling-mcp/src/mcp_server.py.backup.$(date +%Y%m%d_%H%M%S)
```

### 2. Update Main Function with Transport Configuration

Edit `/opt/docling-mcp/src/mcp_server.py` to replace the placeholder `main()` function:

```bash
# Create updated main() function
cat > /tmp/transport_config.py <<'EOF'
def main():
    """
    Main server entry point with configured transport modes.

    Supports three transport modes (configured via environment variables):
    - HTTP: FastMCP HTTP transport (production) - http://hx-docling-mcp-server.hx.dev.local:8000
    - SSE: Server-Sent Events transport (LM Studio, Llama Stack) - SSE endpoint with persistent connections
    - stdio: Standard I/O transport (Claude Desktop) - stdin/stdout communication

    Environment Variables:
        MCP_TRANSPORT: Transport mode ("http", "sse", "stdio") - default: "http"
        MCP_HOST: Server host (default: "0.0.0.0")
        MCP_PORT: Server port (default: 8000)

    Usage:
        # HTTP transport (production, default)
        python3 mcp_server.py
        # Server available at: http://hx-docling-mcp-server.hx.dev.local:8000

        # SSE transport (LM Studio)
        MCP_TRANSPORT=sse python3 mcp_server.py
        # SSE endpoint: http://hx-docling-mcp-server.hx.dev.local:8000/sse

        # stdio transport (Claude Desktop)
        MCP_TRANSPORT=stdio python3 mcp_server.py
        # Communication via stdin/stdout (no network binding)
    """
    import os

    transport = os.getenv("MCP_TRANSPORT", "http").lower()
    host = os.getenv("MCP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_PORT", "8000"))

    logger.info(f"🚀 Starting Docling MCP Server")
    logger.info(f"   Transport: {transport}")
    logger.info(f"   Host: {host}")
    logger.info(f"   Port: {port}")
    logger.info(f"   Tools registered: {len(mcp.list_tools())}")
    logger.info(f"   Node: hx-docling-mcp-server.hx.dev.local")

    # Transport selection based on environment variable
    if transport == "stdio":
        logger.info("📡 Using stdio transport (Claude Desktop mode)")
        logger.info("   Communication: stdin/stdout")
        logger.info("   Network: No network binding (stdio only)")
        mcp.run_stdio()

    elif transport == "sse":
        logger.info(f"📡 Using SSE transport on {host}:{port}")
        logger.info(f"   SSE Endpoint: http://hx-docling-mcp-server.hx.dev.local:{port}/sse")
        logger.info("   Client Support: LM Studio, Llama Stack, custom SSE clients")
        logger.info("   Connection: Persistent (long-running)")
        mcp.run_sse(host=host, port=port)

    else:  # http (default)
        logger.info(f"📡 Using HTTP transport on {host}:{port}")
        logger.info(f"   HTTP Endpoint: http://hx-docling-mcp-server.hx.dev.local:{port}")
        logger.info("   Protocol: MCP over HTTP (REST-like)")
        logger.info("   Client Support: All MCP-compliant HTTP clients")
        mcp.run_http(host=host, port=port)
EOF
```

### 3. Apply Transport Configuration to Server File

```bash
# Use sed to replace the placeholder main() function
# First, remove old main() function (from "def main():" to end of file before "if __name__")
sed -i '/^def main():/,/^if __name__ == "__main__":/{//!d}' /opt/docling-mcp/src/mcp_server.py

# Insert new main() function before "if __name__"
sed -i '/^if __name__ == "__main__":/i\
def main():\
    """\
    Main server entry point with configured transport modes.\
\
    Supports three transport modes (configured via environment variables):\
    - HTTP: FastMCP HTTP transport (production) - http://hx-docling-mcp-server.hx.dev.local:8000\
    - SSE: Server-Sent Events transport (LM Studio, Llama Stack) - SSE endpoint with persistent connections\
    - stdio: Standard I/O transport (Claude Desktop) - stdin/stdout communication\
\
    Environment Variables:\
        MCP_TRANSPORT: Transport mode ("http", "sse", "stdio") - default: "http"\
        MCP_HOST: Server host (default: "0.0.0.0")\
        MCP_PORT: Server port (default: 8000)\
    """\
    import os\
\
    transport = os.getenv("MCP_TRANSPORT", "http").lower()\
    host = os.getenv("MCP_HOST", "0.0.0.0")\
    port = int(os.getenv("MCP_PORT", "8000"))\
\
    logger.info(f"🚀 Starting Docling MCP Server")\
    logger.info(f"   Transport: {transport}")\
    logger.info(f"   Host: {host}")\
    logger.info(f"   Port: {port}")\
    logger.info(f"   Tools registered: {len(mcp.list_tools())}")\
    logger.info(f"   Node: hx-docling-mcp-server.hx.dev.local")\
\
    if transport == "stdio":\
        logger.info("📡 Using stdio transport (Claude Desktop mode)")\
        logger.info("   Communication: stdin/stdout")\
        logger.info("   Network: No network binding (stdio only)")\
        mcp.run_stdio()\
    elif transport == "sse":\
        logger.info(f"📡 Using SSE transport on {host}:{port}")\
        logger.info(f"   SSE Endpoint: http://hx-docling-mcp-server.hx.dev.local:{port}/sse")\
        logger.info("   Client Support: LM Studio, Llama Stack, custom SSE clients")\
        logger.info("   Connection: Persistent (long-running)")\
        mcp.run_sse(host=host, port=port)\
    else:\
        logger.info(f"📡 Using HTTP transport on {host}:{port}")\
        logger.info(f"   HTTP Endpoint: http://hx-docling-mcp-server.hx.dev.local:{port}")\
        logger.info("   Protocol: MCP over HTTP (REST-like)")\
        logger.info("   Client Support: All MCP-compliant HTTP clients")\
        mcp.run_http(host=host, port=port)\
\
' /opt/docling-mcp/src/mcp_server.py

# Cleanup
rm /tmp/transport_config.py
```

### 4. Verify Transport Configuration

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test syntax (compilation check)
python3 -m py_compile /opt/docling-mcp/src/mcp_server.py

# Verify transport methods exist
grep -E "(mcp\.run_http|mcp\.run_sse|mcp\.run_stdio)" /opt/docling-mcp/src/mcp_server.py

# Expected output: Should show 3 lines with each transport method
```

### 5. Test Each Transport Mode (Dry Run)

**Test HTTP Transport** (default):
```bash
cd /opt/docling-mcp/src/

# Run server in background for 5 seconds
timeout 5s python3 mcp_server.py 2>&1 | tee /tmp/http_transport_test.log &
sleep 2

# Check if server started successfully
grep -q "Using HTTP transport" /tmp/http_transport_test.log
if [ $? -eq 0 ]; then
    echo "✅ HTTP transport configured successfully"
else
    echo "❌ HTTP transport test failed"
fi

# Cleanup
pkill -f mcp_server.py 2>/dev/null
```

**Test SSE Transport**:
```bash
# Run with SSE transport
timeout 5s env MCP_TRANSPORT=sse python3 mcp_server.py 2>&1 | tee /tmp/sse_transport_test.log &
sleep 2

grep -q "Using SSE transport" /tmp/sse_transport_test.log
if [ $? -eq 0 ]; then
    echo "✅ SSE transport configured successfully"
else
    echo "❌ SSE transport test failed"
fi

pkill -f mcp_server.py 2>/dev/null
```

**Test stdio Transport**:
```bash
# Note: stdio requires input on stdin, so we'll just verify it attempts to start
timeout 2s env MCP_TRANSPORT=stdio python3 mcp_server.py 2>&1 | tee /tmp/stdio_transport_test.log &
sleep 1

grep -q "Using stdio transport" /tmp/stdio_transport_test.log
if [ $? -eq 0 ]; then
    echo "✅ stdio transport configured successfully"
else
    echo "❌ stdio transport test failed"
fi

pkill -f mcp_server.py 2>/dev/null
```

### 6. Create Client Configuration Examples

Create example configuration files for different MCP clients:

```bash
# Create client-config directory
mkdir -p /opt/docling-mcp/client-configs/

# Claude Desktop configuration (stdio)
cat > /opt/docling-mcp/client-configs/claude_desktop_config.json <<'EOF'
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
EOF

# LM Studio configuration (SSE)
cat > /opt/docling-mcp/client-configs/lm_studio_mcp.json <<'EOF'
{
  "mcpServers": {
    "docling": {
      "url": "http://hx-docling-mcp-server.hx.dev.local:8000/sse",
      "transport": "sse",
      "description": "Docling document processing server (19 MCP tools)"
    }
  }
}
EOF

# Custom HTTP client example
cat > /opt/docling-mcp/client-configs/http_client_example.md <<'EOF'
# HTTP Transport Client Configuration

## Endpoint
http://hx-docling-mcp-server.hx.dev.local:8000

## MCP Protocol Endpoints

### Tool Discovery
GET /mcp/tools
Returns list of all 19 available MCP tools with schemas

### Tool Invocation
POST /mcp/invoke
Body: {
  "tool": "convert_document",
  "parameters": {
    "document_source": "file:///path/to/document.pdf",
    "preserve_images": true,
    "ocr_enabled": true
  }
}

### Health Check
GET /health
Returns server health status

## Example curl Commands

# List all tools
curl http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools

# Invoke health_check tool
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/invoke \
  -H "Content-Type: application/json" \
  -d '{"tool": "health_check", "parameters": {}}'

# Convert PDF document
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/invoke \
  -H "Content-Type: application/json" \
  -d '{"tool": "convert_document", "parameters": {"document_source": "file:///tmp/test.pdf"}}'
EOF

chmod 644 /opt/docling-mcp/client-configs/*
chown -R docling-mcp:docling-mcp /opt/docling-mcp/client-configs/
```

---

## Verification

**Success Criteria**:

- [ ] All three transport modes (`run_http`, `run_sse`, `run_stdio`) implemented in mcp_server.py:
  ```bash
  grep -E "(mcp\.run_http|mcp\.run_sse|mcp\.run_stdio)" /opt/docling-mcp/src/mcp_server.py | wc -l
  # Should output: 3
  ```

- [ ] HTTP transport test passes (server starts with HTTP mode):
  ```bash
  timeout 3s python3 /opt/docling-mcp/src/mcp_server.py 2>&1 | grep -q "Using HTTP transport"
  ```

- [ ] SSE transport test passes:
  ```bash
  timeout 3s env MCP_TRANSPORT=sse python3 /opt/docling-mcp/src/mcp_server.py 2>&1 | grep -q "Using SSE transport"
  ```

- [ ] stdio transport test passes:
  ```bash
  timeout 2s env MCP_TRANSPORT=stdio python3 /opt/docling-mcp/src/mcp_server.py 2>&1 | grep -q "Using stdio transport"
  ```

- [ ] Client configuration examples created:
  ```bash
  ls -la /opt/docling-mcp/client-configs/ | grep -E "(claude_desktop|lm_studio|http_client)"
  ```

- [ ] No syntax errors in updated server file:
  ```bash
  python3 -m py_compile /opt/docling-mcp/src/mcp_server.py
  ```

---

## Rollback

If transport configuration fails:

```bash
# Restore backup
BACKUP_FILE=$(ls -t /opt/docling-mcp/src/mcp_server.py.backup.* | head -1)
cp $BACKUP_FILE /opt/docling-mcp/src/mcp_server.py

# Verify restoration
python3 -m py_compile /opt/docling-mcp/src/mcp_server.py
```

---

## Notes

### Transport Mode Comparison

| Transport | Use Case | Connection | Client Examples | Performance |
|-----------|----------|------------|-----------------|-------------|
| **HTTP** | Production deployment, REST-like API | Stateless (request/response) | Custom MCP clients, cURL, API testing tools | High throughput, low latency |
| **SSE** | Long-running connections, streaming | Persistent (server-push) | LM Studio, Llama Stack, web applications | Efficient for progress updates |
| **stdio** | Desktop applications, local tools | Standard I/O (stdin/stdout) | Claude Desktop, local CLI tools | Minimal overhead, no network |

### Transport Selection Decision Tree

```
Is client a desktop app (e.g., Claude Desktop)?
├─ YES → Use stdio transport
└─ NO → Does client need streaming/progress updates?
    ├─ YES → Use SSE transport (LM Studio, Llama Stack)
    └─ NO → Use HTTP transport (production, API integrations)
```

### Claude Desktop Integration

To integrate with Claude Desktop, users copy `claude_desktop_config.json` to:

**Linux/macOS**:
```bash
~/.config/claude/claude_desktop_config.json
```

**Windows**:
```
%APPDATA%\Claude\claude_desktop_config.json
```

After configuration, Claude Desktop discovers all 19 MCP tools automatically.

### LM Studio Integration

LM Studio supports SSE transport for MCP servers. Configuration steps:

1. Open LM Studio → Settings → MCP Servers
2. Add new server with URL: `http://hx-docling-mcp-server.hx.dev.local:8000/sse`
3. LM Studio connects via SSE and discovers available tools

### Production Deployment (systemd)

For production deployment via systemd (Task 151-160), HTTP transport is default:

```ini
[Service]
Environment="MCP_TRANSPORT=http"
Environment="MCP_HOST=0.0.0.0"
Environment="MCP_PORT=8000"
ExecStart=/opt/docling-mcp/venv/bin/python3 /opt/docling-mcp/src/mcp_server.py
```

### Testing Transport Modes End-to-End

After all 19 tools are registered (Tasks 034-052), test each transport mode:

**HTTP Transport Test**:
```bash
# Start server
python3 /opt/docling-mcp/src/mcp_server.py &

# Wait for startup
sleep 5

# Test tool invocation
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/invoke \
  -H "Content-Type: application/json" \
  -d '{"tool": "health_check", "parameters": {}}'

# Should return: {"status": "healthy", "tools_registered": 19, ...}
```

**SSE Transport Test** (requires SSE client):
```bash
# Start SSE server
MCP_TRANSPORT=sse python3 /opt/docling-mcp/src/mcp_server.py &

# Connect with SSE client (e.g., LM Studio or curl with SSE support)
curl -N http://hx-docling-mcp-server.hx.dev.local:8000/sse
```

**stdio Transport Test** (requires stdio MCP client):
```bash
# Run with stdio (requires MCP client feeding stdin)
echo '{"tool": "health_check", "parameters": {}}' | MCP_TRANSPORT=stdio python3 /opt/docling-mcp/src/mcp_server.py
```

---

## Related Tasks

**Prerequisites**:
- Task 032: Initialize FastMCP Server

**Next Tasks**:
- Tasks 034-052: Register 19 MCP Tools (tools will be available via all transports)

**Future Tasks**:
- Task 151-160: Configure systemd service (will use HTTP transport by default)

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Transport Modes (HTTP, SSE, stdio requirements)
- Section: Client Integration (Claude Desktop, LM Studio examples)

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
