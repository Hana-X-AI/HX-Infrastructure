# DEFECT-065: Hardcoded IP, Absolute Paths, and Missing User Handling in Task 029

**Severity**: MEDIUM
**Status**: CLOSED
**Created**: 2025-11-30
**Closed**: 2025-11-30
**Affects**: nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-029-configure-sse-stdio-transports.md

---

## Description

Task 029 (Configure SSE & stdio Transports) contains multiple portability and configuration issues:

1. **Hardcoded SSE endpoint IP** (line 408): Test client has `http://hx-docling-mcp-server.hx.dev.local:8000/mcp/sse` hardcoded
2. **Environment-specific absolute paths** (lines 470, 472): Claude Desktop config has `/opt/docling-mcp/application` hardcoded
3. **Missing user/group handling** (lines 144, 289, 434, 452, 507): 5 `chown` commands fail if service account doesn't exist
4. **Undocumented dependency**: `sseclient-py` package not documented

## Impact

- **Portability**: Tests and configs can't run on different environments without code changes
- **Deployment failures**: Tasks halt if service account not yet created
- **Missing dependencies**: Users don't know to install `sseclient-py`
- **Best Practices**: Violates configuration-as-environment-variable principle

## Root Cause

1. Test endpoint hardcoded instead of using environment variable
2. Absolute paths instead of variables in config examples
3. No conditional logic for optional service account ownership
4. Dependencies not documented in test scripts

## Issues Found and Resolutions

### Issue 1: Hardcoded SSE Endpoint in Test Client (Line 408)

**Before:**
```python
import sseclient
import requests

def test_sse_transport():
    """Test SSE endpoint for streaming events."""
    url = "http://hx-docling-mcp-server.hx.dev.local:8000/mcp/sse"
    print(f"Connecting to SSE endpoint: {url}")
```

**After:**
```python
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
```

Changes:
- Added `import os` to read environment variables
- Changed URL to use `os.getenv("MCP_SSE_URL", "http://localhost:8000/mcp/sse")`
- Added dependency documentation in docstring
- Default to `localhost` for dev environments

### Issue 2: Hardcoded Absolute Paths in Claude Desktop Config (Lines 470, 472)

**Before:**
```json
{
  "mcpServers": {
    "docling": {
      "cwd": "/opt/docling-mcp/application",
      "env": {
        "PYTHONPATH": "/opt/docling-mcp/application",
        "LOG_LEVEL": "INFO"
      }
    }
  }
}
```

**After:**
```bash
# Create Claude Desktop config example
# NOTE: Replace ${DOCLING_MCP_HOME} with your actual installation path
# Linux/macOS: typically ~/.config/Claude/claude_desktop_config.json
# Windows: typically %APPDATA%\Claude\claude_desktop_config.json
cat > /opt/docling-mcp/claude-desktop-config-example.json <<'EOF'
{
  "mcpServers": {
    "docling": {
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
```

Changes:
- Replaced hardcoded `/opt/docling-mcp/application` with `${DOCLING_MCP_HOME}` variable
- Added comments explaining where config should be placed per platform
- Added note for production deployment path substitution

### Issue 3: Missing User Handling in chown Commands (5 locations)

**Before (Lines 144, 289, 434, 452, 507):**
```bash
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /path/to/file
```

**After (all 5 locations):**
```bash
# Set permissions
chmod 644 /path/to/file

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /path/to/file
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown"
fi
```

Changes:
- Added conditional check for user existence before `chown`
- Graceful fallback with warning message
- Permissions still set via `chmod`
- No task failure if service account not yet created

**Files affected**:
1. `/opt/docling-mcp/application/docling_mcp/transports/sse_config.py`
2. `/opt/docling-mcp/application/docling_mcp/transports/stdio_config.py`
3. `/opt/docling-mcp/test-sse-client.py`
4. `/opt/docling-mcp/test-stdio-client.sh`
5. `/opt/docling-mcp/claude-desktop-config-example.json`

## Testing

- ✅ Verified transports directory doesn't exist yet on deployed server (task not executed)
- ✅ Documentation fixes prevent future deployment issues
- ✅ Test client now uses environment variable with localhost default
- ✅ Claude Desktop config uses portable variable
- ✅ All chown commands handle missing user gracefully

## Prevention

- Always use environment variables for endpoint configuration
- Use placeholder variables (${VAR}) instead of hardcoded absolute paths in config examples
- Add conditional checks for optional dependencies (users, directories, etc.)
- Document all external dependencies (pip packages) in script docstrings
- Provide platform-specific deployment instructions
