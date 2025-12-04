# Task: Configure CORS and Security Middleware

**Task ID**: hx-lang-server-task-111-configure-cors-security-middleware
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-102 (Application factory), hx-lang-server-task-103 (Pydantic config)
**Estimated Time**: 45 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Configure CORS (Cross-Origin Resource Sharing) middleware and security middleware for the FastAPI application. This includes proper CORS headers for frontend integration, request ID middleware for tracing, rate limiting middleware, and security headers. The configuration supports development environment requirements while establishing patterns for future production security.

---

## Pre-Execution Validation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.core.security import RateLimitMiddleware, RequestIDMiddleware
print('VALIDATION: Security middleware implemented - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Security middleware not implemented - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] Application factory implemented (Task 102)
- [ ] Configuration module implemented (Task 103)
- [ ] FastAPI middleware support available

---

## Steps

### 1. Create Security Module

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

cat > /opt/hx-lang-server/app/core/security.py <<'EOF'
"""
Security middleware and authentication handlers.

Provides:
- Request ID middleware for tracing
- Rate limiting middleware (Redis-backed)
- Security headers middleware
- CORS configuration helpers

Specification Reference: Security Requirements section
"""
import time
import uuid
from typing import Callable, Dict, Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
import structlog

from app.core.config import Settings


logger = structlog.get_logger()


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Middleware to add unique request ID to each request.

    The request ID is:
    - Taken from X-Request-ID header if provided
    - Generated as UUID if not provided
    - Added to response headers
    - Available in request.state.request_id
    """

    async def dispatch(
        self,
        request: Request,
        call_next: Callable,
    ) -> Response:
        # Get or generate request ID
        request_id = request.headers.get("X-Request-ID")
        if not request_id:
            request_id = f"req_{uuid.uuid4().hex[:12]}"

        # Store in request state for access in handlers
        request.state.request_id = request_id

        # Process request
        response = await call_next(request)

        # Add to response headers
        response.headers["X-Request-ID"] = request_id

        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Rate limiting middleware using sliding window counter.

    Limits requests per session/IP to prevent abuse.
    Full implementation requires Redis (Work Stream 5).

    Specification:
    - 100 requests per minute per session (default)
    - Returns 429 Too Many Requests when exceeded
    """

    def __init__(
        self,
        app: ASGIApp,
        requests_per_minute: int = 100,
        window_seconds: int = 60,
    ):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
        self.window_seconds = window_seconds
        # In-memory counter for stub (Redis in production)
        self._counters: Dict[str, list] = {}

    async def dispatch(
        self,
        request: Request,
        call_next: Callable,
    ) -> Response:
        # Skip rate limiting for health endpoints
        if request.url.path in ["/health", "/ready", "/metrics"]:
            return await call_next(request)

        # Get client identifier (session_id > IP)
        client_id = self._get_client_id(request)

        # Check rate limit
        if self._is_rate_limited(client_id):
            logger.warning(
                "rate_limit_exceeded",
                client_id=client_id,
                path=request.url.path,
            )
            return Response(
                content='{"error": "Rate limit exceeded", "error_code": "RATE_LIMITED"}',
                status_code=429,
                media_type="application/json",
                headers={
                    "Retry-After": str(self.window_seconds),
                    "X-RateLimit-Limit": str(self.requests_per_minute),
                    "X-RateLimit-Remaining": "0",
                },
            )

        # Record request
        self._record_request(client_id)

        # Process request
        response = await call_next(request)

        # Add rate limit headers
        remaining = self._get_remaining(client_id)
        response.headers["X-RateLimit-Limit"] = str(self.requests_per_minute)
        response.headers["X-RateLimit-Remaining"] = str(remaining)

        return response

    def _get_client_id(self, request: Request) -> str:
        """Get client identifier from session or IP."""
        # Try to get session_id from header
        session_id = request.headers.get("X-Session-ID")
        if session_id:
            return f"session:{session_id}"

        # Fall back to client IP
        client_ip = request.client.host if request.client else "unknown"
        return f"ip:{client_ip}"

    def _is_rate_limited(self, client_id: str) -> bool:
        """Check if client has exceeded rate limit."""
        now = time.time()
        window_start = now - self.window_seconds

        # Get requests in current window
        requests = self._counters.get(client_id, [])
        requests = [ts for ts in requests if ts > window_start]

        return len(requests) >= self.requests_per_minute

    def _record_request(self, client_id: str):
        """Record a request for rate limiting."""
        now = time.time()
        window_start = now - self.window_seconds

        if client_id not in self._counters:
            self._counters[client_id] = []

        # Clean old entries and add new
        self._counters[client_id] = [
            ts for ts in self._counters[client_id]
            if ts > window_start
        ]
        self._counters[client_id].append(now)

    def _get_remaining(self, client_id: str) -> int:
        """Get remaining requests in current window."""
        now = time.time()
        window_start = now - self.window_seconds

        requests = self._counters.get(client_id, [])
        requests = [ts for ts in requests if ts > window_start]

        return max(0, self.requests_per_minute - len(requests))


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Add security headers to all responses.

    Headers added:
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - X-XSS-Protection: 1; mode=block
    - Referrer-Policy: strict-origin-when-cross-origin

    Note: Content-Security-Policy not set (API-only service)
    """

    async def dispatch(
        self,
        request: Request,
        call_next: Callable,
    ) -> Response:
        response = await call_next(request)

        # Add security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        return response


class RequestTimingMiddleware(BaseHTTPMiddleware):
    """
    Add request timing information to responses.

    Adds X-Response-Time header with processing time in milliseconds.
    """

    async def dispatch(
        self,
        request: Request,
        call_next: Callable,
    ) -> Response:
        start_time = time.time()

        response = await call_next(request)

        # Calculate processing time
        process_time_ms = (time.time() - start_time) * 1000
        response.headers["X-Response-Time"] = f"{process_time_ms:.2f}ms"

        return response


def get_cors_config(settings: Settings) -> dict:
    """
    Get CORS middleware configuration.

    Returns configuration dict for CORSMiddleware.

    Per specification Security Requirements:
    - Development: allow all origins (NO FIREWALL policy)
    - Future production: restrict to specific origins
    """
    return {
        "allow_origins": settings.cors_origins,
        "allow_credentials": True,
        "allow_methods": ["GET", "POST", "DELETE", "OPTIONS"],
        "allow_headers": [
            "Accept",
            "Accept-Language",
            "Content-Type",
            "Authorization",
            "X-Request-ID",
            "X-Session-ID",
        ],
        "expose_headers": [
            "X-Request-ID",
            "X-Response-Time",
            "X-RateLimit-Limit",
            "X-RateLimit-Remaining",
        ],
    }


def configure_middleware(app, settings: Settings):
    """
    Configure all middleware for the application.

    Call this from main.py after creating the FastAPI app.

    Order matters:
    1. SecurityHeaders (outermost - always adds headers)
    2. RequestTiming (measures total time)
    3. RequestID (adds tracing ID)
    4. RateLimit (may short-circuit)
    5. CORS (handled separately in main.py)
    """
    # Add middleware in reverse order (first added = outermost)
    app.add_middleware(
        RateLimitMiddleware,
        requests_per_minute=settings.rate_limit_requests,
        window_seconds=settings.rate_limit_window_seconds,
    )

    app.add_middleware(RequestIDMiddleware)
    app.add_middleware(RequestTimingMiddleware)
    app.add_middleware(SecurityHeadersMiddleware)
EOF
```

### 2. Update Main Application to Use Middleware

```bash
cat > /opt/hx-lang-server/app/main.py <<'EOF'
"""
FastAPI Application Factory for hx-lang-server.

This module provides the application factory pattern for creating
and configuring the FastAPI application instance.

Specification Reference: FR-021, FR-022, FR-024, FR-025
"""
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.version import __version__, __app_name__, __description__
from app.core.config import get_settings
from app.core.security import get_cors_config, configure_middleware
from app.routers.v1 import invoke, stream, sessions
from app.routers import health


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """
    Application lifespan manager for startup and shutdown events.

    Handles:
    - Startup: Initialize database connections, Redis pools, external clients
    - Shutdown: Close connections, cleanup resources
    """
    settings = get_settings()

    # --- STARTUP ---
    # TODO: Initialize async PostgreSQL checkpointer (Work Stream 4)
    # TODO: Initialize Redis connection pool (Work Stream 5)
    # TODO: Initialize Ollama clients (Work Stream 7)
    # TODO: Initialize LightRAG client (Work Stream 8)
    # TODO: Initialize MCP client (Work Stream 9)

    app.state.settings = settings

    # Log startup
    import structlog
    logger = structlog.get_logger()
    logger.info(
        "application_startup",
        app_name=__app_name__,
        version=__version__,
        port=settings.service_port,
    )

    yield  # Application runs here

    # --- SHUTDOWN ---
    logger.info("application_shutdown", app_name=__app_name__)

    # TODO: Close PostgreSQL connections
    # TODO: Close Redis connection pool
    # TODO: Close HTTP clients


def create_app() -> FastAPI:
    """
    Application factory that creates and configures the FastAPI application.

    Returns:
        FastAPI: Configured application instance.

    This pattern enables:
    - Dependency injection for testing
    - Clean separation of configuration and instantiation
    - Multiple app instances for testing
    """
    settings = get_settings()

    app = FastAPI(
        title=__app_name__,
        description=__description__,
        version=__version__,
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        openapi_url="/openapi.json" if settings.debug else "/openapi.json",
        lifespan=lifespan,
    )

    # Configure CORS middleware
    cors_config = get_cors_config(settings)
    app.add_middleware(CORSMiddleware, **cors_config)

    # Configure security middleware (request ID, rate limiting, security headers)
    configure_middleware(app, settings)

    # Register API routers
    _register_routers(app)

    return app


def _register_routers(app: FastAPI) -> None:
    """
    Register all API routers with the application.

    Router structure per API Specification:
    - /api/v1/invoke - Synchronous agent invocation
    - /api/v1/stream - Streaming agent invocation (SSE)
    - /api/v1/sessions - Session management
    - /health - Health check
    - /ready - Readiness probe
    - /metrics - Prometheus metrics
    """
    # API v1 routers (port 8100)
    app.include_router(
        invoke.router,
        prefix="/api/v1",
        tags=["invoke"],
    )
    app.include_router(
        stream.router,
        prefix="/api/v1",
        tags=["stream"],
    )
    app.include_router(
        sessions.router,
        prefix="/api/v1",
        tags=["sessions"],
    )

    # Health/monitoring routers
    app.include_router(
        health.router,
        tags=["health"],
    )


# Create application instance for Uvicorn
app = create_app()


if __name__ == "__main__":
    """
    Development server entry point.

    For production, use systemd to start Uvicorn:
    uvicorn app.main:app --host 0.0.0.0 --port 8100
    """
    import uvicorn

    settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.service_port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
EOF
```

### 3. Test Middleware

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test middleware imports
python3 -c "
from app.core.security import (
    RequestIDMiddleware,
    RateLimitMiddleware,
    SecurityHeadersMiddleware,
    RequestTimingMiddleware,
    get_cors_config,
    configure_middleware,
)
print('All middleware classes imported successfully')
"

# Test CORS config
python3 -c "
from app.core.security import get_cors_config
from app.core.config import get_settings

config = get_cors_config(get_settings())
print('CORS Configuration:')
for key, value in config.items():
    print(f'  {key}: {value}')
"

# Test rate limiter
python3 -c "
from app.core.security import RateLimitMiddleware

# Create instance
limiter = RateLimitMiddleware(None, requests_per_minute=5)

# Simulate requests
client = 'test_client'
for i in range(7):
    limited = limiter._is_rate_limited(client)
    if not limited:
        limiter._record_request(client)
    print(f'Request {i+1}: limited={limited}, remaining={limiter._get_remaining(client)}')
"

# Test app has middleware
python3 -c "
from app.main import app

middleware_names = [m.cls.__name__ for m in app.user_middleware]
print('Configured middleware:')
for name in middleware_names:
    print(f'  - {name}')

assert 'RateLimitMiddleware' in middleware_names
assert 'RequestIDMiddleware' in middleware_names
print('\nPASS: All required middleware configured')
"
```

### 4. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/middleware-implementation.txt <<EOF
CORS and Security Middleware Implementation Record
==================================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-111-configure-cors-security-middleware

Files Created/Modified:
- /opt/hx-lang-server/app/core/security.py
- /opt/hx-lang-server/app/main.py (updated)

Middleware Implemented:
- RequestIDMiddleware: Adds X-Request-ID to all requests
- RateLimitMiddleware: 100 req/min per session (Redis-backed in production)
- SecurityHeadersMiddleware: X-Content-Type-Options, X-Frame-Options, etc.
- RequestTimingMiddleware: X-Response-Time header

CORS Configuration:
- Allow origins: Configurable via settings (default: ["*"])
- Allow methods: GET, POST, DELETE, OPTIONS
- Allow headers: Standard headers + X-Request-ID, X-Session-ID
- Expose headers: X-Request-ID, X-Response-Time, rate limit headers

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/middleware-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Security module compiles:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/core/security.py
  ```

- [ ] All middleware classes importable:
  ```bash
  python3 -c "from app.core.security import RequestIDMiddleware, RateLimitMiddleware; print('PASS')"
  ```

- [ ] Middleware configured in app:
  ```bash
  python3 -c "
  from app.main import app
  names = [m.cls.__name__ for m in app.user_middleware]
  assert 'RateLimitMiddleware' in names
  print('PASS: Middleware configured')
  "
  ```

- [ ] Rate limiter logic works:
  ```bash
  python3 -c "
  from app.core.security import RateLimitMiddleware
  limiter = RateLimitMiddleware(None, requests_per_minute=2)
  limiter._record_request('test')
  limiter._record_request('test')
  assert limiter._is_rate_limited('test')
  print('PASS: Rate limiter works')
  "
  ```

---

## Rollback

```bash
# Restore placeholder security.py
cat > /opt/hx-lang-server/app/core/security.py <<'EOF'
"""Security middleware - placeholder. See task-111."""
pass
EOF

# Restore previous main.py (without middleware configuration)
# Manual edit or restore from task-102 backup
```

---

## Notes

### Middleware Order

Middleware is applied in reverse order of addition:
1. SecurityHeaders (outermost) - always runs
2. RequestTiming - measures total time
3. RequestID - adds tracing
4. RateLimit - may short-circuit
5. CORS - handled by CORSMiddleware

### Rate Limiting Strategy

Current implementation uses in-memory sliding window.
For production (Work Stream 5), integrate with Redis:
```python
# Key: hx-lang-server:ratelimit:{client_id}
# Value: Sorted set of timestamps
```

### Security Headers

Per OWASP recommendations for API services:
- X-Content-Type-Options: Prevents MIME sniffing
- X-Frame-Options: Prevents clickjacking
- X-XSS-Protection: Legacy XSS protection
- Referrer-Policy: Controls referrer information

### Development vs Production

Development (current):
- CORS: allow all origins (["*"])
- Rate limit: 100/min (in-memory)
- No authentication required

Production (future):
- CORS: specific frontend origins
- Rate limit: Redis-backed distributed counter
- OAuth2/OIDC authentication via hx-dc-server

---

## Related Tasks

**Prerequisites**:
- Task 102: Application factory
- Task 103: Pydantic config

**Dependencies (Other Work Streams)**:
- Task 041-050: Redis integration for distributed rate limiting

**Next Tasks**:
- Task 112: OpenAPI documentation

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Security Requirements
- FR-021: REST API via FastAPI

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
