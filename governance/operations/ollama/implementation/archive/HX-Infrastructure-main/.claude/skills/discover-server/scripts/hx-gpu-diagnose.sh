#!/usr/bin/env bash
# Read-only GPU enumeration and PCI resource diagnostic.
#
# Written for iss-007 (hxs-3: installed GPU not enumerated) and
# iss-008 (hxs-2: nouveau aborts with "Device allocation failed: -22").
#
# Collects the evidence needed to confirm or refute the working hypothesis that
# both faults share one cause: insufficient 64-bit PCI address space because
# Above 4G Decoding is disabled in 2016-era firmware.
#
# READ-ONLY. Installs nothing, loads no module, changes no firmware setting.
set -u

section() { printf '\n===== %s =====\n' "$1"; }
run()     { printf '\n$ %s\n' "$*"; bash -lc "$*" 2>&1 || true; }

section "1. PCI enumeration errors from the kernel"
# The main collector filters on vram/nouveau/nvidia and cannot see these.
run "dmesg | grep -iE 'pci .*(BAR|bridge window|reserve|assign|no space|not enough|conflict|failed)' | head -n 60"
run "dmesg | grep -iE 'pci_bus|pci .*resource|host bridge|acpi.*_CRS' | head -n 40"

section "2. every PCI device and its bridge topology"
run "lspci -tv"

section "3. GPU BAR assignments and sizes"
for slot in $(lspci -D | grep -Ei 'vga|3d controller|display' | cut -d' ' -f1); do
    printf '\n--- %s\n' "$slot"
    run "lspci -vv -s ${slot#0000:} | grep -EA1 'Region|Memory at|Expansion ROM|Capabilities: .*Resizable'"
    printf '  kernel resource map:\n'
    if [ -r "/sys/bus/pci/devices/$slot/resource" ]; then
        i=0
        while read -r s e f; do
            if [ "$s" != "0x0000000000000000" ]; then
                size=$(( (e - s + 1) / 1024 / 1024 ))
                above4g="below 4G"
                if [ "$((s))" -gt 4294967295 ]; then above4g="ABOVE 4G"; fi
                printf '    BAR%-2d start=%s size=%6d MiB  %s\n' "$i" "$s" "$size" "$above4g"
            fi
            i=$((i + 1))
            [ "$i" -ge 6 ] && break
        done < "/sys/bus/pci/devices/$slot/resource"
    fi
    printf '  driver: %s\n' "$( [ -L "/sys/bus/pci/devices/$slot/driver" ] && basename "$(readlink -f "/sys/bus/pci/devices/$slot/driver")" || echo 'none bound')"
done

section "4. is 64-bit MMIO space in use above 4G"
# If Above 4G Decoding is enabled, large windows appear above 0x100000000.
run "grep -iE 'PCI Bus|PCI mem' /proc/iomem | tail -n 25"
run "awk -F- '{ if (strtonum(\"0x\" \$1) > 4294967295) print \"  above 4G: \" \$0 }' /proc/iomem | head -n 20 || echo '  no ranges above 4G found'"

section "5. firmware and platform"
run "dmidecode -t bios | grep -Ei 'version|release date|revision'"
run "dmidecode -t baseboard | grep -Ei 'product name|manufacturer'"

section "6. GPU power and link state"
for slot in $(lspci -D | grep -Ei 'vga|3d controller|display' | cut -d' ' -f1); do
    printf '  %s  link=%s x%s  max=%s x%s  power=%s\n' "$slot" \
        "$(cat "/sys/bus/pci/devices/$slot/current_link_speed" 2>/dev/null || echo '?')" \
        "$(cat "/sys/bus/pci/devices/$slot/current_link_width" 2>/dev/null || echo '?')" \
        "$(cat "/sys/bus/pci/devices/$slot/max_link_speed" 2>/dev/null || echo '?')" \
        "$(cat "/sys/bus/pci/devices/$slot/max_link_width" 2>/dev/null || echo '?')" \
        "$(cat "/sys/bus/pci/devices/$slot/power_state" 2>/dev/null || echo '?')"
done

section "7. nouveau and firmware availability"
run "dmesg | grep -iE 'nouveau|gsp|firmware' | head -n 40"
run "dpkg-query -W -f='\${Package}\t\${Version}\n' linux-firmware 2>/dev/null || echo 'linux-firmware not installed'"
run "ls /lib/firmware/nvidia/ 2>/dev/null | head -n 20 || echo 'no /lib/firmware/nvidia directory'"

printf '\n===== diagnostic complete =====\n'
