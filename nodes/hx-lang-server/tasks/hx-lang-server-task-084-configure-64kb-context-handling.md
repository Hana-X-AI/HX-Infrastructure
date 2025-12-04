# Task: Configure 64KB Context Handling

**Task ID:** hx-lang-server-task-084-configure-64kb-context-handling
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081-configure-lightrag-http-client, hx-lang-server-task-071 (Ollama integration)
**Estimated Time:** 2.5 hours

---

## Objective

Configure 64KB context size handling for LightRAG operations, ensuring that the RAG Agent can process large retrieval contexts, handle context truncation gracefully, and coordinate with Ollama models that have been configured for extended context.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-013**: Service MUST validate Ollama model context size >= 64KB for RAG and Code operations
- **CAIO Decision**: 64KB context size for RAG and Code operations

From LightRAG Documentation:
- "In order for LightRAG to work context should be at least 32k tokens. By default Ollama models have context size of 8k."
- 64KB recommended for complex entity-relationship extraction

---

## Prerequisites

- [ ] Task 081 complete: LightRAG HTTP client configured
- [ ] Task 071 complete: Ollama1 (general) connection configured
- [ ] Ollama models configured with 64KB context (Jim's work stream)
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`

---

## Critical Background

### Why 64KB Context is Required

LightRAG's entity extraction process works as follows:

1. **Document Indexing**: LightRAG extracts entities and relationships from documents using an LLM
2. **Context Assembly**: During retrieval, LightRAG assembles context from:
   - Matching text chunks
   - Related entities (low-level)
   - Related themes (high-level)
3. **Response Generation**: The assembled context is sent to the LLM for response

With default 8KB context, LightRAG will:
- Fail to extract complex entity relationships
- Truncate retrieval context mid-sentence
- Produce incomplete or incoherent responses

The CAIO-approved 64KB context size ensures:
- Complete entity-relationship extraction
- Sufficient retrieval context for complex queries
- Room for both local and global context in hybrid mode

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/rag/context_manager.py
```

### Context Management Implementation

```python
"""
Context Manager for 64KB LightRAG Operations.

This module handles:
1. Context size validation and enforcement
2. Intelligent context truncation when needed
3. Context assembly for hybrid queries
4. Token counting and budget management

CRITICAL: 64KB context is a CAIO-mandated requirement.
Never reduce context below 32KB for any RAG operation.
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Tuple
import structlog
import tiktoken

logger = structlog.get_logger()


# Token constants
TOKENS_PER_KB = 256  # Approximate tokens per KB of text
MIN_CONTEXT_TOKENS = 32 * 1024  # 32KB minimum (LightRAG requirement)
RECOMMENDED_CONTEXT_TOKENS = 64 * 1024  # 64KB (CAIO decision)
MAX_CONTEXT_TOKENS = 128 * 1024  # 128KB absolute maximum


@dataclass
class ContextBudget:
    """
    Token budget allocation for context handling.

    The 64KB context is divided across:
    - Query/prompt overhead
    - Retrieved context (local + global)
    - Response generation headroom

    Default allocation (64KB = 65,536 tokens):
    - Query overhead: 2,048 tokens
    - Local context: 24,576 tokens
    - Global context: 24,576 tokens
    - Response headroom: 14,336 tokens
    """

    total_tokens: int = RECOMMENDED_CONTEXT_TOKENS
    query_overhead: int = 2048
    local_context_tokens: int = 24576
    global_context_tokens: int = 24576
    response_headroom: int = 14336

    def __post_init__(self):
        """Validate budget allocation."""
        allocated = (
            self.query_overhead +
            self.local_context_tokens +
            self.global_context_tokens +
            self.response_headroom
        )
        if allocated > self.total_tokens:
            raise ValueError(
                f"Context budget overflow: {allocated} > {self.total_tokens}"
            )

    @property
    def available_for_retrieval(self) -> int:
        """Total tokens available for retrieval context."""
        return self.local_context_tokens + self.global_context_tokens

    def for_mode(self, mode: str) -> "ContextBudget":
        """
        Get adjusted budget for specific query mode.

        Args:
            mode: Query mode (local, global, hybrid, mix)

        Returns:
            Adjusted ContextBudget for the mode
        """
        if mode == "local":
            # All retrieval budget to local context
            return ContextBudget(
                total_tokens=self.total_tokens,
                query_overhead=self.query_overhead,
                local_context_tokens=self.available_for_retrieval,
                global_context_tokens=0,
                response_headroom=self.response_headroom,
            )
        elif mode == "global":
            # All retrieval budget to global context
            return ContextBudget(
                total_tokens=self.total_tokens,
                query_overhead=self.query_overhead,
                local_context_tokens=0,
                global_context_tokens=self.available_for_retrieval,
                response_headroom=self.response_headroom,
            )
        elif mode == "mix":
            # 40/60 split favoring global
            return ContextBudget(
                total_tokens=self.total_tokens,
                query_overhead=self.query_overhead,
                local_context_tokens=int(self.available_for_retrieval * 0.4),
                global_context_tokens=int(self.available_for_retrieval * 0.6),
                response_headroom=self.response_headroom,
            )
        else:  # hybrid or default
            return self  # Use default 50/50 split


@dataclass
class ContextChunk:
    """A chunk of retrieved context with metadata."""
    content: str
    source: str  # "local" or "global"
    relevance_score: float
    entity_ids: List[str] = field(default_factory=list)
    tokens: int = 0

    def __post_init__(self):
        if self.tokens == 0:
            self.tokens = estimate_tokens(self.content)


class ContextManager:
    """
    Manages 64KB context handling for LightRAG operations.

    Key responsibilities:
    1. Validate context fits within 64KB budget
    2. Intelligently truncate when needed (preserve semantic units)
    3. Assemble context from multiple sources
    4. Track token usage for observability
    """

    def __init__(
        self,
        budget: Optional[ContextBudget] = None,
        model: str = "cl100k_base"  # GPT-4/Claude tokenizer
    ):
        self.budget = budget or ContextBudget()
        self._logger = logger.bind(component="context_manager")

        # Initialize tokenizer (with fallback)
        try:
            self._tokenizer = tiktoken.get_encoding(model)
        except Exception:
            self._tokenizer = None
            self._logger.warning(
                "tiktoken_fallback",
                message="Using approximate token counting"
            )

    def count_tokens(self, text: str) -> int:
        """
        Count tokens in text.

        Uses tiktoken when available, falls back to approximation.
        """
        if self._tokenizer:
            return len(self._tokenizer.encode(text))
        return estimate_tokens(text)

    def validate_context_size(self, ollama_context_size: int) -> Tuple[bool, str]:
        """
        Validate that Ollama model context size meets requirements.

        Args:
            ollama_context_size: The configured context size in tokens

        Returns:
            Tuple of (is_valid, message)
        """
        if ollama_context_size < MIN_CONTEXT_TOKENS:
            return False, (
                f"Context size {ollama_context_size} is below minimum "
                f"({MIN_CONTEXT_TOKENS}). LightRAG requires at least 32KB context."
            )

        if ollama_context_size < RECOMMENDED_CONTEXT_TOKENS:
            return True, (
                f"Context size {ollama_context_size} is below recommended "
                f"({RECOMMENDED_CONTEXT_TOKENS}). Consider increasing for optimal results."
            )

        return True, f"Context size {ollama_context_size} meets requirements."

    def truncate_to_budget(
        self,
        text: str,
        max_tokens: int,
        preserve_sentences: bool = True
    ) -> str:
        """
        Truncate text to fit within token budget.

        Uses intelligent truncation that:
        1. Respects sentence boundaries when possible
        2. Preserves the beginning and end for context
        3. Adds truncation indicator

        Args:
            text: Text to truncate
            max_tokens: Maximum tokens allowed
            preserve_sentences: Try to end on sentence boundary

        Returns:
            Truncated text
        """
        current_tokens = self.count_tokens(text)

        if current_tokens <= max_tokens:
            return text

        self._logger.debug(
            "context_truncation",
            original_tokens=current_tokens,
            max_tokens=max_tokens
        )

        # Estimate chars per token for this text
        chars_per_token = len(text) / current_tokens
        target_chars = int(max_tokens * chars_per_token * 0.95)  # 5% buffer

        if preserve_sentences:
            # Try to find a sentence boundary
            truncated = text[:target_chars]
            last_period = truncated.rfind(". ")
            last_newline = truncated.rfind("\n")

            boundary = max(last_period, last_newline)
            if boundary > target_chars * 0.8:  # At least 80% preserved
                truncated = text[:boundary + 1]
            else:
                truncated = text[:target_chars]
        else:
            truncated = text[:target_chars]

        # Add truncation indicator
        truncated = truncated.rstrip() + "\n\n[Context truncated due to size limits]"

        return truncated

    def assemble_context(
        self,
        local_chunks: List[ContextChunk],
        global_chunks: List[ContextChunk],
        mode: str = "hybrid"
    ) -> Tuple[str, Dict[str, Any]]:
        """
        Assemble context from local and global chunks within budget.

        Args:
            local_chunks: Chunks from local (entity) retrieval
            global_chunks: Chunks from global (theme) retrieval
            mode: Query mode for budget allocation

        Returns:
            Tuple of (assembled_context, metadata)
        """
        mode_budget = self.budget.for_mode(mode)

        # Sort by relevance
        local_sorted = sorted(local_chunks, key=lambda c: c.relevance_score, reverse=True)
        global_sorted = sorted(global_chunks, key=lambda c: c.relevance_score, reverse=True)

        # Assemble within budget
        local_context = []
        local_tokens_used = 0
        for chunk in local_sorted:
            if local_tokens_used + chunk.tokens <= mode_budget.local_context_tokens:
                local_context.append(chunk.content)
                local_tokens_used += chunk.tokens
            else:
                break

        global_context = []
        global_tokens_used = 0
        for chunk in global_sorted:
            if global_tokens_used + chunk.tokens <= mode_budget.global_context_tokens:
                global_context.append(chunk.content)
                global_tokens_used += chunk.tokens
            else:
                break

        # Format assembled context
        parts = []
        if local_context:
            parts.append("## Entity Context\n" + "\n\n".join(local_context))
        if global_context:
            parts.append("## Thematic Context\n" + "\n\n".join(global_context))

        assembled = "\n\n---\n\n".join(parts) if parts else ""

        metadata = {
            "mode": mode,
            "local_chunks_used": len(local_context),
            "local_chunks_total": len(local_chunks),
            "local_tokens_used": local_tokens_used,
            "local_tokens_budget": mode_budget.local_context_tokens,
            "global_chunks_used": len(global_context),
            "global_chunks_total": len(global_chunks),
            "global_tokens_used": global_tokens_used,
            "global_tokens_budget": mode_budget.global_context_tokens,
            "total_tokens": local_tokens_used + global_tokens_used,
            "total_budget": mode_budget.available_for_retrieval,
        }

        self._logger.info(
            "context_assembled",
            **metadata
        )

        return assembled, metadata

    def prepare_for_llm(
        self,
        query: str,
        context: str
    ) -> Tuple[str, int, bool]:
        """
        Prepare query and context for LLM, ensuring 64KB budget.

        Args:
            query: User query
            context: Retrieved context

        Returns:
            Tuple of (prepared_prompt, total_tokens, was_truncated)
        """
        query_tokens = self.count_tokens(query)
        context_tokens = self.count_tokens(context)

        available_for_context = (
            self.budget.total_tokens -
            self.budget.query_overhead -
            self.budget.response_headroom
        )

        was_truncated = False
        if context_tokens > available_for_context:
            context = self.truncate_to_budget(context, available_for_context)
            context_tokens = self.count_tokens(context)
            was_truncated = True

        total_tokens = query_tokens + context_tokens

        self._logger.debug(
            "context_prepared",
            query_tokens=query_tokens,
            context_tokens=context_tokens,
            total_tokens=total_tokens,
            was_truncated=was_truncated
        )

        return context, total_tokens, was_truncated


def estimate_tokens(text: str) -> int:
    """
    Estimate token count without tokenizer.

    Uses the approximation: 1 token ~= 4 characters for English text.
    This is conservative (tends to overestimate).
    """
    return len(text) // 4 + 1


# Module-level default context budget
DEFAULT_CONTEXT_BUDGET = ContextBudget()


def validate_ollama_context(context_size: int) -> bool:
    """
    Quick validation of Ollama context size.

    Args:
        context_size: Ollama's configured num_ctx

    Returns:
        True if meets 64KB requirement
    """
    return context_size >= RECOMMENDED_CONTEXT_TOKENS
```

---

## Manual Steps

### Step 1: Install tiktoken (Optional but Recommended)

```bash
# tiktoken provides accurate token counting
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pip install tiktoken
```

### Step 2: Create Context Manager Module

```bash
# Create the context_manager.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/rag/context_manager.py
```

### Step 3: Update Module Init

```bash
# Update __init__.py to include context_manager exports
cat << 'EOF' | sudo -u hx-lang-server tee -a /opt/hx-lang-server/app/rag/__init__.py

# Context management
from .context_manager import (
    ContextBudget,
    ContextChunk,
    ContextManager,
    DEFAULT_CONTEXT_BUDGET,
    MIN_CONTEXT_TOKENS,
    RECOMMENDED_CONTEXT_TOKENS,
    validate_ollama_context,
)
EOF
```

### Step 4: Validate Ollama Context Size

```bash
# Check that Ollama models are configured with 64KB context
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/show -d '{"name":"gemma3:27b"}' | jq '.parameters' | grep -i num_ctx
```

---

## Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# Context Configuration (64KB as per CAIO decision)
CONTEXT_TOTAL_TOKENS=65536
CONTEXT_QUERY_OVERHEAD=2048
CONTEXT_LOCAL_TOKENS=24576
CONTEXT_GLOBAL_TOKENS=24576
CONTEXT_RESPONSE_HEADROOM=14336
```

---

## Acceptance Criteria

- [ ] ContextBudget dataclass created with 64KB default allocation
- [ ] ContextManager class implemented with:
  - Token counting (tiktoken with fallback)
  - Context validation (>= 32KB minimum, >= 64KB recommended)
  - Intelligent truncation (sentence-aware)
  - Context assembly for hybrid mode
  - LLM preparation with budget enforcement
- [ ] Context budget properly allocates:
  - 2KB for query overhead
  - 24KB for local context
  - 24KB for global context
  - 14KB for response headroom
- [ ] Mode-specific budgets adjust allocation:
  - local: all retrieval budget to local
  - global: all retrieval budget to global
  - mix: 40/60 local/global split
  - hybrid: 50/50 split (default)
- [ ] Ollama context validation function works
- [ ] Truncation preserves sentence boundaries when possible

---

## Verification

```bash
# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
from app.rag.context_manager import (
    ContextBudget,
    ContextManager,
    ContextChunk,
    validate_ollama_context,
    RECOMMENDED_CONTEXT_TOKENS,
)

# Test budget allocation
budget = ContextBudget()
print(f"Total budget: {budget.total_tokens} tokens ({budget.total_tokens // 1024}KB)")
print(f"Query overhead: {budget.query_overhead}")
print(f"Local context: {budget.local_context_tokens}")
print(f"Global context: {budget.global_context_tokens}")
print(f"Response headroom: {budget.response_headroom}")
print(f"Available for retrieval: {budget.available_for_retrieval}")

# Verify 64KB total
assert budget.total_tokens == 65536, "Expected 64KB (65536 tokens)"

# Test mode budgets
local_budget = budget.for_mode("local")
assert local_budget.global_context_tokens == 0, "Local mode should have no global budget"
print(f"\nLocal mode budget: {local_budget.local_context_tokens} local, {local_budget.global_context_tokens} global")

global_budget = budget.for_mode("global")
assert global_budget.local_context_tokens == 0, "Global mode should have no local budget"
print(f"Global mode budget: {global_budget.local_context_tokens} local, {global_budget.global_context_tokens} global")

# Test context manager
manager = ContextManager()

# Test token counting
test_text = "This is a test sentence for token counting."
tokens = manager.count_tokens(test_text)
print(f"\nToken count for '{test_text}': {tokens}")

# Test truncation
long_text = "This is a long text. " * 1000
truncated = manager.truncate_to_budget(long_text, 100)
truncated_tokens = manager.count_tokens(truncated)
print(f"Truncated from {manager.count_tokens(long_text)} to {truncated_tokens} tokens")
assert truncated_tokens <= 105, "Truncation should respect budget (with small buffer)"

# Test Ollama validation
assert validate_ollama_context(65536), "64KB should pass validation"
assert validate_ollama_context(32768), "32KB should pass validation"
assert not validate_ollama_context(8192), "8KB should fail validation"

print("\n\nAll context handling tests passed!")
EOF
```

---

## Rollback

```bash
# Remove context manager module
sudo rm -f /opt/hx-lang-server/app/rag/context_manager.py

# Remove tiktoken if installed
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/pip uninstall -y tiktoken

# Remove environment variables
sudo -u hx-lang-server sed -i '/^CONTEXT_/d' /opt/hx-lang-server/.env
```

---

## Notes

- **Why 64KB vs 32KB**: While LightRAG requires minimum 32KB, the CAIO decision mandates 64KB for:
  - Complex entity-relationship graphs
  - Hybrid mode with both local and global context
  - Sufficient headroom for response generation

- **Ollama Modelfile**: Jim's work stream (Task 071) must create Modelfiles with:
  ```
  FROM gemma3:27b
  PARAMETER num_ctx 65536
  ```

- **Token Counting**: We use tiktoken for accuracy but fall back to character-based estimation (1 token ~= 4 chars) when unavailable.

- **Truncation Strategy**: The intelligent truncation preserves sentence boundaries to avoid cutting off mid-thought, which would confuse the LLM.

---

## Related Tasks

- **Task 071**: Ollama1 integration (must configure 64KB context)
- **Task 081**: LightRAG HTTP client (consumes context)
- **Task 082**: Adaptive retrieval (uses context manager)
- **Task 054**: RAG Agent worker (final consumer)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
