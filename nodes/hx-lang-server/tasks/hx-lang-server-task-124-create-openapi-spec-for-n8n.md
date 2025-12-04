# Task: Create OpenAPI Specification for n8n Integration

**Task ID**: hx-lang-server-task-124-create-openapi-spec-for-n8n
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-121 (n8n HTTP endpoint), hx-lang-server-task-122 (Status polling)
**Estimated Time**: 45 minutes

---

## Objective

Enhance FastAPI's auto-generated OpenAPI specification with comprehensive metadata, examples, and n8n-specific annotations to enable automated n8n node generation and provide clear API documentation for workflow developers.

---

## Prerequisites

- [ ] FastAPI application with `/invoke` and `/status` endpoints operational
- [ ] Pydantic models defined for all request/response schemas
- [ ] OpenAPI documentation accessible at `/docs`
- [ ] Understanding of OpenAPI 3.0.x specification format

---

## Specification Reference

**From node-spec.md v2.1, Section: API Requirements**

Lines 98-103:
```
#### API Requirements
- FR-021: Service MUST expose REST API via FastAPI on port 8100
- FR-022: Service MUST implement async endpoints using `async def` with `ainvoke()`
- FR-023: Service MUST support webhook callbacks for n8n integration
- FR-024: Service MUST provide health check endpoint at `/health`
- FR-025: Service MUST provide OpenAPI documentation at `/docs`
```

---

## Implementation Steps

### Step 1: Configure FastAPI OpenAPI Metadata

Update `/opt/hx-lang-server/app/main.py`:

```python
"""
FastAPI application for hx-lang-server with comprehensive OpenAPI metadata.
"""

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi
from contextlib import asynccontextmanager
import structlog

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    logger.info("hx_lang_server_startup", version="1.0.0")
    yield
    logger.info("hx_lang_server_shutdown")


# FastAPI application with enhanced metadata
app = FastAPI(
    title="HX-Lang-Server API",
    description="""
# LangGraph Orchestration API for n8n Integration

The HX-Lang-Server provides intelligent multi-agent orchestration using LangGraph
with support for n8n workflow automation, conversational AI, and RAG-enhanced responses.

## Features

- **Multi-Agent Orchestration:** Supervisor pattern with specialized worker agents
- **Conversation Continuity:** Thread-based conversation management with PostgreSQL persistence
- **n8n Integration:** Native support for webhook callbacks and async operations
- **Adaptive RAG:** LightRAG integration for context-aware retrieval
- **Multi-LLM Routing:** Automatic routing to specialized Ollama models

## Agent Workers

- **RAG Agent:** Retrieval-augmented generation using LightRAG
- **Code Agent:** Code generation and debugging with specialized LLM
- **Tool Agent:** MCP tool invocation via FastMCP gateway
- **General Agent:** General-purpose queries and conversation

## Quick Start

### Synchronous Query
```bash
curl -X POST "http://hx-lang-server.hx.dev.local:8100/invoke" \\
  -H "Content-Type: application/json" \\
  -d '{"query": "What is LangGraph?"}'
```

### Multi-Turn Conversation
```bash
# First query
THREAD_ID=$(curl -s -X POST "http://hx-lang-server.hx.dev.local:8100/invoke" \\
  -H "Content-Type: application/json" \\
  -d '{"query": "My name is Alice"}' | jq -r '.thread_id')

# Follow-up query
curl -X POST "http://hx-lang-server.hx.dev.local:8100/invoke" \\
  -H "Content-Type: application/json" \\
  -d "{\"query\": \"What is my name?\", \"thread_id\": \"$THREAD_ID\"}"
```

## n8n Integration

### HTTP Request Node
Use n8n's built-in HTTP Request node:

- **URL:** `http://hx-lang-server.hx.dev.local:8100/invoke`
- **Method:** POST
- **Body:** `{"query": "{{ $json.user_input }}", "thread_id": "{{ $json.thread_id }}"}`

### Webhook Callbacks
For async operations, provide `callback_url`:

```json
{
  "query": "Long running task",
  "callback_url": "{{ $node.Webhook.webhookUrl }}"
}
```

Result will be POSTed to the webhook URL when processing completes.

### Status Polling
Alternative to webhooks:

1. POST `/invoke` with async mode (returns `thread_id`)
2. Poll GET `/status/{thread_id}` until `status === "completed"`
3. Extract result from response

## Architecture

```
┌─────────────┐
│  n8n        │
│  Workflow   │
└──────┬──────┘
       │ HTTP Request
       ▼
┌─────────────────────────────┐
│  HX-Lang-Server             │
│  ┌─────────────────────┐    │
│  │ Supervisor Agent    │    │
│  └────┬────────────────┘    │
│       │                     │
│  ┌────▼────┐  ┌────────┐   │
│  │RAG Agent│  │Code    │   │
│  │         │  │Agent   │   │
│  └────┬────┘  └───┬────┘   │
└───────┼───────────┼─────────┘
        │           │
        ▼           ▼
   LightRAG    Ollama-2
                (Code LLM)
```

## Support

- **Documentation:** http://hx-lang-server.hx.dev.local:8100/docs
- **Health Check:** http://hx-lang-server.hx.dev.local:8100/health
- **Node Specification:** `/nodes/hx-lang-server/specification/node-spec.md`
""",
    version="1.0.0",
    contact={
        "name": "HX-Infrastructure Team",
        "url": "https://github.com/Hana-X-AI/HX-Infrastructure",
        "email": "support@hx.dev.local",
    },
    license_info={
        "name": "Internal Use Only",
        "url": "https://hx.dev.local/license",
    },
    servers=[
        {
            "url": "http://hx-lang-server.hx.dev.local:8100",
            "description": "HX Development Environment",
        }
    ],
    openapi_tags=[
        {
            "name": "Agent",
            "description": "LangGraph agent invocation endpoints",
        },
        {
            "name": "n8n",
            "description": "n8n workflow integration endpoints",
        },
        {
            "name": "Status",
            "description": "Async operation status polling",
        },
        {
            "name": "Threads",
            "description": "Conversation thread management",
        },
        {
            "name": "Health",
            "description": "Service health and readiness checks",
        },
    ],
    lifespan=lifespan,
)


def custom_openapi():
    """
    Customize OpenAPI schema with n8n-specific enhancements.
    """
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        servers=app.servers,
        tags=app.openapi_tags,
    )

    # Add n8n-specific extensions
    openapi_schema["x-n8n"] = {
        "name": "HX-Lang-Server",
        "icon": "🤖",
        "supportLevel": "community",
        "credentials": {
            "name": "hxLangServerApi",
            "required": False,  # No auth in dev environment
        },
    }

    # Enhance operation examples
    for path_data in openapi_schema["paths"].values():
        for operation in path_data.values():
            if isinstance(operation, dict) and "requestBody" in operation:
                # Add rich examples to operations
                if "examples" not in operation["requestBody"]["content"]["application/json"]:
                    operation["requestBody"]["content"]["application/json"]["examples"] = {}

    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi
```

### Step 2: Add Rich Examples to Pydantic Models

Update `/opt/hx-lang-server/app/api/models/n8n.py`:

```python
from pydantic import BaseModel, Field

class N8nInvokeRequest(BaseModel):
    """Request model with rich OpenAPI examples."""

    query: str = Field(
        ...,
        description="User query to process with LangGraph agents",
        examples=[
            "What is LangGraph?",
            "Write a Python function to sort a list",
            "Search our knowledge base for deployment procedures",
        ],
    )

    thread_id: Optional[str] = Field(
        None,
        description="Thread ID for conversation continuation",
        examples=["550e8400-e29b-41d4-a716-446655440000"],
    )

    callback_url: Optional[HttpUrl] = Field(
        None,
        description="n8n webhook URL for async result delivery",
        examples=["http://hx-n8n-server.hx.dev.local:5678/webhook/callback"],
    )

    class Config:
        json_schema_extra = {
            "examples": [
                {
                    "query": "What is LangGraph?",
                    "description": "Simple synchronous query",
                },
                {
                    "query": "Continue our previous conversation",
                    "thread_id": "550e8400-e29b-41d4-a716-446655440000",
                    "description": "Multi-turn conversation with thread_id",
                },
                {
                    "query": "Complex long-running task",
                    "callback_url": "http://hx-n8n-server.hx.dev.local:5678/webhook/callback",
                    "workflow_id": "workflow-123",
                    "execution_id": "exec-456",
                    "description": "Async mode with webhook callback",
                },
            ]
        }
```

### Step 3: Create OpenAPI Export Endpoint

Add to `/opt/hx-lang-server/app/api/routes/openapi.py`:

```python
"""
OpenAPI specification export endpoints.
"""

from fastapi import APIRouter, Response
from fastapi.responses import JSONResponse
import yaml
import json

router = APIRouter()


@router.get(
    "/openapi.json",
    include_in_schema=False,
    summary="Download OpenAPI JSON",
)
async def get_openapi_json():
    """Export OpenAPI specification as JSON."""
    from app.main import app
    return JSONResponse(content=app.openapi())


@router.get(
    "/openapi.yaml",
    include_in_schema=False,
    summary="Download OpenAPI YAML",
)
async def get_openapi_yaml():
    """Export OpenAPI specification as YAML."""
    from app.main import app
    openapi_json = app.openapi()
    openapi_yaml = yaml.dump(openapi_json, default_flow_style=False)
    return Response(content=openapi_yaml, media_type="application/x-yaml")
```

Register in `main.py`:

```python
from app.api.routes import openapi

app.include_router(openapi.router)
```

### Step 4: Generate Static OpenAPI Documentation

Create script: `/opt/hx-lang-server/scripts/export_openapi.py`

```python
#!/usr/bin/env python3
"""
Export OpenAPI specification to static files.

Usage:
    python scripts/export_openapi.py

Outputs:
    docs/openapi.json
    docs/openapi.yaml
"""

import json
import yaml
from pathlib import Path

# Add parent directory to path for imports
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.main import app


def main():
    """Export OpenAPI spec to JSON and YAML."""
    docs_dir = Path(__file__).parent.parent / "docs"
    docs_dir.mkdir(exist_ok=True)

    # Get OpenAPI schema
    openapi_schema = app.openapi()

    # Export JSON
    json_path = docs_dir / "openapi.json"
    with open(json_path, "w") as f:
        json.dump(openapi_schema, f, indent=2)
    print(f"✓ Exported: {json_path}")

    # Export YAML
    yaml_path = docs_dir / "openapi.yaml"
    with open(yaml_path, "w") as f:
        yaml.dump(openapi_schema, f, default_flow_style=False, sort_keys=False)
    print(f"✓ Exported: {yaml_path}")

    print("\nOpenAPI specification exported successfully!")
    print(f"  JSON: {json_path}")
    print(f"  YAML: {yaml_path}")


if __name__ == "__main__":
    main()
```

Make executable:

```bash
chmod +x /opt/hx-lang-server/scripts/export_openapi.py
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Enhanced main.py | `/opt/hx-lang-server/app/main.py` | Rich OpenAPI metadata |
| OpenAPI routes | `/opt/hx-lang-server/app/api/routes/openapi.py` | JSON/YAML export endpoints |
| Export script | `/opt/hx-lang-server/scripts/export_openapi.py` | Static spec generation |
| OpenAPI JSON | `/opt/hx-lang-server/docs/openapi.json` | Static JSON specification |
| OpenAPI YAML | `/opt/hx-lang-server/docs/openapi.yaml` | Static YAML specification |

---

## Verification Steps

### Step 1: Verify Interactive Documentation

```bash
# Open browser to Swagger UI
open http://hx-lang-server.hx.dev.local:8100/docs

# Verify:
# - Rich description with examples visible
# - All endpoints documented
# - Request/response schemas detailed
# - Try it out button functional
```

### Step 2: Test OpenAPI Export Endpoints

```bash
# Download JSON specification
curl -s http://hx-lang-server.hx.dev.local:8100/openapi.json | jq '.'

# Download YAML specification
curl -s http://hx-lang-server.hx.dev.local:8100/openapi.yaml | head -20

# Verify both contain:
# - Complete endpoint definitions
# - Request/response schemas
# - Examples and descriptions
```

### Step 3: Generate Static Files

```bash
# Run export script
cd /opt/hx-lang-server
/opt/hx-lang-server/venv/bin/python scripts/export_openapi.py

# Verify files created
ls -lh docs/openapi.*

# Validate JSON syntax
jq empty docs/openapi.json && echo "✓ Valid JSON"

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('docs/openapi.yaml'))" && echo "✓ Valid YAML"
```

### Step 4: Validate n8n Compatibility

```bash
# Check n8n can parse OpenAPI spec
# (Requires n8n-cli or manual import test in n8n UI)

# In n8n:
# 1. Create new credential: "OpenAPI"
# 2. Import spec: http://hx-lang-server.hx.dev.local:8100/openapi.json
# 3. Verify endpoints appear in HTTP Request node dropdown
```

---

## Acceptance Criteria

- [ ] FastAPI OpenAPI metadata includes comprehensive description
- [ ] All endpoints have detailed descriptions and examples
- [ ] Request/response models include field-level examples
- [ ] n8n-specific extensions added to OpenAPI schema
- [ ] `/openapi.json` endpoint returns valid JSON spec
- [ ] `/openapi.yaml` endpoint returns valid YAML spec
- [ ] Static export script generates docs/openapi.{json,yaml}
- [ ] OpenAPI version is 3.0.x (not 3.1.x for n8n compatibility)
- [ ] Examples demonstrate sync, async, and multi-turn patterns
- [ ] Interactive docs at `/docs` render correctly

---

## Rollback Procedure

If issues occur:

```bash
cd /opt/hx-lang-server
git checkout app/main.py
git checkout app/api/routes/openapi.py
rm -f docs/openapi.{json,yaml}
sudo systemctl restart hx-lang-server
```

---

## Notes

- **OpenAPI Version:** FastAPI generates 3.0.x by default, which is compatible with n8n
- **Examples:** Rich examples in Pydantic models appear in OpenAPI spec automatically
- **Static Export:** Useful for version control and offline documentation
- **n8n Import:** n8n can generate HTTP Request node configurations from OpenAPI specs
- **Validation:** Use tools like Swagger Editor to validate exported specs

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, API Requirements (FR-025)
