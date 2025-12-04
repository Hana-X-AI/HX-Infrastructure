# Task: Implement Tool Namespace Handling with Prefixes

**Task ID**: hx-lang-server-task-093-implement-tool-namespace-handling
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-092 (FastMCP gateway connection)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 35 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-020)

---

## Objective

Implement tool namespace handling to correctly parse and manage namespaced tool names from the FastMCP gateway. The gateway prefixes tools with server names (e.g., `crawl4ai__smart_crawl_url`), and hx-lang-server must handle these prefixes correctly.

**Requirement (FR-020)**: Service MUST handle tool namespace prefixes from gateway

---

## Prerequisites

- [ ] FastMCP gateway connection configured (task-092)
- [ ] MCP client module exists (task-091)
- [ ] Understanding of FastMCP gateway prefixing pattern

---

## Background: Tool Namespace Pattern

FastMCP gateway uses double-underscore (`__`) to prefix tools with their source server:

| Source Server | Tool Name | Namespaced Name |
|---------------|-----------|-----------------|
| crawl4ai | smart_crawl_url | crawl4ai__smart_crawl_url |
| crawl4ai | extract_content | crawl4ai__extract_content |
| docling | convert_document | docling__convert_document |
| docling | extract_tables | docling__extract_tables |

---

## Implementation Steps

### Step 1: Create Tool Namespace Utilities Module

Create file `/opt/hx-lang-server/app/mcp/namespace.py`:

```python
"""
Tool Namespace Handling for FastMCP Gateway Integration.

FastMCP gateway prefixes tools with their source server name
using double-underscore as separator: {server}__{tool}

Examples:
- crawl4ai__smart_crawl_url
- docling__convert_document
"""

import logging
import re
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass

logger = logging.getLogger(__name__)

# Namespace separator used by FastMCP gateway
NAMESPACE_SEPARATOR = "__"

# Known MCP server namespaces in HX-Infrastructure
KNOWN_NAMESPACES = {
    "crawl4ai": {
        "server": "hx-crawl4ai-mcp-server.hx.dev.local",
        "description": "Web crawling and content extraction tools",
        "tools": [
            "smart_crawl_url",
            "extract_content",
            "crawl_multiple_urls",
        ]
    },
    "docling": {
        "server": "hx-docling-mcp-server.hx.dev.local",
        "description": "Document conversion and processing tools",
        "tools": [
            "convert_document",
            "extract_tables",
            "convert_pdf",
            "convert_docx",
        ]
    }
}


@dataclass
class ParsedToolName:
    """Parsed tool name with namespace and base name."""
    namespace: Optional[str]
    base_name: str
    full_name: str
    is_namespaced: bool


def parse_tool_name(tool_name: str) -> ParsedToolName:
    """
    Parse a namespaced tool name into components.

    Args:
        tool_name: Full tool name (may or may not be namespaced)

    Returns:
        ParsedToolName with namespace, base_name, and full_name

    Examples:
        parse_tool_name("crawl4ai__smart_crawl_url")
        -> ParsedToolName(namespace="crawl4ai", base_name="smart_crawl_url", ...)

        parse_tool_name("local_tool")
        -> ParsedToolName(namespace=None, base_name="local_tool", ...)
    """
    if NAMESPACE_SEPARATOR in tool_name:
        parts = tool_name.split(NAMESPACE_SEPARATOR, 1)
        namespace = parts[0]
        base_name = parts[1]
        return ParsedToolName(
            namespace=namespace,
            base_name=base_name,
            full_name=tool_name,
            is_namespaced=True
        )
    else:
        return ParsedToolName(
            namespace=None,
            base_name=tool_name,
            full_name=tool_name,
            is_namespaced=False
        )


def build_namespaced_name(namespace: str, base_name: str) -> str:
    """
    Build a namespaced tool name from components.

    Args:
        namespace: Server namespace (e.g., "crawl4ai")
        base_name: Base tool name (e.g., "smart_crawl_url")

    Returns:
        Namespaced tool name (e.g., "crawl4ai__smart_crawl_url")
    """
    return f"{namespace}{NAMESPACE_SEPARATOR}{base_name}"


def get_namespace(tool_name: str) -> Optional[str]:
    """
    Extract namespace from a tool name.

    Args:
        tool_name: Full tool name

    Returns:
        Namespace string or None if not namespaced
    """
    parsed = parse_tool_name(tool_name)
    return parsed.namespace


def get_base_name(tool_name: str) -> str:
    """
    Extract base name from a tool name (without namespace).

    Args:
        tool_name: Full tool name

    Returns:
        Base tool name without namespace prefix
    """
    parsed = parse_tool_name(tool_name)
    return parsed.base_name


def is_known_namespace(namespace: str) -> bool:
    """
    Check if a namespace is a known MCP server.

    Args:
        namespace: Namespace to check

    Returns:
        True if namespace is known, False otherwise
    """
    return namespace in KNOWN_NAMESPACES


def get_namespace_info(namespace: str) -> Optional[Dict[str, Any]]:
    """
    Get information about a namespace.

    Args:
        namespace: Namespace to look up

    Returns:
        Dict with server info or None if unknown
    """
    return KNOWN_NAMESPACES.get(namespace)


def filter_tools_by_namespace(
    tools: List[Any],
    namespace: str,
    tool_name_attr: str = "name"
) -> List[Any]:
    """
    Filter a list of tools to only those from a specific namespace.

    Args:
        tools: List of tool objects
        namespace: Namespace to filter by
        tool_name_attr: Attribute name for tool name (default: "name")

    Returns:
        Filtered list of tools
    """
    filtered = []
    prefix = f"{namespace}{NAMESPACE_SEPARATOR}"

    for tool in tools:
        tool_name = getattr(tool, tool_name_attr, None)
        if tool_name and tool_name.startswith(prefix):
            filtered.append(tool)

    logger.debug(
        f"Filtered {len(filtered)} tools for namespace '{namespace}' "
        f"from {len(tools)} total tools"
    )

    return filtered


def group_tools_by_namespace(
    tools: List[Any],
    tool_name_attr: str = "name"
) -> Dict[str, List[Any]]:
    """
    Group tools by their namespace.

    Args:
        tools: List of tool objects
        tool_name_attr: Attribute name for tool name

    Returns:
        Dict mapping namespace -> list of tools
        Tools without namespace are grouped under "_local"
    """
    grouped: Dict[str, List[Any]] = {"_local": []}

    for tool in tools:
        tool_name = getattr(tool, tool_name_attr, None)
        if tool_name:
            parsed = parse_tool_name(tool_name)
            if parsed.is_namespaced and parsed.namespace:
                if parsed.namespace not in grouped:
                    grouped[parsed.namespace] = []
                grouped[parsed.namespace].append(tool)
            else:
                grouped["_local"].append(tool)

    # Remove empty _local group
    if not grouped["_local"]:
        del grouped["_local"]

    logger.info(
        f"Grouped {len(tools)} tools into {len(grouped)} namespaces: "
        f"{list(grouped.keys())}"
    )

    return grouped


def validate_namespaced_tool(tool_name: str) -> Tuple[bool, Optional[str]]:
    """
    Validate a namespaced tool name.

    Args:
        tool_name: Tool name to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not tool_name:
        return False, "Tool name is empty"

    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', tool_name.replace(NAMESPACE_SEPARATOR, '_')):
        return False, f"Tool name contains invalid characters: {tool_name}"

    parsed = parse_tool_name(tool_name)

    if parsed.is_namespaced:
        if not parsed.namespace:
            return False, f"Empty namespace in tool name: {tool_name}"
        if not parsed.base_name:
            return False, f"Empty base name in tool name: {tool_name}"

    return True, None


class ToolNamespaceResolver:
    """
    Resolves tool names to their namespaced equivalents.

    Provides mapping from user-friendly names to full namespaced names.
    """

    def __init__(self):
        self._alias_map: Dict[str, str] = {}
        self._namespace_map: Dict[str, Dict[str, str]] = {}

    def register_tool(
        self,
        full_name: str,
        aliases: Optional[List[str]] = None
    ) -> None:
        """
        Register a tool with optional aliases.

        Args:
            full_name: Full namespaced tool name
            aliases: Optional list of alias names
        """
        parsed = parse_tool_name(full_name)

        # Register base name as implicit alias
        if parsed.is_namespaced and parsed.namespace:
            if parsed.namespace not in self._namespace_map:
                self._namespace_map[parsed.namespace] = {}
            self._namespace_map[parsed.namespace][parsed.base_name] = full_name

        # Register explicit aliases
        if aliases:
            for alias in aliases:
                self._alias_map[alias] = full_name

    def resolve(
        self,
        name: str,
        namespace_hint: Optional[str] = None
    ) -> Optional[str]:
        """
        Resolve a tool name to its full namespaced name.

        Args:
            name: Tool name or alias
            namespace_hint: Optional namespace to search in first

        Returns:
            Full namespaced tool name or None if not found
        """
        # Check if already namespaced
        parsed = parse_tool_name(name)
        if parsed.is_namespaced:
            return name

        # Check aliases first
        if name in self._alias_map:
            return self._alias_map[name]

        # Check namespace hint
        if namespace_hint and namespace_hint in self._namespace_map:
            if name in self._namespace_map[namespace_hint]:
                return self._namespace_map[namespace_hint][name]

        # Search all namespaces
        for ns, tools in self._namespace_map.items():
            if name in tools:
                return tools[name]

        return None

    def list_tools(self, namespace: Optional[str] = None) -> List[str]:
        """
        List all registered tool names.

        Args:
            namespace: Optional namespace filter

        Returns:
            List of full tool names
        """
        if namespace:
            return list(self._namespace_map.get(namespace, {}).values())

        all_tools = []
        for ns_tools in self._namespace_map.values():
            all_tools.extend(ns_tools.values())
        return all_tools
```

### Step 2: Update MCP Module Init

Update `/opt/hx-lang-server/app/mcp/__init__.py` to export namespace utilities:

```python
"""MCP Client Integration Module for hx-lang-server."""

from .client import MCPClientManager, get_mcp_client
from .gateway import (
    get_gateway_url,
    get_gateway_mcp_endpoint,
    get_server_config,
    check_gateway_health,
    GATEWAY_HOSTNAME,
    GATEWAY_PORT,
)
from .namespace import (
    parse_tool_name,
    build_namespaced_name,
    get_namespace,
    get_base_name,
    is_known_namespace,
    filter_tools_by_namespace,
    group_tools_by_namespace,
    validate_namespaced_tool,
    ToolNamespaceResolver,
    NAMESPACE_SEPARATOR,
    KNOWN_NAMESPACES,
    ParsedToolName,
)

__all__ = [
    # Client
    "MCPClientManager",
    "get_mcp_client",
    # Gateway
    "get_gateway_url",
    "get_gateway_mcp_endpoint",
    "get_server_config",
    "check_gateway_health",
    "GATEWAY_HOSTNAME",
    "GATEWAY_PORT",
    # Namespace
    "parse_tool_name",
    "build_namespaced_name",
    "get_namespace",
    "get_base_name",
    "is_known_namespace",
    "filter_tools_by_namespace",
    "group_tools_by_namespace",
    "validate_namespaced_tool",
    "ToolNamespaceResolver",
    "NAMESPACE_SEPARATOR",
    "KNOWN_NAMESPACES",
    "ParsedToolName",
]
```

### Step 3: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    parse_tool_name,
    build_namespaced_name,
    get_namespace,
    get_base_name,
    validate_namespaced_tool,
    NAMESPACE_SEPARATOR
)

# Test parsing
result = parse_tool_name('crawl4ai__smart_crawl_url')
print(f'Parsed: namespace={result.namespace}, base={result.base_name}')
assert result.namespace == 'crawl4ai'
assert result.base_name == 'smart_crawl_url'
assert result.is_namespaced == True

# Test non-namespaced
result = parse_tool_name('local_tool')
print(f'Parsed: namespace={result.namespace}, base={result.base_name}')
assert result.namespace is None
assert result.base_name == 'local_tool'
assert result.is_namespaced == False

# Test building
full_name = build_namespaced_name('docling', 'convert_document')
print(f'Built: {full_name}')
assert full_name == 'docling__convert_document'

# Test validation
valid, error = validate_namespaced_tool('crawl4ai__smart_crawl_url')
print(f'Validation: valid={valid}, error={error}')
assert valid == True

print('All namespace tests passed')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Namespace module | `/opt/hx-lang-server/app/mcp/namespace.py` | Namespace utilities |
| Updated module init | `/opt/hx-lang-server/app/mcp/__init__.py` | Namespace exports |

---

## Verification Steps

- [ ] `namespace.py` module created
- [ ] parse_tool_name() correctly parses namespaced names
- [ ] build_namespaced_name() creates correct namespaced names
- [ ] filter_tools_by_namespace() filters tool lists correctly
- [ ] group_tools_by_namespace() groups tools by namespace
- [ ] validate_namespaced_tool() validates tool names

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Full verification script
python -c "
from app.mcp import (
    parse_tool_name,
    build_namespaced_name,
    get_namespace,
    get_base_name,
    is_known_namespace,
    validate_namespaced_tool,
    KNOWN_NAMESPACES,
    ToolNamespaceResolver,
)

# Test all core functions
tests_passed = 0

# Test 1: Parse namespaced
result = parse_tool_name('crawl4ai__smart_crawl_url')
assert result.namespace == 'crawl4ai', 'Parse namespace failed'
assert result.base_name == 'smart_crawl_url', 'Parse base_name failed'
tests_passed += 1

# Test 2: Parse non-namespaced
result = parse_tool_name('local_tool')
assert result.namespace is None, 'Parse non-namespaced failed'
assert result.base_name == 'local_tool', 'Parse non-namespaced base failed'
tests_passed += 1

# Test 3: Build namespaced
name = build_namespaced_name('docling', 'convert')
assert name == 'docling__convert', 'Build namespaced failed'
tests_passed += 1

# Test 4: Get namespace
ns = get_namespace('crawl4ai__smart_crawl_url')
assert ns == 'crawl4ai', 'Get namespace failed'
tests_passed += 1

# Test 5: Get base name
base = get_base_name('crawl4ai__smart_crawl_url')
assert base == 'smart_crawl_url', 'Get base name failed'
tests_passed += 1

# Test 6: Known namespace
assert is_known_namespace('crawl4ai') == True, 'Known namespace failed'
assert is_known_namespace('unknown') == False, 'Unknown namespace failed'
tests_passed += 1

# Test 7: Validation
valid, error = validate_namespaced_tool('crawl4ai__smart_crawl_url')
assert valid == True, 'Validation failed'
tests_passed += 1

# Test 8: ToolNamespaceResolver
resolver = ToolNamespaceResolver()
resolver.register_tool('crawl4ai__smart_crawl_url')
resolved = resolver.resolve('smart_crawl_url', namespace_hint='crawl4ai')
assert resolved == 'crawl4ai__smart_crawl_url', 'Resolver failed'
tests_passed += 1

print(f'All {tests_passed} namespace tests passed!')
"
```

---

## Acceptance Criteria

1. **AC-093-1**: parse_tool_name() returns ParsedToolName with namespace and base_name
2. **AC-093-2**: build_namespaced_name() creates correct namespaced format
3. **AC-093-3**: filter_tools_by_namespace() filters tools correctly
4. **AC-093-4**: group_tools_by_namespace() groups tools by source server
5. **AC-093-5**: validate_namespaced_tool() validates tool name format
6. **AC-093-6**: KNOWN_NAMESPACES contains crawl4ai and docling definitions
7. **AC-093-7**: ToolNamespaceResolver resolves aliases to full names

---

## Rollback Procedure

```bash
sudo rm /opt/hx-lang-server/app/mcp/namespace.py

# Restore previous __init__.py (from task-092 state)
```

---

## Notes

- FastMCP gateway uses `__` (double underscore) as namespace separator
- Tool names follow pattern: `{server}__{tool_name}`
- Known namespaces: crawl4ai (web crawling), docling (document processing)
- ToolNamespaceResolver enables user-friendly tool invocation
- Namespace handling is critical for correct tool invocation via gateway
- Additional namespaces can be added to KNOWN_NAMESPACES as more MCP servers are deployed

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
