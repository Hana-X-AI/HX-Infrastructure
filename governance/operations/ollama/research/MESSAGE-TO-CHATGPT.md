# Revision directive — HX Qwen3.8-27B on Ollama runbook

The deep-dive is good work. The structure, the agent model, and the evidence discipline are right.
But it is scoped for a programme, and I need an execution plan. Revise it against the following.

---

## 1. The rule I need you to follow from now on

**When I float something that is not on the critical path, kill it. Do not accommodate it, do not
scope it down, do not give it a pilot. Say no and put it in the backlog.**

I need to be precise about this, because the example is mine, not yours. **I raised LM Studio /
Bionic.** I was testing whether you would push back on it. You came back with a "narrow comparison
pilot" — Ollama stopped, distinct storage, distinct port, identical inputs. Carefully bounded,
sensibly reasoned, and **exactly the wrong answer.**

A scoped-down version of a bad idea is worse than the bad idea, because a clean no costs me one
line to read and closes the loop, while a narrow pilot keeps the thing alive at reduced size. It
still needs planning, it still needs a section in the document, it still needs someone to run it,
and it still lands back on my desk as a decision. The compromise is the friction.

**Assume my suggestions are impulses until they survive the critical-path test.** I will float
things. I want you to be the one holding the line — refuse them, name them as backlog, and carry
on. If I want an item pulled forward I will say so explicitly, and then it is in scope. Until
then, treat "the owner mentioned it" as the weakest possible reason to keep something alive.

If you think a direction of mine is genuinely wrong — not a nice-to-have I should drop, but wrong
in a way that will break the build — say so in **one line** at the end under
`Challenges to owner direction`. One line, no section.

---

## 2. The only goal

**Qwen3.8-27B running on HXS-1, from operating system to first message successfully sent and
answered.**

**Deadline: 8 hours. If it is not achieved in that window, we have failed.**

Inside that 8 hours, and counted against it:

- the research required to do it correctly
- standing up the agent team
- deploying that team successfully
- the install itself, end to end

Nothing else is in scope.

---

## 3. Scope discipline — this is a dev/test environment

**I need you to be aggressive about what you cut.**

I have watched days, hours and enormous token spend disappear into hardening, defence-in-depth,
and operational polish on machines that are not carrying production traffic and are not exposed
to anything. **HXS-1 is a dev/test box. Do not harden it. Do not design for failure modes that
cannot occur in a lab.** No threat modelling, no defence-in-depth, no availability engineering,
no capacity planning beyond "does the model fit."

**Everything that is not required to get a first message answered goes to the backlog.** I will
override some backlog items myself and pull them forward. Some I will leave there indefinitely.
That is my call to make, not something to pre-empt by keeping items in scope "just in case."

Apply this test to every task you have written and every task you are about to write:

> **Does the first message fail to send without this?**
> Yes → MVP-1. No → backlog.

There is no third answer. "It's quick" and "it's best practice" are not exceptions.

---

## 4. Structure I want: MVP ladder, not phases

Restructure the whole document around iterative MVPs. HXS-1 progresses one working state at a
time, and each state is provable before the next begins.

**MVP-1 — the only thing that matters right now.** OS to first message. The absolute minimum
configuration set, nothing more. Define "done" as a single concrete, observable event: a prompt
sent to the endpoint returns a coherent response.

**MVP-2, MVP-3, …** — everything else, sequenced, each one small and each one with its own
single definition of done. Do not detail these beyond a title and a one-line outcome. I will
decide what MVP-2 is after MVP-1 is standing, and I will decide it based on what MVP-1 taught us.

Then a **Backlog** section: a flat list, no detail, no estimates, no justification. Just titles,
so I can scan it and pull items forward when I want them.

---

## 5. Format

For MVP-1 I want **task-by-task, step-by-step, in execution order**. For each task:

- the exact command or action
- the expected output, so the operator knows it worked
- what to do if it does not match
- who owns it (agent or human)

Assume the operator is following it literally and in sequence. No task should require a decision
that is not already made in the document. If a decision is genuinely still open, it goes at the
top under `Blocking decisions` — and there should be as few as you can manage.

Cut all prose that is not an instruction. No rationale paragraphs, no trade-off discussion, no
alternatives considered. The reasoning can live in a short appendix if you want it preserved.

---

## 6. Verified constraints — use these, do not re-derive them

These are settled against vendor manifests, official documentation and our own discovery record.
Treat them as given. Do not spend any of the 8 hours re-researching them.

**Host — HXS-1, already true today**

- Ubuntu 24.04.4 LTS, kernel 7.0.0-28-generic. 2× RTX 4070 Ti SUPER, 16,376 MiB each,
  **32,752 MiB total**, Ada, compute capability 8.9.
- **Driver `nvidia-driver-580-server-open` 580.173.02 / CUDA 13.0 is already installed and
  validated.** Do not touch it. Do not upgrade it.
- **No CUDA Toolkit is required. No Python is required. No PyTorch is required.** Ollama is a Go
  binary with its CUDA backend compiled in; the kernel driver is the only NVIDIA dependency. This
  means the driver-only directive does not block anything in MVP-1.
- Root filesystem is 3.6 TB at 1% used. Only TCP 22 is listening.

**Artifact — pin exactly this**

- Use **`qwen3.8:27b-q4_K_M`**, short digest **`25b843619e94`**. 18 GB.
- **Do not use bare `qwen3.8:27b`.** It resolves to digest `22130167c4c2`, which is the
  **MTP variant** — a different artifact at the same size. MTP is an MVP-2 A/B, not a baseline.
- **Do not use `27b-nvfp4`.** It shares a digest with the MLX build, and NVFP4 requires Blackwell
  in any case. Our cards are Ada 8.9.
- Do not use Q8_0 (30 GB) or BF16 (56 GB). Q8_0 leaves 2.2 GB; BF16 does not fit.
- 18 GB **does not fit on a single card** — 16.10 GB usable each. Both GPUs are mandatory.

**Storage**

- Model store goes on the spare NVMe. **Resolve it by serial — `250816800905` — never by device
  name.** NVMe enumeration on this host has already changed once between install and now; the
  root filesystem moved from `nvme1n1` to `nvme0n1`. A script that partitions `/dev/nvme1n1` by
  name could target the root device.
- **`/dev/sda` (ST8000DM004, serial `ZR1682F1`) is an SMR drive.** Do not use it for the model
  store, downloads, or anything write-heavy. Archive only, or leave it alone entirely for MVP-1.
- Downloads are **in place** — no staging area and no 2× space provisioning is needed.
- Keep your `/srv/hx-ai` path. I am adopting it over the alternative.

**Configuration that must be explicit in MVP-1**

- `OLLAMA_HOST=127.0.0.1:11434` — loopback only. Ollama has no authentication of any kind.
- `OLLAMA_CONTEXT_LENGTH` — set it explicitly. Ollama's default is VRAM-tiered and this host sits
  on a boundary; do not leave it implicit. Confirm the effective value with `ollama ps`.
- `OLLAMA_FLASH_ATTENTION=1` is a **prerequisite** for KV cache quantization. If you set
  `OLLAMA_KV_CACHE_TYPE`, flash attention must be on or the setting silently does nothing.
- **Sampler settings — we have never specified these for any model, and the defaults will make
  this one measurably worse.** Set them explicitly:
  - thinking mode: `temperature 1.0, top_p 0.95, top_k 20, min_p 0.0, presence_penalty 0.0`
  - instruct mode: `temperature 0.7, top_p 0.80, top_k 20, min_p 0.0, presence_penalty 1.5`
  - **Reasoning effort defaults to `xhigh`, the most expensive setting.** Set it deliberately.
- Pin GPUs by **UUID, never index** — indexes reorder across reboots.

**Two read-only checks that belong in MVP-1 because they gate it**

1. **Capture the GPU UUIDs.** They have never been recorded for this host, and our fit gate blocks
   without them.
   `nvidia-smi --query-gpu=index,uuid,name,memory.total,pci.bus_id,driver_version --format=csv`
2. **Settle the PCIe link width on GPU1.** Discovery recorded it negotiating **×4** against an
   ×16-capable slot. Link width does not recover under load. Use
   `sudo lspci -vvs <bdf>` and compare `LnkCap` against `LnkSta` — **not**
   `nvidia-smi --query-gpu=pcie.link.width.max`, which reports the device's capability rather than
   the slot's and can leave the question unanswerable.

**Known defect to work around, not solve**

- `iss-015` is open: Ollama silently truncates prompts that exceed the context window rather than
  erroring. Do not attempt to fix this in MVP-1. Set a sane context, note the limitation, move on.

---

## 7. Explicitly out of scope for MVP-1

Send all of these to the backlog with no further discussion:

- **LM Studio / Bionic in any form.** I raised it, and I am killing it. Not a pilot, not a comparison, not a stopped-Ollama trial. Backlog.
- Hardening of any kind — firewall rules, SSH tightening, auth layers, TLS, secrets management.
- Fine-tuning, LoRA, QLoRA, adapters, and every dependency they bring.
- SMART monitoring, backup design, redundancy, RAID.
- NFS export, fleet-shared storage.
- The repeatable HXS-1 → HXS-4 pattern. **One host. HXS-1. Get it working.**
- Vision / multimodal testing.
- MTP A/B, quantization comparison, context-ladder measurement beyond what MVP-1 needs to run.
- Benchmarking and evaluation suites.
- Repository migration, GitHub organisation decisions, branch strategy.
- Acceptance-suite build-out beyond a single pass/fail smoke test.

---

## 8. What I want back

Rewrite the runbook as **HXS-1 MVP-1 Execution Plan**, containing:

1. **Blocking decisions** — anything you genuinely cannot proceed without. Keep it short.
2. **Agent team** — who is needed for MVP-1 only, and what each one owns. If a role is not needed
   to get the first message answered, it is not in MVP-1.
3. **MVP-1 task sequence** — numbered, in execution order, with commands, expected output, and
   failure handling. This is the bulk of the document.
4. **Definition of done** — the single observable event that proves MVP-1.
5. **MVP-2 … MVP-n** — titles and one-line outcomes only.
6. **Backlog** — flat list of titles.
7. **Challenges to owner direction** — one line each, if you have any. Optional.

Assume 8 hours, starting now, including the research and the agent stand-up. If any part of your
plan cannot fit that window, say so plainly at the top rather than shipping a plan that silently
does not fit.
