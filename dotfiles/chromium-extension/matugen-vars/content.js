const STYLE_ID = '__matugen_vars__';

// Apply latest stored CSS immediately on page load
chrome.storage.local.get('matVarsCss', ({ matVarsCss }) => {
  if (!matVarsCss) return;
  let el = document.getElementById(STYLE_ID);
  if (!el) {
    el = document.createElement('style');
    el.id = STYLE_ID;
    (document.head ?? document.documentElement).appendChild(el);
  }
  el.textContent = matVarsCss;
});
