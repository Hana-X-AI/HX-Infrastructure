# Task: Implement Graceful Fallback to MCP v1.0

**Task ID**: hx-lang-server-task-095-implement-v10-fallback-mechanism
**Phase**: Implementation
**Assigned To**: George Kim (FastMCP Gateway SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-094 (MCP v1.1 feature detection)
**Work Stream**: 9 - MCP Client Integration
**Estimated Time**: 35 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "MCP Client Integration" (FR-020a)

---

## Objective

Implement graceful fallback to MCP v1.0 when connecting to servers that do not support v1.1 features. This ensures hx-lang-server can communicate with any MCP server regardless of protocol version.

**CAIO Decision (FR-020a)**: Graceful fallback to v1.0 for incompatible servers

---

## Prerequisites

- [ ] MCP v1.1 feature detection implemented (task-094)
- [ ] Protocol module exists with MCPFeatureDetector
- [ ] MCP client module configured

---

## Implementation Steps

### Step 1: Create Fallback Handler Module

Create file `/opt/hx-lang-server/app/mcp/fallback.py`:

```python
"""
MCP v1.0 Fallback Mechanism.

Implements graceful fallback to v1.0 when v1.1 features are unavailable.
Per CAIO decision FR-020a: Graceful fallback to v1.0 for incompatible servers.

Fallback Scenarios:
1. Server does not support v1.1 protocol
2. Transport does not support v1.1 features
3. Feature-specific fallback for partial support
4. Connection errors requiring simpler protocol
"""

import logging
from typing import Dict, Any, Optional, Callable, TypeVar, Awaitable
from dataclasses import dataclass
from enum import Enum
import functools

from .protocol import (
    MCPVersion,
    MCPFeature,
    ServerCapabilities,
    MCPFeatureDetector,
    get_feature_detector,
)

logger = logging.getLogger(__name__)

T = TypeVar('T')


class FallbackReason(Enum):
    """Reasons for falling back to v1.0."""
    SERVER_INCOMPATIBLE = "server_does_not_support_v1.1"
    TRANSPORT_LIMITATION = "transport_does_not_support_feature"
    FEATURE_NOT_AVAILABLE = "specific_feature_not_available"
    CONNECTION_ERROR = "connection_error_fallback"
    EXPLICIT_REQUEST = "explicit_v1.0_requested"
    UNKNOWN = "unknown_reason"


@dataclass
class FallbackContext:
    """Context information about a fallback decision."""
    used_fallback: bool
    reason: Optional[FallbackReason]
    original_feature: Optional[MCPFeature]
    fallback_feature: Optional[str]
    server_name: Optional[str]
    message: str

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for logging."""
        return {
            "used_fallback": self.used_fallback,
            "reason": self.reason.value if self.reason else None,
            "original_feature": self.original_feature.value if self.original_feature else None,
            "fallback_feature": self.fallback_feature,
            "server_name": self.server_name,
            "message": self.message,
        }


class MCPFallbackHandler:
    """
    Handles graceful fallback from v1.1 to v1.0 features.

    Provides:
    - Automatic feature degradation
    - Fallback logging for debugging
    - Feature-specific fallback strategies
    """

    # Feature fallback mappings
    FEATURE_FALLBACKS: Dict[MCPFeature, Dict[str, Any]] = {
        MCPFeature.STREAMABLE_HTTP: {
            "fallback": "sse",
            "description": "Use SSE transport instead of streamable HTTP",
        },
        MCPFeature.PROGRESS_REPORTING: {
            "fallback": "polling",
            "description": "Use polling instead of progress notifications",
        },
        MCPFeature.ENHANCED_ERRORS: {
            "fallback": "basic_errors",
            "description": "Use basic error messages",
        },
        MCPFeature.NOTIFICATIONS: {
            "fallback": "none",
            "description": "Notifications not available",
        },
        MCPFeature.LOGGING: {
            "fallback": "local_logging",
            "description": "Use local logging only",
        },
    }

    def __init__(self):
        self._detector = get_feature_detector()
        self._fallback_history: Dict[str, list] = {}

    def should_fallback(
        self,
        server_name: str,
        feature: MCPFeature
    ) -> tuple[bool, Optional[str]]:
        """
        Check if fallback is needed for a feature.

        Args:
            server_name: Server to check
            feature: Feature to check

        Returns:
            Tuple of (should_fallback, fallback_option)
        """
        caps = self._detector.get_capabilities(server_name)

        if caps is None:
            # No capabilities detected, assume fallback needed
            fallback = self.FEATURE_FALLBACKS.get(feature, {}).get("fallback")
            return True, fallback

        if not caps.has_feature(feature):
            # Feature not available, use fallback
            fallback = self.FEATURE_FALLBACKS.get(feature, {}).get("fallback")
            return True, fallback

        return False, None

    def get_fallback_for_feature(self, feature: MCPFeature) -> Optional[Dict[str, Any]]:
        """
        Get fallback configuration for a feature.

        Args:
            feature: Feature to get fallback for

        Returns:
            Fallback configuration dict or None
        """
        return self.FEATURE_FALLBACKS.get(feature)

    def apply_transport_fallback(
        self,
        server_name: str,
        preferred_transport: str
    ) -> str:
        """
        Apply transport fallback if needed.

        Args:
            server_name: Server name
            preferred_transport: Preferred transport type

        Returns:
            Actual transport to use (may be fallback)
        """
        caps = self._detector.get_capabilities(server_name)

        # Check if streamable_http is supported
        if preferred_transport == "streamable_http":
            if caps is None or not caps.supports_streamable_http():
                logger.info(
                    f"Falling back from streamable_http to sse for {server_name}",
                    extra={
                        "server_name": server_name,
                        "preferred": "streamable_http",
                        "fallback": "sse",
                    }
                )
                self._record_fallback(server_name, "transport", "streamable_http", "sse")
                return "sse"

        return preferred_transport

    def apply_feature_fallback(
        self,
        server_name: str,
        feature: MCPFeature,
        v11_impl: Callable[..., T],
        v10_impl: Callable[..., T],
        *args,
        **kwargs
    ) -> T:
        """
        Apply feature fallback, choosing v1.1 or v1.0 implementation.

        Args:
            server_name: Server name
            feature: Feature being used
            v11_impl: v1.1 implementation function
            v10_impl: v1.0 fallback implementation function
            *args: Arguments to pass to implementation
            **kwargs: Keyword arguments to pass to implementation

        Returns:
            Result from chosen implementation
        """
        should_fb, fb_option = self.should_fallback(server_name, feature)

        if should_fb:
            logger.info(
                f"Using v1.0 fallback for {feature.value} on {server_name}",
                extra={
                    "server_name": server_name,
                    "feature": feature.value,
                    "fallback_option": fb_option,
                }
            )
            self._record_fallback(server_name, feature.value, "v1.1", "v1.0")
            return v10_impl(*args, **kwargs)
        else:
            return v11_impl(*args, **kwargs)

    async def apply_feature_fallback_async(
        self,
        server_name: str,
        feature: MCPFeature,
        v11_impl: Callable[..., Awaitable[T]],
        v10_impl: Callable[..., Awaitable[T]],
        *args,
        **kwargs
    ) -> T:
        """
        Apply feature fallback for async implementations.

        Args:
            server_name: Server name
            feature: Feature being used
            v11_impl: v1.1 async implementation
            v10_impl: v1.0 fallback async implementation
            *args: Arguments to pass to implementation
            **kwargs: Keyword arguments to pass to implementation

        Returns:
            Result from chosen implementation
        """
        should_fb, fb_option = self.should_fallback(server_name, feature)

        if should_fb:
            logger.info(
                f"Using v1.0 fallback for {feature.value} on {server_name}",
                extra={
                    "server_name": server_name,
                    "feature": feature.value,
                    "fallback_option": fb_option,
                }
            )
            self._record_fallback(server_name, feature.value, "v1.1", "v1.0")
            return await v10_impl(*args, **kwargs)
        else:
            return await v11_impl(*args, **kwargs)

    def create_fallback_context(
        self,
        server_name: str,
        feature: Optional[MCPFeature] = None
    ) -> FallbackContext:
        """
        Create a context object describing fallback status.

        Args:
            server_name: Server name
            feature: Optional specific feature to check

        Returns:
            FallbackContext with fallback information
        """
        caps = self._detector.get_capabilities(server_name)

        if caps is None:
            return FallbackContext(
                used_fallback=True,
                reason=FallbackReason.UNKNOWN,
                original_feature=feature,
                fallback_feature=None,
                server_name=server_name,
                message=f"No capabilities detected for {server_name}, using v1.0 fallback"
            )

        if not caps.is_v11_compatible():
            return FallbackContext(
                used_fallback=True,
                reason=FallbackReason.SERVER_INCOMPATIBLE,
                original_feature=feature,
                fallback_feature="v1.0",
                server_name=server_name,
                message=f"Server {server_name} does not support v1.1, using v1.0"
            )

        if feature and not caps.has_feature(feature):
            fb = self.FEATURE_FALLBACKS.get(feature, {})
            return FallbackContext(
                used_fallback=True,
                reason=FallbackReason.FEATURE_NOT_AVAILABLE,
                original_feature=feature,
                fallback_feature=fb.get("fallback"),
                server_name=server_name,
                message=f"Feature {feature.value} not available on {server_name}"
            )

        return FallbackContext(
            used_fallback=False,
            reason=None,
            original_feature=feature,
            fallback_feature=None,
            server_name=server_name,
            message=f"Using v1.1 features for {server_name}"
        )

    def get_fallback_history(self, server_name: str) -> list:
        """
        Get history of fallbacks for a server.

        Args:
            server_name: Server name

        Returns:
            List of fallback events
        """
        return self._fallback_history.get(server_name, [])

    def _record_fallback(
        self,
        server_name: str,
        feature: str,
        original: str,
        fallback: str
    ) -> None:
        """Record a fallback event for debugging."""
        if server_name not in self._fallback_history:
            self._fallback_history[server_name] = []

        import time
        self._fallback_history[server_name].append({
            "timestamp": time.time(),
            "feature": feature,
            "original": original,
            "fallback": fallback,
        })


# Singleton instance
_fallback_handler: Optional[MCPFallbackHandler] = None


def get_fallback_handler() -> MCPFallbackHandler:
    """Get or create the fallback handler singleton."""
    global _fallback_handler
    if _fallback_handler is None:
        _fallback_handler = MCPFallbackHandler()
    return _fallback_handler


def with_v10_fallback(
    server_name: str,
    feature: MCPFeature
):
    """
    Decorator to add v1.0 fallback to a function.

    Usage:
        @with_v10_fallback("fastmcp", MCPFeature.PROGRESS_REPORTING)
        async def my_function_v11():
            # v1.1 implementation
            pass

        @my_function_v11.fallback
        async def my_function_v10():
            # v1.0 fallback implementation
            pass
    """
    def decorator(v11_impl):
        @functools.wraps(v11_impl)
        async def wrapper(*args, **kwargs):
            handler = get_fallback_handler()
            should_fb, _ = handler.should_fallback(server_name, feature)

            if should_fb and hasattr(wrapper, '_fallback_impl'):
                return await wrapper._fallback_impl(*args, **kwargs)
            return await v11_impl(*args, **kwargs)

        def fallback_decorator(v10_impl):
            wrapper._fallback_impl = v10_impl
            return wrapper

        wrapper.fallback = fallback_decorator
        return wrapper

    return decorator
```

### Step 2: Update MCP Module Init

Update `/opt/hx-lang-server/app/mcp/__init__.py` to export fallback utilities:

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
from .fallback import (
    FallbackReason,
    FallbackContext,
    MCPFallbackHandler,
    get_fallback_handler,
    with_v10_fallback,
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
    # Fallback
    "FallbackReason",
    "FallbackContext",
    "MCPFallbackHandler",
    "get_fallback_handler",
    "with_v10_fallback",
]
```

### Step 3: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    FallbackReason,
    FallbackContext,
    MCPFallbackHandler,
    get_fallback_handler,
    MCPFeature,
)

# Test fallback handler
handler = MCPFallbackHandler()

# Test should_fallback for unknown server
should_fb, fallback = handler.should_fallback('unknown_server', MCPFeature.STREAMABLE_HTTP)
print(f'Unknown server fallback: should_fb={should_fb}, fallback={fallback}')
assert should_fb == True, 'Should fallback for unknown server'

# Test transport fallback
transport = handler.apply_transport_fallback('unknown', 'streamable_http')
print(f'Transport fallback: {transport}')
assert transport == 'sse', 'Should fallback to sse'

# Test FallbackContext
ctx = handler.create_fallback_context('unknown_server', MCPFeature.PROGRESS_REPORTING)
print(f'FallbackContext: used_fallback={ctx.used_fallback}, reason={ctx.reason}')
assert ctx.used_fallback == True

# Test context to_dict
ctx_dict = ctx.to_dict()
print(f'Context dict: {ctx_dict}')
assert 'used_fallback' in ctx_dict

print('All fallback tests passed')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Fallback module | `/opt/hx-lang-server/app/mcp/fallback.py` | Fallback handler |
| Updated module init | `/opt/hx-lang-server/app/mcp/__init__.py` | Fallback exports |

---

## Verification Steps

- [ ] `fallback.py` module created
- [ ] FallbackReason enum defines all reasons
- [ ] FallbackContext provides fallback information
- [ ] MCPFallbackHandler.should_fallback() works for unknown servers
- [ ] MCPFallbackHandler.apply_transport_fallback() degrades transport
- [ ] Fallback history is recorded for debugging
- [ ] with_v10_fallback decorator works for async functions

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.mcp import (
    FallbackReason,
    FallbackContext,
    MCPFallbackHandler,
    get_fallback_handler,
    MCPFeature,
    MCPFeatureDetector,
)

tests_passed = 0

# Test 1: FallbackReason enum
assert FallbackReason.SERVER_INCOMPATIBLE.value == 'server_does_not_support_v1.1'
tests_passed += 1

# Test 2: FallbackContext dataclass
ctx = FallbackContext(
    used_fallback=True,
    reason=FallbackReason.SERVER_INCOMPATIBLE,
    original_feature=MCPFeature.STREAMABLE_HTTP,
    fallback_feature='sse',
    server_name='test',
    message='Test message'
)
assert ctx.to_dict()['used_fallback'] == True
tests_passed += 1

# Test 3: Singleton pattern
h1 = get_fallback_handler()
h2 = get_fallback_handler()
assert h1 is h2, 'Should be singleton'
tests_passed += 1

# Test 4: should_fallback for unknown server
handler = MCPFallbackHandler()
should_fb, fb = handler.should_fallback('unknown', MCPFeature.PROGRESS_REPORTING)
assert should_fb == True
tests_passed += 1

# Test 5: Transport fallback
handler = MCPFallbackHandler()
transport = handler.apply_transport_fallback('unknown', 'streamable_http')
assert transport == 'sse'
tests_passed += 1

# Test 6: Feature fallback exists
fb = handler.get_fallback_for_feature(MCPFeature.STREAMABLE_HTTP)
assert fb is not None
assert fb['fallback'] == 'sse'
tests_passed += 1

# Test 7: Create fallback context
ctx = handler.create_fallback_context('unknown', MCPFeature.LOGGING)
assert ctx.used_fallback == True
assert ctx.reason == FallbackReason.UNKNOWN
tests_passed += 1

# Test 8: Fallback history
history = handler.get_fallback_history('unknown')
# History recorded from transport fallback test
assert isinstance(history, list)
tests_passed += 1

print(f'All {tests_passed} fallback tests passed!')
"
```

---

## Acceptance Criteria

1. **AC-095-1**: FallbackReason enum defines SERVER_INCOMPATIBLE, TRANSPORT_LIMITATION, etc.
2. **AC-095-2**: FallbackContext provides complete fallback information
3. **AC-095-3**: MCPFallbackHandler.should_fallback() returns (bool, fallback_option)
4. **AC-095-4**: MCPFallbackHandler.apply_transport_fallback() degrades streamable_http to sse
5. **AC-095-5**: MCPFallbackHandler.apply_feature_fallback() chooses correct implementation
6. **AC-095-6**: Fallback events are logged for debugging (per FR-020a)
7. **AC-095-7**: Fallback history is recorded per server

---

## Rollback Procedure

```bash
sudo rm /opt/hx-lang-server/app/mcp/fallback.py

# Restore previous __init__.py (from task-094 state)
```

---

## Notes

- Implements CAIO decision FR-020a for graceful v1.0 fallback
- Transport fallback: streamable_http -> sse -> stdio
- Feature fallbacks are documented in FEATURE_FALLBACKS dict
- Fallback history enables debugging of protocol negotiation issues
- with_v10_fallback decorator provides clean syntax for dual implementations
- All fallback decisions are logged per FR-020a requirement

---

**Task Created By**: George Kim (FastMCP Gateway SME)
**Task Created Date**: 2025-12-04
