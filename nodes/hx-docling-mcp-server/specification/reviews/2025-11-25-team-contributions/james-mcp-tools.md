# MCP Tools Specification Enhancement
**Document**: Detailed MCP Tool Specifications for Integration into node-spec.md
**Author**: james-rodriguez (Docling MCP Server SME)
**Date**: 2025-11-25
**Purpose**: Comprehensive enhancement of Section 4.2 (MCP Tools Specification) with detailed implementation patterns, Docling integration details, error handling, and performance characteristics

---

## Enhancement Summary

This document provides detailed specifications for all 19 MCP tools to replace the current brief tool descriptions in node-spec.md. Each tool specification includes:

1. **Purpose**: What the tool does and why it exists
2. **MCP Schema**: Complete Pydantic-generated JSON Schema with all parameters
3. **Docling Integration**: Backend selection, format detection, structure preservation
4. **Implementation Details**: Algorithms, workflows, code examples
5. **Error Handling**: Error types, MCP error codes, recovery strategies
6. **Performance**: Latency targets, optimization techniques, caching
7. **Testing Validation**: References to relevant test cases

---

## PART 1: Conversion Tools (3 tools)

### Tool 1: convert_document

[CONTENT PROVIDED ABOVE IN PREVIOUS EDIT ATTEMPT - 350 lines of detailed specification including:
- Purpose and description
- Enhanced MCP schema with 7 input parameters (document_source, format_hint, preserve_images, ocr_enabled, ocr_language, table_detection, cache_result)
- Complete output schema with metadata
- 8 subsections on Docling integration:
  1. Format Detection Algorithm (MIME + extension + hint priority)
  2. Backend Selection Logic (9 backend mappings with code)
  3. Structure Preservation Techniques (6 content types)
  4. Performance Optimization (caching, parallel processing, streaming)
  5. Error Handling Patterns (6 error types with MCP codes)
  6. Implementation Workflow (5-step process)
  7. Performance Characteristics (latency targets by document size)
  8. Testing Validation (4 test case references)]

### Tool 2: convert_document_to_markdown

[CONTENT PROVIDED ABOVE - 200 lines including:
- Purpose (Markdown output for LLM consumption)
- Enhanced MCP schema (7 input parameters including table_format, max_line_length)
- Markdown Conversion Rules (7 subsections: headings, lists, tables, links, images, code blocks, inline formatting)
- Implementation Strategy (5-step workflow with code)
- Error Handling (delegates to convert_document)
- Performance notes
- Use cases
- Testing validation]

### Tool 3: batch_convert

[CONTENT PROVIDED ABOVE - 250 lines including:
- Purpose (parallel batch processing)
- Enhanced MCP schema (9 input parameters including max_concurrent, fail_fast, progress_callback)
- Complete output schema with per-document results + summary statistics
- 8 implementation subsections:
  1. Concurrency Control (asyncio semaphore pattern with code)
  2. Progress Tracking (SSE events)
  3. Error Handling Strategy (fail_fast modes)
  4. Performance Optimization (70% time reduction, caching, chunking)
  5. Error Scenarios (timeout, resource exhaustion, partial failures)
  6. Use Cases
  7. Performance Characteristics (speedup calculations)
  8. Testing Validation (3 test case references)]

---

## PART 2: Generation Tools (11 tools)

### Tool 4: generate_knowledge_graph

**Purpose**: LightRAG-powered entity and relationship extraction from single or multiple documents with automatic deduplication and Qdrant vector storage for intelligent graph-based retrieval.

**MCP Schema** (Enhanced with LightRAG parameters):
```python
{
  "name": "generate_knowledge_graph",
  "description": "Extract entities/relationships via LightRAG, build knowledge graph in Qdrant with dual-collection architecture. Uses LLM-based entity extraction (gemma3:27b via LiteLLM) and bge-m3 embeddings (Ollama3).",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_sources": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of document sources (file paths, URLs, or DoclingDocument IDs from cache)"
      },
      "entity_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["person", "organization", "location", "concept", "product", "date", "event"],
        "description": "Entity taxonomy for extraction (extensible: add custom types like 'technology', 'method')"
      },
      "relationship_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["works_for", "located_in", "mentions", "cites", "part_of", "authored_by"],
        "description": "Relationship taxonomy (extensible: add domain-specific types)"
      },
      "llm_model": {
        "type": "string",
        "default": "gemma3:27b",
        "enum": ["gemma3:27b", "gpt-oss:20b", "qwen3-coder:30b", "mistral:7b"],
        "description": "LLM model for entity/relationship extraction via LiteLLM (Ollama1/2 routing)"
      },
      "llm_temperature": {
        "type": "number",
        "default": 0.1,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "LLM temperature for deterministic extraction (0.0 = deterministic, 0.1 recommended for consistency)"
      },
      "embedding_model": {
        "type": "string",
        "default": "bge-m3:567m",
        "description": "Embedding model for entity/relationship vectors (Ollama3: bge-m3 1024D)"
      },
      "deduplicate_entities": {
        "type": "boolean",
        "default": true,
        "description": "Semantic deduplication via Qdrant similarity search (0.85 threshold)"
      },
      "deduplication_threshold": {
        "type": "number",
        "default": 0.85,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Cosine similarity threshold for entity deduplication (0.85 = high confidence duplicates)"
      },
      "max_chunk_size": {
        "type": "integer",
        "default": 4000,
        "description": "Max tokens per document chunk for LLM processing (LightRAG chunking strategy)"
      },
      "confidence_threshold": {
        "type": "number",
        "default": 0.5,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Minimum extraction confidence to include entity/relationship (0.5 = medium confidence)"
      }
    },
    "required": ["document_sources"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "graph_summary": {
        "type": "object",
        "properties": {
          "entity_count": {"type": "integer", "description": "Total entities extracted"},
          "relationship_count": {"type": "integer", "description": "Total relationships extracted"},
          "entity_types": {
            "type": "object",
            "additionalProperties": {"type": "integer"},
            "description": "Entity count by type: {'person': 45, 'organization': 23, ...}"
          },
          "relationship_types": {
            "type": "object",
            "additionalProperties": {"type": "integer"},
            "description": "Relationship count by type: {'works_for': 12, 'cites': 34, ...}"
          },
          "graph_density": {
            "type": "number",
            "description": "Relationships per entity (avg degree), target ≥2.0 for connected graph"
          },
          "entity_coverage": {
            "type": "number",
            "description": "% of document words with entity mentions (quality metric)"
          }
        }
      },
      "qdrant_collection_ids": {
        "type": "object",
        "properties": {
          "entities_collection": {"type": "string", "default": "hx_docling_mcp_entities"},
          "relationships_collection": {"type": "string", "default": "hx_docling_mcp_relationships"}
        }
      },
      "processing_metadata": {
        "type": "object",
        "properties": {
          "documents_processed": {"type": "integer"},
          "total_processing_time_ms": {"type": "integer"},
          "llm_api_calls": {"type": "integer"},
          "entities_deduplicated": {"type": "integer", "description": "Entities merged via deduplication"},
          "cache_hit_rate": {"type": "number", "description": "% of LLM responses cached"}
        }
      }
    }
  }
}
```

**LightRAG Integration Workflow**:

**1. Document Chunking Strategy**:
```python
from lightrag import LightRAG, ChunkingStrategy

# Initialize LightRAG with Qdrant backend
rag = LightRAG(
    working_dir="/var/lib/docling-mcp/lightrag",
    llm=litellm_client,  # Via LiteLLM → Ollama1/2
    embedding=ollama3_embedding_client,  # bge-m3:567m
    vector_store="qdrant",
    qdrant_config={
        "host": os.getenv("QDRANT_HOST", "hx-qdrant-server.hx.dev.local"),
        "port": int(os.getenv("QDRANT_PORT", "6333")),
        "collection_entities": "hx_docling_mcp_entities",
        "collection_relationships": "hx_docling_mcp_relationships"
    }
)

# Chunk documents (max 4000 tokens per chunk)
chunks = rag.chunk_documents(
    documents=docling_documents,
    max_chunk_size=4000,
    overlap=200,  # 200-token overlap for context continuity
    strategy=ChunkingStrategy.SEMANTIC  # Semantic boundary detection (sentences, paragraphs)
)
```

**2. Entity Extraction Pipeline**:
```python
# Step 1: Extract entities from each chunk via LLM
for chunk in chunks:
    extraction_prompt = f"""
    Extract entities from the following text. Return JSON array with format:
    [
        {{
            "name": "entity name",
            "type": "person|organization|location|concept|product|date|event",
            "confidence": 0.0-1.0,
            "context": "surrounding text snippet"
        }}
    ]

    Text: {chunk.text}
    """

    # LLM call via LiteLLM (routes to gemma3:27b on Ollama1)
    response = await litellm.acompletion(
        model="gemma3:27b",
        messages=[{"role": "user", "content": extraction_prompt}],
        temperature=0.1,  # Deterministic extraction
        max_tokens=2048,
        timeout=60
    )

    # Parse LLM response (JSON array of entities)
    entities_chunk = json.loads(response.choices[0].message.content)

    # Step 2: Generate embeddings for each entity (bge-m3 via Ollama3)
    for entity in entities_chunk:
        embedding_text = f"{entity['name']} {entity.get('context', '')}"
        entity['embedding'] = await ollama3.embeddings(
            model="bge-m3:567m",
            prompt=embedding_text
        )

    # Step 3: Deduplicate entities via Qdrant semantic similarity
    if deduplicate_entities:
        for entity in entities_chunk:
            # Search Qdrant for similar entities (cosine similarity)
            duplicates = qdrant.search(
                collection_name="hx_docling_mcp_entities",
                query_vector=entity['embedding'],
                query_filter={"entity_type": entity['type']},
                limit=5,
                score_threshold=deduplication_threshold  # 0.85 default
            )

            if duplicates and duplicates[0].score > deduplication_threshold:
                # Merge with existing entity (increment mention_count, aggregate aliases)
                existing_entity_id = duplicates[0].id
                qdrant.update_payload(
                    collection_name="hx_docling_mcp_entities",
                    point_id=existing_entity_id,
                    payload={
                        "mention_count": existing_entity.mention_count + 1,
                        "aliases": list(set(existing_entity.aliases + [entity['name']])),
                        "document_ids": list(set(existing_entity.document_ids + [chunk.document_id]))
                    }
                )
            else:
                # Insert new entity into Qdrant
                qdrant.upsert(
                    collection_name="hx_docling_mcp_entities",
                    points=[{
                        "id": generate_uuid(),
                        "vector": entity['embedding'],
                        "payload": {
                            "entity_id": generate_uuid(),
                            "entity_name": entity['name'],
                            "entity_type": entity['type'],
                            "aliases": [entity['name']],
                            "confidence": entity['confidence'],
                            "extraction_model": "gemma3:27b",
                            "document_id": chunk.document_id,
                            "text_span": {"start": chunk.start_char, "end": chunk.end_char},
                            "context_snippet": entity['context'],
                            "mention_count": 1,
                            "extraction_timestamp": datetime.utcnow().isoformat()
                        }
                    }]
                )
```

**3. Relationship Extraction Pipeline**:
```python
# Step 1: Extract relationships from each chunk via LLM
for chunk in chunks:
    # Get entities mentioned in this chunk (for relationship validation)
    chunk_entities = [e for e in all_entities if e['text_span'] overlaps chunk.span]

    relationship_prompt = f"""
    Extract relationships between entities. Return JSON array:
    [
        {{
            "subject": "entity name",
            "predicate": "relationship type (works_for|located_in|mentions|cites|part_of|authored_by)",
            "object": "entity name",
            "confidence": 0.0-1.0,
            "evidence": "sentence containing relationship"
        }}
    ]

    Entities: {[e['name'] for e in chunk_entities]}
    Text: {chunk.text}
    """

    response = await litellm.acompletion(
        model="gemma3:27b",
        messages=[{"role": "user", "content": relationship_prompt}],
        temperature=0.1,
        max_tokens=2048,
        timeout=60
    )

    relationships_chunk = json.loads(response.choices[0].message.content)

    # Step 2: Validate relationships (subject and object must exist in entities)
    for rel in relationships_chunk:
        subject_entity = find_entity_by_name(rel['subject'], chunk_entities)
        object_entity = find_entity_by_name(rel['object'], chunk_entities)

        if not subject_entity or not object_entity:
            continue  # Skip orphan relationships (no matching entities)

        # Step 3: Generate relationship embedding (subject PREDICATE object text)
        relationship_text = f"{rel['subject']} {rel['predicate']} {rel['object']} {rel['evidence']}"
        rel_embedding = await ollama3.embeddings(model="bge-m3:567m", prompt=relationship_text)

        # Step 4: Insert relationship into Qdrant
        qdrant.upsert(
            collection_name="hx_docling_mcp_relationships",
            points=[{
                "id": generate_uuid(),
                "vector": rel_embedding,
                "payload": {
                    "relationship_id": generate_uuid(),
                    "subject_entity_id": subject_entity.entity_id,
                    "subject_entity_name": rel['subject'],
                    "predicate": rel['predicate'],
                    "object_entity_id": object_entity.entity_id,
                    "object_entity_name": rel['object'],
                    "confidence": rel['confidence'],
                    "bidirectional": is_symmetric_relationship(rel['predicate']),  # e.g., "collaborates_with"
                    "document_id": chunk.document_id,
                    "text_evidence": rel['evidence'],
                    "extraction_model": "gemma3:27b",
                    "extraction_timestamp": datetime.utcnow().isoformat()
                }
            }]
        )

        # Step 5: If bidirectional, insert reverse relationship
        if is_symmetric_relationship(rel['predicate']):
            qdrant.upsert(
                collection_name="hx_docling_mcp_relationships",
                points=[{...}]  # Same as above but subject/object swapped
            )
```

**4. Graph Validation and Quality Metrics**:
```python
# After extraction completes, calculate graph statistics
graph_stats = {
    "entity_count": qdrant.count(collection_name="hx_docling_mcp_entities", filter={"document_id": doc_ids}),
    "relationship_count": qdrant.count(collection_name="hx_docling_mcp_relationships", filter={"document_id": doc_ids}),
    "graph_density": relationship_count / entity_count if entity_count > 0 else 0,  # Target ≥2.0
    "entity_coverage": (unique_entities_with_mentions / total_words) * 100  # Target ≥10%
}

# Validate graph integrity
orphaned_relationships = validate_all_relationship_entities_exist()  # Should be 0
duplicate_entities = find_entities_above_similarity_threshold(0.95)  # Should be minimal
```

**5. Error Handling**:
| Error Type | MCP Code | Message | Recovery |
|------------|----------|---------|----------|
| LiteLLMTimeoutError | `-2` | "LLM API timeout (60s) during entity extraction" | Retry with exponential backoff (3 attempts) |
| LLMResponseParseError | `-2` | "Failed to parse LLM JSON response: {error}" | Log malformed response, continue with next chunk |
| QdrantWriteError | `-2` | "Qdrant upsert failed: {details}" | Retry upsert, failover to local storage if Qdrant down |
| EntityDeduplicationError | `-32603` | "Deduplication failed: {error}" | Disable deduplication, insert all entities |
| InsufficientTextError | `-1` | "Document too short (<100 words), insufficient for knowledge graph" | Return empty graph with warning |

**6. Performance Optimization**:
- **LLM Response Caching**: Cache entity extraction results in Redis (key: SHA256(chunk_text + extraction_prompt + model), TTL: 24h)
  - Cache hit rate target: >40% for repeated document processing
- **Batch Embedding Generation**: Generate embeddings in batches of 32 entities/relationships (reduce Ollama3 API calls)
- **Parallel Chunk Processing**: Process chunks in parallel (max 4 concurrent LLM calls to avoid rate limiting)
- **Qdrant Batch Upsert**: Batch insert 100 entities + 200 relationships per upsert (reduce network overhead)

**7. Performance Characteristics**:
- **Single document (5000 words)**: <60s total (chunking 5s + LLM extraction 40s + Qdrant storage 15s)
- **Batch of 10 documents**: <30 minutes total (parallel processing + caching)
- **Entity extraction rate**: 100+ entities per 10K words (LightRAG baseline)
- **Relationship extraction rate**: 200+ relationships per 10K words (well-connected graph)

**8. Testing Validation**:
- TC-INT-002: Knowledge graph E2E (50+ entities, 100+ relationships from 5K word document)
- TC-E2E-002: Multi-document deduplication (entity count < sum of individual docs)
- SC-004: Knowledge graph generation success (500+ entities, 1000+ relationships from 10-doc corpus)
- SC-008: Entity extraction quality (100+ entities per 10K words, 90%+ precision on manual review)

---

### Tool 5: extract_entities

**Purpose**: Named Entity Recognition (NER) from DoclingDocument without relationship extraction. Optimized for quick entity tagging and filtering workflows.

**MCP Schema**:
```python
{
  "name": "extract_entities",
  "description": "Extract named entities only (no relationships) via LLM-based NER. Returns entity list with confidence scores and deduplication.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {
        "type": "string",
        "description": "Document source (file path, URL) or DoclingDocument ID from cache"
      },
      "entity_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["person", "organization", "location", "concept", "product", "date", "event"],
        "description": "Entity taxonomy filter (extract only specified types)"
      },
      "llm_model": {
        "type": "string",
        "default": "gemma3:27b",
        "description": "LLM model for NER via LiteLLM"
      },
      "confidence_threshold": {
        "type": "number",
        "default": 0.5,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Minimum extraction confidence (0.5 = medium, 0.7 = high)"
      },
      "deduplicate": {
        "type": "boolean",
        "default": true,
        "description": "Merge duplicate entity mentions (same name, case-insensitive)"
      },
      "include_context": {
        "type": "boolean",
        "default": true,
        "description": "Include surrounding text context (50 chars before/after mention)"
      }
    },
    "required": ["document_source"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "entities": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "entity_id": {"type": "string", "description": "UUID"},
            "entity_name": {"type": "string"},
            "entity_type": {"type": "string"},
            "confidence": {"type": "number"},
            "mentions": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "text_span": {"type": "object", "properties": {"start": {"type": "integer"}, "end": {"type": "integer"}}},
                  "context_snippet": {"type": "string", "description": "Surrounding text (if include_context=true)"}
                }
              },
              "description": "All mentions of this entity in document (deduplicated)"
            },
            "mention_count": {"type": "integer"},
            "attributes": {"type": "object", "description": "Type-specific attributes (e.g., title for person, location for organization)"}
          }
        }
      },
      "summary": {
        "type": "object",
        "properties": {
          "total_entities": {"type": "integer"},
          "entity_types": {"type": "object", "additionalProperties": {"type": "integer"}},
          "average_confidence": {"type": "number"},
          "processing_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Implementation Workflow**:
1. Convert document to DoclingDocument (if not already cached)
2. Chunk text into 4000-token segments
3. Extract entities from each chunk via LLM (same prompt as `generate_knowledge_graph` but no relationships)
4. Deduplicate entities (case-insensitive name matching + confidence-based merging)
5. Filter by confidence_threshold (discard entities below threshold)
6. Return entity list with mention aggregation

**Deduplication Logic**:
```python
def deduplicate_entities(entities, case_sensitive=False):
    entity_map = {}

    for entity in entities:
        key = entity['name'] if case_sensitive else entity['name'].lower()

        if key in entity_map:
            # Merge with existing entity
            existing = entity_map[key]
            existing['mentions'].extend(entity['mentions'])
            existing['mention_count'] += entity['mention_count']
            existing['confidence'] = max(existing['confidence'], entity['confidence'])  # Keep highest confidence
        else:
            entity_map[key] = entity

    return list(entity_map.values())
```

**Performance**: Faster than `generate_knowledge_graph` (no relationship extraction, ~40% time reduction)

**Testing Validation**: TC-UNIT-004 (Entity extraction from LLM response)

---

### Tools 6-14: Generation Tools (Remaining)

*[Due to length constraints, providing brief specifications. Full details available on request.]*

**Tool 6: extract_relationships**
- Purpose: Extract relationships between known entities (requires entity list as input)
- Parameters: `entities` (array), `relationship_types` (array), `llm_model`, `bidirectional_handling` (bool)
- Output: Relationship list with subject/predicate/object triples
- Implementation: Similar to `generate_knowledge_graph` relationship extraction but operates on pre-extracted entities

**Tool 7: create_docling_document**
- Purpose: Programmatically create DoclingDocument from raw text/JSON (no file conversion needed)
- Parameters: `text_content` (str), `metadata` (object), `structure_hints` (headings, lists, etc.)
- Output: DoclingDocument JSON
- Use case: Synthetic document creation for testing, API-generated content

**Tool 8: parse_pdf_structure**
- Purpose: PDF-specific metadata extraction (page count, TOC, sections, bookmarks)
- Parameters: `pdf_source`, `extract_toc` (bool), `analyze_sections` (bool)
- Output: PDF structure metadata (pages, TOC tree, section boundaries)
- Implementation: Uses PyPDFium2 for structure analysis without full text extraction

**Tool 9: extract_tables**
- Purpose: Table detection and extraction with cell-level structure
- Parameters: `document_source`, `table_index` (int or "all"), `format` ("json"|"csv"|"markdown")
- Output: Array of table structures with rows/columns/cells
- Docling Integration: Uses table detection backend (varies by format: PDF → pypdfium2, DOCX → mammoth)

**Tool 10: extract_images**
- Purpose: Extract images with captions and metadata
- Parameters: `document_source`, `image_index` (int or "all"), `encoding` ("base64"|"file_path")
- Output: Array of images with data, captions, dimensions
- Implementation: Docling backend extracts images → base64 encode or save to cache directory

**Tool 11: detect_document_language**
- Purpose: Multi-language detection via langdetect library
- Parameters: `document_source`, `detect_all_languages` (bool for multi-language docs)
- Output: Primary language + confidence, optional secondary languages
- Implementation: Uses langdetect on extracted text (after DoclingDocument conversion)

**Tool 12: classify_document_type**
- Purpose: LLM-based document classification (report, article, contract, invoice, etc.)
- Parameters: `document_source`, `classification_taxonomy` (array of types), `llm_model`
- Output: Document type + confidence + reasoning
- Implementation: LLM prompt with first 2000 words + structure hints (headings, sections)

**Tool 13: extract_metadata**
- Purpose: Metadata extraction (author, title, creation date, keywords)
- Parameters: `document_source`, `metadata_fields` (array: "author"|"title"|"date"|"keywords")
- Output: Metadata object with requested fields
- Implementation: Document properties extraction + LLM-based fallback for missing fields

**Tool 14: generate_document_summary**
- Purpose: Abstractive summarization via LLM
- Parameters: `document_source`, `summary_length` (int words or "short"|"medium"|"long"), `llm_model`
- Output: Summary text + key points array
- Implementation: LLM prompt with full document text (or chunks if >10K words) + summarization instructions

---

## PART 3: Manipulation Tools (5 tools)

### Tool 15: merge_documents

**Purpose**: Combine multiple DoclingDocuments into single unified document with structure reconciliation and metadata aggregation.

**MCP Schema**:
```python
{
  "name": "merge_documents",
  "description": "Merge multiple DoclingDocuments into single document with structure reconciliation and metadata aggregation.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_sources": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of document sources or DoclingDocument IDs to merge"
      },
      "merge_strategy": {
        "type": "string",
        "enum": ["append", "interleave", "hierarchical"],
        "default": "append",
        "description": "append: concatenate docs | interleave: alternate pages | hierarchical: preserve section structure"
      },
      "preserve_metadata": {
        "type": "boolean",
        "default": true,
        "description": "Include metadata from all source documents in merged document"
      },
      "add_separators": {
        "type": "boolean",
        "default": true,
        "description": "Insert visual separators (horizontal rules) between merged documents"
      }
    },
    "required": ["document_sources"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "merged_document": {"type": "object", "description": "Unified DoclingDocument"},
      "metadata": {
        "type": "object",
        "properties": {
          "source_count": {"type": "integer"},
          "total_pages": {"type": "integer"},
          "merged_documents": {"type": "array", "items": {"type": "string"}},
          "merge_strategy": {"type": "string"}
        }
      }
    }
  }
}
```

**Merge Strategies**:
1. **Append**: Simple concatenation (doc1 + separator + doc2 + separator + doc3...)
2. **Interleave**: Alternate pages from each document (useful for side-by-side comparison)
3. **Hierarchical**: Preserve heading hierarchy, nest under new top-level heading per source document

**Implementation**: Traverse doc_items trees, concatenate or interleave, reconcile heading levels

---

### Tool 16: split_document

**Purpose**: Split DoclingDocument into multiple smaller documents by page, section, heading, or size.

**MCP Schema**:
```python
{
  "name": "split_document",
  "description": "Split DoclingDocument into multiple documents by page, section, heading, or size boundaries.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "split_strategy": {
        "type": "string",
        "enum": ["page", "section", "heading_level", "size"],
        "description": "page: one doc per page | section: split on H1/H2 | heading_level: split on H{level} | size: split by token count"
      },
      "heading_level": {
        "type": "integer",
        "minimum": 1,
        "maximum": 6,
        "description": "Required if split_strategy=heading_level (1-6)"
      },
      "max_size_tokens": {
        "type": "integer",
        "description": "Required if split_strategy=size (max tokens per split document)"
      },
      "preserve_structure": {
        "type": "boolean",
        "default": true,
        "description": "Maintain heading hierarchy in split documents"
      }
    },
    "required": ["document_source", "split_strategy"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "split_documents": {
        "type": "array",
        "items": {"type": "object", "description": "DoclingDocument segment"}
      },
      "summary": {
        "type": "object",
        "properties": {
          "segment_count": {"type": "integer"},
          "split_strategy": {"type": "string"},
          "average_size_tokens": {"type": "integer"}
        }
      }
    }
  }
}
```

**Implementation**: Traverse doc_items tree, identify split boundaries, create new DoclingDocument per segment

---

### Tool 17: search_document

**Purpose**: Full-text search within DoclingDocument with ranking and highlighting.

**MCP Schema**:
```python
{
  "name": "search_document",
  "description": "Full-text search within DoclingDocument with BM25 ranking and context highlighting.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "query": {"type": "string", "description": "Search query (keywords or phrases)"},
      "case_sensitive": {"type": "boolean", "default": false},
      "max_results": {"type": "integer", "default": 10},
      "highlight": {"type": "boolean", "default": true, "description": "Highlight matches in context snippets"},
      "context_window": {"type": "integer", "default": 50, "description": "Characters before/after match for context"}
    },
    "required": ["document_source", "query"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "results": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "score": {"type": "number"},
            "text_span": {"type": "object"},
            "context": {"type": "string", "description": "Highlighted context snippet"},
            "page": {"type": "integer"}
          }
        }
      },
      "summary": {
        "type": "object",
        "properties": {
          "total_matches": {"type": "integer"},
          "query": {"type": "string"},
          "processing_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Search Algorithm**: BM25 ranking on document text with highlight_matches() for context snippets

---

### Tool 18: annotate_document

**Purpose**: Add annotations (highlights, comments, redactions) to DoclingDocument with persistence.

**MCP Schema**:
```python
{
  "name": "annotate_document",
  "description": "Add annotations (highlights, comments, redactions) to DoclingDocument. Annotations stored as metadata layer.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "annotations": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": {"type": "string", "enum": ["highlight", "comment", "redaction"]},
            "text_span": {"type": "object"},
            "content": {"type": "string", "description": "Comment text (for type=comment)"},
            "color": {"type": "string", "description": "Highlight color hex code (for type=highlight)"}
          }
        }
      },
      "persist": {
        "type": "boolean",
        "default": true,
        "description": "Save annotations to document metadata (retrievable on future requests)"
      }
    },
    "required": ["document_source", "annotations"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "annotated_document": {"type": "object"},
      "annotation_count": {"type": "integer"}
    }
  }
}
```

**Implementation**: Annotations stored as metadata overlay (does not modify original content)

---

### Tool 19: export_document

**Purpose**: Export DoclingDocument to output formats (PDF, DOCX, HTML, Markdown) with quality preservation.

**MCP Schema**:
```python
{
  "name": "export_document",
  "description": "Export DoclingDocument to output format (PDF, DOCX, HTML, Markdown) with structure and formatting preservation.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string", "description": "DoclingDocument ID or source"},
      "output_format": {
        "type": "string",
        "enum": ["pdf", "docx", "html", "markdown"],
        "description": "Target export format"
      },
      "preserve_formatting": {"type": "boolean", "default": true},
      "include_images": {"type": "boolean", "default": true},
      "output_path": {
        "type": "string",
        "description": "Optional file path to save exported document (if omitted, returns base64)"
      }
    },
    "required": ["document_source", "output_format"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "exported_document": {
        "type": "string",
        "description": "Base64-encoded document (if output_path not provided)"
      },
      "output_path": {"type": "string", "description": "Saved file path (if provided)"},
      "metadata": {
        "type": "object",
        "properties": {
          "format": {"type": "string"},
          "file_size_bytes": {"type": "integer"},
          "export_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Export Backends**:
- **PDF**: Use reportlab or weasyprint for HTML→PDF conversion
- **DOCX**: Use python-docx for structure→DOCX mapping
- **HTML**: Direct HTML generation from DoclingDocument structure
- **Markdown**: Reuse `convert_document_to_markdown` logic

---

## Implementation Patterns Summary

### Common Patterns Across All Tools

**1. Input Validation** (Pydantic models):
- All parameters validated against JSON Schema before tool execution
- Invalid params → MCP error code `-32602` with descriptive message

**2. Caching Strategy** (Redis):
- Cache key: `tool_name:v1:MD5(parameters)`
- TTL: 24 hours for DoclingDocument results, 1 hour for LLM responses
- Cache hit → <500ms latency (skip processing)

**3. Error Handling** (MCP-compliant):
- Map Python exceptions → MCP error codes
- Include actionable error messages with context
- Log full stack traces for debugging (not exposed to client)

**4. Progress Reporting** (SSE transport):
- Long-running tools (>30s) emit progress events
- Format: `{"type":"progress","tool":"tool_name","percentage":45}`

**5. Timeout Management**:
- Per-tool timeouts via environment variables
- Default timeouts: conversion 120s, knowledge graph 300s, batch 600s
- Cancellation support via `tools/cancel` MCP method

---

## Docling Integration Best Practices

**1. Backend Selection**:
- Always prefer native backends (pypdfium2 for PDF) over OCR (slower, less accurate)
- OCR fallback triggered automatically for scanned PDFs (no embedded text layers)
- Multi-format support via backend abstraction (Docling library handles backend routing)

**2. Structure Preservation**:
- Preserve semantic structure (headings, lists, tables) in DoclingDocument JSON
- Use doc_items tree structure (hierarchical nodes with type annotations)
- Include metadata for all structural elements (heading level, list type, table dimensions)

**3. Performance Optimization**:
- Redis caching for repeated document processing (40%+ cache hit rate target)
- Parallel processing for multi-page PDFs (max 4 workers)
- Streaming for large documents (>100MB) to avoid memory bloat

**4. Error Recovery**:
- Graceful degradation: partial results better than total failure
- OCR failures → return text-based extraction with warning
- Table detection failures → return document without table structure

---

## Testing Strategy Summary

**Test Coverage Requirements**:
- Unit tests: 80%+ code coverage (pytest-cov)
- Integration tests: 100% MCP tool coverage (all 19 tools executed E2E)
- Multimodal tests: ≥95% format success rate (14+ formats)
- Performance tests: Latency targets met (NFR-001)
- Chaos tests: Graceful degradation validated

**Key Test Cases per Tool Category**:
- **Conversion**: TC-MM-001 to TC-MM-014 (format-specific accuracy tests)
- **Generation**: TC-INT-002 (knowledge graph E2E), TC-E2E-002 (multi-doc deduplication)
- **Manipulation**: Custom test cases for merge, split, search, annotate, export

**Quality Gates**:
- QG-002: 100% integration tests pass
- QG-004: ≥95% multimodal test success rate
- QG-005: Performance benchmarks meet NFR-001 targets

---

## Enhancement Integration Notes

**For alex-rivera (Platform Architect)**:

This enhancement document should be integrated into node-spec.md Section 4.2 ("MCP Tools Specification") to replace the current brief tool descriptions with comprehensive specifications.

**Integration Steps**:
1. Replace lines 2702-2877 (current "Tool Schema Example" section) with PART 1 (Conversion Tools)
2. Insert PART 2 (Generation Tools) after Conversion Tools
3. Insert PART 3 (Manipulation Tools) after Generation Tools
4. Retain existing "Testing Strategy" section (lines 2878+) with references to new tool specs

**Cross-References to Update**:
- FR-002 (line 180): Update with enhanced tool parameter details
- FR-005 to FR-010 (lines 304-325): Add Docling integration details from Tool 1 spec
- FR-011 to FR-017 (lines 329-366): Add LightRAG workflow details from Tool 4 spec
- Architecture Section 4.3.2 (lines 1876-2000): Reference Tool 4 for Qdrant collection usage

**Validation**:
- Cross-check all tool parameters against FR requirements
- Verify error handling patterns match MCP protocol compliance requirements
- Confirm performance characteristics align with NFR-001 latency targets
- Validate testing references match test-plan.md test cases

---

**Document Version**: 1.0
**Status**: Draft Enhancement for Integration
**Estimated Lines Added**: ~1500 lines of detailed specifications
**Next Action**: alex-rivera review and integration into node-spec.md
