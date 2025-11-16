# HX Infrastructure Naming Conventions

**Version:** 1.0  
**Last Updated:** 2025-11-15  
**Repository:** https://github.com/Hana-X-AI/HX-Infrastructure.git  
**Purpose:** Establish consistent naming standards for all artifacts in HX-Infrastructure repository

---

## Core Principles

1. **Consistency:** All names follow the same patterns
2. **Clarity:** Names should be self-documenting
3. **Brevity:** Descriptive but concise
4. **Machine-Readable:** No spaces, special characters limited to hyphens and underscores
5. **Case:** Lowercase for files and directories unless specified otherwise

---

## General Format Rules

- **Separator:** Use hyphens (`-`) for all multi-word names
- **Extension:** All documentation uses `.md` (Markdown)
- **No Spaces:** Never use spaces in file or directory names
- **No Special Characters:** Avoid `/ \ : * ? " < > |` and other special characters
- **Dates:** Use ISO format `YYYY-MM-DD` when dates are part of filenames

---

## Services

**Format:** `<service-name>`

**Rules:**
- All lowercase
- Hyphen-separated for multi-word names
- Descriptive but concise
- No version numbers in service name (track in spec.md)

**Examples:**
- `database-service`
- `api-gateway`
- `mcp-server`
- `auth-service`

---

## Nodes

**Format:** `<node-identifier>`

**Rules:**
- All lowercase
- Should reflect node's primary purpose or designation
- Numeric suffixes acceptable (agent0, agent1, etc.)

**Examples:**
- `agent0`
- `database-node`
- `api-server`
- `worker-01`

---

## Documents

### Specification Documents
**Format:** `spec.md`

**Location:** `services/<operational|non-operational>/<service>/spec.md`

**Rules:**
- Always named `spec.md`
- One per service
- Located in service root directory

---

### Plan Documents
**Format:** `plan.md`

**Location:** `services/<operational|non-operational>/<service>/plan.md`

**Rules:**
- Always named `plan.md`
- One per service
- Located in service root directory

---

### Node Specification
**Format:** `node-spec.md`

**Location:** `nodes/<node-name>/node-spec.md`

**Rules:**
- Always named `node-spec.md`
- One per node
- Describes hardware, OS, purpose

---

### Configuration Documents
**Format:** `<configuration-type>.md`

**Location:** `nodes/<node-name>/configuration/<configuration-type>.md`

**Examples:**
- `env-vars.md`
- `installed-packages.md`
- `network-config.md`
- `storage-config.md`

---

## Tasks

**Format:** `<service>-task-<sequence>-<brief-description>.md`

**Location:** `services/<operational|non-operational>/<service>/tasks/`

**Rules:**
- Service name prefix (lowercase, hyphenated)
- Sequential numbering: 001, 002, 003... (three digits)
- Sequence restarts for each service
- Brief description (2-4 words, hyphen-separated)
- Ordered execution implied by sequence number

**Examples:**
- `api-gateway-task-001-install-dependencies.md`
- `api-gateway-task-002-configure-environment.md`
- `api-gateway-task-003-verify-installation.md`
- `database-service-task-001-create-schema.md`

---

## Test Cases

**Format:** `tc-<service>-<test-area>-<sequence>-<description>.md`

**Location:** `services/<operational|non-operational>/<service>/tests/test-suite/<test-area>/`

**Rules:**
- Prefix: `tc-` (test case)
- Service name (lowercase, hyphenated)
- Test area: deployment, functionality, integration, health-check
- Sequential numbering: 001, 002, 003... (three digits per test area)
- Brief description (2-4 words)
- One test case per file

**Test Areas:**
- `deployment` - Deployment verification tests
- `functionality` - Core service functionality tests
- `integration` - Integration with other services/systems
- `health-check` - Ongoing operational health tests

**Examples:**
- `tc-api-gateway-deployment-001-verify-installation.md`
- `tc-api-gateway-deployment-002-validate-configuration.md`
- `tc-api-gateway-functionality-001-route-requests.md`
- `tc-api-gateway-integration-001-database-connection.md`
- `tc-api-gateway-health-001-endpoint-availability.md`

---

## Test Results

**Format:** `<date>-<test-case-id>-<result>.md`

**Location:** `services/<operational|non-operational>/<service>/tests/test-results/`

**Rules:**
- Date: ISO format `YYYY-MM-DD`
- Test case ID: Complete test case filename (without .md extension)
- Result: `pass`, `fail`, `blocked`

**Examples:**
- `2025-11-15-tc-api-gateway-deployment-001-pass.md`
- `2025-11-15-tc-api-gateway-functionality-001-fail.md`
- `2025-11-16-tc-api-gateway-integration-001-blocked.md`

---

## Defects

**Format:** `defect-<service>-<severity>-<sequence>-<brief-description>.md`

**Location:** `defects/` (centralized at repository root)

**Rules:**
- Service name (lowercase, hyphenated)
- Severity: `critical`, `high`, `medium`, `low`
- Sequential numbering: 001, 002, 003... (three digits, global across all services)
- Brief description (2-4 words)

**Severity Definitions:**
- `critical` - System down, complete service failure, data loss
- `high` - Major functionality broken, significant impact
- `medium` - Functionality impaired, workaround available
- `low` - Minor issue, cosmetic, enhancement

**Examples:**
- `defect-api-gateway-critical-001-service-not-starting.md`
- `defect-database-service-high-002-connection-timeouts.md`
- `defect-api-gateway-medium-003-slow-response-time.md`
- `defect-auth-service-low-004-log-formatting.md`

---

## Directories

**Format:** `<directory-name>`

**Rules:**
- All lowercase
- Hyphen-separated for multi-word names
- Descriptive but concise
- Plural for collections (tests, tasks, nodes, services)
- Singular for single items (deployment, configuration)

**Standard Directory Names:**
- `operational` - Operational services
- `non-operational` - Non-operational services
- `deployment` - Deployment artifacts
- `configuration` - Configuration files
- `test-suite` - Test cases organized by area
- `test-results` - Test execution results
- `hx-agents` - Agent operational instructions
- `hx-knowledge` - Knowledge base for agents

**Examples:**
- `services/operational/api-gateway/`
- `nodes/agent0/configuration/`
- `tests/test-suite/deployment/`
- `hx-knowledge/repos/`

---

## POC (Proof of Concept)

**Format:** `poc-<artifact-type>.md`

**Location:** `services/<operational|non-operational>/<service>/poc/`

**Rules:**
- Prefix: `poc-`
- Artifact type: spec, results, summary
- Optional directory - only created if POC exists

**Examples:**
- `poc-spec.md` - POC requirements and objectives
- `poc-results.md` - POC findings and outcomes
- `poc-summary.md` - Executive summary of POC

---

## Inventory Documents

**Format:** `<inventory-type>.md`

**Location:** `inventory/`

**Rules:**
- Descriptive name of what's being inventoried
- Maintained as living documents

**Examples:**
- `nodes.md` - All server nodes
- `services.md` - All deployed services
- `network-topology.md` - Network layout

---

## Network Documentation

**Format:** `<network-aspect>.md`

**Location:** `network/`

**Examples:**
- `topology.md` - Network diagram and structure
- `port-mapping.md` - Port assignments
- `connectivity.md` - Connection requirements

---

## Templates

**Format:** `<artifact-type>-template.md`

**Location:** `templates/` or `templates/testing/`

**Rules:**
- Descriptive artifact type
- Always ends with `-template.md`

**Examples:**
- `service-spec-template.md`
- `service-plan-template.md`
- `service-task-template.md`
- `node-template.md`
- `testing/test-case-template.md`
- `testing/defect-template.md`

---

## Procedures

**Format:** `<procedure-name>.md`

**Location:** `procedures/`

**Rules:**
- Descriptive procedure name
- Hyphen-separated
- Action-oriented naming

**Examples:**
- `node-provisioning.md`
- `service-deployment.md`
- `test-execution.md`
- `defect-management.md`
- `service-promotion.md`

---

## Standards

**Format:** `<standard-area>.md`

**Location:** `standards/`

**Rules:**
- Descriptive standard area
- Hyphen-separated

**Examples:**
- `naming-conventions.md`
- `documentation-requirements.md`
- `deployment-requirements.md`
- `testing-requirements.md`

---

## Version Control

### Branch Naming
**Format:** `<type>/<service>-<brief-description>`

**Types:**
- `feature/` - New feature or service deployment
- `fix/` - Bug fixes or defect resolution
- `docs/` - Documentation updates
- `config/` - Configuration changes

**Examples:**
- `feature/api-gateway-deployment`
- `fix/database-service-connection-issue`
- `docs/update-node-specs`
- `config/agent0-network-settings`

### Commit Messages
**Format:** `<type>: <brief description>`

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `config:` - Configuration change
- `test:` - Test additions/changes

**Examples:**
- `feat: add api-gateway service specification`
- `fix: resolve database connection timeout`
- `docs: update node inventory`
- `test: add integration test for auth service`

---

## File Naming Quick Reference

| Artifact Type | Format | Example |
|--------------|--------|---------|
| Service Name | `<service>` | `api-gateway` |
| Node Name | `<node>` | `agent0` |
| Spec | `spec.md` | `spec.md` |
| Plan | `plan.md` | `plan.md` |
| Task | `<service>-task-<seq>-<desc>.md` | `api-gateway-task-001-install.md` |
| Test Case | `tc-<service>-<area>-<seq>-<desc>.md` | `tc-api-gateway-deploy-001-verify.md` |
| Test Result | `<date>-<test-id>-<result>.md` | `2025-11-15-tc-api-gateway-deploy-001-pass.md` |
| Defect | `defect-<service>-<severity>-<seq>-<desc>.md` | `defect-api-gateway-high-001-timeout.md` |
| Directory | `<name>` | `test-suite` |

---

## Compliance

All artifacts created in hx-infra-base MUST follow these naming conventions. Non-compliant names will be rejected during code review and must be corrected before merge.

**Enforcement:**
- Automated validation in CI/CD pipeline (future)
- Manual review during pull requests
- Regular audits of repository structure

---

## Updates

This document is a living standard. Proposed changes must:
1. Be documented in a proposal
2. Be reviewed by infrastructure team
3. Be approved before implementation
4. Include migration plan for existing artifacts

**Change History:**
- 2025-11-15: Initial version 1.0
