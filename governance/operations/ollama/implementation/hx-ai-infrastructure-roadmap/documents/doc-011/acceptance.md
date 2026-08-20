# MVP-1 acceptance contract

## Single gate

`PASS` requires all conditions in the same execution attempt:

1. endpoint is `127.0.0.1:11434`;
2. exact model is `qwen3.8:27b-q4_K_M` with digest `25b843619e94`;
3. the request explicitly sets `think: "medium"` and the locked sampler options;
4. HTTP status is 200;
5. response contains non-empty `message.content`, the correct product `391`, and `done:true`;
6. `ollama ps` reports context `8192` and `100% GPU`;
7. both pinned GPU UUIDs show Ollama memory use;
8. Tessa repeats the request independently from the accepted DeepSeek V4 Pro profile, records provider/model metadata, and records `PASS`.

Any failed condition is `FAIL`. If Tessa's DeepSeek profile has not passed provider configuration acceptance, condition 8 is `BLOCKED`, and MVP-1 is not complete. Tessa returns defects to the owning agent and does not repair them.
