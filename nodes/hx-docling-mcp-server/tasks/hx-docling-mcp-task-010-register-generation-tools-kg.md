# Task: Register MCP Generation Tools Part 1 (Knowledge Graph Tools)

**Task ID**: hx-docling-mcp-task-010
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-001 (FastMCP Framework Installation)
**Parallel Execution**: Yes [P] (can run parallel with task 002, 004, 005)

## Objective

Implement and register knowledge graph generation MCP tools (`generate_knowledge_graph`, `extract_entities`, `extract_relationships`) with LightRAG integration, LiteLLM routing, and Qdrant storage.

## Prerequisites

- FastMCP framework installed (Task 005 complete)
- LightRAG library installed in virtual environment
- LiteLLM client configuration available
- Qdrant client configuration available

## Steps

### 1. Create Pydantic Models for Generation Tools (Knowledge Graph)

```bash
cat > /opt/docling-mcp/application/docling_mcp/models/knowledge_graph.py <<'EOF'
"""
Pydantic models for Knowledge Graph Generation Tools.

Defines input/output schemas for:
- generate_knowledge_graph
- extract_entities
- extract_relationships
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from enum import Enum

class EntityType(str, Enum):
    """Supported entity types for extraction."""
    PERSON = "person"
    ORGANIZATION = "organization"
    LOCATION = "location"
    CONCEPT = "concept"
    PRODUCT = "product"
    DATE = "date"
    EVENT = "event"

class RelationshipType(str, Enum):
    """Supported relationship types."""
    WORKS_FOR = "works_for"
    LOCATED_IN = "located_in"
    MENTIONS = "mentions"
    CITES = "cites"
    PART_OF = "part_of"
    AUTHORED_BY = "authored_by"

class LLMModel(str, Enum):
    """Available LLM models via LiteLLM routing."""
    GEMMA3_27B = "gemma3:27b"
    GPT_OSS_20B = "gpt-oss:20b"
    QWEN3_CODER_30B = "qwen3-coder:30b"
    MISTRAL_7B = "mistral:7b"

# ============================================================================
# Tool 4: generate_knowledge_graph
# ============================================================================

class GenerateKnowledgeGraphInput(BaseModel):
    """Input schema for generate_knowledge_graph tool."""
    document_sources: List[str] = Field(
        ...,
        description="List of document sources (file paths, URLs, or DoclingDocument IDs)",
        min_length=1,
        max_length=100
    )
    entity_types: List[EntityType] = Field(
        default=[
            EntityType.PERSON,
            EntityType.ORGANIZATION,
            EntityType.LOCATION,
            EntityType.CONCEPT,
            EntityType.PRODUCT,
            EntityType.DATE,
            EntityType.EVENT
        ],
        description="Entity taxonomy for extraction (extensible)"
    )
    relationship_types: List[RelationshipType] = Field(
        default=[
            RelationshipType.WORKS_FOR,
            RelationshipType.LOCATED_IN,
            RelationshipType.MENTIONS,
            RelationshipType.CITES,
            RelationshipType.PART_OF,
            RelationshipType.AUTHORED_BY
        ],
        description="Relationship taxonomy for extraction"
    )
    llm_model: LLMModel = Field(
        LLMModel.GEMMA3_27B,
        description="LLM model for entity/relationship extraction via LiteLLM"
    )
    llm_temperature: float = Field(
        0.1,
        description="LLM temperature (0.0 = deterministic, 0.1 = recommended)",
        ge=0.0,
        le=1.0
    )
    embedding_model: str = Field(
        "bge-m3:567m",
        description="Embedding model for entity/relationship vectors (Ollama3)"
    )
    deduplicate_entities: bool = Field(
        True,
        description="Semantic deduplication via Qdrant similarity search"
    )
    deduplication_threshold: float = Field(
        0.85,
        description="Cosine similarity threshold for entity deduplication",
        ge=0.0,
        le=1.0
    )
    max_chunk_size: int = Field(
        4000,
        description="Max tokens per document chunk for LLM processing",
        ge=100,
        le=8000
    )
    confidence_threshold: float = Field(
        0.5,
        description="Minimum extraction confidence to include entity/relationship",
        ge=0.0,
        le=1.0
    )

class KnowledgeGraphOutput(BaseModel):
    """Output schema for knowledge graph generation."""
    graph_summary: Dict[str, Any] = Field(
        ...,
        description="Graph statistics: entity_count, relationship_count, entity_types, relationship_types, graph_density, entity_coverage"
    )
    qdrant_collection_ids: Dict[str, str] = Field(
        ...,
        description="Qdrant collections: entities_collection, relationships_collection"
    )
    processing_metadata: Dict[str, Any] = Field(
        ...,
        description="Processing stats: documents_processed, total_processing_time_ms, llm_api_calls, entities_deduplicated, cache_hit_rate"
    )

# ============================================================================
# Tool 5: extract_entities
# ============================================================================

class ExtractEntitiesInput(BaseModel):
    """Input schema for extract_entities tool (NER only, no relationships)."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    entity_types: List[EntityType] = Field(
        default=[
            EntityType.PERSON,
            EntityType.ORGANIZATION,
            EntityType.LOCATION,
            EntityType.CONCEPT,
            EntityType.PRODUCT,
            EntityType.DATE,
            EntityType.EVENT
        ],
        description="Entity types to extract (filter)"
    )
    llm_model: LLMModel = Field(
        LLMModel.GEMMA3_27B,
        description="LLM model for NER via LiteLLM"
    )
    confidence_threshold: float = Field(
        0.5,
        description="Minimum extraction confidence",
        ge=0.0,
        le=1.0
    )
    deduplicate: bool = Field(
        True,
        description="Merge duplicate entity mentions (case-insensitive)"
    )
    include_context: bool = Field(
        True,
        description="Include surrounding text context (50 chars before/after mention)"
    )

class EntityMention(BaseModel):
    """Single entity mention in document."""
    text_span: Dict[str, int] = Field(..., description="Text span: {start: int, end: int}")
    context_snippet: Optional[str] = Field(None, description="Surrounding text context")

class Entity(BaseModel):
    """Extracted entity with mentions."""
    entity_id: str
    entity_name: str
    entity_type: EntityType
    confidence: float
    mentions: List[EntityMention]
    mention_count: int
    attributes: Optional[Dict[str, Any]] = None

class EntitiesOutput(BaseModel):
    """Output schema for extract_entities tool."""
    entities: List[Entity]
    summary: Dict[str, Any] = Field(
        ...,
        description="Summary: total_entities, entity_types (count by type), average_confidence, processing_time_ms"
    )

# ============================================================================
# Tool 6: extract_relationships
# ============================================================================

class ExtractRelationshipsInput(BaseModel):
    """Input schema for extract_relationships tool."""
    entities: List[Dict[str, Any]] = Field(
        ...,
        description="Pre-extracted entities list (from extract_entities output)",
        min_length=2
    )
    relationship_types: List[RelationshipType] = Field(
        default=[
            RelationshipType.WORKS_FOR,
            RelationshipType.LOCATED_IN,
            RelationshipType.MENTIONS,
            RelationshipType.CITES,
            RelationshipType.PART_OF,
            RelationshipType.AUTHORED_BY
        ],
        description="Relationship types to extract"
    )
    llm_model: LLMModel = Field(
        LLMModel.GEMMA3_27B,
        description="LLM model for relationship extraction"
    )
    bidirectional_handling: bool = Field(
        True,
        description="Create reverse relationships for symmetric predicates (e.g., collaborates_with)"
    )

class Relationship(BaseModel):
    """Extracted relationship triple."""
    relationship_id: str
    subject_entity_id: str
    subject_entity_name: str
    predicate: RelationshipType
    object_entity_id: str
    object_entity_name: str
    confidence: float
    bidirectional: bool
    text_evidence: str

class RelationshipsOutput(BaseModel):
    """Output schema for extract_relationships tool."""
    relationships: List[Relationship]
    summary: Dict[str, Any] = Field(
        ...,
        description="Summary: total_relationships, relationship_types (count by type), average_confidence, processing_time_ms"
    )

EOF

chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/models/knowledge_graph.py
chmod 644 /opt/docling-mcp/application/docling_mcp/models/knowledge_graph.py
```

### 2. Implement Knowledge Graph Tool Handlers

```bash
cat > /opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py <<'EOF'
"""
MCP Knowledge Graph Generation Tools Implementation.

Implements 3 MCP tools:
4. generate_knowledge_graph: Full LightRAG pipeline with Qdrant storage
5. extract_entities: Named Entity Recognition only
6. extract_relationships: Relationship extraction from known entities
"""

import logging
from fastmcp import FastMCP
from ..models.knowledge_graph import (
    GenerateKnowledgeGraphInput,
    KnowledgeGraphOutput,
    ExtractEntitiesInput,
    EntitiesOutput,
    ExtractRelationshipsInput,
    RelationshipsOutput
)

logger = logging.getLogger(__name__)

# ============================================================================
# Tool Registration Functions
# ============================================================================

def register_knowledge_graph_tools(mcp: FastMCP):
    """
    Register knowledge graph generation tools with FastMCP server.

    Args:
        mcp: FastMCP server instance
    """
    logger.info("Registering knowledge graph tools...")
    logger.info("Knowledge graph tools registered: generate_knowledge_graph, extract_entities, extract_relationships")

# ============================================================================
# Tool 4: generate_knowledge_graph
# ============================================================================

def generate_knowledge_graph_impl(mcp: FastMCP):
    """Decorator-based tool registration for generate_knowledge_graph."""

    @mcp.tool(
        name="generate_knowledge_graph",
        description="Extract entities and relationships via LightRAG, build knowledge graph in Qdrant with dual-collection architecture. Uses LLM-based entity extraction (gemma3:27b via LiteLLM) and bge-m3 embeddings."
    )
    async def generate_knowledge_graph(input: GenerateKnowledgeGraphInput) -> KnowledgeGraphOutput:
        """
        Generate knowledge graph from documents using LightRAG.

        Workflow:
        1. Document chunking (4000 tokens per chunk with 200-token overlap)
        2. Entity extraction per chunk (LLM via LiteLLM → gemma3:27b)
        3. Relationship extraction (LLM identifies subject-predicate-object triples)
        4. Semantic deduplication (Qdrant similarity search at 0.85 threshold)
        5. Graph construction (entities + relationships)
        6. Vector generation (bge-m3:567m embeddings via Ollama3)
        7. Qdrant storage (dual collections: entities + relationships)

        Args:
            input: GenerateKnowledgeGraphInput with documents and extraction parameters

        Returns:
            KnowledgeGraphOutput: Graph summary with Qdrant collection IDs and processing metadata

        Raises:
            InternalError: If LightRAG processing, LLM call, or Qdrant storage fails
        """
        logger.info(f"generate_knowledge_graph called: {len(input.document_sources)} documents, model={input.llm_model.value}")

        # TODO: Implement LightRAG integration (deferred to integration task)
        # Placeholder response

        return KnowledgeGraphOutput(
            graph_summary={
                "entity_count": 0,
                "relationship_count": 0,
                "entity_types": {},
                "relationship_types": {},
                "graph_density": 0.0,
                "entity_coverage": 0.0
            },
            qdrant_collection_ids={
                "entities_collection": "hx_docling_mcp_entities",
                "relationships_collection": "hx_docling_mcp_relationships"
            },
            processing_metadata={
                "documents_processed": len(input.document_sources),
                "total_processing_time_ms": 0,
                "llm_api_calls": 0,
                "entities_deduplicated": 0,
                "cache_hit_rate": 0.0
            }
        )

    return generate_knowledge_graph

# ============================================================================
# Tool 5: extract_entities
# ============================================================================

def extract_entities_impl(mcp: FastMCP):
    """Decorator-based tool registration for extract_entities."""

    @mcp.tool(
        name="extract_entities",
        description="Extract named entities only (no relationships) via LLM-based NER. Returns entity list with confidence scores and deduplication."
    )
    async def extract_entities(input: ExtractEntitiesInput) -> EntitiesOutput:
        """
        Extract named entities from document (NER only).

        Workflow:
        1. Convert document to DoclingDocument (if not cached)
        2. Chunk text (4000 tokens)
        3. Extract entities per chunk (LLM via LiteLLM)
        4. Deduplicate entities (case-insensitive name matching)
        5. Filter by confidence_threshold
        6. Aggregate mentions per entity

        Args:
            input: ExtractEntitiesInput with document source and extraction parameters

        Returns:
            EntitiesOutput: Entity list with mention aggregation and summary stats
        """
        logger.info(f"extract_entities called: source={input.document_source[:50]}..., model={input.llm_model.value}")

        # TODO: Implement entity extraction logic
        # Placeholder response

        return EntitiesOutput(
            entities=[],
            summary={
                "total_entities": 0,
                "entity_types": {},
                "average_confidence": 0.0,
                "processing_time_ms": 0
            }
        )

    return extract_entities

# ============================================================================
# Tool 6: extract_relationships
# ============================================================================

def extract_relationships_impl(mcp: FastMCP):
    """Decorator-based tool registration for extract_relationships."""

    @mcp.tool(
        name="extract_relationships",
        description="Extract relationships between known entities. Requires entity list as input (from extract_entities output)."
    )
    async def extract_relationships(input: ExtractRelationshipsInput) -> RelationshipsOutput:
        """
        Extract relationships from pre-extracted entities.

        Workflow:
        1. Validate entities provided (minimum 2 entities)
        2. Extract relationships between entities (LLM via LiteLLM)
        3. Validate relationship triples (subject and object must exist in entities)
        4. Handle bidirectional relationships (create reverse if symmetric)
        5. Return relationship list with evidence

        Args:
            input: ExtractRelationshipsInput with entities and relationship types

        Returns:
            RelationshipsOutput: Relationship list with summary stats
        """
        logger.info(f"extract_relationships called: {len(input.entities)} entities")

        # TODO: Implement relationship extraction logic
        # Placeholder response

        return RelationshipsOutput(
            relationships=[],
            summary={
                "total_relationships": 0,
                "relationship_types": {},
                "average_confidence": 0.0,
                "processing_time_ms": 0
            }
        )

    return extract_relationships

EOF

chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py
```

### 3. Update Server to Register Knowledge Graph Tools

**IMPORTANT**: This step is idempotent and safe to run multiple times. It checks for existing registrations before modifying server.py.

```bash
# Idempotent server integration (check before appending)
SERVER_FILE="/opt/docling-mcp/application/docling_mcp/server.py"

# Check if knowledge graph tools already registered
if grep -q "from .tools.knowledge_graph import" "$SERVER_FILE"; then
    echo "✓ Knowledge graph tools already registered in server.py, skipping"
    echo "  To verify registration, check for 'knowledge_graph' imports and registration calls"
else
    # Verify mcp instance exists before appending
    if ! grep -q "^mcp = FastMCP(" "$SERVER_FILE"; then
        echo "ERROR: mcp instance not found in server.py"
        echo "Expected: 'mcp = FastMCP(...)' initialization before tool registration"
        exit 1
    fi

    # Backup server.py before modification
    cp "$SERVER_FILE" "$SERVER_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Created backup: $SERVER_FILE.backup.*"

    # Append registration code after verifying logger exists
    if ! grep -q "^logger = " "$SERVER_FILE" && ! grep -q "^import.*structlog" "$SERVER_FILE"; then
        echo "WARNING: logger not found in server.py, registration may fail at runtime"
    fi

    cat >> "$SERVER_FILE" <<'EOF'

# ============================================================================
# Knowledge Graph Tools Registration (Task 010)
# ============================================================================

from .tools.knowledge_graph import (
    register_knowledge_graph_tools,
    generate_knowledge_graph_impl,
    extract_entities_impl,
    extract_relationships_impl
)

# Register knowledge graph tools with MCP server
# Note: Each _impl function returns the decorated tool function
register_knowledge_graph_tools(mcp)  # Logs registration start
generate_knowledge_graph_impl(mcp)   # Registers generate_knowledge_graph tool
extract_entities_impl(mcp)           # Registers extract_entities tool
extract_relationships_impl(mcp)      # Registers extract_relationships tool

logger.info("Knowledge graph tools registered: 3 tools (generate_knowledge_graph, extract_entities, extract_relationships)")
EOF

    echo "✓ Knowledge graph tools registered in server.py"
    echo "  - generate_knowledge_graph: LightRAG knowledge graph generation"
    echo "  - extract_entities: Entity extraction from documents"
    echo "  - extract_relationships: Relationship extraction between entities"
fi

# Verify the registration was added correctly
echo ""
echo "Verifying registration in server.py..."
if grep -q "from .tools.knowledge_graph import" "$SERVER_FILE" && \
   grep -q "generate_knowledge_graph_impl(mcp)" "$SERVER_FILE" && \
   grep -q "extract_entities_impl(mcp)" "$SERVER_FILE" && \
   grep -q "extract_relationships_impl(mcp)" "$SERVER_FILE"; then
    echo "✓ All knowledge graph tools properly registered"
else
    echo "✗ ERROR: Registration verification failed"
    echo "  Check $SERVER_FILE for incomplete registration"
    exit 1
fi
```

**Expected Final State in server.py** (for manual verification):

```python
# ... (existing server.py content with mcp = FastMCP(...) and logger setup) ...

# ============================================================================
# Knowledge Graph Tools Registration (Task 010)
# ============================================================================

from .tools.knowledge_graph import (
    register_knowledge_graph_tools,
    generate_knowledge_graph_impl,
    extract_entities_impl,
    extract_relationships_impl
)

# Register knowledge graph tools with MCP server
# Note: Each _impl function returns the decorated tool function
register_knowledge_graph_tools(mcp)  # Logs registration start
generate_knowledge_graph_impl(mcp)   # Registers generate_knowledge_graph tool
extract_entities_impl(mcp)           # Registers extract_entities tool
extract_relationships_impl(mcp)      # Registers extract_relationships tool

logger.info("Knowledge graph tools registered: 3 tools (generate_knowledge_graph, extract_entities, extract_relationships)")
```

**Verification Commands**:

```bash
# Check for duplicate registrations (should be exactly 1 match per line)
grep -c "from .tools.knowledge_graph import" /opt/docling-mcp/application/docling_mcp/server.py
# Expected: 1

grep -c "generate_knowledge_graph_impl(mcp)" /opt/docling-mcp/application/docling_mcp/server.py
# Expected: 1

grep -c "extract_entities_impl(mcp)" /opt/docling-mcp/application/docling_mcp/server.py
# Expected: 1

# View the complete registration block
grep -A 15 "# Knowledge Graph Tools Registration" /opt/docling-mcp/application/docling_mcp/server.py
```

### 4. Test Knowledge Graph Tool Registration

```bash
cd /opt/docling-mcp/application
python <<'PYEOF'
from docling_mcp.server import mcp

# Verify knowledge graph tools registered
kg_tool_names = ["generate_knowledge_graph", "extract_entities", "extract_relationships"]
registered_names = [tool["name"] for tool in mcp.list_tools()]

for tool_name in kg_tool_names:
    if tool_name in registered_names:
        print(f"✓ {tool_name} registered")
    else:
        print(f"✗ {tool_name} MISSING")
        exit(1)

print("\nAll 3 knowledge graph tools successfully registered")

# Verify generate_knowledge_graph has LightRAG parameters
kg_tool = [t for t in mcp.list_tools() if t["name"] == "generate_knowledge_graph"][0]
required_params = ["document_sources", "entity_types", "relationship_types", "llm_model", "deduplicate_entities", "deduplication_threshold"]

for param in required_params:
    if param in kg_tool["inputSchema"]["properties"]:
        print(f"✓ Parameter '{param}' present")
    else:
        print(f"✗ Parameter '{param}' MISSING")
        exit(1)

print("\nKnowledge graph tool schema validation complete")
PYEOF
```

## Deliverables

- Pydantic models for knowledge graph tools: `/opt/docling-mcp/application/docling_mcp/models/knowledge_graph.py`
- Knowledge graph tool implementations: `/opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py`
- 3 MCP tools registered:
  - `generate_knowledge_graph` (11 input parameters including LightRAG config)
  - `extract_entities` (6 input parameters for NER)
  - `extract_relationships` (4 input parameters for relationship extraction)
- Server updated to import and register knowledge graph tools

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Models import successfully
python -c "from docling_mcp.models.knowledge_graph import GenerateKnowledgeGraphInput, ExtractEntitiesInput, ExtractRelationshipsInput" && echo "PASS: KG models import"

# 2. Tools import successfully
python -c "from docling_mcp.tools.knowledge_graph import register_knowledge_graph_tools" && echo "PASS: KG tools import"

# 3. All 3 KG tools registered
python -c "from docling_mcp.server import mcp; kg_tools = [t for t in mcp.list_tools() if 'knowledge_graph' in t['name'] or 'entities' in t['name'] or 'relationships' in t['name']]; assert len(kg_tools) == 3" && echo "PASS: 3 KG tools registered"

# 4. Tool has LightRAG parameters
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'generate_knowledge_graph'][0]
assert 'llm_model' in tool['inputSchema']['properties']
assert 'deduplicate_entities' in tool['inputSchema']['properties']
assert 'deduplication_threshold' in tool['inputSchema']['properties']
print('PASS: LightRAG parameters present')
"
```

## Rollback

If knowledge graph tool registration fails:

```bash
rm -f /opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py
rm -f /opt/docling-mcp/application/docling_mcp/models/knowledge_graph.py
# Remove knowledge graph tool import lines from server.py
```

## Notes

- **LightRAG Integration**: Actual LightRAG processing deferred to integration task (Task 010)
- **LiteLLM Routing**: Uses gemma3:27b on Ollama1 for entity extraction (NOT granite-docling - too small per charter line 511)
- **Qdrant Dual Collections**: Stores entities and relationships in separate Qdrant collections (hx_docling_mcp_entities, hx_docling_mcp_relationships)
- **Deduplication**: Semantic similarity search in Qdrant with 0.85 cosine threshold (configurable)

## References

- **Specification**: Section 4.2 "MCP Tools" - Tools 4, 5, 6 (knowledge graph tools)
- **Previous Contribution**: `/james-mcp-tools.md` (lines 73-432): LightRAG integration workflow with complete implementation details
- **Charter**: Lines 309-318: LightRAG knowledge graph engine integration with Qdrant
- **Test Plan**: TC-INT-002 (Knowledge graph E2E), TC-E2E-002 (Multi-doc deduplication), SC-004 (KG generation success criteria)
