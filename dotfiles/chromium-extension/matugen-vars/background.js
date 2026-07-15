const VARS_URL = 'http://localhost:9119/matugen-vars.css';

function injectCSS(css) {
  const ID = '__matugen_vars__';
  let el = document.getElementById(ID);
  if (!el) {
    el = document.createElement('style');
    el.id = ID;
    (document.head ?? document.documentElement).appendChild(el);
  }
  el.textContent = css;
}

async function applyUpdate() {
  try {
    const res = await fetch(VARS_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return;
    const css = await res.text();
    await chrome.storage.local.set({ matVarsCss: css });

    const tabs = await chrome.tabs.query({});
    for (const tab of tabs) {
      if (!tab.id || !tab.url || tab.url.startsWith('chrome')) continue;
      chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: injectCSS,
        args: [css],
      }).catch(() => {});
    }
  } catch (_) {}
}

async function ensureOffscreen() {
  const contexts = await chrome.runtime.getContexts({
    contextTypes: ['OFFSCREEN_DOCUMENT'],
  });
  if (contexts.length > 0) return;
  await chrome.offscreen.createDocument({
    url: 'offscreen.html',
    reasons: ['DOM_SCRAPING'],
    justification: 'Poll local matugen server for CSS var updates',
  });
}

chrome.runtime.onMessage.addListener(({ type }) => {
  if (type === 'VARS_CHANGED') applyUpdate();
});

chrome.runtime.onInstalled.addListener(async () => {
  await applyUpdate();
  await ensureOffscreen();
});

chrome.runtime.onStartup.addListener(async () => {
  await applyUpdate();
  await ensureOffscreen();
});
