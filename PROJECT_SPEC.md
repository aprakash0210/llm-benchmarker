# LLM Benchmarker - Project Specification & Learning Blueprint

## 1. Primary Objective
Measure how much quantization reduces a model's memory footprint and what it costs in speed and quality, then use the results to pick the best quantization level for running a larger model on a 16 GB GPU. The project is a learning vehicle for running a controlled experiment on LLM inference.

## 2. Target Tools & Skills to Master
- **Inference tooling:** llama.cpp (`llama-quantize`, `llama-bench`, `llama-perplexity`), GGUF format, Vulkan/ROCm build.
- **Models:** Hugging Face downloads, `convert_hf_to_gguf.py`.
- **Evaluation:** perplexity on WikiText-2, tokens/s, peak VRAM.
- **Analysis:** Python (pandas, matplotlib) for the results table and charts.
- **Experimental method:** pre-registered hypothesis, controlled variables, lab notebook, repeated runs.

## 3. Key Terms
- **Baseline (before):** original model at 16-bit precision (FP16).
- **Quantized (after):** same model with weights stored in 8, 5, 4, or 2 bits.
- **Perplexity:** quality score, lower is better.
- **Tokens/second:** generation speed, higher is better.

## 4. Experiment Contracts

### A. Independent variable
Quantization level, and nothing else. Same source FP16 GGUF for every quantized file.
- 3B run: FP16 (baseline), Q8_0, Q5_K_M, Q4_K_M, Q2_K
- 14B extension: Q6_K (baseline, stated in README), Q5_K_M, Q4_K_M, Q3_K_M

### B. Controls (must not change between runs)
- Same machine, driver, llama.cpp build
- Same flags: `-ngl 99`, `-p 512`, `-n 128`, same perplexity file and context size
- No other GPU programs running (browser, games)
- TODO (user decision): record llama.cpp build number, GPU driver version, and power/clock settings in the README.

### C. Measurements (per model file)
| Metric | How | Notes |
|--------|-----|-------|
| File size | filesystem | GB |
| Peak VRAM | monitoring tool during run (e.g. Adrenalin overlay/logging) | TODO (user decision): choose tool and sampling method |
| Tokens/s | `llama-bench -m <f> -ngl 99 -p 512 -n 128` | 3 runs, averaged (report spread) |
| Perplexity | `llama-perplexity -m <f> -f wiki.test.raw -ngl 99` | test file from `scripts/get-wikitext-2.sh` |

### D. Outputs
1. Results table: precision, size, VRAM, tokens/s, perplexity, % change vs. baseline.
2. Chart: size vs. perplexity.
3. Chart: speed vs. perplexity.
4. "Sweet spot" pick with 2-3 sentence justification.
5. README with sections: Goal, Hypothesis, Method, Results table, Chart, Findings, Limitations, How to reproduce.
6. Resume bullet, written last, using real numbers only.

## 5. Technical Constraints
- **Hypothesis first:** the hypothesis is committed to the README before any measurement.
- **One variable:** only quantization level changes.
- **Lab notebook:** every command and its raw output pasted into `results/lab_notebook.txt`.
- **GPU verification:** confirm layers are actually on the GPU (`-ngl 99`); suspiciously low speed means CPU fallback.
- **Honest reporting:** report numbers as measured; note hardware/driver dependence; do not copy numbers from other sources.
- **No training/fine-tuning:** this is inference and evaluation only.
