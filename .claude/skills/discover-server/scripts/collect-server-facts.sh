#!/usr/bin/env bash
# Read-only HX Phase 1 server fact collector.
# It intentionally does not install packages or change host state.
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

run() {
  printf '\n$ %s\n' "$*"
  bash -lc "$*" 2>&1 || true
}

section "identity"
run "hostname"
run "hostname -f 2>/dev/null || true"
run "hostnamectl 2>/dev/null || true"
run "cat /etc/os-release 2>/dev/null || true"
run "uname -a"

section "platform firmware"
run "sudo -n dmidecode -t system 2>/dev/null || dmidecode -t system 2>/dev/null || true"
run "sudo -n dmidecode -t baseboard 2>/dev/null || dmidecode -t baseboard 2>/dev/null || true"
run "sudo -n dmidecode -t bios 2>/dev/null || dmidecode -t bios 2>/dev/null || true"

section "cpu"
run "lscpu"
run "numactl --hardware 2>/dev/null || true"

section "memory"
run "free -h"
run "lsmem 2>/dev/null || true"
run "sudo -n dmidecode -t memory 2>/dev/null || dmidecode -t memory 2>/dev/null || true"
run "swapon --show --bytes 2>/dev/null || true"

section "gpu and pci"
run "lspci -nnk 2>/dev/null || true"
run "command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi || true"
run "command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total,pci.bus_id --format=csv || true"
run "command -v rocminfo >/dev/null 2>&1 && rocminfo | head -n 250 || true"

section "storage"
run "lsblk -e7 -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,FSVER,MOUNTPOINTS,TRAN,ROTA"
run "findmnt -A 2>/dev/null || findmnt 2>/dev/null || true"
run "df -hT"
run "sudo -n pvs 2>/dev/null || pvs 2>/dev/null || true"
run "sudo -n vgs 2>/dev/null || vgs 2>/dev/null || true"
run "sudo -n lvs -a -o +devices 2>/dev/null || lvs -a -o +devices 2>/dev/null || true"
run "cat /proc/mdstat 2>/dev/null || true"
run "command -v nvme >/dev/null 2>&1 && nvme list || true"

section "network"
run "ip -br link"
run "ip -br address"
run "ip route"
run "ip -6 route 2>/dev/null || true"
run "resolvectl status 2>/dev/null || cat /etc/resolv.conf"
run "for n in /sys/class/net/*; do i=\$(basename \"\$n\"); printf '%s speed=' \"\$i\"; cat \"\$n/speed\" 2>/dev/null || printf 'unknown\n'; printf '%s duplex=' \"\$i\"; cat \"\$n/duplex\" 2>/dev/null || printf 'unknown\n'; done"

section "time and services"
run "timedatectl 2>/dev/null || true"
run "systemctl --failed --no-pager 2>/dev/null || true"
run "systemctl list-unit-files --state=enabled --no-pager 2>/dev/null || true"

section "relevant installed software"
run "dpkg-query -W -f='\${Package}\t\${Version}\n' 2>/dev/null | grep -Ei '^(openssh-server|nvidia|cuda|libcuda|rocm|docker|containerd|podman|ollama|vllm|python3|linux-image)' || true"
run "test -f /var/run/reboot-required && cat /var/run/reboot-required || true"

section "listening sockets"
run "ss -lntup 2>/dev/null || true"
