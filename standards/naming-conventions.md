---
document: naming-conventions
version: 2.1
date: 2025-11-21
status: APPROVED
type: operational-standard
description: Naming convention standards for all artifacts in HX Infrastructure including services, nodes, documents, tasks, tests, and defects
applies_to: all_artifacts, services, nodes, documentation, tasks, tests, defects, version_control
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/standards/naming-conventions.md
last_updated: 2025-11-21
update_notes: Added comprehensive metadata, infrastructure context, command integration, version history
---

# Naming Conventions Standards
## Comprehensive Naming Standards for HX-Infrastructure Artifacts

**Document Type:** Standard - Operational Naming Conventions
**Version:** 2.1
**Date:** 2025-11-21
**Status:** ✅ APPROVED - Mandatory for All Artifacts
**Location:** `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
**Previous Version:** 2.0 → 2.1 (comprehensive metadata, infrastructure integration, procedure alignment)

---

<metadata>
**Document:** Naming Conventions Standards
**Version:** 2.1
**Status:** ✅ APPROVED - Required for All Artifacts
**Last Updated:** 2025-11-21
**Repository:** https://github.com/Hana-X-AI/HX-Infrastructure.git
</metadata>

<objective>
**Purpose:** Establish consistent naming standards for all artifacts in HX-Infrastructure repository ensuring consistency, clarity, and machine-readability.

**Scope:** All artifacts in HX-Infrastructure including:
- Services and nodes
- Documentation (spec.md, plan.md, tasks, tests)
- Defects and POC artifacts
- Directories and templates
- Version control (branches, commits)

**Authority:** Mandatory for all artifact creation. Non-compliant names will be rejected during code review.
</objective>

---

<core_principles>
1. **Consistency:** All names follow the same patterns
2. **Clarity:** Names should be self-documenting
3. **Brevity:** Descriptive but concise
4. **Machine-Readable:** No spaces. Use hyphens only for filenames/directories. Underscores are disallowed in names (exception: vault passwords or formats that mandate them).
5. **Case:** Lowercase for files and directories unless specified otherwise

**Examples:**
- ✅ Allowed: `service-spec-template.md`, `test-case-001.md`, `vault_admin_password`
- ❌ Disallowed: `service_spec_template.md`, `test_case_001.md`, `service name.md`
</core_principles>

---

<general_format_rules>
- **Separator:** Use hyphens (`-`) for all multi-word names
- **Extension:** All documentation uses `.md` (Markdown)
- **No Spaces:** Never use spaces in file or directory names
- **No Special Characters:** Avoid `/ \ : * ? " < > |` and other special characters
- **Dates:** Use ISO format `YYYY-MM-DD` when dates are part of filenames
</general_format_rules>

---

<service_naming>
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
</service_naming>

---

<node_naming>
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
</node_naming>

---

<document_naming>

<specification_documents>
**Format:** `spec.md`
**Location:** `services/<operational|non-operational>/<service>/spec.md`

**Rules:**
- Always named `spec.md`
- One per service
- Located in service root directory
</specification_documents>

<plan_documents>
**Format:** `plan.md`
**Location:** `services/<operational|non-operational>/<service>/plan.md`

**Rules:**
- Always named `plan.md`
- One per service
- Located in service root directory
</plan_documents>

<node_specification>
**Format:** `node-spec.md`
**Location:** `nodes/<node-name>/node-spec.md`

**Rules:**
- Always named `node-spec.md`
- One per node
- Describes hardware, OS, purpose
</node_specification>

<configuration_documents>
**Format:** `<configuration-type>.md`
**Location:** `nodes/<node-name>/configuration/<configuration-type>.md`

**Examples:**
- `env-vars.md`
- `installed-packages.md`
- `network-config.md`
- `storage-config.md`
</configuration_documents>

</document_naming>

---

<task_naming>
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
</task_naming>

---

<test_case_naming>
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
</test_case_naming>

---

<test_result_naming>
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
</test_result_naming>

---

<defect_naming>
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
</defect_naming>

---

<directory_naming>
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
</directory_naming>

---

<poc_naming>
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
</poc_naming>

---

<inventory_naming>
**Format:** `<inventory-type>.md`
**Location:** `inventory/`

**Rules:**
- Descriptive name of what's being inventoried
- Maintained as living documents

**Examples:**
- `nodes.md` - All server nodes
- `services.md` - All deployed services
- `network-topology.md` - Network layout
</inventory_naming>

---

<network_documentation_naming>
**Format:** `<network-aspect>.md`
**Location:** `network/`

**Examples:**
- `topology.md` - Network diagram and structure
- `port-mapping.md` - Port assignments
- `connectivity.md` - Connection requirements
</network_documentation_naming>

---

<template_naming>
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
</template_naming>

---

<procedure_naming>
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
</procedure_naming>

---

<standards_naming>
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
</standards_naming>

---

<version_control_naming>

<branch_naming>
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
</branch_naming>

<commit_message_format>
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
</commit_message_format>

</version_control_naming>

---

<quick_reference>
**File Naming Quick Reference:**

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
</quick_reference>

---

<critical_reminders>
1. ⚠️ **All Lowercase:** All file and directory names MUST be lowercase. No exceptions.

2. ⚠️ **Hyphens Only:** Use hyphens (`-`) as separators for filenames/directories. Never use underscores in filenames/directories (exception: vault passwords or formats that mandate them).

3. ⚠️ **Sequential Numbering:** Task and test sequence numbers MUST be three digits (001, 002, 003) for proper sorting.

4. ⚠️ **Consistent Prefixes:** Test cases MUST start with `tc-`, defects with `defect-`, POC artifacts with `poc-`.

5. ⚠️ **ISO Date Format:** All dates in filenames MUST use `YYYY-MM-DD` format. No other date formats allowed.

6. ⚠️ **Service Name Consistency:** Use exact service name from services/ directory. Must match across all artifacts.

7. ⚠️ **No Version Numbers:** Service names MUST NOT include version numbers. Track versions in spec.md.

8. ⚠️ **Template Suffix:** All template files MUST end with `-template.md`. No exceptions.

9. ⚠️ **Test Area Names:** Test areas MUST be one of: deployment, functionality, integration, health-check. No custom areas.

10. ⚠️ **Severity Levels:** Defect severity MUST be one of: critical, high, medium, low. No custom severities.
</critical_reminders>

---

<validation_checklist>
**Artifact Naming Validation:**

Before committing any artifact, verify:

**General Compliance:**
- [ ] Name is all lowercase
- [ ] Multi-word names use hyphens (not spaces or underscores)
- [ ] No special characters (`/ \ : * ? " < > |`)
- [ ] File extension is `.md` (for documentation)

**Service/Node Names:**
- [ ] Service name matches directory name exactly
- [ ] Node name is descriptive of purpose or designation
- [ ] No version numbers in service/node names

**Task Files:**
- [ ] Prefix matches service name exactly
- [ ] Sequence number is three digits (001, 002, 003)
- [ ] Brief description is 2-4 hyphenated words
- [ ] Format: `<service>-task-<seq>-<desc>.md`

**Test Case Files:**
- [ ] Prefix is `tc-`
- [ ] Service name matches exactly
- [ ] Test area is valid (deployment, functionality, integration, health-check)
- [ ] Sequence number is three digits per test area
- [ ] Format: `tc-<service>-<area>-<seq>-<desc>.md`

**Test Result Files:**
- [ ] Date is ISO format (YYYY-MM-DD)
- [ ] Test case ID matches exactly (without .md)
- [ ] Result is valid (pass, fail, blocked)
- [ ] Format: `<date>-<test-case-id>-<result>.md`

**Defect Files:**
- [ ] Prefix is `defect-`
- [ ] Service name matches exactly
- [ ] Severity is valid (critical, high, medium, low)
- [ ] Sequence number is three digits (global sequence)
- [ ] Format: `defect-<service>-<severity>-<seq>-<desc>.md`

**Version Control:**
- [ ] Branch name uses valid type (feature/, fix/, docs/, config/)
- [ ] Commit message uses valid type (feat:, fix:, docs:, config:, test:)
- [ ] Branch/commit message is concise and descriptive
</validation_checklist>

---

<compliance>
**Compliance Requirements:**

All artifacts created in HX-Infrastructure MUST follow these naming conventions. Non-compliant names will be rejected during code review and must be corrected before merge.

**Enforcement:**
- Automated validation in CI/CD pipeline (future)
- Manual review during pull requests
- Regular audits of repository structure
</compliance>

---

<infrastructure_integration>
**Infrastructure Philosophy and Naming:**

These naming conventions are intentionally infrastructure-agnostic. The HX-Infrastructure deployment philosophy (bare metal, systemd, manual procedures, Ansible Vault) is documented in:
- Specification files (`spec.md`, `node-spec.md`)
- Deployment plans (`plan.md`)
- Task files (execution procedures)

Naming conventions focus on artifact organization and consistency, NOT deployment methodology.

**Node Naming and Infrastructure:**
- Node names reflect operational purpose: `hx-docling-mcp-server` (not deployment method)
- Directory structure (`nodes/`, `services/`) is deployment-neutral
- Infrastructure details documented within artifacts, not in artifact names
</infrastructure_integration>

---

<procedure_alignment>
**Integration with Procedures:**

These naming conventions are enforced throughout the project lifecycle:

**Phase 0: Project Initiation** (`node-deployment-workflow.md`)
- Directory structure follows `<directory_naming>` standards
- Node names follow `<node_naming>` format (hx-<service>-server)
- Template files follow `<template_naming>` conventions

**Phase 1: Charter** (`charter-workflow.md`)
- Charter files: `charter.md` (standardized name)
- Review files: `charter-reviews/YYYY-MM-DD-review.md`

**Phase 2: Specification** (`spec-workflow.md`)
- Specification files: `node-spec.md` or `spec.md`
- Review files: `node-spec-reviews/YYYY-MM-DD-review.md`

**Phase 3: Task Breakdown** (`task-workflow.md`)
- Task files follow `<task_naming>` format
- Test cases follow `<test_case_naming>` format
- Test areas: deployment, functionality, integration, health-check

**Phase 4: Execution** (`task-execution-workflow.md`)
- Task result files: `task-<seq>-results.md`
- Test result files follow `<test_result_naming>` format

**Phase 5: Closeout** (`project-closeout-workflow.md`)
- Final reports: `final-project-status-report.md`
- Operational handoff: `operations-handoff.md`
</procedure_alignment>

---

<related_documents>
**Standards Documentation:**
- `architecture-standards.md` - Architecture patterns and layer structure
- `deployment-requirements.md` - Deployment approach and infrastructure philosophy
- `documentation-requirements.md` - Documentation content and structure standards
- `testing-requirements.md` - Test coverage and test suite requirements
- `credentials-vault-management.md` - Ansible Vault naming and structure
- `utility-development-standards.md` - Command and utility naming patterns

**Procedure Documentation:**
- `/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md` - Directory structure creation (Phase 0)
- `/home/agent0/HX-Infrastructure/procedures/charter-workflow.md` - Charter file naming (Phase 1)
- `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Specification file naming (Phase 2)
- `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Task and test naming (Phase 3)
- `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` - Result file naming (Phase 4)
- `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Closeout document naming (Phase 5)

**Template Documentation:**
- `/home/agent0/HX-Infrastructure/templates/` - All templates follow `-template.md` suffix convention

**Command Documentation:**
- `.claude/commands/workflows/` - Workflow commands enforce naming standards
- `.claude/commands/utilities/` - Utility commands (doc-lint validates naming)
- `.claude/commands/phases/` - Phase commands use standardized artifact names
</related_documents>

---

<document_evolution>
**Change Management:**

This document is a living standard. Proposed changes must:
1. Be documented in a proposal
2. Be reviewed by infrastructure team
3. Be approved before implementation
4. Include migration plan for existing artifacts

**Change History:**
- 2025-11-21: Version 2.1 - Added comprehensive metadata, infrastructure integration, procedure alignment, related documents, version history
- 2025-11-20: Version 2.0 - Converted to semantic XML structure
- 2025-11-15: Version 1.0 - Initial version
</document_evolution>

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-15 | Initial naming conventions standard with comprehensive artifact naming rules | 529 lines | HX-Infrastructure Team |
| 2.0 | 2025-11-20 | Converted to semantic XML structure matching HX-Infrastructure documentation standards | No line change | HX-Infrastructure Team |
| 2.1 | 2025-11-21 | Added comprehensive metadata, infrastructure integration, procedure alignment, related documents, version history table | +83 lines | Agent Zero (CC) |

**Key Updates in v2.1:**
- Added comprehensive document metadata header (Type, Version, Date, Status, Location)
- Added infrastructure integration section (infrastructure-agnostic naming philosophy)
- Added procedure alignment section (naming enforcement across all 6 phases)
- Added related documents section (standards, procedures, templates, commands)
- Added version history table (this table)
- Updated semantic XML metadata tags
- Maintained 100% backward compatibility with v2.0

**Backward Compatibility:** 100% - All v2.0 naming rules unchanged, only documentation enhancements added

---

## Document Maintenance

**Document Type:** Standard - Operational Naming Conventions
**Status:** APPROVED - Mandatory for All Artifacts
**Maintained By:** HX-Infrastructure Team
**Review Frequency:** Annual (or when new artifact types introduced)
**Last Review:** 2025-11-21
**Next Review:** 2026-11-21

**Update Triggers:**
- New artifact types requiring naming standards
- Organizational changes affecting naming patterns
- Tool integration requiring naming adjustments
- Consistency issues identified in audits
- Procedure updates requiring naming changes

**Compliance Enforcement:**
- doc-lint utility validates naming compliance
- Code review process checks naming standards
- Regular repository audits identify non-compliance
- Migration plan required for any naming rule changes

---

<metadata_footer>
**Version:** 2.1
**Status:** APPROVED - Mandatory for All Artifacts
**Date:** 2025-11-21
**Last Updated:** 2025-11-21 (Comprehensive metadata and integration documentation)
**Compliance:** All artifacts MUST follow these naming conventions. Non-compliant names will be rejected during code review.
**Next Steps:** Consult this document before creating any new artifacts. Use the quick reference table for common naming patterns.
**Review Cycle:** Annual review and update based on repository evolution and lessons learned
**Semantic XML Compliance:** Fully converted to semantic XML structure matching HX-Infrastructure documentation standards
**Infrastructure Philosophy:** Naming conventions are infrastructure-agnostic by design. Deployment philosophy documented in spec.md/plan.md, not in artifact names.
**Procedure Integration:** Enforced across all 6 lifecycle phases (0-5) via procedures and Claude Code commands
</metadata_footer>

---

**End of Naming Conventions Standards**

*This standard defines mandatory naming conventions for all HX-Infrastructure artifacts. Naming rules are infrastructure-agnostic and enforced throughout the 6-phase project lifecycle via procedures, templates, and automated validation. All artifact creation must consult this document to ensure compliance and consistency.*
