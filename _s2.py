import pathlib
f = pathlib.Path(r'governance/Phase -3-Regroup/repo review/claude_20260815_0130_phase3remediationplandeep.html')
text = f.read_text(encoding='utf-8')
body_end = text.find('<body><main>') + len('<body><main>')
eyebrow_start = text.find('<div class="eyebrow">')
banner = (
    '\n<div style="background:#3a1418;border:3px solid #ff7d87;border-radius:12px;padding:20px 24px;margin:0 0 28px;text-align:center">\n'
    '<p style="color:#ff7d87;font-size:1.4rem;font-weight:900;margin:0 0 8px;letter-spacing:.04em">SUPERSEDED V1</p>\n'
    '<p style="color:#e8eef4;margin:0;font-size:1rem">This document is a historical artifact. The canonical current plan is\n'
    '<a href="../remediation/claude_20260815_0150_phase3remediationplandeepv2.html" style="color:#6fc6ff;font-weight:700">Phase 3 Remediation Plan v2</a>.</p>\n'
    '</div>\n\n'
)
text = text[:body_end] + banner + text[eyebrow_start:]
f.write_text(text, encoding='utf-8')
count = text.count('SUPERSEDED V1')
print(f'Banner count: {count}')
assert count == 1, f'Expected 1, got {count}'
print('Stage 2 PASS')
