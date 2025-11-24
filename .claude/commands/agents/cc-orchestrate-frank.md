---
document: cc-orchestrate-frank
version: 1.1
date: 2025-11-24
status: APPROVED
type: workflow-command
description: Orchestration patterns for coordinating security, identity, and trust infrastructure work with Frank (Security Specialist)
applies_to: security_tasks, identity_management, dns_operations, certificate_management, trust_infrastructure
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Frank Orchestration - Security & Identity Coordination
**Version:** 1.1
**Date:** 2025-11-24
**Status:** APPROVED - Ready for use
**Type:** Agent Orchestration Command
**Agent:** Frank Lucas (Security Specialist)
**Purpose:** Define how agent0 coordinates WITH Frank for security, identity, DNS, and trust infrastructure work
</metadata>

<objective>
**Purpose:** Provide systematic orchestration patterns for agent0 to coordinate security, identity, and trust infrastructure work with Frank (Security Specialist), ensuring proper security context preparation, effective handoffs, security validation, and integration of security guidance into project work.

**What This Achieves:**
- Clear decision criteria for when to invoke Frank vs. work autonomously on security matters
- Systematic security context preparation that enables Frank to provide quality security guidance
- Structured handoff protocols for identity, DNS, certificates, and access control
- Security validation patterns that ensure compliance with security standards
- Integration workflows that incorporate Frank's security requirements into broader project work
- Threat assessment and security risk mitigation strategies

**When to Use This Command:**
- Implementing identity management (Samba Active Directory, user accounts, groups)
- Configuring DNS records and domain management
- Managing certificates (SSL/TLS, certificate lifecycle, CA operations)
- Implementing access control and authentication mechanisms
- Configuring security zones and network boundaries
- Managing encrypted vaults (Ansible Vault, credential storage)
- Security audits and compliance validation
- Implementing security policies and standards

**When NOT to Use:**
- Routine password resets following established procedures
- Simple DNS lookups or queries
- Certificate renewals following automated processes
- Security documentation updates with no policy changes
- Security monitoring that follows established runbooks
</objective>

<workflow_overview>
**High-Level Orchestration Flow:**

```
Decision Point: Do we need Frank?
  → YES: Security Context Preparation
  → Frank Invocation & Handoff
  → Frank Works Independently (agent0 monitors)
  → Security Output Validation
  → Integration & Documentation
  → Security Follow-up Actions
  → NO: Agent0 proceeds autonomously (document decision)
```

**Duration:** 20 minutes - 2 hours (depends on security complexity)
**Participants:** Agent0 (orchestrator), Frank (security specialist), CAIO (approvals)
**Primary Output:** Security guidance integrated into project work
**Secondary Outputs:** Security configurations, DNS records, certificates, access control policies, security documentation
</workflow_overview>

<phases>

<phase id="0" name="Decision Point - Do We Need Frank?" gate="frank_invocation_decision">
<description>
Agent0 evaluates whether the current task requires Frank's security expertise or can be handled autonomously. This gate prevents unnecessary handoffs while ensuring security-critical decisions receive proper expert review.
</description>

<inputs>
- Current task description
- Security implications
- Identity/DNS/certificate requirements
- Access control needs
- Compliance requirements
</inputs>

<actions>
**Evaluate Against Invocation Criteria:**

**MUST Invoke Frank When:**
- Creating or modifying user accounts in Samba Active Directory
- Creating or updating DNS records
- Requesting, issuing, or revoking certificates
- Implementing authentication or authorization mechanisms
- Configuring security zones or network boundaries
- Managing encrypted vaults (Ansible Vault)
- Implementing access control policies
- Security-sensitive configuration changes
- Credential management or rotation
- Security policy implementation
- Compliance validation required

**MAY Invoke Frank When:**
- Security best practices need verification
- Threat assessment would add value
- Security documentation needs review
- Proactive security audit recommended
- Security pattern selection uncertain

**DO NOT Invoke Frank When:**
- Routine password resets following documented procedures
- Simple DNS queries (not record changes)
- Automated certificate renewals following established process
- Security monitoring following runbooks
- Documentation-only updates with no policy impact

**Decision Framework:**
1. Does this involve identity management (users, groups, permissions)? → YES = Invoke Frank
2. Does this require DNS record changes? → YES = Invoke Frank
3. Does this involve certificate operations? → YES = Invoke Frank
4. Does this affect security zones or boundaries? → YES = Invoke Frank
5. Is this a routine operation with clear procedures? → YES = Consider autonomous work
</actions>

<outputs>
- **Decision:** Invoke Frank OR Proceed Autonomously
- **Rationale:** Brief explanation of decision
- **Documentation:** If autonomous, document why Frank not needed
</outputs>

<quality_gate>
**Gate:** Frank Invocation Decision Made
**Criteria:**
- Decision made using framework above
- Security implications assessed
- Rationale documented
- If autonomous: Procedures are clear and proven
- If invoking Frank: Security scope clearly defined

**Pass:** Proceed to Phase 1 (if invoking) or autonomous work (if not)
**Fail:** Gather more security context, clarify scope, consult CAIO if uncertain
</quality_gate>

<duration>5-10 minutes</duration>

<example>
**Scenario 1: New Service Account for Qdrant**
- Evaluation: Requires AD account, DNS record, and service authentication
- Decision: INVOKE FRANK
- Rationale: Identity management and DNS changes require security expertise

**Scenario 2: Routine Password Reset**
- Evaluation: Standard user password reset following documented procedure
- Decision: PROCEED AUTONOMOUSLY
- Rationale: Established procedure with no security policy implications

**Scenario 3: Certificate for New Web Service**
- Evaluation: New SSL certificate needed for public-facing service
- Decision: INVOKE FRANK
- Rationale: Certificate management and trust infrastructure
</example>
</phase>

<phase id="1" name="Security Context Preparation" gate="security_context_complete">
<description>
Agent0 prepares comprehensive security context for Frank to enable effective security guidance. Quality security context preparation directly impacts the quality and speed of Frank's security recommendations.
</description>

<inputs>
- Security requirements
- Service/user identity needs
- Network/zone placement
- Compliance requirements
- Existing security posture
</inputs>

<actions>
**Gather Security Context Documents:**

**Security Standards:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance and security principles
- `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md` - Vault management standards
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Security architecture requirements

**Infrastructure Context:**
- `/home/agent0/HX-Infrastructure/network/network-topology.md` - Security zones and network boundaries
- `/home/agent0/HX-Infrastructure/inventory/nodes.md` - Node inventory and security assignments

**Identity & Access:**
- Review existing Samba AD structure (users, groups, OUs)
- Identify service account requirements
- Determine group memberships needed
- Check existing access control policies

**DNS Requirements:**
- Review current DNS records in HX.DEV.LOCAL domain
- Identify FQDN requirements
- Check for naming convention compliance
- Verify zone assignments

**Certificate Requirements:**
- Identify certificate type (server, client, service)
- Determine certificate authority (internal CA vs. external)
- Review certificate lifecycle requirements
- Check renewal and revocation procedures

**Vault Management:**
- Determine if credentials need encrypted storage
- Identify vault type (service-specific vs. node-specific)
- Review vault access requirements
- Check vault rotation policies

**Prepare Structured Security Context Brief:**
```markdown
**Security Context for Frank**

**Task:** [One-line security task summary]

**Security Scope:**
- Identity requirements: [Users, groups, service accounts]
- DNS requirements: [FQDNs, record types, zones]
- Certificate requirements: [Types, purposes, lifespans]
- Access control: [Permissions, groups, policies]
- Security zones: [Zone placement, boundary rules]
- Vault requirements: [Credential types, access patterns]

**Current Security State:**
- Existing AD structure relevant to task
- Current DNS configuration
- Active certificates
- Current access control policies

**Security Requirements:**
- Compliance requirements
- Security standards applicable
- Threat model considerations
- Access control needs

**Constraints:**
- Timeline constraints
- Compatibility constraints
- Regulatory constraints

**Questions for Frank:**
1. [Specific security question]
2. [Access control question]
3. [Certificate/trust question]

**Desired Outputs:**
- Identity implementation plan (AD users/groups)
- DNS configuration
- Certificate requests/configurations
- Access control policies
- Vault configurations
- Security validation criteria
```
</actions>

<outputs>
- Comprehensive security context brief for Frank
- Loaded security standards and policies
- Current security posture documented
- Specific security questions formulated
- Clear security scope defined
</outputs>

<quality_gate>
**Gate:** Security Context Complete
**Criteria:**
- All security standards reviewed
- Identity/DNS/certificate requirements clear
- Security zone placement determined
- Compliance requirements identified
- Security context brief comprehensive

**Pass:** Security context complete - ready for Frank
**Fail:** Gather missing security information, clarify requirements, refine questions
</quality_gate>

<duration>15-25 minutes</duration>

<rationale>
Frank's security guidance depends on complete security context. Incomplete context leads to generic security advice or missed threat vectors. Time invested in security context preparation prevents security gaps and ensures compliance.
</rationale>
</phase>

<phase id="2" name="Frank Invocation & Handoff" gate="security_handoff_complete">
<description>
Agent0 invokes Frank using structured handoff that provides all necessary security context and clearly defines the security guidance needed. The security handoff structure determines Frank's response quality and security coverage.
</description>

<actions>
**Invoke Frank with Structured Security Request:**

```
@agent-frank

I need security guidance for [task name].

**SECURITY CONTEXT:**
[Paste security context brief from Phase 1]

**SECURITY DOMAINS AFFECTED:**
- Identity Management: [Impact description]
- DNS Operations: [Impact description]
- Certificate Management: [Impact description]
- Access Control: [Impact description]
- Security Zones: [Impact description]
- Vault Management: [Impact description]

**SPECIFIC SECURITY QUESTIONS:**
1. [Security question 1]
2. [Security question 2]
3. [Security question 3]

**DESIRED SECURITY OUTPUTS:**
- Identity implementation plan (AD users, groups, OUs)
- DNS records configuration
- Certificate requests and configurations
- Access control policies
- Vault encryption configurations
- Security validation criteria
- Threat assessment
- Security documentation updates

**SECURITY CONSTRAINTS:**
- [Constraint 1]
- [Constraint 2]

**COMPLIANCE REQUIREMENTS:**
- [Requirement 1]
- [Requirement 2]

Please provide security guidance aligned with HX-Infrastructure security standards and threat model.
```

**Monitor Security Handoff:**
- Confirm Frank acknowledges security request
- Verify Frank reviews security standards
- Note if Frank requests additional security context
- Provide security clarifications immediately
</actions>

<outputs>
- Frank invoked with complete security context
- Security handoff acknowledged
- Frank begins security analysis
</outputs>

<quality_gate>
**Gate:** Security Handoff Complete
**Criteria:**
- Frank invoked successfully
- Security context provided comprehensively
- Security questions clearly stated
- Desired security outputs specified
- Frank acknowledged and began security work
- Compliance requirements communicated

**Pass:** Frank working on security guidance
**Fail:** Clarify security request, provide missing context, re-invoke if needed
</quality_gate>

<duration>5-10 minutes</duration>
</phase>

<phase id="3" name="Frank Works Independently" gate="none">
<description>
Frank conducts security analysis, reviews threat models, evaluates access controls, and prepares security recommendations. Agent0 monitors but does not interrupt this phase.
</description>

<actions>
**Agent0 Monitoring (Non-Intrusive):**
- Observe Frank's security analysis approach
- Note security considerations Frank raises
- Watch for requests for additional security context
- Prepare to answer security follow-up questions
- DO NOT interrupt Frank's security work

**If Frank Requests Additional Security Context:**
- Provide immediately and clearly
- Ensure security context is complete
- Confirm Frank has security information needed

**Learning Opportunity:**
- Observe Frank's security reasoning
- Note threat vectors Frank identifies
- Understand security best practices applied
- Build agent0 security knowledge
</actions>

<outputs>
- Frank completes security analysis
- Frank prepares security recommendations
- (Agent0 gains security knowledge)
</outputs>

<duration>15-35 minutes (variable based on security complexity)</duration>

<note type="best_practice">
**Do Not Rush Security Analysis:** Quality security guidance requires time for Frank to:
- Review security standards and policies
- Evaluate threat models and attack vectors
- Validate access control requirements
- Check certificate trust chains
- Verify vault encryption configurations
- Ensure compliance with security governance

Rushing security analysis produces incomplete threat coverage and potential vulnerabilities.
</note>
</phase>

<phase id="4" name="Security Output Validation" gate="security_guidance_validated">
<description>
Agent0 validates Frank's security guidance for completeness, security coverage, implementability, and compliance alignment. This gate ensures agent0 understands and can safely implement Frank's security recommendations.
</description>

<inputs>
- Frank's security recommendations
- Expected security outputs from Phase 2
- Security requirements
- Compliance criteria
</inputs>

<actions>
**Validate Against Expected Security Outputs:**

**Check for Security Completeness:**
- [ ] Identity implementation plan present (users, groups, permissions)
- [ ] DNS configuration specified (records, zones, FQDNs)
- [ ] Certificate plan provided (requests, configurations, lifecycle)
- [ ] Access control policies defined
- [ ] Vault configurations specified (encryption, access)
- [ ] Security validation criteria clear and testable
- [ ] Threat assessment included
- [ ] Security documentation updates identified

**Check for Security Coverage:**
- [ ] Threat model addresses relevant attack vectors
- [ ] Access controls follow principle of least privilege
- [ ] Certificate trust chains validated
- [ ] Vault encryption meets standards
- [ ] Network boundaries respected
- [ ] Compliance requirements satisfied

**Check for Implementability:**
- [ ] All security recommendations are actionable
- [ ] DNS records follow naming conventions
- [ ] Certificate requests have required information
- [ ] AD operations are sequenced properly
- [ ] Vault operations are executable
- [ ] Security configurations are testable

**Check for Compliance Alignment:**
- [ ] Constitution security principles followed
- [ ] Credential management standards met
- [ ] Architecture security standards satisfied
- [ ] Security zone boundaries maintained
- [ ] Documentation requirements fulfilled

**If Security Validation Issues Found:**
1. Ask Frank for security clarification
2. Request additional threat analysis
3. Confirm understanding of security controls
4. Resolve security ambiguities before proceeding
</actions>

<outputs>
- Validated security guidance
- Confirmed security understanding
- Security clarifications obtained
- Ready for secure implementation
</outputs>

<quality_gate>
**Gate:** Security Guidance Validated
**Criteria:**
- All expected security outputs received
- Security recommendations are comprehensive
- Agent0 understands how to implement securely
- Threat model is adequate
- Compliance requirements satisfied
- Security controls are testable

**Pass:** Proceed to Phase 5 (Integration)
**Fail:** Request security clarification from Frank, resolve gaps, validate again
</quality_gate>

<duration>10-20 minutes</duration>

<rationale>
Security validation prevents security gaps and vulnerabilities. Agent0 must fully understand security requirements before implementation. Better to clarify security now than discover vulnerabilities in production.
</rationale>
</phase>

<phase id="5" name="Integration & Documentation" gate="security_integrated">
<description>
Agent0 integrates Frank's security guidance into project workflow, implements security controls, updates security documentation, and ensures security requirements are captured for audit and compliance purposes.
</description>

<actions>
**Integrate Security Guidance into Project Work:**

**Update Project Artifacts:**
- Update charter with security requirements (if charter phase)
- Update specification with security implementation (if spec phase)
- Update task breakdown with security sequencing (if task phase)
- Update RAIDD log with security risks and mitigations

**Implement Identity Management:**
```powershell
# Create AD users/groups per Frank's plan
# Example structure (actual commands provided by Frank):
# New-ADUser -Name "svc-qdrant" -Path "OU=ServiceAccounts,DC=hx,DC=dev,DC=local"
# Add-ADGroupMember -Identity "QdrantAdmins" -Members "svc-qdrant"
```

**Implement DNS Configuration:**
```bash
# Add DNS records per Frank's specifications
# Example (actual records provided by Frank):
# hx-qdrant-server.hx.dev.local A 192.168.10.XXX
# Update zone file and reload
```

**Implement Certificate Management:**
```bash
# Request certificates per Frank's plan
# Configure certificate storage and permissions
# Set up renewal automation
```

**Configure Vault Encryption:**
```bash
# Create encrypted vaults per Frank's specifications
# Example:
# ansible-vault create /path/to/service-vault.yml
# ansible-vault create /path/to/node-vault.yml
# Set appropriate permissions and access controls
```

**Update Security Documentation:**
- `/home/agent0/HX-Infrastructure/network/network-topology.md` - If security zones affected
- `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md` - If vault procedures changed
- Document security decisions in project records

**Document Security Implementation:**
- Security controls implemented
- Access control policies applied
- Certificate lifecycle procedures
- Vault access procedures
- Security testing criteria

**Capture Security Lessons Learned:**
- Threat vectors identified
- Security patterns applied
- Compliance validations performed
- Security improvements discovered
</actions>

<outputs>
- Security guidance integrated into project artifacts
- Identity management implemented
- DNS records configured
- Certificates requested/configured
- Vault encryption established
- Security documentation updated
- Security lessons learned captured
</outputs>

<quality_gate>
**Gate:** Security Integrated
**Criteria:**
- Project artifacts reflect security requirements
- Identity management implemented correctly
- DNS records configured and verified
- Certificates requested/installed
- Vault encryption configured properly
- Security documentation updated
- Security validation criteria defined

**Pass:** Security fully integrated - ready for validation
**Fail:** Complete missing security implementations, update documentation
</quality_gate>

<duration>20-40 minutes</duration>
</phase>

<phase id="6" name="Security Follow-up Actions" gate="security_orchestration_complete">
<description>
Agent0 executes security follow-up actions including coordinating with other agents, validating security implementations, conducting security testing, and ensuring security posture throughout execution.
</description>

<actions>
**Coordinate with Other Agents (as needed):**

**If Architecture Implications → Consult Alex:**
- Provide Frank's security zone assignments
- Verify architectural alignment with security requirements
- Ensure security controls don't conflict with architecture

**If Infrastructure Implementation → Invoke William:**
- Provide Frank's security configurations
- Request infrastructure deployment with security controls
- Ensure operational standards include security measures

**If Security Testing Required → Invoke Julia:**
- Provide Frank's security validation criteria
- Request security test plan (penetration testing, vulnerability scanning)
- Ensure quality gates include security testing

**Validate Security Implementation:**
- Verify AD users/groups created correctly
- Test DNS resolution for new records
- Validate certificate installation and trust chains
- Confirm vault encryption and access controls
- Test access control policies
- Verify security zone boundaries

**Conduct Security Testing:**
- Authentication testing
- Authorization testing  
- Certificate validation
- Vault access testing
- Security boundary testing
- Compliance validation

**Security Monitoring Setup:**
- Configure security logging
- Set up security alerts
- Establish security metrics
- Document security baseline

**Update CAIO:**
- Summarize security implementations
- Highlight security risks and mitigations
- Request approval for security exceptions (if any)
- Document CAIO security decisions in RAIDD log
</actions>

<outputs>
- Other agents coordinated (if needed)
- Security implementation validated
- Security testing completed
- Security monitoring established
- CAIO updated and security approvals obtained
- Security orchestration cycle complete
</outputs>

<quality_gate>
**Gate:** Security Orchestration Complete
**Criteria:**
- All security follow-up actions executed
- Other agents coordinated successfully (if needed)
- Security implementation validated and tested
- Security monitoring operational
- No critical security findings
- CAIO security approvals obtained (if required)
- Project can proceed securely

**Pass:** Frank orchestration complete - continue project work securely
**Fail:** Address security gaps, re-coordinate agents, retest security
</quality_gate>

<duration>20-50 minutes (variable based on security coordination needs)</duration>
</phase>

</phases>

<quality_gates>
<gate name="frank_invocation_decision" phase="0">
**Pass Criteria:**
- Decision made using security invocation framework
- Security implications assessed thoroughly
- Rationale for decision documented
- If autonomous: Security procedures are clear and proven
- If invoking Frank: Security scope clearly defined
- Decision is defensible from security perspective

**Fail Actions:**
- Gather more security context and threat information
- Clarify security implications
- Consult CAIO if security uncertainty exists
- Return to Phase 0 with additional security context
</gate>

<gate name="security_context_complete" phase="1">
**Pass Criteria:**
- All security standards reviewed
- Identity/DNS/certificate requirements clearly defined
- Security zone placement determined
- Threat model considerations documented
- Compliance requirements identified
- Security context brief comprehensive and clear
- Existing security posture documented

**Fail Actions:**
- Gather missing security documentation
- Clarify security requirements
- Document threat considerations
- Identify compliance obligations
- Return to Phase 1 security context gathering
</gate>

<gate name="security_handoff_complete" phase="2">
**Pass Criteria:**
- Frank invoked with structured security request
- Complete security context brief provided
- Security questions clearly stated
- Desired security outputs specified
- Compliance requirements communicated
- Frank acknowledged request and began security work

**Fail Actions:**
- Clarify security request structure
- Provide missing security context
- Re-specify expected security outputs
- Re-invoke Frank with complete security information
</gate>

<gate name="security_guidance_validated" phase="4">
**Pass Criteria:**
- All expected security outputs received from Frank
- Security recommendations are comprehensive
- Agent0 understands how to implement securely
- Threat model adequately addresses attack vectors
- Access controls follow least privilege principle
- Compliance requirements satisfied
- Security controls are testable

**Fail Actions:**
- Request security clarification from Frank
- Ask for additional threat analysis
- Confirm understanding of security controls
- Resolve security ambiguities
- Return to Phase 4 validation with clarifications
</gate>

<gate name="security_integrated" phase="5">
**Pass Criteria:**
- Project artifacts updated with security requirements
- Identity management implemented correctly
- DNS records configured and verified
- Certificates requested/installed properly
- Vault encryption configured correctly
- Access control policies applied
- Security documentation updated thoroughly

**Fail Actions:**
- Complete missing security implementations
- Fix identity/DNS/certificate configurations
- Update security documentation
- Clarify security integration points
- Return to Phase 5 to complete security integration
</gate>

<gate name="security_orchestration_complete" phase="6">
**Pass Criteria:**
- All security follow-up actions executed
- Other agents coordinated successfully (if needed)
- Security implementation validated through testing
- Security monitoring operational
- No critical security findings remain unresolved
- CAIO security approvals obtained (if required)
- Security posture is acceptable for production

**Fail Actions:**
- Address critical security findings
- Re-coordinate with other agents on security
- Complete additional security testing
- Obtain missing CAIO security approvals
- Return to Phase 6 to resolve security issues
</gate>
</quality_gates>

<autonomous_work_patterns>
**When Agent0 Can Work Without Frank:**

<pattern name="Routine Password Resets">
**Scenario:** Resetting user passwords following established procedures

**Criteria:**
- Standard password reset procedure exists and is documented
- User identity is verified
- Password policy is clear
- No security policy changes involved
- Reset follows helpdesk runbook

**Agent0 Actions:**
- Follow documented password reset procedure
- Verify user identity per standard process
- Apply password policy requirements
- Document password reset action
- Consult Frank only if unusual circumstances arise
</pattern>

<pattern name="DNS Queries (Non-Changes)">
**Scenario:** Looking up existing DNS records for troubleshooting

**Criteria:**
- No DNS record changes required
- Query is for troubleshooting or verification
- No security implications
- Standard diagnostic activity

**Agent0 Actions:**
- Perform DNS queries using standard tools
- Document findings
- Use information for troubleshooting
- Consult Frank only if DNS changes are needed
</pattern>

<pattern name="Automated Certificate Renewals">
**Scenario:** Certificates renewing via automated process

**Criteria:**
- Certificate renewal is automated
- Renewal follows established process
- No certificate policy changes
- Automation is tested and proven
- Monitoring confirms successful renewal

**Agent0 Actions:**
- Verify automation executed successfully
- Confirm new certificate installed
- Test certificate validity
- Document renewal completion
- Consult Frank only if automation fails
</pattern>

<pattern name="Learning from Frank">
**Scenario:** Building agent0's security knowledge over time

**Goal:** Reduce Frank invocations for routine security tasks while maintaining security posture

**Approach:**
- Study Frank's security recommendations and threat analyses
- Understand security patterns Frank frequently applies
- Learn compliance and policy requirements
- Build confidence in routine security scenarios
- Always defer to Frank for novel or high-risk security decisions
- When uncertain about security, consult Frank (security cannot be compromised)
</pattern>
</autonomous_work_patterns>

<conflict_resolution>
**Handling Security Conflicts:**

<scenario name="Frank's Security Requirements vs. Operational Constraints">
**Situation:** Frank recommends security controls that conflict with operational requirements or timelines

**Resolution Protocol:**
1. **Understand Security Rationale:**
   - Document Frank's threat model and security reasoning
   - Understand specific threats being mitigated
   - Identify non-negotiable security requirements

2. **Assess Risk Tradeoffs:**
   - Can security controls be phased in?
   - Are there alternative controls that meet security objectives?
   - What are consequences of not implementing controls?

3. **Escalate to CAIO if Needed:**
   - Present security requirements and operational constraints
   - Explain risk tradeoffs clearly
   - Recommend approach if possible
   - Request CAIO security decision

4. **Document Security Decision:**
   - Document security risk acceptance if controls deferred
   - Create security backlog item for future implementation
   - Add to RAIDD log as security risk/assumption
   - Establish security monitoring to detect threats
</scenario>

<scenario name="Frank's Security Approach vs. Other Agent's Implementation">
**Situation:** Frank requires security controls that conflict with Alex's architecture or William's infrastructure approach

**Resolution Protocol:**
1. **Convene Multi-Agent Discussion:**
   - Bring Frank, Alex/William, and agent0 together
   - Present security requirements and architectural/operational constraints
   - Explore alternative approaches

2. **Security-First Principle:**
   - Security requirements generally take precedence
   - Find implementation approaches that satisfy security AND operational needs
   - Security cannot be compromised for convenience

3. **Escalate if Unresolved:**
   - Present conflict to CAIO
   - Explain security implications clearly
   - Request CAIO decision
   - Document decision and rationale

4. **Implement with Security Priority:**
   - Implement solution that meets security requirements
   - Document any accepted security risks
   - Establish compensating controls if needed
</scenario>

<scenario name="Security Guidance Unclear or Incomplete">
**Situation:** Frank's security guidance doesn't fully address the security requirements or creates ambiguity

**Resolution Protocol:**
1. **Request Security Clarification from Frank:**
   - Be specific about security ambiguity
   - Provide threat scenarios if helpful
   - Ask for additional security detail

2. **If Still Unclear:**
   - Consult CAIO for security interpretation
   - Document security ambiguity in RAIDD log
   - Request Frank revisit security guidance
   - Do not implement until security clarity achieved
   - Security ambiguity is a security risk
</scenario>
</conflict_resolution>

<escalation_protocols>
**When to Escalate Beyond Frank:**

<escalation level="1" target="Frank">
**Scenarios:**
- Identity management (users, groups, permissions)
- DNS record changes
- Certificate operations
- Access control implementation
- Security zone configuration
- Vault encryption management
- Security policy implementation
- Threat assessment required

**Process:** Follow this workflow (Phases 0-6)
</escalation>

<escalation level="2" target="CAIO">
**Scenarios:**
- Security risk acceptance decision needed
- Frank unavailable and urgent security decision required
- Conflict between security requirements and operational constraints
- Security policy exception needed
- Major security incident response
- Compliance violation or risk
- Strategic security direction decision

**Process:**
1. Document security issue clearly
2. Present security options with risk tradeoffs
3. Provide security recommendation (if possible)
4. Request CAIO security decision
5. Document security decision in RAIDD log
6. Implement with security monitoring
</escalation>

<escalation level="3" target="Security Review Board">
**Scenarios:**
- Security decision with ecosystem-wide implications
- Novel security threats not covered by existing policies
- Cross-project security conflicts
- Security architecture evolution decisions
- Major compliance or regulatory issues

**Process:**
1. Prepare comprehensive security analysis
2. Convene review with Frank, affected agents, CAIO
3. Present security analysis and options
4. Facilitate security discussion
5. Reach consensus or escalate to CAIO for security decision
6. Document extensively (security policies + meeting notes)
</escalation>
</escalation_protocols>

<guiding_principles>
<principle name="Security First">
Security is not negotiable. When in doubt about security, invoke Frank. The cost of security breaches far exceeds the time investment in proper security consultation. Security must never be compromised for convenience or speed.
</principle>

<principle name="Defense in Depth">
Frank's security guidance typically includes multiple layers of security controls. Implement all recommended security controls, not just the minimum. Layered security protects against sophisticated threats.
</principle>

<principle name="Least Privilege">
Access control follows principle of least privilege. Grant minimum permissions necessary for function. Start restrictive and expand only when justified. Excessive permissions are security vulnerabilities.
</principle>

<principle name="Security Documentation">
Security implementations must be thoroughly documented. Document security decisions, threat models, access controls, and security configurations. Undocumented security is unmaintainable security.
</principle>

<principle name="Compliance is Mandatory">
Compliance requirements are not optional. Frank's guidance ensures compliance with security governance and regulatory requirements. Non-compliance creates legal and operational risks.
</principle>

<principle name="Threat-Aware">
Always consider threat model. Frank evaluates threats and attack vectors. Understand the threats being mitigated by security controls. Threat awareness improves security decision-making.
</principle>

<principle name="Security Testing">
All security implementations must be tested. Security controls that aren't tested are security assumptions, not security assurances. Testing validates that security controls work as intended.
</principle>
</guiding_principles>

<visual_diagrams>
<workflow_diagram>
```
┌─────────────────────────────────────────┐
│ Phase 0: Decision Point                 │
│ Do We Need Frank?                       │
└─────────┬───────────────────────────────┘
          │
     ┌────┴────┐
     │  NEED   │
     │  FRANK? │
     └─┬─────┬─┘
       │     │
   YES │     │ NO
       │     │
       │     └──────────────────────────────┐
       │                                    │
       ↓                                    ↓
┌─────────────────────────────────────┐   ┌────────────────────────────┐
│ Phase 1: Security Context Prep     │   │ Agent0 Works Autonomously  │
│ (Standards, threats, requirements)  │   │ (Document decision)        │
└─────────────┬───────────────────────┘   └────────────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Security│
       │ Context Ready│
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 2: Frank Invocation & Handoff│
│ (Structured security request)       │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Security│
       │ Handoff Done │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 3: Frank Works Independently  │
│ (Security analysis, threat model)   │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 4: Security Output Validation │
│ (Validate coverage, compliance)     │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Security│
       │   Validated  │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 5: Integration & Documentation│
│ (Implement security, update docs)   │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Security│
       │  Integrated  │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ Phase 6: Security Follow-up Actions │
│ (Test, validate, monitor)           │
└─────────────┬───────────────────────┘
              ↓
       ┌──────────────┐
       │ GATE: Security│
       │   Complete   │
       └──────┬───────┘
              ↓
┌─────────────────────────────────────┐
│ ✓ Continue Project Work             │
│ (Security Assured)                  │
└─────────────────────────────────────┘
```
</workflow_diagram>

<decision_tree>
```
NEED FRANK? Decision Tree
=========================

Does this involve identity management (users/groups)?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Does this require DNS record changes?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Does this involve certificate operations?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Does this affect security zones or boundaries?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Does this involve access control changes?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Does this require vault/credential management?
├─ YES → INVOKE FRANK
└─ NO → Continue...

Is this a routine operation with clear security procedures?
├─ YES → WORK AUTONOMOUSLY
└─ NO → Continue...

Does this have any security implications?
├─ YES → INVOKE FRANK
└─ NO → WORK AUTONOMOUSLY (document decision)

When in doubt about security → INVOKE FRANK
(Security cannot be compromised)
```
</decision_tree>

<timeline_estimate>
```
Phase 0:   5-10 min   (Decision point)
Phase 1:   15-25 min  (Security context prep)
Phase 2:   5-10 min   (Frank invocation)
Phase 3:   15-35 min  (Frank security analysis)
Phase 4:   10-20 min  (Security validation)
Phase 5:   20-40 min  (Security integration)
Phase 6:   20-50 min  (Security follow-up)
──────────────────────
TOTAL:     ~20 min - 2 hours

Simple security tasks: 20-40 min
Medium security complexity: 40-90 min
Complex security implementations: 90-120 min
```
</timeline_estimate>
</visual_diagrams>

<notes>
<note type="agent_persona">
**About Frank Lucas:**

Frank is the Security Specialist for HX-Infrastructure, responsible for:
- Identity management (Samba Active Directory)
- DNS operations (HX.DEV.LOCAL domain)
- Certificate management (CA operations, SSL/TLS)
- Access control and authentication
- Security zones and network boundaries
- Vault management (Ansible Vault)
- Security policies and compliance
- Threat assessment and security architecture

**Frank's Security Domain:**
- Windows Active Directory (Samba AD)
- DNS zones and records
- PKI and certificate lifecycle
- LDAP and directory services
- Security policies and governance
- Encrypted vault management
- Network security boundaries

**Frank's Response Structure:**
- Threat Assessment (attack vectors, risks)
- Security Recommendations (controls, policies)
- Identity Implementation (users, groups, permissions)
- DNS Configuration (records, zones)
- Certificate Plan (requests, configurations)
- Access Control Policies (permissions, groups)
- Vault Configurations (encryption, access)
- Security Validation Criteria (testing requirements)
- Compliance Verification (standards alignment)

Agent0 should expect this structure and validate against it.
</note>

<note type="orchestration_philosophy">
**Why Orchestration vs. Impersonation:**

Agent0 does not "act as Frank" because:
1. Frank has deep security expertise and threat modeling knowledge agent0 lacks
2. Frank's security judgment is honed through security analysis experience
3. Security requires expert evaluation, not surface-level security checklists
4. Security vulnerabilities from amateur security decisions are costly

Agent0's role is to:
- Recognize when Frank's security expertise is needed
- Prepare security context that enables Frank to provide comprehensive security guidance
- Validate and implement Frank's security controls
- Coordinate Frank's security work with other agents
- Learn from Frank to improve security awareness over time

Security is too critical to improvise. Expert consultation is essential.
</note>

<note type="learning_pattern">
**Agent0's Security Growth:**

Over time, agent0 should:
- Recognize common security patterns Frank recommends
- Understand threat vectors and attack models
- Build confidence in routine security tasks
- Reduce Frank invocations for well-understood security procedures
- Develop security awareness and threat consciousness

**But Always:**
- Defer to Frank for novel or high-risk security decisions
- Consult Frank when uncertain about security
- Never compromise security for convenience
- Document autonomous security decisions

**Growth Metrics:**
- Can agent0 identify when to invoke Frank correctly? (Phase 0 security judgment)
- Does agent0 prepare complete security context? (Phase 1 validation pass rate)
- Can agent0 validate Frank's security guidance effectively? (Phase 4 quality)
- Does agent0 implement security thoroughly? (Phase 5 completeness)
- Does agent0 conduct adequate security testing? (Phase 6 validation)

Improvement in these areas indicates agent0 is learning security practices.
</note>
</notes>

<related_documents>
**Frank's Agent File:**
- `/home/agent0/HX-Infrastructure/x-agents/security-specialist-frank.md` - Frank's system prompt and configuration

**Security Standards:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance and security principles
- `/home/agent0/HX-Infrastructure/standards/credentials-vault-management.md` - Vault management standards
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Security architecture requirements

**Infrastructure Documentation:**
- `/home/agent0/HX-Infrastructure/network/network-topology.md` - Security zones and boundaries
- `/home/agent0/HX-Infrastructure/inventory/nodes.md` - Node inventory and security assignments

**Identity & DNS:**
- Samba Active Directory configuration (HX.DEV.LOCAL domain)
- DNS zone files and configuration
- LDAP directory structure

**Certificate Management:**
- Internal CA configuration
- Certificate lifecycle procedures
- Trust chain documentation

**Other Orchestration Commands:**
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Architecture coordination
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - Infrastructure coordination
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Testing coordination

**Core Workflows:**
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter creation (where security requirements defined)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Specification (where security implemented)
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task breakdown (where security validated)

**Security Templates:**
- Security policy templates
- Access control policy templates
- Threat assessment templates
</related_documents>

<critical_reminders>
**⚠️ NEVER Compromise Security for Convenience:**
Security requirements are not optional. When Frank identifies security controls needed, they must be implemented. Skipping security controls or deferring them for convenience creates vulnerabilities. Security first, always.

**⚠️ ALWAYS Validate Identity Before Access:**
Never grant access or permissions without proper identity verification. Frank's identity management guidance ensures proper authentication. Unauthorized access is a critical security failure.

**⚠️ DO NOT Skip Security Testing:**
All security implementations must be tested. Security controls that aren't validated through testing are assumptions, not assurances. Phase 6 security testing is mandatory, not optional.

**⚠️ ALWAYS Document Security Decisions:**
Every security decision, risk acceptance, and control implementation must be documented. Undocumented security is unmaintainable and unauditable. Security documentation is compliance evidence.

**⚠️ COORDINATE Security Across All Domains:**
Security affects architecture (Alex), infrastructure (William), and testing (Julia). Phase 6 coordination ensures security controls are consistently implemented across all domains. Security gaps emerge from siloed work.

**⚠️ WHEN IN DOUBT About Security, Invoke Frank:**
Security uncertainty is security risk. If uncertain whether Frank's expertise is needed, err on the side of security consultation. The cost of security breaches far exceeds consultation time.

**⚠️ DO NOT Implement Security Without Threat Understanding:**
Frank's threat assessment explains WHY security controls are needed. Understand the threats before implementing controls. Security controls without threat understanding lead to incomplete security.

**⚠️ ALWAYS Use Principle of Least Privilege:**
Grant minimum permissions necessary. Excessive permissions are security vulnerabilities waiting to be exploited. Start restrictive and justify expansions. Frank's access control guidance ensures least privilege.
</critical_reminders>

<validation_checklist>
**Before Using This Orchestration Command:**
- [ ] All phases have clear descriptions and actions
- [ ] Quality gates have explicit pass/fail criteria
- [ ] Security decision framework (Phase 0) is comprehensive
- [ ] Security context preparation (Phase 1) covers all security domains
- [ ] Security validation criteria (Phase 4) ensure adequate coverage
- [ ] Security integration requirements (Phase 5) are thorough
- [ ] Security follow-up actions (Phase 6) include testing and monitoring
- [ ] Autonomous work patterns preserve security posture
- [ ] Conflict resolution protocols prioritize security
- [ ] Escalation paths are clear for security decisions
- [ ] All security standards references are accurate
- [ ] Visual diagrams accurately represent security workflow
- [ ] Guiding principles reflect security-first culture
- [ ] Related documents include all security resources
- [ ] XML tags properly nested and closed
- [ ] No markdown headings used (XML tags only)
</validation_checklist>

<metadata_footer>
**Workflow Version:** 1.0
**Status:** APPROVED - Ready for immediate use
**Created:** 2025-11-20
**Last Updated:** 2025-11-20
**Purpose:** Establish systematic orchestration patterns for agent0 to coordinate with Frank (Security Specialist)
**Key Innovation:** Security-first orchestration ensuring identity, DNS, certificates, and access control are properly managed
**Compliance:** Fully compliant with semantic XML documentation standards
**Security Focus:** Emphasizes threat-aware decision making, defense in depth, and mandatory security testing
**Next Steps:** Apply learnings to William (infrastructure) and Julia (testing) orchestration commands
**Related Commands:** cc-orchestrate-alex.md (complete), cc-orchestrate-william.md (pending), cc-orchestrate-julia.md (pending), cc-agent-zero-synthesis.md (pending)
</metadata_footer>
