# Task: Implement Relationship Extraction Workflow

**Task ID**: hx-docling-mcp-task-083-implement-relationship-extraction-workflow
**Phase**: Development - Knowledge Graph Generation
**Work Stream**: 5 - Knowledge Graph Generation (LightRAG Integration)
**Status**: Not Started
**Assigned Agent**: andy-taylor (LightRAG SME)
**Dependencies**:
- hx-docling-mcp-task-081-configure-literag-http-client (HTTP client ready)
- hx-docling-mcp-task-082-implement-entity-extraction-workflow (entities available)

**Estimated Time**: 120 minutes

---

## Objective

Implement relationship extraction workflow module (`relationship_extraction.py`) that extracts entity relationships via hx-literag-server, classifies relationship types, handles bidirectional relationships, and validates entity-relationship integrity. Prepare relationships for Qdrant storage with proper graph traversal metadata.

---

## Pre-Execution Validation

**Check if work already complete BEFORE executing steps:**

```bash
# Check if relationship_extraction.py module exists
if [ -f "/opt/docling-mcp/src/relationship_extraction.py" ]; then
    echo "✅ VALIDATION: Relationship extraction module exists - checking completeness..."

    # Verify key components present
    grep -q "class RelationshipExtractor" /opt/docling-mcp/src/relationship_extraction.py && \
    grep -q "def extract_relationships" /opt/docling-mcp/src/relationship_extraction.py && \
    grep -q "def validate_relationship_integrity" /opt/docling-mcp/src/relationship_extraction.py && \
    grep -q "def handle_bidirectional" /opt/docling-mcp/src/relationship_extraction.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: Relationship extraction module complete - SKIP task execution"
        exit 0
    else
        echo "⚠️  VALIDATION: Module incomplete - PROCEED with task"
    fi
else
    echo "❌ VALIDATION: Relationship extraction module does not exist - PROCEED with task"
fi
```

**Validation Logic**:
- If `relationship_extraction.py` exists with all required methods → SKIP execution
- If module missing or incomplete → PROCEED with implementation

---

## Prerequisites

- [x] Python 3.11 virtual environment at `/opt/docling-mcp/venv/`
- [x] LightRAG HTTP client module (`literag_client.py`) created (Task 081)
- [x] Entity extraction module (`entity_extraction.py`) created (Task 082)
- [x] hx-literag-server operational at http://hx-literag-server.hx.dev.local:8000
- [x] Source directory `/opt/docling-mcp/src/` exists

---

## Implementation Steps

### Step 1: Create Relationship Extraction Module Structure

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Create relationship_extraction.py module
cat > /opt/docling-mcp/src/relationship_extraction.py << 'EOF'
"""
Relationship Extraction Workflow for hx-docling-mcp-server

Orchestrates LightRAG relationship extraction pipeline:
1. Relationship extraction via hx-literag-server HTTP API
2. Relationship type classification (Organizational, Spatial, Reference, Temporal, etc.)
3. Bidirectional relationship handling (symmetric predicates)
4. Entity-relationship integrity validation
5. Prepare relationships for Qdrant storage with graph traversal indexes

Key Features:
- Co-occurrence detection (entities mentioned in same context)
- LLM-based relationship classification
- Bidirectional linking (store A→B and B→A for symmetric relationships)
- Orphaned relationship prevention (validate subject/object entity IDs exist)
- Text evidence extraction (supporting sentence from document)

Architecture:
- Input: Document text + extracted entities
- Output: List of validated relationships (Pydantic models)
- Integration: literag_client.LiteRAGClient for HTTP API calls
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Set
from uuid import uuid4, UUID
from datetime import datetime
from pydantic import BaseModel, Field

# Import LightRAG client
from literag_client import (
    LiteRAGClient,
    RelationshipExtractionRequest,
    RelationshipExtractionResponse,
    ExtractedRelationship,
    ExtractedEntity
)

logger = logging.getLogger(__name__)

# Relationship configuration
RELATIONSHIP_CONFIDENCE_THRESHOLD = 0.7  # Minimum confidence for relationship extraction

# Bidirectional relationship types (symmetric predicates)
BIDIRECTIONAL_PREDICATES = {
    'collaborates_with',
    'partner_of',
    'similar_to',
    'related_to',
    'co_located_with',
    'contemporary_of'
}

EOF
```

### Step 2: Define Relationship Type Enums

```bash
cat >> /opt/docling-mcp/src/relationship_extraction.py << 'EOF'

# ============================================================================
# Relationship Type Taxonomy
# ============================================================================

class RelationshipCategory:
    """
    Relationship type taxonomy based on LightRAG specification.

    Categories:
    - Organizational: work relationships (works_for, leads, member_of)
    - Spatial: location relationships (located_in, near)
    - Reference: citation relationships (mentions, cites, references)
    - Temporal: time relationships (before, after, during)
    - Semantic: hierarchical relationships (part_of, instance_of, subclass_of)
    - Authorship: creator relationships (authored_by, contributed_to)
    - Custom: user-defined relationships
    """

    ORGANIZATIONAL = "organizational"
    SPATIAL = "spatial"
    REFERENCE = "reference"
    TEMPORAL = "temporal"
    SEMANTIC = "semantic"
    AUTHORSHIP = "authorship"
    CUSTOM = "custom"


# Predicate to category mapping
PREDICATE_CATEGORIES = {
    # Organizational
    'works_for': RelationshipCategory.ORGANIZATIONAL,
    'leads': RelationshipCategory.ORGANIZATIONAL,
    'member_of': RelationshipCategory.ORGANIZATIONAL,
    'employs': RelationshipCategory.ORGANIZATIONAL,
    'manages': RelationshipCategory.ORGANIZATIONAL,
    'collaborates_with': RelationshipCategory.ORGANIZATIONAL,

    # Spatial
    'located_in': RelationshipCategory.SPATIAL,
    'near': RelationshipCategory.SPATIAL,
    'contains': RelationshipCategory.SPATIAL,
    'adjacent_to': RelationshipCategory.SPATIAL,

    # Reference
    'mentions': RelationshipCategory.REFERENCE,
    'cites': RelationshipCategory.REFERENCE,
    'references': RelationshipCategory.REFERENCE,
    'quotes': RelationshipCategory.REFERENCE,

    # Temporal
    'before': RelationshipCategory.TEMPORAL,
    'after': RelationshipCategory.TEMPORAL,
    'during': RelationshipCategory.TEMPORAL,
    'contemporary_of': RelationshipCategory.TEMPORAL,

    # Semantic
    'part_of': RelationshipCategory.SEMANTIC,
    'instance_of': RelationshipCategory.SEMANTIC,
    'subclass_of': RelationshipCategory.SEMANTIC,
    'type_of': RelationshipCategory.SEMANTIC,

    # Authorship
    'authored_by': RelationshipCategory.AUTHORSHIP,
    'contributed_to': RelationshipCategory.AUTHORSHIP,
    'created_by': RelationshipCategory.AUTHORSHIP,
    'developed_by': RelationshipCategory.AUTHORSHIP,
}

EOF
```

### Step 3: Implement RelationshipExtractor Class

```bash
cat >> /opt/docling-mcp/src/relationship_extraction.py << 'EOF'

# ============================================================================
# RelationshipExtractor Class
# ============================================================================

class RelationshipExtractor:
    """
    Relationship extraction workflow orchestrator.

    Features:
    - Relationship extraction via hx-literag-server
    - Relationship type classification
    - Bidirectional relationship handling (symmetric predicates)
    - Entity-relationship integrity validation
    """

    def __init__(
        self,
        literag_client: LiteRAGClient,
        confidence_threshold: float = RELATIONSHIP_CONFIDENCE_THRESHOLD,
        model_name: str = "gemma3:27b"
    ):
        """
        Initialize relationship extractor.

        Args:
            literag_client: HTTP client for hx-literag-server
            confidence_threshold: Minimum extraction confidence (0.0-1.0)
            model_name: LLM model for extraction (gemma3:27b, qwen3-coder:30b)
        """
        self.client = literag_client
        self.confidence_threshold = confidence_threshold
        self.model_name = model_name

        logger.info(
            f"RelationshipExtractor initialized: model={model_name}, "
            f"threshold={confidence_threshold}"
        )


    async def extract_from_text(
        self,
        document_text: str,
        document_id: str,
        entities: List[Dict[str, Any]],
        document_source: str
    ) -> List[Dict[str, Any]]:
        """
        Extract relationships from document text.

        Workflow:
        1. Convert entity dicts to ExtractedEntity models (for API request)
        2. Call hx-literag-server /extract_relationships endpoint
        3. Validate entity-relationship integrity (subject/object IDs exist)
        4. Handle bidirectional relationships (create inverse relationships)
        5. Classify relationship types
        6. Prepare for Qdrant storage

        Args:
            document_text: Document content for relationship extraction
            document_id: Unique document identifier
            entities: List of extracted entities (from Task 082)
            document_source: Document file path or URL

        Returns:
            List of validated relationship dictionaries (ready for Qdrant)

        Example:
            relationships = await extractor.extract_from_text(
                document_text="IBM Research announced LightRAG framework...",
                document_id="doc_abc123",
                entities=extracted_entities,
                document_source="file:///opt/docs/paper.pdf"
            )
            print(f"Extracted {len(relationships)} relationships")
        """
        if not entities:
            logger.warning(f"No entities provided for relationship extraction: document_id={document_id}")
            return []

        logger.info(f"Starting relationship extraction: document_id={document_id}, entities={len(entities)}")

        # Step 1: Convert entity dicts to ExtractedEntity models
        entity_models = []
        for entity in entities:
            try:
                entity_model = ExtractedEntity(
                    entity_name=entity['entity_name'],
                    entity_type=entity['entity_type'],
                    aliases=entity.get('aliases', []),
                    confidence=entity['confidence'],
                    text_span_start=entity['text_span_start'],
                    text_span_end=entity['text_span_end'],
                    context_snippet=entity.get('context_snippet', ''),
                    attributes=entity.get('attributes', {})
                )
                entity_models.append(entity_model)
            except Exception as e:
                logger.error(f"Failed to convert entity to model: {entity.get('entity_name', 'unknown')} - {str(e)[:100]}")
                continue

        # Step 2: Call hx-literag-server for relationship extraction
        try:
            response = await self.client.extract_relationships(
                document_text=document_text,
                document_id=document_id,
                entities=entity_models,
                confidence_threshold=self.confidence_threshold,
                model_name=self.model_name
            )
        except Exception as e:
            logger.error(f"Relationship extraction API call failed: {str(e)[:200]}")
            return []

        logger.info(f"Extracted {len(response.relationships)} raw relationships")

        # Step 3: Convert to dictionary format and add metadata
        relationships = []
        for rel in response.relationships:
            rel_dict = rel.model_dump()
            rel_dict['relationship_id'] = str(uuid4())
            rel_dict['document_id'] = document_id
            rel_dict['extraction_model'] = response.extraction_model
            rel_dict['extraction_timestamp'] = datetime.utcnow().isoformat() + 'Z'

            # Map entities to their IDs
            subject_entity = self._find_entity_by_name(entities, rel.subject_entity_name)
            object_entity = self._find_entity_by_name(entities, rel.object_entity_name)

            if subject_entity and object_entity:
                rel_dict['subject_entity_id'] = subject_entity['entity_id']
                rel_dict['object_entity_id'] = object_entity['entity_id']
                relationships.append(rel_dict)
            else:
                # Log orphaned relationship (entity not found)
                logger.warning(
                    f"Orphaned relationship: {rel.subject_entity_name} → {rel.predicate} → {rel.object_entity_name} "
                    f"(entity not found in extracted entities)"
                )

        # Step 4: Handle bidirectional relationships
        relationships = self.handle_bidirectional_relationships(relationships)

        # Step 5: Validate integrity
        validated_relationships = self.validate_relationship_integrity(
            relationships=relationships,
            entities=entities
        )

        logger.info(f"Relationship extraction complete: {len(validated_relationships)} validated relationships")
        return validated_relationships


    def _find_entity_by_name(
        self,
        entities: List[Dict[str, Any]],
        entity_name: str
    ) -> Optional[Dict[str, Any]]:
        """
        Find entity by name (exact match or alias match).

        Args:
            entities: List of entity dictionaries
            entity_name: Entity name to find

        Returns:
            Entity dictionary if found, None otherwise
        """
        for entity in entities:
            # Check exact name match
            if entity['entity_name'] == entity_name:
                return entity

            # Check alias match
            if entity_name in entity.get('aliases', []):
                return entity

        return None

EOF
```

### Step 4: Implement Bidirectional Relationship Handling

```bash
cat >> /opt/docling-mcp/src/relationship_extraction.py << 'EOF'

    def handle_bidirectional_relationships(
        self,
        relationships: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Create inverse relationships for bidirectional predicates.

        For symmetric relationships (collaborates_with, partner_of, etc.),
        store both A→B and B→A for efficient bi-directional graph traversal.

        Args:
            relationships: List of relationship dictionaries

        Returns:
            List with bidirectional relationships added

        Example:
            Input: [{"subject": "Alice", "predicate": "collaborates_with", "object": "Bob"}]
            Output: [
                {"subject": "Alice", "predicate": "collaborates_with", "object": "Bob"},
                {"subject": "Bob", "predicate": "collaborates_with", "object": "Alice"}
            ]
        """
        bidirectional_relationships = []

        for rel in relationships:
            # Add original relationship
            bidirectional_relationships.append(rel)

            # Check if predicate is bidirectional
            predicate = rel['predicate']
            if predicate in BIDIRECTIONAL_PREDICATES or rel.get('bidirectional', False):
                # Create inverse relationship (swap subject and object)
                inverse_rel = rel.copy()
                inverse_rel['relationship_id'] = str(uuid4())  # New UUID for inverse

                # Swap subject and object
                inverse_rel['subject_entity_id'] = rel['object_entity_id']
                inverse_rel['subject_entity_name'] = rel['object_entity_name']
                inverse_rel['object_entity_id'] = rel['subject_entity_id']
                inverse_rel['object_entity_name'] = rel['subject_entity_name']

                # Mark as bidirectional
                inverse_rel['bidirectional'] = True

                bidirectional_relationships.append(inverse_rel)

                logger.debug(
                    f"Created bidirectional relationship: {rel['subject_entity_name']} ↔ "
                    f"{rel['predicate']} ↔ {rel['object_entity_name']}"
                )

        logger.info(
            f"Bidirectional handling: {len(relationships)} → {len(bidirectional_relationships)} relationships "
            f"({len(bidirectional_relationships) - len(relationships)} inverses added)"
        )

        return bidirectional_relationships

EOF
```

### Step 5: Implement Integrity Validation

```bash
cat >> /opt/docling-mcp/src/relationship_extraction.py << 'EOF'

    def validate_relationship_integrity(
        self,
        relationships: List[Dict[str, Any]],
        entities: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Validate entity-relationship integrity.

        Integrity checks:
        1. Subject entity ID exists in entity list
        2. Object entity ID exists in entity list
        3. No self-referential relationships (subject == object)
        4. No duplicate relationships (same subject, predicate, object)

        Args:
            relationships: List of relationship dictionaries
            entities: List of entity dictionaries (for validation)

        Returns:
            List of validated relationships (orphaned relationships removed)
        """
        logger.info(f"Validating {len(relationships)} relationships against {len(entities)} entities")

        # Build entity ID lookup set
        entity_ids = {entity['entity_id'] for entity in entities}

        validated_relationships = []
        orphaned_count = 0
        self_referential_count = 0
        duplicate_count = 0

        # Track unique relationships (for duplicate detection)
        seen_relationships: Set[tuple] = set()

        for rel in relationships:
            subject_id = rel.get('subject_entity_id')
            object_id = rel.get('object_entity_id')
            predicate = rel.get('predicate')

            # Check 1: Subject entity exists
            if subject_id not in entity_ids:
                logger.warning(f"Orphaned relationship (subject not found): {rel['subject_entity_name']}")
                orphaned_count += 1
                continue

            # Check 2: Object entity exists
            if object_id not in entity_ids:
                logger.warning(f"Orphaned relationship (object not found): {rel['object_entity_name']}")
                orphaned_count += 1
                continue

            # Check 3: No self-referential relationships
            if subject_id == object_id:
                logger.warning(f"Self-referential relationship removed: {rel['subject_entity_name']} → {predicate} → self")
                self_referential_count += 1
                continue

            # Check 4: No duplicate relationships
            rel_tuple = (subject_id, predicate, object_id)
            if rel_tuple in seen_relationships:
                logger.debug(f"Duplicate relationship removed: {rel['subject_entity_name']} → {predicate} → {rel['object_entity_name']}")
                duplicate_count += 1
                continue

            # Relationship is valid
            seen_relationships.add(rel_tuple)
            validated_relationships.append(rel)

        logger.info(
            f"Integrity validation complete: {len(validated_relationships)}/{len(relationships)} relationships valid "
            f"(orphaned: {orphaned_count}, self-referential: {self_referential_count}, duplicates: {duplicate_count})"
        )

        return validated_relationships


    def get_statistics(self, relationships: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Compute relationship extraction statistics.

        Args:
            relationships: List of extracted relationships

        Returns:
            Dictionary with extraction statistics

        Example:
            stats = extractor.get_statistics(relationships)
            print(f"Predicate counts: {stats['predicate_counts']}")
        """
        if not relationships:
            return {
                'total_relationships': 0,
                'predicate_counts': {},
                'category_counts': {},
                'average_confidence': 0.0,
                'bidirectional_count': 0
            }

        # Count by predicate
        predicate_counts = {}
        for rel in relationships:
            predicate = rel['predicate']
            predicate_counts[predicate] = predicate_counts.get(predicate, 0) + 1

        # Count by category
        category_counts = {}
        for rel in relationships:
            predicate = rel['predicate']
            category = PREDICATE_CATEGORIES.get(predicate, RelationshipCategory.CUSTOM)
            category_counts[category] = category_counts.get(category, 0) + 1

        # Average confidence
        avg_confidence = sum(r['confidence'] for r in relationships) / len(relationships)

        # Bidirectional count
        bidirectional_count = sum(1 for r in relationships if r.get('bidirectional', False))

        return {
            'total_relationships': len(relationships),
            'predicate_counts': predicate_counts,
            'category_counts': category_counts,
            'average_confidence': round(avg_confidence, 3),
            'bidirectional_count': bidirectional_count,
            'bidirectional_ratio': round(bidirectional_count / len(relationships), 3)
        }

EOF
```

### Step 6: Set File Permissions and Ownership

```bash
# Set ownership to docling-mcp service account
chown docling-mcp:docling-mcp /opt/docling-mcp/src/relationship_extraction.py

# Read-only for owner/group
chmod 640 /opt/docling-mcp/src/relationship_extraction.py

echo "✅ Relationship extraction workflow module created and secured"
```

---

## Verification

### Automated Verification

```bash
# Verify file exists with correct permissions
ls -l /opt/docling-mcp/src/relationship_extraction.py
# Expected: -rw-r----- 1 docling-mcp docling-mcp [size] [date] relationship_extraction.py

# Verify Python syntax
source /opt/docling-mcp/venv/bin/activate
python -m py_compile /opt/docling-mcp/src/relationship_extraction.py
if [ $? -eq 0 ]; then
    echo "✅ Python syntax valid"
else
    echo "❌ Python syntax errors detected"
    exit 1
fi

# Verify module can be imported
python -c "from relationship_extraction import RelationshipExtractor, RelationshipCategory, BIDIRECTIONAL_PREDICATES; print('✅ Import successful')"

# Test bidirectional predicate set
python << 'PYEOF'
from relationship_extraction import BIDIRECTIONAL_PREDICATES

# Verify bidirectional predicates defined
assert len(BIDIRECTIONAL_PREDICATES) > 0, "No bidirectional predicates defined"
assert 'collaborates_with' in BIDIRECTIONAL_PREDICATES, "Missing collaborates_with predicate"
print(f"✅ Bidirectional predicates defined: {len(BIDIRECTIONAL_PREDICATES)} predicates")
PYEOF
```

### Manual Verification

- [ ] Module imports without errors
- [ ] `RelationshipExtractor` class instantiates successfully
- [ ] `extract_from_text()` method defined
- [ ] `handle_bidirectional_relationships()` method defined
- [ ] `validate_relationship_integrity()` method defined
- [ ] `get_statistics()` method defined
- [ ] `RelationshipCategory` taxonomy defined (7 categories)
- [ ] `PREDICATE_CATEGORIES` mapping defined
- [ ] `BIDIRECTIONAL_PREDICATES` set defined (6+ predicates)
- [ ] File ownership: docling-mcp:docling-mcp
- [ ] File permissions: 640 (rw-r-----)

---

## Rollback

If task needs to be reverted:

```bash
# Remove relationship_extraction.py module
rm -f /opt/docling-mcp/src/relationship_extraction.py

# Verify removal
if [ ! -f "/opt/docling-mcp/src/relationship_extraction.py" ]; then
    echo "✅ Relationship extraction module removed"
else
    echo "❌ Failed to remove module"
fi
```

---

## Integration Points

**Upstream Dependencies**:
- `literag_client.py` (Task 081) - HTTP client for hx-literag-server
- `entity_extraction.py` (Task 082) - Provides extracted entities
- `hx-literag-server` operational at http://hx-literag-server.hx.dev.local:8000

**Downstream Consumers**:
- `hx-docling-mcp-task-084-integrate-qdrant-storage.md` (stores relationships in Qdrant)
- MCP tool `generate_knowledge_graph` (invokes relationship extraction workflow)
- Graph traversal queries (use bidirectional relationships)

**Configuration Requirements**:
- Environment variable: `RELATIONSHIP_CONFIDENCE_THRESHOLD` (default: 0.7)
- Environment variable: `RELATIONSHIP_EXTRACTION_MODEL` (default: gemma3:27b)

---

## Notes

### Relationship Type Taxonomy

**7 Categories** (based on LightRAG specification):

1. **Organizational**: Work relationships (works_for, leads, member_of, employs, manages)
2. **Spatial**: Location relationships (located_in, near, contains, adjacent_to)
3. **Reference**: Citation relationships (mentions, cites, references, quotes)
4. **Temporal**: Time relationships (before, after, during, contemporary_of)
5. **Semantic**: Hierarchical relationships (part_of, instance_of, subclass_of, type_of)
6. **Authorship**: Creator relationships (authored_by, contributed_to, created_by)
7. **Custom**: User-defined relationships (any predicate not in taxonomy)

### Bidirectional Relationship Strategy

**Why Bidirectional Storage?**
- Efficient graph traversal in both directions (no need to query inverse relationships)
- Example: "Find all collaborators of Alice" → Direct query, no inverse lookup required
- Qdrant query: `subject_entity_id = alice_id AND predicate = collaborates_with`

**Storage Cost**:
- 2× storage for symmetric relationships (store both A→B and B→A)
- Typical bidirectional ratio: 10-20% of all relationships
- Example: 1000 relationships → 100-200 bidirectional → 1100-1200 total stored

**Symmetric Predicates** (default set):
- `collaborates_with` (Alice collaborates_with Bob ↔ Bob collaborates_with Alice)
- `partner_of` (Company A partner_of Company B ↔ Company B partner_of Company A)
- `similar_to` (Entity A similar_to Entity B ↔ Entity B similar_to Entity A)
- `related_to` (Concept A related_to Concept B ↔ Concept B related_to Concept A)
- `co_located_with` (Office A co_located_with Office B ↔ Office B co_located_with Office A)
- `contemporary_of` (Person A contemporary_of Person B ↔ Person B contemporary_of Person A)

### Integrity Validation Checks

**4 Validation Rules**:

1. **Subject Entity Exists**: Prevent orphaned relationships where subject entity not found
2. **Object Entity Exists**: Prevent orphaned relationships where object entity not found
3. **No Self-References**: Prevent "Alice works_for Alice" (invalid semantic)
4. **No Duplicates**: Prevent "Alice works_for IBM" stored twice

**Orphaned Relationship Causes**:
- Entity extraction confidence too low (entity filtered out but relationship references it)
- Entity deduplication merged entity (relationship still uses old entity name)
- Extraction error (LLM hallucinated entity not in document)

**Remediation**: Log orphaned relationships for manual review, exclude from graph storage

### Performance Expectations

- **Relationship extraction**: <30s per 100 entities (LLM inference latency)
- **Bidirectional handling**: <1s for 1000 relationships (in-memory processing)
- **Integrity validation**: <1s for 1000 relationships (hash set lookups)
- **Total overhead**: <10% of entity extraction time

### Testing Strategy

- **Unit Tests**: Test bidirectional handling, integrity validation (mock data)
- **Integration Tests**: Live hx-literag-server extraction (TC-INT-004)
- **Graph Tests**: Verify bidirectional traversal works (query both directions)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Version**: 1.0
