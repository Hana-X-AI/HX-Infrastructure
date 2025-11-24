# HX-Infrastructure Orchestration Quick Reference

**Version**: 1.0  
**Last Updated**: 2025-11-15  
**Companion To**: hx-orchestration-guide.md

---

## 🎯 Purpose

Fast reference for multi-agent orchestration patterns in HX-Infrastructure. For detailed workflows and comprehensive guidance, see `hx-orchestration-guide.md`.

---

## 👥 Agent Quick Reference

### Layer Structure (7 Layers + Utilities)

| Layer | Role | Agent Count | Primary Function |
|-------|------|-------------|------------------|
| **Layer 1** | Lead Agent | 1 | Alex - Coordination & delegation |
| **Layer 2** | Managers | 4 | Project management & oversight |
| **Layer 3** | Architects | 5 | Design & architecture decisions |
| **Layer 4** | Leads | 6 | Technical leadership by domain |
| **Layer 5** | Seniors | 7 | Complex implementation |
| **Layer 6** | Engineers | 7 | Standard implementation |
| **Layer 7** | Developers | 5 | Focused development tasks |
| **Utility** | Specialists | 8 | Specialized support functions |
| **Other** | Support | 2 | Additional capabilities |

**Total**: 32 agents (5 Core Team SMEs + 27 Technology SMEs)

### Agent Invocation Format

```
@<agent-name> <task-description>

Example:
@david Create test plan for <service-name> deployment
@maya Review architecture for <component-name> integration
```

---

## 📋 Common Orchestration Patterns

### Pattern 1: Service Deployment

```
Workflow: Specification → Planning → Development → Testing → Deployment

1. @alex     Coordinate <service-name> deployment
2. @maya     Review architecture compliance
3. @david    Create deployment plan
4. @sarah    Develop implementation tasks
5. @olivia   Create test suite
6. @henry    Execute deployment
7. @iris     Verify and validate

Quality Gates:
- Specification review (architect approval)
- Test coverage 100% (testing standards)
- Documentation complete (documentation requirements)
```

### Pattern 2: Infrastructure Documentation

```
Workflow: Discovery → Documentation → Review → Validation

1. @alex     Coordinate documentation effort
2. @chris    Define documentation structure
3. @emma     Document current state
4. @frank    Create procedures
5. @grace    Review accuracy
6. @iris     Validate completeness

Quality Gates:
- Standards compliance check
- Peer review approval
- Template adherence validation
```

### Pattern 3: Test Execution

```
Workflow: Plan → Develop → Execute → Report

1. @alex     Initiate testing cycle
2. @olivia   Create test plan
3. @paul     Develop test cases
4. @quinn    Execute tests
5. @rachel   Document results
6. @david    Review and sign-off

Quality Gates:
- Test plan approval
- 100% test case coverage
- All defects documented
```

### Pattern 4: Defect Management

```
Workflow: Report → Triage → Fix → Verify → Close

1. @<discoverer> Report defect (use defect-template.md)
2. @alex         Triage and assign
3. @<developer>  Implement fix
4. @<tester>     Verify resolution
5. @alex         Close defect

Severity Levels: critical | high | medium | low
```

### Pattern 5: Knowledge Integration

```
Workflow: Identify → Research → Document → Share

1. @alex              Identify knowledge need
2. @technical-researcher  Research topic
3. @context-manager   Organize information
4. @<domain-expert>   Document findings
5. @alex              Share with team

Knowledge Locations:
- hx-knowledge/repos/ - Repository references
- hx-knowledge/docs/  - Documentation
- See: hx-knowledge-vault-catalog.md
```

---

## 🔧 Standard Task Assignments

### By Domain

| Domain | Primary Agents | Common Tasks |
|--------|----------------|--------------|
| **Architecture** | Maya, Nathan, Sarah, Tom, Uma | Design, standards, integration |
| **Development** | Sarah, Frank, Grace, Henry, Clint, Deepak, Neo, Ringo, Trinity | Implementation, coding |
| **Testing** | Olivia, Paul, Quinn, Rachel, Test-Automator | Test creation, execution, validation |
| **Operations** | Henry, Iris, Jack, Deployment-Engineer | Deployment, monitoring, operations |
| **Documentation** | Chris, Emma, Diana, Karen | Documentation, procedures, standards |
| **Project Mgmt** | Bob, Chris, Diana, Emma | Planning, coordination, tracking |

### By Task Type

| Task Type | Recommended Agents | Notes |
|-----------|-------------------|-------|
| Service spec | Maya + Domain Lead | Architecture review required |
| Service plan | David + Developer | Detailed task breakdown |
| Code review | Code-Reviewer | Automated + manual review |
| Test plan | Olivia | 100% coverage mandate |
| Test execution | Quinn + Tester | Follow test-execution-template.md |
| Deployment | Deployment-Engineer + Henry | Use deployment checklist |
| Debugging | Debugger + Developer | Systematic troubleshooting |
| MCP Integration | MCP-Backend-Engineer | MCP-specific expertise |

---

## 📁 Document Templates Quick Reference

### Service Lifecycle

```
Specification Phase:
- service-spec-<service-name>.md (use service-spec-template.md)

Planning Phase:
- service-plan-<service-name>.md (use service-plan-template.md)
- service-task-<sequence>-<description>.md (use service-tasks-template.md)

Testing Phase:
- test-plan-<service-name>.md (use test-plan-template.md)
- tc-<service>-<area>-<sequence>-<description>.md (use test-case-template.md)
- test-suite-index-<service-name>.md (use test-suite-index-template.md)

Execution Phase:
- <YYYY-MM-DD>-<test-case-id>-<r>.md (use test-execution-template.md)
- defect-<service>-<severity>-<sequence>-<description>.md (use defect-template.md)

POC Phase:
- poc-<technology>-<purpose>.md (use poc-template.md)
```

### Infrastructure Documentation

```
Node Documentation:
- nodes/<node-name>/node-spec.md (use node-template.md)
- nodes/<node-name>/services-deployed.md
- nodes/<node-name>/configuration/env-vars.md

Inventory:
- inventory/nodes.md
- inventory/services.md
- inventory/network-topology.md

Network:
- network/network-topology.md
- network/port-mapping.md
- network/connectivity.md

Procedures:
- procedures/<procedure-name>.md
```

---

## ⚡ Quick Decision Trees

### Service Deployment Decision

```
Q: Is service specification complete?
├─ NO → Assign to architect (@maya, @nathan, @sarah, @tom, @uma)
└─ YES → Continue
    Q: Is test coverage 100%?
    ├─ NO → Assign to testing (@olivia creates plan)
    └─ YES → Continue
        Q: Is documentation complete?
        ├─ NO → Assign to documentation (@chris, @emma, @diana)
        └─ YES → Approve deployment (@henry, @deployment-engineer)
```

### Defect Triage Decision

```
Q: What is the severity?
├─ CRITICAL → Immediate attention (@alex assigns senior developer)
├─ HIGH → Priority queue (@alex assigns appropriate developer)
├─ MEDIUM → Standard queue (assign during planning)
└─ LOW → Backlog (schedule for future sprint)

Q: Can it be reproduced?
├─ NO → Assign to @debugger + original reporter
└─ YES → Assign to appropriate developer by domain
```

### Testing Approach Decision

```
Q: What type of testing is needed?
├─ Unit Tests → Developer creates (in code)
├─ Integration Tests → @olivia plans, @paul develops
├─ Deployment Tests → @deployment-engineer + @quinn execute
├─ Health Check Tests → @iris validates
└─ Functional Tests → @rachel designs, @test-automator implements
```

---

## 🔑 Key Standards Quick Lookup

### Naming Conventions

```
Documents:     <type>-<identifier>-<description>.md
Tasks:         <service>-task-<sequence>-<brief-description>.md
Test Cases:    tc-<service>-<test-area>-<sequence>-<description>.md
Defects:       defect-<service>-<severity>-<sequence>-<brief-description>.md
Test Results:  <YYYY-MM-DD>-<test-case-id>-<r>.md
Nodes:         <node-name> (lowercase, hyphens)
Services:      <service-name> (lowercase, hyphens)
```

### Test Coverage Requirements

```
Mandatory: 100% test coverage
Required Test Areas:
- Deployment tests
- Functionality tests  
- Integration tests
- Health check tests

Test-Driven Deployment:
- Services in non-operational/ until tests pass
- Promotion to operational/ requires all tests passing
- No exceptions to coverage requirement
```

### Documentation Requirements

```
Every Service Requires:
✓ Specification (service-spec-template.md)
✓ Deployment Plan (service-plan-template.md)
✓ Task Breakdown (service-tasks-template.md)
✓ Test Plan (test-plan-template.md)
✓ Test Cases (test-case-template.md)
✓ Test Suite Index (test-suite-index-template.md)

Generic Placeholders Only:
✓ Use: <service-name>, <node-name>, <description>
✗ Never: Specific examples (e.g., "docling")
```

### Credentials Management

```
Storage Locations:
- Service vaults: /path/to/<service>/vault/
- Node vaults: /path/to/nodes/<node-name>/vault/

Security Rules:
✗ NEVER commit credentials to GitHub
✗ NEVER use local user accounts for humans
✓ ALWAYS use Samba AD authentication
✓ ALWAYS store in appropriate vault

--------------------------------------------------------------
Enforce vault ignore at repo level.

Add to the repository's .gitignore to prevent accidental
commits:

    # HX-Infrastructure secrets
    standards/credentials-vault-management.md
    **/vault/**
    **/*.vault
    **/*.enc

Protected File:
standards/credentials-vault-management.md (must be in .gitignore)
```

---

## 🚀 Common Workflows Quick Start

### New Service Deployment

```bash
# 1. Create specification
@maya Create service-spec-<service-name>.md

# 2. Create deployment plan  
@david Create service-plan-<service-name>.md

# 3. Break down into tasks
@sarah Create service-task-*.md files

# 4. Create test plan
@olivia Create test-plan-<service-name>.md

# 5. Develop test cases
@paul Create tc-<service>-*.md files

# 6. Implement service
@<developer> Execute tasks from service-plan

# 7. Execute tests
@quinn Run test suite, document results

# 8. Fix defects (if any)
@<developer> Fix issues, @quinn re-test

# 9. Deploy to non-operational
@deployment-engineer Deploy to services/non-operational/

# 10. Validate deployment
@iris Verify all health checks pass

# 11. Promote to operational
@alex Approve, @deployment-engineer move to services/operational/
```

### Infrastructure Discovery

```bash
# 1. Document nodes
@emma Create inventory/nodes.md

# 2. Document services
@frank Create inventory/services.md

# 3. Map network
@grace Create inventory/network-topology.md

# 4. Detail each node
@henry Create nodes/<node-name>/node-spec.md

# 5. Document node services
@iris Create nodes/<node-name>/services-deployed.md

# 6. Review completeness
@alex Validate all documentation complete
```

### Test Execution Cycle

```bash
# 1. Review test plan
@olivia Ensure test-plan-<service-name>.md current

# 2. Execute test suite
@quinn Run all tests from test suite index

# 3. Document each execution
@quinn Create <YYYY-MM-DD>-<test-case-id>-<r>.md per test

# 4. Report defects
@quinn Create defect-*.md for any failures

# 5. Assign defects
@alex Triage and assign to developers

# 6. Verify fixes
@quinn Re-test after fixes implemented

# 7. Update test results
@rachel Update test suite index with final results

# 8. Sign-off
@david Review and approve if all tests pass
```

---

## 📚 Key Document Locations

### Templates
```
Location: /home/agent0/HX-Infrastructure/templates/

Service Templates:
- service-spec-template.md
- service-plan-template.md
- service-tasks-template.md
- poc-template.md

Testing Templates:
- test-plan-template.md
- test-case-template.md
- test-execution-template.md
- test-suite-index-template.md
- defect-template.md

Infrastructure Templates:
- node-template.md
```

### Standards
```
Location: /home/agent0/HX-Infrastructure/standards/

Core Standards:
- naming-conventions.md
- architecture-standards.md
- documentation-requirements.md
- testing-requirements.md
- deployment-requirements.md
- credentials-vault-management.md (⚠️ .gitignored)
```

### Agent Documentation
```
Location: /home/agent0/HX-Infrastructure/hx-agents/

Agent References:
- hx-agent-inventory.md (32 agents: 5 Core Team SMEs + 27 Technology SMEs)
- hx-knowledge-vault-catalog.md (58 repos)
- hx-orchestration-guide.md (detailed workflows)
- hx-orchestration-quick-ref.md (this document)
```

### Infrastructure State
```
Location: /home/agent0/HX-Infrastructure/

Inventory:
- inventory/nodes.md
- inventory/services.md
- inventory/network-topology.md

Node Details:
- nodes/<node-name>/node-spec.md
- nodes/<node-name>/services-deployed.md
- nodes/<node-name>/configuration/

Network:
- network/network-topology.md
- network/port-mapping.md
- network/connectivity.md
```

---

## 🎯 Quality Gates Checklist

### Pre-Development
- [ ] Service specification reviewed by architect
- [ ] Deployment plan approved by lead
- [ ] Tasks broken down and estimated
- [ ] Test plan created and reviewed

### Pre-Deployment  
- [ ] All tasks completed
- [ ] 100% test coverage achieved
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Code review approved (if applicable)

### Pre-Promotion (non-operational → operational)
- [ ] Service deployed to non-operational
- [ ] All health checks passing
- [ ] Integration tests successful
- [ ] Performance validated
- [ ] Monitoring configured
- [ ] Runbook created

---

## ⚠️ Critical Reminders

### Security
- Never commit credentials to GitHub
- Authenticate humans via Samba AD
- Store credentials in service/node vaults
- Ensure credentials-vault-management.md is .gitignored

### Quality
- 100% test coverage is mandatory, not optional
- No service promotes to operational without full test pass
- Documentation is not optional
- Generic placeholders only (no specific examples)

### Process
- Test-driven deployment approach required
- Every service starts in services/non-operational/
- Quality gates are mandatory checkpoints
- Defects must be documented using defect-template.md

---

## 📞 Agent Contact Matrix

### By Specialty

**Architecture & Design**: Maya, Nathan, Sarah, Tom, Uma  
**Project Management**: Bob, Chris, Diana, Emma  
**Development**: Frank, Grace, Henry, Iris, Jack, Kelly, Clint, Deepak, Neo, Ringo, Trinity  
**Testing & QA**: Olivia, Paul, Quinn, Rachel, Test-Automator  
**Operations**: Henry, Iris, Jack, Deployment-Engineer  
**Documentation**: Chris, Emma, Diana, Karen, Linda, Mark  

**Utility Specialists**:
- Code Review: Code-Reviewer
- Context Management: Context-Manager  
- Debugging: Debugger
- Deployment: Deployment-Engineer
- MCP Backend: MCP-Backend-Engineer
- MCP Testing: N8N-MCP-Tester
- Research: Technical-Researcher
- Test Automation: Test-Automator

### By Layer

**Layer 1 (Lead)**: Alex  
**Layer 2 (Managers)**: Bob, Chris, Diana, Emma  
**Layer 3 (Architects)**: Maya, Nathan, Sarah, Tom, Uma  
**Layer 4 (Leads)**: David, Frank, Grace, Henry, Iris, Jack  
**Layer 5 (Seniors)**: Kelly, Olivia, Paul, Quinn, Rachel, Sam, Victor  
**Layer 6 (Engineers)**: Wendy, Xander, Yara, Zoe, Aaron, Bella, Carlos  
**Layer 7 (Developers)**: Clint, Deepak, Neo, Ringo, Trinity  
**Utility**: Code-Reviewer, Context-Manager, Debugger, Deployment-Engineer, MCP-Backend-Engineer, N8N-MCP-Tester, Technical-Researcher, Test-Automator  
**Other**: Diana (additional role), Karen (additional role)

---

## 🔗 Related Documents

**For Detailed Information**:
- `hx-orchestration-guide.md` - Comprehensive workflows and patterns
- `hx-agent-inventory.md` - Complete agent profiles and capabilities
- `hx-knowledge-vault-catalog.md` - Repository and knowledge references
- `constitution.md` - Project principles and philosophy
- `README.md` - Project overview and navigation

**For Standards**:
- `standards/naming-conventions.md` - Naming rules and patterns
- `standards/architecture-standards.md` - Architecture guidelines
- `standards/documentation-requirements.md` - Documentation standards
- `standards/testing-requirements.md` - Testing requirements and coverage
- `standards/deployment-requirements.md` - Deployment procedures

**For Templates**:
- See `/templates/` directory for all template files
- Each template includes detailed instructions and examples

---

## 📝 Version History

- **v1.0** (2025-11-15): Initial creation based on HX-Infrastructure orchestration guide

---

**Document Type**: Quick Reference Guide  
**Audience**: All HX-Infrastructure agents  
**Maintenance**: Update when orchestration patterns change  
**Owner**: Infrastructure Team (Alex coordination)
