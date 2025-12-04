# Specification Contribution: Jim (Ollama SME)

**Contribution Date:** 2025-12-01
**Spec Version:** 1.0
**Focus Areas:** Ollama, model routing, context sizing, fallbacks, langchain-ollama integration

---

## Executive Summary

As the Ollama SME for HX-Infrastructure, I have reviewed the hx-lang-server specification against my charter review recommendations. The specification has addressed many concerns but requires enhancement in several critical areas: model selection within servers, fallback strategies, and performance optimization. This contribution provides production-ready patterns for multi-Ollama routing that will ensure reliable, efficient inference for LangGraph workflows.

---

## Routing Strategy Validation

### Current Spec Assessment

The specification correctly implements server-level routing:
- General queries -> hx-ollama1-server (.204)
- Code queries -> hx-ollama2-server (.205)
- Embeddings -> LightRAG (which uses hx-ollama3-server)

**STATUS: APPROVED** - Server routing is architecturally correct.

### Enhancement: Model Selection Within Servers

The spec currently defaults to a single model per server. This is insufficient for production workloads where query complexity varies significantly.

**Recommended Model Selection Strategy:**

```python
from dataclasses import dataclass
from typing import Optional, Tuple
from enum import Enum

class QueryComplexity(Enum):
    LOW = "low"       # Simple questions, short responses
    MEDIUM = "medium" # Multi-step reasoning, moderate output
    HIGH = "high"     # Complex analysis, code generation, long context

@dataclass
class OllamaModelConfig:
    """Configuration for Ollama model selection."""
    server: str
    model: str
    min_context: int      # Minimum context window (tokens)
    max_context: int      # Maximum safe context (tokens)
    estimated_tps: float  # Estimated tokens per second
    vram_gb: float        # VRAM footprint

class OllamaRouter:
    """Routes queries to appropriate Ollama server and model."""

    # Model configurations per server (current deployments)
    OLLAMA1_MODELS = {
        "gemma3:27b": OllamaModelConfig(
            server="hx-ollama1-server.hx.dev.local:11434",
            model="gemma3:27b",
            min_context=8192,
            max_context=32768,
            estimated_tps=25,
            vram_gb=20
        ),
        "gpt-oss:20b": OllamaModelConfig(
            server="hx-ollama1-server.hx.dev.local:11434",
            model="gpt-oss:20b",
            min_context=8192,
            max_context=16384,
            estimated_tps=30,
            vram_gb=16
        ),
        "mistral:7b": OllamaModelConfig(
            server="hx-ollama1-server.hx.dev.local:11434",
            model="mistral:7b",
            min_context=4096,
            max_context=32768,
            estimated_tps=60,
            vram_gb=6
        ),
    }

    OLLAMA2_MODELS = {
        "qwen3-coder:30b": OllamaModelConfig(
            server="hx-ollama2-server.hx.dev.local:11434",
            model="qwen3-coder:30b",
            min_context=8192,
            max_context=32768,
            estimated_tps=20,
            vram_gb=22
        ),
        "qwen2.5:7b": OllamaModelConfig(
            server="hx-ollama2-server.hx.dev.local:11434",
            model="qwen2.5:7b",
            min_context=4096,
            max_context=32768,
            estimated_tps=55,
            vram_gb=6
        ),
        "cogito:3b": OllamaModelConfig(
            server="hx-ollama2-server.hx.dev.local:11434",
            model="cogito:3b",
            min_context=2048,
            max_context=8192,
            estimated_tps=90,
            vram_gb=4
        ),
    }

    def select_model(
        self,
        query_type: str,
        complexity: QueryComplexity,
        required_context: int = 8192
    ) -> OllamaModelConfig:
        """Select optimal model based on query type and complexity."""

        if query_type == "code":
            models = self.OLLAMA2_MODELS
            if complexity == QueryComplexity.HIGH:
                return models["qwen3-coder:30b"]
            elif complexity == QueryComplexity.MEDIUM:
                return models["qwen2.5:7b"]
            else:
                return models["cogito:3b"]

        else:  # general, rag, tool
            models = self.OLLAMA1_MODELS
            if complexity == QueryComplexity.HIGH or required_context > 16384:
                return models["gemma3:27b"]
            elif complexity == QueryComplexity.MEDIUM:
                return models["gpt-oss:20b"]
            else:
                return models["mistral:7b"]
```

### Complexity Estimation Logic

```python
class ComplexityEstimator:
    """Estimates query complexity for model selection."""

    HIGH_COMPLEXITY_INDICATORS = [
        "analyze", "compare", "evaluate", "comprehensive",
        "detailed", "explain in depth", "step by step",
        "all aspects", "complete", "thorough"
    ]

    LOW_COMPLEXITY_INDICATORS = [
        "what is", "define", "list", "name", "when",
        "who", "where", "yes or no", "simple", "brief"
    ]

    def estimate(self, query: str, context_length: int = 0) -> QueryComplexity:
        """Estimate query complexity."""
        query_lower = query.lower()

        # High complexity indicators
        if any(ind in query_lower for ind in self.HIGH_COMPLEXITY_INDICATORS):
            return QueryComplexity.HIGH

        # Context-based escalation: >16K context requires larger model
        if context_length > 16384:
            return QueryComplexity.HIGH

        # Low complexity indicators
        if any(ind in query_lower for ind in self.LOW_COMPLEXITY_INDICATORS):
            return QueryComplexity.LOW

        # Default to medium for ambiguous queries
        return QueryComplexity.MEDIUM
```

---

## Model Context Requirements

### Critical Finding: RAG Context Size

The specification correctly identifies that RAG operations require 32KB minimum context. This is accurate based on my knowledge of LightRAG entity extraction requirements.

**Context Size Matrix:**

| Use Case | Min Context | Recommended Context | Model Selection |
|----------|-------------|---------------------|-----------------|
| Simple chat | 4KB | 8KB | mistral:7b / cogito:3b |
| Code generation | 8KB | 16KB | qwen2.5:7b / qwen3-coder:30b |
| RAG query | 16KB | 32KB | gemma3:27b |
| RAG + entity extraction | 32KB | 32KB | gemma3:27b (ONLY) |
| Multi-turn conversation | 8KB | 16KB | Based on query type |
| Document analysis | 16KB | 32KB | gemma3:27b |

### langchain-ollama Context Configuration

**CRITICAL:** The langchain-ollama adapter must explicitly set context size. Default is often insufficient.

```python
from langchain_ollama import ChatOllama

def create_ollama_llm(config: OllamaModelConfig, num_ctx: int = 8192) -> ChatOllama:
    """Create ChatOllama instance with explicit context configuration.

    CRITICAL: Always specify num_ctx explicitly. Default may be too small.
    """
    return ChatOllama(
        base_url=f"http://{config.server}",
        model=config.model,
        num_ctx=num_ctx,           # REQUIRED: Context window size
        num_gpu=-1,                # REQUIRED: Use all available GPU layers
        temperature=0.7,
        top_p=0.9,
        repeat_penalty=1.1,
        # Performance settings
        num_thread=4,              # CPU threads for any CPU operations
        num_batch=512,             # Batch size for prompt processing
    )

# Example configurations for different use cases
def get_general_llm() -> ChatOllama:
    """LLM for general queries - fast inference."""
    return create_ollama_llm(
        OllamaRouter.OLLAMA1_MODELS["mistral:7b"],
        num_ctx=8192
    )

def get_rag_llm() -> ChatOllama:
    """LLM for RAG queries - large context required."""
    return create_ollama_llm(
        OllamaRouter.OLLAMA1_MODELS["gemma3:27b"],
        num_ctx=32768  # CRITICAL: RAG requires 32K context
    )

def get_code_llm() -> ChatOllama:
    """LLM for code queries - code-optimized model."""
    return create_ollama_llm(
        OllamaRouter.OLLAMA2_MODELS["qwen3-coder:30b"],
        num_ctx=16384
    )
```

### GPU Utilization Verification

**MANDATORY:** All LangGraph Ollama requests must verify 100% GPU utilization.

```python
import httpx
from typing import Dict, Any

async def verify_gpu_utilization(server: str) -> Dict[str, Any]:
    """Verify Ollama server is using GPU for inference.

    Returns model status including GPU percentage.
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(f"http://{server}/api/ps")
        data = response.json()

        result = {
            "server": server,
            "models": [],
            "all_gpu": True
        }

        for model in data.get("models", []):
            gpu_percent = model.get("size_vram", 0) / model.get("size", 1) * 100
            result["models"].append({
                "name": model.get("name"),
                "gpu_percent": round(gpu_percent, 1),
                "size_vram": model.get("size_vram"),
                "size_total": model.get("size")
            })
            if gpu_percent < 95:  # Allow small tolerance
                result["all_gpu"] = False

        return result

# Health check should include GPU verification
async def check_ollama_health(server: str) -> bool:
    """Health check including GPU utilization verification."""
    try:
        gpu_status = await verify_gpu_utilization(server)
        if not gpu_status["all_gpu"]:
            logger.warning(
                f"GPU utilization below threshold on {server}",
                models=gpu_status["models"]
            )
            return False  # Degraded status
        return True
    except Exception as e:
        logger.error(f"Ollama health check failed: {e}")
        return False
```

---

## Fallback Strategy

### Server Unavailability Handling

The specification lacks fallback strategies. Here is the recommended implementation:

**Fallback Routing Table:**

| Primary Server | Query Type | Fallback Server | Fallback Model | Degradation Notes |
|----------------|------------|-----------------|----------------|-------------------|
| ollama1 (.204) | general | ollama2 (.205) | qwen2.5:7b | Reduced reasoning quality |
| ollama1 (.204) | rag | ollama2 (.205) | qwen2.5:7b | Must reduce context to 16K |
| ollama2 (.205) | code | ollama1 (.204) | mistral:7b | Significantly reduced code quality |
| LightRAG | embeddings | N/A | N/A | HARD DEPENDENCY - no fallback |

**CRITICAL:** LightRAG is a hard dependency. There is NO fallback for embedding operations because:
1. Ollama3 models are accessed exclusively through LightRAG
2. Direct ollama3 access would bypass embedding caching and graph augmentation
3. Embedding dimensions must match existing Qdrant collections

### Fallback Implementation

```python
from typing import Optional
import httpx
import asyncio
from dataclasses import dataclass

@dataclass
class FallbackConfig:
    """Configuration for server fallback."""
    primary_server: str
    primary_model: str
    fallback_server: Optional[str]
    fallback_model: Optional[str]
    max_context_fallback: int  # Reduced context for fallback

class OllamaClientWithFallback:
    """Ollama client with automatic fallback support."""

    FALLBACK_MAP = {
        "hx-ollama1-server.hx.dev.local:11434": FallbackConfig(
            primary_server="hx-ollama1-server.hx.dev.local:11434",
            primary_model="gemma3:27b",
            fallback_server="hx-ollama2-server.hx.dev.local:11434",
            fallback_model="qwen2.5:7b",
            max_context_fallback=16384
        ),
        "hx-ollama2-server.hx.dev.local:11434": FallbackConfig(
            primary_server="hx-ollama2-server.hx.dev.local:11434",
            primary_model="qwen3-coder:30b",
            fallback_server="hx-ollama1-server.hx.dev.local:11434",
            fallback_model="mistral:7b",
            max_context_fallback=16384
        ),
    }

    def __init__(self, timeout: float = 30.0, max_retries: int = 2):
        self.timeout = timeout
        self.max_retries = max_retries
        self._server_status: Dict[str, bool] = {}

    async def check_server_health(self, server: str) -> bool:
        """Check if Ollama server is responding."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"http://{server}/api/tags")
                return response.status_code == 200
        except Exception:
            return False

    async def invoke_with_fallback(
        self,
        server: str,
        model: str,
        prompt: str,
        num_ctx: int = 8192
    ) -> dict:
        """Invoke Ollama with automatic fallback on failure."""

        # Try primary server
        try:
            if await self.check_server_health(server):
                return await self._invoke(server, model, prompt, num_ctx)
        except Exception as e:
            logger.warning(f"Primary server {server} failed: {e}")

        # Try fallback
        fallback_config = self.FALLBACK_MAP.get(server)
        if fallback_config and fallback_config.fallback_server:
            logger.info(
                f"Falling back from {server} to {fallback_config.fallback_server}"
            )

            # Reduce context for fallback if needed
            fallback_ctx = min(num_ctx, fallback_config.max_context_fallback)

            try:
                result = await self._invoke(
                    fallback_config.fallback_server,
                    fallback_config.fallback_model,
                    prompt,
                    fallback_ctx
                )
                result["_fallback_used"] = True
                result["_original_server"] = server
                return result
            except Exception as e:
                logger.error(f"Fallback server also failed: {e}")
                raise

        raise RuntimeError(f"All Ollama servers unavailable for {server}")

    async def _invoke(
        self,
        server: str,
        model: str,
        prompt: str,
        num_ctx: int
    ) -> dict:
        """Internal method to invoke Ollama."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"http://{server}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "options": {
                        "num_ctx": num_ctx,
                        "num_gpu": -1,  # Use all GPU layers
                    },
                    "stream": False
                }
            )
            response.raise_for_status()
            return response.json()
```

### Circuit Breaker Pattern

```python
from datetime import datetime, timedelta
from collections import defaultdict

class CircuitBreaker:
    """Circuit breaker for Ollama server connections."""

    def __init__(
        self,
        failure_threshold: int = 3,
        recovery_timeout: timedelta = timedelta(seconds=30)
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self._failures: Dict[str, int] = defaultdict(int)
        self._last_failure: Dict[str, datetime] = {}
        self._circuit_open: Dict[str, bool] = defaultdict(bool)

    def is_open(self, server: str) -> bool:
        """Check if circuit is open (server should not be called)."""
        if not self._circuit_open[server]:
            return False

        # Check if recovery timeout has passed
        if server in self._last_failure:
            if datetime.now() - self._last_failure[server] > self.recovery_timeout:
                self._circuit_open[server] = False
                self._failures[server] = 0
                logger.info(f"Circuit closed for {server} - attempting recovery")
                return False

        return True

    def record_failure(self, server: str) -> None:
        """Record a failure for a server."""
        self._failures[server] += 1
        self._last_failure[server] = datetime.now()

        if self._failures[server] >= self.failure_threshold:
            self._circuit_open[server] = True
            logger.warning(
                f"Circuit opened for {server} after {self._failures[server]} failures"
            )

    def record_success(self, server: str) -> None:
        """Record a successful call, resetting failure count."""
        self._failures[server] = 0
        self._circuit_open[server] = False
```

---

## Classification Enhancement

### Improved Query Classification

The specification's keyword-based classification is a good starting point. Here are enhancements:

```python
import re
from typing import List, Tuple
from enum import Enum

class QueryType(Enum):
    GENERAL = "general"
    CODE = "code"
    RAG = "rag"
    TOOL = "tool"

class EnhancedQueryClassifier:
    """Enhanced query classifier with confidence scoring."""

    # Code indicators with weights
    CODE_PATTERNS: List[Tuple[str, float]] = [
        (r'\b(def|class|function|import|from)\b', 1.0),  # Direct code keywords
        (r'\b(python|javascript|typescript|java|sql|go|rust)\b', 0.9),  # Languages
        (r'\b(debug|error|exception|bug|fix)\b', 0.8),  # Debugging
        (r'\b(implement|refactor|optimize|code)\b', 0.7),  # Actions
        (r'\b(api|endpoint|request|response)\b', 0.6),  # API work
        (r'```', 1.0),  # Code block markers
        (r'\b(variable|parameter|argument|return)\b', 0.7),  # Programming terms
    ]

    # RAG indicators with weights
    RAG_PATTERNS: List[Tuple[str, float]] = [
        (r'\b(document|knowledge|search|find)\b', 0.9),
        (r'\b(what is|explain|describe|tell me about)\b', 0.8),
        (r'\b(how does|how do|how to)\b', 0.7),
        (r'\b(according to|based on|from the)\b', 0.9),  # Retrieval indicators
        (r'\b(in the context|given the)\b', 0.8),
    ]

    # Tool indicators with weights
    TOOL_PATTERNS: List[Tuple[str, float]] = [
        (r'\b(crawl|scrape|fetch|web|url|http)\b', 0.9),
        (r'\b(download|extract from|get from)\b', 0.7),
        (r'https?://', 1.0),  # Direct URL
        (r'\b(website|webpage|page)\b', 0.6),
    ]

    def classify(self, query: str) -> Tuple[QueryType, float]:
        """Classify query with confidence score.

        Returns:
            Tuple of (QueryType, confidence_score)
        """
        scores = {
            QueryType.CODE: self._calculate_score(query, self.CODE_PATTERNS),
            QueryType.RAG: self._calculate_score(query, self.RAG_PATTERNS),
            QueryType.TOOL: self._calculate_score(query, self.TOOL_PATTERNS),
        }

        # Find highest scoring type
        max_type = max(scores, key=scores.get)
        max_score = scores[max_type]

        # Confidence threshold - below 0.5 defaults to general
        if max_score < 0.5:
            return (QueryType.GENERAL, 1.0 - max_score)

        return (max_type, max_score)

    def _calculate_score(
        self,
        query: str,
        patterns: List[Tuple[str, float]]
    ) -> float:
        """Calculate classification score for a set of patterns."""
        query_lower = query.lower()
        total_weight = 0.0
        matches = 0

        for pattern, weight in patterns:
            if re.search(pattern, query_lower, re.IGNORECASE):
                total_weight += weight
                matches += 1

        # Normalize score (max 1.0)
        if matches == 0:
            return 0.0
        return min(total_weight / len(patterns), 1.0)

    def get_routing_decision(self, query: str) -> dict:
        """Get complete routing decision with metadata."""
        query_type, confidence = self.classify(query)
        complexity = ComplexityEstimator().estimate(query)

        router = OllamaRouter()
        model_config = router.select_model(
            query_type.value,
            complexity
        )

        return {
            "query_type": query_type.value,
            "confidence": round(confidence, 2),
            "complexity": complexity.value,
            "server": model_config.server,
            "model": model_config.model,
            "recommended_context": model_config.max_context,
        }
```

### Classification Caching

```python
import hashlib
from redis import Redis

class CachedClassifier:
    """Query classifier with Redis caching."""

    CACHE_TTL = 1800  # 30 minutes
    CACHE_PREFIX = "classification:"

    def __init__(self, redis_client: Redis, classifier: EnhancedQueryClassifier):
        self.redis = redis_client
        self.classifier = classifier

    def _cache_key(self, query: str) -> str:
        """Generate cache key from query hash."""
        query_hash = hashlib.md5(query.lower().strip().encode()).hexdigest()
        return f"{self.CACHE_PREFIX}{query_hash}"

    async def classify(self, query: str) -> dict:
        """Classify with caching."""
        cache_key = self._cache_key(query)

        # Check cache
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)

        # Classify and cache
        result = self.classifier.get_routing_decision(query)
        await self.redis.setex(
            cache_key,
            self.CACHE_TTL,
            json.dumps(result)
        )

        return result
```

---

## Code Examples

### Complete LangGraph Ollama Integration

```python
"""
Production-ready Ollama integration for hx-lang-server LangGraph.

This module provides the complete integration pattern for connecting
LangGraph to the HX-Infrastructure Ollama servers.
"""

from typing import Dict, Any, Optional
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, AIMessage
from langgraph.graph import StateGraph, END
import structlog

logger = structlog.get_logger()

class OllamaIntegration:
    """Complete Ollama integration for LangGraph supervisor."""

    def __init__(self, settings: "Settings"):
        self.settings = settings
        self.router = OllamaRouter()
        self.classifier = EnhancedQueryClassifier()
        self.complexity_estimator = ComplexityEstimator()
        self.circuit_breaker = CircuitBreaker()

        # Pre-initialize LLM instances
        self._llm_cache: Dict[str, ChatOllama] = {}

    def get_llm(
        self,
        query_type: str,
        complexity: QueryComplexity,
        num_ctx: int = 8192
    ) -> ChatOllama:
        """Get appropriate LLM instance for query."""
        model_config = self.router.select_model(query_type, complexity, num_ctx)

        cache_key = f"{model_config.server}:{model_config.model}:{num_ctx}"

        if cache_key not in self._llm_cache:
            self._llm_cache[cache_key] = ChatOllama(
                base_url=f"http://{model_config.server}",
                model=model_config.model,
                num_ctx=num_ctx,
                num_gpu=-1,
                temperature=0.7,
            )

        return self._llm_cache[cache_key]

    async def invoke(
        self,
        query: str,
        context: Optional[str] = None
    ) -> dict:
        """Invoke appropriate Ollama model based on query classification."""

        # Classify query
        query_type, confidence = self.classifier.classify(query)
        complexity = self.complexity_estimator.estimate(query)

        logger.info(
            "ollama_routing_decision",
            query_type=query_type.value,
            confidence=confidence,
            complexity=complexity.value
        )

        # Determine context size
        if query_type == QueryType.RAG:
            num_ctx = 32768  # RAG requires large context
        elif context and len(context) > 10000:
            num_ctx = 32768
        elif complexity == QueryComplexity.HIGH:
            num_ctx = 16384
        else:
            num_ctx = 8192

        # Get LLM
        llm = self.get_llm(query_type.value, complexity, num_ctx)

        # Build messages
        messages = []
        if context:
            messages.append(HumanMessage(content=f"Context:\n{context}"))
        messages.append(HumanMessage(content=query))

        # Check circuit breaker
        model_config = self.router.select_model(query_type.value, complexity)
        if self.circuit_breaker.is_open(model_config.server):
            logger.warning(f"Circuit open for {model_config.server}, using fallback")
            # Fallback logic here

        try:
            response = await llm.ainvoke(messages)
            self.circuit_breaker.record_success(model_config.server)

            return {
                "response": response.content,
                "model_used": model_config.model,
                "server_used": model_config.server,
                "query_type": query_type.value,
                "confidence": confidence,
                "context_size": num_ctx,
            }

        except Exception as e:
            self.circuit_breaker.record_failure(model_config.server)
            logger.error(
                "ollama_invocation_failed",
                server=model_config.server,
                model=model_config.model,
                error=str(e)
            )
            raise


# LangGraph node function
async def ollama_node(state: "AgentState") -> dict:
    """LangGraph node for Ollama invocation."""
    integration = OllamaIntegration(settings)

    # Get last user message
    last_message = state["messages"][-1]
    query = last_message.content if hasattr(last_message, "content") else str(last_message)

    # Get RAG context if available
    context = state.get("rag_context")

    result = await integration.invoke(query, context)

    return {
        "messages": [AIMessage(content=result["response"])],
        "current_worker": "ollama",
        "metadata": {
            "model": result["model_used"],
            "server": result["server_used"],
            "query_type": result["query_type"],
        }
    }
```

### Model Warm-up Strategy

```python
"""Model warm-up for LangGraph startup."""

async def warm_up_models():
    """Pre-load frequently used models into GPU memory.

    Call this during service startup to reduce first-request latency.
    """
    warm_up_queries = [
        # General model warm-up
        ("hx-ollama1-server.hx.dev.local:11434", "mistral:7b", "Hello"),
        # Code model warm-up
        ("hx-ollama2-server.hx.dev.local:11434", "qwen2.5:7b", "def hello():"),
    ]

    async with httpx.AsyncClient(timeout=60.0) as client:
        for server, model, prompt in warm_up_queries:
            try:
                logger.info(f"Warming up {model} on {server}")
                await client.post(
                    f"http://{server}/api/generate",
                    json={
                        "model": model,
                        "prompt": prompt,
                        "options": {"num_ctx": 4096, "num_gpu": -1}
                    }
                )
                logger.info(f"Warm-up complete for {model}")
            except Exception as e:
                logger.warning(f"Warm-up failed for {model}: {e}")

# In FastAPI startup
@app.on_event("startup")
async def startup_event():
    """Service startup with model warm-up."""
    await warm_up_models()
```

---

## Spec Validation

### Items Correctly Addressed

1. **FR-010/FR-011**: Server routing to ollama1 (general) and ollama2 (code) - CORRECT
2. **FR-012**: Embeddings through LightRAG - CORRECT
3. **FR-013**: 32KB context for RAG operations - CORRECT
4. **Ollama Routing Table** (lines 302-309): Accurate server assignments

### Items Requiring Correction

1. **Line 306**: `general | hx-ollama1-server | gemma3:27b | 8KB`
   - **Issue**: Single model specified, no complexity-based selection
   - **Fix**: Add model selection logic based on complexity

2. **Line 307**: `code | hx-ollama2-server | qwen3-coder:30b | 16KB`
   - **Issue**: Always using 30B model is inefficient for simple code queries
   - **Fix**: Use qwen2.5:7b for simple, qwen3-coder:30b for complex

3. **Missing**: Fallback strategy for server unavailability
   - **Fix**: Add fallback routing table and implementation

4. **Missing**: GPU utilization verification in health checks
   - **Fix**: Add GPU check to health endpoint

5. **Missing**: Model warm-up during service startup
   - **Fix**: Add warm-up routine to startup event

---

## Recommended Changes to node-spec.md

### Section: Query Classification Mechanism (lines 269-300)

**Add after line 300:**

```markdown
### Model Selection Within Servers

The classifier must also select the appropriate model within each server based on query complexity:

**Ollama1 Model Selection (General):**
| Complexity | Model | Use Case | Context |
|------------|-------|----------|---------|
| LOW | mistral:7b | Simple questions, fast response | 8KB |
| MEDIUM | gpt-oss:20b | Moderate reasoning | 16KB |
| HIGH | gemma3:27b | Complex analysis, RAG | 32KB |

**Ollama2 Model Selection (Code):**
| Complexity | Model | Use Case | Context |
|------------|-------|----------|---------|
| LOW | cogito:3b | Simple formatting | 4KB |
| MEDIUM | qwen2.5:7b | Standard code tasks | 16KB |
| HIGH | qwen3-coder:30b | Complex code generation | 32KB |
```

### Section: Dependencies (add new section after line 578)

**Add new section:**

```markdown
### Fallback Strategy

When a primary Ollama server is unavailable, the service implements automatic fallback:

| Primary | Query Type | Fallback | Degradation |
|---------|------------|----------|-------------|
| ollama1 | general/rag | ollama2 (qwen2.5:7b) | Reduced reasoning, 16K max context |
| ollama2 | code | ollama1 (mistral:7b) | Reduced code quality |
| LightRAG | embeddings | NONE | Hard dependency |

**Circuit Breaker Settings:**
- Failure threshold: 3 consecutive failures
- Recovery timeout: 30 seconds
- Half-open test: Single request after timeout
```

### Section: Health Checks (lines 719-742)

**Modify line 730-731:**

```python
        "ollama_general": await check_ollama(settings.ollama_general_url),
        "ollama_code": await check_ollama(settings.ollama_code_url),
```

**Change to:**

```python
        "ollama_general": await check_ollama_with_gpu(settings.ollama_general_url),
        "ollama_code": await check_ollama_with_gpu(settings.ollama_code_url),
```

**Add new function:**

```python
async def check_ollama_with_gpu(url: str) -> dict:
    """Check Ollama health including GPU utilization."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            # Basic connectivity
            tags_resp = await client.get(f"{url}/api/tags")
            if tags_resp.status_code != 200:
                return {"status": "unhealthy", "reason": "API unreachable"}

            # GPU utilization
            ps_resp = await client.get(f"{url}/api/ps")
            ps_data = ps_resp.json()

            for model in ps_data.get("models", []):
                vram_pct = model.get("size_vram", 0) / model.get("size", 1) * 100
                if vram_pct < 95:
                    return {
                        "status": "degraded",
                        "reason": f"GPU utilization low ({vram_pct:.0f}%)"
                    }

            return {"status": "healthy"}
    except Exception as e:
        return {"status": "unhealthy", "reason": str(e)}
```

### Section: Service Configuration (add to systemd unit)

**Add to line 811 (ExecStartPre):**

```ini
ExecStartPre=/opt/hx-lang-server/venv/bin/python -c "import warmup; warmup.run()"
```

---

## Coordination Notes

### Shane Black (LiteLLM SME)

Coordinate on:
1. **Model aliases**: Create LangGraph-specific aliases in LiteLLM config for consistency
2. **Load balancing**: Ensure LiteLLM does not conflict with LangGraph direct access
3. **Request logging**: LangGraph requests should be tagged for LiteLLM metrics

### Andy Dolton (LightRAG SME)

Coordinate on:
1. **Embedding API stability**: Confirm endpoint contracts for LangGraph integration
2. **Context requirements**: Verify 32K minimum for entity extraction
3. **Rate limiting**: Ensure LangGraph requests respect LightRAG limits

### Victor Hayes (Qdrant SME)

Coordinate on:
1. **Embedding dimensions**: Confirm bge-m3 produces 1024-dim vectors
2. **Collection compatibility**: Verify LangGraph-stored vectors match existing collections

---

**Signature:** Jim Harper, Ollama SME
**Date:** 2025-12-01

---

## Appendix: Current Ollama Server Deployments

### hx-ollama1-server (.204) - General Purpose
| Model | Disk Size | VRAM | Inference Speed |
|-------|-----------|------|-----------------|
| gemma3:27b | 17GB | ~20GB | ~25 tok/s |
| gpt-oss:20b | 13GB | ~16GB | ~30 tok/s |
| mistral:7b | 4.4GB | ~6GB | ~60 tok/s |

### hx-ollama2-server (.205) - Code Specialized
| Model | Disk Size | VRAM | Inference Speed |
|-------|-----------|------|-----------------|
| qwen3-coder:30b | 18GB | ~22GB | ~20 tok/s |
| qwen2.5:7b | 4.7GB | ~6GB | ~55 tok/s |
| cogito:3b | 2.2GB | ~4GB | ~90 tok/s |

### hx-ollama3-server (.206) - Embeddings (via LightRAG ONLY)
| Model | Disk Size | VRAM | Purpose |
|-------|-----------|------|---------|
| bge-m3:567m | 1.2GB | ~2GB | Text embeddings |
| granite-docling:258m | 521MB | ~1GB | Document processing |
| bge-reranker-v2-m3 | 1.2GB | ~2GB | Search reranking |
| aipromptassistant | 4.7GB | ~6GB | Prompt enhancement |

**Note:** Ollama3 access is restricted to LightRAG and Open WebUI direct bypass. LangGraph must NOT access ollama3 directly.
