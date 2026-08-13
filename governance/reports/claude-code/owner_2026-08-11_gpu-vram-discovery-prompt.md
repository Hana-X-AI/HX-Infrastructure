During Phase 1 discovery, determine GPU VRAM using native Ubuntu/Linux information only. Do not install NVIDIA drivers or any packages.

Use read-only commands.

Start by identifying the GPU and PCI address:

```bash
lspci -nn | grep -Ei 'vga|3d|display'
lspci -nnk | grep -A4 -Ei 'vga|3d|display'
```

For each GPU PCI address, inspect the device:

```bash
sudo lspci -vv -s <PCI_ADDRESS>
```

Important:

**Do not treat PCI BAR / prefetchable memory-region size as GPU VRAM.**

Values such as:

```text
Memory at ... [size=256M]
Memory at ... [size=32M]
```

describe PCI address-space apertures/BARs and may be much smaller or otherwise different from physical VRAM.

Next inspect kernel discovery messages:

```bash
sudo journalctl -k -b | grep -Ei 'nouveau|nvidia|drm|gpu|vram|gddr|fb:'
```

and:

```bash
sudo dmesg | grep -Ei 'nouveau|nvidia|drm|gpu|vram|gddr|fb:'
```

If the open-source `nouveau` driver probed the NVIDIA GPU, its kernel messages may report framebuffer/VRAM capacity. Record that value only if the kernel explicitly identifies it as VRAM/framebuffer memory.

Also inspect DRM/sysfs without changing the system:

```bash
ls -l /sys/class/drm/
```

For each applicable card:

```bash
readlink -f /sys/class/drm/card*/device
cat /sys/class/drm/card*/device/vendor 2>/dev/null
cat /sys/class/drm/card*/device/device 2>/dev/null
```

Check whether the kernel exposes a VRAM-total attribute:

```bash
find /sys/class/drm/card*/device -maxdepth 1 -type f \
  \( -name '*vram*' -o -name '*mem_info*' \) \
  -print 2>/dev/null
```

If present, read it:

```bash
cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null
```

Values from `mem_info_vram_total` are normally bytes. If needed, convert read-only:

```bash
numfmt --to=iec < /sys/class/drm/card0/device/mem_info_vram_total
```

Also collect:

```bash
sudo lshw -C display -numeric
```

but do not assume that a memory resource reported by `lshw` represents physical VRAM unless it explicitly says so.

Phase 1 rule:

If Ubuntu does not expose an authoritative VRAM value without installing/changing drivers, record:

```text
GPU VRAM: unavailable from current as-found OS/driver state
```

Then record the exact GPU model and PCI ID so VRAM can be verified later from an authoritative hardware specification if needed.

Do not:

- install `nvidia-smi`;
- install NVIDIA drivers;
- install CUDA;
- install `nvtop`, `hwinfo`, or other packages;
- load/unload kernel modules;
- change nouveau configuration;
- infer VRAM from PCI BAR sizes;
- infer VRAM solely from the marketing name if the same GPU model exists in multiple VRAM variants.

For `discovery.md`, distinguish clearly between:

```text
GPU model: directly discovered
GPU PCI ID: directly discovered
VRAM: directly reported | unavailable
VRAM source: <exact command/kernel source>
```

Phase 1 must preserve the server's as-found state.