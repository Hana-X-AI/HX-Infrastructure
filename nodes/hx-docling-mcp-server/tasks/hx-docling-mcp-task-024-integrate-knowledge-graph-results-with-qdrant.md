# Task 024: Integrate Knowledge Graph Results with Qdrant Storage

**Task ID**: hx-docling-mcp-task-024
**Task Type**: Integration
**Component**: Qdrant Vector Storage for Knowledge Graph
**Priority**: HIGH
**Estimated Duration**: 2 hours
**Dependencies**: Task 022 (Entity Extraction), Task 023 (Relationship Extraction)
**Assigned To**: mitch-roberts (Qdrant SME)

---

## Objective

Store extracted entities and relationships from hx-literag-server in Qdrant collections (`hx_docling_mcp_entities`, `hx_docling_mcp_relationships`) for knowledge graph persistence.

---

## Architecture

**Data Flow**: hx-literag-server (extraction) → Local processing → Qdrant (192.168.10.207:6333) storage

---

## Implementation

### Create Qdrant Storage Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/kg_storage.py`

```python
"""Knowledge Graph Storage in Qdrant."""

import structlog
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import uuid
from typing import List
from docling_mcp.clients.literag_client import Entity, Relationship

logger = structlog.get_logger(__name__)


class KnowledgeGraphStorage:
    """Store knowledge graph data in Qdrant."""

    def __init__(self, qdrant_host: str, qdrant_port: int):
        self.client = QdrantClient(host=qdrant_host, port=qdrant_port)
        self.entity_collection = "hx_docling_mcp_entities"
        self.relationship_collection = "hx_docling_mcp_relationships"

    async def store_entities(self, entities: List[Entity], document_id: str):
        """Store entities in Qdrant."""
        points = [
            PointStruct(
                id=str(uuid.uuid4()),
                vector=[0.0] * 1024,  # Placeholder - actual embeddings from hx-literag-server
                payload={
                    "text": entity.text,
                    "type": entity.type,
                    "confidence": entity.confidence,
                    "document_id": document_id,
                    "metadata": entity.metadata
                }
            )
            for entity in entities
        ]

        self.client.upsert(collection_name=self.entity_collection, points=points)
        logger.info("Entities stored in Qdrant", count=len(entities), document_id=document_id)

    async def store_relationships(self, relationships: List[Relationship], document_id: str):
        """Store relationships in Qdrant."""
        points = [
            PointStruct(
                id=str(uuid.uuid4()),
                vector=[0.0] * 1024,  # Placeholder
                payload={
                    "source": rel.source,
                    "target": rel.target,
                    "type": rel.type,
                    "confidence": rel.confidence,
                    "document_id": document_id,
                    "metadata": rel.metadata
                }
            )
            for rel in relationships
        ]

        self.client.upsert(collection_name=self.relationship_collection, points=points)
        logger.info("Relationships stored in Qdrant", count=len(relationships), document_id=document_id)
```

---

## Validation

```bash
pytest tests/test_kg_storage.py -v
```

---

**Task Completed By**: _________________
