# Task: Create MCP Integration Tests

**Task ID**: hx-lang-server-task-097-create-mcp-integration-tests
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-096 (tool discovery and registration)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 45 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Testing Strategy"

---

## Objective

Create comprehensive integration tests for MCP client functionality including gateway connectivity, tool discovery, namespace handling, protocol version detection, and tool invocation. Tests verify all MCP-related requirements from the specification.

**Test Coverage Requirements:**
- Gateway connectivity (FR-018)
- Tool discovery and invocation (FR-019)
- Namespace handling (FR-020)
- MCP v1.1 feature detection (FR-020a)

---

## Prerequisites

- [ ] Tool registry implemented (task-096)
- [ ] All MCP modules implemented (tasks 091-096)
- [ ] pytest installed in virtual environment
- [ ] Network connectivity to hx-fastmcp-server.hx.dev.local

---

## Implementation Steps

### Step 1: Create Tests Directory Structure

```bash
sudo -u hx-lang-server mkdir -p /opt/hx-lang-server/tests/mcp
sudo -u hx-lang-server touch /opt/hx-lang-server/tests/__init__.py
sudo -u hx-lang-server touch /opt/hx-lang-server/tests/mcp/__init__.py
```

### Step 2: Create MCP Gateway Integration Tests

Create file `/opt/hx-lang-server/tests/mcp/test_gateway.py`:

```python
"""
Integration tests for MCP gateway connectivity.

Tests FR-018: Service MUST connect to FastMCP gateway at hx-fastmcp-server.hx.dev.local
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

# Import modules under test
import sys
sys.path.insert(0, '/opt/hx-lang-server')

from app.mcp.gateway import (
    get_gateway_url,
    get_gateway_mcp_endpoint,
    get_server_config,
    check_gateway_health,
    GATEWAY_HOSTNAME,
    GATEWAY_PORT,
)


class TestGatewayConfiguration:
    """Tests for gateway configuration functions."""

    def test_gateway_hostname_uses_dns(self):
        """Verify gateway uses DNS hostname, not hardcoded IP."""
        assert GATEWAY_HOSTNAME == "hx-fastmcp-server.hx.dev.local"
        assert "192.168" not in GATEWAY_HOSTNAME

    def test_gateway_port_is_8000(self):
        """Verify default gateway port is 8000."""
        assert GATEWAY_PORT == 8000

    def test_get_gateway_url_format(self):
        """Verify gateway URL format."""
        url = get_gateway_url()
        assert url.startswith("http://")
        assert "hx-fastmcp-server" in url or "fastmcp" in url.lower()

    def test_get_gateway_mcp_endpoint_includes_path(self):
        """Verify MCP endpoint includes /mcp path."""
        endpoint = get_gateway_mcp_endpoint()
        assert endpoint.endswith("/mcp")

    def test_get_server_config_transport_type(self):
        """Verify server config uses streamable_http transport."""
        config = get_server_config()
        assert "fastmcp" in config
        assert config["fastmcp"]["transport"] == "streamable_http"

    def test_get_server_config_has_url(self):
        """Verify server config includes URL."""
        config = get_server_config()
        assert "url" in config["fastmcp"]
        assert "/mcp" in config["fastmcp"]["url"]


class TestGatewayHealthCheck:
    """Tests for gateway health check functionality."""

    @pytest.mark.asyncio
    async def test_check_gateway_health_returns_dict(self):
        """Verify health check returns dictionary with expected keys."""
        # Mock the HTTP client
        with patch('app.mcp.gateway.httpx.AsyncClient') as mock_client:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"status": "healthy"}
            mock_response.content = b'{"status": "healthy"}'

            mock_client_instance = AsyncMock()
            mock_client_instance.get.return_value = mock_response
            mock_client_instance.__aenter__.return_value = mock_client_instance
            mock_client_instance.__aexit__.return_value = None
            mock_client.return_value = mock_client_instance

            result = await check_gateway_health()

            assert isinstance(result, dict)
            assert "healthy" in result
            assert "gateway_url" in result

    @pytest.mark.asyncio
    async def test_check_gateway_health_handles_connection_error(self):
        """Verify health check handles connection errors gracefully."""
        import httpx

        with patch('app.mcp.gateway.httpx.AsyncClient') as mock_client:
            mock_client_instance = AsyncMock()
            mock_client_instance.get.side_effect = httpx.ConnectError("Connection refused")
            mock_client_instance.__aenter__.return_value = mock_client_instance
            mock_client_instance.__aexit__.return_value = None
            mock_client.return_value = mock_client_instance

            result = await check_gateway_health()

            assert result["healthy"] == False
            assert "error" in result

    @pytest.mark.asyncio
    async def test_check_gateway_health_handles_timeout(self):
        """Verify health check handles timeout errors."""
        import httpx

        with patch('app.mcp.gateway.httpx.AsyncClient') as mock_client:
            mock_client_instance = AsyncMock()
            mock_client_instance.get.side_effect = httpx.TimeoutException("Timeout")
            mock_client_instance.__aenter__.return_value = mock_client_instance
            mock_client_instance.__aexit__.return_value = None
            mock_client.return_value = mock_client_instance

            result = await check_gateway_health()

            assert result["healthy"] == False
            assert "Timeout" in result.get("error", "")


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 3: Create Namespace Handling Tests

Create file `/opt/hx-lang-server/tests/mcp/test_namespace.py`:

```python
"""
Tests for MCP tool namespace handling.

Tests FR-020: Service MUST handle tool namespace prefixes from gateway
"""

import pytest
import sys
sys.path.insert(0, '/opt/hx-lang-server')

from app.mcp.namespace import (
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


class TestParseToolName:
    """Tests for parse_tool_name function."""

    def test_parse_namespaced_tool(self):
        """Verify parsing of namespaced tool names."""
        result = parse_tool_name("crawl4ai__smart_crawl_url")
        assert result.namespace == "crawl4ai"
        assert result.base_name == "smart_crawl_url"
        assert result.is_namespaced == True
        assert result.full_name == "crawl4ai__smart_crawl_url"

    def test_parse_non_namespaced_tool(self):
        """Verify parsing of non-namespaced tool names."""
        result = parse_tool_name("local_tool")
        assert result.namespace is None
        assert result.base_name == "local_tool"
        assert result.is_namespaced == False

    def test_parse_docling_namespace(self):
        """Verify parsing of docling namespace."""
        result = parse_tool_name("docling__convert_document")
        assert result.namespace == "docling"
        assert result.base_name == "convert_document"

    def test_parse_tool_with_underscores_in_name(self):
        """Verify parsing handles underscores in base name."""
        result = parse_tool_name("server__tool_with_underscores")
        assert result.namespace == "server"
        assert result.base_name == "tool_with_underscores"


class TestBuildNamespacedName:
    """Tests for build_namespaced_name function."""

    def test_build_with_crawl4ai(self):
        """Verify building crawl4ai namespaced name."""
        result = build_namespaced_name("crawl4ai", "smart_crawl_url")
        assert result == "crawl4ai__smart_crawl_url"

    def test_build_with_docling(self):
        """Verify building docling namespaced name."""
        result = build_namespaced_name("docling", "convert_document")
        assert result == "docling__convert_document"

    def test_build_uses_double_underscore(self):
        """Verify namespace separator is double underscore."""
        result = build_namespaced_name("ns", "tool")
        assert "__" in result
        assert result == "ns__tool"


class TestGetNamespaceAndBaseName:
    """Tests for get_namespace and get_base_name functions."""

    def test_get_namespace_from_namespaced(self):
        """Verify extracting namespace from namespaced tool."""
        ns = get_namespace("crawl4ai__smart_crawl_url")
        assert ns == "crawl4ai"

    def test_get_namespace_from_non_namespaced(self):
        """Verify None returned for non-namespaced tool."""
        ns = get_namespace("local_tool")
        assert ns is None

    def test_get_base_name_from_namespaced(self):
        """Verify extracting base name from namespaced tool."""
        base = get_base_name("crawl4ai__smart_crawl_url")
        assert base == "smart_crawl_url"

    def test_get_base_name_from_non_namespaced(self):
        """Verify base name equals full name for non-namespaced."""
        base = get_base_name("local_tool")
        assert base == "local_tool"


class TestKnownNamespaces:
    """Tests for known namespace validation."""

    def test_crawl4ai_is_known(self):
        """Verify crawl4ai is a known namespace."""
        assert is_known_namespace("crawl4ai") == True

    def test_docling_is_known(self):
        """Verify docling is a known namespace."""
        assert is_known_namespace("docling") == True

    def test_unknown_namespace(self):
        """Verify unknown namespace returns False."""
        assert is_known_namespace("unknown_server") == False

    def test_known_namespaces_dict_structure(self):
        """Verify KNOWN_NAMESPACES has expected structure."""
        assert "crawl4ai" in KNOWN_NAMESPACES
        assert "docling" in KNOWN_NAMESPACES
        assert "server" in KNOWN_NAMESPACES["crawl4ai"]
        assert "description" in KNOWN_NAMESPACES["crawl4ai"]


class TestValidateNamespacedTool:
    """Tests for tool name validation."""

    def test_valid_namespaced_tool(self):
        """Verify valid namespaced tool passes validation."""
        valid, error = validate_namespaced_tool("crawl4ai__smart_crawl_url")
        assert valid == True
        assert error is None

    def test_valid_non_namespaced_tool(self):
        """Verify valid non-namespaced tool passes validation."""
        valid, error = validate_namespaced_tool("local_tool")
        assert valid == True
        assert error is None

    def test_empty_tool_name_fails(self):
        """Verify empty tool name fails validation."""
        valid, error = validate_namespaced_tool("")
        assert valid == False
        assert error is not None


class TestToolNamespaceResolver:
    """Tests for ToolNamespaceResolver class."""

    def test_resolve_registered_tool(self):
        """Verify resolving a registered tool."""
        resolver = ToolNamespaceResolver()
        resolver.register_tool("crawl4ai__smart_crawl_url")

        result = resolver.resolve("smart_crawl_url", namespace_hint="crawl4ai")
        assert result == "crawl4ai__smart_crawl_url"

    def test_resolve_already_namespaced(self):
        """Verify already namespaced names pass through."""
        resolver = ToolNamespaceResolver()
        result = resolver.resolve("crawl4ai__smart_crawl_url")
        assert result == "crawl4ai__smart_crawl_url"

    def test_resolve_with_alias(self):
        """Verify resolving via alias."""
        resolver = ToolNamespaceResolver()
        resolver.register_tool("crawl4ai__smart_crawl_url", aliases=["crawl", "fetch_url"])

        result = resolver.resolve("crawl")
        assert result == "crawl4ai__smart_crawl_url"

    def test_resolve_unknown_returns_none(self):
        """Verify resolving unknown tool returns None."""
        resolver = ToolNamespaceResolver()
        result = resolver.resolve("unknown_tool")
        assert result is None


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 4: Create Protocol Version Tests

Create file `/opt/hx-lang-server/tests/mcp/test_protocol.py`:

```python
"""
Tests for MCP protocol version detection.

Tests FR-020a: MCP v1.1 with feature detection for backward compatibility
"""

import pytest
import sys
sys.path.insert(0, '/opt/hx-lang-server')

from app.mcp.protocol import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    get_feature_detector,
    detect_server_version,
    V1_0_FEATURES,
    V1_1_FEATURES,
)


class TestMCPVersionEnum:
    """Tests for MCPVersion enumeration."""

    def test_v10_value(self):
        """Verify v1.0 enum value."""
        assert MCPVersion.V1_0.value == "1.0"

    def test_v11_value(self):
        """Verify v1.1 enum value."""
        assert MCPVersion.V1_1.value == "1.1"

    def test_unknown_value(self):
        """Verify unknown enum value."""
        assert MCPVersion.UNKNOWN.value == "unknown"


class TestMCPFeatureEnum:
    """Tests for MCPFeature enumeration."""

    def test_streamable_http_feature(self):
        """Verify STREAMABLE_HTTP feature defined."""
        assert MCPFeature.STREAMABLE_HTTP.value == "streamable_http"

    def test_progress_reporting_feature(self):
        """Verify PROGRESS_REPORTING feature defined."""
        assert MCPFeature.PROGRESS_REPORTING.value == "progress_reporting"

    def test_v11_features_include_streamable_http(self):
        """Verify V1_1_FEATURES includes STREAMABLE_HTTP."""
        assert MCPFeature.STREAMABLE_HTTP in V1_1_FEATURES

    def test_v11_features_include_progress(self):
        """Verify V1_1_FEATURES includes PROGRESS_REPORTING."""
        assert MCPFeature.PROGRESS_REPORTING in V1_1_FEATURES


class TestServerCapabilities:
    """Tests for ServerCapabilities dataclass."""

    def test_default_values(self):
        """Verify default capability values."""
        caps = ServerCapabilities()
        assert caps.version == MCPVersion.UNKNOWN
        assert caps.server_name is None
        assert len(caps.features) == 0

    def test_has_feature_when_present(self):
        """Verify has_feature returns True when present."""
        caps = ServerCapabilities()
        caps.features.add(MCPFeature.STREAMABLE_HTTP)
        assert caps.has_feature(MCPFeature.STREAMABLE_HTTP) == True

    def test_has_feature_when_absent(self):
        """Verify has_feature returns False when absent."""
        caps = ServerCapabilities()
        assert caps.has_feature(MCPFeature.STREAMABLE_HTTP) == False

    def test_is_v11_compatible_when_v11(self):
        """Verify is_v11_compatible for v1.1 server."""
        caps = ServerCapabilities(version=MCPVersion.V1_1)
        assert caps.is_v11_compatible() == True

    def test_is_v11_compatible_when_v10(self):
        """Verify is_v11_compatible for v1.0 server."""
        caps = ServerCapabilities(version=MCPVersion.V1_0)
        assert caps.is_v11_compatible() == False

    def test_supports_streamable_http(self):
        """Verify supports_streamable_http method."""
        caps = ServerCapabilities()
        caps.features.add(MCPFeature.STREAMABLE_HTTP)
        assert caps.supports_streamable_http() == True

    def test_to_dict(self):
        """Verify to_dict serialization."""
        caps = ServerCapabilities(
            version=MCPVersion.V1_1,
            server_name="test_server"
        )
        caps.features.add(MCPFeature.STREAMABLE_HTTP)

        d = caps.to_dict()
        assert d["version"] == "1.1"
        assert d["server_name"] == "test_server"
        assert "streamable_http" in d["features"]


class TestMCPFeatureDetector:
    """Tests for MCPFeatureDetector class."""

    def test_detect_from_transport_streamable_http(self):
        """Verify v1.1 detected for streamable_http transport."""
        detector = MCPFeatureDetector()
        caps = detector.detect_from_transport("test_server", "streamable_http")

        assert caps.version == MCPVersion.V1_1
        assert MCPFeature.STREAMABLE_HTTP in caps.features

    def test_detect_from_transport_sse(self):
        """Verify v1.1 detected for SSE transport."""
        detector = MCPFeatureDetector()
        caps = detector.detect_from_transport("test_server", "sse")

        assert caps.version == MCPVersion.V1_1

    def test_detect_from_transport_stdio(self):
        """Verify unknown version for stdio transport."""
        detector = MCPFeatureDetector()
        caps = detector.detect_from_transport("test_server", "stdio")

        # stdio could be either version
        assert caps.version in [MCPVersion.UNKNOWN, MCPVersion.V1_0, MCPVersion.V1_1]

    def test_get_capabilities_returns_cached(self):
        """Verify capabilities are cached."""
        detector = MCPFeatureDetector()
        detector.detect_from_transport("cached_server", "streamable_http")

        caps = detector.get_capabilities("cached_server")
        assert caps is not None
        assert caps.version == MCPVersion.V1_1

    def test_should_use_v11_features_true(self):
        """Verify should_use_v11_features returns True for v1.1 server."""
        detector = MCPFeatureDetector()
        detector.detect_from_transport("v11_server", "streamable_http")

        assert detector.should_use_v11_features("v11_server") == True

    def test_should_use_v11_features_false_for_unknown(self):
        """Verify should_use_v11_features returns False for unknown server."""
        detector = MCPFeatureDetector()
        assert detector.should_use_v11_features("unknown_server") == False


class TestFeatureDetectorSingleton:
    """Tests for feature detector singleton."""

    def test_singleton_instance(self):
        """Verify get_feature_detector returns singleton."""
        d1 = get_feature_detector()
        d2 = get_feature_detector()
        assert d1 is d2


class TestDetectServerVersion:
    """Tests for detect_server_version convenience function."""

    def test_detect_from_transport_type(self):
        """Verify detection from transport type."""
        caps = detect_server_version("test", transport_type="streamable_http")
        assert caps.version == MCPVersion.V1_1

    def test_detect_with_no_input(self):
        """Verify detection with no input returns unknown."""
        caps = detect_server_version("test")
        assert caps.detection_method == "no_input"


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 5: Create Fallback Mechanism Tests

Create file `/opt/hx-lang-server/tests/mcp/test_fallback.py`:

```python
"""
Tests for MCP v1.0 fallback mechanism.

Tests FR-020a: Graceful fallback to v1.0 for incompatible servers
"""

import pytest
import sys
sys.path.insert(0, '/opt/hx-lang-server')

from app.mcp.fallback import (
    FallbackReason,
    FallbackContext,
    MCPFallbackHandler,
    get_fallback_handler,
)
from app.mcp.protocol import MCPFeature, MCPVersion


class TestFallbackReason:
    """Tests for FallbackReason enumeration."""

    def test_server_incompatible_reason(self):
        """Verify SERVER_INCOMPATIBLE reason."""
        assert FallbackReason.SERVER_INCOMPATIBLE.value == "server_does_not_support_v1.1"

    def test_transport_limitation_reason(self):
        """Verify TRANSPORT_LIMITATION reason."""
        assert FallbackReason.TRANSPORT_LIMITATION.value == "transport_does_not_support_feature"


class TestFallbackContext:
    """Tests for FallbackContext dataclass."""

    def test_fallback_context_creation(self):
        """Verify FallbackContext creation."""
        ctx = FallbackContext(
            used_fallback=True,
            reason=FallbackReason.SERVER_INCOMPATIBLE,
            original_feature=MCPFeature.STREAMABLE_HTTP,
            fallback_feature="sse",
            server_name="test_server",
            message="Test message"
        )
        assert ctx.used_fallback == True
        assert ctx.reason == FallbackReason.SERVER_INCOMPATIBLE

    def test_fallback_context_to_dict(self):
        """Verify FallbackContext.to_dict serialization."""
        ctx = FallbackContext(
            used_fallback=True,
            reason=FallbackReason.SERVER_INCOMPATIBLE,
            original_feature=MCPFeature.STREAMABLE_HTTP,
            fallback_feature="sse",
            server_name="test",
            message="Test"
        )
        d = ctx.to_dict()
        assert d["used_fallback"] == True
        assert d["reason"] == "server_does_not_support_v1.1"


class TestMCPFallbackHandler:
    """Tests for MCPFallbackHandler class."""

    def test_should_fallback_for_unknown_server(self):
        """Verify fallback needed for unknown server."""
        handler = MCPFallbackHandler()
        should_fb, fallback = handler.should_fallback("unknown", MCPFeature.STREAMABLE_HTTP)
        assert should_fb == True
        assert fallback == "sse"

    def test_apply_transport_fallback_streamable_http(self):
        """Verify streamable_http falls back to sse."""
        handler = MCPFallbackHandler()
        result = handler.apply_transport_fallback("unknown", "streamable_http")
        assert result == "sse"

    def test_apply_transport_fallback_other_unchanged(self):
        """Verify other transports unchanged."""
        handler = MCPFallbackHandler()
        result = handler.apply_transport_fallback("unknown", "stdio")
        assert result == "stdio"

    def test_get_fallback_for_feature(self):
        """Verify getting fallback for specific feature."""
        handler = MCPFallbackHandler()
        fb = handler.get_fallback_for_feature(MCPFeature.STREAMABLE_HTTP)
        assert fb is not None
        assert fb["fallback"] == "sse"

    def test_create_fallback_context_unknown_server(self):
        """Verify fallback context for unknown server."""
        handler = MCPFallbackHandler()
        ctx = handler.create_fallback_context("unknown", MCPFeature.PROGRESS_REPORTING)
        assert ctx.used_fallback == True
        assert ctx.reason == FallbackReason.UNKNOWN

    def test_fallback_history_recorded(self):
        """Verify fallback history is recorded."""
        handler = MCPFallbackHandler()
        handler.apply_transport_fallback("test_server", "streamable_http")

        history = handler.get_fallback_history("test_server")
        assert len(history) > 0
        assert history[0]["feature"] == "transport"


class TestFallbackHandlerSingleton:
    """Tests for fallback handler singleton."""

    def test_singleton_instance(self):
        """Verify get_fallback_handler returns singleton."""
        h1 = get_fallback_handler()
        h2 = get_fallback_handler()
        assert h1 is h2


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 6: Create pytest Configuration

Create file `/opt/hx-lang-server/tests/mcp/conftest.py`:

```python
"""
Pytest configuration for MCP integration tests.
"""

import pytest
import sys
import os

# Ensure app module is importable
sys.path.insert(0, '/opt/hx-lang-server')

# Set test environment
os.environ.setdefault('TESTING', 'true')


@pytest.fixture
def mock_mcp_client():
    """Fixture for mocked MCP client."""
    from unittest.mock import AsyncMock, MagicMock

    client = MagicMock()
    client.get_tools = AsyncMock(return_value=[])
    client.invoke_tool = AsyncMock(return_value=MagicMock(content=[MagicMock(text="result")]))

    return client


@pytest.fixture
def sample_tools():
    """Fixture for sample tool list."""
    from unittest.mock import MagicMock

    tools = []

    # Crawl4AI tool
    tool1 = MagicMock()
    tool1.name = "crawl4ai__smart_crawl_url"
    tool1.description = "Crawl a URL and extract content"
    tool1.args_schema = None
    tools.append(tool1)

    # Docling tool
    tool2 = MagicMock()
    tool2.name = "docling__convert_document"
    tool2.description = "Convert document to markdown"
    tool2.args_schema = None
    tools.append(tool2)

    return tools
```

### Step 7: Run Tests

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Install pytest if not installed
pip install pytest pytest-asyncio

# Run all MCP tests
pytest tests/mcp/ -v

# Run specific test file
pytest tests/mcp/test_namespace.py -v

# Run with coverage
pip install pytest-cov
pytest tests/mcp/ -v --cov=app/mcp --cov-report=term-missing
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Test directory | `/opt/hx-lang-server/tests/mcp/` | MCP test suite |
| Gateway tests | `/opt/hx-lang-server/tests/mcp/test_gateway.py` | Gateway connectivity tests |
| Namespace tests | `/opt/hx-lang-server/tests/mcp/test_namespace.py` | Namespace handling tests |
| Protocol tests | `/opt/hx-lang-server/tests/mcp/test_protocol.py` | Version detection tests |
| Fallback tests | `/opt/hx-lang-server/tests/mcp/test_fallback.py` | Fallback mechanism tests |
| Test config | `/opt/hx-lang-server/tests/mcp/conftest.py` | Pytest fixtures |

---

## Verification Steps

- [ ] Test directory structure created
- [ ] All test files created
- [ ] pytest discovers all tests
- [ ] All tests pass
- [ ] Test coverage > 80% for MCP modules

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Verify test discovery
pytest tests/mcp/ --collect-only

# Run all tests
pytest tests/mcp/ -v

# Verify test count
pytest tests/mcp/ -v --tb=no | grep -E "passed|failed|error"

# Run with coverage report
pytest tests/mcp/ --cov=app/mcp --cov-report=term-missing
```

---

## Acceptance Criteria

1. **AC-097-1**: Test directory structure exists at `/opt/hx-lang-server/tests/mcp/`
2. **AC-097-2**: Gateway tests cover FR-018 requirements
3. **AC-097-3**: Namespace tests cover FR-020 requirements
4. **AC-097-4**: Protocol tests cover FR-020a version detection
5. **AC-097-5**: Fallback tests cover FR-020a graceful fallback
6. **AC-097-6**: All tests pass with pytest
7. **AC-097-7**: Test coverage > 80% for app/mcp modules

---

## Rollback Procedure

```bash
sudo rm -rf /opt/hx-lang-server/tests/mcp/
```

---

## Notes

- Tests use pytest-asyncio for async test support
- Mock objects used to avoid actual gateway connectivity in unit tests
- Integration tests with real gateway connectivity should be run separately
- conftest.py provides shared fixtures for all MCP tests
- Test coverage should be verified before promoting to operational
- Tests verify all MCP-related functional requirements (FR-017 through FR-020a)

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
