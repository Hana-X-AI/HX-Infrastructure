# Task: Implement Query Classifier

**Task ID**: hx-lang-server-task-052-implement-query-classifier
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-051 (AgentState Schema), hx-lang-server-task-023 (langchain-ollama)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 45 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Query Classification Mechanism"

---

## Objective

Implement the QueryClassifier that determines how to route queries to appropriate worker agents. Uses keyword-based classification (fast path) with LLM fallback (slow path) for ambiguous queries.

---

## Prerequisites

- [ ] AgentState schema implemented (task-051)
- [ ] langchain-ollama installed (task-023)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Classifier Module

Create `/opt/hx-lang-server/app/core/classifier.py`:

```python
"""
Query Classifier for hx-lang-server.

Classifies incoming queries to route them to the appropriate worker agent.
Uses keyword-based classification (fast path) with LLM fallback (slow path).

Classification Types:
- "general": General knowledge queries -> Ollama1
- "code": Code-related queries -> Ollama2
- "rag": Document/knowledge retrieval -> Ollama1 + LightRAG
- "tool": Tool invocation requests -> MCP tools

Specification Reference: node-spec.md Section "Query Classification Mechanism"
"""

import re
import hashlib
from typing import Optional, Set
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, SystemMessage

from .state import (
    QUERY_TYPE_GENERAL,
    QUERY_TYPE_CODE,
    QUERY_TYPE_RAG,
    QUERY_TYPE_TOOL
)


class QueryClassifier:
    """
    Classifies queries for Ollama routing.

    Uses two-tier classification:
    1. Keyword-based (fast path) - immediate classification
    2. LLM-based (slow path) - for ambiguous queries
    """

    # Keywords that strongly indicate code-related queries
    CODE_KEYWORDS: Set[str] = {
        "code", "function", "class", "debug", "error", "exception",
        "python", "javascript", "typescript", "java", "rust", "go",
        "sql", "api", "implement", "refactor", "optimize", "algorithm",
        "variable", "method", "syntax", "compile", "runtime", "bug",
        "script", "program", "developer", "coding", "programming",
        "def ", "async", "await", "import", "return", "if ", "for ",
        "while ", "try:", "except:", "class ", "function("
    }

    # Keywords that strongly indicate RAG/document retrieval queries
    RAG_KEYWORDS: Set[str] = {
        "search", "find", "document", "knowledge", "retrieve",
        "what is", "explain", "how does", "tell me about",
        "describe", "definition", "meaning", "information about",
        "lookup", "look up", "research", "learn about",
        "documentation", "reference", "guide", "tutorial"
    }

    # Keywords that strongly indicate tool usage requests
    TOOL_KEYWORDS: Set[str] = {
        "crawl", "fetch", "scrape", "web", "url", "website",
        "download", "extract", "page", "browse", "link",
        "convert", "transform", "process file", "pdf",
        "docx", "spreadsheet", "image"
    }

    # LLM classification prompt
    CLASSIFICATION_PROMPT = """You are a query classifier for an AI assistant system.
Classify the following query into exactly ONE of these categories:

- "code": Programming, debugging, code writing, software development
- "rag": Questions requiring document lookup, knowledge retrieval, explanations
- "tool": Requests to fetch web pages, convert documents, or use external tools
- "general": General conversation, greetings, or queries not fitting above

Respond with ONLY the category name in lowercase, nothing else.

Query: {query}

Category:"""

    def __init__(
        self,
        llm: Optional[ChatOllama] = None,
        cache: Optional[dict] = None
    ):
        """
        Initialize the classifier.

        Args:
            llm: Optional ChatOllama instance for LLM fallback.
                 If None, only keyword classification is used.
            cache: Optional cache dict for classification results.
        """
        self.llm = llm
        self.cache = cache if cache is not None else {}

    def _get_cache_key(self, query: str) -> str:
        """Generate cache key from query."""
        normalized = query.lower().strip()
        return hashlib.md5(normalized.encode()).hexdigest()

    def _keyword_classify(self, query: str) -> Optional[str]:
        """
        Attempt keyword-based classification (fast path).

        Returns classification if keywords match, None otherwise.
        """
        query_lower = query.lower()

        # Check for code keywords
        for keyword in self.CODE_KEYWORDS:
            if keyword in query_lower:
                return QUERY_TYPE_CODE

        # Check for tool keywords
        for keyword in self.TOOL_KEYWORDS:
            if keyword in query_lower:
                return QUERY_TYPE_TOOL

        # Check for RAG keywords
        for keyword in self.RAG_KEYWORDS:
            if keyword in query_lower:
                return QUERY_TYPE_RAG

        # No strong keyword match
        return None

    async def _llm_classify(self, query: str) -> str:
        """
        Use LLM for classification (slow path).

        Falls back to "general" if LLM is unavailable or fails.
        """
        if self.llm is None:
            return QUERY_TYPE_GENERAL

        try:
            messages = [
                HumanMessage(content=self.CLASSIFICATION_PROMPT.format(query=query))
            ]
            response = await self.llm.ainvoke(messages)

            # Parse response
            classification = response.content.strip().lower()

            # Validate classification
            valid_types = {QUERY_TYPE_GENERAL, QUERY_TYPE_CODE, QUERY_TYPE_RAG, QUERY_TYPE_TOOL}
            if classification in valid_types:
                return classification
            else:
                # Invalid response, default to general
                return QUERY_TYPE_GENERAL

        except Exception:
            # LLM failure, default to general
            return QUERY_TYPE_GENERAL

    async def classify(self, query: str) -> str:
        """
        Classify a query to determine routing.

        Uses keyword-based classification first (fast path).
        Falls back to LLM classification for ambiguous queries (slow path).

        Args:
            query: The user's query string.

        Returns:
            Classification string: "general", "code", "rag", or "tool"
        """
        # Check cache first
        cache_key = self._get_cache_key(query)
        if cache_key in self.cache:
            return self.cache[cache_key]

        # Try keyword classification (fast path)
        classification = self._keyword_classify(query)

        if classification is None:
            # Fall back to LLM classification (slow path)
            classification = await self._llm_classify(query)

        # Cache the result
        self.cache[cache_key] = classification

        return classification

    def classify_sync(self, query: str) -> str:
        """
        Synchronous classification using only keywords.

        For use in contexts where async is not available.
        Always returns a classification (defaults to general).
        """
        classification = self._keyword_classify(query)
        return classification if classification else QUERY_TYPE_GENERAL


# Singleton classifier instance (initialized without LLM)
_default_classifier: Optional[QueryClassifier] = None


def get_classifier(llm: Optional[ChatOllama] = None) -> QueryClassifier:
    """
    Get or create the default classifier instance.

    Args:
        llm: Optional ChatOllama for LLM fallback.

    Returns:
        QueryClassifier instance.
    """
    global _default_classifier
    if _default_classifier is None or llm is not None:
        _default_classifier = QueryClassifier(llm=llm)
    return _default_classifier
```

### Step 2: Update Package Exports

Update `/opt/hx-lang-server/app/core/__init__.py`:

```python
"""Core module for hx-lang-server."""

from .state import (
    AgentState,
    SCHEMA_VERSION,
    QUERY_TYPE_GENERAL,
    QUERY_TYPE_CODE,
    QUERY_TYPE_RAG,
    QUERY_TYPE_TOOL,
    VALID_QUERY_TYPES,
    create_initial_state,
    validate_query_type
)

from .classifier import (
    QueryClassifier,
    get_classifier
)

__all__ = [
    # State
    "AgentState",
    "SCHEMA_VERSION",
    "QUERY_TYPE_GENERAL",
    "QUERY_TYPE_CODE",
    "QUERY_TYPE_RAG",
    "QUERY_TYPE_TOOL",
    "VALID_QUERY_TYPES",
    "create_initial_state",
    "validate_query_type",
    # Classifier
    "QueryClassifier",
    "get_classifier"
]
```

### Step 3: Create Unit Tests

Create `/opt/hx-lang-server/tests/test_classifier.py`:

```python
"""Unit tests for QueryClassifier."""

import pytest
from app.core.classifier import QueryClassifier
from app.core.state import (
    QUERY_TYPE_GENERAL,
    QUERY_TYPE_CODE,
    QUERY_TYPE_RAG,
    QUERY_TYPE_TOOL
)


class TestKeywordClassification:
    """Test keyword-based classification."""

    @pytest.fixture
    def classifier(self):
        return QueryClassifier()

    def test_code_queries(self, classifier):
        """Test code-related queries are classified correctly."""
        code_queries = [
            "Write a Python function to sort a list",
            "Debug this error in my code",
            "How do I implement a binary search?",
            "Fix this JavaScript bug",
            "Refactor this class for better performance"
        ]
        for query in code_queries:
            assert classifier.classify_sync(query) == QUERY_TYPE_CODE, f"Failed: {query}"

    def test_rag_queries(self, classifier):
        """Test RAG/knowledge queries are classified correctly."""
        rag_queries = [
            "What is LangGraph?",
            "Explain how neural networks work",
            "Find information about kubernetes",
            "Search the documentation for deployment"
        ]
        for query in rag_queries:
            assert classifier.classify_sync(query) == QUERY_TYPE_RAG, f"Failed: {query}"

    def test_tool_queries(self, classifier):
        """Test tool-related queries are classified correctly."""
        tool_queries = [
            "Crawl this website for me",
            "Fetch the content from this URL",
            "Scrape the web page at example.com",
            "Convert this PDF to text"
        ]
        for query in tool_queries:
            assert classifier.classify_sync(query) == QUERY_TYPE_TOOL, f"Failed: {query}"

    def test_general_queries(self, classifier):
        """Test general queries default correctly."""
        general_queries = [
            "Hello, how are you?",
            "Thank you for your help",
            "What time is it?"
        ]
        for query in general_queries:
            assert classifier.classify_sync(query) == QUERY_TYPE_GENERAL, f"Failed: {query}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.core.classifier import QueryClassifier, get_classifier
from app.core.state import QUERY_TYPE_CODE, QUERY_TYPE_RAG, QUERY_TYPE_TOOL, QUERY_TYPE_GENERAL

classifier = QueryClassifier()

# Test classifications
tests = [
    ('Write a Python function', QUERY_TYPE_CODE),
    ('What is LangGraph?', QUERY_TYPE_RAG),
    ('Crawl this website', QUERY_TYPE_TOOL),
    ('Hello there', QUERY_TYPE_GENERAL),
]

print('Query Classification Tests:')
for query, expected in tests:
    result = classifier.classify_sync(query)
    status = 'PASS' if result == expected else 'FAIL'
    print(f'  [{status}] \"{query}\" -> {result} (expected: {expected})')

print('\nQueryClassifier implementation verified!')
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   ├── __init__.py
│   └── core/
│       ├── __init__.py
│       ├── state.py          # AgentState (task-051)
│       └── classifier.py     # QueryClassifier (this task)
└── tests/
    └── test_classifier.py    # Unit tests
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Classifier module | `/opt/hx-lang-server/app/core/classifier.py` | QueryClassifier implementation |
| Unit tests | `/opt/hx-lang-server/tests/test_classifier.py` | Classification tests |

---

## Verification Steps

- [ ] `classifier.py` file exists at correct location
- [ ] QueryClassifier can be imported
- [ ] classify_sync() returns correct classifications
- [ ] Code keywords -> "code"
- [ ] RAG keywords -> "rag"
- [ ] Tool keywords -> "tool"
- [ ] Unknown -> "general"

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Run unit tests
mkdir -p tests
python -m pytest tests/test_classifier.py -v

# Manual verification
python -c "
from app.core.classifier import QueryClassifier

c = QueryClassifier()
print('Keyword classification tests:')
print(f'  \"debug my code\" -> {c.classify_sync(\"debug my code\")}')
print(f'  \"search for docs\" -> {c.classify_sync(\"search for docs\")}')
print(f'  \"crawl website\" -> {c.classify_sync(\"crawl website\")}')
print(f'  \"hello\" -> {c.classify_sync(\"hello\")}')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/core/classifier.py
rm /opt/hx-lang-server/tests/test_classifier.py
# Revert __init__.py changes
```

---

## Notes

- Keyword classification is the fast path (no LLM call)
- LLM fallback only used for ambiguous queries
- Classification is cached to avoid repeated computation
- Redis caching integration in Work Stream 5 (Sri)
- LLM connection for fallback tested in Work Stream 7 (Jim)
- Classification accuracy target: >90% per specification

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
