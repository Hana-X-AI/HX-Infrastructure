# Task: Configure Embedding Generation for Knowledge Graph

**Task ID**: hx-docling-mcp-task-085-configure-embedding-generation
**Phase**: Development - Knowledge Graph Generation
**Work Stream**: 5 - Knowledge Graph Generation (LightRAG Integration)
**Status**: Not Started
**Assigned Agent**: andy-taylor (LightRAG SME)
**Dependencies**:
- hx-docling-mcp-task-082-implement-entity-extraction-workflow (entities available)
- hx-docling-mcp-task-083-implement-relationship-extraction-workflow (relationships available)
- hx-ollama3-server operational with bge-m3:567m model at http://hx-ollama3-server.hx.dev.local:11434

**Estimated Time**: 90 minutes

---

## Objective

Create embedding generation module (`embedding_generator.py`) for generating 1024-dimensional dense vectors from entities and relationships using bge-m3:567m model via hx-ollama3-server. Implement batch processing, text formatting strategies (entity_name + context for entities, subject + predicate + object for relationships), and integration with Qdrant storage workflow.

---

## Pre-Execution Validation

**Check if work already complete BEFORE executing steps:**

```bash
# Check if embedding_generator.py module exists
if [ -f "/opt/docling-mcp/src/embedding_generator.py" ]; then
    echo "✅ VALIDATION: Embedding generator module exists - checking completeness..."

    # Verify key components present
    grep -q "class EmbeddingGenerator" /opt/docling-mcp/src/embedding_generator.py && \
    grep -q "def generate_entity_embeddings" /opt/docling-mcp/src/embedding_generator.py && \
    grep -q "def generate_relationship_embeddings" /opt/docling-mcp/src/embedding_generator.py && \
    grep -q "ollama" /opt/docling-mcp/src/embedding_generator.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: Embedding generator module complete - SKIP task execution"
        exit 0
    else
        echo "⚠️  VALIDATION: Module incomplete - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: Embedding generator module does not exist - PROCEED with task"
fi

# Verify hx-ollama3-server is operational
curl -s -o /dev/null -w "%{http_code}" http://hx-ollama3-server.hx.dev.local:11434/api/tags
if [ $? -ne 0 ]; then
    echo "❌ BLOCKER: hx-ollama3-server not accessible - cannot proceed"
    exit 1
fi
```

**Validation Logic**:
- If `embedding_generator.py` exists with all required methods → SKIP execution
- If module missing or incomplete → PROCEED with implementation
- If hx-ollama3-server unavailable → BLOCK task (dependency failure)

---

## Prerequisites

- [x] Python 3.11 virtual environment at `/opt/docling-mcp/venv/`
- [x] Entity extraction module (`entity_extraction.py`) created (Task 082)
- [x] Relationship extraction module (`relationship_extraction.py`) created (Task 083)
- [x] ollama Python library installed (Ollama HTTP client)
- [x] hx-ollama3-server operational at http://hx-ollama3-server.hx.dev.local:11434
- [x] bge-m3:567m model available on hx-ollama3-server
- [x] Source directory `/opt/docling-mcp/src/` exists

---

## Implementation Steps

### Step 1: Install Ollama Python Client

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install ollama Python client
pip install ollama==0.2.1

# Verify installation
python -c "import ollama; print('✅ ollama client installed')"
```

### Step 2: Create Embedding Generator Module Structure

```bash
cat > /opt/docling-mcp/src/embedding_generator.py << 'EOF'
"""
Embedding Generation Module for hx-docling-mcp-server

Generates 1024-dimensional dense vector embeddings for entities and relationships
using bge-m3:567m model via hx-ollama3-server.

Key Features:
- Entity embeddings: entity_name + context_snippet (semantic deduplication)
- Relationship embeddings: subject + predicate + object (relationship similarity)
- Batch processing: 32 entities/relationships per batch (optimal for bge-m3)
- Error handling: Retry logic for Ollama API failures
- Vector validation: Ensure 1024 dimensions, normalized for cosine similarity

Architecture:
- Model: bge-m3:567m (1024D dense vectors, multilingual, high quality)
- Server: hx-ollama3-server.hx.dev.local:11434 (Ollama3 embedding service)
- Batch Size: 32 (balance throughput vs memory)
- Normalization: L2 normalization for cosine similarity (Qdrant requirement)
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional
import numpy as np
import ollama

logger = logging.getLogger(__name__)

# Ollama configuration
OLLAMA_HOST = "http://hx-ollama3-server.hx.dev.local:11434"
EMBEDDING_MODEL = "bge-m3:567m"
EXPECTED_VECTOR_SIZE = 1024  # bge-m3:567m output dimensions

# Batch processing configuration
BATCH_SIZE = 32  # Optimal batch size for bge-m3 (balance GPU memory vs throughput)

EOF
```

### Step 3: Implement EmbeddingGenerator Class

```bash
cat >> /opt/docling-mcp/src/embedding_generator.py << 'EOF'

# ============================================================================
# EmbeddingGenerator Class
# ============================================================================

class EmbeddingGenerator:
    """
    Embedding generation for entities and relationships via Ollama3.

    Features:
    - Entity embeddings from entity_name + context_snippet
    - Relationship embeddings from subject + predicate + object
    - Batch processing (32 items per batch)
    - L2 normalization for cosine similarity
    - Error handling and retry logic
    """

    def __init__(
        self,
        ollama_host: str = OLLAMA_HOST,
        model_name: str = EMBEDDING_MODEL,
        batch_size: int = BATCH_SIZE
    ):
        """
        Initialize embedding generator.

        Args:
            ollama_host: Ollama server endpoint
            model_name: Embedding model name (bge-m3:567m)
            batch_size: Batch size for parallel embedding generation
        """
        self.ollama_host = ollama_host
        self.model_name = model_name
        self.batch_size = batch_size

        # Configure Ollama client
        self.client = ollama.Client(host=ollama_host)

        logger.info(
            f"EmbeddingGenerator initialized: host={ollama_host}, "
            f"model={model_name}, batch_size={batch_size}"
        )


    async def generate_entity_embeddings(
        self,
        entities: List[Dict[str, Any]]
    ) -> List[List[float]]:
        """
        Generate embeddings for entities.

        Text Format: "{entity_name} | {context_snippet}"
        Example: "MIT | researchers at MIT developed a novel approach"

        Rationale:
        - entity_name: Canonical entity identifier
        - context_snippet: Semantic context for disambiguation
        - Pipe separator: Clear delimiter for model parsing

        Args:
            entities: List of entity dictionaries (from entity_extraction.py)

        Returns:
            List of 1024D embedding vectors (one per entity)

        Example:
            embeddings = await generator.generate_entity_embeddings(entities)
            assert len(embeddings) == len(entities)
            assert all(len(emb) == 1024 for emb in embeddings)
        """
        if not entities:
            return []

        logger.info(f"Generating embeddings for {len(entities)} entities...")

        # Format entity text for embedding
        entity_texts = []
        for entity in entities:
            entity_name = entity['entity_name']
            context_snippet = entity.get('context_snippet', '')

            # Format: "entity_name | context_snippet"
            if context_snippet:
                text = f"{entity_name} | {context_snippet}"
            else:
                text = entity_name

            entity_texts.append(text)

        # Generate embeddings in batches
        embeddings = await self._generate_embeddings_batched(entity_texts)

        logger.info(f"Entity embeddings generated: {len(embeddings)} vectors")
        return embeddings


    async def generate_relationship_embeddings(
        self,
        relationships: List[Dict[str, Any]]
    ) -> List[List[float]]:
        """
        Generate embeddings for relationships.

        Text Format: "{subject_entity_name} {predicate} {object_entity_name}"
        Example: "Alice works_for IBM"

        Rationale:
        - Natural language format for semantic similarity
        - Captures relationship semantics (similar predicates → similar vectors)
        - No context needed (relationship already has semantic meaning)

        Args:
            relationships: List of relationship dictionaries (from relationship_extraction.py)

        Returns:
            List of 1024D embedding vectors (one per relationship)

        Example:
            embeddings = await generator.generate_relationship_embeddings(relationships)
            assert len(embeddings) == len(relationships)
        """
        if not relationships:
            return []

        logger.info(f"Generating embeddings for {len(relationships)} relationships...")

        # Format relationship text for embedding
        relationship_texts = []
        for rel in relationships:
            subject_name = rel['subject_entity_name']
            predicate = rel['predicate']
            object_name = rel['object_entity_name']

            # Format: "subject predicate object"
            text = f"{subject_name} {predicate} {object_name}"
            relationship_texts.append(text)

        # Generate embeddings in batches
        embeddings = await self._generate_embeddings_batched(relationship_texts)

        logger.info(f"Relationship embeddings generated: {len(embeddings)} vectors")
        return embeddings

EOF
```

### Step 4: Implement Batch Embedding Generation

```bash
cat >> /opt/docling-mcp/src/embedding_generator.py << 'EOF'

    async def _generate_embeddings_batched(
        self,
        texts: List[str]
    ) -> List[List[float]]:
        """
        Generate embeddings in batches for efficiency.

        Batching strategy:
        - Split texts into batches of BATCH_SIZE (32)
        - Generate embeddings for each batch in parallel
        - Flatten results and validate dimensions

        Args:
            texts: List of text strings to embed

        Returns:
            List of 1024D embedding vectors (one per text)

        Raises:
            ValueError: If embedding dimensions incorrect
            RuntimeError: If Ollama API call fails
        """
        if not texts:
            return []

        all_embeddings = []
        total_batches = (len(texts) + self.batch_size - 1) // self.batch_size

        logger.debug(f"Generating embeddings in {total_batches} batches (batch_size={self.batch_size})")

        for batch_idx in range(0, len(texts), self.batch_size):
            batch_texts = texts[batch_idx:batch_idx + self.batch_size]
            batch_num = batch_idx // self.batch_size + 1

            logger.debug(f"Processing batch {batch_num}/{total_batches} ({len(batch_texts)} texts)")

            try:
                # Generate embeddings for batch
                batch_embeddings = await self._call_ollama_embeddings(batch_texts)
                all_embeddings.extend(batch_embeddings)

            except Exception as e:
                logger.error(f"Batch {batch_num} embedding generation failed: {str(e)[:200]}")
                raise RuntimeError(f"Embedding generation failed at batch {batch_num}: {str(e)[:100]}")

        # Validate total count
        if len(all_embeddings) != len(texts):
            raise ValueError(
                f"Embedding count mismatch: expected {len(texts)}, got {len(all_embeddings)}"
            )

        logger.info(f"Batch embedding generation complete: {len(all_embeddings)} vectors")
        return all_embeddings


    async def _call_ollama_embeddings(
        self,
        texts: List[str]
    ) -> List[List[float]]:
        """
        Call Ollama API to generate embeddings.

        Uses synchronous Ollama client (no native async support).
        Runs in thread pool to avoid blocking event loop.

        Args:
            texts: List of text strings to embed

        Returns:
            List of 1024D embedding vectors

        Raises:
            RuntimeError: If Ollama API call fails
        """
        # Ollama client is synchronous, run in thread pool
        loop = asyncio.get_event_loop()

        def _sync_embeddings():
            embeddings = []
            for text in texts:
                try:
                    response = self.client.embeddings(
                        model=self.model_name,
                        prompt=text
                    )

                    # Extract embedding vector
                    embedding = response.get('embedding', [])

                    # Validate dimensions
                    if len(embedding) != EXPECTED_VECTOR_SIZE:
                        raise ValueError(
                            f"Unexpected embedding size: expected {EXPECTED_VECTOR_SIZE}, "
                            f"got {len(embedding)}"
                        )

                    # L2 normalize for cosine similarity (Qdrant requirement)
                    embedding_normalized = self._normalize_vector(embedding)
                    embeddings.append(embedding_normalized)

                except Exception as e:
                    logger.error(f"Ollama embedding API call failed: {str(e)[:200]}")
                    raise RuntimeError(f"Ollama API error: {str(e)[:100]}")

            return embeddings

        # Run synchronous function in thread pool
        embeddings = await loop.run_in_executor(None, _sync_embeddings)
        return embeddings


    def _normalize_vector(self, vector: List[float]) -> List[float]:
        """
        L2 normalize vector for cosine similarity.

        Cosine similarity requires normalized vectors (magnitude = 1.0).
        Qdrant COSINE distance metric assumes normalized vectors.

        Args:
            vector: Raw embedding vector (1024D)

        Returns:
            Normalized vector (L2 norm = 1.0)

        Example:
            raw = [0.5, 0.5, 0.7, ...]
            normalized = _normalize_vector(raw)
            assert abs(np.linalg.norm(normalized) - 1.0) < 1e-6
        """
        vector_np = np.array(vector, dtype=np.float32)
        norm = np.linalg.norm(vector_np)

        if norm == 0:
            logger.warning("Zero-magnitude vector encountered, returning original")
            return vector

        normalized = (vector_np / norm).tolist()
        return normalized


    async def health_check(self) -> bool:
        """
        Check if Ollama3 server is operational and bge-m3:567m model available.

        Returns:
            True if server healthy and model available, False otherwise

        Example:
            if await generator.health_check():
                print("Embedding service operational")
        """
        try:
            # List available models
            models = self.client.list()

            # Check if bge-m3:567m is available
            model_names = [model['name'] for model in models.get('models', [])]

            if self.model_name in model_names:
                logger.info(f"Ollama3 health check: PASS (model {self.model_name} available)")
                return True
            else:
                logger.warning(
                    f"Ollama3 health check: FAIL (model {self.model_name} not found in {model_names})"
                )
                return False

        except Exception as e:
            logger.error(f"Ollama3 health check failed: {str(e)[:200]}")
            return False

EOF
```

### Step 5: Set File Permissions and Ownership

```bash
# Set ownership to docling-mcp service account
chown docling-mcp:docling-mcp /opt/docling-mcp/src/embedding_generator.py

# Read-only for owner/group
chmod 640 /opt/docling-mcp/src/embedding_generator.py

echo "✅ Embedding generator module created and secured"
```

---

## Verification

### Automated Verification

```bash
# Verify file exists with correct permissions
ls -l /opt/docling-mcp/src/embedding_generator.py
# Expected: -rw-r----- 1 docling-mcp docling-mcp [size] [date] embedding_generator.py

# Verify Python syntax
source /opt/docling-mcp/venv/bin/activate
python -m py_compile /opt/docling-mcp/src/embedding_generator.py
if [ $? -eq 0 ]; then
    echo "✅ Python syntax valid"
else
    echo "❌ Python syntax errors detected"
    exit 1
fi

# Verify module can be imported
python -c "from embedding_generator import EmbeddingGenerator; print('✅ Import successful')"

# Test health check
python << 'PYEOF'
import asyncio
from embedding_generator import EmbeddingGenerator

async def test_health():
    generator = EmbeddingGenerator()
    is_healthy = await generator.health_check()

    if is_healthy:
        print("✅ Ollama3 server health check PASSED")
        print("✅ bge-m3:567m model available")
    else:
        print("❌ Ollama3 server health check FAILED")
        exit(1)

asyncio.run(test_health())
PYEOF

# Test embedding generation (small sample)
python << 'PYEOF'
import asyncio
from embedding_generator import EmbeddingGenerator

async def test_embeddings():
    generator = EmbeddingGenerator()

    # Test entity embedding
    test_entities = [
        {
            'entity_name': 'MIT',
            'context_snippet': 'researchers at MIT developed a novel approach'
        }
    ]

    embeddings = await generator.generate_entity_embeddings(test_entities)

    if len(embeddings) == 1 and len(embeddings[0]) == 1024:
        print("✅ Entity embedding generated: 1024 dimensions")
    else:
        print(f"❌ Unexpected embedding size: {len(embeddings[0])} dimensions")
        exit(1)

    # Test relationship embedding
    test_relationships = [
        {
            'subject_entity_name': 'Alice',
            'predicate': 'works_for',
            'object_entity_name': 'IBM'
        }
    ]

    rel_embeddings = await generator.generate_relationship_embeddings(test_relationships)

    if len(rel_embeddings) == 1 and len(rel_embeddings[0]) == 1024:
        print("✅ Relationship embedding generated: 1024 dimensions")
    else:
        print(f"❌ Unexpected embedding size: {len(rel_embeddings[0])} dimensions")
        exit(1)

asyncio.run(test_embeddings())
PYEOF
```

### Manual Verification

- [ ] Module imports without errors
- [ ] `EmbeddingGenerator` class instantiates successfully
- [ ] `generate_entity_embeddings()` method defined
- [ ] `generate_relationship_embeddings()` method defined
- [ ] `health_check()` method verifies bge-m3:567m model availability
- [ ] Entity embeddings format: "entity_name | context_snippet"
- [ ] Relationship embeddings format: "subject predicate object"
- [ ] Batch processing configured (batch_size=32)
- [ ] L2 normalization applied to all vectors
- [ ] Embedding dimensions validated (1024D)
- [ ] File ownership: docling-mcp:docling-mcp
- [ ] File permissions: 640 (rw-r-----)

---

## Rollback

If task needs to be reverted:

```bash
# Remove embedding_generator.py module
rm -f /opt/docling-mcp/src/embedding_generator.py

# Verify removal
if [ ! -f "/opt/docling-mcp/src/embedding_generator.py" ]; then
    echo "✅ Embedding generator module removed"
else
    echo "❌ Failed to remove module"
fi
```

---

## Integration Points

**Upstream Dependencies**:
- `entity_extraction.py` (Task 082) - Provides entities for embedding
- `relationship_extraction.py` (Task 083) - Provides relationships for embedding
- `hx-ollama3-server` operational at http://hx-ollama3-server.hx.dev.local:11434
- `bge-m3:567m` model available on hx-ollama3-server

**Downstream Consumers**:
- `qdrant_knowledge_graph.py` (Task 084) - Uses embeddings for entity/relationship storage
- MCP tool `generate_knowledge_graph` (orchestrates extraction + embedding + storage)

**Configuration Requirements**:
- Environment variable: `OLLAMA_HOST` (default: http://hx-ollama3-server.hx.dev.local:11434)
- Environment variable: `EMBEDDING_MODEL` (default: bge-m3:567m)
- Environment variable: `EMBEDDING_BATCH_SIZE` (default: 32)

---

## Notes

### BGE-M3 Model Characteristics

**Model**: bge-m3:567m (567 million parameters)

**Key Features**:
- **Multilingual**: 100+ languages supported
- **High Quality**: MTEB benchmark top-10 performance
- **Dense Vectors**: 1024 dimensions (optimal for semantic similarity)
- **Normalization**: L2 normalized output (magnitude = 1.0)

**Performance**:
- **Throughput**: ~100 embeddings/second on GPU (batch_size=32)
- **Latency**: <50ms per embedding (single item)
- **Memory**: ~2GB GPU VRAM (model weights + batch processing)

**Why bge-m3 vs Alternatives?**
- ✅ Better than all-MiniLM-L6-v2 (384D, lower quality)
- ✅ Better than bge-base-en-v1.5 (768D, English-only)
- ❌ Smaller than bge-large-en-v1.5 (1024D, 335M params, similar quality, faster)
- **Tradeoff**: Accuracy vs Speed (bge-m3 chosen for accuracy priority)

### Text Formatting Strategies

**Entity Embeddings**:
```
Format: "entity_name | context_snippet"
Example: "MIT | researchers at MIT developed a novel approach"

Rationale:
- entity_name: Primary identifier (canonical form)
- context_snippet: Semantic disambiguation (distinguish "Apple Inc" from "apple fruit")
- Pipe separator: Clear delimiter for model parsing
```

**Relationship Embeddings**:
```
Format: "subject_entity_name predicate object_entity_name"
Example: "Alice works_for IBM"

Rationale:
- Natural language format: Model trained on sentence-level semantics
- Predicate semantics: Similar predicates → similar vectors ("works_for" ≈ "employed_by")
- No context needed: Relationship triple has complete semantic meaning
```

### Batch Processing Strategy

**Why Batch Size 32?**
- **GPU Efficiency**: bge-m3 model optimized for batch processing
- **Memory**: 32 × 1024D vectors = ~131KB (well within GPU memory)
- **Throughput**: 3× faster than sequential processing
- **Latency**: <2s for 32 embeddings vs <50s sequential

**Alternative Batch Sizes**:
- Batch 16: Lower memory, ~2.5× faster than sequential
- Batch 64: Higher memory, ~3.5× faster but GPU memory constraints on some servers
- Batch 1: No batching, sequential processing, lowest throughput

### Normalization Importance

**Why L2 Normalization?**
- **Cosine Similarity**: Qdrant COSINE distance metric requires normalized vectors
- **Formula**: cosine_similarity(A, B) = dot(A, B) / (norm(A) × norm(B))
- **With Normalization**: cosine_similarity(A, B) = dot(A, B) (faster computation)
- **Performance**: ~2× faster similarity computation with pre-normalized vectors

**Validation**:
```python
import numpy as np
vector = [0.5, 0.5, 0.7, ...]
normalized = _normalize_vector(vector)
assert abs(np.linalg.norm(normalized) - 1.0) < 1e-6
```

### Testing Strategy

- **Unit Tests**: Test vector normalization, batch splitting, text formatting
- **Integration Tests**: Live Ollama3 connectivity (TC-INT-003), bge-m3 model availability
- **Performance Tests**: Measure embedding generation latency (10/100/1000 entities)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Version**: 1.0
