#!/usr/bin/env bash
# Read-only HX Phase 1 server fact collector.
#
# It intentionally does not install packages, load modules, or change host state.
# Every command below reads existing system state only.
#
# Privilege handling: the script detects whether it can obtain root non-interactively.
# When it cannot, privileged facts are reported as REQUIRES ROOT rather than silently
# returning empty output. Prepare passwordless sudo per the human pre-discovery
# checklist and a single pass collects everything.
#
# Evidence rules honoured here:
#   - GPU VRAM is read from kernel messages that name it as VRAM.
#   - PCI base address register sizes are NOT collected as VRAM evidence.
set -u

section() { printf '\n===== %s =====\n' "$1"; }
hdr()     { printf '\n--- %s\n' "$1"; }
run()     { printf '\n$ %s\n' "$*"; bash -lc "$*" 2>&1 || true; }
have()    { command -v "$1" >/dev/null 2>&1; }

# Run a command that needs root. Never silently empty.
priv() {
    printf '\n$ %s\n' "$*"
    case "$HX_PRIV" in
        root) bash -lc "$*" 2>&1 || true ;;
        sudo) bash -lc "sudo -n $*" 2>&1 || true ;;
        *)    printf 'REQUIRES ROOT - NOT DETERMINED (no passwordless sudo available)\n' ;;
    esac
}

# Run a command from an optional package. Never silently empty.
opt() {
    local tool="$1"; shift
    printf '\n$ %s\n' "$*"
    if have "$tool"; then
        bash -lc "$*" 2>&1 || true
    else
        printf 'TOOL NOT INSTALLED: %s\n' "$tool"
    fi
}

# Optional tool that also needs root.
privopt() {
    local tool="$1"; shift
    printf '\n$ %s\n' "$*"
    if ! have "$tool"; then
        printf 'TOOL NOT INSTALLED: %s\n' "$tool"
        return 0
    fi
    case "$HX_PRIV" in
        root) bash -lc "$*" 2>&1 || true ;;
        sudo) bash -lc "sudo -n $*" 2>&1 || true ;;
        *)    printf 'REQUIRES ROOT - NOT DETERMINED (no passwordless sudo available)\n' ;;
    esac
}

if [ "$(id -u)" -eq 0 ]; then
    HX_PRIV="root"
elif sudo -n true 2>/dev/null; then
    HX_PRIV="sudo"
else
    HX_PRIV="none"
fi

section "collection context"
printf 'collector user      : %s\n' "$(id -un)"
printf 'privilege mode      : %s\n' "$HX_PRIV"
printf 'collection time utc : %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S')"
if [ "$HX_PRIV" = "none" ]; then
    printf '\nNOTE: no passwordless sudo. Firmware serial, DIMM layout, GPU VRAM from\n'
    printf 'kernel messages, firewall state and effective SSH configuration will be\n'
    printf 'reported as REQUIRES ROOT. Prepare sudo per the human checklist and rerun.\n'
fi

section "identity"
run "hostname"
run "hostname -f 2>/dev/null || echo 'no FQDN configured'"
run "hostnamectl"
run "cat /etc/os-release"
run "uname -a"

hdr "DMI identity readable without root"
for f in sys_vendor product_name product_version board_vendor board_name \
         board_version bios_vendor bios_version bios_date chassis_type; do
    printf '  %-16s %s\n' "$f" "$(cat "/sys/class/dmi/id/$f" 2>/dev/null || echo 'unavailable')"
done

hdr "DMI identity requiring root"
priv "cat /sys/class/dmi/id/product_serial"
priv "cat /sys/class/dmi/id/board_serial"
priv "cat /sys/class/dmi/id/chassis_serial"
privopt dmidecode "dmidecode -t system"
privopt dmidecode "dmidecode -t baseboard"
privopt dmidecode "dmidecode -t bios"

section "cpu"
run "lscpu"

section "memory"
run "free -h"
run "lsmem 2>/dev/null || echo 'lsmem reported nothing'"
run "swapon --show --bytes 2>/dev/null || echo 'no swap configured'"
privopt dmidecode "dmidecode -t memory"

section "gpu and accelerators"
run "lspci -nn | grep -Ei 'vga|3d|display|processing accelerator|co-processor' || echo 'no display or accelerator class devices found'"
# -A4 so the Subsystem line is captured. The subsystem ID identifies the board
# partner and VBIOS; two cards can share a chip and PCI device ID yet behave
# differently, so device ID alone is not enough to compare GPUs across hosts.
run "lspci -nnk | grep -A4 -Ei 'vga|3d|display|processing accelerator|co-processor' || true"

hdr "vendor tooling, if present"
opt nvidia-smi "nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total,pci.bus_id --format=csv"
opt rocminfo "rocminfo | head -n 60"

hdr "VRAM and GPU driver initialization from kernel messages"
# Also captures driver bring-up failures. An earlier filter matched only memory
# strings and silently hid GSP initialization failures and probe errors, which
# are the messages that explain why a GPU has no driver bound.
priv "journalctl -k -b | grep -Ei 'vram|gddr|fb: |nouveau|amdgpu|nvidia|gsp|init failed|probe with driver|allocation failed' | head -n 60"

hdr "VRAM from drm sysfs, where the driver exposes it"
for c in /sys/class/drm/card*; do
    cbase="$(basename "$c")"
    # /sys/class/drm also contains connector entries such as card0-DP-4.
    # Only the card devices themselves are of interest here.
    case "$cbase" in *-*) continue ;; esac
    [ -e "$c/device" ] || continue

    if [ -L "$c/device/driver" ]; then
        drv="$(basename "$(readlink -f "$c/device/driver")")"
    else
        drv="none bound"
    fi

    printf '  %-10s driver=%-12s pci=%s\n' "$cbase" "$drv" \
        "$(basename "$(readlink -f "$c/device" 2>/dev/null)" 2>/dev/null || echo unknown)"

    found_attr="no"
    for a in mem_info_vram_total mem_info_vis_vram_total; do
        if [ -r "$c/device/$a" ]; then
            printf '    %s = %s bytes\n' "$a" "$(cat "$c/device/$a")"
            found_attr="yes"
        fi
    done
    [ "$found_attr" = "no" ] && printf '    no VRAM attribute exposed by this driver\n'
done

hdr "PCIe link state per display and accelerator device"
for d in /sys/bus/pci/devices/*; do
    cls="$(cat "$d/class" 2>/dev/null || echo 0)"
    case "$cls" in
        0x0300*|0x0302*|0x0380*|0x1200*|0x0b40*)
            # A missing driver symlink means no driver is bound. readlink -f
            # succeeds on a non-existent path, so test for the link itself.
            if [ -L "$d/driver" ]; then
                dev_drv="$(basename "$(readlink -f "$d/driver")")"
            else
                dev_drv="none bound"
            fi
            printf '  %s class=%s driver=%s\n' "$(basename "$d")" "$cls" "$dev_drv"

            link_speed="$(cat "$d/current_link_speed" 2>/dev/null || echo Unknown)"
            # On-die devices report Unknown speed and a sentinel width of 255.
            # Printing that as a link state is misleading.
            if [ "$link_speed" = "Unknown" ] || [ ! -r "$d/current_link_speed" ]; then
                printf '    no PCIe link reported (on-die or root-complex integrated device)\n'
            else
                printf '    negotiated %s x%s | maximum %s x%s\n' \
                    "$link_speed" \
                    "$(cat "$d/current_link_width" 2>/dev/null || echo '?')" \
                    "$(cat "$d/max_link_speed" 2>/dev/null || echo unavailable)" \
                    "$(cat "$d/max_link_width" 2>/dev/null || echo '?')"
            fi
            ;;
    esac
done

section "storage"
run "lsblk -e7 -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,FSVER,MOUNTPOINTS,TRAN,ROTA"
run "findmnt --real"
run "df -hT -x tmpfs -x devtmpfs -x efivarfs"
priv "blkid"
run "cat /etc/fstab"

hdr "LVM (empty output without root is ambiguous, so it is qualified)"
privopt pvs "pvs"
privopt vgs "vgs"
privopt lvs "lvs -a -o +devices"

hdr "RAID"
run "cat /proc/mdstat 2>/dev/null || echo 'no md subsystem'"

hdr "device detail from optional tooling"
opt nvme "nvme list"
privopt smartctl "smartctl --scan"

section "network"
run "ip -br link"
run "ip -br address"
run "ip route"
run "ip -6 route 2>/dev/null || echo 'no IPv6 routes'"
run "resolvectl status 2>/dev/null || cat /etc/resolv.conf"

hdr "link speed and duplex"
for n in /sys/class/net/*; do
    i="$(basename "$n")"
    [ "$i" = "lo" ] && continue
    printf '  %-14s speed=%-8s duplex=%-8s operstate=%s\n' "$i" \
        "$(cat "$n/speed" 2>/dev/null || echo unknown)" \
        "$(cat "$n/duplex" 2>/dev/null || echo unknown)" \
        "$(cat "$n/operstate" 2>/dev/null || echo unknown)"
done

section "security and access state"
run "test -d /sys/firmware/efi && echo 'UEFI boot mode' || echo 'legacy BIOS boot mode'"
opt mokutil "mokutil --sb-state"
privopt ufw "ufw status verbose"
priv "sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|x11forwarding) '"

section "time and services"
run "timedatectl 2>/dev/null || echo 'timedatectl unavailable'"
run "systemctl --failed --no-pager 2>/dev/null || echo 'systemctl unavailable'"
run "systemctl list-unit-files --state=enabled --no-pager 2>/dev/null | tail -n +1"

section "relevant installed software"
run "dpkg-query -W -f='\${Package}\t\${Version}\n' 2>/dev/null | grep -Ei '^(openssh-server|nvidia|cuda|libcuda|rocm|docker|containerd|podman|ollama|vllm|python3|linux-image)' || echo 'no matching packages'"

hdr "pending updates"
run "apt list --upgradable 2>/dev/null | grep -c 'upgradable from' || echo 0"
run "test -f /var/run/reboot-required && cat /var/run/reboot-required || echo 'no reboot required'"

section "listening sockets"
priv "ss -lntup"

printf '\n===== collection complete =====\n'
