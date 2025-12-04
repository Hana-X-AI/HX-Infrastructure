# Task: Configure All LightRAG Query Modes

**Task ID:** hx-lang-server-task-083-configure-query-modes
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081-configure-lightrag-http-client
**Estimated Time:** 2 hours

---

## Objective

Configure and validate all LightRAG query modes (local, global, hybrid, mix) with appropriate parameters, ensuring each mode is properly optimized for its use case and integrated into the hx-lang-server query workflow.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-016**: Service MUST support LightRAG query modes: local, global, hybrid, mix

From the LightRAG Research Paper:
- **Local Mode**: Extracts specific entities and their direct relationships
- **Global Mode**: Synthesizes high-level themes and concepts across the knowledge graph
- **Hybrid Mode**: Combines local entity detail with global thematic understanding
- **Mix Mode**: Blends local and global context into a single retrieval pass

---

## Prerequisites

- [ ] Task 081 complete: LightRAG HTTP client configured
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`
- [ ] LightRAG server operational at hx-literag-server.hx.dev.local:8020

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/rag/query_modes.py
```

### Query Mode Configuration

```python
"""
LightRAG Query Mode Configuration.

This module defines the configuration and behavior for each LightRAG
query mode, including optimal parameters and use-case recommendations.

Query Mode Overview (from LightRAG Paper):
---------------------------------------
| Mode   | API Calls | Latency | Use Case                           |
|--------|-----------|---------|-------------------------------------|
| local  | 1         | <500ms  | Entity lookup, specific questions   |
| global | 1         | <1s     | Themes, trends, conceptual queries  |
| hybrid | 2-3       | 1-3s    | Comprehensive, complex questions    |
| mix    | 1         | <1s     | Blended context, exploration        |

Performance (Agriculture Dataset, LightRAG Paper):
- Hybrid: 54.8% win rate vs GraphRAG
- Best comprehensiveness scores across all datasets
"""

from dataclasses import dataclass, field
from typing import Dict, Any, Optional, List
from enum import Enum


class QueryModeType(str, Enum):
    """Available LightRAG query modes."""
    LOCAL = "local"
    GLOBAL = "global"
    HYBRID = "hybrid"
    MIX = "mix"
    # Note: naive and bypass exist but are NOT recommended for production
    # NAIVE = "naive"    # Skips knowledge graph - defeats purpose of LightRAG
    # BYPASS = "bypass"  # Returns raw content - no RAG processing


@dataclass
class QueryModeConfig:
    """Configuration for a specific query mode."""

    mode: QueryModeType
    description: str

    # Token limits for context retrieval
    max_token_for_text_unit: int = 4000
    max_token_for_local_context: int = 4000
    max_token_for_global_context: int = 4000

    # Result count
    top_k: int = 60

    # Response behavior
    only_need_context: bool = False  # If True, skip LLM response generation

    # Performance characteristics (informational)
    expected_latency_ms: int = 1000
    api_calls: int = 1

    # Use case guidance
    recommended_for: List[str] = field(default_factory=list)
    not_recommended_for: List[str] = field(default_factory=list)

    def to_query_params(self) -> Dict[str, Any]:
        """Convert to LightRAG query parameters."""
        return {
            "mode": self.mode.value,
            "top_k": self.top_k,
            "max_token_for_text_unit": self.max_token_for_text_unit,
            "max_token_for_local_context": self.max_token_for_local_context,
            "max_token_for_global_context": self.max_token_for_global_context,
            "only_need_context": self.only_need_context,
        }


# Default configurations for each mode
MODE_CONFIGS: Dict[QueryModeType, QueryModeConfig] = {
    QueryModeType.LOCAL: QueryModeConfig(
        mode=QueryModeType.LOCAL,
        description="Entity-focused retrieval for specific questions",
        max_token_for_text_unit=4000,
        max_token_for_local_context=4000,
        max_token_for_global_context=0,  # No global context in local mode
        top_k=60,
        expected_latency_ms=500,
        api_calls=1,
        recommended_for=[
            "Who/What/When/Where questions",
            "Entity lookups",
            "Specific fact retrieval",
            "Definition requests",
            "Name lookups",
        ],
        not_recommended_for=[
            "Why/How questions",
            "Trend analysis",
            "Comparative analysis",
            "Complex multi-entity queries",
        ],
    ),

    QueryModeType.GLOBAL: QueryModeConfig(
        mode=QueryModeType.GLOBAL,
        description="Theme-focused retrieval for conceptual questions",
        max_token_for_text_unit=4000,
        max_token_for_local_context=0,  # No local context in global mode
        max_token_for_global_context=4000,
        top_k=60,
        expected_latency_ms=800,
        api_calls=1,
        recommended_for=[
            "Why/How questions",
            "Trend analysis",
            "Impact assessment",
            "Conceptual explanations",
            "Theme identification",
        ],
        not_recommended_for=[
            "Specific entity lookups",
            "Exact fact retrieval",
            "Name/date queries",
        ],
    ),

    QueryModeType.HYBRID: QueryModeConfig(
        mode=QueryModeType.HYBRID,
        description="Comprehensive retrieval combining entity and theme analysis",
        max_token_for_text_unit=4000,
        max_token_for_local_context=4000,
        max_token_for_global_context=4000,
        top_k=60,
        expected_latency_ms=2000,
        api_calls=3,  # Local + Global + Merge
        recommended_for=[
            "Complex questions",
            "Research queries",
            "Comparative analysis",
            "Multi-faceted questions",
            "Comprehensive answers needed",
            "Default for unknown query types",
        ],
        not_recommended_for=[
            "Simple fact lookups (use local)",
            "Time-sensitive queries (use local)",
        ],
    ),

    QueryModeType.MIX: QueryModeConfig(
        mode=QueryModeType.MIX,
        description="Blended context retrieval in single pass",
        max_token_for_text_unit=4000,
        max_token_for_local_context=2000,  # Half local
        max_token_for_global_context=2000,  # Half global
        top_k=60,
        expected_latency_ms=700,
        api_calls=1,
        recommended_for=[
            "Exploratory queries",
            "Open-ended questions",
            "Balanced perspective needed",
            "Discovery mode",
        ],
        not_recommended_for=[
            "Queries requiring deep entity detail",
            "Queries requiring comprehensive theme analysis",
        ],
    ),
}


class QueryModeSelector:
    """
    Selects and configures query modes based on use case.

    This class provides intelligent mode selection and parameter
    optimization based on query characteristics and requirements.
    """

    def __init__(self, default_mode: QueryModeType = QueryModeType.HYBRID):
        self.default_mode = default_mode
        self._configs = MODE_CONFIGS.copy()

    def get_config(self, mode: QueryModeType) -> QueryModeConfig:
        """Get configuration for a specific mode."""
        return self._configs[mode]

    def override_config(
        self,
        mode: QueryModeType,
        **overrides
    ) -> QueryModeConfig:
        """
        Get a mode config with specific overrides.

        Args:
            mode: The base mode to use
            **overrides: Parameters to override

        Returns:
            Modified QueryModeConfig
        """
        base = self._configs[mode]
        return QueryModeConfig(
            mode=base.mode,
            description=base.description,
            max_token_for_text_unit=overrides.get(
                "max_token_for_text_unit", base.max_token_for_text_unit
            ),
            max_token_for_local_context=overrides.get(
                "max_token_for_local_context", base.max_token_for_local_context
            ),
            max_token_for_global_context=overrides.get(
                "max_token_for_global_context", base.max_token_for_global_context
            ),
            top_k=overrides.get("top_k", base.top_k),
            only_need_context=overrides.get(
                "only_need_context", base.only_need_context
            ),
            expected_latency_ms=base.expected_latency_ms,
            api_calls=base.api_calls,
            recommended_for=base.recommended_for,
            not_recommended_for=base.not_recommended_for,
        )

    def get_optimal_mode_for_query(
        self,
        query: str,
        require_speed: bool = False,
        require_depth: bool = False
    ) -> QueryModeType:
        """
        Recommend optimal mode based on query and requirements.

        Args:
            query: The query text
            require_speed: Prioritize low latency
            require_depth: Prioritize comprehensive answers

        Returns:
            Recommended QueryModeType
        """
        query_lower = query.lower()

        # Speed requirement overrides
        if require_speed:
            return QueryModeType.LOCAL

        # Depth requirement
        if require_depth:
            return QueryModeType.HYBRID

        # Pattern-based selection
        entity_keywords = ["who", "what is", "when", "where", "define", "name"]
        theme_keywords = ["why", "how does", "importance", "impact", "trend"]
        explore_keywords = ["tell me", "overview", "summarize", "explore"]

        if any(kw in query_lower for kw in entity_keywords):
            return QueryModeType.LOCAL

        if any(kw in query_lower for kw in theme_keywords):
            return QueryModeType.GLOBAL

        if any(kw in query_lower for kw in explore_keywords):
            return QueryModeType.MIX

        # Default to hybrid for best general results
        return self.default_mode

    def describe_modes(self) -> str:
        """Get human-readable description of all modes."""
        lines = ["LightRAG Query Modes:\n"]
        for mode, config in self._configs.items():
            lines.append(f"## {mode.value.upper()}")
            lines.append(f"{config.description}")
            lines.append(f"- Expected latency: {config.expected_latency_ms}ms")
            lines.append(f"- API calls: {config.api_calls}")
            lines.append(f"- Best for: {', '.join(config.recommended_for[:3])}")
            lines.append("")
        return "\n".join(lines)


# Module-level convenience functions

def get_mode_config(mode: str) -> QueryModeConfig:
    """Get configuration for a query mode by name."""
    mode_type = QueryModeType(mode)
    return MODE_CONFIGS[mode_type]


def get_mode_params(mode: str, **overrides) -> Dict[str, Any]:
    """Get query parameters for a mode with optional overrides."""
    config = get_mode_config(mode)
    params = config.to_query_params()
    params.update(overrides)
    return params


def recommend_mode(query: str) -> str:
    """Get recommended mode for a query."""
    selector = QueryModeSelector()
    return selector.get_optimal_mode_for_query(query).value
```

---

## Manual Steps

### Step 1: Create Query Modes Module

```bash
# Create the query_modes.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/rag/query_modes.py
```

### Step 2: Update Module Init

```bash
# Update __init__.py to include query_modes exports
cat << 'EOF' | sudo -u hx-lang-server tee -a /opt/hx-lang-server/app/rag/__init__.py

# Query mode configuration
from .query_modes import (
    QueryModeType,
    QueryModeConfig,
    QueryModeSelector,
    MODE_CONFIGS,
    get_mode_config,
    get_mode_params,
    recommend_mode,
)
EOF
```

---

## Query Mode Reference Table

| Mode | Latency | API Calls | Best For | Avoid For |
|------|---------|-----------|----------|-----------|
| **local** | <500ms | 1 | Entity lookups, specific facts | Complex analysis |
| **global** | <1s | 1 | Themes, trends, conceptual | Specific entities |
| **hybrid** | 1-3s | 2-3 | Complex queries, research | Simple lookups |
| **mix** | <1s | 1 | Exploration, balanced view | Deep analysis |

---

## Acceptance Criteria

- [ ] QueryModeConfig dataclass created with all configuration parameters
- [ ] MODE_CONFIGS dictionary with default configs for all 4 modes
- [ ] QueryModeSelector class for intelligent mode recommendation
- [ ] get_mode_config() function for retrieving mode configuration
- [ ] get_mode_params() function for generating query parameters
- [ ] recommend_mode() function for query-based mode selection
- [ ] Token limits properly configured per mode:
  - local: 4000 local, 0 global
  - global: 0 local, 4000 global
  - hybrid: 4000 local, 4000 global
  - mix: 2000 local, 2000 global

---

## Verification

```bash
# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
from app.rag.query_modes import (
    QueryModeType,
    QueryModeSelector,
    MODE_CONFIGS,
    get_mode_config,
    recommend_mode,
)

# Test mode configuration
print("Mode Configurations:")
for mode, config in MODE_CONFIGS.items():
    print(f"\n{mode.value.upper()}:")
    print(f"  Local tokens: {config.max_token_for_local_context}")
    print(f"  Global tokens: {config.max_token_for_global_context}")
    print(f"  Expected latency: {config.expected_latency_ms}ms")

# Test mode recommendation
test_queries = [
    "Who is the CEO?",
    "Why is security important?",
    "Tell me about the architecture",
    "What is the relationship between A and B?",
]

print("\n\nMode Recommendations:")
for query in test_queries:
    mode = recommend_mode(query)
    print(f"  '{query}' -> {mode}")

# Verify hybrid is default for complex queries
selector = QueryModeSelector()
assert selector.default_mode == QueryModeType.HYBRID
print("\n\nAll query mode tests passed!")
EOF
```

---

## Rollback

```bash
# Remove query modes module
sudo rm -f /opt/hx-lang-server/app/rag/query_modes.py

# Revert __init__.py additions
# (manual edit to remove query_modes imports)
```

---

## Notes

- **Why No Naive/Bypass Modes**: These modes exist in LightRAG but are NOT configured here because:
  - `naive`: Skips the knowledge graph entirely (defeats the purpose)
  - `bypass`: Returns raw content without RAG processing

- **Token Budget**: The 64KB context requirement from the specification applies to the LLM processing LightRAG's output, not these retrieval parameters.

- **Mode Selection**: When in doubt, use `hybrid`. It has the best win rate (54.8% vs GraphRAG) and provides the most comprehensive answers.

---

## Related Tasks

- **Task 081**: LightRAG HTTP client (uses these configurations)
- **Task 082**: Adaptive retrieval (uses mode selector)
- **Task 054**: RAG Agent worker (selects modes based on query)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
