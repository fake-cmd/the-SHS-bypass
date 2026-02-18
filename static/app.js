const links = {
  games: [
    ['Poki', 'https://poki.com'],
    ['CrazyGames', 'https://www.crazygames.com'],
    ['Krunker', 'https://krunker.io']
  ],
  movies: [
    ['lookmovie', 'https://www.lookmovie2.to/'],
    ['seris2watch', 'https://series2watch.net/home']
  ]
};

function fillGrid(id, entries) {
  const root = document.getElementById(id);
  root.innerHTML = '';
  for (const [name, href] of entries) {
    const a = document.createElement('a');
    a.href = href;
    a.target = '_blank';
    a.rel = 'noopener';
    a.textContent = name;
    root.appendChild(a);
  }
}

function safeApplyAds(enabled) {
  // Intentionally no DOM assumptions; no breakage when toggling/removing ads.
  localStorage.setItem('adsEnabled', String(Boolean(enabled)));
  document.getElementById('ads-note').textContent = enabled
    ? 'Ads preference saved. UI remains stable.'
    : 'Ads disabled. App continues normally.';
}

function exportData() {
  const data = {
    localStorage: Object.fromEntries(Object.entries(localStorage)),
    cookies: document.cookie || ''
  };
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'vortex-data.json';
  a.click();
  URL.revokeObjectURL(url);
}

async function importData(file) {
  const text = await file.text();
  const data = JSON.parse(text);
  if (data.localStorage && typeof data.localStorage === 'object') {
    for (const [k, v] of Object.entries(data.localStorage)) {
      localStorage.setItem(k, String(v));
    }
  }
  if (typeof data.cookies === 'string' && data.cookies.trim()) {
    data.cookies.split(';').forEach((cookie) => {
      const chunk = cookie.trim();
      if (chunk) document.cookie = `${chunk}; path=/`;
    });
  }
}

function initTabs() {
  const buttons = document.querySelectorAll('nav button');
  const tabs = document.querySelectorAll('.tab');
  buttons.forEach((btn) => {
    btn.addEventListener('click', () => {
      buttons.forEach((b) => b.classList.remove('active'));
      tabs.forEach((t) => t.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById(btn.dataset.tab).classList.add('active');
    });
  });
}

function initSearch() {
  const form = document.getElementById('search-form');
  const q = document.getElementById('q');
  const engine = document.getElementById('engine');
  engine.value = localStorage.getItem('searchEngine') || 'duckduckgo';

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const query = encodeURIComponent(q.value.trim());
    const selected = engine.value;
    localStorage.setItem('searchEngine', selected);
    if (!query) return;

    const map = {
      duckduckgo: `https://duckduckgo.com/?q=${query}`,
      google: `https://www.google.com/search?q=${query}`,
      bing: `https://www.bing.com/search?q=${query}`
    };

    window.open(map[selected] || map.duckduckgo, '_blank', 'noopener');
  });
}

function initSettings() {
  const adsToggle = document.getElementById('ads-toggle');
  adsToggle.checked = localStorage.getItem('adsEnabled') === 'true';
  safeApplyAds(adsToggle.checked);
  adsToggle.addEventListener('change', () => safeApplyAds(adsToggle.checked));

  const status = document.getElementById('status');
  document.getElementById('export-data').addEventListener('click', () => {
    exportData();
    status.textContent = 'Export complete.';
  });

  document.getElementById('import-data').addEventListener('click', async () => {
    const file = document.getElementById('import-file').files?.[0];
    if (!file) {
      status.textContent = 'Choose a JSON export file first.';
      return;
    }
    try {
      await importData(file);
      status.textContent = 'Import complete. Refresh to apply all data.';
    } catch (err) {
      status.textContent = `Import failed: ${err.message}`;
    }
  });
}

fillGrid('games-list', links.games);
fillGrid('movies-list', links.movies);
initTabs();
initSearch();
initSettings();
