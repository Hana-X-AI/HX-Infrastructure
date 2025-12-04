# Task: Create FastAPI Application Structure

**Task ID**: hx-lang-server-task-101-create-fastapi-application-structure
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-021 (Python virtual environment), hx-lang-server-task-022 (Python dependencies)
**Estimated Time**: 45 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Create the FastAPI application directory structure under `/opt/hx-lang-server/app/` following FastAPI best practices. This establishes the modular architecture that supports the LangGraph orchestration service with clear separation between API layer, business logic, and integrations.

---

## Pre-Execution Validation

**CRITICAL**: Check if application structure already exists BEFORE executing steps.

```bash
# Check for existing app directory structure
if [ -d "/opt/hx-lang-server/app" ] && [ -f "/opt/hx-lang-server/app/__init__.py" ]; then
    echo "Application directory structure exists"
    ls -la /opt/hx-lang-server/app/

    # Verify minimum required structure
    required_dirs=("routers" "models" "services" "core")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "/opt/hx-lang-server/app/$dir" ]; then
            echo "VALIDATION: Missing directory $dir - PROCEED with task"
            exit 1
        fi
    done
    echo "VALIDATION: Structure complete - SKIP task execution"
    exit 0
else
    echo "VALIDATION: App structure not found - PROCEED with task"
fi
```

**Validation Logic**:
- If all directories and __init__.py files exist -> SKIP execution, mark task as validated/complete
- If any structure missing -> PROCEED with creation steps
- Document validation results in task execution tracking

---

## Prerequisites

- [ ] Python 3.11+ virtual environment created at `/opt/hx-lang-server/venv/` (Task 021)
- [ ] Python dependencies installed including FastAPI, Pydantic (Task 022)
- [ ] Service account `hx-lang-server` has write permissions to `/opt/hx-lang-server/`
- [ ] Base directory `/opt/hx-lang-server/` exists with proper ownership

---

## Steps

### 1. Create Base Application Directory

```bash
# Switch to service account
sudo -u hx-lang-server bash

# Create main application directory
mkdir -p /opt/hx-lang-server/app

# Verify ownership
ls -la /opt/hx-lang-server/app
# Expected: owned by hx-lang-server:hx-lang-server
```

### 2. Create Module Directory Structure

The application follows a modular architecture aligned with the specification:

```bash
# Create directory structure
mkdir -p /opt/hx-lang-server/app/routers      # API route handlers
mkdir -p /opt/hx-lang-server/app/models       # Pydantic models (request/response)
mkdir -p /opt/hx-lang-server/app/schemas      # Database/state schemas
mkdir -p /opt/hx-lang-server/app/services     # Business logic services
mkdir -p /opt/hx-lang-server/app/core         # Configuration, dependencies, security
mkdir -p /opt/hx-lang-server/app/agents       # LangGraph agent implementations
mkdir -p /opt/hx-lang-server/app/integrations # External service clients (Ollama, LightRAG, MCP)
mkdir -p /opt/hx-lang-server/app/utils        # Utility functions

# Verify structure
find /opt/hx-lang-server/app -type d
```

**Expected Directory Tree**:
```
/opt/hx-lang-server/app/
    routers/          # API endpoints by domain
    models/           # Pydantic request/response models
    schemas/          # Database and state schemas
    services/         # Business logic layer
    core/             # Configuration, dependencies
    agents/           # LangGraph supervisor and workers
    integrations/     # External service clients
    utils/            # Helper utilities
```

### 3. Create Python Package Files (__init__.py)

```bash
# Create __init__.py files to make directories Python packages
touch /opt/hx-lang-server/app/__init__.py
touch /opt/hx-lang-server/app/routers/__init__.py
touch /opt/hx-lang-server/app/models/__init__.py
touch /opt/hx-lang-server/app/schemas/__init__.py
touch /opt/hx-lang-server/app/services/__init__.py
touch /opt/hx-lang-server/app/core/__init__.py
touch /opt/hx-lang-server/app/agents/__init__.py
touch /opt/hx-lang-server/app/integrations/__init__.py
touch /opt/hx-lang-server/app/utils/__init__.py

# Verify all __init__.py files created
find /opt/hx-lang-server/app -name "__init__.py"
```

### 4. Create Application Version File

```bash
# Create version file for application metadata
cat > /opt/hx-lang-server/app/version.py <<'EOF'
"""
Application version information.
"""

__version__ = "1.0.0"
__app_name__ = "hx-lang-server"
__description__ = "LangGraph Orchestration Server for HX-Infrastructure"
EOF
```

### 5. Create Core Module Placeholder Files

```bash
# Create placeholder files for core modules (to be implemented in subsequent tasks)

# Config module placeholder
cat > /opt/hx-lang-server/app/core/config.py <<'EOF'
"""
Application configuration using Pydantic Settings.
Implementation: Task 103
"""
# TODO: Implement in task-103-implement-pydantic-config
pass
EOF

# Dependencies module placeholder
cat > /opt/hx-lang-server/app/core/dependencies.py <<'EOF'
"""
FastAPI dependency injection providers.
Implementation: Tasks 104-109
"""
# TODO: Implement in subsequent tasks
pass
EOF

# Security module placeholder
cat > /opt/hx-lang-server/app/core/security.py <<'EOF'
"""
Security middleware and authentication handlers.
Implementation: Task 111
"""
# TODO: Implement in task-111-configure-cors-security-middleware
pass
EOF
```

### 6. Create Router Module Placeholder Files

```bash
# API v1 routers directory
mkdir -p /opt/hx-lang-server/app/routers/v1
touch /opt/hx-lang-server/app/routers/v1/__init__.py

# Invoke endpoint placeholder
cat > /opt/hx-lang-server/app/routers/v1/invoke.py <<'EOF'
"""
Synchronous agent invocation endpoint (POST /api/v1/invoke).
Implementation: Task 105
"""
# TODO: Implement in task-105-implement-invoke-endpoint
pass
EOF

# Stream endpoint placeholder
cat > /opt/hx-lang-server/app/routers/v1/stream.py <<'EOF'
"""
Streaming agent invocation endpoint with SSE (POST /api/v1/stream).
Implementation: Task 106
"""
# TODO: Implement in task-106-implement-stream-endpoint
pass
EOF

# Sessions endpoint placeholder
cat > /opt/hx-lang-server/app/routers/v1/sessions.py <<'EOF'
"""
Session management endpoints (CRUD for sessions).
Implementation: Task 107
"""
# TODO: Implement in task-107-implement-session-management-endpoints
pass
EOF

# Health endpoints placeholder
cat > /opt/hx-lang-server/app/routers/health.py <<'EOF'
"""
Health and readiness endpoints for port 8101.
Implementation: Tasks 108-110
"""
# TODO: Implement in tasks 108, 109, 110
pass
EOF
```

### 7. Create Models Module Placeholder Files

```bash
# Request models placeholder
cat > /opt/hx-lang-server/app/models/requests.py <<'EOF'
"""
Pydantic models for API request validation.
Implementation: Task 104
"""
# TODO: Implement in task-104-create-pydantic-request-response-models
pass
EOF

# Response models placeholder
cat > /opt/hx-lang-server/app/models/responses.py <<'EOF'
"""
Pydantic models for API response serialization.
Implementation: Task 104
"""
# TODO: Implement in task-104-create-pydantic-request-response-models
pass
EOF

# Error models placeholder
cat > /opt/hx-lang-server/app/models/errors.py <<'EOF'
"""
Pydantic models for error responses.
Implementation: Task 104
"""
# TODO: Implement in task-104-create-pydantic-request-response-models
pass
EOF
```

### 8. Set File Permissions

```bash
# Set appropriate permissions
chmod 755 /opt/hx-lang-server/app
find /opt/hx-lang-server/app -type d -exec chmod 755 {} \;
find /opt/hx-lang-server/app -type f -name "*.py" -exec chmod 644 {} \;

# Verify ownership (should be hx-lang-server:hx-lang-server)
ls -laR /opt/hx-lang-server/app/
```

### 9. Document Structure Creation

```bash
# Create structure record
cat > /opt/hx-lang-server/installation-records/app-structure-creation.txt <<EOF
FastAPI Application Structure Creation Record
=============================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-101-create-fastapi-application-structure
User: hx-lang-server

Directory Structure Created:
$(find /opt/hx-lang-server/app -type d | sort)

Python Package Files:
$(find /opt/hx-lang-server/app -name "__init__.py" | sort)

Total Files Created:
$(find /opt/hx-lang-server/app -type f | wc -l)

Structure Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/app-structure-creation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Application root directory exists:
  ```bash
  test -d /opt/hx-lang-server/app && echo "PASS: App directory exists"
  ```

- [ ] All module directories exist:
  ```bash
  for dir in routers models schemas services core agents integrations utils; do
      test -d /opt/hx-lang-server/app/$dir && echo "PASS: $dir directory exists"
  done
  ```

- [ ] All __init__.py files created (makes directories Python packages):
  ```bash
  count=$(find /opt/hx-lang-server/app -name "__init__.py" | wc -l)
  [ "$count" -ge 9 ] && echo "PASS: __init__.py files created ($count found)"
  ```

- [ ] version.py exists and is importable:
  ```bash
  source /opt/hx-lang-server/venv/bin/activate
  cd /opt/hx-lang-server
  python3 -c "from app.version import __version__; print(f'Version: {__version__}')"
  ```

- [ ] Directory ownership is correct:
  ```bash
  owner=$(stat -c '%U:%G' /opt/hx-lang-server/app)
  [ "$owner" = "hx-lang-server:hx-lang-server" ] && echo "PASS: Ownership correct"
  ```

---

## Rollback

If application structure creation fails or needs to be redone:

```bash
# Remove app directory completely
sudo rm -rf /opt/hx-lang-server/app/

# Remove installation record
sudo rm -f /opt/hx-lang-server/installation-records/app-structure-creation.txt

# Re-execute this task from Step 1
```

---

## Notes

### Directory Purpose Mapping

| Directory | Purpose | Specification Reference |
|-----------|---------|------------------------|
| `routers/` | API endpoint handlers (FastAPI routers) | FR-021, FR-022 |
| `routers/v1/` | Versioned API endpoints | API Endpoints section |
| `models/` | Pydantic request/response models | Request/Response Models section |
| `schemas/` | Database and state schemas | State Schema Design section |
| `services/` | Business logic layer | Separation of concerns |
| `core/` | Configuration, dependencies, security | Configuration Management section |
| `agents/` | LangGraph supervisor and workers | Core Agent Orchestration section |
| `integrations/` | External service clients | Dependencies section |
| `utils/` | Utility functions | General utilities |

### Architecture Alignment

This structure supports the specification's architecture:

```
FastAPI Application (this task)
        |
        +-- routers/v1/invoke.py     -> POST /api/v1/invoke
        +-- routers/v1/stream.py     -> POST /api/v1/stream
        +-- routers/v1/sessions.py   -> Session management
        +-- routers/health.py        -> /health, /ready, /metrics
        |
        +-- core/config.py           -> Pydantic Settings
        +-- core/dependencies.py     -> FastAPI dependencies
        |
        +-- services/                -> Business logic
        +-- agents/                  -> LangGraph (Work Stream 6)
        +-- integrations/            -> Ollama, LightRAG, MCP clients
```

### File Naming Conventions

- Router files: Named by resource (invoke.py, sessions.py, health.py)
- Model files: requests.py, responses.py, errors.py
- Core files: config.py, dependencies.py, security.py
- All files use snake_case per Python PEP 8

### Next Steps

This task creates the skeleton. Subsequent tasks populate the files:

- Task 102: main.py (application factory)
- Task 103: config.py (Pydantic settings)
- Task 104: Pydantic models
- Tasks 105-110: Router implementations

---

## Related Tasks

**Prerequisites**:
- Task 021: Create Python virtual environment
- Task 022: Install Python dependencies

**Next Tasks**:
- Task 102: Implement main.py with application factory
- Task 103: Implement config.py with Pydantic settings
- Task 104: Create Pydantic request/response models

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: API Specification (endpoints structure)
- Section: Configuration Management (Pydantic Settings)
- Section: SOLID Principles Application (Single Responsibility)

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
