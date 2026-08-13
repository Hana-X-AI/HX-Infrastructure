// Build the governance HTML set from the Markdown sources.
//
// The two log files are the source of truth and their cells run to ~3000 characters, so
// they are parsed rather than transcribed. Cells legitimately contain escaped pipes
// (regex alternations like idle_prompt\|agent_needs_input), so rows are split only on
// unescaped pipes — a naive split corrupts several rows.
//
// One CSS definition is shared by every page so the set cannot drift apart.

const fs = require('fs');
const path = require('path');

const GOV = 'C:/Users/JarvisRichardson/Desktop/HX-Infrastructure/governance';

// Filled in after the pages are published; each artifact gets its own URL.
const LINKS = JSON.parse(fs.readFileSync(path.join(__dirname, 'links.json'), 'utf8'));

/* ---------------------------------------------------------------- shared design system */

const CSS = `
  :root {
    --ground:#fbfbf9; --surface:#f2f3f0; --raised:#ffffff;
    --ink:#1b1f1d; --muted:#6b726e; --faint:#949b96;
    --line:#dde0db; --line-firm:#c3c8c1;
    --accent:#0f6e5c; --accent-wash:#e6f0ec;
    --signal:#b4531a; --signal-wash:#fbeee4;
    --ok:#2f6d4f; --ok-wash:#e4efe8;
    --sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
    --mono:ui-monospace,"SF Mono",SFMono-Regular,"Cascadia Mono",Menlo,Consolas,"Liberation Mono",monospace;
    --step--2:0.6875rem; --step--1:0.8125rem; --step-0:0.9375rem;
    --step-1:1.125rem; --step-2:1.5rem; --step-3:2.125rem;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --ground:#141917; --surface:#1b211e; --raised:#1f2724;
      --ink:#e8ebe8; --muted:#97a09b; --faint:#6f7873;
      --line:#2b342f; --line-firm:#3c4740;
      --accent:#4fbfa3; --accent-wash:#16302a;
      --signal:#e08a4c; --signal-wash:#33251a;
      --ok:#6cc09a; --ok-wash:#162c22;
    }
  }
  :root[data-theme="dark"] {
    --ground:#141917; --surface:#1b211e; --raised:#1f2724;
    --ink:#e8ebe8; --muted:#97a09b; --faint:#6f7873;
    --line:#2b342f; --line-firm:#3c4740;
    --accent:#4fbfa3; --accent-wash:#16302a;
    --signal:#e08a4c; --signal-wash:#33251a;
    --ok:#6cc09a; --ok-wash:#162c22;
  }
  :root[data-theme="light"] {
    --ground:#fbfbf9; --surface:#f2f3f0; --raised:#ffffff;
    --ink:#1b1f1d; --muted:#6b726e; --faint:#949b96;
    --line:#dde0db; --line-firm:#c3c8c1;
    --accent:#0f6e5c; --accent-wash:#e6f0ec;
    --signal:#b4531a; --signal-wash:#fbeee4;
    --ok:#2f6d4f; --ok-wash:#e4efe8;
  }

  :root { color-scheme: light; }
  @media (prefers-color-scheme: dark) { :root { color-scheme: dark; } }
  :root[data-theme="dark"] { color-scheme: dark; }
  :root[data-theme="light"] { color-scheme: light; }

  body {
    margin:0; padding:clamp(1.5rem,4vw,3.5rem) clamp(1rem,4vw,2rem) 5rem;
    background:var(--ground); color:var(--ink);
    font-family:var(--sans); font-size:var(--step-0); line-height:1.55;
    -webkit-text-size-adjust:100%;
  }
  .page { max-width:1100px; margin:0 auto; display:flex; flex-direction:column; gap:2.25rem; }

  .bar { display:flex; align-items:center; justify-content:space-between; gap:1rem; flex-wrap:wrap; }
  .nav { display:flex; gap:1.1rem; flex-wrap:wrap; align-items:center;
         font-family:var(--mono); font-size:var(--step--2);
         text-transform:uppercase; letter-spacing:0.1em; }
  .nav a { color:var(--muted); text-decoration:none; border-bottom:1px solid transparent; padding-bottom:2px; }
  .nav a:hover { color:var(--accent); border-bottom-color:var(--accent); }
  .nav a[aria-current="page"] { color:var(--accent); border-bottom-color:var(--accent); }

  .toggle {
    font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
    letter-spacing:0.09em; color:var(--muted); background:var(--surface);
    border:1px solid var(--line-firm); border-radius:2px; padding:0.4rem 0.75rem; cursor:pointer;
    transition:color 120ms ease, border-color 120ms ease;
  }
  .toggle:hover { color:var(--accent); border-color:var(--accent); }

  .masthead { display:flex; flex-direction:column; gap:0.7rem; }
  .eyebrow { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
             letter-spacing:0.14em; color:var(--accent); margin:0; }
  h1 { font-size:var(--step-3); line-height:1.08; letter-spacing:-0.02em; font-weight:650;
       margin:0; text-wrap:balance; }
  .masthead p { margin:0; max-width:65ch; color:var(--muted); }

  .strip { display:grid; grid-template-columns:repeat(auto-fit,minmax(130px,1fr)); gap:1px;
           background:var(--line); border:1px solid var(--line); border-radius:3px; overflow:hidden; }
  .cell { background:var(--surface); padding:0.8rem 1rem; display:flex; flex-direction:column; gap:0.1rem; }
  .cell dt { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
             letter-spacing:0.1em; color:var(--muted); }
  .cell dd { margin:0; font-size:var(--step-1); font-weight:600; font-variant-numeric:tabular-nums; }

  h2 { font-size:var(--step-2); letter-spacing:-0.015em; font-weight:620; margin:0; text-wrap:balance; }
  section { display:flex; flex-direction:column; gap:0.85rem; }
  .lede { margin:0; color:var(--muted); max-width:70ch; font-size:var(--step--1); }

  .entries { display:flex; flex-direction:column; gap:0.75rem; }
  .entry { border:1px solid var(--line); border-radius:3px; background:var(--raised);
           padding:1rem 1.15rem; display:flex; flex-direction:column; gap:0.6rem;
           border-left:3px solid var(--line-firm); }
  .entry.is-open { border-left-color:var(--signal); }
  .entry.is-done { border-left-color:var(--ok); }
  .entry.is-hold { border-left-color:var(--faint); }

  .entry-head { display:flex; align-items:center; gap:0.55rem; flex-wrap:wrap; }
  .eid { font-family:var(--mono); font-weight:650; font-size:var(--step-0); }
  .chip { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
          letter-spacing:0.08em; padding:0.15rem 0.45rem; border-radius:2px;
          border:1px solid var(--line-firm); color:var(--muted); }
  .pill { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
          letter-spacing:0.08em; padding:0.15rem 0.5rem; border-radius:10px; font-weight:600; }
  .pill.is-open { background:var(--signal-wash); color:var(--signal); }
  .pill.is-done { background:var(--ok-wash); color:var(--ok); }
  .pill.is-hold { background:var(--surface); color:var(--muted); }
  .rel { margin-left:auto; font-family:var(--mono); font-size:var(--step--2); color:var(--faint); }

  .field { display:flex; flex-direction:column; gap:0.2rem; }
  .field-label { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
                 letter-spacing:0.09em; color:var(--faint); }
  .field p { margin:0; max-width:78ch; }
  .field.body p { color:var(--ink); }
  .field.sub p { color:var(--muted); font-size:var(--step--1); }

  .cards { display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:1rem; }
  .card { border:1px solid var(--line); border-radius:3px; background:var(--raised);
          padding:1.15rem 1.25rem; display:flex; flex-direction:column; gap:0.5rem;
          text-decoration:none; color:inherit;
          transition:border-color 120ms ease, transform 120ms ease; }
  .card:hover { border-color:var(--accent); transform:translateY(-2px); }
  .card h3 { margin:0; font-size:var(--step-1); font-weight:620; letter-spacing:-0.01em; }
  .card p { margin:0; font-size:var(--step--1); color:var(--muted); }
  .card .meta { font-family:var(--mono); font-size:var(--step--2); text-transform:uppercase;
                letter-spacing:0.09em; color:var(--accent); margin-top:auto; padding-top:0.3rem; }

  .scroll { overflow-x:auto; border:1px solid var(--line); border-radius:3px; background:var(--raised); }
  table { border-collapse:collapse; width:100%; font-size:var(--step--1); }
  thead th { background:var(--surface); border-bottom:1px solid var(--line-firm);
             font-family:var(--mono); font-size:var(--step--2); font-weight:600;
             text-transform:uppercase; letter-spacing:0.09em; color:var(--muted);
             text-align:left; padding:0.65rem 0.85rem; white-space:nowrap; }
  tbody td { padding:0.6rem 0.85rem; border-bottom:1px solid var(--line); vertical-align:top; }
  tbody tr:last-child td { border-bottom:none; }

  ul.notes { padding-left:1.15rem; margin:0; font-size:var(--step--1); color:var(--muted);
             display:flex; flex-direction:column; gap:0.4rem; }
  ul.notes b, ul.notes code { color:var(--ink); }

  code { font-family:var(--mono); font-size:0.92em; background:var(--surface);
         padding:0.05em 0.32em; border-radius:2px; }
  pre { margin:0; overflow-x:auto; background:var(--surface); border:1px solid var(--line);
        border-radius:3px; padding:0.85rem 1rem; }
  pre code { background:none; padding:0; font-size:var(--step--1); }

  footer { border-top:1px solid var(--line); padding-top:1rem; font-size:var(--step--2); color:var(--faint); }
  a { color:var(--accent); }
  :focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
  @media (prefers-reduced-motion: reduce) { * { animation:none !important; transition:none !important; } }
`;

const SCRIPT = `
(function () {
  var root = document.documentElement;
  var btn = document.getElementById('theme-toggle');
  if (!btn) { return; }
  var media = window.matchMedia('(prefers-color-scheme: dark)');
  function stored(v) {
    try { if (v === undefined) { return localStorage.getItem('hx-theme'); } localStorage.setItem('hx-theme', v); }
    catch (e) { /* sandboxed: the toggle still works for this view */ }
    return null;
  }
  function active() {
    var e = root.getAttribute('data-theme');
    return (e === 'dark' || e === 'light') ? e : (media.matches ? 'dark' : 'light');
  }
  function relabel() {
    var next = active() === 'dark' ? 'light' : 'dark';
    btn.textContent = next === 'dark' ? 'Dark mode' : 'Light mode';
    btn.setAttribute('aria-label', 'Switch to ' + next + ' mode');
  }
  var saved = stored();
  if (saved === 'dark' || saved === 'light') { root.setAttribute('data-theme', saved); }
  relabel();
  btn.addEventListener('click', function () {
    var next = active() === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next); stored(next); relabel();
  });
  if (typeof media.addEventListener === 'function') { media.addEventListener('change', relabel); }
  if (typeof MutationObserver === 'function') {
    new MutationObserver(relabel).observe(root, { attributes: true, attributeFilter: ['data-theme'] });
  }
})();
`;

/* ------------------------------------------------------------------------ helpers */

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Markdown inline subset, applied after escaping.
function inline(s) {
  return esc(s)
    .replace(/\\\|/g, '|')
    .replace(/`([^`]+)`/g, (_, c) => '<code>' + c + '</code>')
    .replace(/\*\*([^*]+)\*\*/g, (_, c) => '<strong>' + c + '</strong>');
}

// Split a Markdown table row on unescaped pipes only.
function cells(line) {
  return line.replace(/^\||\|$/g, '').split(/(?<!\\)\|/).map((c) => c.trim());
}

function readRows(file, idPattern) {
  return fs
    .readFileSync(path.join(GOV, file), 'utf8')
    .split(/\r?\n/)
    .filter((l) => idPattern.test(l))
    .map(cells);
}

function navHtml(current) {
  const items = [
    ['index', 'Governance'],
    ['actions', 'Actions &amp; issues'],
    ['lessons', 'Lessons learned'],
    ['standards', 'Standards'],
    ['inventory', 'Fleet inventory'],
    ['architecture', 'Architecture v0.3'],
    ['frozen', 'v0.1 frozen'],
    ['validation', 'Validation'],
    ['recommendations', 'Recommendations'],
  ];
  return items
    .map(([k, label]) => {
      const href = LINKS[k] || '#';
      const cur = k === current ? ' aria-current="page"' : '';
      return `<a href="${href}"${cur}>${label}</a>`;
    })
    .join('\n        ');
}

function shell({ title, current, favicon, body }) {
  return `<title>${title}</title>
<style>${CSS}</style>

<div class="page">

  <div class="bar">
    <nav class="nav">
        ${navHtml(current)}
    </nav>
    <button type="button" class="toggle" id="theme-toggle">Dark mode</button>
  </div>

${body}

  <footer>
    HX-Infrastructure governance &middot; generated from the Markdown sources in <code>governance/</code> on 2026-08-13.
    The Markdown files remain the source of truth.
  </footer>

</div>

<script>${SCRIPT}</script>
`;
}

/* --------------------------------------------------------------- actions and issues */

const A = readRows('actions-and-issues.md', /^\| (act|iss)-/);

function statusClass(s) {
  const v = s.toLowerCase();
  if (v === 'open' || v === 'in progress' || v === 'investigating' || v === 'blocked') return 'is-open';
  if (v === 'backlog') return 'is-hold';
  return 'is-done';
}

const aCount = (pred) => A.filter(pred).length;

const actionsBody = `
  <header class="masthead">
    <p class="eyebrow">HX-Infrastructure &middot; project log</p>
    <h1>Actions &amp; Issues</h1>
    <p>The single tracking log for the project. <code>action</code> is work that must be
    completed; <code>issue</code> is a known problem, defect or unresolved behaviour. Each
    entry carries its own resolution, so the record of what happened stays with the item.</p>
  </header>

  <dl class="strip">
    <div class="cell"><dt>Entries</dt><dd>${A.length}</dd></div>
    <div class="cell"><dt>Actions</dt><dd>${aCount((r) => r[1] === 'action')}</dd></div>
    <div class="cell"><dt>Issues</dt><dd>${aCount((r) => r[1] === 'issue')}</dd></div>
    <div class="cell"><dt>Open</dt><dd>${aCount((r) => statusClass(r[5]) === 'is-open')}</dd></div>
    <div class="cell"><dt>Backlog</dt><dd>${aCount((r) => statusClass(r[5]) === 'is-hold')}</dd></div>
    <div class="cell"><dt>Closed</dt><dd>${aCount((r) => statusClass(r[5]) === 'is-done')}</dd></div>
  </dl>

  <section>
    <h2>Log</h2>
    <p class="lede">Open items first, then deferred, then closed. Within each group the most
    recent entry leads.</p>
    <div class="entries">
${[...A]
  .sort((x, y) => {
    const rank = { 'is-open': 0, 'is-hold': 1, 'is-done': 2 };
    const d = rank[statusClass(x[5])] - rank[statusClass(y[5])];
    return d !== 0 ? d : y[0].localeCompare(x[0], undefined, { numeric: true });
  })
  .map((r) => {
    const [id, type, item, impact, , status, related, resolution] = r;
    const cls = statusClass(status);
    return `      <article class="entry ${cls}">
        <div class="entry-head">
          <span class="eid">${esc(id)}</span>
          <span class="chip">${esc(type)}</span>
          <span class="pill ${cls}">${esc(status)}</span>
          ${related ? `<span class="rel">related: ${esc(related)}</span>` : ''}
        </div>
        <div class="field body"><span class="field-label">Item</span><p>${inline(item)}</p></div>
        <div class="field sub"><span class="field-label">Impact / outcome</span><p>${inline(impact)}</p></div>
        ${resolution ? `<div class="field sub"><span class="field-label">Resolution / closeout</span><p>${inline(resolution)}</p></div>` : ''}
      </article>`;
  })
  .join('\n')}
    </div>
  </section>
`;

/* ------------------------------------------------------------------ lessons learned */

const L = readRows('lessons-learned.md', /^\| ll-/);

const lessonsBody = `
  <header class="masthead">
    <p class="eyebrow">HX-Infrastructure &middot; running log</p>
    <h1>Lessons Learned</h1>
    <p>Things this project learned the hard way. A lesson belongs here when it changes how
    work should be done next time; the defect itself lives in the actions and issues log.
    Each entry names the evidence that produced it and what was changed in response.</p>
  </header>

  <dl class="strip">
    <div class="cell"><dt>Lessons</dt><dd>${L.length}</dd></div>
    <div class="cell"><dt>First</dt><dd>${L.map((r) => r[1]).sort()[0]}</dd></div>
    <div class="cell"><dt>Latest</dt><dd>${L.map((r) => r[1]).sort().slice(-1)[0]}</dd></div>
  </dl>

  <section>
    <h2>Log</h2>
    <p class="lede">Most recent first.</p>
    <div class="entries">
${[...L]
  .sort((x, y) => y[0].localeCompare(x[0], undefined, { numeric: true }))
  .map((r) => {
    const [id, date, lesson, evidence, applied] = r;
    return `      <article class="entry">
        <div class="entry-head">
          <span class="eid">${esc(id)}</span>
          <span class="chip">${esc(date)}</span>
        </div>
        <div class="field body"><span class="field-label">Lesson</span><p>${inline(lesson)}</p></div>
        <div class="field sub"><span class="field-label">Evidence</span><p>${inline(evidence)}</p></div>
        <div class="field sub"><span class="field-label">Applied</span><p>${inline(applied)}</p></div>
      </article>`;
  })
  .join('\n')}
    </div>
  </section>
`;

/* ----------------------------------------------------------------------- write out */

fs.writeFileSync(
  path.join(GOV, 'actions-and-issues.html'),
  shell({ title: 'Actions & Issues — HX Governance', current: 'actions', body: actionsBody })
);
fs.writeFileSync(
  path.join(GOV, 'lessons-learned.html'),
  shell({ title: 'Lessons Learned — HX Governance', current: 'lessons', body: lessonsBody })
);

// The home page and the standards page are authored, not derived; both reuse the shell.
// The home page's link targets and counts are substituted so they cannot fall out of step
// with the logs they describe.
const indexBody = fs
  .readFileSync(path.join(__dirname, 'page-bodies', 'index-body.html'), 'utf8')
  .replace(/__LINK_INVENTORY__/g, LINKS.inventory || '#')
  .replace(/__LINK_ACTIONS__/g, LINKS.actions || '#')
  .replace(/__LINK_LESSONS__/g, LINKS.lessons || '#')
  .replace(/__LINK_STANDARDS__/g, LINKS.standards || '#')
  .replace(/__LINK_ARCHITECTURE__/g, LINKS.architecture || '#')
  .replace(/__LINK_FROZEN__/g, LINKS.frozen || '#')
  .replace(/__LINK_VALIDATION__/g, LINKS.validation || '#')
  .replace(/__LINK_RECOMMENDATIONS__/g, LINKS.recommendations || '#')
  .replace(/__COUNT_ACTIONS__/g, String(A.length))
  .replace(/__COUNT_OPEN__/g, String(aCount((r) => statusClass(r[5]) === 'is-open')))
  .replace(/__COUNT_LESSONS__/g, String(L.length));

const leftover = indexBody.match(/__[A-Z_]+__/g);
if (leftover) { throw new Error('unsubstituted placeholders: ' + leftover.join(', ')); }

fs.writeFileSync(
  path.join(GOV, 'index.html'),
  shell({ title: 'Governance — HX-Infrastructure', current: 'index', body: indexBody })
);
fs.writeFileSync(
  path.join(GOV, 'documentation-standards.html'),
  shell({
    title: 'Documentation Standards — HX Governance',
    current: 'standards',
    body: fs.readFileSync(path.join(__dirname, 'page-bodies', 'standards-body.html'), 'utf8'),
  })
);

console.log('actions/issues entries : ' + A.length);
console.log('lessons entries        : ' + L.length);
console.log('wrote index.html, actions-and-issues.html, lessons-learned.html, documentation-standards.html');
