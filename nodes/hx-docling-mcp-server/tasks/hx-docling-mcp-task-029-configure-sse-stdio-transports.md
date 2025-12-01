# Task: Configure MCP SSE & stdio Transports

**Task ID**: hx-docling-mcp-task-029
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-013 (HTTP Transport Configuration), hx-docling-mcp-task-026 (LiteLLM Integration)
**Parallel Execution**: No (sequential after HTTP transport)

## Objective

Configure Server-Sent Events (SSE) and stdio transports for the Docling MCP Server to support streaming progress updates for long-running documents and Claude Desktop integration.

## Prerequisites

- FastMCP framework installed (Task 001 complete)
- HTTP transport configured on port 8000 (Task 013 complete)
- All MCP tools registered (Tasks 009-012 complete)
- Server running with basic HTTP transport

## Steps

### 1. Install SSE Dependency

```bash
# Add sse-starlette to requirements.txt
echo "sse-starlette>=1.8.0,<2.0.0  # SSE transport for streaming MCP tool progress" >> /opt/docling-mcp/application/requirements.txt

# Activate virtual environment and install
source /opt/docling-mcp/venv/bin/activate
pip install sse-starlette>=1.8.0

# Verify installation
pip show sse-starlette
# Expected: Version 1.8.x or higher
```

### 2. Configure SSE Transport

```bash
# Update server.py to add SSE transport configuration
cat > /opt/docling-mcp/application/docling_mcp/transports/sse_config.py <<'EOF'
"""
Server-Sent Events (SSE) Transport Configuration.

Provides streaming progress updates for long-running MCP tool executions.

SSE Endpoint: GET /mcp/sse
Event Format:
  - ping: {"event": "ping", "data": "keepalive"} (every 30s)
  - progress: {"event": "progress", "data": {"type": "progress", "tool": "<name>", "percentage": 0-100, "message": "..."}}
  - complete: {"event": "complete", "data": {"type": "complete", "tool": "<name>", "result": {...}}}
  - error: {"event": "error", "data": {"type": "error", "tool": "<name>", "error": "..."}}

Dependency: sse-starlette>=1.8.0
"""

import logging
import json
from typing import AsyncIterator
from fastmcp import FastMCP
from sse_starlette.sse import EventSourceResponse

logger = logging.getLogger(__name__)

class SSEProgressEmitter:
    """Emit progress events via SSE for long-running tools."""

    def __init__(self, tool_name: str, session_id: str):
        self.tool_name = tool_name
        self.session_id = session_id
        self.percentage = 0

    async def emit(self, percentage: int, message: str = None) -> dict:
        """
        Emit progress event.

        Args:
            percentage: Progress percentage (0-100)
            message: Optional progress message

        Returns:
            Event dict for SSE stream (keyed for EventSourceResponse)
        """
        self.percentage = percentage
        event_data = {
            "type": "progress",
            "tool": self.tool_name,
            "session_id": self.session_id,
            "percentage": percentage,
            "message": message or f"Processing: {percentage}%"
        }
        logger.debug(f"SSE progress: {self.tool_name} {percentage}%")
        return {"event": "progress", "data": json.dumps(event_data)}

    async def complete(self, result: dict) -> dict:
        """
        Emit completion event with final result.

        Args:
            result: MCP tool result

        Returns:
            Completion event dict (keyed for EventSourceResponse)
        """
        event_data = {
            "type": "complete",
            "tool": self.tool_name,
            "session_id": self.session_id,
            "result": result
        }
        logger.info(f"SSE completion: {self.tool_name}")
        return {"event": "complete", "data": json.dumps(event_data)}

    async def error(self, error_message: str) -> dict:
        """
        Emit error event.

        Args:
            error_message: Error description

        Returns:
            Error event dict (keyed for EventSourceResponse)
        """
        event_data = {
            "type": "error",
            "tool": self.tool_name,
            "session_id": self.session_id,
            "error": error_message
        }
        logger.error(f"SSE error: {self.tool_name} - {error_message}")
        return {"event": "error", "data": json.dumps(event_data)}

async def sse_event_generator(mcp: FastMCP, session_id: str, tool_name: str = None, arguments: dict = None) -> AsyncIterator[dict]:
    """
    Generate SSE events for tool execution with progress updates.

    Args:
        mcp: FastMCP server instance
        session_id: Unique session ID for this SSE connection
        tool_name: Optional tool name to execute
        arguments: Optional tool arguments

    Yields:
        SSE event dicts (progress, complete, error) formatted for EventSourceResponse
    """
    import asyncio

    logger.info(f"SSE connection established: session={session_id}")

    try:
        if tool_name and arguments:
            # Execute tool and stream progress
            emitter = SSEProgressEmitter(tool_name, session_id)
            
            try:
                # Emit initial progress
                yield await emitter.emit(0, "Starting tool execution...")
                
                # Execute tool via FastMCP
                # Note: Real progress tracking would require FastMCP callback hooks
                # For now, emit progress checkpoints during execution
                yield await emitter.emit(25, "Initializing...")
                
                result = await mcp.call_tool(tool_name, arguments)
                
                yield await emitter.emit(75, "Processing results...")
                
                # Emit completion with result
                yield await emitter.complete(result)
                
            except Exception as e:
                # Emit error event
                yield await emitter.error(str(e))
                raise
        else:
            # Keepalive mode: Send ping every 30 seconds
            while True:
                yield {"event": "ping", "data": "keepalive"}
                await asyncio.sleep(30)

    except asyncio.CancelledError:
        logger.info(f"SSE connection closed: session={session_id}")
        raise

def configure_sse_transport(mcp: FastMCP, app):
    """
    Configure SSE transport on existing HTTP server.

    Args:
        mcp: FastMCP server instance
        app: FastAPI/Starlette application instance
    """
    from starlette.requests import Request
    import uuid

    @app.get("/mcp/sse")
    async def sse_endpoint(
        request: Request,
        tool: str = None,  # Optional: tool name to execute
        arguments: str = None  # Optional: JSON-encoded arguments
    ):
        """
        SSE endpoint for streaming MCP tool execution.
        
        Query Parameters:
          - tool: Tool name to execute (optional, for keepalive-only use omit)
          - arguments: JSON-encoded tool arguments (optional)
        
        Returns:
          EventSourceResponse with streaming progress events
        """
        session_id = str(uuid.uuid4())
        logger.info(f"SSE endpoint accessed: session={session_id}, tool={tool}")

        # Parse arguments if provided
        tool_args = None
        if arguments:
            try:
                tool_args = json.loads(arguments)
            except json.JSONDecodeError as e:
                logger.error(f"Invalid arguments JSON: {e}")
                tool_args = None

        return EventSourceResponse(
            sse_event_generator(mcp, session_id, tool, tool_args),
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no"  # Disable nginx buffering
            }
        )

    logger.info("SSE transport configured on /mcp/sse")

EOF

# Set permissions
chmod 644 /opt/docling-mcp/application/docling_mcp/transports/sse_config.py

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/transports/sse_config.py
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi
```

### 2. Configure stdio Transport

```bash
# Create stdio transport module
cat > /opt/docling-mcp/application/docling_mcp/transports/stdio_config.py <<'EOF'
"""
stdio Transport Configuration.

Provides JSON-RPC over stdin/stdout for CLI integration and Claude Desktop.
"""

import logging
import sys
import json
import asyncio
from typing import Optional
from fastmcp import FastMCP

logger = logging.getLogger(__name__)

class StdioTransport:
    """stdio transport for MCP protocol."""

    def __init__(self, mcp: FastMCP):
        self.mcp = mcp
        self.running = False

    async def handle_request(self, request_json: str) -> str:
        """
        Handle single JSON-RPC request from stdin.

        Args:
            request_json: JSON-RPC request string

        Returns:
            JSON-RPC response string
        """
        try:
            request = json.loads(request_json)
            logger.debug(f"stdio request: {request.get('method')} id={request.get('id')}")

            # Route to MCP server
            if request.get("method") == "tools/list":
                tools = self.mcp.list_tools()
                response = {
                    "jsonrpc": "2.0",
                    "result": {"tools": tools},
                    "id": request.get("id")
                }
            elif request.get("method") == "tools/call":
                # Execute tool via MCP
                tool_name = request["params"]["name"]
                arguments = request["params"]["arguments"]
                result = await self.mcp.call_tool(tool_name, arguments)
                response = {
                    "jsonrpc": "2.0",
                    "result": {"content": [{"type": "text", "text": json.dumps(result)}]},
                    "id": request.get("id")
                }
            else:
                response = {
                    "jsonrpc": "2.0",
                    "error": {"code": -32601, "message": f"Method not found: {request.get('method')}"},
                    "id": request.get("id")
                }

            return json.dumps(response)

        except json.JSONDecodeError as e:
            error_response = {
                "jsonrpc": "2.0",
                "error": {"code": -32700, "message": f"Parse error: {e}"},
                "id": None
            }
            return json.dumps(error_response)

        except Exception as e:
            logger.error(f"stdio request error: {e}", exc_info=True)
            error_response = {
                "jsonrpc": "2.0",
                "error": {"code": -32603, "message": f"Internal error: {e}"},
                "id": request.get("id")
            }
            return json.dumps(error_response)

    async def run(self):
        """
        Run stdio transport event loop.

        Reads JSON-RPC requests from stdin (newline-delimited).
        Writes JSON-RPC responses to stdout (newline-delimited).
        Logs to stderr (separate from protocol communication).
        """
        self.running = True
        logger.info("stdio transport started (reading from stdin, writing to stdout)")

        try:
            # Read from stdin in separate thread to avoid blocking
            loop = asyncio.get_event_loop()

            while self.running:
                # Read line from stdin (blocking in thread)
                line = await loop.run_in_executor(None, sys.stdin.readline)

                if not line:  # EOF
                    logger.info("stdio transport: stdin closed, exiting")
                    break

                line = line.strip()
                if not line:
                    continue

                # Handle request
                response = await self.handle_request(line)

                # Write response to stdout (newline-delimited)
                sys.stdout.write(response + "\n")
                sys.stdout.flush()

        except KeyboardInterrupt:
            logger.info("stdio transport interrupted")
        finally:
            self.running = False

def configure_stdio_transport(mcp: FastMCP):
    """
    Configure stdio transport for MCP server.

    Args:
        mcp: FastMCP server instance

    Returns:
        StdioTransport instance
    """
    transport = StdioTransport(mcp)
    logger.info("stdio transport configured")
    return transport

EOF

# Set permissions
chmod 644 /opt/docling-mcp/application/docling_mcp/transports/stdio_config.py

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/transports/stdio_config.py
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi
```

### 3. Update Server Main Entry Point

```bash
# Update server.py to support both transports
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import transport configurations
from .transports.sse_config import configure_sse_transport
from .transports.stdio_config import configure_stdio_transport
import argparse
import asyncio

def parse_args():
    """Parse command-line arguments for transport selection."""
    parser = argparse.ArgumentParser(description="Docling MCP Server")
    parser.add_argument(
        "--transport",
        choices=["http", "sse", "stdio"],
        default="http",
        help="MCP transport mode (http, sse, stdio)"
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="HTTP/SSE server bind address"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="HTTP/SSE server port"
    )
    return parser.parse_args()

async def main_async():
    """Async main entry point with transport configuration."""
    args = parse_args()

    logger.info(f"Starting Docling MCP Server with transport: {args.transport}")
    logger.info(f"Server name: {mcp.name}")
    logger.info(f"Server version: {mcp.version}")

    if args.transport == "stdio":
        # stdio transport mode (Claude Desktop integration)
        logger.info("Running in stdio mode (stdin/stdout)")
        stdio_transport = configure_stdio_transport(mcp)
        await stdio_transport.run()

    else:
        # HTTP/SSE transport modes (share same server)
        from fastapi import FastAPI
        app = FastAPI(title="Docling MCP Server")

        # Register MCP HTTP endpoints
        @app.post("/mcp/call")
        async def mcp_call(request: dict):
            """MCP tool execution endpoint."""
            tool_name = request["params"]["name"]
            arguments = request["params"]["arguments"]
            result = await mcp.call_tool(tool_name, arguments)
            return {
                "jsonrpc": "2.0",
                "result": {"content": [{"type": "text", "text": json.dumps(result)}]},
                "id": request.get("id")
            }

        @app.get("/mcp/tools")
        async def mcp_tools():
            """MCP tool discovery endpoint."""
            tools = mcp.list_tools()
            return {"jsonrpc": "2.0", "result": {"tools": tools}, "id": None}

        @app.get("/health")
        async def health_check():
            """Health check endpoint."""
            return {"status": "healthy", "server": mcp.name, "version": mcp.version}

        # Configure SSE transport if requested
        if args.transport == "sse":
            configure_sse_transport(mcp, app)
            logger.info(f"SSE transport enabled on {args.host}:{args.port}/mcp/sse")

        # Start HTTP server
        import uvicorn
        logger.info(f"Starting HTTP server on {args.host}:{args.port}")
        config = uvicorn.Config(
            app,
            host=args.host,
            port=args.port,
            log_level="info",
            access_log=True
        )
        server = uvicorn.Server(config)
        await server.serve()

if __name__ == "__main__":
    # Run async main
    asyncio.run(main_async())

EOF
```

### 4. Create Transport Test Scripts

```bash
# Create SSE test client
cat > /opt/docling-mcp/test-sse-client.py <<'EOF'
#!/usr/bin/env python3
"""Test SSE transport with streaming progress.

Dependencies:
    sseclient-py: pip install sseclient-py
    requests: pip install requests

Environment Variables:
    MCP_SSE_URL: SSE endpoint URL (default: http://localhost:8000/mcp/sse)
"""

import os
import sseclient
import requests

def test_sse_transport():
    """Test SSE endpoint for streaming events."""
    url = os.getenv("MCP_SSE_URL", "http://localhost:8000/mcp/sse")
    print(f"Connecting to SSE endpoint: {url}")

    response = requests.get(url, stream=True)
    client = sseclient.SSEClient(response)

    print("SSE connection established, waiting for events...")

    for event in client.events():
        print(f"Event: {event.event}")
        print(f"Data: {event.data}")
        print("---")

        # Stop after 5 events for test
        if event.event == "ping":
            count = getattr(test_sse_transport, 'ping_count', 0) + 1
            test_sse_transport.ping_count = count
            if count >= 3:
                print("Received 3 keepalive pings, test PASSED")
                break

if __name__ == "__main__":
    test_sse_transport()
EOF

chmod +x /opt/docling-mcp/test-sse-client.py

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/test-sse-client.py
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi

# Create stdio test script
cat > /opt/docling-mcp/test-stdio-client.sh <<'EOF'
#!/bin/bash
# Test stdio transport with JSON-RPC requests

echo "Testing stdio transport..."

# Test tools/list request
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | \
    python -m docling_mcp.server --transport stdio | \
    python -m json.tool

echo "stdio transport test complete"
EOF

chmod +x /opt/docling-mcp/test-stdio-client.sh

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/test-stdio-client.sh
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi
```

### 5. Create Claude Desktop Configuration Example

```bash
# Create Claude Desktop config example
# NOTE: Replace ${DOCLING_MCP_HOME} with your actual installation path
# Linux/macOS: typically ~/.config/Claude/claude_desktop_config.json
# Windows: typically %APPDATA%\Claude\claude_desktop_config.json
cat > /opt/docling-mcp/claude-desktop-config-example.json <<'EOF'
{
  "mcpServers": {
    "docling": {
      "command": "python",
      "args": [
        "-m",
        "docling_mcp.server",
        "--transport",
        "stdio"
      ],
      "cwd": "${DOCLING_MCP_HOME}",
      "env": {
        "PYTHONPATH": "${DOCLING_MCP_HOME}",
        "LOG_LEVEL": "INFO"
      }
    }
  }
}
EOF

# Note: For production deployment on hx-docling-server:
# Replace ${DOCLING_MCP_HOME} with /opt/docling-mcp/application

chmod 644 /opt/docling-mcp/claude-desktop-config-example.json

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/claude-desktop-config-example.json
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi
```

## Deliverables

- **Dependency**: sse-starlette>=1.8.0 added to requirements.txt
- **SSE transport configuration**: `/opt/docling-mcp/application/docling_mcp/transports/sse_config.py`
- **stdio transport configuration**: `/opt/docling-mcp/application/docling_mcp/transports/stdio_config.py`
- **Updated server.py**: Multi-transport support with command-line arguments
- **SSE test client**: `/opt/docling-mcp/test-sse-client.py`
- **stdio test script**: `/opt/docling-mcp/test-stdio-client.sh`
- **Claude Desktop configuration**: `/opt/docling-mcp/claude-desktop-config-example.json`

## SSE Endpoint Documentation

### Endpoint

- **URL**: `GET /mcp/sse`
- **Protocol**: Server-Sent Events (SSE) over HTTP
- **Port**: 8000 (default MCP service port)

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tool` | string | No | Tool name to execute (omit for keepalive-only mode) |
| `arguments` | string | No | JSON-encoded tool arguments |

### Event Types

The SSE endpoint emits the following event types:

| Event | Data Format | Description |
|-------|-------------|-------------|
| `ping` | `"keepalive"` (string) | Keepalive ping every 30s |
| `progress` | JSON object | Tool execution progress update |
| `complete` | JSON object | Tool execution completion with result |
| `error` | JSON object | Tool execution error |

### Event Data Schemas

**Progress Event:**
```json
{
  "type": "progress",
  "tool": "convert_document",
  "session_id": "uuid-here",
  "percentage": 25,
  "message": "Initializing..."
}
```

**Complete Event:**
```json
{
  "type": "complete",
  "tool": "convert_document",
  "session_id": "uuid-here",
  "result": {
    "content": [{"type": "text", "text": "..."}]
  }
}
```

**Error Event:**
```json
{
  "type": "error",
  "tool": "convert_document",
  "session_id": "uuid-here",
  "error": "Error message here"
}
```

### Usage Examples

**Keepalive Mode (no tool execution):**
```bash
curl -N http://192.168.10.217:8000/mcp/sse
# Receives ping events every 30 seconds
```

**Tool Execution with Progress:**
```bash
curl -N "http://192.168.10.217:8000/mcp/sse?tool=convert_document&arguments=%7B%22source%22%3A%22test.pdf%22%7D"
# Receives progress → complete events
```

**Python Client:**
```python
import sseclient
import requests

response = requests.get(
    "http://192.168.10.217:8000/mcp/sse",
    params={"tool": "convert_document", "arguments": '{"source":"test.pdf"}'},
    stream=True
)

client = sseclient.SSEClient(response)
for event in client.events():
    print(f"{event.event}: {event.data}")
```

### Required Dependency

**Package**: `sse-starlette>=1.8.0`

This dependency provides the `EventSourceResponse` class used by the SSE transport. It must be installed in the virtual environment:

```bash
pip install sse-starlette>=1.8.0
```

The dependency is automatically added to `requirements.txt` during task execution.

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 0. sse-starlette dependency installed
pip show sse-starlette && echo "PASS: sse-starlette dependency installed"

# 1. SSE transport module imports
python -c "from docling_mcp.transports.sse_config import configure_sse_transport" && echo "PASS: SSE transport imports"

# 2. stdio transport module imports
python -c "from docling_mcp.transports.stdio_config import configure_stdio_transport" && echo "PASS: stdio transport imports"

# 3. EventSourceResponse can be imported
python -c "from sse_starlette.sse import EventSourceResponse" && echo "PASS: EventSourceResponse available"

# 4. Server supports --transport argument
python -m docling_mcp.server --help | grep -q "\-\-transport" && echo "PASS: Server has --transport argument"

# 4. SSE transport test (run server first in separate terminal)
# python -m docling_mcp.server --transport sse
# Then in another terminal:
# /opt/docling-mcp/test-sse-client.py
# Expected: Receive keepalive ping events

# 5. stdio transport test
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | \
    timeout 5s python -m docling_mcp.server --transport stdio | \
    python -m json.tool | grep -q "tools" && echo "PASS: stdio transport responds"
```

### Expected Output

All verification checks should output "PASS".

## Rollback

If SSE/stdio transport configuration fails:

```bash
# 1. Remove transport modules
rm -f /opt/docling-mcp/application/docling_mcp/transports/sse_config.py
rm -f /opt/docling-mcp/application/docling_mcp/transports/stdio_config.py

# 2. Restore server.py to HTTP-only mode (remove transport argument parsing)

# 3. Document failure reason
echo "SSE/stdio transport configuration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **SSE Use Cases**: Long-running documents (>30s processing), batch conversions, progress monitoring
- **stdio Use Cases**: Claude Desktop integration, CLI scripts, automation pipelines
- **HTTP Remains Primary**: HTTP transport is primary for AI agent integrations, SSE/stdio are supplementary
- **Keepalive Pings**: SSE sends keepalive every 30 seconds to prevent client timeout
- **stdin Buffering**: stdio mode flushes stdout after each response for immediate delivery

## References

- **Specification**: Section 3.2.1 "MCP Protocol Compliance" - FR-003 (Multi-transport support)
- **Charter**: Lines 239-267 (Transport configuration details)
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 183-197: SSE/stdio transport documentation)
- **Dependencies**: Task 013 (HTTP Transport), Task 026 (LiteLLM Integration for SSE progress events)
