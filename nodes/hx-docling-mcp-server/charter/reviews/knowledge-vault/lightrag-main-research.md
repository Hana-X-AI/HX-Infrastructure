# LightRAG Comprehensive Research Report

## Executive Summary

LightRAG is a **knowledge graph-based RAG (Retrieval-Augmented Generation)** system that differs fundamentally from traditional vector-only RAG by extracting structured entities, relationships, and keywords from documents to build a knowledge graph. This enables more sophisticated, semantic-aware retrieval through dual-level mechanisms (local and global) and provides superior context for LLM-based synthesis.

**Repository**: HKUDS/LightRAG (GitHub)
**Key Publication**: arXiv:2410.05779
**Status**: Active development (Last update: Nov 2024)

---

## I. ARCHITECTURE & DESIGN PHILOSOPHY

### Core Insight
Traditional RAG relies on simple vector similarity matching. LightRAG introduces:
1. **Entity Extraction** - Identify key actors, concepts, organizations
2. **Relationship Modeling** - Understand connections between entities
3. **Keyword Extraction** - Capture high and low-level semantic signals
4. **Dual-Level Retrieval** - Query at both local (entity-centric) and global (relationship) levels

### Processing Pipeline

```
Document Ingestion
        ↓
Text Chunking (1200 tokens default, 100 token overlap)
        ↓
Entity & Relationship Extraction (LLM-driven)
        ↓
Graph Building (merge duplicate entities/relationships)
        ↓
Vector Embedding (chunks, entities, relationships)
        ↓
Storage in 4 Storage Layers:
  - KV Storage (metadata, LLM cache, chunks)
  - Vector Storage (embeddings for retrieval)
  - Graph Storage (knowledge graph structure)
  - Doc Status Storage (processing pipeline state)
        ↓
Query Processing (local/global/hybrid/mix modes)
        ↓
LLM Synthesis with Retrieved Context
```

### Design Principles
- **Quality First**: High-quality entity extraction prioritized over speed
- **Incremental Updates**: Add documents without full rebuilds
- **Multi-Backend Support**: Pluggable storage implementations
- **LLM-Agnostic**: Works with OpenAI, Ollama, Hugging Face, Upstage, LlamaIndex
- **Production-Ready**: API server with Docker, systemd, authentication

---

## II. ENTITY EXTRACTION & KNOWLEDGE GRAPH BUILDING

### Entity Extraction Process

**Default Entity Types** (configurable):
- Person
- Creature
- Organization
- Location
- Event
- Concept
- Method
- Content
- Data
- Artifact
- NaturalObject

### Extraction Mechanism

1. **LLM-Driven Parsing**: Uses structured prompts to extract:
   - Entity name (title-cased for consistency)
   - Entity type (from predefined list)
   - Description (multi-sentence summary)

2. **Relationship Extraction**: Each relationship includes:
   - Source entity name
   - Target entity name
   - Keywords (high-level semantic tags)
   - Description (nature of relationship)
   - Weight (importance score, default 1.0)

3. **N-ary Relationship Decomposition**: Complex relationships with 3+ entities are decomposed into binary pairs

4. **Output Format**: Fixed delimiter-based parsing
   ```
   entity<|#|>entity_name<|#|>entity_type<|#|>description
   relation<|#|>source<|#|>target<|#|>keywords<|#|>description
   <|COMPLETE|>
   ```

5. **Gleaning (Error Recovery)**: 
   - If extraction incomplete (default MAX_GLEANING=1)
   - LLM attempts to fill missed entities/relationships
   - Iterative refinement with history context

### Entity Merging Strategy

When duplicate entities appear across documents:

1. **Description Merging** (Map-Reduce approach):
   - Split descriptions if total tokens exceed summary_context_size
   - Use LLM to synthesize summaries recursively
   - Preserves all information while respecting token limits
   - Tracks whether LLM was needed vs simple concatenation

2. **Merge Criteria**:
   - Entity names must match (case-insensitive, title-cased)
   - Type consistency validated
   - Description synthesis limited by:
     - `summary_max_tokens`: 1200 (max output length)
     - `summary_context_size`: 12000 (max input length)
     - `force_llm_summary_on_merge`: 8 (threshold for forcing LLM)

3. **Relationship Merging**: Same principle applied to relationship descriptions

---

## III. STORAGE BACKENDS & VECTOR DATABASE INTEGRATION

### 4-Layer Storage Architecture

**1. KV Storage** (Key-Value for metadata)
- Text chunks and their content
- LLM response cache (reduces duplicate API calls)
- Document metadata
- Full documents
- Processing status tracking

**Implementations**:
```
JsonKVStorage        (default - local JSON files)
PGKVStorage          (PostgreSQL)
RedisKVStorage       (Redis in-memory)
MongoKVStorage       (MongoDB)
```

**2. Vector Storage** (Embeddings for similarity search)
- Entity embeddings (semantic meaning of entities)
- Relationship embeddings (semantic meaning of connections)
- Chunk embeddings (document content)
- Cosine distance metric (default)
- Configurable similarity threshold (default: 0.2)

**Implementations**:
```
NanoVectorDBStorage  (default - lightweight embedded)
QdrantVectorDBStorage (Qdrant vector DB) ← SUPPORTS BOTH REMOTE & LOCAL
PGVectorStorage      (PostgreSQL pgvector extension)
MilvusVectorDBStorage (Milvus distributed vector DB)
FaissVectorDBStorage (Meta's FAISS - CPU/GPU)
MongoVectorDBStorage (MongoDB native vector search - Atlas only)
ChromaVectorDBStorage (deprecated - Chroma)
```

**3. Graph Storage** (Knowledge graph structure)
- Entity nodes with properties
- Relationship edges with weights
- Full ACID properties (except NetworkX)

**Implementations**:
```
NetworkXStorage      (default - in-memory Python library)
Neo4JStorage         (Neo4j - RECOMMENDED for production)
PGGraphStorage       (PostgreSQL with Apache AGE extension)
MemgraphStorage      (Memgraph - Neo4j compatible)
MongoGraphStorage    (MongoDB collections as graph)
```

**4. Document Status Storage** (Pipeline state tracking)
- Document processing state (pending/processing/processed/failed)
- Chunk extraction results
- Error tracking
- Timestamp tracking

**Implementations**:
```
JsonDocStatusStorage (default - local JSON files)
PGDocStatusStorage   (PostgreSQL)
MongoDocStatusStorage (MongoDB)
```

### Qdrant Vector Storage Details (Supported)

**Configuration**:
```python
rag = LightRAG(
    vector_storage="QdrantVectorDBStorage",
    vector_db_storage_cls_kwargs={
        "cosine_better_than_threshold": 0.2  # similarity threshold
    }
)
```

**Environment Variables**:
```
QDRANT_URL=http://localhost:6333              # Qdrant server endpoint
QDRANT_API_KEY=your-api-key                   # optional authentication
QDRANT_WORKSPACE=my_workspace                 # workspace prefix for multi-instance
```

**Features**:
- Collection per namespace (automatically created)
- Automatic persistence
- Batch upsert operations (configurable batch size)
- Filter-based deletion
- Cosine distance metric
- Metadata payload support

**Implementation Highlights**:
- Uses `qdrant-client` Python library
- Auto-installs if not present (pipmaster)
- Handles multi-instance isolation via workspace prefixes
- UUID-based point IDs (SHA256 hash of content)

---

## IV. QUERY MODES & RETRIEVAL STRATEGIES

### Query Parameter Configuration

```python
class QueryParam:
    mode: Literal["local", "global", "hybrid", "naive", "mix", "bypass"]
    top_k: int = 60              # entities (local) or relations (global)
    chunk_top_k: int = 20        # text chunks to retrieve
    max_entity_tokens: int = 6000
    max_relation_tokens: int = 8000
    max_total_tokens: int = 30000
    response_type: str = "Multiple Paragraphs"
    stream: bool = False
    only_need_context: bool = False
    only_need_prompt: bool = False
    enable_rerank: bool = True
    user_prompt: str | None = None  # post-processing instructions
    conversation_history: list[dict] = []  # context window
```

### Query Modes Explained

**1. NAIVE Mode** - Vector-only (baseline)
- Simple vector similarity search on chunks
- No knowledge graph involvement
- Fast but less semantically aware
- Use case: Quick searches, baseline comparisons

**2. LOCAL Mode** - Entity-centric
- Retrieve top_k entities similar to query
- Get related chunks for each entity
- Build context from entity descriptions
- Use case: Entity-specific questions ("Who is X?", "What is organization Y?")

**3. GLOBAL Mode** - Relationship-centric
- Retrieve top_k relationships relevant to query
- Extract source/target entities from relationships
- Get related chunks for entities and relationships
- Emphasizes connections and patterns
- Use case: Understanding relationships ("How are X and Y connected?")

**4. HYBRID Mode** - Combined local + global
- Retrieves both entities AND relationships
- Combines context from both signals
- Best for comprehensive understanding
- Use case: Complex questions requiring multiple perspectives

**5. MIX Mode** - Knowledge graph + vector fusion
- Integrates KG-based retrieval with chunk vector search
- Balances structured (graph) and unstructured (vector) signals
- Most flexible and robust
- Use case: Production queries, general-purpose RAG

**6. BYPASS Mode** - LLM only (no RAG)
- Passes conversation history directly to LLM
- Ignores all indexed knowledge
- Use case: Chat mode, general conversation

### Dual-Level Retrieval Mechanism

```
User Query
    ↓
Step 1: Extract keywords (high-level, low-level)
    ↓
Step 2a (Local):              Step 2b (Global):
- Vector search entities      - Vector search relationships
- Top k entity results        - Top k relationship results
- Get chunk context           - Extract entities from relationships
                              - Get chunk context for all
    ↓
Step 3: Merge contexts (token-limited)
- Prioritize by relevance
- Truncate to max_total_tokens
- Respect entity/relation token budgets
    ↓
Step 4: Generate prompt
- System prompt + context
- Conversation history (optional)
    ↓
Step 5: LLM synthesis
- Generate answer with retrieved context
- Optional reranking of chunks
```

### Reranking Integration

**Supported Reranker Providers**:
- Cohere / vLLM (local or cloud)
- Jina AI
- Aliyun

**Configuration**:
```
RERANK_BINDING=cohere
RERANK_MODEL=BAAI/bge-reranker-v2-m3
RERANK_BINDING_HOST=http://localhost:8000/v1/rerank
RERANK_BINDING_API_KEY=...
```

**Effect**: Re-orders retrieved chunks based on learned relevance before LLM synthesis

---

## V. LLM INTEGRATION PATTERNS

### Supported LLM Backends

**1. OpenAI-Compatible** (Most flexible)
- Direct OpenAI API
- Azure OpenAI
- Upstage
- OpenRouter (vLLM, SGLang)
- Any OpenAI-compatible endpoint

**2. Ollama** (Local models)
- Any model available via Ollama
- Requires context window configuration

**3. Hugging Face** (Open models)
- Direct inference or API
- SentenceTransformers for embeddings

**4. LlamaIndex** (Multi-backend abstraction)
- Abstracts over OpenAI, Ollama, local models
- Simplified configuration

**5. AWS Bedrock** (Cloud-native)
- AWS-managed LLMs

### Entity Extraction Requirements

LightRAG has **HIGHER demands** than traditional RAG:

**Minimum LLM Specifications**:
- **Parameter count**: ≥32B recommended
- **Context length**: ≥32KB minimum, 64KB recommended
- **Training data**: Should understand entity extraction tasks
- **NOT recommended**: Reasoning models (o1) during extraction (too expensive)
- **For querying**: Stronger model than extraction phase recommended

**Configuration Pattern**:
```python
# Extraction (cheaper model)
llm_model_func = openai_complete_if_cache(
    model="gpt-4o-mini",
    ...
)

# Querying (stronger model - optional override)
QueryParam(
    model_func=openai_complete_if_cache(
        model="gpt-4o",
        ...
    )
)
```

### Embedding Model Requirements

**Importance**: Critical - must match across indexing and querying

**Specifications**:
- High-quality multilingual embedding model
- Supports semantic similarity matching
- Consistent vector dimensions

**Recommended Models**:
- `text-embedding-3-large` (OpenAI - 3072 dims)
- `BAAI/bge-m3` (Open source - 1024 dims)
- `bge-large-en-v1.5` (High quality - 1024 dims)

**Configuration Impact**:
- Changing embedding model requires deleting vector tables (for PostgreSQL)
- Vector dimension must be declared upfront
- Same model must be used for indexing and querying

### LLM Caching Strategy

**Two-Level Caching**:
1. **Response Cache**: LLM responses for identical prompts
2. **Entity Extraction Cache**: Cached extraction results per chunk
   - Environment: `ENABLE_LLM_CACHE_FOR_EXTRACT=true` (default)
   - Reduces redundant LLM calls during document reprocessing
   - Particularly useful for debugging

**Cache Implementation**: KVStorage-based (same as document store)

### LLM Timeout Configuration

**Critical Parameter**: Prevents extraction failures from overly long outputs

**Calculation**:
```
max_tokens = LLM_TIMEOUT * estimated_tokens_per_second
Example: 180 seconds * 50 tokens/sec = 9000 tokens
```

**Environment Variables**:
```
OPENAI_LLM_MAX_TOKENS=9000        # vLLM, most OpenAI-compatible
OLLAMA_LLM_NUM_PREDICT=9000       # Ollama
OPENAI_LLM_MAX_COMPLETION_TOKENS=9000  # OpenAI o1-mini/newer
```

---

## VI. INCREMENTAL UPDATES & DOCUMENT MANAGEMENT

### Document Insertion Methods

**1. Simple Insert**:
```python
await rag.ainsert("Document text")
await rag.ainsert(["text1", "text2", "text3"])
```

**2. Insert with Custom IDs**:
```python
await rag.ainsert(["text1", "text2"], ids=["doc_001", "doc_002"])
```

**3. Multi-File Type Support**:
- PDF, DOCX, PPTX, CSV
- Requires: `textract` library
- Automatic parsing and content extraction

**4. Batch Processing with Custom Parallelization**:
```python
rag = LightRAG(
    max_parallel_insert=4  # Process 4 docs concurrently
)
rag.insert(list_of_documents)
```

**5. Pipeline-Based Incremental Processing**:
```python
# Enqueue documents for background processing
await rag.apipeline_enqueue_documents(documents)

# Process in background while main thread continues
await rag.apipeline_process_enqueue_documents()
```

### Document Deletion

**By Document ID**:
```python
await rag.adelete("document_id")
await rag.adelete(["id_1", "id_2"])
```

**By Entity Name**:
```python
await rag.adelete_entity("Entity Name")
```

**Clean Deletion**:
- Removes entity from graph
- Removes relationships where entity is source/target
- Updates all vector storage
- LLM cache preserved if needed

### Document Status Tracking

**Pipeline Stages**:
- `pending` - queued for processing
- `processing` - currently being extracted/merged
- `processed` - successfully indexed
- `failed` - error during processing

**Track ID System**: Each document gets unique track ID for progress monitoring
- API endpoint: `/track_status/{track_id}`
- Returns: processing percentage, error messages, timestamps

---

## VII. CONFIGURATION OPTIONS & DEPLOYMENT PATTERNS

### Initialization Parameters

```python
LightRAG(
    # Directories
    working_dir="./rag_storage",
    workspace="my_instance",  # Multi-instance isolation
    
    # Storage backends
    kv_storage="JsonKVStorage",
    vector_storage="NanoVectorDBStorage",
    graph_storage="NetworkXStorage",
    doc_status_storage="JsonDocStatusStorage",
    
    # Text chunking
    chunk_token_size=1200,
    chunk_overlap_token_size=100,
    
    # Entity extraction
    entity_extract_max_gleaning=1,
    
    # LLM & Embedding
    embedding_func=EmbeddingFunc(embedding_dim=1536, func=...),
    llm_model_func=...
    llm_model_name="gpt-4o-mini",
    
    # Query parameters
    top_k=60,
    chunk_top_k=20,
    max_entity_tokens=6000,
    max_relation_tokens=8000,
    max_total_tokens=30000,
    cosine_threshold=0.2,
    
    # Parallelization
    embedding_func_max_async=16,
    embedding_batch_num=32,
    llm_model_max_async=4,
    max_parallel_insert=2,
    
    # Caching
    enable_llm_cache=True,
    enable_llm_cache_for_entity_extract=True,
    embedding_cache_config={...},
    
    # Summary
    summary_max_tokens=500,
    summary_context_size=10000,
)
```

### Environment Variable Configuration

**Key Variables**:
```
# LLM & Embedding
LLM_BINDING=openai
LLM_MODEL=gpt-4o-mini
LLM_BINDING_HOST=https://api.openai.com/v1
LLM_BINDING_API_KEY=...
EMBEDDING_BINDING=ollama
EMBEDDING_MODEL=bge-m3:latest
EMBEDDING_DIM=1024

# Query tuning
TOP_K=60
CHUNK_TOP_K=20
MAX_ENTITY_TOKENS=6000
MAX_RELATION_TOKENS=8000
COSINE_THRESHOLD=0.2

# Parallelization
MAX_ASYNC=4
MAX_PARALLEL_INSERT=2
EMBEDDING_BATCH_NUM=10

# Caching
ENABLE_LLM_CACHE_FOR_EXTRACT=true
LLM_CACHE_SIZE=10000

# Entity extraction
MAX_GLEANING=1
SUMMARY_MAX_TOKENS=500
SUMMARY_CONTEXT_SIZE=12000
ENTITY_TYPES=Person,Organization,Location,Event

# Multi-instance
WORKSPACE=instance_1
REDIS_WORKSPACE=redis_instance_1
NEO4J_WORKSPACE=neo4j_instance_1

# Reranking
RERANK_BINDING=cohere
RERANK_MODEL=BAAI/bge-reranker-v2-m3
RERANK_BINDING_HOST=http://localhost:8000/v1/rerank
```

### Deployment Patterns

**1. Development** (Single instance, in-memory)
```bash
pip install lightrag-hku
cp env.example .env
# Edit .env with OpenAI/Ollama keys
python my_script.py
```

**2. Production API Server** (Uvicorn)
```bash
pip install "lightrag-hku[api]"
lightrag-server --host 0.0.0.0 --port 9621
# Swagger UI at http://localhost:9621/docs
```

**3. Production Multi-Worker** (Gunicorn + Uvicorn)
```bash
lightrag-gunicorn --workers 4
# Prevents document indexing from blocking queries
```

**4. Docker Container**:
```yaml
services:
  lightrag:
    image: ghcr.io/hkuds/lightrag:latest
    ports:
      - "9621:9621"
    volumes:
      - ./data:/app/data
      - ./.env:/app/.env
    environment:
      - WORKSPACE=prod_instance
```

**5. Linux SystemD Service**:
```ini
[Unit]
Description=LightRAG Service

[Service]
WorkingDirectory=/path/to/lightrag
ExecStart=/path/to/venv/bin/lightrag-server
Restart=always

[Install]
WantedBy=multi-user.target
```

**6. Multi-Instance with Shared Database**:
```bash
# Instance 1 (Port 9621)
lightrag-server --port 9621 --workspace space1

# Instance 2 (Port 9622)
lightrag-server --port 9622 --workspace space2

# Shared PostgreSQL backend
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=PGGraphStorage
```

---

## VIII. PERFORMANCE CHARACTERISTICS & RESOURCE REQUIREMENTS

### Computational Bottlenecks

**1. LLM Inference** (Primary bottleneck)
- Entity extraction requires 2-3 LLM calls per chunk
- Merge operations require additional LLM calls
- Recommendation: Use faster LLM for extraction, stronger for querying

**2. Vector Embeddings** (Secondary bottleneck)
- Batch embedding operations
- Configurable batch size (default: 10 chunks per batch)

**3. Graph Merging** (Tertiary)
- Map-reduce entity merging
- Dependency on LLM but can use cache

### Performance Tips

1. **Increase Parallelization** (if LLM supports it)
   ```
   MAX_ASYNC=8
   MAX_PARALLEL_INSERT=4
   EMBEDDING_BATCH_NUM=32
   ```

2. **Enable LLM Cache**
   ```
   ENABLE_LLM_CACHE_FOR_EXTRACT=true
   ```

3. **Use Production LLM**
   - OpenAI/Upstage: ~10-30 tokens/sec
   - Ollama (local): ~5-15 tokens/sec
   - Avoid reasoning models (o1)

4. **Optimize Storage Backend**
   - PostgreSQL: Good for hybrid workloads
   - Neo4j: Best for graph operations
   - Qdrant/Milvus: Best for vector similarity

5. **Tune Token Budgets**
   - Increase `max_total_tokens` for long context
   - Decrease for faster processing
   - Balance between quality and speed

### Resource Requirements (Example: 10K Documents)

**CPU**: 
- Multi-core recommended (4+ cores)
- Higher for Gunicorn workers

**Memory**:
- Base: 2-4 GB
- In-memory storage (default): +0.5-2 GB
- External DB (PostgreSQL): minimal additional

**Storage**:
- ~10-100 bytes per entity/relationship
- Text chunks: proportional to document size
- Embeddings: (vector_dim * 4 bytes) per entity/chunk
  - Example: 1000 entities * 1536 dims * 4 bytes = 6 MB

**Network** (if using external DB):
- PostgreSQL: low latency required (<10ms)
- Qdrant: moderate latency acceptable

---

## IX. COMPARISON WITH TRADITIONAL RAG

| Aspect | Traditional RAG | LightRAG |
|--------|-----------------|----------|
| **Retrieval** | Vector similarity only | Entity + Relationship + Vector |
| **Context** | Unstructured chunks | Structured entities + relationships + chunks |
| **LLM Requirements** | Modest (7B+ models OK) | Higher (32B+ recommended) |
| **Query Complexity** | Simple semantic search | Complex multi-hop reasoning |
| **Update Cost** | Low (just add vectors) | Medium (merge entities/relationships) |
| **Scalability** | Excellent (vector-only) | Good (graph structure adds overhead) |
| **Question Types** | "What information about X?" | "How are X and Y related?" "What pattern connects these entities?" |
| **Hallucination** | Moderate (vectors may mislead) | Lower (structured facts constrain generation) |
| **Graph Building** | No | Yes (implicit in entity extraction) |

---

## X. CONFIDENCE LEVELS & FINDINGS SUMMARY

### High Confidence Findings
- LightRAG architecture and entity extraction process
- Storage backend options and Qdrant support
- Query modes and retrieval mechanisms
- LLM integration patterns and requirements
- Configuration and deployment patterns
- Performance characteristics and bottlenecks

### Medium Confidence Findings
- Exact performance metrics (proprietary benchmarks in arxiv paper)
- Detailed reranking implementation details
- Edge cases in graph merging with very large entity sets

### Low Confidence / Research Gaps
- Exact accuracy improvements over traditional RAG (depends on data)
- Optimal parameter tuning (domain-specific)
- Cost comparison with other KG-RAG systems

---

## XI. KEY INTEGRATION POINTS FOR DOCLING PIPELINE

### Stage 2: LightRAG Knowledge Structuring

**Input from Docling**:
- Parsed text (per document)
- Document metadata (source, type, tables/images)
- Potentially structured content (tables as JSON)

**LightRAG Processing**:
1. Text chunking (1200 tokens)
2. Entity/relationship extraction (LLM-driven)
3. Graph building (merge across chunks)
4. Vector embedding (all components)
5. Storage in 4-layer system

**Output for Stage 3 (Synthesis)**:
- Indexed knowledge graph
- Entity/relationship vectors
- Chunk vectors
- Query interface (local/global/hybrid modes)

**Critical Configuration for Pipeline Integration**:
```python
rag = LightRAG(
    # Match Docling output language
    addon_params={"language": "English"},
    
    # Fast extraction for speed
    entity_extract_max_gleaning=1,
    
    # Reasonable merge thresholds
    force_llm_summary_on_merge=8,
    
    # Support Docling file path tracking
    # Each document can have file_path parameter
)

# Process Docling output batches
await rag.ainsert(
    docling_extracted_texts,
    file_paths=docling_source_files,
    ids=docling_document_ids
)
```

**Expected Performance**:
- ~100-500 entities per 10K-word document
- ~50-200 relationships per 10K-word document
- Processing time: ~2-5 minutes per 10K-word document (OpenAI, parallel=2)

---

## XII. RESEARCH GAPS & FUTURE INVESTIGATION

1. **Comparison with GraphRAG**: LightRAG appears distinct but similar in goals
2. **Exact Algorithm Details**: Some merging heuristics not fully documented
3. **Scalability Benchmarks**: Performance with 100K+ entity graphs
4. **Multi-Language Optimization**: Language-specific entity extraction
5. **Citation Tracking**: How exactly file paths are used for attribution

---

## CONCLUSION

LightRAG represents a **mature, production-ready KG-RAG system** that significantly advances beyond traditional vector-only RAG. Its architecture elegantly balances:

- **Simplicity**: Easy to use API, multiple storage backends, flexible LLM integration
- **Sophistication**: Knowledge graph extraction, dual-level retrieval, intelligent merging
- **Scalability**: Multi-instance support, distributed storage options (Qdrant, PostgreSQL, Neo4j)
- **Performance**: Careful token budgeting, parallel processing, LLM caching

For the HX-Infrastructure Stage 2 (Docling → LightRAG → Synthesis) pipeline, LightRAG provides:
- **Structured knowledge extraction** from Docling-parsed documents
- **Semantic-aware retrieval** through multiple query modes
- **Production-grade deployment** with API, authentication, monitoring
- **Qdrant support** for vector similarity (confirming vectorization capability)

**Recommendation**: LightRAG is well-suited for Stage 2 knowledge structuring in your RAG pipeline.

