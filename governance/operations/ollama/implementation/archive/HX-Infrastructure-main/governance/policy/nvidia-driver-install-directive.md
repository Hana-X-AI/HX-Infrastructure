# NVIDIA Driver Install Directive

## Scope

Install and validate the NVIDIA driver on:

- `hxs-2`
- `hxs-3`

This directive is **driver-only**.

After the NVIDIA driver is installed and validated, **STOP**.

## Required Driver

Claude must use this driver explicitly on both servers:

```text
nvidia-driver-580-server-open
```

Install the matching userspace utilities:

```text
nvidia-utils-580-server
```

Do not substitute another NVIDIA driver branch, including `595`, `610`, non-server, or non-open variants.

Use:

```bash
sudo apt update
sudo apt install -y nvidia-driver-580-server-open nvidia-utils-580-server
```

Reboot after installation:

```bash
sudo reboot
```

## Validation

After each server returns, verify:

```bash
nvidia-smi
```

Then:

```bash
nvidia-smi --query-gpu=index,name,pci.bus_id,driver_version,memory.total --format=csv
```

Verify the NVIDIA kernel driver is bound:

```bash
lspci -nnk | grep -A4 -Ei 'vga|3d|display'
```

Expected for every GPU:

```text
Kernel driver in use: nvidia
```

Verify the installed NVIDIA module:

```bash
modinfo nvidia | grep -E '^(version|license):'
```

## Success Criteria

The driver task is complete only when:

- `hxs-2` exposes both expected GPUs through `nvidia-smi`.
- `hxs-3` exposes both expected GPUs through `nvidia-smi`.
- Each GPU reports its model, PCI bus ID, driver version, and VRAM.
- `lspci -nnk` reports `Kernel driver in use: nvidia` for every GPU.
- No GPU is left bound to `nouveau`.
- No NVIDIA driver initialization failure is present.

## Hard Stop

Once the driver is installed and validated, **STOP**.

Do **not** install, configure, initialize, or test any of the following:

- vLLM
- PyTorch
- CUDA Toolkit
- CUDA development packages
- `uv`
- Conda
- Python virtual environments for vLLM
- Hugging Face CLI
- Hugging Face tokens
- model files
- model caches
- inference services
- systemd services for vLLM
- vLLM API keys
- tensor-parallel configuration
- multi-GPU workload configuration
- inference containers or container runtimes

Do not test a model.

Do not make any vLLM-specific configuration changes.

The only objective of this directive is:

```text
Ubuntu
  -> install nvidia-driver-580-server-open
  -> install nvidia-utils-580-server
  -> reboot
  -> validate nvidia-smi
  -> confirm all GPUs use the nvidia driver
  -> STOP
```
