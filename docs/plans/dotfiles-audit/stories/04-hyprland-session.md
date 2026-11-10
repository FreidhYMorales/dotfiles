# Story 04: Hyprland session audit (hypr, uwsm, xdg-portal, termfilechooser)

## Story

04. As the owner, I want my Hyprland session (hypr, uwsm, xdg-portal, termfilechooser) audited so that the desktop starts and behaves reliably.

## Acceptance criteria

- [ ] Given a cold login from SDDM into the uwsm Hyprland session, when the desktop comes up, then the shell, wallpaper, clipboard history, keyring and portals each run exactly once, every keybind runs a command that exists, and the user journal shows no errors from session components.
- [ ] Given an app asks for a file, a screenshot or a screen share through the portal, when I answer the request, then yazi opens in kitty for files (the chosen path returns to the app) and the Hyprland portal handles screenshot and screen share.
- [ ] Given a running session, when the laptop suspends (lid close) and resumes, then the wallpaper and the shell are still on screen and nothing in the session has crashed.

## Plan

- Inventory: list what the Lua entry point actually loads and what the session starts; anything Hyprland or uwsm never reads is dead config (candidates seen: `hypridle.conf` and `hyprlock.conf` with neither binary installed, legacy `monitors.conf`, an empty `workspaces.conf`, the untracked `hyprpaper.conf.bak`).
- Startup: reconcile the autostart list with what uwsm and D-Bus already provide (uwsm already exports the environment, and termfilechooser is D-Bus/systemd activatable but is also exec'd by hand), so each service has exactly one owner.
- Environment: check that env vars set in Hyprland, the uwsm env file and the portal config agree (session type, toolkit backends, cursor, `GTK_USE_PORTAL`), and that the NVIDIA branch is harmless on this Intel-only machine.
- Resume: reproduce the hyprpaper core dump seen in this boot's journal (it crashes when an output is destroyed) and make the wallpaper survive suspend and resume.
- Verify: the test command plus a cold login, a portal round trip (browser upload, screenshot, screen share) and a real suspend/resume, all done live.

## Out of scope

- Theming of Hyprland borders and colors (story 05), scripts called by keybinds (story 08), logind/systemd-sleep hooks under `system/` (story 09).
- Changes to bootstrap/deploy (story 10 picks them up).
- Quickshell notch internals and the old-bar cutover (story 14); SDDM → greetd (story 13).
- New keybinds, gestures or visual tweaks beyond fixing dead or broken ones (the previously skipped `vrr=1` and the extra gestures stay unapplied).

## Assumptions

- The session stays uwsm-managed (`hyprland-uwsm.desktop`, confirmed live: `wayland-wm@hyprland.desktop.service` is active).
- The Quickshell lockscreen and its idle handling remain the lock and idle path, so the hypridle/hyprlock configs count as dead, not as something to revive.
- hyprpaper stays as the wallpaper process the notch writes its config for; whether to drop it is a story 14 decision.

## Decisions

- Launch autostart apps through `uwsm app --` so that each one runs in its own systemd scope and shows up in the journal, instead of as a bare child of Hyprland.

## Suggestions (your call)

- none pending

## Size

normal
Risk: item 5, 6 (session runtime config and autostart; portals and resume are only verifiable live)

## Log

- L1 request: "/flow:story 04"
- L2 approval: "si, aprobada, aplica la sugerencia" → `uwsm app --` suggestion promoted to Decisions.
