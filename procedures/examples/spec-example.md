# Specification Development Example: Vector Search Gateway

**Document Type:** Example Walkthrough - Specification Development (Phase 1)
**Version:** 1.0
**Date:** 2025-11-24
**Status:** ✅ APPROVED - Reference Example
**Location:** `/home/agent0/HX-Infrastructure/procedures/examples/spec-example.md`

---

## Purpose

This example demonstrates the **Specification Development workflow (Phase 1)** for the Vector Search Gateway service, showing how Alex Rivera (Platform Architect) coordinates with specialist agents to create a comprehensive technical specification from an approved charter.

**Prerequisites:**
- Charter approved (see charter-example.md)
- Agent assignments confirmed
- Knowledge vault research completed

**Related Documents:**
- **Charter:** charter-example.md
- **Workflow:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md`
- **Template:** `/home/agent0/HX-Infrastructure/templates/service-spec-template.md`

---

## Phase 1: Charter Review and Kickoff

### Agent Zero → Alex Rivera (Platform Architect)

**Handoff Message:**
```
Alex, the Vector Search Gateway charter has been approved by CAIO. We need your
architectural guidance to create the technical specification.

Charter Summary:
- Service: hx-vector-gateway (Layer 4 - Agentic & Toolchain)
- Node: hx-vector-gateway-server (192.168.10.235)
- Purpose: Unified vector search API gateway with multi-database support
- Lead: Mitch Anderson (Qdrant SME)
- Timeline: 3-4 weeks

Key Technical Requirements:
- Multi-database support (Qdrant primary, pgvector, extensible for Weaviate)
- Intelligent query routing (hybrid: feature-based + semantic + manual override)
- Semantic caching (meaning-aware with Redis)
- <200ms P95 latency, 100-1000 qps target
- FastAPI framework, Python 3.11

Please coordinate specification development with specialists:
- Mitch Anderson (lead): Qdrant integration architecture
- Bob Martinez: FastAPI API design
- Sri Patel: Redis caching strategy
- Trinity Brooks: PostgreSQL/pgvector integration
- Paul Warfield: Pydantic data models
- Shane Black: LiteLLM embedding integration

Charter location: procedures/examples/charter-example.md
```

### Alex Rivera's Response

```
Acknowledged. I'll coordinate specification development with the team.

Architectural Approach:
1. Adapter pattern for database abstraction (supports extensibility)
2. Strategy pattern for routing logic (enables hybrid routing)
3. Decorator pattern for caching layer (clean separation of concerns)
4. Factory pattern for embedding model selection

Coordination Plan:
Phase 1A: Core architecture design (me + Mitch)
Phase 1B: Component specifications (parallel specialist contributions)
Phase 1C: Integration design (cross-cutting concerns)
Phase 1D: Specification assembly and review

Starting with Phase 1A architecture design session with Mitch.
```

---

## Phase 1A: Core Architecture Design

### Alex Rivera + Mitch Anderson (Collaboration Session)

**Architecture Decision Session Notes:**

**1. System Architecture Pattern**
```
Decision: Layered architecture with clean separation of concerns

┌─────────────────────────────────────────────────────────┐
│  FastAPI Application Layer                              │
│  - Request validation (Pydantic)                        │
│  - Response serialization                               │
│  - Error handling                                       │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Service Layer (Business Logic)                         │
│  - Query routing logic                                  │
│  - Semantic caching decisions                           │
│  - Result aggregation                                   │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Adapter Layer (Database Abstraction)                   │
│  - QdrantAdapter (primary)                              │
│  - PgvectorAdapter                                      │
│  - WeaviateAdapter (future)                             │
│  - Base VectorDatabaseAdapter interface                 │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  External Services                                       │
│  - Qdrant (hx-qdrant-server)                            │
│  - PostgreSQL/pgvector (hx-postgres-server)             │
│  - Redis (hx-redis-server)                              │
│  - LiteLLM (hx-litellm-server) for embeddings           │
└─────────────────────────────────────────────────────────┘
```

**Rationale:**
- Layered architecture provides clear boundaries
- Adapter pattern enables database extensibility without core changes
- Service layer isolates business logic from infrastructure

**2. Routing Strategy Selection**

**Decision Matrix:**
| Routing Type | Use Case | Implementation |
|--------------|----------|----------------|
| **Feature-based** | Database has specific feature (e.g., HNSW in Qdrant) | Route based on query requirements |
| **Semantic** | Query embeddings similarity to database specialization | Compare query embedding to database profiles |
| **Manual** | User explicitly specifies target database | Direct routing via API parameter |
| **Load-based** (future) | Balance across replicas | Monitor query load metrics |

**Implementation:** Hybrid router evaluates in order: Manual override → Feature requirements → Semantic similarity → Default (Qdrant)

**3. Caching Strategy**

**Decision: Hybrid caching with semantic awareness**
```
Cache Key Generation:
1. Text normalization (lowercase, whitespace, stop words)
2. Embedding generation (via LiteLLM)
3. Composite key: hash(normalized_text) + hash(embedding_approx)

Cache Lookup:
1. Exact text match (Redis hash key)
2. If miss: Semantic similarity search (Redis vector similarity, threshold 0.95)
3. If miss: Execute query and cache result

TTL Strategy:
- Default: 3600 seconds (1 hour)
- High-frequency queries: 7200 seconds (2 hours, detected by hit count)
- User-configurable via API parameter
```

**Rationale:** Balances exact match speed with semantic flexibility

**4. Data Models Design Principles**

**Core Entity Model:**
```python
# Pydantic v2 models (Paul Warfield will implement details)

VectorQuery (input):
  - query_text: str
  - top_k: int = 10
  - filter: Optional[dict] = None
  - target_db: Optional[str] = None  # Manual routing
  - use_cache: bool = True
  - cache_ttl: Optional[int] = None

VectorSearchResult (output):
  - id: str
  - score: float
  - metadata: dict
  - source_db: str  # Which database returned this result
  - cached: bool    # Was result served from cache

SearchResponse (wrapper):
  - results: List[VectorSearchResult]
  - total_time_ms: float
  - source_databases: List[str]
  - cache_hit: bool
```

---

## Phase 1B: Component Specifications (Parallel Work)

### Specialist Contributions

#### Bob Martinez (FastAPI SME) - API Design Specification

**API Endpoints Specification:**

**1. POST /v1/search**
```
Purpose: Execute vector similarity search
Request Body: VectorQuery (Pydantic model)
Response: SearchResponse
Status Codes:
  - 200: Success
  - 400: Invalid query parameters
  - 422: Validation error (Pydantic)
  - 500: Internal server error (database connectivity)
  - 503: Service unavailable (all databases down)

Performance SLA: <200ms P95 (per charter requirement)

Rate Limiting: 1000 requests/minute per API key (configurable)
```

**2. POST /v1/embed**
```
Purpose: Generate embeddings for text (utility endpoint)
Request Body: { "text": str, "model": Optional[str] }
Response: { "embedding": List[float], "model": str, "dimensions": int }
Status Codes:
  - 200: Success
  - 400: Invalid text
  - 500: LiteLLM connection error

Use Case: Clients needing embeddings for custom operations
```

**3. GET /v1/health**
```
Purpose: Service health check with database connectivity validation
Response: {
  "status": "healthy" | "degraded" | "unhealthy",
  "databases": {
    "qdrant": "connected" | "disconnected",
    "pgvector": "connected" | "disconnected"
  },
  "cache": "connected" | "disconnected",
  "uptime_seconds": int
}

Health Determination:
- healthy: All databases + cache connected
- degraded: At least 1 database connected, cache optional
- unhealthy: No databases connected
```

**4. GET /v1/stats**
```
Purpose: Operational metrics (for monitoring)
Response: {
  "total_queries": int,
  "cache_hit_rate": float,
  "avg_latency_ms": float,
  "database_usage": {
    "qdrant": int,
    "pgvector": int
  }
}

Authentication: Requires admin API key
```

**Authentication Strategy:**
- API Key authentication (header: X-API-Key)
- Integration with hx-dc-server for key validation
- Rate limiting per API key

**Error Handling:**
- Structured error responses with Pydantic models
- Detailed error messages in development mode
- Generic messages in production (security)
- Request ID tracking for debugging

#### Sri Patel (Redis SME) - Caching Strategy Specification

**Redis Data Structures:**

**1. Query Result Cache**
```
Key Pattern: cache:query:{hash}
Value Type: JSON string (SearchResponse)
TTL: Configurable (default 3600s)
Eviction Policy: allkeys-lru (when maxmemory reached)

Example:
Key: cache:query:sha256("machine learning papers")
Value: {
  "results": [...],
  "total_time_ms": 45.2,
  "cached": false,
  "timestamp": 1732464000
}
```

**2. Semantic Cache Index (for similarity-based lookup)**
```
Key Pattern: cache:semantic:{collection}
Value Type: Sorted Set
Members: query_hash (text)
Scores: timestamp (for TTL management)

Purpose: Track all cached queries for semantic similarity search
Implementation: Use Redis Vector Similarity Search (RediSearch module)
  - Store query embeddings alongside hashes
  - K-NN search with threshold 0.95 for cache hits
```

**3. Statistics Tracking**
```
Key Patterns:
  - stats:queries:total (Counter)
  - stats:cache:hits (Counter)
  - stats:cache:misses (Counter)
  - stats:latency (Histogram approximation with sorted set)
  - stats:db_usage:{db_name} (Counter)

Update Strategy: Increment atomically on each request
Aggregation: Calculate hit rate = hits / (hits + misses)
```

**Connection Pool Configuration:**
```python
Redis Pool Settings:
  - max_connections: 50
  - socket_timeout: 5 seconds
  - socket_connect_timeout: 5 seconds
  - retry_on_timeout: True
  - health_check_interval: 30 seconds
  - decode_responses: True (for string handling)
```

**Failure Handling:**
- Cache miss behavior: If Redis unavailable, bypass cache (graceful degradation)
- No cache blocking: Never fail requests due to cache issues
- Logging: Log all Redis connection errors for monitoring

#### Trinity Brooks (PostgreSQL DBA) - pgvector Integration Specification

**Database Schema:**

**1. Collections Table**
```sql
CREATE TABLE vector_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    dimensions INTEGER NOT NULL,
    distance_metric VARCHAR(20) DEFAULT 'cosine', -- cosine, l2, inner_product
    created_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_collections_name ON vector_collections(name);
```

**2. Vectors Table**
```sql
CREATE TABLE vectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES vector_collections(id) ON DELETE CASCADE,
    external_id VARCHAR(255), -- Original document ID from source system
    embedding vector(1536), -- Adjust dimensions per collection
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Vector similarity index (HNSW for speed)
CREATE INDEX idx_vectors_embedding ON vectors
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Metadata GIN index for filtering
CREATE INDEX idx_vectors_metadata ON vectors USING gin(metadata);

-- Foreign key index
CREATE INDEX idx_vectors_collection ON vectors(collection_id);
```

**Query Patterns:**

**1. Vector Similarity Search with Filtering**
```sql
-- Optimized query for top-k with metadata filter
SELECT
    v.id,
    v.external_id,
    v.metadata,
    (v.embedding <=> $1::vector) AS distance, -- cosine distance operator
    1 - (v.embedding <=> $1::vector) AS similarity_score
FROM vectors v
WHERE
    v.collection_id = $2::uuid
    AND v.metadata @> $3::jsonb -- JSONB containment for filtering
ORDER BY v.embedding <=> $1::vector
LIMIT $4;

-- Parameters:
-- $1: query embedding (vector)
-- $2: collection_id (uuid)
-- $3: metadata filter (jsonb, e.g., {"category": "research"})
-- $4: top_k (int)
```

**Connection Pool Configuration:**
```python
PostgreSQL Pool Settings (asyncpg):
  - min_size: 5
  - max_size: 20
  - max_queries: 50000 (per connection)
  - max_inactive_connection_lifetime: 300 seconds
  - timeout: 10 seconds (connection acquisition)
  - command_timeout: 30 seconds (query execution)
```

**Performance Optimization:**
- HNSW index parameters tuned for 1536-dimension embeddings
- Separate connection pools for read vs write operations
- Query result caching at application layer (Redis)
- VACUUM ANALYZE scheduled weekly (maintenance window)

**Monitoring:**
- pg_stat_statements for slow query detection
- Connection pool utilization metrics
- Index bloat monitoring
- Query latency P50/P95/P99 tracking

#### Mitch Anderson (Qdrant SME) - Qdrant Integration Specification

**Collection Configuration:**

**1. Primary Collection Schema**
```python
Collection: "hx-vector-gateway-primary"
Configuration:
  - vectors:
      size: 1536  # OpenAI ada-002 / text-embedding-3-small dimension
      distance: Cosine
      on_disk: False  # Keep vectors in memory for speed
  - optimizers_config:
      indexing_threshold: 10000  # Build HNSW after 10k vectors
      memmap_threshold: 50000    # Use memory mapping beyond 50k
  - hnsw_config:
      m: 16               # Connections per node (speed vs accuracy)
      ef_construct: 100   # Construction quality (higher = better index)
  - quantization:
      type: "scalar"      # Scalar quantization for 4x compression
      quantile: 0.99      # Preserve 99th percentile accuracy
  - replication_factor: 2  # High availability (future multi-node setup)
```

**2. Payload Schema and Indexes**
```python
Payload Structure:
{
    "external_id": str,        # Original document ID
    "text": str,               # Original text (for debugging/display)
    "metadata": {
        "source": str,         # Data source identifier
        "category": str,       # Document category
        "timestamp": int,      # Unix timestamp
        "custom_fields": {}    # Extensible metadata
    }
}

Indexes:
  - metadata.category (keyword index for filtering)
  - metadata.timestamp (range index for time-based queries)
  - metadata.source (keyword index)
```

**Query Patterns:**

**1. Standard Vector Search with Filters**
```python
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

search_result = client.search(
    collection_name="hx-vector-gateway-primary",
    query_vector=query_embedding,  # List[float] from LiteLLM
    query_filter=Filter(
        must=[
            FieldCondition(
                key="metadata.category",
                match=MatchValue(value="research_papers")
            )
        ]
    ),
    limit=10,
    score_threshold=0.7,  # Minimum similarity score
    with_payload=True,
    with_vectors=False    # Don't return vectors (reduce payload size)
)
```

**Connection Configuration:**
```python
Qdrant Client Settings:
  - host: "hx-qdrant-server.hx.dev.local"
  - port: 6333 (HTTP API)
  - grpc_port: 6334 (gRPC for high performance)
  - prefer_grpc: True  # Use gRPC for 3-5x performance improvement
  - timeout: 10 seconds
  - api_key: from hx-dc-server (if authentication enabled)
  - https: False (internal network, TLS at hx-ssl-server boundary)
```

**Performance Optimization:**
- Use gRPC instead of HTTP for production queries (significant speedup)
- Batch insert operations (bulk upsert for efficiency)
- Async client usage (qdrant-client async support)
- Prefetch optimization (fetch with_payload=False when only IDs needed)

**Monitoring:**
- Collection size and growth rate
- Query latency distribution
- Index build status (wait for HNSW completion)
- Memory usage tracking

#### Paul Warfield (Pydantic SME) - Data Models Specification

**Complete Pydantic v2 Models:**

```python
from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime

# ============================================================================
# INPUT MODELS
# ============================================================================

class VectorQuery(BaseModel):
    """Vector similarity search query input"""

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "query_text": "machine learning research papers",
                "top_k": 10,
                "filter": {"category": "research"},
                "target_db": None,
                "use_cache": True
            }
        }
    )

    query_text: str = Field(
        ...,
        description="Text query for semantic search",
        min_length=1,
        max_length=5000
    )

    top_k: int = Field(
        default=10,
        description="Number of results to return",
        ge=1,
        le=100
    )

    filter: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Metadata filters (JSON object)"
    )

    target_db: Optional[Literal["qdrant", "pgvector"]] = Field(
        default=None,
        description="Manually specify target database (overrides routing)"
    )

    use_cache: bool = Field(
        default=True,
        description="Enable semantic caching"
    )

    cache_ttl: Optional[int] = Field(
        default=None,
        description="Cache TTL in seconds (overrides default)",
        ge=60,
        le=86400
    )

    @field_validator("query_text")
    @classmethod
    def validate_query_text(cls, v: str) -> str:
        """Validate query text is not empty after stripping"""
        if not v.strip():
            raise ValueError("query_text cannot be empty or whitespace only")
        return v.strip()

# ============================================================================
# OUTPUT MODELS
# ============================================================================

class VectorSearchResult(BaseModel):
    """Single vector search result"""

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "doc-12345",
                "score": 0.92,
                "metadata": {"category": "research", "year": 2024},
                "source_db": "qdrant",
                "cached": False
            }
        }
    )

    id: str = Field(..., description="Document identifier")
    score: float = Field(..., description="Similarity score (0-1)", ge=0, le=1)
    metadata: Dict[str, Any] = Field(..., description="Document metadata")
    source_db: str = Field(..., description="Database that returned this result")
    cached: bool = Field(..., description="Whether result was served from cache")

class SearchResponse(BaseModel):
    """Complete search response with metadata"""

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "results": [
                    {
                        "id": "doc-1",
                        "score": 0.95,
                        "metadata": {"title": "ML Paper"},
                        "source_db": "qdrant",
                        "cached": False
                    }
                ],
                "total_time_ms": 45.2,
                "source_databases": ["qdrant"],
                "cache_hit": False,
                "query_embedding_time_ms": 12.1,
                "search_time_ms": 33.1
            }
        }
    )

    results: List[VectorSearchResult] = Field(
        ...,
        description="List of search results ordered by score"
    )

    total_time_ms: float = Field(
        ...,
        description="Total query processing time in milliseconds"
    )

    source_databases: List[str] = Field(
        ...,
        description="Databases queried for these results"
    )

    cache_hit: bool = Field(
        ...,
        description="Whether results were served from cache"
    )

    query_embedding_time_ms: float = Field(
        ...,
        description="Time to generate query embedding"
    )

    search_time_ms: float = Field(
        ...,
        description="Time for database search operations"
    )

# ============================================================================
# HEALTH CHECK MODELS
# ============================================================================

class DatabaseStatus(BaseModel):
    """Individual database connection status"""
    status: Literal["connected", "disconnected"]
    latency_ms: Optional[float] = None

class HealthResponse(BaseModel):
    """Service health check response"""

    status: Literal["healthy", "degraded", "unhealthy"]
    databases: Dict[str, DatabaseStatus]
    cache: Literal["connected", "disconnected"]
    uptime_seconds: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# ============================================================================
# ERROR MODELS
# ============================================================================

class ErrorResponse(BaseModel):
    """Structured error response"""

    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Additional error details (dev mode only)"
    )
    request_id: str = Field(..., description="Request ID for tracing")
```

**Validation Strategy:**
- Use Pydantic field validators for input sanitization
- Leverage ConfigDict for JSON schema generation (OpenAPI docs)
- Provide comprehensive examples for API documentation
- Type hints for editor autocomplete support

#### Shane Black (LiteLLM SME) - Embedding Integration Specification

**LiteLLM Integration Configuration:**

**1. Client Setup**
```python
from litellm import embedding

LiteLLM Configuration:
  - base_url: "http://hx-litellm-server.hx.dev.local:4000"
  - api_key: from environment variable LITELLM_API_KEY
  - default_model: "text-embedding-3-small" (OpenAI, 1536 dimensions)
  - fallback_models: ["nomic-embed-text"] (Ollama local fallback)
  - timeout: 10 seconds
  - max_retries: 2
```

**2. Embedding Generation Flow**
```python
async def generate_embedding(text: str, model: str = "text-embedding-3-small") -> List[float]:
    """
    Generate text embedding via LiteLLM gateway

    LiteLLM handles:
    - Automatic routing to OpenAI or Ollama based on availability
    - Load balancing across multiple API keys
    - Retry logic with exponential backoff
    - Cost tracking and logging
    """
    try:
        response = await embedding(
            model=model,
            input=[text],  # LiteLLM accepts batches
            api_base=litellm_base_url,
            api_key=litellm_api_key
        )
        return response.data[0]["embedding"]

    except Exception as e:
        # Fallback to local Ollama model if LiteLLM unavailable
        logger.warning(f"LiteLLM error: {e}, falling back to local Ollama")
        return await generate_embedding_ollama(text)
```

**3. Model Selection Strategy**

| Model | Provider | Dimensions | Use Case | Cost |
|-------|----------|------------|----------|------|
| text-embedding-3-small | OpenAI | 1536 | General purpose (default) | $0.00002/1k tokens |
| text-embedding-3-large | OpenAI | 3072 | High accuracy needs | $0.00013/1k tokens |
| nomic-embed-text | Ollama (local) | 768 | Offline/fallback | Free (compute) |

**Routing Logic:**
1. Default: text-embedding-3-small (best price/performance)
2. High-accuracy mode (API parameter): text-embedding-3-large
3. Fallback: nomic-embed-text (if LiteLLM/OpenAI unavailable)

**4. Error Handling and Fallback**
```python
Failure Scenarios:
1. LiteLLM server unreachable → Fallback to direct Ollama connection
2. OpenAI rate limit → LiteLLM auto-retries with backoff
3. OpenAI API key invalid → LiteLLM falls back to Ollama models
4. Embedding generation timeout → Return 500 error (no fallback after Ollama)

Monitoring:
- Track embedding generation latency (P50/P95/P99)
- Monitor LiteLLM vs Ollama usage ratio
- Alert on fallback rate >10% (indicates LiteLLM issues)
```

---

## Phase 1C: Integration Design (Cross-Cutting Concerns)

### Alex Rivera (Platform Architect) - Integration Specification

**1. Service Dependencies**

```
hx-vector-gateway dependencies:

CRITICAL (Layer 1 - Identity & Trust):
  ✓ hx-dc-server (192.168.10.200) - API key validation via LDAP
  ✓ hx-ssl-server (192.168.10.202) - TLS termination for external access

REQUIRED (Layer 2 & 3 - Data/Model Plane):
  ✓ hx-qdrant-server (192.168.10.220) - Primary vector database
  ✓ hx-postgres-server (192.168.10.210) - pgvector secondary database
  ✓ hx-redis-server (192.168.10.215) - Semantic caching
  ✓ hx-litellm-server (192.168.10.212) - Embedding generation

OPTIONAL (graceful degradation if unavailable):
  - hx-grafana-server - Metrics visualization (non-blocking)
  - hx-prometheus-server - Metrics collection (non-blocking)
```

**Startup Dependency Validation:**
```python
# On service startup, validate all CRITICAL and REQUIRED dependencies
async def validate_dependencies() -> Dict[str, bool]:
    """
    Check connectivity to all required services

    Fail fast if CRITICAL services unavailable
    Warn if REQUIRED services unavailable but start anyway (degraded mode)
    """
    dependencies = {
        "qdrant": await check_qdrant_connection(),
        "postgres": await check_postgres_connection(),
        "redis": await check_redis_connection(),
        "litellm": await check_litellm_connection()
    }

    if not any([dependencies["qdrant"], dependencies["postgres"]]):
        raise RuntimeError("No vector databases available - cannot start")

    return dependencies
```

**2. Error Handling Strategy**

```python
Error Hierarchy:
1. Client Errors (4xx):
   - 400 Bad Request: Invalid query parameters
   - 401 Unauthorized: Missing/invalid API key
   - 422 Unprocessable Entity: Pydantic validation errors
   - 429 Too Many Requests: Rate limit exceeded

2. Server Errors (5xx):
   - 500 Internal Server Error: Unexpected application error
   - 502 Bad Gateway: Downstream service (Qdrant/Postgres) error
   - 503 Service Unavailable: All databases disconnected
   - 504 Gateway Timeout: Query timeout exceeded

Error Response Format (Pydantic ErrorResponse model):
{
    "error": "DatabaseConnectionError",
    "message": "Unable to connect to vector databases",
    "details": { ... },  # Only in development mode
    "request_id": "req-abc123"  # For tracing
}
```

**3. Logging and Observability**

```python
Logging Strategy:
- Structured JSON logging (for log aggregation)
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Request ID tracking (UUID per request)
- Sensitive data masking (API keys, user data)

Log Events:
  - INFO: Every API request (method, path, status, latency)
  - INFO: Cache hit/miss with hit rate calculation
  - WARNING: Database connection errors (with retry attempts)
  - ERROR: Unexpected exceptions with stack traces
  - DEBUG: Query embeddings, routing decisions (dev mode only)

Metrics (Prometheus format):
  - http_requests_total (counter, labels: method, endpoint, status)
  - http_request_duration_seconds (histogram, labels: method, endpoint)
  - cache_requests_total (counter, labels: hit/miss)
  - database_queries_total (counter, labels: database, status)
  - embedding_generation_duration_seconds (histogram)
```

**4. Configuration Management**

```python
# Environment variables (12-factor app methodology)
Configuration Sources (priority order):
1. Environment variables (highest priority)
2. .env file (development)
3. Default values (fallback)

Required Variables:
  - QDRANT_HOST, QDRANT_PORT, QDRANT_API_KEY
  - POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
  - REDIS_HOST, REDIS_PORT, REDIS_PASSWORD (optional)
  - LITELLM_BASE_URL, LITELLM_API_KEY
  - API_KEY_VALIDATION_URL (hx-dc-server LDAP endpoint)

Validation:
  - Pydantic Settings for configuration management
  - Validate all required variables on startup
  - Fail fast if critical config missing
```

**5. Deployment Architecture**

```
┌───────────────────────────────────────────────────────────────┐
│  hx-ssl-server (TLS Termination)                              │
│  HTTPS → HTTP forwarding                                      │
└───────────────────────────────────────────────────────────────┘
                          ↓
┌───────────────────────────────────────────────────────────────┐
│  hx-vector-gateway-server (192.168.10.235)                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Uvicorn (ASGI Server)                                   │ │
│  │ - Workers: 4 (CPU cores)                                │ │
│  │ - Port: 8000 (internal)                                 │ │
│  │ - Worker class: uvicorn.workers.UvicornWorker           │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ FastAPI Application                                      │ │
│  │ - Async request handling                                │ │
│  │ - Connection pooling (Qdrant, Postgres, Redis)         │ │
│  │ - Request middleware (logging, auth, rate limiting)     │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
       ↓              ↓              ↓              ↓
   Qdrant        PostgreSQL       Redis         LiteLLM
 (.220:6334)     (.210:5432)   (.215:6379)    (.212:4000)
```

**6. Security Considerations**

```
Security Measures:
1. API Key Authentication:
   - Validate against hx-dc-server LDAP
   - Cache validation results (Redis, 5-minute TTL)
   - Rate limiting per API key

2. Input Validation:
   - Pydantic strict mode (no coercion)
   - SQL injection prevention (parameterized queries)
   - NoSQL injection prevention (Qdrant filter validation)
   - Maximum payload size: 10 MB

3. Output Sanitization:
   - Remove internal error details in production
   - Mask sensitive metadata fields
   - Request ID for error tracing (no sensitive data)

4. Network Security:
   - Internal network only (no direct external access)
   - TLS termination at hx-ssl-server
   - Database connections: internal network (no TLS overhead)
   - Firewall rules: Allow only from hx-ssl-server

5. Secrets Management:
   - Ansible Vault for credential storage
   - Environment variables for runtime secrets
   - No secrets in code or logs
   - Rotate API keys quarterly
```

---

## Phase 1D: Specification Assembly and Review

### Alex Rivera - Final Specification Document

**Specification Document Structure:**

```markdown
# Technical Specification: Vector Search Gateway

## 1. Executive Summary
[Service purpose, scope, timeline]

## 2. System Architecture
[Layered architecture diagram + component descriptions]

## 3. API Specification
[All endpoints with request/response models - from Bob Martinez]

## 4. Data Models
[Complete Pydantic models - from Paul Warfield]

## 5. Database Integration
### 5.1 Qdrant Integration [from Mitch Anderson]
### 5.2 PostgreSQL/pgvector Integration [from Trinity Brooks]

## 6. Caching Strategy
[Redis semantic caching design - from Sri Patel]

## 7. Embedding Generation
[LiteLLM integration - from Shane Black]

## 8. Routing Logic
[Hybrid routing implementation]

## 9. Cross-Cutting Concerns
[Error handling, logging, observability, security - from Alex Rivera]

## 10. Performance Requirements
[SLA targets: <200ms P95, 100-1000 qps]

## 11. Dependencies and Integration Points
[Service dependency map with validation]

## 12. Configuration Management
[Environment variables, deployment settings]

## 13. Testing Strategy
[Test areas: unit, integration, performance, security]

## 14. Deployment Architecture
[Infrastructure layout, systemd service, monitoring]

## 15. Security Considerations
[Authentication, authorization, secrets management]

## 16. Success Criteria
[Measurable outcomes for deployment validation]
```

### Specification Review Process

**1. Technical Review - Specialist Agents**

**Mitch Anderson (Lead) Review:**
```
✅ APPROVED - Qdrant integration specification

Strengths:
- Proper use of gRPC for performance (3-5x faster than HTTP)
- HNSW configuration appropriate for 1536-dimension embeddings
- Scalar quantization for 4x compression without accuracy loss
- Replication factor 2 for future HA setup

Recommendations:
- Monitor index build completion before production traffic
- Consider collection aliases for zero-downtime reindexing
```

**Bob Martinez (FastAPI) Review:**
```
✅ APPROVED - API design specification

Strengths:
- RESTful design with clear resource semantics
- Comprehensive error handling with structured responses
- Rate limiting strategy aligns with infrastructure standards
- Health check endpoint supports load balancer integration

Recommendations:
- Add API versioning in URL path (/v1/) for future compatibility
- Consider OpenAPI schema export for client SDK generation
```

**Sri Patel (Redis) Review:**
```
✅ APPROVED - Caching strategy specification

Strengths:
- Hybrid caching (exact + semantic) maximizes hit rate
- LRU eviction policy appropriate for query cache use case
- Connection pooling configuration prevents connection exhaustion
- Graceful degradation if Redis unavailable

Recommendations:
- Monitor cache memory usage (set maxmemory policy)
- Implement cache warming for high-frequency queries
- Consider separate Redis instance for different TTL buckets
```

**Trinity Brooks (PostgreSQL) Review:**
```
✅ APPROVED - pgvector integration specification

Strengths:
- HNSW index configuration optimized for query performance
- Proper use of JSONB for metadata filtering
- Connection pooling prevents database connection exhaustion
- Maintenance plan (VACUUM ANALYZE) documented

Recommendations:
- Monitor index bloat (HNSW can degrade over time)
- Consider partitioning vectors table if >10M records
- Use read replicas for high query load (future scaling)
```

**2. Architecture Review - Alex Rivera**

```
✅ APPROVED - Complete specification ready for planning phase

Architecture Validation:
✓ Clean separation of concerns (layered architecture)
✓ Adapter pattern enables database extensibility
✓ Hybrid routing supports charter requirements
✓ Semantic caching design is innovative and sound
✓ All Layer 1-3 dependencies correctly identified
✓ Error handling comprehensive and production-ready
✓ Security measures align with HX-Infrastructure standards

Performance Validation:
✓ <200ms P95 latency achievable with current design
  - Embedding: ~10-15ms (LiteLLM)
  - Cache lookup: ~1-2ms (Redis)
  - Database query: ~20-50ms (Qdrant gRPC)
  - Processing overhead: ~5-10ms
  - Total: ~36-77ms typical (well under 200ms target)

✓ 100-1000 qps achievable with 4 Uvicorn workers
  - Each worker: ~250 qps capacity
  - 4 workers: ~1000 qps total
  - Bottleneck: Database query latency (Qdrant/Postgres)
  - Mitigation: Connection pooling + caching

Quality Gates:
✓ All specialist reviews completed and approved
✓ All charter requirements addressed in specification
✓ Dependencies documented with validation strategy
✓ Testing strategy defined (to be detailed in test planning)
✓ Deployment architecture validated against infrastructure standards

Ready for Phase 2: Task Breakdown and Planning
```

**3. Stakeholder Approval - CAIO**

```
CAIO Review:

✅ APPROVED - Specification meets all charter requirements

Business Validation:
✓ Multi-database support (Qdrant + pgvector + extensible) ✓
✓ Intelligent routing (hybrid: feature + semantic + manual) ✓
✓ Semantic caching (meaning-aware, not just text matching) ✓
✓ Performance SLA (<200ms P95, 100-1000 qps) ✓
✓ Timeline aligned (3-4 weeks from charter approval) ✓

Technical Confidence:
- Specialist reviews all positive
- Architecture sound and extensible
- Dependencies clearly mapped
- Risk mitigation addressed

Approval: Proceed to Planning Phase (Task Breakdown)

Signature: CAIO
Date: 2025-11-17 14:30:00 UTC
```

---

## Phase 2: Transition to Planning

### Agent Zero - Handoff to Planning Phase

**Handoff Message:**

```
Specification approved by all stakeholders. Transitioning to Planning Phase.

Specification Location:
  services/operational/hx-vector-gateway/service-spec-vector-gateway.md

Next Phase: Task Breakdown and Planning (Phase 2)
Assigned Lead: [Planning specialist from Technology SME agents]

Planning Phase Objectives:
1. Break specification into implementable tasks
2. Define task dependencies and sequencing
3. Create detailed task documents (service-task-*.md)
4. Estimate effort and timeline
5. Assign tasks to specialist agents
6. Create test planning strategy

Deliverables:
- service-plan-vector-gateway.md (master plan)
- service-task-*.md files (individual task details)
- Task dependency graph
- Resource allocation matrix

Timeline: Planning phase should complete within 2-3 days
Quality Gate: Plan approved before development begins

Proceeding to plan-example.md creation...
```

---

## Key Learnings from This Example

### Multi-Agent Coordination Patterns

**1. Parallel Work Streams:**
- Architect (Alex) coordinates all specialists in Phase 1B
- Each specialist works independently on their domain
- Reduces overall timeline (parallel vs sequential)
- Requires clear interface definitions up front

**2. Integration Synthesis:**
- Alex Rivera synthesizes specialist contributions (Phase 1C)
- Identifies cross-cutting concerns not visible to specialists
- Ensures architectural consistency across components
- Validates integration points and dependencies

**3. Review Cycles:**
- Technical review by specialists (domain validation)
- Architecture review by Alex (system-level validation)
- Stakeholder review by CAIO (business validation)
- Multiple approval gates ensure quality

### Technical Design Principles Demonstrated

**1. Layered Architecture:**
- FastAPI → Service → Adapter → External Services
- Clean separation enables independent component evolution
- Testability improved (mock adapters for unit tests)

**2. Adapter Pattern:**
- VectorDatabaseAdapter interface
- QdrantAdapter, PgvectorAdapter implementations
- Enables extensibility (future: WeaviateAdapter) without core changes

**3. Graceful Degradation:**
- Redis cache miss → bypass cache, query database
- LiteLLM unavailable → fallback to Ollama
- One database down → route to available database
- Non-blocking failure modes improve reliability

**4. Configuration as Code:**
- 12-factor app methodology (environment variables)
- Pydantic Settings for validation
- No hardcoded configuration (infrastructure-agnostic)

### Documentation Quality

**1. Specification Completeness:**
- Every component fully specified with code examples
- Error cases documented alongside happy paths
- Performance targets quantified with calculations
- Security considerations integrated throughout

**2. Traceability:**
- Charter requirements → Specification sections
- Specification sections → Specialist contributions
- Each design decision has rationale documented
- Review comments preserved for future reference

**3. Actionable for Next Phase:**
- Specification detailed enough to create task breakdown
- All technical unknowns resolved during spec phase
- Dependencies and integration points clearly documented
- Planning phase can proceed without returning to specification

---

## Related Examples

**Previous:** charter-example.md (Charter Creation workflow)
**Next:** plan-example.md (Task Breakdown and Planning workflow)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-24
**Repository:** https://github.com/Hana-X-AI/HX-Infrastructure.git

---

*This example demonstrates Phase 1 (Specification Development) of the 5-phase canonical lifecycle, showing how Alex Rivera coordinates specialist agents to transform an approved charter into a comprehensive technical specification ready for task breakdown and planning.*
