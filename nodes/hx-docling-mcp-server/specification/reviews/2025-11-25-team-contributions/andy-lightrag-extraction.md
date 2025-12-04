# LightRAG Knowledge Graph Extraction Enhancement
**Document Type:** Technical Enhancement Specification
**Version:** 1.0
**Date:** 2025-11-25
**Author:** andy-taylor (LightRAG Subject Matter Expert)
**Target Spec Section:** 4.3.2 LightRAG Knowledge Engine in node-spec.md

---

## Enhancement Overview

This document provides comprehensive enhancements to the LightRAG Knowledge Graph extraction pipeline in the hx-docling-mcp-server specification. These enhancements detail:

1. **Entity Extraction Pipeline** with LLM prompting strategies
2. **Relationship Extraction** with directionality handling
3. **Entity Deduplication Strategy** using hybrid string + vector similarity
4. **LLM Integration Patterns** for production-ready entity extraction
5. **Graph Construction Workflow** from document ingestion to Qdrant storage

---

## 1. Entity Extraction Pipeline

### 1.1 Document Chunking (Preprocessing for LLM-Safe Context Windows)

**Chunk Size Configuration:**
- **Chunk Size**: 4096 tokens (safe for 32KB context models like gemma3:27b, leaves 28KB for prompt overhead)
  - **Rationale**: LightRAG research shows optimal entity extraction with 4K-token chunks (balances context richness vs LLM compute cost)
- **Chunk Overlap**: 512 tokens (12.5% overlap) to preserve entity/relationship context at chunk boundaries
  - **Why Overlap**: Prevents split entities ("Massachusett..." chunk 1, "...s Institute of Technology" chunk 2)

**Chunking Strategy:**
- **Semantic Chunking**: Split at paragraph boundaries (`\n\n`) to preserve topical coherence
- **Fallback**: Token-based splitting if paragraph exceeds 4096 tokens (force split at sentence `.` boundary)
- **Code Block Preservation**: Treat code blocks as atomic units (do not split mid-code, critical for technical docs)
- **Token Counting**: `tiktoken` library with `cl100k_base` encoding (GPT-3.5/4-compatible, works for all Ollama models)
- **Chunk Metadata**: Track `document_id`, `chunk_index`, `char_start`, `char_end` for source attribution

**Edge Cases:**
- Documents <4096 tokens: Single chunk (no splitting required)
- Long paragraphs (>4096 tokens): Force split at sentence boundaries, preserve context with overlap
- Code blocks: Treat as atomic units (do not split mid-code)

### 1.2 Entity Types (10 Configurable Types)

| Entity Type | Description | Examples |
|-------------|-------------|----------|
| **Person** | Individuals, authors, researchers, historical figures | "Dr. Jane Smith", "Albert Einstein" |
| **Organization** | Companies, institutions, research groups, government agencies | "MIT", "IBM Research", "UN" |
| **Location** | Countries, cities, geographic regions, facilities | "Cambridge, MA", "Building 32" |
| **Concept** | Abstract ideas, theories, methodologies, scientific concepts | "Quantum Entanglement", "Machine Learning" |
| **Technology** | Software, hardware, tools, frameworks, programming languages | "Python", "LightRAG", "CUDA" |
| **Product** | Commercial products, services, brands | "iPhone", "Windows 11", "Qdrant Cloud" |
| **Event** | Historical events, conferences, incidents, milestones | "ICML 2024", "Apollo 11 Launch" |
| **Date** | Temporal references (absolute dates, time periods, durations) | "November 25 2025", "1990s", "3 months" |
| **Quantity** | Numerical values with units, measurements, statistics | "54.8% win rate", "1024 dimensions", "32GB RAM" |
| **Document** | References to other documents, papers, reports, standards | "RFC 9110", "LightRAG Research Paper" |

### 1.3 LLM Extraction Prompt Template

**System Prompt with Few-Shot Examples:**

```markdown
You are an expert entity extraction system. Extract structured entities from technical documents.

ENTITY TYPES: Person, Organization, Location, Concept, Technology, Product, Event, Date, Quantity, Document

INSTRUCTIONS:
1. Extract ALL entities of the specified types from the text chunk
2. For each entity, provide:
   - entity_text: Exact text span from document (verbatim, no normalization or correction)
   - entity_type: One of the 10 entity types listed above (EXACTLY as spelled)
   - normalized_name: Canonical form (e.g., "Dr. John Smith" → "John Smith", "MIT" → "Massachusetts Institute of Technology")
   - confidence: Confidence score 0.0-1.0
     * 0.9-1.0: Explicit mentions with clear context (e.g., "Python is a programming language")
     * 0.7-0.9: Inferred entities with supporting context (e.g., "developed in Python" → Technology)
     * <0.7: Ambiguous entities (e.g., "Apple" could be fruit or company)
   - context: 50-character snippet surrounding entity mention (for disambiguation)
   - attributes: Type-specific structured attributes (see examples below)
3. Extract entities even if mentioned only once (frequency filtering is post-processing)
4. Preserve entity coreferences (distinguish "Tesla" the company vs "Tesla" the person)
5. Return ONLY valid JSON array (no markdown, no preamble, no explanation)

FEW-SHOT EXAMPLES:

Example 1 (Technical Document):
Text: "IBM Research announced LightRAG, a knowledge graph RAG framework, achieving 54.8% win rate."
Output:
{
  "entities": [
    {
      "entity_text": "IBM Research",
      "entity_type": "Organization",
      "normalized_name": "IBM Research",
      "confidence": 0.95,
      "context": "...announced by IBM Research in...",
      "attributes": {"industry": "technology research", "parent_company": "IBM"}
    },
    {
      "entity_text": "LightRAG",
      "entity_type": "Technology",
      "normalized_name": "LightRAG",
      "confidence": 0.98,
      "context": "...announced LightRAG, a knowledge...",
      "attributes": {"type": "RAG framework", "category": "knowledge graph"}
    },
    {
      "entity_text": "54.8% win rate",
      "entity_type": "Quantity",
      "normalized_name": "54.8%",
      "confidence": 0.92,
      "context": "...achieving 54.8% win rate against...",
      "attributes": {"value": 54.8, "unit": "percent", "metric": "win rate"}
    }
  ]
}

Example 2 (Academic Paper):
Text: "At ICML 2024 in Vienna, Dr. Zhang presented research on Quantum Entanglement."
Output:
{
  "entities": [
    {
      "entity_text": "ICML 2024",
      "entity_type": "Event",
      "normalized_name": "International Conference on Machine Learning 2024",
      "confidence": 0.97,
      "context": "...presented at ICML 2024 in...",
      "attributes": {"conference": "ICML", "year": "2024", "full_name": "International Conference on Machine Learning"}
    },
    {
      "entity_text": "Vienna",
      "entity_type": "Location",
      "normalized_name": "Vienna, Austria",
      "confidence": 0.90,
      "context": "...ICML 2024 in Vienna, Dr....",
      "attributes": {"city": "Vienna", "country": "Austria", "region": "Europe"}
    },
    {
      "entity_text": "Dr. Zhang",
      "entity_type": "Person",
      "normalized_name": "Zhang",
      "confidence": 0.85,
      "context": "...Vienna, Dr. Zhang presented research...",
      "attributes": {"title": "Dr.", "role": "researcher"}
    },
    {
      "entity_text": "Quantum Entanglement",
      "entity_type": "Concept",
      "normalized_name": "Quantum Entanglement",
      "confidence": 0.94,
      "context": "...research on Quantum Entanglement using...",
      "attributes": {"domain": "quantum physics", "category": "physics concept"}
    }
  ]
}

NEGATIVE EXAMPLES (DO NOT EXTRACT):
- Stopwords: "the", "and", "of", "a", "an", "in", "on", "at", "to", "for"
- Common verbs without noun form: "running", "processing", "analyzing" (unless part of named entity)
- Generic adjectives: "important", "large", "small", "good", "bad"
- Pronouns: "he", "she", "it", "they", "we"

OUTPUT FORMAT (STRICT JSON ARRAY):
{"entities": [{"entity_text": "...", "entity_type": "...", ...}, ...]}

TEXT TO ANALYZE:
{document_chunk}
```

### 1.4 LLM Model Selection (Task-Specific Routing)

**Model Configuration:**

| Use Case | Model | Server | Strengths |
|----------|-------|--------|-----------|
| **General Documents** (news, articles, reports) | gemma3:27b | Ollama1 (${OLLAMA1_BASE_URL}) | Balanced quality/speed, strong NER, 32KB context |
| **Technical Documents** (API docs, code, configs) | qwen3-coder:30b | Ollama2 (${OLLAMA2_BASE_URL}) | Code-aware tokenization, programming syntax understanding |
| **Academic Papers** (research publications) | gpt-oss:20b | Ollama1 | Research-focused training data, academic terminology |
| **Fallback Chain** | gemma3 → gpt-oss → qwen3-coder | Auto-routing | Try primary, fallback if unavailable |

**Routing Configuration:**
- **Environment Variable**: `LIGHTRAG_ENTITY_MODEL` (default: `gemma3:27b`)
- **Availability Check**: Pre-flight health check to LiteLLM `/v1/models` endpoint before extraction
- **Fallback Behavior**: If primary unavailable (503) or timeout (60s), attempt next in chain

### 1.5 LLM API Configuration (LiteLLM Gateway Integration)

**API Request Specification:**

```json
{
  "endpoint": "POST ${LITELLM_BASE_URL}/v1/chat/completions",
  "payload": {
    "model": "gemma3:27b",
    "messages": [
      {"role": "system", "content": "<entity_extraction_prompt>"},
      {"role": "user", "content": "<document_chunk>"}
    ],
    "max_tokens": 8192,
    "temperature": 0.1,
    "top_p": 0.9,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0
  },
  "timeout": 60
}
```

**Environment Variable**: `LITELLM_BASE_URL` (default: `http://hx-litellm-server.hx.dev.local:4000`)

**Parameter Rationale:**
- **max_tokens: 8192**: Sufficient for large entity lists from 4K-token chunks (typical response ~2-3K tokens)
- **temperature: 0.1**: Deterministic extraction, minimize hallucination, reproducible results
- **top_p: 0.9**: Focus on high-confidence token predictions, exclude long tail
- **timeout: 60s**: Large LLM inference can take 30-45 seconds for 4K-token chunks on Ollama

**Retry Logic:**
- **Attempts**: 3 attempts with exponential backoff (5s, 10s, 20s)
- **Retry Triggers**: HTTP 429 (rate limit), HTTP 500/502/503 (server error), connection timeout
- **Non-Retryable**: HTTP 400 (bad request), HTTP 401 (auth error), invalid JSON response

### 1.6 LLM Response Parsing & Validation

**Multi-Layer Quality Gates:**

**Layer 1: JSON Schema Validation (Pydantic)**

```python
from pydantic import BaseModel, Field, validator
from typing import Literal, Dict, List

class Entity(BaseModel):
    entity_text: str = Field(..., min_length=1, max_length=500)
    entity_type: Literal["Person", "Organization", "Location", "Concept", "Technology", "Product", "Event", "Date", "Quantity", "Document"]
    normalized_name: str = Field(..., min_length=1)
    confidence: float = Field(..., ge=0.0, le=1.0)
    context: str = Field(..., max_length=100)
    attributes: Dict[str, str] = Field(default_factory=dict)

    @validator('entity_text')
    def validate_entity_in_chunk(cls, v, values):
        # Verify entity_text appears in original document chunk (prevent hallucination)
        if 'document_chunk' in values and v not in values['document_chunk']:
            raise ValueError(f"Hallucinated entity: '{v}' not found in chunk")
        return v

class EntityExtractionResult(BaseModel):
    entities: List[Entity]
```

**Layer 2: Hallucination Detection**
- **Check**: Verify `entity_text` appears in original document chunk (exact substring match, case-insensitive)
- **Threshold**: If >50% of entities fail verification → Discard entire result (LLM hallucinating)
- **Logging**: Log ERROR with document_id, chunk_index, model_name for debugging

**Layer 3: Confidence Filtering**
- **Threshold**: Discard entities with `confidence < 0.7` (configurable via `LIGHTRAG_MIN_ENTITY_CONFIDENCE`)
- **Rationale**: Low-confidence entities often false positives or ambiguous mentions

**Layer 4: Ambiguity Resolution**
- **Scenario**: LLM returns multiple entities with overlapping text spans
- **Resolution**: Select entity with highest confidence, discard lower-confidence overlaps

---

## 2. Relationship Extraction

### 2.1 Relationship Types (10 Configurable Types)

| Relationship Type | Description | Example | Directionality |
|-------------------|-------------|---------|----------------|
| **LOCATED_IN** | Physical location | "Tesla LOCATED_IN California" | Directed |
| **WORKS_FOR** | Employment | "John Smith WORKS_FOR IBM Research" | Directed |
| **AUTHORED_BY** | Document authorship | "Research Paper AUTHORED_BY Dr. Smith" | Directed |
| **USES** | Technology utilization | "IBM Research USES Quantum Computing" | Directed |
| **PART_OF** | Component/subset relationship | "AI Lab PART_OF MIT" | Directed |
| **RELATED_TO** | Generic semantic association | "Machine Learning RELATED_TO Deep Learning" | Bidirectional |
| **CITES** | Document reference | "Paper A CITES Paper B" | Directed |
| **MENTIONS** | Explicit mention | "Article MENTIONS Tesla" | Directed/Bidirectional |
| **FOUNDED_BY** | Organizational founding | "SpaceX FOUNDED_BY Elon Musk" | Directed |
| **OCCURRED_IN** | Event timing/location | "ICML 2024 OCCURRED_IN Vienna" | Directed |

### 2.2 LLM Relationship Prompt Template

**System Prompt with Two-Pass Extraction:**

```markdown
You are an expert relationship extraction system. Extract semantic relationships between entities.

RELATIONSHIP TYPES: LOCATED_IN, WORKS_FOR, AUTHORED_BY, USES, PART_OF, RELATED_TO, CITES, MENTIONS, FOUNDED_BY, OCCURRED_IN

ENTITIES PROVIDED (extract relationships ONLY between these entities):
{entity_list_json}

INSTRUCTIONS:
1. Extract ALL relationships between provided entities from the text chunk
2. ONLY extract relationships between entities in the provided list (no new entities)
3. For each relationship, provide:
   - subject_entity: Entity initiating the relationship (use exact normalized_name from entity list)
   - predicate: Relationship type (one of the 10 types listed above, EXACTLY as spelled)
   - object_entity: Entity receiving the relationship (use exact normalized_name from entity list)
   - confidence: Confidence score 0.0-1.0
     * 0.9-1.0: Explicit relationships with clear evidence (e.g., "John works at IBM")
     * 0.7-0.9: Implied relationships with context (e.g., "John, an IBM researcher" → WORKS_FOR)
     * <0.7: Speculative relationships (e.g., "John may collaborate with IBM")
   - evidence: Text snippet explicitly stating the relationship (verbatim quote, max 200 chars)
   - directionality: "directed" (subject→object) or "bidirectional" (subject↔object)
4. Extract directional relationships correctly:
   - "John WORKS_FOR IBM" NOT "IBM WORKS_FOR John"
   - "Paper A CITES Paper B" NOT "Paper B CITES Paper A"
5. Bidirectional relationships only for symmetric predicates:
   - RELATED_TO (always bidirectional: "ML RELATED_TO DL" ↔ "DL RELATED_TO ML")
   - MENTIONS (can be bidirectional if both entities mention each other)
6. Return ONLY valid JSON array (no markdown, no preamble)

FEW-SHOT EXAMPLE:
Entities: ["IBM Research", "LightRAG", "Qdrant", "Knowledge Graph RAG"]
Text: "IBM Research developed LightRAG, a framework using Qdrant for Knowledge Graph RAG."
Output:
{
  "relationships": [
    {
      "subject_entity": "IBM Research",
      "predicate": "USES",
      "object_entity": "LightRAG",
      "confidence": 0.96,
      "evidence": "IBM Research developed LightRAG, a framework...",
      "directionality": "directed"
    },
    {
      "subject_entity": "LightRAG",
      "predicate": "USES",
      "object_entity": "Qdrant",
      "confidence": 0.94,
      "evidence": "...framework using Qdrant for Knowledge Graph RAG",
      "directionality": "directed"
    },
    {
      "subject_entity": "LightRAG",
      "predicate": "RELATED_TO",
      "object_entity": "Knowledge Graph RAG",
      "confidence": 0.92,
      "evidence": "...using Qdrant for Knowledge Graph RAG",
      "directionality": "bidirectional"
    }
  ]
}

NEGATIVE EXAMPLES (DO NOT EXTRACT):
- Relationships between entities NOT in provided list
- Self-relationships ("IBM RELATED_TO IBM")
- Speculative relationships without evidence ("may", "might", "could")

OUTPUT FORMAT (STRICT JSON ARRAY):
{"relationships": [{"subject_entity": "...", "predicate": "...", ...}, ...]}

TEXT TO ANALYZE:
{document_chunk}
```

### 2.3 Relationship Validation (Post-LLM Processing)

**Validation Layers:**

1. **Entity Membership Check**: Verify both `subject_entity` and `object_entity` exist in extracted entity list (discard if not)
2. **Confidence Threshold**: Filter relationships with `confidence < 0.7` (configurable via `LIGHTRAG_MIN_REL_CONFIDENCE`)
3. **Evidence Verification**: Verify `evidence` text appears in original document chunk (prevent hallucination)
4. **Directionality Validation**: Enforce bidirectional only for symmetric predicates (RELATED_TO, MENTIONS if mutual)
5. **Duplicate Detection**: Merge duplicate relationships (same subject/predicate/object across chunks)
   - **Merging Strategy**: Keep highest confidence, concatenate evidence from both (separated by " | ")

---

## 3. Entity Deduplication Strategy

### 3.1 Deduplication Goals

- **Merge Variant Mentions**: "IBM" + "IBM Research" + "International Business Machines" → Single canonical entity
- **Prevent False Positives**: "Apple Inc." (company) vs "apple" (fruit) → Keep separate
- **Preserve Entity Diversity**: "John Smith" (author) vs "John Smith" (CEO) → Keep separate if different attributes

### 3.2 Similarity Metrics (Hybrid String + Vector Approach)

**Metric 1: String Similarity (Jaro-Winkler Distance)**

- **Algorithm**: Jaro-Winkler (optimized for short strings, prefix bias)
- **Library**: `jellyfish` Python library
- **Preprocessing**:
  - Convert to lowercase (case-insensitive matching)
  - Collapse multiple whitespaces → single space
  - Trim leading/trailing whitespace
  - Remove common suffixes ("Inc.", "Corp.", "Ltd.") for Organization entities
- **Threshold**: 0.85 for matching (e.g., "IBM Research" vs "IBM Research Lab" = 0.88 → MATCH)
- **Use Case**: Fast first-pass filtering (90% of non-matches eliminated with <0.70 threshold)

**Metric 2: Vector Similarity (Semantic Embedding Cosine Similarity)**

- **Embedding Model**: `bge-m3:567m` (Ollama3 @ hx-ollama3-server.hx.dev.local)
  - **Model Type**: Multilingual general-purpose embedding (1024 dimensions)
  - **Strengths**: Captures semantic equivalence beyond lexical matching
- **Embedding Endpoint**: `POST ${OLLAMA3_BASE_URL}/api/embeddings`
- **Environment Variable**: `OLLAMA3_BASE_URL` (default: `http://hx-ollama3-server.hx.dev.local:11434`)
- **Embedding Batch Size**: Max 64 entities per API call (reduce API overhead)
- **Similarity Metric**: Cosine similarity (normalized dot product, range 0.0-1.0)
- **Threshold**: 0.90 for matching (high threshold to prevent false positives)
- **Example**: "Massachusetts Institute of Technology" vs "MIT" = 0.94 similarity → MATCH

**Metric 3: Hybrid Score (Weighted Combination)**

- **Formula**: `hybrid_score = 0.4 * string_similarity + 0.6 * vector_similarity`
- **Rationale**: Vector similarity weighted higher (captures synonyms, abbreviations, semantic equivalence)
- **Deduplication Threshold**: `hybrid_score >= 0.87` (configurable via `LIGHTRAG_DEDUP_THRESHOLD`)

**Example Scores:**

| Entity Pair | String Similarity | Vector Similarity | Hybrid Score | Match? |
|-------------|-------------------|-------------------|--------------|--------|
| "IBM" vs "IBM Research" | 0.85 | 0.92 | 0.89 | ✅ MATCH |
| "Apple Inc." vs "apple" | 0.75 | 0.42 | 0.55 | ❌ NO MATCH |
| "John Smith" vs "Jane Smith" | 0.88 | 0.68 | 0.76 | ❌ NO MATCH |

### 3.3 Deduplication Algorithm (Per-Document Batch Processing)

**Phase 1: Candidate Pair Generation**

1. **Type Grouping**: Group entities by type (Person with Person, Organization with Organization, etc.)
   - **Rationale**: No need to compare "IBM" (Organization) with "Python" (Technology)
2. **Pairwise Combinations**: Generate all pairs within each type group
   - **Complexity**: O(n²) per type, but typically <100 entities per type per document
3. **Early Termination**: Skip pairs with identical `normalized_name` (already canonicalized)

**Phase 2: String Similarity Filtering**

1. **Compute Jaro-Winkler**: For all candidate pairs
2. **Filter Threshold**: Keep only pairs with `string_similarity >= 0.70`
   - **Elimination Rate**: ~70% of pairs eliminated (avoid expensive vector computation)

**Phase 3: Vector Similarity Computation**

1. **Batch Embedding Generation**:
   - Collect all entities needing embeddings (both sides of filtered pairs)
   - Deduplicate entity names (avoid re-embedding same entity)
   - Send batch request to Ollama3 (max 64 entities per batch, parallel batches if >64)
2. **Cache Embeddings**: Store in Redis with TTL 7 days
   - **Key**: `embedding:<sha256(entity_name)>`
   - **Value**: 1024-float vector (4KB per embedding)
   - **Cache Hit Rate**: ~40% on second/third documents (common entities like "Python", "USA")
3. **Compute Cosine Similarity**: For all filtered pairs

**Phase 4: Entity Resolution (Canonical Entity Selection)**

1. **Merge Decision**: Pairs with `hybrid_score >= 0.87` are merged
2. **Canonical Entity Selection** (Tie-Breaking Rules):
   - **Rule 1**: Select entity with highest `confidence` score (e.g., 0.95 > 0.88)
   - **Rule 2**: If confidence tied, select entity with most `attributes` (richer metadata preferred)
   - **Rule 3**: If still tied, select entity appearing first in document (preserve original order)
3. **Attribute Merging**: Union of key-value pairs from both entities
   - **Conflict Resolution**: Prefer canonical entity's value
4. **Alias Tracking**: Record all `entity_text` variants as aliases
   - **Example**: Canonical "Massachusetts Institute of Technology", aliases: ["MIT", "Mass. Inst. of Tech.", "MIT University"]
   - **Storage**: Qdrant payload field `entity_text_variants: List[str]`

**Phase 5: Relationship Update**

1. **Entity ID Replacement**: Replace all occurrences of merged entity IDs in relationship triples with canonical entity ID
2. **Relationship Deduplication**: After entity merging, deduplicate relationships (same subject/predicate/object)
   - **Aggregation**: Merge duplicate relationships, concatenate evidence snippets (separated by " | ")
   - **Confidence Averaging**: Take max confidence from duplicates

### 3.4 Deduplication Performance Optimization

**Optimization Techniques:**

1. **Embedding Caching**: Redis cache with 7-day TTL
   - **Cache Key**: `sha256(entity_name)`
   - **Cache Size**: ~4KB per embedding, 100K entities = 400MB Redis RAM
2. **Batch API Calls**: Group embedding requests (max 64 entities per Ollama3 call)
   - **Latency Reduction**: 100 entities → 2 API calls (3 seconds) vs 100 sequential calls (90 seconds)
3. **Parallel Processing**: Python `concurrent.futures.ThreadPoolExecutor` (4 workers) for similarity computation
4. **Early Termination**: Skip vector similarity if `string_similarity < 0.70` (70% of pairs eliminated)

---

## 4. LLM Integration Patterns

### 4.1 Model Selection Strategy

**Task-Specific Model Routing:**

| Document Type | Primary Model | Fallback Model | Rationale |
|---------------|---------------|----------------|-----------|
| General Documents | gemma3:27b | gpt-oss:20b | Balanced quality/speed, strong NER |
| Technical Documents | qwen3-coder:30b | gemma3:27b | Code-aware tokenization, API patterns |
| Academic Papers | gpt-oss:20b | gemma3:27b | Research-focused training data |

**Fallback Chain**: gemma3:27b → gpt-oss:20b → qwen3-coder:30b

### 4.2 Prompt Engineering Best Practices

**Iterative Refinement Strategies:**

1. **Few-Shot Examples**: Include 2-3 examples for complex entity types (+12% F1 score improvement)
2. **Chain-of-Thought**: For relationship extraction only (+12% accuracy)
3. **Output Constraints**: Explicitly specify JSON schema (40% reduction in parsing errors)
4. **Negative Examples**: Include what NOT to extract (25% reduction in noise entities)
5. **Iterative Refinement**: If avg confidence <0.8, retry with stricter prompt (max 1 retry)

### 4.3 Error Handling for LLM Failures

**Graceful Degradation Strategies:**

| Failure Type | Response Code | Action | Impact |
|--------------|---------------|--------|--------|
| **LiteLLM Unavailable** | 503 | Disable knowledge graph generation, allow document conversion | Stage 1 only |
| **Model Not Found** | 404 | Attempt fallback model chain | Eventual success or error |
| **Timeout** | Timeout | Retry with backoff (max 3 attempts), skip chunk if fail | Partial knowledge graph |
| **Rate Limit** | 429 | Wait for Retry-After header, then retry | Eventual success |
| **Hallucination** | N/A | Discard result if >50% entities invalid, log ERROR | Skip chunk |

---

## 5. Graph Construction Workflow

### 5.1 Workflow Overview (5 Phases)

```
Phase 1: Document Ingestion
  ↓ (DoclingDocument JSON)
Phase 2: Document Chunking
  ↓ (4096-token chunks with 512-token overlap)
Phase 3: Entity + Relationship Extraction (Parallel)
  ↓ (Raw entities/relationships from all chunks)
Phase 4: Entity Deduplication
  ↓ (Canonical entities + updated relationships)
Phase 5: Qdrant Storage
  ↓ (Knowledge graph persisted)
```

### 5.2 Phase 1: Document Ingestion

**Input Validation:**
- **Accept**: File path (local FS), URL (http/https), base64-encoded content
- **Format Hint**: Optional format parameter (pdf, docx, pptx, xlsx, html, image)
- **File Size Limit**: 500MB max (configurable via `MAX_DOCUMENT_SIZE_MB`)
- **MIME Type Detection**: Auto-detect if no format hint (using `python-magic` library)

**Docling Conversion:**
- **Converter**: Docling library converts to DoclingDocument JSON
- **Error Handling**: If conversion fails → Return error, do not proceed

**Text Extraction:**
- **Source**: Extract plain text from DoclingDocument (join all text elements)
- **Metadata Preservation**: Track page numbers, section headings, table captions

**Minimum Length Check:**
- **Threshold**: Skip documents with <100 characters
- **Example**: Single-page cover letters, placeholder PDFs → Skip with WARNING log

### 5.3 Phase 2: Document Chunking

**Chunking Implementation:**

1. **Token Counting**: Use `tiktoken` library with `cl100k_base` encoding
2. **Chunking Strategy**:
   - **Semantic Splitting**: Split at paragraph boundaries (`\n\n`)
   - **Chunk Size**: Target 4096 tokens
   - **Overlap**: 512-token overlap
   - **Fallback**: If paragraph >4096 tokens → Force split at sentence boundary (`. `)
3. **Special Handling**:
   - **Code Blocks**: Preserve ` ``` ` fenced code blocks intact
   - **Tables**: Extract as single chunk
   - **Metadata Tracking**: `document_id`, `chunk_index`, `char_start`, `char_end`

### 5.4 Phase 3: Entity + Relationship Extraction

**Parallel Entity Extraction:**

1. **Concurrency**: Process all chunks in parallel using Python `asyncio.gather`
2. **Rate Limiting**: Max 4 concurrent LLM requests
3. **Per-Chunk**: Send entity extraction prompt → Parse JSON → Validate entities
4. **Aggregation**: Merge entity lists from all chunks

**Sequential Relationship Extraction:**

1. **Sequential Processing**: Process chunks one-by-one for relationships
2. **Per-Chunk**: Send relationship prompt with entity list → Parse JSON → Validate
3. **Aggregation**: Merge relationship lists from all chunks

**Progress Tracking:**

- **Redis Key**: `kg_progress:<document_id>`
- **Fields**: status, total_chunks, processed_chunks, entities_extracted, relationships_extracted
- **MCP Tool**: `get_kg_progress(document_id)` returns progress percentage

### 5.5 Phase 4: Entity Deduplication

**Deduplication Execution:**

1. **Run Deduplication Algorithm**: (See Section 3.3 for full details)
   - **Input**: All entities from all chunks (~10-500 entities per document)
   - **Output**: Canonical entity list (typically 10-30% reduction)
2. **Relationship Updates**: Replace merged entity IDs in relationship triples
3. **Relationship Deduplication**: Merge duplicate relationships

### 5.6 Phase 5: Qdrant Storage

**Entity Embeddings Generation:**

1. **Batch Embedding**: Send all canonical entity names to Ollama3 bge-m3 (max 64 per batch)
2. **Endpoint**: `POST ${OLLAMA3_BASE_URL}/api/embeddings`
3. **Caching**: Check Redis cache first, embed only cache misses

**Entity Upsert to Qdrant:**

1. **Collection**: `hx_docling_mcp_entities`
2. **Batch Size**: 100 entities per upsert
3. **Payload**: Entity metadata (see node-spec.md Qdrant section)
4. **Error Handling**: Retry on connection error (3 attempts), fail entire KG if write fails

**Relationship Embeddings Generation:**

1. **Embed Evidence Text**: Generate embedding for each relationship's `evidence` field

**Relationship Upsert to Qdrant:**

1. **Collection**: `hx_docling_mcp_relationships`
2. **Batch Size**: 100 relationships per upsert
3. **Foreign Key Validation**: Verify subject/object entity IDs exist before insert

**Atomic Transaction Simulation:**

1. **Strategy**: Insert all entities first, then relationships
2. **Rollback**: If relationship insert fails → Delete entities from current document

### 5.7 Knowledge Graph Quality Metrics

**Automated Quality Assessment:**

| Metric | Formula | Target | Rationale |
|--------|---------|--------|-----------|
| **Entity Coverage** | (entity text spans length / total text length) × 100% | 15-25% | Good extraction density |
| **Entity Density** | entity_count / (word_count / 1000) | 10-20 entities/1K words | LightRAG baseline |
| **Relationship Density** | relationship_count / entity_count | 1.5-3.0 | Well-connected graph |
| **Average Confidence** | mean(entity.confidence + rel.confidence) | >0.85 | High-quality extraction |
| **Deduplication Rate** | (entities before - entities after) / entities before × 100% | 10-20% | Effective resolution |
| **Extraction Latency** | End-to-end time (document → Qdrant) | <30s for 10-page PDF | Acceptable performance |

---

## 6. Configuration Requirements

### 6.1 Environment Variables

**LightRAG-Specific Configuration:**

```bash
# Entity Extraction
LIGHTRAG_ENTITY_MODEL=gemma3:27b                    # Primary model for entity extraction
LIGHTRAG_MIN_ENTITY_CONFIDENCE=0.7                  # Minimum confidence threshold for entities
LIGHTRAG_MIN_REL_CONFIDENCE=0.7                     # Minimum confidence threshold for relationships

# Chunking
LIGHTRAG_CHUNK_SIZE=4096                            # Tokens per chunk
LIGHTRAG_CHUNK_OVERLAP=512                          # Token overlap between chunks
LIGHTRAG_TOKENIZER=cl100k_base                      # Tiktoken encoding

# Deduplication
LIGHTRAG_DEDUP_THRESHOLD=0.87                       # Hybrid score threshold for entity merging
LIGHTRAG_STRING_SIM_THRESHOLD=0.85                  # Jaro-Winkler threshold
LIGHTRAG_VECTOR_SIM_THRESHOLD=0.90                  # Cosine similarity threshold
LIGHTRAG_DEDUP_BATCH_SIZE=64                        # Entities per embedding API call

# LLM Integration
LIGHTRAG_LLM_TIMEOUT=60                             # LLM API timeout (seconds)
LIGHTRAG_LLM_MAX_RETRIES=3                          # Max retry attempts for LLM failures
LIGHTRAG_LLM_BACKOFF_BASE=5                         # Exponential backoff base (seconds)

# Embedding Cache
LIGHTRAG_EMBEDDING_CACHE_TTL=604800                 # 7 days in seconds
LIGHTRAG_EMBEDDING_CACHE_PREFIX=embedding:          # Redis key prefix

# Performance
LIGHTRAG_MAX_CONCURRENT_LLM_REQUESTS=4              # Parallel LLM requests
LIGHTRAG_DEDUP_WORKERS=4                            # Parallel workers for similarity computation
```

### 6.2 Redis Keys

**LightRAG-Specific Redis Keys:**

| Key Pattern | Type | Purpose | TTL |
|-------------|------|---------|-----|
| `kg_progress:<doc_id>` | Hash | Knowledge graph construction progress | 24 hours |
| `embedding:<sha256(name)>` | String | Cached entity embeddings (1024 floats) | 7 days |
| `kg_stats:<doc_id>` | Hash | Quality metrics (coverage, density, confidence) | 7 days |

---

## 7. Pydantic Schemas

### 7.1 Entity Schema

```python
from pydantic import BaseModel, Field, validator
from typing import Literal, Dict, List

class Entity(BaseModel):
    entity_text: str = Field(..., min_length=1, max_length=500, description="Exact text span from document")
    entity_type: Literal["Person", "Organization", "Location", "Concept", "Technology", "Product", "Event", "Date", "Quantity", "Document"]
    normalized_name: str = Field(..., min_length=1, description="Canonical form of entity")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Extraction confidence score")
    context: str = Field(..., max_length=100, description="50-char snippet surrounding entity")
    attributes: Dict[str, str] = Field(default_factory=dict, description="Type-specific attributes")

    @validator('entity_text')
    def validate_entity_in_chunk(cls, v, values):
        if 'document_chunk' in values and v not in values['document_chunk']:
            raise ValueError(f"Hallucinated entity: '{v}' not found in chunk")
        return v

class EntityExtractionResult(BaseModel):
    entities: List[Entity]
```

### 7.2 Relationship Schema

```python
class Relationship(BaseModel):
    subject_entity: str = Field(..., min_length=1, description="Subject entity normalized name")
    predicate: Literal["LOCATED_IN", "WORKS_FOR", "AUTHORED_BY", "USES", "PART_OF", "RELATED_TO", "CITES", "MENTIONS", "FOUNDED_BY", "OCCURRED_IN"]
    object_entity: str = Field(..., min_length=1, description="Object entity normalized name")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Extraction confidence")
    evidence: str = Field(..., max_length=200, description="Text snippet proving relationship")
    directionality: Literal["directed", "bidirectional"]

class RelationshipExtractionResult(BaseModel):
    relationships: List[Relationship]
```

---

## 8. Integration with Existing Spec

### 8.1 Merge Instructions for node-spec.md

**Target Section**: Component 3 - LightRAG Knowledge Engine (lines ~1455-1467)

**Merge Strategy**:

1. **Replace** existing high-level bullet points with detailed subsections from this document
2. **Insert** after existing Qdrant Collection Architecture section (added by mitch-roberts)
3. **Add** new subsections:
   - Entity Extraction Pipeline
   - Relationship Extraction
   - Entity Deduplication Strategy
   - LLM Integration Patterns
   - Graph Construction Workflow

### 8.2 Cross-References to Add

**In FR-011 to FR-017** (Functional Requirements section):
- Add references to detailed LightRAG sections (e.g., "See Section 4.3.2 Entity Extraction Pipeline")
- Update entity/relationship type lists to match 10 types defined here

**In Component 4 (Integration Manager)**:
- Reference LLM integration patterns for LiteLLM gateway usage

**In Deployment Architecture**:
- Add configuration requirements from Section 6.1

---

## 9. Validation Criteria

**This enhancement is complete when:**

- ✅ All 10 entity types defined with examples
- ✅ All 10 relationship types defined with directionality
- ✅ LLM prompt templates provided with few-shot examples
- ✅ Deduplication algorithm detailed with hybrid similarity scoring
- ✅ LLM integration patterns documented with error handling
- ✅ 5-phase graph construction workflow documented
- ✅ Configuration requirements specified (environment variables, Redis keys)
- ✅ Pydantic schemas provided for validation
- ✅ Quality metrics defined with target baselines

---

## Document Control

**Version**: 1.0
**Status**: Ready for Spec Integration
**Next Action**: Merge into node-spec.md Section 4.3.2 (coordinate with other agents currently editing)
**Contact**: andy-taylor (LightRAG SME)

---

**End of LightRAG Knowledge Extraction Enhancement**
