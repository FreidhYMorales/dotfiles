const VARS_URL = 'http://localhost:9119/matugen-vars.css';
const POLL_MS = 30_000;

async function fetchAndBroadcast() {
  try {
    const res = await fetch(VARS_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return;
    const css = await res.text();

    const { lastCss } = await chrome.storage.local.get('lastCss');
    if (css === lastCss) return;

    await chrome.storage.local.set({ matVarsCss: css, lastCss: css });

    const tabs = await chrome.tabs.query({});
    for (const tab of tabs) {
      chrome.tabs.sendMessage(tab.id, { type: 'MAT_VARS_UPDATE', css }).catch(() => {});
    }
  } catch (_) {}
}

chrome.alarms.create('poll', { periodInMinutes: POLL_MS / 60_000 });
chrome.alarms.onAlarm.addListener(({ name }) => {
  if (name === 'poll') fetchAndBroadcast();
});

chrome.runtime.onInstalled.addListener(fetchAndBroadcast);
fetchAndBroadcast();
