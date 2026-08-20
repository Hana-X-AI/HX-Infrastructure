# HXS-1 MVP-1 execution runbook

**Execution point:** `hxs-cp` repository checkout  
**Remote user:** `hxsa`  
**Remote host:** `192.168.50.200`  
**Timebox:** 8 hours

## Blocking decisions

None.

## 1 — Start execution and validate the repository

**Owner:** Meta-Agent

```bash
date -Is
bash tests/repository/validate.sh
bash platform/hxs-cp/bin/hx-library.sh sync ollama
bash platform/hxs-cp/bin/hx-library.sh verify ollama
```

**Expected:** repository validator prints `PASS`; Ollama source reports commit `d67ad83426633195089509347ffd4fe795120198` and tag `v0.32.14`.

**If different:** stop. Repair the local repository/library before contacting HXS-1.

## 2 — Verify host, driver, GPU UUIDs and PCIe links

**Owner:** Owen

```bash
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' | tee evidence/hxs-1/mvp-1/owen-host-preflight.txt
set -euo pipefail
test "$(hostname)" = "hxs-1"
nvidia-smi --query-gpu=index,uuid,name,memory.total,pci.bus_id,driver_version --format=csv
test "$(nvidia-smi --query-gpu=uuid --format=csv,noheader | wc -l)" -eq 2
test "$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | sort -u)" = "580.173.02"
for bdf in 02:00.0 81:00.0; do
  echo "=== $bdf ==="
  sudo lspci -vvs "$bdf" | grep -E 'LnkCap:|LnkSta:'
done
REMOTE
```

**Expected:** hostname `hxs-1`; two RTX 4070 Ti SUPER rows; two non-empty GPU UUIDs; driver `580.173.02`; GPU0 `LnkCap`/`LnkSta` includes x16 capability; GPU1 evidence includes x16 capability and the observed negotiated width.

**If different:** stop. Do not change the driver or PCIe configuration. Record the mismatch for the owner.

## 3 — Resolve and mount the spare NVMe by serial

**Owner:** Owen

```bash
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' | tee evidence/hxs-1/mvp-1/owen-storage-result.txt
set -euo pipefail
TARGET_SERIAL=250816800905
ROOT_PART=$(findmnt -n -o SOURCE /)
ROOT_PARENT="/dev/$(lsblk -n -o PKNAME "$ROOT_PART")"
TARGET_DISK=$(lsblk -dnpo NAME,SERIAL,TYPE | awk -v serial="$TARGET_SERIAL" '$2==serial && $3=="disk" {print $1}')
test -n "$TARGET_DISK"
test "$TARGET_DISK" != "$ROOT_PARENT"
test "$(printf '%s\n' "$TARGET_DISK" | wc -l)" -eq 1
if lsblk -nrpo TYPE,MOUNTPOINT "$TARGET_DISK" | awk '$1=="part" || $2!="" {bad=1} END{exit !bad}'; then
  echo "STOP: target disk already has a partition or mount" >&2
  exit 20
fi
if sudo wipefs -n "$TARGET_DISK" | grep -q .; then
  echo "STOP: target disk contains a filesystem signature" >&2
  exit 21
fi
command -v parted >/dev/null || { sudo apt-get update; sudo apt-get install -y parted; }
sudo parted --script "$TARGET_DISK" mklabel gpt mkpart primary ext4 1MiB 100%
sudo partprobe "$TARGET_DISK"
sudo udevadm settle
TARGET_PART=$(lsblk -nrpo NAME,TYPE "$TARGET_DISK" | awk '$2=="part" {print $1; exit}')
test -n "$TARGET_PART"
sudo mkfs.ext4 -L hx-ai "$TARGET_PART"
FS_UUID=$(sudo blkid -s UUID -o value "$TARGET_PART")
test -n "$FS_UUID"
sudo mkdir -p /srv/hx-ai
grep -q "UUID=$FS_UUID[[:space:]]\+/srv/hx-ai" /etc/fstab || echo "UUID=$FS_UUID /srv/hx-ai ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab >/dev/null
sudo mount /srv/hx-ai
findmnt /srv/hx-ai
lsblk -o NAME,SERIAL,SIZE,FSTYPE,LABEL,MOUNTPOINT "$TARGET_DISK"
REMOTE
```

**Expected:** serial `250816800905` resolves to exactly one non-root NVMe; `/srv/hx-ai` is ext4, label `hx-ai`, and mounted by UUID.

**If different:** the script stops before mutation on identity/signature failures. Do not substitute a device name or clear signatures.

## 4 — Install pinned Ollama

**Owner:** Craig

```bash
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' | tee evidence/hxs-1/mvp-1/craig-ollama-version.txt
set -euo pipefail
curl -fsSL https://ollama.com/install.sh -o /tmp/ollama-install.sh
sudo env OLLAMA_VERSION=0.32.14 sh /tmp/ollama-install.sh
ollama --version
REMOTE
```

**Expected:** version output contains `0.32.14` and the installer creates the `ollama` service/user.

**If different:** stop. Do not continue with another Ollama version.

## 5 — Configure storage, loopback, context, flash attention and GPU UUIDs

**Owner:** Craig

```bash
GPU_UUIDS=$(ssh hxsa@192.168.50.200 "nvidia-smi --query-gpu=uuid --format=csv,noheader | paste -sd, -")
test "$(printf '%s' "$GPU_UUIDS" | tr -cd ',' | wc -c)" -eq 1
sed "s|__GPU_UUIDS__|$GPU_UUIDS|" platform/hxs-1/ollama/ollama.service.d/override.conf.template > /tmp/hx-ollama-override.conf
scp /tmp/hx-ollama-override.conf hxsa@192.168.50.200:/tmp/hx-ollama-override.conf
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' | tee evidence/hxs-1/mvp-1/craig-service-state.txt
set -euo pipefail
sudo install -d -o ollama -g ollama -m 0750 /srv/hx-ai/ollama/models
sudo install -d -m 0755 /etc/systemd/system/ollama.service.d
sudo install -o root -g root -m 0644 /tmp/hx-ollama-override.conf /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl enable --now ollama
sudo systemctl restart ollama
systemctl is-active ollama
ss -ltnp | grep '127.0.0.1:11434'
curl -fsS http://127.0.0.1:11434/api/version
REMOTE
```

**Expected:** service is `active`; only `127.0.0.1:11434` listens; API version is `0.32.14`; model directory is owned by `ollama`.

**If different:** collect `sudo journalctl -u ollama -n 200 --no-pager`, stop and return the defect to Craig.

## 6 — Pull and verify the exact model

**Owner:** Quincy

```bash
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' | tee evidence/hxs-1/mvp-1/quincy-model-manifest.txt
set -euo pipefail
ollama pull qwen3.8:27b-q4_K_M
ollama list | grep '^qwen3.8:27b-q4_K_M[[:space:]]\+25b843619e94'
ollama show qwen3.8:27b-q4_K_M
REMOTE
```

**Expected:** the exact tag exists with short digest `25b843619e94`, size approximately 18 GB and quantization Q4_K_M.

**If different:** stop. Do not substitute the bare `27b`, MTP, NVFP4, Q8 or BF16 tag.

## 7 — Send the first explicit request

**Owner:** Quincy

```bash
scp platform/hxs-1/ollama/requests/mvp1-chat.json hxsa@192.168.50.200:/tmp/mvp1-chat.json
ssh hxsa@192.168.50.200 'bash -s' <<'REMOTE' > evidence/hxs-1/mvp-1/quincy-smoke-response.json
set -euo pipefail
curl -fsS http://127.0.0.1:11434/api/chat \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/mvp1-chat.json
REMOTE
grep -q '"done":true' evidence/hxs-1/mvp-1/quincy-smoke-response.json
grep -Eq '"content":"[^"[:space:]]' evidence/hxs-1/mvp-1/quincy-smoke-response.json
grep -q '391' evidence/hxs-1/mvp-1/quincy-smoke-response.json
ssh hxsa@192.168.50.200 'ollama ps; nvidia-smi --query-compute-apps=gpu_uuid,process_name,used_gpu_memory --format=csv'
```

**Expected:** HTTP request succeeds; response has non-empty content, the correct product `391`, and `done:true`; `ollama ps` reports `8192` context and `100% GPU`; both UUIDs show Ollama GPU memory.

**If different:** collect Ollama logs and return the defect to Craig for runtime failures or Quincy for model/request failures.

## 8 — Independently repeat the gate

**Owner:** Tessa

After the isolated DeepSeek profile passes ADR-0004 configuration acceptance, start a new `hx-claude --provider deepseek` process. Tessa repeats steps 6 verification and 7 using the acceptance contract, records exact output plus provider/model metadata in `servers/hxs-1/evidence/<attempt>/tessa-validation.md`, and returns `PASS`, `FAIL` or `BLOCKED` with condition numbers. She must read the retained Kimi-lane handoff and must not rely on private conversation state from that implementation process.

**Expected:** `PASS`.

**If different or provider acceptance is unavailable:** MVP-1 is not done. Return the failed condition to the owning agent, or record `BLOCKED` for an unavailable validation profile; Tessa does not repair it.

## Definition of done

One coherent Qwen response, from the HXS-1 loopback endpoint using the locked model and explicit settings, independently validated by Tessa.

## Later MVPs

- MVP-2 — owner selects the next single improvement after reviewing MVP-1 evidence.
- MVP-3 — owner selects the next single improvement after MVP-2.

## Challenges to owner direction

None.
