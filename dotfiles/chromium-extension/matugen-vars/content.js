const STYLE_ID = '__matugen_vars__';

function updateStyle(css) {
  if (!css) return;
  let el = document.getElementById(STYLE_ID);
  if (!el) {
    el = document.createElement('style');
    el.id = STYLE_ID;
    (document.head ?? document.documentElement).appendChild(el);
  }
  el.textContent = css;
}

chrome.storage.local.get('matVarsCss', ({ matVarsCss }) => updateStyle(matVarsCss));

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'local' && changes.matVarsCss?.newValue) {
    updateStyle(changes.matVarsCss.newValue);
  }
});
