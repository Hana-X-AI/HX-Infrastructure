---
document: cc-util-artifact-tracker
version: 1.2
date: 2025-11-24
status: APPROVED
type: utility-command
description: Artifact tracking utility for centralized registry of project deliverables with version control, relationship mapping, status tracking, and compliance validation
applies_to: all_workflows, all_orchestrations, artifact_management, deliverable_tracking, compliance_verification
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Artifact Tracking Utility - Centralized Deliverable Registry
**Version:** 1.2
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide centralized artifact registry tracking all project deliverables with version control, status management, relationship mapping, ownership accountability, and compliance validation throughout project lifecycle
</metadata>

<objective>
**Purpose:** Establish systematic artifact tracking that provides single source of truth for all project deliverables, enables artifact discovery and traceability, supports version control and relationship management, ensures artifact compliance, and facilitates knowledge preservation.

**Utility Capabilities:**
- Register and catalog all project artifacts with comprehensive metadata
- Track artifact status through lifecycle (Draft → Review → Approved → Deprecated)
- Manage artifact versions with change history and lineage tracking
- Map artifact relationships, dependencies, and derivations
- Track artifact ownership and accountability
- Validate artifact compliance with standards and requirements
- Generate artifact catalogs, inventories, and reports
- Support cross-workflow artifact continuity and discovery
- Enable artifact search and retrieval
- Provide artifact dashboard for project visibility

**When to Use This Utility:**
- When creating any project deliverable (document, code, config, diagram)
- When updating existing artifacts requiring version tracking
- When validating artifact compliance before phase transitions
- During project status reviews requiring artifact inventory
- When generating project closeout artifact summary
- When searching for existing artifacts to reuse or reference
- During retrospectives analyzing artifact management effectiveness
- Anytime artifact registration, tracking, or discovery needed
</objective>

<utility_overview>
**Core Function:**
This utility provides centralized artifact registry by capturing artifact metadata (type, purpose, location, owner, status), tracking versions and changes, mapping relationships between artifacts, validating compliance with standards, and generating catalogs for discovery and reporting.

**Artifact Management Process:**
1. **Register Artifact** - Capture new artifact with comprehensive metadata
2. **Assign Metadata** - Type, purpose, owner, status, location, tags
3. **Track Versions** - Document versions, changes, and lineage
4. **Map Relationships** - Identify dependencies, derivations, references
5. **Update Status** - Monitor status transitions through lifecycle
6. **Validate Compliance** - Check artifact meets standards and requirements
7. **Generate Catalog** - Create searchable artifact inventory
8. **Enable Discovery** - Support artifact search and retrieval

**Key Principle:** Centralized artifact registry prevents duplication, enables reuse, supports compliance verification, and preserves project knowledge.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-artifact-tracker.md file contains instructions and templates only.

**State artifacts** are created by following these instructions:
- **Artifact Registry:** `/projects/{project-name}/artifacts/registry.md` (persistent, primary artifact)
- **Artifact Catalog:** `/projects/{project-name}/artifacts/catalog.md` (persistent, searchable index)
- **Version History:** `/projects/{project-name}/artifacts/versions/{artifact-id}-history.md` (per artifact)
- **Compliance Reports:** `/projects/{project-name}/artifacts/compliance/compliance-report-YYYYMMDD.md` (periodic)
- **Artifact Dashboard:** `/projects/{project-name}/artifacts/dashboard.md` (persistent, updated)

These state artifacts are:
- Created during first artifact registration
- Updated/appended throughout project lifecycle
- Persistent across sessions
- Project-specific (one artifact registry per project)

**Distinction:**
- **Utility** = Stateless instructions + templates (this document)
- **Artifacts** = Stateful files created per project (registry, catalog, versions, compliance, dashboard)

**Registry Evolution:**
The artifact registry grows throughout project:
- Charter phase: Charter document registered
- Spec phase: Specification, ADRs, technical designs registered
- Task phase: Task breakdown, test suite index registered
- Execution phase: Code, configs, deployment artifacts registered
- Closeout phase: Final artifacts registered, complete inventory generated

This evolution provides complete artifact traceability and supports knowledge preservation.
</state_management>

<artifact_types>
**Artifact Type Taxonomy:**

**Documentation Artifacts:**
- **Charter Documents:** Project charters, charter questions, charter reviews
- **Specifications:** Technical specifications, requirements documents, design specs
- **Plans:** Test plans, deployment plans, migration plans, project plans
- **Reports:** Status reports, test reports, compliance reports, closeout reports
- **Procedures:** Runbooks, operational procedures, guidelines, standards
- **Reviews:** Review documents, feedback compilations, approval records

**Architecture Artifacts:**
- **ADRs:** Architecture Decision Records documenting significant decisions
- **Diagrams:** Architecture diagrams, component diagrams, deployment diagrams, sequence diagrams
- **Patterns:** Design patterns, architectural patterns, integration patterns
- **Models:** Data models, domain models, system models

**Code Artifacts:**
- **Source Code:** Application code, scripts, utilities, tools
- **Configuration Files:** YAML, JSON, INI, XML configuration files
- **Infrastructure as Code:** Ansible playbooks, Terraform configs, Docker files
- **Database Artifacts:** Schemas, migrations, seed data, queries

**Security Artifacts:**
- **Policies:** Security policies, access control policies, data policies
- **Procedures:** Security procedures, incident response procedures
- **Configurations:** Security configurations, firewall rules, access controls
- **Certificates:** SSL/TLS certificates, signing certificates, CA configurations

**Infrastructure Artifacts:**
- **Runbooks:** Operational runbooks, deployment runbooks, troubleshooting guides
- **Configurations:** Server configurations, service configurations, network configs
- **Systemd Service Units:** Service unit files, timer units, socket units, systemd configurations
- **Bare-Metal Deployment Artifacts:** Installation scripts, package lists, dependency manifests, deployment procedures
- **Manual Procedures:** Step-by-step deployment procedures, verification checklists, rollback procedures
- **Deployment Artifacts:** Deployment scripts, release packages, deployment configs
- **Monitoring:** Monitoring configurations, alert rules, dashboards, health check scripts

**Testing Artifacts:**
- **Test Plans:** Master test plans, test strategy documents
- **Test Suites:** Test suite indexes, test suite organizations
- **Test Cases:** Individual test case documents, test scenarios
- **Test Scripts:** Automated test scripts, test harnesses, test utilities
- **Test Results:** Test execution results, defect reports, validation records

**Process Artifacts:**
- **RAIDD Logs:** Risk, Assumption, Issue, Dependency, Decision logs
- **Quality Gates:** Quality gate validation reports, gate history
- **Context Documents:** Orchestration context documents, handoff packages
- **Handoff Documents:** Session handoffs, context preservation documents
</artifact_types>

<artifact_registry_structure>
**Registry Entry Format:**

Each artifact entry follows standardized structure:

```
ARTIFACT-{NUMBER}: {Artifact Name}
══════════════════════════════════════════════════════════════════════
Type: [Artifact Type]
ID: ARTIFACT-{NUMBER}
Status: [Draft|Review|Approved|Deprecated]
Version: X.Y
Date Registered: YYYY-MM-DD
Last Updated: YYYY-MM-DD
Owner: [Responsible party]
Related Workflow/Orchestration: [Where created]

DESCRIPTION:
[Purpose and contents of artifact]

LOCATION:
Primary: [File path or URL]
Backup: [Backup location if applicable]

METADATA:
Format: [File format - md, yaml, json, py, etc.]
Size: [File size]
Lines/Pages: [Content size metric]
Language: [Programming language if code]
Technology: [Technology stack if applicable]

RELATIONSHIPS:
Depends On: [List of prerequisite artifacts]
Derived From: [Source artifacts if derived]
Referenced By: [Artifacts that reference this one]
Related To: [Associated artifacts]

VERSIONS:
Current: X.Y
Previous: [List of previous versions]
Version History: [Path to detailed version history]

COMPLIANCE:
Standards: [List of applicable standards]
Requirements: [Requirements this artifact fulfills]
Validation Status: [Compliant|Non-compliant|Pending]
Last Validated: YYYY-MM-DD

TAGS: [tag1], [tag2], [tag3]
```

**Status Lifecycle:**

**Draft:**
- Artifact created and in development
- Content incomplete or undergoing changes
- Not ready for formal review
- Owner: Author/creator

**Review:**
- Artifact complete and ready for review
- Undergoing peer review, technical review, or stakeholder review
- Feedback being incorporated
- Owner: Reviewers + author

**Approved:**
- Artifact reviewed and approved
- Ready for use in project
- Considered authoritative and current
- Owner: Project/domain owner

**Deprecated:**
- Artifact superseded by newer version or no longer applicable
- Retained for historical reference
- Not to be used for new work
- Owner: Project/domain owner

**File Organization:**
```
/projects/{project-name}/
  artifacts/
    registry.md                          ← Master artifact registry
    catalog.md                           ← Searchable artifact catalog
    dashboard.md                         ← Current artifact status
    versions/
      ARTIFACT-001-history.md           ← Version history per artifact
      ARTIFACT-002-history.md
      ...
    compliance/
      compliance-report-20251120.md     ← Periodic compliance reports
      compliance-summary-closeout.md    ← Final compliance summary
```
</artifact_registry_structure>

<management_procedures>
  <procedure name="Register New Artifact">
  **Purpose:** Capture new artifact in centralized registry
  
  **Registration Process:**
  
  1. **Assign Artifact ID**
     - Format: ARTIFACT-{NUMBER}
     - Sequential numbering (ARTIFACT-001, ARTIFACT-002, etc.)
     - Project-specific numbering
  
  2. **Determine Artifact Type**
     - Select from artifact type taxonomy
     - Documentation, Architecture, Code, Security, Infrastructure, Testing, or Process
     - Sub-type if applicable (e.g., Documentation > Charter)
  
  3. **Complete Artifact Metadata**
     - Name: Clear, descriptive artifact name
     - Type: Artifact type and sub-type
     - Status: Initial status (typically Draft)
     - Version: 1.0 for new artifacts
     - Date registered: Current date
     - Owner: Responsible party
     - Related workflow/orchestration: Context where created
  
  4. **Write Description**
     - Purpose: Why artifact exists
     - Contents: What artifact contains
     - Audience: Who uses artifact
     - Scope: Boundaries of artifact coverage
  
  5. **Document Location**
     - Primary location: File path or URL
     - Backup location: If applicable
     - Access requirements: Permissions or credentials needed
  
  6. **Capture Technical Metadata**
     - Format: File format (md, yaml, json, py, etc.)
     - Size: File size in appropriate units
     - Lines/pages: Content size metric
     - Language: Programming language if code artifact
     - Technology: Technology stack if applicable
  
  7. **Map Relationships**
     - Depends on: Prerequisite artifacts required
     - Derived from: Source artifacts if derived
     - Referenced by: Initially empty, populated as references discovered
     - Related to: Associated artifacts
  
  8. **Initialize Version Information**
     - Current version: 1.0
     - Create version history file
     - Document initial version entry
  
  9. **Document Compliance Requirements**
     - Applicable standards: List standards artifact must meet
     - Requirements fulfilled: Requirements artifact addresses
     - Initial validation status: Pending
  
  10. **Apply Tags**
      - Domain tags: security, architecture, infrastructure, testing
      - Phase tags: charter, spec, task, execution, closeout
      - Workflow tags: charter-workflow, orchestrate-alex, etc.
      - Custom tags: As needed for organization
  
  11. **Add to Registry**
      - Append entry to `/projects/{project-name}/artifacts/registry.md`
      - Update artifact catalog with searchable entry
      - Update artifact dashboard with new artifact
  
  **Outputs:**
  - Artifact registry entry
  - Version history file initialized
  - Updated artifact catalog
  - Updated artifact dashboard
  </procedure>

  <procedure name="Update Artifact Status">
  **Purpose:** Track artifact status transitions through lifecycle
  
  **Status Update Process:**
  
  1. **Locate Artifact Entry**
     - Find artifact by ID in registry
     - Verify current status
  
  2. **Determine New Status**
     - Valid transitions:
       - Draft → Review (artifact complete, ready for review)
       - Review → Draft (feedback requires changes)
       - Review → Approved (review successful, artifact approved)
       - Approved → Deprecated (superseded or no longer applicable)
     - Ensure status transition is logical
  
  3. **Document Status Change**
     - Update Status field in registry entry
     - Update Last Updated date
     - Add version history entry documenting status change
  
  4. **Update Status-Specific Information**
     - Review status: Add reviewer names, review dates, feedback location
     - Approved status: Add approval date, approver names, approval conditions
     - Deprecated status: Add deprecation reason, superseding artifact reference
  
  5. **Notify Stakeholders**
     - Inform artifact owner of status change
     - Notify reviewers if moving to Review status
     - Alert users if moving to Deprecated status
  
  6. **Update Related Artifacts**
     - If artifact deprecated, update artifacts referencing it
     - If artifact approved, update artifacts depending on it
  
  7. **Update Dashboard**
     - Reflect new status in artifact dashboard
     - Update status counts and metrics
  
  **Outputs:**
  - Updated artifact registry entry
  - Version history entry documenting status change
  - Updated artifact dashboard
  - Stakeholder notifications
  </procedure>

  <procedure name="Track Artifact Versions">
  **Purpose:** Manage artifact versions with complete change history
  
  **Version Tracking Process:**
  
  1. **Determine Version Change Type**
     - Major version (X.0): Significant changes, breaking changes, complete rewrites
     - Minor version (X.Y): Additions, enhancements, non-breaking changes
     - Patch version (X.Y.Z): Bug fixes, corrections, clarifications (if using semantic versioning)
  
  2. **Assign New Version Number**
     - Major: Increment X, reset Y (and Z) to 0
     - Minor: Increment Y, reset Z to 0
     - Patch: Increment Z
     - Example: 1.0 → 1.1 (minor), 1.9 → 2.0 (major)
  
  3. **Document Version Changes**
     - What changed: Specific modifications made
     - Why changed: Reason for changes
     - Impact: How changes affect artifact users
     - Backward compatibility: If applicable
  
  4. **Update Registry Entry**
     - Update Version field
     - Update Last Updated date
     - Add previous version to Previous versions list
  
  5. **Update Version History File**
     - Add detailed version entry to `/projects/{project-name}/artifacts/versions/ARTIFACT-{NUMBER}-history.md`
     - Include: Version number, date, author, changes, rationale
  
  6. **Update Dependent Artifacts**
     - Identify artifacts depending on this artifact
     - Notify owners of dependent artifacts
     - Update dependency references if needed
  
  7. **Archive Previous Version**
     - Retain previous version for historical reference
     - Document archival location
     - Maintain traceability to previous versions
  
  **Version History Entry Format:**
  ```
  VERSION X.Y
  ══════════════════════════════════════════════════════════════════════
  Date: YYYY-MM-DD
  Author: [Who made changes]
  Version Type: [Major|Minor|Patch]
  Status: [Draft|Review|Approved]
  
  CHANGES:
  - [Specific change 1]
  - [Specific change 2]
  - [Specific change 3]
  
  RATIONALE:
  [Why changes were made]
  
  IMPACT:
  [How changes affect artifact users]
  
  BACKWARD COMPATIBILITY:
  [Yes|No|Partial - Explanation]
  
  RELATED ARTIFACTS UPDATED:
  - [ARTIFACT-XXX updated due to this change]
  - [ARTIFACT-YYY notified of changes]
  ```
  
  **Outputs:**
  - Updated artifact registry entry with new version
  - Detailed version history entry
  - Updated dependent artifacts (if applicable)
  - Archived previous version
  </procedure>

  <procedure name="Map Artifact Relationships">
  **Purpose:** Document dependencies and relationships between artifacts
  
  **Relationship Mapping Process:**
  
  1. **Identify Relationship Type**
     - **Depends On:** This artifact requires another artifact to exist/be complete
     - **Derived From:** This artifact created from another artifact
     - **Referenced By:** Other artifacts reference this artifact
     - **Related To:** Associated artifacts (same domain, related purpose)
  
  2. **Document Relationship**
     - Source artifact: The artifact being mapped
     - Target artifact: The related artifact
     - Relationship type: From above list
     - Relationship nature: Explanation of relationship
  
  3. **Update Source Artifact Entry**
     - Add relationship to appropriate section (Depends On, Derived From, Related To)
     - Include artifact ID and name
     - Document relationship nature
  
  4. **Update Target Artifact Entry**
     - Add reciprocal relationship (Referenced By if source Depends On target)
     - Maintain bidirectional traceability
  
  5. **Validate Relationship**
     - Ensure both artifacts exist in registry
     - Verify relationship is logical
     - Check for circular dependencies (flag but don't prevent)
  
  6. **Update Relationship Map**
     - Maintain visual or structured relationship map
     - Support dependency analysis
     - Enable impact analysis for changes
  
  7. **Generate Dependency Report**
     - Show dependency chains
     - Identify artifacts with many dependents (critical artifacts)
     - Identify artifacts with many dependencies (complex artifacts)
  
  **Relationship Examples:**
  
  **Depends On:**
  - Test Case (ARTIFACT-025) depends on Test Plan (ARTIFACT-020)
  - Deployment Script (ARTIFACT-040) depends on Configuration File (ARTIFACT-038)
  - ADR (ARTIFACT-015) depends on Architecture Diagram (ARTIFACT-012)
  
  **Derived From:**
  - Test Suite (ARTIFACT-030) derived from Task Breakdown (ARTIFACT-018)
  - Deployment Config (ARTIFACT-042) derived from Architecture Design (ARTIFACT-010)
  - Security Procedure (ARTIFACT-050) derived from Security Policy (ARTIFACT-048)
  
  **Referenced By:**
  - Charter (ARTIFACT-001) referenced by Specification (ARTIFACT-005)
  - ADR (ARTIFACT-015) referenced by Implementation Code (ARTIFACT-035)
  
  **Related To:**
  - Test Plan (ARTIFACT-020) related to Test Strategy (ARTIFACT-019)
  - Security Policy (ARTIFACT-048) related to Compliance Report (ARTIFACT-052)
  
  **Outputs:**
  - Updated artifact registry entries with relationships
  - Bidirectional relationship traceability
  - Relationship map or dependency graph
  - Dependency analysis report
  </procedure>

  <procedure name="Validate Artifact Compliance">
  **Purpose:** Verify artifact meets standards and requirements
  
  **Compliance Validation Process:**
  
  1. **Identify Applicable Standards**
     - Documentation standards (if documentation artifact)
     - Coding standards (if code artifact)
     - Security standards (if security artifact)
     - Architecture standards (if architecture artifact)
     - Testing standards (if testing artifact)
  
  2. **Identify Requirements Fulfilled**
     - Which project requirements does artifact address?
     - Which quality requirements must artifact meet?
     - Which compliance requirements are applicable?
  
  3. **Execute Compliance Checks**
     - **Documentation artifacts:**
       - Structure: Required sections present
       - Content: Sufficient detail and clarity
       - Format: Markdown/YAML/JSON formatting correct
       - Metadata: Complete and accurate
     
     - **Code artifacts:**
       - Style: Follows coding standards
       - Documentation: Comments and docstrings present
       - Testing: Tests provided and passing
       - Security: No obvious vulnerabilities
     
     - **Architecture artifacts:**
       - Completeness: All required elements present
       - Rationale: Decisions explained with rationale
       - Alternatives: Alternatives considered and documented
       - Traceability: Linked to requirements
     
     - **Testing artifacts:**
       - Coverage: Adequate test coverage
       - Traceability: Tests linked to requirements
       - Automation: Automated where appropriate
       - Results: Test results documented
  
  4. **Document Compliance Status**
     - **Compliant:** Artifact meets all applicable standards and requirements
     - **Non-compliant:** Artifact fails one or more checks
     - **Pending:** Artifact awaiting validation
  
  5. **Generate Compliance Report**
     - Standards checked
     - Requirements verified
     - Compliance status per standard/requirement
     - Non-compliance issues identified
     - Remediation guidance for non-compliant items
  
  6. **Update Registry Entry**
     - Update Compliance > Validation Status
     - Update Compliance > Last Validated date
     - Reference compliance report
  
  7. **Track Compliance Metrics**
     - Percentage of artifacts compliant
     - Most common non-compliance issues
     - Compliance trends over time
  
  **Compliance Report Format:**
  ```
  ARTIFACT COMPLIANCE REPORT - ARTIFACT-{NUMBER}
  ══════════════════════════════════════════════════════════════════════
  Artifact: [Name]
  Type: [Type]
  Validation Date: YYYY-MM-DD
  Validator: [Who validated]
  
  APPLICABLE STANDARDS:
  1. [Standard name] - [Compliant|Non-compliant]
  2. [Standard name] - [Compliant|Non-compliant]
  
  REQUIREMENTS FULFILLED:
  1. [Requirement ID] - [Verified|Not verified]
  2. [Requirement ID] - [Verified|Not verified]
  
  OVERALL COMPLIANCE STATUS: [Compliant|Non-compliant|Pending]
  
  NON-COMPLIANCE ISSUES (if any):
  1. Issue: [Description]
     Standard: [Which standard violated]
     Severity: [High|Medium|Low]
     Remediation: [How to fix]
  
  RECOMMENDATIONS:
  [Recommendations for improvement]
  ```
  
  **Outputs:**
  - Compliance validation report
  - Updated registry entry with compliance status
  - Remediation guidance for non-compliant artifacts
  - Compliance metrics update
  </procedure>

  <procedure name="Generate Artifact Catalog">
  **Purpose:** Create searchable artifact inventory for discovery
  
  **Catalog Generation Process:**
  
  1. **Query Artifact Registry**
     - Extract all artifact entries
     - Filter by criteria if needed (status, type, phase, etc.)
  
  2. **Organize by Categories**
     - By type: Group documentation, architecture, code, etc.
     - By status: Group draft, review, approved, deprecated
     - By phase: Group charter, spec, task, execution, closeout
     - By workflow: Group by related workflow/orchestration
  
  3. **Create Catalog Entries**
     For each artifact:
     - Artifact ID and name
     - Type and status
     - Owner
     - Location (path/URL)
     - Brief description
     - Tags
  
  4. **Generate Catalog Indexes**
     - Alphabetical index by artifact name
     - Index by type
     - Index by owner
     - Index by tag
  
  5. **Add Search Functionality**
     - Support search by name, type, owner, tag
     - Enable filtering by status, phase, workflow
     - Provide quick reference to artifact locations
  
  6. **Format Catalog**
     - Use consistent, scannable format
     - Include table of contents
     - Provide cross-references
     - Maintain catalog at `/projects/{project-name}/artifacts/catalog.md`
  
  7. **Update Catalog Regularly**
     - Regenerate after each artifact registration
     - Ensure catalog stays current with registry
  
  **Catalog Entry Format:**
  ```
  ARTIFACT-{NUMBER}: {Artifact Name}
  Type: [Type] | Status: [Status] | Owner: [Owner]
  Location: [Path]
  Description: [Brief description]
  Tags: [tag1, tag2, tag3]
  ```
  
  **Catalog Structure:**
  ```
  PROJECT ARTIFACT CATALOG
  ══════════════════════════════════════════════════════════════════════
  Project: [Project Name]
  Last Updated: YYYY-MM-DD
  Total Artifacts: X
  
  SUMMARY BY TYPE:
  - Documentation: X artifacts
  - Architecture: Y artifacts
  - Code: Z artifacts
  - Security: A artifacts
  - Infrastructure: B artifacts
  - Testing: C artifacts
  - Process: D artifacts
  
  SUMMARY BY STATUS:
  - Draft: X artifacts
  - Review: Y artifacts
  - Approved: Z artifacts
  - Deprecated: A artifacts
  
  ARTIFACTS BY TYPE:
  
  DOCUMENTATION ARTIFACTS:
  [List of documentation artifacts]
  
  ARCHITECTURE ARTIFACTS:
  [List of architecture artifacts]
  
  [Continue for all types]
  
  ALPHABETICAL INDEX:
  [A-Z index of all artifacts]
  
  TAG INDEX:
  [Index organized by tags]
  ```
  
  **Outputs:**
  - Complete artifact catalog
  - Searchable artifact index
  - Category and tag organization
  - Discovery-enabled artifact inventory
  </procedure>
</management_procedures>

<integration_with_workflows>
**Workflow Integration Points:**

Artifact tracking integrates throughout project lifecycle:

**Charter Workflow:**
- Phase 2 (Draft): Register charter document (ARTIFACT-001)
- Phase 3 (Review): Update charter status to Review, then Approved
- Phase 4 (Approval): Register charter approval record

**Spec Workflow:**
- Phase 1 (Context): Register specification context document
- Phase 2 (Draft): Register specification document, register ADRs
- Phase 3 (Review): Update spec status, register review feedback
- Phase 4 (Approval): Update spec status to Approved, register approval

**Task Workflow:**
- Phase 1 (Breakdown): Register task breakdown document
- Phase 2 (Estimation): Update task breakdown with estimates
- Phase 3 (Approval): Register test suite index, update status

**Execution Workflow:**
- Phase 1 (Readiness): Verify prerequisite artifacts approved
- Phase 2 (Work): Register code artifacts, configuration files, deployment scripts
- Phase 3 (Validation): Register test results, validation reports
- Phase 4 (Integration): Register deployment artifacts, update all artifacts to Approved

**Closeout Workflow:**
- Phase 1 (Verification): Validate all artifacts compliant
- Phase 2 (Documentation): Generate complete artifact catalog
- Phase 3 (Learning): Register lessons learned document
- Phase 4 (Formal Closeout): Generate artifact summary for closeout

**Orchestration Integration:**
Artifact tracking also integrates with Set 2 orchestrations:
- Alex: Register ADRs, architecture diagrams, design documents
- Frank: Register security policies, procedures, configurations
- William: Register runbooks, deployment configs, infrastructure artifacts
- Julia: Register test plans, test cases, test results
- Multi-agent: Track artifacts from multiple specialists, map cross-domain relationships
</integration_with_workflows>

<integration_convention>
**How Commands Invoke This Utility:**

This section documents how workflow commands (Set 1) and orchestration commands (Set 2) invoke the artifact tracker utility. Invocation uses instructional reference pattern with explicit artifact metadata.

**From Workflow Commands (Set 1):**
Throughout workflow phases, commands invoke artifact tracker with instructional reference:

**Example from cc-charter-workflow.md Phase 2:**
"Use cc-util-artifact-tracker to register charter document. Create entry:
- Type: Documentation > Charter
- Name: [Project Name] Charter v1.0
- Status: Draft
- Location: /projects/{project-name}/charter/charter-v1.0.md
- Owner: Agent Zero
- Related Workflow: charter-workflow

Update artifact dashboard showing new charter artifact."

**Example from cc-task-execution-workflow.md Phase 2:**
"Use cc-util-artifact-tracker to register deployment artifacts. Create entries:
- ARTIFACT-035: Deployment script (Code artifact)
- ARTIFACT-036: Configuration file (Code artifact)
- ARTIFACT-037: Database migration (Code artifact)

Map relationships:
- ARTIFACT-036 depends on ARTIFACT-015 (Architecture design)
- ARTIFACT-035 depends on ARTIFACT-036 (Config required)
- ARTIFACT-037 depends on ARTIFACT-030 (Test suite)

Validate compliance with coding standards."

**Example from cc-closeout-workflow.md Phase 2:**
"Use cc-util-artifact-tracker to generate complete artifact catalog for
project documentation. Include all artifacts by type, status summary,
relationship map, compliance report. Export catalog to closeout package."

**From Orchestration Commands (Set 2):**
Orchestrations invoke artifact tracker to register specialist deliverables:

**Example from cc-orchestrate-alex.md Phase 5:**
"Use cc-util-artifact-tracker to register Alex's architecture deliverables:
- ARTIFACT-012: System architecture diagram
- ARTIFACT-013: Component interaction diagram  
- ARTIFACT-014: ADR-001 - OAuth 2.0 selection decision
- ARTIFACT-015: API specification

Map relationships: All ADRs reference architecture diagrams.
Validate ADRs comply with architecture standards."

**Required Inputs:**
1. **Artifact Name** - Clear, descriptive name
2. **Artifact Type** - From artifact type taxonomy
3. **Status** - Initial or updated status (Draft/Review/Approved/Deprecated)
4. **Location** - File path or URL to artifact
5. **Owner** - Responsible party
6. **Description** - Purpose and contents summary
7. **Related Workflow/Orchestration** - Context where created
8. **Version** - Version number (1.0 for new, incremented for updates)
9. **Relationships** - Dependencies, derivations, references (if applicable)
10. **Tags** - Domain, phase, workflow tags for organization
11. **Project Name** - For file organization

**Expected Outputs:**

1. **Artifact Registry Entry** (Primary Output)
   - Format: Structured markdown with comprehensive metadata
   - Location: `/projects/{project-name}/artifacts/registry.md` (appended)
   - Contents: Full artifact entry with metadata, location, relationships, compliance

2. **Artifact Catalog Entry** (Searchable Index)
   - Format: Concise catalog entry for discovery
   - Location: `/projects/{project-name}/artifacts/catalog.md` (updated)
   - Contents: ID, name, type, status, owner, location, brief description, tags

3. **Version History File** (Per-Artifact Tracking)
   - Format: Detailed change history
   - Location: `/projects/{project-name}/artifacts/versions/ARTIFACT-{NUMBER}-history.md`
   - Contents: Version entries with changes, rationale, impact, compatibility

4. **Compliance Report** (Validation Output)
   - Format: Structured validation report
   - Location: `/projects/{project-name}/artifacts/compliance/compliance-report-YYYYMMDD.md`
   - Contents: Standards checked, requirements verified, compliance status, remediation

5. **Artifact Dashboard** (Status Overview)
   - Format: Real-time dashboard with metrics
   - Location: `/projects/{project-name}/artifacts/dashboard.md` (updated)
   - Contents: Summary metrics, status breakdown, recent activity, compliance overview

**State Management:**

**Stateless Component:**
- cc-util-artifact-tracker.md utility file (this document)
- Instructions for artifact management procedures
- Artifact type taxonomy and templates
- No state maintained in utility itself

**Stateful Artifacts:**
- Artifact registry: `/projects/{project-name}/artifacts/registry.md` (master registry, appended)
- Artifact catalog: `/projects/{project-name}/artifacts/catalog.md` (searchable index, updated)
- Version histories: `/projects/{project-name}/artifacts/versions/` (per-artifact change history)
- Compliance reports: `/projects/{project-name}/artifacts/compliance/` (validation reports)
- Artifact dashboard: `/projects/{project-name}/artifacts/dashboard.md` (current status, updated)
- Created/updated by following utility procedures
- Persistent across sessions
- Project-specific

**File Organization:**
```
/projects/{project-name}/
  artifacts/
    registry.md                          ← Master artifact registry
    catalog.md                           ← Searchable artifact catalog
    dashboard.md                         ← Current artifact status
    versions/
      ARTIFACT-001-history.md           ← Version histories
      ARTIFACT-002-history.md
      ...
    compliance/
      compliance-report-20251120.md     ← Compliance reports
      compliance-summary-closeout.md
```

**Invocation Pattern Summary:**
1. Caller creates/updates artifact needing registration/tracking
2. Caller references cc-util-artifact-tracker with artifact metadata
3. Artifact entry created/updated in project registry
4. Catalog updated for discovery
5. Version history tracked (if version change)
6. Compliance validated (if requested)
7. Dashboard updated to reflect changes
8. Artifact visibility maintained throughout project lifecycle
</integration_convention>

<usage_examples>
  <example name="Register Charter Document">
  **Scenario:** Registering charter document after Phase 2 draft complete
  
  **Command:**
  ```
  Register artifact:
  - Project: auth-system
  - Name: Authentication System Charter v1.0
  - Type: Documentation > Charter
  - Status: Draft
  - Location: /projects/auth-system/charter/charter-v1.0.md
  - Owner: Agent Zero
  ```
  
  **Utility Process:**
  1. Assign ID: ARTIFACT-001
  2. Capture metadata (type, status, version, owner, date)
  3. Document location and description
  4. Initialize version history (v1.0 initial)
  5. Set compliance requirements (documentation standards)
  6. Apply tags (charter, documentation, phase-1)
  7. Add to registry and catalog
  8. Update dashboard
  
  **Output:**
  ```
  ARTIFACT-001: Authentication System Charter v1.0
  Type: Documentation > Charter
  Status: Draft
  Version: 1.0
  Date Registered: 2025-11-20
  Owner: Agent Zero
  Related Workflow: charter-workflow
  
  DESCRIPTION:
  Project charter defining authentication system objectives, scope,
  stakeholders, constraints, and success criteria. Addresses OAuth 2.0
  implementation with Active Directory integration.
  
  LOCATION:
  Primary: /projects/auth-system/charter/charter-v1.0.md
  
  METADATA:
  Format: Markdown
  Size: 15 KB
  Lines: 450
  
  RELATIONSHIPS:
  Depends On: None (first artifact)
  Derived From: None
  Referenced By: [Will be populated as references created]
  Related To: None yet
  
  VERSIONS:
  Current: 1.0
  Version History: /projects/auth-system/artifacts/versions/ARTIFACT-001-history.md
  
  COMPLIANCE:
  Standards: Documentation standards, charter template requirements
  Validation Status: Pending
  
  TAGS: charter, documentation, phase-1, auth-system
  ```
  </example>

  <example name="Update Artifact Status">
  **Scenario:** Moving charter from Draft to Review after completion
  
  **Command:**
  ```
  Update artifact status:
  - Artifact: ARTIFACT-001
  - Current Status: Draft
  - New Status: Review
  - Reviewers: Stakeholder team
  ```
  
  **Utility Process:**
  1. Locate ARTIFACT-001 in registry
  2. Validate status transition (Draft → Review is valid)
  3. Update Status field to Review
  4. Update Last Updated date
  5. Add version history entry documenting status change
  6. Notify reviewers
  7. Update dashboard
  
  **Output:**
  ```
  ARTIFACT-001: Authentication System Charter v1.0
  Status: Review ← UPDATED
  Last Updated: 2025-11-21 ← UPDATED
  
  VERSION HISTORY ENTRY:
  2025-11-21 - Status: Draft → Review - Charter complete, sent for stakeholder
  review. Review period: 2025-11-21 to 2025-11-23. Reviewers: Product Owner,
  Security Lead, Infrastructure Lead. - Agent Zero
  ```
  </example>

  <example name="Track Artifact Version">
  **Scenario:** Charter updated after review feedback, new version created
  
  **Command:**
  ```
  Update artifact version:
  - Artifact: ARTIFACT-001
  - Current Version: 1.0
  - New Version: 1.1 (minor - incorporated review feedback)
  - Changes: Added stakeholder concerns section, clarified scope boundaries
  ```
  
  **Utility Process:**
  1. Locate ARTIFACT-001 in registry
  2. Increment version: 1.0 → 1.1
  3. Update Version field
  4. Add 1.0 to Previous versions list
  5. Create detailed version history entry
  6. Update Last Updated date
  7. Notify stakeholders of new version
  
  **Output:**
  ```
  ARTIFACT-001: Authentication System Charter v1.1
  Version: 1.1 ← UPDATED
  Previous: 1.0 ← ADDED
  Last Updated: 2025-11-22 ← UPDATED
  
  VERSION HISTORY ENTRY (v1.1):
  ══════════════════════════════════════════════════════════════════════
  Date: 2025-11-22
  Author: Agent Zero
  Version Type: Minor
  Status: Review
  
  CHANGES:
  - Added "Stakeholder Concerns" section addressing security team questions
  - Clarified scope boundaries excluding mobile app (Phase 2)
  - Updated timeline to reflect 2-week buffer for infrastructure setup
  
  RATIONALE:
  Incorporated feedback from stakeholder review cycle. Security team
  needed explicit statement of security requirements. Product owner
  requested clear scope exclusions to manage expectations.
  
  IMPACT:
  No impact on project approach. Changes are clarifications and additions.
  
  BACKWARD COMPATIBILITY:
  Yes - v1.1 is additive only, no conflicts with v1.0
  ```
  </example>

  <example name="Map Artifact Relationships">
  **Scenario:** Registering specification that depends on charter
  
  **Command:**
  ```
  Register artifact with relationships:
  - Name: Authentication System Specification v1.0
  - Type: Documentation > Specification
  - Depends On: ARTIFACT-001 (Charter)
  - Location: /projects/auth-system/spec/spec-v1.0.md
  ```
  
  **Utility Process:**
  1. Register new artifact (ARTIFACT-005)
  2. Document "Depends On: ARTIFACT-001" relationship
  3. Update ARTIFACT-001 with "Referenced By: ARTIFACT-005"
  4. Maintain bidirectional traceability
  5. Validate both artifacts exist
  6. Update relationship map
  
  **Output:**
  ```
  ARTIFACT-005: Authentication System Specification v1.0
  Type: Documentation > Specification
  
  RELATIONSHIPS:
  Depends On: ARTIFACT-001 (Charter) - Specification derived from charter
                requirements and scope
  
  ---
  
  ARTIFACT-001: Authentication System Charter v1.1
  [Updated entry]
  
  RELATIONSHIPS:
  Referenced By: ARTIFACT-005 (Specification) - Spec uses charter as foundation
  ```
  </example>

  <example name="Validate Artifact Compliance">
  **Scenario:** Validating ADR compliance with architecture standards
  
  **Command:**
  ```
  Validate artifact compliance:
  - Artifact: ARTIFACT-014 (ADR-001 OAuth 2.0 selection)
  - Type: Architecture > ADR
  - Standards: Architecture standards, ADR template requirements
  ```
  
  **Utility Process:**
  1. Identify applicable standards (architecture standards for ADRs)
  2. Execute compliance checks:
     - Required sections present (Context, Decision, Rationale, Consequences)
     - Alternatives considered and documented
     - Rationale clearly explained
     - Traceability to requirements present
  3. Document compliance status
  4. Generate compliance report
  5. Update registry entry
  
  **Output:**
  ```
  ARTIFACT COMPLIANCE REPORT - ARTIFACT-014
  ══════════════════════════════════════════════════════════════════════
  Artifact: ADR-001 OAuth 2.0 Selection Decision
  Type: Architecture > ADR
  Validation Date: 2025-11-22
  Validator: Agent Zero
  
  APPLICABLE STANDARDS:
  1. Architecture Standards (ADR template) - Compliant ✓
  2. Documentation Standards - Compliant ✓
  
  REQUIREMENTS FULFILLED:
  1. REQ-AUTH-001 (Authentication mechanism selection) - Verified ✓
  2. REQ-SEC-005 (Security standards compliance) - Verified ✓
  
  COMPLIANCE CHECKS:
  ✓ Required sections present (Context, Decision, Rationale, Consequences)
  ✓ Alternatives documented (SAML, Custom JWT, Session-based)
  ✓ Rationale clear and justified
  ✓ Traceability to requirements present
  ✓ Stakeholder consultation documented
  
  OVERALL COMPLIANCE STATUS: Compliant ✓
  
  RECOMMENDATIONS:
  None - ADR meets all architecture standards for decision documentation.
  ```
  </example>

  <example name="Generate Artifact Catalog">
  **Scenario:** Creating artifact catalog for project status review
  
  **Command:**
  ```
  Generate artifact catalog:
  - Project: auth-system
  - Include all artifacts
  - Organize by type and status
  ```
  
  **Utility Process:**
  1. Query registry for all artifacts
  2. Group by type (Documentation, Architecture, Code, etc.)
  3. Sub-group by status (Draft, Review, Approved, Deprecated)
  4. Create catalog entries with key metadata
  5. Generate indexes (alphabetical, by tag, by owner)
  6. Format catalog for readability
  7. Save to catalog.md
  
  **Output:**
  ```
  AUTHENTICATION SYSTEM - ARTIFACT CATALOG
  ══════════════════════════════════════════════════════════════════════
  Last Updated: 2025-11-22
  Total Artifacts: 15
  
  SUMMARY BY TYPE:
  - Documentation: 5 artifacts
  - Architecture: 4 artifacts
  - Code: 3 artifacts
  - Testing: 3 artifacts
  
  SUMMARY BY STATUS:
  - Approved: 8 artifacts
  - Review: 3 artifacts
  - Draft: 4 artifacts
  - Deprecated: 0 artifacts
  
  DOCUMENTATION ARTIFACTS (Approved):
  
  ARTIFACT-001: Authentication System Charter v1.1
  Owner: Agent Zero | Location: /projects/auth-system/charter/charter-v1.1.md
  Description: Project charter defining objectives, scope, stakeholders
  Tags: charter, documentation, approved
  
  ARTIFACT-005: Authentication System Specification v1.0
  Owner: Agent Zero | Location: /projects/auth-system/spec/spec-v1.0.md
  Description: Technical specification for OAuth 2.0 implementation
  Tags: specification, documentation, approved
  
  ARCHITECTURE ARTIFACTS (Approved):
  
  ARTIFACT-012: System Architecture Diagram
  Owner: Alex Rivera | Location: /projects/auth-system/architecture/system-arch.svg
  Description: High-level system architecture showing components and interactions
  Tags: architecture, diagram, alex, approved
  
  ARTIFACT-014: ADR-001 OAuth 2.0 Selection Decision
  Owner: Alex Rivera | Location: /projects/auth-system/adrs/ADR-001-oauth2.md
  Description: Architecture decision documenting OAuth 2.0 selection rationale
  Tags: architecture, adr, decision, alex, approved
  
  [Continue for all artifacts...]
  
  ALPHABETICAL INDEX:
  A: ADR-001 OAuth 2.0 Selection (ARTIFACT-014)
     Authentication System Charter (ARTIFACT-001)
     Authentication System Specification (ARTIFACT-005)
  ...
  
  TAG INDEX:
  approved: ARTIFACT-001, 005, 012, 014, ...
  architecture: ARTIFACT-012, 014, 015
  documentation: ARTIFACT-001, 005
  ...
  ```
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Register Immediately:** Register artifacts as soon as created. Delayed registration leads to lost artifacts and incomplete tracking.

2. ⚠️ **Complete Metadata:** Incomplete artifact metadata reduces discoverability. Always provide type, owner, location, description, tags.

3. ⚠️ **Track Relationships:** Documenting artifact dependencies enables impact analysis and traceability. Map relationships during registration.

4. ⚠️ **Version Consistently:** Use consistent versioning scheme (major.minor). Document what changed and why in version history.

5. ⚠️ **Validate Compliance:** Compliance validation prevents quality issues downstream. Validate artifacts before status transitions.

6. ⚠️ **Update Status:** Artifact status must reflect reality. Update status as artifacts progress through lifecycle.

7. ⚠️ **One Source of Truth:** Registry is authoritative. Don't create duplicate tracking systems. Use artifact tracker consistently.

8. ⚠️ **Deprecate Properly:** When artifacts superseded, mark as Deprecated with reason. Don't delete - maintain history.

9. ⚠️ **Catalog Searchability:** Tags and descriptions enable discovery. Apply meaningful tags for filtering and search.

10. ⚠️ **Cross-Reference:** Maintain bidirectional relationships (Depends On ↔ Referenced By). Enables complete traceability.

11. ⚠️ **Dashboard Visibility:** Keep dashboard current for stakeholder visibility. Stale dashboards lose credibility.

12. ⚠️ **Compliance Matters:** Non-compliant artifacts create technical debt. Address compliance issues before approval.
</critical_reminders>

<validation_checklist>
**Artifact Registration Checklist:**
- [ ] Artifact ID assigned (ARTIFACT-{NUMBER})
- [ ] Artifact type selected from taxonomy
- [ ] Clear, descriptive artifact name
- [ ] Initial status set (typically Draft)
- [ ] Version number assigned (1.0 for new)
- [ ] Owner identified and notified
- [ ] Related workflow/orchestration documented
- [ ] Description written (purpose, contents, audience)
- [ ] Location documented (primary path/URL)
- [ ] Technical metadata captured (format, size, language)
- [ ] Relationships mapped (dependencies, derivations)
- [ ] Version history file initialized
- [ ] Compliance requirements documented
- [ ] Tags applied (domain, phase, workflow)
- [ ] Registry entry created
- [ ] Catalog entry created
- [ ] Dashboard updated

**Status Update Checklist:**
- [ ] Current status verified
- [ ] New status is valid transition
- [ ] Status field updated in registry
- [ ] Last Updated date changed
- [ ] Version history entry added
- [ ] Status-specific information updated
- [ ] Related artifacts checked for impact
- [ ] Stakeholders notified
- [ ] Dashboard updated

**Version Tracking Checklist:**
- [ ] Version change type determined (major/minor)
- [ ] New version number assigned
- [ ] Changes documented (what/why/impact)
- [ ] Registry Version field updated
- [ ] Previous version added to list
- [ ] Detailed version history entry created
- [ ] Dependent artifacts identified
- [ ] Dependent artifact owners notified
- [ ] Previous version archived
- [ ] Backward compatibility assessed

**Compliance Validation Checklist:**
- [ ] Applicable standards identified
- [ ] Requirements fulfilled documented
- [ ] Compliance checks executed
- [ ] Compliance status determined
- [ ] Compliance report generated
- [ ] Non-compliance issues documented
- [ ] Remediation guidance provided
- [ ] Registry compliance status updated
- [ ] Compliance report saved
- [ ] Compliance metrics updated
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Spec artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Code artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-project-closeout-workflow.md` - Artifact catalog generation
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Architecture artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Security artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - Infrastructure artifact registration
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Testing artifact registration
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Documentation standards
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Architecture artifact standards
</related_documents>

<metadata_footer>
**Version:** 1.2
**Status:** APPROVED - Production Ready
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Compliance:** 100% semantic XML structure, comprehensive artifact tracking, standardized procedures
**Next Steps:** Use this utility throughout project lifecycle to register, track, and manage all project artifacts systematically
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**Artifact Coverage:** Complete artifact type taxonomy (7 categories including systemd units, bare-metal deployment artifacts, manual procedures), management procedures (6 procedures), integration with all workflows and orchestrations
**Infrastructure Philosophy:** Explicitly covers systemd service units, bare-metal deployment artifacts, manual procedures, aligning with HX-Infrastructure deployment philosophy
</metadata_footer>
