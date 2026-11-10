# Story 05: Theming pipeline audit (matugen, vesktop, stylus, chromium-extension)

## Story

05. As the owner, I want the theming pipeline (matugen, spicetify, vesktop, betterdiscord, stylus, chromium-extension) audited so that every app follows the wallpaper.

## Acceptance criteria

- [ ] Given Vesktop is open, when I pick a new wallpaper, then Discord's UI switches to the new palette without restarting Vesktop.
- [ ] Given a site with a Stylus userstyle open in Zen and in a Chromium webapp, when I pick a new wallpaper and reload it, then the page uses the new palette in both browsers.
- [ ] Given the repo deployed on this machine, when I use Vesktop and list the theming packages, then there is no Spotify/Spicetify or BetterDiscord config left and Vesktop's runtime data never shows up as repo changes.

## Plan

- Remove: drop the Spicetify and BetterDiscord packages (Spotify is unused; BetterDiscord has no client here, Vesktop runs Vencord) and uninstall spotify/spicetify from this machine.
- Vesktop: add a matugen template rendered into a Vencord theme, enabled once, which Vencord reloads on file change; the post-hook needs nothing new.
- Vesktop package: stow only the settings Vesktop needs from the repo, so session data, crash dumps and window state stay out of git, without logging Discord out.
- Browsers: check the palette vars still reach pages end to end (matugen output, matugen-server, Zen userContent, the Chromium extension); fix only breakage, not per-site coverage.
- Verify: the test command plus a live wallpaper change with Vesktop open and a styled site reloaded in Zen and Chromium.

## Out of scope

- Theming new apps or a CLI Spotify client (spotify-player/ncspot): an idea for story 06 or `/flow:idea`, not this story.
- Completing per-site Stylus token coverage (story 15).
- Changes to bootstrap/deploy beyond what removing a package forces (story 10 drops spotify/spicetify-cli from bootstrap.sh).
- Re-enabling GTK3/GTK4 theming, Hyprland/kitty/zellij/btop templates (audited in stories 01-04), SDDM theming (story 13).

## Assumptions

- Vesktop is the Discord client that stays; BetterDiscord is removed (owner approved).
- Stylus import stays manual; matugen-server on :9119 keeps serving the vars.

## Suggestions (your call)

- none pending

## Size

normal
Risk: item 1, 5, 6 (Vesktop login data when restowing; stow packages and installed apps; colors verifiable only live)

## Log

- L1 request: "/flow:story 05"
- L2 owner: Spotify unused, remove it (a CLI client maybe later); Stylus works, finish mapping tokens for the webapps; asked which of BetterDiscord/Vesktop to keep.
- L3 approval: "si, aprobada, no no son solo esas 3, pero me gustaria hacer que stylus sea mas completo de lo que ya es. Podriamos dejarlo para una story aparte si se pasa de esta story." → per-site Stylus coverage split to story 15; criterion 2 narrowed to the vars pipeline working end to end.
