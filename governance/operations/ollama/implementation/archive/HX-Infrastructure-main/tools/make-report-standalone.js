// Build openable-from-disk copies of the per-AI reports under governance/reports/.
//
// Those reports live in subdirectories and are not part of the flat nine-page set that
// make-standalone.js handles, so they were only reachable through their published
// artifact URLs. This gives each one a fully-formed document under governance/site/reports/
// that opens with no network and no claude.ai account.

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const SRC = path.join(REPO, 'governance', 'reports');
const OUT = path.join(REPO, 'governance', 'site', 'reports');
const links = JSON.parse(fs.readFileSync(path.join(__dirname, 'links.json'), 'utf8'));

const REPORTS = [
  ['claude-code', 'merge-plan-feedback.html'],
  ['chatgpt', 'hx-infrastructure-legacy-to-current-repo-merge-assessment.html'],
  ['claude', 'claude_20260813_1053_legacymergedecision.html'],
];

let written = 0;
for (const [dir, file] of REPORTS) {
  const src = path.join(SRC, dir, file);
  if (!fs.existsSync(src)) { throw new Error('missing report: ' + src); }
  let html = fs.readFileSync(src, 'utf8');

  const titleMatch = html.match(/<title>([\s\S]*?)<\/title>/i);
  if (!titleMatch) { throw new Error('no <title> in ' + file); }
  const title = titleMatch[1].trim();
  html = html.replace(titleMatch[0], '');

  const styleMatch = html.match(/<style>[\s\S]*?<\/style>/i);
  const style = styleMatch ? styleMatch[0] : '';
  if (styleMatch) { html = html.replace(style, ''); }

  // Point the governance back-link at the local home page instead of the artifact URL.
  if (links.index && links.index !== '#') {
    html = html.split(links.index).join('../../index.html');
  }

  fs.mkdirSync(path.join(OUT, dir), { recursive: true });
  fs.writeFileSync(path.join(OUT, dir, file), `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
${style}
</head>
<body>
${html.trim()}
</body>
</html>
`);
  written++;
  console.log('wrote governance/site/reports/' + dir + '/' + file);
}

console.log('---');
console.log(written + ' report pages written, openable from disk');
