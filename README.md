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

## Results
_Not yet run._ Table and charts land in `results/`.

| Precision | Size (GB) | Peak VRAM (GB) | Tokens/s | Perplexity | Δ size | Δ speed | Δ perplexity |
|-----------|-----------|----------------|----------|------------|--------|---------|--------------|
| FP16      |           |                |          |            | -      | -       | -            |
| Q8_0      |           |                |          |            |        |         |              |
| Q5_K_M    |           |                |          |            |        |         |              |
| Q4_K_M    |           |                |          |            |        |         |              |
| Q2_K      |           |                |          |            |        |         |              |

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
