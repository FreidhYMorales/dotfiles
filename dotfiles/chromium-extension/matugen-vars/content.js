const VARS_URL = 'http://localhost:9119/matugen-vars.css';
const POLL_MS = 30_000;
const STYLE_ID = '__matugen_vars__';

async function apply() {
  try {
    const res = await fetch(VARS_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!res.ok) return;
    const css = await res.text();
    let el = document.getElementById(STYLE_ID);
    if (!el) {
      el = document.createElement('style');
      el.id = STYLE_ID;
      (document.head ?? document.documentElement).appendChild(el);
    }
    el.textContent = css;
  } catch (_) {}
}

apply();
setInterval(apply, POLL_MS);
