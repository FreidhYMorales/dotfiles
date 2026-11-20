# Story 16: Larger TTY console font

## Story

16. As the owner, I want a larger console font on the plain TTYs (no TTY replacement) so that text is readable on the 2K screen before any desktop starts.

## Acceptance criteria

- [x] Given this ThinkPad after a reboot, when I switch to a plain TTY (e.g. Ctrl+Alt+F3), then the text uses the larger font and is readable at the panel's native 2880x1800 without leaning in.
- [x] Given the boot before any desktop (early boot messages, and later story 13's LUKS prompt), when the console shows text, then it already uses the same larger font, not the tiny default.
- [x] Given a fresh install or a re-run of bootstrap, when it finishes, then the font is installed and set with no hand step, and a second run changes nothing.

## Plan

- Install the Terminus console font package and set it as the console font in the system console config, keeping the current keymap lines untouched.
- Make sure the early-boot image carries the font (the console-font hook is already in the image today) and rebuild it once.
- Fold both into bootstrap as one idempotent step, reusing the existing image rebuild instead of adding another.
- Pin it with tests: bootstrap installs the package and writes the font line once on re-run; the live console config names the chosen font.
- Verify by eye on a real TTY after a reboot; test command plus suites green.

## Out of scope

- TTY replacements (kmscon, fbterm) and Nerd Font glyphs on the kernel console: declined in story 10 (PSF fonts hold at most 512 glyphs).
- Switching the image to systemd hooks, Plymouth or LUKS: story 13 (its plan already uses the hook that reads the same console config, so the font carries over).
- GRUB menu font or resolution, SDDM and desktop fonts.

## Assumptions

- Today, seen live: `FONT=default8x16` at 2880x1800 (about 360x112 cells, tiny); `terminus-font` not installed; the image already runs the `consolefont` hook; bootstrap has no console font step.
- Font: `ter-132b` (Terminus bold, 16x32, about 180x56 cells), the usual HiDPI pick. If it feels too big, `ter-128b` (14x28) is the step down; pair swaps it on the owner's word.

## Suggestions (your call)

- none

## Size

normal
Risk: item 5, 6 (install script and initramfs rebuild; readability is checked by eye, not by a test)

## Log

- L1 request: /flow:story 16
- L2 test list approved ("si"): 1 step sets the font (replace and add, keymap kept, installs terminus-font), 2 re-run changes nothing, 3 font reaches the initramfs (rebuild follows the step, live HOOKS read vconsole.conf), 4 live ThinkPad state, 5 manual TTY and early boot.
- L3 red/green: e7c6853 test red (step missing: 3 FAIL) -> 4f3d472 feat green. 8ca0d3a and cc10b27 passed with no new code; shown red against mutants (unconditional FONT append: 3 FONT lines; no mkinitcpio -P after the step; HOOKS without consolefont). eb3acfe live test red (FONT=default8x16, terminus-font missing) -> green after the owner ran `sudo pacman -S --needed terminus-font && sudo sed -i 's/^FONT=.*/FONT=ter-132b/' /etc/vconsole.conf && sudo mkinitcpio -P` (consolefont hook ran). The initramfs is root-only, so test 4 checks "rebuilt after vconsole.conf changed" by mtime.
- L4 check: Test command passes ("Dry run complete."); console.test.sh 13/13 "all passed"; all other suites pass except hypr-session.test.sh, red from two untracked empty files (dotfiles/hypr/.config/hypr/monitors.conf, workspaces.conf, dated 15 Nov) that predate the story. Verifier: NEEDS DECISION only for the by-eye check (all automated evidence PASS, extra mutants red, tamper check clean, refs unchanged).
- L5 manual: owner confirmed ter-132b is readable on a TTY ("si esta bien ese tamaño"), after `setfont` since the running TTYs predate the change; early boot is seen on the next reboot.
- Done. Last code commit 4f3d472. Risk: item 5, 6 (install script and initramfs rebuild; readability checked by eye). Suggestions: delete or track the two empty hypr .conf files; bootstrap does not ensure HOOKS hold consolefont/sd-vconsole (Arch default and story 13's plan both do).
