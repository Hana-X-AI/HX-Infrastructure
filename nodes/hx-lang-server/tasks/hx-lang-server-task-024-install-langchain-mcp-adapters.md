# Task: Install langchain-mcp-adapters Package

**Task ID**: hx-lang-server-task-024-install-langchain-mcp-adapters
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-022 (LangChain Core)
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 10 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration"

---

## Objective

Install langchain-mcp-adapters package to enable MCP (Model Context Protocol) client integration. This allows hx-lang-server to connect to the FastMCP gateway and invoke MCP tools (e.g., Crawl4AI, Docling) as an MCP CLIENT.

---

## Prerequisites

- [ ] LangChain v0.3.x installed (task-022)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Network connectivity to PyPI

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Install langchain-mcp-adapters

```bash
pip install "langchain-mcp-adapters>=0.1.0"
```

### Step 3: Verify Installation

```bash
pip show langchain-mcp-adapters
python -c "import langchain_mcp_adapters; print('langchain-mcp-adapters imported successfully')"
```

### Step 4: Verify Client Imports

```bash
python -c "
from langchain_mcp_adapters.client import MultiServerMCPClient
print('MultiServerMCPClient import successful')
print(f'MultiServerMCPClient class available: {MultiServerMCPClient}')
"
```

---

## Code Patterns Reference

langchain-mcp-adapters usage pattern for hx-lang-server:

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

# Configure MCP client to connect to FastMCP gateway
mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)

# Tool discovery - returns LangChain-compatible tools
tools = await mcp_client.get_tools()

# Tool invocation with namespace handling
# Note: FastMCP prefixes tools with server name
result = await mcp_client.invoke_tool("crawl4ai__smart_crawl_url", {
    "url": "https://example.com",
    "output_format": "markdown"
})

# For use with LangGraph agents
from langgraph.prebuilt import create_react_agent
agent = create_react_agent(llm, tools)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| langchain-mcp-adapters package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/langchain_mcp_adapters/` | Installed package |

---

## Verification Steps

- [ ] `pip show langchain-mcp-adapters` returns version 0.1.x or higher
- [ ] `from langchain_mcp_adapters.client import MultiServerMCPClient` imports without error
- [ ] MultiServerMCPClient class is accessible

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate

# Version check
pip show langchain-mcp-adapters | grep -E "^(Name|Version):"

# Import verification
python -c "
from langchain_mcp_adapters.client import MultiServerMCPClient

# Verify class can be inspected
print(f'MultiServerMCPClient: {MultiServerMCPClient}')
print('langchain-mcp-adapters installed and verified')

# Check for MCP v1.1 support
import inspect
sig = inspect.signature(MultiServerMCPClient.__init__)
print(f'Constructor signature: {sig}')
"
```

---

## Rollback Procedure

```bash
source /opt/hx-lang-server/venv/bin/activate
pip uninstall langchain-mcp-adapters -y
pip cache purge
```

---

## Notes

- langchain-mcp-adapters v0.1.x is required per specification
- hx-lang-server is an MCP CLIENT, not an MCP server
- Connection to FastMCP gateway tested in Work Stream 9 (George - MCP Integration)
- Tool namespaces are prefixed by FastMCP gateway (e.g., `crawl4ai__smart_crawl_url`)
- CAIO decision: MCP v1.1 with feature detection for backward compatibility (FR-020a)
- Tool discovery is async - must use `await mcp_client.get_tools()`

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
