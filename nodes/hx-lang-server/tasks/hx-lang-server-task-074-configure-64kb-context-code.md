# Task: Configure 64KB Context for Code Operations

**Task ID:** hx-lang-server-task-074-configure-64kb-context-code
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:** hx-lang-server-task-072 (Ollama2 connection configured)
**Estimated Time:** 45 minutes

---

## Objective

Validate and ensure 64KB context window is properly configured for code operations on hx-ollama2-server. This enables complex code generation, multi-file context understanding, and comprehensive code review capabilities.

---

## Prerequisites

- [ ] Task 072 completed (Ollama2 code connection configured)
- [ ] Code model deployed on hx-ollama2-server (qwen2.5-coder or qwen3-coder)
- [ ] langchain-ollama>=0.2.0 installed
- [ ] hx-ollama2-server has sufficient VRAM for 64KB context

---

## Specification References

From node-spec.md (v2.1):
- **FR-013**: Service MUST validate Ollama model context size >= 64KB for Code operations
- **CAIO Decision**: 64KB context for Code operations
- **Ollama Routing Table**: Code queries use 64KB context on hx-ollama2-server

---

## Background: CAIO Decision Rationale

The 64KB context requirement for Code operations stems from:
1. **Multi-file context**: Understanding code across multiple files
2. **Complex refactoring**: Full function/class context needed
3. **Code review**: Reviewing large diffs or entire modules
4. **API implementation**: Complete interface definitions in context

---

## Steps

### Step 1: Verify Model Supports 64KB Context

```bash
# Determine which code model is deployed
MODEL_NAME=$(curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | \
  jq -r '.models[] | select(.name | contains("coder")) | .name' | head -1)

echo "Code model: $MODEL_NAME"

# Check model configuration
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/show \
  -d "{\"name\":\"$MODEL_NAME\"}" | jq '.parameters'
```

### Step 2: Create Custom Modelfile for Code Operations (If Needed)

If the deployed code model doesn't default to 64KB context:

```bash
# On hx-ollama2-server.hx.dev.local
# Determine base model
MODEL_NAME=$(ollama list | grep -i coder | awk '{print $1}' | head -1)

# Create Modelfile for code-optimized model
cat > /tmp/coder-64k.modelfile << EOF
FROM $MODEL_NAME

# Code-optimized parameters with 64KB context
PARAMETER num_ctx 65536
PARAMETER temperature 0.2
PARAMETER top_p 0.95
PARAMETER repeat_penalty 1.05

# System prompt for code operations
SYSTEM """You are an expert software engineer. When generating or reviewing code:
1. Follow best practices and design patterns
2. Write clean, maintainable, well-documented code
3. Consider edge cases and error handling
4. Provide explanations for complex logic
5. Use consistent formatting and naming conventions
"""
EOF

# Create the custom model
ollama create coder-64k -f /tmp/coder-64k.modelfile

# Verify creation
ollama list | grep coder-64k
```

### Step 3: Validate Task 072 Implementation

Verify `/opt/hx-lang-server/app/llm/ollama_code.py` contains:

```python
# Verify these exist from Task 072
CODE_CONTEXT_SIZE = 65536  # 64KB

def create_code_llm(
    temperature: float = 0.2,
    num_ctx: int = CODE_CONTEXT_SIZE,  # Must default to 64KB
    ...
) -> ChatOllama:
    # FR-013 validation
    if num_ctx < 65536:
        num_ctx = 65536  # Enforce minimum
    ...
```

### Step 4: Create Code Context Validation Function

Add to `/opt/hx-lang-server/app/llm/ollama_code.py`:

```python
import httpx

async def validate_code_context_size() -> dict:
    """
    Validate that the code model supports 64KB context.

    Per FR-013, code operations require >= 64KB context.

    Returns:
        Dictionary with validation results

    Raises:
        RuntimeError: If validation fails
    """
    CODE_MINIMUM_CONTEXT = 65536

    async with httpx.AsyncClient(timeout=30.0) as client:
        # Get model info
        response = await client.post(
            f"{OLLAMA_CODE_URL}/api/show",
            json={"name": OLLAMA_CODE_MODEL}
        )
        model_info = response.json()

        # Test with 64KB context
        test_response = await client.post(
            f"{OLLAMA_CODE_URL}/api/generate",
            json={
                "model": OLLAMA_CODE_MODEL,
                "prompt": "test",
                "options": {"num_ctx": CODE_MINIMUM_CONTEXT},
                "stream": False,
            }
        )

    if test_response.status_code != 200:
        raise RuntimeError(
            f"Code model cannot support {CODE_MINIMUM_CONTEXT} context: "
            f"{test_response.text}"
        )

    logger.info(
        "code_context_validated",
        model=OLLAMA_CODE_MODEL,
        context_size=CODE_MINIMUM_CONTEXT,
        result="PASS",
    )

    return {
        "model": OLLAMA_CODE_MODEL,
        "required_context_kb": CODE_MINIMUM_CONTEXT // 1024,
        "configured_context": CODE_MINIMUM_CONTEXT,
        "validation": "PASS",
    }


def enforce_code_context_minimum(num_ctx: int) -> int:
    """
    Enforce minimum context size for code operations.

    Per FR-013, code operations require >= 64KB context.

    Args:
        num_ctx: Requested context size

    Returns:
        Context size (at least 64KB)
    """
    CODE_MINIMUM = 65536

    if num_ctx < CODE_MINIMUM:
        logger.warning(
            "code_context_below_minimum",
            requested=num_ctx,
            enforced=CODE_MINIMUM,
        )
        return CODE_MINIMUM

    return num_ctx
```

### Step 5: Verify Environment Variables

Check `/opt/hx-lang-server/.env` contains (from Task 072):

```bash
# Code Context Configuration (CAIO Decision: 64KB)
OLLAMA_CODE_CONTEXT=65536
```

### Step 6: Test 64KB Context Code Generation

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test 64KB context with complex code request
python3 << 'EOF'
from langchain_ollama import ChatOllama
import httpx

# Get available code model
response = httpx.get("http://hx-ollama2-server.hx.dev.local:11434/api/tags")
models = response.json().get("models", [])
code_model = next((m["name"] for m in models if "coder" in m["name"].lower()), None)

if not code_model:
    print("ERROR: No code model found")
    exit(1)

print(f"Using code model: {code_model}")

# Create code-configured LLM with 64KB context
llm = ChatOllama(
    base_url="http://hx-ollama2-server.hx.dev.local:11434",
    model=code_model,
    temperature=0.2,
    num_ctx=65536,  # 64KB context per CAIO decision
    timeout=180.0,
)

# Complex multi-file code context test
code_context = '''
# file: models/user.py
class User:
    def __init__(self, id: int, name: str, email: str):
        self.id = id
        self.name = name
        self.email = email

    def validate(self) -> bool:
        return bool(self.name and self.email and "@" in self.email)

# file: models/order.py
from typing import List
from decimal import Decimal

class OrderItem:
    def __init__(self, product_id: int, quantity: int, price: Decimal):
        self.product_id = product_id
        self.quantity = quantity
        self.price = price

    @property
    def subtotal(self) -> Decimal:
        return self.price * self.quantity

class Order:
    def __init__(self, user_id: int, items: List[OrderItem]):
        self.user_id = user_id
        self.items = items

    @property
    def total(self) -> Decimal:
        return sum(item.subtotal for item in self.items)
'''

query = f"""
Given the following code context:

{code_context}

Write a comprehensive OrderService class that:
1. Validates users before processing orders
2. Calculates totals with tax
3. Handles order cancellation
4. Includes proper error handling
5. Uses type hints throughout

Provide complete implementation with docstrings.
"""

print(f"Query length: {len(query)} characters")
print("Sending code generation query with 64KB context window...")

response = llm.invoke(query)
print(f"\nResponse preview:\n{response.content[:1000]}...")
print("\nSUCCESS: 64KB context code generation completed")
EOF
```

### Step 7: Benchmark Code Generation Performance

```bash
python3 << 'EOF'
import time
from langchain_ollama import ChatOllama
import httpx

# Get code model
response = httpx.get("http://hx-ollama2-server.hx.dev.local:11434/api/tags")
models = response.json().get("models", [])
code_model = next((m["name"] for m in models if "coder" in m["name"].lower()), None)

llm = ChatOllama(
    base_url="http://hx-ollama2-server.hx.dev.local:11434",
    model=code_model,
    num_ctx=65536,
    timeout=180.0,
)

# Test with progressively larger code contexts
test_cases = [
    ("Small (1KB)", "def hello(): pass\n" * 25),
    ("Medium (4KB)", "def hello(): pass\n" * 100),
    ("Large (16KB)", "def hello(): pass\n" * 400),
    ("XL (32KB)", "def hello(): pass\n" * 800),
]

print("Code Context Size Benchmarks:")
print("-" * 60)
print(f"Model: {code_model}")
print(f"Context window: 64KB")
print("-" * 60)

for label, context in test_cases:
    query = f"Review this code and suggest improvements:\n{context}"

    start = time.time()
    try:
        response = llm.invoke(query)
        duration = time.time() - start
        print(f"{label}: {duration:.2f}s - OK")
    except Exception as e:
        print(f"{label}: FAILED - {e}")

print("-" * 60)
print("Benchmark complete")
EOF
```

---

## Acceptance Criteria

- [ ] Code model verified capable of 64KB context
- [ ] Custom Modelfile created if needed for 64KB context
- [ ] CODE_CONTEXT_SIZE = 65536 enforced in create_code_llm
- [ ] validate_code_context_size function implemented
- [ ] enforce_code_context_minimum function implemented
- [ ] Environment variable OLLAMA_CODE_CONTEXT=65536 configured
- [ ] Complex code generation test completes with large context
- [ ] No context overflow errors with 64KB window
- [ ] Performance benchmarks documented

---

## Verification Commands

```bash
# Verify 64KB constant in code
grep -n "65536\|CODE_CONTEXT" /opt/hx-lang-server/app/llm/ollama_code.py

# Verify environment variable
grep OLLAMA_CODE_CONTEXT /opt/hx-lang-server/.env

# Check custom model exists (if created)
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | grep -i "coder-64k"

# Test model with 64KB context
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/generate \
  -d '{"model":"qwen2.5-coder:14b","prompt":"test","options":{"num_ctx":65536},"stream":false}' \
  | jq '.done'
```

---

## Rollback Procedure

1. Revert create_code_llm to use smaller context if memory issues
2. Remove custom Modelfile model if created
3. Restore original environment variables
4. Coordinate with William Chen if memory issues persist

---

## Related Tasks

- **Task 072:** Configure Ollama2 (code) connection
- **Task 073:** Configure 64KB context for RAG operations
- **Task 075:** Implement model routing based on query classification

---

## Notes

- CAIO Decision explicitly requires 64KB for Code operations
- Code models (qwen2.5-coder, qwen3-coder) typically support large contexts
- 30B models (qwen3-coder) require more VRAM for 64KB context
- If memory issues occur on hx-ollama2-server:
  - Escalate to William Chen (Infrastructure SME)
  - Consider using 14B model instead of 30B
  - Monitor VRAM usage during large context operations

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
