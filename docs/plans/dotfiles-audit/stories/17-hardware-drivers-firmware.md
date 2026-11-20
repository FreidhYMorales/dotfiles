# Story 17: Hardware, drivers and firmware audited against the bootstrap

## Story

17. As the owner, I want this ThinkPad's hardware, drivers and firmware (CPU microcode, xe iGPU, NPU, audio, Wi-Fi/Bluetooth, power, fwupd) audited against the bootstrap so that every device runs on the right driver and config after a reinstall.

## Acceptance criteria

- [ ] Given this ThinkPad running, when I check each device (CPU, iGPU, NPU, audio, Wi-Fi, Bluetooth, battery and power, system firmware), then each one runs on its expected driver and firmware, and this boot's kernel log has no driver or firmware errors left unexplained.
- [ ] Given a fresh install on this ThinkPad, when bootstrap.sh runs, then every package, service and config those devices need is installed and enabled by a step gated on that device being present, including periodic firmware update checks.
- [ ] Given a later change to bootstrap.sh or to the hardware stack, when the test suite runs, then it fails if a device's driver package or service goes missing from bootstrap, or if a live device stops matching its expected driver.

## Plan

- Inventory the devices live (PCI/USB, loaded modules, firmware revisions, fwupd devices) and record the expected driver per device in the Log.
- Review the kernel and service logs of this boot; each warning is fixed or written down as harmless with its reason (today: SOF HDMI topology notice, HPET `_CRS`, Bluetooth gp1 mailbox).
- Reconcile bootstrap's GPU, microcode, NPU, audio, network, Bluetooth, battery, ASPM and power-profile steps with what the inventory needs; enable periodic firmware checks (the `fwupd-refresh` timer is disabled today) and stop installing fwupd only as a side effect of the battery step.
- Pin it with a test: a live device-to-driver check plus bootstrap containing each device's packages and services.
- Verify: test command plus all suites green; owner confirms audio, Wi-Fi, Bluetooth, suspend/resume and the battery threshold still work.

## Out of scope

- Running local models on the NPU/iGPU (story 12); here the NPU only has to be on its driver.
- The unused, unparsable UKI `/boot/efi/EFI/Linux/arch-linux.efi` flooding the logind journal: paused until the owner decides whether the reinstall keeps this disk or uses another one. Its warnings count as explained, not fixed.
- Applying firmware updates; fwupd reports none today, the story only makes sure checks run.
- Kernel parameter tuning beyond what a driver needs, and new power-saving work (the 2026-08-14 energy audit stands).
- A real fresh install or a VM run.

## Assumptions

- The expected driver per device is today's live one (xe, intel_vpu, sof-audio-pci-intel-lnl, iwlwifi/iwlmld, btusb, thinkpad_acpi, microcode 0x128) unless the review finds a reason to change it.
- The device test reads sysfs/lspci without root, so it can run in the normal suite.

## Suggestions (your call)

- fwupd is installed inside the battery step (18b) only; a small firmware step of its own reads clearer.

## Size

normal
Risk: item 5, 6 (install script and driver packages; a fresh install is verifiable only on the real reinstall)

## Log

- L1 request: "/flow:story 17"
- L2 approval (owner: "si, no el uki lo vamos a dejar en pausa, como no se si voy a usar este mismo disco o voy a usar otro, pero de momento no lo vamos a hacer hasta que eso este definido, pero el reinstall si"): story approved; the UKI stays out, paused until the reinstall disk is decided; the reinstall itself still goes ahead.
- L3 test list approved ("si"): 1 live devices on expected driver, 2 bootstrap installs and enables each device's stack, 3 firmware checks outside the battery step, 4 live fwupd-refresh.timer, 5 no legacy i965 driver (bootstrap and live), 6 manual. Owner approved dropping libva-intel-driver (i965, Gen <= 9 only; Lunar Lake uses intel-media-driver/iHD) and keeping the linux-firmware meta (covers USB dongles of other vendors).
- L4 audit: live drivers xe (DMC xe2lpd v2.29, GuC 70.72.1, HuC 9.4.13, GSC 104.0.5.1429), intel_vpu (vpu_40xx fw Mar 2026), sof-audio-pci-intel-lnl, iwlwifi/iwlmld (BE200, fw c107), Bluetooth hci0 on btintel_pcie (not btusb: the BE200 hangs BT off PCIe; ibt-0190-0291), thinkpad_acpi, microcode 0x128; battery 75/80, ASPM powersave, profile balanced; fwupd: no updates. Kernel warnings explained as harmless: BIOS _OSI(Linux) ignored, HPET no _CRS, SOF "no PCM in topology for HDMI converter 3" and deferred card binding, Bluetooth gp1 mailbox interrupt. logind's "Failed to parse PE file arch-linux.efi" flood: the paused UKI (L2).
- L5 pair: characterization 8e7f190 (devices, shown failing with i915/btusb expected) and 8e5b21c (bootstrap packages and enables, shown failing on a copy without sof-firmware and the bluetooth enable); red→green 5a07e4d→767cc9d (step 18a: fwupd + fwupd-refresh.timer, out of the battery step; companion case iwd not gated), 5767a2b→live (owner ran `sudo systemctl enable --now fwupd-refresh.timer`, no code commit), ef7c0e0→d50fc84 (libva-intel-driver dropped from bootstrap, owner uninstalled it live). hardware.test.sh: 22 ok, all passed; test command passes; every suite green except hypr-session (pre-existing: the two untracked nwg-displays files, story 10 L7).
- L6 manual (owner: "si, todo anda bien"): audio, Wi-Fi, Bluetooth pairing, suspend and resume all work.
