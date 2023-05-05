#!/usr/bin/env python3

import pandas as pd
import numpy as np

cycles = pd.read_csv('data/cycles.csv')
o2b_common_case = pd.read_csv('data/o2b-common-case.csv')
l2b_common_case = pd.read_csv('data/l2b-common-case.csv')

def makemacro(name, value):
    print('\\newcommand{{\\{name}}}{{{value}}}'.format(
        name=name, value=value))

def slowdown(data, new, old, *, compilercol='eval', datacol='Cycles'):
    newcycles = data[data[compilercol] == new][datacol].to_numpy(dtype='float64')
    oldcycles = data[data[compilercol] == old][datacol].to_numpy(dtype='float64')
    # import ipdb; ipdb.set_trace()
    return (newcycles / oldcycles).mean()


makemacro('EbpfCompilerSlowdown',
    str(slowdown(cycles, 'jitsynth-compiler', 'linux-compiler').round(2)))

makemacro('EbpfInterpSpeedup',
    str(slowdown(cycles, 'linux-interpreter', 'jitsynth-compiler').round(2)))


makemacro('CbpfSlowdown',
    str(slowdown(o2b_common_case, 'jitsynth', 'linux',
            datacol='instructions',
            compilercol='compiler').round(2)))

makemacro('LibseccompSlowdown',
    str(slowdown(l2b_common_case, 'jitsynth', 'seccomp',
            datacol='instructions',
            compilercol='compiler').round(2)))

l2b_all_opts = pd.read_csv('data/l2b-all-opts.csv')
l2b_no_opts = pd.read_csv('data/l2b-no-opts.csv')

synthSpeedup = l2b_no_opts['time(s)'].to_numpy(dtype='float64').max() / \
               l2b_all_opts['time(s)'].to_numpy(dtype='float64').max()

makemacro('LibseccompSynthSpeedup', str(int(round(synthSpeedup))))
