# Testing Knowledge Research Process
## Systematic Research of Knowledge Vault for Testing Resources

**Document Type:** Procedure - Testing Support Process
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready v1.1
**Location:** `/home/agent0/HX-Infrastructure/procedures/testing-knowledge-research-process.md`

**Purpose:** Guide for systematically researching knowledge vault repositories to identify testing artifacts, tools, examples, and best practices
**When to Use:** Before test suite generation (Task Workflow Phase 7, STEP 1)
**Who Uses:** Julia (Testing Agent) primarily, but applicable to any agent creating tests
**Key Principle:** Leverage existing testing frameworks and patterns - don't reinvent the wheel
**Previous Version:** 1.0 → 1.1 (infrastructure testing integration, command documentation, comprehensive metadata)

---

## Document Purpose

This procedure defines the **Testing Knowledge Research Process** - a systematic methodology for researching knowledge vault repositories BEFORE generating test suites. This process is **STEP 1** of Phase 7 (Test Suite Generation) in the task workflow, executed by Julia (Testing Agent) to identify testing frameworks, patterns, tools, and examples from technology repositories.

### Target Audience
- **Julia Chen (Testing Agent):** Primary user - executes this research before test suite generation
- **Agent Zero (CC):** Coordinates timing of research in task workflow Phase 7
- **Other Agents:** Any agent creating tests can follow this process

### Related Documents
- **Primary Integration:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Phase 7, STEP 1 (knowledge research)
- **Next Step:** `.claude/commands/phases/cc-phase-test-suite-generation.md` - Phase 7, STEP 2 (uses research findings)
- **Context Loading:** `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Testing phase context load checklist
- **Testing Standards:** `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage requirement
- **Team Structure:** `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Julia's role and responsibilities

---

## 🎯 Overview

**Why This Process Matters:**

When generating test suites, we must leverage the testing knowledge already present in technology repositories. Most repositories contain:
- Pre-built test frameworks and examples
- Recommended testing tools
- Established test patterns and structures
- CI/CD testing configurations
- Testing best practices and documentation

**Failing to research the knowledge vault means:**
- ❌ Reinventing testing frameworks that already exist
- ❌ Missing recommended testing tools
- ❌ Creating tests that don't follow established patterns
- ❌ Lower test quality and coverage
- ❌ More rework and debugging

**Following this process ensures:**
- ✅ Use proven testing tools and frameworks
- ✅ Model tests after working examples
- ✅ Follow established testing patterns
- ✅ Comprehensive test coverage (100% per testing-requirements.md)
- ✅ Higher quality tests with less rework

---

## HX-Infrastructure Testing Considerations

While researching knowledge vault repositories, Julia must also consider HX-Infrastructure-specific testing requirements:

### Infrastructure Philosophy Testing Implications

**Bare Metal Deployment Testing:**
- Look for examples testing bare metal server deployments (not Docker-focused tests)
- Ubuntu/Debian system testing patterns
- Physical/VM infrastructure validation tests
- Server provisioning verification tests

**Systemd Service Testing:**
- Systemd service health check patterns (`systemctl status`)
- Service start/stop/restart testing
- Service dependency validation
- Systemd journal log analysis for errors
- Service recovery testing

**Manual Procedure Testing:**
- Test that manual procedures execute successfully
- Validate manual procedure documentation accuracy
- Verify reproducibility of manual deployment steps
- No automation testing (no Ansible playbook tests)

**Ansible Vault Credential Testing:**
- Ansible Vault access testing (can retrieve credentials)
- Credential format validation
- No plaintext credential validation (ensure all encrypted)
- Vault file integrity checks

### Infrastructure Testing Patterns to Research

While reviewing knowledge vault repositories, prioritize finding:
1. **Service health check tests** - For systemd service validation
2. **Port availability tests** - For network service validation
3. **Configuration file validation tests** - For manual configuration verification
4. **Integration tests** - For service-to-service connectivity
5. **Credential access tests** - For Ansible Vault workflow validation

### Test Categories for HX-Infrastructure

Based on `/home/agent0/HX-Infrastructure/standards/testing-requirements.md`, research should support these test categories:
1. **Deployment Tests** - Bare metal provisioning, systemd service deployment
2. **Functionality Tests** - Service core capabilities
3. **Integration Tests** - Service-to-service communication
4. **Health Check Tests** - Systemd status, service availability

---

## 📋 Research Process (Step-by-Step)

### **STEP 1: Identify Primary Knowledge Repositories**

**Before researching, identify which repositories to review:**

```
From charter/spec phases:
├─ Primary technology repo (core system being deployed)
├─ Integration repos (systems we're integrating with)
├─ Framework repos (if using specific frameworks)
└─ Related technology repos (similar systems for patterns)

Example Decision Tree:
- Deploying MCP server? → Research MCP repository
- Using LangGraph? → Research LangGraph repository  
- Integrating with Ollama? → Research Ollama repository
- Building agentic system? → Research agentic patterns repo

Review knowledge vault assignments from charter phase
```

**Document:**
- Which repos will be researched
- Why each repo is relevant
- Priority order (primary first, integrations second)

---

### **STEP 2: Locate Testing Directories and Files**

**Systematically search each repository for testing artifacts:**

#### **A. Standard Testing Directories**

Look for these common directory names:
```
/tests/              ← Most common
/test/               ← Singular form
/testing/            ← Alternative
/__tests__/          ← JavaScript/Node.js convention
/spec/               ← RSpec/Ruby convention
/pytest/             ← Python pytest
/.github/workflows/  ← CI/CD testing configs
/examples/           ← May contain test examples
/docs/testing/       ← Testing documentation
```

**Search Strategy:**
```bash
# Look for test directories
find . -type d -name "*test*"
find . -type d -name "spec"
find . -type d -name "__tests__"

# Look for test files
find . -type f -name "*test*.py"
find . -type f -name "*test*.js"
find . -type f -name "*spec*.rb"
find . -type f -name "test_*.py"
```

#### **B. Testing Configuration Files**

Look for testing framework configuration:
```
pytest.ini                  ← Python pytest config
.pytest.ini                 ← Hidden pytest config
pyproject.toml             ← Python project config (may include pytest)
tox.ini                    ← Python tox config
jest.config.js             ← JavaScript Jest config
karma.conf.js              ← JavaScript Karma config
phpunit.xml                ← PHP testing config
.coveragerc                ← Coverage configuration
.github/workflows/*.yml    ← CI/CD test automation
```

**What to extract:**
- Testing frameworks used
- Test command syntax
- Coverage requirements
- Test organization structure

#### **C. Testing Documentation**

Look for testing documentation:
```
README.md                  ← Often has "Testing" section
TESTING.md                 ← Dedicated testing docs
CONTRIBUTING.md            ← May include testing guidelines
docs/testing.md            ← Testing documentation
docs/development.md        ← May include testing info
DEVELOPMENT.md             ← Developer docs with testing
```

**What to extract:**
- How to run tests
- Testing philosophy/approach
- Required test coverage
- Testing best practices
- Common pitfalls to avoid

---

### **STEP 3: Analyze Testing Structure and Patterns**

**For each repository, document the testing approach:**

#### **A. Test Organization Structure**

```
Example Repository Test Structure:

/tests/
├── unit/                  ← Unit tests (isolated component tests)
│   ├── test_component1.py
│   ├── test_component2.py
│   └── test_utils.py
├── integration/           ← Integration tests (component interactions)
│   ├── test_api_integration.py
│   ├── test_database_integration.py
│   └── test_service_integration.py
├── e2e/                   ← End-to-end tests (full workflows)
│   ├── test_user_workflow.py
│   └── test_deployment_workflow.py
├── fixtures/              ← Test data and fixtures
│   ├── sample_data.json
│   └── mock_responses.py
├── conftest.py           ← Pytest fixtures (shared setup)
└── __init__.py

Pattern Identified:
- Tests organized by type (unit/integration/e2e)
- Naming convention: test_*.py
- Shared fixtures in conftest.py
- Test data in fixtures/ directory
```

**Document:**
- Directory structure used
- File naming conventions
- How tests are categorized
- Shared fixture approach
- Test data management

#### **B. Test File Patterns**

**Examine multiple test files to identify patterns:**

```python
# Example Test File Pattern Analysis

# Pattern 1: Test Class Structure
class TestComponentName:
    """Tests for ComponentName functionality"""
    
    def setup_method(self):
        """Setup before each test"""
        # Pattern: Setup method for test initialization
    
    def test_basic_functionality(self):
        """Test basic operation"""
        # Pattern: Descriptive test names
        # Pattern: Given-When-Then structure
        
    def test_error_handling(self):
        """Test error conditions"""
        # Pattern: Separate error handling tests
        
    def teardown_method(self):
        """Cleanup after each test"""
        # Pattern: Cleanup method

# Pattern 2: Pytest-style Functions
def test_function_name():
    """Test description"""
    # Given
    setup_data = create_test_data()
    
    # When
    result = function_under_test(setup_data)
    
    # Then
    assert result == expected_value
    assert result.property == expected_property

# Pattern 3: Fixtures Usage
@pytest.fixture
def sample_data():
    """Provide test data"""
    return {"key": "value"}

def test_with_fixture(sample_data):
    """Test using fixture"""
    result = process(sample_data)
    assert result is not None
```

**Document:**
- Test structure (classes vs functions)
- Naming patterns
- Setup/teardown patterns
- Assertion patterns
- Fixture usage patterns
- Comment/documentation patterns

#### **C. Testing Tools and Frameworks**

**Identify which testing tools are used:**

```
Common Patterns by Language:

Python:
- pytest              ← Most common Python testing framework
- unittest           ← Standard library
- pytest-cov         ← Coverage plugin
- pytest-asyncio     ← Async testing
- pytest-mock        ← Mocking framework
- hypothesis         ← Property-based testing

JavaScript/Node.js:
- Jest               ← React/Node testing
- Mocha              ← Test framework
- Chai               ← Assertion library
- Sinon              ← Mocking/stubbing
- Cypress            ← E2E testing
- Testing Library    ← Component testing

Other Languages:
- RSpec (Ruby)
- JUnit (Java)
- NUnit (C#)
- Go testing package
```

**Document:**
- Primary testing framework
- Additional testing libraries
- Mocking/stubbing tools
- Coverage tools
- E2E testing tools
- Performance testing tools

---

### **STEP 4: Extract Test Examples**

**Find and analyze example tests for the technology:**

#### **A. Basic Functionality Tests**

```
Look for:
- Installation verification tests
- Basic operation tests
- Configuration tests
- Initialization tests

Example from repository:
def test_service_initialization():
    """Verify service initializes correctly"""
    service = ServiceClass(config)
    assert service.is_initialized()
    assert service.config == config
    assert service.status == "ready"

Key Patterns Extracted:
1. Test initialization separately
2. Verify multiple properties
3. Check status/state after init
```

**Document:**
- Basic test examples found
- What they test
- How they structure assertions
- Setup requirements

#### **B. Integration Tests**

```
Look for:
- API integration tests
- Database connection tests
- External service tests
- Component interaction tests

Example from repository:
@pytest.mark.integration
async def test_api_connection():
    """Test API connectivity"""
    async with ApiClient(config) as client:
        response = await client.health_check()
        assert response.status_code == 200
        assert response.data["status"] == "healthy"

Key Patterns Extracted:
1. Mark integration tests with decorator
2. Use async/await for API calls
3. Context managers for connections
4. Check both status and content
```

**Document:**
- Integration test examples
- How they handle connections
- Async patterns (if applicable)
- Assertion strategies

#### **C. Error Handling Tests**

```
Look for:
- Exception testing
- Error condition tests
- Validation tests
- Boundary condition tests

Example from repository:
def test_invalid_input_raises_error():
    """Test invalid input handling"""
    with pytest.raises(ValidationError) as exc_info:
        service.process(invalid_data)
    
    assert "Invalid format" in str(exc_info.value)
    assert exc_info.value.code == "INVALID_INPUT"

Key Patterns Extracted:
1. Use pytest.raises for exceptions
2. Verify exception details
3. Check error codes/messages
4. Test boundary conditions
```

**Document:**
- Error test patterns
- How exceptions are tested
- What error details are verified
- Boundary condition approaches

#### **D. Mocking and Stubbing**

```
Look for:
- External dependency mocks
- Database mocks
- API mocks
- Time/date mocks

Example from repository:
@pytest.fixture
def mock_external_service(mocker):
    """Mock external service calls"""
    mock = mocker.patch('module.external_service')
    mock.return_value = {"status": "success"}
    return mock

def test_with_mocked_service(mock_external_service):
    """Test using mocked external service"""
    result = function_that_calls_external_service()
    
    assert mock_external_service.called
    assert mock_external_service.call_count == 1
    assert result["status"] == "success"

Key Patterns Extracted:
1. Use fixtures for mocks
2. Verify mock was called
3. Check call count
4. Verify mock return values used
```

**Document:**
- Mocking patterns used
- What gets mocked
- How to verify mock calls
- Mock data patterns

---

### **STEP 5: Identify Testing Best Practices**

**Extract testing best practices from repository documentation:**

#### **A. From Documentation**

```
Common Best Practices Found:

Coverage Requirements:
- "Maintain minimum 80% code coverage"
- "All public APIs must have tests"
- "Integration tests for all external connections"

Test Organization:
- "One test file per module"
- "Test file mirrors source file structure"
- "Use descriptive test names"

Test Data:
- "Use fixtures for common test data"
- "Don't commit sensitive data to test files"
- "Generate test data dynamically when possible"

CI/CD:
- "Tests must pass before merge"
- "Run tests on all Python versions"
- "Generate coverage reports"
```

**Document:**
- Coverage requirements
- Test organization rules
- Naming conventions
- CI/CD requirements
- Test data best practices

#### **B. From Configuration Files**

```
Example pytest.ini Analysis:

[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --verbose
    --cov=src
    --cov-report=html
    --cov-report=term
    --cov-fail-under=80

Key Insights:
1. Tests in /tests directory
2. Files must start with "test_"
3. Classes must start with "Test"
4. Functions must start with "test_"
5. Verbose output required
6. Coverage required with 80% minimum
7. HTML and terminal coverage reports
```

**Document:**
- Required coverage levels
- Naming conventions enforced
- Report formats required
- Additional plugins needed

#### **C. From CI/CD Workflows**

```
Example .github/workflows/test.yml Analysis:

name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, 3.10, 3.11]
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: pip install -r requirements-dev.txt
      - name: Run tests
        run: pytest tests/
      - name: Upload coverage
        uses: codecov/codecov-action@v2

Key Insights:
1. Tests run on every push and PR
2. Tests must pass on multiple Python versions
3. Separate dev requirements file
4. Coverage uploaded to codecov
5. Tests block merge if failing
```

**Document:**
- When tests run (triggers)
- Test environments required
- Multiple versions tested
- Coverage reporting approach
- Blocking vs non-blocking tests

---

### **STEP 6: Document Research Findings**

**Create comprehensive research documentation:**

**Location:** `/nodes/[node-name]/reviews/team-member/julia/testing-knowledge-research.md`

**Template:**
```markdown
# Testing Knowledge Research: [Node Name]
**Researcher:** Julia (Testing Agent)
**Date:** [YYYY-MM-DD]
**Phase:** Test Suite Generation (Task Workflow Phase 7)
**Repositories Researched:** [list]
**Research Time:** [X minutes]

---

## Repositories Researched

### Primary Repository: [repo-name]
**URL:** [repo-url]
**Relevance:** [why researched]
**Testing Directory:** [path]
**Last Updated:** [date]

### Integration Repository: [repo-name]
**URL:** [repo-url]
**Relevance:** [why researched]
**Testing Directory:** [path]

---

## Testing Framework Analysis

### Primary Framework: [framework-name]
**Installation:** `[install-command]`
**Documentation:** [url]
**Version Used:** [version]

**Plugins/Extensions Used:**
- [plugin-1]: [purpose]
- [plugin-2]: [purpose]
- [plugin-3]: [purpose]

### Testing Tools Stack:
```
Primary Framework:    [pytest|jest|junit|etc]
Mocking Framework:    [pytest-mock|sinon|etc]
Coverage Tool:        [pytest-cov|istanbul|etc]
E2E Framework:        [cypress|playwright|etc]
CI/CD Platform:       [GitHub Actions|GitLab CI|etc]
```

**Recommendation:** Use [framework] because:
1. [reason 1]
2. [reason 2]
3. [reason 3]

---

## Test Organization Structure

### Directory Structure Found:
```
/tests/
├── unit/              ← [purpose]
├── integration/       ← [purpose]
├── e2e/              ← [purpose]
├── fixtures/         ← [purpose]
└── conftest.py       ← [purpose]
```

### Naming Conventions Found:
- Test files: `test_*.py` or `*_test.py`
- Test classes: `Test*` or `*Test`
- Test functions: `test_*`
- Fixtures: `*_fixture` or descriptive names

### Recommendation:
Adopt [structure] because:
- [reason 1]
- [reason 2]

---

## Test Pattern Examples

### Pattern 1: Basic Functionality Test
**Source:** [repo-name]/tests/unit/test_example.py

**Pattern Identified:**
```python
[code example showing pattern]
```

**Key Insights:**
- [insight 1]
- [insight 2]
- [insight 3]

**Application to Our Project:**
We will use this pattern for:
- [use case 1]
- [use case 2]

### Pattern 2: Integration Test
**Source:** [repo-name]/tests/integration/test_api.py

**Pattern Identified:**
```python
[code example showing pattern]
```

**Key Insights:**
- [insight 1]
- [insight 2]

**Application to Our Project:**
We will use this pattern for:
- [use case 1]
- [use case 2]

### Pattern 3: Error Handling Test
**Source:** [repo-name]/tests/unit/test_errors.py

**Pattern Identified:**
```python
[code example showing pattern]
```

**Key Insights:**
- [insight 1]
- [insight 2]

**Application to Our Project:**
We will use this pattern for:
- [use case 1]
- [use case 2]

---

## Mocking and Stubbing Patterns

### Mocking Framework: [framework]

**Common Mocking Patterns Found:**

1. **External API Mocking:**
```python
[example code]
```

2. **Database Mocking:**
```python
[example code]
```

3. **File System Mocking:**
```python
[example code]
```

**Recommendation:**
Use [approach] for mocking because:
- [reason 1]
- [reason 2]

---

## Coverage Requirements

### Repository Standards:
- **Minimum Coverage:** [X]%
- **Coverage Tools:** [tool-name]
- **Coverage Reports:** [formats]
- **Coverage Exclusions:** [what's excluded]

### Configuration Found:
```ini
[coverage configuration]
```

### Recommendation:
Adopt [X]% coverage requirement because:
- Aligns with testing-requirements.md (100% mandate)
- Matches industry standards for [technology]
- Provides confidence in deployment

---

## CI/CD Testing Integration

### Testing Automation Found:
**Platform:** [GitHub Actions|GitLab CI|etc]
**Workflow File:** [path]

**Test Execution Strategy:**
- Triggered on: [push|PR|schedule]
- Runs on: [OS/versions]
- Test environments: [list]
- Blocks merge: [yes|no]

**Configuration Example:**
```yaml
[relevant CI/CD config]
```

### Recommendation:
Implement [approach] because:
- [reason 1]
- [reason 2]

---

## Best Practices Identified

### Code Quality:
1. [practice 1]
2. [practice 2]
3. [practice 3]

### Test Organization:
1. [practice 1]
2. [practice 2]
3. [practice 3]

### Test Data:
1. [practice 1]
2. [practice 2]
3. [practice 3]

### Performance:
1. [practice 1]
2. [practice 2]
3. [practice 3]

---

## Gaps and Limitations

### What Repository Tests DON'T Cover:
1. [gap 1] - We need to add this
2. [gap 2] - We need to add this
3. [gap 3] - We need to add this

### What Repository Tests Do Poorly:
1. [limitation 1] - We'll improve this
2. [limitation 2] - We'll improve this

### Additional Tests We Need:
1. [additional test type 1] - Because [reason]
2. [additional test type 2] - Because [reason]

---

## Pre-Built Tests We Can Leverage

### Test 1: [test-name]
**Source:** [file-path]
**Purpose:** [what it tests]
**Can we use as-is?** [Yes|No|Adapt]
**Adaptation needed:** [description]

### Test 2: [test-name]
**Source:** [file-path]
**Purpose:** [what it tests]
**Can we use as-is?** [Yes|No|Adapt]
**Adaptation needed:** [description]

### Test 3: [test-name]
**Source:** [file-path]
**Purpose:** [what it tests]
**Can we use as-is?** [Yes|No|Adapt]
**Adaptation needed:** [description]

---

## Testing Strategy for Our Project

### Based on Research, Our Testing Approach:

**Framework:** [chosen-framework]
**Tools:** [tool-list]
**Organization:** [structure]
**Coverage Target:** [X]% (per testing-requirements.md: 100%)
**Test Categories:**
1. Deployment validation tests
2. Functionality tests
3. Integration tests
4. Health check tests
5. [Additional categories based on project]

### Test Patterns We'll Use:
1. [pattern 1] - From [repo-name]
2. [pattern 2] - From [repo-name]
3. [pattern 3] - From [repo-name]

### Pre-Built Tests We'll Leverage:
1. [test 1] - [adaptation needed]
2. [test 2] - [adaptation needed]
3. [test 3] - [adaptation needed]

---

## References

### Documentation URLs:
- [framework docs]: [url]
- [tool docs]: [url]
- [repo testing guide]: [url]

### Example Test Files:
- [example 1]: [url]
- [example 2]: [url]
- [example 3]: [url]

### Configuration Files:
- [config 1]: [url]
- [config 2]: [url]

---

## Time Investment

**Research Time Breakdown:**
- Repository exploration: [X] minutes
- Test file analysis: [Y] minutes
- Documentation review: [Z] minutes
- Pattern extraction: [A] minutes
- Documentation writing: [B] minutes
- **Total:** [Total] minutes

**Value Delivered:**
- Identified [N] reusable test patterns
- Found [M] pre-built tests to leverage
- Established testing framework and tools
- Documented best practices
- Reduced test creation time by estimated [X]%
```

---

## ✅ Research Quality Checklist

**Before moving to test suite generation, verify:**

- [ ] Primary repository tested thoroughly researched
- [ ] Integration repository tests reviewed (if applicable)
- [ ] Testing framework identified and documented
- [ ] Test organization structure understood
- [ ] At least 3 test pattern examples documented
- [ ] Mocking/stubbing patterns identified
- [ ] Coverage requirements documented
- [ ] CI/CD testing approach understood
- [ ] Best practices extracted and documented
- [ ] Pre-built tests identified for potential use
- [ ] Testing strategy for project defined
- [ ] All findings documented in research document

---

## 🔗 Integration with Task Workflow

**This process integrates with Task Workflow Phase 7:**

```
Task Workflow Phase 7, STEP 1: Context Loading (30-40 minutes)
   ├─ Load charter, spec, tasks, RAIDD, etc.
   └─ **Knowledge vault research (THIS PROCESS)**
       ├─ Follow Testing Knowledge Research Process
       ├─ Create testing-knowledge-research.md
       └─ Document framework, tools, patterns, examples

Task Workflow Phase 7, STEP 2: Test Suite Generation (90-120 minutes)
   ├─ USE findings from knowledge research
   ├─ USE recommended frameworks and tools
   ├─ MODEL tests after identified patterns
   ├─ LEVERAGE pre-built tests found
   └─ FOLLOW best practices documented
```

**Reference this document in:**
- `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` Phase 7, STEP 1
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` for testing phase
- Test plan creation (reference research findings)

---

## 📊 Success Metrics

**Research is successful when:**

1. ✅ Testing framework clearly identified and justified
2. ✅ Testing tools documented with installation instructions
3. ✅ Test organization structure defined
4. ✅ At least 3 reusable test patterns documented
5. ✅ Mocking approach identified
6. ✅ Coverage requirements understood
7. ✅ Best practices extracted from repository
8. ✅ Pre-built tests identified (if any exist)
9. ✅ Testing strategy defined for project
10. ✅ Research findings documented comprehensively
11. ✅ Ready to generate test suite using research

---

## 🔑 Key Principles

**Remember:**

1. **Leverage, Don't Reinvent:**
   - If repo has tests, learn from them
   - If tool is recommended, use it
   - If pattern works, adopt it

2. **Document Thoroughly:**
   - Future team members need to understand choices
   - Research findings inform test suite decisions
   - Justification for framework/tool selection

3. **Be Systematic:**
   - Follow process step-by-step
   - Don't skip steps
   - Complete checklist before proceeding

4. **Think Critically:**
   - Not all repo tests are good examples
   - Some patterns may not apply to our project
   - Adapt, don't blindly copy

5. **Time-Box Research:**
   - Aim for 30-40 minutes of focused research
   - Balance thoroughness with efficiency
   - Document as you research

---

---

## Claude Code Command Infrastructure Integration

### How Commands Invoke This Process

**Set 4: Phase Commands (Primary Integration)**
- **`cc-phase-knowledge-research.md`:** Primary command implementing this research process
  - Julia invokes during task workflow Phase 7, STEP 1
  - Executes systematic knowledge vault research
  - Creates testing-knowledge-research.md output document
  - Outputs used by cc-phase-test-suite-generation.md in STEP 2

**Set 5: Agent Orchestration**
- **`cc-orchestrate-julia.md`:** Coordinates Julia's test suite generation workflow
  - Phase 7 STEP 1: Knowledge vault research (this process)
  - Phase 7 STEP 2: Test suite generation (uses research findings)

**Integration with Task Workflow:**
```
Task Workflow Phase 7: Test Suite Generation
├─ Agent Zero assigns test generation to Julia
├─ Julia loads context (charter, spec, tasks, RAIDD)
└─ STEP 1: Knowledge Vault Research (THIS PROCESS)
    ├─ cc-phase-knowledge-research.md executes
    ├─ Julia researches technology repositories
    ├─ Identifies frameworks, tools, patterns, examples
    ├─ Creates testing-knowledge-research.md
    └─ Documents findings (30-40 minutes)
↓
STEP 2: Test Suite Generation
├─ cc-phase-test-suite-generation.md executes
├─ Julia USES research findings
├─ Uses recommended frameworks
├─ Models tests after identified patterns
├─ Leverages pre-built tests
└─ Generates complete test suite (90-120 minutes)
```

**Research Output Used By:**
- `cc-phase-test-suite-generation.md` - Primary consumer of research findings
- Test plan creation - References framework and tool choices
- Test suite generation - Uses patterns and examples identified
- Team review - References research to validate test approach

---

## Related Documents

**Task Workflow Integration:**
- **Primary:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Phase 7, STEP 1 (knowledge research)
- **Follow-up:** Phase 7, STEP 2 (test suite generation uses these findings)

**Testing Documentation:**
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage requirement, test categories
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Testing phase context load checklist

**Claude Code Commands:**
- **Set 4:** `.claude/commands/phases/cc-phase-knowledge-research.md` - Primary research command
- **Set 4:** `.claude/commands/phases/cc-phase-test-suite-generation.md` - Uses research findings
- **Set 5:** `.claude/commands/agents/cc-orchestrate-julia.md` - Julia orchestration including research

**Team Documentation:**
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Julia's role as testing specialist
- **Julia Profile:** `.claude/agents/julia.md` - Testing & quality specialist capabilities

**Templates:**
- Research output template provided in STEP 6 of this document
- Test templates: `/home/agent0/HX-Infrastructure/templates/test-*.md`

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-17 | Initial testing knowledge research process with 6-step methodology, research template, quality checklist | 970 lines | HX-Infrastructure Team |
| 1.1 | 2025-11-21 | Infrastructure testing integration, command infrastructure documentation, comprehensive metadata | +99 lines | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added proper document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose and Target Audience sections
- Added comprehensive Related Documents section
- Added HX-Infrastructure Testing Considerations section (infrastructure philosophy testing implications)
- Added infrastructure testing patterns to research (systemd, bare metal, manual procedures, Ansible Vault)
- Added test categories for HX-Infrastructure (deployment, functionality, integration, health)
- Added Claude Code Command Infrastructure Integration section (Sets 4, 5)
- Added research process integration pattern diagram
- Expanded Related Documents with task workflow, commands, templates, team documentation
- Added version history table (this table)

**Backward Compatibility:** 100% - All v1.0 research steps unchanged, only infrastructure testing guidance and documentation enhancements added

---

## Document Maintenance

**Document Type:** Procedure - Testing Support Process
**Status:** APPROVED - Production Ready v1.1
**Maintained By:** Agent Zero (CC) and Julia Chen (Testing Specialist)
**Review Frequency:** Quarterly (or when testing research process changes)
**Last Review:** 2025-11-21
**Next Review:** 2026-02-21

**Update Triggers:**
- Changes to knowledge vault research methodology
- Changes to testing frameworks or tools recommended
- Changes to infrastructure philosophy testing requirements
- Changes to test categories in testing-requirements.md
- Changes to task workflow Phase 7 structure
- New testing patterns emerge from projects
- Julia identifies research process improvements

**Research Process Evolution:**
This document should evolve based on Julia's experience:
- Capture new research patterns that prove effective
- Document testing framework trends
- Update infrastructure testing guidance
- Refine time estimates based on actual research duration
- Add examples of successful research outputs

---

**End of Testing Knowledge Research Process Documentation**

*This procedure defines the systematic methodology for researching knowledge vault repositories before test suite generation. It is STEP 1 of task workflow Phase 7, executed by Julia to identify testing frameworks, patterns, tools, and examples. Research findings directly inform test suite generation, ensuring tests leverage proven frameworks and follow established patterns while meeting HX-Infrastructure's 100% coverage requirement and infrastructure philosophy compliance.*
