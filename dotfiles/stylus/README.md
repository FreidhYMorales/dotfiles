# Stylus Userstyles — matugen

Userstyles for the [Stylus](https://github.com/openstyles/stylus) browser extension that theme 23+ sites using the active [matugen](https://github.com/InioX/matugen) Material Design 3 color palette.

These styles follow your wallpaper in real time — every time matugen regenerates colors from a new wallpaper, all themed sites update automatically on next page load.

---

## How it works

```
wallpaper → matugen → colors.json → userContent.css → --mat-* CSS vars
                                                           ↓
                                        Stylus userstyles use var(--mat-*)
```

1. **matugen** generates a Material 3 palette from the current wallpaper.
2. A template outputs `~/.config/matugen/output/zen-matugen.css` with `--mat-*` custom properties.
3. Zen Browser loads this file via `chrome/userContent.css`, injecting `--mat-*` into every page's `:root`.
4. Each userstyle here overrides site-specific design tokens with `var(--mat-*)`.

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

## Stylus import flow

1. Install [Stylus](https://github.com/openstyles/stylus) in Zen Browser.
2. In Stylus settings, ensure **"Specify regexp separately"** is enabled if using `regexp()` matchers.
3. For each file: open Stylus → **Write new style** → paste the file content → save.
   Or use Stylus's **Import** feature to bulk-import all files.
4. Ensure your Zen Browser has `chrome/userContent.css` configured to load the matugen output file:
   ```css
   @import url("file:///home/youruser/.config/matugen/output/zen-matugen.css");
   ```
5. Regenerate the palette: pick a new wallpaper in the Quickshell launcher (`>wallpaper`). Sites theme automatically on next load.

---

## Adding new styles

Template:

```css
/* ==UserStyle==
@name         Site — matugen
@namespace    github.com/FreidhYMorales/dotfiles
@version      2.0.0
@description  Themes Site with the active matugen Material 3 palette.
              Requires userContent.css in Zen's chrome/ to inject --mat-* vars.
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
