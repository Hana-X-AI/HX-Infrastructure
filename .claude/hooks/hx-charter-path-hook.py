#!/usr/bin/env python3
"""
Hook: Charter Path Validator
Event: PreToolUse (Write, Edit)
Purpose: Ensure charter.md references use correct path structure

HX-Infrastructure Standard:
  - charter.md MUST be in: nodes/<node>/charter/charter.md
  - NOT at: nodes/<node>/charter.md (root level)

This hook detects and blocks incorrect charter path references.

Exit Codes:
  0 - Allow (correct path or not applicable)
  2 - Block (wrong charter path detected)
"""

import json
import sys
import re
import os

# Pattern for wrong charter references
# Matches: /nodes/hx-something/charter.md (no charter/ subdirectory)
WRONG_CHARTER_PATTERN = r'/nodes/([^/]+)/charter\.md(?!/)'

# Pattern for correct charter references
# Matches: /nodes/hx-something/charter/charter.md
CORRECT_CHARTER_PATTERN = r'/nodes/([^/]+)/charter/charter\.md'

def check_charter_paths(content: str) -> list:
    """Check content for wrong charter path references."""
    issues = []
    
    # Find wrong charter references
    wrong_matches = re.finditer(WRONG_CHARTER_PATTERN, content)
    
    for match in wrong_matches:
        node_name = match.group(1)
        wrong_path = match.group(0)
        correct_path = f'/nodes/{node_name}/charter/charter.md'
        
        # Get context
        start = max(0, match.start() - 30)
        end = min(len(content), match.end() + 30)
        context = content[start:end]
        
        issues.append({
            'wrong_path': wrong_path,
            'correct_path': correct_path,
            'node_name': node_name,
            'context': context
        })
    
    return issues

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)
    
    tool_name = input_data.get('tool_name', '')
    tool_input = input_data.get('tool_input', {})
    
    # Only check Write and Edit operations
    if tool_name not in ['Write', 'Edit']:
        sys.exit(0)
    
    # Get file path
    filepath = tool_input.get('file_path', '')
    
    # Only check HX-Infrastructure files
    if 'HX-Infrastructure' not in filepath:
        sys.exit(0)
    
    # Get content to check
    content = ''
    if tool_name == 'Write':
        content = tool_input.get('content', '')
    elif tool_name == 'Edit':
        content = tool_input.get('new_string', '')
    
    if not content:
        sys.exit(0)
    
    # Check for wrong charter paths
    issues = check_charter_paths(content)
    
    if issues:
        print("BLOCKED: Wrong charter.md path reference detected", file=sys.stderr)
        print("", file=sys.stderr)
        print("HX-Infrastructure Standard: charter.md must be in charter/ subdirectory", file=sys.stderr)
        print("", file=sys.stderr)
        for issue in issues:
            print(f"  Wrong:   {issue['wrong_path']}", file=sys.stderr)
            print(f"  Correct: {issue['correct_path']}", file=sys.stderr)
            print(f"  Context: ...{issue['context']}...", file=sys.stderr)
            print("", file=sys.stderr)
        
        print("Standard directory structure:", file=sys.stderr)
        print("  nodes/<node-name>/", file=sys.stderr)
        print("  ├── charter/", file=sys.stderr)
        print("  │   └── charter.md    <-- CORRECT location", file=sys.stderr)
        print("  ├── specification/", file=sys.stderr)
        print("  └── planning/", file=sys.stderr)
        print("", file=sys.stderr)
        print("Reference: templates/node-template.md", file=sys.stderr)
        sys.exit(2)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
