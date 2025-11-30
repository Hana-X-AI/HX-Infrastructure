#!/usr/bin/env python3
"""
Hook: IP Address Validator
Event: PreToolUse (Write, Edit)
Purpose: Prevent wrong IP addresses from being written to HX-Infrastructure files

This hook validates that IP addresses for known services match the authoritative
inventory in /home/agent0/HX-Infrastructure/inventory/nodes.md

Exit Codes:
  0 - Allow (no IP issues or not applicable)
  2 - Block (wrong IP detected)
"""

import json
import sys
import re
import os

# Authoritative IP mappings from inventory/nodes.md
# These are the CORRECT IPs for each service
CORRECT_IPS = {
    'hx-dc-server': '192.168.10.200',
    'hx-ca-server': '192.168.10.201',
    'hx-ssl-server': '192.168.10.202',
    'hx-control-node': '192.168.10.203',
    'hx-qdrant-server': '192.168.10.207',
    'hx-redis-server': '192.168.10.210',
    'hx-litellm-server': '192.168.10.212',
    'hx-fastmcp-server': '192.168.10.213',
    'hx-docling-server': '192.168.10.216',
    'hx-docling-mcp-server': '192.168.10.217',
    'hx-literag-server': '192.168.10.220',
    'hx-agui-server': '192.168.10.221',
    'hx-demo-server': '192.168.10.223',
    'hx-infrastructure': '192.168.10.224',
}

# Known WRONG IPs that have caused issues
# Map of wrong IP -> what it was mistakenly used for
KNOWN_WRONG_IPS = {
    '192.168.10.213': {
        'actual': 'hx-fastmcp-server',
        'mistaken_for': 'hx-litellm-server',
        'correct_ip': '192.168.10.212'
    },
    '192.168.10.221': {
        'actual': 'hx-agui-server',
        'mistaken_for': 'hx-redis-server',
        'correct_ip': '192.168.10.210'
    },
    '192.168.10.223': {
        'actual': 'hx-demo-server',
        'mistaken_for': 'hx-qdrant-server',
        'correct_ip': '192.168.10.207'
    },
}

def find_repo_root() -> str:
    """Find HX-Infrastructure root directory."""
    markers = ['.git', 'inventory', 'nodes', 'standards']
    current = os.getcwd()
    while current != '/':
        if all(os.path.exists(os.path.join(current, m)) for m in markers[:2]):
            return current
        current = os.path.dirname(current)
    return '/home/agent0/HX-Infrastructure'

def check_ip_in_content(content: str, filepath: str) -> list:
    """Check content for wrong IP addresses."""
    issues = []
    
    # Find all IP addresses in content
    ip_pattern = r'192\.168\.10\.(\d{1,3})'
    matches = re.finditer(ip_pattern, content)
    
    for match in matches:
        full_ip = match.group(0)
        
        # Check if this is a known wrong IP
        if full_ip in KNOWN_WRONG_IPS:
            info = KNOWN_WRONG_IPS[full_ip]
            issues.append({
                'wrong_ip': full_ip,
                'actual_server': info['actual'],
                'likely_intended': info['mistaken_for'],
                'correct_ip': info['correct_ip'],
                'context': content[max(0, match.start()-30):match.end()+30]
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
    
    # Check for wrong IPs
    issues = check_ip_in_content(content, filepath)
    
    if issues:
        print("BLOCKED: Wrong IP address(es) detected in content", file=sys.stderr)
        print("", file=sys.stderr)
        for issue in issues:
            print(f"  Wrong IP: {issue['wrong_ip']}", file=sys.stderr)
            print(f"  This is actually: {issue['actual_server']}", file=sys.stderr)
            print(f"  You probably meant: {issue['likely_intended']} ({issue['correct_ip']})", file=sys.stderr)
            print(f"  Context: ...{issue['context']}...", file=sys.stderr)
            print("", file=sys.stderr)
        
        print("Reference: inventory/nodes.md for authoritative IP addresses", file=sys.stderr)
        print("", file=sys.stderr)
        print("Common corrections:", file=sys.stderr)
        print("  - hx-litellm-server: 192.168.10.212 (NOT .213)", file=sys.stderr)
        print("  - hx-qdrant-server:  192.168.10.207 (NOT .223)", file=sys.stderr)
        print("  - hx-redis-server:   192.168.10.210 (NOT .221)", file=sys.stderr)
        sys.exit(2)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
