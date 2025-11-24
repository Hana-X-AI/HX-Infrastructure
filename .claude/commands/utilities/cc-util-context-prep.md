---
document: cc-util-context-prep
version: 1.2
date: 2025-11-24
status: APPROVED
type: utility-command
description: Context preparation utility for streamlining context document creation, validation, and handoff package generation for agent orchestration
applies_to: all_orchestrations, context_preparation, agent_handoffs, multi_agent_coordination
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-context-prep.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Context Preparation Utility - Orchestration Context Management
**Version:** 1.2
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Streamline context document preparation for agent orchestration (Set 2), providing templates, validation, cross-domain context management, and handoff package generation
</metadata>

<objective>
**Purpose:** Standardize and accelerate context preparation for agent orchestration by providing reusable templates, automated completeness validation, cross-domain context management, and structured handoff packages that enable effective specialist coordination.

**Utility Capabilities:**
- Generate context document templates for each specialist (Alex, Frank, William, Julia)
- Validate context completeness against orchestration-specific checklists
- Manage cross-domain context for multi-agent synthesis coordination
- Create structured handoff packages with proper formatting
- Track context versions and updates across orchestration iterations
- Ensure context continuity in sequential multi-agent coordination
- Support both single-agent and multi-agent orchestration contexts

**When to Use This Utility:**
- During Phase 2 (Context Preparation) of any orchestration workflow
- Before invoking specialist agents (Alex, Frank, William, Julia)
- When preparing multi-agent synthesis context spanning multiple domains
- When updating context for orchestration re-attempts or iterations
- During context validation before handoff to specialists
- When generating handoff packages for formal specialist engagement
</objective>

<utility_overview>
**Core Function:**
This utility accelerates context preparation by providing pre-structured templates containing all required context elements for each specialist, validating completeness before handoff, and generating properly formatted context packages.

**Context Preparation Process:**
1. **Select Template** - Choose appropriate context template (Alex/Frank/William/Julia/Multi-agent)
2. **Populate Context** - Fill template with task-specific information
3. **Validate Completeness** - Check all required context elements present
4. **Format Package** - Structure context into handoff-ready package
5. **Generate Documentation** - Create context summary and metadata
6. **Track Version** - Record context version for iteration tracking
7. **Prepare Handoff** - Package context for specialist delivery

**Key Principle:** Complete, well-structured context enables specialist autonomy. Incomplete context creates clarification cycles and delays.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-context-prep.md file contains instructions and templates only.

**State artifacts** are created by following these instructions:
- **Context Documents:** `/projects/{project-name}/orchestration/{specialist}-context.md` (persistent)
- **Validation Reports:** `/projects/{project-name}/orchestration/{specialist}-context-validation.md` (persistent)
- **Handoff Packages:** `/projects/{project-name}/orchestration/handoff-{specialist}.md` (persistent)
- **Version Log:** `/projects/{project-name}/orchestration/context-versions.md` (persistent)

These state artifacts are:
- Created during first context preparation
- Updated during context iterations and refinements
- Persistent across sessions
- Project-specific (separate orchestration directory per project)

**Distinction:**
- **Utility** = Stateless instructions + templates (this document)
- **Artifacts** = Stateful files created per project (context documents, validation reports, handoffs, versions)

**Version Tracking:**
Context documents evolve through orchestration iterations. Version log tracks:
- Version number (1.0, 1.1, 2.0...)
- Date and author of changes
- What changed (additions, clarifications, corrections)
- Completeness status at each version
- Specialist feedback incorporated

This version history improves future context preparation by showing what context elements required refinement.
</state_management>

<context_templates>
  <template name="Alex Context Template - Architecture Coordination">
  **Purpose:** Prepare context for architecture coordination with Alex (Platform Architect)
  
  **Required Context Elements:**
  
  1. **Architecture Requirements**
     - What architectural decisions, patterns, or designs are needed?
     - What architectural problems need solving?
     - What design constraints exist?
  
  2. **System Context**
     - Current system architecture state
     - Existing components and relationships
     - Technology stack and platform constraints
     - Integration points and interfaces
  
  3. **Architecture Scope**
     - What level of architecture (system/component/detail)?
     - What architectural artifacts needed (ADRs, diagrams, patterns)?
     - What architectural decisions require documentation?
  
  4. **Design Constraints**
     - Performance requirements
     - Scalability needs
     - Maintainability expectations
     - Technology restrictions or mandates
  
  5. **Stakeholder Considerations**
     - Who are the architectural stakeholders?
     - What are their architectural concerns?
     - What architectural trade-offs need stakeholder input?
  
  6. **Cross-Domain Context**
     - Security requirements affecting architecture (Frank's domain)
     - Infrastructure constraints affecting design (William's domain)
     - Testing requirements affecting architecture (Julia's domain)
  
  7. **Deliverable Expectations**
     - Expected architectural artifacts (ADRs, diagrams, patterns)
     - Documentation format and detail level
     - Timeline and milestone expectations
  
  8. **Reference Materials**
     - Related architectural documentation
     - Relevant architectural patterns library
     - Previous ADRs or design decisions
     - Architecture standards to follow
  
  **Template Structure:**
  ```
  ARCHITECTURE CONTEXT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Date: [YYYY-MM-DD]
  Prepared By: Agent Zero
  Target Specialist: Alex Rivera (Platform Architect)
  
  ARCHITECTURE REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  [What architectural decisions/patterns/designs needed]
  [What architectural problems need solving]
  [What design constraints exist]
  
  SYSTEM CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Current Architecture: [Describe current system architecture state]
  Existing Components: [List relevant components and relationships]
  Technology Stack: [Current technologies and platform]
  Integration Points: [Interfaces and external systems]
  
  ARCHITECTURE SCOPE:
  ──────────────────────────────────────────────────────────────────────
  Level: [System/Component/Detail]
  Artifacts Needed: [ADRs, diagrams, patterns, documentation]
  Decisions to Document: [Key architectural decisions requiring capture]
  
  DESIGN CONSTRAINTS:
  ──────────────────────────────────────────────────────────────────────
  Performance: [Response time, throughput, latency requirements]
  Scalability: [Growth expectations, load requirements]
  Maintainability: [Code quality, documentation, extensibility needs]
  Technology: [Restrictions, mandates, platform limitations]
  
  STAKEHOLDER CONSIDERATIONS:
  ──────────────────────────────────────────────────────────────────────
  Stakeholders: [Who needs to be consulted on architecture]
  Concerns: [Stakeholder architectural concerns]
  Trade-offs: [Architectural decisions requiring stakeholder input]
  
  CROSS-DOMAIN CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Security (Frank): [Security requirements affecting architecture]
  Infrastructure (William): [Infrastructure constraints affecting design]
  Testing (Julia): [Testing requirements affecting architecture]
  
  DELIVERABLE EXPECTATIONS:
  ──────────────────────────────────────────────────────────────────────
  Artifacts: [List expected deliverables]
  Format: [Documentation format and detail level]
  Timeline: [Expected completion date]
  Milestones: [Key checkpoints]
  
  REFERENCE MATERIALS:
  ──────────────────────────────────────────────────────────────────────
  - [Path to related architectural documentation]
  - [Path to relevant pattern library]
  - [Path to previous ADRs]
  - [Path to architecture standards]
  
  CONTEXT VERSION: 1.0
  LAST UPDATED: [YYYY-MM-DD HH:MM]
  ```
  </template>

  <template name="Frank Context Template - Security Coordination">
  **Purpose:** Prepare context for security coordination with Frank (Security Specialist)
  
  **Required Context Elements:**
  
  1. **Security Requirements**
     - What security controls, policies, or configurations needed?
     - What security threats or risks need addressing?
     - What security compliance requirements apply?
  
  2. **Security Context**
     - Current security posture and controls
     - Identity and access management state
     - DNS and certificate infrastructure status
     - Security zones and network boundaries
  
  3. **Security Scope**
     - What security domains involved (identity, DNS, certificates, access control)?
     - What security artifacts needed (policies, procedures, configs)?
     - What security decisions require documentation?
  
  4. **Threat Context**
     - Threat model and attack vectors
     - Risk assessment and severity
     - Compliance and regulatory requirements
  
  5. **Security Constraints**
     - Usability vs. security trade-offs
     - Performance impact of security controls
     - Operational complexity considerations
  
  6. **Cross-Domain Context**
     - Architecture patterns requiring security (Alex's domain)
     - Infrastructure security implementation (William's domain)
     - Security testing requirements (Julia's domain)
  
  7. **Deliverable Expectations**
     - Expected security artifacts (policies, configs, procedures)
     - Documentation format and detail level
     - Timeline and security milestone expectations
  
  8. **Reference Materials**
     - Security policies and standards
     - Threat intelligence and risk assessments
     - Previous security decisions
     - Compliance requirements documentation
  
  **Template Structure:**
  ```
  SECURITY CONTEXT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Date: [YYYY-MM-DD]
  Prepared By: Agent Zero
  Target Specialist: Frank Lucas (Security Specialist)
  
  SECURITY REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  [What security controls/policies/configurations needed]
  [What security threats/risks need addressing]
  [What compliance requirements apply]
  
  SECURITY CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Current Security Posture: [Existing controls and configurations]
  Identity & Access: [Current IAM state, authentication/authorization]
  DNS & Certificates: [Domain configuration, CA status, cert management]
  Security Zones: [Network boundaries, trust levels, isolation]
  
  SECURITY SCOPE:
  ──────────────────────────────────────────────────────────────────────
  Domains: [Identity, DNS, Certificates, Access Control, etc.]
  Artifacts Needed: [Policies, procedures, configurations, documentation]
  Decisions to Document: [Key security decisions requiring capture]
  
  THREAT CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Threat Model: [Attack vectors, threat actors, vulnerabilities]
  Risk Assessment: [Severity levels, likelihood, impact]
  Compliance: [Regulatory requirements, audit needs, standards]
  
  SECURITY CONSTRAINTS:
  ──────────────────────────────────────────────────────────────────────
  Usability: [User experience vs. security balance]
  Performance: [Security overhead acceptable limits]
  Operational: [Complexity vs. security trade-offs]
  
  CROSS-DOMAIN CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Architecture (Alex): [Design patterns requiring security]
  Infrastructure (William): [Security implementation environment]
  Testing (Julia): [Security testing and validation requirements]
  
  DELIVERABLE EXPECTATIONS:
  ──────────────────────────────────────────────────────────────────────
  Artifacts: [List expected security deliverables]
  Format: [Documentation format and detail level]
  Timeline: [Expected completion date]
  Security Milestones: [Key security checkpoints]
  
  REFERENCE MATERIALS:
  ──────────────────────────────────────────────────────────────────────
  - [Path to security policies and standards]
  - [Path to threat intelligence]
  - [Path to previous security decisions]
  - [Path to compliance requirements]
  
  CONTEXT VERSION: 1.0
  LAST UPDATED: [YYYY-MM-DD HH:MM]
  ```
  </template>

  <template name="William Context Template - Infrastructure Coordination">
  **Purpose:** Prepare context for infrastructure coordination with William (Infrastructure Specialist)
  
  **Required Context Elements:**
  
  1. **Infrastructure Requirements**
     - What infrastructure, operations, or deployment needed?
     - What operational problems need solving?
     - What infrastructure constraints exist?
  
  2. **Infrastructure Context**
     - Current infrastructure state (servers, services, configurations)
     - Operating system environment (Ubuntu 24 bare metal)
     - Deployment procedures and operational status
     - System monitoring and health check state
  
  3. **Infrastructure Scope**
     - What infrastructure work needed (deployment, configuration, operations)?
     - What operational artifacts needed (runbooks, procedures, configs)?
     - What infrastructure decisions require documentation?
  
  4. **Operational Constraints**
     - Manual installation requirements (no automation currently)
     - Bare metal environment (no Docker in production)
     - Ansible Vault for secrets only (no deployment automation)
     - Resource limitations and environment restrictions
  
  5. **Reliability Requirements**
     - Uptime expectations and availability needs
     - Monitoring and alerting requirements
     - Health check and operational validation needs
  
  6. **Cross-Domain Context**
     - Architecture requiring infrastructure (Alex's domain)
     - Security controls needing implementation (Frank's domain)
     - Testing validation requirements (Julia's domain)
  
  7. **Deliverable Expectations**
     - Expected infrastructure artifacts (runbooks, configs, procedures)
     - Documentation format and detail level
     - Timeline and operational milestone expectations
  
  8. **Reference Materials**
     - Infrastructure documentation and runbooks
     - Deployment standards and procedures
     - Previous infrastructure decisions
     - Operational baselines and monitoring data
  
  **Template Structure:**
  ```
  INFRASTRUCTURE CONTEXT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Date: [YYYY-MM-DD]
  Prepared By: Agent Zero
  Target Specialist: William Chen (Infrastructure Specialist)
  
  INFRASTRUCTURE REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  [What infrastructure/operations/deployment needed]
  [What operational problems need solving]
  [What infrastructure constraints exist]
  
  INFRASTRUCTURE CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Current Infrastructure: [Server inventory, service status, configurations]
  Operating System: [Ubuntu 24 bare metal environment details]
  Deployment State: [Current deployment procedures and status]
  Monitoring: [System monitoring and health check state]
  
  INFRASTRUCTURE SCOPE:
  ──────────────────────────────────────────────────────────────────────
  Work Needed: [Deployment, configuration, operations tasks]
  Artifacts Needed: [Runbooks, procedures, configurations, documentation]
  Decisions to Document: [Key infrastructure decisions requiring capture]
  
  OPERATIONAL CONSTRAINTS:
  ──────────────────────────────────────────────────────────────────────
  Installation: [Manual installation procedures required (no automation)]
  Environment: [Bare metal deployment (no Docker in production)]
  Secrets Management: [Ansible Vault for secrets only (no deployment automation)]
  Resources: [Hardware, network, storage limitations]
  
  RELIABILITY REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  Uptime: [Availability expectations, SLA requirements]
  Monitoring: [Monitoring systems, alerting needs, dashboards]
  Health Checks: [Validation procedures, operational checks]
  
  CROSS-DOMAIN CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Architecture (Alex): [Design requiring infrastructure implementation]
  Security (Frank): [Security controls needing operational deployment]
  Testing (Julia): [Infrastructure testing and validation requirements]
  
  DELIVERABLE EXPECTATIONS:
  ──────────────────────────────────────────────────────────────────────
  Artifacts: [List expected infrastructure deliverables]
  Format: [Documentation format and detail level]
  Timeline: [Expected completion date]
  Operational Milestones: [Key infrastructure checkpoints]
  
  REFERENCE MATERIALS:
  ──────────────────────────────────────────────────────────────────────
  - [Path to infrastructure documentation]
  - [Path to deployment standards]
  - [Path to operational runbooks]
  - [Path to monitoring baselines]
  
  CONTEXT VERSION: 1.0
  LAST UPDATED: [YYYY-MM-DD HH:MM]
  ```
  </template>

  <template name="Julia Context Template - Testing Coordination">
  **Purpose:** Prepare context for testing coordination with Julia (Testing & Quality Specialist)
  
  **Required Context Elements:**
  
  1. **Testing Requirements**
     - What testing, validation, or quality assurance needed?
     - What quality problems need addressing?
     - What testing constraints exist?
  
  2. **Testing Context**
     - Current test coverage and quality state
     - Existing test cases and test data
     - Known defects and quality issues
     - Testing infrastructure and tools available
  
  3. **Testing Scope**
     - What test types needed (unit, integration, e2e, acceptance)?
     - What testing artifacts needed (plans, cases, reports)?
     - What quality decisions require documentation?
  
  4. **Quality Standards**
     - Acceptance criteria and quality gates
     - Test coverage requirements
     - Quality metrics and success criteria
  
  5. **Testing Constraints**
     - Testing environment limitations
     - Test data availability
     - Testing timeline and resource restrictions
  
  6. **Cross-Domain Context**
     - Architecture requiring testing (Alex's domain)
     - Security validation needs (Frank's domain)
     - Infrastructure testing requirements (William's domain)
  
  7. **Deliverable Expectations**
     - Expected testing artifacts (plans, cases, scripts, reports)
     - Documentation format and detail level
     - Timeline and quality milestone expectations
  
  8. **Reference Materials**
     - Testing knowledge vault repositories
     - Test case templates and standards
     - Previous test plans and quality reports
     - Quality assurance procedures
  
  **Template Structure:**
  ```
  TESTING CONTEXT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Date: [YYYY-MM-DD]
  Prepared By: Agent Zero
  Target Specialist: Julia Santos (Testing & Quality Specialist)
  
  TESTING REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  [What testing/validation/quality assurance needed]
  [What quality problems need addressing]
  [What testing constraints exist]
  
  TESTING CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Current Test Coverage: [Existing test cases and coverage metrics]
  Test Data: [Available test data, environments, configurations]
  Known Defects: [Outstanding quality issues and defect backlog]
  Testing Infrastructure: [Test environments, tools, frameworks available]
  
  TESTING SCOPE:
  ──────────────────────────────────────────────────────────────────────
  Test Types: [Unit, integration, e2e, acceptance, performance, security]
  Artifacts Needed: [Test plans, test cases, test scripts, quality reports]
  Decisions to Document: [Key testing decisions requiring capture]
  
  QUALITY STANDARDS:
  ──────────────────────────────────────────────────────────────────────
  Acceptance Criteria: [Quality gates and success criteria]
  Coverage Requirements: [Minimum test coverage expectations]
  Quality Metrics: [Defect density, test pass rate, coverage percentage]
  
  TESTING CONSTRAINTS:
  ──────────────────────────────────────────────────────────────────────
  Environment: [Testing environment limitations and availability]
  Test Data: [Data availability, privacy constraints, generation needs]
  Resources: [Timeline, personnel, tooling restrictions]
  
  CROSS-DOMAIN CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Architecture (Alex): [Design patterns requiring testing validation]
  Security (Frank): [Security testing and validation requirements]
  Infrastructure (William): [Infrastructure testing and operational validation]
  
  DELIVERABLE EXPECTATIONS:
  ──────────────────────────────────────────────────────────────────────
  Artifacts: [List expected testing deliverables]
  Format: [Documentation format and detail level]
  Timeline: [Expected completion date]
  Quality Milestones: [Key testing and quality checkpoints]
  
  REFERENCE MATERIALS:
  ──────────────────────────────────────────────────────────────────────
  - [Path to testing knowledge vault]
  - [Path to test case templates]
  - [Path to previous test plans]
  - [Path to quality assurance procedures]
  
  CONTEXT VERSION: 1.0
  LAST UPDATED: [YYYY-MM-DD HH:MM]
  ```
  </template>

  <template name="Multi-Agent Context Template - Synthesis Coordination">
  **Purpose:** Prepare context for multi-agent synthesis coordination requiring multiple specialists
  
  **Required Context Elements:**
  
  1. **Multi-Agent Requirements**
     - Why are multiple specialists needed?
     - What domains must be coordinated (architecture, security, infrastructure, testing)?
     - What cross-domain integration is required?
  
  2. **Agent Selection Rationale**
     - Which specialists are involved (Alex, Frank, William, Julia)?
     - What is the coordination sequence (sequential, parallel, hybrid)?
     - Why this coordination approach chosen?
  
  3. **Domain-Specific Contexts**
     - Architecture context (if Alex involved)
     - Security context (if Frank involved)
     - Infrastructure context (if William involved)
     - Testing context (if Julia involved)
  
  4. **Cross-Domain Dependencies**
     - How do specialist outputs depend on each other?
     - What information flows between specialists?
     - What conflicts might arise between domains?
  
  5. **Synthesis Requirements**
     - How should specialist outputs be integrated?
     - What conflicts need resolution mechanisms?
     - What synergies should be leveraged?
  
  6. **Coordination Constraints**
     - Timeline for multi-agent coordination
     - Resource availability of specialists
     - Sequencing dependencies and prerequisites
  
  7. **Deliverable Expectations**
     - Expected integrated deliverable spanning domains
     - Documentation format and detail level
     - Timeline and coordination milestone expectations
  
  8. **Reference Materials**
     - Multi-agent coordination precedents
     - Cross-domain integration patterns
     - Previous multi-agent synthesis examples
  
  **Template Structure:**
  ```
  MULTI-AGENT SYNTHESIS CONTEXT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Date: [YYYY-MM-DD]
  Prepared By: Agent Zero
  Target: Multi-Agent Coordination
  Specialists Involved: [Alex/Frank/William/Julia]
  
  MULTI-AGENT REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  [Why multiple specialists needed]
  [What domains must be coordinated]
  [What cross-domain integration required]
  
  AGENT SELECTION RATIONALE:
  ──────────────────────────────────────────────────────────────────────
  Specialists: [List of specialists involved with domain expertise]
  Coordination Mode: [Sequential/Parallel/Hybrid]
  Rationale: [Why this approach chosen]
  
  DOMAIN-SPECIFIC CONTEXTS:
  ──────────────────────────────────────────────────────────────────────
  
  ARCHITECTURE CONTEXT (Alex):
  [Insert architecture-specific context if Alex involved]
  
  SECURITY CONTEXT (Frank):
  [Insert security-specific context if Frank involved]
  
  INFRASTRUCTURE CONTEXT (William):
  [Insert infrastructure-specific context if William involved]
  
  TESTING CONTEXT (Julia):
  [Insert testing-specific context if Julia involved]
  
  CROSS-DOMAIN DEPENDENCIES:
  ──────────────────────────────────────────────────────────────────────
  Dependencies: [How specialist outputs depend on each other]
  Information Flow: [What information flows between specialists]
  Potential Conflicts: [Where contradictions might arise]
  
  SYNTHESIS REQUIREMENTS:
  ──────────────────────────────────────────────────────────────────────
  Integration: [How to combine specialist outputs]
  Conflict Resolution: [Mechanisms for handling contradictions]
  Synergies: [Opportunities where specialists reinforce each other]
  
  COORDINATION CONSTRAINTS:
  ──────────────────────────────────────────────────────────────────────
  Timeline: [Coordination schedule and milestones]
  Resources: [Specialist availability and capacity]
  Sequencing: [Dependencies and prerequisites for coordination]
  
  DELIVERABLE EXPECTATIONS:
  ──────────────────────────────────────────────────────────────────────
  Integrated Deliverable: [Unified output spanning domains]
  Format: [Documentation format and detail level]
  Timeline: [Expected completion date]
  Coordination Milestones: [Key multi-agent checkpoints]
  
  REFERENCE MATERIALS:
  ──────────────────────────────────────────────────────────────────────
  - [Path to multi-agent coordination precedents]
  - [Path to cross-domain integration patterns]
  - [Path to previous synthesis examples]
  
  CONTEXT VERSION: 1.0
  LAST UPDATED: [YYYY-MM-DD HH:MM]
  ```
  </template>
</context_templates>

<validation_procedures>
  <procedure name="Validate Context Completeness">
  **Purpose:** Verify context document contains all required elements before handoff
  
  **Validation Process:**
  
  1. **Load Validation Checklist**
     - Retrieve specialist-specific checklist (Alex/Frank/William/Julia/Multi-agent)
     - Identify all required context elements
     - Note optional vs. mandatory elements
  
  2. **Check Element Presence**
     For each required element:
     - Verify element present in context document
     - Check element has meaningful content (not just placeholder)
     - Assess if content addresses element purpose
     - Mark element: PRESENT or MISSING
  
  3. **Evaluate Element Quality**
     For each present element:
     - Is information specific and actionable?
     - Is information current and accurate?
     - Is information sufficient for specialist to proceed?
     - Mark quality: SUFFICIENT or INSUFFICIENT
  
  4. **Calculate Completeness Score**
     - Required elements present: X of Y
     - Required elements sufficient: A of Y
     - Completeness percentage: (A/Y) × 100%
  
  5. **Determine Validation Status**
     - If ALL required elements PRESENT and SUFFICIENT → PASS
     - If ANY required element MISSING or INSUFFICIENT → FAIL
  
  6. **Generate Validation Report**
     - Completeness score and status
     - Element-by-element assessment
     - Gaps identified (missing or insufficient)
     - Remediation guidance for gaps
  
  **Validation Checklists:**
  
  **Alex (Architecture) Context Checklist:**
  - [ ] Architecture requirements specified
  - [ ] System context documented
  - [ ] Architecture scope defined
  - [ ] Design constraints identified
  - [ ] Stakeholder considerations addressed
  - [ ] Cross-domain context provided (Frank, William, Julia)
  - [ ] Deliverable expectations clear
  - [ ] Reference materials accessible
  
  **Frank (Security) Context Checklist:**
  - [ ] Security requirements specified
  - [ ] Security context documented
  - [ ] Security scope defined
  - [ ] Threat context identified
  - [ ] Security constraints addressed
  - [ ] Cross-domain context provided (Alex, William, Julia)
  - [ ] Deliverable expectations clear
  - [ ] Reference materials accessible
  
  **William (Infrastructure) Context Checklist:**
  - [ ] Infrastructure requirements specified
  - [ ] Infrastructure context documented
  - [ ] Infrastructure scope defined
  - [ ] Operational constraints identified
  - [ ] Reliability requirements addressed
  - [ ] Cross-domain context provided (Alex, Frank, Julia)
  - [ ] Deliverable expectations clear
  - [ ] Reference materials accessible
  
  **Julia (Testing) Context Checklist:**
  - [ ] Testing requirements specified
  - [ ] Testing context documented
  - [ ] Testing scope defined
  - [ ] Quality standards identified
  - [ ] Testing constraints addressed
  - [ ] Cross-domain context provided (Alex, Frank, William)
  - [ ] Deliverable expectations clear
  - [ ] Reference materials accessible
  
  **Multi-Agent Synthesis Context Checklist:**
  - [ ] Multi-agent requirements explained
  - [ ] Agent selection rationale documented
  - [ ] Domain-specific contexts provided for each specialist
  - [ ] Cross-domain dependencies mapped
  - [ ] Synthesis requirements defined
  - [ ] Coordination constraints identified
  - [ ] Deliverable expectations clear
  - [ ] Reference materials accessible
  
  **Outputs:**
  - Context validation report (PASS/FAIL)
  - Completeness score
  - Gap identification and remediation guidance
  </procedure>

  <procedure name="Generate Handoff Package">
  **Purpose:** Create structured handoff package for specialist delivery
  
  **Package Generation Process:**
  
  1. **Compile Context Document**
     - Gather validated context document
     - Ensure all required elements present
     - Verify formatting and structure
  
  2. **Add Metadata**
     - Package creation date and time
     - Package version number
     - Prepared by (Agent Zero)
     - Target specialist (Alex/Frank/William/Julia)
  
  3. **Include Reference Materials**
     - Gather all referenced documents
     - Verify accessibility of paths
     - Create index of reference materials
  
  4. **Add Handoff Instructions**
     - Expected deliverables summary
     - Timeline and milestones
     - Contact information for clarifications
     - Next steps after specialist work complete
  
  5. **Structure Package**
     - Primary context document (main content)
     - Reference materials index
     - Handoff instructions
     - Package metadata
  
  6. **Generate Package Documentation**
     - Package summary describing contents
     - Quick reference guide for specialist
     - Handoff checklist
  
  7. **Version Control**
     - Assign package version number
     - Record creation timestamp
     - Track any updates or iterations
  
  **Package Structure:**
  ```
  HANDOFF PACKAGE - [SPECIALIST] - [PROJECT]
  ══════════════════════════════════════════════════════════════════════
  Package Version: 1.0
  Created: [YYYY-MM-DD HH:MM]
  Prepared By: Agent Zero
  Target Specialist: [Alex/Frank/William/Julia]
  
  PACKAGE CONTENTS:
  ──────────────────────────────────────────────────────────────────────
  1. Primary Context Document
     [Path to main context document]
  
  2. Reference Materials
     [List of reference documents with paths]
  
  3. Handoff Instructions
     [Expected deliverables, timeline, next steps]
  
  QUICK REFERENCE:
  ──────────────────────────────────────────────────────────────────────
  Task: [One-line task description]
  Scope: [Brief scope summary]
  Due Date: [Expected completion]
  Key Deliverables: [List 2-3 main outputs expected]
  
  HANDOFF CHECKLIST:
  ──────────────────────────────────────────────────────────────────────
  [ ] Context document reviewed and understood
  [ ] Reference materials accessed and reviewed
  [ ] Deliverable expectations clear
  [ ] Timeline feasible
  [ ] No blocking questions
  [ ] Ready to proceed with autonomous work
  
  CONTACT FOR CLARIFICATIONS:
  ──────────────────────────────────────────────────────────────────────
  Agent Zero (Orchestrator)
  Available for clarification requests during work phase
  
  NEXT STEPS AFTER WORK COMPLETE:
  ──────────────────────────────────────────────────────────────────────
  1. Signal work completion to Agent Zero
  2. Provide deliverables for validation
  3. Participate in validation phase if questions arise
  4. Support integration phase as needed
  ```
  
  **Outputs:**
  - Structured handoff package
  - Package documentation
  - Version control record
  </procedure>

  <procedure name="Track Context Versions">
  **Purpose:** Maintain version history of context documents across iterations
  
  **Version Tracking Process:**
  
  1. **Assign Version Number**
     - Initial context: Version 1.0
     - Minor updates: Increment decimal (1.1, 1.2, etc.)
     - Major revisions: Increment integer (2.0, 3.0, etc.)
  
  2. **Document Changes**
     - What changed from previous version
     - Why change was made
     - Who requested or identified need for change
  
  3. **Record Metadata**
     - Version number
     - Creation/update timestamp
     - Author (Agent Zero)
     - Reason for version
  
  4. **Maintain Version History**
     - Keep record of all versions
     - Link versions to orchestration attempts
     - Track which version used in each handoff
  
  5. **Enable Version Comparison**
     - Support diff between versions
     - Identify what evolved across iterations
     - Analyze context improvement patterns
  
  **Version History Format:**
  ```
  CONTEXT VERSION HISTORY - [PROJECT] - [SPECIALIST]
  ══════════════════════════════════════════════════════════════════════
  
  VERSION 1.0 (Initial)
  Date: 2025-11-20 09:00
  Status: Used in Orchestration Attempt 1
  Changes: Initial context creation
  Outcome: Orchestration attempt 1 failed - context incomplete
  
  VERSION 1.1 (Minor Update)
  Date: 2025-11-20 14:30
  Status: Used in Orchestration Attempt 2
  Changes: Added missing stakeholder considerations section
  Reason: Specialist requested clarification on stakeholder concerns
  Outcome: Orchestration attempt 2 successful
  
  VERSION 2.0 (Major Revision)
  Date: 2025-11-21 10:00
  Status: Used in Orchestration Attempt 3 (scope expanded)
  Changes: Major scope expansion, added 3 new requirements
  Reason: Project requirements changed after stakeholder review
  Outcome: [Pending]
  ```
  
  **Outputs:**
  - Version-controlled context document
  - Version history log
  - Change tracking documentation
  </procedure>

  <procedure name="Manage Cross-Domain Context">
  **Purpose:** Ensure context continuity across multi-agent coordination
  
  **Cross-Domain Management Process:**
  
  1. **Identify Cross-Domain Elements**
     - What information needed by multiple specialists?
     - What specialist outputs become inputs for others?
     - What dependencies exist between specialists?
  
  2. **Structure Shared Context**
     - Create base context shared by all specialists
     - Identify specialist-specific context extensions
     - Map cross-references between contexts
  
  3. **Maintain Context Flow**
     In sequential coordination:
     - Specialist A's output → Specialist B's input context
     - Specialist B's output → Specialist C's input context
     - Ensure context accumulates properly
  
  4. **Resolve Context Conflicts**
     - Identify contradictory information from different sources
     - Determine authoritative source for each element
     - Reconcile conflicts before downstream handoffs
  
  5. **Track Context Lineage**
     - Document where each context element originated
     - Track how context evolved across specialists
     - Enable traceability of information flow
  
  6. **Validate Context Consistency**
     - Check contexts don't contradict each other
     - Verify cross-references resolve correctly
     - Ensure specialists have compatible assumptions
  
  **Cross-Domain Context Map Example:**
  ```
  CROSS-DOMAIN CONTEXT MAP - [PROJECT]
  ══════════════════════════════════════════════════════════════════════
  
  SHARED BASE CONTEXT (All Specialists):
  - Project goals and objectives
  - Overall scope and constraints
  - Timeline and milestones
  - Stakeholder information
  
  SPECIALIST-SPECIFIC CONTEXTS:
  
  Alex (Architecture):
  - Base context + architecture requirements
  - Needs Frank's security requirements
  - Provides architecture design to William and Julia
  
  Frank (Security):
  - Base context + security requirements
  - Provides security controls to Alex (affects architecture)
  - Provides security requirements to William (implementation)
  - Provides security testing needs to Julia
  
  William (Infrastructure):
  - Base context + infrastructure requirements
  - Needs Alex's architecture design
  - Needs Frank's security requirements
  - Provides deployment context to Julia
  
  Julia (Testing):
  - Base context + testing requirements
  - Needs Alex's architecture (what to test)
  - Needs Frank's security (security testing)
  - Needs William's infrastructure (where to test)
  
  CONTEXT FLOW (Sequential Coordination):
  Frank → Alex → William → Julia
  (Security requirements inform architecture, architecture informs 
   infrastructure, all inform testing)
  ```
  
  **Outputs:**
  - Cross-domain context map
  - Context flow documentation
  - Consistency validation report
  </procedure>
</validation_procedures>

<integration_with_orchestrations>
**Orchestration Integration:**

This utility integrates with Set 2 orchestrations during Phase 2 (Context Preparation):

**Single-Agent Orchestrations:**
- **cc-orchestrate-alex.md** Phase 2 → Use Alex context template
- **cc-orchestrate-frank.md** Phase 2 → Use Frank context template
- **cc-orchestrate-william.md** Phase 2 → Use William context template
- **cc-orchestrate-julia.md** Phase 2 → Use Julia context template

**Multi-Agent Orchestration:**
- **cc-agent-zero-synthesis.md** Phase 2 → Use Multi-agent context template
- Manage cross-domain context across all involved specialists

**Usage Pattern:**
1. Orchestration reaches Phase 2 (Context Preparation)
2. Call context-prep utility to generate template
3. Populate template with task-specific information
4. Validate completeness using utility
5. Generate handoff package using utility
6. Proceed to Phase 3 (Handoff) with validated context
</integration_with_orchestrations>

<integration_convention>
**How Commands Invoke This Utility:**

**From Orchestration Commands (Set 2):**
At Phase 2 (Context Preparation), orchestration commands invoke utility with instructional reference:

**Example from cc-orchestrate-alex.md Phase 2:**
"Use cc-util-context-prep to generate Alex context document. Load Alex
context template and populate with project-specific information:
- Project: auth-system
- Task: Design authentication service architecture using OAuth 2.0
- Requirements: Support RBAC, Active Directory integration, multi-tenant
- Deliverables: Architecture decision records, component diagrams, API specs

Validate context completeness before proceeding to Phase 3 (Handoff).
Generate context document at /projects/auth-system/orchestration/alex-context.md"

**Example from cc-agent-zero-synthesis.md Phase 2:**
"Use cc-util-context-prep to generate multi-agent context. Prepare contexts
for Frank (security requirements), Alex (architecture design), William
(infrastructure deployment), and Julia (test strategy). Map cross-domain
dependencies and ensure context continuity for sequential coordination."

**Required Inputs:**
1. **Specialist Identifier** - Which specialist (Alex/Frank/William/Julia/Multi-agent)
2. **Project Name** - For context document organization
3. **Task Description** - Specific work requiring specialist expertise
4. **Requirements** - Functional and non-functional requirements
5. **Constraints** - Design, technology, or policy constraints
6. **Deliverables** - Expected artifacts from specialist
7. **Timeline** - Schedule expectations
8. **Reference Materials** - Supporting documentation paths

**Expected Outputs:**

1. **Context Document** (Primary Output)
   - Format: Structured markdown with all required context elements
   - Location: `/projects/{project-name}/orchestration/{specialist}-context.md`
   - Contents: Specialist-specific context from template populated with task details

2. **Validation Report** (Completeness Check)
   - Format: Structured markdown with completeness metrics
   - Location: `/projects/{project-name}/orchestration/{specialist}-context-validation.md`
   - Contents: Required elements present/absent, sufficiency assessment, remediation guidance

3. **Handoff Package** (Formal Specialist Engagement)
   - Format: Bundled context document + reference materials
   - Location: `/projects/{project-name}/orchestration/handoff-{specialist}.md`
   - Contents: Context document, reference links, deliverable expectations, timeline

4. **Context Version Log** (State Artifact)
   - Format: Version history with changes tracked
   - Location: `/projects/{project-name}/orchestration/context-versions.md`
   - Contents: Version number, date, changes, completeness status

**State Management:**

**Stateless Component:**
- cc-util-context-prep.md utility file (this document)
- Instructions for context preparation procedures
- Template library (Alex, Frank, William, Julia, Multi-agent)
- No state maintained in utility itself

**Stateful Artifacts:**
- Context documents: `/projects/{project-name}/orchestration/{specialist}-context.md`
- Validation reports: `/projects/{project-name}/orchestration/{specialist}-context-validation.md`
- Handoff packages: `/projects/{project-name}/orchestration/handoff-{specialist}.md`
- Version log: `/projects/{project-name}/orchestration/context-versions.md`
- Created/updated by following utility procedures
- Persistent across sessions

**File Organization:**
```
/projects/{project-name}/
  orchestration/
    alex-context.md                    ← Alex specialist context
    alex-context-validation.md         ← Validation report
    frank-context.md                   ← Frank specialist context
    frank-context-validation.md
    william-context.md                 ← William specialist context
    william-context-validation.md
    julia-context.md                   ← Julia specialist context
    julia-context-validation.md
    multi-agent-context.md             ← Multi-agent synthesis context
    context-versions.md                ← Version history log
    handoff-alex.md                    ← Handoff packages
    handoff-frank.md
    ...
```

**Invocation Pattern Summary:**
1. Orchestration reaches Phase 2 (Context Preparation)
2. Reference cc-util-context-prep with specialist and task details
3. Context document generated at standard location
4. Completeness validated with report generated
5. Handoff package assembled if validation passes
6. Context version logged
7. Proceed to Phase 3 (Handoff) with validated context
</integration_convention>

<usage_examples>
  <example name="Generate Alex Context">
  **Scenario:** Preparing context for architecture coordination
  
  **Command:**
  ```
  Generate context document:
  - Specialist: Alex (Architecture)
  - Project: auth-system
  - Task: Design authentication service architecture
  ```
  
  **Utility Process:**
  1. Load Alex context template
  2. Populate with auth-system specifics
  3. Validate completeness
  4. Generate handoff package
  
  **Output:** Complete context document ready for Alex handoff
  </example>

  <example name="Validate Context Completeness">
  **Scenario:** Checking if context document ready for handoff
  
  **Command:**
  ```
  Validate context completeness:
  - Context document: /path/to/frank-context.md
  - Specialist: Frank (Security)
  - Checklist: Frank security context checklist
  ```
  
  **Utility Process:**
  1. Load Frank context checklist
  2. Check each required element
  3. Assess element quality
  4. Calculate completeness score
  5. Generate validation report
  
  **Output (if incomplete):**
  ```
  CONTEXT VALIDATION REPORT: ❌ FAIL
  
  Completeness: 6 of 8 required elements (75%)
  
  MISSING ELEMENTS:
  - Threat context (required)
  - Reference materials (required)
  
  INSUFFICIENT ELEMENTS:
  - Security scope (present but vague)
  
  REMEDIATION:
  1. Add threat model and risk assessment
  2. Provide paths to security policies
  3. Clarify security scope with specific domains
  
  Re-validate after remediation.
  ```
  </example>

  <example name="Multi-Agent Context Preparation">
  **Scenario:** Preparing context for multi-agent synthesis
  
  **Command:**
  ```
  Generate multi-agent context:
  - Project: auth-system
  - Specialists: Frank, Alex, William, Julia (in sequence)
  - Coordination: Sequential (Frank → Alex → William → Julia)
  ```
  
  **Utility Process:**
  1. Load multi-agent synthesis template
  2. Generate domain-specific contexts for each specialist
  3. Map cross-domain dependencies
  4. Structure context flow for sequential coordination
  5. Validate cross-domain consistency
  6. Generate handoff packages for all specialists
  
  **Output:** Complete multi-agent context package with specialist-specific contexts and cross-domain mapping
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Complete Context Essential:** Incomplete context creates clarification cycles and delays. Invest time in comprehensive context preparation.

2. ⚠️ **Validation Before Handoff:** Always validate context completeness before specialist handoff. Failed handoffs often trace to incomplete context.

3. ⚠️ **Cross-Domain Awareness:** Include cross-domain context even for single-agent orchestration. Specialists need to understand how their work affects other domains.

4. ⚠️ **Specific Over Generic:** Context must be specific and actionable, not generic placeholders. "Design the authentication system" insufficient; "Design OAuth 2.0 authentication supporting RBAC with Active Directory integration" sufficient.

5. ⚠️ **Version Control Important:** Track context versions across orchestration iterations. Understanding context evolution improves future preparation.

6. ⚠️ **Template Not Script:** Templates guide context preparation but must be populated with task-specific information. Don't handoff template as-is.

7. ⚠️ **Reference Materials Accessible:** Ensure all referenced materials actually accessible to specialists. Broken references waste specialist time.

8. ⚠️ **Context Continuity in Multi-Agent:** For sequential coordination, ensure downstream specialists receive upstream outputs in their context.
</critical_reminders>

<validation_checklist>
**Template Selection Checklist:**
- [ ] Correct specialist template selected (Alex/Frank/William/Julia/Multi-agent)
- [ ] Template version current
- [ ] Template appropriate for task type

**Context Population Checklist:**
- [ ] All required sections populated (no placeholders)
- [ ] Information specific and actionable
- [ ] Information current and accurate
- [ ] Cross-domain context included
- [ ] Reference materials provided with valid paths

**Completeness Validation Checklist:**
- [ ] All checklist items addressed
- [ ] Required elements present
- [ ] Required elements sufficient quality
- [ ] Optional elements included where relevant
- [ ] No contradictory information

**Handoff Package Checklist:**
- [ ] Context document included
- [ ] Reference materials accessible
- [ ] Handoff instructions clear
- [ ] Deliverable expectations specified
- [ ] Timeline communicated
- [ ] Version number assigned

**Multi-Agent Context Checklist:**
- [ ] All specialist contexts prepared
- [ ] Cross-domain dependencies mapped
- [ ] Context flow documented
- [ ] Consistency validated across contexts
- [ ] Coordination sequence clear
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Alex orchestration Phase 2
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Frank orchestration Phase 2
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - William orchestration Phase 2
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Julia orchestration Phase 2
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-agent-zero-synthesis.md` - Multi-agent synthesis Phase 2
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - Agent specialist details
- `/srv/knowledge/vault/` - Reference materials for specialist contexts
</related_documents>

<metadata_footer>
**Version:** 1.2
**Status:** APPROVED - Production Ready with Enhanced Integration Convention
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Updated to v2.1 metadata format with location field)
**Compliance:** 100% semantic XML structure, comprehensive template library, validation procedures
**Next Steps:** Use this utility during Phase 2 (Context Preparation) of all orchestrations to ensure complete, validated context documents
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**Infrastructure Philosophy:** Bare metal first philosophy integrated in William context template (lines 295, 306-307, 348, 361-362)
</metadata_footer>