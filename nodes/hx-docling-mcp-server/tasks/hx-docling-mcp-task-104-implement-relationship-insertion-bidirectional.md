# Task 104: Implement Relationship Insertion with Bidirectional Linking

**Assigned To**: mitch-harper
**Estimated Effort**: 2.5 hours
**Dependencies**: Task 103 (Entity Insertion), Task 081-100 (LightRAG Integration - relationship extraction)
**Status**: Not Started

## Objective

Implement relationship insertion into `hx_docling_mcp_relationships` collection with bidirectional linking for symmetric relationships, relationship payload schema validation, and batch upsert operations.

## Pre-Execution Validation

```bash
# Check if relationship operations module exists
RELATIONSHIP_OPS_FILE="/opt/docling-mcp/src/integrations/qdrant_relationship_operations.py"

if [ -f "$RELATIONSHIP_OPS_FILE" ]; then
    echo "✅ VALIDATION RESULT: Relationship operations module exists"
    grep -q "async def upsert_relationship" "$RELATIONSHIP_OPS_FILE" && echo "✅ upsert_relationship found" || echo "❌ Missing"
    grep -q "bidirectional" "$RELATIONSHIP_OPS_FILE" && echo "✅ Bidirectional logic found" || echo "❌ Missing"
    exit 0
else
    echo "❌ VALIDATION RESULT: Module does not exist - PROCEED with implementation"
fi
```

## Context

Relationships connect entities in the knowledge graph. This task implements:

1. **Relationship Payload Schema**:
   ```python
   relationship_id: UUID
   subject_entity_id: UUID  # Source entity
   subject_entity_name: str
   predicate: str  # Relationship type (works_for, located_in, etc.)
   object_entity_id: UUID  # Target entity
   object_entity_name: str
   confidence: float  # LLM extraction confidence
   bidirectional: bool  # Symmetric relationship flag
   attributes: Dict[str, Any]
   document_id: str
   text_evidence: str  # Supporting text
   text_span: TextSpan
   extraction_model: str
   extraction_timestamp: str
   ```

2. **Bidirectional Linking**: Symmetric relationships (e.g., "works_with") stored twice:
   - Forward: A→B (subject=A, object=B)
   - Reverse: B→A (subject=B, object=A)
   - Enables efficient graph traversal in both directions

3. **Entity ID Validation**: Verify subject/object entities exist before creating relationship

4. **Vector Generation**: Relationship embedding from text: `f"{subject} {predicate} {object}"`

## Implementation Steps

### Step 1: Create Relationship Pydantic Models

```bash
sudo tee -a /opt/docling-mcp/src/models/entity_models.py > /dev/null <<'EOF'

class RelationshipPayload(BaseModel):
    """Qdrant payload schema for relationship storage."""
    relationship_id: UUID4
    subject_entity_id: UUID4
    subject_entity_name: str = Field(min_length=1, max_length=200)
    predicate: str = Field(min_length=1, max_length=100, description="Relationship type")
    object_entity_id: UUID4
    object_entity_name: str = Field(min_length=1, max_length=200)
    confidence: float = Field(ge=0.0, le=1.0)
    bidirectional: bool = Field(default=False, description="Symmetric relationship flag")
    attributes: Dict[str, Any] = Field(default_factory=dict)
    document_id: str
    text_evidence: str = Field(max_length=1000, description="Supporting text")
    text_span: TextSpan
    extraction_model: str
    extraction_timestamp: str


class RelationshipWithVector(BaseModel):
    """Relationship with embedding vector for Qdrant upsert."""
    id: UUID4
    vector: List[float] = Field(min_length=1024, max_length=1024)
    payload: RelationshipPayload
EOF

echo "✅ Added relationship models to entity_models.py"
```

### Step 2: Implement Relationship Operations

```bash
sudo tee /opt/docling-mcp/src/integrations/qdrant_relationship_operations.py > /dev/null <<'EOF'
"""Qdrant relationship storage with bidirectional linking."""

import logging
from typing import List, Dict, Any
from uuid import uuid4

from .qdrant_client import QdrantClient
from .qdrant_collections import RELATIONSHIP_COLLECTION_NAME
from .qdrant_exceptions import QdrantUpsertError
from models.entity_models import RelationshipPayload, RelationshipWithVector

logger = logging.getLogger(__name__)


async def upsert_relationship(
    client: QdrantClient,
    relationship: RelationshipWithVector,
) -> Dict[str, Any]:
    """
    Upsert relationship with optional bidirectional linking.

    If relationship.payload.bidirectional=True:
      - Insert forward relationship (subject→object)
      - Insert reverse relationship (object→subject with swapped entities)

    Returns:
        Upsert result with status, relationship_id(s)
    """
    client.require_available()

    results = []

    # Insert forward relationship
    forward_point = {
        "id": str(relationship.id),
        "vector": relationship.vector,
        "payload": relationship.payload.model_dump(),
    }

    try:
        # Upsert forward
        await client._request_with_retry(
            "PUT",
            f"/collections/{RELATIONSHIP_COLLECTION_NAME}/points",
            json={"points": [forward_point]},
        )

        results.append({
            "direction": "forward",
            "relationship_id": str(relationship.id),
            "subject": relationship.payload.subject_entity_name,
            "object": relationship.payload.object_entity_name,
        })

        logger.info(
            f"Relationship inserted: {relationship.payload.subject_entity_name} "
            f"{relationship.payload.predicate} {relationship.payload.object_entity_name}"
        )

        # If bidirectional, insert reverse
        if relationship.payload.bidirectional:
            reverse_id = uuid4()
            reverse_payload = RelationshipPayload(
                relationship_id=reverse_id,
                subject_entity_id=relationship.payload.object_entity_id,
                subject_entity_name=relationship.payload.object_entity_name,
                predicate=relationship.payload.predicate,
                object_entity_id=relationship.payload.subject_entity_id,
                object_entity_name=relationship.payload.subject_entity_name,
                confidence=relationship.payload.confidence,
                bidirectional=True,
                attributes=relationship.payload.attributes,
                document_id=relationship.payload.document_id,
                text_evidence=relationship.payload.text_evidence,
                text_span=relationship.payload.text_span,
                extraction_model=relationship.payload.extraction_model,
                extraction_timestamp=relationship.payload.extraction_timestamp,
            )

            reverse_point = {
                "id": str(reverse_id),
                "vector": relationship.vector,  # Same vector
                "payload": reverse_payload.model_dump(),
            }

            await client._request_with_retry(
                "PUT",
                f"/collections/{RELATIONSHIP_COLLECTION_NAME}/points",
                json={"points": [reverse_point]},
            )

            results.append({
                "direction": "reverse",
                "relationship_id": str(reverse_id),
                "subject": reverse_payload.subject_entity_name,
                "object": reverse_payload.object_entity_name,
            })

            logger.info(f"Bidirectional reverse relationship inserted: {reverse_id}")

        return {
            "status": "created",
            "relationships": results,
            "count": len(results),
        }

    except Exception as e:
        logger.error(f"Relationship upsert failed: {e}")
        raise QdrantUpsertError(f"Relationship upsert failed: {e}") from e


async def batch_upsert_relationships(
    client: QdrantClient,
    relationships: List[RelationshipWithVector],
) -> Dict[str, Any]:
    """Batch upsert relationships with bidirectional linking."""
    client.require_available()

    total_inserted = 0

    for rel in relationships:
        result = await upsert_relationship(client, rel)
        total_inserted += result["count"]

    logger.info(f"Batch relationship upsert complete: {total_inserted} relationships")

    return {
        "total": len(relationships),
        "relationships_inserted": total_inserted,
    }
EOF

echo "✅ Created qdrant_relationship_operations.py"
```

### Step 3: Validate and Test

```bash
# Syntax validation
/opt/docling-mcp/venv/bin/python -m py_compile /opt/docling-mcp/src/integrations/qdrant_relationship_operations.py

# Import test
/opt/docling-mcp/venv/bin/python -c "from integrations.qdrant_relationship_operations import upsert_relationship"

echo "✅ Relationship operations module validated"
```

## Validation

```bash
echo "=== Relationship Insertion Validation ==="

# Check module exists
[ -f "/opt/docling-mcp/src/integrations/qdrant_relationship_operations.py" ] && echo "✅ Module exists" || exit 1

# Check syntax
/opt/docling-mcp/venv/bin/python -m py_compile /opt/docling-mcp/src/integrations/qdrant_relationship_operations.py && echo "✅ Syntax valid" || exit 1

# Check imports
/opt/docling-mcp/venv/bin/python -c "from integrations.qdrant_relationship_operations import upsert_relationship, batch_upsert_relationships" && echo "✅ Imports successful" || exit 1

echo "✅ ALL VALIDATIONS PASSED"
echo "Next: Task 105 - Configure Payload Indexes"
```

## Notes

**Bidirectional Relationships**: Symmetric predicates (works_with, collaborates_with) stored twice for efficient traversal
**Graph Traversal**: Query by subject_entity_id to find outgoing relationships, object_entity_id for incoming
**Performance**: Batch upsert processes relationships sequentially with bidirectional expansion

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` - FR-014 (Relationship Extraction), FR-015 (Relationship Collection Schema)

## Risk Assessment

**Risk Level**: Low
**Risks**: Bidirectional duplication increases storage 2x for symmetric relationships
**Mitigation**: Documented as expected behavior, query performance benefit justifies storage cost
