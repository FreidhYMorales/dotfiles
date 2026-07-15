let lastVersion = -1;

async function poll() {
  try {
    const res = await fetch('http://localhost:9119/version?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return;
    const v = parseInt(await res.text(), 10);
    if (lastVersion !== -1 && v !== lastVersion) {
      chrome.runtime.sendMessage({ type: 'VARS_CHANGED' });
    }
    lastVersion = v;
  } catch (_) {}
}

setInterval(poll, 1000);
poll();
