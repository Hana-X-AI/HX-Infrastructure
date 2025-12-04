# Task: Register MCP Generation Tools (11 Tools)

**Task ID**: hx-docling-mcp-task-035-register-generation-tools
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**:
- hx-docling-mcp-task-032 (FastMCP server initialization)
- hx-docling-mcp-task-081-100 (LightRAG integration - coordinate with andy-taylor)
- hx-docling-mcp-task-121-130 (LiteLLM integration - coordinate with shane-black)
- hx-docling-mcp-task-101-120 (Qdrant integration - coordinate with mitch-harper)
**Estimated Time**: 3 hours
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Register 11 generation tools in the FastMCP server for knowledge graph generation and document processing:

**Knowledge Graph Generation Tools** (4 tools):
4. **generate_knowledge_graph**: LightRAG-powered entity/relationship extraction with Qdrant storage
5. **extract_entities**: Named entity recognition via LLM with confidence scoring
6. **extract_relationships**: Relationship extraction with bidirectional handling
7. **create_docling_document**: Programmatic DoclingDocument creation from raw text/JSON

**Document Processing Tools** (7 tools):
8. **parse_pdf_structure**: PDF-specific structure analysis (pages, sections, TOC, metadata)
9. **extract_tables**: Table detection and cell-level extraction with format conversion
10. **extract_images**: Image extraction with base64 encoding and metadata preservation
11. **detect_document_language**: Multi-language detection via langdetect with confidence scores
12. **classify_document_type**: LLM-based document classification (report, article, contract, invoice)
13. **extract_metadata**: Metadata extraction (author, title, creation date, keywords)
14. **generate_document_summary**: LLM-powered abstractive summarization with configurable length

These tools extend conversion capabilities with advanced AI-powered document understanding.

---

## Pre-Execution Validation

**CRITICAL**: Check if generation tools already registered BEFORE creating tool handlers.

```bash
# Validation Step 1: Check if generation tools module exists
if [ ! -f /opt/docling-mcp/src/tools/generation.py ]; then
    echo "❌ VALIDATION: generation.py does not exist - PROCEED with task"
    exit 1
fi

echo "✅ Generation tools module exists: /opt/docling-mcp/src/tools/generation.py"

# Validation Step 2: Verify mcp_server.py imports the generation module
if ! grep -q "from tools\.generation import\|from tools import generation\|import tools\.generation" /opt/docling-mcp/src/mcp_server.py 2>/dev/null; then
    echo "❌ VALIDATION: generation module not imported in mcp_server.py - PROCEED with task"
    exit 1
fi

echo "✅ Generation module imported in mcp_server.py"

# Validation Step 3: Count top-level function definitions in generation.py
# Count functions at column 0 (^def ) to avoid counting nested functions
FUNCTION_COUNT=$(grep -c "^def " /opt/docling-mcp/src/tools/generation.py 2>/dev/null || echo "0")

if [ "$FUNCTION_COUNT" -ge "11" ]; then
    echo "✅ VALIDATION: Generation tools already registered ($FUNCTION_COUNT functions found, >= 11 required)"
    echo "✅ ALL VALIDATION CHECKS PASSED - SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION: Insufficient functions in generation.py ($FUNCTION_COUNT found, 11 required) - PROCEED with task"
    exit 1
fi
```

**Validation Logic**:

1. **Module Existence**: Verify `/opt/docling-mcp/src/tools/generation.py` exists
2. **Import Check**: Verify `mcp_server.py` imports the generation module (checks for various import patterns)
3. **Function Count**: Count top-level function definitions (`^def `) and confirm >= 11 functions exist
4. **Exit Codes**:
   - Exit 0 (success) if all validations pass → SKIP task execution
   - Exit 1 (failure) if any validation fails → PROCEED with task

**Note**: This validation checks for function definitions, not `@mcp.tool()` decorators, because tool registration happens in `mcp_server.py`, not in the generation module itself.

---

## Prerequisites

- [ ] FastMCP server initialized (Task 032)
- [ ] Conversion tools registered (Task 034)
- [ ] LightRAG integration ready (coordinate with andy-taylor, Tasks 081-100)
- [ ] LiteLLM integration ready (coordinate with shane-black, Tasks 121-130)
- [ ] Qdrant integration ready (coordinate with mitch-harper, Tasks 101-120)
- [ ] Directory `/opt/docling-mcp/src/tools/` exists

---

## Steps

### 1. Create Generation Tools Module Skeleton

```bash
# Switch to service account
sudo -u docling-mcp bash

# Create generation tools module with 11 tool function stubs
cat > /opt/docling-mcp/src/tools/generation.py <<'EOF'
"""
MCP Generation Tools

This module implements 11 MCP tools for knowledge graph generation and document processing:

Knowledge Graph Tools (4):
1. generate_knowledge_graph: Entity/relationship extraction via LightRAG + Qdrant storage
2. extract_entities: Named entity recognition with confidence scoring
3. extract_relationships: Relationship extraction with bidirectional linking
4. create_docling_document: Programmatic DoclingDocument creation

Document Processing Tools (7):
5. parse_pdf_structure: PDF structure analysis (pages, sections, TOC)
6. extract_tables: Table detection and extraction
7. extract_images: Image extraction with base64 encoding
8. detect_document_language: Language detection
9. classify_document_type: Document classification (report, article, contract, etc.)
10. extract_metadata: Metadata extraction
11. generate_document_summary: LLM-powered summarization

Integration Points:
- hx-literag-server.hx.dev.local:8000 (LightRAG entity/relationship extraction)
- hx-litellm-server.hx.dev.local:4000 (LLM routing for classification, summarization)
- hx-qdrant-server.hx.dev.local:6333 (Vector storage for knowledge graphs)
- hx-redis-server.hx.dev.local:6379 (Caching)

Specification Reference:
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md
Section: MCP Tools Specification → PART 2: Generation Tools
"""

import logging
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)

# ============================================================================
# Knowledge Graph Generation Tools (4 tools)
# ============================================================================

def generate_knowledge_graph(
    document_source: str,
    entity_types: Optional[List[str]] = None,
    extract_relationships: bool = True,
    confidence_threshold: float = 0.7,
    store_in_qdrant: bool = True,
    deduplicate_entities: bool = True
) -> Dict[str, Any]:
    """
    Extract entities and relationships from document using LightRAG, store in Qdrant.

    Coordinates:
    - andy-taylor (Tasks 081-100): LightRAG HTTP client for entity/relationship extraction
    - mitch-harper (Tasks 101-120): Qdrant storage for knowledge graph
    - shane-black (Tasks 121-130): LiteLLM routing for entity extraction model

    Returns: {
        "entities": [...],
        "relationships": [...],
        "metadata": {
            "entity_count": 42,
            "relationship_count": 58,
            "processing_time_ms": 12000
        }
    }
    """
    logger.info(f"generate_knowledge_graph invoked: {document_source[:100]}")

    # PLACEHOLDER: Integration with LightRAG (andy-taylor, Tasks 081-100)
    # from utils.literag_client import LightRAGClient
    # literag = LightRAGClient("http://hx-literag-server.hx.dev.local:8000")
    # entities = literag.extract_entities(document_text, entity_types)
    # relationships = literag.extract_relationships(document_text, entities)

    # PLACEHOLDER: Integration with Qdrant (mitch-harper, Tasks 101-120)
    # from utils.qdrant_client import QdrantClient
    # qdrant = QdrantClient("http://hx-qdrant-server.hx.dev.local:6333")
    # qdrant.insert_entities(entities, collection="hx_docling_mcp_entities")
    # qdrant.insert_relationships(relationships, collection="hx_docling_mcp_relationships")

    return {
        "entities": [],
        "relationships": [],
        "metadata": {
            "entity_count": 0,
            "relationship_count": 0,
            "processing_time_ms": 0,
            "note": "Placeholder - LightRAG/Qdrant integration pending (Tasks 081-120)"
        }
    }


def extract_entities(
    text: str,
    entity_types: Optional[List[str]] = None,
    confidence_threshold: float = 0.7,
    language: str = "auto"
) -> Dict[str, Any]:
    """
    Named entity recognition via LLM with confidence scoring.

    Supported entity types: PERSON, ORG, LOC, DATE, PRODUCT, EVENT, CONCEPT

    Returns: {
        "entities": [
            {
                "text": "Apple Inc.",
                "type": "ORG",
                "confidence": 0.95,
                "start_char": 42,
                "end_char": 52
            }
        ]
    }
    """
    logger.info(f"extract_entities invoked: {len(text)} chars")

    # PLACEHOLDER: LightRAG entity extraction
    return {
        "entities": [],
        "metadata": {
            "entity_count": 0,
            "note": "Placeholder - LightRAG integration pending (Tasks 081-100)"
        }
    }


def extract_relationships(
    text: str,
    entities: Optional[List[Dict]] = None,
    relationship_types: Optional[List[str]] = None,
    bidirectional: bool = True
) -> Dict[str, Any]:
    """
    Extract relationships between entities with bidirectional handling.

    Supported relationship types: WORKS_AT, LOCATED_IN, PART_OF, CREATED_BY, etc.

    Returns: {
        "relationships": [
            {
                "subject": "John Doe",
                "predicate": "WORKS_AT",
                "object": "Apple Inc.",
                "confidence": 0.89
            }
        ]
    }
    """
    logger.info(f"extract_relationships invoked: {len(text)} chars")

    # PLACEHOLDER: LightRAG relationship extraction
    return {
        "relationships": [],
        "metadata": {
            "relationship_count": 0,
            "note": "Placeholder - LightRAG integration pending (Tasks 081-100)"
        }
    }


def create_docling_document(
    doc_items: List[Dict[str, Any]],
    metadata: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Programmatic DoclingDocument creation from raw text/JSON.

    Allows manual construction of DoclingDocument structure for testing or
    synthetic document generation.

    Args:
        doc_items: List of document items (headings, paragraphs, tables, etc.)
        metadata: Document metadata (title, author, creation_date)

    Returns: DoclingDocument JSON
    """
    logger.info(f"create_docling_document invoked: {len(doc_items)} items")

    return {
        "doc_items": doc_items,
        "metadata": metadata or {},
        "version": "1.0"
    }


# ============================================================================
# Document Processing Tools (7 tools)
# ============================================================================

def parse_pdf_structure(
    document_source: str,
    extract_toc: bool = True,
    extract_page_metadata: bool = True
) -> Dict[str, Any]:
    """
    PDF-specific structure analysis (pages, sections, TOC, metadata).

    Returns: {
        "pages": [
            {
                "page_number": 1,
                "width": 612,
                "height": 792,
                "text_blocks": 5,
                "images": 2
            }
        ],
        "table_of_contents": [...],
        "metadata": {...}
    }
    """
    logger.info(f"parse_pdf_structure invoked: {document_source[:100]}")

    # PLACEHOLDER: Docling PDF structure parsing
    return {
        "pages": [],
        "table_of_contents": [],
        "metadata": {
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


def extract_tables(
    document_source: str,
    output_format: str = "json",
    preserve_formatting: bool = True
) -> Dict[str, Any]:
    """
    Table detection and cell-level extraction with format conversion.

    Output formats: json, csv, markdown, html

    Returns: {
        "tables": [
            {
                "table_id": 0,
                "rows": 5,
                "cols": 3,
                "cells": [
                    {"row": 0, "col": 0, "text": "Header 1"}
                ],
                "format": "json"
            }
        ]
    }
    """
    logger.info(f"extract_tables invoked: {document_source[:100]}")

    # PLACEHOLDER: Docling table extraction
    return {
        "tables": [],
        "metadata": {
            "table_count": 0,
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


def extract_images(
    document_source: str,
    include_base64: bool = True,
    min_width: int = 100,
    min_height: int = 100
) -> Dict[str, Any]:
    """
    Image extraction with base64 encoding and metadata preservation.

    Returns: {
        "images": [
            {
                "image_id": 0,
                "page": 1,
                "width": 800,
                "height": 600,
                "format": "png",
                "base64_data": "iVBORw0KGgo..."
            }
        ]
    }
    """
    logger.info(f"extract_images invoked: {document_source[:100]}")

    # PLACEHOLDER: Docling image extraction
    return {
        "images": [],
        "metadata": {
            "image_count": 0,
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


def detect_document_language(
    text: str,
    top_n: int = 3
) -> Dict[str, Any]:
    """
    Multi-language detection via langdetect with confidence scores.

    Supports 50+ languages. Returns top N language candidates.

    Returns: {
        "languages": [
            {"code": "en", "name": "English", "confidence": 0.95},
            {"code": "es", "name": "Spanish", "confidence": 0.03}
        ]
    }
    """
    logger.info(f"detect_document_language invoked: {len(text)} chars")

    # PLACEHOLDER: langdetect integration
    return {
        "languages": [
            {"code": "en", "name": "English", "confidence": 1.0}
        ],
        "metadata": {
            "note": "Placeholder - langdetect integration pending"
        }
    }


def classify_document_type(
    document_source: str,
    classification_types: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    LLM-based document classification.

    Default types: report, article, contract, invoice, resume, letter, form, manual

    Returns: {
        "classification": {
            "type": "report",
            "confidence": 0.92,
            "secondary_types": [
                {"type": "article", "confidence": 0.06}
            ]
        }
    }
    """
    logger.info(f"classify_document_type invoked: {document_source[:100]}")

    # PLACEHOLDER: LiteLLM classification via LLM
    return {
        "classification": {
            "type": "unknown",
            "confidence": 0.0,
            "note": "Placeholder - LiteLLM integration pending (Tasks 121-130)"
        }
    }


def extract_metadata(
    document_source: str,
    extract_keywords: bool = True,
    max_keywords: int = 10
) -> Dict[str, Any]:
    """
    Metadata extraction (author, title, creation date, keywords).

    Returns: {
        "metadata": {
            "title": "Annual Report 2024",
            "author": "John Doe",
            "creation_date": "2024-01-15",
            "keywords": ["finance", "Q4", "revenue"]
        }
    }
    """
    logger.info(f"extract_metadata invoked: {document_source[:100]}")

    # PLACEHOLDER: Docling metadata extraction
    return {
        "metadata": {
            "title": "",
            "author": "",
            "creation_date": "",
            "keywords": [],
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


def generate_document_summary(
    document_source: str,
    max_length: int = 200,
    summary_type: str = "abstractive"
) -> Dict[str, Any]:
    """
    LLM-powered abstractive summarization with configurable length.

    Summary types: abstractive (LLM-generated), extractive (sentence extraction)

    Returns: {
        "summary": {
            "text": "This document discusses...",
            "word_count": 45,
            "compression_ratio": 0.05
        }
    }
    """
    logger.info(f"generate_document_summary invoked: {document_source[:100]}")

    # PLACEHOLDER: LiteLLM summarization via LLM
    return {
        "summary": {
            "text": "Summary generation pending LiteLLM integration",
            "word_count": 0,
            "compression_ratio": 0.0,
            "note": "Placeholder - LiteLLM integration pending (Tasks 121-130)"
        }
    }


# ============================================================================
# Module Exports
# ============================================================================

__all__ = [
    # Knowledge Graph Tools
    "generate_knowledge_graph",
    "extract_entities",
    "extract_relationships",
    "create_docling_document",
    # Document Processing Tools
    "parse_pdf_structure",
    "extract_tables",
    "extract_images",
    "detect_document_language",
    "classify_document_type",
    "extract_metadata",
    "generate_document_summary"
]
EOF

chmod 644 /opt/docling-mcp/src/tools/generation.py
chown docling-mcp:docling-mcp /opt/docling-mcp/src/tools/generation.py
```

### 2. Register Tools in MCP Server

Update `/opt/docling-mcp/src/mcp_server.py` to import and register generation tools:

```bash
# Create timestamped backup before modifying mcp_server.py
BACKUP_TIMESTAMP=$(date +%s)
BACKUP_FILE="/opt/docling-mcp/src/mcp_server.py.backup.${BACKUP_TIMESTAMP}"
cp /opt/docling-mcp/src/mcp_server.py "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to create backup of mcp_server.py"
    exit 1
fi
echo "✅ Created backup: $BACKUP_FILE"

# Use Python-based file modification for reliability and portability
python3 << 'PYTHON_SCRIPT'
import sys
import re

# Read the original file
mcp_server_path = "/opt/docling-mcp/src/mcp_server.py"
try:
    with open(mcp_server_path, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"❌ ERROR: Failed to read {mcp_server_path}: {e}", file=sys.stderr)
    sys.exit(1)

# Define the insertion block
insertion = '''

# ============================================================================
# Generation Tools Registration (Task 035) - 11 tools
# ============================================================================

from tools.generation import (
    # Knowledge Graph Tools (4)
    generate_knowledge_graph,
    extract_entities,
    extract_relationships,
    create_docling_document,
    # Document Processing Tools (7)
    parse_pdf_structure,
    extract_tables,
    extract_images,
    detect_document_language,
    classify_document_type,
    extract_metadata,
    generate_document_summary
)

# Register all 11 generation tools
mcp.tool()(generate_knowledge_graph)
mcp.tool()(extract_entities)
mcp.tool()(extract_relationships)
mcp.tool()(create_docling_document)
mcp.tool()(parse_pdf_structure)
mcp.tool()(extract_tables)
mcp.tool()(extract_images)
mcp.tool()(detect_document_language)
mcp.tool()(classify_document_type)
mcp.tool()(extract_metadata)
mcp.tool()(generate_document_summary)

logger.info("✅ Registered 11 generation tools (4 knowledge graph + 7 document processing)")
'''

# Find the insertion point (after conversion tools registration)
pattern = r'^logger\.info\("✅ Registered 3 conversion tools.*?"\)'
match = re.search(pattern, content, re.MULTILINE)

if not match:
    print("❌ ERROR: Could not find conversion tools registration marker", file=sys.stderr)
    print("   Expected pattern: logger.info(\"✅ Registered 3 conversion tools...\")", file=sys.stderr)
    sys.exit(1)

# Insert the new content after the matched line
insert_position = match.end()
new_content = content[:insert_position] + insertion + content[insert_position:]

# Write the modified content back
try:
    with open(mcp_server_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
except Exception as e:
    print(f"❌ ERROR: Failed to write {mcp_server_path}: {e}", file=sys.stderr)
    sys.exit(1)

print("✅ Successfully inserted generation tool registrations")
PYTHON_SCRIPT

# Check Python script exit status
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Python modification script failed"
    echo "   Restoring backup from: $BACKUP_FILE"
    cp "$BACKUP_FILE" /opt/docling-mcp/src/mcp_server.py
    exit 1
fi

# Validate Python syntax after modification
python3 -m py_compile /opt/docling-mcp/src/mcp_server.py
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Python syntax check failed for mcp_server.py after modification"
    echo "   The insertion may have created invalid Python code."
    echo "   Restoring backup from: $BACKUP_FILE"
    cp "$BACKUP_FILE" /opt/docling-mcp/src/mcp_server.py
    exit 1
fi

echo "✅ Successfully validated Python syntax"
```

### 3. Verify Tool Registration

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test tool registration
cd /opt/docling-mcp/src/
python3 -c "
import mcp_server
tools = mcp_server.mcp.list_tools()
print(f'✅ Total tools registered: {len(tools)}')

# Expected: 1 (health_check) + 3 (conversion) + 11 (generation) = 15
expected_count = 15
assert len(tools) == expected_count, f'Expected {expected_count} tools, got {len(tools)}'

# Verify generation tools present
generation_tools = [
    'generate_knowledge_graph', 'extract_entities', 'extract_relationships',
    'create_docling_document', 'parse_pdf_structure', 'extract_tables',
    'extract_images', 'detect_document_language', 'classify_document_type',
    'extract_metadata', 'generate_document_summary'
]

tool_names = [t.name for t in tools]
for tool_name in generation_tools:
    assert tool_name in tool_names, f'Tool {tool_name} not found'

print('✅ All 11 generation tools registered successfully')
print('✅ Tool inventory:')
for tool in tools:
    print(f'   - {tool.name}')
"
```

**Expected Output**:
```
✅ Total tools registered: 15
✅ All 11 generation tools registered successfully
✅ Tool inventory:
   - health_check
   - convert_document
   - convert_document_to_markdown
   - batch_convert
   - generate_knowledge_graph
   - extract_entities
   - extract_relationships
   - create_docling_document
   - parse_pdf_structure
   - extract_tables
   - extract_images
   - detect_document_language
   - classify_document_type
   - extract_metadata
   - generate_document_summary
```

### 4. Test Tool Invocation (Placeholder Mode)

**Note**: Functions must be imported directly from the `tools.generation` module, not from `mcp_server`, because `mcp_server.py` imports but does not re-export these functions.

```bash
# Test knowledge graph generation
python3 -c "
import json
from tools.generation import generate_knowledge_graph

result = generate_knowledge_graph('file:///tmp/test.pdf')
print('generate_knowledge_graph result:')
print(json.dumps(result, indent=2))
"

# Test entity extraction
python3 -c "
import json
from tools.generation import extract_entities

result = extract_entities('Apple Inc. is headquartered in Cupertino.')
print('extract_entities result:')
print(json.dumps(result, indent=2))
"

# Test document summarization
python3 -c "
import json
from tools.generation import generate_document_summary

result = generate_document_summary('file:///tmp/test.pdf')
print('generate_document_summary result:')
print(json.dumps(result, indent=2))
"
```

---

## Verification

**Success Criteria**:

- [ ] File `/opt/docling-mcp/src/tools/generation.py` created with all 11 tool functions
- [ ] Tools imported and registered in `mcp_server.py`
- [ ] Total tool count = 15 (1 health_check + 3 conversion + 11 generation)
- [ ] All 11 generation tools respond with placeholder data
- [ ] No import errors or syntax errors

---

## Rollback

If tool registration fails:

```bash
# Remove generation tools module
rm /opt/docling-mcp/src/tools/generation.py

# Restore mcp_server.py from timestamped backup (mcp_server.py.backup.<epoch>)
# Find most recent backup
BACKUP_FILE=$(ls -t /opt/docling-mcp/src/mcp_server.py.backup.* 2>/dev/null | head -1)

if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" /opt/docling-mcp/src/mcp_server.py
    echo "✅ Restored mcp_server.py from backup: $BACKUP_FILE"
else
    echo "❌ ERROR: No backup file found matching pattern mcp_server.py.backup.*"
    echo "Manual restoration required from version control or previous backup"
    exit 1
fi
```

---

## Notes

### Integration Dependencies

**Knowledge Graph Tools** depend on:
- **andy-taylor** (Tasks 081-100): LightRAG HTTP client for entity/relationship extraction
- **mitch-harper** (Tasks 101-120): Qdrant vector storage for knowledge graphs
- **shane-black** (Tasks 121-130): LiteLLM routing for entity extraction models

**Document Processing Tools** depend on:
- **albert-singh** (Tasks 061-080): Docling library for structure parsing, table/image extraction
- **shane-black** (Tasks 121-130): LiteLLM for classification and summarization

### Placeholder Strategy

All 11 tools return placeholder responses until integration tasks complete. This enables:
- Parallel development across multiple agents
- Early MCP client testing (schema validation, tool discovery)
- Incremental integration (replace placeholders as dependencies complete)

---

## Related Tasks

**Prerequisites**: Task 032, Task 034
**Parallel Tasks**: Tasks 061-080 (albert), 081-100 (andy), 101-120 (mitch), 121-130 (shane)
**Next Task**: Task 036 (Register manipulation tools)

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Lines 5630-6500: Generation tools specifications (11 tools detailed)

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
