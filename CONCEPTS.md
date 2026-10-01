# CONCEPTS.md (The Study Wiki)
Anytime the user learns a new concept, it goes here as a reference.

## Experiment Design (Phase 0)

**Hypothesis before measurement** — writing a prediction ("Q4_K_M cuts size ~70% with under X% quality loss") before running anything is what turns a tutorial into an experiment. It prevents rationalizing whatever numbers come out, and a wrong hypothesis is still a valid, interesting result.

**Controlled experiment** — change one variable (quantization level) and hold everything else fixed: same machine, flags, prompts, driver, nothing else on the GPU. If two things change at once, you can't attribute the difference to either.

**Baseline** — the reference point everything is compared against. For the 3B model it's FP16 (a true "before"). For the 14B model FP16 doesn't fit in 16 GB, so Q6_K is the baseline, and that must be stated because changes are then relative to Q6_K, not the original.

**Repeated runs** — speed varies run to run (clocks, thermals, background load). Running each speed test 3 times and averaging (and noting the spread) separates real differences from noise.

## LLM Concepts

**Quantization** — storing model weights with fewer bits (16 -> 8/5/4/2). Fewer bits means a smaller file and less memory to read per token, at the cost of rounding error in the weights.

**GGUF** — llama.cpp's single-file model format (weights + metadata + tokenizer). HF checkpoints are converted to it with `convert_hf_to_gguf.py`.

**Q-level naming (Q4_K_M etc.)** — the number is roughly bits per weight. `K` means "K-quant" (block-wise scheme with better quality per bit than the older schemes); `S/M/L` is small/medium/large, i.e. how many sensitive tensors get more bits. `Q8_0` and `Q2_K` follow the same idea with different schemes.

**Perplexity** — how "surprised" the model is by real text; lower is better. It's a quick proxy for quality, and comparing it across quantizations of the same model on the same text shows the degradation. It's not a full measure of usefulness (reasoning, instruction-following can differ).

**Tokens/second** — generation speed. Token generation is usually memory-bandwidth-bound, so smaller weights often generate faster, but the gain isn't always proportional to the size reduction.

**Prompt processing vs. generation** — `llama-bench -p 512` measures how fast the prompt is ingested; `-n 128` measures generating new tokens. They stress hardware differently, so report both.

## Measurement Practice

**GPU offload (`-ngl 99`)** — number of layers placed on the GPU. If speed looks very low, layers may be running on the CPU; verify GPU use rather than assuming.

**VRAM vs. file size** — VRAM use is file size plus KV cache and runtime overhead, so peak VRAM is always larger than the GGUF size, and grows with context length.

**Lab notebook** — paste every command and its raw output into a text file as you go. It makes the experiment reproducible and lets you re-check a number later.

**Numbers are hardware-specific** — results depend on GPU, driver, and llama.cpp build. Record them and state that findings may not transfer.
