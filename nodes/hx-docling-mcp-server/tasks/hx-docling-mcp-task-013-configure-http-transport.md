# Task: Configure MCP HTTP Transport

**Task ID**: hx-docling-mcp-task-013
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-001 (FastMCP Framework Installation)
**Parallel Execution**: No (must complete before task 007)

## Objective

Configure FastMCP HTTP transport to expose MCP protocol endpoints on port 8000, bound to internal interface (192.168.10.217) with proper request handling and error responses.

## Prerequisites

- FastMCP framework installed (Task 005 complete)
- At least one MCP tool registered (Task 002, 003, 004, or 005 complete)
- Environment variable `SERVICE_HOST=192.168.10.217` configured in `/etc/docling-mcp/.env`

## Steps

### 1. Configure HTTP Transport in Server

```bash
# Idempotently add HTTP transport configuration to server.py
SERVER_FILE="/opt/docling-mcp/application/docling_mcp/server.py"

# Check if HTTP transport configuration already exists
if ! grep -q "# HTTP Transport Configuration" "$SERVER_FILE"; then
    cat > /tmp/http_transport_addition.py <<'EOF'

# ============================================================================
# HTTP Transport Configuration
# ============================================================================

import os
from pathlib import Path

# Load configuration from environment
SERVICE_HOST = os.getenv("SERVICE_HOST", "192.168.10.217")
SERVICE_PORT = int(os.getenv("SERVICE_PORT", "8000"))

logger.info(f"Configuring HTTP transport: {SERVICE_HOST}:{SERVICE_PORT}")

# Add HTTP transport (primary MCP endpoint)
mcp.add_transport(
    transport_type="http",
    host=SERVICE_HOST,  # Bind to internal interface ONLY (not 0.0.0.0)
    port=SERVICE_PORT,
    path="/mcp"  # MCP endpoint: http://192.168.10.217:8000/mcp
)

logger.info("HTTP transport configured successfully")
logger.info(f"MCP HTTP endpoint: http://{SERVICE_HOST}:{SERVICE_PORT}/mcp")

# HTTP Transport Details:
# - Protocol: HTTP/1.1 (JSON-RPC over HTTP POST)
# - Content-Type: application/json
# - Method: POST only
# - Path: /mcp
# - Authentication: None (Phase 1 - network-level security only)

EOF

    # Append HTTP transport configuration to server.py
    cat /tmp/http_transport_addition.py >> "$SERVER_FILE"
    rm /tmp/http_transport_addition.py
    echo "HTTP transport configuration added to server.py"
else
    echo "HTTP transport configuration already exists in server.py, skipping"
fi
```

### 2. Update Main Function to Start Server

```bash
# Idempotently add main() function to server.py
SERVER_FILE="/opt/docling-mcp/application/docling_mcp/server.py"

# Check if main() function already exists
if ! grep -q "def main():" "$SERVER_FILE"; then
    cat >> "$SERVER_FILE" <<'EOF'

# Update main() to start MCP server
def main():
    """Main entry point for Docling MCP Server."""
    logger.info("=" * 80)
    logger.info("Starting Docling MCP Server")
    logger.info("=" * 80)
    logger.info(f"Server name: {mcp.name}")
    logger.info(f"Server version: {mcp.version}")
    logger.info(f"HTTP endpoint: http://{SERVICE_HOST}:{SERVICE_PORT}/mcp")
    logger.info(f"Registered tools: {len(mcp.list_tools())}")
    logger.info("=" * 80)

    # Start FastMCP server (blocks until shutdown)
    try:
        mcp.run()
    except KeyboardInterrupt:
        logger.info("Shutdown signal received")
    except Exception as e:
        logger.error(f"Server error: {e}", exc_info=True)
        raise
    finally:
        logger.info("Docling MCP Server stopped")

if __name__ == "__main__":
    main()
EOF
```

### 3. Create Test Client Script

```bash
# Create simple HTTP test client
cat > /opt/docling-mcp/test-http-client.py <<'EOF'
#!/usr/bin/env python3
"""
Test HTTP client for Docling MCP Server.

Tests MCP protocol endpoints:
- tools/list: List all registered tools
- tools/call: Call specific tool
"""

import requests
import json
import sys

MCP_URL = "http://192.168.10.217:8000/mcp"

def test_tools_list():
    """Test tools/list endpoint."""
    print("Testing tools/list...")

    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(
        MCP_URL,
        headers={"Content-Type": "application/json"},
        json=request,
        timeout=10
    )

    if response.status_code == 200:
        result = response.json()
        if "result" in result and "tools" in result["result"]:
            tools = result["result"]["tools"]
            print(f"✓ tools/list successful: {len(tools)} tools registered")
            for tool in tools:
                print(f"  - {tool['name']}: {tool['description'][:60]}...")
            return True
        else:
            print(f"✗ Invalid response format: {result}")
            return False
    else:
        print(f"✗ HTTP error: {response.status_code}")
        print(f"Response: {response.text}")
        return False

def test_tool_call(tool_name="convert_document", params=None):
    """Test tools/call endpoint."""
    print(f"\nTesting tools/call ({tool_name})...")

    if params is None:
        params = {
            "document_source": "test://placeholder.pdf"
        }

    request = {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": params
        },
        "id": 2
    }

    response = requests.post(
        MCP_URL,
        headers={"Content-Type": "application/json"},
        json=request,
        timeout=30
    )

    if response.status_code == 200:
        result = response.json()
        if "result" in result:
            print(f"✓ tools/call successful for {tool_name}")
            return True
        elif "error" in result:
            print(f"✗ MCP error: {result['error']}")
            return False
        else:
            print(f"✗ Invalid response: {result}")
            return False
    else:
        print(f"✗ HTTP error: {response.status_code}")
        print(f"Response: {response.text}")
        return False

if __name__ == "__main__":
    print("Docling MCP Server HTTP Transport Test")
    print("=" * 60)

    # Test 1: List tools
    if not test_tools_list():
        print("\n✗ FAILED: tools/list test failed")
        sys.exit(1)

    # Test 2: Call tool
    if not test_tool_call():
        print("\n✗ FAILED: tools/call test failed")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("✓ ALL TESTS PASSED: HTTP transport working correctly")
    sys.exit(0)
EOF

chmod +x /opt/docling-mcp/test-http-client.py
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/test-http-client.py
```

### 4. Test HTTP Transport Configuration

```bash
# Start MCP server in background for testing
cd /opt/docling-mcp/application
source /opt/docling-mcp/venv/bin/activate

# Start server (will run in foreground - use separate terminal or systemd service for actual deployment)
python -m docling_mcp.server &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Run HTTP transport tests
python /opt/docling-mcp/test-http-client.py

# Stop test server
kill $SERVER_PID
```

## Deliverables

- HTTP transport configured in server.py with internal interface binding (192.168.10.217:8000)
- MCP HTTP endpoint available at: `http://192.168.10.217:8000/mcp`
- Test client script created: `/opt/docling-mcp/test-http-client.py`
- Server main() function updated to start HTTP server via mcp.run()

## Verification

### Success Criteria

```bash
# 1. Server starts without errors
cd /opt/docling-mcp/application && source /opt/docling-mcp/venv/bin/activate
timeout 10 python -m docling_mcp.server &
sleep 5
ps aux | grep "docling_mcp.server" | grep -v grep && echo "PASS: Server running"
kill $(pgrep -f "docling_mcp.server")

# 2. HTTP endpoint responds
curl -f http://192.168.10.217:8000/mcp && echo "PASS: HTTP endpoint accessible"

# 3. tools/list returns valid response
curl -X POST http://192.168.10.217:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' \
  | jq '.result.tools | length' && echo "PASS: tools/list working"

# 4. Test client passes all tests
python /opt/docling-mcp/test-http-client.py && echo "PASS: HTTP transport tests passed"
```

### Expected Output

- Server starts and logs "HTTP endpoint: http://192.168.10.217:8000/mcp"
- Test client outputs "✓ ALL TESTS PASSED: HTTP transport working correctly"
- tools/list endpoint returns JSON array of registered MCP tools

## Rollback

If HTTP transport configuration fails:

```bash
# 1. Stop any running server processes
pkill -f "docling_mcp.server"

# 2. Remove HTTP transport configuration from server.py
# (Manual: Edit server.py to remove HTTP transport section)

# 3. Document failure reason
echo "HTTP transport configuration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Internal Interface Binding**: Server binds to 192.168.10.217 (NOT 0.0.0.0) for internal network access only
- **No Firewall Rules**: Firewall DISABLED per HX-Infrastructure standard (charter line 119)
- **No Authentication Phase 1**: Network-level security only (authentication deferred to Phase 2)
- **HTTP Only (Phase 1)**: HTTPS transport deferred to Phase 2 (requires TLS certificates from hx-ca-server)
- **JSON-RPC Protocol**: All MCP requests/responses use JSON-RPC 2.0 format per MCP specification

## References

- **Architecture**: Section 3.2 "Request/Response Flow" (lines 722-773): HTTP transport request flow
- **Configuration**: Section 9.1 "Listen Address and Ports" (lines 1329-1345): HTTP endpoint configuration
- **Plan**: Section "Phase 1" Task 006: HTTP transport configuration task outline
