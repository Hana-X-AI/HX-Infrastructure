# Documentation Requirements Standards

**Document Type**: Standards - Documentation  
**Created**: 2025-11-15  
**Version**: 1.0  
**Status**: ✅ ACTIVE - Required for All Services

---

## Purpose

This document establishes documentation standards for HX Infrastructure. All services, nodes, and infrastructure components must maintain documentation that meets these requirements.

---

## Table of Contents

1. [Documentation Principles](#1-documentation-principles)
2. [Required Documentation](#2-required-documentation)
3. [Documentation Format Standards](#3-documentation-format-standards)
4. [Documentation Maintenance](#4-documentation-maintenance)
5. [Agent-Readable Documentation](#5-agent-readable-documentation)
6. [Documentation Review and Approval](#6-documentation-review-and-approval)

---

## 1. Documentation Principles

### 1.1 Core Principles

**Documentation MUST be**:
- **Accurate**: Reflects current state, no outdated information
- **Complete**: All required sections filled out, no placeholders
- **Consistent**: Follows naming conventions and templates
- **Agent-Readable**: Structured for AI agent consumption
- **Maintainable**: Updated as part of deployment process
- **Accessible**: Located in standard locations

**Documentation is NOT**:
- Optional - All services must have complete documentation
- Static - Must be updated with every change
- Decorative - Must provide actionable information

---

### 1.2 Documentation-First Principle

**From Constitution**:
> "Every infrastructure change starts with documentation before execution."

**Application**:
- Specification written before deployment
- Plan documented before execution
- Tests documented before running
- Changes documented before implementing

**No Exceptions**: Services without complete documentation cannot be promoted to operational status.

---

## 2. Required Documentation

### 2.1 Service Documentation (Mandatory)

**Every service MUST have**:

1. **Specification** (`spec.md`)
   - Service purpose and requirements
   - Functional requirements (FR-001, FR-002, ...)
   - Success criteria (SC-001, SC-002, ...)
   - Dependencies and integrations
   - Node requirements

2. **Deployment Plan** (`plan.md`)
   - Technical context (technology, versions, target node)
   - Deployment architecture
   - Configuration specifications
   - Rollback strategy
   - Risk assessment

3. **Deployment Tasks** (`tasks/`)
   - Individual task files: `[service]-task-###-[description].md`
   - Sequential numbering per service
   - Clear dependencies
   - Verification steps

4. **Architecture** (`deployment/architecture.md`)
   - System context diagram
   - Component architecture
   - API documentation (if applicable)
   - Integration points
   - Data model

5. **Configuration** (`deployment/`)
   - `configuration.md` - Configuration details
   - `dependencies.md` - Dependency list and versions
   - `installation.md` - Installation instructions

6. **Test Suite** (`tests/`)
   - `test-plan.md` - Test strategy and coverage
   - `test-suite/` - Test cases organized by area
     - `deployment/` - Deployment validation tests
     - `functionality/` - Functionality tests
     - `integration/` - Integration tests (if applicable)
     - `health-check/` - Health check tests
   - `test-results/` - Test execution results

7. **Vault** (`vault/`)
   - `secrets.yml` - Encrypted secrets (Ansible Vault)
   - `README.md` - Vault usage instructions
   - `.vault_password` - Vault password file (git-ignored)

---

### 2.2 Node Documentation (Mandatory)

**Every node MUST have**:

1. **Node Specification** (`nodes/[node]/node-spec.md`)
   - Hardware specifications
   - Operating system details
   - Network configuration
   - Deployed services
   - Resource allocation
   - Monitoring configuration

2. **Services Deployed** (`nodes/[node]/services-deployed.md`)
   - List of all services on node
   - Service status (operational/non-operational)
   - Resource usage per service
   - Service dependencies

3. **Configuration** (`nodes/[node]/configuration/`)
   - `env-vars.md` - Environment variables
   - `installed-packages.md` - System packages
   - Additional configuration files as needed

4. **Node Vault** (`nodes/[node]/vault/`)
   - Node-level secrets
   - SSH keys
   - System credentials

---

### 2.3 Infrastructure Documentation (Mandatory)

**Repository-level documentation**:

1. **Constitution** (`constitution.md`)
   - Infrastructure principles
   - Non-negotiable standards
   - Governance and compliance

2. **Inventory** (`inventory/`)
   - `nodes.md` - All nodes and their status
   - `services.md` - All services and their status
   - `network-topology.md` - Network layout

3. **Network** (`network/`)
   - `topology.md` - Network diagram and structure
   - `port-mapping.md` - Port assignments
   - `connectivity.md` - Connection requirements

4. **Standards** (`standards/`)
   - All standards documents (this file included)

5. **Templates** (`templates/`)
   - All template files for creating documentation

6. **Procedures** (`procedures/`)
   - Operational procedures
   - Troubleshooting guides

---

## 3. Documentation Format Standards

### 3.1 File Format

**All documentation MUST use**:
- **Format**: Markdown (.md files)
- **Encoding**: UTF-8
- **Line endings**: LF (Unix-style)
- **Max line length**: None (let editors wrap)

**Why Markdown**:
- Version control friendly
- Agent-readable
- Human-readable
- Platform-independent
- Rich formatting support

---

### 3.2 Document Structure

**Every document MUST include**:

1. **Title** (H1 heading)
   ```markdown
   # Service Specification: [Service Name]
   ```

2. **Metadata**
   ```markdown
   **Service**: [service-name]  
   **Created**: [DATE]  
   **Last Updated**: [DATE]  
   **Status**: [Draft | Active | Deprecated]
   ```

3. **Table of Contents** (for documents > 100 lines)
   ```markdown
   ## Table of Contents
   - [Section 1](#section-1)
   - [Section 2](#section-2)
   ```

4. **Clear section headers** (H2, H3)
   - Descriptive titles
   - Hierarchical structure
   - Consistent naming

5. **Footer metadata**
   ```markdown
   ---
   **Template Version**: 1.0  
   **Last Updated**: 2025-11-15  
   **Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
   ```

---

### 3.3 Writing Style

**Documentation MUST be**:

1. **Clear and Concise**
   - Short sentences
   - Active voice
   - No jargon unless defined
   - Specific, not vague

2. **Structured**
   - Use headings appropriately
   - Lists for multiple items
   - Tables for comparisons
   - Code blocks for examples

3. **Complete**
   - No "TODO" markers
   - No "[To be completed]" placeholders
   - No vague references ("see elsewhere")
   - All sections filled out

4. **Consistent**
   - Follow naming conventions
   - Use templates
   - Same terminology throughout
   - Consistent formatting

---

### 3.4 Code Examples

**All code examples MUST**:

1. **Use proper syntax highlighting**
   ```bash
   # Good
   ansible-vault view vault/secrets.yml
   ```

2. **Be complete and runnable**
   - No partial snippets (unless clearly marked)
   - Include all necessary context
   - Use realistic values or clear placeholders

3. **Include comments**
   ```yaml
   # Database configuration
   database:
     host: postgres.hx.dev.local  # Database server
     port: 5432                    # Standard PostgreSQL port
   ```

4. **Show expected output** (where helpful)
   ```bash
   $ ls -la /opt/service/
   # Output:
   # drwxr-xr-x 3 svc-service svc-service 4096 Nov 15 10:30 .
   ```

---

### 3.5 Diagrams

**Diagrams SHOULD**:

1. **Use Mermaid** (preferred)
   ```mermaid
   graph LR
       A[Service] --> B[Database]
       A --> C[Cache]
   ```

2. **Be version controlled**
   - Source files committed to Git
   - Generated images also committed

3. **Have clear labels**
   - All components labeled
   - Connections labeled with protocol/purpose
   - Legend included if needed

4. **Be up to date**
   - Updated when architecture changes
   - Reviewed during documentation audits

---

## 4. Documentation Maintenance

### 4.1 Update Requirements

**Documentation MUST be updated when**:

1. **Service Changes**
   - New features added → Update spec.md
   - Configuration changed → Update plan.md, configuration.md
   - Dependencies changed → Update dependencies.md
   - API changed → Update architecture.md, API docs

2. **Deployment Changes**
   - Node reassigned → Update node-spec.md, services-deployed.md
   - Resources changed → Update node-spec.md
   - Network changed → Update network/topology.md

3. **Test Changes**
   - New tests added → Update test-plan.md
   - Tests modified → Update test cases
   - Results change → Add to test-results/

4. **Issues Found**
   - Defects logged → Create defect-*.md files
   - Problems resolved → Update defect status
   - Workarounds found → Document in troubleshooting

---

### 4.2 Documentation Lifecycle

**Draft → Active → Deprecated**

**Draft**:
- Service in non-operational/
- Documentation being created
- May have some incomplete sections (clearly marked)

**Active**:
- Service in operational/
- All documentation complete
- Regularly maintained

**Deprecated**:
- Service being decommissioned
- Documentation marked deprecated
- Retained for historical reference

---

### 4.3 Version Control

**All documentation MUST be**:
- Committed to Git
- Have meaningful commit messages
- Reviewed in pull requests

**Commit Message Format**:
```
docs([service]): [brief description]

[Detailed description of what changed and why]

Affects: [list of files]
```

**Example**:
```
docs(api-gateway): update API endpoints for v2

Added new authentication endpoints and deprecated v1 user endpoints.
Updated architecture diagram to show new auth flow.

Affects:
- spec.md
- deployment/architecture.md
- deployment/api-documentation.md
```

---

## 5. Agent-Readable Documentation

### 5.1 Structure for Agents

**AI agents (Claude Code, GitHub Copilot) require**:

1. **Explicit Structure**
   - Clear headings
   - Consistent formatting
   - Predictable locations
   - Standard templates

2. **Complete Context**
   - No assumed knowledge
   - All dependencies stated
   - Clear relationships
   - Explicit references

3. **Actionable Information**
   - Specific commands
   - Clear procedures
   - Unambiguous requirements
   - Testable criteria

---

### 5.2 Agent-Friendly Patterns

**Use**:
```markdown
## Prerequisites
- [ ] Node has 4GB RAM available
- [ ] PostgreSQL 16 is installed
- [ ] Port 8080 is available

## Steps
1. Install dependencies: `apt install package-name`
2. Create configuration: `cp config.template config.yml`
3. Start service: `systemctl start service-name`

## Verification
Run: `curl http://localhost:8080/health`
Expected: `{"status": "healthy"}`
```

**Avoid**:
```markdown
## Setup
Make sure everything is ready, then install the stuff and configure it properly.
```

---

### 5.3 Cross-References

**Always use explicit paths**:

**Good**:
```markdown
See deployment plan: `services/api-gateway/plan.md`
See node specification: `nodes/agent0/node-spec.md`
```

**Bad**:
```markdown
See the deployment plan
Check the node specs
```

---

## 6. Documentation Review and Approval

### 6.1 Review Requirements

**All documentation MUST be reviewed before**:
- Service promoted to operational
- Major changes committed
- Documentation marked as "Active"

**Review Checklist**:
- [ ] All required sections complete
- [ ] No placeholders or TODOs
- [ ] Follows format standards
- [ ] Agent-readable structure
- [ ] Code examples work
- [ ] Diagrams up to date
- [ ] Cross-references valid
- [ ] Naming conventions followed
- [ ] Grammar and spelling correct

---

### 6.2 Review Process

1. **Author** creates/updates documentation
2. **Self-review** against checklist
3. **Peer review** by another team member
4. **Agent review** (agent can parse it)
5. **Approval** and merge

**Review Comments Format**:
- Specific: "Line 42: Add node requirements"
- Actionable: "Update diagram to show new API endpoint"
- Constructive: "Consider adding example for this configuration"

---

### 6.3 Documentation Audits

**Quarterly audit of**:
- Accuracy (does doc match reality?)
- Completeness (all sections filled?)
- Currency (is it up to date?)
- Consistency (follows standards?)

**Audit Process**:
1. Select services for audit (random + all operational)
2. Verify documentation against deployed state
3. Identify discrepancies
4. Create issues for fixes
5. Track fix completion

---

## Documentation Completeness Checklist

### Service Promotion Requirements

**Before service moves to operational/**:

- [ ] spec.md complete with all requirements
- [ ] plan.md complete with deployment architecture
- [ ] All tasks documented in tasks/
- [ ] Architecture documented in deployment/architecture.md
- [ ] API documented (if service has API)
- [ ] Integrations documented
- [ ] Test plan complete
- [ ] All test cases written
- [ ] Test results documented
- [ ] Vault configured
- [ ] Configuration documented
- [ ] Dependencies documented
- [ ] No [NEEDS CLARIFICATION] markers
- [ ] No TODO or placeholder sections
- [ ] Diagrams included and current
- [ ] Peer reviewed
- [ ] Approved

---

## Common Documentation Defects

### What to Avoid

**Vague Requirements**:
```markdown
❌ "Service should be fast"
✅ "Service must respond in < 200ms (p95)"
```

**Incomplete Examples**:
```markdown
❌ "Configure the database connection"
✅ "Configure database in config.yml:
    database:
      host: postgres.hx.dev.local
      port: 5432
      name: service_db"
```

**Broken References**:
```markdown
❌ "See the architecture doc"
✅ "See `services/api-gateway/deployment/architecture.md`"
```

**Outdated Information**:
```markdown
❌ Spec says: "Deployed on node1" (but actually on node2)
✅ Spec says: "Deployed on node2" (matches reality)
```

**Assumed Knowledge**:
```markdown
❌ "Use the standard password"
✅ "Use service password from vault: services/[service]/vault/secrets.yml"
```

---

## Quick Reference

### Documentation Locations

| Document Type | Location | Required? |
|--------------|----------|-----------|
| Service Spec | `services/[service]/spec.md` | Yes |
| Deployment Plan | `services/[service]/plan.md` | Yes |
| Architecture | `services/[service]/deployment/architecture.md` | Yes |
| Test Plan | `services/[service]/tests/test-plan.md` | Yes |
| Node Spec | `nodes/[node]/node-spec.md` | Yes |
| Inventory | `inventory/*.md` | Yes |
| Standards | `standards/*.md` | Yes |

### Document Status Values

| Status | Meaning |
|--------|---------|
| Draft | Work in progress, may be incomplete |
| Active | Complete, current, in use |
| Deprecated | No longer current, retained for history |

---

## Related Documents

- `constitution.md` - Documentation-first principle
- `standards/naming-conventions.md` - File naming standards
- `templates/` - Documentation templates

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
