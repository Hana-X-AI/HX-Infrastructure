# HX-Infrastructure Configuration Placeholders

**Purpose:** Centralized documentation of configuration placeholders used throughout HX-Infrastructure documentation
**Status:** ACTIVE
**Last Updated:** 2025-11-22

---

## Overview

This document defines placeholder tokens used in HX-Infrastructure documentation to prevent hardcoding sensitive values and enable environment-specific configuration.

**Usage:**
- Documentation files use `{PLACEHOLDER_NAME}` tokens
- Actual values are maintained in this centralized file
- Prevents IP/credential leakage in documentation
- Enables easy updates when infrastructure changes

---

## Network Infrastructure Placeholders

### {DEV_SERVER_IP}
**Description:** Development server IP address for Docker-based project isolation
**Actual Value:** `192.168.10.222` (hx-dev-server - planned dedicated development environment server)
**Usage:** References to Docker development environment
**Example:** "Docker containers allowed ONLY on hx-dev-server ({DEV_SERVER_IP})"

**Context:**
- Docker is permitted ONLY on this server for development/project isolation
- Production and staging environments use bare metal deployment
- This server also hosts code-focused LLM models (dual-purpose)

---

## Future Placeholders

As the infrastructure evolves, additional placeholders will be added here following the same pattern:

**Format:**
```markdown
### {PLACEHOLDER_NAME}
**Description:** Brief description of what this represents
**Actual Value:** The actual value (if non-sensitive)
**Usage:** When and where to use this placeholder
**Example:** Example usage in documentation
**Context:** Additional context or constraints
```

---

## Placeholder Usage Guidelines

1. **Always use placeholders in documentation** for:
   - Internal IP addresses (except in inventory files)
   - Server hostnames (when referencing infrastructure)
   - Port numbers that might change
   - Environment-specific paths

2. **Use actual values in**:
   - `/inventory/nodes.md` - authoritative infrastructure baseline
   - Deployment scripts and configurations
   - Operational runbooks (when specific values are needed)

3. **Update this file when**:
   - Infrastructure changes affect placeholder values
   - New placeholders are needed
   - Placeholder usage patterns change

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-22 | Initial creation with {DEV_SERVER_IP} placeholder | Infrastructure Team |

---

**Document Type:** Infrastructure - Configuration Management
**Classification:** Internal
**Maintained By:** Infrastructure Team
