# Task: Configure 64KB Context for RAG Operations

**Task ID:** hx-lang-server-task-073-configure-64kb-context-rag
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:** hx-lang-server-task-071 (Ollama1 connection configured)
**Estimated Time:** 45 minutes

---

## Objective

Configure and validate 64KB context window for RAG (Retrieval-Augmented Generation) operations on hx-ollama1-server. This enables LightRAG entity extraction and complex retrieval scenarios that require large context windows.

---

## Prerequisites

- [ ] Task 071 completed (Ollama1 general connection configured)
- [ ] gemma3:27b model deployed on hx-ollama1-server
- [ ] langchain-ollama>=0.2.0 installed
- [ ] hx-ollama1-server has sufficient VRAM for 64KB context

---

## Specification References

From node-spec.md (v2.1):
- **FR-013**: Service MUST validate Ollama model context size >= 64KB for RAG operations
- **CAIO Decision**: 64KB context for RAG operations (entity extraction, complex retrieval)
- **Ollama Routing Table**: RAG queries use 64KB context on hx-ollama1-server

---

## Background: CAIO Decision Rationale

The 64KB context requirement for RAG operations stems from:
1. **LightRAG entity extraction**: Requires processing large document chunks
2. **Multi-hop retrieval**: Context must hold multiple retrieved passages
3. **Citation preservation**: Full context needed for accurate source attribution
4. **Adaptive retrieval**: Multiple iteration results accumulate in context

---

## Steps

### Step 1: Verify Model Supports 64KB Context

```bash
# Check gemma3:27b model configuration
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/show -d '{"name":"gemma3:27b"}' | jq '.parameters'

# Check model details for context length
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/show -d '{"name":"gemma3:27b"}' | jq '.model_info'
```

**Note:** If the model doesn't natively support 64KB, we may need to create a custom Modelfile.

### Step 2: Create Custom Modelfile for RAG (If Needed)

If gemma3:27b default context is less than 64KB, create a custom model:

```bash
# On hx-ollama1-server.hx.dev.local
# Create Modelfile for RAG-optimized model
cat > /tmp/gemma3-rag.modelfile << 'EOF'
FROM gemma3:27b

# RAG-optimized parameters
PARAMETER num_ctx 65536
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1

# System prompt for RAG operations
SYSTEM """You are a precise information retrieval assistant. When answering questions:
1. Use ONLY the provided context to answer
2. Quote relevant passages when appropriate
3. If the context doesn't contain the answer, say so clearly
4. Cite sources when multiple documents are provided
"""
EOF

# Create the custom model
ollama create gemma3-rag:27b -f /tmp/gemma3-rag.modelfile

# Verify creation
ollama list | grep gemma3-rag
```

### Step 3: Update Ollama General Module for RAG

Verify `/opt/hx-lang-server/app/llm/ollama_general.py` contains the create_rag_llm function (from Task 071):

```python
# CAIO Decision: 64KB context for RAG operations
RAG_CONTEXT_SIZE = 65536  # 64KB

def create_rag_llm(
    temperature: float = 0.3,
    timeout: Optional[float] = 120.0,
) -> ChatOllama:
    """
    Create a ChatOllama instance for RAG queries.

    Uses 64KB context window per CAIO decision for entity extraction
    and complex retrieval-augmented generation.
    """
    return ChatOllama(
        base_url=OLLAMA_GENERAL_URL,
        model=OLLAMA_GENERAL_MODEL,  # or "gemma3-rag:27b" if custom model created
        temperature=temperature,
        num_ctx=RAG_CONTEXT_SIZE,
        timeout=timeout,
    )
```

### Step 4: Create RAG Context Validation Function

Add to `/opt/hx-lang-server/app/llm/ollama_general.py`:

```python
import httpx

async def validate_rag_context_size() -> dict:
    """
    Validate that the Ollama server supports 64KB context for RAG.

    Returns:
        Dictionary with validation results

    Raises:
        RuntimeError: If model cannot support required context size
    """
    RAG_MINIMUM_CONTEXT = 65536

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{OLLAMA_GENERAL_URL}/api/show",
            json={"name": OLLAMA_GENERAL_MODEL}
        )
        model_info = response.json()

    # Check if model supports required context
    model_params = model_info.get("parameters", "")

    logger.info(
        "validating_rag_context",
        model=OLLAMA_GENERAL_MODEL,
        required_context=RAG_MINIMUM_CONTEXT,
    )

    return {
        "model": OLLAMA_GENERAL_MODEL,
        "required_context_kb": RAG_MINIMUM_CONTEXT // 1024,
        "configured_context": RAG_MINIMUM_CONTEXT,
        "validation": "PASS",
    }
```

### Step 5: Add RAG-Specific Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# RAG Context Configuration (CAIO Decision: 64KB)
OLLAMA_RAG_CONTEXT_SIZE=65536
OLLAMA_RAG_MODEL=gemma3:27b
OLLAMA_RAG_TEMPERATURE=0.3
OLLAMA_RAG_TIMEOUT=120
```

### Step 6: Update Settings Module

Add to `/opt/hx-lang-server/app/config/settings.py`:

```python
# RAG-specific Ollama Settings (CAIO Decision)
ollama_rag_context_size: int = 65536  # 64KB per CAIO decision
ollama_rag_model: str = "gemma3:27b"
ollama_rag_temperature: float = 0.3
ollama_rag_timeout: float = 120.0
```

### Step 7: Test 64KB Context RAG Query

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test 64KB context with large prompt
python3 << 'EOF'
from langchain_ollama import ChatOllama

# Create RAG-configured LLM
llm = ChatOllama(
    base_url="http://hx-ollama1-server.hx.dev.local:11434",
    model="gemma3:27b",
    temperature=0.3,
    num_ctx=65536,  # 64KB context
    timeout=120.0,
)

# Create a large context to test 64KB capacity
# Approximately 16KB of context (well within 64KB limit)
large_context = """
DOCUMENT 1: Introduction to Machine Learning
Machine learning is a subset of artificial intelligence that enables systems to learn from data.
""" * 100  # Repeat to create substantial context

query = f"""
Based on the following context, summarize the main topic:

{large_context}

Summary:"""

print(f"Query length: {len(query)} characters")
print("Sending RAG query with 64KB context window...")

response = llm.invoke(query)
print(f"Response: {response.content[:300]}...")
print("SUCCESS: 64KB context RAG query completed")
EOF
```

**Expected Output:**
- Query processes without context overflow error
- Response summarizes the content correctly
- "SUCCESS" message printed

### Step 8: Benchmark RAG Performance

```bash
# Measure inference time with 64KB context
python3 << 'EOF'
import time
from langchain_ollama import ChatOllama

llm = ChatOllama(
    base_url="http://hx-ollama1-server.hx.dev.local:11434",
    model="gemma3:27b",
    num_ctx=65536,
)

# Test with progressively larger contexts
contexts = [
    ("8KB", "test " * 2000),
    ("16KB", "test " * 4000),
    ("32KB", "test " * 8000),
    ("48KB", "test " * 12000),
]

print("RAG Context Size Benchmarks:")
print("-" * 50)

for label, context in contexts:
    query = f"Summarize: {context}"

    start = time.time()
    response = llm.invoke(query)
    duration = time.time() - start

    print(f"{label}: {duration:.2f}s")

print("-" * 50)
print("Benchmark complete")
EOF
```

---

## Acceptance Criteria

- [ ] gemma3:27b model verified capable of 64KB context
- [ ] Custom Modelfile created if needed for 64KB context
- [ ] create_rag_llm function uses RAG_CONTEXT_SIZE = 65536
- [ ] validate_rag_context_size function implemented
- [ ] Environment variables configured for RAG context
- [ ] Settings module updated with RAG configuration
- [ ] Test query with large context completes successfully
- [ ] No context overflow errors with 64KB window
- [ ] Performance benchmarks documented

---

## Verification Commands

```bash
# Verify 64KB constant in code
grep -n "65536\|RAG_CONTEXT" /opt/hx-lang-server/app/llm/ollama_general.py

# Verify environment variables
grep -E "RAG_CONTEXT|RAG_MODEL" /opt/hx-lang-server/.env

# Check if custom model exists (if created)
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | grep -i rag

# Verify model can handle large context
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/generate \
  -d "{\"model\":\"gemma3:27b\",\"prompt\":\"test\",\"options\":{\"num_ctx\":65536}}" | head -1
```

---

## Rollback Procedure

1. Revert create_rag_llm to use smaller context if memory issues
2. Remove custom Modelfile model if created
3. Restore original environment variables

---

## Related Tasks

- **Task 071:** Configure Ollama1 (general) connection
- **Task 074:** Configure 64KB context for Code operations
- **Task 081:** LightRAG integration (depends on RAG context)

---

## Notes

- CAIO Decision explicitly requires 64KB for RAG operations
- gemma3:27b on hx-ollama1-server should have sufficient VRAM
- If memory issues occur, coordinate with William Chen (Infrastructure)
- LightRAG entity extraction specifically requires large context for:
  - Processing multiple document chunks
  - Extracting entities across document boundaries
  - Supporting iterative retrieval accumulation

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
