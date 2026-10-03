# llm-benchmarker

> A controlled experiment measuring what quantization costs a local LLM in quality and what it buys in memory and speed.

## Overview & Goal
Quantization stores a model's weights in fewer bits (8, 5, 4, 2 instead of 16). This project measures, on one machine with one methodology, how much that shrinks the model and what it costs in speed and quality.
- **Main goal:** Quantify the size / speed / quality tradeoff of quantization.
- **Practical goal:** Find the best quantization level for running a larger model on a 16 GB GPU.
- **Resume goal:** A reproducible repo with a results table, charts, and an honest write-up.

## Hypothesis
> Q4_K_M will cut model size by about 70% with under 20% perplexity increase. The 70% decrease comes from 4.85/16 which is about .3, where 4.85 is the the bits per weight, and 16 is the
> old bits per weight.  The perplexity increase comes from the jump from FP16 to Q4_K_M. Since much of the computing power is lost from this jump, its easy to hypothesize that the
> post quantized model will not hold up to the original.

Result vs. hypothesis is reported in Findings once the runs are done.

## Method
- **Baseline (before):** Qwen2.5-3B at FP16 (GGUF `f16`).
- **Quantized (after):** Q8_0, Q5_K_M, Q4_K_M, Q2_K from the same FP16 file.
- **Metrics:** file size, peak VRAM, tokens/s (llama-bench, 3 runs averaged), perplexity (WikiText-2 test set).
- **Controls:** same machine, same flags, same prompts, nothing else on the GPU.
- **Extension:** 14B model with Q6_K as the baseline (FP16 doesn't fit) vs. Q5_K_M, Q4_K_M, Q3_K_M.

## Sanity Check: Baseline Sample Output
Informal check that the FP16 GGUF loads and generates coherent text on the GPU. This is **not** benchmark data: sampling was at llama.cpp's default (temperature 0.8), so output varies from run to run, and Qwen2.5-3B is a base model (it continues text rather than answering as an assistant).

**Command:**
```
llama-completion.exe -m models\qwen2.5-3b-f16.gguf -ngl 99 -p "The top reasons why macos is better than windows is" -n 100 -no-cnv
```

**FP16 output** (the model repeats the prompt, then continues it):
> The top reasons why macos is better than windows is that macos has the ability to protect you from malware, viruses, and other viruses that windows cannot. Also, macos is the most secure operating system in the world.
> There are some reasons why macos is better than windows and some reasons why it is not. There is no right or wrong answer. The best OS for you is the one that works best for you. In this blog post, we’ll explore some of the reasons why macOS might be better than Windows. Let’s get started

**Observations:** The model continues the prompt like the start of a blog post instead of answering directly (expected for a base model), and its claims are generic and partly wrong or repetitive ("viruses ... other viruses"). Useful as a qualitative reference to compare against the quantized versions later.

## Results
The FP16 baseline is fully measured (size, VRAM, speed, perplexity); all quantized rows are pending. Perplexity is `llama-perplexity` on the WikiText-2 test set with default settings (context 512, 584 chunks); the ± is the standard error across chunks. Peak VRAM is the rise above the idle baseline during `llama-bench` (`scripts/measure_vram.ps1`), so it includes weights plus KV cache and compute buffers. Table and charts land in `results/`.

Speed is mean ± standard deviation across repeated `llama-bench` runs, in tokens/s. `pp512` = prompt processing (512 tokens), `tg128` = token generation (128 tokens). Sizes are GiB (2^30 bytes). Δ speed is computed on `tg128`.

| Precision | Size (GiB) | Peak VRAM (GiB) | pp512 (t/s)        | tg128 (t/s)  | Perplexity | Δ size | Δ speed | Δ perplexity |
|-----------|------------|-----------------|--------------------|--------------|------------|--------|---------|--------------|
| FP16      | 5.75       | 6.20            | 6062.53 ± 526.86   | 92.50 ± 0.52 | 8.4251 ± 0.0567 | -      | -       | -            |
| Q8_0      |            |                 |                    |              |            |        |         |              |
| Q5_K_M    |            |                 |                    |              |            |        |         |              |
| Q4_K_M    |            |                 |                    |              |            |        |         |              |
| Q2_K      |            |                 |                    |              |            |        |         |              |

Baseline note: `pp512` varies about 9% between runs (±526.86), while `tg128` is stable (±0.52, about 0.6%). The first run is often slower from GPU warm-up and shader compilation; see Limitations once all runs are in.

## Findings
TODO after results.

## Limitations
TODO after results (single machine, single model family, single perplexity dataset, etc.).

## How to Reproduce
See `PROJECT_SPEC.md` for the exact commands and settings.

## Tech Stack
llama.cpp (Vulkan/ROCm build), GGUF, Hugging Face, Python (matplotlib/pandas for charts).

## Personal Learning Objectives
- Design a controlled experiment with a pre-registered hypothesis.
- Understand GGUF, quantization schemes (Q8_0 vs K-quants), and perplexity as a quality proxy.
- Benchmark inference correctly (GPU offload, repeated runs, controlled environment).
- Communicate results honestly with a table, charts, and stated limitations.
