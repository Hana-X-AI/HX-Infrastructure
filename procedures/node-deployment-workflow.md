# HX-Infrastructure Node Deployment Workflow
## Project Initiation and Structure Creation

**Document Type:** Procedure - Project Initiation (Phase 0: Setup)
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready v1.1
**Location:** `/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md`

**Purpose:** Define systematic workflow for initializing node deployment projects with proper directory structure, templates, and review mechanisms
**Previous Version:** 1.0 → 1.1 (infrastructure philosophy integration, comprehensive documentation, command integration)

---

## Document Purpose

This procedure defines **Phase 0: Project Initiation** - the project setup phase that occurs BEFORE the 5-phase project lifecycle begins. This workflow creates the directory structure, copies templates, and prepares the environment for charter creation (Phase 1).

### Target Audience
- **Agent Zero (CC):** Executes project initialization workflow
- **CAIO:** Approves project structure before charter creation begins
- **Project Team:** References this structure throughout all 5 project phases

### Related Documents
- **Next Phase:** `.claude/commands/workflows/cc-charter-workflow.md` - Charter creation (Phase 1)
- **Standards:** `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - Node naming and directory structure
- **Templates:** `/home/agent0/HX-Infrastructure/templates/` - All templates copied during initialization
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles for project setup

### Relationship to 5-Phase Lifecycle

This document describes **Phase 0** (prerequisite setup):
- **Phase 0:** Project Initiation (this document) - Structure creation
- **Phase 1:** Charter Creation (charter-workflow.md) - Vision and scope
- **Phase 2:** Specification Development (spec-workflow.md) - Technical requirements
- **Phase 3:** Task Breakdown & Testing (task-workflow.md) - Task and test generation
- **Phase 4:** Task Execution (task-execution-workflow.md) - Implementation and validation
- **Phase 5:** Project Closeout (project-closeout-workflow.md) - Final documentation

---

## 🎯 Project Types & Commands

HX-Infrastructure supports three types of infrastructure projects:

### **1. New Node Deployment**
**Command:** `/deploy server node`  
**Purpose:** Deploy a brand new server node to infrastructure  
**Complexity:** HIGH - Full charter → spec → plan → deploy → test cycle

### **2. Document Existing Node**
**Command:** `/document server node configure`  
**Purpose:** Document current state of existing operational node  
**Complexity:** MEDIUM - Discovery → documentation → validation

### **3. Node Enhancement**
**Command:** `/new server node enhancement`  
**Purpose:** Modify/upgrade existing node configuration  
**Complexity:** MEDIUM-HIGH - Charter → change plan → test → deploy

---

## 📁 Approved Directory Structure

**Location:** `/home/agent0/HX-Infrastructure/nodes/<node-name>/`

```
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/
│
├─── charter.md                          # Project charter
├─── charter-reviews/                    # ✅ ADDED: Charter reviews
│    └─── YYYY-MM-DD-review.md
│
├─── node-spec.md                        # Node specification
├─── node-spec-reviews/                  # ✅ ADDED: Node spec reviews
│    └─── YYYY-MM-DD-review.md
│
├─── deployment/
│    ├─── plan.md                        # Deployment plan
│    ├─── architecture.md                # Architecture documentation
│    ├─── deployment-research.md         # Research findings (Phase 0)
│    ├─── configuration-spec.md          # Configuration specification (Phase 1)
│    └─── reviews/                       # Deployment work product reviews
│         └─── YYYY-MM-DD-review.md
│
├─── tasks/
│    ├─── task-001-*.md                  # Individual task files
│    ├─── task-002-*.md                  # Individual task files
│    └─── reviews/                       # Task-specific reviews
│         └─── YYYY-MM-DD-task-###-review.md
│
├─── tests/
│    ├─── test-plan.md                   # Test plan
│    ├─── test-suite/
│    │    ├─── deployment/               # Deployment tests
│    │    │    ├─── tc-001-*.md
│    │    │    └─── reviews/             # Test case reviews
│    │    │         └─── YYYY-MM-DD-review.md
│    │    ├─── functionality/            # Functionality tests
│    │    │    ├─── tc-001-*.md
│    │    │    └─── reviews/
│    │    │         └─── YYYY-MM-DD-review.md
│    │    └─── integration/              # Integration tests
│    │         ├─── tc-001-*.md
│    │         └─── reviews/
│    │              └─── YYYY-MM-DD-review.md
│    └─── test-plan-reviews/             # Test plan reviews
│         └─── YYYY-MM-DD-review.md
│
├─── configuration/
│    ├─── env-vars.md                    # Environment variables
│    ├─── installed-packages.md          # Package inventory
│    ├─── network-config.md              # Network settings
│    ├─── ansible-vault/                 # Vault secrets only (no playbooks)
│    └─── reviews/                       # Configuration reviews
│         └─── YYYY-MM-DD-review.md
│
├─── status-reports/                     # Status reporting (no reviews)
│    └─── YYYY-MM-DD-status-report.md
│
├─── services-deployed.md                # Services running on node
│
└─── README.md                           # Project overview
```

### **Key Structure Decisions:**

✅ **Node naming:** `hx-<service>-server` (matches operational name)  
✅ **Charter reviews:** Dedicated `charter-reviews/` directory  
✅ **Node-spec reviews:** Dedicated `node-spec-reviews/` directory  
✅ **Work product reviews:** At level 2 (specific work products, not categories)  
  - deployment/reviews/ - for deployment work products
  - tasks/reviews/ - for individual task reviews
  - tests/test-suite/{type}/reviews/ - for test case reviews
  - tests/test-plan-reviews/ - for test plan reviews
  - configuration/reviews/ - for configuration reviews
✅ **No reviews in:** status-reports/ (point-in-time documents)  
✅ **No rollback plan:** New nodes don't require rollback procedures  
✅ **Template source:** `/home/agent0/HX-Infrastructure/templates/`  
✅ **Template-driven:** All .md files from templates

---

## 🚀 Complete Workflow: New Node Deployment

### **PHASE 0: Project Initiation**

```
┌─────────────────────────────────────────────────────────────┐
│ Step 0.1: Command Execution                                 │
└─────────────────────────────────────────────────────────────┘

CAIO: "/deploy server node"

CC (Processing):
├─ Detects: New node deployment request
├─ Project type: Infrastructure - Node Deployment
└─ Workflow: Full deployment cycle

CC (Response):
┌───────────────────────────────────────────────────────────┐
│ 🚀 New Node Deployment Project                           │
│                                                           │
│ Please provide the node name:                            │
│ (Example: docling-mcp-server)                            │
└───────────────────────────────────────────────────────────┘

CAIO: "docling mcp server"

CC (Normalization):
├─ Input: "docling mcp server"
├─ Applies naming conventions (lowercase, hyphens)
├─ Adds prefix: "hx-"
└─ Result: "hx-docling-mcp-server"

CC (Confirmation):
┌───────────────────────────────────────────────────────────┐
│ ✓ Confirmed: New Node Deployment Project                 │
│                                                           │
│ Project Name: docling-mcp-server-deployment              │
│ Node Name: hx-docling-mcp-server                         │
│ Project Type: Node Deployment                            │
│                                                           │
│ I'll create a complete project structure with:           │
│ • Project charter (charter-template.md)                  │
│ • Node specification (node-template.md)                  │
│ • Deployment plan (node-deployment-plan-template.md)     │
│ • Task breakdown structure                               │
│ • Test plan framework                                    │
│ • Configuration documentation                            │
│ • Status reporting setup                                 │
│ • Review subdirectories                                  │
│                                                           │
│ Where should I create the project structure?             │
│ Suggested: /home/agent0/HX-Infrastructure/nodes/         │
└───────────────────────────────────────────────────────────┘

CAIO: "/home/agent0/HX-Infrastructure/nodes"

CC (Pre-Creation Validation):
├─ Checks: /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/
├─ Status: ✓ Directory does not exist
├─ Validates: Naming convention compliance
└─ Ready: Proceed with creation

CC (Final Confirmation):
┌───────────────────────────────────────────────────────────┐
│ Perfect. I'll create:                                     │
│                                                           │
│ /home/agent0/HX-Infrastructure/nodes/                    │
│ └─── hx-docling-mcp-server/                              │
│      ├─── charter.md                                      │
│      ├─── charter-reviews/                                │
│      ├─── node-spec.md                                    │
│      ├─── node-spec-reviews/                              │
│      ├─── deployment/ (with reviews/)                     │
│      ├─── tasks/ (with reviews/)                          │
│      ├─── tests/ (with test-plan-reviews/ and            │
│      │    test-suite/{type}/reviews/)                     │
│      ├─── configuration/ (with reviews/)                  │
│      ├─── status-reports/                                 │
│      ├─── services-deployed.md                            │
│      └─── README.md                                       │
│                                                           │
│ Templates will be:                                        │
│ • Copied from /home/agent0/HX-Infrastructure/templates/  │
│ • Renamed appropriately                                  │
│ • Pre-filled with: project name, date, type              │
│                                                           │
│ This follows HX-Infrastructure standards:                │
│ ✓ Naming: lowercase with hyphens                         │
│ ✓ Structure: Standard node deployment layout             │
│ ✓ Reviews: At work product level (level 2)               │
│ ✓ No rollback plan: New nodes don't require it           │
│                                                           │
│ Should I proceed with creation?                          │
│ (yes/no/modify)                                          │
└───────────────────────────────────────────────────────────┘

CAIO: "yes"

┌─────────────────────────────────────────────────────────────┐
│ Step 0.2: Structure Creation                                │
└─────────────────────────────────────────────────────────────┘

CC (Execution):
├─ Creating directory structure...
│   ├─ /nodes/hx-docling-mcp-server/
│   ├─ /nodes/hx-docling-mcp-server/charter-reviews/
│   ├─ /nodes/hx-docling-mcp-server/node-spec-reviews/
│   ├─ /nodes/hx-docling-mcp-server/deployment/
│   ├─ /nodes/hx-docling-mcp-server/deployment/reviews/
│   ├─ /nodes/hx-docling-mcp-server/tasks/
│   ├─ /nodes/hx-docling-mcp-server/tasks/reviews/
│   ├─ /nodes/hx-docling-mcp-server/tests/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-plan-reviews/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/deployment/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/deployment/reviews/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/functionality/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/functionality/reviews/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/integration/
│   ├─ /nodes/hx-docling-mcp-server/tests/test-suite/integration/reviews/
│   ├─ /nodes/hx-docling-mcp-server/configuration/
│   ├─ /nodes/hx-docling-mcp-server/configuration/reviews/
│   └─ /nodes/hx-docling-mcp-server/status-reports/
│
├─ Copying and customizing templates...
│   ├─ /home/agent0/HX-Infrastructure/templates/charter-template.md → charter.md
│   │   └─ Pre-filled: Project name, date, type=Node Deployment
│   ├─ /home/agent0/HX-Infrastructure/templates/node-template.md → node-spec.md
│   │   └─ Pre-filled: Node name, date
│   ├─ /home/agent0/HX-Infrastructure/templates/node-deployment-plan-template.md → deployment/plan.md
│   │   └─ Pre-filled: Project name, date
│   ├─ /home/agent0/HX-Infrastructure/templates/service-tasks-template.md → tasks/TASKS-README.md
│   │   └─ Pre-filled: Project name, instructions
│   ├─ /home/agent0/HX-Infrastructure/templates/test-plan-template.md → tests/test-plan.md
│   │   └─ Pre-filled: Project name, date
│   ├─ /home/agent0/HX-Infrastructure/templates/test-case-template.md → tests/test-suite/TEST-README.md
│   │   └─ Pre-filled: Instructions for test creation
│   └─ /home/agent0/HX-Infrastructure/templates/status-report-template.md → status-reports/STATUS-README.md
│       └─ Pre-filled: Project name, reporting instructions
│
├─ Generating project README.md...
│   ├─ Project overview
│   ├─ Directory structure explanation
│   ├─ Quick reference links
│   └─ Next steps guidance
│
├─ Creating placeholder files...
│   ├─ services-deployed.md (empty, ready for updates)
│   ├─ configuration/env-vars.md (template structure)
│   ├─ configuration/installed-packages.md (template structure)
│   └─ configuration/network-config.md (template structure)
│
└─ Complete! ✓

CC (Status Report):
┌───────────────────────────────────────────────────────────┐
│ ✓ Project Structure Created Successfully                  │
│                                                           │
│ Location: /home/agent0/HX-Infrastructure/nodes/          │
│          hx-docling-mcp-server/                          │
│                                                           │
│ Created:                                                  │
│ ✓ 15 directories                                         │
│ ✓ 11 template files (ready for customization)           │
│ ✓ 1 README with project overview                        │
│ ✓ 7 review directories (charter, node-spec, deployment, │
│   tasks, test-plan, test-suite levels, configuration)   │
│                                                           │
│ Pre-filled Information:                                  │
│ • Project name: hx-docling-mcp-server                   │
│ • Date: 2025-11-16                                      │
│ • Type: Node Deployment                                 │
│                                                           │
│ 📋 Note: Centralized artifacts will be updated during    │
│    and after charter creation (not now)                  │
│                                                           │
│ Next Steps Available:                                    │
│ 1. Review structure (RECOMMENDED)                        │
│ 2. Begin charter creation                                │
│ 3. Review project standards                              │
│                                                           │
│ What would you like to do?                               │
└───────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Step 0.3: Structure Review (Optional but Recommended)       │
└─────────────────────────────────────────────────────────────┘

CAIO: "1" (Review structure)

CC (Displays):
┌───────────────────────────────────────────────────────────┐
│ 📁 Project Structure                                      │
│                                                           │
│ /nodes/hx-docling-mcp-server/                            │
│ │                                                         │
│ ├─── 📄 charter.md (19K)                                 │
│ │    Purpose: Project vision, scope, success criteria    │
│ │    Status: Template ready, needs CAIO input            │
│ │    Next: Charter creation workflow                     │
│ ├─── 📁 charter-reviews/                                 │
│ │    Purpose: Reviews of charter document                │
│ │                                                         │
│ ├─── 📄 node-spec.md (13K)                               │
│ │    Purpose: Node specifications and requirements       │
│ │    Status: Template ready, needs details               │
│ │    Filled during: Specification phase                  │
│ ├─── 📁 node-spec-reviews/                               │
│ │    Purpose: Reviews of node specification              │
│ │                                                         │
│ ├─── 📁 deployment/                                       │
│ │    ├─── plan.md (14K) - Deployment strategy           │
│ │    ├─── architecture.md (placeholder)                  │
│ │    ├─── deployment-research.md (Phase 0 output)        │
│ │    ├─── configuration-spec.md (Phase 1 output)         │
│ │    └─── reviews/ (deployment work product reviews)     │
│ │                                                         │
│ ├─── 📁 tasks/                                            │
│ │    ├─── TASKS-README.md (11K) - Task instructions     │
│ │    └─── reviews/ (task-specific reviews)               │
│ │    Note: Individual tasks created during breakdown     │
│ │                                                         │
│ ├─── 📁 tests/                                            │
│ │    ├─── test-plan.md (9.5K)                            │
│ │    ├─── test-plan-reviews/ (test plan reviews)         │
│ │    ├─── test-suite/                                    │
│ │    │    ├─── deployment/                               │
│ │    │    │    ├─── tc-001-*.md                          │
│ │    │    │    └─── reviews/ (test case reviews)         │
│ │    │    ├─── functionality/                            │
│ │    │    │    ├─── tc-001-*.md                          │
│ │    │    │    └─── reviews/                             │
│ │    │    └─── integration/                              │
│ │    │         ├─── tc-001-*.md                          │
│ │    │         └─── reviews/                             │
│ │                                                         │
│ ├─── 📁 configuration/                                    │
│ │    ├─── env-vars.md (template)                         │
│ │    ├─── installed-packages.md (template)               │
│ │    ├─── network-config.md (template)                   │
│ │    ├─── ansible-vault/ (secrets only, no playbooks)   │
│ │    └─── reviews/ (configuration reviews)               │
│ │                                                         │
│ ├─── 📁 status-reports/                                   │
│ │    └─── STATUS-README.md (instructions)                │
│ │    Note: No reviews/ (point-in-time documents)         │
│ │                                                         │
│ ├─── 📄 services-deployed.md (placeholder)               │
│ │    Purpose: Track services running on this node        │
│ │                                                         │
│ └─── 📄 README.md (2K)                                    │
│      Purpose: Project overview and quick reference        │
│                                                           │
│ ✓ All naming conventions followed                        │
│ ✓ All required templates present                         │
│ ✓ Review directories at work product level (level 2)     │
│ ✓ No rollback plan (new node deployment)                 │
│ ✓ Structure ready for charter phase                      │
└───────────────────────────────────────────────────────────┘

CAIO: "Looks good, proceed to charter"

CC (Phase Gate):
┌───────────────────────────────────────────────────────────┐
│ ✓ Structure Approved                                     │
│                                                           │
│ 🚦 PHASE GATE 0: Project Setup Complete                  │
│                                                           │
│ Completed:                                                │
│ ✓ Project initialized                                    │
│ ✓ Directory structure created                            │
│ ✓ Templates copied and pre-filled                        │
│ ✓ Structure reviewed and approved                        │
│                                                           │
│ Next: Phase 1 - Project Charter Creation                 │
│                                                           │
│ Charter workflow will:                                    │
│ • Guide you through vision and scope definition          │
│ • Ask clarifying questions                               │
│ • Integrate knowledge vault review                       │
│ • Update centralized RAIDD log (after approval)          │
│ • Update centralized Backlog (after approval)            │
│ • Identify dependencies (after charter)                  │
│ • Preview agent assignments (after charter)              │
│                                                           │
│ Ready to begin charter creation?                         │
│ (yes/review-standards/pause)                             │
└───────────────────────────────────────────────────────────┘

[WORKFLOW PAUSES HERE - READY FOR CHARTER PHASE]
```

---

## 📋 Approved Decisions Summary

### **Commands:**
✅ `/deploy server node` - New node deployment  
✅ `/document server node configure` - Document existing node  
✅ `/new server node enhancement` - Node modifications

### **Directory Structure:**
✅ Add `reviews/` subdirectory to: deployment/, tasks/, tests/, configuration/  
✅ NO `reviews/` in status-reports/ (point-in-time docs)  
✅ Node naming: `hx-<service>-server` (operational name match)

### **Template:**
✅ Create new: `node-deployment-plan-template.md` (separate from service plan)  
✅ Pre-fill: Minimal (project name, date, type only)

### **Workflow Integration:**
✅ RAIDD notification: Add to workflow  
✅ Knowledge vault: During charter phase (not before)  
✅ Agent assignment: First review after charter  
✅ Dependencies check: After charter approval  
✅ Centralized updates: During and after charter (not before)

---

## HX-Infrastructure Philosophy Integration

All node deployment projects must prepare for infrastructure philosophy compliance from initialization:

### Infrastructure Philosophy in Project Structure

**Directory Structure Preparation:**
- `deployment/` directory prepared for manual deployment procedures documentation
- `configuration/` directory prepared for Ansible Vault credential documentation
- `configuration/ansible-vault/` directory for vault secrets only (no playbooks, no automation)
- `tasks/` directory prepared for bare metal and systemd service task files
- No automation directories created (no CI/CD, no automated deployment pipelines, no Ansible playbooks)

**Template Integration:**
- Templates copied from `/home/agent0/HX-Infrastructure/templates/` include infrastructure philosophy sections
- Charter template includes infrastructure requirements questions
- Node specification template includes bare metal, systemd, Ansible Vault sections
- Task templates include manual procedure documentation requirements

### Infrastructure Philosophy Awareness Points

**During Structure Creation (Phase 0):**
- Node naming follows hx-<service>-server convention (matches operational hostname)
- Directory structure supports manual procedures (no automation tooling directories)
- Configuration directory includes `ansible-vault/` subdirectory for secrets only (no playbooks)

**During Charter Creation (Phase 1 - Next):**
- Charter template prompts for bare metal deployment requirements
- Infrastructure requirements section mandatory in charter
- Success criteria must include infrastructure philosophy compliance

**During Specification (Phase 2 - Future):**
- Specification template includes infrastructure requirements section
- Bare metal server specification (hostname, IP, Ubuntu 24 version)
- Systemd service specification section
- Manual deployment procedure outline
- Ansible Vault credential management section

**During Task Breakdown (Phase 3 - Future):**
- Task templates designed for manual execution steps
- Test templates include systemd service validation
- Infrastructure philosophy compliance validation tasks

**During Execution (Phase 4 - Future):**
- Task execution validates bare metal deployment
- Test execution validates systemd service health
- Result documentation captures manual procedure execution
- Infrastructure philosophy compliance verification

### Quality Gate: Infrastructure Philosophy Readiness

Before proceeding to charter creation, verify:
- [ ] Project structure supports manual procedures (no automation directories)
- [ ] Templates include infrastructure philosophy sections
- [ ] Configuration directory prepared for Ansible Vault documentation
- [ ] Deployment directory prepared for manual procedure documentation

---

## Claude Code Command Infrastructure Integration

### How Commands Invoke This Workflow

**Set 1: Workflow Commands (Primary Integration)**
- **`cc-node-deployment-init.md`:** Primary command implementing Phase 0 (project initialization)
  - Invokes this procedure for structure creation
  - Prompts for node name and validates naming conventions
  - Creates directory structure per this specification
  - Copies and pre-fills templates
  - Validates structure before proceeding to charter

**Project Lifecycle Integration:**
```
User: "/deploy server node"
↓
cc-node-deployment-init.md (Set 1) executes Phase 0
├─ Prompt for node name
├─ Validate naming: hx-<service>-server
├─ Create directory structure (this document)
├─ Copy templates from /templates/
├─ Pre-fill: project name, date, type
├─ CAIO reviews structure
└─ GATE 0: Structure approved → Proceed to Phase 1
↓
cc-charter-workflow.md (Set 1) executes Phase 1
└─ Charter creation workflow begins
```

**Set 3: Utility Commands (Supporting Tools)**
- **`artifact-tracker`:** Tracks project structure creation as initial deliverable
- **`doc-lint`:** Validates directory structure and template customization
- **`status-report`:** Reports Phase 0 completion status

**Command Workflow Pattern:**
1. CAIO executes `/deploy server node`
2. Agent Zero invokes `cc-node-deployment-init.md`
3. Phase 0 workflow (this document) executes
4. Structure created, templates copied
5. CAIO approves structure (Gate 0)
6. Phase 1 (charter workflow) begins automatically

### Directory Structure Standardization

This procedure defines the AUTHORITATIVE directory structure for all node deployment projects. Any changes to structure require:
- Update to this document
- Update to `cc-node-deployment-init.md` command
- Update to `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
- Validation against all existing projects for consistency

---

## 🚧 Action Items

### **Immediate:**
1. ✅ Document this workflow (THIS FILE)
2. ⏳ Create `node-deployment-plan-template.md` template
3. ⏳ Define charter creation workflow (next discussion)
4. ⏳ Define knowledge vault integration during charter

### **Future:**
- Document `/document server node configure` workflow
- Document `/new server node enhancement` workflow
- Create automation scripts for structure creation
- Build validation checks into workflow

---

## 📝 Notes

**Quality Gates Identified:**
- Gate 0: Project setup approval (structure review)
- Gate 1: Charter approval (after charter creation)
- Gate 2+: To be defined in later workflow phases

**Constitution Alignment:**
- ✅ Systematic approach
- ✅ Quality over speed (approval gates)
- ✅ Accuracy as job #1 (validation steps)
- ✅ Documentation-first (templates before work)

---

## Related Documents

**Project Lifecycle Workflows:**
- **Phase 0:** `/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md` (this document) - Project initialization
- **Phase 1:** `.claude/commands/workflows/cc-charter-workflow.md` - Charter creation
- **Phase 2:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Specification development
- **Phase 3:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Task breakdown and testing
- **Phase 4:** `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` - Task execution
- **Phase 5:** `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Project closeout

**Standards and Templates:**
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - Node naming, directory structure, file naming
- `/home/agent0/HX-Infrastructure/templates/` - All templates copied during Phase 0
  - `charter-template.md` - Project charter template
  - `node-template.md` - Node specification template
  - `node-deployment-plan-template.md` - Deployment plan template
  - `service-tasks-template.md` - Task documentation template
  - `test-plan-template.md` - Test plan template
  - `test-case-template.md` - Test case template
  - `status-report-template.md` - Status reporting template

**Claude Code Commands:**
- **Set 1:** `.claude/commands/workflows/cc-node-deployment-init.md` - Primary initialization command
- **Set 3:** `.claude/commands/utilities/` - Supporting utilities (artifact-tracker, doc-lint, status-report)

**Governance:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Project principles and governance

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-16 | Initial node deployment workflow with Phase 0 structure creation, template copying, review directory strategy | 465 lines | HX-Infrastructure Team & CAIO |
| 1.1 | 2025-11-21 | Infrastructure philosophy integration, command infrastructure documentation, comprehensive metadata, lifecycle context | +154 lines | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added proper document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose and Target Audience sections
- Added Relationship to 5-Phase Lifecycle context
- Added HX-Infrastructure Philosophy Integration section (manual procedures, Ansible Vault, bare metal awareness)
- Added infrastructure philosophy awareness points for all 5 phases
- Added infrastructure philosophy readiness quality gate
- Added Claude Code Command Infrastructure Integration section
- Added project lifecycle integration pattern diagram
- Added directory structure standardization governance
- Expanded Related Documents with all workflow phases, templates, standards
- Added version history table (this table)

**Backward Compatibility:** 100% - All v1.0 directory structure and workflow unchanged, only documentation and context enhancements added

---

## Document Maintenance

**Document Type:** Procedure - Project Initiation (Phase 0: Setup)
**Status:** APPROVED - Production Ready v1.1
**Maintained By:** Agent Zero (CC) and HX-Infrastructure Team
**Review Frequency:** Quarterly (or when directory structure standards change)
**Last Review:** 2025-11-21
**Next Review:** 2026-02-21

**Update Triggers:**
- Changes to directory structure standard
- Changes to template inventory or locations
- Changes to naming conventions
- Changes to infrastructure philosophy requirements
- Addition of new project types (beyond node deployment, documentation, enhancement)
- Changes to Claude Code command infrastructure
- Template format updates requiring structure changes

**Critical Dependency:**
This document defines the AUTHORITATIVE directory structure for node deployment projects. Changes to this structure require coordinated updates to:
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
- `.claude/commands/workflows/cc-node-deployment-init.md`
- All template files in `/home/agent0/HX-Infrastructure/templates/`
- All existing project structures (migration required)

---

**End of Node Deployment Workflow Documentation**

*This procedure defines Phase 0 (Project Initiation) of the HX-Infrastructure project lifecycle. It establishes the directory structure, copies templates, and prepares the environment for charter creation. All node deployment projects begin with this phase before proceeding to the 5-phase project lifecycle (Charter → Specification → Task Breakdown → Execution → Closeout).*
