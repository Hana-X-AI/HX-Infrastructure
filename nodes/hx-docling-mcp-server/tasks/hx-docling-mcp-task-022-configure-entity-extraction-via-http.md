# Task 022: Configure Entity Extraction via hx-literag-server HTTP API

**Task ID**: hx-docling-mcp-task-022
**Task Type**: Integration
**Component**: LightRAG Knowledge Graph Engine - Entity Extraction (HTTP Client)
**Priority**: HIGH
**Estimated Duration**: 2 hours
**Dependencies**: Task 021 (LiteRAG HTTP Client configured)
**Assigned To**: andy-taylor (LightRAG SME)

---

## Objective

Implement entity extraction integration using hx-literag-server HTTP API (NO local LightRAG processing). Configure document chunking, API request handling, and result processing for entity extraction via remote service.

---

## Architecture Change Context

**CRITICAL**: This task uses HTTP API client instead of local LightRAG library.

**Previous Architecture** (OBSOLETE):
- Local entity extraction with LightRAG library
- In-process LLM calls via LiteLLM
- Direct Pydantic schema validation

**New Architecture** (CURRENT):
- HTTP API calls to hx-literag-server (192.168.10.220:8080)
- Remote entity extraction processing
- Server-side validation and confidence filtering

---

## Prerequisites

**Before starting this task, verify**:

```bash
# 1. Task 021 complete (HTTP client exists)
ls -la /opt/docling-mcp/application/docling_mcp/clients/literag_client.py

# 2. hx-literag-server operational
curl -s http://192.168.10.220:8080/health
# Expected: {"status": "healthy"}

# 3. HTTP client imports successfully
source /opt/docling-mcp/venv/bin/activate
python -c "from docling_mcp.clients.literag_client import LiteRAGClient; print('OK')"
```

**All prerequisites must pass before proceeding.**

---

## Acceptance Criteria

- [ ] Entity extraction processor created at `/opt/docling-mcp/application/docling_mcp/processors/entity_processor.py`
- [ ] Document chunking configured (4096 tokens, 512 overlap)
- [ ] HTTP API integration functional (uses LiteRAGClient)
- [ ] Result processing implemented (convert API response to internal format)
- [ ] Error handling for API failures, timeouts
- [ ] Unit tests passing (minimum 5 test cases)
- [ ] Integration test with actual hx-literag-server passing
- [ ] Documentation complete

---

## Implementation Steps

### Step 1: Create Entity Processor Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/entity_processor.py`

```python
"""
Entity Extraction Processor using hx-literag-server HTTP API.

This module handles document chunking and entity extraction via
remote LightRAG service (NO local processing).
"""

import structlog
from typing import List, Dict
from docling_mcp.clients.literag_client import LiteRAGClient, Entity

logger = structlog.get_logger(__name__)


class EntityProcessor:
    """
    Process documents for entity extraction via hx-literag-server.

    Uses HTTP API client to extract entities from documents without
    local LightRAG installation.
    """

    def __init__(self, literag_client: LiteRAGClient, chunk_size: int = 4096, chunk_overlap: int = 512):
        """
        Initialize entity processor.

        Args:
            literag_client: HTTP client for hx-literag-server
            chunk_size: Maximum tokens per chunk (default: 4096)
            chunk_overlap: Overlap tokens between chunks (default: 512)
        """
        self.client = literag_client
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        logger.info("Entity processor initialized", chunk_size=chunk_size, chunk_overlap=chunk_overlap)

    def chunk_document(self, text: str) -> List[str]:
        """
        Split document into overlapping chunks.

        Args:
            text: Document text to chunk

        Returns:
            List of text chunks with configured overlap
        """
        # Simple character-based chunking (can be enhanced with tiktoken)
        chunks = []
        start = 0
        text_length = len(text)

        while start < text_length:
            end = start + self.chunk_size
            chunk = text[start:end]
            chunks.append(chunk)

            # Move start position with overlap
            start = end - self.chunk_overlap

        logger.info("Document chunked", total_chunks=len(chunks), text_length=text_length)
        return chunks

    async def extract_entities_from_document(self, document: str, document_id: str = None) -> List[Entity]:
        """
        Extract entities from entire document via hx-literag-server.

        Handles document chunking and aggregates results from all chunks.

        Args:
            document: Full document text
            document_id: Optional document identifier

        Returns:
            List of extracted entities (deduplicated across chunks)
        """
        try:
            # Chunk document
            chunks = self.chunk_document(document)

            # Extract entities from each chunk via HTTP API
            all_entities = []

            for idx, chunk in enumerate(chunks):
                logger.info("Processing chunk", chunk_index=idx, total_chunks=len(chunks))

                # Call hx-literag-server HTTP API
                entities = await self.client.extract_entities(chunk)
                all_entities.extend(entities)

                logger.debug("Chunk entities extracted", chunk_index=idx, entity_count=len(entities))

            # Deduplicate entities (by text)
            unique_entities = self._deduplicate_entities(all_entities)

            logger.info(
                "Entity extraction complete",
                document_id=document_id,
                total_entities=len(all_entities),
                unique_entities=len(unique_entities)
            )

            return unique_entities

        except Exception as e:
            logger.error("Entity extraction failed", document_id=document_id, error=str(e))
            raise

    def _deduplicate_entities(self, entities: List[Entity]) -> List[Entity]:
        """
        Remove duplicate entities by text (keep highest confidence).

        Args:
            entities: List of entities with potential duplicates

        Returns:
            Deduplicated entity list
        """
        entity_map = {}

        for entity in entities:
            key = entity.text.lower()

            if key not in entity_map or entity.confidence > entity_map[key].confidence:
                entity_map[key] = entity

        deduplicated = list(entity_map.values())

        logger.debug("Entities deduplicated", original_count=len(entities), deduplicated_count=len(deduplicated))

        return deduplicated

    async def extract_entities_from_chunk(self, text: str) -> List[Entity]:
        """
        Extract entities from single chunk via HTTP API.

        Args:
            text: Text chunk to process

        Returns:
            List of extracted entities
        """
        return await self.client.extract_entities(text)
```

### Step 2: Create Unit Tests

**File**: `/opt/docling-mcp/application/tests/test_entity_processor.py`

```python
"""Unit tests for Entity Processor."""

import pytest
from unittest.mock import AsyncMock, MagicMock
from docling_mcp.processors.entity_processor import EntityProcessor
from docling_mcp.clients.literag_client import Entity


@pytest.fixture
def mock_client():
    """Mock LiteRAG client."""
    client = MagicMock()
    client.extract_entities = AsyncMock()
    return client


@pytest.fixture
def processor(mock_client):
    """Entity processor with mocked client."""
    return EntityProcessor(literag_client=mock_client, chunk_size=100, chunk_overlap=20)


def test_chunk_document(processor):
    """Test document chunking."""
    text = "A" * 250  # 250 characters

    chunks = processor.chunk_document(text)

    # Expect 3 chunks: 0-100, 80-180, 160-250
    assert len(chunks) == 3
    assert len(chunks[0]) == 100
    assert len(chunks[1]) == 100
    assert len(chunks[2]) == 90


@pytest.mark.asyncio
async def test_extract_entities_single_chunk(processor, mock_client):
    """Test entity extraction from single chunk."""
    mock_client.extract_entities.return_value = [
        Entity(text="Python", type="TECHNOLOGY", confidence=0.95)
    ]

    entities = await processor.extract_entities_from_chunk("Python is great")

    assert len(entities) == 1
    assert entities[0].text == "Python"
    mock_client.extract_entities.assert_called_once()


@pytest.mark.asyncio
async def test_extract_entities_from_document(processor, mock_client):
    """Test entity extraction from full document with chunking."""
    # Small document that creates 2 chunks
    document = "X" * 150

    mock_client.extract_entities.return_value = [
        Entity(text="TestEntity", type="CONCEPT", confidence=0.90)
    ]

    entities = await processor.extract_entities_from_document(document)

    # Should call API twice (2 chunks)
    assert mock_client.extract_entities.call_count == 2
    assert len(entities) > 0


@pytest.mark.asyncio
async def test_deduplication(processor, mock_client):
    """Test entity deduplication."""
    # Return duplicate entities with different confidence
    mock_client.extract_entities.side_effect = [
        [Entity(text="Python", type="TECHNOLOGY", confidence=0.80)],
        [Entity(text="python", type="TECHNOLOGY", confidence=0.95)]  # Higher confidence
    ]

    document = "X" * 150  # Creates 2 chunks

    entities = await processor.extract_entities_from_document(document)

    # Should keep only highest confidence entity
    assert len(entities) == 1
    assert entities[0].confidence == 0.95


@pytest.mark.asyncio
async def test_error_handling(processor, mock_client):
    """Test error handling on API failure."""
    mock_client.extract_entities.side_effect = Exception("API Error")

    with pytest.raises(Exception, match="API Error"):
        await processor.extract_entities_from_document("test document")
```

### Step 3: Create Integration Test

**File**: `/opt/docling-mcp/application/tests/integration/test_entity_extraction_integration.py`

```python
"""Integration tests for entity extraction with real hx-literag-server."""

import pytest
from docling_mcp.clients.literag_client import LiteRAGClient
from docling_mcp.processors.entity_processor import EntityProcessor


@pytest.fixture
def real_processor():
    """Entity processor with real hx-literag-server client."""
    client = LiteRAGClient(base_url="http://192.168.10.220:8080")
    return EntityProcessor(literag_client=client)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_extract_entities_real_server(real_processor):
    """Test entity extraction with real hx-literag-server."""
    document = """
    Python is a high-level programming language.
    FastMCP is a framework for building MCP servers.
    The project is located in San Francisco.
    """

    entities = await real_processor.extract_entities_from_document(document)

    # Should extract at minimum: Python, FastMCP, San Francisco
    assert len(entities) >= 3

    entity_texts = [e.text for e in entities]
    assert any("Python" in text for text in entity_texts)
    assert any("FastMCP" in text for text in entity_texts)
```

### Step 4: Update MCP Tool Integration

Update the knowledge graph generation tool to use the entity processor:

**File**: `/opt/docling-mcp/application/docling_mcp/tools/knowledge_graph.py` (modify existing)

```python
# Add import
from docling_mcp.processors.entity_processor import EntityProcessor
from docling_mcp.clients.literag_client import LiteRAGClient

# Initialize in tool registration
literag_client = LiteRAGClient(base_url=os.getenv("LIGHTRAG_API_URL"))
entity_processor = EntityProcessor(literag_client=literag_client)

# Update generate_knowledge_graph tool
@mcp.tool()
async def generate_knowledge_graph(document: str, document_id: str = None) -> dict:
    """Generate knowledge graph from document via hx-literag-server."""
    try:
        # Extract entities via HTTP API
        entities = await entity_processor.extract_entities_from_document(document, document_id)

        return {
            "entities": [e.dict() for e in entities],
            "document_id": document_id,
            "entity_count": len(entities)
        }
    except Exception as e:
        logger.error("Knowledge graph generation failed", error=str(e))
        raise
```

### Step 5: Execute Tests

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Run unit tests
cd /opt/docling-mcp/application
pytest tests/test_entity_processor.py -v

# Run integration tests
pytest tests/integration/test_entity_extraction_integration.py -v -m integration
```

**Expected Result**: All tests PASS

---

## Validation

### Validation Commands

```bash
# 1. Verify processor file exists
ls -la /opt/docling-mcp/application/docling_mcp/processors/entity_processor.py

# 2. Verify imports work
source /opt/docling-mcp/venv/bin/activate
python -c "from docling_mcp.processors.entity_processor import EntityProcessor; print('OK')"

# 3. Test entity extraction
python -c "
import asyncio
from docling_mcp.clients.literag_client import LiteRAGClient
from docling_mcp.processors.entity_processor import EntityProcessor

async def test():
    client = LiteRAGClient('http://192.168.10.220:8080')
    processor = EntityProcessor(client)
    entities = await processor.extract_entities_from_document('Python is a programming language')
    print(f'Extracted {len(entities)} entities')
    await client.close()

asyncio.run(test())
"

# 4. Run test suite
pytest tests/test_entity_processor.py -v
```

### Success Criteria

- ✅ Processor file created with correct structure
- ✅ Document chunking functional (4096/512 configuration)
- ✅ HTTP API integration working
- ✅ Entity deduplication working
- ✅ All unit tests passing (5+ tests)
- ✅ Integration test with real server passing
- ✅ Error handling verified

---

## Documentation

**File**: `/opt/docling-mcp/documentation/entity-extraction-http.md`

```markdown
# Entity Extraction via hx-literag-server

## Architecture

**Service**: hx-literag-server (192.168.10.220:8080)
**Client**: EntityProcessor (uses LiteRAGClient)
**Processing**: Remote (NO local LightRAG)

## Configuration

- **Chunk Size**: 4096 tokens
- **Chunk Overlap**: 512 tokens (12.5%)
- **Deduplication**: By entity text (keep highest confidence)

## Usage

```python
from docling_mcp.clients.literag_client import LiteRAGClient
from docling_mcp.processors.entity_processor import EntityProcessor

# Initialize
client = LiteRAGClient("http://192.168.10.220:8080")
processor = EntityProcessor(literag_client=client)

# Extract entities
entities = await processor.extract_entities_from_document(document_text)
```

## API Flow

1. Document → Chunking (4096 tokens with 512 overlap)
2. For each chunk → HTTP POST to /api/v1/entities/extract
3. Aggregate results from all chunks
4. Deduplicate entities (keep highest confidence)
5. Return unique entity list
```

---

## Rollback Procedure

```bash
# Remove processor file
rm -f /opt/docling-mcp/application/docling_mcp/processors/entity_processor.py

# Remove test files
rm -f /opt/docling-mcp/application/tests/test_entity_processor.py
rm -f /opt/docling-mcp/application/tests/integration/test_entity_extraction_integration.py

# Remove documentation
rm -f /opt/docling-mcp/documentation/entity-extraction-http.md
```

---

## Dependencies

**Blocks**:
- Task 023: Configure Relationship Extraction (needs entity extraction working)
- Task 024: Implement Qdrant Knowledge Graph Storage (needs entities to store)

**Depends On**:
- Task 021: Configure LiteRAG HTTP Client (requires LiteRAGClient class)
- hx-literag-server operational (192.168.10.220:8080)

---

## Notes

### Architecture Change

**This task REPLACES local entity extraction with HTTP API integration.**

**OLD (OBSOLETE)**:
```python
# Local LightRAG processing
from lightrag import LightRAG
rag = LightRAG(...)
entities = rag.extract_entities(text)
```

**NEW (CURRENT)**:
```python
# HTTP API client
from docling_mcp.processors.entity_processor import EntityProcessor
entities = await processor.extract_entities_from_document(text)
```

### Benefits

1. **No local processing**: All entity extraction happens on hx-literag-server
2. **Centralized service**: Single LightRAG instance shared across clients
3. **Scalability**: Server-side scaling independent of this service
4. **Consistency**: Same entity extraction logic for all clients

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
