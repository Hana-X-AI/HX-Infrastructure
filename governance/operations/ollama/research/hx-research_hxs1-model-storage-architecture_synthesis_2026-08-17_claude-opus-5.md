# hxs-1 Model Storage Architecture — Reconnaissance and Design Proposal

| | |
|---|---|
| **Document ID** | `hx-research_hxs1-model-storage-architecture_synthesis_2026-08-17_claude-opus-5` |
| **Subject** | hxs-1 local storage: current state, device selection, filesystem and mount design, and how model artifacts should be stored during download and at runtime |
| **Evidence tier** | `synthesis` — HX discovery record (primary) + vendor runtime documentation + published drive characteristics, with derived design |
| **Author** | Claude (Opus 5) |
| **Date** | 2026-08-17 |
| **Status** | **Design proposal.** Not a decision, not an acceptance, not an authorization. No storage mutation is authorized by Phase 3. |
| **Relates to** | hxs-1 · `INFRASTRUCTURE-CONTRACT.md` §10 · `hx-recommendations.html` R1, R5 · `tests/ai-runtime/hx-capacity-gate.ps1` |

---

## Abstract

hxs-1 has ~11 TB of installed, unpartitioned, unused storage across two devices and a root
filesystem at 1% capacity. Capacity is not the constraint — **device selection is**.

Three findings drive the design. The 7.3 TB SATA drive is a **Seagate ST8000DM004, an SMR
(shingled) 5400-RPM consumer disk**; it is unsuitable as a model store or download target and
should be treated as cold archive only. NVMe device enumeration on this host has **already
changed once** — the discovery record notes root and `/boot/efi` were on `nvme1n1` at install
and are now on `nvme0n1` — so device-name-based configuration is empirically unsafe here and
serial numbers are the only reliable device identity. And because hxs-1 has **no BMC or
out-of-band management**, a data-disk mount that can block boot is a recovery hazard, making
`nofail` mandatory rather than optional.

The proposal: dedicate the second NVMe (`WD_BLACK SN850X`, serial `250816800905`) to a model
store mounted at `/srv/hx/models`, keep models entirely off the root filesystem, and reserve
the SMR drive for cold archive. Both Ollama and Hugging Face download **in place** using
content-addressed layouts with same-filesystem atomic promotion, so **no 2× staging space is
required**. At runtime the 128 GB of host RAM keeps the model file page-cache resident after
first load absent memory pressure, so storage speed governs cold start only — where the two
candidate devices differ by roughly **38× on published sequential specs**.

---

## 1. Reconnaissance — current storage state

All facts from `servers/hxs-1/discovery.md`. Nothing in this section is inferred.

### 1.1 Block devices

| Device | Model | Serial | Type | Capacity | State |
|---|---|---|---|---|---|
| `/dev/nvme0n1` | WD_BLACK SN850X 4000GB | `250816800073` | NVMe SSD | 3.6 TB | partitioned, **in use** |
| ` └ nvme0n1p1` | — | — | partition | 1 GB | vfat FAT32, UUID `2EFE-5D0D` → `/boot/efi` |
| ` └ nvme0n1p2` | — | — | partition | 3.6 TB | ext4, UUID `ab09b07d-fb20-4235-99df-440f18896e99` → `/` |
| `/dev/nvme1n1` | WD_BLACK SN850X 4000GB | `250816800905` | NVMe SSD | 3.6 TB | **no partition table, no filesystem, unmounted** |
| `/dev/sda` | **ST8000DM004-2U91** | `ZR1682F1` | SATA HDD, rotational | 7.3 TB | **no partition table, no filesystem, unmounted** |

### 1.2 Recorded characteristics

- Root filesystem usage: **11 GB of 3.6 TB — 1%**
- **No LVM** — no physical volumes, volume groups or logical volumes
- **No RAID** — `/proc/mdstat` lists personalities but reports no active arrays
- `fstab` mounts root and `/boot/efi` **by UUID**, satisfying the stable-identifier requirement
  in `INFRASTRUCTURE-CONTRACT.md` §10.2
- **Device enumeration is empirically unstable:** *"fstab comments record that root and
  `/boot/efi` were on `nvme1n1` during installation; they are now on `nvme0n1`, so NVMe
  enumeration changed after install"*
- Swap is the file `/swap.img` (size not recorded in the discovery record)
- **SMART detail unavailable — `smartctl` is not installed** (open recommendation R1)
- Host RAM: **128 GB DDR5**, non-ECC
- Network: single **1 Gb/s** copper link, `enp131s0`
- `multipathd`, `open-iscsi` and `lvm2-monitor` are enabled, carried over from a
  virtualization-oriented install image on what is bare metal

### 1.3 Finding — the SATA drive is SMR

The **Seagate ST8000DM004** is a shingled-magnetic-recording (SMR) drive in the 5400-RPM
BarraCuda consumer line. Seagate added SMR to this model without initially disclosing it; it
was identified in the 2020 industry-wide SMR disclosure episode and independently measured.

Why it matters here:

- SMR writes overlap adjacent tracks. Writes land first in a small CMR cache zone, then are
  re-shingled in the background. **Once the cache is exhausted, sustained write throughput
  collapses** — measured drops to a small fraction of nominal, sometimes for tens of minutes.
- Any write pattern that is not large, sequential and well-spaced is pathological. Fine-tuning
  checkpoint churn is exactly that pattern.
- Seagate rates it at "up to 190 MB/s" sustained transfer at the outer diameter. That is a
  **vendor maximum, not a measurement**, and it is a read figure — the drive's sustained
  *write* rate after media-cache exhaustion is not published, and field reports for this model
  record collapse to single-digit MB/s during re-shingling.
- Even at the vendor read figure it is a 5400-RPM mechanical disk, roughly **38× slower than
  the SN850X** on published sequential specs.

**Disposition:** cold archive only. Never a download target, never a model store, never a
checkpoint destination.

### 1.4 Finding — device names are unsafe on this host, serials are not

The enumeration change recorded in `discovery.md` is not hypothetical risk; it already
happened on this machine. Consequences for any storage work:

1. Every persistent mount must use `UUID=` — already required by contract §10.2, and now with
   host-specific evidence behind it.
2. **Identifying which physical drive is the spare requires the serial, not the device name.**
   The target for the model store is the SN850X with serial `250816800905`. Confirm with
   `lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS,TRAN` immediately before any
   partitioning command — never from a remembered `/dev/nvmeXn1` path.
3. A script that partitions `/dev/nvme1n1` by name could, after a reboot or firmware change,
   be pointed at the root device. This is the single highest-consequence hazard in the whole
   proposal.

---

## 2. How the runtimes actually use disk

Vendor-documented behaviour. This determines the space budget and the layout.

### 2.1 Ollama

- **Default store:** `/usr/share/ollama/.ollama/models` on Linux; the service runs as the
  `ollama` user.
- **Relocated by:** `OLLAMA_MODELS=<dir>`, with `chown -R ollama:ollama <dir>`.
- **Layout:** content-addressed. `blobs/sha256-<digest>` holds weights; `manifests/` holds the
  model metadata tree.
- **Download:** partial blobs are written into the same `blobs/` directory and promoted by
  rename on completion. Source and destination are the same filesystem, so promotion is an
  atomic `rename(2)` — **no copy, no double space**.

### 2.2 Hugging Face Hub (used by vLLM and by any fine-tuning tooling)

- **Default cache:** `~/.cache/huggingface/hub`.
- **Relocated by:** `HF_HOME=<dir>` (moves everything) or `HF_HUB_CACHE=<dir>` (hub cache only).
- **Layout:** per-repo directories `models--Qwen--Qwen3.8-27B/` containing `blobs/` (content
  addressed), `snapshots/<revision>/` (**symlinks into `blobs/`**), `refs/`, `trees/`.
- **Download:** in-progress files are `.incomplete` blobs inside `blobs/`, promoted in place.
  Again same-filesystem — **no 2× staging requirement**.
- **Symlink dependency:** `snapshots/` are symlinks. On a filesystem without symlink support
  the library falls back to **copying**, which doubles the footprint. ext4 supports symlinks,
  so this is a non-issue for the proposed layout — but it is a real trap if the store is ever
  moved to an exFAT/NTFS volume or certain network mounts.
- **Two genuine 2× paths do exist**, and neither is the cache: `huggingface-cli download
  --local-dir` and vLLM's `--download-dir` both **copy out of** the cache into a second
  location. Prefer letting the runtime read from the cache directly; if a local directory is
  required, budget for both copies.
- Stale `.incomplete` files are reclaimed with `hf cache prune`.

### 2.3 Runtime access pattern

| Runtime | Load behaviour | Storage implication |
|---|---|---|
| Ollama / llama.cpp | **`mmap`s the GGUF**; pages fault in on demand and are cached by the kernel | With 128 GB RAM the ~17 GB file is likely to remain cached **absent memory pressure** — page-cache pages are clean and LRU-evictable, and a fine-tuning run on this host would evict them. Storage speed governs **cold start only**. |
| vLLM | **`mmap`s the safetensors shards** (safetensors is a zero-copy mmap format) and copies tensors into VRAM; the mapping is released after load | Page cache still warms; same conclusion. |

Two honest qualifications. Nothing *pins* page cache — "stays cached indefinitely" would be too
strong. And with `OLLAMA_KEEP_ALIVE=-1` (§3.6) the weights are resident in **VRAM** anyway, so
page-cache residency only shortens a reload after an explicit unload — which that setting exists
to prevent. The two arguments are not independent supports; the keep-alive setting largely
supersedes the page-cache one.

**Derived cold-start comparison** for a ~17 GB artifact. These are **device-bandwidth floors
from published sequential specs, not measured load times** — real load is additionally bounded
by page-fault handling and host-to-VRAM transfer, and will run several times the NVMe figure
(order 10–20 s in practice). The ratio is between device specs only:

| Device | Sequential read | Cold load |
|---|---|---|
| WD_BLACK SN850X (PCIe 4 NVMe) | ~7,300 MB/s | **~2.3 s** |
| ST8000DM004 (SMR, 5400 RPM) | ~190 MB/s | **~89 s** |

The 128 GB of RAM makes this a *first-load-only* penalty — but it also argues directly for a
long `OLLAMA_KEEP_ALIVE` and against frequent unload/reload cycles, which discard both the page
cache and (per the companion inference-performance record) the prefix cache.

### 2.4 The download bottleneck is the network, not the disk

hxs-1 has a single **1 Gb/s** link — roughly 110 MB/s sustained in practice.

| Artifact | Est. size | Download time @ ~110 MB/s | Write time to NVMe |
|---|---|---|---|
| GGUF Q4_K_M | ~17 GB | **~2.6 min** | ~2.6 s |
| vLLM w4a16 / AWQ | ~30 GB (est., unverified) | **~4.5 min** | ~4.5 s |
| HF BF16 safetensors (fine-tune base) | ~54 GB | **~8.2 min** | ~8.2 s |

<small>Write times use the SN850X's ~6,600 MB/s sequential **write** rating, not its 7,300 MB/s
read rating. Order-of-magnitude only.</small>

The NVMe absorbs writes roughly **60–70× faster** than the NIC delivers them (SN850X sequential
write ~6,600 MB/s against ~110 MB/s of wire). **Optimising download storage is pointless; the
link is the constraint.**

Note also that `HF_HUB_ENABLE_HF_TRANSFER` is **deprecated** — Hub transfers now go through the
Xet backend (`hf-xet`) by default. Either way, transfer parallelism buys little against a 1 Gb/s
ceiling. Xet's chunk cache (`HF_XET_CACHE`) is disabled by default and lives under `HF_HOME`, so
the §3.6 wiring already contains it if it is ever enabled.

**The tempting corollary does not hold.** It is easy to reason that the SMR drive at
"~190 MB/s" would also out-run a 1 Gb/s link on a single clean download — but 190 MB/s is
Seagate's max-OD *read* rating, silently reused as a write figure. A 17–54 GB download exhausts
a DM-SMR media cache many times over, and §1.3 already records that sustained write throughput
collapses once it does. **The SMR drive is disqualified as a download target on the initial
pull as well, not only on repeated writes.**

---

## 3. Proposed storage design

**Status: proposal.** Phase 3 authorizes no storage mutation. Commands are given so that the
proposal is concrete and reviewable, not because it is cleared to run.

### 3.1 Device assignment

| Device | Serial | Role | Rationale |
|---|---|---|---|
| `nvme0n1` (root) | `250816800073` | **OS only** | Keep model artifacts off `/` entirely |
| `nvme1n1` | `250816800905` | **Model store** → `/srv/hx/models` | Matched PCIe 4 NVMe; fast cold start; isolates model I/O from OS and journal |
| `sda` | `ZR1682F1` | **Cold archive** → `/srv/hx/archive` | SMR: acceptable for write-once/read-rarely; unfit for anything else |

### 3.2 Why not simply use the root filesystem

Root has 3.6 TB free at 1% used, so capacity alone would permit it. Four reasons not to:

1. **Blast radius.** A runaway download, a checkpoint loop, or an unpruned HF cache that fills
   `/` takes the host down. On a machine with no BMC, that means physical access to recover.
   A separate filesystem bounds the failure to the model store.
2. **`hx-capacity-gate.ps1` already gates on free space.** It applies a `minimum_free_gb`
   storage gate before authorizing a model download. Pointing that at a dedicated filesystem
   makes the check meaningful; pointing it at `/` conflates OS headroom with model capacity.
3. **I/O isolation.** Model reads on a separate device do not contend with the root filesystem's
   journal and OS writes.
4. **Lifecycle.** A model store is disposable and re-downloadable; the OS volume is not. Keeping
   them separate lets each be wiped, resized, or backed up on its own terms.

### 3.3 Partition and filesystem plan — `nvme1n1`

§1.4 calls mis-targeting the wrong NVMe "the single highest-consequence hazard in the whole
proposal." A comment is not a mitigation against `parted -s`, which suppresses every prompt —
so the serial check below is **machine-enforced**, and the device name is derived, never typed.

```bash
# 0. RESOLVE THE DEVICE FROM ITS SERIAL, AND REFUSE TO PROCEED OTHERWISE.
TARGET_SERIAL=250816800905                       # WD_BLACK SN850X, the spare NVMe
DEV=$(lsblk -dno NAME,SERIAL | awk -v s="$TARGET_SERIAL" '$2==s{print "/dev/"$1}')
[ "$(printf '%s\n' "$DEV" | grep -c .)" -eq 1 ] && [ -n "$DEV" ] \
  || { echo "FATAL: serial $TARGET_SERIAL resolved to zero or multiple devices"; exit 1; }
[ -z "$(lsblk -no FSTYPE,PTTYPE,MOUNTPOINTS "$DEV" | tr -d ' \n')" ] \
  || { echo "FATAL: $DEV is not blank — refusing"; exit 1; }
echo "Resolved $TARGET_SERIAL -> $DEV"
lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS,TRAN "$DEV"

# 1. GPT label, single partition spanning the device.
#    On a GPT label parted REQUIRES a partition name; `ext4` here only sets the
#    partition type code — it creates no filesystem.
sudo parted -s "$DEV" mklabel gpt
sudo parted -s -a optimal "$DEV" mkpart hx-models ext4 0% 100%

# 2. ext4: zero reserved blocks, large-file inode ratio, labelled
sudo mkfs.ext4 -m 0 -T largefile -L hx-models "${DEV}p1"

# 3. Capture the UUID — this, not the device name, goes in fstab
sudo blkid -s UUID -o value "${DEV}p1"
tune2fs -l "${DEV}p1" | grep -E 'Inode count|Reserved block count|Filesystem volume name'
```

**And the archive drive**, which §3.4 mounts and therefore must exist:

```bash
TARGET_SERIAL=ZR1682F1                           # ST8000DM004-2U91, the SMR archive disk
DEV=$(lsblk -dno NAME,SERIAL | awk -v s="$TARGET_SERIAL" '$2==s{print "/dev/"$1}')
[ "$(printf '%s\n' "$DEV" | grep -c .)" -eq 1 ] && [ -n "$DEV" ] \
  || { echo "FATAL: serial $TARGET_SERIAL resolved to zero or multiple devices"; exit 1; }
[ -z "$(lsblk -no FSTYPE,PTTYPE,MOUNTPOINTS "$DEV" | tr -d ' \n')" ] \
  || { echo "FATAL: $DEV is not blank — refusing"; exit 1; }
sudo parted -s "$DEV" mklabel gpt
sudo parted -s -a optimal "$DEV" mkpart hx-archive ext4 0% 100%
sudo mkfs.ext4 -m 0 -T largefile -L hx-archive "${DEV}1"
sudo blkid -s UUID -o value "${DEV}1"
```

**Filesystem choice — ext4.** It matches root, it is the Ubuntu 24.04 default, and it is the
boring option for a workload that is overwhelmingly large sequential reads of immutable files.
XFS has a modest edge on very large files and parallel I/O and would be a defensible
alternative; it is not worth introducing a second filesystem type on this host for the
difference.

**`-m 0` is a deliberate choice.** ext4 reserves 5% of the filesystem for root by default. On a
3.6 TiB data volume that is **~184 GiB withheld for a purpose that does not apply here** — the
reservation keeps root-owned daemons writable when a *root* filesystem fills, and stops
unprivileged users exhausting it. Neither applies to a dedicated model store. The residual
trade-off is slightly less allocator headroom near full, which is low-risk for a few hundred
large immutable files. (Leaving 1% would be a reasonable conservative variant.)

**`-T largefile` is the larger win, and it is easy to miss.** `mkfs.ext4` defaults to one inode
per 16 KiB, which on 3.6 TiB allocates ~236 million inodes and **~60 GB of inode tables** — for
a store that will hold a few hundred multi-gigabyte files. `-T largefile` (one inode per 1 MiB)
yields ~3.7 M inodes for under 1 GB of tables, recovering **~59 GB**. `largefile4` recovers
marginally more but is too aggressive if the HF cache ever holds many small config, tokenizer,
or dataset files. Verify with `tune2fs -l` that the inode count comfortably exceeds the expected
file count before committing. The same applies with more force to the 7.3 TB archive drive:
under the default 16 KiB ratio the inode tables would be ~114 GB, and even the `big` class
(32 KiB inode ratio in `mke2fs.conf`) would still allocate ~57 GB — against ~1.8 GB under
`-T largefile`, recovering ~55 GB over `big` and ~112 GB over the default.

### 3.4 Mount configuration

`/etc/fstab` — **by UUID**, per contract §10.2 and the enumeration evidence in §1.4:

```
UUID=<uuid-of-nvme1n1p1>  /srv/hx/models  ext4  defaults,noatime,nofail,x-systemd.device-timeout=10s  0  2
UUID=<uuid-of-sda1>       /srv/hx/archive ext4  defaults,noatime,nofail,x-systemd.device-timeout=10s  0  2
```

| Option | Why |
|---|---|
| `noatime` | Eliminates atime updates entirely. **The benefit here is small, not large** — Ubuntu already defaults to `relatime` (at most one atime write per file per 24 h), and faulting pages of an already-`mmap`ed region updates no atime at all: `file_accessed()` fires once at `mmap()` time, not per fault. Kept as a cheap, conventional default for a store of immutable large files, not as a performance measure. |
| **`nofail`** | **The critical one.** Without it, a failed or absent data disk drops the host into emergency mode at boot. hxs-1 has **no BMC and no out-of-band access** — recovery would require physically attending the machine. `nofail` degrades to a missing mount instead of a dead host. |
| `x-systemd.device-timeout=10s` | Bounds boot delay if the device is genuinely gone, rather than waiting out the default timeout. |
| fsck pass `2` | Checked after root, not in parallel with it. |
| *not* `discard` | Ubuntu enables `fstrim.timer` weekly, which is the preferred pattern. Inline discard adds latency to every delete. |

**A caveat `nofail` introduces.** If the mount fails, the mountpoint directory still exists on
the root filesystem and `OLLAMA_MODELS` still points at it — so the runtime would cheerfully
re-download 17–54 GB onto `/`, which is precisely the runaway-fills-root scenario §3.2 exists to
prevent. `nofail` converts a loud boot failure into a silent wrong-disk failure. Two mitigations,
both cheap: bind the service to the mount (§3.6), and make the bare mountpoint unwritable so a
stray write cannot succeed.

**Create and mount first, and validate before rebooting** — contract §10.4:

```bash
sudo mkdir -p /srv/hx/models /srv/hx/archive
sudo mount -a
findmnt --verify
findmnt /srv/hx/models
df -hT /srv/hx/models
```

Then make the bare mountpoint immutable: unmount the mounted filesystem, apply `chattr +i` to the
bare mountpoint, and remount. The immutable flag lands on the underlying directory, and the mount
itself is unaffected:

```bash
sudo umount /srv/hx/models
sudo chattr +i /srv/hx/models     # bare mountpoint on / becomes immutable
sudo mount /srv/hx/models         # the mount itself is unaffected
```

### 3.5 Directory layout and ownership

```
/srv/hx/models/                     <- nvme1n1p1, label hx-models
├── ollama/                         <- OLLAMA_MODELS         owner ollama:ollama
│   ├── blobs/                         sha256-<digest> weight blobs
│   └── manifests/
├── hf/                             <- HF_HOME               owner <serving user>
│   └── hub/                        <- HF_HUB_CACHE
│       └── models--Qwen--Qwen3.8-27B/
│           ├── blobs/                 content-addressed
│           ├── snapshots/<rev>/       symlinks into blobs/
│           └── refs/
└── staging/                        <- optional: checksum verification before promotion

/srv/hx/archive/                    <- sda1, SMR: cold only
├── datasets/                          write-once, read-rarely
└── snapshots/                         retired artifacts
```

**Path choice.** `/srv` is the FHS location for site-specific data served by the system, which
is what model weights consumed by an inference service are. `/opt/hx` or `/var/lib/hx` are
defensible alternatives; the important property is that it is **one documented path**, not the
runtime defaults scattered across `/usr/share` and `$HOME`.

```bash
sudo mkdir -p /srv/hx/models/{ollama,hf/hub,staging}

# The `ollama` system user is created by the Ollama installer. This step therefore
# runs AFTER the runtime is installed, not before — guard it rather than assume it.
id ollama >/dev/null 2>&1 \
  || { echo "FATAL: ollama user absent — install the runtime before this step"; exit 1; }
sudo chown -R ollama:ollama /srv/hx/models/ollama
sudo chmod 0750 /srv/hx/models/ollama

# The HF cache needs its own owner — whichever service account runs vLLM or the
# fine-tuning tooling. Left root-owned, a non-root serving user cannot write to it.
sudo chown -R "${HX_SERVING_USER:?set to the serving account}":"${HX_SERVING_USER}" \
  /srv/hx/models/hf
```

### 3.6 Environment wiring

Ollama, via a systemd drop-in rather than an edited unit file (survives package upgrade):

```ini
# /etc/systemd/system/ollama.service.d/10-hx.conf
[Unit]
# Refuse to start if the model store is not mounted — see the nofail caveat in §3.4.
RequiresMountsFor=/srv/hx/models

[Service]
Environment="OLLAMA_MODELS=/srv/hx/models/ollama"
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="OLLAMA_KEEP_ALIVE=-1"
```

A drop-in has no effect until reloaded, and the unit must be restarted to pick it up:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
systemctl show ollama -p Environment      # confirm OLLAMA_MODELS took effect
```

Note that repointing `OLLAMA_MODELS` at an empty directory makes any previously pulled models
invisible — they must be moved or re-pulled.

`OLLAMA_HOST` stays on loopback: Ollama has **no authentication of any kind**, and the fleet's
standing position (`act-017`) is that Qwen remains loopback-bound with remote consumption only
through a gateway. `OLLAMA_KEEP_ALIVE=-1` holds the model resident, preserving both VRAM
residency and the prefix cache — see the companion inference-performance record.

For Hugging Face tooling, set in the service environment rather than a user profile:

```
HF_HOME=/srv/hx/models/hf
HF_HUB_CACHE=/srv/hx/models/hf/hub
```

### 3.7 Space budget

| Artifact | Estimated size | Notes |
|---|---|---|
| Qwen3.8-27B GGUF Q4_K_M | ~16–17 GB | primary inference artifact |
| Alternate quant tiers (Q3_K_M / Q5_K_M / Q8_0) | ~13 / ~19 / ~29 GB | only if comparison testing is wanted |
| HF BF16 safetensors | ~54 GB | fine-tuning base; not needed for inference |
| vLLM w4a16 / AWQ | ~30 GB | **estimate, unverified** — see hypothesis H8 in the companion record |
| LoRA adapters | <1 GB each | |
| Fine-tune checkpoints | highly variable | the genuinely unbounded item |
| Datasets | variable | candidate for `/srv/hx/archive` |

Realistic inference-only footprint: **well under 200 GB against 3.6 TiB.** Capacity is not a
constraint and will not become one for inference. Set `minimum_free_gb` in
`hx-capacity-gate.ps1` generously — 200 GB is defensible — so the gate catches a genuinely
degenerate condition rather than firing on normal growth.

Fine-tuning is the exception. Checkpoint retention is the one workload here that can consume
terabytes, and it needs its own retention policy before it starts, not after.

---

## 4. Risks and open conflicts

### R-1 — The R5 NFS proposal directly competes for this device

`hx-recommendations.html` R5 proposes exporting hxs-1's unallocated NVMe **and** the 7.3 TB HDD
as fleet NFS. That is the same `nvme1n1` this proposal assigns to the model store. R5 also
carries its own recorded caution:

> "hxs-1 is the reasoning GPU host, so making it the fleet's NFS server puts an I/O dependency
> on the most performance-critical machine."

Two further points argue against overlapping them:

- **Do not serve model weights over NFS at runtime on this host.** The binding constraint is the
  single 1 Gb/s NIC: a 17 GB cold load is ~2.6 minutes of wire time on the same interface
  serving inference requests, versus seconds from local NVMe. (`mmap` over NFS additionally has
  weak cache-coherence semantics — though that matters far less for immutable, digest-verified
  weight files than the bandwidth ceiling does, and plenty of clusters do serve weights over
  network filesystems successfully.)
- If fleet NFS is still wanted from this host, export **`/srv/hx/archive` (the SMR drive) only**
  — cold, write-once fleet data is the one workload SMR suits.

**This is an owner decision, not a technical one.** It should be settled before either
proposal is actioned, because they cannot both have `nvme1n1`.

### R-2 — No redundancy, and two different kinds of data

No RAID, no LVM, no backup path. That is **acceptable for model weights** — they are
re-downloadable, and the artifact is verified by digest. It is **not acceptable for
fine-tuning checkpoints and curated datasets**, which are the product of compute and human
effort and cannot be re-fetched from anywhere.

Any fine-tuning work needs a stated backup destination before the first run, not after the
first loss. This distinction should be explicit in whatever storage decision is ratified.

### R-3 — SMART is absent on the drives about to become load-bearing (R1)

> "Not one drive in the fleet has SMART monitoring. `smartmontools` is absent on all sixteen
> machines."

Installing `smartmontools` and establishing a baseline should precede committing terabytes to
these devices — particularly the SMR drive, which is consumer-grade, mechanical, unredundant,
and the least healthy device in the host. This is cheap, low-risk, and independently
recommended already.

### R-4 — Residual observations

- **`multipathd` and `open-iscsi` are enabled** on bare metal, inherited from a
  virtualization-oriented image. `multipathd` can claim block devices under some
  configurations. Confirm it is not managing these NVMe devices before partitioning
  (`multipath -ll`), and consider disabling both as unused services.
- **Non-ECC RAM with a large page cache.** 128 GB of non-ECC memory will hold model weights in
  page cache. Bit flips are possible and undetectable. Impact is low for inference — a
  corrupted page produces a bad token, and the file re-reads clean — but it is worth stating
  rather than discovering.
- **Partitioning is a §14 high-impact change.** `INFRASTRUCTURE-CONTRACT.md` §10.5 states
  automation must not repartition disks or create filesystems without explicit approval, and
  §14 lists partition changes among operations requiring inspection, backup, validation and
  rollback planning. The devices are unpartitioned and unused, which makes the risk low — but
  the procedure still applies, and §1.4's device-naming hazard is exactly why.

---

## 5. Answering the question directly

**How should the model be stored during download?**

On the dedicated NVMe model store, downloaded **in place** by the runtime's own client. Both
Ollama and Hugging Face use content-addressed layouts that write partial files into the final
directory and promote them atomically on the same filesystem — **no separate staging area and
no 2× space provisioning is needed**. Do not download to `/tmp`, to `/`, or to the SMR drive
and then move; a cross-filesystem move is a copy, and it buys nothing. Verify the artifact
digest before first load, and let `hx-capacity-gate.ps1` clear free space before the download
is authorized at all.

**How should the model be stored at runtime?**

In exactly the same place. There is no separate runtime copy. Ollama `mmap`s the GGUF directly
from the store; vLLM reads the safetensors once into VRAM. With 128 GB of host RAM the file
becomes page-cache resident after the first load, so runtime disk performance stops mattering
almost immediately — which is precisely why the design should optimise for **cold start and
safety** (fast NVMe, isolated filesystem, `nofail`, `noatime`) rather than for sustained
throughput. Keep the model resident (`OLLAMA_KEEP_ALIVE=-1`) so that neither the page cache nor
the prefix cache is discarded between requests.

---

## 6. Recommended next steps

Phase-3-safe items first; nothing below assumes authorization it does not have.

1. **Resolve the R5 conflict.** Owner decision: does `nvme1n1` become the hxs-1 model store, or
   fleet NFS? They cannot both have it. Documentation-only.
2. **Capture a storage baseline** on hxs-1, read-only, to append to `driver-results.md` or a new
   evidence file:
   ```bash
   lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS,TRAN
   sudo blkid
   findmnt --verify
   df -hT
   # NB: `multipath` requires root. Run unprivileged with stderr discarded, it fails
   # into a FALSE all-clear — the one outcome this check exists to rule out.
   sudo multipath -ll || echo "multipath: command failed or no maps — check exit status"
   sudo multipath -ll -v3 2>&1 | grep -Ei 'nvme|sda' || echo "no nvme/sda paths claimed"
   ```
3. **Install `smartmontools` and take a baseline** (R1) before any device becomes load-bearing.
   A small, independently-recommended change — but still a package install, so it belongs in
   the same authorization request as the rest.
4. **Set `minimum_free_gb`** in `hx-capacity-gate.ps1` against the proposed model-store path.
   Repository-side, no host access.
5. **Decide the fine-tuning retention and backup policy** before any fine-tuning run — the one
   workload here that is neither bounded nor re-downloadable.
6. **When implementation is authorized,** execute §3.3–§3.6 in order, confirming device identity
   by **serial** at every step, validating with `findmnt --verify` before reboot.

---

## 7. Citation

**Primary — HX records**
`servers/hxs-1/discovery.md` (block devices, serials, filesystems, enumeration change, RAM,
network, enabled units) · `INFRASTRUCTURE-CONTRACT.md` §10.1–§10.5, §14 ·
`governance/hx-recommendations.html` R1, R5 · `governance/logs/actions-and-issues.md`
(`act-017`) · `tests/ai-runtime/hx-capacity-gate.ps1`

**Vendor — retrieved 2026-08-17**
- Ollama FAQ — `OLLAMA_MODELS`, service user and ownership, environment variables
  <https://docs.ollama.com/faq>
- Hugging Face Hub — cache layout, blobs/snapshots/refs, `.incomplete` handling, `HF_HOME`
  <https://huggingface.co/docs/huggingface_hub/en/guides/manage-cache>

**Third-party — drive characteristics**
- Tom's Hardware, *Seagate BarraCuda 8TB HDD Review: The SMR Slowdown* — ST8000DM004 SMR
  identification and 5400-RPM confirmation. **Sourcing caveat:** the review reports Seagate's
  "up to 190 MBps" rating and cautions that it may be misleading given SMR degradation; it
  publishes no independent sequential-read measurement. The 190 MB/s figure used in §1.3 and
  §2.3 is a **vendor max-OD sustained-transfer specification, not a measurement**.
- Blocks & Files, *Seagate 'submarines' SMR into 3 Barracuda drives* — SMR disclosure record
- Western Digital — WD_BLACK SN850X 4 TB specification: 7,300 MB/s sequential read,
  6,600 MB/s sequential write, PCIe Gen4 ×4

Sequential-throughput figures for both devices are vendor-published values used only for
order-of-magnitude comparison. **Neither has been measured on hxs-1**, and no figure in this
document should be quoted as an HX measurement.

---

*Prepared by Claude (Opus 5), 2026-08-17. Design proposal — no authority asserted, no decision
made, no storage mutation authorized. Per repository convention, a proposal is not a ruling.*
