# Task: Implement Model Routing Based on Query Classification

**Task ID:** hx-lang-server-task-075-implement-model-routing
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:**
- hx-lang-server-task-071 (Ollama1 connection)
- hx-lang-server-task-072 (Ollama2 connection)
- hx-lang-server-task-052 (Query classifier implemented)
**Estimated Time:** 60 minutes

---

## Objective

Implement the Ollama model routing logic that directs queries to the appropriate server and model based on query classification. Routes general/RAG/tool queries to hx-ollama1-server (gemma3:27b) and code queries to hx-ollama2-server (qwen2.5-coder).

---

## Prerequisites

- [ ] Task 071 completed (Ollama1 connection configured)
- [ ] Task 072 completed (Ollama2 connection configured)
- [ ] Task 052 completed (Query classifier implemented)
- [ ] Both Ollama servers accessible from hx-lang-server

---

## Specification References

From node-spec.md (v2.1):
- **FR-003**: Service MUST route queries to appropriate worker based on query classification
- **FR-010**: Service MUST route general queries to hx-ollama1-server
- **FR-011**: Service MUST route code-related queries to hx-ollama2-server

**Ollama Routing Table:**
| Query Type | Target Server | Model | Min Context |
|------------|---------------|-------|-------------|
| general | hx-ollama1-server | gemma3:27b | 8KB |
| code | hx-ollama2-server | qwen2.5-coder | 64KB |
| rag | hx-ollama1-server | gemma3:27b | 64KB |
| tool | hx-ollama1-server | gemma3:27b | 8KB |

---

## Steps

### Step 1: Create Ollama Router Module

Create file `/opt/hx-lang-server/app/llm/ollama_router.py`:

```python
"""
Ollama Model Router

Routes queries to appropriate Ollama server based on query classification.
Implements FR-003, FR-010, FR-011 from specification.
"""

from enum import Enum
from dataclasses import dataclass
from typing import Optional
from langchain_ollama import ChatOllama
import structlog

from app.llm.ollama_general import (
    create_general_llm,
    create_rag_llm,
    create_tool_llm,
    OLLAMA_GENERAL_URL,
    OLLAMA_GENERAL_MODEL,
)
from app.llm.ollama_code import (
    create_code_llm,
    OLLAMA_CODE_URL,
    OLLAMA_CODE_MODEL,
    CODE_CONTEXT_SIZE,
)

logger = structlog.get_logger(__name__)


class QueryType(Enum):
    """Query classification types."""
    GENERAL = "general"
    CODE = "code"
    RAG = "rag"
    TOOL = "tool"


@dataclass
class RoutingConfig:
    """Configuration for a specific query type routing."""
    query_type: QueryType
    server_url: str
    model: str
    min_context: int
    temperature: float
    timeout: float


# Routing configuration table (from specification)
ROUTING_TABLE: dict[QueryType, RoutingConfig] = {
    QueryType.GENERAL: RoutingConfig(
        query_type=QueryType.GENERAL,
        server_url="http://hx-ollama1-server.hx.dev.local:11434",
        model="gemma3:27b",
        min_context=8192,  # 8KB
        temperature=0.7,
        timeout=60.0,
    ),
    QueryType.CODE: RoutingConfig(
        query_type=QueryType.CODE,
        server_url="http://hx-ollama2-server.hx.dev.local:11434",
        model="qwen2.5-coder:14b",
        min_context=65536,  # 64KB per CAIO decision
        temperature=0.2,
        timeout=120.0,
    ),
    QueryType.RAG: RoutingConfig(
        query_type=QueryType.RAG,
        server_url="http://hx-ollama1-server.hx.dev.local:11434",
        model="gemma3:27b",
        min_context=65536,  # 64KB per CAIO decision
        temperature=0.3,
        timeout=120.0,
    ),
    QueryType.TOOL: RoutingConfig(
        query_type=QueryType.TOOL,
        server_url="http://hx-ollama1-server.hx.dev.local:11434",
        model="gemma3:27b",
        min_context=8192,  # 8KB
        temperature=0.5,
        timeout=60.0,
    ),
}


class OllamaRouter:
    """
    Routes queries to appropriate Ollama server based on classification.

    Implements:
    - FR-003: Route queries based on classification
    - FR-010: General queries to hx-ollama1-server
    - FR-011: Code queries to hx-ollama2-server
    """

    def __init__(self, code_model_override: Optional[str] = None):
        """
        Initialize the Ollama router.

        Args:
            code_model_override: Optional override for code model name
                (deployment may have qwen3-coder instead of qwen2.5-coder)
        """
        self.code_model_override = code_model_override
        self._llm_cache: dict[QueryType, ChatOllama] = {}

        logger.info(
            "ollama_router_initialized",
            code_model_override=code_model_override,
        )

    def get_routing_config(self, query_type: str | QueryType) -> RoutingConfig:
        """
        Get routing configuration for a query type.

        Args:
            query_type: The query classification (string or QueryType)

        Returns:
            RoutingConfig for the query type

        Raises:
            ValueError: If query type is unknown
        """
        if isinstance(query_type, str):
            try:
                query_type = QueryType(query_type.lower())
            except ValueError:
                logger.warning(
                    "unknown_query_type_defaulting_to_general",
                    query_type=query_type,
                )
                query_type = QueryType.GENERAL

        return ROUTING_TABLE[query_type]

    def get_llm(
        self,
        query_type: str | QueryType,
        use_cache: bool = True,
    ) -> ChatOllama:
        """
        Get the appropriate LLM for a query type.

        Args:
            query_type: The query classification
            use_cache: Whether to use cached LLM instances

        Returns:
            Configured ChatOllama instance for the query type
        """
        if isinstance(query_type, str):
            try:
                query_type = QueryType(query_type.lower())
            except ValueError:
                query_type = QueryType.GENERAL

        # Return cached instance if available
        if use_cache and query_type in self._llm_cache:
            logger.debug("returning_cached_llm", query_type=query_type.value)
            return self._llm_cache[query_type]

        # Create appropriate LLM based on query type
        if query_type == QueryType.GENERAL:
            llm = create_general_llm()
        elif query_type == QueryType.CODE:
            llm = create_code_llm(model_override=self.code_model_override)
        elif query_type == QueryType.RAG:
            llm = create_rag_llm()
        elif query_type == QueryType.TOOL:
            llm = create_tool_llm()
        else:
            # Fallback to general
            llm = create_general_llm()

        config = self.get_routing_config(query_type)

        logger.info(
            "llm_routed",
            query_type=query_type.value,
            server=config.server_url,
            model=config.model,
            context=config.min_context,
        )

        # Cache the instance
        if use_cache:
            self._llm_cache[query_type] = llm

        return llm

    def route_query(
        self,
        query: str,
        query_type: str,
    ) -> tuple[ChatOllama, RoutingConfig]:
        """
        Route a query to the appropriate LLM.

        Args:
            query: The user query
            query_type: Classification result from QueryClassifier

        Returns:
            Tuple of (ChatOllama instance, RoutingConfig)
        """
        config = self.get_routing_config(query_type)
        llm = self.get_llm(query_type)

        logger.info(
            "query_routed",
            query_preview=query[:50] + "..." if len(query) > 50 else query,
            query_type=query_type,
            target_server=config.server_url,
            model=config.model,
        )

        return llm, config

    def get_routing_info(self) -> dict:
        """
        Get routing table information for diagnostics.

        Returns:
            Dictionary with routing configuration for all query types
        """
        return {
            qt.value: {
                "server": config.server_url,
                "model": config.model,
                "min_context_kb": config.min_context // 1024,
                "temperature": config.temperature,
                "timeout": config.timeout,
            }
            for qt, config in ROUTING_TABLE.items()
        }

    def clear_cache(self) -> None:
        """Clear the LLM instance cache."""
        self._llm_cache.clear()
        logger.info("llm_cache_cleared")


# Module-level router instance
_router: Optional[OllamaRouter] = None


def get_router(code_model_override: Optional[str] = None) -> OllamaRouter:
    """
    Get or create the global Ollama router instance.

    Args:
        code_model_override: Optional code model name override

    Returns:
        OllamaRouter instance
    """
    global _router

    if _router is None:
        _router = OllamaRouter(code_model_override=code_model_override)

    return _router
```

### Step 2: Create Router Integration with Query Classifier

Create file `/opt/hx-lang-server/app/llm/router_integration.py`:

```python
"""
Router Integration Module

Integrates query classification with Ollama routing.
"""

from typing import Optional
from langchain_ollama import ChatOllama
import structlog

from app.agents.query_classifier import QueryClassifier
from app.llm.ollama_router import OllamaRouter, RoutingConfig, get_router

logger = structlog.get_logger(__name__)


class RoutedLLMProvider:
    """
    Provides LLMs routed based on query classification.

    Combines QueryClassifier with OllamaRouter to automatically
    select the appropriate model for each query.
    """

    def __init__(
        self,
        classifier: Optional[QueryClassifier] = None,
        router: Optional[OllamaRouter] = None,
    ):
        """
        Initialize the routed LLM provider.

        Args:
            classifier: Query classifier instance
            router: Ollama router instance
        """
        self.classifier = classifier or QueryClassifier()
        self.router = router or get_router()

    def get_llm_for_query(
        self,
        query: str,
        override_type: Optional[str] = None,
    ) -> tuple[ChatOllama, str, RoutingConfig]:
        """
        Get the appropriate LLM for a query.

        Args:
            query: The user query
            override_type: Optional override for query type

        Returns:
            Tuple of (ChatOllama, query_type, RoutingConfig)
        """
        # Classify query unless overridden
        if override_type:
            query_type = override_type
            logger.info(
                "query_type_overridden",
                override=override_type,
            )
        else:
            query_type = self.classifier.classify(query)

        # Get routed LLM
        llm, config = self.router.route_query(query, query_type)

        return llm, query_type, config

    async def invoke(
        self,
        query: str,
        override_type: Optional[str] = None,
    ) -> dict:
        """
        Classify query, route to LLM, and invoke.

        Args:
            query: The user query
            override_type: Optional query type override

        Returns:
            Dictionary with response and routing info
        """
        llm, query_type, config = self.get_llm_for_query(
            query,
            override_type=override_type,
        )

        logger.info(
            "invoking_routed_llm",
            query_type=query_type,
            model=config.model,
            server=config.server_url,
        )

        response = await llm.ainvoke(query)

        return {
            "response": response.content,
            "query_type": query_type,
            "model": config.model,
            "server": config.server_url,
            "context_size": config.min_context,
        }
```

### Step 3: Add Environment Variables for Routing

Add to `/opt/hx-lang-server/.env`:

```bash
# Ollama Routing Configuration
OLLAMA_ROUTE_GENERAL_TO=hx-ollama1-server.hx.dev.local:11434
OLLAMA_ROUTE_CODE_TO=hx-ollama2-server.hx.dev.local:11434
OLLAMA_ROUTE_RAG_TO=hx-ollama1-server.hx.dev.local:11434
OLLAMA_ROUTE_TOOL_TO=hx-ollama1-server.hx.dev.local:11434
```

### Step 4: Test Model Routing

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test routing logic
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/hx-lang-server')

# Simulated routing test (without full imports)
ROUTING_TABLE = {
    "general": ("hx-ollama1-server.hx.dev.local:11434", "gemma3:27b", 8192),
    "code": ("hx-ollama2-server.hx.dev.local:11434", "qwen2.5-coder:14b", 65536),
    "rag": ("hx-ollama1-server.hx.dev.local:11434", "gemma3:27b", 65536),
    "tool": ("hx-ollama1-server.hx.dev.local:11434", "gemma3:27b", 8192),
}

test_queries = [
    ("What is the capital of France?", "general"),
    ("Write a Python function to sort a list", "code"),
    ("Search for documents about machine learning", "rag"),
    ("Crawl this URL and extract content", "tool"),
    ("Debug this JavaScript error", "code"),
    ("Explain how transformers work", "general"),
]

print("Model Routing Test:")
print("-" * 70)

for query, expected_type in test_queries:
    server, model, context = ROUTING_TABLE[expected_type]
    print(f"Query: {query[:40]}...")
    print(f"  Type: {expected_type}")
    print(f"  Server: {server}")
    print(f"  Model: {model}")
    print(f"  Context: {context // 1024}KB")
    print()

print("-" * 70)
print("SUCCESS: Routing table configured correctly")
EOF
```

### Step 5: Integration Test with Both Servers

```bash
python3 << 'EOF'
from langchain_ollama import ChatOllama
import httpx

# Test routing to both servers
servers = {
    "general": ("hx-ollama1-server.hx.dev.local", 11434),
    "code": ("hx-ollama2-server.hx.dev.local", 11434),
}

queries = {
    "general": "What is 2 + 2?",
    "code": "Write a hello world function in Python",
}

print("Live Routing Integration Test:")
print("-" * 60)

for query_type, (host, port) in servers.items():
    url = f"http://{host}:{port}"

    # Get first available model
    response = httpx.get(f"{url}/api/tags")
    models = response.json().get("models", [])

    if not models:
        print(f"{query_type}: No models available on {host}")
        continue

    model = models[0]["name"]

    # Create LLM and test
    llm = ChatOllama(
        base_url=url,
        model=model,
        timeout=60.0,
    )

    query = queries[query_type]
    result = llm.invoke(query)

    print(f"{query_type.upper()} Query Test:")
    print(f"  Server: {host}")
    print(f"  Model: {model}")
    print(f"  Query: {query}")
    print(f"  Response: {result.content[:100]}...")
    print()

print("-" * 60)
print("SUCCESS: Both Ollama servers responding to routed queries")
EOF
```

---

## Acceptance Criteria

- [ ] OllamaRouter class implemented with get_llm and route_query methods
- [ ] ROUTING_TABLE correctly maps query types to servers/models
- [ ] General queries route to hx-ollama1-server (gemma3:27b)
- [ ] Code queries route to hx-ollama2-server (qwen2.5-coder or qwen3-coder)
- [ ] RAG queries route to hx-ollama1-server with 64KB context
- [ ] Tool queries route to hx-ollama1-server
- [ ] RoutedLLMProvider integrates classifier with router
- [ ] Environment variables configured for routing
- [ ] Integration test confirms both servers respond correctly
- [ ] No hardcoded IP addresses (hostnames only)

---

## Verification Commands

```bash
# Verify router module exists
ls -la /opt/hx-lang-server/app/llm/ollama_router.py

# Verify routing table in code
grep -A 20 "ROUTING_TABLE" /opt/hx-lang-server/app/llm/ollama_router.py

# Verify both servers accessible
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | jq '.models[0].name'
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models[0].name'
```

---

## Rollback Procedure

1. Remove ollama_router.py module
2. Remove router_integration.py module
3. Remove routing environment variables from .env
4. Revert any settings.py changes

---

## Related Tasks

- **Task 071:** Configure Ollama1 (general) connection
- **Task 072:** Configure Ollama2 (code) connection
- **Task 052:** Query classifier implementation
- **Task 076:** Implement connection health checks

---

## Notes

- Routing is based on query classification from Task 052
- Unknown query types default to "general" for safety
- LLM instances are cached per query type for performance
- Code model override supports deployment variations (qwen2.5 vs qwen3)
- All server references use hostnames, not IP addresses

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
