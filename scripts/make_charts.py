"""Build the two results charts from results/results.csv.

Each figure has two panels because Q2_K's perplexity (about 21,900) is ~2,600x the
baseline's: the left panel shows all five files on a log axis (so the collapse is
visible), the right panel zooms in on the four usable files on a linear axis (so the
real tradeoff between them is visible).

Usage:  python scripts/make_charts.py
"""
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "results" / "charts"
OUT.mkdir(parents=True, exist_ok=True)

# Palette: blue = series, orange = highlighted choice (categorical slots 1 and 2 of the
# reference palette; they pass the adjacent-pair checks). Text uses ink colors, not series colors.
SURFACE, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
BLUE, ORANGE = "#2a78d6", "#eb6834"
SWEET_SPOT = "Q5_K_M"

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "text.color": INK, "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2,
    "axes.edgecolor": GRID, "axes.spines.top": False, "axes.spines.right": False,
    "font.size": 10, "axes.titlesize": 11, "axes.titleweight": "bold", "axes.titlelocation": "left",
})

df = pd.read_csv(ROOT / "results" / "results.csv", encoding="utf-8-sig")
df["label"] = df["quant"].replace({"F16": "FP16"})
df = df.sort_values("size_gib", ascending=False).reset_index(drop=True)


def draw(ax, data, x, xerr, xlabel, log_y, title, label_offsets, skip_labels=(), note=None):
    ax.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.plot(data[x], data["perplexity"], color=BLUE, linewidth=2, alpha=0.5, zorder=2)
    for _, r in data.iterrows():
        sweet = r["quant"] == SWEET_SPOT
        color = ORANGE if sweet else BLUE
        ax.errorbar(r[x], r["perplexity"], xerr=r[xerr] if xerr else None, yerr=r["ppl_stderr"],
                    fmt="none", ecolor=color, elinewidth=1.2, capsize=3, alpha=0.7, zorder=3)
        ax.scatter(r[x], r["perplexity"], s=110 if sweet else 70, color=color,
                   edgecolor=SURFACE, linewidth=2, zorder=4)
        if r["quant"] in skip_labels:
            continue
        text = r["label"] + (" (sweet spot)" if sweet else "")
        if r["perplexity"] > 1000:
            text += f"\nPPL {r['perplexity']:,.0f}"
        dx, dy, ha, *rest = label_offsets.get(r["quant"], (8, 8, "left"))
        ax.annotate(text, (r[x], r["perplexity"]), xytext=(dx, dy), textcoords="offset points",
                    ha=ha, va=rest[0] if rest else "bottom", fontsize=9.5, color=INK, fontweight="bold" if sweet else "normal")
    if note:
        ax.text(note[0], note[1], note[2], transform=ax.transAxes, ha=note[3], va="bottom",
                fontsize=9.5, color=INK2)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("Perplexity (lower is better)")
    ax.set_title(title)
    if log_y:
        ax.set_yscale("log")
        ax.set_yticks([10, 100, 1000, 10000])
        ax.get_yaxis().set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:,.0f}"))


def figure(x, xerr, xlabel, filename, suptitle, all_offsets, zoom_offsets, note, invert_x=False):
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(12.5, 5), gridspec_kw={"width_ratios": [1, 1.15]})
    draw(a1, df, x, xerr, xlabel, True, "All five files (log scale)", all_offsets,
         skip_labels=("F16", "Q8_0", "Q5_K_M", "Q4_K_M"), note=note)
    usable = df[df["quant"] != "Q2_K"]
    draw(a2, usable, x, xerr, xlabel, False, "Zoom: excluding Q2_K (linear scale)", zoom_offsets)
    if invert_x:
        a1.invert_xaxis(); a2.invert_xaxis()
    fig.suptitle(suptitle, x=0.01, ha="left", fontsize=13, fontweight="bold")
    fig.text(0.01, 0.005, "Qwen2.5-3B, llama.cpp Vulkan build 11312, RX 9070 XT. Perplexity: WikiText-2 test, "
             "context 512. Vertical bars = standard error across chunks." + (" Horizontal bars = standard deviation of 3 runs." if xerr else ""), fontsize=8.5, color=INK2)
    fig.tight_layout(rect=(0, 0.03, 1, 0.94))
    fig.savefig(OUT / filename, dpi=200)
    plt.close(fig)
    print("wrote", OUT / filename)


figure("size_gib", None, "File size (GiB)", "size_vs_perplexity.png",
       "Smaller files cost quality slowly, then all at once",
       {"Q2_K": (12, -4, "left", "center")},
       {"F16": (-6, 10, "right"), "Q8_0": (-6, 10, "right"), "Q5_K_M": (12, 10, "left"),
        "Q4_K_M": (8, -16, "left")},
       (0.97, 0.12, "FP16, Q8_0, Q5_K_M and Q4_K_M all sit\nat perplexity 8.4 to 8.8 (see zoom)", "right"))

figure("tg128_ts", "tg128_sd", "Generation speed (tokens/s, higher is faster)", "speed_vs_perplexity.png",
       "Faster generation costs quality slowly, then all at once",
       {"Q2_K": (-8, 10, "right")},
       {"F16": (8, 10, "left"), "Q8_0": (8, 10, "left"), "Q5_K_M": (-8, 12, "right"),
        "Q4_K_M": (-8, 10, "right")},
       (0.03, 0.12, "FP16, Q8_0, Q5_K_M and Q4_K_M all sit\nat perplexity 8.4 to 8.8 (see zoom)", "left"))
