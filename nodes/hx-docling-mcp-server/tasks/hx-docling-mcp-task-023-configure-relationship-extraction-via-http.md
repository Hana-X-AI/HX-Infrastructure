# Task 023: Configure Relationship Extraction via hx-literag-server HTTP API

**Task ID**: hx-docling-mcp-task-023
**Task Type**: Integration
**Component**: LightRAG Knowledge Graph Engine - Relationship Extraction (HTTP Client)
**Priority**: HIGH
**Estimated Duration**: 2 hours
**Dependencies**: Task 022 (Entity Extraction via HTTP configured)
**Assigned To**: andy-taylor (LightRAG SME)

---

## Objective

Implement relationship extraction integration using hx-literag-server HTTP API. Configure relationship discovery between entities using remote service (NO local processing).

---

## Architecture

**HTTP API Integration**: All relationship extraction performed by hx-literag-server (192.168.10.220:8080)

---

## Implementation

### Create Relationship Processor

**File**: `/opt/docling-mcp/application/docling_mcp/processors/relationship_processor.py`

```python
"""Relationship Extraction Processor using hx-literag-server HTTP API."""

import structlog
from typing import List
from docling_mcp.clients.literag_client import LiteRAGClient, Relationship

logger = structlog.get_logger(__name__)


class RelationshipProcessor:
    """Process documents for relationship extraction via hx-literag-server."""

    def __init__(self, literag_client: LiteRAGClient):
        self.client = literag_client

    async def extract_relationships_from_document(self, document: str) -> List[Relationship]:
        """Extract relationships from document via HTTP API."""
        try:
            relationships = await self.client.extract_relationships(document)
            logger.info("Relationships extracted", count=len(relationships))
            return relationships
        except Exception as e:
            logger.error("Relationship extraction failed", error=str(e))
            raise
```

---

## Validation

```bash
pytest tests/test_relationship_processor.py -v
```

---

**Task Completed By**: _________________
