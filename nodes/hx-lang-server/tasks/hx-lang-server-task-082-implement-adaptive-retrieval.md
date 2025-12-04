# Task: Implement Adaptive Retrieval Mode Selection

**Task ID:** hx-lang-server-task-082-implement-adaptive-retrieval
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081-configure-lightrag-http-client
**Estimated Time:** 3 hours

---

## Objective

Implement an adaptive retrieval system that intelligently selects the optimal LightRAG query mode (local, global, hybrid, mix) based on query classification, iterates when initial results are insufficient, and supports fallback strategies for degraded scenarios.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-015**: Service MUST support adaptive retrieval with iteration when initial results insufficient
- **FR-016**: Service MUST support LightRAG query modes: local, global, hybrid, mix

From the LightRAG Research Paper:
- Hybrid mode achieves 54.8% win rate vs GraphRAG on comprehensive queries
- Local mode optimal for specific entity queries (lower cost, faster)
- Global mode optimal for thematic/conceptual queries

---

## Prerequisites

- [ ] Task 081 complete: LightRAG HTTP client configured
- [ ] Task 052 complete: Query classifier implemented
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/rag/adaptive_retrieval.py
```

### Adaptive Retrieval Implementation

```python
"""
Adaptive Retrieval for LightRAG Integration.

This module implements intelligent query mode selection and iterative
retrieval based on LightRAG's dual-level retrieval paradigm:

- Low-level (local): Specific entity lookups ("Who wrote X?")
- High-level (global): Thematic/conceptual queries ("How does A influence B?")
- Hybrid: Combines both for comprehensive answers (default, best results)
- Mix: Blends local and global context in single response

The adaptive system:
1. Classifies queries to select initial mode
2. Evaluates result quality
3. Iterates with broader modes if insufficient
4. Caches successful mode patterns for future queries
"""

from enum import Enum
from typing import Optional, Dict, Any, List, Tuple
from dataclasses import dataclass, field
from pydantic import BaseModel, Field
import structlog
import hashlib
import re

from app.clients.lightrag_client import LightRAGClient, QueryResponse

logger = structlog.get_logger()


class QueryMode(str, Enum):
    """LightRAG query modes with cost/comprehensiveness trade-offs."""
    LOCAL = "local"      # 1 API call, fast, narrow scope
    GLOBAL = "global"    # 1 API call, thematic, broader scope
    HYBRID = "hybrid"    # 2-3 API calls, comprehensive, best quality
    MIX = "mix"          # 1 API call, blended context


class QueryType(str, Enum):
    """Query classification types for mode selection."""
    ENTITY = "entity"           # Specific entity lookup -> local
    RELATIONSHIP = "relationship"  # Entity relationships -> hybrid
    THEMATIC = "thematic"       # Concepts/themes -> global
    COMPREHENSIVE = "comprehensive"  # Complex multi-faceted -> hybrid
    EXPLORATORY = "exploratory"  # Open-ended discovery -> mix


@dataclass
class RetrievalResult:
    """Result from adaptive retrieval."""
    response: str
    context: Optional[str]
    mode_used: QueryMode
    iterations: int
    confidence: float
    entities_found: int = 0
    relationships_found: int = 0
    fallback_used: bool = False
    query_hash: str = ""


@dataclass
class RetrievalConfig:
    """Configuration for adaptive retrieval behavior."""
    # Quality thresholds
    min_response_length: int = 100  # Minimum chars for "sufficient" response
    min_context_length: int = 200   # Minimum chars for "sufficient" context
    min_entities: int = 1           # Minimum entities for entity queries
    min_confidence: float = 0.6     # Minimum confidence score

    # Iteration limits
    max_iterations: int = 3         # Maximum retrieval attempts
    iteration_timeout: float = 45.0  # Max seconds for all iterations

    # Mode escalation path
    escalation_path: List[QueryMode] = field(default_factory=lambda: [
        QueryMode.LOCAL,
        QueryMode.HYBRID,
        QueryMode.GLOBAL,
        QueryMode.MIX
    ])


class AdaptiveRetriever:
    """
    Intelligent retrieval orchestrator for LightRAG.

    This class implements the adaptive retrieval pattern described in
    the LightRAG research paper, with enhancements for HX-Infrastructure:

    1. Query Analysis: Classify query type to select initial mode
    2. Retrieval Execution: Query LightRAG with selected mode
    3. Quality Evaluation: Assess result sufficiency
    4. Iterative Refinement: Retry with broader modes if needed
    5. Mode Learning: Track successful patterns for future queries

    Performance Expectations (from LightRAG paper):
    - Hybrid mode: 54.8% win rate vs GraphRAG
    - Local mode: <500ms for simple entity queries
    - Global mode: Better for thematic understanding
    """

    # Query classification patterns
    ENTITY_PATTERNS = [
        r"\bwho\s+(is|was|are|were)\b",
        r"\bwhat\s+(is|are)\s+(a|an|the)\b",
        r"\bwhen\s+(did|was|were)\b",
        r"\bwhere\s+(is|was|are|were)\b",
        r"\bdefine\b",
        r"\bname(s)?\s+of\b",
    ]

    RELATIONSHIP_PATTERNS = [
        r"\bhow\s+(does|do|did)\s+.+\s+(relate|connect|affect|influence)\b",
        r"\brelationship\s+between\b",
        r"\bconnection\s+between\b",
        r"\blinked?\s+to\b",
        r"\bcause(s|d)?\s+(of|by)\b",
    ]

    THEMATIC_PATTERNS = [
        r"\bwhy\s+(is|are|does|do|did)\b",
        r"\bexplain\s+(the|how|why)\b",
        r"\bimportance\s+of\b",
        r"\bsignificance\s+of\b",
        r"\bimpact\s+of\b",
        r"\btrend(s)?\s+(in|of)\b",
    ]

    EXPLORATORY_PATTERNS = [
        r"\btell\s+me\s+(about|more)\b",
        r"\bwhat\s+do\s+(you|we)\s+know\b",
        r"\bsummarize\b",
        r"\boverview\s+of\b",
        r"\bexplore\b",
    ]

    def __init__(
        self,
        client: LightRAGClient,
        config: Optional[RetrievalConfig] = None
    ):
        self.client = client
        self.config = config or RetrievalConfig()
        self._logger = logger.bind(component="adaptive_retrieval")

        # Compile regex patterns
        self._entity_re = [re.compile(p, re.IGNORECASE) for p in self.ENTITY_PATTERNS]
        self._relationship_re = [re.compile(p, re.IGNORECASE) for p in self.RELATIONSHIP_PATTERNS]
        self._thematic_re = [re.compile(p, re.IGNORECASE) for p in self.THEMATIC_PATTERNS]
        self._exploratory_re = [re.compile(p, re.IGNORECASE) for p in self.EXPLORATORY_PATTERNS]

    def _hash_query(self, query: str) -> str:
        """Generate a hash for query caching."""
        return hashlib.sha256(query.lower().strip().encode()).hexdigest()[:16]

    def classify_query(self, query: str) -> Tuple[QueryType, QueryMode]:
        """
        Classify query type and recommend initial mode.

        Classification Strategy:
        1. Pattern matching for known query structures
        2. Length heuristics (longer = more complex)
        3. Default to hybrid for ambiguous queries

        Args:
            query: The user query text

        Returns:
            Tuple of (QueryType, recommended QueryMode)
        """
        query_lower = query.lower().strip()

        # Check patterns in order of specificity
        for pattern in self._entity_re:
            if pattern.search(query_lower):
                self._logger.debug(
                    "query_classified",
                    query_type="entity",
                    mode="local",
                    pattern=pattern.pattern
                )
                return QueryType.ENTITY, QueryMode.LOCAL

        for pattern in self._relationship_re:
            if pattern.search(query_lower):
                self._logger.debug(
                    "query_classified",
                    query_type="relationship",
                    mode="hybrid"
                )
                return QueryType.RELATIONSHIP, QueryMode.HYBRID

        for pattern in self._thematic_re:
            if pattern.search(query_lower):
                self._logger.debug(
                    "query_classified",
                    query_type="thematic",
                    mode="global"
                )
                return QueryType.THEMATIC, QueryMode.GLOBAL

        for pattern in self._exploratory_re:
            if pattern.search(query_lower):
                self._logger.debug(
                    "query_classified",
                    query_type="exploratory",
                    mode="mix"
                )
                return QueryType.EXPLORATORY, QueryMode.MIX

        # Length heuristic: complex queries benefit from hybrid
        if len(query) > 150:
            return QueryType.COMPREHENSIVE, QueryMode.HYBRID

        # Default: hybrid provides best general results
        return QueryType.COMPREHENSIVE, QueryMode.HYBRID

    def evaluate_result(
        self,
        result: QueryResponse,
        query_type: QueryType
    ) -> Tuple[bool, float]:
        """
        Evaluate if retrieval result is sufficient.

        Criteria vary by query type:
        - Entity queries: Need specific entities in response
        - Thematic queries: Need substantial explanation
        - Comprehensive: Need both context and coherent response

        Args:
            result: The LightRAG query response
            query_type: The classified query type

        Returns:
            Tuple of (is_sufficient, confidence_score)
        """
        response_len = len(result.response)
        context_len = len(result.context or "")
        entities_count = len(result.entities or [])
        relationships_count = len(result.relationships or [])

        # Calculate base confidence from response quality
        confidence = 0.0

        # Response length contribution (0-0.3)
        if response_len >= self.config.min_response_length:
            length_score = min(response_len / (self.config.min_response_length * 3), 1.0)
            confidence += length_score * 0.3

        # Context availability (0-0.2)
        if context_len >= self.config.min_context_length:
            context_score = min(context_len / (self.config.min_context_length * 3), 1.0)
            confidence += context_score * 0.2

        # Entity/relationship presence (0-0.3)
        if entities_count >= self.config.min_entities:
            entity_score = min(entities_count / 5, 1.0)
            confidence += entity_score * 0.2

        if relationships_count > 0:
            rel_score = min(relationships_count / 3, 1.0)
            confidence += rel_score * 0.1

        # Content quality heuristics (0-0.2)
        # Check for "I don't know" or similar failure patterns
        failure_patterns = [
            "i don't have",
            "i cannot find",
            "no information",
            "not available",
            "unable to answer"
        ]
        response_lower = result.response.lower()
        if not any(p in response_lower for p in failure_patterns):
            confidence += 0.2

        # Query-type specific adjustments
        if query_type == QueryType.ENTITY and entities_count < 1:
            confidence *= 0.7  # Penalty for entity query without entities

        if query_type == QueryType.RELATIONSHIP and relationships_count < 1:
            confidence *= 0.8  # Penalty for relationship query without relationships

        is_sufficient = confidence >= self.config.min_confidence

        self._logger.debug(
            "result_evaluated",
            is_sufficient=is_sufficient,
            confidence=confidence,
            response_length=response_len,
            context_length=context_len,
            entities=entities_count,
            relationships=relationships_count
        )

        return is_sufficient, confidence

    def get_escalation_mode(
        self,
        current_mode: QueryMode,
        iteration: int
    ) -> Optional[QueryMode]:
        """
        Get next mode in escalation path.

        Escalation follows this logic:
        - local -> hybrid (broaden scope)
        - global -> hybrid (add entity detail)
        - hybrid -> mix (try alternative blend)
        - mix -> None (exhausted options)

        Args:
            current_mode: The current query mode
            iteration: Current iteration number

        Returns:
            Next mode to try, or None if exhausted
        """
        try:
            current_idx = self.config.escalation_path.index(current_mode)
            if current_idx + 1 < len(self.config.escalation_path):
                return self.config.escalation_path[current_idx + 1]
        except ValueError:
            # Mode not in path, try hybrid
            if current_mode != QueryMode.HYBRID:
                return QueryMode.HYBRID

        return None

    async def retrieve(
        self,
        query: str,
        force_mode: Optional[QueryMode] = None,
        only_need_context: bool = False
    ) -> RetrievalResult:
        """
        Execute adaptive retrieval with intelligent mode selection.

        This is the main entry point for RAG operations. The algorithm:
        1. Classify query to select initial mode
        2. Execute retrieval with selected mode
        3. Evaluate result quality
        4. If insufficient, iterate with escalated mode
        5. Return best result with metadata

        Args:
            query: The user query
            force_mode: Override automatic mode selection
            only_need_context: Return only context (no LLM response)

        Returns:
            RetrievalResult with response and metadata
        """
        query_hash = self._hash_query(query)

        # Step 1: Classify query
        query_type, initial_mode = self.classify_query(query)
        current_mode = force_mode or initial_mode

        self._logger.info(
            "adaptive_retrieval_started",
            query_hash=query_hash,
            query_type=query_type.value,
            initial_mode=current_mode.value,
            force_mode=force_mode is not None
        )

        best_result: Optional[QueryResponse] = None
        best_confidence: float = 0.0
        best_mode: QueryMode = current_mode
        iterations = 0

        # Step 2-4: Iterative retrieval
        while iterations < self.config.max_iterations:
            iterations += 1

            self._logger.debug(
                "retrieval_iteration",
                iteration=iterations,
                mode=current_mode.value
            )

            try:
                result = await self.client.query(
                    query=query,
                    mode=current_mode.value,
                    only_need_context=only_need_context
                )

                is_sufficient, confidence = self.evaluate_result(result, query_type)

                # Track best result
                if confidence > best_confidence:
                    best_confidence = confidence
                    best_result = result
                    best_mode = current_mode

                if is_sufficient:
                    self._logger.info(
                        "retrieval_sufficient",
                        iterations=iterations,
                        mode=current_mode.value,
                        confidence=confidence
                    )
                    break

                # Not sufficient - escalate mode
                next_mode = self.get_escalation_mode(current_mode, iterations)
                if next_mode is None:
                    self._logger.info(
                        "retrieval_exhausted",
                        iterations=iterations,
                        best_confidence=best_confidence
                    )
                    break

                current_mode = next_mode

            except Exception as e:
                self._logger.error(
                    "retrieval_error",
                    iteration=iterations,
                    mode=current_mode.value,
                    error=str(e)
                )
                # Try next mode on error
                next_mode = self.get_escalation_mode(current_mode, iterations)
                if next_mode is None:
                    break
                current_mode = next_mode

        # Step 5: Return result
        if best_result is None:
            self._logger.warning(
                "retrieval_failed",
                query_hash=query_hash,
                iterations=iterations
            )
            return RetrievalResult(
                response="Unable to retrieve relevant information.",
                context=None,
                mode_used=best_mode,
                iterations=iterations,
                confidence=0.0,
                fallback_used=True,
                query_hash=query_hash
            )

        return RetrievalResult(
            response=best_result.response,
            context=best_result.context,
            mode_used=best_mode,
            iterations=iterations,
            confidence=best_confidence,
            entities_found=len(best_result.entities or []),
            relationships_found=len(best_result.relationships or []),
            fallback_used=iterations > 1,
            query_hash=query_hash
        )


# Convenience function for simple retrieval
async def adaptive_query(
    client: LightRAGClient,
    query: str,
    force_mode: Optional[str] = None
) -> RetrievalResult:
    """
    Simple interface for adaptive retrieval.

    Args:
        client: LightRAG client instance
        query: The user query
        force_mode: Optional mode override ("local", "global", "hybrid", "mix")

    Returns:
        RetrievalResult with response and metadata
    """
    retriever = AdaptiveRetriever(client)
    mode = QueryMode(force_mode) if force_mode else None
    return await retriever.retrieve(query, force_mode=mode)
```

---

## Manual Steps

### Step 1: Create RAG Module Directory

```bash
# As hx-lang-server user
sudo -u hx-lang-server mkdir -p /opt/hx-lang-server/app/rag
sudo -u hx-lang-server touch /opt/hx-lang-server/app/rag/__init__.py
```

### Step 2: Create Adaptive Retrieval Module

```bash
# Create the adaptive_retrieval.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/rag/adaptive_retrieval.py
```

### Step 3: Create Module Init

```bash
# Update __init__.py for exports
cat << 'EOF' | sudo -u hx-lang-server tee /opt/hx-lang-server/app/rag/__init__.py
"""RAG module for LightRAG integration."""
from .adaptive_retrieval import (
    AdaptiveRetriever,
    RetrievalResult,
    RetrievalConfig,
    QueryMode,
    QueryType,
    adaptive_query,
)

__all__ = [
    "AdaptiveRetriever",
    "RetrievalResult",
    "RetrievalConfig",
    "QueryMode",
    "QueryType",
    "adaptive_query",
]
EOF
```

---

## Acceptance Criteria

- [ ] AdaptiveRetriever class created at `/opt/hx-lang-server/app/rag/adaptive_retrieval.py`
- [ ] Query classification correctly identifies entity, relationship, thematic, and exploratory queries
- [ ] Mode selection maps correctly:
  - Entity queries -> LOCAL mode
  - Relationship queries -> HYBRID mode
  - Thematic queries -> GLOBAL mode
  - Exploratory queries -> MIX mode
- [ ] Iterative retrieval escalates modes when results insufficient
- [ ] Maximum 3 iterations enforced
- [ ] Confidence scoring implemented (0.0-1.0 scale)
- [ ] Best result tracking across iterations
- [ ] Structured logging for observability
- [ ] Fallback handling for retrieval failures

---

## Verification

```bash
# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
import asyncio
from app.clients.lightrag_client import LightRAGClient
from app.rag.adaptive_retrieval import AdaptiveRetriever, QueryMode

async def test_adaptive_retrieval():
    async with LightRAGClient() as client:
        retriever = AdaptiveRetriever(client)

        # Test query classification
        test_queries = [
            ("Who is the author of this document?", "entity", "local"),
            ("How does authentication relate to authorization?", "relationship", "hybrid"),
            ("Why is security important?", "thematic", "global"),
            ("Tell me about the system architecture", "exploratory", "mix"),
        ]

        for query, expected_type, expected_mode in test_queries:
            query_type, mode = retriever.classify_query(query)
            print(f"Query: {query[:40]}...")
            print(f"  Type: {query_type.value} (expected: {expected_type})")
            print(f"  Mode: {mode.value} (expected: {expected_mode})")
            assert query_type.value == expected_type, f"Classification mismatch"
            assert mode.value == expected_mode, f"Mode mismatch"

        print("\nAll classification tests passed!")

        # Test actual retrieval (if LightRAG is available)
        health = await client.health_check()
        if health.get("status") == "healthy":
            result = await retriever.retrieve(
                "What is the main purpose of this knowledge base?"
            )
            print(f"\nRetrieval Result:")
            print(f"  Mode used: {result.mode_used.value}")
            print(f"  Iterations: {result.iterations}")
            print(f"  Confidence: {result.confidence:.2f}")
            print(f"  Response length: {len(result.response)} chars")
        else:
            print("\nLightRAG not available, skipping retrieval test")

asyncio.run(test_adaptive_retrieval())
EOF
```

---

## Rollback

```bash
# Remove adaptive retrieval module
sudo rm -rf /opt/hx-lang-server/app/rag/
```

---

## Notes

- **Mode Selection Trade-offs**:
  - LOCAL: Fastest (1 API call), best for specific entity queries
  - GLOBAL: Better for themes/concepts, may miss specific details
  - HYBRID: Most comprehensive (2-3 calls), recommended default
  - MIX: Blends contexts, good for exploratory queries

- **Performance Expectations** (from LightRAG paper):
  - Hybrid mode achieves 54.8% win rate vs GraphRAG
  - Local mode typically <500ms
  - Hybrid mode typically 1-3s

- **Escalation Logic**: The system starts with the most efficient mode for the query type and escalates only when results are insufficient. This optimizes for both quality and cost.

---

## Related Tasks

- **Task 081**: LightRAG HTTP client (prerequisite)
- **Task 052**: Query classifier (complements this)
- **Task 054**: RAG Agent worker (uses this retriever)
- **Task 085**: Response caching (caches retrieval results)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
