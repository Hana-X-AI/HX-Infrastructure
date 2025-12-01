#!/usr/bin/env python3
"""
Hook: HX-Infrastructure File Location Guard
Event: PreToolUse (Write, Edit)
Purpose: Block writes to incorrect file locations based on documented standards

This enforces file structure rules from lessons-learned.md.
"""

import json
import sys
import re
from pathlib import Path

# File location rules: (file_pattern, must_contain_in_path, error_message)
LOCATION_RULES = [
    # charter.md must be in charter/ directory
    (r'/nodes/[^/]+/charter\.md$',
     '/charter/',
     "BLOCKED: charter.md must be in charter/ subdirectory. Correct path: /nodes/{node}/charter/charter.md"),

    # node-spec.md must be in specification/ directory
    (r'/nodes/[^/]+/node-spec\.md$',
     '/specification/',
     "BLOCKED: node-spec.md must be in specification/ subdirectory. Correct path: /nodes/{node}/specification/node-spec.md"),

    # services-deployed.md must be in inventory/ directory
    (r'/nodes/[^/]+/services-deployed\.md$',
     '/inventory/',
     "BLOCKED: services-deployed.md must be in inventory/ subdirectory."),

    # Status reports must be in specification/status-reports/
    (r'/nodes/[^/]+/status-reports?/',
     '/specification/status-reports/',
     "BLOCKED: status-reports/ must be inside specification/ directory."),

    # No UPPERCASE in .md filenames within nodes/
    # Pattern breakdown:
    #   /nodes/   - matches nodes directory
    #   .*/       - matches any subdirectories (greedy, up to last /)
    #   [^/]*     - matches filename chars before uppercase (no slashes)
    #   [A-Z]     - matches the uppercase letter in filename
    #   [^/]*     - matches remaining filename chars (no slashes)
    #   \.md$    - matches .md extension at end
    # This ensures only the filename portion is checked, not directory names
    (r'/nodes/.*/[^/]*[A-Z][^/]*\.md$',
     None,  # Special case - pattern should NOT match valid files
     "BLOCKED: Filename contains UPPERCASE. Use lowercase-with-hyphens per naming standards."),
]


def find_repo_root(start_path: str) -> Path:
    """Find repository root by looking for .git directory."""
    path = Path(start_path).resolve()
    for parent in [path] + list(path.parents):
        if (parent / '.git').exists():
            return parent
    # Fallback to current working directory
    return Path.cwd()


def check_file_location(file_path: str) -> tuple:
    """Check if file location is valid. Returns (is_valid, error_message)."""
    import os
    
    for pattern, required_path, error_message in LOCATION_RULES:
        if re.search(pattern, file_path):
            if required_path is None:
                # This is the uppercase check - verify only filename has uppercase
                # Extract just the filename portion
                filename = os.path.basename(file_path)
                # Check if filename (not path) contains uppercase and ends with .md
                if filename.endswith('.md') and any(c.isupper() for c in filename):
                    return (False, error_message)
                # If pattern matched but filename is actually lowercase, allow it
                # (this handles directory names with uppercase)
                continue
            elif required_path not in file_path:
                return (False, error_message)

    return (True, None)


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get('tool_name', '')
    tool_input = input_data.get('tool_input', {})

    # Only check Write and Edit tools
    if tool_name not in ['Write', 'Edit']:
        sys.exit(0)

    file_path = tool_input.get('file_path', '')

    # Only check files in /nodes/ directory
    if '/nodes/' not in file_path:
        sys.exit(0)

    is_valid, error_message = check_file_location(file_path)

    if not is_valid:
        print(error_message, file=sys.stderr)
        # Dynamically find repo root for lessons-learned.md reference
        repo_root = find_repo_root(file_path)
        lessons_learned = repo_root / 'lessons-learned.md'
        print(f"\nReview: {lessons_learned}", file=sys.stderr)
        sys.exit(2)

    sys.exit(0)


if __name__ == '__main__':
    main()
