# Story 15: Stylus coverage for the webapps

## Story

15. As the owner, I want the Stylus userstyles to cover every surface of the sites I use so that no page keeps stock colors after a wallpaper change. Requires: #05

## Acceptance criteria

- [x] Given GitHub, WhatsApp, Notion or YouTube open as a Chromium webapp, when I go through the screens I use on each (the list we write down at the start), then none of them keeps stock colors: backgrounds, text, borders, menus, dialogs and inputs all use the palette.
- [x] Given those four webapps, when I pick a new wallpaper and reload them, then every screen from that list switches to the new palette.
- [x] Given a fresh install, when I import the four userstyles the way the post-install doc says, then they work in the Chromium webapps on the first try, and their own instructions talk about Chromium, not Zen.

## Plan

- Start with the owner: open each of the four webapps and list, per site, the screens and elements that still show stock colors (screenshots help); that list is the spec.
- Map each one to the site's own color tokens (or a selector when the site has no token), using only the existing palette variables.
- Fix the stale headers and how-to text in those four styles (they still describe Zen), in line with post-install.
- Pin with tests: the four styles use only palette variables for colors (no hard-coded colors) and their instructions name Chromium; the rest is checked by eye.
- Verify: re-import, walk the list per site, change wallpaper, reload, walk it again; test command plus suites green.

## Out of scope

- X (owner: stays as it is) and the other 21 userstyles; Discord (Vesktop covers it, story 05).
- Zen Browser theming (userContent.css) and the matugen-vars extension or matugen-server, unless one of them is broken.
- Automating the Stylus import; palette variables beyond the RGB triplets this story needs.
- Light mode: the styles target the sites' dark modes.

## Assumptions

- The webapps in use, seen live: X, GitHub, WhatsApp, Notion, YouTube and Discord; the owner picked GitHub, WhatsApp, Notion and YouTube for this story.
- Today the four styles have no hard-coded colors (all `var(--mat-*)`); the gaps are surfaces they do not target yet.
- Notion's style only applies in Notion's dark mode; that stays.
- Edited styles reach Chromium by re-importing them in Stylus (import stays manual).

## Suggestions (your call)

- If the screen list for one site is long, split that site into its own story rather than growing this one.

## Size

normal
Risk: item 3, 6 (the --mat-* vars file the Chromium extension and styles consume gains -rgb vars; colors on live third-party pages are checked by eye)

## Log

- L1 request: /flow:story 15
- L2 owner scope: "si, menos x, esa se puede quedar como esta" → the four webapps GitHub, WhatsApp, Notion, YouTube.
- L3 pair, owner's list: WhatsApp only (message chevron keeps a stock green gradient on hover; outgoing bubble text unreadable on the mono theme); GitHub, Notion, YouTube need only the readability check ("para esos tres alcanza con eso").
- L4 findings: outgoing bubble = --mat-primary-container under --mat-on-surface text (#d4d4d4 vs #e2e2e2 on mono). Measured with matugen 4.2.0 --dry-run, dark, all 9 schemes: on-surface over primary-container is 2.46 (content, fidelity), 1.14 (monochrome); over secondary-container >= 6.95 in every scheme. Notion --bg-selected has the same pairing. WhatsApp defines -RGB twins of each --WDS color (stock outgoing 20, 77, 55 = the green on the chevron); the style overrides only the hex.
- L5 decision (owner: "si, agrega las variables -rgb"): the userContent template (source of userContent.css, chromium-vars.user.css and matugen-vars.css) gains -rgb triplets for the roles the bubbles use; matugen 4.2.0 renders .red/.green/.blue (checked with a scratch config).
- L6 red/green: b64cf8e -> 6d97388 (WhatsApp outgoing bubble to secondary-container; red: content 2.46, fidelity 2.46, monochrome 1.14), 7f350ef -> c82cf35 (Notion --bg-selected, same numbers), 4a75ea5 pin for GitHub/YouTube (passed at once, red against on-surface mutants), f16e3e0 -> 37ed86c (template -rgb triplets for secondary-container and surface-container), 8adc89e -> f9f3867 (WhatsApp bubble -RGB twins), a426dac -> f21718e (headers name Chromium and the matugen-vars extension; no-hard-coded-color case red against a #21C063 mutant).
- L7 manual, first pass: no change seen; the page still had the old style. Stylus Manage -> Import does not update an installed style; opening the file:// URL and pressing Reinstall did. Owner: "si, todo se ve bien" (WhatsApp bubbles readable, chevron no longer green, Notion selection readable, GitHub/YouTube fine).
- L8 verifier: NEEDS DECISION (refs unchanged, HEAD f21718e). All automated evidence PASS (each fix reverted in a scratch clone turns its test red; tamper check clean). Open: Risk line should be item 3, 6; C3 import method in post-install unproven; C2 live wallpaper change not reported. Optional: the hard-coded-color regex misses named colors and hsl().
- L9 decisions (owner "si"): post-install and the styles' how-to switch to the file:// install page; test 'install steps use file://' red (5 FAIL) -> d767bb7 green. Risk line updated to item 3, 6. Owner, live after a wallpaper change and reload: "si, se ve bien". No verifier recheck: the only change after it is docs text pinned by its own red->green step.
- Check: Test command passes ("Dry run complete."); stylus.test.sh all passed; other suites pass except hypr-session.test.sh (pre-existing untracked empty hypr .conf files).
- Done. Last code commit d767bb7. Risk: item 3, 6 (the --mat-* vars file the Chromium extension and styles consume gains -rgb vars; colors on live third-party pages are checked by eye). Suggestions: widen the hard-coded-color check to named colors and hsl(); post-install section 5 (Stylus in Zen) is stale since story 05 (Zen gets the vars through userContent.css, no Stylus); the other 21 userstyles likely share the primary-container/on-surface pairing and the stale Zen headers.
