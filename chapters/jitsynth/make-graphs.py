#!/usr/bin/env python3

import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from itertools import cycle

plt.rcParams.update({
    'pgf.texsystem': 'pdflatex',
    'pgf.rcfonts': False,
})

sns.set(style="whitegrid", font_scale=1.75)

fig = plt.figure()
instrs = pd.read_csv("data/cycles.csv")
instrs['Evaluator'] = instrs['eval'].map(
        dict(zip(["jitsynth-compiler","linux-compiler","linux-interpreter"],
            ["JitSynth compiler","Linux compiler","Linux interpreter"])))
g = sns.catplot(x="Benchmark", y="Cycles", hue="Evaluator", data=instrs, kind="bar",aspect=3.,legend_out=False)
for i,bar in enumerate(g.ax.patches):
    bar.set_hatch(['///', '\\\\\\', ' '][i // 7])
g.ax.legend(loc='best')
g.despine(left=True)
g.set_ylabels("Cycles")
plt.tight_layout()
plt.savefig("figs/cycles.pgf")
plt.close(fig)

# fig = plt.figure()
# instrs = pd.read_csv("data/l2b-worst-case.csv")
# instrs['Compiler'] = instrs['compiler'].map(
#         dict(zip(["seccomp","jitsynth"],
#             ["libseccomp","JitSynth"])))
# instrs['Benchmark'] = instrs['benchmark']
# g = sns.catplot(x="Benchmark", y="instructions", hue="Compiler", data=instrs, kind="bar", aspect=1.5, legend_out=False)
# for i,bar in enumerate(g.ax.patches):
#     bar.set_hatch(' ' if i >= 5 else '///')
# g.ax.legend(loc='best')
# g.despine(left=True)
# plt.title("Worst-case execution for libseccomp to eBPF benchmarks")
# g.set_ylabels("Instructions executed")
# plt.tight_layout()
# plt.savefig("figs/l2b-wc.pgf")
# plt.close(fig)

fig = plt.figure()
instrs = pd.read_csv("data/l2b-common-case.csv")
instrs['Compiler'] = instrs['compiler'].map(
        dict(zip(["seccomp","jitsynth"],
            ["libseccomp","JitSynth"])))
instrs['Benchmark'] = instrs['benchmark']
g = sns.catplot(x="Benchmark", y="instructions", hue="Compiler", data=instrs, kind="bar", aspect=1.6, legend_out=False)
for i,bar in enumerate(g.ax.patches):
    bar.set_hatch(' ' if i >= 5 else '///')
g.ax.legend(loc='best')
g.despine(left=True)
plt.title("libseccomp to eBPF benchmarks")
g.set_ylabels("Instructions executed")
plt.tight_layout()
plt.savefig("figs/l2b-cc.pgf")
plt.close(fig)


# fig = plt.figure()
# instrs = pd.read_csv("data/o2b-worst-case.csv")
# instrs['Compiler'] = instrs['compiler'].map(
#         dict(zip(["linux","jitsynth"],
#             ["Linux","JitSynth"])))
# instrs['Benchmark'] = instrs['benchmark']
# g = sns.catplot(x="Benchmark", y="instructions", hue="Compiler", data=instrs, kind="bar", aspect=1.5, legend_out=False)
# for i,bar in enumerate(g.ax.patches):
#     bar.set_hatch(' ' if i >= 7 else '///')
# g.ax.legend(loc='best')
# g.despine(left=True)
# plt.title("Worst-case execution for classic BPF to eBPF benchmarks")
# g.set_ylabels("Instructions executed")
# plt.tight_layout()
# plt.savefig("figs/o2b-wc.pgf")
# plt.close(fig)

fig = plt.figure()
instrs = pd.read_csv("data/o2b-common-case.csv")
instrs['Compiler'] = instrs['compiler'].map(
        dict(zip(["linux","jitsynth"],
            ["Linux","JitSynth"])))
instrs['Benchmark'] = instrs['benchmark']
g = sns.catplot(x="Benchmark", y="instructions", hue="Compiler", data=instrs, kind="bar", aspect=1.6, legend_out=False)
for i,bar in enumerate(g.ax.patches):
    bar.set_hatch(' ' if i >= 7 else '///')
g.ax.legend(loc='best')
g.despine(left=True)
plt.title("Classic BPF to eBPF benchmarks")
g.set_ylabels("Instructions executed")
plt.tight_layout()
plt.savefig("figs/o2b-cc.pgf")
plt.close(fig)


def make_synthesis_graph(*,
        csvs,
        title,
        filename,
        markers=['.','.','.'],
        linestyles=['-','--','-.']):

    # Assume first is all-opts and completes
    csvs = list(map(pd.read_csv, csvs))

    total_nr_instructions = len(csvs[0]) - 1

    fig = plt.figure()
    for df, marker, linestyle in zip(csvs, markers, linestyles):
        xs = np.array(df[df.columns[1]])
        ys = np.array(df[df.columns[0]])

        # Draw step plot
        plt.step(xs, (100. * ys) / total_nr_instructions, marker=marker, linestyle=linestyle, where='post', markevery=len(xs)-1)

        # Draw a marker corresponding to if synthesis timed out or not
        (c, m) = ('red', 'x')
        if ys[-1] != total_nr_instructions:
            plt.scatter(xs[-1], (100.*ys[-1])/total_nr_instructions, s=60, c=c, marker=m, zorder=1000)

    plt.title(title)
    plt.xlabel('Time (s)')
    plt.ylabel('Percent of instructions synthesized')
    plt.grid(alpha=0.4)
    plt.legend(labels=['Pre-load','Read-write','Naïve'])

    plt.tight_layout()
    plt.savefig(filename)
    plt.close(fig)


make_synthesis_graph(
    csvs=["data/b2r-all-opts.csv",
          "data/b2r-rwset-only.csv",
          "data/b2r-no-opts.csv"],
    filename='figs/b2r-synth-time.pgf',
    title='Synthesis time for eBPF to RISC-V',
)


make_synthesis_graph(
    csvs=["data/o2b-all-opts.csv",
          "data/o2b-rwset-only.csv",
          "data/o2b-no-opts.csv"],
    filename='figs/o2b-synth-time.pgf',
    title='Synthesis time for classic BPF to eBPF',
)


make_synthesis_graph(
    csvs=["data/l2b-all-opts.csv",
          "data/l2b-rwset-only.csv",
          "data/l2b-no-opts.csv"],
    filename='figs/l2b-synth-time.pgf',
    title='Synthesis time for classic libseccomp to eBPF',
)

