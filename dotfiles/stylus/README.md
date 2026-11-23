# Stylus Userstyles — matugen

Userstyles for the [Stylus](https://github.com/openstyles/stylus) browser extension that theme 23+ sites using the active [matugen](https://github.com/InioX/matugen) Material Design 3 color palette.

These styles follow your wallpaper in real time — every time matugen regenerates colors from a new wallpaper, all themed sites update automatically on next page load.

---

## How it works

```
wallpaper → matugen → --mat-* CSS vars → Stylus site styles
                         ├─ Zen: userContent.css in active profile
                         └─ Chromium: matugen-vars extension
```

1. **matugen** generates a Material 3 palette from the current wallpaper.
2. Zen gets the variables through `userContent.css` in its active profile;
   Chromium web apps get them from the `matugen-vars` extension.
3. The Stylus styles here map each site's colors to `var(--mat-*)`.

Bootstrap enables and starts `matugen-server.service` for Chromium's live
palette updates. Browser extensions and per-site Stylus styles are still
one-time manual installs.

---

## Available `--mat-*` variables

| Variable | Role |
|----------|------|
| `--mat-background` | Darkest background (crust equivalent) |
| `--mat-surface-container-lowest` | Very dark surface (mantle) |
| `--mat-surface-container-low` | Dark surface (base) |
| `--mat-surface-container` | Elevated surface (surface0) |
| `--mat-surface-container-high` | More elevated (surface1) |
| `--mat-surface-container-highest` | Highest elevation (surface2) |
| `--mat-on-surface` | Primary text on surfaces |
| `--mat-on-surface-variant` | Secondary / dimmed text |
| `--mat-outline` | Border / divider |
| `--mat-outline-variant` | Subtle border |
| `--mat-primary` | Accent color (links, buttons, brand) |
| `--mat-on-primary` | Text/icons on primary-colored backgrounds |
| `--mat-secondary` | Warm accent (yellow, peach tones) |
| `--mat-on-secondary` | Text on secondary |
| `--mat-tertiary` | Cool accent (teal, green tones) |
| `--mat-on-tertiary` | Text on tertiary |
| `--mat-error` | Error / destructive |
| `--mat-on-error` | Text on error |

---

## Catppuccin → matugen mapping

| Catppuccin | matugen |
|-----------|---------|
| `@crust` | `--mat-background` |
| `@mantle` | `--mat-surface-container-lowest` |
| `@base` | `--mat-surface-container-low` |
| `@surface0` | `--mat-surface-container` |
| `@surface1` | `--mat-surface-container-high` |
| `@surface2` | `--mat-surface-container-highest` |
| `@overlay0` / `@overlay1` | `--mat-outline-variant` / `--mat-outline` |
| `@overlay2` | `--mat-on-surface-variant` |
| `@subtext0`, `@subtext1` | `--mat-on-surface-variant` |
| `@text` | `--mat-on-surface` |
| `@accent`, `@blue`, `@sapphire`, `@lavender`, `@mauve` | `--mat-primary` |
| `@red`, `@maroon` | `--mat-error` |
| `@green`, `@teal` | `--mat-tertiary` |
| `@yellow`, `@peach`, `@pink`, `@flamingo`, `@rosewater` | `--mat-secondary` |

### LESS function conversions

| LESS | Plain CSS |
|------|-----------|
| `fade(@color, 50%)` | `color-mix(in srgb, var(--mat-X), transparent 50%)` |
| `mix(@a, @b, 20%)` | `color-mix(in srgb, var(--mat-A) 20%, var(--mat-B))` |
| `darken(@color, 5%)` | `var(--mat-X)` (approximated — no plain CSS equivalent) |
| `lighten(@color, 5%)` | `var(--mat-X)` (approximated) |
| `#lib.rgbify(@color)[]` | **skipped** — triplet format incompatible with `var()` inside `rgb()` |

---

## Available userstyles

| File | Site | Dark mode selector |
|------|------|-------------------|
| `arch-wiki-matugen.user.css` | Arch Wiki (MediaWiki) | `:root.skin-theme-clientpref-night` |
| `chatgpt-matugen.user.css` | ChatGPT / OpenAI | `.dark *` |
| `claude-matugen.user.css` | Claude.ai | `[data-mode="dark"]` |
| `deepseek-matugen.user.css` | DeepSeek Chat | `body[data-ds-dark-theme]` |
| `duckduckgo-matugen.user.css` | DuckDuckGo + duck.ai | `:root.dark-bg` |
| `github-matugen.user.css` | GitHub | `[data-color-mode="dark"]` |
| `gmail-matugen.user.css` | Gmail | `@media (prefers-color-scheme: dark)` |
| `google-drive-matugen.user.css` | Google Drive | `.vhoiae.LgGVmb` |
| `google-matugen.user.css` | Google Search / Images | `@media (prefers-color-scheme: dark)` |
| `google-photos-matugen.user.css` | Google Photos | `.dm7YTc` |
| `hacker-news-matugen.user.css` | Hacker News | `@media (prefers-color-scheme: dark)` |
| `instagram-matugen.user.css` | Instagram | `._aa4d` |
| `linkedin-matugen.user.css` | LinkedIn | `:root.theme--dark` |
| `notion-matugen.user.css` | Notion | `.dark` (body class) |
| `ollama-matugen.user.css` | Ollama.com | `@media (prefers-color-scheme: dark)` |
| `pinterest-matugen.user.css` | Pinterest | `@media (prefers-color-scheme: dark)` |
| `proton-matugen.user.css` | Proton Mail/Drive/Cal | `@media (prefers-color-scheme: dark)` |
| `reddit-matugen.user.css` | Reddit | `.theme-dark` |
| `spotify-web-matugen.user.css` | Spotify Web Player | `.encore-dark-theme` |
| `stack-overflow-matugen.user.css` | Stack Overflow network | `.unified-theme.theme-dark` |
| `twitch-matugen.user.css` | Twitch + Dashboard | `.tw-root--theme-dark` |
| `twitter-matugen.user.css` | Twitter / X | `body.LightsOut` + `@media` |
| `whatsapp-matugen.user.css` | WhatsApp Web | `:root:has(> .dark)` |
| `wikipedia-matugen.user.css` | Wikipedia (MediaWiki) | `:root.skin-theme-clientpref-night` |
| `youtube-matugen.user.css` | YouTube | `:root[dark]` |

---

## Known limitations

**Instagram** — most color vars use the `#lib.rgbify()` pattern (stored as bare `R G B` triplets for use in `rgb(var(--ig-X))`). Setting those to `var(--mat-*)` breaks the `rgb()` call. Only plain-value vars and direct element overrides are themed.

**Google Photos** — same rgbify limitation. Only the hex `-` (non `-rgb`) token variants are overridden. Alpha-composited surfaces that rely on `rgb(var(--gm3-sys-color-X-rgb))` will not be themed.

**Gmail** — no CSS design token system. Uses element-level class selectors (`.bkL`, `.T-I-atl`, etc.). Icon colorization via SVG `filter:` (requires compiled hex from LESS) is not applied.

**Google** — highly obfuscated class names that rotate with deployments. Only the stable `--gm3-sys-color-*` and `--uv-styles-*` token layers are targeted.

**Twitter/X** — uses atomic `.r-*` CSS utility classes. The covered selectors are best-effort; they may break after deployments.

---

## Installation

The bootstrap deploys the matugen templates and automatically enables
`matugen-server.service`. It does not install browser extensions or import
userstyles; do those once in each browser that needs them.

### Zen Browser

1. Install [Stylus](https://github.com/openstyles/stylus) from Firefox Add-ons.
2. In `about:config`, verify
   `toolkit.legacyUserProfileCustomizations.stylesheets` is `true` (the
   matugen post-hook sets this on first run).
3. Install the site styles you use: open each `*-matugen.user.css` from this
   directory in Zen and choose **Install** on Stylus's page.
4. Regenerate the palette with `~/.config/matugen/post-hook.sh` or change the
   wallpaper in the Quickshell launcher, then restart Zen once so it loads the
   generated `userContent.css` in its active profile.

### Chromium web apps (WhatsApp, YouTube, etc.)

1. Install Stylus from the Chrome Web Store in Chromium.
2. Open `chrome://extensions` → Stylus → **Details** and enable **Allow access
   to file URLs**.
3. Open `chrome://extensions`, turn on **Developer mode**, choose **Load
   unpacked**, and select
   `dotfiles/chromium-extension/matugen-vars/`.
4. Install the needed site styles: open each `*-matugen.user.css` here as a
   `file://` URL and press **Install** in Stylus. Use **Reinstall** after
   manually editing a style.
5. If you installed or started the extension while the matugen server was
   stopped, reload **matugen vars** once in `chrome://extensions` after starting
   the server so it fetches the initial palette.

The extension gets variables from `http://localhost:9119/matugen-vars.css`.
Check the service with `systemctl --user status matugen-server.service` or
`curl http://localhost:9119/version`.

For both browsers, enable dark mode in each site so the dark-theme selectors
match. For YouTube, also turn off **Ambient mode** under Settings → Playback
and performance to avoid an untinted cinematic gradient.

---

## Adding new styles

Template:

```css
/* ==UserStyle==
@name         Site — matugen
@namespace    github.com/FreidhYMorales/dotfiles
@version      2.0.0
@description  Themes Site with the active matugen Material 3 palette.
              Requires matugen --mat-* variables (Zen userContent.css or Chromium extension).
@author       deadlock
@match        https://example.com/*
@preprocessor default
==/UserStyle== */

@-moz-document domain("example.com") {
  .dark-mode-class {
    --site-bg:    var(--mat-surface-container-low) !important;
    --site-text:  var(--mat-on-surface) !important;
    --site-accent: var(--mat-primary) !important;
  }
}
```
