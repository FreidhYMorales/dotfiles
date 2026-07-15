const STYLE_ID = '__matugen_vars__';

function applyCSS(css) {
  let el = document.getElementById(STYLE_ID);
  if (!el) {
    el = document.createElement('style');
    el.id = STYLE_ID;
    (document.head ?? document.documentElement).appendChild(el);
  }
  el.textContent = css;
}

// Apply stored CSS immediately on page load
chrome.storage.local.get('matVarsCss', ({ matVarsCss }) => {
  if (matVarsCss) applyCSS(matVarsCss);
});

// Apply updates pushed from background
chrome.runtime.onMessage.addListener(({ type, css }) => {
  if (type === 'MAT_VARS_UPDATE' && css) applyCSS(css);
});
