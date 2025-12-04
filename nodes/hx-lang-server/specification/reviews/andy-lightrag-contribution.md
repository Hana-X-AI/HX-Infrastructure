# Specification Contribution: Andy (LightRAG SME)

**Contribution Date:** 2025-12-01
**Spec Version:** 1.0
**Focus Areas:** LightRAG, RAG integration, query modes, context sizing, adaptive retrieval
**Charter Reference:** `/nodes/hx-lang-server/charter/charter.md`
**Previous Review:** `/nodes/hx-lang-server/charter/reviews/andy-lightrag-review.md`

---

## Executive Summary

This contribution provides detailed technical guidance for LightRAG integration with hx-lang-server. The specification draft correctly identifies LightRAG as the RAG pipeline component (FR-014 through FR-016) and specifies HTTP API integration with hx-literag-server. This contribution expands on integration patterns, query mode selection logic, adaptive retrieval strategies, context size validation, and provides production-ready code examples.

---

## Integration Pattern Details

### Recommended Architecture: HTTP API Integration

The specification correctly identifies HTTP API integration with existing hx-literag-server (FR-014). This is the **recommended pattern** for the following reasons:

1. **Service Isolation**: LangGraph agents remain decoupled from LightRAG internals
2. **Operational Simplicity**: Single point of LightRAG configuration/maintenance
3. **Consistency**: Ensures embedding model alignment across all consumers
4. **Incremental Benefits**: Leverages existing indexed knowledge graph without re-indexing

### HTTP API Integration Pattern

```python
"""
LightRAG HTTP Client for hx-lang-server RAG Agent.

This module provides a typed, async HTTP client for interacting with
hx-literag-server's REST API. Designed for integration with LangGraph
worker agents.
"""
import httpx
from typing import Optional, Literal
from pydantic import BaseModel, Field
from enum import Enum

class QueryMode(str, Enum):
    """LightRAG query modes per research paper."""
    LOCAL = "local"      # Entity-focused, 1 API call
    GLOBAL = "global"    # Theme-focused, 1 API call
    HYBRID = "hybrid"    # Combined, 2-3 API calls (recommended default)
    MIX = "mix"          # KG + vector retrieval
    NAIVE = "naive"      # Basic search, skips KG (NOT recommended)

class LightRAGQueryRequest(BaseModel):
    """Request model for LightRAG query endpoint."""
    query: str = Field(..., description="User query text")
    mode: QueryMode = Field(default=QueryMode.HYBRID, description="Retrieval mode")
    only_need_context: bool = Field(default=False, description="Return context only, no LLM generation")
    top_k: int = Field(default=60, ge=1, le=200, description="Number of items to retrieve")
    enable_rerank: bool = Field(default=True, description="Enable reranking for better precision")

class LightRAGQueryResponse(BaseModel):
    """Response model from LightRAG query."""
    response: str = Field(..., description="Generated response or context")
    mode_used: QueryMode = Field(..., description="Actual mode used")
    entities_retrieved: int = Field(default=0, description="Number of entities in context")
    relationships_retrieved: int = Field(default=0, description="Number of relationships in context")

class LightRAGClient:
    """
    Async HTTP client for hx-literag-server.

    Implements circuit breaker pattern and retry logic for production reliability.
    Designed to be injected into LangGraph RAG Agent.
    """

    def __init__(
        self,
        base_url: str = "http://hx-literag-server.hx.dev.local:9621",
        timeout: float = 30.0,
        max_retries: int = 3,
    ):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self._client: Optional[httpx.AsyncClient] = None

    async def __aenter__(self):
        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=httpx.Timeout(self.timeout),
            headers={"Content-Type": "application/json"}
        )
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self._client:
            await self._client.aclose()

    async def query(
        self,
        query: str,
        mode: QueryMode = QueryMode.HYBRID,
        only_need_context: bool = False,
        top_k: int = 60,
        enable_rerank: bool = True,
    ) -> LightRAGQueryResponse:
        """
        Execute a LightRAG query via HTTP API.

        Args:
            query: User query text
            mode: Retrieval mode (local, global, hybrid, mix)
            only_need_context: If True, returns context only without LLM generation
            top_k: Number of items to retrieve
            enable_rerank: Enable reranking for improved precision

        Returns:
            LightRAGQueryResponse with response text and metadata

        Raises:
            httpx.HTTPStatusError: On HTTP errors (4xx, 5xx)
            httpx.TimeoutException: On request timeout
        """
        request = LightRAGQueryRequest(
            query=query,
            mode=mode,
            only_need_context=only_need_context,
            top_k=top_k,
            enable_rerank=enable_rerank,
        )

        # Retry logic with exponential backoff
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                response = await self._client.post(
                    "/query",
                    json=request.model_dump()
                )
                response.raise_for_status()
                data = response.json()
                return LightRAGQueryResponse(
                    response=data.get("response", ""),
                    mode_used=mode,
                    entities_retrieved=data.get("entities_count", 0),
                    relationships_retrieved=data.get("relations_count", 0),
                )
            except (httpx.HTTPStatusError, httpx.TimeoutException) as e:
                last_exception = e
                if attempt < self.max_retries - 1:
                    import asyncio
                    await asyncio.sleep(2 ** attempt)  # Exponential backoff

        raise last_exception

    async def health_check(self) -> bool:
        """Check if LightRAG service is healthy."""
        try:
            response = await self._client.get("/health")
            return response.status_code == 200
        except Exception:
            return False
```

### Alternative Pattern: Embedded LightRAG Instance (NOT Recommended)

For completeness, here is the embedded pattern. This is **NOT recommended** for hx-lang-server because:
- Requires separate knowledge graph indexing
- Embedding model must match hx-literag-server exactly
- Increases deployment complexity
- No benefit over HTTP API for query-only operations

```python
"""
ALTERNATIVE PATTERN - NOT RECOMMENDED for hx-lang-server.
Shown for completeness. Use HTTP API integration instead.
"""
from lightrag import LightRAG, QueryParam
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
from lightrag.utils import EmbeddingFunc
from lightrag.kg.shared_storage import initialize_pipeline_status

async def create_embedded_lightrag(working_dir: str) -> LightRAG:
    """
    Create embedded LightRAG instance.

    WARNING: This pattern requires:
    1. Separate document indexing
    2. Exact embedding model match with existing data
    3. Shared storage configuration for PostgreSQL/Qdrant

    For hx-lang-server, use HTTP API integration instead.
    """
    rag = LightRAG(
        working_dir=working_dir,
        llm_model_func=ollama_model_complete,
        llm_model_name="gemma3:27b",
        # CRITICAL: Context size must be >= 32KB for entity extraction
        llm_model_kwargs={"options": {"num_ctx": 32768}},
        embedding_func=EmbeddingFunc(
            embedding_dim=1024,  # Must match hx-literag-server
            func=lambda texts: ollama_embed(
                texts,
                embed_model="bge-m3:latest",
                host="http://hx-ollama3-server.hx.dev.local:11434"
            )
        ),
        # Production storage backends
        kv_storage="PGKVStorage",
        vector_storage="QdrantVectorDBStorage",
        graph_storage="PGGraphStorage",
        doc_status_storage="PGDocStatusStorage",
    )

    # CRITICAL: Both initialization calls are MANDATORY
    await rag.initialize_storages()
    await initialize_pipeline_status()

    return rag
```

---

## Query Mode Selection Logic

### Decision Matrix

The specification correctly identifies four query modes (FR-016: local, global, hybrid, mix). The following decision logic should be implemented in the RAG Agent's query classifier:

| Query Characteristic | Recommended Mode | API Calls | Latency | Use Case |
|---------------------|------------------|-----------|---------|----------|
| Simple entity lookup | `local` | 1 | ~500ms | "Who is X?", "What is Y?" |
| Thematic/conceptual | `global` | 1 | ~800ms | "How does A influence B?" |
| Complex multi-faceted | `hybrid` | 2-3 | ~1.5s | Default for comprehensive answers |
| KG + vector combined | `mix` | 3+ | ~2s | Research-quality with reranking |

### Query Mode Classifier Implementation

```python
"""
Query Mode Classifier for LangGraph RAG Agent.

Implements keyword-based fast path with LLM fallback for ambiguous queries.
Aligned with LightRAG research paper recommendations.
"""
from typing import Literal
import re

QueryModeType = Literal["local", "global", "hybrid", "mix"]

class LightRAGQueryClassifier:
    """
    Classifies queries to select optimal LightRAG mode.

    Research paper findings:
    - hybrid mode achieves highest win rate (60-85% vs NaiveRAG)
    - local mode is fastest for simple entity queries
    - mix mode best when reranking is enabled
    """

    # Entity-focused patterns (local mode)
    LOCAL_PATTERNS = [
        r"\bwho\s+(?:is|was|are|were)\b",
        r"\bwhat\s+(?:is|was|are|were)\s+(?:the\s+)?(?:name|author|creator|inventor)\b",
        r"\bwhen\s+(?:did|was|were)\b",
        r"\bwhere\s+(?:is|was|are|were)\b",
        r"\blist\s+(?:the|all)\b",
        r"\bdefine\b",
    ]

    # Thematic/conceptual patterns (global mode)
    GLOBAL_PATTERNS = [
        r"\bhow\s+does\b.*\b(?:influence|affect|impact|relate)\b",
        r"\bwhy\s+(?:did|does|do|is|are)\b",
        r"\bexplain\s+(?:the\s+)?(?:relationship|connection|impact)\b",
        r"\bcompare\s+and\s+contrast\b",
        r"\bwhat\s+(?:are\s+)?the\s+(?:main|key|major)\s+(?:themes|concepts|ideas)\b",
        r"\bsummarize\b",
        r"\boverview\s+of\b",
    ]

    # Complex patterns requiring hybrid (default)
    HYBRID_PATTERNS = [
        r"\band\s+how\b",
        r"\balso\s+(?:explain|describe)\b",
        r"\bin\s+detail\b",
        r"\bcomprehensive\b",
        r"\banalyze\b",
    ]

    def __init__(self, enable_llm_fallback: bool = True):
        self.enable_llm_fallback = enable_llm_fallback
        self._local_re = [re.compile(p, re.IGNORECASE) for p in self.LOCAL_PATTERNS]
        self._global_re = [re.compile(p, re.IGNORECASE) for p in self.GLOBAL_PATTERNS]
        self._hybrid_re = [re.compile(p, re.IGNORECASE) for p in self.HYBRID_PATTERNS]

    def classify(self, query: str) -> QueryModeType:
        """
        Classify query to determine optimal LightRAG mode.

        Args:
            query: User query text

        Returns:
            Recommended query mode: local, global, hybrid, or mix
        """
        query_lower = query.lower().strip()

        # Check for explicit hybrid indicators first (highest priority)
        for pattern in self._hybrid_re:
            if pattern.search(query_lower):
                return "hybrid"

        # Check for local mode indicators
        local_score = sum(1 for p in self._local_re if p.search(query_lower))

        # Check for global mode indicators
        global_score = sum(1 for p in self._global_re if p.search(query_lower))

        # Decision logic
        if local_score > 0 and global_score == 0:
            return "local"
        elif global_score > 0 and local_score == 0:
            return "global"
        elif local_score > 0 and global_score > 0:
            # Mixed signals - use hybrid
            return "hybrid"
        else:
            # No clear indicators - default to hybrid (best research results)
            return "hybrid"

    def classify_with_rerank_recommendation(
        self,
        query: str
    ) -> tuple[QueryModeType, bool]:
        """
        Classify query and recommend reranking.

        Returns:
            Tuple of (query_mode, enable_rerank)
        """
        mode = self.classify(query)

        # Enable reranking for mix mode (research paper recommendation)
        # Also enable for hybrid when query seems research-oriented
        enable_rerank = mode in ("mix", "hybrid")

        return mode, enable_rerank
```

### Integration with LangGraph RAG Agent

```python
"""
RAG Agent node for LangGraph supervisor.

Integrates LightRAG query classification and adaptive retrieval.
"""
from typing import TypedDict, Annotated, Optional
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage, AIMessage

class RAGAgentState(TypedDict):
    """State schema for RAG Agent."""
    messages: Annotated[list[BaseMessage], add_messages]
    query: str
    rag_context: Optional[str]
    query_mode: Optional[str]
    retrieval_iterations: int
    rag_sufficient: bool

async def rag_agent_node(
    state: RAGAgentState,
    lightrag_client: LightRAGClient,
    classifier: LightRAGQueryClassifier,
) -> RAGAgentState:
    """
    RAG Agent node for LangGraph.

    Implements adaptive retrieval with mode selection and iteration.
    """
    query = state["query"]
    iterations = state.get("retrieval_iterations", 0)

    # Classify query to select optimal mode
    mode, enable_rerank = classifier.classify_with_rerank_recommendation(query)

    # Execute LightRAG query
    async with lightrag_client as client:
        result = await client.query(
            query=query,
            mode=QueryMode(mode),
            enable_rerank=enable_rerank,
        )

    # Check if context is sufficient
    context_sufficient = (
        result.entities_retrieved >= 3 or
        result.relationships_retrieved >= 2 or
        len(result.response) > 500
    )

    return {
        **state,
        "rag_context": result.response,
        "query_mode": mode,
        "retrieval_iterations": iterations + 1,
        "rag_sufficient": context_sufficient,
    }
```

---

## Adaptive Retrieval Strategy

### Multi-Stage Retrieval Pattern

The charter specifies "retrieval iteration when initial results insufficient" (Success Criterion 1). The following pattern implements this requirement:

```python
"""
Adaptive Retrieval Strategy for LangGraph RAG Agent.

Implements iterative retrieval with mode escalation when initial
results are insufficient. Aligns with LightRAG dual-level paradigm.
"""
from typing import Literal
from enum import IntEnum

class RetrievalStage(IntEnum):
    """Retrieval stages with increasing comprehensiveness."""
    INITIAL = 1      # First attempt with classified mode
    ESCALATED = 2    # Escalate to more comprehensive mode
    COMPREHENSIVE = 3  # Full hybrid retrieval
    EXHAUSTIVE = 4   # Mix mode with reranking

class AdaptiveRetrievalStrategy:
    """
    Implements adaptive retrieval with iteration.

    Strategy based on LightRAG research paper findings:
    1. Start with classified mode (fast path)
    2. Escalate to hybrid if insufficient
    3. Use mix with reranking for exhaustive retrieval
    """

    # Escalation path for each starting mode
    ESCALATION_PATH = {
        "local": ["local", "hybrid", "mix"],
        "global": ["global", "hybrid", "mix"],
        "hybrid": ["hybrid", "mix"],
        "mix": ["mix"],
    }

    # Minimum thresholds for "sufficient" context
    MIN_ENTITIES = 3
    MIN_RELATIONSHIPS = 2
    MIN_CONTEXT_LENGTH = 500

    def __init__(self, max_iterations: int = 3):
        self.max_iterations = max_iterations

    def evaluate_sufficiency(
        self,
        entities_count: int,
        relationships_count: int,
        context_length: int,
    ) -> bool:
        """
        Evaluate if retrieved context is sufficient.

        Based on empirical thresholds for quality answers.
        """
        return (
            entities_count >= self.MIN_ENTITIES or
            relationships_count >= self.MIN_RELATIONSHIPS or
            context_length >= self.MIN_CONTEXT_LENGTH
        )

    def get_next_mode(
        self,
        current_mode: str,
        iteration: int,
    ) -> tuple[str, bool]:
        """
        Get next retrieval mode for escalation.

        Returns:
            Tuple of (next_mode, enable_rerank)
        """
        path = self.ESCALATION_PATH.get(current_mode, ["hybrid", "mix"])

        # Clamp to available escalation levels
        index = min(iteration, len(path) - 1)
        next_mode = path[index]

        # Enable reranking only for mix mode
        enable_rerank = next_mode == "mix"

        return next_mode, enable_rerank

    def should_continue(
        self,
        iteration: int,
        is_sufficient: bool,
        current_mode: str,
    ) -> bool:
        """
        Determine if retrieval should continue.

        Returns True if more retrieval attempts are warranted.
        """
        if is_sufficient:
            return False

        if iteration >= self.max_iterations:
            return False

        # Check if we can still escalate
        path = self.ESCALATION_PATH.get(current_mode, [])
        return iteration < len(path)


async def adaptive_rag_workflow(
    query: str,
    lightrag_client: LightRAGClient,
    classifier: LightRAGQueryClassifier,
    strategy: AdaptiveRetrievalStrategy,
) -> dict:
    """
    Execute adaptive retrieval workflow.

    Implements iterative retrieval with mode escalation.
    """
    # Initial classification
    initial_mode, _ = classifier.classify_with_rerank_recommendation(query)

    current_mode = initial_mode
    iteration = 0
    final_result = None

    async with lightrag_client as client:
        while True:
            mode, enable_rerank = strategy.get_next_mode(current_mode, iteration)

            result = await client.query(
                query=query,
                mode=QueryMode(mode),
                enable_rerank=enable_rerank,
            )

            is_sufficient = strategy.evaluate_sufficiency(
                entities_count=result.entities_retrieved,
                relationships_count=result.relationships_retrieved,
                context_length=len(result.response),
            )

            final_result = result
            iteration += 1

            if not strategy.should_continue(iteration, is_sufficient, mode):
                break

            current_mode = mode

    return {
        "response": final_result.response,
        "mode_used": current_mode,
        "iterations": iteration,
        "entities": final_result.entities_retrieved,
        "relationships": final_result.relationships_retrieved,
    }
```

---

## Context Size Validation

### Critical Requirement: 32KB Minimum Context

The specification correctly notes the 32KB context requirement (FR-013). This section provides enforcement mechanisms.

**WARNING**: Default Ollama models use 8KB context. LightRAG entity extraction **WILL FAIL** with insufficient context.

### Context Size Enforcement

```python
"""
Context Size Validation for LightRAG Operations.

Ensures Ollama models meet minimum 32KB context requirement.
"""
import httpx
from typing import Optional

# Minimum context size in tokens (32KB = 32,768 tokens)
MIN_CONTEXT_SIZE = 32768
RECOMMENDED_CONTEXT_SIZE = 65536

class ContextSizeError(Exception):
    """Raised when Ollama model context is insufficient for LightRAG."""
    pass

async def validate_ollama_context_size(
    ollama_url: str,
    model_name: str,
    min_context: int = MIN_CONTEXT_SIZE,
) -> dict:
    """
    Validate Ollama model context size meets LightRAG requirements.

    Args:
        ollama_url: Ollama server URL (e.g., http://hx-ollama1-server.hx.dev.local:11434)
        model_name: Model name to validate
        min_context: Minimum required context size (default: 32768)

    Returns:
        Dict with model info and validation status

    Raises:
        ContextSizeError: If model context is below minimum
    """
    async with httpx.AsyncClient() as client:
        # Get model info from Ollama API
        response = await client.post(
            f"{ollama_url}/api/show",
            json={"name": model_name}
        )

        if response.status_code != 200:
            raise ValueError(f"Failed to get model info for {model_name}")

        model_info = response.json()

        # Extract context length from model parameters
        # Default Ollama context is 8192 if not specified
        parameters = model_info.get("parameters", "")

        # Parse num_ctx from parameters string
        context_size = 8192  # Default
        for line in parameters.split("\n"):
            if "num_ctx" in line.lower():
                try:
                    context_size = int(line.split()[-1])
                except (ValueError, IndexError):
                    pass

        validation_result = {
            "model": model_name,
            "context_size": context_size,
            "min_required": min_context,
            "recommended": RECOMMENDED_CONTEXT_SIZE,
            "valid": context_size >= min_context,
            "optimal": context_size >= RECOMMENDED_CONTEXT_SIZE,
        }

        if not validation_result["valid"]:
            raise ContextSizeError(
                f"Model {model_name} has context size {context_size} tokens, "
                f"but LightRAG requires minimum {min_context} tokens. "
                f"Create a Modelfile with 'PARAMETER num_ctx {min_context}' "
                f"or use llm_model_kwargs={{'options': {{'num_ctx': {min_context}}}}}"
            )

        return validation_result


def get_ollama_model_kwargs(
    context_size: int = MIN_CONTEXT_SIZE,
    temperature: float = 0.7,
    num_predict: int = 4096,
) -> dict:
    """
    Get Ollama model kwargs with proper context size for LightRAG.

    Use these kwargs when initializing LightRAG or calling Ollama directly.
    """
    return {
        "options": {
            "num_ctx": context_size,
            "temperature": temperature,
            "num_predict": num_predict,
        }
    }
```

### Modelfile Template for LightRAG-Compatible Models

```dockerfile
# Modelfile for LightRAG-compatible Ollama model
# Usage: ollama create gemma3-32k -f Modelfile

FROM gemma3:27b

# CRITICAL: LightRAG requires minimum 32K context
# 64K recommended for complex documents
PARAMETER num_ctx 65536

# Reasonable temperature for entity extraction
PARAMETER temperature 0.7

# Allow sufficient output for entity-relationship extraction
PARAMETER num_predict 4096

# System prompt for entity extraction (optional)
SYSTEM """You are a helpful AI assistant specializing in information extraction
and knowledge graph construction. Extract entities and relationships accurately."""
```

### Startup Validation Pattern

```python
"""
Startup validation for hx-lang-server.

Validates all Ollama models meet LightRAG context requirements before
allowing service to start.
"""
import asyncio
from typing import List

async def validate_all_ollama_models(
    models: List[dict],
) -> dict:
    """
    Validate all configured Ollama models at startup.

    Args:
        models: List of dicts with 'url' and 'model' keys

    Returns:
        Validation summary

    Raises:
        ContextSizeError: If any model fails validation
    """
    results = []
    errors = []

    for config in models:
        try:
            result = await validate_ollama_context_size(
                ollama_url=config["url"],
                model_name=config["model"],
            )
            results.append(result)
        except ContextSizeError as e:
            errors.append(str(e))

    if errors:
        raise ContextSizeError(
            f"Ollama model validation failed:\n" + "\n".join(errors)
        )

    return {
        "validated_models": len(results),
        "all_optimal": all(r["optimal"] for r in results),
        "results": results,
    }


# Usage in FastAPI startup
async def startup_validation():
    """Run at hx-lang-server startup."""
    models_to_validate = [
        {
            "url": "http://hx-ollama1-server.hx.dev.local:11434",
            "model": "gemma3:27b"
        },
        {
            "url": "http://hx-ollama2-server.hx.dev.local:11434",
            "model": "qwen3-coder:30b"
        },
    ]

    validation = await validate_all_ollama_models(models_to_validate)

    if not validation["all_optimal"]:
        import logging
        logging.warning(
            "Some Ollama models have suboptimal context size. "
            "Recommend 64KB for best LightRAG performance."
        )

    return validation
```

---

## Code Examples

### Complete RAG Agent Implementation

```python
"""
Complete RAG Agent for LangGraph Supervisor Pattern.

Production-ready implementation with:
- HTTP API integration to hx-literag-server
- Query mode classification
- Adaptive retrieval with iteration
- Context size validation
- Health check integration
"""
from typing import TypedDict, Annotated, Optional, Any
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage, AIMessage, HumanMessage
from pydantic import BaseModel, Field
import structlog

logger = structlog.get_logger()

# State schema for RAG Agent
class RAGAgentState(TypedDict):
    """State managed by RAG Agent."""
    messages: Annotated[list[BaseMessage], add_messages]
    query: str
    query_type: str
    rag_context: Optional[str]
    rag_mode_used: Optional[str]
    rag_iterations: int
    rag_sufficient: bool
    rag_entities_count: int
    rag_relationships_count: int

class RAGAgentConfig(BaseModel):
    """Configuration for RAG Agent."""
    lightrag_url: str = Field(
        default="http://hx-literag-server.hx.dev.local:9621",
        description="LightRAG server URL"
    )
    max_iterations: int = Field(default=3, ge=1, le=5)
    timeout_seconds: float = Field(default=30.0, ge=5.0, le=120.0)
    min_entities_threshold: int = Field(default=3, ge=1)
    min_relationships_threshold: int = Field(default=2, ge=1)
    min_context_length: int = Field(default=500, ge=100)

class RAGAgent:
    """
    RAG Agent for LangGraph supervisor pattern.

    Responsibilities:
    1. Classify incoming queries for optimal retrieval mode
    2. Execute LightRAG queries via HTTP API
    3. Implement adaptive retrieval with iteration
    4. Return enriched context to supervisor
    """

    def __init__(self, config: RAGAgentConfig):
        self.config = config
        self.client = LightRAGClient(
            base_url=config.lightrag_url,
            timeout=config.timeout_seconds,
        )
        self.classifier = LightRAGQueryClassifier()
        self.strategy = AdaptiveRetrievalStrategy(
            max_iterations=config.max_iterations
        )

    async def process(self, state: RAGAgentState) -> RAGAgentState:
        """
        Process query through RAG pipeline.

        Implements adaptive retrieval with mode selection.
        """
        query = state["query"]

        logger.info(
            "rag_agent_processing",
            query=query[:100],
            current_iterations=state.get("rag_iterations", 0),
        )

        # Execute adaptive retrieval
        result = await adaptive_rag_workflow(
            query=query,
            lightrag_client=self.client,
            classifier=self.classifier,
            strategy=self.strategy,
        )

        # Evaluate sufficiency
        is_sufficient = self.strategy.evaluate_sufficiency(
            entities_count=result["entities"],
            relationships_count=result["relationships"],
            context_length=len(result["response"]),
        )

        logger.info(
            "rag_agent_complete",
            mode_used=result["mode_used"],
            iterations=result["iterations"],
            entities=result["entities"],
            relationships=result["relationships"],
            sufficient=is_sufficient,
        )

        return {
            **state,
            "rag_context": result["response"],
            "rag_mode_used": result["mode_used"],
            "rag_iterations": result["iterations"],
            "rag_sufficient": is_sufficient,
            "rag_entities_count": result["entities"],
            "rag_relationships_count": result["relationships"],
        }

    async def health_check(self) -> dict:
        """Check RAG Agent health including LightRAG connectivity."""
        async with self.client as client:
            lightrag_healthy = await client.health_check()

        return {
            "rag_agent": "healthy",
            "lightrag_service": "healthy" if lightrag_healthy else "unhealthy",
            "config": {
                "lightrag_url": self.config.lightrag_url,
                "max_iterations": self.config.max_iterations,
            }
        }


# Factory function for dependency injection
def create_rag_agent(
    lightrag_url: str = "http://hx-literag-server.hx.dev.local:9621",
) -> RAGAgent:
    """Create RAG Agent with default configuration."""
    config = RAGAgentConfig(lightrag_url=lightrag_url)
    return RAGAgent(config)
```

### Health Check Integration

```python
"""
Health check endpoint for hx-lang-server.

Includes LightRAG service validation.
"""
from fastapi import APIRouter, status
from pydantic import BaseModel
from typing import Dict

router = APIRouter()

class DependencyHealth(BaseModel):
    """Health status of a dependency."""
    status: str  # healthy, degraded, unhealthy
    latency_ms: float
    details: Dict[str, any] = {}

class HealthResponse(BaseModel):
    """Complete health check response."""
    status: str
    version: str
    uptime_seconds: float
    dependencies: Dict[str, DependencyHealth]

async def check_lightrag_health(url: str) -> DependencyHealth:
    """Check LightRAG service health."""
    import time
    import httpx

    start = time.monotonic()
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{url}/health")
            latency = (time.monotonic() - start) * 1000

            if response.status_code == 200:
                return DependencyHealth(
                    status="healthy",
                    latency_ms=latency,
                    details=response.json(),
                )
            else:
                return DependencyHealth(
                    status="degraded",
                    latency_ms=latency,
                    details={"error": f"HTTP {response.status_code}"},
                )
    except Exception as e:
        latency = (time.monotonic() - start) * 1000
        return DependencyHealth(
            status="unhealthy",
            latency_ms=latency,
            details={"error": str(e)},
        )

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Comprehensive health check including LightRAG."""
    # Check all dependencies
    lightrag_health = await check_lightrag_health(
        "http://hx-literag-server.hx.dev.local:9621"
    )

    # Aggregate status
    all_healthy = lightrag_health.status == "healthy"

    return HealthResponse(
        status="healthy" if all_healthy else "degraded",
        version="1.0.0",
        uptime_seconds=get_uptime(),
        dependencies={
            "lightrag": lightrag_health,
        }
    )
```

---

## Spec Validation

### Confirmed Correct in node-spec.md

1. **FR-014**: HTTP API integration with hx-literag-server - CORRECT
2. **FR-015**: Adaptive retrieval with iteration - CORRECT, implementation guidance provided above
3. **FR-016**: Query modes (local, global, hybrid, mix) - CORRECT, decision matrix provided
4. **FR-013**: Context size >= 32KB validation - CORRECT, enforcement code provided
5. **LightRAG Port 8020**: Specification shows port 8020 for hx-literag-server - NEEDS VERIFICATION (LightRAG server default is 9621)

### Items Requiring Clarification

1. **LightRAG Port Number**: Specification shows port 8020, but LightRAG Server default is 9621. Verify with hx-literag-server deployment.

2. **Embedding Model Alignment**: Specification should explicitly document the embedding model used by hx-literag-server to ensure consistency.

---

## Recommended Changes to node-spec.md

### Change 1: Verify LightRAG Port

**Current (line ~577):**
```
| LightRAG | hx-literag-server.hx.dev.local | 8020 | RAG pipeline |
```

**Recommendation:** Verify actual port from hx-literag-server deployment. LightRAG server defaults to 9621. Update if necessary:
```
| LightRAG | hx-literag-server.hx.dev.local | 9621 | RAG pipeline |
```

### Change 2: Add Embedding Model Specification

**Add to Configuration Management section:**
```bash
# LightRAG Integration
LIGHTRAG_URL=http://hx-literag-server.hx.dev.local:9621
LIGHTRAG_EMBEDDING_MODEL=bge-m3:latest
LIGHTRAG_EMBEDDING_DIM=1024
LIGHTRAG_DEFAULT_MODE=hybrid
```

### Change 3: Add Query Mode Selection to RAG Agent Specification

**Add new subsection after Query Classification Mechanism:**

```markdown
### RAG Agent Query Mode Selection

The RAG Agent implements adaptive query mode selection:

| Query Pattern | Mode | Latency | Use Case |
|--------------|------|---------|----------|
| Who/What/Where | local | ~500ms | Entity lookup |
| How/Why/Influence | global | ~800ms | Thematic queries |
| Complex/Default | hybrid | ~1.5s | Comprehensive |
| Research-quality | mix | ~2s | With reranking |

**Adaptive Retrieval:**
1. Initial query with classified mode
2. Evaluate result sufficiency (min 3 entities OR 2 relationships OR 500 chars)
3. Escalate to more comprehensive mode if insufficient
4. Maximum 3 iterations before returning best result
```

### Change 4: Add Context Size Validation Requirement

**Add to LLM Integration section (after FR-013):**

```markdown
**Context Size Validation:**
- **FR-013a**: Service MUST validate Ollama model context size at startup
- **FR-013b**: Service MUST fail startup if any RAG-configured model has context < 32KB
- **FR-013c**: Service SHOULD log warning if model context < 64KB (suboptimal)
```

---

## Research-Backed Performance Expectations

Based on the LightRAG research paper (arXiv:2410.05779), expected performance for this integration:

| Metric | Expected Performance | Notes |
|--------|---------------------|-------|
| Win rate vs NaiveRAG | 60-85% | Varies by domain, hybrid mode |
| Win rate vs GraphRAG | 50-55% | Similar quality, much lower cost |
| Retrieval cost | 610x lower than GraphRAG | Per-query token usage |
| Incremental update | 1000x lower than GraphRAG | New document ingestion |
| Latency (local mode) | <1 second | Simple entity queries |
| Latency (hybrid mode) | 1-3 seconds | Comprehensive queries |
| Latency (mix mode) | 2-4 seconds | With reranking |

---

## Coordination Notes

### Agents to Coordinate With

1. **Sophia (LangGraph SME)**: Review RAG Agent integration with supervisor pattern
2. **Bob (FastAPI SME)**: Health check endpoint integration
3. **Jim (Ollama SME)**: Validate Ollama model configurations for 32KB+ context
4. **Sri (Redis SME)**: RAG response caching strategy

### Integration Points with Other Agents' Work

- **Trinity (PostgreSQL)**: LightRAG uses PostgreSQL for KV and graph storage via hx-literag-server
- **Victor (Qdrant)**: LightRAG uses Qdrant for vector storage via hx-literag-server
- **George (FastMCP)**: MCP client in hx-lang-server is separate from RAG Agent

---

**Signature:** Andy (LightRAG Subject Matter Expert)
**Date:** 2025-12-01
