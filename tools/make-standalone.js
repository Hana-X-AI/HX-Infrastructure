// Produce standalone, portable copies of the governance pages in governance/site/.
//
// Why this exists as a second output rather than a change to the originals:
// the Artifact publisher wraps the source file in its own
// <!doctype html><head></head><body> skeleton at publish time and requires the
// source NOT to carry those tags. Adding them would nest a second document
// inside the first. So the files in governance/ stay artifact-shaped, and this
// script emits a fully-formed document for anyone opening the pages from disk,
// a file server, or an exported bundle.
//
// Two things the artifact-shaped source cannot provide on its own:
//   - <!DOCTYPE html>, <html lang="en">, <head>, <body>, and a charset
//   - <meta name="viewport">, without which a phone lays the page out at
//     desktop width and then scales it down, so the clamp() sizing never
//     engages and the responsive design is inert
//
// It also rewrites the five inter-page links. In governance/ they are absolute
// claude.ai artifact URLs, which resolve only inside Claude and only for the
// owning account. Here they become plain relative filenames.

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const SRC = path.join(REPO, 'governance');
const OUT = path.join(SRC, 'site');

const links = JSON.parse(fs.readFileSync(path.join(__dirname, 'links.json'), 'utf8'));

// artifact URL -> the local filename that holds the same page
const LOCAL = {
  index: 'index.html',
  actions: 'actions-and-issues.html',
  lessons: 'lessons-learned.html',
  standards: 'documentation-standards.html',
  inventory: 'hx-fleet-inventory.html',
  architecture: 'fleet-architecture-candidate-v0.1.html',
};

const PAGES = Object.values(LOCAL);

fs.mkdirSync(OUT, { recursive: true });

let rewritten = 0;

for (const file of PAGES) {
  const srcPath = path.join(SRC, file);
  if (!fs.existsSync(srcPath)) {
    throw new Error('missing source page: ' + srcPath);
  }
  let html = fs.readFileSync(srcPath, 'utf8');

  // Pull the title out; it belongs in <head>, not loose at the top of the body.
  const titleMatch = html.match(/<title>([\s\S]*?)<\/title>/i);
  if (!titleMatch) { throw new Error('no <title> in ' + file); }
  const title = titleMatch[1].trim();
  html = html.replace(titleMatch[0], '');

  // Hoist the stylesheet into <head> rather than leaving it in the body.
  const styleMatch = html.match(/<style>[\s\S]*?<\/style>/i);
  if (!styleMatch) { throw new Error('no <style> in ' + file); }
  const style = styleMatch[0];
  html = html.replace(style, '');

  // Point the nav and cards at sibling files instead of artifact URLs.
  for (const [key, url] of Object.entries(links)) {
    if (!url || url === '#') { continue; }
    const local = LOCAL[key];
    if (!local) { continue; }
    const before = html;
    html = html.split(url).join(local);
    if (html !== before) { rewritten++; }
  }

  const body = html.trim();

  const doc = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
${style}
</head>
<body>
${body}
</body>
</html>
`;

  fs.writeFileSync(path.join(OUT, file), doc);
  console.log('wrote governance/site/' + file);
}

// Nothing should still point at an artifact URL in the standalone build.
for (const file of PAGES) {
  const out = fs.readFileSync(path.join(OUT, file), 'utf8');
  const stray = out.match(/https:\/\/claude\.ai\/code\/artifact\/[a-f0-9-]+/g);
  if (stray) { throw new Error(file + ' still contains artifact URLs: ' + stray.join(', ')); }
  for (const target of PAGES) {
    if (target === file) { continue; }
    if (!out.includes('href="' + target + '"')) {
      throw new Error(file + ' does not link to ' + target);
    }
  }
}

console.log('---');
console.log(PAGES.length + ' standalone pages, ' + rewritten + ' link groups rewritten, all cross-links verified');
