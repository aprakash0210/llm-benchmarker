# LLM Benchmarker - Learning Roadmap
This document tracks progress on the project. Mark things as complete once they are done.

## Active Phase: [ Phase 2 ]

- [x] **Phase 0: Hypothesis & Setup**
  - [x] Write the hypothesis in `README.md` BEFORE running anything: "Q4_K_M will cut model size by about 70% with under X% quality loss" (choose X yourself)
  - [x] Download a prebuilt llama.cpp release (Vulkan or ROCm build) for Windows; confirm `llama-bench --help` runs
  - [x] Create the GitHub repo with `README.md` and a `results/` folder; start `results/lab_notebook.txt`
  - [x] Download Qwen2.5-3B from Hugging Face (~6 GB at FP16)
  - [x] Get the test file via llama.cpp's `scripts/get-wikitext-2.sh` (`wiki.test.raw`)
- [x] **Phase 1: Baseline (before)**
  - [x] Convert to GGUF: `python convert_hf_to_gguf.py <model_dir> --outtype f16 --outfile model-f16.gguf`
  - [x] Measure file size and peak VRAM
  - [x] Measure speed: `llama-bench -m model-f16.gguf -ngl 99 -p 512 -n 128` (3 runs, averaged)
  - [x] Measure quality: `llama-perplexity -m model-f16.gguf -f wiki.test.raw -ngl 99`
  - [x] Confirm the GPU is actually used (speed sanity check)
- [ ] **Phase 2: Optimize (after)**
  - [ ] Create Q8_0, Q5_K_M, Q4_K_M, Q2_K with `llama-quantize` from the FP16 file
  - [ ] Repeat size / VRAM / speed / perplexity for each file — change nothing else, nothing else running
- [ ] **Phase 3: Analyze**
  - [ ] Build the table: precision, size, VRAM, tokens/s, perplexity, % change vs. baseline
  - [ ] Chart size vs. perplexity and speed vs. perplexity
  - [ ] Pick the "sweet spot" and justify it in 2-3 sentences
- [ ] **Phase 4: Write up**
  - [ ] README sections: Goal, Hypothesis, Method, Results table, Chart, Findings, Limitations, How to reproduce
  - [ ] Compare results to the original hypothesis (right or wrong, say so)
  - [ ] Only after all of the above, add the resume bullet with real numbers
- [ ] **Phase 5 (Extension): 14B model**
  - [ ] Repeat with a 14B model; baseline is Q6_K (state this in the README)s
  - [ ] Compare Q6_K, Q5_K_M, Q4_K_M, Q3_K_M
  - [ ] Answer the practical question: what's the best model you can comfortably run on 16 GB?
