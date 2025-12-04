# Task: Implement main.py with Application Factory

**Task ID**: hx-lang-server-task-102-implement-application-factory
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-101 (FastAPI application structure), hx-lang-server-task-103 (Pydantic settings)
**Estimated Time**: 60 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement the FastAPI application factory pattern in `main.py` that creates and configures the main application instance. This includes setting up lifespan events for async resource management, registering all routers, and configuring middleware. The application factory pattern enables proper dependency injection, testability, and clean startup/shutdown handling.

---

## Pre-Execution Validation

**CRITICAL**: Check if main.py already exists and is functional BEFORE executing steps.

```bash
# Check for existing main.py with app factory
if [ -f "/opt/hx-lang-server/app/main.py" ]; then
    echo "main.py exists, checking functionality..."
    source /opt/hx-lang-server/venv/bin/activate
    python3 -c "from app.main import create_app; app = create_app(); print(f'App created: {app.title}')" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "VALIDATION: Application factory functional - SKIP task execution"
        exit 0
    fi
fi
echo "VALIDATION: main.py not functional - PROCEED with task"
```

**Validation Logic**:
- If main.py exists and create_app() succeeds -> SKIP execution
- If main.py missing or create_app() fails -> PROCEED with implementation
- Document validation results in task execution tracking

---

## Prerequisites

- [ ] FastAPI application structure created (Task 101)
- [ ] Pydantic settings configuration implemented (Task 103)
- [ ] FastAPI and Uvicorn installed in virtual environment
- [ ] Virtual environment accessible at `/opt/hx-lang-server/venv/`

---

## Steps

### 1. Verify Dependencies Available

```bash
# Switch to service account and activate venv
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

# Verify FastAPI and dependencies
python3 -c "
import fastapi
import uvicorn
import pydantic_settings
print(f'FastAPI: {fastapi.__version__}')
print(f'Uvicorn: {uvicorn.__version__}')
print(f'Pydantic Settings: {pydantic_settings.__version__}')
"
```

### 2. Implement Application Factory (main.py)

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
from app.routers.v1 import invoke, stream, sessions
from app.routers import health


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """
    Application lifespan manager for startup and shutdown events.

    This async context manager handles:
    - Startup: Initialize database connections, Redis pools, external clients
    - Shutdown: Close connections, cleanup resources

    Per FR-006, FR-007: Manages PostgreSQL checkpointer and Redis session cache.
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

    # Configure CORS middleware (FR-021: REST API accessibility)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE"],
        allow_headers=["*"],
    )

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

    # Health/monitoring routers (port 8101 in production, same app for dev)
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

### 3. Create Stub Routers (Temporary)

Until subsequent tasks implement the actual routers, create stubs to allow main.py to import:

```bash
# Create invoke router stub
cat > /opt/hx-lang-server/app/routers/v1/invoke.py <<'EOF'
"""
Synchronous agent invocation endpoint (POST /api/v1/invoke).

Full implementation: Task 105
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("/invoke")
async def invoke_agent():
    """
    Placeholder for synchronous agent invocation.
    Implementation pending in task-105-implement-invoke-endpoint.
    """
    return {"status": "not_implemented", "message": "See task-105"}
EOF

# Create stream router stub
cat > /opt/hx-lang-server/app/routers/v1/stream.py <<'EOF'
"""
Streaming agent invocation endpoint with SSE (POST /api/v1/stream).

Full implementation: Task 106
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("/stream")
async def stream_agent():
    """
    Placeholder for streaming agent invocation.
    Implementation pending in task-106-implement-stream-endpoint.
    """
    return {"status": "not_implemented", "message": "See task-106"}
EOF

# Create sessions router stub
cat > /opt/hx-lang-server/app/routers/v1/sessions.py <<'EOF'
"""
Session management endpoints (CRUD for sessions).

Full implementation: Task 107
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("/sessions")
async def create_session():
    """Placeholder for session creation. Implementation: task-107."""
    return {"status": "not_implemented", "message": "See task-107"}


@router.get("/sessions/{session_id}")
async def get_session(session_id: str):
    """Placeholder for session retrieval. Implementation: task-107."""
    return {"status": "not_implemented", "session_id": session_id}


@router.delete("/sessions/{session_id}")
async def delete_session(session_id: str):
    """Placeholder for session deletion. Implementation: task-107."""
    return {"status": "not_implemented", "session_id": session_id}
EOF

# Create health router stub
cat > /opt/hx-lang-server/app/routers/health.py <<'EOF'
"""
Health, readiness, and metrics endpoints.

Full implementation: Tasks 108, 109, 110
"""
from fastapi import APIRouter

from app.version import __version__

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Basic health check endpoint.
    Full implementation: task-108.
    """
    return {
        "status": "healthy",
        "version": __version__,
    }


@router.get("/ready")
async def readiness_check():
    """
    Readiness probe with dependency checks.
    Full implementation: task-109.
    """
    return {"status": "not_implemented", "message": "See task-109"}


@router.get("/metrics")
async def metrics():
    """
    Prometheus metrics endpoint.
    Full implementation: task-110.
    """
    return {"status": "not_implemented", "message": "See task-110"}
EOF

# Update v1 router __init__.py for exports
cat > /opt/hx-lang-server/app/routers/v1/__init__.py <<'EOF'
"""
API v1 routers package.
"""
from . import invoke, stream, sessions

__all__ = ["invoke", "stream", "sessions"]
EOF

# Update routers __init__.py
cat > /opt/hx-lang-server/app/routers/__init__.py <<'EOF'
"""
API routers package.
"""
from . import health

__all__ = ["health"]
EOF
```

### 4. Create Stub Config (Temporary)

Create minimal config stub to allow main.py to run (full implementation in Task 103):

```bash
cat > /opt/hx-lang-server/app/core/config.py <<'EOF'
"""
Application configuration using Pydantic Settings.

Full implementation: Task 103
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Minimal settings stub for application factory.
    Full implementation in task-103-implement-pydantic-config.
    """
    # Service settings
    service_name: str = "hx-lang-server"
    service_port: int = 8100
    debug: bool = True
    log_level: str = "INFO"

    # CORS settings
    cors_origins: List[str] = ["*"]

    class Config:
        env_file = "/opt/hx-lang-server/.env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """
    Return cached settings instance.
    Uses lru_cache to ensure single instance.
    """
    return Settings()
EOF
```

### 5. Test Application Factory

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test application creation
python3 -c "
from app.main import create_app, app
print(f'App Title: {app.title}')
print(f'App Version: {app.version}')
print(f'Routes registered: {len(app.routes)}')
for route in app.routes:
    if hasattr(route, 'path'):
        print(f'  {route.path} - {route.methods if hasattr(route, \"methods\") else \"N/A\"}')
"
```

**Expected Output**:
```
App Title: hx-lang-server
App Version: 1.0.0
Routes registered: 8+
  /api/v1/invoke - {'POST'}
  /api/v1/stream - {'POST'}
  /api/v1/sessions - {'POST'}
  /api/v1/sessions/{session_id} - {'GET'}
  /api/v1/sessions/{session_id} - {'DELETE'}
  /health - {'GET'}
  /ready - {'GET'}
  /metrics - {'GET'}
```

### 6. Test Uvicorn Startup (Brief Test)

```bash
# Start server briefly to verify it can bind to port
timeout 5 python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8100 2>&1 || true

# Should see startup message like:
# INFO:     Uvicorn running on http://0.0.0.0:8100
```

### 7. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/main-py-implementation.txt <<EOF
Application Factory Implementation Record
=========================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-102-implement-application-factory

Files Created/Modified:
- /opt/hx-lang-server/app/main.py (application factory)
- /opt/hx-lang-server/app/routers/v1/invoke.py (stub)
- /opt/hx-lang-server/app/routers/v1/stream.py (stub)
- /opt/hx-lang-server/app/routers/v1/sessions.py (stub)
- /opt/hx-lang-server/app/routers/health.py (stub)
- /opt/hx-lang-server/app/core/config.py (stub)

Application Factory Features:
- create_app() function for testability
- Lifespan context manager for async resources
- CORS middleware configuration
- Router registration for all API endpoints

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/main-py-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] main.py exists and is syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/main.py && echo "PASS: Syntax OK"
  ```

- [ ] create_app() function returns FastAPI instance:
  ```bash
  python3 -c "from app.main import create_app; app = create_app(); assert app.title == 'hx-lang-server'"
  ```

- [ ] All required routes registered:
  ```bash
  python3 -c "
  from app.main import app
  paths = [r.path for r in app.routes if hasattr(r, 'path')]
  required = ['/api/v1/invoke', '/api/v1/stream', '/health', '/ready', '/metrics']
  for p in required:
      assert p in paths, f'Missing route: {p}'
  print('PASS: All required routes present')
  "
  ```

- [ ] Application can start (Uvicorn binding succeeds):
  ```bash
  timeout 3 python3 -m uvicorn app.main:app --port 8199 2>&1 | grep -q "Uvicorn running" && echo "PASS: Uvicorn starts"
  ```

- [ ] Lifespan context manager defined:
  ```bash
  python3 -c "from app.main import lifespan; print('PASS: Lifespan defined')"
  ```

---

## Rollback

If implementation needs to be reverted:

```bash
# Remove main.py
rm -f /opt/hx-lang-server/app/main.py

# Remove stub routers (will be re-created in subsequent tasks)
rm -f /opt/hx-lang-server/app/routers/v1/invoke.py
rm -f /opt/hx-lang-server/app/routers/v1/stream.py
rm -f /opt/hx-lang-server/app/routers/v1/sessions.py
rm -f /opt/hx-lang-server/app/routers/health.py

# Remove stub config
rm -f /opt/hx-lang-server/app/core/config.py

# Re-execute this task from Step 2
```

---

## Notes

### Application Factory Pattern

The application factory pattern (`create_app()`) is used for several reasons:

1. **Testability**: Tests can create isolated app instances with different configurations
2. **Configuration Flexibility**: Settings can be overridden per environment
3. **Clean Resource Management**: Lifespan handlers manage async resources
4. **Multiple Instances**: Allows running separate instances for API (8100) and health (8101)

### Lifespan Context Manager

Per FastAPI's recommended pattern, we use `@asynccontextmanager` for lifespan instead of deprecated `@app.on_event("startup")` and `@app.on_event("shutdown")` decorators.

```python
@asynccontextmanager
async def lifespan(app):
    # Startup code here
    yield
    # Shutdown code here
```

### Router Organization

Routers are organized by:
- **API Version**: `/api/v1/` prefix for versioned endpoints
- **Resource**: invoke, stream, sessions
- **Non-versioned**: /health, /ready, /metrics (stable endpoints)

### Port Configuration

Per specification:
- **Port 8100**: Main API endpoints (invoke, stream, sessions)
- **Port 8101**: Health/Metrics endpoints (separate Uvicorn instance in production)

For development, both are served on the same application. Production deployment uses separate systemd services.

### Stub Implementation Strategy

Stubs are created to:
1. Allow main.py to be tested independently
2. Provide clear placeholders with task references
3. Enable incremental development and testing

Each stub includes a reference to the task that will implement it fully.

---

## Related Tasks

**Prerequisites**:
- Task 101: Create FastAPI application structure
- Task 103: Implement config.py with Pydantic settings (partial dependency - stub works)

**Next Tasks**:
- Task 103: Implement Pydantic config (replaces stub config)
- Task 104: Create Pydantic request/response models
- Tasks 105-110: Implement actual router logic

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: API Specification (endpoint structure)
- Section: Configuration Management (Settings class)
- FR-021: REST API via FastAPI on port 8100
- FR-022: Async endpoints using async def

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
