---
description: "Deployment plan template for infrastructure services"
scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

# Deployment Plan: [SERVICE NAME]

**Branch**: `[###-service-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Service specification from `/services/non-operational/[service-name]/spec.md`

## Execution Flow (/hx-plan command scope)
```
1. Load service spec from Input path
   → If not found: ERROR "No service spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Target Node(s) from spec
   → Verify node capacity and compatibility
   → Set Deployment Strategy
3. Fill Constitution Check section based on constitution.md
4. Evaluate Constitution Check section
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → deployment-research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → deployment-architecture.md, test-plan.md, configuration-spec.md
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks)
9. STOP - Ready for /hx-tasks command
```

**IMPORTANT**: The /hx-plan command STOPS at step 8. Phase 2 is executed by /hx-tasks command.

## Summary
[Extract from service spec: primary purpose + deployment approach from research]

## Technical Context
**Service Type**: [e.g., Database, API Server, Message Queue, MCP Server, or NEEDS CLARIFICATION]  
**Technology/Version**: [e.g., PostgreSQL 16, Node.js 20, Redis 7.2, or NEEDS CLARIFICATION]  
**Target Node(s)**: [e.g., agent0, database-node, or NEEDS CLARIFICATION]  
**Node OS**: [e.g., Ubuntu 24.04, any Linux, or NEEDS CLARIFICATION]  
**Installation Method**: [e.g., apt, Docker, from source, or NEEDS CLARIFICATION]  
**Port Requirements**: [e.g., 5432, 8080, or NEEDS CLARIFICATION]  
**Storage Requirements**: [e.g., 100GB persistent, /var/lib/service, or NEEDS CLARIFICATION]  
**Network Requirements**: [e.g., internal only, external access, VPN, or NEEDS CLARIFICATION]  
**Dependencies**: [e.g., Python 3.11, systemd, other services, or NEEDS CLARIFICATION]  
**Resource Targets**: [e.g., 4GB RAM, 2 CPU cores, or NEEDS CLARIFICATION]

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Documentation-First Requirements**:
- [ ] Service spec.md is complete and reviewed
- [ ] All NEEDS CLARIFICATION resolved before deployment
- [ ] Deployment plan will be documented before execution

**Test-Driven Deployment Requirements**:
- [ ] Test suite will be defined in Phase 1
- [ ] Tests will be written before deployment execution
- [ ] Service will remain non-operational until all tests pass

**Single Responsibility**:
- [ ] Service has clear, focused purpose (from spec.md)
- [ ] Dependencies are explicitly documented
- [ ] No scope creep beyond spec requirements

**Quality Over Speed**:
- [ ] Thorough planning prioritized over quick deployment
- [ ] All edge cases considered
- [ ] Rollback strategy defined

**Violations Requiring Justification**: [List any constitution violations that need documented justification]

## Deployment Structure

### Documentation (this service)
```
services/non-operational/[service-name]/
├── spec.md                    # Service specification (input)
├── plan.md                    # This file (/hx-plan output)
├── deployment-research.md     # Phase 0 output (/hx-plan)
├── deployment-architecture.md # Phase 1 output (/hx-plan)
├── configuration-spec.md      # Phase 1 output (/hx-plan)
├── deployment/               # Deployment artifacts
│   ├── configuration.md
│   ├── dependencies.md
│   └── installation.md
├── tasks/                    # Deployment tasks (/hx-tasks output)
│   ├── [service]-task-001-*.md
│   ├── [service]-task-002-*.md
│   └── ...
├── poc/                      # Optional POC if needed
│   ├── poc-spec.md
│   └── poc-results.md
└── tests/                    # Test suite (Phase 1 output)
    ├── test-plan.md
    ├── test-suite/
    │   ├── deployment/
    │   ├── functionality/
    │   ├── integration/
    │   └── health-check/
    └── test-results/
```

### Node Configuration
```
nodes/[target-node]/
├── node-spec.md              # Node capabilities
├── services-deployed.md      # Update after deployment
└── configuration/
    └── [service-specific configs]
```

### Inventory Updates
```
inventory/
├── nodes.md                  # Update node status
├── services.md               # Add service entry
└── network-topology.md       # Update if network changes
```

## Phase 0: Research & Requirements Validation
1. **Technology Selection Validation**:
   - Verify specified technology meets requirements
   - Research installation methods and best practices
   - Identify potential issues or limitations
   - Research alternatives if needed

2. **Node Compatibility Research**:
   - Verify target node can support service
   - Check OS compatibility
   - Verify resource availability
   - Identify conflicts with existing services

3. **Dependency Research**:
   - Research all system dependencies
   - Identify dependency installation order
   - Research dependency compatibility
   - Document dependency versions

4. **Integration Research** (if applicable):
   - Research integration patterns with existing services
   - Identify integration requirements
   - Research authentication/authorization methods
   - Document integration best practices

5. **Security Research**:
   - Research security best practices for this service
   - Identify security hardening steps (if applicable)
   - Research certificate/secrets management
   - Document security configuration

6. **Generate research report** in `deployment-research.md`:
   - Decision: [what was chosen/validated]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]
   - Risks identified: [potential issues]
   - Mitigations: [how to address risks]

**Output**: deployment-research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Deployment Architecture & Test Planning
*Prerequisites: deployment-research.md complete*

1. **Create Deployment Architecture** → `deployment-architecture.md`:
   - Node placement and resource allocation
   - Network configuration (ports, interfaces, firewall)
   - Storage configuration (mount points, volumes)
   - Service dependencies and startup order
   - Configuration file locations
   - Log file locations
   - Backup strategy (if applicable)

2. **Define Configuration Specification** → `configuration-spec.md`:
   - Environment variables required
   - Configuration file templates
   - Secrets/credentials needed
   - Default values and overrides
   - Configuration validation approach

3. **Create Test Plan** → `tests/test-plan.md`:
   - Test strategy based on service spec
   - Test environment requirements
   - Test data requirements
   - Test execution order

4. **Generate Test Suite Structure**:
   - **Deployment Tests** (`tests/test-suite/deployment/`):
     - Verify installation completed
     - Verify configuration applied correctly
     - Verify dependencies installed
     - Verify file permissions correct
     - Verify service starts successfully
   
   - **Functionality Tests** (`tests/test-suite/functionality/`):
     - Test core service capabilities from spec.md
     - Verify each functional requirement
     - Test error handling
   
   - **Integration Tests** (`tests/test-suite/integration/`) (if applicable):
     - Test connections to dependent services
     - Test authentication/authorization
     - Test data flow
   
   - **Health Check Tests** (`tests/test-suite/health-check/`):
     - Service responds to health endpoint
     - Resource usage within limits
     - No error conditions present

5. **Update agent context incrementally** (if agent context system in use):
   - Run `{SCRIPT}`
     **IMPORTANT**: Execute exactly as specified. Do not add or remove arguments.
   - Add only NEW infrastructure context
   - Keep under 150 lines for token efficiency

**Output**: deployment-architecture.md, configuration-spec.md, test-plan.md, test suite structure with test case templates

## Phase 2: Task Planning Approach
*This section describes what the /hx-tasks command will do - DO NOT execute during /hx-plan*

**Task Generation Strategy**:
- Load `.claude/tasks.md` template as base (or equivalent for agent)
- Generate tasks from Phase 1 design docs
- Each test case → test creation task [P]
- Architecture components → deployment tasks
- Configuration items → configuration tasks

**Task Categories**:
1. **Pre-Deployment Tasks**:
   - Verify node capacity
   - Backup existing configurations (if applicable)
   - Download/prepare installation packages

2. **Installation Tasks**:
   - Install system dependencies
   - Install service software
   - Configure service

3. **Test Tasks**:
   - Write deployment validation tests [P]
   - Write functionality tests [P]
   - Write integration tests [P] (if applicable)
   - Write health check tests [P]

4. **Verification Tasks**:
   - Run deployment validation tests
   - Run functionality tests
   - Run integration tests
   - Run health check tests

5. **Post-Deployment Tasks**:
   - Update inventory documents
   - Update node documentation
   - Document any deployment issues/learnings

**Ordering Strategy**:
- Pre-deployment → Installation → Test Creation → Verification → Post-deployment
- Tests must be written before verification
- Mark [P] for parallel execution (independent tasks)

**Estimated Output**: 20-40 numbered, ordered tasks in tasks/ directory

**IMPORTANT**: This phase is executed by the /hx-tasks command, NOT by /hx-plan

## Phase 3+: Future Execution
*These phases are beyond the scope of the /hx-plan command*

**Phase 3**: Task generation (/hx-tasks command creates task files)  
**Phase 4**: Deployment execution (execute tasks following test-driven approach)  
**Phase 5**: Validation (run all tests, verify success criteria)
**Phase 6**: Service Promotion (move from non-operational to operational)

## Rollback Strategy
*Document how to undo this deployment if needed*

**Rollback Triggers**:
- Critical test failures
- Service instability
- Resource exhaustion
- Integration failures

**Rollback Steps**:
1. [Step to stop service]
2. [Step to remove configuration]
3. [Step to remove software]
4. [Step to restore previous state]
5. [Step to verify rollback successful]

**Rollback Testing**:
- Rollback procedure will be tested before deployment
- Rollback time estimate: [time]

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [e.g., Port conflict] | [High/Med/Low] | [High/Med/Low] | [How to prevent/handle] |
| [e.g., Resource exhaustion] | [High/Med/Low] | [High/Med/Low] | [How to prevent/handle] |
| [e.g., Data loss] | [High/Med/Low] | [High/Med/Low] | [How to prevent/handle] |

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., Non-standard port] | [specific reason] | [why standard port insufficient] |
| [e.g., Custom installation] | [specific need] | [why package manager insufficient] |

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [ ] Phase 0: Research complete (/hx-plan command)
- [ ] Phase 1: Architecture & tests planned (/hx-plan command)
- [ ] Phase 2: Task planning complete (/hx-plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/hx-tasks command)
- [ ] Phase 4: Deployment complete
- [ ] Phase 5: Validation passed
- [ ] Phase 6: Service promoted to operational

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented
- [ ] Rollback strategy defined
- [ ] Risk assessment complete

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git  
*Based on HX Infrastructure Constitution v1.0 - See `/constitution.md`*
