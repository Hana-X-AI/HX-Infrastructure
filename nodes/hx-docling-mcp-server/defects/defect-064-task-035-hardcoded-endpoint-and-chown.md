# DEFECT-064: Hardcoded MCP Endpoint and Missing User Handling in Task 035

**Severity**: MEDIUM
**Status**: CLOSED
**Created**: 2025-11-30
**Closed**: 2025-11-30
**Affects**: nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-035-mcp-protocol-compliance-testing.md

---

## Description

Task 035 (MCP Protocol Compliance Testing) contains three issues:

1. **Hardcoded MCP endpoint IP** (lines 17, 42): Test code has hardcoded `http://hx-docling-mcp-server.hx.dev.local:8000/mcp`
2. **Inflexible test environment**: Cannot run tests against different deployments without code changes
3. **Missing user/group handling** (line 283): `chown` command fails if `docling-mcp@hx.dev.local` user doesn't exist

## Impact

- **Portability**: Tests can't run on different environments (dev, staging, production)
- **Maintainability**: IP changes require editing test code
- **Deployment failures**: Task halts if service account not yet created
- **Best Practices**: Violates configuration-as-environment-variable principle

## Root Cause

1. Test endpoint hardcoded instead of using environment variable
2. No conditional logic for optional service account ownership

## Issues Found and Resolutions

### Issue 1: Hardcoded MCP Endpoint in Prerequisites (Line 17)

**Before:**
```markdown
- Server running and accessible at `http://hx-docling-mcp-server.hx.dev.local:8000/mcp`
```

**After:**
```markdown
- Server running and accessible (configure via `MCP_ENDPOINT` environment variable, defaults to `http://localhost:8000/mcp`)
```

### Issue 2: Hardcoded MCP Endpoint in Python Code (Line 42)

**Before:**
```python
import pytest
import requests
import json
from typing import Dict, Any

MCP_ENDPOINT = "http://hx-docling-mcp-server.hx.dev.local:8000/mcp"
TIMEOUT = 30
```

**After:**
```python
import pytest
import requests
import json
import os
from typing import Dict, Any

MCP_ENDPOINT = os.getenv("MCP_ENDPOINT", "http://localhost:8000/mcp")
TIMEOUT = 30
```

Added:
- `import os` to read environment variables
- Environment variable documentation in docstring
- Configurable endpoint with sensible default (localhost)

### Issue 3: Missing User Handling in chown (Line 283)

**Before:**
```bash
chmod +x /opt/docling-mcp/tests/test_mcp_protocol_compliance.py
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/test_mcp_protocol_compliance.py
```

**After:**
```bash
chmod +x /opt/docling-mcp/tests/test_mcp_protocol_compliance.py

# Set ownership if service account exists
if id "docling-mcp@hx.dev.local" >/dev/null 2>&1; then
  chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/test_mcp_protocol_compliance.py
else
  echo "Warning: User docling-mcp@hx.dev.local not found; skipping chown (file remains owned by current user)"
fi
```

Added:
- Conditional check for user existence
- Graceful fallback with warning message
- No task failure if service account not yet created

### Issue 4: Missing Environment Variable Documentation in Test Execution

**Before:**
```bash
# Run compliance test suite
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py -v --tb=short
```

**After:**
```bash
# Set MCP endpoint (adjust hostname/port as needed for your deployment)
export MCP_ENDPOINT="http://hx-docling-server.hx.dev.local:8000/mcp"

# Run compliance test suite
pytest /opt/docling-mcp/tests/test_mcp_protocol_compliance.py -v --tb=short
```

Added:
- Clear documentation of environment variable
- Example using hostname instead of IP
- Comment explaining configurability

## Testing

- ✅ Verified no hardcoded IPs remain in task file
- ✅ Verified no hardcoded IPs in existing deployed test files
- ✅ Test code now uses environment variable with localhost default
- ✅ chown command handles missing user gracefully

## Prevention

- Always use environment variables for endpoint configuration
- Use hostnames, not IPs, in configuration examples
- Add conditional checks for optional dependencies (users, directories, etc.)
- Document environment variables in test file docstrings
