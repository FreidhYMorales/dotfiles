#!/usr/bin/env bash
# Tests for this ThinkPad's hardware stack (story 17): every device on its
# expected driver (live_*), and bootstrap.sh installing what each one needs.
# Usage: scripts/tests/hardware.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

pci_driver() { # lspci class pattern -> kernel driver in use (first match)
    lspci -k | awk -v pat="$1" '
        $0 ~ /^[0-9a-f]/ { hit = ($0 ~ pat) }
        hit && /Kernel driver in use:/ { print $NF; exit }'
}

sysfs_driver() { # /sys/class/<path> -> module name of its device driver
    basename "$(readlink -f "/sys/class/$1/device/driver/module" 2>/dev/null)"
}

bootstrap_lines() { # -> bootstrap.sh with backslash continuations joined
    awk '{ if (sub(/\\$/, "")) { buf = buf $0 " "; next } print buf $0; buf = "" }' "$BOOTSTRAP"
}

installs() { # pkg -> yes|no: bootstrap.sh installs it with pacman or yay
    # grep -c, not grep -q: under pipefail an early-exiting grep -q kills the
    # writer with SIGPIPE and turns a match into "no".
    [[ $(bootstrap_lines | grep -oE '(pacman|yay) -S --needed --noconfirm[^|;&]*' |
        tr -s ' ' '\n' | grep -cxF -- "$1") -gt 0 ]] && echo yes || echo no
}

enables() { # unit -> yes|no: bootstrap.sh runs systemctl enable on it
    [[ $(bootstrap_lines | grep -v '^\s*#' | grep -cE -- "systemctl enable( --now)? $1( |$)") -gt 0 ]] && echo yes || echo no
}

battery_gated() { # pkg -> yes|no: bootstrap.sh installs it only inside a BAT0 (laptop) block
    bootstrap_lines | awk -v pkg="$1" '
        /^if .*power_supply\/BAT0/ { gated = 1 }
        /^fi/ { gated = 0 }
        gated && /(pacman|yay) -S/ { for (i = 1; i <= NF; i++) if ($i == pkg) hit = 1 }
        END { print (hit ? "yes" : "no") }'
}

test_live_devices_on_expected_driver() {
    # Story 17 audit, this ThinkPad X1 Carbon Gen 13 (Lunar Lake).
    assert_eq "iGPU (Arc 130V/140V) on xe" xe "$(pci_driver 'VGA compatible controller')"
    assert_eq "NPU on intel_vpu" intel_vpu "$(pci_driver 'Processing accelerators.*NPU')"
    assert_eq "audio on SOF (Lunar Lake)" sof-audio-pci-intel-lnl "$(pci_driver 'Multimedia audio controller')"
    assert_eq "Wi-Fi (BE200) on iwlwifi" iwlwifi "$(pci_driver 'Network controller')"
    assert_eq "Bluetooth hci0 on btintel_pcie" btintel_pcie "$(sysfs_driver bluetooth/hci0)"
    assert_eq "thinkpad_acpi loaded" yes "$([[ -d /sys/module/thinkpad_acpi ]] && echo yes || echo no)"
}

test_bootstrap_installs_device_packages() {
    # Story 17: what each device needs on a fresh install of this ThinkPad.
    local p u
    for p in intel-ucode vulkan-intel intel-media-driver intel-npu-driver-bin sof-firmware \
        iwd wireless-regdb bluez power-profiles-daemon fwupd; do
        assert_eq "bootstrap installs $p" yes "$(installs "$p")"
    done
    for u in iwd bluetooth power-profiles-daemon; do
        assert_eq "bootstrap enables $u" yes "$(enables "$u")"
    done
}

test_firmware_checks_enabled() {
    # Story 17: firmware update checks run on any machine, not only on laptops
    # as a side effect of the battery threshold step.
    assert_eq "fwupd is not installed only on laptops" no "$(battery_gated fwupd)"
    assert_eq "bootstrap enables fwupd-refresh.timer" yes "$(enables fwupd-refresh.timer)"
}

all_tests=(test_live_devices_on_expected_driver test_bootstrap_installs_device_packages
    test_firmware_checks_enabled)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
