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

async function fetchAndApply() {
  try {
    const res = await fetch(VARS_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return;
    const css = await res.text();

    const { lastCss } = await chrome.storage.local.get('lastCss');
    if (css === lastCss) return;
    await chrome.storage.local.set({ matVarsCss: css, lastCss: css });

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

chrome.alarms.create('poll', { periodInMinutes: 1 });
chrome.alarms.onAlarm.addListener(({ name }) => {
  if (name === 'poll') fetchAndApply();
});
chrome.runtime.onInstalled.addListener(fetchAndApply);
chrome.runtime.onStartup.addListener(fetchAndApply);
fetchAndApply();
