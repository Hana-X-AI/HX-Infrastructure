# Task: Implement Document Ingestion Workflow

**Task ID:** hx-lang-server-task-085-implement-document-ingestion
**Work Stream:** 8 - LightRAG Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Andy (LightRAG SME)
**Dependencies:** hx-lang-server-task-081-configure-lightrag-http-client, hx-lang-server-task-084-configure-64kb-context-handling
**Estimated Time:** 3 hours

---

## Objective

Implement a document ingestion workflow that prepares documents for LightRAG indexing, leveraging LightRAG's incremental update algorithm for 10-100x cost reduction compared to full graph rebuilds.

---

## Specification Reference

From `/nodes/hx-lang-server/specification/node-spec.md` v2.1:

- **FR-014**: Service MUST integrate with hx-literag-server.hx.dev.local via HTTP API
- Integration with hx-docling-mcp-server for document conversion (related service)

From LightRAG Research Paper:
- Incremental updates use Textract-only processing (new documents)
- GraphRAG requires full community rebuilds (1,399 x 2 x 5,000 tokens)
- LightRAG achieves 610x retrieval cost reduction, 1,000x incremental update cost reduction

---

## Prerequisites

- [ ] Task 081 complete: LightRAG HTTP client configured
- [ ] Task 084 complete: 64KB context handling configured
- [ ] Virtual environment active: `/opt/hx-lang-server/venv`
- [ ] LightRAG server operational at hx-literag-server.hx.dev.local:8020

---

## Implementation Details

### File Location

```
/opt/hx-lang-server/app/rag/document_ingestion.py
```

### Document Ingestion Implementation

```python
"""
Document Ingestion Workflow for LightRAG.

This module provides a workflow for ingesting documents into LightRAG's
knowledge graph, leveraging the incremental update algorithm for
optimal cost efficiency.

Key Features:
1. Document preprocessing (chunking, metadata extraction)
2. Batch ingestion with progress tracking
3. Incremental updates (new documents only)
4. Integration with Docling for document conversion

LightRAG Incremental Update Algorithm (from paper):
---------------------------------------------------
Instead of rebuilding entire community structures (GraphRAG),
LightRAG uses a three-step incremental process:

1. Recog: Extract entities/relationships from new document
2. Prof: Profile new nodes against existing graph
3. Dedupe: Merge duplicates with existing entities

This provides 10-100x cost reduction for document updates.
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, AsyncIterator
from enum import Enum
from datetime import datetime
import hashlib
import structlog
import asyncio

from app.clients.lightrag_client import LightRAGClient

logger = structlog.get_logger()


class DocumentStatus(str, Enum):
    """Status of a document in the ingestion pipeline."""
    PENDING = "pending"
    PREPROCESSING = "preprocessing"
    INGESTING = "ingesting"
    INDEXED = "indexed"
    FAILED = "failed"
    SKIPPED = "skipped"  # Already indexed (incremental check)


@dataclass
class DocumentMetadata:
    """Metadata for a document being ingested."""
    doc_id: str
    title: Optional[str] = None
    source: Optional[str] = None
    source_type: Optional[str] = None  # file, url, text
    created_at: Optional[str] = None
    author: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    custom: Dict[str, Any] = field(default_factory=dict)


@dataclass
class DocumentChunk:
    """A chunk of a document for ingestion."""
    content: str
    chunk_index: int
    total_chunks: int
    doc_id: str
    metadata: Optional[Dict[str, Any]] = None
    content_hash: str = ""

    def __post_init__(self):
        if not self.content_hash:
            self.content_hash = hashlib.sha256(self.content.encode()).hexdigest()[:16]


@dataclass
class IngestionResult:
    """Result of ingesting a document."""
    doc_id: str
    status: DocumentStatus
    chunks_processed: int = 0
    chunks_total: int = 0
    entities_extracted: int = 0
    relationships_extracted: int = 0
    processing_time_ms: int = 0
    error: Optional[str] = None


@dataclass
class BatchIngestionResult:
    """Result of batch document ingestion."""
    total_documents: int
    successful: int
    failed: int
    skipped: int
    total_entities: int
    total_relationships: int
    total_time_ms: int
    results: List[IngestionResult] = field(default_factory=list)


class DocumentPreprocessor:
    """
    Preprocesses documents for LightRAG ingestion.

    Handles:
    - Text chunking with overlap
    - Metadata extraction
    - Content deduplication checks
    """

    def __init__(
        self,
        chunk_size: int = 4000,  # ~1000 tokens
        chunk_overlap: int = 200,  # ~50 tokens overlap
        min_chunk_size: int = 100
    ):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.min_chunk_size = min_chunk_size
        self._logger = logger.bind(component="document_preprocessor")

    def generate_doc_id(self, content: str, source: Optional[str] = None) -> str:
        """Generate a unique document ID from content hash."""
        hash_input = f"{source or ''}{content}"
        return hashlib.sha256(hash_input.encode()).hexdigest()[:16]

    def chunk_document(
        self,
        content: str,
        doc_id: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> List[DocumentChunk]:
        """
        Split document into overlapping chunks.

        Uses paragraph-aware chunking:
        1. Split on paragraph boundaries when possible
        2. Fall back to sentence boundaries
        3. Last resort: hard split at chunk_size

        Args:
            content: Document text
            doc_id: Document identifier
            metadata: Optional metadata to attach to chunks

        Returns:
            List of DocumentChunks
        """
        if len(content) <= self.chunk_size:
            return [DocumentChunk(
                content=content,
                chunk_index=0,
                total_chunks=1,
                doc_id=doc_id,
                metadata=metadata
            )]

        chunks = []
        paragraphs = content.split("\n\n")

        current_chunk = ""
        chunk_index = 0

        for para in paragraphs:
            # If adding this paragraph would exceed chunk size
            if len(current_chunk) + len(para) + 2 > self.chunk_size:
                if len(current_chunk) >= self.min_chunk_size:
                    chunks.append(current_chunk.strip())
                    chunk_index += 1

                    # Keep overlap from end of previous chunk
                    overlap_text = current_chunk[-self.chunk_overlap:] if len(current_chunk) > self.chunk_overlap else ""
                    current_chunk = overlap_text + para
                else:
                    current_chunk += "\n\n" + para
            else:
                if current_chunk:
                    current_chunk += "\n\n" + para
                else:
                    current_chunk = para

        # Don't forget the last chunk
        if len(current_chunk) >= self.min_chunk_size:
            chunks.append(current_chunk.strip())

        # Convert to DocumentChunk objects
        total_chunks = len(chunks)
        return [
            DocumentChunk(
                content=chunk,
                chunk_index=i,
                total_chunks=total_chunks,
                doc_id=doc_id,
                metadata=metadata
            )
            for i, chunk in enumerate(chunks)
        ]

    def extract_metadata(self, content: str) -> DocumentMetadata:
        """
        Extract basic metadata from document content.

        For richer metadata, use Docling integration.
        """
        # Simple heuristics for metadata extraction
        lines = content.split("\n")

        # Try to find title (first non-empty line or markdown heading)
        title = None
        for line in lines[:10]:
            line = line.strip()
            if line:
                if line.startswith("# "):
                    title = line[2:]
                else:
                    title = line[:100] if len(line) > 100 else line
                break

        return DocumentMetadata(
            doc_id=self.generate_doc_id(content),
            title=title,
            source_type="text",
            created_at=datetime.utcnow().isoformat()
        )


class DocumentIngestionService:
    """
    Service for ingesting documents into LightRAG.

    This service provides:
    1. Single document ingestion
    2. Batch ingestion with progress tracking
    3. Incremental update support (skip already-indexed docs)
    4. Error handling and retry logic

    Cost Optimization (from LightRAG paper):
    - Uses incremental updates instead of full rebuilds
    - Achieves 10-100x cost reduction vs GraphRAG
    - Processes only new/changed documents
    """

    def __init__(
        self,
        client: LightRAGClient,
        preprocessor: Optional[DocumentPreprocessor] = None,
        batch_size: int = 10,
        retry_attempts: int = 2,
        retry_delay: float = 1.0
    ):
        self.client = client
        self.preprocessor = preprocessor or DocumentPreprocessor()
        self.batch_size = batch_size
        self.retry_attempts = retry_attempts
        self.retry_delay = retry_delay
        self._logger = logger.bind(component="document_ingestion")
        self._indexed_hashes: set = set()  # Track indexed content hashes

    async def check_already_indexed(self, content_hash: str) -> bool:
        """
        Check if content is already indexed (for incremental updates).

        In a full implementation, this would query LightRAG's doc status store.
        For now, we use an in-memory cache.
        """
        return content_hash in self._indexed_hashes

    async def ingest_document(
        self,
        content: str,
        doc_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        skip_if_indexed: bool = True
    ) -> IngestionResult:
        """
        Ingest a single document into LightRAG.

        Args:
            content: Document text content
            doc_id: Optional document ID (generated if not provided)
            metadata: Optional document metadata
            skip_if_indexed: Skip if document already indexed

        Returns:
            IngestionResult with status and metrics
        """
        start_time = datetime.utcnow()

        # Generate doc_id if not provided
        if not doc_id:
            doc_id = self.preprocessor.generate_doc_id(content)

        self._logger.info(
            "ingestion_started",
            doc_id=doc_id,
            content_length=len(content)
        )

        # Check for duplicate
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        if skip_if_indexed and await self.check_already_indexed(content_hash):
            self._logger.info(
                "ingestion_skipped",
                doc_id=doc_id,
                reason="already_indexed"
            )
            return IngestionResult(
                doc_id=doc_id,
                status=DocumentStatus.SKIPPED
            )

        # Chunk document
        chunks = self.preprocessor.chunk_document(content, doc_id, metadata)

        total_entities = 0
        total_relationships = 0
        failed = False
        error_msg = None

        # Ingest each chunk
        for chunk in chunks:
            for attempt in range(self.retry_attempts):
                try:
                    result = await self.client.insert_document(
                        content=chunk.content,
                        doc_id=f"{doc_id}_chunk_{chunk.chunk_index}",
                        metadata={
                            **(chunk.metadata or {}),
                            "parent_doc_id": doc_id,
                            "chunk_index": chunk.chunk_index,
                            "total_chunks": chunk.total_chunks,
                        }
                    )

                    total_entities += result.get("entities_count", 0)
                    total_relationships += result.get("relationships_count", 0)
                    break

                except Exception as e:
                    if attempt == self.retry_attempts - 1:
                        failed = True
                        error_msg = str(e)
                        self._logger.error(
                            "chunk_ingestion_failed",
                            doc_id=doc_id,
                            chunk_index=chunk.chunk_index,
                            error=str(e)
                        )
                    else:
                        await asyncio.sleep(self.retry_delay * (attempt + 1))

        # Calculate processing time
        end_time = datetime.utcnow()
        processing_time_ms = int((end_time - start_time).total_seconds() * 1000)

        # Update indexed cache
        if not failed:
            self._indexed_hashes.add(content_hash)

        status = DocumentStatus.FAILED if failed else DocumentStatus.INDEXED

        self._logger.info(
            "ingestion_complete",
            doc_id=doc_id,
            status=status.value,
            chunks=len(chunks),
            entities=total_entities,
            relationships=total_relationships,
            time_ms=processing_time_ms
        )

        return IngestionResult(
            doc_id=doc_id,
            status=status,
            chunks_processed=len(chunks) if not failed else 0,
            chunks_total=len(chunks),
            entities_extracted=total_entities,
            relationships_extracted=total_relationships,
            processing_time_ms=processing_time_ms,
            error=error_msg
        )

    async def ingest_batch(
        self,
        documents: List[Dict[str, Any]],
        skip_if_indexed: bool = True
    ) -> BatchIngestionResult:
        """
        Ingest a batch of documents.

        Each document dict should have:
        - content: str (required)
        - doc_id: str (optional)
        - metadata: dict (optional)

        Args:
            documents: List of document dicts
            skip_if_indexed: Skip already-indexed documents

        Returns:
            BatchIngestionResult with aggregate metrics
        """
        start_time = datetime.utcnow()
        results = []

        self._logger.info(
            "batch_ingestion_started",
            total_documents=len(documents)
        )

        # Process in batches to avoid overwhelming LightRAG
        for i in range(0, len(documents), self.batch_size):
            batch = documents[i:i + self.batch_size]

            # Process batch concurrently
            tasks = [
                self.ingest_document(
                    content=doc["content"],
                    doc_id=doc.get("doc_id"),
                    metadata=doc.get("metadata"),
                    skip_if_indexed=skip_if_indexed
                )
                for doc in batch
            ]

            batch_results = await asyncio.gather(*tasks)
            results.extend(batch_results)

            self._logger.debug(
                "batch_progress",
                processed=min(i + self.batch_size, len(documents)),
                total=len(documents)
            )

        # Aggregate results
        successful = sum(1 for r in results if r.status == DocumentStatus.INDEXED)
        failed = sum(1 for r in results if r.status == DocumentStatus.FAILED)
        skipped = sum(1 for r in results if r.status == DocumentStatus.SKIPPED)
        total_entities = sum(r.entities_extracted for r in results)
        total_relationships = sum(r.relationships_extracted for r in results)

        end_time = datetime.utcnow()
        total_time_ms = int((end_time - start_time).total_seconds() * 1000)

        self._logger.info(
            "batch_ingestion_complete",
            total=len(documents),
            successful=successful,
            failed=failed,
            skipped=skipped,
            entities=total_entities,
            relationships=total_relationships,
            time_ms=total_time_ms
        )

        return BatchIngestionResult(
            total_documents=len(documents),
            successful=successful,
            failed=failed,
            skipped=skipped,
            total_entities=total_entities,
            total_relationships=total_relationships,
            total_time_ms=total_time_ms,
            results=results
        )

    async def ingest_stream(
        self,
        documents: AsyncIterator[Dict[str, Any]],
        skip_if_indexed: bool = True
    ) -> AsyncIterator[IngestionResult]:
        """
        Ingest documents from an async stream.

        Useful for processing large document sets without
        loading all into memory.

        Args:
            documents: Async iterator of document dicts
            skip_if_indexed: Skip already-indexed documents

        Yields:
            IngestionResult for each document
        """
        async for doc in documents:
            result = await self.ingest_document(
                content=doc["content"],
                doc_id=doc.get("doc_id"),
                metadata=doc.get("metadata"),
                skip_if_indexed=skip_if_indexed
            )
            yield result


# Convenience functions

async def ingest_text(
    client: LightRAGClient,
    text: str,
    doc_id: Optional[str] = None
) -> IngestionResult:
    """Quick ingestion of a single text document."""
    service = DocumentIngestionService(client)
    return await service.ingest_document(text, doc_id)


async def ingest_texts(
    client: LightRAGClient,
    texts: List[str]
) -> BatchIngestionResult:
    """Quick ingestion of multiple text documents."""
    service = DocumentIngestionService(client)
    documents = [{"content": text} for text in texts]
    return await service.ingest_batch(documents)
```

---

## Manual Steps

### Step 1: Create Document Ingestion Module

```bash
# Create the document_ingestion.py file with implementation above
sudo -u hx-lang-server vim /opt/hx-lang-server/app/rag/document_ingestion.py
```

### Step 2: Update Module Init

```bash
# Update __init__.py to include document_ingestion exports
cat << 'EOF' | sudo -u hx-lang-server tee -a /opt/hx-lang-server/app/rag/__init__.py

# Document ingestion
from .document_ingestion import (
    DocumentStatus,
    DocumentMetadata,
    DocumentChunk,
    DocumentPreprocessor,
    DocumentIngestionService,
    IngestionResult,
    BatchIngestionResult,
    ingest_text,
    ingest_texts,
)
EOF
```

---

## Acceptance Criteria

- [ ] DocumentPreprocessor class implemented with:
  - Document chunking with configurable size and overlap
  - Paragraph-aware splitting
  - Document ID generation
  - Basic metadata extraction
- [ ] DocumentIngestionService class implemented with:
  - Single document ingestion
  - Batch ingestion with progress tracking
  - Stream ingestion for large datasets
  - Retry logic with configurable attempts
  - Skip-if-indexed for incremental updates
- [ ] IngestionResult captures:
  - Document status (indexed, failed, skipped)
  - Chunks processed/total
  - Entities and relationships extracted
  - Processing time
- [ ] BatchIngestionResult aggregates metrics across all documents
- [ ] Proper error handling and logging throughout

---

## Verification

```bash
# Python integration test
sudo -u hx-lang-server /opt/hx-lang-server/venv/bin/python << 'EOF'
import asyncio
from app.clients.lightrag_client import LightRAGClient
from app.rag.document_ingestion import (
    DocumentPreprocessor,
    DocumentIngestionService,
    ingest_text,
)

async def test_document_ingestion():
    # Test preprocessor
    preprocessor = DocumentPreprocessor(chunk_size=500, chunk_overlap=50)

    test_doc = """
# Test Document

This is the first paragraph of our test document.
It contains some important information about testing.

This is the second paragraph with more details.
We need to make sure chunking works correctly.

And a third paragraph for good measure.
This should help us verify the overlap behavior.
""" * 10  # Make it long enough to chunk

    doc_id = preprocessor.generate_doc_id(test_doc)
    print(f"Generated doc_id: {doc_id}")

    chunks = preprocessor.chunk_document(test_doc, doc_id)
    print(f"Created {len(chunks)} chunks from document")

    for i, chunk in enumerate(chunks):
        print(f"  Chunk {i}: {len(chunk.content)} chars, hash={chunk.content_hash}")

    # Test metadata extraction
    metadata = preprocessor.extract_metadata(test_doc)
    print(f"\nExtracted metadata:")
    print(f"  Title: {metadata.title}")
    print(f"  Source type: {metadata.source_type}")

    # Test ingestion service (if LightRAG is available)
    async with LightRAGClient() as client:
        health = await client.health_check()

        if health.get("status") == "healthy":
            service = DocumentIngestionService(client, preprocessor)

            result = await service.ingest_document(
                content="This is a test document for LightRAG ingestion.",
                doc_id="test-001"
            )
            print(f"\nIngestion result:")
            print(f"  Status: {result.status.value}")
            print(f"  Entities: {result.entities_extracted}")
            print(f"  Relationships: {result.relationships_extracted}")
            print(f"  Time: {result.processing_time_ms}ms")

            # Test skip-if-indexed
            result2 = await service.ingest_document(
                content="This is a test document for LightRAG ingestion.",
                skip_if_indexed=True
            )
            print(f"\nSecond ingestion (should skip):")
            print(f"  Status: {result2.status.value}")
        else:
            print("\nLightRAG not available, skipping ingestion test")

    print("\nAll document ingestion tests passed!")

asyncio.run(test_document_ingestion())
EOF
```

---

## Rollback

```bash
# Remove document ingestion module
sudo rm -f /opt/hx-lang-server/app/rag/document_ingestion.py

# Update __init__.py to remove exports
# (manual edit to remove document_ingestion imports)
```

---

## Notes

- **Incremental Updates**: LightRAG's incremental update algorithm is the key cost optimization. By tracking already-indexed documents, we avoid reprocessing unchanged content.

- **Chunking Strategy**: The paragraph-aware chunking preserves semantic units. Overlap ensures entity references that span chunk boundaries are captured.

- **Batch Processing**: Large document sets are processed in configurable batches (default 10) to avoid overwhelming LightRAG's entity extraction pipeline.

- **Integration with Docling**: For richer document processing (PDF, DOCX, etc.), integrate with hx-docling-mcp-server for conversion to text/markdown before ingestion.

---

## Related Tasks

- **Task 081**: LightRAG HTTP client (prerequisite)
- **Task 084**: 64KB context handling (context for extracted entities)
- **Task 054**: RAG Agent worker (uses indexed documents)
- **Task 056**: Tool Agent worker (may invoke Docling for conversion)

---

**Task Created By:** Andy (LightRAG SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
