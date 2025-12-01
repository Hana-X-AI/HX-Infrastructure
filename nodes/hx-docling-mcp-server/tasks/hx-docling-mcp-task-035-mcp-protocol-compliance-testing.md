# Task: MCP Protocol Compliance Testing

**Task ID**: hx-docling-mcp-task-035
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-002, hx-docling-mcp-task-003, hx-docling-mcp-task-006 (at least one tool registered + HTTP transport configured)
**Parallel Execution**: No (requires deployed MCP server)

## Objective

Validate that Docling MCP Server implements MCP protocol specification correctly, including JSON-RPC format compliance, tool schema validation, error handling per MCP error codes, and transport protocol adherence.

## Prerequisites

- MCP server deployed with HTTP transport (Task 006 complete)
- At least 3 MCP tools registered (Tasks 002-005 partially or fully complete)
- Server running and accessible (configure via `MCP_ENDPOINT` environment variable, defaults to `http://localhost:8000/mcp`)

## Steps

### 1. Create MCP Protocol Compliance Test Suite

```bash
# Create comprehensive MCP protocol test suite
cat > /opt/docling-mcp/tests/test_mcp_protocol_compliance.py <<'EOF'
"""
MCP Protocol Compliance Test Suite.

Tests MCP specification compliance:
- JSON-RPC 2.0 format
- MCP methods (tools/list, tools/call)
- Error code mapping
- Schema validation
- Transport protocol compliance

Environment Variables:
    MCP_ENDPOINT: MCP server endpoint URL (default: http://localhost:8000/mcp)
"""

import pytest
import requests
import json
import os
from typing import Dict, Any

MCP_ENDPOINT = os.getenv("MCP_ENDPOINT", "http://localhost:8000/mcp")
TIMEOUT = 30

# ============================================================================
# JSON-RPC Format Compliance Tests
# ============================================================================

def test_jsonrpc_version():
    """Test that all responses include jsonrpc: 2.0."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    assert "jsonrpc" in result, "Response missing 'jsonrpc' field"
    assert result["jsonrpc"] == "2.0", f"Invalid JSON-RPC version: {result['jsonrpc']}"


def test_request_id_echo():
    """Test that response 'id' matches request 'id'."""
    request_id = "test-request-123"
    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": request_id
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    assert "id" in result, "Response missing 'id' field"
    assert result["id"] == request_id, f"Response ID mismatch: expected {request_id}, got {result['id']}"


# ============================================================================
# MCP Method Tests
# ============================================================================

def test_tools_list_method():
    """Test tools/list returns valid tool array."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    assert "result" in result, "Response missing 'result' field"
    assert "tools" in result["result"], "Result missing 'tools' array"
    assert isinstance(result["result"]["tools"], list), "Tools must be array"
    assert len(result["result"]["tools"]) > 0, "No tools registered"


def test_tool_schema_structure():
    """Test that all tools have required schema fields."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    tools = response.json()["result"]["tools"]

    required_fields = ["name", "description", "inputSchema"]

    for tool in tools:
        for field in required_fields:
            assert field in tool, f"Tool '{tool.get('name', 'unknown')}' missing required field: {field}"

        # Validate inputSchema structure
        assert "type" in tool["inputSchema"], f"Tool '{tool['name']}' inputSchema missing 'type'"
        assert tool["inputSchema"]["type"] == "object", f"Tool '{tool['name']}' inputSchema type must be 'object'"
        assert "properties" in tool["inputSchema"], f"Tool '{tool['name']}' inputSchema missing 'properties'"


def test_tools_call_method():
    """Test tools/call executes tool and returns result."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "convert_document",
            "arguments": {
                "document_source": "test://placeholder.pdf"
            }
        },
        "id": 2
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    # Tool execution may fail (placeholder implementation), but response should be valid JSON-RPC
    assert "result" in result or "error" in result, "Response must have 'result' or 'error'"
    assert "id" in result, "Response missing 'id'"


# ============================================================================
# Error Handling Tests
# ============================================================================

def test_invalid_json_parse_error():
    """Test that malformed JSON returns parse error (-32700)."""
    response = requests.post(
        MCP_ENDPOINT,
        data="invalid json{",  # Malformed JSON
        headers={"Content-Type": "application/json"},
        timeout=TIMEOUT
    )

    result = response.json()
    assert "error" in result, "Expected error response for malformed JSON"
    assert result["error"]["code"] == -32700, f"Expected parse error code -32700, got {result['error']['code']}"


def test_invalid_request_error():
    """
    Test that request missing 'jsonrpc' field returns invalid request error (-32600).
    
    This test enforces strict JSON-RPC 2.0 compliance per the specification:
    "A rpc call is represented by sending a Request object to a Server. 
     The Request object has the following members: jsonrpc (required), method, params, id"
    
    Note: Lenient server implementations may accept requests without the jsonrpc field.
    If testing against a lenient server, this test may need to be skipped or adjusted.
    """
    request = {
        # Missing "jsonrpc": "2.0" - REQUIRED by JSON-RPC 2.0 spec
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    # Strict JSON-RPC 2.0: missing jsonrpc field MUST return -32600 Invalid Request
    assert "error" in result, "Expected error response for invalid request (missing jsonrpc field)"
    assert result["error"]["code"] == -32600, f"Expected invalid request code -32600, got {result['error']['code']}"


def test_method_not_found_error():
    """Test that unknown method returns method not found error (-32601)."""
    request = {
        "jsonrpc": "2.0",
        "method": "unknown/method",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    assert "error" in result, "Expected error response for unknown method"
    assert result["error"]["code"] == -32601, f"Expected method not found code -32601, got {result['error']['code']}"


def test_invalid_params_error():
    """Test that invalid tool parameters return invalid params error (-32602)."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "convert_document",
            "arguments": {
                # Missing required "document_source" parameter
                "invalid_param": "value"
            }
        },
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    assert "error" in result, "Expected error response for invalid params"
    assert result["error"]["code"] == -32602, f"Expected invalid params code -32602, got {result['error']['code']}"


# ============================================================================
# Schema Validation Tests
# ============================================================================

def test_pydantic_schema_generation():
    """Test that tool schemas are valid JSON Schema generated from Pydantic models."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    tools = response.json()["result"]["tools"]

    for tool in tools:
        schema = tool["inputSchema"]

        # Validate JSON Schema structure
        assert "type" in schema, f"Tool '{tool['name']}' schema missing 'type'"
        assert "properties" in schema, f"Tool '{tool['name']}' schema missing 'properties'"

        # Check for Pydantic-generated metadata (optional)
        # Pydantic schemas often include "title", "description" fields
        for prop_name, prop_schema in schema["properties"].items():
            assert "type" in prop_schema or "$ref" in prop_schema, \
                f"Tool '{tool['name']}' property '{prop_name}' missing type definition"


def test_required_parameters_validation():
    """Test that required parameters are enforced."""
    request = {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "convert_document",
            "arguments": {}  # Empty arguments (missing required params)
        },
        "id": 1
    }

    response = requests.post(MCP_ENDPOINT, json=request, timeout=TIMEOUT)
    result = response.json()

    # Should return invalid params error due to missing required fields
    assert "error" in result, "Expected error for missing required parameters"
    assert result["error"]["code"] == -32602, "Expected invalid params error code"


# ============================================================================
# Test Execution
# ============================================================================

if __name__ == "__main__":
    # Run tests with pytest
    pytest.main([__file__, "-v", "--tb=short"])

EOF

chmod +x /opt/docling-mcp/tests/test_mcp_protocol_compliance.py

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/test_mcp_protocol_compliance.py
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown (file remains owned by current user)"
fi
```

### 2. Run MCP Protocol Compliance Tests

```bash
# Ensure server is running
cd /opt/docling-mcp/application
source /opt/docling-mcp/venv/bin/activate
python -m docling_mcp.server &
SERVER_PID=$!
sleep 5

# Set MCP endpoint (adjust hostname/port as needed for your deployment)
export MCP_ENDPOINT="http://hx-docling-server.hx.dev.local:8000/mcp"

# Run compliance test suite
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py -v --tb=short

# Capture exit code
TEST_RESULT=$?

# Stop server
kill $SERVER_PID

# Exit with test result
exit $TEST_RESULT
```

## Deliverables

- MCP protocol compliance test suite: `/opt/docling-mcp/tests/test_mcp_protocol_compliance.py`
- Test coverage for:
  - JSON-RPC 2.0 format compliance (2 tests)
  - MCP methods (tools/list, tools/call) (3 tests)
  - Error code mapping (-32700, -32600, -32601, -32602) (4 tests)
  - Schema validation (Pydantic → JSON Schema) (2 tests)
- Total: 11 compliance tests

## Verification

### Success Criteria

```bash
# 1. All compliance tests pass
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py -v
# Expected: 11 passed (or more if additional tests added)

# 2. JSON-RPC format tests pass
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_jsonrpc_version -v
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_request_id_echo -v
# Expected: 2 passed

# 3. Error handling tests pass
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_invalid_json_parse_error -v
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_method_not_found_error -v
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_invalid_params_error -v
# Expected: 3 passed (validates MCP error code mapping)

# 4. Schema validation tests pass
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_pydantic_schema_generation -v
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py::test_required_parameters_validation -v
# Expected: 2 passed (validates Pydantic → JSON Schema conversion)
```

### Expected Output

```
========================= test session starts ==========================
collected 11 items

test_mcp_protocol_compliance.py::test_jsonrpc_version PASSED      [  9%]
test_mcp_protocol_compliance.py::test_request_id_echo PASSED      [ 18%]
test_mcp_protocol_compliance.py::test_tools_list_method PASSED    [ 27%]
test_mcp_protocol_compliance.py::test_tool_schema_structure PASSED [ 36%]
test_mcp_protocol_compliance.py::test_tools_call_method PASSED    [ 45%]
test_mcp_protocol_compliance.py::test_invalid_json_parse_error PASSED [ 54%]
test_mcp_protocol_compliance.py::test_invalid_request_error PASSED [ 63%]
test_mcp_protocol_compliance.py::test_method_not_found_error PASSED [ 72%]
test_mcp_protocol_compliance.py::test_invalid_params_error PASSED [ 81%]
test_mcp_protocol_compliance.py::test_pydantic_schema_generation PASSED [ 90%]
test_mcp_protocol_compliance.py::test_required_parameters_validation PASSED [100%]

========================== 11 passed in 2.34s ==========================
```

## Rollback

Not applicable (test-only task, no deployment changes)

## Notes

- **MCP Specification**: Tests validate compliance with Model Context Protocol (MCP) JSON-RPC specification
- **Error Code Mapping**: Validates FastMCP error handling maps Python exceptions to correct MCP error codes:
  - -32700: Parse error (malformed JSON)
  - -32600: Invalid request (missing jsonrpc field)
  - -32601: Method not found (unknown MCP method)
  - -32602: Invalid params (schema validation failure)
  - -32603: Internal error (server-side processing failure)
- **Pydantic Integration**: Tests verify that Pydantic models correctly generate JSON Schema for MCP tool schemas
- **Quality Gate**: This task validates MCP protocol compliance before operational promotion (required for QG-002)

## References

- **Architecture**: Section 3.3 "Error Handling Architecture" (lines 820-897): MCP error response format and code mapping
- **Test Plan**: TC-FUNC-019 (MCP protocol compliance), QG-002 (100% integration tests pass)
- **Specification**: Section 4.2 "MCP Tools Specification": Tool schema format requirements
