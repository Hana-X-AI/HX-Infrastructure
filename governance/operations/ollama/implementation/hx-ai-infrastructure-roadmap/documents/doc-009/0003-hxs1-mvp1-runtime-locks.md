# ADR-0003 — HXS-1 MVP-1 runtime locks

**Status:** ACCEPTED FOR MVP-1  
**Date:** 2026-08-18  
**Truth state:** PROPOSED CONFIGURATION; NOT YET AS-BUILT

## Locks

| Concern | MVP-1 value |
|---|---|
| Host | `hxs-1` / `192.168.50.200` |
| Ollama | `v0.32.14`, commit `d67ad83426633195089509347ffd4fe795120198` |
| Model | `qwen3.8:27b-q4_K_M` |
| Manifest | `25b843619e944cd0ae6069f94ff4e5e26a16e109ccbc0a66a0f05979ed70098e` |
| Model store | `/srv/hx-ai/ollama/models` on NVMe serial `250816800905` |
| Listen address | `127.0.0.1:11434` |
| Context | `8192` tokens |
| Flash attention | enabled |
| Thinking effort | `medium` through native `think` |
| Sampler | `temperature=1.0`, `top_p=0.95`, `top_k=20`, `min_p=0.0`, `presence_penalty=0.0` |

## Basis

The exact model manifest requires Ollama `0.32.12` or newer. `v0.32.14` is the current stable release verified on 2026-08-18. An 8K context is the smallest deliberate working envelope selected for MVP-1; larger-context work remains outside this gate.

## Exclusions

The bare `qwen3.8:27b` manifest enables embedded MTP with `draft_num_predict=4` and is not the baseline. No alternate model tag or runtime is permitted in MVP-1.

