// Rewrite the shared nav block in every governance page from tools/links.json.
//
// The nav was hand-maintained at first and immediately went stale: adding the
// architecture page left the inventory page's nav one link short, which only
// surfaced because make-standalone.js refuses to emit a set that isn't fully
// cross-linked. Generating it removes that class of mistake.
//
// Pages authored by hand keep their own stylesheet and markup; this touches
// only the <nav class="nav">…</nav> block and nothing else.

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const SRC = path.join(REPO, 'governance');
const links = JSON.parse(fs.readFileSync(path.join(__dirname, 'links.json'), 'utf8'));

// key -> [filename, nav label]. Order here is the order in the nav.
const PAGES = {
  index: ['index.html', 'Governance'],
  inventory: ['hx-fleet-inventory.html', 'Fleet inventory'],
  architecture: ['fleet-architecture-v0.2.html', 'Architecture v0.2'],
  frozen: ['hx-stack-alignment-v0.1-frozen.html', 'v0.1 frozen'],
  validation: ['hx-validation-findings.html', 'Validation'],
  recommendations: ['hx-recommendations.html', 'Recommendations'],
  actions: ['actions-and-issues.html', 'Actions &amp; issues'],
  lessons: ['lessons-learned.html', 'Lessons learned'],
  standards: ['documentation-standards.html', 'Standards'],
};

function navFor(currentKey) {
  const items = Object.entries(PAGES).map(([key, [, label]]) => {
    const href = links[key] || '#';
    const cur = key === currentKey ? ' aria-current="page"' : '';
    return `        <a href="${href}"${cur}>${label}</a>`;
  });
  return '<nav class="nav">\n' + items.join('\n') + '\n      </nav>';
}

let touched = 0;
for (const [key, [file]] of Object.entries(PAGES)) {
  const p = path.join(SRC, file);
  if (!fs.existsSync(p)) { throw new Error('missing page: ' + file); }
  const before = fs.readFileSync(p, 'utf8');
  // Generated pages get their nav from build-governance-html.js; skip those.
  if (!/<nav class="nav">/.test(before)) { continue; }
  const after = before.replace(/<nav class="nav">[\s\S]*?<\/nav>/, navFor(key));
  if (after !== before) { fs.writeFileSync(p, after); touched++; console.log('nav updated: ' + file); }
}

// Every page must now reach every other page.
for (const [, [file]] of Object.entries(PAGES)) {
  const html = fs.readFileSync(path.join(SRC, file), 'utf8');
  for (const [key, [target]] of Object.entries(PAGES)) {
    if (target === file) { continue; }
    const url = links[key];
    if (url && url !== '#' && !html.includes(url)) {
      throw new Error(file + ' does not link to ' + target);
    }
  }
}

console.log('---');
console.log(touched + ' navs rewritten, ' + Object.keys(PAGES).length + ' pages cross-linked');
