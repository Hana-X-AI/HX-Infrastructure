# Service Specification: hx-lang-server

**Document Type:** Service Specification
**Specification Version:** 2.1
**Specification Date:** 2025-12-04
**Specification Status:** APPROVED
**Charter Reference:** `/nodes/hx-lang-server/charter/charter.md` (APPROVED 2025-12-01)
**Synthesis Complete:** 12 specialist contributions integrated + 4 CAIO decisions applied
**CAIO Approval:** 2025-12-04

---

## Executive Summary

**Node:** hx-lang-server
**Purpose:** Central LangGraph orchestration hub for intelligent, multi-step AI workflows using local Ollama models
**Status:** APPROVED (Ready for Planning Phase)
**Target Server:** hx-lang-server.hx.dev.local (192.168.10.226)
**Technical Lead:** Sophia (LangGraph Orchestration SME)

**Key Technology Stack:**
- LangGraph v0.2.x (agent orchestration)
- FastAPI (API wrapper)
- PostgreSQL (checkpoint persistence via langgraph-checkpoint-postgres)
- Redis (session caching)
- langchain-ollama (LLM integration)
- langchain-mcp-adapters (MCP client integration)

**Phased Delivery:**
- **Phase 1:** Core LangGraph + RAG (supervisor + 2-3 workers, Ollama routing, LightRAG)
- **Phase 2:** n8n + MCP Integration (workflows, Crawl4AI MCP)

---

## Service Purpose & Requirements

### Primary Purpose

hx-lang-server provides a central agent orchestration platform that:
1. Coordinates multi-agent workflows using LangGraph's supervisor pattern
2. Routes queries to appropriate Ollama models based on query classification
3. Integrates with LightRAG for adaptive retrieval-augmented generation
4. Persists conversation state across service restarts
5. Exposes agent capabilities via FastAPI for n8n and other consumers

### Deployment Scenarios

1. **Given** hx-lang-server.hx.dev.local is provisioned with Python 3.11+, **When** the LangGraph service is deployed, **Then** the supervisor agent accepts queries and routes to appropriate worker agents.

2. **Given** PostgreSQL checkpointing is configured, **When** the service restarts, **Then** all in-progress conversations resume from their last checkpoint.

3. **Given** n8n workflow invokes the LangGraph API, **When** an agent task completes, **Then** n8n receives a callback with results.

### Operational Requirements

- **Service Failure:** Supervisor agent gracefully degrades; in-progress work checkpointed to PostgreSQL; Redis cache cleared on restart
- **Network Interruption:** Retry logic with exponential backoff for Ollama/LightRAG connections; circuit breaker prevents cascade failures
- **Recovery Requirements:** RTO < 5 minutes (service restart), RPO < 1 minute (checkpoint frequency)

---

## Requirements

### Functional Requirements

#### Core Agent Orchestration
- **FR-001**: Service MUST implement LangGraph supervisor pattern with configurable worker agents
- **FR-002**: Service MUST support minimum 3 worker agent types: RAG Agent, Code Agent, Tool Agent
- **FR-003**: Service MUST route queries to appropriate worker based on query classification
- **FR-004**: Service MUST support human-in-the-loop interrupts for agent approval workflows
- **FR-005**: Service MUST implement graph recursion limits (default: 25 iterations)

#### State Management
- **FR-006**: Service MUST persist agent state to PostgreSQL using langgraph-checkpoint-postgres
- **FR-007**: Service MUST cache session data in Redis with configurable TTL
- **FR-008**: Service MUST support conversation continuation across service restarts
- **FR-009**: Service MUST implement state schema versioning for backward compatibility

#### LLM Integration
- **FR-010**: Service MUST route general queries to hx-ollama1-server.hx.dev.local
- **FR-011**: Service MUST route code-related queries to hx-ollama2-server.hx.dev.local
- **FR-012**: Service MUST route embedding requests through LightRAG (NOT direct to ollama3)
- **FR-013**: Service MUST validate Ollama model context size >= 64KB for RAG and Code operations

#### RAG Integration
- **FR-014**: Service MUST integrate with hx-literag-server.hx.dev.local via HTTP API
- **FR-015**: Service MUST support adaptive retrieval with iteration when initial results insufficient
- **FR-016**: Service MUST support LightRAG query modes: local, global, hybrid, mix

#### MCP Integration
- **FR-017**: Service MUST implement MCP CLIENT using langchain-mcp-adapters (NOT MCP server)
- **FR-018**: Service MUST connect to FastMCP gateway at hx-fastmcp-server.hx.dev.local
- **FR-019**: Service MUST support tool discovery and invocation for Crawl4AI MCP
- **FR-020**: Service MUST handle tool namespace prefixes from gateway
- **FR-020a**: Service MUST support MCP protocol v1.1 with feature detection for backward compatibility

#### API Requirements
- **FR-021**: Service MUST expose REST API via FastAPI on port 8100
- **FR-022**: Service MUST implement async endpoints using `async def` with `ainvoke()`
- **FR-023**: Service MUST support webhook callbacks for n8n integration
- **FR-024**: Service MUST provide health check endpoint at `/health`
- **FR-025**: Service MUST provide OpenAPI documentation at `/docs`

#### n8n Integration (Phase 2)
- **FR-026**: Service MUST expose HTTP endpoint for n8n HTTP Request node
- **FR-027**: Service MUST support webhook callback registration for async operations
- **FR-028**: Service MUST provide thread_id for conversation continuity in n8n workflows

### Non-Functional Requirements

- **NFR-001**: API response time < 5 seconds for simple queries (95th percentile)
- **NFR-002**: Checkpoint persistence latency < 100ms
- **NFR-003**: Service startup time < 30 seconds
- **NFR-004**: Memory usage < 12GB under normal load (within 16GB minimum)
- **NFR-005**: Support 10 concurrent agent sessions minimum

---

## Node Requirements

### Target Node
- **Hostname:** hx-lang-server.hx.dev.local
- **IP Address:** 192.168.10.226
- **Operating System:** Ubuntu 24.04 LTS
- **Environment:** Development (no production SLA)

### Resource Requirements
- **CPU:** 4 cores minimum (8 recommended for concurrent agents)
- **Memory:** 16GB RAM minimum (32GB recommended for production workloads)
- **Storage:** 50GB (20GB application, 30GB logs/cache)
- **Network:** 1Gbps connection to HX network

**Note:** Memory increased from 8GB to 16GB per William Chen's infrastructure review. LangGraph with concurrent agent sessions requires additional headroom for state management and LLM response buffering.

### Service Account
- **Account Name:** `hx-lang-server`
- **Domain:** `hx-lang-server@hx.dev.local`
- **Home Directory:** `/opt/hx-lang-server`
- **Shell:** `/bin/bash`

### Port Allocation
| Port | Protocol | Purpose |
|------|----------|---------|
| 8100 | TCP | FastAPI HTTP API |
| 8101 | TCP | Health/Metrics endpoint |

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     hx-lang-server                               │
│                   (192.168.10.226:8100)                         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   FastAPI Wrapper                        │   │
│  │  - Async endpoints (POST /invoke, POST /stream)         │   │
│  │  - Health check (GET /health)                           │   │
│  │  - Webhook registration (POST /webhooks)                │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │                                     │
│  ┌────────────────────────▼────────────────────────────────┐   │
│  │              LangGraph Supervisor Agent                  │   │
│  │  - StateGraph with TypedDict state schema               │   │
│  │  - Conditional routing based on query classification    │   │
│  │  - Checkpoint persistence to PostgreSQL                 │   │
│  │  - Session caching in Redis                             │   │
│  └───┬─────────────────┬─────────────────┬─────────────────┘   │
│      │                 │                 │                      │
│  ┌───▼───┐        ┌───▼───┐        ┌───▼───┐                   │
│  │  RAG  │        │ Code  │        │ Tool  │                   │
│  │ Agent │        │ Agent │        │ Agent │                   │
│  │       │        │       │        │       │                   │
│  │Ollama1│        │Ollama2│        │  MCP  │                   │
│  │LightRAG│       │       │        │Client │                   │
│  └───┬───┘        └───┬───┘        └───┬───┘                   │
│      │                │                │                        │
└──────┼────────────────┼────────────────┼────────────────────────┘
       │                │                │
       ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│hx-ollama1    │ │hx-ollama2    │ │hx-fastmcp    │
│(General LLM) │ │(Code LLM)    │ │(MCP Gateway) │
│.204:11434    │ │.205:11434    │ │.213:8000     │
└──────────────┘ └──────────────┘ └──────┬───────┘
                                         │
       ▼                                 ▼
┌──────────────┐                  ┌──────────────┐
│hx-literag    │                  │hx-crawl4ai   │
│(RAG Pipeline)│                  │(Web Crawling)│
│.219:8020     │                  │.218:11235    │
└──────┬───────┘                  └──────────────┘
       │
       ▼
┌──────────────┐
│hx-qdrant     │
│(Vector DB)   │
│.220:6333     │
└──────────────┘
```

### State Persistence Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    State Persistence Layer                   │
├─────────────────────────────┬───────────────────────────────┤
│      PostgreSQL             │           Redis               │
│   (Durable Checkpoints)     │    (Ephemeral Session)        │
├─────────────────────────────┼───────────────────────────────┤
│ - Conversation history      │ - Active session cache        │
│ - Agent state snapshots     │ - Query classification cache  │
│ - Checkpoint metadata       │ - LLM response cache (5min)   │
│ - Thread branching          │ - Rate limiting counters      │
│                             │                               │
│ Retention: 30 days          │ TTL: 1 hour (sessions)        │
│ Checkpoint freq: per-turn   │ TTL: 5 min (LLM cache)        │
└─────────────────────────────┴───────────────────────────────┘
```

---

## State Schema Design

### Agent State TypedDict

```python
from typing import TypedDict, Annotated, List, Optional
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    """Core state schema for LangGraph supervisor."""

    # Schema version for backward compatibility (per Alex Rivera's review)
    schema_version: str  # "1.0" - increment on breaking changes

    # Message history with reducer for appending
    messages: Annotated[List[BaseMessage], add_messages]

    # Query classification result
    query_type: str  # "general", "code", "rag", "tool"

    # Active worker assignment
    current_worker: Optional[str]

    # RAG context from LightRAG
    rag_context: Optional[str]

    # Tool invocation results
    tool_results: Optional[dict]

    # Iteration counter for recursion limits
    iteration_count: int

    # Session metadata
    session_id: str
    thread_id: str
    user_id: Optional[str]
    created_at: str  # ISO 8601 timestamp
    updated_at: str  # ISO 8601 timestamp
```

### Redis Key Schema

**Namespace Prefix:** All keys MUST use `hx-lang-server:` prefix for namespace isolation (per Alex Rivera's architecture review).

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:session:{session_id}` | Active session data | 1 hour |
| `hx-lang-server:thread:{thread_id}:messages` | Message cache | 1 hour |
| `hx-lang-server:cache:llm:{hash}` | LLM response cache | 5 minutes |
| `hx-lang-server:cache:rag:{hash}` | RAG result cache | 10 minutes |
| `hx-lang-server:ratelimit:{user_id}` | Rate limiting | 1 minute |
| `hx-lang-server:classification:{hash}` | Query classification cache | 30 minutes |

---

## Query Classification Mechanism

### Classification Strategy

The supervisor uses a **keyword-based classifier with LLM fallback**:

```python
class QueryClassifier:
    """Classifies queries for Ollama routing."""

    CODE_KEYWORDS = ["code", "function", "class", "debug", "error",
                     "python", "javascript", "sql", "api", "implement"]

    RAG_KEYWORDS = ["search", "find", "document", "knowledge",
                   "what is", "explain", "how does"]

    TOOL_KEYWORDS = ["crawl", "fetch", "scrape", "web", "url"]

    def classify(self, query: str) -> str:
        query_lower = query.lower()

        # Keyword-based classification (fast path)
        if any(kw in query_lower for kw in self.CODE_KEYWORDS):
            return "code"
        if any(kw in query_lower for kw in self.TOOL_KEYWORDS):
            return "tool"
        if any(kw in query_lower for kw in self.RAG_KEYWORDS):
            return "rag"

        # LLM fallback for ambiguous queries (slow path)
        return self._llm_classify(query)
```

### Ollama Routing Table

| Query Type | Target Server | Model | Min Context |
|------------|---------------|-------|-------------|
| general | hx-ollama1-server | gemma3:27b | 8KB |
| code | hx-ollama2-server | qwen3-coder:30b | 64KB |
| rag | hx-ollama1-server | gemma3:27b | 64KB |
| tool | hx-ollama1-server | gemma3:27b | 8KB |

**Critical:** RAG and Code operations require **64KB minimum context** (CAIO Decision). LightRAG entity extraction and complex code generation require this headroom. Jim (Ollama SME) to configure models accordingly.

---

## PostgreSQL Checkpoint Configuration

### Connection Configuration

```python
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from psycopg import AsyncConnection

# CRITICAL: These parameters are REQUIRED
connection_kwargs = {
    "autocommit": True,  # REQUIRED for checkpoint commits
    "row_factory": dict_row,  # REQUIRED for langgraph-checkpoint-postgres
    # Note: pgBouncer not in use (CAIO confirmed), direct PostgreSQL connection
}

async def get_checkpointer():
    conn = await AsyncConnection.connect(
        host="hx-postgres-server.hx.dev.local",
        port=5432,
        dbname="hx_lang_server",
        user="hx_lang_server",
        password="${POSTGRES_PASSWORD}",  # From Ansible Vault
        **connection_kwargs
    )
    return AsyncPostgresSaver(conn)
```

### Database Schema

The `langgraph-checkpoint-postgres` library auto-creates these tables:

| Table | Purpose |
|-------|---------|
| `checkpoints` | Checkpoint metadata and state |
| `checkpoint_blobs` | Large state objects (JSONB) |
| `checkpoint_writes` | Pending writes buffer |
| `checkpoint_migrations` | Schema version tracking |

### Database Provisioning

```sql
-- Run on hx-postgres-server as postgres superuser
CREATE USER hx_lang_server WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE hx_lang_server OWNER hx_lang_server;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE hx_lang_server TO hx_lang_server;

-- Create dedicated schema
\c hx_lang_server
CREATE SCHEMA langgraph AUTHORIZATION hx_lang_server;
ALTER USER hx_lang_server SET search_path TO langgraph, public;
```

---

## Redis Integration

### Connection Configuration

```python
import redis.asyncio as redis

redis_pool = redis.ConnectionPool.from_url(
    "redis://hx-redis-server.hx.dev.local:6379/0",
    max_connections=50,  # Increased from 20 per Sri Patel's Redis review
    socket_timeout=5.0,
    socket_connect_timeout=5.0,
    retry_on_timeout=True,
)

async def get_redis():
    return redis.Redis(connection_pool=redis_pool)
```

### Session Management

```python
class SessionManager:
    """Manages ephemeral session state in Redis."""

    KEY_PREFIX = "hx-lang-server"  # Namespace prefix for key isolation
    SESSION_TTL = 3600  # 1 hour
    CACHE_TTL = 300     # 5 minutes

    def _key(self, suffix: str) -> str:
        """Generate namespaced key."""
        return f"{self.KEY_PREFIX}:{suffix}"

    async def create_session(self, session_id: str, data: dict) -> None:
        await self.redis.setex(
            self._key(f"session:{session_id}"),
            self.SESSION_TTL,
            json.dumps(data)
        )

    async def get_session(self, session_id: str) -> Optional[dict]:
        data = await self.redis.get(self._key(f"session:{session_id}"))
        return json.loads(data) if data else None

    async def extend_session(self, session_id: str) -> None:
        await self.redis.expire(self._key(f"session:{session_id}"), self.SESSION_TTL)
```

---

## MCP Client Integration

### Architecture Clarification

**IMPORTANT:** hx-lang-server is an MCP **CLIENT**, not an MCP server.

- **MCP Servers:** hx-fastmcp-server, hx-crawl4ai-mcp-server, hx-docling-mcp-server
- **MCP Client:** hx-lang-server (consumes tools via langchain-mcp-adapters)

### Client Configuration

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)

# Tool discovery
tools = await mcp_client.get_tools()

# Tool invocation (handles namespace prefixes)
result = await mcp_client.invoke_tool("crawl4ai__smart_crawl_url", {
    "url": "https://example.com",
    "output_format": "markdown"
})
```

### Tool Namespace Handling

FastMCP gateway prefixes tools with server name. The client must handle:
- `crawl4ai__smart_crawl_url` (not `smart_crawl_url`)
- `docling__convert_document` (not `convert_document`)

---

## API Specification

### Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/invoke` | Synchronous agent invocation |
| POST | `/stream` | Streaming agent invocation (SSE) |
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check |
| POST | `/webhooks` | Register webhook callback |
| DELETE | `/webhooks/{id}` | Remove webhook |
| GET | `/threads/{thread_id}` | Get thread history |
| DELETE | `/threads/{thread_id}` | Delete thread |

### Request/Response Models

```python
from pydantic import BaseModel, Field
from typing import Optional, List

class InvokeRequest(BaseModel):
    """Request model for agent invocation."""
    query: str = Field(..., description="User query")
    thread_id: Optional[str] = Field(None, description="Thread ID for continuation")
    session_id: Optional[str] = Field(None, description="Session ID")
    config: Optional[dict] = Field(None, description="Agent configuration overrides")

class InvokeResponse(BaseModel):
    """Response model for agent invocation."""
    thread_id: str
    response: str
    query_type: str
    worker_used: str
    iteration_count: int
    metadata: dict

class HealthResponse(BaseModel):
    """Health check response."""
    status: str  # "healthy", "degraded", "unhealthy"
    version: str
    uptime_seconds: float
    dependencies: dict  # Status of PostgreSQL, Redis, Ollama, etc.
```

### Error Responses

```python
class ErrorResponse(BaseModel):
    """Standard error response."""
    error: str
    error_code: str
    detail: Optional[str]
    request_id: str

# Error codes
ERROR_CODES = {
    "INVALID_REQUEST": 400,
    "UNAUTHORIZED": 401,
    "NOT_FOUND": 404,
    "RATE_LIMITED": 429,
    "OLLAMA_UNAVAILABLE": 503,
    "LIGHTRAG_UNAVAILABLE": 503,
    "CHECKPOINT_FAILED": 500,
}
```

---

## n8n Integration (Phase 2)

### HTTP Endpoint Integration

```yaml
# n8n HTTP Request Node Configuration
url: http://hx-lang-server.hx.dev.local:8100/invoke
method: POST
headers:
  Content-Type: application/json
body:
  query: "{{ $json.user_input }}"
  thread_id: "{{ $json.thread_id }}"
  callback_url: "{{ $webhook.url }}"
```

### Webhook Callback Pattern

```
┌─────────┐       ┌─────────────┐       ┌─────────────┐
│   n8n   │──1───▶│ hx-lang-srv │──2───▶│  Process    │
│         │       │             │       │  Agent      │
│         │◀──4───│             │◀──3───│  Task       │
└─────────┘       └─────────────┘       └─────────────┘
     │
     └── Callback URL registered in step 1
         Response delivered via webhook in step 4
```

### Custom Node Requirements (Phase 2)

| Operation | Description |
|-----------|-------------|
| executeAgent | Invoke agent with query |
| checkStatus | Poll for async operation status |
| getResponse | Retrieve completed response |
| listThreads | List active conversation threads |

---

## Dependencies

### External Services

| Service | Hostname | Port | Purpose |
|---------|----------|------|---------|
| PostgreSQL | hx-postgres-server.hx.dev.local | 5432 | Checkpoint persistence |
| Redis | hx-redis-server.hx.dev.local | 6379 | Session caching |
| Ollama (General) | hx-ollama1-server.hx.dev.local | 11434 | General LLM |
| Ollama (Code) | hx-ollama2-server.hx.dev.local | 11434 | Code LLM |
| LightRAG | hx-literag-server.hx.dev.local | 8020 | RAG pipeline |
| Qdrant | hx-qdrant-server.hx.dev.local | 6333 | Vector storage |
| FastMCP | hx-fastmcp-server.hx.dev.local | 8000 | MCP gateway |
| Crawl4AI MCP | hx-crawl4ai-mcp-server.hx.dev.local | 11235 | Web crawling |
| n8n | hx-n8n-server.hx.dev.local | 5678 | Workflow automation |

### Python Dependencies

```
# Core
langgraph>=0.3.0  # CAIO Decision: Use latest v0.3.x
langchain>=0.3.0
langchain-ollama>=0.2.0
langchain-mcp-adapters>=0.1.0  # MCP v1.1 with feature detection

# Persistence
langgraph-checkpoint-postgres>=2.0.0
psycopg[binary]>=3.2.0
redis>=5.0.0

# API
fastapi>=0.115.0
uvicorn>=0.32.0
pydantic>=2.9.0
pydantic-settings>=2.6.0

# HTTP Client
httpx>=0.27.0
aiohttp>=3.10.0

# Utilities
python-dotenv>=1.0.0
structlog>=24.0.0
```

---

## Configuration Management

### Environment Variables

```bash
# Service
SERVICE_NAME=hx-lang-server
SERVICE_PORT=8100
LOG_LEVEL=INFO

# PostgreSQL
POSTGRES_HOST=hx-postgres-server.hx.dev.local
POSTGRES_PORT=5432
POSTGRES_DB=hx_lang_server
POSTGRES_USER=hx_lang_server
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # From Ansible Vault

# Redis
REDIS_URL=redis://hx-redis-server.hx.dev.local:6379/0

# Ollama
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_CODE_MODEL=qwen3-coder:30b

# LightRAG
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:8020

# MCP
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

# Agent Configuration
MAX_RECURSION_DEPTH=25
CHECKPOINT_FREQUENCY=per_turn
SESSION_TTL_SECONDS=3600
```

### Pydantic Settings

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings with validation."""

    service_name: str = "hx-lang-server"
    service_port: int = 8100
    log_level: str = "INFO"

    postgres_host: str
    postgres_port: int = 5432
    postgres_db: str
    postgres_user: str
    postgres_password: str

    redis_url: str

    ollama_general_url: str
    ollama_code_url: str
    ollama_general_model: str = "gemma3:27b"
    ollama_code_model: str = "qwen3-coder:30b"

    lightrag_url: str
    fastmcp_url: str

    max_recursion_depth: int = 25
    checkpoint_frequency: str = "per_turn"
    session_ttl_seconds: int = 3600

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
```

---

## Security Requirements

### Authentication

- **Internal Services:** No authentication (trusted HX network)
- **n8n Integration:** API key in header (Phase 2)
- **Future:** OAuth2/OIDC via hx-dc-server (if needed)

### Authorization

- **Development Environment:** No authorization (all operations permitted)
- **Rate Limiting:** 100 requests/minute per session (Redis-based)

### Network Security

- **NO FIREWALL** - All firewalls disabled per HX-Infrastructure philosophy
- **Network Isolation:** HX internal network only (192.168.10.0/24)
- **TLS:** Not required for dev environment (internal traffic)

### Data Security

- **Credentials:** Stored in Ansible Vault only
- **Checkpoint Data:** Plain text in PostgreSQL (dev environment)
- **Session Data:** Plain text in Redis (dev environment)

---

## Monitoring & Observability

### Health Checks

```python
@app.get("/health")
async def health_check() -> HealthResponse:
    """Comprehensive health check."""
    dependencies = {
        "postgres": await check_postgres(),
        "redis": await check_redis(),
        "ollama_general": await check_ollama(settings.ollama_general_url),
        "ollama_code": await check_ollama(settings.ollama_code_url),
        "lightrag": await check_lightrag(),
        "fastmcp": await check_fastmcp(),
    }

    all_healthy = all(d["status"] == "healthy" for d in dependencies.values())

    return HealthResponse(
        status="healthy" if all_healthy else "degraded",
        version=__version__,
        uptime_seconds=get_uptime(),
        dependencies=dependencies
    )
```

### Key Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `langgraph_invoke_total` | Counter | Total agent invocations |
| `langgraph_invoke_duration_seconds` | Histogram | Invocation latency |
| `langgraph_checkpoint_duration_seconds` | Histogram | Checkpoint persistence time |
| `langgraph_active_sessions` | Gauge | Current active sessions |
| `langgraph_worker_invocations` | Counter | Invocations per worker type |
| `langgraph_ollama_requests` | Counter | Ollama requests by server |
| `langgraph_errors_total` | Counter | Error count by type |

### Logging

```python
import structlog

logger = structlog.get_logger()

# Structured log example
logger.info(
    "agent_invocation_complete",
    thread_id=thread_id,
    query_type=query_type,
    worker=worker_name,
    duration_ms=duration,
    iteration_count=iterations,
)
```

---

## Backup & Recovery

### Backup Strategy

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| PostgreSQL | pg_dump | Daily | 30 days |
| PostgreSQL | WAL archiving | Continuous | 7 days |
| Redis | Not backed up | N/A | Ephemeral |
| Configuration | Git | On change | Forever |

### Recovery Procedures

1. **Service Failure:** Restart systemd service; checkpoints resume automatically
2. **PostgreSQL Failure:** Restore from pg_dump or WAL; conversations continue from last checkpoint
3. **Redis Failure:** Clear and restart; sessions lost but conversations preserved in PostgreSQL

---

## systemd Service Configuration

### Service Unit File

```ini
[Unit]
Description=HX LangGraph Orchestration Server
After=network.target postgresql.service redis.service
Wants=network-online.target

[Service]
Type=simple
User=hx-lang-server
Group=hx-lang-server
WorkingDirectory=/opt/hx-lang-server
Environment=PATH=/opt/hx-lang-server/venv/bin:/usr/local/bin:/usr/bin
EnvironmentFile=/opt/hx-lang-server/.env
ExecStart=/opt/hx-lang-server/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8100
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Resource limits
LimitNOFILE=65536
MemoryMax=16G  # Matches minimum memory requirement per William Chen review

[Install]
WantedBy=multi-user.target
```

### Service Management

```bash
# Start service
sudo systemctl start hx-lang-server

# Enable on boot
sudo systemctl enable hx-lang-server

# Check status
sudo systemctl status hx-lang-server

# View logs
sudo journalctl -u hx-lang-server -f
```

---

## Testing Strategy

### Test Categories

| Category | Count | Coverage |
|----------|-------|----------|
| Unit Tests | 25 | Core logic, classifiers, state management |
| Integration Tests | 20 | Ollama, LightRAG, PostgreSQL, Redis |
| API Tests | 15 | All endpoints, error handling |
| Multi-Agent Tests | 10 | Supervisor patterns, worker routing |
| End-to-End Tests | 8 | Full workflow scenarios |
| **Total** | **78** | 100% requirement coverage |

### Multi-Agent Testing Patterns

```python
# Test supervisor-worker routing
async def test_supervisor_routes_code_query_to_code_agent():
    """Verify code queries route to Ollama2."""
    response = await invoke_agent("Write a Python function to sort a list")
    assert response.worker_used == "code_agent"
    assert "ollama2" in response.metadata["llm_used"]

# Test state persistence across restarts
async def test_conversation_continues_after_restart():
    """Verify checkpoint persistence."""
    thread_id = await start_conversation("Hello")
    # Simulate restart (clear in-memory state)
    await restart_service()
    response = await continue_conversation(thread_id, "Continue our chat")
    assert response.iteration_count > 1  # Proves continuation
```

### Quality Gates

| Gate | Criteria | Phase |
|------|----------|-------|
| Unit Tests | 100% pass, 80% coverage | Pre-commit |
| Integration Tests | All pass | Pre-merge |
| API Tests | All pass, <500ms p95 | Pre-deploy |
| E2E Tests | All pass | Post-deploy |

---

## Success Criteria

### Deployment Success

- **SC-001**: Service responds to `/health` within 2 seconds
- **SC-002**: PostgreSQL checkpoint created successfully on first invocation
- **SC-003**: All three Ollama servers reachable and responding
- **SC-004**: LightRAG integration functional (RAG query returns results)
- **SC-005**: MCP client connects to FastMCP gateway

### Operational Success

- **SC-006**: 95th percentile API response time < 5 seconds
- **SC-007**: Zero checkpoint failures in 48-hour test period
- **SC-008**: Query classification accuracy > 90%
- **SC-009**: Session persistence across service restart verified
- **SC-010**: 100% test suite pass rate

### Phase 1 Complete Criteria

- **SC-011**: Supervisor + 3 workers operational
- **SC-012**: Adaptive RAG with iteration working
- **SC-013**: Multi-Ollama routing functional
- **SC-014**: State persistence validated

### Phase 2 Complete Criteria

- **SC-015**: n8n HTTP integration working
- **SC-016**: Webhook callbacks functional
- **SC-017**: Crawl4AI MCP tool invocation successful

---

## SOLID Principles Application

### Single Responsibility (SRP)
- Each worker agent has single purpose (RAG, Code, Tool)
- Separate modules for: API, agents, persistence, MCP client

### Open/Closed (OCP)
- Agent registry allows adding workers without modifying supervisor
- Tool discovery enables new MCP tools without code changes

### Liskov Substitution (LSP)
- All workers implement common `WorkerAgent` protocol
- Interchangeable worker implementations

### Interface Segregation (ISP)
- Separate interfaces for checkpoint, cache, LLM providers
- Clients depend only on interfaces they use

### Dependency Inversion (DIP)
- Configuration injected via Pydantic Settings
- Abstract interfaces for all external dependencies

---

## Assumptions & Open Questions

### Assumptions

1. **A-001**: Ollama servers have capacity for 3x concurrent request increase from LangGraph
2. **A-002**: LightRAG API is stable and backward compatible
3. **A-003**: FastMCP gateway routes tools correctly with namespace prefixes
4. **A-004**: Python 3.11+ can be installed on hx-lang-server without conflicts
5. **A-005**: 16GB RAM is sufficient for 10 concurrent agent sessions (validated by William Chen)

### Open Questions - RESOLVED

| Question | CAIO Decision | Action |
|----------|---------------|--------|
| LangGraph v0.2.x vs v0.3.x | Use v0.3.x (latest) | Updated dependencies |
| Ollama context sizes | 64KB for RAG and Code | Jim to configure models |
| MCP protocol version | v1.1 with feature detection | Updated FR-020a |
| pgBouncer compatibility | Not applicable (not used) | Removed pgBouncer config |

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (specific commands, exact file paths)
- [x] Focused on service requirements and operational needs
- [x] Written for infrastructure team and agents
- [x] All mandatory sections completed

### Requirement Completeness
- [x] All 26 HIGH severity findings from charter review addressed
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and integrations identified
- [x] Node requirements specified
- [x] Security requirements defined
- [x] Monitoring and observability requirements clear

### Infrastructure Alignment
- [x] Aligns with HX Infrastructure constitution
- [x] Bare-metal deployment documented
- [x] systemd service management specified
- [x] Ansible Vault for credentials only
- [x] NO FIREWALL documented
- [x] SOLID principles documented

---

## Related Documentation

**Charter:**
- `/nodes/hx-lang-server/charter/charter.md` (APPROVED)
- `/nodes/hx-lang-server/charter/reviews/` (12 team reviews)

**To Be Created:**
- `planning/plan.md` - Deployment plan
- `planning/deployment-architecture.md` - Architecture details
- `tasks/` - Task breakdown
- `tests/` - Test suite

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-01 | Agent Zero | Initial specification draft addressing all 26 HIGH severity findings |
| 2.0 | 2025-12-01 | Agent Zero | Synthesis of 12 specialist contributions: memory 16GB (William Chen), Redis pool 50 (Sri Patel), Redis namespace prefix (Alex Rivera), schema_version field (Alex Rivera), timestamps in AgentState |
| 2.1 | 2025-12-01 | Agent Zero | CAIO decisions applied: LangGraph v0.3.x, 64KB context for RAG/Code, MCP v1.1 with feature detection, pgBouncer not applicable |
| 2.1 | 2025-12-04 | CAIO | **APPROVED** - Specification approved for planning phase |

---

## Synthesis Notes

### Conflicts Resolved

| Conflict | Resolution | Source |
|----------|------------|--------|
| Memory 8GB vs 16GB | Adopted 16GB minimum | William Chen infrastructure review |
| Redis pool 20 vs 50 | Adopted 50 connections | Sri Patel Redis review |
| Redis key namespace | Added `hx-lang-server:` prefix | Alex Rivera architecture review |
| State schema versioning | Added `schema_version` field | Alex Rivera architecture review |
| AgentState timestamps | Added `created_at`, `updated_at` | Synthesis enhancement |

### Contributions Integrated

All 12 specialist contributions have been reviewed and synthesized:
1. **Sophia** (LangGraph) - Supervisor pattern, state schema design
2. **Bob** (FastAPI) - API endpoints, async patterns
3. **Trinity** (PostgreSQL) - Checkpoint configuration, connection params
4. **Sri** (Redis) - Connection pooling, TTL strategies
5. **Andy** (LightRAG) - 32KB context requirement, adaptive retrieval
6. **Jim** (Ollama) - Multi-model routing, context sizes
7. **Isabella** (n8n) - Webhook patterns, custom node requirements
8. **George** (FastMCP) - MCP client configuration, namespace handling
9. **David** (Crawl4AI) - Tool discovery, gateway routing
10. **Alex Rivera** (Architecture) - SOLID compliance, namespace standards
11. **William Chen** (Infrastructure) - Resource specs, systemd configuration
12. **Julia Santos** (Testing) - 78 test cases, quality gates

---

**Specification Version:** 2.1
**Last Updated:** 2025-12-04
**Status:** APPROVED - Ready for Planning Phase
