# Task: MCP Tool Schema Validation

**Task ID**: hx-docling-mcp-task-030
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-009-012 (All 19 tools registered), hx-docling-mcp-task-026 (LiteLLM Integration)
**Parallel Execution**: No (requires all tools registered)

## Objective

Implement comprehensive MCP protocol schema validation for all 19 registered tools to ensure compliance with MCP specification, proper Pydantic model definitions, and JSON Schema generation.

## Prerequisites

- FastMCP framework installed (Task 001 complete)
- All 19 MCP tools registered (Tasks 009-012 complete)
- Server running with all tools available

## Environment Variables

**IMPORTANT**: The following environment variables must be set before executing this task. These ensure proper file ownership across different deployment environments.

```bash
# Set deployment-specific user and group
# HX-Infrastructure default values:
export DOCLING_USER="docling-mcp"
export DOCLING_GROUP="domain users"

# Alternative for non-AD environments:
# export DOCLING_USER="docling-mcp"
# export DOCLING_GROUP="docling-mcp"

# Verify variables are set
if [ -z "$DOCLING_USER" ] || [ -z "$DOCLING_GROUP" ]; then
    echo "ERROR: DOCLING_USER and DOCLING_GROUP must be set"
    echo "Example: export DOCLING_USER=docling-mcp DOCLING_GROUP='domain users'"
    exit 1
fi

echo "Using ownership: $DOCLING_USER:$DOCLING_GROUP"
```

**Notes**:
- HX-Infrastructure uses Samba AD with `domain users` group
- Non-AD environments should use local user/group (e.g., `docling-mcp:docling-mcp`)
- CI/automation scripts must provide these variables or use fallbacks
- Group names with spaces must be quoted in shell commands

## Steps

### 1. Create Schema Validation Module

```bash
# Create schema validation utilities
cat > /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py <<'EOF'
"""
MCP Tool Schema Validation Utilities.

Validates all MCP tools against protocol specification:
- Pydantic model compliance
- JSON Schema generation
- Required parameter validation
- Field description completeness
- Error handling compliance
"""

import logging
from typing import List, Dict, Any
from pydantic import BaseModel
import inspect

logger = logging.getLogger(__name__)

class SchemaValidationResult(BaseModel):
    """Schema validation result for single tool."""
    tool_name: str
    valid: bool
    errors: List[str] = []
    warnings: List[str] = []
    schema_generated: bool = False
    required_params_count: int = 0
    optional_params_count: int = 0

class SchemaValidator:
    """Validate MCP tool schemas for protocol compliance."""

    def __init__(self):
        self.results: List[SchemaValidationResult] = []

    def validate_tool(self, tool_name: str, tool_schema: dict) -> SchemaValidationResult:
        """
        Validate single MCP tool schema.

        Args:
            tool_name: Tool name
            tool_schema: Generated JSON Schema from MCP (via list_tools() public API)

        Returns:
            SchemaValidationResult with validation errors/warnings
        """
        result = SchemaValidationResult(tool_name=tool_name, valid=True)

        # Validate JSON Schema generated
        if "inputSchema" in tool_schema:
            result.schema_generated = True
            input_schema = tool_schema["inputSchema"]

            # Validate required vs optional parameters
            required_params = input_schema.get("required", [])
            all_params = input_schema.get("properties", {})
            result.required_params_count = len(required_params)
            result.optional_params_count = len(all_params) - len(required_params)

            # Validate all parameters have descriptions
            for param_name, param_schema in all_params.items():
                if "description" not in param_schema:
                    result.warnings.append(f"Parameter '{param_name}' missing description (LLMs rely on descriptions)")

            # Validate required parameters have descriptions
            for param_name in required_params:
                param_schema = all_params.get(param_name, {})
                if "description" not in param_schema:
                    result.errors.append(f"Required parameter '{param_name}' MUST have description")
                    result.valid = False

        else:
            result.errors.append("Tool missing inputSchema (Pydantic model not generating schema)")
            result.valid = False

        # Validate tool description exists
        if "description" not in tool_schema or not tool_schema["description"]:
            result.errors.append("Tool missing description (required for MCP protocol)")
            result.valid = False

        return result

    def validate_all_tools(self, mcp) -> List[SchemaValidationResult]:
        """
        Validate all registered MCP tools.

        Args:
            mcp: FastMCP server instance

        Returns:
            List of validation results (one per tool)
        """
        tools = mcp.list_tools()
        logger.info(f"Validating {len(tools)} MCP tools...")

        for tool_schema in tools:
            tool_name = tool_schema["name"]

            # Tool existence already validated by list_tools() public API
            # (tools returned by list_tools() are guaranteed to be registered)

            # Validate tool schema
            result = self.validate_tool(tool_name, tool_schema)
            self.results.append(result)

        return self.results

    def generate_report(self) -> str:
        """
        Generate human-readable validation report.

        Returns:
            Validation report string
        """
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("MCP TOOL SCHEMA VALIDATION REPORT")
        report_lines.append("=" * 80)

        total_tools = len(self.results)
        valid_tools = sum(1 for r in self.results if r.valid)
        invalid_tools = total_tools - valid_tools

        report_lines.append(f"\nTotal Tools: {total_tools}")
        report_lines.append(f"Valid Tools: {valid_tools}")
        report_lines.append(f"Invalid Tools: {invalid_tools}")
        report_lines.append("")

        # List invalid tools
        if invalid_tools > 0:
            report_lines.append("INVALID TOOLS:")
            for result in self.results:
                if not result.valid:
                    report_lines.append(f"\n  ✗ {result.tool_name}")
                    for error in result.errors:
                        report_lines.append(f"      ERROR: {error}")
                    for warning in result.warnings:
                        report_lines.append(f"      WARN:  {warning}")

        # List valid tools with warnings
        tools_with_warnings = [r for r in self.results if r.valid and r.warnings]
        if tools_with_warnings:
            report_lines.append("\nVALID TOOLS WITH WARNINGS:")
            for result in tools_with_warnings:
                report_lines.append(f"\n  ⚠ {result.tool_name}")
                for warning in result.warnings:
                    report_lines.append(f"      WARN: {warning}")

        # List fully valid tools
        fully_valid = [r for r in self.results if r.valid and not r.warnings]
        if fully_valid:
            report_lines.append("\nFULLY VALID TOOLS:")
            for result in fully_valid:
                report_lines.append(f"  ✓ {result.tool_name} ({result.required_params_count} required, {result.optional_params_count} optional params)")

        report_lines.append("\n" + "=" * 80)

        return "\n".join(report_lines)

    def fail_if_invalid(self):
        """
        Raise exception if any tools are invalid.

        Raises:
            RuntimeError: If invalid tools found
        """
        invalid_tools = [r for r in self.results if not r.valid]
        if invalid_tools:
            tool_names = ", ".join(r.tool_name for r in invalid_tools)
            raise RuntimeError(
                f"Schema validation failed for {len(invalid_tools)} tools: {tool_names}. "
                f"See validation report for details."
            )

EOF

# Set ownership and permissions (uses environment variables)
sudo chown "$DOCLING_USER" /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py
sudo chgrp "$DOCLING_GROUP" /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py
chmod 644 /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py

# Verify ownership
ls -l /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py
```

### 2. Add Schema Validation to Server Startup

```bash
# Update server.py to validate schemas on startup
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import schema validation
from .utils.schema_validation import SchemaValidator

def validate_schemas_on_startup(mcp):
    """
    Validate all MCP tool schemas on server startup.

    Fails fast if any tools have invalid schemas.
    """
    logger.info("Validating MCP tool schemas...")

    validator = SchemaValidator()
    validator.validate_all_tools(mcp)

    # Generate and log report
    report = validator.generate_report()
    print(report)  # Print to console for visibility
    logger.info("Schema validation report:\n" + report)

    # Fail fast if invalid tools found
    try:
        validator.fail_if_invalid()
        logger.info("✓ All MCP tool schemas valid")
    except RuntimeError as e:
        logger.error(f"✗ Schema validation failed: {e}")
        raise

# Call validation before starting server
validate_schemas_on_startup(mcp)

EOF
```

### 3. Create Schema Export Endpoint

```bash
# Add JSON Schema export endpoint to server
cat > /opt/docling-mcp/application/docling_mcp/api/schema_export.py <<'EOF'
"""
MCP Tool JSON Schema Export API.

Provides OpenAPI 3.1 compatible JSON Schema for all MCP tools.
"""

import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

def generate_openapi_schema(mcp) -> Dict[str, Any]:
    """
    Generate OpenAPI 3.1 compatible schema for all MCP tools.

    Args:
        mcp: FastMCP server instance

    Returns:
        OpenAPI schema dict
    """
    tools = mcp.list_tools()

    openapi_schema = {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "openapi": "3.1.0",
        "info": {
            "title": "Docling MCP Server",
            "version": mcp.version,
            "description": "Model Context Protocol server for document processing",
            "contact": {
                "name": "Hana-X Infrastructure",
                "url": "https://github.com/Hana-X-AI/HX-Infrastructure"
            }
        },
        "servers": [
            {
                "url": "http://192.168.10.217:8000/mcp",
                "description": "Docling MCP Server (hx.dev.local)"
            }
        ],
        "paths": {},
        "components": {
            "schemas": {}
        }
    }

    # Generate schema for each tool
    for tool in tools:
        tool_name = tool["name"]
        input_schema = tool.get("inputSchema", {})
        output_schema = tool.get("outputSchema", {})

        # Add tool endpoint to paths
        openapi_schema["paths"][f"/tools/{tool_name}"] = {
            "post": {
                "summary": tool.get("description", ""),
                "operationId": tool_name,
                "requestBody": {
                    "required": True,
                    "content": {
                        "application/json": {
                            "schema": input_schema
                        }
                    }
                },
                "responses": {
                    "200": {
                        "description": "Successful tool execution",
                        "content": {
                            "application/json": {
                                "schema": output_schema
                            }
                        }
                    }
                }
            }
        }

        # Add input/output schemas to components
        if input_schema:
            openapi_schema["components"]["schemas"][f"{tool_name}Input"] = input_schema
        if output_schema:
            openapi_schema["components"]["schemas"][f"{tool_name}Output"] = output_schema

    logger.info(f"Generated OpenAPI schema for {len(tools)} tools")
    return openapi_schema

def configure_schema_export_endpoint(app, mcp):
    """
    Add /mcp/schema endpoint to export JSON Schema.

    Args:
        app: FastAPI application
        mcp: FastMCP server instance
    """
    @app.get("/mcp/schema")
    async def export_schema():
        """Export OpenAPI 3.1 JSON Schema for all MCP tools."""
        return generate_openapi_schema(mcp)

    logger.info("Schema export endpoint configured: GET /mcp/schema")

EOF

# Set ownership and permissions (uses environment variables)
sudo chown "$DOCLING_USER" /opt/docling-mcp/application/docling_mcp/api/schema_export.py
sudo chgrp "$DOCLING_GROUP" /opt/docling-mcp/application/docling_mcp/api/schema_export.py
chmod 644 /opt/docling-mcp/application/docling_mcp/api/schema_export.py

# Verify ownership
ls -l /opt/docling-mcp/application/docling_mcp/api/schema_export.py
```

### 4. Create Schema Validation Test

```bash
# Create schema validation test
cat > /opt/docling-mcp/application/tests/test_schema_validation.py <<'EOF'
"""
Test MCP tool schema validation.
"""

import pytest
from docling_mcp.server import mcp
from docling_mcp.utils.schema_validation import SchemaValidator

def test_all_tools_have_valid_schemas():
    """Test all 19 MCP tools have valid schemas."""
    validator = SchemaValidator()
    results = validator.validate_all_tools(mcp)

    # All tools should be valid
    invalid_tools = [r for r in results if not r.valid]
    assert len(invalid_tools) == 0, f"Invalid tool schemas: {[r.tool_name for r in invalid_tools]}"

def test_all_tools_have_descriptions():
    """Test all MCP tools have descriptions."""
    tools = mcp.list_tools()
    for tool in tools:
        assert "description" in tool, f"Tool {tool['name']} missing description"
        assert tool["description"], f"Tool {tool['name']} has empty description"

def test_all_required_params_have_descriptions():
    """Test all required parameters have descriptions."""
    validator = SchemaValidator()
    results = validator.validate_all_tools(mcp)

    for result in results:
        assert result.valid, f"Tool {result.tool_name} schema validation failed: {result.errors}"

def test_total_tool_count():
    """Test exactly 19 MCP tools registered."""
    tools = mcp.list_tools()
    assert len(tools) == 19, f"Expected 19 tools, found {len(tools)}"

def test_tool_categories():
    """Test tools distributed across 3 categories."""
    tools = mcp.list_tools()
    tool_names = {tool["name"] for tool in tools}

    # Conversion tools (3)
    conversion_tools = {"convert_document", "convert_document_to_markdown", "batch_convert"}
    assert conversion_tools.issubset(tool_names), "Missing conversion tools"

    # Generation tools (11)
    generation_tools = {
        "generate_knowledge_graph", "extract_entities", "extract_relationships",
        "create_docling_document", "parse_pdf_structure", "extract_tables", "extract_images",
        "detect_document_language", "classify_document_type", "extract_metadata", "generate_document_summary"
    }
    assert generation_tools.issubset(tool_names), "Missing generation tools"

    # Manipulation tools (5)
    manipulation_tools = {"merge_documents", "split_document", "search_document", "annotate_document", "export_document"}
    assert manipulation_tools.issubset(tool_names), "Missing manipulation tools"

EOF

# Set ownership and permissions (uses environment variables)
sudo chown "$DOCLING_USER" /opt/docling-mcp/application/tests/test_schema_validation.py
sudo chgrp "$DOCLING_GROUP" /opt/docling-mcp/application/tests/test_schema_validation.py
chmod 644 /opt/docling-mcp/application/tests/test_schema_validation.py

# Verify ownership
ls -l /opt/docling-mcp/application/tests/test_schema_validation.py
```

## Deliverables

- Schema validation module: `/opt/docling-mcp/application/docling_mcp/utils/schema_validation.py`
- Schema export API: `/opt/docling-mcp/application/docling_mcp/api/schema_export.py`
- Server startup validation (added to server.py)
- Schema validation tests: `/opt/docling-mcp/application/tests/test_schema_validation.py`

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Schema validation module imports
python -c "from docling_mcp.utils.schema_validation import SchemaValidator" && echo "PASS: Schema validation imports"

# 2. Run schema validation manually
python <<'PYEOF'
from docling_mcp.server import mcp
from docling_mcp.utils.schema_validation import SchemaValidator

validator = SchemaValidator()
results = validator.validate_all_tools(mcp)
report = validator.generate_report()
print(report)

# Check all tools valid
validator.fail_if_invalid()
print("\nPASS: All tool schemas valid")
PYEOF

# 3. Run schema validation tests
pytest tests/test_schema_validation.py -v

# Expected output: All tests pass

# 4. Test schema export endpoint (requires server running)
# python -m docling_mcp.server --transport http &
# sleep 5
# curl http://192.168.10.217:8000/mcp/schema | python -m json.tool | head -20
# Expected: OpenAPI 3.1 schema JSON

# 5. Verify all 19 tools present in schema
python -c "
from docling_mcp.server import mcp
tools = mcp.list_tools()
assert len(tools) == 19, f'Expected 19 tools, got {len(tools)}'
print(f'PASS: All 19 tools registered')
"
```

### Expected Output

All 5 verification checks should output "PASS".

## Rollback

If schema validation fails:

```bash
# 1. Remove schema validation module
rm -f /opt/docling-mcp/application/docling_mcp/utils/schema_validation.py
rm -f /opt/docling-mcp/application/docling_mcp/api/schema_export.py

# 2. Remove validation call from server.py startup

# 3. Document failure reason
echo "Schema validation failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Fail-Fast Strategy**: Server will not start if any tool has invalid schema
- **Warning Tolerance**: Tools with warnings (missing parameter descriptions) will still start, but warnings logged
- **Critical Errors**: Missing required parameter descriptions, missing input schema, invalid Pydantic models
- **Schema Export**: GET /mcp/schema provides OpenAPI 3.1 compatible schema for documentation generation

## References

- **Specification**: Section 3.2.1 "MCP Protocol Compliance" - FR-004 (Schema validation requirements)
- **Charter**: Lines 270-336 (MCP protocol compliance details)
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 199-209: Schema validation documentation)
- **Dependencies**: Tasks 009-012 (All tool registration), Task 001 (FastMCP)
