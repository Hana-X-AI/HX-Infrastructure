# Task: Document Processing Pipeline Integration

**Task ID**: hx-docling-mcp-task-031
**Category**: MCP Tools - Backend Integration
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-020 (Docling MCP Integration from Albert), hx-docling-mcp-task-025 (Entity Deduplication), hx-docling-mcp-task-026 (LiteLLM Integration)
**Parallel Execution**: No (CRITICAL PATH - requires all backend integrations complete)

## Objective

Replace all placeholder MCP tool implementations with actual Docling document processing and LightRAG knowledge graph generation by integrating the complete processing pipeline (Tasks 020, 025, 026 backends).

## Prerequisites

- All 19 MCP tools registered with placeholder implementations (Tasks 009-012 complete)
- Docling processing backend integrated (Task 020 complete)
- Entity deduplication strategy implemented (Task 025 complete)
- LiteLLM integration operational (Task 026 complete)
- Qdrant and Redis clients configured (Tasks 027-028 complete)

## Steps

### 1. Create Integrated Processing Pipeline Manager

```bash
# Create pipeline orchestration module
cat > /opt/docling-mcp/application/docling_mcp/pipeline/processor.py <<'EOF'
"""
Document Processing Pipeline Manager.

Orchestrates full pipeline:
1. Document ingestion (Docling)
2. Knowledge graph generation (LightRAG)
3. Entity deduplication (Qdrant semantic similarity)
4. Storage (Qdrant + Redis caching)
"""

import logging
import hashlib
from typing import Dict, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)

class DocumentProcessor:
    """Orchestrate document processing pipeline."""

    def __init__(self, docling_backend, lightrag_engine, qdrant_client, redis_client, litellm_client):
        """
        Initialize processor with all backend integrations.

        Args:
            docling_backend: Docling processing backend (from Task 020)
            lightrag_engine: LightRAG knowledge graph engine (from Task 025)
            qdrant_client: Qdrant vector database client
            redis_client: Redis cache client
            litellm_client: LiteLLM gateway client (from Task 026)
        """
        self.docling = docling_backend
        self.lightrag = lightrag_engine
        self.qdrant = qdrant_client
        self.redis = redis_client
        self.litellm = litellm_client

        logger.info("DocumentProcessor initialized with all backends")

    async def convert_document(
        self,
        source: str,
        format_hint: Optional[str] = None,
        preserve_images: bool = True,
        ocr_enabled: bool = True,
        table_detection: bool = True,
        cache_result: bool = True
    ) -> Dict[str, Any]:
        """
        Convert document to DoclingDocument format with caching.

        This replaces the placeholder implementation from Task 002 (convert_document tool).

        Args:
            source: Document source (file://, http://, data:)
            format_hint: Optional format hint
            preserve_images: Include images in output
            ocr_enabled: Enable OCR for scanned documents
            table_detection: Enable table detection
            cache_result: Cache converted DoclingDocument in Redis

        Returns:
            DoclingDocument dict with structure and metadata
        """
        # Validate cache key format
        try:
            cache_key = f"docling:v1:{hashlib.sha256(source.encode()).hexdigest()}"
        except Exception as e:
            logger.warning(f"Failed to generate cache key: {e}, proceeding without cache")
            cache_key = None
        
        # Check Redis cache first
        if cache_result and self.redis and cache_key:
            try:
                cached = await self.redis.get(cache_key)
                if cached:
                    logger.info(f"Cache hit: {cache_key[:30]}...")
                    return cached
                else:
                    logger.debug(f"Cache miss: {cache_key[:30]}...")
            except Exception as e:
                logger.warning(f"Redis cache read error: {e}, proceeding with conversion")

        # Convert via Docling backend (Task 020)
        try:
            logger.info(f"Converting document via Docling: {source[:50]}...")
            docling_result = await self.docling.convert(
                source=source,
                format_hint=format_hint,
                preserve_images=preserve_images,
                ocr_enabled=ocr_enabled,
                table_detection=table_detection
            )
        except Exception as e:
            logger.error(f"Docling conversion failed for source '{source[:50]}...': {e}", exc_info=True)
            raise

        # Cache result in Redis (24h TTL)
        if cache_result and self.redis and cache_key:
            try:
                await self.redis.setex(cache_key, 86400, docling_result)
                logger.debug(f"Cached DoclingDocument: {cache_key[:30]}...")
            except Exception as e:
                logger.warning(f"Failed to cache result: {e}, proceeding without cache")

        return docling_result

    async def generate_knowledge_graph(
        self,
        docling_document: Dict[str, Any],
        llm_model: str = "gemma3:27b",
        entity_types: Optional[list] = None,
        confidence_threshold: float = 0.5,
        max_entities: int = 1000
    ) -> Dict[str, Any]:
        """
        Generate knowledge graph from DoclingDocument via LightRAG.

        This replaces the placeholder implementation from Task 003 (generate_knowledge_graph tool).

        Workflow:
        1. Extract text from DoclingDocument
        2. Chunk text (max 4000 tokens per chunk)
        3. Extract entities via LiteLLM + Ollama models (Task 026)
        4. Extract relationships via LightRAG
        5. Deduplicate entities via Qdrant semantic similarity (Task 025)
        6. Insert entities and relationships into Qdrant

        Args:
            docling_document: DoclingDocument dict from convert_document
            llm_model: LLM model for entity extraction (via LiteLLM)
            entity_types: Filter to specific entity types
            confidence_threshold: Minimum entity/relationship confidence
            max_entities: Maximum entities to extract

        Returns:
            Knowledge graph result with entity/relationship counts and Qdrant collection IDs
        """
        logger.info(f"Generating knowledge graph via LightRAG: llm_model={llm_model}")

        # Extract text from DoclingDocument
        text_content = self._extract_text_from_docling(docling_document)

        # Generate knowledge graph via LightRAG engine (Task 025)
        kg_result = await self.lightrag.generate_graph(
            text=text_content,
            llm_model=llm_model,
            entity_types=entity_types,
            confidence_threshold=confidence_threshold,
            max_entities=max_entities
        )

        logger.info(
            f"Knowledge graph generated: {kg_result['entity_count']} entities, "
            f"{kg_result['relationship_count']} relationships"
        )

        return kg_result

    def _extract_text_from_docling(self, docling_document: Dict[str, Any]) -> str:
        """
        Extract plain text from DoclingDocument for knowledge graph generation.

        Args:
            docling_document: DoclingDocument dict

        Returns:
            Concatenated text content from all doc_items
        """
        # Validate input is a dict
        if not isinstance(docling_document, dict):
            logger.warning(f"Invalid docling_document type: {type(docling_document)}, expected dict")
            return ""
        
        doc_items = docling_document.get("doc_items", [])
        
        # Validate doc_items is a list
        if not isinstance(doc_items, list):
            logger.warning(f"Invalid doc_items type: {type(doc_items)}, expected list")
            return ""
        
        text_parts = []

        for idx, item in enumerate(doc_items):
            # Skip non-dict items
            if not isinstance(item, dict):
                logger.warning(f"Skipping non-dict item at index {idx}: {type(item)}")
                continue
            
            item_type = item.get("type", "unknown")
            
            if item_type in ["heading", "paragraph", "list_item"]:
                # Only append if text is present and non-empty after stripping
                text = item.get("text", "")
                if text:
                    text_stripped = text.strip()
                    if text_stripped:
                        text_parts.append(text_stripped)
            
            elif item_type == "table":
                # Extract table text (cells concatenated)
                cells = item.get("cells", [])
                
                # Ensure cells is a list
                if not isinstance(cells, list):
                    logger.warning(f"Table at index {idx} has non-list cells: {type(cells)}")
                    continue
                
                table_texts = []
                for cell in cells:
                    # Skip non-dict cells
                    if not isinstance(cell, dict):
                        continue
                    
                    # Only collect if text is present and non-empty
                    cell_text = cell.get("text", "")
                    if cell_text:
                        cell_text_stripped = cell_text.strip()
                        if cell_text_stripped:
                            table_texts.append(cell_text_stripped)
                
                if table_texts:
                    text_parts.append(" ".join(table_texts))
            
            # Ignore other item types silently

        return "\n\n".join(text_parts)

# Global processor instance (initialized in server.py)
_processor: Optional[DocumentProcessor] = None
_processor_lock = threading.Lock()

def get_processor() -> DocumentProcessor:
    """Get global DocumentProcessor instance."""
    if _processor is None:
        raise RuntimeError("DocumentProcessor not initialized. Call initialize_processor() first.")
    return _processor

def initialize_processor(docling_backend, lightrag_engine, qdrant_client, redis_client, litellm_client):
    """Initialize global DocumentProcessor instance with thread-safe initialization."""
    global _processor
    
    with _processor_lock:
        if _processor is not None:
            logger.warning("DocumentProcessor already initialized, skipping re-initialization")
            return
        
        _processor = DocumentProcessor(
            docling_backend=docling_backend,
            lightrag_engine=lightrag_engine,
            qdrant_client=qdrant_client,
            redis_client=redis_client,
            litellm_client=litellm_client
        )
        logger.info("Global DocumentProcessor initialized")

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/pipeline/processor.py
chmod 644 /opt/docling-mcp/application/docling_mcp/pipeline/processor.py
```

### 2. Update Conversion Tools to Use Pipeline

```bash
# Replace placeholder implementations in conversion.py
cat > /opt/docling-mcp/application/docling_mcp/tools/conversion_integrated.py <<'EOF'
"""
Updated conversion.py with integrated pipeline (replaces placeholders).
"""

import logging
from fastmcp import FastMCP
from ..models.conversion import (
    ConvertDocumentInput,
    DoclingDocumentOutput,
    ConvertToMarkdownInput,
    MarkdownOutput,
    BatchConvertInput,
    BatchConvertOutput,
    BatchDocumentResult
)
from ..pipeline.processor import get_processor

logger = logging.getLogger(__name__)

def convert_document_impl_integrated(mcp: FastMCP):
    """INTEGRATED convert_document with actual Docling processing."""

    @mcp.tool(
        name="convert_document",
        description="Convert document (PDF, DOCX, PPTX, XLSX, HTML, images) to structured DoclingDocument format."
    )
    async def convert_document(input: ConvertDocumentInput) -> DoclingDocumentOutput:
        """Convert document via integrated pipeline (REPLACES PLACEHOLDER)."""
        logger.info(f"convert_document (INTEGRATED): source={input.document_source[:50]}...")

        processor = get_processor()

        # Use actual Docling conversion (not placeholder)
        result = await processor.convert_document(
            source=input.document_source,
            format_hint=input.format_hint,
            preserve_images=input.preserve_images,
            ocr_enabled=input.ocr_enabled,
            table_detection=input.table_detection,
            cache_result=input.cache_result
        )

        return DoclingDocumentOutput(
            document_id=result["document_id"],
            format=result["format"],
            content=result["content"],
            metadata=result["metadata"]
        )

    return convert_document

# Repeat for convert_document_to_markdown and batch_convert...
# (Similar pattern: get_processor() → call actual backend method)

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/conversion_integrated.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/conversion_integrated.py
```

### 3. Update Generation Tools to Use Pipeline

```bash
# Replace placeholder implementations in generation_kg.py
cat > /opt/docling-mcp/application/docling_mcp/tools/generation_kg_integrated.py <<'EOF'
"""
Updated generation_kg.py with integrated LightRAG pipeline (replaces placeholders).
"""

import logging
from fastmcp import FastMCP
from ..models.generation_kg import (
    GenerateKnowledgeGraphInput,
    KnowledgeGraphResult
)
from ..pipeline.processor import get_processor

logger = logging.getLogger(__name__)

def generate_knowledge_graph_impl_integrated(mcp: FastMCP):
    """INTEGRATED generate_knowledge_graph with actual LightRAG processing."""

    @mcp.tool(
        name="generate_knowledge_graph",
        description="Generate knowledge graph with entities and relationships via LightRAG."
    )
    async def generate_knowledge_graph(input: GenerateKnowledgeGraphInput) -> KnowledgeGraphResult:
        """Generate knowledge graph via integrated pipeline (REPLACES PLACEHOLDER)."""
        logger.info(f"generate_knowledge_graph (INTEGRATED): llm_model={input.llm_model}")

        processor = get_processor()

        # Parse docling_document JSON
        import json
        docling_doc = json.loads(input.docling_document)

        # Use actual LightRAG knowledge graph generation (not placeholder)
        kg_result = await processor.generate_knowledge_graph(
            docling_document=docling_doc,
            llm_model=input.llm_model,
            entity_types=input.entity_types,
            confidence_threshold=input.confidence_threshold,
            max_entities=input.max_entities
        )

        return KnowledgeGraphResult(
            entity_count=kg_result["entity_count"],
            relationship_count=kg_result["relationship_count"],
            entity_collection_id=kg_result["entity_collection_id"],
            relationship_collection_id=kg_result["relationship_collection_id"],
            statistics=kg_result["statistics"]
        )

    return generate_knowledge_graph

# Repeat for extract_entities and extract_relationships...

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/generation_kg_integrated.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/generation_kg_integrated.py
```

### 4. Update Server to Initialize Pipeline

```bash
# Update server.py to initialize pipeline on startup
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import pipeline initialization
from .pipeline.processor import initialize_processor
from .integrations.docling_backend import get_docling_backend
from .integrations.lightrag_engine import get_lightrag_engine
from .integrations.qdrant_client import get_qdrant_client
from .integrations.redis_client import get_redis_client
from .integrations.litellm_client import get_litellm_client

def initialize_backends():
    """Initialize all backend integrations before starting server with validation."""
    logger.info("Initializing backend integrations...")

    # Define backends to initialize with validation
    backends = [
        ("Docling Backend", get_docling_backend),
        ("LightRAG Engine", get_lightrag_engine),
        ("Qdrant Client", get_qdrant_client),
        ("Redis Client", get_redis_client),
        ("LiteLLM Client", get_litellm_client)
    ]
    
    initialized_backends = {}
    
    # Initialize and validate each backend
    for name, getter in backends:
        try:
            logger.info(f"Initializing {name}...")
            backend = getter()
            
            if backend is None:
                error_msg = f"{name} initialization returned None"
                logger.error(error_msg)
                raise RuntimeError(error_msg)
            
            initialized_backends[name] = backend
            logger.info(f"✓ {name} initialized successfully")
            
        except Exception as e:
            error_msg = f"Failed to initialize {name}: {e}"
            logger.error(error_msg, exc_info=True)
            raise RuntimeError(error_msg) from e

    # Initialize global pipeline processor with validated backends
    try:
        initialize_processor(
            docling_backend=initialized_backends["Docling Backend"],
            lightrag_engine=initialized_backends["LightRAG Engine"],
            qdrant_client=initialized_backends["Qdrant Client"],
            redis_client=initialized_backends["Redis Client"],
            litellm_client=initialized_backends["LiteLLM Client"]
        )
        logger.info("✓ All backends initialized, pipeline ready")
    except Exception as e:
        error_msg = f"Failed to initialize DocumentProcessor: {e}"
        logger.error(error_msg, exc_info=True)
        raise RuntimeError(error_msg) from e

# Call backend initialization BEFORE server startup
initialize_backends()

EOF
```

### 5. Create Integration Test

```bash
# Create end-to-end integration test
cat > /opt/docling-mcp/application/tests/test_pipeline_integration.py <<'EOF'
"""
Test integrated document processing pipeline.
"""

import pytest
from docling_mcp.server import mcp
from docling_mcp.pipeline.processor import get_processor

@pytest.mark.asyncio
async def test_convert_document_integrated():
    """Test convert_document with actual Docling backend."""
    # Get MCP tool
    tool = [t for t in mcp.list_tools() if t["name"] == "convert_document"][0]

    # Call tool with test document
    result = await mcp.call_tool(
        "convert_document",
        {
            "document_source": "file:///opt/docling-mcp/test-data/sample.pdf",
            "preserve_images": True,
            "ocr_enabled": True
        }
    )

    # Verify result is DoclingDocument (not placeholder)
    assert "document_id" in result
    assert "content" in result
    assert result["metadata"]["backend_used"] != "placeholder"  # Should be actual backend name

@pytest.mark.asyncio
async def test_generate_knowledge_graph_integrated():
    """Test generate_knowledge_graph with actual LightRAG backend."""
    # First convert a document
    processor = get_processor()
    docling_result = await processor.convert_document(
        source="file:///opt/docling-mcp/test-data/sample.pdf"
    )

    # Generate knowledge graph
    import json
    kg_result = await mcp.call_tool(
        "generate_knowledge_graph",
        {
            "docling_document": json.dumps(docling_result),
            "llm_model": "gemma3:27b",
            "confidence_threshold": 0.5
        }
    )

    # Verify knowledge graph generated (not placeholder)
    assert kg_result["entity_count"] > 0  # Should have extracted entities
    assert kg_result["relationship_count"] >= 0
    assert "entity_collection_id" in kg_result  # Qdrant collection ID present

EOF

chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/tests/test_pipeline_integration.py
chmod 644 /opt/docling-mcp/application/tests/test_pipeline_integration.py
```

## Deliverables

- Pipeline processor: `/opt/docling-mcp/application/docling_mcp/pipeline/processor.py`
- Integrated conversion tools: `/opt/docling-mcp/application/docling_mcp/tools/conversion_integrated.py`
- Integrated knowledge graph tools: `/opt/docling-mcp/application/docling_mcp/tools/generation_kg_integrated.py`
- Server backend initialization (added to server.py)
- Integration tests: `/opt/docling-mcp/application/tests/test_pipeline_integration.py`

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Pipeline processor imports
python -c "from docling_mcp.pipeline.processor import DocumentProcessor, get_processor" && echo "PASS: Pipeline processor imports"

# 2. Backend initialization succeeds
python <<'PYEOF'
from docling_mcp.server import initialize_backends
initialize_backends()
print("PASS: All backends initialized")
PYEOF

# 3. Run integration tests
pytest tests/test_pipeline_integration.py -v

# Expected: All integration tests pass with actual backend results (not placeholders)

# 4. Verify convert_document returns actual DoclingDocument
python -c "
import asyncio
from docling_mcp.server import mcp
result = asyncio.run(mcp.call_tool('convert_document', {'document_source': 'file:///opt/docling-mcp/test-data/sample.pdf'}))
assert result['metadata']['backend_used'] != 'placeholder'
print('PASS: convert_document integrated with actual backend')
"

# 5. Verify generate_knowledge_graph extracts entities
python -c "
import asyncio
from docling_mcp.pipeline.processor import get_processor
processor = get_processor()
# ... test knowledge graph generation with actual LightRAG
print('PASS: Knowledge graph generation integrated')
"
```

### Expected Output

All verification checks should output "PASS" with actual backend results.

## Rollback

If pipeline integration fails:

```bash
# 1. Revert to placeholder implementations
# (Restore original conversion.py and generation_kg.py files)

# 2. Remove pipeline processor
rm -f /opt/docling-mcp/application/docling_mcp/pipeline/processor.py

# 3. Remove backend initialization from server.py

# 4. Document failure reason
echo "Pipeline integration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **CRITICAL PATH TASK**: This task replaces ALL placeholder implementations with actual backends
- **Dependencies**: Requires Tasks 020, 025, 026, 027, 028 complete (all backend integrations)
- **Testing Priority**: Integration tests MUST pass before operational promotion
- **Performance**: Caching via Redis critical for repeated document conversions

## References

- **Specification**: Section 4.2 "MCP Tools Specification" - Complete tool implementations
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 211-224: Pipeline integration documentation)
- **Dependencies**: Task 020 (Docling Integration), Task 025 (Entity Deduplication), Task 026 (LiteLLM), Tasks 027-028 (Qdrant, Redis)
