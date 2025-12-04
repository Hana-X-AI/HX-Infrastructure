# Task: Implement MCP v1.1 Feature Detection

**Task ID**: hx-lang-server-task-094-implement-mcp-v11-feature-detection
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-093 (tool namespace handling)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 40 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-020a)

---

## Objective

Implement MCP v1.1 feature detection to identify protocol version capabilities when connecting to MCP servers. This enables hx-lang-server to use v1.1 features when available while maintaining compatibility with v1.0 servers.

**CAIO Decision (FR-020a)**:
- Use MCP protocol v1.1 features when available
- Implement feature detection for v1.1 capabilities
- Graceful fallback to v1.0 for incompatible servers
- Log protocol version negotiation for debugging

---

## Prerequisites

- [ ] Tool namespace handling implemented (task-093)
- [ ] MCP client module exists (task-091)
- [ ] Understanding of MCP protocol version differences

---

## Background: MCP Protocol Versions

### MCP v1.0 (Baseline)
- Basic tool discovery and invocation
- Resource reading
- Prompt retrieval
- Stdio transport

### MCP v1.1 (Enhanced)
- Streamable HTTP transport
- Progress reporting
- Enhanced error messages
- Server capabilities negotiation
- Improved logging/notifications

---

## Implementation Steps

### Step 1: Create Protocol Version Module

Create file `/opt/hx-lang-server/app/mcp/protocol.py`:

```python
"""
MCP Protocol Version Detection and Feature Management.

Implements MCP v1.1 feature detection with graceful fallback to v1.0.
Per CAIO decision FR-020a:
- Use v1.1 features when available
- Implement feature detection for v1.1 capabilities
- Graceful fallback to v1.0 for incompatible servers
- Log protocol version negotiation for debugging
"""

import logging
from typing import Dict, Any, Optional, Set
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class MCPVersion(Enum):
    """MCP Protocol versions."""
    V1_0 = "1.0"
    V1_1 = "1.1"
    UNKNOWN = "unknown"


class MCPFeature(Enum):
    """MCP v1.1 features that can be detected."""
    STREAMABLE_HTTP = "streamable_http"
    PROGRESS_REPORTING = "progress_reporting"
    ENHANCED_ERRORS = "enhanced_errors"
    CAPABILITIES_NEGOTIATION = "capabilities_negotiation"
    NOTIFICATIONS = "notifications"
    LOGGING = "logging"
    ROOTS = "roots"
    SAMPLING = "sampling"


# Default capabilities for each version
V1_0_FEATURES: Set[MCPFeature] = {
    # v1.0 has basic features only
}

V1_1_FEATURES: Set[MCPFeature] = {
    MCPFeature.STREAMABLE_HTTP,
    MCPFeature.PROGRESS_REPORTING,
    MCPFeature.ENHANCED_ERRORS,
    MCPFeature.CAPABILITIES_NEGOTIATION,
    MCPFeature.NOTIFICATIONS,
    MCPFeature.LOGGING,
    MCPFeature.ROOTS,
    MCPFeature.SAMPLING,
}


@dataclass
class ServerCapabilities:
    """
    Detected capabilities of an MCP server.

    Populated during connection initialization based on
    server response to capabilities negotiation.
    """
    version: MCPVersion = MCPVersion.UNKNOWN
    server_name: Optional[str] = None
    server_version: Optional[str] = None
    protocol_version: Optional[str] = None
    features: Set[MCPFeature] = field(default_factory=set)
    raw_capabilities: Dict[str, Any] = field(default_factory=dict)
    detection_method: str = "unknown"

    def has_feature(self, feature: MCPFeature) -> bool:
        """Check if server supports a specific feature."""
        return feature in self.features

    def is_v11_compatible(self) -> bool:
        """Check if server supports MCP v1.1."""
        return self.version == MCPVersion.V1_1

    def supports_streamable_http(self) -> bool:
        """Check if server supports streamable HTTP transport."""
        return self.has_feature(MCPFeature.STREAMABLE_HTTP)

    def supports_progress(self) -> bool:
        """Check if server supports progress reporting."""
        return self.has_feature(MCPFeature.PROGRESS_REPORTING)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for logging/serialization."""
        return {
            "version": self.version.value,
            "server_name": self.server_name,
            "server_version": self.server_version,
            "protocol_version": self.protocol_version,
            "features": [f.value for f in self.features],
            "detection_method": self.detection_method,
        }


class MCPFeatureDetector:
    """
    Detects MCP protocol version and features for connected servers.

    Implements CAIO decision FR-020a:
    - Detect v1.1 capabilities
    - Log negotiation for debugging
    - Enable graceful fallback
    """

    def __init__(self):
        self._server_capabilities: Dict[str, ServerCapabilities] = {}

    def detect_from_initialize_result(
        self,
        server_name: str,
        initialize_result: Any
    ) -> ServerCapabilities:
        """
        Detect capabilities from MCP initialize result.

        Args:
            server_name: Name/identifier of the server
            initialize_result: Result from client initialization

        Returns:
            ServerCapabilities with detected features
        """
        capabilities = ServerCapabilities(
            detection_method="initialize_result"
        )

        try:
            # Extract server info
            if hasattr(initialize_result, 'serverInfo'):
                server_info = initialize_result.serverInfo
                capabilities.server_name = getattr(server_info, 'name', None)
                capabilities.server_version = getattr(server_info, 'version', None)

            # Extract protocol version
            if hasattr(initialize_result, 'protocolVersion'):
                capabilities.protocol_version = initialize_result.protocolVersion
                capabilities.version = self._parse_version(
                    initialize_result.protocolVersion
                )

            # Extract capabilities
            if hasattr(initialize_result, 'capabilities'):
                raw_caps = initialize_result.capabilities
                capabilities.raw_capabilities = self._extract_raw_capabilities(raw_caps)
                capabilities.features = self._detect_features(raw_caps)

            # Determine version from features if not explicitly set
            if capabilities.version == MCPVersion.UNKNOWN:
                capabilities.version = self._infer_version_from_features(
                    capabilities.features
                )

        except Exception as e:
            logger.warning(
                f"Error detecting capabilities for {server_name}: {e}",
                exc_info=True
            )
            capabilities.detection_method = "fallback_after_error"
            capabilities.version = MCPVersion.V1_0

        # Cache and log
        self._server_capabilities[server_name] = capabilities
        self._log_detection_result(server_name, capabilities)

        return capabilities

    def detect_from_transport(
        self,
        server_name: str,
        transport_type: str
    ) -> ServerCapabilities:
        """
        Detect capabilities from transport type.

        Args:
            server_name: Name/identifier of the server
            transport_type: Transport type string

        Returns:
            ServerCapabilities with inferred features
        """
        capabilities = ServerCapabilities(
            detection_method="transport_inference"
        )

        # Infer from transport type
        if transport_type in ("streamable_http", "http"):
            capabilities.version = MCPVersion.V1_1
            capabilities.features.add(MCPFeature.STREAMABLE_HTTP)
        elif transport_type == "sse":
            capabilities.version = MCPVersion.V1_1
            capabilities.features.add(MCPFeature.STREAMABLE_HTTP)
        elif transport_type == "stdio":
            # stdio could be either version
            capabilities.version = MCPVersion.UNKNOWN

        self._server_capabilities[server_name] = capabilities
        self._log_detection_result(server_name, capabilities)

        return capabilities

    def get_capabilities(self, server_name: str) -> Optional[ServerCapabilities]:
        """
        Get cached capabilities for a server.

        Args:
            server_name: Server name/identifier

        Returns:
            ServerCapabilities or None if not detected
        """
        return self._server_capabilities.get(server_name)

    def should_use_v11_features(self, server_name: str) -> bool:
        """
        Check if v1.1 features should be used for a server.

        Args:
            server_name: Server name/identifier

        Returns:
            True if v1.1 features should be used
        """
        caps = self._server_capabilities.get(server_name)
        if caps is None:
            return False
        return caps.is_v11_compatible()

    def _parse_version(self, version_string: str) -> MCPVersion:
        """Parse version string to MCPVersion enum."""
        if not version_string:
            return MCPVersion.UNKNOWN

        version_string = str(version_string).strip()

        if version_string.startswith("1.1") or version_string == "2024-11-05":
            return MCPVersion.V1_1
        elif version_string.startswith("1.0") or version_string == "2024-10-07":
            return MCPVersion.V1_0
        else:
            # Try to parse as semver
            try:
                parts = version_string.split(".")
                major = int(parts[0])
                minor = int(parts[1]) if len(parts) > 1 else 0

                if major >= 1 and minor >= 1:
                    return MCPVersion.V1_1
                elif major >= 1:
                    return MCPVersion.V1_0
            except (ValueError, IndexError):
                pass

        return MCPVersion.UNKNOWN

    def _extract_raw_capabilities(self, capabilities: Any) -> Dict[str, Any]:
        """Extract raw capabilities to dictionary."""
        if capabilities is None:
            return {}

        if isinstance(capabilities, dict):
            return capabilities

        # Handle object-like capabilities
        result = {}
        for attr in dir(capabilities):
            if not attr.startswith('_'):
                try:
                    value = getattr(capabilities, attr)
                    if not callable(value):
                        result[attr] = value
                except Exception:
                    pass

        return result

    def _detect_features(self, capabilities: Any) -> Set[MCPFeature]:
        """Detect features from capabilities object."""
        features: Set[MCPFeature] = set()

        if capabilities is None:
            return features

        raw = self._extract_raw_capabilities(capabilities)

        # Check for specific capability indicators
        if raw.get('logging'):
            features.add(MCPFeature.LOGGING)
        if raw.get('prompts'):
            features.add(MCPFeature.CAPABILITIES_NEGOTIATION)
        if raw.get('resources'):
            features.add(MCPFeature.CAPABILITIES_NEGOTIATION)
        if raw.get('tools'):
            features.add(MCPFeature.CAPABILITIES_NEGOTIATION)
        if raw.get('roots'):
            features.add(MCPFeature.ROOTS)
        if raw.get('sampling'):
            features.add(MCPFeature.SAMPLING)
        if raw.get('experimental'):
            # Experimental features often indicate v1.1
            features.add(MCPFeature.ENHANCED_ERRORS)

        return features

    def _infer_version_from_features(self, features: Set[MCPFeature]) -> MCPVersion:
        """Infer version from detected features."""
        # If we have v1.1-specific features, assume v1.1
        v11_indicators = {
            MCPFeature.STREAMABLE_HTTP,
            MCPFeature.PROGRESS_REPORTING,
            MCPFeature.CAPABILITIES_NEGOTIATION,
            MCPFeature.LOGGING,
            MCPFeature.ROOTS,
            MCPFeature.SAMPLING,
        }

        if features & v11_indicators:
            return MCPVersion.V1_1

        return MCPVersion.V1_0

    def _log_detection_result(
        self,
        server_name: str,
        capabilities: ServerCapabilities
    ) -> None:
        """Log detection result for debugging (per FR-020a)."""
        logger.info(
            f"MCP protocol version detected for '{server_name}'",
            extra={
                "server_name": server_name,
                "version": capabilities.version.value,
                "protocol_version": capabilities.protocol_version,
                "features": [f.value for f in capabilities.features],
                "detection_method": capabilities.detection_method,
            }
        )


# Singleton instance
_feature_detector: Optional[MCPFeatureDetector] = None


def get_feature_detector() -> MCPFeatureDetector:
    """Get or create the feature detector singleton."""
    global _feature_detector
    if _feature_detector is None:
        _feature_detector = MCPFeatureDetector()
    return _feature_detector


def detect_server_version(
    server_name: str,
    initialize_result: Any = None,
    transport_type: str = None
) -> ServerCapabilities:
    """
    Convenience function to detect server version.

    Args:
        server_name: Server name/identifier
        initialize_result: Optional initialize result
        transport_type: Optional transport type

    Returns:
        ServerCapabilities
    """
    detector = get_feature_detector()

    if initialize_result:
        return detector.detect_from_initialize_result(server_name, initialize_result)
    elif transport_type:
        return detector.detect_from_transport(server_name, transport_type)
    else:
        # Return unknown capabilities
        return ServerCapabilities(
            detection_method="no_input"
        )
```

### Step 2: Update MCP Module Init

Update `/opt/hx-lang-server/app/mcp/__init__.py` to export protocol utilities:

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
from .protocol import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    get_feature_detector,
    detect_server_version,
    V1_0_FEATURES,
    V1_1_FEATURES,
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
    # Protocol
    "MCPVersion",
    "MCPFeature",
    "ServerCapabilities",
    "MCPFeatureDetector",
    "get_feature_detector",
    "detect_server_version",
    "V1_0_FEATURES",
    "V1_1_FEATURES",
]
```

### Step 3: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    detect_server_version,
)

# Test version detection from transport
detector = MCPFeatureDetector()
caps = detector.detect_from_transport('fastmcp', 'streamable_http')
print(f'Transport detection: version={caps.version.value}')
assert caps.version == MCPVersion.V1_1, 'Should detect v1.1 for streamable_http'
assert caps.supports_streamable_http(), 'Should support streamable_http'

# Test ServerCapabilities
caps = ServerCapabilities(version=MCPVersion.V1_1)
caps.features.add(MCPFeature.PROGRESS_REPORTING)
print(f'Manual caps: v1.1_compatible={caps.is_v11_compatible()}')
assert caps.is_v11_compatible() == True
assert caps.has_feature(MCPFeature.PROGRESS_REPORTING) == True

# Test to_dict
caps_dict = caps.to_dict()
print(f'Caps dict: {caps_dict}')
assert 'version' in caps_dict
assert 'features' in caps_dict

print('All protocol detection tests passed')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Protocol module | `/opt/hx-lang-server/app/mcp/protocol.py` | Version detection |
| Updated module init | `/opt/hx-lang-server/app/mcp/__init__.py` | Protocol exports |

---

## Verification Steps

- [ ] `protocol.py` module created
- [ ] MCPVersion enum has V1_0, V1_1, UNKNOWN values
- [ ] MCPFeature enum has all v1.1 features
- [ ] ServerCapabilities tracks detected features
- [ ] MCPFeatureDetector detects version from transport type
- [ ] MCPFeatureDetector detects version from initialize result
- [ ] Logging includes protocol version negotiation details

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    get_feature_detector,
    V1_0_FEATURES,
    V1_1_FEATURES,
)

tests_passed = 0

# Test 1: Version enum
assert MCPVersion.V1_0.value == '1.0'
assert MCPVersion.V1_1.value == '1.1'
tests_passed += 1

# Test 2: Feature enum
assert MCPFeature.STREAMABLE_HTTP.value == 'streamable_http'
assert MCPFeature.PROGRESS_REPORTING.value == 'progress_reporting'
tests_passed += 1

# Test 3: V1.1 features defined
assert MCPFeature.STREAMABLE_HTTP in V1_1_FEATURES
assert MCPFeature.PROGRESS_REPORTING in V1_1_FEATURES
tests_passed += 1

# Test 4: ServerCapabilities methods
caps = ServerCapabilities(version=MCPVersion.V1_1)
caps.features.add(MCPFeature.STREAMABLE_HTTP)
assert caps.is_v11_compatible() == True
assert caps.supports_streamable_http() == True
tests_passed += 1

# Test 5: Feature detector singleton
detector1 = get_feature_detector()
detector2 = get_feature_detector()
assert detector1 is detector2, 'Should be singleton'
tests_passed += 1

# Test 6: Transport-based detection
detector = MCPFeatureDetector()
caps = detector.detect_from_transport('test', 'streamable_http')
assert caps.version == MCPVersion.V1_1
tests_passed += 1

# Test 7: should_use_v11_features
detector = MCPFeatureDetector()
detector.detect_from_transport('v11_server', 'streamable_http')
assert detector.should_use_v11_features('v11_server') == True
assert detector.should_use_v11_features('unknown_server') == False
tests_passed += 1

print(f'All {tests_passed} protocol detection tests passed!')
"
```

---

## Acceptance Criteria

1. **AC-094-1**: MCPVersion enum defines V1_0, V1_1, UNKNOWN
2. **AC-094-2**: MCPFeature enum defines all v1.1 features
3. **AC-094-3**: ServerCapabilities.has_feature() checks for specific features
4. **AC-094-4**: ServerCapabilities.is_v11_compatible() returns correct boolean
5. **AC-094-5**: MCPFeatureDetector detects version from transport type
6. **AC-094-6**: MCPFeatureDetector detects version from initialize result
7. **AC-094-7**: Protocol version negotiation is logged for debugging (per FR-020a)

---

## Rollback Procedure

```bash
sudo rm /opt/hx-lang-server/app/mcp/protocol.py

# Restore previous __init__.py (from task-093 state)
```

---

## Notes

- Implements CAIO decision FR-020a for MCP v1.1 feature detection
- Version detection uses multiple methods: transport type, initialize result, feature inference
- Logging includes protocol version negotiation per FR-020a requirement
- Singleton pattern for MCPFeatureDetector ensures consistent state
- ServerCapabilities is cached per server for performance
- Graceful fallback to v1.0 implemented in task-095

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
