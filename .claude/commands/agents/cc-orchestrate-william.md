---
workflow: orchestrate-william
version: 2.0
date: 2025-11-20
status: APPROVED
type: workflow-command
description: Orchestration patterns for coordinating operational infrastructure work with William (Infrastructure Specialist)
applies_to: infrastructure_operations, bare_metal_deployment, operational_runbooks, manual_procedures
author: HX-Infrastructure Team
---

<metadata>
**Workflow:** William Orchestration - Infrastructure & Operations Coordination
**Version:** 2.0 (Rewritten with CAIO infrastructure philosophy)
**Date:** 2025-11-20
**Status:** APPROVED - Ready for use
**Type:** Agent Orchestration Command
**Agent:** William (Infrastructure Specialist)
**Purpose:** Define how agent0 coordinates WITH William for infrastructure and operational work
</metadata>

<objective>
**Purpose:** Guide agent0 through systematic coordination with William (Infrastructure Specialist) for all infrastructure and operational work in the HX-Infrastructure ecosystem.

**Infrastructure Philosophy (CRITICAL):**
⚠️ **BARE METAL FIRST, Docker FOR DEV ONLY** - HX-Infrastructure defaults to native OS packages with systemd services for ALL production and staging deployments. Docker is ONLY used on dev server for project isolation (Python, React, Next.js development environments). Docker in production/staging requires explicit CAIO approval.

⚠️ **ANSIBLE VAULT ONLY** - Ansible Vault is used for centralized credential management. Ansible playbooks are NOT used. Operational procedures are manual with comprehensive documentation (runbooks, bash scripts, systemd).

**Key Innovation:** Separates orchestration (agent0's role) from execution (William's role) with proper respect for infrastructure expertise and CAIO's strategic authority over deployment approach and automation strategy.
</objective>

<workflow_overview>
**High-Level Flow:**
1. **Phase 0:** Decision - Does this task require William's infrastructure expertise?
2. **Phase 1:** Context Preparation - Gather comprehensive operational requirements
3. **Phase 2:** Handoff - Transfer context to William with clear operational scope
4. **Phase 3:** William Works - William develops runbooks/procedures autonomously
5. **Phase 4:** Validation - Verify operational deliverables meet requirements
6. **Phase 5:** Integration - Merge infrastructure guidance into project
7. **Phase 6:** Follow-up - Document lessons and operational patterns

**Workflow Duration:** 2-5 hours typical (varies by infrastructure complexity)

**Philosophy:** William implements operational infrastructure; agent0 coordinates, provides context, and integrates results. CAIO directs deployment approach (bare metal vs. Docker) and automation strategy (manual vs. future Ansible).
</workflow_overview>

<key_principles>
1. **Bare Metal First:** Production/staging use native packages + systemd; Docker ONLY for dev server project isolation
2. **Ansible Vault Only:** Ansible Vault for credential management; NO Ansible playbooks
3. **Manual Operations:** Documented procedures, bash scripts, systemd configs (NOT automation frameworks)
4. **Operational Reliability:** Uptime and monitoring are non-negotiable
5. **Trust William:** Infrastructure expertise is trusted implicitly
6. **Complete Context:** Quality guidance requires comprehensive operational requirements
7. **CAIO Authority:** All production deployment and automation strategy decisions directed by CAIO
</key_principles>

<phases>
<phase id="0" name="Decision Point - Do We Need William?" gate="william_invocation_decision">
<description>
Evaluate whether the task requires William's infrastructure and operational expertise.

**Decision Framework:**
- Does task involve OS configuration, system services, or deployment procedures?
- Does task require operational runbooks or bash scripts?
- Does task involve reliability requirements, monitoring, or health checks?
- Does task require infrastructure architecture or deployment strategy?
</description>

<actions>
**Evaluate Against Invocation Criteria:**

**MUST Invoke William When:**
- Operating system configuration or system service management required
- Deployment procedures or operational runbooks need development
- Bash scripts for deployment repeatability needed
- Systemd service configurations required
- Docker deployment required (IF CAIO has approved Docker for this service)
- System monitoring, health checks, or alerting setup needed
- Backup strategies or disaster recovery procedures required
- Infrastructure architecture or deployment strategy decisions needed
- Operational reliability requirements or uptime expectations specified

**MAY Invoke William When:**
- Infrastructure best practices verification would add value
- Operational approach guidance would improve deployment quality
- Infrastructure precedent research could inform decisions
- Proactive operational review would catch deployment issues early

**DO NOT Invoke William When:**
- Task is pure application development (no infrastructure changes)
- Task is documentation-only (no operational procedures)
- Task has no reliability or deployment concerns
- Task is exploratory research (not implementation)
- Task is purely security-focused (coordinate with Frank instead)

**Decision Process:**
1. Is infrastructure or operational work involved? → YES = Continue evaluation
2. Does it require deployment procedures or runbooks? → YES = Likely William
3. Are reliability or monitoring requirements present? → YES = Likely William
4. Is operational expertise beneficial? → YES = Consider William
5. When in doubt about operational complexity → Invoke William
</actions>

<critical_check>
**⚠️ DEPLOYMENT APPROACH GATE - BARE METAL FOR PRODUCTION/STAGING**

**Production/Staging Deployment (DEFAULT):** BARE METAL
- Native OS packages (apt/dpkg)
- Systemd service management
- Traditional configuration files
- No Docker containerization

**Dev Server Docker Usage (PROJECT ISOLATION ONLY):**
- Docker is ONLY used on dev server for development environment isolation
- Python, React, Next.js development projects use Docker for isolation
- Dev Docker does NOT require CAIO approval (established pattern)
- Production/staging Docker DOES require CAIO approval

**Decision Tree:**
- Is this a PRODUCTION or STAGING deployment? → Use BARE METAL (native packages + systemd)
- Is this a DEV SERVER project environment? → Docker allowed for project isolation
- Is this Docker for production? → Requires explicit CAIO approval

**CAIO Authority:** Production/staging Docker decisions directed by CAIO. Dev server Docker for project isolation is established pattern.
</critical_check>

<critical_check>
**⚠️ AUTOMATION APPROACH GATE - ANSIBLE VAULT ONLY**

**Current State (DEFAULT):** Manual operations with comprehensive documentation
- Operational runbooks (step-by-step procedures)
- Bash scripts (for repeatability where appropriate)
- Systemd service configurations
- Configuration file templates
- Manual validation procedures

**Ansible Usage (VAULT ONLY):**
- ✅ **Ansible Vault:** Used for centralized credential management (ONLY Ansible component in use)
- ❌ **Ansible Playbooks:** NOT used (not on roadmap)
- ❌ **Ansible Roles:** NOT used
- ❌ **Ansible Galaxy:** NOT used
- Ansible Vault stores encrypted credentials; playbooks NOT deployed

**William's Deliverables:**
- Comprehensive operational runbooks
- Bash scripts for deployment repeatability
- Systemd service unit files
- Configuration file templates
- Ansible Vault credential access procedures (how to retrieve secrets)
- Troubleshooting guides
- NOT: Ansible playbooks, roles, or automation (only Vault for secrets)

**CAIO Authority:** Ansible Vault is approved for credential management. All other Ansible components or automation frameworks require CAIO strategic decision.
</critical_check>

<outputs>
- Decision: Coordinate WITH William OR Proceed independently
- Rationale: Clear justification for decision
- Deployment approach confirmed: Bare metal (default) or Docker (if CAIO approved)
- Automation approach confirmed: Manual operations (current) or future state
</outputs>

<duration>5-10 minutes</duration>
</phase>

<phase id="1" name="Context Preparation - Gather Operational Requirements" gate="context_complete">
<description>
Gather comprehensive operational context for William. Complete context enables effective runbook development and infrastructure guidance.

**Context must include:**
- Infrastructure requirements (what systems, services, configurations)
- Operational constraints (environment limits, resource restrictions)
- Reliability expectations (uptime, monitoring, health checks)
- Deployment approach (bare metal default, Docker if CAIO approved)
- Automation scope (manual procedures, bash scripts, systemd)
- Current system state (existing config, deployed services)
- Dependencies (related infrastructure, service prerequisites)
</description>

<inputs>
- Task requirements with operational details
- Infrastructure scope and system inventory
- Reliability requirements and SLA expectations
- Deployment approach (confirmed in Phase 0)
- Automation approach (confirmed in Phase 0)
- Current system state documentation
- Available operational precedents
</inputs>

<actions>
1. **Document infrastructure requirements** - What needs deployment/configuration
2. **Identify operational constraints** - Environment limits, compliance requirements
3. **Define reliability expectations** - Uptime SLAs, monitoring needs, alerting thresholds
4. **Confirm deployment approach** - Bare metal (default) or Docker (CAIO approved)
5. **Confirm automation scope** - Manual runbooks, bash scripts, systemd (NOT Ansible playbooks)
6. **Assess current system state** - Existing configurations, deployed services
7. **Trace infrastructure dependencies** - Related systems, service relationships
8. **Gather operational artifacts** - Relevant documentation, config examples
9. **Prepare reliability context** - Operational history, known issues, monitoring baselines
10. **Create operational context brief** - Comprehensive handoff document for William
</actions>

<outputs>
- **Operational Context Brief** - Comprehensive document with all requirements
- **Infrastructure Scope** - Clear definition of systems/services involved
- **Reliability Requirements** - Specific uptime, monitoring, health check needs
- **Deployment Approach** - Confirmed bare metal or Docker (with CAIO approval)
- **Automation Scope** - Confirmed manual operations, bash scripts, systemd
- **System State** - Current configuration and operational status
- **Operational Constraints** - Known limitations and compliance requirements
</outputs>

<duration>15-25 minutes</duration>
</phase>

<phase id="2" name="Handoff - Transfer Context to William" gate="handoff_complete">
<description>
Transfer complete operational context to William with clear scope and expected deliverables.

**Handoff Package Must Include:**
- Operational context brief
- Infrastructure requirements
- Reliability specifications
- Deployment approach (bare metal/Docker)
- Automation scope (manual operations)
- Expected deliverables from William
</description>

<actions>
1. **Package operational context** - Assemble complete context brief
2. **Clarify deployment approach** - Explicit bare metal or Docker (CAIO approved)
3. **Clarify automation scope** - Explicit manual operations, NOT Ansible playbooks
4. **Specify expected deliverables** - What William should create
5. **Provide supporting artifacts** - Relevant docs, configs, examples
6. **Invoke William** - Use Task tool with infrastructure context
7. **Confirm handoff** - Verify William has complete operational context
8. **Establish communication** - William knows how to request clarifications
</actions>

<outputs>
- **Handoff Complete** - William has comprehensive operational context
- **Scope Confirmed** - William understands infrastructure requirements
- **Approach Confirmed** - Deployment and automation approaches clear
- **Deliverables Defined** - William knows what to create
- **Communication Open** - Clarification channel established
</outputs>

<duration>10-15 minutes</duration>
</phase>

<phase id="3" name="William Works - Autonomous Infrastructure Development" gate="none">
<description>
William develops operational runbooks, bash scripts, and systemd configurations autonomously. Agent0 does NOT interfere.

**William's Infrastructure Autonomy:**

**Bare Metal Deployment (Default - CURRENT STATE):**
- Creates comprehensive operational runbooks (step-by-step manual procedures)
- Develops bash scripts for deployment repeatability (where appropriate)
- Creates systemd service unit files and configurations
- Develops configuration file templates and examples
- Documents manual validation procedures
- Creates troubleshooting guides and recovery procedures
- Does NOT develop Ansible playbooks (future state)

**Docker Deployment (IF CAIO Approved):**
- Develops Docker configurations per CAIO's direction
- Implements CAIO's containerization requirements
- Follows CAIO's specified approach
- Does NOT independently decide to containerize

**Critical Principles:**
1. William does NOT choose containerization vs. bare metal (CAIO decides)
2. William does NOT develop Ansible playbooks (future state)
3. William creates manual operational procedures with comprehensive documentation
4. Bash scripts supplement documentation, don't replace manual procedures
5. CAIO directs all deployment and automation strategy

**Agent0's Role:** Monitor progress passively, remain available for clarifications, do NOT critique or suggest during development.
</description>

<outputs>
- **Infrastructure Design** - Architecture and operational approach (William creates)
- **Operational Runbooks** - Step-by-step manual procedures (William writes)
- **Bash Scripts** - Deployment repeatability scripts (William develops)
- **Systemd Configurations** - Service unit files (William creates)
- **Configuration Templates** - Config file examples (William provides)
- **Troubleshooting Guides** - Recovery procedures (William documents)
- **Progress Updates** - Periodic status from William
</outputs>

<duration>1-4 hours (varies by infrastructure complexity)</duration>
</phase>

<phase id="4" name="Validation - Verify Operational Deliverables" gate="validation_complete">
<description>
Validate that William's operational deliverables meet requirements. Validate WHAT delivered, not HOW implemented.

**Validation Focus:**
- Requirements Coverage: Do runbooks address all operational requirements?
- Operational Completeness: Are procedures comprehensive and clear?
- Reliability Alignment: Do procedures meet uptime and monitoring needs?
- Deployment Correctness: Is bare metal/Docker approach correct per CAIO direction?
- Documentation Quality: Are runbooks, scripts, configs well-documented?
- Operational Constraints: Are environment limits respected?
</description>

<actions>
1. **Review operational runbooks** - Verify comprehensive step-by-step procedures
2. **Review bash scripts** - Confirm deployment repeatability where appropriate
3. **Review systemd configs** - Validate service management approach
4. **Review configuration templates** - Check config file examples and documentation
5. **Verify requirements coverage** - All operational needs addressed
6. **Verify reliability alignment** - Monitoring, health checks, alerting included
7. **Verify deployment approach** - Bare metal (default) or Docker (CAIO approved) correct
8. **Verify automation scope** - Manual operations approach, NOT Ansible playbooks
9. **Check operational constraints** - Environment limits respected
10. **Request clarifications** - Ask William to explain unclear operational decisions
</actions>

<outputs>
- **Validation Complete** - Operational deliverables meet requirements
- **Requirements Confirmed** - All operational needs addressed
- **Quality Confirmed** - Documentation, runbooks, scripts are comprehensive
- **Approach Confirmed** - Deployment and automation approaches correct
- **Ready for Integration** - Deliverables can be merged into project
</outputs>

<duration>15-30 minutes</duration>
</phase>

<phase id="5" name="Integration - Merge Infrastructure Guidance" gate="integration_complete">
<description>
Integrate William's operational guidance into project deliverables and infrastructure documentation.

**Integration Activities:**
- Add operational runbooks to project procedures
- Add bash scripts to project repository
- Add systemd configs to infrastructure directory
- Add configuration templates to project
- Update infrastructure documentation with operational approach
- Document deployment decisions and rationale
- Capture operational precedents for future reference
</description>

<actions>
1. **Add operational runbooks** - Move runbooks to project procedures directory
2. **Add bash scripts** - Add deployment scripts to infrastructure repository
3. **Add systemd configs** - Add service unit files to appropriate locations
4. **Add config templates** - Include configuration file examples in project
5. **Update infrastructure docs** - Document operational approach and architecture
6. **Document deployment decisions** - Capture WHY bare metal or Docker chosen
7. **Document operational rationale** - Explain infrastructure approach
8. **Update operational precedents** - Capture patterns for future projects
9. **Commit infrastructure changes** - Version control all operational artifacts
10. **Update project documentation** - Reflect new operational procedures
</actions>

<outputs>
- **Operational Runbooks Integrated** - Procedures added to project
- **Bash Scripts Integrated** - Deployment scripts in repository
- **Systemd Configs Integrated** - Service configs in infrastructure directory
- **Configuration Templates Integrated** - Config examples in project
- **Documentation Updated** - Infrastructure approach documented
- **Decisions Captured** - Deployment rationale preserved
- **Precedents Documented** - Operational patterns recorded
</outputs>

<duration>20-40 minutes</duration>
</phase>

<phase id="6" name="Follow-up - Document Lessons and Patterns" gate="followup_complete">
<description>
Document operational lessons learned and infrastructure patterns for future reference.

**Follow-up Components:**
- Coordination summary (what worked well, what to improve)
- Operational lessons (infrastructure insights gained)
- Action items (future coordination improvements)
- Knowledge capture (operational patterns documented)
- Efficiency gains (operational learning for future)
</description>

<actions>
1. **Summarize coordination** - Document what worked well, what to improve
2. **Capture operational lessons** - Infrastructure insights from William's work
3. **Document operational patterns** - Reusable infrastructure approaches
4. **Identify action items** - Improvements for future William coordination
5. **Update operational knowledge** - Add patterns to infrastructure knowledge base
6. **Measure efficiency gains** - Track operational learning over time
7. **Thank William** - Acknowledge infrastructure expertise and guidance
8. **Close coordination** - Mark William orchestration complete
</actions>

<outputs>
- **Coordination Summary** - What worked, what to improve
- **Operational Lessons** - Infrastructure insights gained
- **Action Items** - Future coordination improvements
- **Knowledge Captured** - Operational patterns documented
- **Efficiency Tracked** - Learning progress measured
</outputs>

<duration>15-25 minutes</duration>
</phase>
</phases>

<quality_gates>
<gate name="william_invocation_decision" phase="0">
**Pass Criteria:**
- Decision made using invocation framework
- Rationale for decision documented
- Deployment approach confirmed (bare metal default, Docker if CAIO approved)
- Automation approach confirmed (manual operations current, Ansible future)
- Decision defensible to CAIO

**Fail Actions:**
- Gather more information about infrastructure scope
- Clarify operational requirements
- Confirm deployment approach with CAIO if Docker needed
- Confirm automation approach with CAIO if uncertain
- Return to Phase 0 with additional context
</gate>

<gate name="context_complete" phase="1">
**Pass Criteria:**
- All operational requirements documented
- Infrastructure scope clearly defined
- Reliability expectations specified
- Deployment approach confirmed and documented
- Automation scope confirmed and documented
- Current system state assessed
- Operational constraints identified
- Context brief is comprehensive

**Fail Actions:**
- Gather missing operational requirements
- Clarify infrastructure scope
- Define reliability expectations more specifically
- Confirm deployment approach with CAIO
- Document additional constraints
- Return to Phase 1 context gathering
</gate>

<gate name="handoff_complete" phase="2">
**Pass Criteria:**
- William invoked with structured request
- Complete context brief provided
- Deployment approach explicitly stated
- Automation scope explicitly stated
- Expected deliverables clearly specified
- William acknowledged and began work
- Communication channel established

**Fail Actions:**
- Clarify handoff structure
- Provide missing context elements
- Re-specify deployment approach
- Re-specify automation scope
- Re-invoke William with complete information
</gate>

<gate name="validation_complete" phase="4">
**Pass Criteria:**
- All operational deliverables received
- Requirements coverage verified
- Operational runbooks comprehensive
- Bash scripts appropriate and documented
- Systemd configs correct
- Configuration templates provided
- Reliability requirements met
- Deployment approach correct (bare metal/Docker per CAIO)
- Automation approach correct (manual operations, NOT Ansible playbooks)
- Operational constraints respected

**Fail Actions:**
- Request clarification on unclear operational decisions
- Ask for additional operational documentation
- Confirm deployment approach alignment
- Confirm automation approach alignment
- Resolve operational ambiguities
- Return to Phase 4 validation with clarifications
</gate>

<gate name="integration_complete" phase="5">
**Pass Criteria:**
- Operational runbooks added to project
- Bash scripts added to repository
- Systemd configs added to infrastructure directory
- Configuration templates integrated
- Infrastructure documentation updated
- Deployment decisions documented
- Operational precedents captured

**Fail Actions:**
- Complete missing integration steps
- Document operational decisions
- Capture operational precedents
- Update infrastructure documentation
- Return to Phase 5 to complete integration
</gate>

<gate name="followup_complete" phase="6">
**Pass Criteria:**
- Coordination summary documented
- Operational lessons captured
- Action items identified
- Knowledge captured in infrastructure knowledge base
- Efficiency gains tracked
- William coordination complete

**Fail Actions:**
- Document operational lessons
- Capture infrastructure patterns
- Identify improvement actions
- Update knowledge base
- Return to Phase 6 to complete follow-up
</gate>
</quality_gates>

<autonomous_work_patterns>
<pattern name="Infrastructure Design Autonomy">
**Focus:** William designs infrastructure architecture independently

**Agent0 Role:** Provide operational requirements, trust expertise, don't suggest implementation

**William Autonomy:** Choose architecture, select tools, design monitoring, determine deployment procedures

**Outcome:** Infrastructure reflects William's operational expertise without interference
</pattern>

<pattern name="Runbook Development Autonomy">
**Focus:** William develops operational runbooks independently

**Agent0 Role:** Specify WHAT operational outcomes needed (requirements), William determines HOW (procedures)

**William Autonomy:** Structure runbooks, write procedures, determine validation steps, create troubleshooting guides

**Outcome:** Runbooks reflect William's operational expertise and best practices
</pattern>

<pattern name="Operational Validation Autonomy">
**Focus:** William validates infrastructure design and procedures independently

**Agent0 Role:** Provide operational constraints and reliability requirements

**William Autonomy:** Validate design, test procedures, verify reliability, assess deployment readiness

**Outcome:** Validation reflects William's operational standards
</pattern>

<pattern name="Operational Documentation Autonomy">
**Focus:** William creates operational documentation independently

**Agent0 Role:** Request documentation, don't prescribe format

**William Autonomy:** Create runbooks, write procedures, develop troubleshooting guides, structure documentation

**Outcome:** Documentation reflects William's operational expertise
</pattern>
</autonomous_work_patterns>

<conflict_resolution>
<conflict type="Deployment Approach Disagreement">
**Scenario:** Agent0 or William uncertain about bare metal vs. Docker

**Resolution:**
1. Escalate to CAIO - Deployment approach is CAIO's strategic decision
2. CAIO clarifies containerization decision with rationale
3. William implements CAIO's direction
4. Document CAIO's deployment decision for future reference

**Principle:** CAIO directs all containerization decisions
</conflict>

<conflict type="Automation Strategy Disagreement">
**Scenario:** William suggests Ansible playbooks, agent0 knows it's future state

**Resolution:**
1. Clarify current state is manual operations with documentation
2. Explain Ansible playbooks are future state, not current roadmap
3. Refocus William on manual runbooks, bash scripts, systemd
4. If William believes Ansible is needed, escalate to CAIO for strategic decision

**Principle:** CAIO directs all automation strategy decisions
</conflict>

<conflict type="Operational Requirements Ambiguity">
**Scenario:** William finds operational requirements unclear or contradictory

**Resolution:**
1. William requests clarification from agent0
2. Agent0 gathers additional operational details
3. If still unclear, agent0 consults user/CAIO for clarification
4. Agent0 provides William with clarified requirements
5. William proceeds with clear operational direction

**Principle:** Clear requirements enable quality operational guidance
</conflict>

<conflict type="Infrastructure Scope Expansion">
**Scenario:** William identifies additional infrastructure work beyond original scope

**Resolution:**
1. William documents additional operational needs discovered
2. Agent0 evaluates scope expansion against project goals
3. If expansion is critical operational work → Approve and document scope change
4. If expansion is nice-to-have → Defer to future work
5. Document scope decision and rationale

**Principle:** Operational necessity justifies scope expansion
</conflict>

<conflict type="Timeline Pressure vs. Infrastructure Quality">
**Scenario:** Timeline pressure to skip operational validation or documentation

**Resolution:**
1. **Never compromise operational reliability for speed**
2. Explain infrastructure failures are more expensive than delays
3. If timeline is truly critical → Escalate to CAIO for risk acceptance
4. CAIO makes informed decision on operational quality vs. timeline trade-off

**Principle:** Operational reliability is non-negotiable without CAIO approval
</conflict>
</conflict_resolution>

<escalation_protocols>
<escalation level="1" target="User/CAIO">
**When:** Operational requirements unclear or contradictory

**Process:**
1. Document specific operational ambiguity or contradiction
2. Prepare clarifying questions for user/CAIO
3. Escalate via agent0 with clear operational questions
4. Receive clarified requirements
5. Update operational context and inform William

**Outcome:** Clear operational requirements enable quality infrastructure guidance
</escalation>

<escalation level="2" target="CAIO">
**When:** Deployment approach decision needed (bare metal vs. Docker)

**Process:**
1. Document infrastructure requirements and operational context
2. Present deployment options to CAIO (bare metal default, Docker requires justification)
3. CAIO makes strategic containerization decision
4. Document CAIO's decision and rationale
5. William implements CAIO's direction

**Outcome:** Strategic deployment decisions made at appropriate authority level
</escalation>

<escalation level="3" target="CAIO">
**When:** Automation strategy decision needed (manual vs. future Ansible)

**Process:**
1. Document operational complexity and automation needs
2. Present automation options to CAIO (manual current, Ansible future)
3. CAIO makes strategic automation decision
4. Document CAIO's decision and rationale
5. William implements CAIO's automation direction

**Outcome:** Strategic automation decisions made at appropriate authority level
</escalation>

<escalation level="4" target="William + Frank">
**When:** Infrastructure work has security implications

**Process:**
1. Identify security-infrastructure intersection (firewall rules, OS hardening, etc.)
2. Coordinate BOTH William (infrastructure) and Frank (security)
3. William provides infrastructure approach, Frank provides security requirements
4. Agent0 facilitates alignment between operational reliability and security posture
5. Joint validation ensures infrastructure security WITHOUT compromising operability

**Outcome:** Infrastructure work properly coordinated across operational and security domains
</escalation>
</escalation_protocols>

<guiding_principles>
<principle name="Bare Metal for Production/Staging, Docker for Dev Only">
Production and staging deployments use bare metal (native OS packages + systemd). Docker is ONLY used on dev server for project isolation (Python, React, Next.js development environments). Production/staging Docker requires explicit CAIO approval. Dev server Docker for project isolation is an established pattern and does NOT require CAIO approval for each project. This is a strategic architectural decision. CAIO directs production/staging containerization decisions; dev server Docker usage is standardized.
</principle>

<principle name="Ansible Vault Only - No Playbooks">
Ansible Vault is used for centralized credential management (ONLY Ansible component deployed). Ansible playbooks, roles, and other Ansible automation components are NOT used. William's deliverables are operational runbooks, bash scripts, systemd configurations, Ansible Vault access procedures, and configuration templates—NOT Ansible playbooks or automation. CAIO directs all automation strategy decisions including if/when Ansible playbooks would be adopted. Ansible Vault for credentials is current standard; Ansible automation is not.
</principle>

<principle name="Operational Reliability First">
Infrastructure decisions must prioritize operational reliability over convenience, speed, or simplicity. Reliability requirements (uptime, monitoring, health checks) are non-negotiable. Operational correctness cannot be compromised.
</principle>

<principle name="Respect William's Operational Expertise">
William's infrastructure expertise and operational judgment are trusted implicitly. Agent0 coordinates WITH William, never attempts to replace William's infrastructure knowledge or second-guess operational decisions.
</principle>

<principle name="Manual Operations with Documentation">
Operational procedures must be documented comprehensively with step-by-step runbooks. Bash scripts supplement documentation for repeatability where appropriate. Systemd configurations provide service management. Configuration templates ensure consistency. Manual operations with excellent documentation are the current standard, not technical debt.
</principle>

<principle name="Operational Context Completeness">
Complete infrastructure requirements, reliability specifications, and operational constraints are essential for William's effective work. Time invested in context preparation (Phase 1) yields significantly better infrastructure outcomes.
</principle>

<principle name="Document Operational Decisions">
Infrastructure choices, deployment patterns, and operational rationale must be documented for future reference. Operational knowledge compounds over time when properly captured.
</principle>

<principle name="Quality Over Speed">
Never compromise infrastructure quality or operational reliability for timeline pressure. Operational failures are more expensive than schedule delays. Infrastructure technical debt costs multiply over time.
</principle>

<principle name="Learn Infrastructure Patterns">
Every William coordination should yield documented operational lessons and captured infrastructure patterns. This operational learning reduces future William invocations while maintaining infrastructure quality.
</principle>
</guiding_principles>

<visual_diagrams>
<workflow_diagram>
```
WILLIAM ORCHESTRATION WORKFLOW
══════════════════════════════════════════════════════════════════════════

Phase 0: Decision Point
├─ Evaluate: Does task need William's infrastructure expertise?
├─ Confirm: Bare metal (default) or Docker (CAIO approved)?
├─ Confirm: Manual operations (current) or Ansible (future)?
└─ GATE: william_invocation_decision
    ├─ PASS → Phase 1
    └─ FAIL → Gather more information

Phase 1: Context Preparation
├─ Document: Infrastructure requirements
├─ Define: Reliability expectations
├─ Confirm: Deployment approach (bare metal/Docker)
├─ Confirm: Automation scope (manual operations)
├─ Assess: Current system state
└─ GATE: context_complete
    ├─ PASS → Phase 2
    └─ FAIL → Gather missing operational requirements

Phase 2: Handoff to William
├─ Package: Complete operational context brief
├─ Specify: Expected deliverables (runbooks, scripts, configs)
├─ Clarify: Deployment approach explicitly
├─ Clarify: Automation scope explicitly
├─ Invoke: William with comprehensive context
└─ GATE: handoff_complete
    ├─ PASS → Phase 3
    └─ FAIL → Clarify handoff structure

Phase 3: William Works (Autonomous)
├─ William: Develops operational runbooks
├─ William: Creates bash scripts (where appropriate)
├─ William: Configures systemd services
├─ William: Creates configuration templates
├─ William: Documents troubleshooting procedures
└─ NO GATE (William works autonomously)
    └─ Phase 4

Phase 4: Validation
├─ Verify: Requirements coverage
├─ Verify: Operational runbooks comprehensive
├─ Verify: Bash scripts appropriate
├─ Verify: Systemd configs correct
├─ Verify: Deployment approach correct
├─ Verify: Automation approach correct (manual, NOT Ansible)
└─ GATE: validation_complete
    ├─ PASS → Phase 5
    └─ FAIL → Request clarifications from William

Phase 5: Integration
├─ Add: Operational runbooks to project
├─ Add: Bash scripts to repository
├─ Add: Systemd configs to infrastructure directory
├─ Add: Configuration templates to project
├─ Update: Infrastructure documentation
├─ Document: Deployment decisions and rationale
└─ GATE: integration_complete
    ├─ PASS → Phase 6
    └─ FAIL → Complete missing integration

Phase 6: Follow-up
├─ Document: Coordination summary
├─ Capture: Operational lessons learned
├─ Identify: Future coordination improvements
├─ Update: Infrastructure knowledge base
└─ GATE: followup_complete
    ├─ PASS → Orchestration Complete ✓
    └─ FAIL → Document operational lessons

══════════════════════════════════════════════════════════════════════════
Total Duration: 2-5 hours typical
Success Indicator: Operational infrastructure delivered, tested, documented
```
</workflow_diagram>

<decision_tree>
```
INFRASTRUCTURE COORDINATION DECISION TREE
══════════════════════════════════════════════════════════════════════════

Start: New task requiring infrastructure/operations work?
  │
  ├─ NO → Proceed independently (no infrastructure coordination needed)
  │
  └─ YES → Evaluate operational complexity...
            │
            ├─ Q1: OS configuration, system services, or deployment procedures?
            │   ├─ NO → Continue evaluation
            │   └─ YES → Likely William → CONTINUE TO Q2
            │
            ├─ Q2: Operational runbooks, bash scripts, or systemd configs?
            │   ├─ NO → Continue evaluation
            │   └─ YES → Likely William → CONTINUE TO Q3
            │
            ├─ Q3: Reliability requirements, monitoring, or health checks?
            │   ├─ NO → Continue evaluation
            │   └─ YES → Likely William → CONTINUE TO Q4
            │
            ├─ Q4: Deployment procedures or operational validation?
            │   ├─ NO → Continue evaluation
            │   └─ YES → Likely William → CONTINUE TO Q5
            │
            └─ Q5: Infrastructure architecture or deployment strategy?
                ├─ NO → Probably proceed independently
                └─ YES → DEFINITELY William

COORDINATE WITH WILLIAM if ANY apply:
══════════════════════════════════════════════════════════════════════════
✓ Operating system configuration or system service management
✓ Operational runbook development or deployment procedures
✓ Bash script development for deployment repeatability
✓ Systemd service configuration or service management
✓ Docker container deployment (IF CAIO APPROVED)
✓ System monitoring, health checks, or alerting setup
✓ Backup strategies or disaster recovery procedures
✓ Infrastructure architecture or deployment strategy design
✓ Configuration file templates or operational documentation
✓ Operational reliability requirements or uptime expectations

PROCEED INDEPENDENTLY if ALL apply:
══════════════════════════════════════════════════════════════════════════
✓ No infrastructure changes or operational modifications
✓ No operational runbooks or bash script development
✓ No reliability requirements or operational health concerns
✓ No system deployment or configuration management
✓ Documentation-only or planning-only task
✓ Application-level work (not infrastructure/operations layer)

INFRASTRUCTURE APPROACH GATES (CHECK BEFORE WILLIAM):
══════════════════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────────────────────────┐
│ DEFAULT ASSUMPTIONS: BARE METAL + MANUAL OPERATIONS                    │
├────────────────────────────────────────────────────────────────────────┤
│ Deployment:                                                            │
│ • Native OS packages (apt/dpkg)                                        │
│ • Systemd service management                                           │
│ • Traditional configuration files                                      │
│ • No containerization unless CAIO approved                             │
│                                                                        │
│ Automation:                                                            │
│ • Manual procedures with comprehensive documentation                   │
│ • Bash scripts for repeatability (where appropriate)                  │
│ • Systemd configurations for service management                        │
│ • Configuration file templates                                         │
│ • NO Ansible playbooks (future state)                                 │
│ • Ansible Vault ONLY for credential management                        │
└────────────────────────────────────────────────────────────────────────┘

GATE 1: Is Docker explicitly approved by CAIO for this service?
├─ YES (Documented CAIO approval) → Proceed with Docker per CAIO direction
├─ NO (No approval) → Proceed with BARE METAL (default)
└─ UNCLEAR → STOP → Escalate to CAIO for containerization decision

GATE 2: What operational approach for this deployment?
├─ Manual procedures with documentation (DEFAULT - CURRENT STATE)
├─ Ansible Vault for credentials (APPROVED for credential management)
└─ Ansible playbooks (FUTURE STATE - Do NOT use without CAIO approval)

⚠️ CRITICAL: Do NOT assume Docker without CAIO approval
⚠️ CRITICAL: Do NOT develop Ansible playbooks (future state)
⚠️ CRITICAL: William creates manual runbooks, NOT automation
⚠️ CRITICAL: William implements CAIO's direction, doesn't choose approach

WHEN IN DOUBT:
══════════════════════════════════════════════════════════════════════════
Default to coordinating WITH William. Infrastructure mistakes are expensive,
operational failures impact production. Better to involve William and learn
the operational concerns are simple than to proceed independently and create
reliability problems.

Remember agent0's values: "Quality matters over speed. Accuracy is job 1."
Infrastructure and operations demand accuracy—coordinate WITH William when
operational expertise is needed.
```
</decision_tree>
</visual_diagrams>

<notes>
**Operational Maturity Context:**
HX-Infrastructure is in the manual operations phase with a focus on comprehensive documentation and reliable procedures. Complex automation frameworks (Ansible playbooks, Kubernetes, etc.) are future state considerations, not current implementation. This reflects appropriate operational maturity progression: master manual operations first, automate strategically later with CAIO direction.

**William's Deliverable Focus:**
- Comprehensive step-by-step operational runbooks
- Bash scripts that supplement (not replace) manual procedures
- Systemd service configurations for reliable service management
- Configuration file templates with clear documentation
- Troubleshooting guides for operational support
- Monitoring and health check procedures
- Backup and recovery documentation

**Agent0's Coordination Focus:**
- Provide complete operational requirements to William
- Respect William's infrastructure expertise implicitly
- Validate requirements met, not critique implementation approach
- Integrate operational guidance into project deliverables
- Capture operational precedents for future learning
- Never assume Docker or Ansible without CAIO approval

**CAIO's Strategic Authority:**
- All containerization decisions (bare metal vs. Docker)
- All automation strategy decisions (manual vs. future Ansible)
- Risk acceptance for operational quality vs. timeline trade-offs
- Strategic infrastructure direction for HX-Infrastructure ecosystem

**Comparison with Other Orchestrations:**
- **Alex (Architecture):** Strategic multi-layer architecture decisions
- **Frank (Security):** Identity, DNS, certificates, access control, security posture
- **William (Infrastructure):** Operational procedures, deployment, reliability, system configuration
- All three respect CAIO authority and maintain domain expertise autonomy
</notes>

<related_documents>
**Orchestration Patterns:**
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Alex orchestration (architecture)
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Frank orchestration (security)

**Infrastructure Philosophy:**
- `/home/agent0/HX-Infrastructure/x-claude/williams-review.md` - William orchestration review with CAIO feedback

**Operational Standards:**
- Infrastructure runbook templates (to be created as operational patterns emerge)
- Bash script standards (to be documented from William's deliverables)
- Systemd configuration patterns (to be captured from operational precedents)
</related_documents>

<critical_reminders>
1. ⚠️ **BARE METAL FOR PRODUCTION/STAGING, Docker FOR DEV ONLY:**
   Production and staging use bare metal (native packages, systemd). Docker is ONLY used on dev server for project isolation (Python, React, Next.js environments). Dev server Docker is established pattern (no CAIO approval per project). Production/staging Docker requires explicit CAIO approval. CAIO directs production containerization; dev Docker is standardized.

2. ⚠️ **ANSIBLE VAULT ONLY - NO PLAYBOOKS:**
   Ansible Vault is used for centralized credential management (ONLY Ansible component deployed). Ansible playbooks, roles, and other automation are NOT used. William creates operational runbooks, bash scripts, systemd configs, Ansible Vault access procedures—NOT Ansible playbooks. CAIO directs all automation strategy decisions. Ansible Vault for credentials is current standard; Ansible automation is not.

3. ⚠️ **Operational Reliability Non-Negotiable:**
   Infrastructure decisions must prioritize operational reliability over speed, convenience, or simplicity. Reliability requirements (uptime, monitoring, health checks) cannot be compromised without CAIO risk acceptance.

4. ⚠️ **Trust William's Infrastructure Expertise:**
   William is the infrastructure specialist. Never second-guess William's operational approach, runbook design, or infrastructure architecture decisions. Agent0 coordinates WITH William, not replaces William.

5. ⚠️ **Complete Operational Context Essential:**
   Infrastructure guidance quality directly correlates with context completeness. Invest time in Phase 1 (Context) to provide William with comprehensive operational requirements, reliability specifications, and system state information.

6. ⚠️ **Manual Operations with Documentation:**
   Operational procedures must be documented comprehensively: step-by-step runbooks, bash scripts for repeatability where appropriate, systemd configurations, and configuration templates. Documentation enables operational consistency and knowledge transfer.

7. ⚠️ **Quality Over Speed:**
   Never compromise infrastructure quality or operational reliability for timeline pressure. Operational failures are more expensive than schedule delays. Infrastructure technical debt costs multiply over time.

8. ⚠️ **Document Infrastructure Decisions:**
   Operational rationale, deployment patterns, and infrastructure precedents must be captured for future reference. Operational knowledge compounds when properly documented.

9. ⚠️ **Validate Requirements, Not Expertise:**
   Phase 4 (Validate) confirms William's infrastructure deliverables meet operational requirements—it does NOT critique William's infrastructure expertise or operational judgment.

10. ⚠️ **Learn Operational Patterns:**
    Every William coordination should yield documented infrastructure lessons and captured operational patterns. This operational learning reduces future William invocations while maintaining infrastructure quality.
</critical_reminders>

<validation_checklist>
**Pre-Orchestration Validation:**
- [ ] Infrastructure coordination need clearly justified with operational rationale
- [ ] Deployment approach confirmed: Bare metal (default) or Docker (CAIO approved)
- [ ] Automation approach confirmed: Manual operations (current) or Ansible (future with CAIO approval)
- [ ] Operational requirements documented comprehensively
- [ ] Reliability expectations defined with specific uptime/monitoring needs
- [ ] Current system state assessed and documented
- [ ] Operational constraints identified (environment, compliance, resources)

**Phase 0 Validation:**
- [ ] Decision made using invocation framework (MUST/MAY/DO NOT criteria)
- [ ] Deployment approach gate passed (bare metal default confirmed or Docker CAIO-approved)
- [ ] Automation approach gate passed (manual operations confirmed)
- [ ] Rationale for William coordination documented
- [ ] Decision defensible to CAIO if questioned

**Phase 1 Validation:**
- [ ] Complete operational context brief created for William
- [ ] Infrastructure scope clearly defined with specific systems/services
- [ ] Reliability requirements specified (uptime SLAs, monitoring, health checks)
- [ ] Deployment approach explicitly documented (bare metal/Docker)
- [ ] Automation scope explicitly documented (manual procedures, bash scripts, systemd)
- [ ] Current system state comprehensively assessed
- [ ] Operational dependencies traced and documented
- [ ] Supporting operational artifacts gathered

**Phase 2 Validation:**
- [ ] William invoked with structured handoff request
- [ ] Complete context brief provided to William
- [ ] Deployment approach explicitly stated in handoff
- [ ] Automation scope explicitly stated in handoff
- [ ] Expected deliverables clearly specified (runbooks, scripts, configs)
- [ ] William acknowledged receipt of complete operational context
- [ ] Communication channel for clarifications established

**Phase 4 Validation:**
- [ ] All expected operational deliverables received from William
- [ ] Operational runbooks comprehensive and step-by-step clear
- [ ] Bash scripts appropriate, documented, and supplement manual procedures
- [ ] Systemd configurations correct and well-documented
- [ ] Configuration templates provided with clear examples
- [ ] Requirements coverage verified (all operational needs addressed)
- [ ] Reliability alignment confirmed (monitoring, health checks, alerting)
- [ ] Deployment approach correct per CAIO direction (bare metal/Docker)
- [ ] Automation approach correct (manual operations, NOT Ansible playbooks)
- [ ] Operational constraints respected
- [ ] Documentation quality high (comprehensive, clear, maintainable)

**Phase 5 Validation:**
- [ ] Operational runbooks added to project procedures directory
- [ ] Bash scripts added to project infrastructure repository
- [ ] Systemd configurations added to appropriate infrastructure directory
- [ ] Configuration templates integrated into project
- [ ] Infrastructure documentation updated with operational approach
- [ ] Deployment decisions documented with rationale
- [ ] Operational precedents captured for future reference
- [ ] All infrastructure artifacts version controlled

**Phase 6 Validation:**
- [ ] Coordination summary documented (what worked, what to improve)
- [ ] Operational lessons learned captured
- [ ] Infrastructure patterns documented for future reuse
- [ ] Action items identified for future coordination improvements
- [ ] Knowledge captured in infrastructure knowledge base
- [ ] Efficiency gains tracked (operational learning measured)
- [ ] William coordination formally closed

**Post-Orchestration Validation:**
- [ ] Operational procedures tested in development environment
- [ ] Bash scripts validated for deployment repeatability
- [ ] Systemd services tested for correct startup and management
- [ ] Monitoring and health checks validated
- [ ] Troubleshooting procedures verified
- [ ] Documentation comprehensiveness confirmed
- [ ] Operational readiness for production confirmed
</validation_checklist>

<metadata_footer>
**Workflow Version:** 2.0 (Complete rewrite)
**Status:** APPROVED - Ready for immediate use
**Created:** 2025-11-20
**Purpose:** Establish systematic orchestration patterns for agent0 to coordinate with William (Infrastructure Specialist) with proper infrastructure philosophy
**Key Philosophy:** Bare metal first (Docker requires CAIO approval), manual operations current state (Ansible playbooks future), CAIO directs all deployment and automation strategy
**Infrastructure Maturity:** Manual operations with comprehensive documentation is CURRENT STATE and appropriate for organizational maturity
**Compliance:** Fully compliant with semantic XML documentation standards and CAIO infrastructure mandates
**Related Commands:** cc-orchestrate-alex.md (architecture), cc-orchestrate-frank.md (security)
</metadata_footer>
